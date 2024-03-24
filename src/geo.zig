const std = @import("std");

pub const Vec = struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn setNull(self: *Vec) void {
        self.x = 0;
        self.y = 0;
    }

    pub fn isNull(self: Vec) bool {
        return self.x == 0 and self.y == 0;
    }

    pub fn scale(self: *Vec, scalar: f32) void {
        self.x *= scalar;
        self.y *= scalar;
    }

    pub fn add(self: *Vec, other: Vec) void {
        self.x += other.x;
        self.y += other.y;
    }

    pub fn step(self: Vec, length: f32) Vec {
        const abs = self.getAbs();
        return Vec{ .x = length * self.x / abs, .y = length * self.y / abs };
    }

    pub fn dot(self: Vec, other: Vec) f32 {
        return self.x * other.x + self.y * other.y;
    }

    pub fn getAbs(self: Vec) f32 {
        return std.math.sqrt(self.x * self.x + self.y * self.y);
    }
};

pub const Direction = enum(u8) {
    LEFT,
    UP,
    RIGHT,
    DOWN,

    pub fn unitVec(self: Direction) Vec {
        return switch (self) {
            .UP => Vec{ .x = 0, .y = -1 },
            .DOWN => Vec{ .x = 0, .y = 1 },
            .LEFT => Vec{ .x = -1, .y = 0 },
            .RIGHT => Vec{ .x = 1, .y = 0 },
        };
    }

    pub fn vec(self: Direction, length: f32) Vec {
        var v = self.unitVec();
        v.x *= length;
        v.y *= length;
        return v;
    }
};
