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

const TEA = struct {
    const Self = @This();
    const DELTA: u32 = 0x9E3779B9;
    key: u128,
    k1: u32,
    k2: u32,
    k3: u32,
    k4: u32,

    pub fn init128(key: u128) Self {
        return .{
            .key = key,
            .k1 = (@as(u32, @truncate(key)) >> 96),
            .k2 = (@as(u32, @truncate(key)) >> 64),
            .k3 = (@as(u32, @truncate(key)) >> 32),
            .k4 = @as(u32, @truncate(key)),
        };
    }

    pub fn init(key: [4]u32) Self {
        return .{
            .key = (@as(u128, @intCast(key[0])) << 96) | (@as(u128, @intCast(key[1])) << 64) | (@as(u128, @intCast(key[2])) << 32) | @as(u128, @intCast(key[3])),
            .k1 = key[0],
            .k2 = key[1],
            .k3 = key[2],
            .k4 = key[3],
        };
    }

    pub fn block_encrypt(self: *Self, val: u64) u64 {
        var valh: u32 = @as(u32, @truncate((val >> 32)));
        var vall: u32 = @as(u32, @truncate(val));

        var sum: u32 = 0;
        var i: usize = 0;
        while (i < 32) : (i += 1) {
            sum +%= Self.DELTA;
            valh +%= ((vall << 4) +% self.k1) ^ (vall +% sum) ^ ((vall >> 5) +% self.k2);
            vall +%= ((valh << 4) +% self.k3) ^ (valh +% sum) ^ ((valh >> 5) +% self.k4);
        }

        return (@as(u64, @intCast(valh)) << 32) | @as(u64, @intCast(vall));
    }

    pub fn block_decrypt(self: *Self, val: u64) u64 {
        var valh: u32 = @as(u32, @truncate((val >> 32)));
        var vall: u32 = @as(u32, @truncate(val));

        var sum: u32 = 0xC6EF3720;
        var i: usize = 0;
        while (i < 32) : (i += 1) {
            vall -%= ((valh << 4) +% self.k3) ^ (valh +% sum) ^ ((valh >> 5) +% self.k4);
            valh -%= ((vall << 4) +% self.k1) ^ (vall +% sum) ^ ((vall >> 5) +% self.k2);
            sum -%= Self.DELTA;
        }

        return (@as(u64, @intCast(valh)) << 32) | @as(u64, @intCast(vall));
    }

    pub fn denint(self: *Self) void {
        self.k1 = 0;
        self.k2 = 0;
        self.k3 = 0;
        self.k4 = 0;
        self.key = 0;
    }
};
