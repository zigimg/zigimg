const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const Image = @import("../Image.zig");
const utils = @import("../utils.zig");
const std = @import("std");
const PixelStorage = color.PixelStorage;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const packbits = @import("../compressions/packbits.zig");
const io = @import("../io.zig");

const iff_description_length = 12;
const IFFMagicHeader = "FORM";
const ILBMMagicHeader = "ILBM";
const ACBMMagicHeader = "ACBM";
const PBMMagicHeader = "PBM ";
const DEEPMMagicHeader = "DEEP";

pub const Chunk = struct {
    id: u32,
    name: []const u8,

    pub fn init(name: []const u8) Chunk {
        std.debug.assert(name.len == 4);
        return .{
            .name = name,
            .id = std.mem.bigToNative(u32, std.mem.bytesToValue(u32, name)),
        };
    }
};

pub const Chunks = struct {
    pub const BMHD = Chunk.init("BMHD");
    pub const BODY = Chunk.init("BODY");
    pub const CAMG = Chunk.init("CAMG");
    pub const CMAP = Chunk.init("CMAP");
    pub const ABIT = Chunk.init("ABIT");
    // DEEP specific chunks
    pub const DGBL = Chunk.init("DBGL");
    pub const DLOC = Chunk.init("DLOC");
};

pub const ChunkHeader = extern struct {
    type: u32 align(1),
    length: u32 align(1),

    const Self = @This();

    pub fn name(self: *const Self) []const u8 {
        return std.mem.asBytes(&self.type);
    }
};

pub const IlbmCompressionType = enum(u8) {
    none = 0,
    // packbits compression
    byterun = 1,
    // Atari-ST files
    byterun2 = 2,
};

pub const DeepCompressionType = enum(u16) {
    none = 0,
    rle = 1,
    huffman = 2,
    dynamic_chuff = 3,
    jpeg = 4,
};

pub const MaskType = enum(u8) {
    none = 0,
    has_mask = 1,
    has_transparent_color = 2,
    has_lasso = 3,
};

pub const ViewportMode = enum(u32) {
    ehb = 0x80,
    ham = 0x800,
    pub fn isEhb(mode: u32) bool {
        return (@intFromEnum(ViewportMode.ehb) & mode) != 0;
    }
    pub fn isHam(mode: u32) bool {
        return (@intFromEnum(ViewportMode.ham) & mode) != 0;
    }
};

pub const IffFormat = enum(u8) {
    // Amiga line-interleaved format
    ilbm = 0,
    // PC-DeluxePaint chunky format
    pbm = 1,
    // AmigaBasic plane-interleaved format
    acbm = 2,
    // TVPaint/Aura .deep files
    deep = 3,
    bad = 4,
};

pub const BmhdHeader = extern struct {
    width: u16 = 0,
    height: u16 = 0,
    x: i16 = 0,
    y: i16 = 0,
    planes: u8 = 0,
    mask_type: MaskType = .none,
    compression_type: IlbmCompressionType = .none,
    pad: u8 = 0,
    transparent_color: u16 = 0,
    x_asoect: u8 = 0,
    y_aspect: u8 = 0,
    page_width: u16 = 0,
    page_height: u16 = 0,

    const Self = @This();

    pub const HeaderSize = @sizeOf(BmhdHeader);

    pub fn debug(self: *const Self) void {
        std.log.debug("{}", .{self});
    }
};

pub const DgblHeader = extern struct {
    width: u16 = 0,
    height: u16 = 0,
    compression_type: DeepCompressionType = .none,
    x_aspect: u8 = 0,
    y_aspect: u8 = 0,

    const Self = @This();

    pub fn debug(self: *const Self) void {
        std.log.debug("{}", .{self});
    }
};

const Header = enum { bmhd, dgbl };

pub const IffHeader = union(Header) {
    bmhd: BmhdHeader,
    dgbl: DgblHeader,

    fn width(self: IffHeader) u16 {
        return switch (self) {
            IffHeader.dgbl => |dgbl| dgbl.width,
            IffHeader.bmhd => |bmhd| bmhd.width,
        };
    }

    fn height(self: IffHeader) u16 {
        return switch (self) {
            IffHeader.dgbl => |dgbl| dgbl.height,
            IffHeader.bmhd => |bmhd| bmhd.height,
        };
    }

    fn debug(self: IffHeader) void {
        switch (self) {
            IffHeader.dgbl => |dgbl| dgbl.debug(),
            IffHeader.bmhd => |bmhd| bmhd.debug(),
        }
    }
};

fn getIffFormatId(magic_buffer: []const u8) Image.ReadError!IffFormat {
    if (magic_buffer.len != iff_description_length) {
        return Image.ReadError.InvalidData;
    }

    const is_iff = std.mem.eql(u8, magic_buffer[0..4], IFFMagicHeader[0..]);
    if (!is_iff) {
        return Image.ReadError.InvalidData;
    }

    if (std.mem.eql(u8, magic_buffer[8..], PBMMagicHeader[0..]))
        return IffFormat.pbm;

    if (std.mem.eql(u8, magic_buffer[8..], ILBMMagicHeader[0..]))
        return IffFormat.ilbm;

    if (std.mem.eql(u8, magic_buffer[8..], ACBMMagicHeader[0..]))
        return IffFormat.acbm;

    return Image.ReadError.InvalidData;
}

pub fn peekIffFormatId(reader: *std.Io.Reader) Image.ReadError!IffFormat {
    const magic_buffer = try reader.peek(iff_description_length);

    return getIffFormatId(magic_buffer);
}

pub fn takeIffFormatId(reader: *std.Io.Reader) Image.ReadError!IffFormat {
    const magic_buffer = try reader.take(iff_description_length);

    return getIffFormatId(magic_buffer);
}

pub fn decodeBmhdChunk(read_stream: *io.ReadStream) Image.ReadError!BmhdHeader {
    const reader = read_stream.reader();

    const chunk = try reader.takeStruct(ChunkHeader, .big);
    if (chunk.type != Chunks.BMHD.id) return Image.ReadError.InvalidData;
    if (chunk.length != @sizeOf(BmhdHeader)) return Image.ReadError.InvalidData;

    const header = try reader.takeStruct(BmhdHeader, .big);
    return header;
}

pub fn decodeDbglChunk(_: *io.ReadStream) Image.ReadError!DgblHeader {
    return DgblHeader{
        .width = 0,
        .height = 0,
        .compression_type = .none,
        .x_aspect = 0,
        .y_aspect = 0,
    };
}

pub fn loadHeader(read_stream: *io.ReadStream, format_id: IffFormat) Image.ReadError!IffHeader {
    return if (format_id == IffFormat.deep) IffHeader{ .dgbl = try decodeDbglChunk(read_stream) } else IffHeader{ .bmhd = try decodeBmhdChunk(read_stream) };
}

pub fn extendEhbPalette(palette: *utils.FixedStorage(color.Rgba32, 256)) void {
    palette.resize(64);
    const data = palette.data;
    for (0..32) |i| {
        const c = data[i];
        // EHB mode extends the palette to 64 colors by adding 32 darker colors
        data[i + 32] = color.Rgba32.from.rgb(c.r >> 1, c.g >> 1, c.b >> 1);
    }
}

pub const IFF = struct {
    cmap_bits: u8 = 0,
    format_id: IffFormat = undefined,
    header: IffHeader = undefined,
    palette: utils.FixedStorage(color.Rgba32, 256) = .{},
    pitch: u16 = 0,
    pixel_byte_size: u8 = 0,
    viewport_mode: u32 = 0,

    pub fn width(self: *IFF) usize {
        return self.header.width();
    }

    pub fn height(self: *IFF) usize {
        return self.header.height();
    }

    pub fn pixelFormat(self: *IFF) Image.Error!PixelFormat {
        if (ViewportMode.isHam(self.viewport_mode) or self.header.bmhd.planes == 24) {
            return PixelFormat.rgb24;
        } else if (self.header.bmhd.planes <= 8) {
            return PixelFormat.indexed8;
        } else {
            return Image.Error.Unsupported;
        }
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn formatDetect(read_stream: *io.ReadStream) Image.ReadError!bool {
        const reader = read_stream.reader();

        const iff_format = peekIffFormatId(reader) catch {
            return false;
        };

        return iff_format != .bad;
    }

    pub fn readImage(allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!Image {
        var result = Image{};
        errdefer result.deinit(allocator);

        var iff = IFF{};

        const pixels = try iff.read(read_stream, allocator);

        result.pixels = pixels;
        result.width = iff.width();
        result.height = iff.height();

        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: Image, encoder_options: Image.EncoderOptions) Image.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }

    pub fn read(self: *IFF, read_stream: *io.ReadStream, allocator: std.mem.Allocator) Image.ReadError!color.PixelStorage {
        const reader = read_stream.reader();

        self.format_id = try takeIffFormatId(reader);
        self.header = try loadHeader(read_stream, self.format_id);
        self.pitch = (std.math.divCeil(u16, self.header.width(), 16) catch 0) * 2;

        const pixels = try self.decodeChunks(read_stream, allocator);

        return pixels;
    }

    pub fn decodeChunks(self: *IFF, read_stream: *io.ReadStream, allocator: std.mem.Allocator) !color.PixelStorage {
        const reader = read_stream.reader();
        const end_pos = try read_stream.getEndPos();
        while (true) {
            const chunk = try reader.takeStruct(ChunkHeader, .big);
            switch (chunk.type) {
                Chunks.ABIT.id, Chunks.BODY.id => return try self.decodeILBMPixelChunk(read_stream, &chunk, allocator),
                Chunks.CAMG.id => try self.decodeCAMGChunk(read_stream),
                Chunks.CMAP.id => try self.decodeCMAPChunk(read_stream, &chunk),
                // skip unsupported chunks
                else => try read_stream.seekBy(chunk.length),
            }
            if (read_stream.getPos() >= end_pos - 1) {
                break;
            }
        }

        return Image.Error.Unsupported;
    }

    pub fn decodeByteRun2(self: *IFF, read_stream: *io.ReadStream, tmp_buffer: []u8, allocator: std.mem.Allocator) !void {
        const header = self.header.bmhd;
        const pitch = self.pitch;
        const reader = read_stream.reader();

        @memset(tmp_buffer, 0);

        // Atari ST ByteRun2 compression: each bitplane is stored and compressed in column
        for (0..header.planes) |plane| {
            // Each plane is stored in a 'VDAT' chunk inside the 'BODY' chunk
            // skip VDAT chunk ID & size
            try reader.discardAll(8);
            const count = try reader.takeInt(u16, .big) - 2;
            const cmds: []u8 = try allocator.alloc(u8, count);
            defer allocator.free(cmds);

            _ = try reader.readSliceAll(cmds);

            var x: u32 = 0;
            var y: u32 = 0;
            var dataCount: u16 = 0;
            var index: usize = 0;
            const plane_offset = plane * header.height * pitch;
            while (x < pitch) : (index += 1) {
                const cmd: i8 = @bitCast(cmds[index]);
                var repeat: u16 = 0;
                switch (cmd) {
                    0 => dataCount = try reader.takeInt(u16, .big),
                    1 => {
                        dataCount = try reader.takeInt(u16, .big);
                        repeat = try reader.takeInt(u16, .big);
                    },
                    else => {
                        if (cmd < 0) {
                            dataCount = @as(u8, @intCast(@abs(cmd)));
                        } else {
                            dataCount = @intCast(cmd);
                            repeat = try reader.takeInt(u16, .big);
                        }
                    },
                }

                while (dataCount > 0 and x < pitch) : (dataCount -= 1) {
                    const offset = plane_offset + x + y * pitch;
                    if (cmd >= 1) {
                        tmp_buffer[offset] = @truncate(repeat >> 8);
                        tmp_buffer[offset + 1] = @truncate(repeat & 0xFF);
                    } else {
                        tmp_buffer[offset] = try reader.takeByte();
                        tmp_buffer[offset + 1] = try reader.takeByte();
                    }
                    y += 1;
                    if (y >= header.height) {
                        y = 0;
                        x += 2;
                    }
                }
            }
        }
    }

    pub fn planarToChunky(self: *IFF, bitplanes: []u8, chunky_buffer: []u8) !void {
        const header = self.header.bmhd;
        const planes = header.planes;
        const w = header.width;
        const h = header.height;
        const pitch = self.pitch;
        const dest_len = chunky_buffer.len;
        const is_vertical = header.compression_type == IlbmCompressionType.byterun2;
        // pixel_size in bytes in the buffer:
        // 1 (the cmap index) for indexed mode
        // 3 (r, g, b components) for 24bit mode
        const pixel_size: u8 = @max(1, planes / 8);

        // we already have a chunky buffer: no need to convert to planar
        if (self.format_id == .pbm) {
            @memcpy(chunky_buffer[0..dest_len], bitplanes[0..dest_len]);
            return;
        }

        @memset(chunky_buffer, 0);

        if (self.format_id == .ilbm) {
            for (0..h) |y| {
                const scanline = y * w;
                for (0..planes) |p| {
                    const plane_mask: u8 = @as(u8, 1) << @intCast(p % 8);
                    // Atari bitplanes are stored plane by plane, Amiga bitplanes are interleaved
                    const offset_base = if (!is_vertical) (pitch * planes * y) + (p * pitch) else p * header.height * pitch + y * pitch;
                    for (0..pitch) |i| {
                        const bit = bitplanes[offset_base + i];
                        const rgb_shift = p / 8;

                        for (0..8) |b| {
                            const mask = @as(u8, 1) << @intCast((@as(u8, 7) - b));
                            if ((bit & mask) > 0) {
                                const x = (i * 8) + b;
                                const offset = (scanline * pixel_size) + (x * pixel_size) + rgb_shift;
                                chunky_buffer[offset] |= plane_mask;
                            }
                        }
                    }
                }
            }
        } else {
            for (0..planes) |p| {
                const plane_mask: u8 = @as(u8, 1) << @intCast(p % 8);
                for (0..h) |y| {
                    const scanline = y * w;
                    const offset_base = (p * pitch * h) + pitch * y;
                    for (0..pitch) |i| {
                        const bit = bitplanes[offset_base + i];
                        const rgb_shift = p / 8;

                        for (0..8) |b| {
                            const mask = @as(u8, 1) << @intCast((@as(u8, 7) - b));
                            if ((bit & mask) > 0) {
                                const x = (i * 8) + b;
                                const offset = (scanline * pixel_size) + (x * pixel_size) + rgb_shift;
                                chunky_buffer[offset] |= plane_mask;
                            }
                        }
                    }
                }
            }
        }
    }

    pub fn decodeCAMGChunk(self: *IFF, read_stream: *io.ReadStream) !void {
        const reader = read_stream.reader();
        self.viewport_mode = try reader.takeInt(u32, .big);
    }

    pub fn decodeCMAPChunk(self: *IFF, read_stream: *io.ReadStream, chunk: *const ChunkHeader) !void {
        const num_colors = chunk.length / 3;
        const reader = read_stream.reader();
        self.palette.resize(num_colors);
        const palette = self.palette.data;

        for (0..num_colors) |i| {
            const c = try reader.takeStruct(color.Rgb24, .little);
            palette[i] = c.to.color(color.Rgba32);
        }
        self.cmap_bits = std.math.log2_int_ceil(usize, palette.len);
    }

    pub fn reduceHamPalette(self: *IFF) void {
        var bits = self.cmap_bits;
        const planes = self.header.bmhd.planes;

        if (bits > planes) {
            bits -= (bits - planes) + 2;
            // bits shouldn't theorically be less than 4 bits in HAM mode.
            std.debug.assert(bits >= 4);

            self.palette.resize(self.palette.data.len >> @truncate(bits));
            self.cmap_bits = bits;
        }
    }

    // Decode BODY/ABIT chunks from IFF-ILBM files
    pub fn decodeILBMPixelChunk(self: *IFF, read_stream: *io.ReadStream, chunk: *const ChunkHeader, allocator: std.mem.Allocator) !color.PixelStorage {
        std.debug.assert(self.pitch != 0);

        const pixel_format = try self.pixelFormat();
        const bmhd = self.header.bmhd;
        var pixels = try color.PixelStorage.init(allocator, pixel_format, self.width() * self.height());
        errdefer pixels.deinit(allocator);

        const tmp_buffer: []u8 = try allocator.alloc(u8, self.pitch * self.height() * bmhd.planes);
        defer allocator.free(tmp_buffer);

        var buffer_size = self.width() * self.height();
        if (bmhd.planes == 24)
            buffer_size *= 3;
        const chunky_buffer: []u8 = try allocator.alloc(u8, buffer_size);
        defer allocator.free(chunky_buffer);

        // first uncompress planes data if needed
        switch (bmhd.compression_type) {
            IlbmCompressionType.byterun => {
                if (self.format_id == IffFormat.acbm) {
                    // ACBM's ABIT body is not compressed even though
                    // the header's compress method is set to 1
                    const reader = read_stream.reader();
                    _ = try reader.readSliceAll(tmp_buffer);
                } else {
                    try packbits.decode(read_stream, tmp_buffer, chunk.length);
                }
            },
            IlbmCompressionType.byterun2 => try self.decodeByteRun2(read_stream, tmp_buffer, allocator),
            else => {
                const reader = read_stream.reader();
                _ = try reader.readSliceAll(tmp_buffer);
            },
        }

        try self.planarToChunky(tmp_buffer, chunky_buffer);

        if (ViewportMode.isEhb(self.viewport_mode) and self.palette.data.len < 64) {
            extendEhbPalette(&self.palette);
        } else if (ViewportMode.isHam((self.viewport_mode))) {
            self.reduceHamPalette();
        }

        switch (pixels) {
            .indexed8 => |*storage| {
                @memcpy(storage.indices[0..], chunky_buffer[0..storage.indices.len]);
                storage.resizePalette(self.palette.data.len);
                for (0..self.palette.data.len) |index| {
                    const palette = storage.palette;
                    palette[index] = self.palette.data[index];
                }
            },
            .rgb24 => |storage| {
                const is_ham = ViewportMode.isHam(self.viewport_mode);
                const planes = self.header.bmhd.planes;
                const cmap_bits: u3 = @truncate(self.cmap_bits);
                const pad_bits: u3 = @truncate(8 - self.cmap_bits);
                const palette = self.palette.data;

                const pixel_size: u8 = @max(1, planes / 8);
                for (0..self.height()) |row| {
                    // Keep color: in HAM mode, current color
                    // may be based on previous color instead of coming from
                    // the palette.
                    var previous_color = color.Rgb24.from.rgb(0, 0, 0);
                    for (0..self.width()) |col| {
                        const index = (self.width() * row * pixel_size) + (col * pixel_size);
                        if (planes == 24) {
                            previous_color = color.Rgb24.from.rgb(chunky_buffer[index], chunky_buffer[index + 1], chunky_buffer[index + 2]);
                        } else if (chunky_buffer[index] < palette.len) {
                            previous_color = color.Rgb24.from.u32Rgba(palette[chunky_buffer[index]].to.u32Rgba());
                        } else if (is_ham) {
                            // Get the control bit which will tell use how current pixel should be calculated
                            const control: u8 = (chunky_buffer[index] >> cmap_bits) & 0x3;
                            // Since we only have (cmap_bits - 2) bits to define the component,
                            // we need to pad it to 8 bits.
                            const component: u8 = (chunky_buffer[index] % @as(u8, @truncate(palette.len))) << pad_bits;

                            if (control == 1) {
                                previous_color.b = component;
                            } else if (control == 2) {
                                previous_color.r = component;
                            } else {
                                previous_color.g = component;
                            }
                        } else unreachable;

                        storage[row * self.width() + col] = previous_color;
                    }
                }
            },
            else => unreachable,
        }

        return pixels;
    }
};
