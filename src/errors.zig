const std = @import("std");

pub const ImageError = error{
    Unsupported,
};

pub const ImageReadError = ImageError ||
    std.mem.Allocator.Error ||
    std.io.StreamSource.ReadError ||
    std.io.StreamSource.SeekError ||
    std.io.StreamSource.GetSeekPosError ||
    error{ EndOfStream, StreamTooLong, InvalidData };

pub const ImageWriteError = ImageError ||
    std.mem.Allocator.Error ||
    std.io.StreamSource.WriteError ||
    std.io.StreamSource.SeekError ||
    std.io.StreamSource.GetSeekPosError;
