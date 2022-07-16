const std = @import("std");
const utils = @import("utils.zig");

pub const ImageError = error{
    Unsupported,
};

pub const ImageReadError = ImageError ||
    std.mem.Allocator.Error ||
    utils.StructReadError ||
    std.io.StreamSource.SeekError ||
    std.io.StreamSource.GetSeekPosError ||
    error{ EndOfStream, StreamTooLong, InvalidData };

pub const ImageWriteError = ImageError ||
    std.mem.Allocator.Error ||
    std.io.StreamSource.WriteError ||
    std.io.StreamSource.SeekError ||
    std.io.StreamSource.GetSeekPosError;
