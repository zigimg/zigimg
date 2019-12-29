pub const Color = struct {
    R: u8,
    G: u8,
    B: u8,
    A: u8,

    pub fn initRGB(r: u8, g: u8, b: u8) Color {
        return Color{
            .R = r,
            .G = g,
            .B = b,
            .A = 0xFF,
        };
    }

    pub fn initRGBA(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{
            .R = r,
            .G = g,
            .B = b,
            .A = a,
        };
    }
};

pub const Rgb24 = packed struct {
    B: u8,
    G: u8,
    R: u8,

    const Self = @This();

    pub fn toColor(self: *Self) Color {
        return Color{
            .R = self.R,
            .G = self.G,
            .B = self.B,
            .A = 0xFF,
        };
    }
};

pub const Argb32 = packed struct {
    B: u8,
    G: u8,
    R: u8,
    A: u8,

    const Self = @This();

    pub fn toColor(self: *Self) Color {
        return Color{
            .R = self.R,
            .G = self.G,
            .B = self.B,
            .A = self.A,
        };
    }
};
