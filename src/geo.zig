const std = @import("std");

const COS_30 = 0.866025;
const SIN_30 = 0.5;
const COS_60 = 0.5;
const SIN_60 = 0.866025;

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
    LEFT_DOWN,
    LEFT,
    LEFT_UP,
    UP_LEFT,
    UP,
    UP_RIGHT,
    RIGHT_UP,
    RIGHT,
    RIGHT_DOWN,
    DOWN_RIGHT,
    DOWN,
    DOWN_LEFT,

    pub fn unitVec(self: Direction) Vec {
        return switch (self) {
            .UP => Vec{ .x = 0, .y = -1 },
            .DOWN => Vec{ .x = 0, .y = 1 },
            .LEFT => Vec{ .x = -1, .y = 0 },
            .RIGHT => Vec{ .x = 1, .y = 0 },
            .LEFT_UP => Vec{ .x = -COS_30, .y = -SIN_30 },
            .UP_LEFT => Vec{ .x = -COS_60, .y = -SIN_60 },
            .LEFT_DOWN => Vec{ .x = -COS_30, .y = SIN_30 },
            .DOWN_LEFT => Vec{ .x = -COS_60, .y = SIN_60 },
            .RIGHT_UP => Vec{ .x = COS_30, .y = -SIN_30 },
            .UP_RIGHT => Vec{ .x = COS_60, .y = -SIN_60 },
            .RIGHT_DOWN => Vec{ .x = COS_30, .y = SIN_30 },
            .DOWN_RIGHT => Vec{ .x = COS_60, .y = SIN_60 },
        };
    }

    pub fn vec(self: Direction, length: f32) Vec {
        var v = self.unitVec();
        v.x *= length;
        v.y *= length;
        return v;
    }
};
