const ImageUnmanaged = @import("../ImageUnmanaged.zig");
const std = @import("std");

pub fn decode(stream: *ImageUnmanaged.Stream, tmp_buffer: []u8, length: u32) !void {
    const reader = stream.reader();
    var output_offset: u32 = 0;
    var input_offset: u32 = 0;

    while (input_offset < length - 1) {
        const control: usize = try reader.readByte();
        input_offset += 1;
        if (control < 128) {
            for (0..control + 1) |_| {
                if (input_offset >= length) {
                    return;
                }
                tmp_buffer[output_offset] = try reader.readByte();
                output_offset += 1;
                input_offset += 1;
            }
        } else if (control > 128) {
            if (input_offset >= length) {
                return;
            }
            const value = try reader.readByte();
            input_offset += 1;
            for (0..257 - control) |_| {
                tmp_buffer[output_offset] = value;
                output_offset += 1;
            }
        }
    }
}
