const std = @import("std");

pub const ImageError = error{
    InvalidData,
    Unsupported,
};

pub const ImageReadError = ImageError ||
    std.mem.Allocator.Error ||
    std.io.StreamSource.ReadError ||
    std.io.StreamSource.SeekError ||
    std.io.StreamSource.GetSeekPosError ||
    error{ EndOfStream, StreamTooLong };

pub const ImageWriteError = error{Unsupported} ||
    std.mem.Allocator.Error ||
    std.io.StreamSource.WriteError ||
    std.io.StreamSource.SeekError ||
    std.io.StreamSource.GetSeekPosError;
