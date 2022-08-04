const FormatInterface = @import("../format_interface.zig").FormatInterface;
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const color = @import("../color.zig");
const Image = @import("../Image.zig");
const std = @import("std");
const utils = @import("../utils.zig");
const lzw = @import("../compressions/lzw.zig");

const ImageReadError = Image.ReadError;
const ImageWriteError = Image.WriteError;

pub const HeaderFlags = packed struct {
    global_color_table_size: u3,
    sorted: bool,
    color_resolution: u3,
    use_global_color_table: bool,
};

// TODO: mlarouche: Replace this with a packed struct once zig supports nested packed struct
pub const Header = struct {
    magic: [3]u8,
    version: [3]u8,
    width: u16,
    height: u16,
    flags: HeaderFlags,
    background_color_index: u8,
    pixel_aspect_ratio: u8,
};

pub const ImageDescriptorFlags = packed struct {
    local_color_table_size: u3,
    reserved: u2,
    sort: bool,
    is_interlaced: bool,
    has_local_color_table: bool,
};

// TODO: mlarouche: Replace this with a packed struct once zig supports nested packed struct
pub const ImageDescriptor = struct {
    left_position: u16,
    top_position: u16,
    width: u16,
    height: u16,
    flags: ImageDescriptorFlags,
};

pub const GraphicControlExtensionFlags = packed struct {
    has_transparent_color: bool,
    user_input: bool,
    disposal_method: enum(u3) {
        none = 0,
        do_not_dispose = 1,
        restore_background_color = 2,
        restore_to_previous = 3,
        _,
    },
    reserved: u3,
};

pub const GraphicControlExtension = struct {
    flags: GraphicControlExtensionFlags,
    delay_time: u16,
    transparent_color_index: u8,
};

pub const CommentExtension = struct {
    comment: []u8,
    comment_storage: [256]u8,
};

pub const PlainTextExtension = struct {
    text_grid_top_position: u16,
    text_grid_left_position: u16,
    text_grid_width: u16,
    character_cell_width: u8,
    character_cell_height: u8,
    text_foreground_color_index: u8,
    text_background_color_index: u8,
    plain_text: []u8,
    plain_text_storage: [256]u8,
};

pub const ApplicationExtension = struct {
    application_identifier: [8]u8,
    authentification_code: [3]u8,
    data: []u8,
};

const DataBlockKind = enum((u8)) {
    image_descriptor = 0x2c,
    extension = 0x21,
    end_of_file = 0x3b,
};

const ExtensionKind = enum(u8) {
    graphic_control = 0xf9,
    comment = 0xfe,
    plain_text = 0x01,
    application_extension = 0xff,
};

const Magic = "GIF";

const Versions = [_][]const u8{
    "87a",
    "89a",
};

const ExtensionBlockTerminator = 0x00;

pub const GIF = struct {
    header: Header = undefined,
    graphics_control: ?GraphicControlExtension = null,
    comments: ?std.ArrayListUnmanaged(CommentExtension) = null,
    plain_texts: ?std.ArrayListUnmanaged(PlainTextExtension) = null,
    application_info: ?ApplicationExtension = null,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.comments) |*comments| {
            comments.deinit(self.allocator);
        }

        if (self.plain_texts) |*plain_texts| {
            plain_texts.deinit(self.allocator);
        }

        if (self.application_info) |application_info| {
            self.allocator.free(application_info.data);
        }
    }

    pub fn formatInterface() FormatInterface {
        return FormatInterface{
            .format = format,
            .formatDetect = formatDetect,
            .readImage = readImage,
            .writeImage = writeImage,
        };
    }

    pub fn format() Image.Format {
        return Image.Format.gif;
    }

    pub fn formatDetect(stream: *Image.Stream) !bool {
        var header_buffer: [6]u8 = undefined;
        const read_bytes = try stream.read(header_buffer[0..]);
        if (read_bytes < 6) {
            return false;
        }

        for (Versions) |version| {
            if (std.mem.eql(u8, header_buffer[0..Magic.len], Magic) and std.mem.eql(u8, header_buffer[Magic.len..], version)) {
                return true;
            }
        }

        return false;
    }

    pub fn readImage(allocator: std.mem.Allocator, stream: *Image.Stream) ImageReadError!Image {
        var result = Image.init(allocator);
        errdefer result.deinit();

        var gif = Self.init(allocator);
        defer gif.deinit();

        try gif.read(stream, &result.pixels);

        result.width = @intCast(usize, gif.header.width);
        result.height = @intCast(usize, gif.header.height);
        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *Image.Stream, pixels: color.PixelStorage, save_info: Image.SaveInfo) Image.Stream.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = pixels;
        _ = save_info;
    }

    pub fn read(self: *Self, stream: *Image.Stream, pixels_opt: *?color.PixelStorage) ImageReadError!void {
        _ = pixels_opt;

        const reader = stream.reader();

        // TODO: mlarouche: Try again having Header being a packed struct when stage3 is released
        // self.header = try utils.readStructLittle(reader, Header);

        _ = try reader.read(self.header.magic[0..]);
        _ = try reader.read(self.header.version[0..]);
        self.header.width = try reader.readIntLittle(u16);
        self.header.height = try reader.readIntLittle(u16);
        self.header.flags = try utils.readStructLittle(reader, HeaderFlags);
        self.header.background_color_index = try reader.readIntLittle(u8);
        self.header.pixel_aspect_ratio = try reader.readIntLittle(u8);

        if (!std.mem.eql(u8, self.header.magic[0..], Magic)) {
            return ImageReadError.InvalidData;
        }

        var valid_version = false;

        for (Versions) |version| {
            if (std.mem.eql(u8, self.header.version[0..], version)) {
                valid_version = true;
                break;
            }
        }

        if (!valid_version) {
            return ImageReadError.InvalidData;
        }

        var global_color_table_storage: [256 * @sizeOf(color.Rgb24)]u8 = undefined;
        var global_color_table_fixed_alloc = std.heap.FixedBufferAllocator.init(global_color_table_storage[0..]);
        var global_color_table_allocator = global_color_table_fixed_alloc.allocator();

        const global_color_table_size = @as(usize, 1) << (self.header.flags.global_color_table_size + 1);

        var global_color_table = try global_color_table_allocator.alloc(color.Rgb24, global_color_table_size);

        if (self.header.flags.use_global_color_table) {
            var index: usize = 0;

            while (index < global_color_table_size) : (index += 1) {
                global_color_table[index] = try utils.readStructLittle(reader, color.Rgb24);
            }
        }

        var current_block = reader.readEnum(DataBlockKind, .Little) catch {
            return ImageReadError.InvalidData;
        };

        while (current_block != .end_of_file) {
            switch (current_block) {
                .image_descriptor => {
                    // TODO: mlarouche: Try again having Header being a packed struct when stage3 is released
                    //const image_descriptor_header = try utils.readStructLittle(reader, ImageDescriptor);
                    var image_descriptor_header: ImageDescriptor = undefined;

                    image_descriptor_header.left_position = try reader.readIntLittle(u16);
                    image_descriptor_header.top_position = try reader.readIntLittle(u16);
                    image_descriptor_header.width = try reader.readIntLittle(u16);
                    image_descriptor_header.height = try reader.readIntLittle(u16);
                    image_descriptor_header.flags = try utils.readStructLittle(reader, ImageDescriptorFlags);

                    var local_color_table_storage: [256 * @sizeOf(color.Rgb24)]u8 = undefined;
                    var local_color_table_fixed_alloc = std.heap.FixedBufferAllocator.init(local_color_table_storage[0..]);
                    var local_color_table_allocator = local_color_table_fixed_alloc.allocator();

                    const local_color_table_size = @as(usize, 1) << (self.header.flags.global_color_table_size + 1);

                    var local_color_table = try local_color_table_allocator.alloc(color.Rgb24, global_color_table_size);

                    if (image_descriptor_header.flags.has_local_color_table) {
                        var index: usize = 0;

                        while (index < local_color_table_size) : (index += 1) {
                            local_color_table[index] = try utils.readStructLittle(reader, color.Rgb24);
                        }
                    }

                    const effective_color_table = if (image_descriptor_header.flags.has_local_color_table) local_color_table else global_color_table;

                    pixels_opt.* = try color.PixelStorage.init(self.allocator, PixelFormat.indexed8, @intCast(usize, self.header.width * self.header.height));

                    if (pixels_opt.*) |pixels| {
                        // Copy the effective palette
                        for (effective_color_table) |palette_entry, index| {
                            pixels.indexed8.palette[index] = color.Rgba32.initRgb(palette_entry.r, palette_entry.g, palette_entry.b);
                        }

                        var pixel_buffer = Image.Stream{
                            .buffer = std.io.fixedBufferStream(std.mem.sliceAsBytes(pixels.indexed8.indices)),
                        };

                        const lzw_minimum_code_size = try reader.readByte();

                        var lzw_decoder = try lzw.Decoder(.Little).init(self.allocator, lzw_minimum_code_size);
                        defer lzw_decoder.deinit();

                        var data_block_size = try reader.readByte();

                        while (data_block_size > 0) {
                            var data_block_storage: [256]u8 = undefined;
                            var data_block_fixed_alloc = std.heap.FixedBufferAllocator.init(data_block_storage[0..]);
                            var data_block_allocator = data_block_fixed_alloc.allocator();

                            const data_block = try data_block_allocator.alloc(u8, data_block_size);
                            _ = try reader.read(data_block[0..]);

                            var data_block_reader = Image.Stream{
                                .buffer = std.io.fixedBufferStream(data_block),
                            };

                            lzw_decoder.decode(data_block_reader.reader(), pixel_buffer.writer()) catch {
                                return ImageReadError.InvalidData;
                            };

                            data_block_size = try reader.readByte();
                        }
                    }
                },
                .extension => {
                    const extension_kind = reader.readEnum(ExtensionKind, .Little) catch {
                        return ImageReadError.InvalidData;
                    };

                    switch (extension_kind) {
                        .graphic_control => {
                            self.graphics_control = blk: {
                                var graphics_control: GraphicControlExtension = undefined;

                                // Eat block size
                                _ = try reader.readByte();

                                graphics_control.flags = try utils.readStructLittle(reader, GraphicControlExtensionFlags);
                                graphics_control.delay_time = try reader.readIntLittle(u16);

                                if (graphics_control.flags.has_transparent_color) {
                                    graphics_control.transparent_color_index = try reader.readByte();
                                }

                                // Eat block terminator
                                _ = try reader.readByte();

                                break :blk graphics_control;
                            };
                        },
                        .comment => {
                            if (self.comments == null) {
                                self.comments = try std.ArrayListUnmanaged(CommentExtension).initCapacity(self.allocator, 2);
                            }

                            if (self.comments) |*comments| {
                                var new_comment_entry = try comments.addOne(self.allocator);

                                var fixed_alloc = std.heap.FixedBufferAllocator.init(new_comment_entry.comment_storage[0..]);
                                var comment_list = std.ArrayList(u8).init(fixed_alloc.allocator());

                                var read_data = try reader.readByte();

                                while (read_data != ExtensionBlockTerminator) {
                                    try comment_list.append(read_data);

                                    read_data = try reader.readByte();
                                }

                                new_comment_entry.comment = comment_list.items;
                            }
                        },
                        .plain_text => {
                            if (self.plain_texts == null) {
                                self.plain_texts = try std.ArrayListUnmanaged(PlainTextExtension).initCapacity(self.allocator, 2);
                            }

                            if (self.plain_texts) |*plain_texts| {
                                var new_plain_text_entry = try plain_texts.addOne(self.allocator);

                                // Eat block size
                                _ = try reader.readByte();

                                new_plain_text_entry.text_grid_left_position = try reader.readIntLittle(u16);
                                new_plain_text_entry.text_grid_top_position = try reader.readIntLittle(u16);
                                new_plain_text_entry.text_grid_width = try reader.readIntLittle(u16);
                                new_plain_text_entry.character_cell_width = try reader.readByte();
                                new_plain_text_entry.character_cell_height = try reader.readByte();
                                new_plain_text_entry.text_foreground_color_index = try reader.readByte();
                                new_plain_text_entry.text_background_color_index = try reader.readByte();

                                var fixed_alloc = std.heap.FixedBufferAllocator.init(new_plain_text_entry.plain_text_storage[0..]);
                                var plain_data_list = std.ArrayList(u8).init(fixed_alloc.allocator());

                                var read_data = try reader.readByte();

                                while (read_data != ExtensionBlockTerminator) {
                                    try plain_data_list.append(read_data);

                                    read_data = try reader.readByte();
                                }

                                new_plain_text_entry.plain_text = plain_data_list.items;
                            }
                        },
                        .application_extension => {
                            self.application_info = blk: {
                                var application_info: ApplicationExtension = undefined;

                                // Eat block size
                                _ = try reader.readByte();

                                _ = try reader.read(application_info.application_identifier[0..]);
                                _ = try reader.read(application_info.authentification_code[0..]);

                                var data_list = try std.ArrayListUnmanaged(u8).initCapacity(self.allocator, 256);
                                defer data_list.deinit(self.allocator);

                                var read_data = try reader.readByte();

                                while (read_data != ExtensionBlockTerminator) {
                                    try data_list.append(self.allocator, read_data);

                                    read_data = try reader.readByte();
                                }

                                application_info.data = try self.allocator.dupe(u8, data_list.items);

                                break :blk application_info;
                            };
                        },
                    }
                },
                .end_of_file => {},
            }

            current_block = reader.readEnum(DataBlockKind, .Little) catch {
                return ImageReadError.InvalidData;
            };
        }
    }
};
