const std = @import("std");
const math = @import("math.zig");
const Allocator = std.mem.Allocator;
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const TypeInfo = std.builtin.TypeInfo;

pub inline fn toIntColor(comptime T: type, value: f32) T {
    const float_value = @round(value * @as(f32, @floatFromInt(std.math.maxInt(T))));
    return @as(T, @intFromFloat(std.math.clamp(float_value, std.math.minInt(T), std.math.maxInt(T))));
}

pub inline fn scaleToIntColor(comptime T: type, value: anytype) T {
    const ValueT = @TypeOf(value);
    if (ValueT == comptime_int) return @as(T, value);
    const ValueTypeInfo = @typeInfo(ValueT);
    if (ValueTypeInfo != .int or ValueTypeInfo.int.signedness != .unsigned) {
        @compileError("scaleToInColor only accepts unsigned integers as values. Got " ++ @typeName(ValueT) ++ ".");
    }
    const cur_value_bits = @bitSizeOf(ValueT);
    const new_value_bits = @bitSizeOf(T);
    if (cur_value_bits > new_value_bits) {
        return @as(T, @truncate(value >> (cur_value_bits - new_value_bits)));
    } else if (cur_value_bits < new_value_bits) {
        const cur_value_max = std.math.maxInt(ValueT);
        const new_value_max = std.math.maxInt(T);
        return @as(T, @truncate((@as(u32, value) * new_value_max + cur_value_max / 2) / cur_value_max));
    } else return @as(T, value);
}

pub inline fn toF32Color(value: anytype) f32 {
    return @as(f32, @floatFromInt(value)) / @as(f32, @floatFromInt(std.math.maxInt(@TypeOf(value))));
}

pub const Colorf32 = extern struct {
    r: f32 align(1) = 0.0,
    g: f32 align(1) = 0.0,
    b: f32 align(1) = 0.0,
    a: f32 align(1) = 1.0,

    pub fn initRgb(r: f32, g: f32, b: f32) Colorf32 {
        return .{
            .r = r,
            .g = g,
            .b = b,
        };
    }

    pub fn initRgba(r: f32, g: f32, b: f32, a: f32) Colorf32 {
        return .{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }

    pub fn fromU32Rgba(value: u32) Colorf32 {
        return .{
            .r = toF32Color(@as(u8, @truncate(value >> 24))),
            .g = toF32Color(@as(u8, @truncate(value >> 16))),
            .b = toF32Color(@as(u8, @truncate(value >> 8))),
            .a = toF32Color(@as(u8, @truncate(value))),
        };
    }

    pub fn toU32Rgba(self: Colorf32) u32 {
        return @as(u32, toIntColor(u8, self.r)) << 24 |
            @as(u32, toIntColor(u8, self.g)) << 16 |
            @as(u32, toIntColor(u8, self.b)) << 8 |
            @as(u32, toIntColor(u8, self.a));
    }

    pub fn fromU64Rgba(value: u64) Colorf32 {
        return .{
            .r = toF32Color(@as(u16, @truncate(value >> 48))),
            .g = toF32Color(@as(u16, @truncate(value >> 32))),
            .b = toF32Color(@as(u16, @truncate(value >> 16))),
            .a = toF32Color(@as(u16, @truncate(value))),
        };
    }

    pub fn toU64Rgba(self: Colorf32) u64 {
        return @as(u64, toIntColor(u16, self.r)) << 48 |
            @as(u64, toIntColor(u16, self.g)) << 32 |
            @as(u64, toIntColor(u16, self.b)) << 16 |
            @as(u64, toIntColor(u16, self.a));
    }

    pub fn toPremultipliedAlpha(self: Colorf32) Colorf32 {
        return .{
            .r = self.r * self.a,
            .g = self.g * self.a,
            .b = self.b * self.a,
            .a = self.a,
        };
    }

    pub fn toRgba(self: Colorf32, comptime T: type) RgbaColor(T) {
        return .{
            .r = toIntColor(T, self.r),
            .g = toIntColor(T, self.g),
            .b = toIntColor(T, self.b),
            .a = toIntColor(T, self.a),
        };
    }

    pub fn toRgba32(self: Colorf32) Rgba32 {
        return self.toRgba(u8);
    }

    pub fn toRgba64(self: Colorf32) Rgba64 {
        return self.toRgba(u16);
    }

    pub inline fn fromArray(value: [4]f32) Colorf32 {
        return @bitCast(value);
    }

    pub inline fn toArray(self: Colorf32) [4]f32 {
        return @bitCast(self);
    }

    pub inline fn fromFloat4(value: math.float4) Colorf32 {
        return @bitCast(value);
    }

    pub inline fn toFloat4(self: Colorf32) math.float4 {
        return @bitCast(self);
    }
};

fn isAll8BitColor(comptime red_type: type, comptime green_type: type, comptime blue_type: type, comptime alpha_type: type) bool {
    return red_type == u8 and green_type == u8 and blue_type == u8 and (alpha_type == u8 or alpha_type == void);
}

// FIXME: Workaround for https://github.com/zigimg/zigimg/issues/101, before it was only passed Self and getting RedT, GreenT, BlueT and AlphaT from Self fields.
fn RgbMethods(
    comptime Self: type,
    comptime RedT: type,
    comptime GreenT: type,
    comptime BlueT: type,
    comptime AlphaT: type,
) type {
    const has_alpha_type = @hasField(Self, "a");

    return struct {
        pub fn initRgb(r: RedT, g: GreenT, b: BlueT) Self {
            return Self{
                .r = r,
                .g = g,
                .b = b,
            };
        }

        pub fn toColorf32(self: Self) Colorf32 {
            return Colorf32{
                .r = toF32Color(self.r),
                .g = toF32Color(self.g),
                .b = toF32Color(self.b),
                .a = if (has_alpha_type) toF32Color(self.a) else 1.0,
            };
        }

        pub fn fromU32Rgba(value: u32) Self {
            var res = Self{
                .r = scaleToIntColor(RedT, @as(u8, @truncate(value >> 24))),
                .g = scaleToIntColor(GreenT, @as(u8, @truncate(value >> 16))),
                .b = scaleToIntColor(BlueT, @as(u8, @truncate(value >> 8))),
            };
            if (has_alpha_type) {
                res.a = scaleToIntColor(AlphaT, @as(u8, @truncate(value)));
            }
            return res;
        }

        pub fn fromU32Rgb(value: u32) Self {
            return Self{
                .r = scaleToIntColor(RedT, @as(u8, @truncate(value >> 16))),
                .g = scaleToIntColor(GreenT, @as(u8, @truncate(value >> 8))),
                .b = scaleToIntColor(BlueT, @as(u8, @truncate(value))),
            };
        }

        pub fn fromU64Rgba(value: u64) Self {
            var res = Self{
                .r = scaleToIntColor(RedT, @as(u16, @truncate(value >> 48))),
                .g = scaleToIntColor(GreenT, @as(u16, @truncate(value >> 32))),
                .b = scaleToIntColor(BlueT, @as(u16, @truncate(value >> 16))),
            };
            if (has_alpha_type) {
                res.a = scaleToIntColor(AlphaT, @as(u16, @truncate(value)));
            }
            return res;
        }

        pub fn fromU64Rgb(value: u64) Self {
            return Self{
                .r = scaleToIntColor(RedT, @as(u16, @truncate(value >> 32))),
                .g = scaleToIntColor(GreenT, @as(u16, @truncate(value >> 16))),
                .b = scaleToIntColor(BlueT, @as(u16, @truncate(value))),
            };
        }

        // Only enable fromHtmlHex when all color component type are u8
        pub usingnamespace if (isAll8BitColor(RedT, GreenT, BlueT, AlphaT))
            struct {
                pub fn fromHtmlHex(hex_string: []const u8) !Self {
                    if (hex_string.len == 0) {
                        return error.InvalidHtmlHexString;
                    }

                    if (hex_string[0] != '#') {
                        return error.InvalidHtmlHexString;
                    }

                    if (has_alpha_type) {
                        if (hex_string.len != 4 and hex_string.len != 7 and hex_string.len != 5 and hex_string.len != 9) {
                            return error.InvalidHtmlHexString;
                        }
                    } else {
                        if (hex_string.len != 4 and hex_string.len != 7) {
                            return error.InvalidHtmlHexString;
                        }
                    }

                    if (hex_string.len == 7) {
                        var storage: [3]u8 = undefined;
                        const output = std.fmt.hexToBytes(storage[0..], hex_string[1..]) catch {
                            return error.InvalidHtmlHexString;
                        };

                        return Self{
                            .r = output[0],
                            .g = output[1],
                            .b = output[2],
                        };
                    } else if (has_alpha_type and hex_string.len == 9) {
                        var storage: [4]u8 = undefined;
                        const output = std.fmt.hexToBytes(storage[0..], hex_string[1..]) catch {
                            return error.InvalidHtmlHexString;
                        };

                        return Self{
                            .r = output[0],
                            .g = output[1],
                            .b = output[2],
                            .a = output[3],
                        };
                    } else if (hex_string.len == 4) {
                        const red_digit = std.fmt.charToDigit(hex_string[1], 16) catch {
                            return error.InvalidHtmlHexString;
                        };
                        const green_digit = std.fmt.charToDigit(hex_string[2], 16) catch {
                            return error.InvalidHtmlHexString;
                        };
                        const blue_digit = std.fmt.charToDigit(hex_string[3], 16) catch {
                            return error.InvalidHtmlHexString;
                        };

                        return Self{
                            .r = red_digit | (red_digit << 4),
                            .g = green_digit | (green_digit << 4),
                            .b = blue_digit | (blue_digit << 4),
                        };
                    } else if (has_alpha_type and hex_string.len == 5) {
                        const red_digit = std.fmt.charToDigit(hex_string[1], 16) catch {
                            return error.InvalidHtmlHexString;
                        };
                        const green_digit = std.fmt.charToDigit(hex_string[2], 16) catch {
                            return error.InvalidHtmlHexString;
                        };
                        const blue_digit = std.fmt.charToDigit(hex_string[3], 16) catch {
                            return error.InvalidHtmlHexString;
                        };
                        const alpha_digit = std.fmt.charToDigit(hex_string[4], 16) catch {
                            return error.InvalidHtmlHexString;
                        };

                        return Self{
                            .r = red_digit | (red_digit << 4),
                            .g = green_digit | (green_digit << 4),
                            .b = blue_digit | (blue_digit << 4),
                            .a = alpha_digit | (alpha_digit << 4),
                        };
                    } else {
                        return error.InvalidHtmlHexString;
                    }
                }
            }
        else
            struct {};

        pub fn toU32Rgba(self: Self) u32 {
            return @as(u32, scaleToIntColor(u8, self.r)) << 24 |
                @as(u32, scaleToIntColor(u8, self.g)) << 16 |
                @as(u32, scaleToIntColor(u8, self.b)) << 8 |
                if (@hasField(Self, "a")) scaleToIntColor(u8, self.a) else 0xff;
        }

        pub fn toU32Rgb(self: Self) u32 {
            return @as(u32, scaleToIntColor(u8, self.r)) << 16 |
                @as(u32, scaleToIntColor(u8, self.g)) << 8 |
                scaleToIntColor(u8, self.b);
        }

        pub fn toU64Rgba(self: Self) u64 {
            return @as(u64, scaleToIntColor(u16, self.r)) << 48 |
                @as(u64, scaleToIntColor(u16, self.g)) << 32 |
                @as(u64, scaleToIntColor(u16, self.b)) << 16 |
                if (@hasField(Self, "a")) scaleToIntColor(u16, self.a) else 0xffff;
        }

        pub fn toU64Rgb(self: Self) u64 {
            return @as(u64, scaleToIntColor(u16, self.r)) << 32 |
                @as(u64, scaleToIntColor(u16, self.g)) << 16 |
                scaleToIntColor(u16, self.b);
        }
    };
}

fn RgbaMethods(comptime Self: type) type {
    return struct {
        const T = std.meta.fieldInfo(Self, .r).type;
        const comp_bits = @typeInfo(T).Int.bits;

        pub fn initRgba(r: T, g: T, b: T, a: T) Self {
            return Self{
                .r = r,
                .g = g,
                .b = b,
                .a = a,
            };
        }

        pub fn toPremultipliedAlpha(self: Self) Self {
            const max = std.math.maxInt(T);
            return Self{
                .r = @as(T, @truncate((@as(u32, self.r) * self.a + max / 2) / max)),
                .g = @as(T, @truncate((@as(u32, self.g) * self.a + max / 2) / max)),
                .b = @as(T, @truncate((@as(u32, self.b) * self.a + max / 2) / max)),
                .a = self.a,
            };
        }
    };
}

fn RgbColor(comptime T: type) type {
    return extern struct {
        r: T align(1),
        g: T align(1),
        b: T align(1),

        pub usingnamespace RgbMethods(@This(), T, T, T, void);
    };
}

// NOTE: For all the packed structs colors, the order of color is reversed
// because the least significant part of the struct needs to be first, as per packed struct rules.
// Also little endian is assumed for those formats.

// Bgr555
// OpenGL: n/a
// Vulkan: VK_FORMAT_B5G5R5A1_UNORM_PACK16
// Direct3D/DXGI: n/a
pub const Bgr555 = packed struct {
    r: u5 = 0,
    g: u5 = 0,
    b: u5 = 0,

    pub usingnamespace RgbMethods(@This(), u5, u5, u5, void);
};

// Rgb332
// OpenGL: GL_R3_G3_B2
// Vulkan: n/a
// Direct3D/DXGI: n/a
pub const Rgb332 = packed struct {
    r: u3,
    g: u3,
    b: u2,

    pub usingnamespace RgbMethods(@This(), u3, u3, u2, void);
};

// Rgb555
// OpenGL: GL_RGB5
// Vulkan: VK_FORMAT_R5G5B5A1_UNORM_PACK16
// Direct3D/DXGI: n/a
pub const Rgb555 = packed struct {
    b: u5,
    g: u5,
    r: u5,

    pub usingnamespace RgbMethods(@This(), u5, u5, u5, void);
};

// Rgb565
// OpenGL: n/a
// Vulkan: VK_FORMAT_R5G6B5_UNORM_PACK16
// Direct3D/DXGI: n/a
pub const Rgb565 = packed struct {
    b: u5,
    g: u6,
    r: u5,

    pub usingnamespace RgbMethods(@This(), u5, u6, u5, void);
};

fn RgbaColor(comptime T: type) type {
    return extern struct {
        r: T align(1),
        g: T align(1),
        b: T align(1),
        a: T align(1) = std.math.maxInt(T),

        pub usingnamespace RgbMethods(@This(), T, T, T, T);
        pub usingnamespace RgbaMethods(@This());
    };
}

// Rgb24
// OpenGL: GL_RGB
// Vulkan: VK_FORMAT_R8G8B8_UNORM
// Direct3D/DXGI: n/a
pub const Rgb24 = RgbColor(u8);

// Rgba32
// OpenGL: GL_RGBA
// Vulkan: VK_FORMAT_R8G8B8A8_UNORM
// Direct3D/DXGI: DXGI_FORMAT_R8G8B8A8_UNORM
pub const Rgba32 = RgbaColor(u8);

// Rgb48
// OpenGL: GL_RGB16
// Vulkan: VK_FORMAT_R16G16B16_UNORM
// Direct3D/DXGI: n/a
pub const Rgb48 = RgbColor(u16);

// Rgba64
// OpenGL: GL_RGBA16
// Vulkan: VK_FORMAT_R16G16B16A16_UNORM
// Direct3D/DXGI: DXGI_FORMAT_R16G16B16A16_UNORM
pub const Rgba64 = RgbaColor(u16);

fn BgrColor(comptime T: type) type {
    return extern struct {
        b: T align(1),
        g: T align(1),
        r: T align(1),

        pub usingnamespace RgbMethods(@This(), T, T, T, void);
    };
}

fn BgraColor(comptime T: type) type {
    return extern struct {
        b: T align(1),
        g: T align(1),
        r: T align(1),
        a: T = std.math.maxInt(T),

        pub usingnamespace RgbMethods(@This(), T, T, T, T);
        pub usingnamespace RgbaMethods(@This());
    };
}

// Bgr24
// OpenGL: GL_BGR
// Vulkan: VK_FORMAT_B8G8R8_UNORM
// Direct3D/DXGI: n/a
pub const Bgr24 = BgrColor(u8);

// Bgra32
// OpenGL: GL_BGRA
// Vulkan: VK_FORMAT_B8G8R8A8_UNORM
// Direct3D/DXGI: DXGI_FORMAT_B8G8R8A8_UNORM
pub const Bgra32 = BgraColor(u8);

pub fn IndexedStorage(comptime T: type) type {
    return struct {
        palette: []Rgba32,
        indices: []T,

        pub const PaletteSize = 1 << @bitSizeOf(T);

        const Self = @This();

        pub fn init(allocator: Allocator, pixel_count: usize) !Self {
            return initPaletteSize(allocator, pixel_count, PaletteSize);
        }

        pub fn initPaletteSize(allocator: Allocator, pixel_count: usize, palette_size: usize) !Self {
            std.debug.assert(palette_size <= PaletteSize);

            // Allocate the full capacity of the palette but reduce its length to the requested size
            var result = Self{
                .indices = try allocator.alloc(T, pixel_count),
                .palette = try allocator.alloc(Rgba32, PaletteSize),
            };

            result.palette.len = palette_size;

            // Palette is filled with a opaque black by default. Having palette not use
            // alpha is a good heuristic for indexed PNG to not add the transparency chunk.
            @memset(result.palette, Rgba32.initRgba(0, 0, 0, 255));
            return result;
        }

        pub fn deinit(self: Self, allocator: Allocator) void {
            var full_palette = self.palette;
            full_palette.len = PaletteSize;
            allocator.free(full_palette);
            allocator.free(self.indices);
        }

        pub fn resizePalette(self: *Self, new_palette_size: usize) void {
            std.debug.assert(new_palette_size <= PaletteSize);
            self.palette.len = new_palette_size;
        }
    };
}

pub const IndexedStorage1 = IndexedStorage(u1);
pub const IndexedStorage2 = IndexedStorage(u2);
pub const IndexedStorage4 = IndexedStorage(u4);
pub const IndexedStorage8 = IndexedStorage(u8);
pub const IndexedStorage16 = IndexedStorage(u16);

pub fn Grayscale(comptime T: type) type {
    return struct {
        value: T,

        const Self = @This();

        pub fn toColorf32(self: Self) Colorf32 {
            const gray = toF32Color(self.value);
            return Colorf32{
                .r = gray,
                .g = gray,
                .b = gray,
                .a = 1.0,
            };
        }
    };
}

pub fn GrayscaleAlpha(comptime T: type) type {
    return struct {
        value: T,
        alpha: T = std.math.maxInt(T),

        const Self = @This();

        pub fn toColorf32(self: Self) Colorf32 {
            const gray = toF32Color(self.value);
            return Colorf32{
                .r = gray,
                .g = gray,
                .b = gray,
                .a = toF32Color(self.alpha),
            };
        }
    };
}

pub const Grayscale1 = Grayscale(u1);
pub const Grayscale2 = Grayscale(u2);
pub const Grayscale4 = Grayscale(u4);
pub const Grayscale8 = Grayscale(u8);
pub const Grayscale16 = Grayscale(u16);
pub const Grayscale8Alpha = GrayscaleAlpha(u8);
pub const Grayscale16Alpha = GrayscaleAlpha(u16);

pub const PixelStorage = union(PixelFormat) {
    invalid: void,
    indexed1: IndexedStorage1,
    indexed2: IndexedStorage2,
    indexed4: IndexedStorage4,
    indexed8: IndexedStorage8,
    indexed16: IndexedStorage16,
    grayscale1: []Grayscale1,
    grayscale2: []Grayscale2,
    grayscale4: []Grayscale4,
    grayscale8: []Grayscale8,
    grayscale16: []Grayscale16,
    grayscale8Alpha: []Grayscale8Alpha,
    grayscale16Alpha: []Grayscale16Alpha,
    rgb332: []Rgb332,
    rgb555: []Rgb555,
    rgb565: []Rgb565,
    rgb24: []Rgb24,
    rgba32: []Rgba32,
    bgr555: []Bgr555,
    bgr24: []Bgr24,
    bgra32: []Bgra32,
    rgb48: []Rgb48,
    rgba64: []Rgba64,
    float32: []Colorf32,

    pub fn init(allocator: Allocator, format: PixelFormat, pixel_count: usize) !PixelStorage {
        return switch (format) {
            .invalid => {
                return .{
                    .invalid = void{},
                };
            },
            .indexed1 => {
                return .{
                    .indexed1 = try IndexedStorage(u1).init(allocator, pixel_count),
                };
            },
            .indexed2 => {
                return .{
                    .indexed2 = try IndexedStorage(u2).init(allocator, pixel_count),
                };
            },
            .indexed4 => {
                return .{
                    .indexed4 = try IndexedStorage(u4).init(allocator, pixel_count),
                };
            },
            .indexed8 => {
                return .{
                    .indexed8 = try IndexedStorage(u8).init(allocator, pixel_count),
                };
            },
            .indexed16 => {
                return .{
                    .indexed16 = try IndexedStorage(u16).init(allocator, pixel_count),
                };
            },
            .grayscale1 => {
                return .{
                    .grayscale1 = try allocator.alloc(Grayscale1, pixel_count),
                };
            },
            .grayscale2 => {
                return .{
                    .grayscale2 = try allocator.alloc(Grayscale2, pixel_count),
                };
            },
            .grayscale4 => {
                return .{
                    .grayscale4 = try allocator.alloc(Grayscale4, pixel_count),
                };
            },
            .grayscale8 => {
                return .{
                    .grayscale8 = try allocator.alloc(Grayscale8, pixel_count),
                };
            },
            .grayscale8Alpha => {
                return .{
                    .grayscale8Alpha = try allocator.alloc(Grayscale8Alpha, pixel_count),
                };
            },
            .grayscale16 => {
                return .{
                    .grayscale16 = try allocator.alloc(Grayscale16, pixel_count),
                };
            },
            .grayscale16Alpha => {
                return .{
                    .grayscale16Alpha = try allocator.alloc(Grayscale16Alpha, pixel_count),
                };
            },
            .rgb24 => {
                return .{
                    .rgb24 = try allocator.alloc(Rgb24, pixel_count),
                };
            },
            .rgba32 => {
                return .{
                    .rgba32 = try allocator.alloc(Rgba32, pixel_count),
                };
            },
            .rgb332 => {
                return .{
                    .rgb332 = try allocator.alloc(Rgb332, pixel_count),
                };
            },
            .rgb565 => {
                return .{
                    .rgb565 = try allocator.alloc(Rgb565, pixel_count),
                };
            },
            .rgb555 => {
                return .{
                    .rgb555 = try allocator.alloc(Rgb555, pixel_count),
                };
            },
            .bgr555 => {
                return .{
                    .bgr555 = try allocator.alloc(Bgr555, pixel_count),
                };
            },
            .bgr24 => {
                return .{
                    .bgr24 = try allocator.alloc(Bgr24, pixel_count),
                };
            },
            .bgra32 => {
                return .{
                    .bgra32 = try allocator.alloc(Bgra32, pixel_count),
                };
            },
            .rgb48 => {
                return .{
                    .rgb48 = try allocator.alloc(Rgb48, pixel_count),
                };
            },
            .rgba64 => {
                return .{
                    .rgba64 = try allocator.alloc(Rgba64, pixel_count),
                };
            },
            .float32 => {
                return .{
                    .float32 = try allocator.alloc(Colorf32, pixel_count),
                };
            },
        };
    }

    pub fn initRawPixels(pixels: []const u8, pixel_format: PixelFormat) !PixelStorage {
        return switch (pixel_format) {
            .grayscale1 => {
                return .{
                    .grayscale1 = @constCast(std.mem.bytesAsSlice(Grayscale1, pixels)),
                };
            },
            .grayscale2 => {
                return .{
                    .grayscale2 = @constCast(std.mem.bytesAsSlice(Grayscale2, pixels)),
                };
            },
            .grayscale4 => {
                return .{
                    .grayscale4 = @constCast(std.mem.bytesAsSlice(Grayscale4, pixels)),
                };
            },
            .grayscale8 => {
                return .{
                    .grayscale8 = @constCast(std.mem.bytesAsSlice(Grayscale8, pixels)),
                };
            },
            .grayscale8Alpha => {
                return .{
                    .grayscale8Alpha = @constCast(std.mem.bytesAsSlice(Grayscale8Alpha, pixels)),
                };
            },
            .grayscale16Alpha => {
                return .{
                    .grayscale16Alpha = @constCast(@alignCast(std.mem.bytesAsSlice(Grayscale16Alpha, pixels))),
                };
            },
            .rgb332 => {
                return .{
                    .rgb332 = @constCast(std.mem.bytesAsSlice(Rgb332, pixels)),
                };
            },
            .rgb555 => {
                return .{
                    .rgb555 = @constCast(@alignCast(std.mem.bytesAsSlice(Rgb555, pixels))),
                };
            },
            .rgb565 => {
                return .{
                    .rgb565 = @constCast(@alignCast(std.mem.bytesAsSlice(Rgb565, pixels))),
                };
            },
            .rgb24 => {
                return .{
                    .rgb24 = @constCast(std.mem.bytesAsSlice(Rgb24, pixels)),
                };
            },
            .rgba32 => {
                return .{
                    .rgba32 = @constCast(std.mem.bytesAsSlice(Rgba32, pixels)),
                };
            },
            .bgr555 => {
                return .{
                    .bgr555 = @constCast(@alignCast(std.mem.bytesAsSlice(Bgr555, pixels))),
                };
            },
            .bgr24 => {
                return .{
                    .bgr24 = @constCast(std.mem.bytesAsSlice(Bgr24, pixels)),
                };
            },
            .bgra32 => {
                return .{
                    .bgra32 = @constCast(std.mem.bytesAsSlice(Bgra32, pixels)),
                };
            },
            .rgb48 => {
                return .{
                    .rgb48 = @constCast(std.mem.bytesAsSlice(Rgb48, pixels)),
                };
            },
            .rgba64 => {
                return .{
                    .rgba64 = @constCast(std.mem.bytesAsSlice(Rgba64, pixels)),
                };
            },
            .float32 => {
                return .{
                    .float32 = @constCast(std.mem.bytesAsSlice(Colorf32, pixels)),
                };
            },
            else => error.Unsupported,
        };
    }

    pub fn deinit(self: PixelStorage, allocator: Allocator) void {
        switch (self) {
            .invalid => {},
            .indexed1 => |data| data.deinit(allocator),
            .indexed2 => |data| data.deinit(allocator),
            .indexed4 => |data| data.deinit(allocator),
            .indexed8 => |data| data.deinit(allocator),
            .indexed16 => |data| data.deinit(allocator),
            .grayscale1 => |data| allocator.free(data),
            .grayscale2 => |data| allocator.free(data),
            .grayscale4 => |data| allocator.free(data),
            .grayscale8 => |data| allocator.free(data),
            .grayscale8Alpha => |data| allocator.free(data),
            .grayscale16 => |data| allocator.free(data),
            .grayscale16Alpha => |data| allocator.free(data),
            .rgb24 => |data| allocator.free(data),
            .rgba32 => |data| allocator.free(data),
            .rgb332 => |data| allocator.free(data),
            .rgb565 => |data| allocator.free(data),
            .rgb555 => |data| allocator.free(data),
            .bgr555 => |data| allocator.free(data),
            .bgr24 => |data| allocator.free(data),
            .bgra32 => |data| allocator.free(data),
            .rgb48 => |data| allocator.free(data),
            .rgba64 => |data| allocator.free(data),
            .float32 => |data| allocator.free(data),
        }
    }

    pub fn len(self: PixelStorage) usize {
        return switch (self) {
            .invalid => 0,
            .indexed1 => |data| data.indices.len,
            .indexed2 => |data| data.indices.len,
            .indexed4 => |data| data.indices.len,
            .indexed8 => |data| data.indices.len,
            .indexed16 => |data| data.indices.len,
            .grayscale1 => |data| data.len,
            .grayscale2 => |data| data.len,
            .grayscale4 => |data| data.len,
            .grayscale8 => |data| data.len,
            .grayscale8Alpha => |data| data.len,
            .grayscale16 => |data| data.len,
            .grayscale16Alpha => |data| data.len,
            .rgb24 => |data| data.len,
            .rgba32 => |data| data.len,
            .rgb332 => |data| data.len,
            .rgb565 => |data| data.len,
            .rgb555 => |data| data.len,
            .bgr555 => |data| data.len,
            .bgr24 => |data| data.len,
            .bgra32 => |data| data.len,
            .rgb48 => |data| data.len,
            .rgba64 => |data| data.len,
            .float32 => |data| data.len,
        };
    }

    pub fn isIndexed(self: PixelStorage) bool {
        return switch (self) {
            .indexed1 => true,
            .indexed2 => true,
            .indexed4 => true,
            .indexed8 => true,
            .indexed16 => true,
            else => false,
        };
    }

    pub fn getPalette(self: PixelStorage) ?[]Rgba32 {
        return switch (self) {
            .indexed1 => |data| data.palette,
            .indexed2 => |data| data.palette,
            .indexed4 => |data| data.palette,
            .indexed8 => |data| data.palette,
            .indexed16 => |data| data.palette,
            else => null,
        };
    }

    pub fn resizePalette(self: *PixelStorage, new_palette_size: usize) void {
        switch (self.*) {
            .indexed1 => |*data| data.resizePalette(new_palette_size),
            .indexed2 => |*data| data.resizePalette(new_palette_size),
            .indexed4 => |*data| data.resizePalette(new_palette_size),
            .indexed8 => |*data| data.resizePalette(new_palette_size),
            .indexed16 => |*data| data.resizePalette(new_palette_size),
            else => {},
        }
    }

    /// Return the pixel data as a const byte slice
    pub fn asBytes(self: PixelStorage) []u8 {
        return switch (self) {
            .invalid => &[_]u8{},
            .indexed1 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed2 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed4 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed8 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed16 => |data| std.mem.sliceAsBytes(data.indices),
            .grayscale1 => |data| std.mem.sliceAsBytes(data),
            .grayscale2 => |data| std.mem.sliceAsBytes(data),
            .grayscale4 => |data| std.mem.sliceAsBytes(data),
            .grayscale8 => |data| std.mem.sliceAsBytes(data),
            .grayscale8Alpha => |data| std.mem.sliceAsBytes(data),
            .grayscale16 => |data| std.mem.sliceAsBytes(data),
            .grayscale16Alpha => |data| std.mem.sliceAsBytes(data),
            .rgb24 => |data| std.mem.sliceAsBytes(data),
            .rgba32 => |data| std.mem.sliceAsBytes(data),
            .rgb332 => |data| std.mem.sliceAsBytes(data),
            .rgb565 => |data| std.mem.sliceAsBytes(data),
            .rgb555 => |data| std.mem.sliceAsBytes(data),
            .bgr555 => |data| std.mem.sliceAsBytes(data),
            .bgr24 => |data| std.mem.sliceAsBytes(data),
            .bgra32 => |data| std.mem.sliceAsBytes(data),
            .rgb48 => |data| std.mem.sliceAsBytes(data),
            .rgba64 => |data| std.mem.sliceAsBytes(data),
            .float32 => |data| std.mem.sliceAsBytes(data),
        };
    }

    pub fn asConstBytes(self: PixelStorage) []const u8 {
        return switch (self) {
            .invalid => &[_]u8{},
            .indexed1 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed2 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed4 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed8 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed16 => |data| std.mem.sliceAsBytes(data.indices),
            .grayscale1 => |data| std.mem.sliceAsBytes(data),
            .grayscale2 => |data| std.mem.sliceAsBytes(data),
            .grayscale4 => |data| std.mem.sliceAsBytes(data),
            .grayscale8 => |data| std.mem.sliceAsBytes(data),
            .grayscale8Alpha => |data| std.mem.sliceAsBytes(data),
            .grayscale16 => |data| std.mem.sliceAsBytes(data),
            .grayscale16Alpha => |data| std.mem.sliceAsBytes(data),
            .rgb24 => |data| std.mem.sliceAsBytes(data),
            .rgba32 => |data| std.mem.sliceAsBytes(data),
            .rgb332 => |data| std.mem.sliceAsBytes(data),
            .rgb565 => |data| std.mem.sliceAsBytes(data),
            .rgb555 => |data| std.mem.sliceAsBytes(data),
            .bgr555 => |data| std.mem.sliceAsBytes(data),
            .bgr24 => |data| std.mem.sliceAsBytes(data),
            .bgra32 => |data| std.mem.sliceAsBytes(data),
            .rgb48 => |data| std.mem.sliceAsBytes(data),
            .rgba64 => |data| std.mem.sliceAsBytes(data),
            .float32 => |data| std.mem.sliceAsBytes(data),
        };
    }

    /// Return a slice of the current pixel storage
    pub fn slice(self: PixelStorage, begin: usize, end: usize) PixelStorage {
        return switch (self) {
            .invalid => .invalid,
            .indexed1 => |data| .{ .indexed1 = .{ .palette = data.palette, .indices = data.indices[begin..end] } },
            .indexed2 => |data| .{ .indexed2 = .{ .palette = data.palette, .indices = data.indices[begin..end] } },
            .indexed4 => |data| .{ .indexed4 = .{ .palette = data.palette, .indices = data.indices[begin..end] } },
            .indexed8 => |data| .{ .indexed8 = .{ .palette = data.palette, .indices = data.indices[begin..end] } },
            .indexed16 => |data| .{ .indexed16 = .{ .palette = data.palette, .indices = data.indices[begin..end] } },
            .grayscale1 => |data| .{ .grayscale1 = data[begin..end] },
            .grayscale2 => |data| .{ .grayscale2 = data[begin..end] },
            .grayscale4 => |data| .{ .grayscale4 = data[begin..end] },
            .grayscale8 => |data| .{ .grayscale8 = data[begin..end] },
            .grayscale8Alpha => |data| .{ .grayscale8Alpha = data[begin..end] },
            .grayscale16 => |data| .{ .grayscale16 = data[begin..end] },
            .grayscale16Alpha => |data| .{ .grayscale16Alpha = data[begin..end] },
            .rgb24 => |data| .{ .rgb24 = data[begin..end] },
            .rgba32 => |data| .{ .rgba32 = data[begin..end] },
            .rgb332 => |data| .{ .rgb332 = data[begin..end] },
            .rgb565 => |data| .{ .rgb565 = data[begin..end] },
            .rgb555 => |data| .{ .rgb555 = data[begin..end] },
            .bgr555 => |data| .{ .bgr555 = data[begin..end] },
            .bgr24 => |data| .{ .bgr24 = data[begin..end] },
            .bgra32 => |data| .{ .bgra32 = data[begin..end] },
            .rgb48 => |data| .{ .rgb48 = data[begin..end] },
            .rgba64 => |data| .{ .rgba64 = data[begin..end] },
            .float32 => |data| .{ .float32 = data[begin..end] },
        };
    }
};

pub const PixelStorageIterator = struct {
    pixels: *const PixelStorage = undefined,
    current_index: usize = 0,
    end: usize = 0,

    const Self = @This();

    pub fn init(pixels: *const PixelStorage) Self {
        return Self{
            .pixels = pixels,
            .end = pixels.len(),
        };
    }

    pub fn next(self: *Self) ?Colorf32 {
        if (self.current_index >= self.end) {
            return null;
        }

        const result: ?Colorf32 = switch (self.pixels.*) {
            .invalid => Colorf32.initRgb(0.0, 0.0, 0.0),
            .indexed1 => |data| data.palette[data.indices[self.current_index]].toColorf32(),
            .indexed2 => |data| data.palette[data.indices[self.current_index]].toColorf32(),
            .indexed4 => |data| data.palette[data.indices[self.current_index]].toColorf32(),
            .indexed8 => |data| data.palette[data.indices[self.current_index]].toColorf32(),
            .indexed16 => |data| data.palette[data.indices[self.current_index]].toColorf32(),
            .grayscale1 => |data| data[self.current_index].toColorf32(),
            .grayscale2 => |data| data[self.current_index].toColorf32(),
            .grayscale4 => |data| data[self.current_index].toColorf32(),
            .grayscale8 => |data| data[self.current_index].toColorf32(),
            .grayscale8Alpha => |data| data[self.current_index].toColorf32(),
            .grayscale16 => |data| data[self.current_index].toColorf32(),
            .grayscale16Alpha => |data| data[self.current_index].toColorf32(),
            .rgb24 => |data| data[self.current_index].toColorf32(),
            .rgba32 => |data| data[self.current_index].toColorf32(),
            .rgb332 => |data| data[self.current_index].toColorf32(),
            .rgb565 => |data| data[self.current_index].toColorf32(),
            .rgb555 => |data| data[self.current_index].toColorf32(),
            .bgr555 => |data| data[self.current_index].toColorf32(),
            .bgr24 => |data| data[self.current_index].toColorf32(),
            .bgra32 => |data| data[self.current_index].toColorf32(),
            .rgb48 => |data| data[self.current_index].toColorf32(),
            .rgba64 => |data| data[self.current_index].toColorf32(),
            .float32 => |data| data[self.current_index],
        };

        self.current_index += 1;
        return result;
    }
};

// For this point on, we are defining color types that are not used to store pixels but are used for color manipulation on the CPU.
// Most of them are in the 0.0 to 1.0 range in 32-bit float except for a few exceptions.
// Also assume that the from and to functions uses linear RGB color space with no gamma correction.

// HSL (Hue, Saturation, Luminance) is a different representation of the device dependent linear sRGB colorspace
// where the luminance is pure white and models the way different paints mix together
// to create color in the real world, with the lightness dimension resembling the varying amounts of black or white paint in the mixture
pub const Hsl = struct {
    hue: f32 = 0.0, // angle in degrees (0-360)
    saturation: f32 = 0.0, // range from 0 to 1
    luminance: f32 = 0.0, // range from 0 to 1

    pub fn fromRgb(rgb: Colorf32) Hsl {
        const maximum = @max(rgb.r, @max(rgb.g, rgb.b)); // V
        const minimum = @min(rgb.r, @min(rgb.g, rgb.b)); // V - C
        const range = maximum - minimum; // C := 2(V - L)
        const luminance = (maximum + minimum) / 2.0; // V - C/2

        var hue: f32 = 0.0;

        if (range == 0.0) {
            hue = 0.0;
        } else if (maximum == rgb.r) {
            hue = 60 * (@mod((rgb.g - rgb.b) / range, 6));
        } else if (maximum == rgb.g) {
            hue = 60 * ((rgb.b - rgb.r) / range + 2);
        } else if (maximum == rgb.b) {
            hue = 60 * ((rgb.r - rgb.g) / range + 4);
        }

        const saturation = if (luminance == 0.0 or luminance == 1.0) 0.0 else (maximum - luminance) / @min(luminance, 1.0 - luminance);

        return .{
            .hue = hue,
            .saturation = saturation,
            .luminance = luminance,
        };
    }

    pub fn toRgb(self: Hsl) Colorf32 {
        return .{
            .r = self.getRgbComponent(0),
            .g = self.getRgbComponent(8),
            .b = self.getRgbComponent(4),
            .a = 1.0,
        };
    }

    pub fn toHsv(self: Hsl) Hsv {
        const value = self.luminance + self.saturation * @min(self.luminance, 1.0 - self.luminance);

        return .{
            .hue = self.hue,
            .saturation = if (value == 0.0) 0.0 else 2.0 * (1.0 - (self.luminance / value)),
            .value = value,
        };
    }

    fn getRgbComponent(self: Hsl, n: f32) f32 {
        const a = self.saturation * @min(self.luminance, 1.0 - self.luminance);
        const k = @mod(n + self.hue / 30, 12);

        return self.luminance - a * @max(-1, @min(k - 3.0, @min(9.0 - k, 1.0)));
    }
};

// HSV (Hue, Saturation, Value) or HSB (Hue, Saturation, Brightness) is a different representation of the device dependent linear sRGB colorspace
// where the value/brightness is the maximum brightnes of a color. It models how colors appear under light.
pub const Hsv = struct {
    hue: f32 = 0.0, // angle in degrees(0-360)
    saturation: f32 = 0.0, // range from 0 to 1
    value: f32 = 0.0, // range from 0 to 1

    pub fn fromRgb(rgb: Colorf32) Hsv {
        const maximum = @max(rgb.r, @max(rgb.g, rgb.b)); // V
        const minimum = @min(rgb.r, @min(rgb.g, rgb.b)); // V - C
        const range = maximum - minimum; // C := 2(V - L)

        var hue: f32 = 0.0;

        if (range == 0.0) {
            hue = 0.0;
        } else if (maximum == rgb.r) {
            hue = 60 * (@mod((rgb.g - rgb.b) / range, 6));
        } else if (maximum == rgb.g) {
            hue = 60 * ((rgb.b - rgb.r) / range + 2);
        } else if (maximum == rgb.b) {
            hue = 60 * ((rgb.r - rgb.g) / range + 4);
        }

        const saturation = if (maximum == 0.0) 0.0 else range / maximum;

        return .{
            .hue = hue,
            .saturation = saturation,
            .value = maximum,
        };
    }

    pub fn toRgb(self: Hsv) Colorf32 {
        return .{
            .r = self.getRgbComponent(5),
            .g = self.getRgbComponent(3),
            .b = self.getRgbComponent(1),
            .a = 1.0,
        };
    }

    pub fn toHsl(self: Hsv) Hsl {
        const luminance = self.value * (1.0 - (self.saturation / 2.0));
        return .{
            .hue = self.hue,
            .saturation = if (luminance == 0.0) 0.0 else (self.value - luminance) / @min(luminance, 1.0 - luminance),
            .luminance = luminance,
        };
    }

    fn getRgbComponent(self: Hsv, n: f32) f32 {
        const k = @mod(n + (self.hue / 60), 6);

        return self.value - (self.value * self.saturation * @max(0.0, @min(k, @min(4.0 - k, 1))));
    }
};

// Device-dependent Cyan-Magenta-Yellow-blacK representation of the subtractive color model analogue to Colorf32.
// When converting from Colorf32, the alpha component is dropped so remember to pre-multiply the alpha.
// Used for printing mostly.
pub const Cmykf32 = extern struct {
    c: f32 align(1) = 0.0,
    m: f32 align(1) = 0.0,
    y: f32 align(1) = 0.0,
    k: f32 align(1) = 0.0,

    pub fn fromColorf32(value: Colorf32) Cmykf32 {
        const max = @max(value.r, @max(value.g, value.b));
        const k = 1.0 - max;

        const minus_k = 1.0 - k;
        if (std.math.approxEqAbs(f32, minus_k, 0.0, std.math.floatEps(f32))) {
            return .{
                .k = k,
            };
        }

        return .{
            .c = (1.0 - value.r - k) / minus_k,
            .m = (1.0 - value.g - k) / minus_k,
            .y = (1.0 - value.b - k) / minus_k,
            .k = k,
        };
    }

    pub fn toColorF32(self: Cmykf32) Colorf32 {
        const minus_k = 1.0 - self.k;
        return .{
            .r = (1.0 - self.c) * minus_k,
            .g = (1.0 - self.m) * minus_k,
            .b = (1.0 - self.y) * minus_k,
            .a = 1.0,
        };
    }
};

// CIE 1931 XYZ color space, device-independant color space
pub const CIEXYZ = extern struct {
    x: f32 align(1) = 0.0,
    y: f32 align(1) = 0.0,
    z: f32 align(1) = 0.0,
};

// CIE 1931 XYZ color space, device-independant color space but with alpha component
pub const CIEXYZAlpha = extern struct {
    x: f32 align(1) = 0.0,
    y: f32 align(1) = 0.0,
    z: f32 align(1) = 0.0,
    a: f32 align(1) = 1.0,

    pub inline fn fromFloat4(value: math.float4) CIEXYZAlpha {
        return @bitCast(value);
    }

    pub inline fn toFloat4(self: CIEXYZAlpha) math.float4 {
        return @bitCast(self);
    }

    pub fn toXYZ(self: CIEXYZAlpha) CIEXYZ {
        return .{
            .x = self.x,
            .y = self.y,
            .z = self.z,
        };
    }
};

pub const CIEConstants = struct {
    const epsilon: f32 = 216.0 / 24389.0;
    const kappa: f32 = 24389.0 / 27.0;
};

// CIE L*a*b* color space, meaning L* for perceptual lightness and a* and b* for the four unique colors of human vision: red, green, blue and yellow.
// L = 0.0 to 1.0
// a = -1.0 to 1.0
// b = -1.0 to 1.0
pub const CIELab = extern struct {
    l: f32 align(1) = 0.0,
    a: f32 align(1) = 0.0,
    b: f32 align(1) = 0.0,

    pub inline fn fromXYZ(xyz: CIEXYZ, white_point: CIExyY) CIELab {
        return CIELab.fromXYZPrecomputedWhitePoint(xyz, white_point.toXYZ(1.0));
    }

    pub fn fromXYZPrecomputedWhitePoint(xyz: CIEXYZ, white_point_xyz: CIEXYZ) CIELab {
        // Math from http://www.brucelindbloom.com/Eqn_XYZ_to_Lab.html
        const relative_x = xyz.x / white_point_xyz.x;
        const relative_y = xyz.y / white_point_xyz.y;
        const relative_z = xyz.z / white_point_xyz.z;

        const factor_x = factor(relative_x);
        const factor_y = factor(relative_y);
        const factor_z = factor(relative_z);

        const l = 116.0 * factor_y - 16.0;
        const a = 500.0 * (factor_x - factor_y);
        const b = 200.0 * (factor_y - factor_z);

        // Normalize to 0 to 1 or -1.0 to 1.0
        return .{
            .l = l / 100.0,
            .a = a / 100.0,
            .b = b / 100.0,
        };
    }

    pub inline fn toXYZ(self: CIELab, white_point: CIExyY) CIEXYZ {
        return self.toXYZPrecomputedWhitePoint(white_point.toXYZ(1.0));
    }

    pub fn toXYZPrecomputedWhitePoint(self: CIELab, white_point_xyz: CIEXYZ) CIEXYZ {
        // Math from http://www.brucelindbloom.com/Eqn_Lab_to_XYZ.html
        const scaled_l = self.l * 100.0;
        const scaled_a = self.a * 100.0;
        const scaled_b = self.b * 100.0;

        const factor_y = (scaled_l + 16.0) / 116.0;
        const factor_z = factor_y - (scaled_b / 200.0);
        const factor_x = (scaled_a / 500.0) + factor_y;

        const cubic_factor_x = factor_x * factor_x * factor_x;
        const cubic_factor_z = factor_z * factor_z * factor_z;

        const result_x = if (cubic_factor_x > CIEConstants.epsilon) cubic_factor_x else ((116.0 * factor_x) - 16.0) / CIEConstants.kappa;
        const result_y = if (scaled_l > (CIEConstants.kappa * CIEConstants.epsilon)) std.math.pow(f32, (scaled_l + 16.0) / 116.0, 3.0) else scaled_l / CIEConstants.kappa;
        const result_z = if (cubic_factor_z > CIEConstants.epsilon) cubic_factor_z else ((116.0 * factor_z) - 16.0) / CIEConstants.kappa;

        return .{
            .x = result_x * white_point_xyz.x,
            .y = result_y * white_point_xyz.y,
            .z = result_z * white_point_xyz.z,
        };
    }

    pub inline fn fromLCHab(value: CIELCHab) CIELab {
        return value.toLab();
    }

    pub inline fn toLCHab(self: CIELab) CIELCHab {
        return CIELCHab.fromLab(self);
    }

    fn factor(t: f32) f32 {
        if (t > CIEConstants.epsilon) {
            return std.math.cbrt(t);
        }

        return ((CIEConstants.kappa * t) + 16.0) / 116.0;
    }
};

// CIE L*a*b* color space with alpha component
// L = 0.0 to 1.0
// a = -1.0 to 1.0
// b = -1.0 to 1.0
pub const CIELabAlpha = extern struct {
    l: f32 align(1) = 0.0,
    a: f32 align(1) = 0.0,
    b: f32 align(1) = 0.0,
    alpha: f32 align(1) = 1.0,

    pub inline fn fromXYZAlpha(xyza: CIEXYZAlpha, white_point: CIExyY) CIELabAlpha {
        return fromXYZAlphaPrecomputedWhitePoint(xyza, white_point.toXYZ(1.0));
    }

    pub fn fromXYZAlphaPrecomputedWhitePoint(xyza: CIEXYZAlpha, white_point_xyz: CIEXYZ) CIELabAlpha {
        const lab = CIELab.fromXYZPrecomputedWhitePoint(xyza.toXYZ(), white_point_xyz);

        return .{
            .l = lab.l,
            .a = lab.a,
            .b = lab.b,
            .alpha = xyza.a,
        };
    }

    pub inline fn toXYZAlpha(self: CIELabAlpha, white_point: CIExyY) CIEXYZAlpha {
        return self.toXYZAlphaPrecomputedWhitePoint(white_point.toXYZ(1.0));
    }

    pub fn toXYZAlphaPrecomputedWhitePoint(self: CIELabAlpha, white_point_xyz: CIEXYZ) CIEXYZAlpha {
        const xyz = CIELab.toXYZPrecomputedWhitePoint(self.toLab(), white_point_xyz);

        return .{
            .x = xyz.x,
            .y = xyz.y,
            .z = xyz.z,
            .a = self.alpha,
        };
    }

    pub fn toLab(self: CIELabAlpha) CIELab {
        return .{
            .l = self.l,
            .a = self.a,
            .b = self.b,
        };
    }

    pub inline fn fromLCHabAlpha(value: CIELCHabAlpha) CIELabAlpha {
        return value.toLabAlpha();
    }

    pub inline fn toLCHabAlpha(self: CIELabAlpha) CIELCHabAlpha {
        return CIELCHabAlpha.fromLabAlpha(self);
    }

    pub inline fn fromFloat4(value: math.float4) CIELabAlpha {
        return @bitCast(value);
    }

    pub inline fn toFloat4(self: CIELabAlpha) math.float4 {
        return @bitCast(self);
    }
};

// CIE LCH(ab) is the cylindrical representation of CIE L*a*b so it is always converted
// from and to L*a*b. The angle H is stored in radians.
pub const CIELCHab = extern struct {
    l: f32 align(1) = 0.0,
    c: f32 align(1) = 0.0,
    h: f32 align(1) = 0.0,

    pub fn fromLab(value: CIELab) CIELCHab {
        const c = std.math.sqrt(value.a * value.a + value.b * value.b);
        var h = std.math.atan2(value.b, value.a);
        if (h < 0.0) {
            h += 2.0 * std.math.pi;
        }

        return .{
            .l = value.l,
            .c = c,
            .h = h,
        };
    }

    pub fn toLab(self: CIELCHab) CIELab {
        return .{
            .l = self.l,
            .a = self.c * @cos(self.h),
            .b = self.c * @sin(self.h),
        };
    }
};

// CIE LCH(ab) with alpha is the cylindrical representation of CIE L*a*b so it is always converted
// from and to L*a*b. The angle H is stored in radians.
pub const CIELCHabAlpha = extern struct {
    l: f32 align(1) = 0.0,
    c: f32 align(1) = 0.0,
    h: f32 align(1) = 0.0,
    alpha: f32 align(1) = 1.0,

    pub fn fromLabAlpha(lab_alpha: CIELabAlpha) CIELCHabAlpha {
        const lch = CIELCHab.fromLab(lab_alpha.toLab());

        return .{
            .l = lch.l,
            .c = lch.c,
            .h = lch.h,
            .alpha = lab_alpha.alpha,
        };
    }

    pub fn toLabAlpha(self: CIELCHabAlpha) CIELabAlpha {
        const lab = CIELCHab.toLab(self.toLCHab());

        return .{
            .l = lab.l,
            .a = lab.a,
            .b = lab.b,
            .alpha = self.alpha,
        };
    }

    pub fn toLCHab(self: CIELCHabAlpha) CIELCHab {
        return .{
            .l = self.l,
            .c = self.c,
            .h = self.h,
        };
    }
};

// CIE L*u*v* color space, meaning L* for perceptual lightness, u* and v* are chroma coordinates
// L = 0.0 to 1.0
// u = -1.0 to 1.0
// v = -1.0 to 1.0
pub const CIELuv = extern struct {
    l: f32 align(1) = 0.0,
    u: f32 align(1) = 0.0,
    v: f32 align(1) = 0.0,

    pub inline fn fromXYZ(xyz: CIEXYZ, white_point: CIExyY) CIELuv {
        return fromXYZPrecomputedWhitePoint(xyz, white_point.toXYZ(1.0));
    }

    pub fn fromXYZPrecomputedWhitePoint(xyz: CIEXYZ, white_point_xyz: CIEXYZ) CIELuv {
        // Math from: http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_Luv.html
        const y_relative = xyz.y / white_point_xyz.y;

        const value_denominator = xyz.x + 15.0 * xyz.y + 3.0 * xyz.z;
        const is_value_zero = std.math.approxEqAbs(f32, value_denominator, 0.0, std.math.floatEps(f32));
        const u_prime = if (!is_value_zero) (4.0 * xyz.x) / value_denominator else 0.0;
        const v_prime = if (!is_value_zero) (9.0 * xyz.y) / value_denominator else 0.0;

        const white_denominator = (white_point_xyz.x + 15.0 * white_point_xyz.y + 3.0 * white_point_xyz.z);
        const white_u_prime = (4.0 * white_point_xyz.x) / white_denominator;
        const white_v_prime = (9.0 * white_point_xyz.y) / white_denominator;

        const l = if (y_relative > CIEConstants.epsilon) (116.0 * std.math.cbrt(y_relative)) - 16.0 else CIEConstants.kappa * y_relative;
        const u = 13.0 * l * (u_prime - white_u_prime);
        const v = 13.0 * l * (v_prime - white_v_prime);

        // Normalize the result
        return .{
            .l = l / 100.0,
            .u = u / 100.0,
            .v = v / 100.0,
        };
    }

    pub inline fn toXYZ(self: CIELuv, white_point: CIExyY) CIEXYZ {
        return self.toXYZPrecomputedWhitePoint(white_point.toXYZ(1.0));
    }

    pub fn toXYZPrecomputedWhitePoint(self: CIELuv, white_point_xyz: CIEXYZ) CIEXYZ {
        // Math from: http://www.brucelindbloom.com/index.html?Eqn_Luv_to_XYZ.html
        const scaled_l = self.l * 100.0;
        const scaled_u = self.u * 100.0;
        const scaled_v = self.v * 100.0;

        if (std.math.approxEqAbs(f32, scaled_l, 0.0, std.math.floatEps(f32))) {
            return .{
                .x = 0.0,
                .y = 0.0,
                .z = 0.0,
            };
        }

        const white_denominator = white_point_xyz.x + 15.0 * white_point_xyz.y + 3.0 * white_point_xyz.z;
        const white_u_zero = (4.0 * white_point_xyz.x) / white_denominator;
        const white_v_zero = (9.0 * white_point_xyz.y) / white_denominator;

        const y = if (scaled_l > CIEConstants.kappa * CIEConstants.epsilon) std.math.pow(f32, (scaled_l + 16.0) / 116.0, 3.0) else scaled_l / CIEConstants.kappa;

        const a = (((52.0 * scaled_l) / (scaled_u + 13.0 * scaled_l * white_u_zero)) - 1) * (1.0 / 3.0);
        const b = -5.0 * y;
        const c = -1.0 / 3.0;
        const d = y * (((39.0 * scaled_l) / (scaled_v + 13.0 * scaled_l * white_v_zero)) - 5.0);

        const x = (d - b) / (a - c);
        const z = x * a + b;

        return .{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub inline fn fromLCHuv(value: CIELCHuv) CIELuv {
        return value.toLuv();
    }

    pub inline fn toLCHuv(self: CIELuv) CIELCHuv {
        return CIELCHuv.fromLuv(self);
    }
};

// CIE L*u*v* color space with alpha, meaning L* for perceptual lightness, u* and v* are chroma coordinates
// L = 0.0 to 1.0
// u = -1.0 to 1.0
// v = -1.0 to 1.0
pub const CIELuvAlpha = extern struct {
    l: f32 align(1) = 0.0,
    u: f32 align(1) = 0.0,
    v: f32 align(1) = 0.0,
    alpha: f32 align(1) = 1.0,

    pub inline fn fromXYZAlpha(xyza: CIEXYZAlpha, white_point: CIExyY) CIELuvAlpha {
        return fromXYZAlphaPrecomputedWhitePoint(xyza, white_point.toXYZ(1.0));
    }

    pub fn fromXYZAlphaPrecomputedWhitePoint(xyza: CIEXYZAlpha, white_point_xyz: CIEXYZ) CIELuvAlpha {
        const luv = CIELuv.fromXYZPrecomputedWhitePoint(xyza.toXYZ(), white_point_xyz);

        return .{
            .l = luv.l,
            .u = luv.u,
            .v = luv.v,
            .alpha = xyza.a,
        };
    }

    pub inline fn toXYZAlpha(self: CIELuvAlpha, white_point: CIExyY) CIEXYZAlpha {
        return self.toXYZAlphaPrecomputedWhitePoint(white_point.toXYZ(1.0));
    }

    pub fn toXYZAlphaPrecomputedWhitePoint(self: CIELuvAlpha, white_point_xyz: CIEXYZ) CIEXYZAlpha {
        const xyz = CIELuv.toXYZPrecomputedWhitePoint(self.toLuv(), white_point_xyz);

        return .{
            .x = xyz.x,
            .y = xyz.y,
            .z = xyz.z,
            .a = self.alpha,
        };
    }

    pub fn toLuv(self: CIELuvAlpha) CIELuv {
        return .{
            .l = self.l,
            .u = self.u,
            .v = self.v,
        };
    }

    pub inline fn fromLCHuvAlpha(value: CIELCHuvAlpha) CIELuvAlpha {
        return value.toLuvAlpha();
    }

    pub inline fn toLCHuvAlpha(self: CIELuvAlpha) CIELCHuvAlpha {
        return CIELCHuvAlpha.fromLuvAlpha(self);
    }

    pub inline fn fromFloat4(value: math.float4) CIELuvAlpha {
        return @bitCast(value);
    }

    pub inline fn toFloat4(self: CIELuvAlpha) math.float4 {
        return @bitCast(self);
    }
};

// CIE LCH(uv) is the cylindrical representation of CIE L*u*v*s so it is always converted
// from and to L*u*v*. The angle H is stored in radians.
pub const CIELCHuv = extern struct {
    l: f32 align(1) = 0.0,
    c: f32 align(1) = 0.0,
    h: f32 align(1) = 0.0,

    pub fn fromLuv(value: CIELuv) CIELCHuv {
        const c = std.math.sqrt(value.u * value.u + value.v * value.v);
        var h = std.math.atan2(value.v, value.u);
        if (h < 0.0) {
            h += 2.0 * std.math.pi;
        }

        return .{
            .l = value.l,
            .c = c,
            .h = h,
        };
    }

    pub fn toLuv(self: CIELCHuv) CIELuv {
        return .{
            .l = self.l,
            .u = self.c * @cos(self.h),
            .v = self.c * @sin(self.h),
        };
    }
};

// CIE LCH(uv) with alpha is the cylindrical representation of CIE L*u*v* so it is always converted
// from and to L*u*v*. The angle H is stored in radians.
pub const CIELCHuvAlpha = extern struct {
    l: f32 align(1) = 0.0,
    c: f32 align(1) = 0.0,
    h: f32 align(1) = 0.0,
    alpha: f32 align(1) = 1.0,

    pub fn fromLuvAlpha(luv_alpha: CIELuvAlpha) CIELCHuvAlpha {
        const lch = CIELCHuv.fromLuv(luv_alpha.toLuv());

        return .{
            .l = lch.l,
            .c = lch.c,
            .h = lch.h,
            .alpha = luv_alpha.alpha,
        };
    }

    pub fn toLuvAlpha(self: CIELCHuvAlpha) CIELuvAlpha {
        const luv = CIELCHuv.toLuv(self.toLCHuv());

        return .{
            .l = luv.l,
            .u = luv.u,
            .v = luv.v,
            .alpha = self.alpha,
        };
    }

    pub fn toLCHuv(self: CIELCHuvAlpha) CIELCHuv {
        return .{
            .l = self.l,
            .c = self.c,
            .h = self.h,
        };
    }
};

// HSLuv is a HSL representation of CIE LCH(uv) which is a cylindrical representation of CIE L*u*v* color space
// Adapted from hsluv-c: https://github.com/hsluv/hsluv-c/blob/master/src/hsluv.c
// The MIT License (MIT)

// Copyright © 2015 Alexei Boronine (original idea, JavaScript implementation)
// Copyright © 2015 Roger Tallada (Obj-C implementation)
// Copyright © 2017 Martin Mitáš (C implementation, based on Obj-C implementation)

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”),
// to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pub const HSLuv = extern struct {
    h: f32 align(1), // Hue in radians
    s: f32 align(1), // Saturation from 0.0 to 1.0
    l: f32 align(1), // Lightness from 0.0 to 1.0

    const Line = struct {
        a: f32 = 0.0,
        b: f32 = 0.0,

        pub fn intersect(left: Line, right: Line) f32 {
            return (left.b - right.b) / (right.a - left.a);
        }

        pub fn rayLengthUntilIntersect(self: Line, angle: f32) f32 {
            return self.b / (@sin(angle) - self.a * @cos(angle));
        }
    };

    pub fn fromCIELChuv(lch: CIELCHuv, xyz_to_rgb_matrix: math.float4x4) HSLuv {
        var s: f32 = 0.0;

        // White and black: disambiguate saturation
        if (lch.l > 0.99999999999 or lch.l < 0.00000001) {
            s = 0.0;
        } else {
            s = lch.c / (maxChromaForLH(lch.l, lch.h, xyz_to_rgb_matrix) / 100.0);
        }

        //  Grays: disambiguate hue
        const h = if (lch.c < 0.00000001) 0.0 else lch.h;

        return .{
            .h = h,
            .s = s,
            .l = lch.l,
        };
    }

    pub fn toCIELCHuv(self: HSLuv, xyz_to_rgb_matrix: math.float4x4) CIELCHuv {
        var c: f32 = 0.0;

        // White and black: disambiguate chroma
        if (self.l > 0.99999999999 or self.l < 0.00000001) {
            c = 0.0;
        } else {
            c = (maxChromaForLH(self.l, self.h, xyz_to_rgb_matrix) / 100.0) * self.s;
        }

        //  Grays: disambiguate hue
        const h = if (self.s < 0.00000001) 0.0 else self.h;

        return .{
            .l = self.l,
            .c = c,
            .h = h,
        };
    }

    fn maxChromaForLH(l: f32, h: f32, xyz_to_rgb_matrix: math.float4x4) f32 {
        var minimum_length = std.math.floatMax(f32);
        var bounds: [6]Line = undefined;

        getBounds(l, bounds[0..], xyz_to_rgb_matrix);

        for (bounds) |bound| {
            const length = bound.rayLengthUntilIntersect(h);
            if (length >= 0 and length < minimum_length) {
                minimum_length = length;
            }
        }

        return minimum_length;
    }

    fn getBounds(l: f32, bounds: []Line, xyz_to_rgb_matrix: math.float4x4) void {
        const scaled_l = l * 100.0;

        const tl = scaled_l + 16.0;
        const sub1 = (tl * tl * tl) / 1560896.0;
        const sub2 = if (sub1 > CIEConstants.epsilon) sub1 else (1.0 / CIEConstants.kappa);

        for (0..3) |channel| {
            const m1 = xyz_to_rgb_matrix.matrix[channel][0];
            const m2 = xyz_to_rgb_matrix.matrix[channel][1];
            const m3 = xyz_to_rgb_matrix.matrix[channel][2];

            for (0..2) |t| {
                const top1 = (284517.0 * m1 - 94839.0 * m3) * sub2;
                const top2 = (838422.0 * m3 + 769860.0 * m2 + 731718.0 * m1) * scaled_l * sub2 - 769860.0 * @as(f32, @floatFromInt(t)) * scaled_l;
                const bottom = (632260.0 * m3 - 126452.0 * m2) * sub2 + 126452.0 * @as(f32, @floatFromInt(t));

                bounds[channel * 2 + t].a = top1 / bottom;
                bounds[channel * 2 + t].b = top2 / bottom;
            }
        }
    }
};

// HSLuvAlpha is a HSL representation of CIE LCH(uv) which is a cylindrical representation of CIE L*u*v* color space with alpha
pub const HSLuvAlpha = extern struct {
    h: f32 align(1), // Hue in radians
    s: f32 align(1), // Saturation from 0.0 to 1.0
    l: f32 align(1), // Lightness from 0.0 to 1.0
    alpha: f32 align(1),

    pub fn fromCIELChuvAlpha(lch: CIELCHuvAlpha, xyz_to_rgb_matrix: math.float4x4) HSLuvAlpha {
        const hsl = HSLuv.fromCIELChuv(lch.toLCHuv(), xyz_to_rgb_matrix);

        return .{
            .h = hsl.h,
            .s = hsl.s,
            .l = hsl.l,
            .alpha = lch.alpha,
        };
    }

    pub fn toCIELCHuvAlpha(self: HSLuvAlpha, xyz_to_rgb_matrix: math.float4x4) CIELCHuvAlpha {
        const lch = HSLuv.toCIELCHuv(self.toHSLuv(), xyz_to_rgb_matrix);

        return .{
            .l = lch.l,
            .c = lch.c,
            .h = lch.h,
            .alpha = self.alpha,
        };
    }

    pub fn toHSLuv(self: HSLuvAlpha) HSLuv {
        return .{
            .h = self.h,
            .s = self.s,
            .l = self.l,
        };
    }

    pub inline fn fromFloat4(value: math.float4) CIELuvAlpha {
        return @bitCast(value);
    }

    pub inline fn toFloat4(self: CIELuvAlpha) math.float4 {
        return @bitCast(self);
    }
};

// Oklab is represented with three coordinates, similar to how CIELAB works, but with better perceptual properties.
// Oklab uses a D65 whitepoint so make sure to convert your RGBA color to D65 white if you use a different white point.
// See https://bottosson.github.io/posts/oklab/ for more information.
pub const Oklab = extern struct {
    l: f32 align(1) = 0.0,
    a: f32 align(1) = 0.0,
    b: f32 align(1) = 0.0,

    pub fn fromXYZ(xyz: CIEXYZ) Oklab {
        const labAlpha = OklabAlpha.fromXYZAlpha(CIEXYZAlpha{ .x = xyz.x, .y = xyz.y, .z = xyz.z, .a = 1.0 });
        return labAlpha.toOklab();
    }

    pub fn toXYZ(self: Oklab) CIEXYZ {
        const xyza = OklabAlpha.toXYZAlpha(self.toOklabAlpha());
        return xyza.toXYZ();
    }

    pub fn toOklabAlpha(self: Oklab) OklabAlpha {
        return .{
            .l = self.l,
            .a = self.a,
            .b = self.b,
        };
    }

    pub inline fn toOkLCh(self: Oklab) OkLCh {
        return OkLCh.fromOklab(self);
    }
};

// Oklab with alpha is represented with three coordinates, similar to how CIELAB works, but with better perceptual properties.
// Oklab uses a D65 whitepoint so make sure to convert your RGBA color to D65 white if you use a different white point.
// See https://bottosson.github.io/posts/oklab/ for more information.
pub const OklabAlpha = extern struct {
    l: f32 align(1) = 0.0,
    a: f32 align(1) = 0.0,
    b: f32 align(1) = 0.0,
    alpha: f32 align(1) = 1.0,

    const XYZAtoLMS = math.float4x4.fromArray(.{
        0.8189330101, 0.3618667424, -0.1288597137, 0.0,
        0.0329845436, 0.9293118715, 0.0361456387,  0.0,
        0.0482003018, 0.2643662691, 0.6338517070,  0.0,
        0.0,          0.0,          0.0,           1.0,
    });

    const LMSPrimeToLab = math.float4x4.fromArray(.{
        0.2104542553, 0.7936177850,  -0.0040720468, 0.0,
        1.9779984951, -2.4285922050, 0.4505937099,  0.0,
        0.0259040371, 0.7827717662,  -0.8086757660, 0.0,
        0.0,          0.0,           0.0,           1.0,
    });

    const LabToLMSPrime = LMSPrimeToLab.inverse();
    const LMSToXYZA = XYZAtoLMS.inverse();

    pub fn fromXYZAlpha(xyza: CIEXYZAlpha) OklabAlpha {
        var lmsa = XYZAtoLMS.mulVector(xyza.toFloat4());

        lmsa[0] = std.math.cbrt(lmsa[0]);
        lmsa[1] = std.math.cbrt(lmsa[1]);
        lmsa[2] = std.math.cbrt(lmsa[2]);

        const lab_a = LMSPrimeToLab.mulVector(lmsa);
        return .{
            .l = lab_a[0],
            .a = lab_a[1],
            .b = lab_a[2],
            .alpha = xyza.a,
        };
    }

    pub fn toXYZAlpha(self: OklabAlpha) CIEXYZAlpha {
        var lmsa_prime = LabToLMSPrime.mulVector(self.toFloat4());

        lmsa_prime[0] = lmsa_prime[0] * lmsa_prime[0] * lmsa_prime[0];
        lmsa_prime[1] = lmsa_prime[1] * lmsa_prime[1] * lmsa_prime[1];
        lmsa_prime[2] = lmsa_prime[2] * lmsa_prime[2] * lmsa_prime[2];

        const xyza_float4 = LMSToXYZA.mulVector(lmsa_prime);

        return CIEXYZAlpha.fromFloat4(xyza_float4);
    }

    pub fn toOklab(self: OklabAlpha) Oklab {
        return .{
            .l = self.l,
            .a = self.a,
            .b = self.b,
        };
    }

    pub inline fn toOkLChAlpha(self: OklabAlpha) OkLChAlpha {
        return OkLChAlpha.fromOklabAlpha(self);
    }

    pub inline fn fromFloat4(value: math.float4) OklabAlpha {
        return @bitCast(value);
    }

    pub inline fn toFloat4(self: OklabAlpha) math.float4 {
        return @bitCast(self);
    }
};

// OkLCh is the cylindrical representation of CIE L*a*b so it is always converted
// from and to L*a*b. The angle H is stored in radians.
pub const OkLCh = extern struct {
    l: f32 align(1) = 0.0,
    c: f32 align(1) = 0.0,
    h: f32 align(1) = 0.0,

    pub fn fromOklab(value: Oklab) OkLCh {
        const c = std.math.sqrt(value.a * value.a + value.b * value.b);
        var h = std.math.atan2(value.b, value.a);
        if (h < 0.0) {
            h += 2.0 * std.math.pi;
        }

        return .{
            .l = value.l,
            .c = c,
            .h = h,
        };
    }

    pub fn toOklab(self: OkLCh) Oklab {
        return .{
            .l = self.l,
            .a = self.c * @cos(self.h),
            .b = self.c * @sin(self.h),
        };
    }
};

// OkLCh with alpha is the cylindrical representation of Oklab so it is always converted
// from and to Oklab. The angle H is stored in radians.
pub const OkLChAlpha = extern struct {
    l: f32 align(1) = 0.0,
    c: f32 align(1) = 0.0,
    h: f32 align(1) = 0.0,
    alpha: f32 align(1) = 1.0,

    pub fn fromOklabAlpha(lab_alpha: OklabAlpha) OkLChAlpha {
        const lch = OkLCh.fromOklab(lab_alpha.toOklab());

        return .{
            .l = lch.l,
            .c = lch.c,
            .h = lch.h,
            .alpha = lab_alpha.alpha,
        };
    }

    pub fn toOkLabAlpha(self: OkLChAlpha) OklabAlpha {
        const lab = OkLCh.toOklab(self.toOkLCh());

        return .{
            .l = lab.l,
            .a = lab.a,
            .b = lab.b,
            .alpha = self.alpha,
        };
    }

    pub fn toOkLCh(self: OkLChAlpha) OkLCh {
        return .{
            .l = self.l,
            .c = self.c,
            .h = self.h,
        };
    }
};

// Using CIE 1931 2°
pub const CIExyY = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,

    pub inline fn z(self: CIExyY) f32 {
        return 1.0 - self.x - self.y;
    }

    pub fn toXYZ(self: CIExyY, Y: f32) CIEXYZ {
        return .{
            .x = (self.x / self.y) * Y,
            .y = Y,
            .z = (self.z() / self.y) * Y,
        };
    }

    pub fn equals(self: CIExyY, right: CIExyY) bool {
        return self.x == right.x and self.y == right.y;
    }
};

/// RGB Colorspace are defined in the CIE xyY colorspace, requiring only the x and y value
pub const RgbColorspace = struct {
    red: CIExyY,
    green: CIExyY,
    blue: CIExyY,
    white: CIExyY,
    rgba_to_xyza: math.float4x4,
    xyza_to_rgba: math.float4x4,
    to_gamma: *const fn (f32) f32,
    to_gamma_fast: *const fn (f32) f32,
    to_linear: *const fn (f32) f32,
    to_linear_fast: *const fn (f32) f32,

    pub const PostConversionBehavior = enum {
        none, // Keep value as-is
        clamp, // Clamp values inside of the color in case of color being outside the colorspace
    };

    pub const InitArgs = struct {
        red: CIExyY = .{},
        green: CIExyY = .{},
        blue: CIExyY = .{},
        white: CIExyY = .{},
        to_gamma: *const fn (f32) f32 = gammaNoTransfer,
        to_gamma_fast: *const fn (f32) f32 = gammaNoTransfer,
        to_linear: *const fn (f32) f32 = gammaNoTransfer,
        to_linear_fast: *const fn (f32) f32 = gammaNoTransfer,
    };

    pub const ConversionMatrix = math.float4x4;

    pub fn init(args: InitArgs) RgbColorspace {
        var result = RgbColorspace{
            .red = args.red,
            .green = args.green,
            .blue = args.blue,
            .white = args.white,
            .rgba_to_xyza = undefined,
            .xyza_to_rgba = undefined,
            .to_gamma = args.to_gamma,
            .to_gamma_fast = args.to_gamma_fast,
            .to_linear = args.to_linear,
            .to_linear_fast = args.to_linear_fast,
        };

        const conversion_matrix = result.toXYZConversionMatrix();

        result.rgba_to_xyza = conversion_matrix;
        result.xyza_to_rgba = conversion_matrix.inverse();

        return result;
    }

    /// Return a gamma-corrected version of the color
    pub fn toGamma(self: RgbColorspace, color: Colorf32) Colorf32 {
        return .{
            .r = self.to_gamma(color.r),
            .g = self.to_gamma(color.g),
            .b = self.to_gamma(color.b),
            .a = color.a,
        };
    }

    /// Return a gamma-corrected version of the color using a fast approximation
    /// of the transfer function
    pub fn toGammaFast(self: RgbColorspace, color: Colorf32) Colorf32 {
        return .{
            .r = self.to_gamma_fast(color.r),
            .g = self.to_gamma_fast(color.g),
            .b = self.to_gamma_fast(color.b),
            .a = color.a,
        };
    }

    /// Return a linear version of the color from a gamma-corrected color
    pub fn toLinear(self: RgbColorspace, color: Colorf32) Colorf32 {
        return .{
            .r = self.to_linear(color.r),
            .g = self.to_linear(color.g),
            .b = self.to_linear(color.b),
            .a = color.a,
        };
    }

    /// Return a linear version of the color from a gamma-corrected color using a fast approximation
    /// of the transfer function
    pub fn toLinearFast(self: RgbColorspace, color: Colorf32) Colorf32 {
        return .{
            .r = self.to_linear_fast(color.r),
            .g = self.to_linear_fast(color.g),
            .b = self.to_linear_fast(color.b),
            .a = color.a,
        };
    }

    pub fn fromXYZ(self: RgbColorspace, xyz: CIEXYZ) Colorf32 {
        const xyz_float4 = math.float4{ xyz.x, xyz.y, xyz.z, 1.0 };

        const result = self.xyza_to_rgba.mulVector(xyz_float4);

        return Colorf32.fromFloat4(result);
    }

    pub fn toXYZ(self: RgbColorspace, color: Colorf32) CIEXYZ {
        const result = self.rgba_to_xyza.mulVector(color.toFloat4());

        return .{
            .x = result[0],
            .y = result[1],
            .z = result[2],
        };
    }

    pub fn fromXYZAlpha(self: RgbColorspace, xyza: CIEXYZAlpha) Colorf32 {
        const result = self.xyza_to_rgba.mulVector(xyza.toFloat4());

        return Colorf32.fromFloat4(result);
    }

    pub fn toXYZAlpha(self: RgbColorspace, color: Colorf32) CIEXYZAlpha {
        const result = self.rgba_to_xyza.mulVector(color.toFloat4());

        return CIEXYZAlpha.fromFloat4(result);
    }

    pub fn fromLab(self: RgbColorspace, lab: CIELab, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        const xyz = lab.toXYZ(self.white);
        var result = self.fromXYZ(xyz);

        switch (post_conversion_behavior) {
            .none => {},
            .clamp => {
                result = Colorf32.fromFloat4(math.clamp4(result.toFloat4(), 0.0, 1.0));
            },
        }

        return result;
    }

    pub fn toLab(self: RgbColorspace, color: Colorf32) CIELab {
        return CIELab.fromXYZ(self.toXYZ(color), self.white);
    }

    pub inline fn fromLCHab(self: RgbColorspace, lch_ab: CIELCHab, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        return self.fromLab(lch_ab.toLab(), post_conversion_behavior);
    }

    pub inline fn toLCHab(self: RgbColorspace, color: Colorf32) CIELCHab {
        return self.toLab(color).toLCHab();
    }

    pub fn fromLabAlpha(self: RgbColorspace, lab: CIELabAlpha, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        const xyza = lab.toXYZAlpha(self.white);

        var result = self.fromXYZAlpha(xyza);

        switch (post_conversion_behavior) {
            .none => {},
            .clamp => {
                result = Colorf32.fromFloat4(math.clamp4(result.toFloat4(), 0.0, 1.0));
            },
        }

        return result;
    }

    pub fn toLabAlpha(self: RgbColorspace, color: Colorf32) CIELabAlpha {
        return CIELabAlpha.fromXYZAlpha(self.toXYZAlpha(color), self.white);
    }

    pub inline fn fromLCHabAlpha(self: RgbColorspace, lch_ab_alpha: CIELCHabAlpha, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        return self.fromLabAlpha(lch_ab_alpha.toLabAlpha(), post_conversion_behavior);
    }

    pub inline fn toLCHabAlpha(self: RgbColorspace, color: Colorf32) CIELCHabAlpha {
        return self.toLabAlpha(color).toLCHabAlpha();
    }

    pub fn fromLuv(self: RgbColorspace, luv: CIELuv, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        const xyz = luv.toXYZ(self.white);
        var result = self.fromXYZ(xyz);

        switch (post_conversion_behavior) {
            .none => {},
            .clamp => {
                result = Colorf32.fromFloat4(math.clamp4(result.toFloat4(), 0.0, 1.0));
            },
        }

        return result;
    }

    pub fn toLuv(self: RgbColorspace, color: Colorf32) CIELuv {
        return CIELuv.fromXYZ(self.toXYZ(color), self.white);
    }

    pub inline fn fromLCHuv(self: RgbColorspace, lch_uv: CIELCHuv, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        return self.fromLuv(lch_uv.toLuv(), post_conversion_behavior);
    }

    pub inline fn toLCHuv(self: RgbColorspace, color: Colorf32) CIELCHuv {
        return self.toLuv(color).toLCHuv();
    }

    pub fn fromLuvAlpha(self: RgbColorspace, luv: CIELuvAlpha, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        const xyza = luv.toXYZAlpha(self.white);
        var result = self.fromXYZAlpha(xyza);

        switch (post_conversion_behavior) {
            .none => {},
            .clamp => {
                result = Colorf32.fromFloat4(math.clamp4(result.toFloat4(), 0.0, 1.0));
            },
        }

        return result;
    }

    pub fn toLuvAlpha(self: RgbColorspace, color: Colorf32) CIELuvAlpha {
        return CIELuvAlpha.fromXYZAlpha(self.toXYZAlpha(color), self.white);
    }

    pub inline fn fromLCHuvAlpha(self: RgbColorspace, lch_uv: CIELCHuvAlpha, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        return self.fromLuvAlpha(lch_uv.toLuvAlpha(), post_conversion_behavior);
    }

    pub inline fn toLCHuvAlpha(self: RgbColorspace, color: Colorf32) CIELCHuvAlpha {
        return self.toLuvAlpha(color).toLCHuvAlpha();
    }

    pub fn fromHSLuv(self: RgbColorspace, hsluv: HSLuv, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        const lch = hsluv.toCIELCHuv(self.xyza_to_rgba);

        return self.fromLCHuv(lch, post_conversion_behavior);
    }

    pub fn toHSLuv(self: RgbColorspace, color: Colorf32) HSLuv {
        const lch = self.toLCHuv(color);

        return HSLuv.fromCIELChuv(lch, self.xyza_to_rgba);
    }

    pub fn fromHSLuvAlpha(self: RgbColorspace, hsluv: HSLuvAlpha, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        const lch = hsluv.toCIELCHuvAlpha(self.xyza_to_rgba);

        return self.fromLCHuvAlpha(lch, post_conversion_behavior);
    }

    pub fn toHSLuvAlpha(self: RgbColorspace, color: Colorf32) HSLuvAlpha {
        const lch = self.toLCHuvAlpha(color);

        return HSLuvAlpha.fromCIELChuvAlpha(lch, self.xyza_to_rgba);
    }

    pub fn fromOkLab(self: RgbColorspace, oklab: Oklab, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        const xyz = oklab.toXYZ();
        var result = self.fromXYZ(xyz);

        switch (post_conversion_behavior) {
            .none => {},
            .clamp => {
                result = Colorf32.fromFloat4(math.clamp4(result.toFloat4(), 0.0, 1.0));
            },
        }

        return result;
    }

    pub fn toOklab(self: RgbColorspace, color: Colorf32) Oklab {
        return Oklab.fromXYZ(self.toXYZ(color));
    }

    pub fn fromOkLabAlpha(self: RgbColorspace, oklab: OklabAlpha, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        const xyza = oklab.toXYZAlpha();
        var result = self.fromXYZAlpha(xyza);

        switch (post_conversion_behavior) {
            .none => {},
            .clamp => {
                result = Colorf32.fromFloat4(math.clamp4(result.toFloat4(), 0.0, 1.0));
            },
        }

        return result;
    }

    pub fn toOklabAlpha(self: RgbColorspace, color: Colorf32) OklabAlpha {
        return OklabAlpha.fromXYZAlpha(self.toXYZAlpha(color));
    }

    pub inline fn fromOkLCh(self: RgbColorspace, lch: OkLCh, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        return self.fromOkLab(lch.toOklab(), post_conversion_behavior);
    }

    pub inline fn toOkLCh(self: RgbColorspace, color: Colorf32) OkLCh {
        return self.toOklab(color).toOkLCh();
    }

    pub inline fn fromOkLChAlpha(self: RgbColorspace, lch: OkLChAlpha, post_conversion_behavior: PostConversionBehavior) Colorf32 {
        return self.fromOkLabAlpha(lch.toOkLabAlpha(), post_conversion_behavior);
    }

    pub inline fn toOkLChAlpha(self: RgbColorspace, color: Colorf32) OkLChAlpha {
        return self.toOklabAlpha(color).toOkLChAlpha();
    }

    pub fn sliceFromXYZAlphaInPlace(self: RgbColorspace, slice_xyza: []CIEXYZAlpha) []Colorf32 {
        const slice_rgba: []Colorf32 = @ptrCast(slice_xyza);

        for (slice_rgba) |*rgba| {
            rgba.* = Colorf32.fromFloat4(self.xyza_to_rgba.mulVector(rgba.toFloat4()));
        }

        return slice_rgba;
    }

    pub fn sliceToXYZAlphaInPlace(self: RgbColorspace, colors: []Colorf32) []CIEXYZAlpha {
        const slice_xyza: []CIEXYZAlpha = @ptrCast(colors);

        for (slice_xyza) |*xyza| {
            xyza.* = CIEXYZAlpha.fromFloat4(self.rgba_to_xyza.mulVector(xyza.toFloat4()));
        }

        return slice_xyza;
    }

    pub fn sliceFromXYZAlphaCopy(self: RgbColorspace, allocator: std.mem.Allocator, slice_xyza: []const CIEXYZAlpha) ![]Colorf32 {
        const slice_rgba: []Colorf32 = try allocator.alloc(Colorf32, slice_xyza.len);

        for (0..slice_xyza.len) |index| {
            slice_rgba[index] = Colorf32.fromFloat4(self.xyza_to_rgba.mulVector(slice_xyza[index].toFloat4()));
        }

        return slice_rgba;
    }

    pub fn sliceToXYZAlphaCopy(self: RgbColorspace, allocator: std.mem.Allocator, colors: []const Colorf32) ![]CIEXYZAlpha {
        const slice_xyza: []CIEXYZAlpha = try allocator.alloc(CIEXYZAlpha, colors.len);

        for (0..colors.len) |index| {
            slice_xyza[index] = CIEXYZAlpha.fromFloat4(self.rgba_to_xyza.mulVector(colors[index].toFloat4()));
        }

        return slice_xyza;
    }

    pub fn sliceFromLabAlphaInPlace(self: RgbColorspace, slice_lab: []CIELabAlpha, post_conversion_behavior: PostConversionBehavior) []Colorf32 {
        const slice_rgba: []Colorf32 = @ptrCast(slice_lab);

        const white_point_xyz = self.white.toXYZ(1.0);

        const all_zeroes: math.float4 = @splat(0.0);
        const all_ones: math.float4 = @splat(1.0);

        for (slice_rgba) |*rgba| {
            const lab_alpha: CIELabAlpha = @bitCast(rgba.*);

            const xyza = lab_alpha.toXYZAlphaPrecomputedWhitePoint(white_point_xyz);

            rgba.* = Colorf32.fromFloat4(self.xyza_to_rgba.mulVector(xyza.toFloat4()));

            switch (post_conversion_behavior) {
                .none => {},
                .clamp => {
                    rgba.* = Colorf32.fromFloat4(@min(@max(rgba.toFloat4(), all_zeroes), all_ones));
                },
            }
        }

        return slice_rgba;
    }

    pub fn sliceToLabAlphaInPlace(self: RgbColorspace, colors: []Colorf32) []CIELabAlpha {
        const slice_lab: []CIELabAlpha = @ptrCast(colors);

        const white_point_xyz = self.white.toXYZ(1.0);

        for (slice_lab) |*lab_alpha| {
            const xyza = CIEXYZAlpha.fromFloat4(self.rgba_to_xyza.mulVector(lab_alpha.toFloat4()));

            lab_alpha.* = CIELabAlpha.fromXYZAlphaPrecomputedWhitePoint(xyza, white_point_xyz);
        }

        return slice_lab;
    }

    pub fn sliceFromLabAlphaCopy(self: RgbColorspace, allocator: std.mem.Allocator, slice_lab: []const CIELabAlpha, post_conversion_behavior: PostConversionBehavior) ![]Colorf32 {
        const slice_rgba: []Colorf32 = try allocator.alloc(Colorf32, slice_lab.len);

        const white_point_xyz = self.white.toXYZ(1.0);

        const all_zeroes: math.float4 = @splat(0.0);
        const all_ones: math.float4 = @splat(1.0);

        for (0..slice_lab.len) |index| {
            const xyza = slice_lab[index].toXYZAlphaPrecomputedWhitePoint(white_point_xyz);

            slice_rgba[index] = Colorf32.fromFloat4(self.xyza_to_rgba.mulVector(xyza.toFloat4()));

            switch (post_conversion_behavior) {
                .none => {},
                .clamp => {
                    slice_rgba[index] = Colorf32.fromFloat4(@min(@max(slice_rgba[index].toFloat4(), all_zeroes), all_ones));
                },
            }
        }

        return slice_rgba;
    }

    pub fn sliceToLabAlphaCopy(self: RgbColorspace, allocator: std.mem.Allocator, colors: []const Colorf32) ![]CIELabAlpha {
        const slice_lab: []CIELabAlpha = try allocator.alloc(CIELabAlpha, colors.len);

        const white_point_xyz = self.white.toXYZ(1.0);

        for (0..colors.len) |index| {
            const xyza = CIEXYZAlpha.fromFloat4(self.rgba_to_xyza.mulVector(colors[index].toFloat4()));

            slice_lab[index] = CIELabAlpha.fromXYZAlphaPrecomputedWhitePoint(xyza, white_point_xyz);
        }

        return slice_lab;
    }

    pub fn sliceFromLuvAlphaInPlace(self: RgbColorspace, slice_luv: []CIELuvAlpha, post_conversion_behavior: PostConversionBehavior) []Colorf32 {
        const slice_rgba: []Colorf32 = @ptrCast(slice_luv);

        const white_point_xyz = self.white.toXYZ(1.0);

        const all_zeroes: math.float4 = @splat(0.0);
        const all_ones: math.float4 = @splat(1.0);

        for (slice_rgba) |*rgba| {
            const luv_alpha: CIELuvAlpha = @bitCast(rgba.*);

            const xyza = luv_alpha.toXYZAlphaPrecomputedWhitePoint(white_point_xyz);

            rgba.* = Colorf32.fromFloat4(self.xyza_to_rgba.mulVector(xyza.toFloat4()));

            switch (post_conversion_behavior) {
                .none => {},
                .clamp => {
                    rgba.* = Colorf32.fromFloat4(@min(@max(rgba.toFloat4(), all_zeroes), all_ones));
                },
            }
        }

        return slice_rgba;
    }

    pub fn sliceToLuvAlphaInPlace(self: RgbColorspace, colors: []Colorf32) []CIELuvAlpha {
        const slice_luv: []CIELuvAlpha = @ptrCast(colors);

        const white_point_xyz = self.white.toXYZ(1.0);

        for (slice_luv) |*luv_alpha| {
            const xyza = CIEXYZAlpha.fromFloat4(self.rgba_to_xyza.mulVector(luv_alpha.toFloat4()));

            luv_alpha.* = CIELuvAlpha.fromXYZAlphaPrecomputedWhitePoint(xyza, white_point_xyz);
        }

        return slice_luv;
    }

    pub fn sliceFromLuvAlphaCopy(self: RgbColorspace, allocator: std.mem.Allocator, slice_luv: []const CIELuvAlpha, post_conversion_behavior: PostConversionBehavior) ![]Colorf32 {
        const slice_rgba: []Colorf32 = try allocator.alloc(Colorf32, slice_luv.len);

        const white_point_xyz = self.white.toXYZ(1.0);

        const all_zeroes: math.float4 = @splat(0.0);
        const all_ones: math.float4 = @splat(1.0);

        for (0..slice_luv.len) |index| {
            const luv_alpha = slice_luv[index];

            const xyza = luv_alpha.toXYZAlphaPrecomputedWhitePoint(white_point_xyz);

            slice_rgba[index] = Colorf32.fromFloat4(self.xyza_to_rgba.mulVector(xyza.toFloat4()));

            switch (post_conversion_behavior) {
                .none => {},
                .clamp => {
                    slice_rgba[index] = Colorf32.fromFloat4(@min(@max(slice_rgba[index].toFloat4(), all_zeroes), all_ones));
                },
            }
        }

        return slice_rgba;
    }

    pub fn sliceToLuvAlphaCopy(self: RgbColorspace, allocator: std.mem.Allocator, colors: []const Colorf32) ![]CIELuvAlpha {
        const slice_luv: []CIELuvAlpha = try allocator.alloc(CIELuvAlpha, colors.len);

        const white_point_xyz = self.white.toXYZ(1.0);

        for (0..colors.len) |index| {
            const xyza = CIEXYZAlpha.fromFloat4(self.rgba_to_xyza.mulVector(colors[index].toFloat4()));

            slice_luv[index] = CIELuvAlpha.fromXYZAlphaPrecomputedWhitePoint(xyza, white_point_xyz);
        }

        return slice_luv;
    }

    pub fn sliceFromOkLabAlphaInPlace(self: RgbColorspace, slice_lab: []OklabAlpha, post_conversion_behavior: PostConversionBehavior) []Colorf32 {
        const slice_rgba: []Colorf32 = @ptrCast(slice_lab);

        const all_zeroes: math.float4 = @splat(0.0);
        const all_ones: math.float4 = @splat(1.0);

        for (slice_rgba) |*rgba| {
            const lab_alpha: OklabAlpha = @bitCast(rgba.*);

            const xyza = lab_alpha.toXYZAlpha();

            rgba.* = Colorf32.fromFloat4(self.xyza_to_rgba.mulVector(xyza.toFloat4()));

            switch (post_conversion_behavior) {
                .none => {},
                .clamp => {
                    rgba.* = Colorf32.fromFloat4(@min(@max(rgba.toFloat4(), all_zeroes), all_ones));
                },
            }
        }

        return slice_rgba;
    }

    pub fn sliceToOklabAlphaInPlace(self: RgbColorspace, colors: []Colorf32) []OklabAlpha {
        const slice_lab: []OklabAlpha = @ptrCast(colors);

        for (slice_lab) |*lab_alpha| {
            const xyza = CIEXYZAlpha.fromFloat4(self.rgba_to_xyza.mulVector(lab_alpha.toFloat4()));

            lab_alpha.* = OklabAlpha.fromXYZAlpha(xyza);
        }

        return slice_lab;
    }

    pub fn sliceFromOkLabAlphaCopy(self: RgbColorspace, allocator: std.mem.Allocator, slice_lab: []const OklabAlpha, post_conversion_behavior: PostConversionBehavior) ![]Colorf32 {
        const slice_rgba: []Colorf32 = try allocator.alloc(Colorf32, slice_lab.len);

        const all_zeroes: math.float4 = @splat(0.0);
        const all_ones: math.float4 = @splat(1.0);

        for (0..slice_lab.len) |index| {
            const lab_alpha: OklabAlpha = slice_lab[index];

            const xyza = lab_alpha.toXYZAlpha();

            slice_rgba[index] = Colorf32.fromFloat4(self.xyza_to_rgba.mulVector(xyza.toFloat4()));

            switch (post_conversion_behavior) {
                .none => {},
                .clamp => {
                    slice_rgba[index] = Colorf32.fromFloat4(@min(@max(slice_rgba[index].toFloat4(), all_zeroes), all_ones));
                },
            }
        }

        return slice_rgba;
    }

    pub fn sliceToOklabAlphaCopy(self: RgbColorspace, allocator: std.mem.Allocator, colors: []const Colorf32) ![]OklabAlpha {
        const slice_lab: []OklabAlpha = try allocator.alloc(OklabAlpha, colors.len);

        for (0..colors.len) |index| {
            const xyza = CIEXYZAlpha.fromFloat4(self.rgba_to_xyza.mulVector(colors[index].toFloat4()));

            slice_lab[index] = OklabAlpha.fromXYZAlpha(xyza);
        }

        return slice_lab;
    }

    pub fn convertColor(source: RgbColorspace, target: RgbColorspace, color: Colorf32) Colorf32 {
        const conversion_matrix = computeConversionMatrix(source, target);

        const color_float4 = color.toFloat4();
        const result = conversion_matrix.mulVector(color_float4);

        return Colorf32.fromFloat4(result);
    }

    pub fn convertColors(source: RgbColorspace, target: RgbColorspace, colors: []Colorf32) void {
        const conversion_matrix = computeConversionMatrix(source, target);

        for (colors) |*color| {
            const color_float4 = color.toFloat4();
            color.* = Colorf32.fromFloat4(conversion_matrix.mulVector(color_float4));
        }
    }

    fn toXYZConversionMatrix(self: RgbColorspace) ConversionMatrix {
        // Adapted from http://docs-hoffmann.de/ciexyz29082000.pdf
        const D = (self.red.x - self.blue.x) * (self.green.y - self.blue.y) - (self.red.y - self.blue.y) * (self.green.x - self.blue.x);
        const U = (self.white.x - self.blue.x) * (self.green.y - self.blue.y) - (self.white.y - self.blue.y) * (self.green.x - self.blue.x);
        const V = (self.red.x - self.blue.x) * (self.white.y - self.blue.y) - (self.red.y - self.blue.y) * (self.white.x - self.blue.x);

        const u = U / D;
        const v = V / D;
        const w = 1.0 - u - v;

        return ConversionMatrix.fromArray(.{
            u * (self.red.x / self.white.y),   v * (self.green.x / self.white.y),   w * (self.blue.x / self.white.y),   0.0,
            u * (self.red.y / self.white.y),   v * (self.green.y / self.white.y),   w * (self.blue.y / self.white.y),   0.0,
            u * (self.red.z() / self.white.y), v * (self.green.z() / self.white.y), w * (self.blue.z() / self.white.y), 0.0,
            0.0,                               0.0,                                 0.0,                                1.0,
        });
    }

    fn computeConversionMatrix(source: RgbColorspace, target: RgbColorspace) math.float4x4 {
        const source_to_xyz_matrix = source.rgba_to_xyza;
        const target_to_rgb_matrix = target.xyza_to_rgba;

        if (source.white.equals(target.white)) {
            return target_to_rgb_matrix.mul(source_to_xyz_matrix);
        }

        const bradford_mapping = math.float4x4.fromArray(.{
            0.8951000,  0.2664000,  -0.1614000, 0.0,
            -0.7502000, 1.7135000,  0.0367000,  0.0,
            0.0389000,  -0.0685000, 1.0296000,  0.0,
            0.0,        0.0,        0.0,        1.0,
        });

        const bradford_inverse = math.float4x4.fromArray(.{
            0.9869929,  -0.1470543, 0.1599627, 0.0,
            0.4323053,  0.5183603,  0.0492912, 0.0,
            -0.0085287, 0.0400428,  0.9684867, 0.0,
            0.0,        0.0,        0.0,       1.0,
        });

        const source_white_xyz = source.white.toXYZ(1.0);
        const target_white_xyz = target.white.toXYZ(1.0);

        const source_white_float4: math.float4 = .{ source_white_xyz.x, source_white_xyz.y, source_white_xyz.z, 1.0 };
        const target_white_float4: math.float4 = .{ target_white_xyz.x, target_white_xyz.y, target_white_xyz.z, 1.0 };

        const source_cone_response = bradford_mapping.mulVector(source_white_float4);
        const target_cone_response = bradford_mapping.mulVector(target_white_float4);

        const scale_matrix = math.float4x4.fromArray(.{
            target_cone_response[0] / source_cone_response[0], 0.0,                                               0.0,                                               0.0,
            0.0,                                               target_cone_response[1] / source_cone_response[1], 0.0,                                               0.0,
            0.0,                                               0.0,                                               target_cone_response[2] / source_cone_response[2], 0.0,
            0.0,                                               0.0,                                               0.0,                                               1.0,
        });
        const chromatic_adaptation_matrix = bradford_inverse.mul(scale_matrix).mul(bradford_mapping);

        return target_to_rgb_matrix.mul(chromatic_adaptation_matrix).mul(source_to_xyz_matrix);
    }

    fn gammaNoTransfer(value: f32) f32 {
        return value;
    }
};

pub inline fn applyGamma(value: f32, gamma: f32) f32 {
    return std.math.pow(f32, value, 1.0 / gamma);
}

pub inline fn removeGamma(value: f32, gamma: f32) f32 {
    return std.math.pow(f32, value, gamma);
}

pub const GammaFunctionsParameters = struct {
    alpha: f32 = 0.0,
    beta: f32 = 0.0,
    delta: f32 = 0.0,
    gamma: f32 = 1.0,
    transition_point: f32 = 0.0,
    display_gamma: f32 = 1.0,
};

pub fn NonLinearGammaTransferFunctions(comptime params: GammaFunctionsParameters) type {
    return struct {
        const alpha_minus_1 = params.alpha - 1.0;

        pub fn toGamma(value: f32) f32 {
            if (value <= params.beta) {
                return value * params.delta;
            }

            return params.alpha * std.math.pow(f32, value, 1.0 / params.gamma) - alpha_minus_1;
        }

        pub fn toGammaFast(value: f32) f32 {
            return applyGamma(value, params.display_gamma);
        }

        pub fn toLinear(value: f32) f32 {
            if (value <= params.transition_point) {
                return value / params.delta;
            }

            return std.math.pow(f32, (value + alpha_minus_1) / params.alpha, params.gamma);
        }

        pub fn toLinearFast(value: f32) f32 {
            return removeGamma(value, params.display_gamma);
        }
    };
}

pub fn CurveGammaTransferFunctions(comptime gamma: f32) type {
    return struct {
        pub fn toGamma(value: f32) f32 {
            return applyGamma(value, gamma);
        }

        pub fn toGammaFast(value: f32) f32 {
            return applyGamma(value, gamma);
        }

        pub fn toLinear(value: f32) f32 {
            return removeGamma(value, gamma);
        }

        pub fn toLinearFast(value: f32) f32 {
            return removeGamma(value, gamma);
        }
    };
}

pub const sRGB_TransferFunctions = NonLinearGammaTransferFunctions(.{
    .alpha = 1.055,
    .beta = 0.0031308,
    .delta = 12.92,
    .gamma = 12.0 / 5.0,
    .transition_point = 0.04045,
    .display_gamma = 2.2,
});

pub const Rec601_TransferFunctions = NonLinearGammaTransferFunctions(.{
    .alpha = 1.099,
    .beta = 0.004,
    .delta = 4.5,
    .gamma = 20.0 / 9.0,
    .transition_point = 0.018,
    .display_gamma = 2.2,
});

pub const Rec709_TransferFunctions = NonLinearGammaTransferFunctions(.{
    .alpha = 1.099,
    .beta = 0.004,
    .delta = 4.5,
    .gamma = 20.0 / 9.0,
    .transition_point = 0.018,
    .display_gamma = 2.2,
});

pub const BT2020_TransferFunctions = NonLinearGammaTransferFunctions(.{
    .alpha = 1.0993,
    .beta = 0.004,
    .delta = 4.5,
    .gamma = 20.0 / 9.0,
    .transition_point = 0.0181,
    .display_gamma = 2.2,
});

pub const ProPhotoRGB_TransferFunctions = NonLinearGammaTransferFunctions(.{
    .alpha = 1,
    .beta = 0.001953125,
    .delta = 16,
    .gamma = 9.0 / 5.0,
    .transition_point = 0.031248,
    .display_gamma = 1.8,
});

pub const DCIP3_TransferFuntions = CurveGammaTransferFunctions(13.0 / 5.0);
pub const AdobeRGB_TransferFunctions = CurveGammaTransferFunctions(563.0 / 256.0);

// All white points are defined with the CIE 1931 2 degrees
pub const WhitePoints = struct {
    pub const A = CIExyY{ .x = 0.44758, .y = 0.40745 };
    pub const B = CIExyY{ .x = 0.34842, .y = 0.35161 };
    pub const C = CIExyY{ .x = 0.31006, .y = 0.31616 };
    pub const D50 = CIExyY{ .x = 0.34567, .y = 0.35850 };
    pub const D55 = CIExyY{ .x = 0.33242, .y = 0.34743 };
    pub const D65 = CIExyY{ .x = 0.31271, .y = 0.32902 };
    pub const D75 = CIExyY{ .x = 0.29902, .y = 0.31485 };
    pub const D93 = CIExyY{ .x = 0.28315, .y = 0.29711 };
    pub const E = CIExyY{ .x = 0.33333, .y = 0.33333 };
    pub const F1 = CIExyY{ .x = 0.31310, .y = 0.33727 };
    pub const F2 = CIExyY{ .x = 0.37208, .y = 0.37529 };
    pub const F3 = CIExyY{ .x = 0.40910, .y = 0.39430 };
    pub const F4 = CIExyY{ .x = 0.44018, .y = 0.40329 };
    pub const F5 = CIExyY{ .x = 0.31379, .y = 0.34531 };
    pub const F6 = CIExyY{ .x = 0.37790, .y = 0.38835 };
    pub const F7 = CIExyY{ .x = 0.31292, .y = 0.32933 };
    pub const F8 = CIExyY{ .x = 0.34588, .y = 0.35875 };
    pub const F9 = CIExyY{ .x = 0.37417, .y = 0.37281 };
    pub const F10 = CIExyY{ .x = 0.34609, .y = 0.35986 };
    pub const F11 = CIExyY{ .x = 0.38052, .y = 0.37713 };
    pub const F12 = CIExyY{ .x = 0.43695, .y = 0.40441 };
    pub const LED_B1 = CIExyY{ .x = 0.4560, .y = 0.4078 };
    pub const LED_B2 = CIExyY{ .x = 0.4357, .y = 0.4012 };
    pub const LED_B3 = CIExyY{ .x = 0.3756, .y = 0.3723 };
    pub const LED_B4 = CIExyY{ .x = 0.3422, .y = 0.3502 };
    pub const LED_B5 = CIExyY{ .x = 0.3118, .y = 0.3236 };
    pub const LED_BH1 = CIExyY{ .x = 0.4474, .y = 0.4066 };
    pub const LED_RGB1 = CIExyY{ .x = 0.4557, .y = 0.4211 };
    pub const LED_V1 = CIExyY{ .x = 0.4560, .y = 0.4548 };
    pub const LED_V2 = CIExyY{ .x = 0.3781, .y = 0.3781 };
};

// BT.601-6 (NTSC)
pub const BT601_NTSC = RgbColorspace.init(.{
    .red = .{ .x = 0.630, .y = 0.340 },
    .green = .{ .x = 0.310, .y = 0.595 },
    .blue = .{ .x = 0.155, .y = 0.070 },
    .white = WhitePoints.D65,
    .to_gamma = Rec601_TransferFunctions.toGamma,
    .to_gamma_fast = Rec601_TransferFunctions.toGammaFast,
    .to_linear = Rec601_TransferFunctions.toLinear,
    .to_linear_fast = Rec601_TransferFunctions.toLinearFast,
});

// BT.601-6 (PAL)
pub const BT601_PAL = RgbColorspace.init(.{
    .red = .{ .x = 0.640, .y = 0.330 },
    .green = .{ .x = 0.290, .y = 0.600 },
    .blue = .{ .x = 0.150, .y = 0.060 },
    .white = WhitePoints.D65,
    .to_gamma = Rec601_TransferFunctions.toGamma,
    .to_gamma_fast = Rec601_TransferFunctions.toGammaFast,
    .to_linear = Rec601_TransferFunctions.toLinear,
    .to_linear_fast = Rec601_TransferFunctions.toLinearFast,
});

// ITU-R BT.709 aka Rec.709
pub const BT709 = RgbColorspace.init(.{
    .red = .{ .x = 0.6400, .y = 0.3300 },
    .green = .{ .x = 0.3000, .y = 0.6000 },
    .blue = .{ .x = 0.1500, .y = 0.0600 },
    .white = WhitePoints.D65,
    .to_gamma = Rec709_TransferFunctions.toGamma,
    .to_gamma_fast = Rec709_TransferFunctions.toGammaFast,
    .to_linear = Rec709_TransferFunctions.toLinear,
    .to_linear_fast = Rec709_TransferFunctions.toLinearFast,
});

// sRGB use the same color gamut as BT.709 but have a different transfer function
pub const sRGB = RgbColorspace.init(.{
    .red = .{ .x = 0.6400, .y = 0.3300 },
    .green = .{ .x = 0.3000, .y = 0.6000 },
    .blue = .{ .x = 0.1500, .y = 0.0600 },
    .white = WhitePoints.D65,
    .to_gamma = sRGB_TransferFunctions.toGamma,
    .to_gamma_fast = sRGB_TransferFunctions.toGammaFast,
    .to_linear = sRGB_TransferFunctions.toLinear,
    .to_linear_fast = sRGB_TransferFunctions.toLinearFast,
});

//  Digital Cinema Initiatives P3 color spaces
pub const DCIP3 = struct {
    // Display P3 usee the same transfer function as sRGB
    pub const Display = RgbColorspace.init(.{
        .red = .{ .x = 0.680, .y = 0.320 },
        .green = .{ .x = 0.265, .y = 0.690 },
        .blue = .{ .x = 0.150, .y = 0.060 },
        .white = WhitePoints.D65,
        .to_gamma = sRGB_TransferFunctions.toGamma,
        .to_gamma_fast = sRGB_TransferFunctions.toGammaFast,
        .to_linear = sRGB_TransferFunctions.toLinear,
        .to_linear_fast = sRGB_TransferFunctions.toLinearFast,
    });

    pub const Theater = RgbColorspace.init(.{
        .red = .{ .x = 0.680, .y = 0.320 },
        .green = .{ .x = 0.265, .y = 0.690 },
        .blue = .{ .x = 0.150, .y = 0.060 },
        .white = .{ .x = 0.314, .y = 0.351 },
        .to_gamma = DCIP3_TransferFuntions.toGamma,
        .to_gamma_fast = DCIP3_TransferFuntions.toGammaFast,
        .to_linear = DCIP3_TransferFuntions.toLinear,
        .to_linear_fast = DCIP3_TransferFuntions.toLinearFast,
    });

    pub const ACES = RgbColorspace.init(.{
        .red = .{ .x = 0.680, .y = 0.320 },
        .green = .{ .x = 0.265, .y = 0.690 },
        .blue = .{ .x = 0.150, .y = 0.060 },
        .white = .{ .x = 0.32168, .y = 0.33767 },
        .to_gamma = DCIP3_TransferFuntions.toGamma,
        .to_gamma_fast = DCIP3_TransferFuntions.toGammaFast,
        .to_linear = DCIP3_TransferFuntions.toLinear,
        .to_linear_fast = DCIP3_TransferFuntions.toLinearFast,
    });
};

// ITU-R BT.2020 aka Rec.2020, Rec.2100 use the same color space
pub const BT2020 = RgbColorspace.init(.{
    .red = .{ .x = 0.708, .y = 0.292 },
    .green = .{ .x = 0.170, .y = 0.797 },
    .blue = .{ .x = 0.131, .y = 0.046 },
    .white = WhitePoints.D65,
    .to_gamma = BT2020_TransferFunctions.toGamma,
    .to_gamma_fast = BT2020_TransferFunctions.toGammaFast,
    .to_linear = BT2020_TransferFunctions.toLinear,
    .to_linear_fast = BT2020_TransferFunctions.toLinearFast,
});

pub const AdobeRGB = RgbColorspace.init(.{
    .red = .{ .x = 0.6400, .y = 0.3300 },
    .green = .{ .x = 0.2100, .y = 0.7100 },
    .blue = .{ .x = 0.1500, .y = 0.0600 },
    .white = WhitePoints.D65,
    .to_gamma = AdobeRGB_TransferFunctions.toGamma,
    .to_gamma_fast = AdobeRGB_TransferFunctions.toGammaFast,
    .to_linear = AdobeRGB_TransferFunctions.toLinear,
    .to_linear_fast = AdobeRGB_TransferFunctions.toLinearFast,
});

pub const AdobeWideGamutRGB = RgbColorspace.init(.{
    .red = .{ .x = 0.7347, .y = 0.2653 },
    .green = .{ .x = 0.1152, .y = 0.8264 },
    .blue = .{ .x = 0.1566, .y = 0.0177 },
    .white = WhitePoints.D50,
    .to_gamma = AdobeRGB_TransferFunctions.toGamma,
    .to_gamma_fast = AdobeRGB_TransferFunctions.toGammaFast,
    .to_linear = AdobeRGB_TransferFunctions.toLinear,
    .to_linear_fast = AdobeRGB_TransferFunctions.toLinearFast,
});

pub const ProPhotoRGB = RgbColorspace.init(.{
    .red = .{ .x = 0.734699, .y = 0.265301 },
    .green = .{ .x = 0.159597, .y = 0.840403 },
    .blue = .{ .x = 0.036598, .y = 0.000105 },
    .white = WhitePoints.D50,
    .to_gamma = ProPhotoRGB_TransferFunctions.toGamma,
    .to_gamma_fast = ProPhotoRGB_TransferFunctions.toGammaFast,
    .to_linear = ProPhotoRGB_TransferFunctions.toLinear,
    .to_linear_fast = ProPhotoRGB_TransferFunctions.toLinearFast,
});
