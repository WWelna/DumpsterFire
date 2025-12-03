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

const RC4 = struct {
    const Self = @This();
    i: u8,
    j: u8,
    s: [256]u8,

    pub fn init(key: []const u8) Self {
        std.debug.print("{x} {}\n", .{ key, key.len });
        var ret: Self = .{ .i = 0, .j = 0, .s = blk: {
            var t: [256]u8 = undefined;
            for (0..256) |x| t[x] = @truncate(x);
            break :blk t;
        } };
        var j: u8 = 0;
        for (0..256) |x| {
            j = j +% ret.s[x] +% key[x % key.len];
            const tmp = ret.s[x];
            ret.s[x] = ret.s[j];
            ret.s[j] = tmp;
        }
        return ret;
    }

    fn step(self: *Self) u8 {
        self.i = self.i +% 1;
        self.j = self.j +% self.s[self.i];
        const tmp = self.s[self.i];
        self.s[self.i] = self.s[self.j];
        self.s[self.j] = tmp;
        return self.s[self.s[self.i] +% self.s[self.j]];
    }

    pub fn drop(self: *Self, count: usize) void {
        for (0..count) |_| _ = self.step();
    }

    pub fn u8Random(self: *Self) u8 {
        return self.step();
    }

    pub fn u16Random(self: *Self) u16 {
        return (@as(u16, self.step()) << 8) | @as(u16, self.step());
    }

    pub fn u32Random(self: *Self) u32 {
        return (@as(u32, self.step()) << 24) | (@as(u32, self.step()) << 16) | (@as(u32, self.step()) << 8) | @as(u32, self.step());
    }

    pub fn u64Random(self: *Self) u64 {
        return (@as(u64, self.u32Random()) << 32) | @as(u64, self.u32Random());
    }

    pub fn deinit(self: *Self) void {
        self.s = std.mem.zeroes([256]u8);
        self.i = 0;
        self.j = 0;
    }
};
