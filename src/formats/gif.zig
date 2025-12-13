const color = @import("../color.zig");
const FormatInterface = @import("../FormatInterface.zig");
const Image = @import("../Image.zig");
const io = @import("../io.zig");
const lzw = @import("../compressions/lzw.zig");
const PixelFormat = @import("../pixel_format.zig").PixelFormat;
const PixelFormatConverter = @import("../PixelFormatConverter.zig");
const std = @import("std");
const utils = @import("../utils.zig");

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
    local_color_table_size: u3 = 0,
    reserved: u2 = 0,
    sort: bool = false,
    is_interlaced: bool = false,
    has_local_color_table: bool = false,
};

pub const ImageDescriptor = extern struct {
    left_position: u16 align(1) = 0,
    top_position: u16 align(1) = 0,
    width: u16 align(1) = 0,
    height: u16 align(1) = 0,
    flags: ImageDescriptorFlags align(1) = .{},
};

pub const DisposeMethod = enum(u3) {
    none = 0,
    do_not_dispose = 1,
    restore_background_color = 2,
    restore_to_previous = 3,
    _,
};

pub const GraphicControlExtensionFlags = packed struct(u8) {
    has_transparent_color: bool = false,
    user_input: bool = false,
    disposal_method: DisposeMethod = .none,
    reserved: u3 = 0,
};

pub const GraphicControlExtension = extern struct {
    flags: GraphicControlExtensionFlags align(1) = .{},
    delay_time: u16 align(1) = 0,
    transparent_color_index: u8 align(1) = 0,
};

pub const CommentExtension = struct {
    comment: []u8,

    pub fn deinit(self: CommentExtension, allocator: std.mem.Allocator) void {
        allocator.free(self.comment);
    }
};

pub const ApplicationExtension = struct {
    application_identifier: [8]u8,
    authentification_code: [3]u8,
    data: []u8,

    pub fn deinit(self: ApplicationExtension, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }
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

const MAGIC = "GIF";

const VERSIONS = [_][]const u8{
    "87a",
    "89a",
};

const ApplicationExtensions = struct {
    identifier: []const u8,
    code: []const u8,
};
const ANIMATION_APPLICATION_EXTENSIONS = [_]ApplicationExtensions{
    .{
        .identifier = "NETSCAPE",
        .code = "2.0",
    },
    .{
        .identifier = "ANIMEXTS",
        .code = "1.0",
    },
};

const EXTENSION_BLOCK_TERMINATOR = 0x00;

const INTERLACE_PASSES = [_]struct { start: usize, step: usize }{
    .{ .start = 0, .step = 8 },
    .{ .start = 4, .step = 8 },
    .{ .start = 2, .step = 4 },
    .{ .start = 1, .step = 2 },
};

const COLOR_TABLE_SHIFT_TYPE = if (@sizeOf(usize) == 4) u5 else u6;

pub const GIF = struct {
    header: Header = .{},
    global_color_table: utils.FixedStorage(color.Rgb24, 256) = .{},
    frames: std.ArrayList(FrameData) = .{},
    comments: std.ArrayList(CommentExtension) = .{},
    application_infos: std.ArrayList(ApplicationExtension) = .{},
    arena_allocator: std.heap.ArenaAllocator = undefined,

    pub const SubImage = struct {
        local_color_table: utils.FixedStorage(color.Rgb24, 256) = .{},
        image_descriptor: ImageDescriptor = .{},
        pixels: []u8 = &.{},

        pub fn deinit(self: SubImage, allocator: std.mem.Allocator) void {
            allocator.free(self.pixels);
        }
    };

    pub const FrameData = struct {
        graphics_control: ?GraphicControlExtension = null,
        sub_images: std.ArrayList(*SubImage) = .{},

        pub fn deinit(self: *FrameData, allocator: std.mem.Allocator) void {
            for (self.sub_images.items) |sub_image| {
                sub_image.deinit(allocator);
            }

            self.sub_images.deinit(allocator);
        }

        pub fn allocNewSubImage(self: *FrameData, allocator: std.mem.Allocator) !*SubImage {
            const new_sub_image = try allocator.create(SubImage);
            new_sub_image.* = SubImage{};

            try self.sub_images.append(allocator, new_sub_image);

            return new_sub_image;
        }
    };

    const ReaderContext = struct {
        reader: *std.Io.Reader = undefined,
        current_frame_data: ?*FrameData = null,
        has_animation_application_extension: bool = false,
    };

    pub const EncoderOptions = struct {
        /// Number of animation loops (-1 for infinite, 0 for play once).
        /// When `null`, the writer preserves `Image.animation.loop_count`.
        loop_count: ?i32 = null,

        /// Automatically quantize non-indexed input to `.indexed8`.
        auto_convert: bool = false,
    };

    pub fn init(allocator: std.mem.Allocator) GIF {
        return .{
            .arena_allocator = std.heap.ArenaAllocator.init(allocator),
        };
    }

    pub fn deinit(self: *GIF) void {
        self.arena_allocator.deinit();
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

        const read_header = try reader.peek(6);
        if (read_header.len < 6) {
            return false;
        }

        for (VERSIONS) |version| {
            if (std.mem.eql(u8, read_header[0..MAGIC.len], MAGIC) and std.mem.eql(u8, read_header[MAGIC.len..], version)) {
                return true;
            }
        }

        return false;
    }

    pub fn readImage(allocator: std.mem.Allocator, read_stream: *io.ReadStream) Image.ReadError!Image {
        var result = Image{};
        errdefer result.deinit(allocator);

        var gif = GIF.init(allocator);
        defer gif.deinit();

        const frames = try gif.read(read_stream);
        if (frames.items.len == 0) {
            return Image.ReadError.InvalidData;
        }

        result.width = gif.header.width;
        result.height = gif.header.height;
        result.pixels = frames.items[0].pixels;
        result.animation.frames = frames;
        result.animation.loop_count = gif.loopCount();
        return result;
    }

    pub fn writeImage(allocator: std.mem.Allocator, write_stream: *io.WriteStream, image: Image, encoder_options: Image.EncoderOptions) Image.WriteError!void {
        const writer = write_stream.writer();

        var converted_pixels: ?color.PixelStorage = null;
        defer if (converted_pixels) |pixels| pixels.deinit(allocator);

        var pixels_to_use = &image.pixels;
        if (!image.pixelFormat().isIndexed()) {
            if (!encoder_options.gif.auto_convert) {
                return Image.WriteError.Unsupported;
            }
            converted_pixels = PixelFormatConverter.convert(allocator, &image.pixels, .indexed8) catch {
                return Image.WriteError.Unsupported;
            };
            pixels_to_use = &converted_pixels.?;
        }

        // Use image's loop_count for roundtrip preservation.
        // encoder_options.gif.loop_count can override (-1 means infinite, >= 0 is explicit).
        const loop_count = selectedLoopCount(encoder_options.gif.loop_count, image.animation.loop_count);

        try writeHeader(writer, image, pixels_to_use, loop_count);

        // Get global palette for color table optimization
        const global_palette = pixels_to_use.getPalette();

        // Write image frames
        if (image.animation.frames.items.len > 1) {
            // Multi-frame animated GIF - write each frame with its bounds
            for (image.animation.frames.items) |frame| {
                const delay_cs: u16 = @intFromFloat(frame.duration * 100.0);
                const disposal: DisposeMethod = @enumFromInt(frame.disposal);

                // Use frame bounds if set, otherwise use full image dimensions
                const frame_width: u16 = if (frame.frame_width > 0) frame.frame_width else @truncate(image.width);
                const frame_height: u16 = if (frame.frame_height > 0) frame.frame_height else @truncate(image.height);

                try writeImageBlock(
                    allocator,
                    writer,
                    &frame.pixels,
                    frame_width,
                    frame_height,
                    frame.left,
                    frame.top,
                    delay_cs,
                    disposal,
                    global_palette,
                    frame.transparent_index,
                );
            }
        } else {
            // Single frame. Use pixels_to_use which may have been auto-converted
            const first_frame = if (image.animation.frames.items.len > 0) image.animation.frames.items[0] else null;
            const frame_width: u16 = if (first_frame != null and first_frame.?.frame_width > 0) first_frame.?.frame_width else @truncate(image.width);
            const frame_height: u16 = if (first_frame != null and first_frame.?.frame_height > 0) first_frame.?.frame_height else @truncate(image.height);
            const left: u16 = if (first_frame != null) first_frame.?.left else 0;
            const top: u16 = if (first_frame != null) first_frame.?.top else 0;
            const transparent_idx: ?u8 = if (first_frame != null) first_frame.?.transparent_index else null;

            try writeImageBlock(
                allocator,
                writer,
                pixels_to_use,
                frame_width,
                frame_height,
                left,
                top,
                0, // no delay for single frame
                .none,
                global_palette,
                transparent_idx,
            );
        }

        try writeTrailer(writer);
    }

    fn selectedLoopCount(override_loop_count: ?i32, animation_loop_count: i32) i32 {
        return override_loop_count orelse animation_loop_count;
    }

    pub fn loopCount(self: GIF) i32 {
        for (self.application_infos.items) |application_info| {
            for (ANIMATION_APPLICATION_EXTENSIONS) |anim_extension| {
                if (std.mem.eql(u8, application_info.application_identifier[0..], anim_extension.identifier) and std.mem.eql(u8, application_info.authentification_code[0..], anim_extension.code)) {
                    const loop_count = std.mem.readPackedInt(u16, application_info.data[1..], 0, .little);
                    if (loop_count == 0) {
                        return Image.AnimationLoopInfinite;
                    }
                    return loop_count;
                }
            }
        }

        return 0;
    }

    pub fn read(self: *GIF, read_stream: *io.ReadStream) Image.ReadError!Image.Animation.FrameList {
        var context = ReaderContext{
            .reader = read_stream.reader(),
        };

        self.header = try context.reader.takeStruct(Header, .little);

        if (!std.mem.eql(u8, self.header.magic[0..], MAGIC)) {
            return Image.ReadError.InvalidData;
        }

        var valid_version = false;

        for (VERSIONS) |version| {
            if (std.mem.eql(u8, self.header.version[0..], version)) {
                valid_version = true;
                break;
            }
        }

        if (!valid_version) {
            return Image.ReadError.InvalidData;
        }

        const global_color_table_size = @as(usize, 1) << (@as(COLOR_TABLE_SHIFT_TYPE, @intCast(self.header.flags.global_color_table_size)) + 1);

        self.global_color_table.resize(global_color_table_size);

        if (self.header.flags.use_global_color_table) {
            var index: usize = 0;

            while (index < global_color_table_size) : (index += 1) {
                self.global_color_table.data[index] = try context.reader.takeStruct(color.Rgb24, .little);
            }
        }

        try self.readData(&context);

        return try self.render();
    }

    // <Data> ::= <Graphic Block> | <Special-Purpose Block>
    fn readData(self: *GIF, context: *ReaderContext) Image.ReadError!void {
        var current_block = context.reader.takeEnum(DataBlockKind, .little) catch {
            return Image.ReadError.InvalidData;
        };

        while (current_block != .end_of_file) {
            var is_graphic_block = false;
            var extension_kind_opt: ?ExtensionKind = null;

            switch (current_block) {
                .image_descriptor => {
                    is_graphic_block = true;
                },
                .extension => {
                    extension_kind_opt = context.reader.takeEnum(ExtensionKind, .little) catch blk: {
                        var dummy_byte = try context.reader.takeByte();
                        while (dummy_byte != EXTENSION_BLOCK_TERMINATOR) {
                            dummy_byte = try context.reader.takeByte();
                        }
                        break :blk null;
                    };

                    if (extension_kind_opt) |extension_kind| {
                        switch (extension_kind) {
                            .graphic_control => {
                                is_graphic_block = true;
                            },
                            .plain_text => {
                                is_graphic_block = true;
                            },
                            else => {},
                        }
                    } else {
                        current_block = context.reader.takeEnum(DataBlockKind, .little) catch {
                            return Image.ReadError.InvalidData;
                        };
                        continue;
                    }
                },
                .end_of_file => {
                    return;
                },
            }

            if (is_graphic_block) {
                try self.readGraphicBlock(context, current_block, extension_kind_opt);
            } else {
                try self.readSpecialPurposeBlock(context, extension_kind_opt.?);
            }

            current_block = context.reader.takeEnum(DataBlockKind, .little) catch {
                return Image.ReadError.InvalidData;
            };
        }
    }

    // <Graphic Block> ::= [Graphic Control Extension] <Graphic-Rendering Block>
    fn readGraphicBlock(self: *GIF, context: *ReaderContext, block_kind: DataBlockKind, extension_kind_opt: ?ExtensionKind) Image.ReadError!void {
        if (extension_kind_opt) |extension_kind| {
            if (extension_kind == .graphic_control) {
                // If we are seeing a Graphics Control Extension block, it means we need to start a new animation frame
                context.current_frame_data = try self.allocNewFrame();

                context.current_frame_data.?.graphics_control = blk: {
                    var graphics_control: GraphicControlExtension = undefined;

                    // Eat block size
                    context.reader.toss(1);

                    graphics_control.flags = try context.reader.takeStruct(GraphicControlExtensionFlags, .little);
                    graphics_control.delay_time = try context.reader.takeInt(u16, .little);

                    if (graphics_control.flags.has_transparent_color) {
                        graphics_control.transparent_color_index = try context.reader.takeByte();
                    } else {
                        // Eat transparent index byte
                        context.reader.toss(1);

                        graphics_control.transparent_color_index = 0;
                    }

                    // Eat block terminator
                    context.reader.toss(1);

                    break :blk graphics_control;
                };

                const new_block_kind = context.reader.takeEnum(DataBlockKind, .little) catch {
                    return Image.ReadError.InvalidData;
                };

                // Continue reading the graphics rendering block
                try self.readGraphicRenderingBlock(context, new_block_kind, null);
            } else if (extension_kind == .plain_text) {
                try self.readGraphicRenderingBlock(context, block_kind, extension_kind_opt);
            }
        } else {
            if (context.current_frame_data == null) {
                context.current_frame_data = try self.allocNewFrame();
            } else if (context.has_animation_application_extension) {
                context.current_frame_data = try self.allocNewFrame();
            }

            try self.readGraphicRenderingBlock(context, block_kind, extension_kind_opt);
        }
    }

    // <Graphic-Rendering Block> ::= <Table-Based Image> | Plain Text Extension
    fn readGraphicRenderingBlock(self: *GIF, context: *ReaderContext, block_kind: DataBlockKind, extension_kind_opt: ?ExtensionKind) Image.ReadError!void {
        switch (block_kind) {
            .image_descriptor => {
                try self.readImageDescriptorAndData(context);
            },
            .extension => {
                var extension_kind: ExtensionKind = undefined;
                if (extension_kind_opt) |value| {
                    extension_kind = value;
                } else {
                    extension_kind = context.reader.takeEnum(ExtensionKind, .little) catch {
                        return Image.ReadError.InvalidData;
                    };
                }

                switch (extension_kind) {
                    .plain_text => {
                        // Skip plain text extension, it is not worth it to support it
                        const block_size = try context.reader.takeByte();
                        try context.reader.discardAll(block_size);

                        const sub_data_size = try context.reader.takeByte();
                        try context.reader.discardAll(sub_data_size + 1);
                    },
                    else => {
                        return Image.ReadError.InvalidData;
                    },
                }
            },
            .end_of_file => {
                return;
            },
        }
    }

    // <Special-Purpose Block> ::= Application Extension | Comment Extension
    fn readSpecialPurposeBlock(self: *GIF, context: *ReaderContext, extension_kind: ExtensionKind) Image.ReadError!void {
        const gif_arena_allocator = self.arena_allocator.allocator();

        switch (extension_kind) {
            .comment => {
                var new_comment_entry = try self.comments.addOne(gif_arena_allocator);

                var temp_arena = std.heap.ArenaAllocator.init(self.arena_allocator.child_allocator);
                defer temp_arena.deinit();

                const temp_allocator = temp_arena.allocator();

                var comment_list = try std.ArrayList(u8).initCapacity(temp_allocator, 256);

                var data_block_size = try context.reader.takeByte();

                while (data_block_size > 0) {
                    var data_block = utils.FixedStorage(u8, 256){};
                    data_block.resize(data_block_size);

                    _ = try context.reader.readSliceAll(data_block.data[0..]);

                    try comment_list.appendSlice(temp_allocator, data_block.data);

                    data_block_size = try context.reader.takeByte();
                }

                new_comment_entry.comment = try gif_arena_allocator.dupe(u8, comment_list.items);
            },
            .application_extension => {
                const new_application_info = blk: {
                    var application_info: ApplicationExtension = undefined;

                    // Eat block size
                    context.reader.toss(1);

                    _ = try context.reader.readSliceAll(application_info.application_identifier[0..]);
                    _ = try context.reader.readSliceAll(application_info.authentification_code[0..]);

                    var temp_arena = std.heap.ArenaAllocator.init(self.arena_allocator.child_allocator);
                    defer temp_arena.deinit();

                    const temp_allocator = temp_arena.allocator();

                    var data_list = try std.ArrayList(u8).initCapacity(temp_allocator, 256);

                    var data_block_size = try context.reader.takeByte();

                    while (data_block_size > 0) {
                        var data_block = utils.FixedStorage(u8, 256){};
                        data_block.resize(data_block_size);

                        _ = try context.reader.readSliceAll(data_block.data[0..]);

                        try data_list.appendSlice(temp_allocator, data_block.data);

                        data_block_size = try context.reader.takeByte();
                    }

                    application_info.data = try gif_arena_allocator.dupe(u8, data_list.items);

                    break :blk application_info;
                };

                for (ANIMATION_APPLICATION_EXTENSIONS) |anim_extension| {
                    if (std.mem.eql(u8, new_application_info.application_identifier[0..], anim_extension.identifier) and std.mem.eql(u8, new_application_info.authentification_code[0..], anim_extension.code)) {
                        context.has_animation_application_extension = true;
                        break;
                    }
                }

                try self.application_infos.append(gif_arena_allocator, new_application_info);
            },
            else => {
                return Image.ReadError.InvalidData;
            },
        }
    }

    // <Table-Based Image> ::= Image Descriptor [Local Color Table] Image Data
    fn readImageDescriptorAndData(self: *GIF, context: *ReaderContext) Image.ReadError!void {
        const gif_arena_allocator = self.arena_allocator.allocator();

        if (context.current_frame_data) |current_frame_data| {
            var sub_image = try current_frame_data.allocNewSubImage(gif_arena_allocator);
            sub_image.image_descriptor = try context.reader.takeStruct(ImageDescriptor, .little);

            // Don't read any futher if the local width or height is zero
            if (sub_image.image_descriptor.width == 0 or sub_image.image_descriptor.height == 0) {
                return;
            }

            const local_color_table_size = @as(usize, 1) << (@as(COLOR_TABLE_SHIFT_TYPE, @intCast(sub_image.image_descriptor.flags.local_color_table_size)) + 1);

            sub_image.local_color_table.resize(local_color_table_size);

            if (sub_image.image_descriptor.flags.has_local_color_table) {
                var index: usize = 0;

                while (index < local_color_table_size) : (index += 1) {
                    sub_image.local_color_table.data[index] = try context.reader.takeStruct(color.Rgb24, .little);
                }
            }

            sub_image.pixels = try gif_arena_allocator.alloc(u8, @as(usize, sub_image.image_descriptor.height) * @as(usize, sub_image.image_descriptor.width));
            var pixels_buffer_writer = std.Io.Writer.fixed(sub_image.pixels);

            const lzw_minimum_code_size = try context.reader.takeByte();

            if (lzw_minimum_code_size == @intFromEnum(DataBlockKind.end_of_file)) {
                return Image.ReadError.InvalidData;
            }

            var temp_arena = std.heap.ArenaAllocator.init(self.arena_allocator.child_allocator);
            defer temp_arena.deinit();

            const temp_allocator = temp_arena.allocator();

            var lzw_decoder = try lzw.Decoder(.little).init(temp_allocator, lzw_minimum_code_size, 0);
            defer lzw_decoder.deinit();

            var data_block_size = try context.reader.takeByte();

            while (data_block_size > 0) {
                var data_block = utils.FixedStorage(u8, 256){};
                data_block.resize(data_block_size);

                _ = try context.reader.readSliceAll(data_block.data[0..]);

                var data_block_reader = std.Io.Reader.fixed(data_block.data);

                lzw_decoder.decode(&data_block_reader, &pixels_buffer_writer) catch |err| {
                    if (err != error.WriteFailed) {
                        return Image.ReadError.InvalidData;
                    }
                };

                data_block_size = try context.reader.takeByte();
            }
        }
    }

    fn render(self: *GIF) Image.ReadError!Image.Animation.FrameList {
        const final_pixel_format = self.findBestPixelFormat();

        const frame_list_allocator = self.arena_allocator.child_allocator;

        var frame_list = Image.Animation.FrameList{};

        if (self.frames.items.len == 0) {
            var current_animation_frame = try self.createNewAnimationFrame(frame_list_allocator, final_pixel_format);
            fillPalette(&current_animation_frame, self.global_color_table.data, null);
            fillWithBackgroundColor(&current_animation_frame, self.global_color_table.data, self.header.background_color_index);
            try frame_list.append(frame_list_allocator, current_animation_frame);
            return frame_list;
        }

        var canvas = try self.createNewAnimationFrame(frame_list_allocator, final_pixel_format);
        defer canvas.deinit(frame_list_allocator);

        var previous_canvas = try self.createNewAnimationFrame(frame_list_allocator, final_pixel_format);
        defer previous_canvas.deinit(frame_list_allocator);

        if (self.header.flags.use_global_color_table) {
            fillPalette(&canvas, self.global_color_table.data, null);
            fillWithBackgroundColor(&canvas, self.global_color_table.data, self.header.background_color_index);

            copyFrame(&canvas, &previous_canvas);
        }

        var has_graphic_control = false;
        for (self.frames.items) |frame| {
            if (frame.graphics_control != null) {
                has_graphic_control = true;
                break;
            }
        }

        for (self.frames.items) |frame| {
            var current_animation_frame = try self.createNewAnimationFrame(frame_list_allocator, final_pixel_format);

            var transparency_index_opt: ?u8 = null;

            var dispose_method: DisposeMethod = .none;

            if (frame.graphics_control) |graphics_control| {
                current_animation_frame.duration = @as(f32, @floatFromInt(graphics_control.delay_time)) * (1.0 / 100.0);
                if (graphics_control.flags.has_transparent_color) {
                    transparency_index_opt = graphics_control.transparent_color_index;
                }

                dispose_method = graphics_control.flags.disposal_method;
            }

            if (self.header.flags.use_global_color_table) {
                fillPalette(&current_animation_frame, self.global_color_table.data, transparency_index_opt);
            }

            for (frame.sub_images.items) |sub_image| {
                const effective_color_table = if (sub_image.image_descriptor.flags.has_local_color_table) sub_image.local_color_table.data else self.global_color_table.data;

                if (sub_image.image_descriptor.flags.has_local_color_table) {
                    fillPalette(&current_animation_frame, effective_color_table, transparency_index_opt);
                }

                self.renderSubImage(sub_image, &canvas, effective_color_table, transparency_index_opt);
            }

            copyFrame(&canvas, &current_animation_frame);

            if (!has_graphic_control or (has_graphic_control and frame.graphics_control != null)) {
                try frame_list.append(frame_list_allocator, current_animation_frame);
            } else {
                current_animation_frame.deinit(frame_list_allocator);
            }

            switch (dispose_method) {
                .restore_to_previous => {
                    copyFrame(&previous_canvas, &canvas);
                },
                .restore_background_color => {
                    for (frame.sub_images.items) |sub_image| {
                        const effective_color_table = if (sub_image.image_descriptor.flags.has_local_color_table) sub_image.local_color_table.data else self.global_color_table.data;

                        self.replaceWithBackground(sub_image, &canvas, effective_color_table, transparency_index_opt);
                    }

                    copyFrame(&canvas, &previous_canvas);
                },
                else => {
                    copyFrame(&canvas, &previous_canvas);
                },
            }
        }

        return frame_list;
    }

    fn fillPalette(current_frame: *Image.AnimationFrame, effective_color_table: []const color.Rgb24, transparency_index_opt: ?u8) void {
        // TODO: Support transparency index for indexed images
        _ = transparency_index_opt;

        switch (current_frame.pixels) {
            .indexed1 => |pixels| {
                for (0..@min(effective_color_table.len, pixels.palette.len)) |index| {
                    pixels.palette[index] = color.Rgba32.from.u32Rgb(effective_color_table[index].to.u32Rgb());
                }
            },
            .indexed2 => |pixels| {
                for (0..@min(effective_color_table.len, pixels.palette.len)) |index| {
                    pixels.palette[index] = color.Rgba32.from.u32Rgb(effective_color_table[index].to.u32Rgb());
                }
            },
            .indexed4 => |pixels| {
                for (0..@min(effective_color_table.len, pixels.palette.len)) |index| {
                    pixels.palette[index] = color.Rgba32.from.u32Rgb(effective_color_table[index].to.u32Rgb());
                }
            },
            .indexed8 => |pixels| {
                for (0..@min(effective_color_table.len, pixels.palette.len)) |index| {
                    pixels.palette[index] = color.Rgba32.from.u32Rgb(effective_color_table[index].to.u32Rgb());
                }
            },
            else => {},
        }
    }

    fn fillWithBackgroundColor(current_frame: *Image.AnimationFrame, effective_color_table: []const color.Rgb24, background_color_index: u8) void {
        if (background_color_index >= effective_color_table.len) {
            return;
        }

        switch (current_frame.pixels) {
            .indexed1 => |pixels| @memset(pixels.indices, @intCast(background_color_index)),
            .indexed2 => |pixels| @memset(pixels.indices, @intCast(background_color_index)),
            .indexed4 => |pixels| @memset(pixels.indices, @intCast(background_color_index)),
            .indexed8 => |pixels| @memset(pixels.indices, background_color_index),
            .rgb24 => |pixels| @memset(pixels, effective_color_table[background_color_index]),
            .rgba32 => |pixels| @memset(pixels, color.Rgba32.from.u32Rgba(effective_color_table[background_color_index].to.u32Rgb())),
            else => std.debug.panic("Pixel format {s} not supported", .{@tagName(current_frame.pixels)}),
        }
    }

    fn copyFrame(source: *Image.AnimationFrame, target: *Image.AnimationFrame) void {
        switch (target.pixels) {
            .indexed1 => |pixels| @memcpy(pixels.indices, source.pixels.indexed1.indices),
            .indexed2 => |pixels| @memcpy(pixels.indices, source.pixels.indexed2.indices),
            .indexed4 => |pixels| @memcpy(pixels.indices, source.pixels.indexed4.indices),
            .indexed8 => |pixels| @memcpy(pixels.indices, source.pixels.indexed8.indices),
            .rgb24 => |pixels| @memcpy(pixels, source.pixels.rgb24),
            .rgba32 => |pixels| @memcpy(pixels, source.pixels.rgba32),
            else => std.debug.panic("Pixel format {s} not supported", .{@tagName(target.pixels)}),
        }
    }

    fn replaceWithBackground(self: *const GIF, sub_image: *const SubImage, canvas: *Image.AnimationFrame, effective_color_table: []const color.Rgb24, transparency_index_opt: ?u8) void {
        const background_color_index = if (transparency_index_opt != null) transparency_index_opt.? else self.header.background_color_index;

        for (0..sub_image.image_descriptor.height) |source_y| {
            const target_y = source_y + sub_image.image_descriptor.top_position;

            const source_stride = source_y * sub_image.image_descriptor.width;
            const target_stride = target_y * self.header.width;

            for (0..sub_image.image_descriptor.width) |source_x| {
                const target_x = source_x + sub_image.image_descriptor.left_position;

                const source_index = source_stride + source_x;
                const target_index = target_stride + target_x;

                if (source_index >= sub_image.pixels.len) {
                    continue;
                }

                switch (canvas.pixels) {
                    .indexed1 => |pixels| {
                        if (target_index >= pixels.indices.len) {
                            return;
                        }

                        pixels.indices[target_index] = @intCast(background_color_index);
                    },
                    .indexed2 => |pixels| {
                        if (target_index >= pixels.indices.len) {
                            return;
                        }

                        pixels.indices[target_index] = @intCast(background_color_index);
                    },
                    .indexed4 => |pixels| {
                        if (target_index >= pixels.indices.len) {
                            return;
                        }

                        pixels.indices[target_index] = @intCast(background_color_index);
                    },
                    .indexed8 => |pixels| {
                        if (target_index >= pixels.indices.len) {
                            return;
                        }

                        pixels.indices[target_index] = background_color_index;
                    },
                    .rgb24 => |pixels| {
                        if (target_index >= pixels.len) {
                            return;
                        }

                        if (background_color_index < effective_color_table.len) {
                            pixels[target_index] = effective_color_table[background_color_index];
                        }
                    },
                    .rgba32 => |pixels| {
                        if (target_index >= pixels.len) {
                            return;
                        }

                        if (background_color_index < effective_color_table.len) {
                            pixels[target_index] = color.Rgba32.from.u32Rgba(effective_color_table[background_color_index].to.u32Rgba());
                        }
                    },
                    else => {
                        std.debug.panic("Pixel format {s} not supported", .{@tagName(canvas.pixels)});
                    },
                }
            }
        }
    }

    fn renderSubImage(self: *const GIF, sub_image: *const SubImage, current_frame: *Image.AnimationFrame, effective_color_table: []const color.Rgb24, transparency_index_opt: ?u8) void {
        if (sub_image.image_descriptor.flags.is_interlaced) {
            var source_y: usize = 0;

            for (INTERLACE_PASSES) |pass| {
                var target_y = pass.start + sub_image.image_descriptor.top_position;

                while (target_y < self.header.height) {
                    const source_stride = source_y * sub_image.image_descriptor.width;
                    const target_stride = target_y * self.header.width;

                    for (0..sub_image.image_descriptor.width) |source_x| {
                        const target_x = source_x + sub_image.image_descriptor.left_position;

                        const source_index = source_stride + source_x;
                        const target_index = target_stride + target_x;

                        plotPixel(sub_image, current_frame, effective_color_table, transparency_index_opt, source_index, target_index);
                    }

                    target_y += pass.step;
                    source_y += 1;
                }
            }
        } else {
            for (0..sub_image.image_descriptor.height) |source_y| {
                const target_y = source_y + sub_image.image_descriptor.top_position;

                const source_stride = source_y * sub_image.image_descriptor.width;
                const target_stride = target_y * self.header.width;

                for (0..sub_image.image_descriptor.width) |source_x| {
                    const target_x = source_x + sub_image.image_descriptor.left_position;

                    const source_index = source_stride + source_x;
                    const target_index = target_stride + target_x;

                    plotPixel(sub_image, current_frame, effective_color_table, transparency_index_opt, source_index, target_index);
                }
            }
        }
    }

    fn plotPixel(sub_image: *const SubImage, current_frame: *Image.AnimationFrame, effective_color_table: []const color.Rgb24, transparency_index_opt: ?u8, source_index: usize, target_index: usize) void {
        if (source_index >= sub_image.pixels.len) {
            return;
        }

        switch (current_frame.pixels) {
            .indexed1 => |pixels| {
                if (target_index >= pixels.indices.len) {
                    return;
                }

                if (transparency_index_opt) |transparency_index| {
                    if (sub_image.pixels[source_index] == transparency_index) {
                        return;
                    }
                }

                pixels.indices[target_index] = @truncate(sub_image.pixels[source_index]);
            },
            .indexed2 => |pixels| {
                if (target_index >= pixels.indices.len) {
                    return;
                }

                if (transparency_index_opt) |transparency_index| {
                    if (sub_image.pixels[source_index] == transparency_index) {
                        return;
                    }
                }

                pixels.indices[target_index] = @truncate(sub_image.pixels[source_index]);
            },
            .indexed4 => |pixels| {
                if (target_index >= pixels.indices.len) {
                    return;
                }

                if (transparency_index_opt) |transparency_index| {
                    if (sub_image.pixels[source_index] == transparency_index) {
                        return;
                    }
                }

                pixels.indices[target_index] = @truncate(sub_image.pixels[source_index]);
            },
            .indexed8 => |pixels| {
                if (target_index >= pixels.indices.len) {
                    return;
                }

                if (transparency_index_opt) |transparency_index| {
                    if (sub_image.pixels[source_index] == transparency_index) {
                        return;
                    }
                }

                pixels.indices[target_index] = @intCast(sub_image.pixels[source_index]);
            },
            .rgb24 => |pixels| {
                if (target_index >= pixels.len) {
                    return;
                }

                if (transparency_index_opt) |transparency_index| {
                    if (sub_image.pixels[source_index] == transparency_index) {
                        return;
                    }
                }

                const pixel_index = sub_image.pixels[source_index];
                if (pixel_index < effective_color_table.len) {
                    pixels[target_index] = effective_color_table[pixel_index];
                }
            },
            .rgba32 => |pixels| {
                if (target_index >= pixels.len) {
                    return;
                }

                if (transparency_index_opt) |transparency_index| {
                    if (sub_image.pixels[source_index] == transparency_index) {
                        return;
                    }
                }

                const pixel_index = sub_image.pixels[source_index];
                if (pixel_index < effective_color_table.len) {
                    pixels[target_index] = color.Rgba32.from.u32Rgba(effective_color_table[pixel_index].to.u32Rgba());
                }
            },
            else => {
                std.debug.panic("Pixel format {s} not supported", .{@tagName(current_frame.pixels)});
            },
        }
    }

    fn allocNewFrame(self: *GIF) !*FrameData {
        const new_frame = try self.frames.addOne(self.arena_allocator.allocator());
        new_frame.* = FrameData{};
        return new_frame;
    }

    fn createNewAnimationFrame(self: *const GIF, allocator: std.mem.Allocator, pixel_format: PixelFormat) !Image.AnimationFrame {
        const new_frame = Image.AnimationFrame{
            .pixels = try color.PixelStorage.init(allocator, pixel_format, @as(usize, @intCast(self.header.width)) * @as(usize, @intCast(self.header.height))),
            .duration = 0.0,
        };

        // Set all pixels to all zeroes
        switch (new_frame.pixels) {
            .indexed1 => |pixels| @memset(pixels.indices, 0),
            .indexed2 => |pixels| @memset(pixels.indices, 0),
            .indexed4 => |pixels| @memset(pixels.indices, 0),
            .indexed8 => |pixels| @memset(pixels.indices, 0),
            .rgb24 => |pixels| @memset(pixels, color.Rgb24.from.u32Rgb(0)),
            .rgba32 => |pixels| @memset(pixels, color.Rgba32.from.u32Rgba(0)),
            else => std.debug.panic("Pixel format {} not supported", .{pixel_format}),
        }

        return new_frame;
    }

    fn findBestPixelFormat(self: *const GIF) PixelFormat {
        var total_color_count: usize = 0;

        if (self.header.flags.use_global_color_table) {
            total_color_count = @as(usize, 1) << (@as(COLOR_TABLE_SHIFT_TYPE, @intCast(self.header.flags.global_color_table_size)) + 1);
        }

        var use_transparency: bool = false;

        var max_color_per_frame: usize = 0;

        for (self.frames.items) |frame| {
            if (frame.graphics_control) |graphic_control| {
                if (graphic_control.flags.has_transparent_color) {
                    use_transparency = true;
                }
            }

            var color_per_frame: usize = 0;

            for (frame.sub_images.items) |sub_image| {
                if (sub_image.image_descriptor.flags.has_local_color_table) {
                    color_per_frame += @as(usize, 1) << (@as(COLOR_TABLE_SHIFT_TYPE, @intCast(sub_image.image_descriptor.flags.local_color_table_size)) + 1);
                }
            }

            max_color_per_frame = @max(max_color_per_frame, color_per_frame);
        }

        total_color_count += max_color_per_frame;

        // TODO: Handle indexed format with transparency
        if (total_color_count <= (1 << 1)) {
            return .indexed1;
        } else if (total_color_count <= (1 << 2)) {
            return .indexed2;
        } else if (total_color_count <= (1 << 4)) {
            return .indexed4;
        } else if (total_color_count <= (1 << 8)) {
            return .indexed8;
        }

        if (use_transparency) {
            return .rgba32;
        }

        return .rgb24;
    }

    fn writeHeader(writer: *std.Io.Writer, image: Image, pixels: *const color.PixelStorage, loop_count: i32) Image.WriteError!void {
        var header = Header{
            .magic = undefined,
            .version = undefined,
            .width = 0,
            .height = 0,
            .flags = .{},
            .background_color_index = 0,
            .pixel_aspect_ratio = 0,
        };

        @memcpy(&header.magic, MAGIC.ptr);
        @memcpy(&header.version, VERSIONS[1].ptr);

        if (image.width > std.math.maxInt(u16) or image.height > std.math.maxInt(u16)) {
            return Image.WriteError.Unsupported;
        }

        header.width = @truncate(image.width);
        header.height = @truncate(image.height);

        var palette_buffer: [3 * 256]u8 = undefined;
        var palette_byte_length: usize = 0;

        const pixel_format = std.meta.activeTag(pixels.*);
        if (pixel_format.isIndexed()) {
            if (pixels.*.getPalette()) |palette_slice| {
                if (palette_slice.len > 0) {
                    const palette_index = try paletteSizeIndex(palette_slice.len);
                    header.flags.use_global_color_table = true;
                    header.flags.global_color_table_size = @intCast(palette_index);
                    // Color resolution = bits per primary color - 1
                    // Our palettes use RGBA32 (8 bits), so color_resolution = 7
                    header.flags.color_resolution = 7;

                    const entries = paletteEntryCounts[palette_index];
                    palette_byte_length = entries * 3;
                    encodeColorTable(palette_buffer[0..palette_byte_length], palette_slice, entries);
                }
            }
        }

        try writer.writeStruct(header, .little);

        if (palette_byte_length > 0) {
            try writer.writeAll(palette_buffer[0..palette_byte_length]);
        }

        // Write loop extension if loop_count is set (for animated GIFs or explicit requests)
        // Always write if loop_count is AnimationLoopInfinite (-1) or > 0
        // Note: loop_count == 0 means no extension (single play, no loop)
        if (loop_count == Image.AnimationLoopInfinite) {
            try writeLoopExtension(writer, 0); // GIF uses 0 to represent infinite looping
        } else if (loop_count > 0) {
            if (loop_count <= @as(i32, std.math.maxInt(u16))) {
                try writeLoopExtension(writer, @intCast(loop_count));
            }
        }
    }
};

const paletteEntryCounts = [_]usize{ 2, 4, 8, 16, 32, 64, 128, 256 };

fn loopCountToExtension(loop_count: i32) Image.WriteError!?u16 {
    if (loop_count == 0) {
        // Value 0 means no extension should be written.
        return null;
    }
    if (loop_count == Image.AnimationLoopInfinite) {
        // GIF uses 0 to represent infinite looping.
        return 0;
    }
    if (loop_count < 0) {
        return Image.WriteError.Unsupported;
    }
    if (loop_count > @as(i32, std.math.maxInt(u16))) {
        return Image.WriteError.Unsupported;
    }
    const converted: u16 = @intCast(loop_count);
    return converted;
}

fn writeLoopExtension(writer: *std.Io.Writer, loop_count: u16) Image.WriteError!void {
    try writer.writeAll(&[_]u8{
        0x21, // Extension Introducer.
        0xff, // Application Label.
        0x0b, // Block Size.
    });
    try writer.writeAll("NETSCAPE2.0"); // Application Identifier.
    const loop_count_u16: u16 = loop_count;

    var block: [5]u8 = .{
        0x03, // Block Size.
        0x01, // Sub-block Index.
        @truncate(loop_count_u16 & 0xff),
        @truncate((loop_count_u16 >> 8) & 0xff),
        0x00, // Block Terminator.
    };
    try writer.writeAll(&block);
}

fn paletteSizeIndex(palette_len: usize) Image.WriteError!usize {
    for (paletteEntryCounts, 0..) |entry, idx| {
        if (palette_len <= entry) {
            return idx;
        }
    }
    return Image.WriteError.Unsupported;
}

fn encodeColorTable(dst: []u8, palette: []const color.Rgba32, entries: usize) void {
    std.debug.assert(palette.len <= entries);
    var offset: usize = 0;
    for (palette) |entry| {
        dst[offset + 0] = entry.r;
        dst[offset + 1] = entry.g;
        dst[offset + 2] = entry.b;
        offset += 3;
    }
    if (palette.len < entries) {
        @memset(dst[palette.len * 3 .. entries * 3], 0);
    }
}

/// SubBlockWriter wraps an output writer and chunks data into GIF sub-blocks.
/// Each sub-block is: [length byte (1-255)][data bytes...]
/// Terminated with a 0x00 byte.
const SubBlockWriter = struct {
    underlying: *std.Io.Writer,
    // buf[0] holds current length, buf[1..256] holds data
    buffer: [256]u8 = undefined,
    // The writer interface that uses this SubBlockWriter
    interface: std.Io.Writer = undefined,

    const Self = @This();

    const vtable: std.Io.Writer.VTable = .{
        .drain = drain,
        .flush = noopFlush,
        .rebase = std.Io.Writer.defaultRebase,
        .sendFile = std.Io.Writer.unimplementedSendFile,
    };

    pub fn init(underlying_writer: *std.Io.Writer) Self {
        var self = Self{
            .underlying = underlying_writer,
            .interface = .{
                .buffer = &.{},
                .vtable = &vtable,
            },
        };
        self.buffer[0] = 0;
        return self;
    }

    /// Write a single byte to the sub-block buffer
    fn writeByteInternal(self: *Self, byte: u8) Image.WriteError!void {
        self.buffer[0] += 1;
        self.buffer[self.buffer[0]] = byte;

        if (self.buffer[0] == 255) {
            // Buffer full - flush the block
            self.underlying.writeAll(self.buffer[0..256]) catch return Image.WriteError.WriteFailed;
            self.buffer[0] = 0;
        }
    }

    /// Finish writing - flush remaining data and write terminator
    pub fn finish(self: *Self) Image.WriteError!void {
        if (self.buffer[0] == 0) {
            // No pending data - just write terminator
            self.underlying.writeByte(0x00) catch return Image.WriteError.WriteFailed;
        } else {
            // Write pending block + terminator
            const n = self.buffer[0];
            self.buffer[n + 1] = 0x00; // terminator
            self.underlying.writeAll(self.buffer[0 .. n + 2]) catch return Image.WriteError.WriteFailed;
        }
    }

    /// Returns a pointer to the std.Io.Writer interface
    pub fn writer(self: *Self) *std.Io.Writer {
        return &self.interface;
    }

    fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        const self: *Self = @alignCast(@fieldParentPtr("interface", w));
        var total: usize = 0;

        // Handle splat byte if present
        if (splat > 0) {
            if (data.len > 0 and data[0].len > 0) {
                for (0..splat) |_| {
                    self.writeByteInternal(data[0][0]) catch {
                        return error.WriteFailed;
                    };
                    total += 1;
                }
            }
        }

        // Handle regular data slices
        const start_idx: usize = if (splat > 0) 1 else 0;
        for (data[start_idx..]) |slice| {
            for (slice) |byte| {
                self.writeByteInternal(byte) catch {
                    return error.WriteFailed;
                };
                total += 1;
            }
        }
        return total;
    }

    fn noopFlush(_: *std.Io.Writer) std.Io.Writer.Error!void {}
};

/// Write the Graphic Control Extension block
fn writeGraphicControlExtension(
    writer: *std.Io.Writer,
    delay_time_cs: u16, // delay in centiseconds (1/100th second)
    disposal: DisposeMethod,
    transparent_index: ?u8,
) Image.WriteError!void {
    var gce_block: [8]u8 = .{
        @intFromEnum(DataBlockKind.extension), // 0x21 Extension Introducer
        @intFromEnum(ExtensionKind.graphic_control), // 0xF9 Graphic Control Label
        0x04, // Block Size (always 4)
        0x00, // Flags (will be set below)
        0x00, // Delay time low byte
        0x00, // Delay time high byte
        0x00, // Transparent color index
        0x00, // Block Terminator
    };

    // Build flags byte
    var flags: u8 = @as(u8, @intFromEnum(disposal)) << 2;
    if (transparent_index != null) {
        flags |= 0x01; // has_transparent_color
    }
    gce_block[3] = flags;

    // Delay time (little-endian)
    gce_block[4] = @truncate(delay_time_cs & 0xff);
    gce_block[5] = @truncate((delay_time_cs >> 8) & 0xff);

    // Transparent index
    if (transparent_index) |idx| {
        gce_block[6] = idx;
    }

    writer.writeAll(&gce_block) catch return Image.WriteError.WriteFailed;
}

/// Check if local palette matches global palette (can skip local color table)
fn palettesMatch(local: []const color.Rgba32, global: ?[]const color.Rgba32, transparent_index: ?u8) bool {
    const global_palette = global orelse return false;

    // Local palette must not be longer than global
    if (local.len > global_palette.len) return false;

    // Compare colors
    for (local, 0..) |local_color, i| {
        if (transparent_index != null and i == transparent_index.?) {
            continue; // Skip transparent color comparison
        }
        const global_color = global_palette[i];
        if (local_color.r != global_color.r or
            local_color.g != global_color.g or
            local_color.b != global_color.b)
        {
            return false;
        }
    }
    return true;
}

/// Write a single image block (frame)
fn writeImageBlock(
    allocator: std.mem.Allocator,
    writer: *std.Io.Writer,
    pixels: *const color.PixelStorage,
    width: u16,
    height: u16,
    left: u16,
    top: u16,
    delay_time_cs: u16,
    disposal: DisposeMethod,
    global_palette: ?[]const color.Rgba32,
    frame_transparent_index: ?u8,
) Image.WriteError!void {
    const palette = pixels.getPalette() orelse return Image.WriteError.Unsupported;
    if (palette.len == 0) {
        return Image.WriteError.Unsupported;
    }

    // GIF only supports up to 256 colors
    if (palette.len > 256) {
        return Image.WriteError.Unsupported;
    }

    // Use frame's transparent index if provided, otherwise detect from palette
    const transparent_index: ?u8 = if (frame_transparent_index != null) frame_transparent_index else blk: {
        for (palette, 0..) |c, i| {
            if (c.a == 0) {
                break :blk @intCast(i);
            }
        }
        break :blk null;
    };

    // Write Graphic Control Extension if needed
    if (delay_time_cs > 0 or disposal != .none or transparent_index != null) {
        try writeGraphicControlExtension(writer, delay_time_cs, disposal, transparent_index);
    }

    // Write Image Descriptor
    const palette_size_idx = try paletteSizeIndex(palette.len);

    // Check if we can use global color table (skip local)
    const use_global = palettesMatch(palette, global_palette, transparent_index);

    var descriptor: [10]u8 = .{
        @intFromEnum(DataBlockKind.image_descriptor), // 0x2C
        @truncate(left & 0xff),
        @truncate((left >> 8) & 0xff),
        @truncate(top & 0xff),
        @truncate((top >> 8) & 0xff),
        @truncate(width & 0xff),
        @truncate((width >> 8) & 0xff),
        @truncate(height & 0xff),
        @truncate((height >> 8) & 0xff),
        0x00, // Flags - will be set below
    };

    if (use_global) {
        // Use global color table (no local)
        descriptor[9] = 0x00;
    } else {
        // Use local color table
        descriptor[9] = 0x80 | @as(u8, @intCast(palette_size_idx));
    }

    writer.writeAll(&descriptor) catch return Image.WriteError.WriteFailed;

    // Write local color table only if not using global
    if (!use_global) {
        const entries = paletteEntryCounts[palette_size_idx];
        var color_table_buf: [3 * 256]u8 = undefined;
        encodeColorTable(color_table_buf[0 .. entries * 3], palette, entries);
        writer.writeAll(color_table_buf[0 .. entries * 3]) catch return Image.WriteError.WriteFailed;
    }

    // Calculate LZW minimum code size
    var lit_width: u4 = @intCast(palette_size_idx + 1);
    if (lit_width < 2) {
        lit_width = 2; // Minimum is 2 for GIF
    }

    // Write LZW Minimum Code Size
    writer.writeByte(lit_width) catch return Image.WriteError.WriteFailed;

    // Get pixel indices as u8 slice - handle all indexed formats
    const pixel_count = @as(usize, width) * @as(usize, height);
    var allocated_indices: ?[]u8 = null;
    defer if (allocated_indices) |buffer| allocator.free(buffer);

    const indices: []const u8 = switch (pixels.*) {
        .indexed1 => |data| blk: {
            const buffer = allocator.alloc(u8, pixel_count) catch return Image.WriteError.OutOfMemory;
            allocated_indices = buffer;
            for (0..pixel_count) |i| {
                buffer[i] = data.indices[i];
            }
            break :blk buffer;
        },
        .indexed2 => |data| blk: {
            const buf = allocator.alloc(u8, pixel_count) catch return Image.WriteError.OutOfMemory;
            allocated_indices = buf;
            for (0..pixel_count) |i| {
                buf[i] = data.indices[i];
            }
            break :blk buf;
        },
        .indexed4 => |data| blk: {
            const buffer = allocator.alloc(u8, pixel_count) catch return Image.WriteError.OutOfMemory;
            allocated_indices = buffer;
            for (0..pixel_count) |i| {
                buffer[i] = data.indices[i];
            }
            break :blk buffer;
        },
        .indexed8 => |data| data.indices,
        .indexed16 => |data| blk: {
            // Verify all indices fit in u8
            for (data.indices) |idx| {
                if (idx > 255) {
                    return Image.WriteError.Unsupported;
                }
            }
            const buffer = allocator.alloc(u8, pixel_count) catch return Image.WriteError.OutOfMemory;
            allocated_indices = buffer;
            for (0..pixel_count) |i| {
                buffer[i] = @intCast(data.indices[i]);
            }
            break :blk buffer;
        },
        else => return Image.WriteError.Unsupported,
    };

    // Create sub-block writer for chunking LZW output
    var sub_block_writer = SubBlockWriter.init(writer);

    // Get a streaming writer interface that writes through sub-blocks
    const lzw_writer = sub_block_writer.writer();

    var encoder = lzw.Encoder(.little).init(lit_width) catch return Image.WriteError.Unsupported;

    // Encode pixel data - streams directly through sub-block writer
    encoder.encode(lzw_writer, indices) catch return Image.WriteError.WriteFailed;
    encoder.finish(lzw_writer) catch return Image.WriteError.WriteFailed;

    // Finish writing sub-blocks (flush remaining data + terminator)
    try sub_block_writer.finish();
}

/// Write the GIF trailer
fn writeTrailer(writer: *std.Io.Writer) Image.WriteError!void {
    writer.writeByte(@intFromEnum(DataBlockKind.end_of_file)) catch return Image.WriteError.WriteFailed;
}
