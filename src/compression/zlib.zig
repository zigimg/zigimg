// Implement ZLIB Compressed data format (RFC 1950)
pub const CompressionLevel = packed enum(u2) {
    Fastest,
    Fast,
    Default,
    Maximum
};

pub const StreamHeader = struct {
    compression: Compression,
    flags: Flags,

    pub const Compression = packed struct {
        method: u4,
        info: u4,
    };

    pub const Flags = packed struct {
        check: u5,
        preset_dictionary: bool,
        compression_level: CompressionLevel,
    };

    const Self = @This();

    pub fn getCompressionWindowSize(self: Self) usize {
        return @as(usize, 1) << (self.compression.info + 8);
    }
};