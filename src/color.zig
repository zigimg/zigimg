const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const PixelFormat = @import("pixel_format.zig").PixelFormat;
const TypeInfo = std.builtin.TypeInfo;

pub inline fn toColorInt(comptime T: type, value: f32) T {
    return math.max(math.minInt(T), math.min(math.maxInt(T), @floatToInt(T, math.round(value * @intToFloat(f32, math.maxInt(T))))));
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

fn ARgbColor(comptime red_bits: comptime_int, comptime green_bits: comptime_int, comptime blue_bits: comptime_int, comptime alpha_bits: comptime_int) type {
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

fn RgbaColor(comptime red_bits: comptime_int, comptime green_bits: comptime_int, comptime blue_bits: comptime_int, comptime alpha_bits: comptime_int) type {
    return packed struct {
        A: AlphaType,
        B: BlueType,
        G: GreenType,
        R: RedType,

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

pub const Rgb24 = RgbColor(8, 8, 8);
pub const Rgba32 = RgbaColor(8, 8, 8, 8);
pub const Rgb565 = RgbColor(5, 6, 5);
pub const Rgb555 = RgbColor(5, 5, 5);
pub const Argb32 = ARgbColor(8, 8, 8, 8);
pub const Rgb48 = RgbColor(16, 16, 16);
pub const Rgba64 = RgbaColor(16, 16, 16, 16);

pub fn IndexedStorage(comptime T: type) type {
    return struct {
        palette: []Color,
        indices: []T,

        pub const PaletteSize = 1 << @bitSizeOf(T);

        const Self = @This();

        pub fn init(allocator: *Allocator, pixel_count: usize) !Self {
            return Self{
                .indices = try allocator.alloc(T, pixel_count),
                .palette = try allocator.alloc(Color, PaletteSize),
            };
        }

        pub fn deinit(self: Self, allocator: *Allocator) void {
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

pub const ColorStorage = union(PixelFormat) {
    Bpp1: IndexedStorage1,
    Bpp2: IndexedStorage2,
    Bpp4: IndexedStorage4,
    Bpp8: IndexedStorage8,
    Bpp16: IndexedStorage16,
    Grayscale1: []Grayscale1,
    Grayscale2: []Grayscale2,
    Grayscale4: []Grayscale4,
    Grayscale8: []Grayscale8,
    Grayscale8Alpha: []Grayscale8Alpha,
    Grayscale16: []Grayscale16,
    Grayscale16Alpha: []Grayscale16Alpha,
    Rgb24: []Rgb24,
    Rgba32: []Rgba32,
    Rgb565: []Rgb565,
    Rgb555: []Rgb555,
    Argb32: []Argb32,
    Rgb48: []Rgb48,
    Rgba64: []Rgba64,

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
            .Grayscale1 => {
                return Self{
                    .Grayscale1 = try allocator.alloc(Grayscale1, pixel_count),
                };
            },
            .Grayscale2 => {
                return Self{
                    .Grayscale2 = try allocator.alloc(Grayscale2, pixel_count),
                };
            },
            .Grayscale4 => {
                return Self{
                    .Grayscale4 = try allocator.alloc(Grayscale4, pixel_count),
                };
            },
            .Grayscale8 => {
                return Self{
                    .Grayscale8 = try allocator.alloc(Grayscale8, pixel_count),
                };
            },
            .Grayscale8Alpha => {
                return Self{
                    .Grayscale8Alpha = try allocator.alloc(Grayscale8Alpha, pixel_count),
                };
            },
            .Grayscale16 => {
                return Self{
                    .Grayscale16 = try allocator.alloc(Grayscale16, pixel_count),
                };
            },
            .Grayscale16Alpha => {
                return Self{
                    .Grayscale16Alpha = try allocator.alloc(Grayscale16Alpha, pixel_count),
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
            .Rgb48 => {
                return Self{
                    .Rgb48 = try allocator.alloc(Rgb48, pixel_count),
                };
            },
            .Rgba64 => {
                return Self{
                    .Rgba64 = try allocator.alloc(Rgba64, pixel_count),
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
            .Grayscale1 => |data| allocator.free(data),
            .Grayscale2 => |data| allocator.free(data),
            .Grayscale4 => |data| allocator.free(data),
            .Grayscale8 => |data| allocator.free(data),
            .Grayscale8Alpha => |data| allocator.free(data),
            .Grayscale16 => |data| allocator.free(data),
            .Grayscale16Alpha => |data| allocator.free(data),
            .Rgb24 => |data| allocator.free(data),
            .Rgba32 => |data| allocator.free(data),
            .Rgb565 => |data| allocator.free(data),
            .Rgb555 => |data| allocator.free(data),
            .Argb32 => |data| allocator.free(data),
            .Rgb48 => |data| allocator.free(data),
            .Rgba64 => |data| allocator.free(data),
        }
    }

    pub fn len(self: Self) usize {
        return switch (self) {
            .Bpp1 => |data| data.indices.len,
            .Bpp2 => |data| data.indices.len,
            .Bpp4 => |data| data.indices.len,
            .Bpp8 => |data| data.indices.len,
            .Bpp16 => |data| data.indices.len,
            .Grayscale1 => |data| data.len,
            .Grayscale2 => |data| data.len,
            .Grayscale4 => |data| data.len,
            .Grayscale8 => |data| data.len,
            .Grayscale8Alpha => |data| data.len,
            .Grayscale16 => |data| data.len,
            .Grayscale16Alpha => |data| data.len,
            .Rgb24 => |data| data.len,
            .Rgba32 => |data| data.len,
            .Rgb565 => |data| data.len,
            .Rgb555 => |data| data.len,
            .Argb32 => |data| data.len,
            .Rgb48 => |data| data.len,
            .Rgba64 => |data| data.len,
        };
    }

    pub fn isIndexed(self: Self) bool {
        return switch (self) {
            .Bpp1 => true,
            .Bpp2 => true,
            .Bpp4 => true,
            .Bpp8 => true,
            .Bpp16 => true,
            else => false,
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
            .Grayscale1 => |data| data[self.currentIndex].toColor(),
            .Grayscale2 => |data| data[self.currentIndex].toColor(),
            .Grayscale4 => |data| data[self.currentIndex].toColor(),
            .Grayscale8 => |data| data[self.currentIndex].toColor(),
            .Grayscale8Alpha => |data| data[self.currentIndex].toColor(),
            .Grayscale16 => |data| data[self.currentIndex].toColor(),
            .Grayscale16Alpha => |data| data[self.currentIndex].toColor(),
            .Rgb24 => |data| data[self.currentIndex].toColor(),
            .Rgba32 => |data| data[self.currentIndex].toColor(),
            .Rgb565 => |data| data[self.currentIndex].toColor(),
            .Rgb555 => |data| data[self.currentIndex].toColor(),
            .Argb32 => |data| data[self.currentIndex].toColor(),
            .Rgb48 => |data| data[self.currentIndex].toColor(),
            .Rgba64 => |data| data[self.currentIndex].toColor(),
        };

        self.currentIndex += 1;
        return result;
    }
};
