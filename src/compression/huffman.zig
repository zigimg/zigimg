// Huffman encoder & decoder
const std = @import("std");

// TODO: Make this generic parameter ?
pub const MaxHuffmanSymbols = 288;
pub const MaxHuffmanBits = 15;
pub const HuffmanLookupTableBits = 8;

pub const Decoder = struct {
    table: [1 << HuffmanLookupTableBits]packed struct {
        symbol: u9,
        length: u7,
    },
    sentinel_bits: [MaxHuffmanBits + 1]u16,
    offset_first_symbol_index: [MaxHuffmanBits + 1]u16,
    symbols: [MaxHuffmanSymbols]u16,

    const Self = @This();

    pub fn initFromCodewordLength(length_table: []const u8) !Self {
        var result: Self = undefined;

        // Zero-initialize the lookup table
        std.mem.secureZero(@TypeOf(result.table[0]), result.table[0..]);
        std.mem.secureZero(u16, result.sentinel_bits[0..]);
        std.mem.secureZero(u16, result.offset_first_symbol_index[0..]);
        std.mem.secureZero(u16, result.symbols[0..]);

        // Count the number of codewords of each length
        var count: [MaxHuffmanBits + 1]u16 = undefined;
        std.mem.secureZero(u16, count[0..]);

        for (length_table) |length| {
            count[length] += 1;
        }
        count[0] = 0; // Ignore zero-length codewords

        // Compute sentinel_bits and offset_first_symbol_index for each length
        var code: [MaxHuffmanBits + 1]u16 = undefined;
        var symbol_indices: [MaxHuffmanBits + 1]u16 = undefined;

        code[0] = 0;
        symbol_indices[0] = 0;

        var length: usize = 1;

        while (length <= MaxHuffmanBits) : (length += 1) {
            // First canonical codeword of this length
            code[length] = (code[length - 1] + count[length - 1]) << 1;

            if (count[length] != 0 and (code[length] + count[length] - 1) > ((@as(usize, 1) << @intCast(u6, length)) - 1)) {
                return error.CodewordTooLong;
            }

            const sentinel = (code[length] + count[length]) << @intCast(u4, MaxHuffmanBits - length);
            result.sentinel_bits[length] = @intCast(u16, sentinel);

            symbol_indices[length] = symbol_indices[length - 1] + count[length - 1];
            const a = @intCast(isize, symbol_indices[length]);
            const b = @intCast(isize, code[length]);
            const temp = a - b;
            result.offset_first_symbol_index[length] = @truncate(u16, @bitCast(usize, temp));
        }

        var index: usize = 0;
        while (index < length_table.len) : (index += 1) {
            const current_length = length_table[index];
            if (current_length == 0) {
                continue;
            }

            result.symbols[symbol_indices[current_length]] = @intCast(u16, index);
            symbol_indices[current_length] += 1;

            if (current_length <= HuffmanLookupTableBits) {
                result.tableInsert(index, current_length, code[current_length]);
                code[current_length] += 1;
            }
        }

        return result;
    }

    pub fn decode(self: Self, bits: u16, used_bits: *usize) !u16 {
        const lookup_bits = lsb(@as(u64, bits), HuffmanLookupTableBits);
        if (self.table[lookup_bits].length != 0) {
            used_bits.* = self.table[lookup_bits].length;
            return @as(u16, self.table[lookup_bits].symbol);
        }

        var reversed_bits = reverse16(bits, MaxHuffmanBits);
        var length: usize = HuffmanLookupTableBits + 1;
        while (length <= MaxHuffmanBits) : (length += 1) {
            if (reversed_bits < self.sentinel_bits[length]) {
                reversed_bits >>= @intCast(u4, MaxHuffmanBits - length);

                const symbol_index = @truncate(u16, @as(usize, self.offset_first_symbol_index[length]) + @as(usize, reversed_bits));
                used_bits.* = length;
                return self.symbols[symbol_index];
            }
        }
        used_bits.* = 0;
        return error.DecodeError;
    }

    fn tableInsert(self: *Self, symbol: usize, len: u8, codeword: u16) void {
        const reversed_codeword = reverse16(codeword, len);
        const padding_length = HuffmanLookupTableBits - len;

        var padding: usize = 0;
        while (padding < (@as(usize, 1) << @intCast(u6, padding_length))) : (padding += 1) {
            const index = reversed_codeword | (padding << @intCast(u6, len));
            self.table[index].symbol = @intCast(u9, symbol);
            self.table[index].length = @intCast(u7, len);
        }
    }

    fn reverse16(value: u16, bits: usize) u16 {
        const reverse8_table = comptime blk: {
            @setEvalBranchQuota(5000);
            var result: [std.math.maxInt(u8) + 1]u8 = undefined;

            var index: usize = 0;
            while (index < result.len) : (index += 1) {
                var temp: u8 = 0;

                var i: usize = 0;
                while (i < 8) : (i += 1) {
                    if ((index & (1 << i)) != 0) {
                        temp |= (1 << (8 - 1 - i));
                    }
                }

                result[index] = temp;
            }
            break :blk result;
        };

        const lo = value & 0xFF;
        const high = value >> 8;

        const reversed = @as(u16, reverse8_table[lo]) << 8 | @as(u16, reverse8_table[high]);

        return reversed >> @intCast(u4, (16 - bits));
    }

    inline fn lsb(input: usize, bits: usize) usize {
        return input & ((@as(usize, 1) << @intCast(u6, bits)) - 1);
    }
};
