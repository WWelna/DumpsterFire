// Copyright (C) 2025 William Welna (wwelna@occultusterra.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

const std = @import("std");

const XTEA = struct {
    const Self = @This();
    const DELTA: u32 = 0x9E3779B9;
    key: u128,
    k: [4]u32,
    rounds: u32,

    pub fn init128(key: u128) Self {
        return .{
            .key = key,
            .rounds = 32,
            .k = .{ (@as(u32, @truncate(key)) >> 96), (@as(u32, @truncate(key)) >> 64), (@as(u32, @truncate(key)) >> 32), @as(u32, @truncate(key)) },
        };
    }

    pub fn init(key: [4]u32) Self {
        return .{
            .key = (@as(u128, @intCast(key[0])) << 96) | (@as(u128, @intCast(key[1])) << 64) | (@as(u128, @intCast(key[2])) << 32) | @as(u128, @intCast(key[3])),
            .rounds = 32,
            .k = key,
        };
    }

    pub fn block_encrypt(self: *Self, val: u64) u64 {
        var valh: u32 = @as(u32, @truncate((val >> 32)));
        var vall: u32 = @as(u32, @truncate(val));

        var sum: u32 = 0;
        var i: usize = 0;
        while (i < self.rounds) : (i += 1) {
            valh +%= (((vall << 4) ^ (vall >> 5)) +% vall) ^ (sum +% self.k[sum & 3]);
            sum +%= Self.DELTA;
            vall +%= (((valh << 4) ^ (valh >> 5)) +% valh) ^ (sum +% self.k[(sum >> 11) & 3]);
        }

        return (@as(u64, @intCast(valh)) << 32) | @as(u64, @intCast(vall));
    }

    pub fn block_decrypt(self: *Self, val: u64) u64 {
        var valh: u32 = @as(u32, @truncate((val >> 32)));
        var vall: u32 = @as(u32, @truncate(val));

        var sum: u32 = Self.DELTA *% self.rounds;
        var i: usize = 0;
        while (i < 32) : (i += 1) {
            vall -%= (((valh << 4) ^ (valh >> 5)) +% valh) ^ (sum +% self.k[(sum >> 11) & 3]);
            sum -%= Self.DELTA;
            valh -%= (((vall << 4) ^ (vall >> 5)) +% vall) ^ (sum +% self.k[sum & 3]);
        }

        return (@as(u64, @intCast(valh)) << 32) | @as(u64, @intCast(vall));
    }

    pub fn denint(self: *Self) void {
        self.key = 0;
        self.k = std.mem.zeroes([4]u32);
        self.rounds = 0;
    }
};
