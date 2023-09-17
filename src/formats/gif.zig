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
    global_color_table_size: u3 = 0,
    sorted: bool = false,
    color_resolution: u3 = 0,
    use_global_color_table: bool = false,
};

pub const Header = extern struct {
    magic: [3]u8 align(1) = undefined,
    version: [3]u8 align(1) = undefined,
    width: u16 align(1) = 0,
    height: u16 align(1) = 0,
    flags: HeaderFlags align(1) = .{},
    background_color_index: u8 align(1) = 0,
    pixel_aspect_ratio: u8 align(1) = 0,
};

pub const ImageDescriptorFlags = packed struct(u8) {
    local_color_table_size: u3,
    reserved: u2,
    sort: bool,
    is_interlaced: bool,
    has_local_color_table: bool,
};

pub const ImageDescriptor = extern struct {
    left_position: u16 align(1),
    top_position: u16 align(1),
    width: u16 align(1),
    height: u16 align(1),
    flags: ImageDescriptorFlags align(1),
};

pub const GraphicControlExtensionFlags = packed struct(u8) {
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

pub const GraphicControlExtension = extern struct {
    flags: GraphicControlExtensionFlags align(1),
    delay_time: u16 align(1),
    transparent_color_index: u8 align(1),
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

const InterlacePasses = [_]struct { start: usize, step: usize }{
    .{ .start = 0, .step = 8 },
    .{ .start = 4, .step = 8 },
    .{ .start = 2, .step = 4 },
    .{ .start = 1, .step = 2 },
};

// TODO: Move to utils.zig
pub fn FixedStorage(comptime T: type, comptime storage_size: usize) type {
    return struct {
        data: []T,
        storage: [storage_size]T,

        const Self = @This();

        pub fn init() Self {
            var result: Self = undefined;
            return result;
        }

        pub fn resize(self: *Self, size: usize) void {
            self.data = self.storage[0..size];
        }
    };
}

pub const GIF = struct {
    header: Header = .{},
    global_color_table: FixedStorage(color.Rgb24, 256) = FixedStorage(color.Rgb24, 256).init(),
    frames: std.ArrayListUnmanaged(FrameData) = .{},
    comments: std.ArrayListUnmanaged(CommentExtension) = .{},
    application_info: ?ApplicationExtension = null,
    allocator: std.mem.Allocator = undefined,

    pub const FrameData = struct {
        local_color_table: FixedStorage(color.Rgb24, 256) = FixedStorage(color.Rgb24, 256).init(),
        graphics_control: ?GraphicControlExtension = null,
        image_descriptor: ?ImageDescriptor = null,
        plain_text: ?PlainTextExtension = null,
    };

    const Self = @This();

    const ReaderContext = struct {
        reader: Image.Stream.Reader = undefined,
        frame_list: Image.Animation.FrameList = .{},
        current_frame_data: ?*FrameData = null,
    };

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.frames.deinit(self.allocator);
        self.comments.deinit(self.allocator);

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

        var frames = try gif.read(stream);
        if (frames.items.len == 0) {
            return ImageReadError.InvalidData;
        }

        result.width = gif.header.width;
        result.height = gif.header.height;
        result.pixels = frames.items[0].pixels;
        result.animation.frames = frames;
        result.animation.loop_count = gif.loopCount();
        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *Image.Stream, image: Image, encoder_options: Image.EncoderOptions) Image.Stream.WriteError!void {
        _ = allocator;
        _ = write_stream;
        _ = image;
        _ = encoder_options;
    }

    pub fn loopCount(self: Self) i32 {
        _ = self;
        // TODO: mlarouche: Read this information from the application extension
        return Image.AnimationLoopInfinite;
    }

    pub fn read(self: *Self, stream: *Image.Stream) ImageReadError!Image.Animation.FrameList {
        var context = ReaderContext{
            .reader = stream.reader(),
        };

        errdefer {
            for (context.frame_list.items) |entry| {
                entry.pixels.deinit(self.allocator);
            }

            context.frame_list.deinit(self.allocator);
        }

        self.header = try utils.readStructLittle(context.reader, Header);

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

        const global_color_table_size = @as(usize, 1) << (@as(u6, @intCast(self.header.flags.global_color_table_size)) + 1);

        self.global_color_table.resize(global_color_table_size);

        if (self.header.flags.use_global_color_table) {
            var index: usize = 0;

            while (index < global_color_table_size) : (index += 1) {
                self.global_color_table.data[index] = try utils.readStructLittle(context.reader, color.Rgb24);
            }
        }

        try self.readData(&context);

        if (context.frame_list.items.len == 0) {
            const empty_frame = try self.createNewAnimationFrame();
            @memset(empty_frame.pixels.indexed8.palette, color.Rgba32.initRgba(0, 0, 0, 0));

            try context.frame_list.append(self.allocator, empty_frame);
        }

        return context.frame_list;
    }

    // <Data> ::= <Graphic Block> | <Special-Purpose Block>
    fn readData(self: *Self, context: *ReaderContext) !void {
        var current_block = context.reader.readEnum(DataBlockKind, .Little) catch {
            return ImageReadError.InvalidData;
        };

        while (current_block != .end_of_file) {
            var is_graphic_block = false;
            var extension_kind: ?ExtensionKind = null;

            switch (current_block) {
                .image_descriptor => {
                    is_graphic_block = true;
                },
                .extension => {
                    extension_kind = context.reader.readEnum(ExtensionKind, .Little) catch {
                        return ImageReadError.InvalidData;
                    };

                    switch (extension_kind.?) {
                        .graphic_control => {
                            is_graphic_block = true;
                        },
                        .plain_text => {
                            is_graphic_block = true;
                        },
                        else => {},
                    }
                },
                .end_of_file => {
                    return;
                },
            }

            if (is_graphic_block) {
                try self.readGraphicBlock(context, current_block, extension_kind);
            } else {
                try self.readSpecialPurposeBlock(context, extension_kind.?);
            }

            current_block = context.reader.readEnum(DataBlockKind, .Little) catch {
                return ImageReadError.InvalidData;
            };
        }
    }

    // <Graphic Block> ::= [Graphic Control Extension] <Graphic-Rendering Block>
    fn readGraphicBlock(self: *Self, context: *ReaderContext, block_kind: DataBlockKind, extension_kind_opt: ?ExtensionKind) !void {
        context.current_frame_data = try self.allocNewFrame();

        if (extension_kind_opt) |extension_kind| {
            if (extension_kind == .graphic_control) {
                context.current_frame_data.?.graphics_control = blk: {
                    var graphics_control: GraphicControlExtension = undefined;

                    // Eat block size
                    _ = try context.reader.readByte();

                    graphics_control.flags = try utils.readStructLittle(context.reader, GraphicControlExtensionFlags);
                    graphics_control.delay_time = try context.reader.readIntLittle(u16);

                    if (graphics_control.flags.has_transparent_color) {
                        graphics_control.transparent_color_index = try context.reader.readByte();
                    }

                    // Eat block terminator
                    _ = try context.reader.readByte();

                    break :blk graphics_control;
                };

                var new_block_kind = context.reader.readEnum(DataBlockKind, .Little) catch {
                    return ImageReadError.InvalidData;
                };

                try self.readGraphicRenderingBlock(context, new_block_kind, null);
            }
        } else {
            try self.readGraphicRenderingBlock(context, block_kind, extension_kind_opt);
        }
    }

    // <Graphic-Rendering Block> ::= <Table-Based Image> | Plain Text Extension
    fn readGraphicRenderingBlock(self: *Self, context: *ReaderContext, block_kind: DataBlockKind, extension_kind_opt: ?ExtensionKind) !void {
        switch (block_kind) {
            .image_descriptor => {
                try self.readImageDescriptorAndData(context);
            },
            .extension => {
                var extension_kind: ExtensionKind = undefined;
                if (extension_kind_opt) |value| {
                    extension_kind = value;
                } else {
                    extension_kind = context.reader.readEnum(ExtensionKind, .Little) catch {
                        return ImageReadError.InvalidData;
                    };
                }

                switch (extension_kind) {
                    .plain_text => {
                        context.current_frame_data.?.plain_text = blk: {
                            // Eat block size
                            _ = try context.reader.readByte();

                            var new_plain_text_entry: PlainTextExtension = undefined;

                            new_plain_text_entry.text_grid_left_position = try context.reader.readIntLittle(u16);
                            new_plain_text_entry.text_grid_top_position = try context.reader.readIntLittle(u16);
                            new_plain_text_entry.text_grid_width = try context.reader.readIntLittle(u16);
                            new_plain_text_entry.character_cell_width = try context.reader.readByte();
                            new_plain_text_entry.character_cell_height = try context.reader.readByte();
                            new_plain_text_entry.text_foreground_color_index = try context.reader.readByte();
                            new_plain_text_entry.text_background_color_index = try context.reader.readByte();

                            var fixed_alloc = std.heap.FixedBufferAllocator.init(new_plain_text_entry.plain_text_storage[0..]);
                            var plain_data_list = std.ArrayList(u8).init(fixed_alloc.allocator());

                            var read_data = try context.reader.readByte();

                            while (read_data != ExtensionBlockTerminator) {
                                try plain_data_list.append(read_data);

                                read_data = try context.reader.readByte();
                            }

                            new_plain_text_entry.plain_text = plain_data_list.items;

                            break :blk new_plain_text_entry;
                        };
                    },
                    else => {
                        return ImageReadError.InvalidData;
                    },
                }
            },
            .end_of_file => {
                return;
            },
        }
    }

    // <Special-Purpose Block> ::= Application Extension | Comment Extension
    fn readSpecialPurposeBlock(self: *Self, context: *ReaderContext, extension_kind: ExtensionKind) !void {
        switch (extension_kind) {
            .comment => {
                var new_comment_entry = try self.comments.addOne(self.allocator);

                var fixed_alloc = std.heap.FixedBufferAllocator.init(new_comment_entry.comment_storage[0..]);
                var comment_list = std.ArrayList(u8).init(fixed_alloc.allocator());

                var read_data = try context.reader.readByte();

                while (read_data != ExtensionBlockTerminator) {
                    try comment_list.append(read_data);

                    read_data = try context.reader.readByte();
                }

                new_comment_entry.comment = comment_list.items;
            },
            .application_extension => {
                self.application_info = blk: {
                    var application_info: ApplicationExtension = undefined;

                    // Eat block size
                    _ = try context.reader.readByte();

                    _ = try context.reader.read(application_info.application_identifier[0..]);
                    _ = try context.reader.read(application_info.authentification_code[0..]);

                    var data_list = try std.ArrayListUnmanaged(u8).initCapacity(self.allocator, 256);
                    defer data_list.deinit(self.allocator);

                    var read_data = try context.reader.readByte();

                    while (read_data != ExtensionBlockTerminator) {
                        try data_list.append(self.allocator, read_data);

                        read_data = try context.reader.readByte();
                    }

                    application_info.data = try self.allocator.dupe(u8, data_list.items);

                    break :blk application_info;
                };
            },
            else => {
                return ImageReadError.InvalidData;
            },
        }
    }

    // <Table-Based Image> ::= Image Descriptor [Local Color Table] Image Data
    fn readImageDescriptorAndData(self: *Self, context: *ReaderContext) !void {
        if (context.current_frame_data) |current_frame_data| {
            current_frame_data.image_descriptor = try utils.readStructLittle(context.reader, ImageDescriptor);

            // Don't read any futher if the local width or height is zero
            if (current_frame_data.image_descriptor.?.width == 0 or current_frame_data.image_descriptor.?.height == 0) {
                return;
            }

            const local_color_table_size = @as(usize, 1) << (@as(u6, @intCast(current_frame_data.image_descriptor.?.flags.local_color_table_size)) + 1);

            current_frame_data.local_color_table.resize(local_color_table_size);

            if (current_frame_data.image_descriptor.?.flags.has_local_color_table) {
                var index: usize = 0;

                while (index < local_color_table_size) : (index += 1) {
                    current_frame_data.local_color_table.data[index] = try utils.readStructLittle(context.reader, color.Rgb24);
                }
            }

            const effective_color_table = if (current_frame_data.image_descriptor.?.flags.has_local_color_table) current_frame_data.local_color_table.data else self.global_color_table.data;

            var new_animation_frame = try self.createNewAnimationFrame();

            if (current_frame_data.graphics_control) |graphics_control| {
                new_animation_frame.duration = @as(f32, @floatFromInt(graphics_control.delay_time)) * (1.0 / 100.0);
            }

            for (effective_color_table, 0..) |palette_entry, index| {
                new_animation_frame.pixels.indexed8.palette[index] = color.Rgba32.initRgb(palette_entry.r, palette_entry.g, palette_entry.b);
            }

            var array_pixel_buffer = try std.ArrayList(u8).initCapacity(self.allocator, current_frame_data.image_descriptor.?.width * current_frame_data.image_descriptor.?.height);
            defer array_pixel_buffer.deinit();

            const lzw_minimum_code_size = try context.reader.readByte();

            if (lzw_minimum_code_size == @intFromEnum(DataBlockKind.end_of_file)) {
                return Image.ReadError.InvalidData;
            }

            var lzw_decoder = try lzw.Decoder(.Little).init(self.allocator, lzw_minimum_code_size);
            defer lzw_decoder.deinit();

            var data_block_size = try context.reader.readByte();

            while (data_block_size > 0) {
                var data_block = FixedStorage(u8, 256).init();
                data_block.resize(data_block_size);

                _ = try context.reader.read(data_block.data[0..]);

                var data_block_reader = Image.Stream{
                    .buffer = std.io.fixedBufferStream(data_block.data),
                };

                lzw_decoder.decode(data_block_reader.reader(), array_pixel_buffer.writer()) catch {
                    return ImageReadError.InvalidData;
                };

                data_block_size = try context.reader.readByte();
            }

            // Fill frame with background color
            @memset(new_animation_frame.pixels.indexed8.indices, self.header.background_color_index);

            if (current_frame_data.image_descriptor.?.flags.is_interlaced) {
                var source_y: usize = 0;

                for (InterlacePasses) |pass| {
                    var target_y = pass.start + current_frame_data.image_descriptor.?.top_position;

                    while (target_y < self.header.height) {
                        const source_stride = source_y * current_frame_data.image_descriptor.?.width;
                        const target_stride = target_y * self.header.width;

                        for (0..current_frame_data.image_descriptor.?.width) |source_x| {
                            const target_x = source_x + current_frame_data.image_descriptor.?.left_position;

                            const source_index = source_stride + source_x;
                            const target_index = target_stride + target_x;

                            if (source_index < array_pixel_buffer.items.len and target_index < new_animation_frame.pixels.indexed8.indices.len) {
                                new_animation_frame.pixels.indexed8.indices[target_index] = array_pixel_buffer.items[source_index];
                            }
                        }

                        target_y += pass.step;
                        source_y += 1;
                    }
                }
            } else {
                for (0..current_frame_data.image_descriptor.?.height) |source_y| {
                    const target_y = source_y + current_frame_data.image_descriptor.?.top_position;

                    const source_stride = source_y * current_frame_data.image_descriptor.?.width;
                    const target_stride = target_y * self.header.width;

                    for (0..current_frame_data.image_descriptor.?.width) |source_x| {
                        const target_x = source_x + current_frame_data.image_descriptor.?.left_position;

                        const source_index = source_stride + source_x;
                        const target_index = target_stride + target_x;

                        if (source_index < array_pixel_buffer.items.len and target_index < new_animation_frame.pixels.indexed8.indices.len) {
                            new_animation_frame.pixels.indexed8.indices[target_index] = array_pixel_buffer.items[source_index];
                        }
                    }
                }
            }

            try context.frame_list.append(self.allocator, new_animation_frame);
        }
    }

    fn allocNewFrame(self: *Self) !*FrameData {
        var new_frame = try self.frames.addOne(self.allocator);
        new_frame.* = FrameData{};
        return new_frame;
    }

    fn createNewAnimationFrame(self: *const Self) !Image.AnimationFrame {
        var new_frame = Image.AnimationFrame{
            .pixels = try color.PixelStorage.init(self.allocator, PixelFormat.indexed8, @as(usize, @intCast(self.header.width * self.header.height))),
            .duration = 0.0,
        };

        @memset(new_frame.pixels.indexed8.indices, 0);

        return new_frame;
    }
};
