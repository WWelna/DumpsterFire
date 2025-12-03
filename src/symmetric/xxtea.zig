// Copyright (C) 2025 William Welna (wwelna@occultusterra.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following condition.

// * The above copyright notice and this permission notice shall be included in
//   all copies or substantial portions of the Software.

// In addition, the following restrictions apply:

// * The software, either in source or compiled binary form, with or without any
//   modification, may not be used with or incorporated into any other software
//   that used an Artificial Intelligence (AI) model and/or Large Language Model
//   (LLM) to generate any portion of that other software's source code, binaries,
//   or artwork.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

const std = @import("std");

const XXTEA = struct {
    const Self = @This();
    const DELTA: u32 = 0x9E3779B9;
    key: u128,
    k: [4]u32,

    pub fn init128(key: u128) Self {
        return .{
            .key = key,
            .k = .{ (@as(u32, @truncate(key)) >> 96), (@as(u32, @truncate(key)) >> 64), (@as(u32, @truncate(key)) >> 32), @as(u32, @truncate(key)) },
        };
    }

    pub fn init(key: [4]u32) Self {
        return .{
            .key = (@as(u128, @intCast(key[0])) << 96) | (@as(u128, @intCast(key[1])) << 64) | (@as(u128, @intCast(key[2])) << 32) | @as(u128, @intCast(key[3])),
            .k = key,
        };
    }

    pub fn block_encrypt(self: *Self, val: []u32) []u32 {
        var z: u32 = val[val.len - 1];
        var y: u32 = val[0];
        var sum: u32 = 0;

        var q: u32 = 6 + 52 / @as(u32, @truncate(val.len));
        while (q > 0) : (q -= 1) {
            sum +%= Self.DELTA;
            const e: u32 = (sum >> 2) & 3;
            var p: u32 = 0;
            while (p < @as(u32, @truncate(val.len)) - 1) : (p += 1) {
                y = val[p + 1];
                val[p] +%= ((z >> 5 ^ y << 2) +% (y >> 3 ^ z << 4) ^ (sum ^ y) +% (self.k[p & 3 ^ e] ^ z));
                z = val[p];
            }
            y = val[0];
            val[val.len - 1] +%= ((z >> 5 ^ y << 2) +% (y >> 3 ^ z << 4) ^ (sum ^ y) +% (self.k[p & 3 ^ e] ^ z));
            z = val[val.len - 1];
        }

        return val;
    }

    pub fn block_decrypt(self: *Self, val: []u32) []u32 {
        var z: u32 = val[val.len - 1];
        var y: u32 = val[0];
        var sum: u32 = 0;

        var q: u32 = 6 + 52 / @as(u32, @truncate(val.len));
        while (q > 0) : (q -= 1) {
            sum = q *% DELTA;
            const e: u32 = (sum >> 2) & 3;
            var p: u32 = @as(u32, @truncate(val.len)) - 1;
            while (p > 0) : (p -= 1) {
                z = val[p - 1];
                val[p] -%= ((z >> 5 ^ y << 2) +% (y >> 3 ^ z << 4) ^ (sum ^ y) +% (self.k[p & 3 ^ e] ^ z));
                y = val[p];
            }
            z = val[val.len - 1];
            val[0] -%= ((z >> 5 ^ y << 2) +% (y >> 3 ^ z << 4) ^ (sum ^ y) +% (self.k[p & 3 ^ e] ^ z));
            y = val[0];
            sum -%= Self.DELTA;
        }

        return val;
    }

    pub fn denint(self: *Self) void {
        self.key = 0;
        self.k = std.mem.zeroes([4]u32);
    }
};
