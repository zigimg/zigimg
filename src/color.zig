const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const TypeInfo = std.builtin.TypeInfo;

pub inline fn toColorInt(comptime T: type, value: f32) T {
    const float_value = @round(value * @intToFloat(f32, math.maxInt(T)));
    return @floatToInt(T, math.clamp(float_value, math.minInt(T), math.maxInt(T)));
}

pub inline fn toColorFloat(value: anytype) f32 {
    return @intToFloat(f32, value) / @intToFloat(f32, math.maxInt(@TypeOf(value)));
}

pub const Color = struct {
    R: f32,
    G: f32,
    B: f32,
    A: f32,

    const Self = @This();

    pub fn initRGB(r: f32, g: f32, b: f32) Self {
        return Self{
            .R = r,
            .G = g,
            .B = b,
            .A = 1.0,
        };
    }

    pub fn initRGBA(r: f32, g: f32, b: f32, a: f32) Self {
        return Self{
            .R = r,
            .G = g,
            .B = b,
            .A = a,
        };
    }

    pub fn fromHtmlHex(value: u32) Self {
        return Self{
            .R = toColorFloat((value >> 16) & 0xFF),
            .G = toColorFloat((value >> 8) & 0xFF),
            .B = toColorFloat(value & 0xFF),
            .A = 1.0,
        };
    }

    pub fn premultipliedAlpha(self: Self) Self {
        return Self{
            .R = self.R * self.A,
            .G = self.G * self.A,
            .B = self.B * self.A,
            .A = self.A,
        };
    }

    pub fn toIntegerColor(self: Self, comptime storage_type: type) IntegerColor(storage_type) {
        return IntegerColor(storage_type){
            .R = toColorInt(storage_type, self.R),
            .G = toColorInt(storage_type, self.G),
            .B = toColorInt(storage_type, self.B),
            .A = toColorInt(storage_type, self.A),
        };
    }

    pub fn toIntegerColor8(self: Self) IntegerColor8 {
        return toIntegerColor(self, u8);
    }

    pub fn toIntegerColor16(self: Self) IntegerColor16 {
        return toIntegerColor(self, u16);
    }
};

pub fn IntegerColor(comptime storage_type: type) type {
    return struct {
        R: storage_type,
        G: storage_type,
        B: storage_type,
        A: storage_type,

        const Self = @This();

        pub fn initRGB(r: storage_type, g: storage_type, b: storage_type) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
                .A = math.maxInt(storage_type),
            };
        }

        pub fn initRGBA(r: storage_type, g: storage_type, b: storage_type, a: storage_type) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
                .A = a,
            };
        }

        pub fn fromHtmlHex(value: u32) Self {
            return Self{
                .R = @intCast(storage_type, (value >> 16) & 0xFF),
                .G = @intCast(storage_type, (value >> 8) & 0xFF),
                .B = @intCast(storage_type, value & 0xFF),
                .A = math.maxInt(storage_type),
            };
        }

        pub fn premultipliedAlpha(self: Self) Self {
            var floatR: f32 = toColorFloat(self.R);
            var floatG: f32 = toColorFloat(self.G);
            var floatB: f32 = toColorFloat(self.B);
            var floatA: f32 = toColorFloat(self.A);

            return Self{
                .R = toColorInt(u8, floatR * floatA),
                .G = toColorInt(u8, floatG * floatA),
                .B = toColorInt(u8, floatB * floatA),
                .A = self.A,
            };
        }

        pub fn toColor(self: Self) Color {
            return Color{
                .R = toColorFloat(self.R),
                .G = toColorFloat(self.G),
                .B = toColorFloat(self.B),
                .A = toColorFloat(self.A),
            };
        }
    };
}

pub const IntegerColor8 = IntegerColor(u8);
pub const IntegerColor16 = IntegerColor(u16);

fn RgbColor(comptime red_bits: comptime_int, comptime green_bits: comptime_int, comptime blue_bits: comptime_int) type {
    return packed struct {
        R: RedType,
        G: GreenType,
        B: BlueType,

        const RedType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = red_bits } });
        const GreenType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = green_bits } });
        const BlueType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = blue_bits } });

        const Self = @This();

        pub fn initRGB(r: RedType, g: GreenType, b: BlueType) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
            };
        }

        pub fn toColor(self: Self) Color {
            return Color{
                .R = toColorFloat(self.R),
                .G = toColorFloat(self.G),
                .B = toColorFloat(self.B),
                .A = 1.0,
            };
        }
    };
}

fn RgbaColor(comptime red_bits: comptime_int, comptime green_bits: comptime_int, comptime blue_bits: comptime_int, comptime alpha_bits: comptime_int) type {
    return packed struct {
        R: RedType,
        G: GreenType,
        B: BlueType,
        A: AlphaType,

        const RedType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = red_bits } });
        const GreenType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = green_bits } });
        const BlueType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = blue_bits } });
        const AlphaType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = alpha_bits } });

        const Self = @This();

        pub fn initRGB(r: RedType, g: GreenType, b: BlueType) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
                .A = math.maxInt(AlphaType),
            };
        }

        pub fn initRGBA(r: RedType, g: GreenType, b: BlueType, a: AlphaType) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
                .A = a,
            };
        }

        pub fn toColor(self: Self) Color {
            return Color{
                .R = toColorFloat(self.R),
                .G = toColorFloat(self.G),
                .B = toColorFloat(self.B),
                .A = toColorFloat(self.A),
            };
        }
    };
}

// Rgb24
// OpenGL: GL_RGB
// Vulkan: VK_FORMAT_R8G8B8_UNORM
// Direct3D/DXGI: n/a
pub const Rgb24 = RgbColor(8, 8, 8);

// Rgba32
// OpenGL: GL_RGBA
// Vulkan: VK_FORMAT_R8G8B8A8_UNORM
// Direct3D/DXGI: DXGI_FORMAT_R8G8B8A8_UNORM
pub const Rgba32 = RgbaColor(8, 8, 8, 8);

// Rgb565
// OpenGL: n/a
// Vulkan: n/a
// Direct3D/DXGI: n/a
pub const Rgb565 = RgbColor(5, 6, 5);

// Rgb555
// OpenGL: GL_RGB5
// Vulkan: VK_FORMAT_R5G6B5_UNORM_PACK16
// Direct3D/DXGI: n/a
pub const Rgb555 = RgbColor(5, 5, 5);

// Rgb48
// OpenGL: GL_RGB16
// Vulkan: VK_FORMAT_R16G16B16_UNORM
// Direct3D/DXGI: n/a
pub const Rgb48 = RgbColor(16, 16, 16);

// Rgba64
// OpenGL: GL_RGBA16
// Vulkan: VK_FORMAT_R16G16B16A16_UNORM
// Direct3D/DXGI: DXGI_FORMAT_R16G16B16A16_UNORM
pub const Rgba64 = RgbaColor(16, 16, 16, 16);

fn BgrColor(comptime red_bits: comptime_int, comptime green_bits: comptime_int, comptime blue_bits: comptime_int) type {
    return packed struct {
        B: BlueType,
        G: GreenType,
        R: RedType,

        const RedType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = red_bits } });
        const GreenType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = green_bits } });
        const BlueType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = blue_bits } });

        const Self = @This();

        pub fn initRGB(r: RedType, g: GreenType, b: BlueType) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
            };
        }

        pub fn toColor(self: Self) Color {
            return Color{
                .R = toColorFloat(self.R),
                .G = toColorFloat(self.G),
                .B = toColorFloat(self.B),
                .A = 1.0,
            };
        }
    };
}

fn BgraColor(comptime red_bits: comptime_int, comptime green_bits: comptime_int, comptime blue_bits: comptime_int, comptime alpha_bits: comptime_int) type {
    return packed struct {
        B: BlueType,
        G: GreenType,
        R: RedType,
        A: AlphaType,

        const RedType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = red_bits } });
        const GreenType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = green_bits } });
        const BlueType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = blue_bits } });
        const AlphaType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .signedness = .unsigned, .bits = alpha_bits } });

        const Self = @This();

        pub fn initRGB(r: RedType, g: GreenType, b: BlueType) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
                .A = math.maxInt(AlphaType),
            };
        }

        pub fn initRGBA(r: RedType, g: GreenType, b: BlueType, a: AlphaType) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
                .A = a,
            };
        }

        pub fn toColor(self: Self) Color {
            return Color{
                .R = toColorFloat(self.R),
                .G = toColorFloat(self.G),
                .B = toColorFloat(self.B),
                .A = toColorFloat(self.A),
            };
        }
    };
}

// Bgr24
// OpenGL: GL_BGR
// Vulkan: VK_FORMAT_B8G8R8_UNORM
// Direct3D/DXGI: n/a
pub const Bgr24 = BgrColor(8, 8, 8);

// Bgra32
// OpenGL: GL_BGRA
// Vulkan: VK_FORMAT_B8G8R8A8_UNORM
// Direct3D/DXGI: DXGI_FORMAT_B8G8R8A8_UNORM
pub const Bgra32 = BgraColor(8, 8, 8, 8);

pub fn IndexedStorage(comptime T: type) type {
    return struct {
        palette: []Color,
        indices: []T,

        pub const PaletteSize = 1 << @bitSizeOf(T);

        const Self = @This();

        pub fn init(allocator: Allocator, pixel_count: usize) !Self {
            return Self{
                .indices = try allocator.alloc(T, pixel_count),
                .palette = try allocator.alloc(Color, PaletteSize),
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

        pub fn toColor(self: Self) Color {
            const gray = toColorFloat(self.value);
            return Color{
                .R = gray,
                .G = gray,
                .B = gray,
                .A = 1.0,
            };
        }
    };
}

pub fn GrayscaleAlpha(comptime T: type) type {
    return struct {
        value: T,
        alpha: T,

        const Self = @This();

        pub fn toColor(self: Self) Color {
            const gray = toColorFloat(self.value);
            return Color{
                .R = gray,
                .G = gray,
                .B = gray,
                .A = toColorFloat(self.alpha),
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
    float32: []Color,

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
                    .float32 = try allocator.alloc(Color, pixel_count),
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

    pub fn next(self: *Self) ?Color {
        if (self.current_index >= self.end) {
            return null;
        }

        const result: ?Color = switch (self.pixels.*) {
            .indexed1 => |data| data.palette[data.indices[self.current_index]],
            .indexed2 => |data| data.palette[data.indices[self.current_index]],
            .indexed4 => |data| data.palette[data.indices[self.current_index]],
            .indexed8 => |data| data.palette[data.indices[self.current_index]],
            .indexed16 => |data| data.palette[data.indices[self.current_index]],
            .grayscale1 => |data| data[self.current_index].toColor(),
            .grayscale2 => |data| data[self.current_index].toColor(),
            .grayscale4 => |data| data[self.current_index].toColor(),
            .grayscale8 => |data| data[self.current_index].toColor(),
            .grayscale8Alpha => |data| data[self.current_index].toColor(),
            .grayscale16 => |data| data[self.current_index].toColor(),
            .grayscale16Alpha => |data| data[self.current_index].toColor(),
            .rgb24 => |data| data[self.current_index].toColor(),
            .rgba32 => |data| data[self.current_index].toColor(),
            .rgb565 => |data| data[self.current_index].toColor(),
            .rgb555 => |data| data[self.current_index].toColor(),
            .bgr24 => |data| data[self.current_index].toColor(),
            .bgra32 => |data| data[self.current_index].toColor(),
            .rgb48 => |data| data[self.current_index].toColor(),
            .rgba64 => |data| data[self.current_index].toColor(),
            .float32 => |data| data[self.current_index],
        };

        self.current_index += 1;
        return result;
    }
};
