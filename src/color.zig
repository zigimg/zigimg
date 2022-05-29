const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const TypeInfo = std.builtin.TypeInfo;

pub inline fn toIntColor(comptime T: type, value: f32) T {
    const float_value = @round(value * @intToFloat(f32, math.maxInt(T)));
    return @floatToInt(T, math.clamp(float_value, math.minInt(T), math.maxInt(T)));
}

pub inline fn toF32Color(value: anytype) f32 {
    return @intToFloat(f32, value) / @intToFloat(f32, math.maxInt(@TypeOf(value)));
}

pub const Colorf32 = packed struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1.0,

    const Self = @This();

    pub fn initRgb(r: f32, g: f32, b: f32) Self {
        return Self{
            .r = r,
            .g = g,
            .b = b,
        };
    }

    pub fn initRgba(r: f32, g: f32, b: f32, a: f32) Self {
        return Self{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }

    pub fn fromU32Rgba(value: u32) Self {
        return Self{
            .r = toF32Color(@truncate(u8, value >> 24)),
            .g = toF32Color(@truncate(u8, value >> 16)),
            .b = toF32Color(@truncate(u8, value >> 8)),
            .a = toF32Color(@truncate(u8, value)),
        };
    }

    pub fn toU32Rgba(self: Self) u32 {
        return @as(u32, toIntColor(u8, self.r)) << 24 |
            @as(u32, toIntColor(u8, self.g)) << 16 |
            @as(u32, toIntColor(u8, self.b)) << 8 |
            @as(u32, toIntColor(u8, self.a));
    }

    pub fn fromU64Rgba(value: u64) Self {
        return Self{
            .r = toF32Color(@truncate(u16, value >> 48)),
            .g = toF32Color(@truncate(u16, value >> 32)),
            .b = toF32Color(@truncate(u16, value >> 16)),
            .a = toF32Color(@truncate(u16, value)),
        };
    }

    pub fn toU64Rgba(self: Self) u64 {
        return @as(u64, toIntColor(u16, self.r)) << 48 |
            @as(u64, toIntColor(u16, self.g)) << 32 |
            @as(u64, toIntColor(u16, self.b)) << 16 |
            @as(u64, toIntColor(u16, self.a));
    }

    pub fn toPremultipliedAlpha(self: Self) Self {
        return Self{
            .r = self.r * self.a,
            .g = self.g * self.a,
            .b = self.b * self.a,
            .a = self.a,
        };
    }

    pub fn toRgba(self: Self, comptime T: type) RgbaColor(T) {
        return .{
            .r = toIntColor(T, self.r),
            .g = toIntColor(T, self.g),
            .b = toIntColor(T, self.b),
            .a = toIntColor(T, self.a),
        };
    }

    pub fn toRgba32(self: Self) Rgba32 {
        return self.toRgba(u8);
    }

    pub fn toRgba64(self: Self) Rgba64 {
        return self.toRgba(u16);
    }

    pub fn toArray(self: Self) [4]f32 {
        return @bitCast([4]f32, self);
    }

    pub fn fromArray(value: [4]f32) Self {
        return @bitCast(Self, value);
    }
};

fn RgbMethods(comptime Self: type) type {
    return struct {
        const RT = std.meta.fieldInfo(Self, .r).field_type;
        const GT = std.meta.fieldInfo(Self, .g).field_type;
        const BT = std.meta.fieldInfo(Self, .b).field_type;
        const r_bits = @typeInfo(RT).Int.bits;
        const g_bits = @typeInfo(GT).Int.bits;
        const b_bits = @typeInfo(BT).Int.bits;
        const AT = RT; // We assume Alpha type is same as Red type

        pub fn initRgb(r: RT, g: GT, b: BT) Self {
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
                .a = if (@hasField(Self, "a")) toF32Color(self.a) else 1.0,
            };
        }

        pub fn fromU32Rgba(value: u32) Self {
            return switch (RT) {
                u5, u8 => blk: {
                    var res = Self{
                        .r = @truncate(RT, value >> (32 - r_bits)),
                        .g = @truncate(GT, value >> (24 - g_bits)),
                        .b = @truncate(BT, value >> (16 - b_bits)),
                    };
                    // This if can only be true for u8 here
                    if (@hasField(Self, "a")) res.a = @truncate(AT, value);
                    break :blk res;
                },
                u16 => blk: {
                    var res = Self{
                        .r = @truncate(RT, value >> 24) * 257,
                        .g = @truncate(GT, value >> 16 & 0xff) * 257,
                        .b = @truncate(BT, value >> 8 & 0xff) * 257,
                    };
                    if (@hasField(Self, "a")) res.a = @truncate(AT, value & 0xff) * 257;
                    break :blk res;
                },
                else => unreachable,
            };
        }

        pub fn fromU32Rgb(value: u32) Self {
            return switch (RT) {
                u5, u8 => Self{
                    .r = @truncate(RT, value >> (24 - r_bits)),
                    .g = @truncate(GT, value >> (16 - g_bits)),
                    .b = @truncate(BT, value >> (8 - b_bits)),
                },
                u16 => Self{
                    .r = @truncate(RT, value >> 16 & 0xff) * 257,
                    .g = @truncate(GT, value >> 8 & 0xff) * 257,
                    .b = @truncate(BT, value & 0xff) * 257,
                },
                else => unreachable,
            };
        }

        pub fn fromU64Rgba(value: u64) Self {
            return switch (RT) {
                u5, u8 => blk: {
                    var res = Self{
                        .r = @truncate(RT, value >> (64 - r_bits)),
                        .g = @truncate(GT, value >> (48 - g_bits)),
                        .b = @truncate(BT, value >> (32 - b_bits)),
                    };
                    // This if can only be true for u8 here
                    if (@hasField(Self, "a")) res.a = @truncate(AT, value >> 8);
                    break :blk res;
                },
                u16 => blk: {
                    var res = Self{
                        .r = @truncate(RT, value >> 48),
                        .g = @truncate(GT, value >> 32),
                        .b = @truncate(BT, value >> 16),
                    };
                    if (@hasField(Self, "a")) res.a = @truncate(AT, value);
                    break :blk res;
                },
                else => unreachable,
            };
        }

        pub fn fromU64Rgb(value: u64) Self {
            return switch (RT) {
                u5, u8 => Self{
                    .r = @truncate(RT, value >> (48 - r_bits)),
                    .g = @truncate(GT, value >> (32 - g_bits)),
                    .b = @truncate(BT, value >> (16 - b_bits)),
                },
                u16 => Self{
                    .r = @truncate(RT, value >> 32),
                    .g = @truncate(GT, value >> 16),
                    .b = @truncate(BT, value),
                },
                else => unreachable,
            };
        }

        pub fn toU32Rgba(self: Self) u32 {
            return switch (GT) {
                u5 => ((@as(u32, self.r) * 255 + 15) / 31) << 24 |
                    ((@as(u32, self.g) * 255 + 15) / 31) << 16 |
                    ((@as(u32, self.b) * 255 + 15) / 31) << 8 |
                    0xff,
                u6 => ((@as(u32, self.r) * 255 + 15) / 31) << 24 |
                    ((@as(u32, self.g) * 255 + 31) / 63) << 16 |
                    ((@as(u32, self.b) * 255 + 15) / 31) << 8 |
                    0xff,
                u8 => @as(u32, self.r) << 24 |
                    @as(u32, self.g) << 16 |
                    @as(u32, self.b) << 8 |
                    if (@hasField(Self, "a")) @as(u32, self.a) else 0xff,
                u16 => @as(u32, self.r & 0xff00) << 16 |
                    @as(u32, self.g & 0xff00) << 8 |
                    @as(u32, self.b & 0xff00) |
                    if (@hasField(Self, "a")) @as(u32, self.a) >> 8 else 0xff,
                else => unreachable,
            };
        }

        pub fn toU32Rgb(self: Self) u32 {
            return switch (GT) {
                u5 => ((@as(u32, self.r) * 255 + 15) / 31) << 16 |
                    ((@as(u32, self.g) * 255 + 15) / 31) << 8 |
                    ((@as(u32, self.b) * 255 + 15) / 31),
                u6 => ((@as(u32, self.r) * 255 + 15) / 31) << 16 |
                    ((@as(u32, self.g) * 255 + 31) / 63) << 8 |
                    ((@as(u32, self.b) * 255 + 15) / 31),
                u8 => @as(u32, self.r) << 16 |
                    @as(u32, self.g) << 8 |
                    @as(u32, self.b),
                u16 => @as(u32, self.r & 0xff00) << 8 |
                    @as(u32, self.g & 0xff00) |
                    @as(u32, self.b & 0xff00) >> 8,
                else => unreachable,
            };
        }

        pub fn toU64Rgba(self: Self) u64 {
            return switch (GT) {
                u5 => ((@as(u64, self.r) * 65535 + 15) / 31) << 48 |
                    ((@as(u64, self.g) * 65535 + 15) / 31) << 32 |
                    ((@as(u64, self.b) * 65535 + 15) / 31) << 16 |
                    0xff,
                u6 => ((@as(u64, self.r) * 65535 + 15) / 31) << 48 |
                    ((@as(u64, self.g) * 65535 + 31) / 63) << 32 |
                    ((@as(u64, self.b) * 65535 + 15) / 31) << 16 |
                    0xff,
                u8 => ((@as(u64, self.r) * 65535 + 127) / 255) << 48 |
                    ((@as(u64, self.g) * 65535 + 127) / 255) << 32 |
                    ((@as(u64, self.b) * 65535 + 127) / 255) << 16 |
                    if (@hasField(Self, "a")) (@as(u64, self.a) * 65535 + 127) / 255 else 0xffff,
                u16 => @as(u64, self.r) << 48 |
                    @as(u64, self.g) << 32 |
                    @as(u64, self.b) << 16 |
                    if (@hasField(Self, "a")) @as(u64, self.a) else 0xffff,
                else => unreachable,
            };
        }

        pub fn toU64Rgb(self: Self) u64 {
            return switch (GT) {
                u5 => ((@as(u64, self.r) * 65535 + 15) / 31) << 32 |
                    ((@as(u64, self.g) * 65535 + 15) / 31) << 16 |
                    ((@as(u64, self.b) * 65535 + 15) / 31),
                u6 => ((@as(u64, self.r) * 65535 + 15) / 31) << 32 |
                    ((@as(u64, self.g) * 65535 + 31) / 63) << 16 |
                    ((@as(u64, self.b) * 65535 + 15) / 31),
                u8 => ((@as(u64, self.r) * 65535 + 127) / 255) << 32 |
                    ((@as(u64, self.g) * 65535 + 127) / 255) << 16 |
                    ((@as(u64, self.b) * 65535 + 127) / 255),
                u16 => @as(u64, self.r) << 16 |
                    @as(u64, self.g) << 8 |
                    @as(u64, self.b),
                else => unreachable,
            };
        }
    };
}

fn RgbaMethods(comptime Self: type) type {
    return struct {
        const T = std.meta.fieldInfo(Self, .r).field_type;
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
            const max = math.maxInt(T);
            return Self{
                .r = @truncate(T, (@as(u32, self.r) * self.a + max / 2) / max),
                .g = @truncate(T, (@as(u32, self.g) * self.a + max / 2) / max),
                .b = @truncate(T, (@as(u32, self.b) * self.a + max / 2) / max),
                .a = self.a,
            };
        }
    };
}

fn RgbColor(comptime T: type) type {
    return packed struct {
        r: T,
        g: T,
        b: T,

        pub usingnamespace RgbMethods(@This());
    };
}

// Rgb565
// OpenGL: n/a
// Vulkan: n/a
// Direct3D/DXGI: n/a
pub const Rgb565 = packed struct {
    r: u5,
    g: u6,
    b: u5,

    pub usingnamespace RgbMethods(@This());
};

fn RgbaColor(comptime T: type) type {
    return packed struct {
        r: T,
        g: T,
        b: T,
        a: T = math.maxInt(T),

        pub usingnamespace RgbMethods(@This());
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

// Rgb555
// OpenGL: GL_RGB5
// Vulkan: VK_FORMAT_R5G6B5_UNORM_PACK16
// Direct3D/DXGI: n/a
pub const Rgb555 = RgbColor(u5);

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
    return packed struct {
        b: T,
        g: T,
        r: T,

        pub usingnamespace RgbMethods(@This());
    };
}

fn BgraColor(comptime T: type) type {
    return packed struct {
        b: T,
        g: T,
        r: T,
        a: T = math.maxInt(T),

        pub usingnamespace RgbMethods(@This());
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
        palette: []Colorf32,
        indices: []T,

        pub const PaletteSize = 1 << @bitSizeOf(T);

        const Self = @This();

        pub fn init(allocator: Allocator, pixel_count: usize) !Self {
            return Self{
                .indices = try allocator.alloc(T, pixel_count),
                .palette = try allocator.alloc(Colorf32, PaletteSize),
            };
        }

        pub fn deinit(self: Self, allocator: Allocator) void {
            allocator.free(self.palette);
            allocator.free(self.indices);
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
        alpha: T = math.maxInt(T),

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
    indexed1: IndexedStorage1,
    indexed2: IndexedStorage2,
    indexed4: IndexedStorage4,
    indexed8: IndexedStorage8,
    indexed16: IndexedStorage16,
    grayscale1: []Grayscale1,
    grayscale2: []Grayscale2,
    grayscale4: []Grayscale4,
    grayscale8: []Grayscale8,
    grayscale8Alpha: []Grayscale8Alpha,
    grayscale16: []Grayscale16,
    grayscale16Alpha: []Grayscale16Alpha,
    rgb24: []Rgb24,
    rgba32: []Rgba32,
    rgb565: []Rgb565,
    rgb555: []Rgb555,
    bgr24: []Bgr24,
    bgra32: []Bgra32,
    rgb48: []Rgb48,
    rgba64: []Rgba64,
    float32: []Colorf32,

    const Self = @This();

    pub fn init(allocator: Allocator, format: PixelFormat, pixel_count: usize) !Self {
        return switch (format) {
            .indexed1 => {
                return Self{
                    .indexed1 = try IndexedStorage(u1).init(allocator, pixel_count),
                };
            },
            .indexed2 => {
                return Self{
                    .indexed2 = try IndexedStorage(u2).init(allocator, pixel_count),
                };
            },
            .indexed4 => {
                return Self{
                    .indexed4 = try IndexedStorage(u4).init(allocator, pixel_count),
                };
            },
            .indexed8 => {
                return Self{
                    .indexed8 = try IndexedStorage(u8).init(allocator, pixel_count),
                };
            },
            .indexed16 => {
                return Self{
                    .indexed16 = try IndexedStorage(u16).init(allocator, pixel_count),
                };
            },
            .grayscale1 => {
                return Self{
                    .grayscale1 = try allocator.alloc(Grayscale1, pixel_count),
                };
            },
            .grayscale2 => {
                return Self{
                    .grayscale2 = try allocator.alloc(Grayscale2, pixel_count),
                };
            },
            .grayscale4 => {
                return Self{
                    .grayscale4 = try allocator.alloc(Grayscale4, pixel_count),
                };
            },
            .grayscale8 => {
                return Self{
                    .grayscale8 = try allocator.alloc(Grayscale8, pixel_count),
                };
            },
            .grayscale8Alpha => {
                return Self{
                    .grayscale8Alpha = try allocator.alloc(Grayscale8Alpha, pixel_count),
                };
            },
            .grayscale16 => {
                return Self{
                    .grayscale16 = try allocator.alloc(Grayscale16, pixel_count),
                };
            },
            .grayscale16Alpha => {
                return Self{
                    .grayscale16Alpha = try allocator.alloc(Grayscale16Alpha, pixel_count),
                };
            },
            .rgb24 => {
                return Self{
                    .rgb24 = try allocator.alloc(Rgb24, pixel_count),
                };
            },
            .rgba32 => {
                return Self{
                    .rgba32 = try allocator.alloc(Rgba32, pixel_count),
                };
            },
            .rgb565 => {
                return Self{
                    .rgb565 = try allocator.alloc(Rgb565, pixel_count),
                };
            },
            .rgb555 => {
                return Self{
                    .rgb555 = try allocator.alloc(Rgb555, pixel_count),
                };
            },
            .bgr24 => {
                return Self{
                    .bgr24 = try allocator.alloc(Bgr24, pixel_count),
                };
            },
            .bgra32 => {
                return Self{
                    .bgra32 = try allocator.alloc(Bgra32, pixel_count),
                };
            },
            .rgb48 => {
                return Self{
                    .rgb48 = try allocator.alloc(Rgb48, pixel_count),
                };
            },
            .rgba64 => {
                return Self{
                    .rgba64 = try allocator.alloc(Rgba64, pixel_count),
                };
            },
            .float32 => {
                return Self{
                    .float32 = try allocator.alloc(Colorf32, pixel_count),
                };
            },
        };
    }

    pub fn deinit(self: Self, allocator: Allocator) void {
        switch (self) {
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
            .rgb565 => |data| allocator.free(data),
            .rgb555 => |data| allocator.free(data),
            .bgr24 => |data| allocator.free(data),
            .bgra32 => |data| allocator.free(data),
            .rgb48 => |data| allocator.free(data),
            .rgba64 => |data| allocator.free(data),
            .float32 => |data| allocator.free(data),
        }
    }

    pub fn len(self: Self) usize {
        return switch (self) {
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
            .rgb565 => |data| data.len,
            .rgb555 => |data| data.len,
            .bgr24 => |data| data.len,
            .bgra32 => |data| data.len,
            .rgb48 => |data| data.len,
            .rgba64 => |data| data.len,
            .float32 => |data| data.len,
        };
    }

    pub fn isIndexed(self: Self) bool {
        return switch (self) {
            .indexed1 => true,
            .indexed2 => true,
            .indexed4 => true,
            .indexed8 => true,
            .indexed16 => true,
            else => false,
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

    pub fn initNull() Self {
        return Self{};
    }

    pub fn next(self: *Self) ?Colorf32 {
        if (self.current_index >= self.end) {
            return null;
        }

        const result: ?Colorf32 = switch (self.pixels.*) {
            .indexed1 => |data| data.palette[data.indices[self.current_index]],
            .indexed2 => |data| data.palette[data.indices[self.current_index]],
            .indexed4 => |data| data.palette[data.indices[self.current_index]],
            .indexed8 => |data| data.palette[data.indices[self.current_index]],
            .indexed16 => |data| data.palette[data.indices[self.current_index]],
            .grayscale1 => |data| data[self.current_index].toColorf32(),
            .grayscale2 => |data| data[self.current_index].toColorf32(),
            .grayscale4 => |data| data[self.current_index].toColorf32(),
            .grayscale8 => |data| data[self.current_index].toColorf32(),
            .grayscale8Alpha => |data| data[self.current_index].toColorf32(),
            .grayscale16 => |data| data[self.current_index].toColorf32(),
            .grayscale16Alpha => |data| data[self.current_index].toColorf32(),
            .rgb24 => |data| data[self.current_index].toColorf32(),
            .rgba32 => |data| data[self.current_index].toColorf32(),
            .rgb565 => |data| data[self.current_index].toColorf32(),
            .rgb555 => |data| data[self.current_index].toColorf32(),
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
