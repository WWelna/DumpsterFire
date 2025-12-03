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

// I am not sure if this is 100% accurate as there is a bug in the original isaac64.c.
// I used https://docs.rs/rand_isaac/latest/rand_isaac/isaac64/struct.Isaac64Rng.html pseudo-code as a reference.

const std = @import("std");

const isaac64 = struct {
    const Self = @This();
    randrsl: [256]u64,
    mm: [256]u64,
    randcnt: u64,
    aa: u64,
    bb: u64,
    cc: u64,

    pub fn init() Self {
        return .{ .randrsl = std.mem.zeroes([256]u64), .mm = std.mem.zeroes([256]u64), .randcnt = 0, .aa = 0, .bb = 0, .cc = 0 };
    }

    inline fn mix(a: *u64, b: *u64, c: *u64, d: *u64, e: *u64, f: *u64, g: *u64, h: *u64) void {
        a.* -%= e.*;
        f.* ^= h.* >> 9;
        h.* +%= a.*;
        b.* -%= f.*;
        g.* ^= a.* << 9;
        a.* +%= b.*;
        c.* -%= g.*;
        h.* ^= b.* >> 23;
        b.* +%= c.*;
        d.* -%= h.*;
        a.* ^= c.* << 15;
        c.* +%= d.*;
        e.* -%= a.*;
        b.* ^= d.* >> 14;
        d.* +%= e.*;
        f.* -%= b.*;
        c.* ^= e.* << 20;
        e.* +%= f.*;
        g.* -%= c.*;
        d.* ^= f.* >> 17;
        f.* +%= g.*;
        h.* -%= d.*;
        e.* ^= g.* << 14;
        g.* +%= h.*;
    }

    fn randinit(self: *Self, flag: bool) void {
        var i: usize = 0;
        var a: u64 = 0x9e3779b97f4a7c13;
        var b: u64 = 0x9e3779b97f4a7c13;
        var c: u64 = 0x9e3779b97f4a7c13;
        var d: u64 = 0x9e3779b97f4a7c13;
        var e: u64 = 0x9e3779b97f4a7c13;
        var f: u64 = 0x9e3779b97f4a7c13;
        var g: u64 = 0x9e3779b97f4a7c13;
        var h: u64 = 0x9e3779b97f4a7c13;

        for (0..4) |t| {
            _ = t;
            Self.mix(&a, &b, &c, &d, &e, &f, &g, &h);
        }

        while (i < 255) : (i += 8) {
            if (flag) {
                a +%= self.randrsl[i];
                b +%= self.randrsl[i + 1];
                c +%= self.randrsl[i + 2];
                d +%= self.randrsl[i + 3];
                e +%= self.randrsl[i + 4];
                f +%= self.randrsl[i + 5];
                g +%= self.randrsl[i + 6];
                h +%= self.randrsl[i + 7];
            }
            Self.mix(&a, &b, &c, &d, &e, &f, &g, &h);
            self.mm[i] = a;
            self.mm[i + 1] = b;
            self.mm[i + 2] = c;
            self.mm[i + 3] = d;
            self.mm[i + 4] = e;
            self.mm[i + 5] = f;
            self.mm[i + 6] = g;
            self.mm[i + 7] = h;
        }

        if (flag) {
            i = 0;
            while (i < 255) : (i += 8) {
                a +%= self.mm[i];
                b +%= self.mm[i + 1];
                c +%= self.mm[i + 2];
                d +%= self.mm[i + 3];
                e +%= self.mm[i + 4];
                f +%= self.mm[i + 5];
                g +%= self.mm[i + 6];
                h +%= self.mm[i + 7];
                Self.mix(&a, &b, &c, &d, &e, &f, &g, &h);
                self.mm[i] = a;
                self.mm[i + 1] = b;
                self.mm[i + 2] = c;
                self.mm[i + 3] = d;
                self.mm[i + 4] = e;
                self.mm[i + 5] = f;
                self.mm[i + 6] = g;
                self.mm[i + 7] = h;
            }
        }

        self.isaac();
    }

    inline fn step(self: *Self, sugar: u64, i: u64) void {
        const x: u64 = self.mm[i];
        self.aa = sugar +% self.mm[(i + 128) % 256];

        self.mm[i] = self.aa +% self.bb +% self.mm[@as(u8, @intCast((x >> 3) % 256))];
        self.bb = self.mm[@as(u8, @intCast((self.mm[i] >> 11) % 256))] +% x;
        self.randrsl[i] = self.bb;
    }

    fn isaac(self: *Self) void {
        var i: u64 = undefined;
        self.cc +%= 1;
        self.bb +%= self.cc;

        i = 0;
        while (i < 256) : (i += 4) {
            self.step(~(self.aa ^ (self.aa << 21)), i);
            self.step(self.aa ^ (self.aa >> 5), i + 1);
            self.step(self.aa ^ (self.aa << 12), i + 2);
            self.step(self.aa ^ (self.aa >> 33), i + 3);
        }
    }

    pub fn u8Seed(self: *Self, seed: []const u8, flag: bool) void {
        var i: u64 = 0;
        while (i < 255) : (i += 1) {
            if (i > seed.len - 1) self.randrsl[i] = 0 else self.randrsl[i] = seed[i];
        }
        self.randinit(flag);
    }

    pub fn randSeed(self: *Self) [255]u64 {
        var r: [255]u64 = undefined;
        for (&self.randrsl, &r) |*x, *y| {
            y.* = std.crypto.random.int(u64);
            x.* = y.*;
        }
        self.randinit(true);
        return r;
    }

    pub fn drop(self: *Self, count: usize) void {
        for (0..count) |_| _ = self.u64Random();
    }

    pub fn u8Random(self: *Self) u8 {
        return @as(u8, @intCast(self.u64Random() % std.math.maxInt(u8)));
    }

    pub fn u16Random(self: *Self) u16 {
        return @as(u16, @intCast(self.u64Random() % std.math.maxInt(u16)));
    }

    pub fn u32Random(self: *Self) u32 {
        return @as(u32, @intCast(self.u64Random() % std.math.maxInt(u32)));
    }

    pub fn u64Random(self: *Self) u64 {
        const r = self.randrsl[self.randcnt];
        self.randcnt += 1;
        if (self.randcnt > 255) {
            self.isaac();
            self.randcnt = 0;
        }
        return r;
    }

    pub fn asciiRand(self: *Self) u8 {
        return @as(u8, @intCast(self.u64Random() % 95 + 32));
    }

    pub fn deinit(self: *Self) void {
        self.randrsl = std.mem.zeroes([256]u64);
        self.mm = std.mem.zeroes([256]u64);
        self.aa = 0;
        self.bb = 0;
        self.cc = 0;
        self.randcnt = 0;
    }
};
