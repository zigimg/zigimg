const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const TypeInfo = std.builtin.TypeInfo;

inline fn toColorInt(comptime T: type, value: f32) T {
    return math.max(math.minInt(T), math.min(math.maxInt(T), @floatToInt(T, math.round(value * @intToFloat(f32, math.maxInt(T))))));
}

inline fn toColorFloat(value: var, comptime maxValue: f32) f32 {
    return @intToFloat(f32, value) / maxValue;
}

pub const Color = struct {
    R: u8,
    G: u8,
    B: u8,
    A: u8,

    const Self = @This();

    pub fn initRGB(r: u8, g: u8, b: u8) Self {
        return Self{
            .R = r,
            .G = g,
            .B = b,
            .A = 0xFF,
        };
    }

    pub fn initRGBA(r: u8, g: u8, b: u8, a: u8) Self {
        return Self{
            .R = r,
            .G = g,
            .B = b,
            .A = a,
        };
    }

    pub fn premultipliedAlpha(self: Self) Self {
        var floatR: f32 = toColorFloat(self.R, 255.0);
        var floatG: f32 = toColorFloat(self.G, 255.0);
        var floatB: f32 = toColorFloat(self.B, 255.0);
        var floatA: f32 = toColorFloat(self.A, 255.0);

        return Self{
            .R = toColorInt(u8, floatR * floatA),
            .G = toColorInt(u8, floatG * floatA),
            .B = toColorInt(u8, floatB * floatA),
            .A = self.A,
        };
    }
};

fn RgbColor(comptime red_bits: comptime_int, comptime green_bits: comptime_int, comptime blue_bits: comptime_int) type {
    return packed struct {
        B: BlueType,
        G: GreenType,
        R: RedType,

        const RedType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = red_bits } });
        const GreenType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = green_bits } });
        const BlueType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = blue_bits } });

        const MaxRed = @intToFloat(f32, (1 << red_bits) - 1);
        const MaxGreen = @intToFloat(f32, (1 << green_bits) - 1);
        const MaxBlue = @intToFloat(f32, (1 << blue_bits) - 1);

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
                .R = toColorInt(u8, toColorFloat(self.R, MaxRed)),
                .G = toColorInt(u8, toColorFloat(self.G, MaxGreen)),
                .B = toColorInt(u8, toColorFloat(self.B, MaxBlue)),
                .A = 0xFF,
            };
        }
    };
}

fn ARgbColor(comptime red_bits: comptime_int, comptime green_bits: comptime_int, comptime blue_bits: comptime_int, comptime alpha_bits: comptime_int) type {
    return packed struct {
        B: BlueType,
        G: GreenType,
        R: RedType,
        A: AlphaType,

        const RedType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = red_bits } });
        const GreenType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = green_bits } });
        const BlueType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = blue_bits } });
        const AlphaType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = alpha_bits } });

        const MaxRed = @intToFloat(f32, (1 << red_bits) - 1);
        const MaxGreen = @intToFloat(f32, (1 << green_bits) - 1);
        const MaxBlue = @intToFloat(f32, (1 << blue_bits) - 1);
        const MaxAlpha = @intToFloat(f32, (1 << alpha_bits) - 1);

        const Self = @This();

        pub fn initRGB(r: RedType, g: GreenType, b: BlueType) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
                .A = @floatToInt(AlphaType, MaxAlpha),
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
                .R = toColorInt(u8, toColorFloat(self.R, MaxRed)),
                .G = toColorInt(u8, toColorFloat(self.G, MaxGreen)),
                .B = toColorInt(u8, toColorFloat(self.B, MaxBlue)),
                .A = toColorInt(u8, toColorFloat(self.A, MaxAlpha)),
            };
        }
    };
}

fn RgbaColor(comptime red_bits: comptime_int, comptime green_bits: comptime_int, comptime blue_bits: comptime_int, comptime alpha_bits: comptime_int) type {
    return packed struct {
        A: AlphaType,
        B: BlueType,
        G: GreenType,
        R: RedType,

        const RedType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = red_bits } });
        const GreenType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = green_bits } });
        const BlueType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = blue_bits } });
        const AlphaType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = alpha_bits } });

        const MaxRed = @intToFloat(f32, (1 << red_bits) - 1);
        const MaxGreen = @intToFloat(f32, (1 << green_bits) - 1);
        const MaxBlue = @intToFloat(f32, (1 << blue_bits) - 1);
        const MaxAlpha = @intToFloat(f32, (1 << alpha_bits) - 1);

        const Self = @This();

        pub fn initRGB(r: RedType, g: GreenType, b: BlueType) Self {
            return Self{
                .R = r,
                .G = g,
                .B = b,
                .A = @floatToInt(AlphaType, MaxAlpha),
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
                .R = toColorInt(u8, toColorFloat(self.R, MaxRed)),
                .G = toColorInt(u8, toColorFloat(self.G, MaxGreen)),
                .B = toColorInt(u8, toColorFloat(self.B, MaxBlue)),
                .A = toColorInt(u8, toColorFloat(self.A, MaxAlpha)),
            };
        }
    };
}

pub const Rgb24 = RgbColor(8, 8, 8);
pub const Rgba32 = RgbaColor(8, 8, 8, 8);
pub const Rgb565 = RgbColor(5, 6, 5);
pub const Rgb555 = RgbColor(5, 5, 5);
pub const Argb32 = ARgbColor(8, 8, 8, 8);

fn IndexedStorage(comptime T: type) type {
    return struct {
        palette: [PaletteSize]Color = undefined,
        indices: []T,

        pub const PaletteSize = 1 << @bitSizeOf(T);

        const Self = @This();

        pub fn init(allocator: *Allocator, pixel_count: usize) !Self {
            return Self{
                .indices = try allocator.alloc(T, pixel_count),
            };
        }

        pub fn deinit(self: Self, allocator: *Allocator) void {
            allocator.free(self.indices);
        }
    };
}

fn Grayscale(comptime T: type) type {
    return struct {
        value: T,

        pub const MaxInt = std.math.maxInt(T);

        const Self = @This();

        pub fn toColor(self: Self) Color {
            const gray = toColorInt(u8, toColorFloat(self.value, MaxInt));
            return Color{
                .R = gray,
                .G = gray,
                .B = gray,
                .A = 0xFF,
            };
        }
    };
}

pub const Monochrome = Grayscale(u1);
pub const Grayscale8 = Grayscale(u8);
pub const Grayscale16 = Grayscale(u16);

pub const ColorStorage = union(PixelFormat) {
    Bpp1: IndexedStorage(u1),
    Bpp2: IndexedStorage(u2),
    Bpp4: IndexedStorage(u4),
    Bpp8: IndexedStorage(u8),
    Bpp16: IndexedStorage(u16),
    Monochrome: []Monochrome,
    Grayscale8: []Grayscale8,
    Grayscale16: []Grayscale16,
    Rgb24: []Rgb24,
    Rgba32: []Rgba32,
    Rgb565: []Rgb565,
    Rgb555: []Rgb555,
    Argb32: []Argb32,

    const Self = @This();

    pub fn init(allocator: *Allocator, format: PixelFormat, pixel_count: usize) !Self {
        return switch (format) {
            .Bpp1 => {
                return Self{
                    .Bpp1 = try IndexedStorage(u1).init(allocator, pixel_count),
                };
            },
            .Bpp2 => {
                return Self{
                    .Bpp2 = try IndexedStorage(u2).init(allocator, pixel_count),
                };
            },
            .Bpp4 => {
                return Self{
                    .Bpp4 = try IndexedStorage(u4).init(allocator, pixel_count),
                };
            },
            .Bpp8 => {
                return Self{
                    .Bpp8 = try IndexedStorage(u8).init(allocator, pixel_count),
                };
            },
            .Bpp16 => {
                return Self{
                    .Bpp16 = try IndexedStorage(u16).init(allocator, pixel_count),
                };
            },
            .Monochrome => {
                return Self{
                    .Monochrome = try allocator.alloc(Monochrome, pixel_count),
                };
            },
            .Grayscale8 => {
                return Self{
                    .Grayscale8 = try allocator.alloc(Grayscale8, pixel_count),
                };
            },
            .Grayscale16 => {
                return Self{
                    .Grayscale16 = try allocator.alloc(Grayscale16, pixel_count),
                };
            },
            .Rgb24 => {
                return Self{
                    .Rgb24 = try allocator.alloc(Rgb24, pixel_count),
                };
            },
            .Rgba32 => {
                return Self{
                    .Rgba32 = try allocator.alloc(Rgba32, pixel_count),
                };
            },
            .Rgb565 => {
                return Self{
                    .Rgb565 = try allocator.alloc(Rgb565, pixel_count),
                };
            },
            .Rgb555 => {
                return Self{
                    .Rgb555 = try allocator.alloc(Rgb555, pixel_count),
                };
            },
            .Argb32 => {
                return Self{
                    .Argb32 = try allocator.alloc(Argb32, pixel_count),
                };
            },
        };
    }

    pub fn deinit(self: Self, allocator: *Allocator) void {
        switch (self) {
            .Bpp1 => |data| data.deinit(allocator),
            .Bpp2 => |data| data.deinit(allocator),
            .Bpp4 => |data| data.deinit(allocator),
            .Bpp8 => |data| data.deinit(allocator),
            .Bpp16 => |data| data.deinit(allocator),
            .Monochrome => |data| allocator.free(data),
            .Grayscale8 => |data| allocator.free(data),
            .Grayscale16 => |data| allocator.free(data),
            .Rgb24 => |data| allocator.free(data),
            .Rgba32 => |data| allocator.free(data),
            .Rgb565 => |data| allocator.free(data),
            .Rgb555 => |data| allocator.free(data),
            .Argb32 => |data| allocator.free(data),
        }
    }

    pub fn len(self: Self) usize {
        return switch (self) {
            .Bpp1 => |data| data.indices.len,
            .Bpp2 => |data| data.indices.len,
            .Bpp4 => |data| data.indices.len,
            .Bpp8 => |data| data.indices.len,
            .Bpp16 => |data| data.indices.len,
            .Monochrome => |data| data.len,
            .Grayscale8 => |data| data.len,
            .Grayscale16 => |data| data.len,
            .Rgb24 => |data| data.len,
            .Rgba32 => |data| data.len,
            .Rgb565 => |data| data.len,
            .Rgb555 => |data| data.len,
            .Argb32 => |data| data.len,
        };
    }
};

pub const ColorStorageIterator = struct {
    pixels: *const ColorStorage = undefined,
    currentIndex: usize = 0,
    end: usize = 0,

    const Self = @This();

    pub fn init(pixels: *const ColorStorage) Self {
        return Self{
            .pixels = pixels,
            .end = pixels.len(),
        };
    }

    pub fn initNull() Self {
        return Self{};
    }

    pub fn next(self: *Self) ?Color {
        if (self.currentIndex >= self.end) {
            return null;
        }

        const result: ?Color = switch (self.pixels.*) {
            .Bpp1 => |data| data.palette[data.indices[self.currentIndex]],
            .Bpp2 => |data| data.palette[data.indices[self.currentIndex]],
            .Bpp4 => |data| data.palette[data.indices[self.currentIndex]],
            .Bpp8 => |data| data.palette[data.indices[self.currentIndex]],
            .Bpp16 => |data| data.palette[data.indices[self.currentIndex]],
            .Monochrome => |data| data[self.currentIndex].toColor(),
            .Grayscale8 => |data| data[self.currentIndex].toColor(),
            .Grayscale16 => |data| data[self.currentIndex].toColor(),
            .Rgb24 => |data| data[self.currentIndex].toColor(),
            .Rgba32 => |data| data[self.currentIndex].toColor(),
            .Rgb565 => |data| data[self.currentIndex].toColor(),
            .Rgb555 => |data| data[self.currentIndex].toColor(),
            .Argb32 => |data| data[self.currentIndex].toColor(),
            else => null,
        };

        self.currentIndex += 1;
        return result;
    }
};
