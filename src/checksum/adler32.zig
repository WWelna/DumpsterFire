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

const adler32 = struct {
    const Self = @This();
    state_a: u32,
    state_b: u32,

    pub fn initSeed(a: u32, b: u32) Self {
        return .{ .state_a = a, .state_b = b };
    }

    pub fn init() Self {
        return .{ .state_a = 1, .state_b = 0 };
    }

    pub fn update(self: *Self, bytes: []const u8) void {
        for (bytes) |b| {
            self.state_a = (self.state_a + b) % 65521;
            self.state_b = (self.state_b + self.state_a) % 65521;
        }
    }

    pub fn finalize(self: *Self) u32 {
        return (self.state_b << 16) | self.state_a;
    }
};
