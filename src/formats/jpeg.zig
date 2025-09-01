const std = @import("std");

const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const FormatInterface = @import("../FormatInterface.zig");
const color = @import("../color.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const io = @import("../io.zig");

const FrameHeader = @import("./jpeg/FrameHeader.zig");
const JFIFHeader = @import("./jpeg/JFIFHeader.zig");

const Markers = @import("./jpeg/utils.zig").Markers;
const QuantizationTable = @import("./jpeg/quantization.zig").Table;

const HuffmanReader = @import("./jpeg/huffman.zig").Reader;
const HuffmanTable = @import("./jpeg/huffman.zig").Table;
const Frame = @import("./jpeg/Frame.zig");
const Scan = @import("./jpeg/Scan.zig");

// TODO: Precisions other than 8-bit

// TODO: Hierarchical mode of JPEG compression.

const JPEG_DEBUG = false;

pub const JPEG = struct {
    frame: ?Frame = null,
    allocator: std.mem.Allocator,
    quantization_tables: [4]?QuantizationTable = @splat(null),
    dc_huffman_tables: [4]?HuffmanTable = @splat(null),
    ac_huffman_tables: [4]?HuffmanTable = @splat(null),
    restart_interval: u16 = 0,

    pub fn init(allocator: std.mem.Allocator) JPEG {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *JPEG) void {
        if (self.frame) |*frame| {
            frame.deinit();
        }
    }

    fn parseDefineQuantizationTables(self: *JPEG, reader: *std.Io.Reader) ImageUnmanaged.ReadError!void {
        var segment_size = try reader.takeInt(u16, .big);
        if (JPEG_DEBUG) std.debug.print("DefineQuantizationTables: segment size = 0x{X}\n", .{segment_size});
        segment_size -= 2;

        while (segment_size > 0) {
            const precision_and_destination = try reader.takeByte();
            const table_precision = precision_and_destination >> 4;
            const table_destination = precision_and_destination & 0b11;

            const quantization_table = try QuantizationTable.read(table_precision, reader);
            switch (quantization_table) {
                .q8 => segment_size -= 64 + 1,
                .q16 => segment_size -= 128 + 1,
            }

            self.quantization_tables[table_destination] = quantization_table;
            if (JPEG_DEBUG) std.debug.print("  Table with precision {} installed at {}\n", .{ table_precision, table_destination });
        }
    }

    fn parseScan(self: *JPEG, read_stream: *io.ReadStream) ImageUnmanaged.ReadError!void {
        if (self.frame) |frame| {
            try Scan.performScan(&frame, self.restart_interval, read_stream);
        } else {
            return ImageUnmanaged.ReadError.InvalidData;
        }
    }

    fn initializePixels(self: *JPEG, pixels_opt: *?color.PixelStorage) ImageUnmanaged.ReadError!void {
        if (self.frame) |frame| {
            var pixel_format: PixelFormat = undefined;
            switch (frame.frame_header.components.len) {
                1 => pixel_format = .grayscale8,
                3 => pixel_format = .rgb24,
                else => unreachable,
            }

            const pixel_count = @as(usize, @intCast(frame.frame_header.width)) * @as(usize, @intCast(frame.frame_header.height));
            pixels_opt.* = try color.PixelStorage.init(self.allocator, pixel_format, pixel_count);
        } else {
            return ImageUnmanaged.ReadError.InvalidData;
        }
    }

    pub fn read(self: *JPEG, read_stream: *io.ReadStream, pixels_opt: *?color.PixelStorage) ImageUnmanaged.ReadError!Frame {
        errdefer {
            if (pixels_opt.*) |pixels| {
                pixels.deinit(self.allocator);
                pixels_opt.* = null;
            }
        }

        const reader = read_stream.reader();
        var marker = try reader.takeInt(u16, .big);

        if (marker != @intFromEnum(Markers.start_of_image)) {
            return ImageUnmanaged.ReadError.InvalidData;
        }

        while (marker != @intFromEnum(Markers.end_of_image)) {
            marker = try reader.takeInt(u16, .big);

            if (JPEG_DEBUG) std.debug.print("Parsing marker value: 0x{X}\n", .{marker});

            switch (@as(Markers, @enumFromInt(marker))) {
                .sof0, .sof2 => { // Baseline DCT, progressive DCT Huffman coding
                    if (self.frame != null) {
                        return ImageUnmanaged.Error.Unsupported;
                    }

                    self.frame = try Frame.read(self.allocator, @enumFromInt(marker), &self.quantization_tables, &self.dc_huffman_tables, &self.ac_huffman_tables, reader);
                    try self.initializePixels(pixels_opt);
                },

                .sof1 => return ImageUnmanaged.Error.Unsupported, // extended sequential DCT Huffman coding
                .sof3 => return ImageUnmanaged.Error.Unsupported, // lossless (sequential) Huffman coding
                .sof5 => return ImageUnmanaged.Error.Unsupported,
                .sof6 => return ImageUnmanaged.Error.Unsupported,
                .sof7 => return ImageUnmanaged.Error.Unsupported,
                .sof9 => return ImageUnmanaged.Error.Unsupported, // extended sequential DCT arithmetic coding
                .sof10 => return ImageUnmanaged.Error.Unsupported, // progressive DCT arithmetic coding
                .sof11 => return ImageUnmanaged.Error.Unsupported, // lossless (sequential) arithmetic coding
                .sof13 => return ImageUnmanaged.Error.Unsupported,
                .sof14 => return ImageUnmanaged.Error.Unsupported,
                .sof15 => return ImageUnmanaged.Error.Unsupported,
                .define_huffman_tables => {
                    try self.parseDefineHuffmanTables(reader);
                },
                .start_of_scan => {
                    try self.parseScan(read_stream);
                },

                .define_quantization_tables => {
                    try self.parseDefineQuantizationTables(reader);
                },

                .comment => {
                    if (JPEG_DEBUG) std.debug.print("Skipping comment segment\n", .{});

                    const comment_length = try reader.takeInt(u16, .big);
                    try read_stream.seekBy(comment_length - 2);
                },

                .app0, .app1, .app2, .app3, .app4, .app5, .app6, .app7, .app8, .app9, .app10, .app11, .app12, .app13, .app14, .app15 => {
                    if (JPEG_DEBUG) std.debug.print("Skipping application data segment\n", .{});
                    const application_data_length = try reader.takeInt(u16, .big);
                    try read_stream.seekBy(application_data_length - 2);
                },
                .define_restart_interval => {
                    try self.parseDefineRestartInterval(reader);
                },
                .restart0, .restart1, .restart2, .restart3, .restart4, .restart5, .restart6, .restart7 => {
                    continue;
                },
                .end_of_image => {
                    continue;
                },
                else => {
                    return ImageUnmanaged.ReadError.InvalidData;
                },
            }
        }

        if (self.frame) |*frame| {
            try frame.dequantizeBlocks();
            frame.idctBlocks();
            try frame.renderToPixels(&pixels_opt.*.?);

            return frame.*;
        }

        return ImageUnmanaged.ReadError.InvalidData;
    }

    // Format interface
    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    fn formatDetect(read_stream: *io.ReadStream) ImageUnmanaged.ReadError!bool {
        const reader = read_stream.reader();
        const maybe_start_of_image = try reader.peekInt(u16, .big);
        return maybe_start_of_image == @intFromEnum(Markers.start_of_image);
    }

    fn readImage(allocator: std.mem.Allocator, read_stream: *io.ReadStream) ImageUnmanaged.ReadError!ImageUnmanaged {
        var result = ImageUnmanaged{};
        errdefer result.deinit(allocator);

        var jpeg = JPEG.init(allocator);
        defer jpeg.deinit();

        var pixels_opt: ?color.PixelStorage = null;

        const frame = try jpeg.read(read_stream, &pixels_opt);

        result.width = frame.frame_header.width;
        result.height = frame.frame_header.height;

        if (pixels_opt) |pixels| {
            result.pixels = pixels;
        } else {
            return ImageUnmanaged.ReadError.InvalidData;
        }

        return result;
    }

    fn writeImage(allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: ImageUnmanaged, encoder_options: ImageUnmanaged.EncoderOptions) ImageUnmanaged.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }

    fn parseDefineHuffmanTables(self: *JPEG, reader: *std.Io.Reader) ImageUnmanaged.ReadError!void {
        var segment_size = try reader.takeInt(u16, .big);
        if (JPEG_DEBUG) std.debug.print("DefineHuffmanTables: segment size = 0x{X}\n", .{segment_size});
        segment_size -= 2;

        while (segment_size > 0) {
            const class_and_destination = try reader.takeByte();
            const table_class = class_and_destination >> 4;
            const table_destination = class_and_destination & 0x0F;

            const huffman_table = try HuffmanTable.read(self.allocator, table_class, reader);

            if (table_class == 0) {
                if (self.dc_huffman_tables[table_destination]) |*old_huffman_table| {
                    old_huffman_table.deinit();
                }
                self.dc_huffman_tables[table_destination] = huffman_table;
            } else {
                if (self.ac_huffman_tables[table_destination]) |*old_huffman_table| {
                    old_huffman_table.deinit();
                }
                self.ac_huffman_tables[table_destination] = huffman_table;
            }

            if (JPEG_DEBUG) std.debug.print("  Table with class {} installed at {}\n", .{ table_class, table_destination });

            // Class+Destination + code counts + code table
            segment_size -= 1 + 16 + @as(u16, @intCast(huffman_table.code_map.count()));
        }
    }

    fn parseDefineRestartInterval(self: *JPEG, reader: *std.Io.Reader) !void {
        const segment_length = try reader.takeInt(u16, .big);
        std.debug.assert(segment_length - 4 == 0);

        self.restart_interval = try reader.takeInt(u16, .big);

        if (JPEG_DEBUG) std.debug.print("Restart Interval: {}\n", .{self.restart_interval});
    }
};
