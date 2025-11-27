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

const isaac32 = struct {
    const Self = @This();
    randrsl: [256]u32,
    mm: [256]u32,
    randcnt: u32,
    aa: u32,
    bb: u32,
    cc: u32,

    pub fn init() Self {
        return .{ .randrsl = std.mem.zeroes([256]u32), .mm = std.mem.zeroes([256]u32), .randcnt = 0, .aa = 0, .bb = 0, .cc = 0 };
    }

    inline fn mix(a: *u32, b: *u32, c: *u32, d: *u32, e: *u32, f: *u32, g: *u32, h: *u32) void {
        a.* ^= b.* << 11;
        d.* +%= a.*;
        b.* +%= c.*;
        b.* ^= c.* >> 2;
        e.* +%= b.*;
        c.* +%= d.*;
        c.* ^= d.* << 8;
        f.* +%= c.*;
        d.* +%= e.*;
        d.* ^= e.* >> 16;
        g.* +%= d.*;
        e.* +%= f.*;
        e.* ^= f.* << 10;
        h.* +%= e.*;
        f.* +%= g.*;
        f.* ^= g.* >> 4;
        a.* +%= f.*;
        g.* +%= h.*;
        g.* ^= h.* << 8;
        b.* +%= g.*;
        h.* +%= a.*;
        h.* ^= a.* >> 9;
        c.* +%= h.*;
        a.* +%= b.*;
    }

    fn randinit(self: *Self, flag: bool) void {
        var i: usize = 0;
        var a: u32 = 0x9e3779b9;
        var b: u32 = 0x9e3779b9;
        var c: u32 = 0x9e3779b9;
        var d: u32 = 0x9e3779b9;
        var e: u32 = 0x9e3779b9;
        var f: u32 = 0x9e3779b9;
        var g: u32 = 0x9e3779b9;
        var h: u32 = 0x9e3779b9;

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

    fn isaac(self: *Self) void {
        var i: u32 = 0;
        var x: u32 = 0;
        var y: u32 = 0;

        self.cc +%= 1;
        self.bb +%= self.cc;

        while (i < 255) : (i += 1) {
            x = self.mm[i];
            switch (i % 4) {
                0 => self.aa ^= (self.aa << 13),
                1 => self.aa ^= (self.aa >> 6),
                2 => self.aa ^= (self.aa << 2),
                3 => self.aa ^= (self.aa >> 16),
                else => unreachable,
            }
            self.aa = self.mm[(i + 128) % 255] +% self.aa;
            y = self.mm[(x >> 2) % 255] +% self.aa +% self.bb;
            self.mm[i] = y;
            self.bb = self.mm[(y >> 10) % 255] +% x;
            self.randrsl[i] = self.bb;
        }
    }

    pub fn u8Seed(self: *Self, seed: []const u8, flag: bool) void {
        var i: u32 = 0;
        while (i < 255) : (i += 1) {
            if (i > seed.len - 1) self.randrsl[i] = 0 else self.randrsl[i] = seed[i];
        }
        self.randinit(flag);
    }

    pub fn randSeed(self: *Self) [255]u32 {
        var r: [255]u32 = undefined;
        for (&self.randrsl, &r) |*x, *y| {
            y.* = std.crypto.random.int(u32);
            x.* = y.*;
        }
        self.randinit(true);
        return r;
    }

    pub fn drop(self: *Self, count: usize) void {
        for (0..count) |_| _ = self.u32Random();
    }

    pub fn u8Random(self: *Self) u8 {
        return @as(u8, @intCast(self.u32Random() % std.math.maxInt(u8)));
    }

    pub fn u16Random(self: *Self) u16 {
        return @as(u16, @intCast(self.u32Random() % std.math.maxInt(u16)));
    }

    pub fn u32Random(self: *Self) u32 {
        const r = self.randrsl[self.randcnt];
        self.randcnt += 1;
        if (self.randcnt > 255) {
            self.isaac();
            self.randcnt = 0;
        }
        return r;
    }

    pub fn u64Random(self: *Self) u64 {
        return (@as(u64, self.u32Random()) << 32) | @as(u64, self.u32Random());
    }

    pub fn asciiRand(self: *Self) u8 {
        return @as(u8, @intCast(self.u32Random() % 95 + 32));
    }

    pub fn deinit(self: *Self) void {
        self.randrsl = std.mem.zeroes([256]u32);
        self.mm = std.mem.zeroes([256]u32);
        self.aa = 0;
        self.bb = 0;
        self.cc = 0;
        self.randcnt = 0;
    }
};
