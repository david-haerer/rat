const Server = @import("server.zig").Server;
const Time = @import("time.zig").Time;
const config = @import("config.zig");
const geo = @import("geo.zig");
const io = @import("io.zig");

pub const Rat = struct {
    mode: io.Mode = .Normal,
    speed: geo.Vec = geo.Vec{},
    time: Time,
    keys: io.Keys,
    acceleration: f32 = config.NORMAL_ACCELERATION,
    server: Server,
    scroll_remainder: geo.Vec = geo.Vec{},

    pub fn init() !Rat {
        const time: Time = try Time.init();
        const server = try Server.connect();
        var keys: io.Keys = undefined;
        inline for (&keys, 0..) |*key, i| key.* = io.Key{ .direction = @enumFromInt(i) };
        return Rat{ .time = time, .keys = keys, .server = server };
    }

    pub fn cleanup(self: Rat) void {
        self.server.disconnect();
    }

    pub fn running(self: Rat) bool {
        return self.mode != io.Mode.Exit;
    }

    pub fn move(self: *Rat) void {
        if (!self.time.nextFrame()) return;
        self.accelerate();
        if (self.speed.isNull()) return;
        switch (self.mode) {
            io.Mode.Normal => self.movePointer(self.speed),
            io.Mode.Scroll => self.scroll(self.speed),
            else => {},
        }
    }

    fn step(self: *Rat, direction: geo.Direction) void {
        switch (self.mode) {
            io.Mode.Normal => self.movePointer(direction.vec(config.NORMAL_STEP)),
            io.Mode.Scroll => self.scroll(direction.vec(config.SCROLL_STEP)),
            else => {},
        }
    }

    fn movePointer(self: Rat, vec: geo.Vec) void {
        self.server.move(@intFromFloat(vec.x), @intFromFloat(vec.y));
    }

    fn scroll(self: *Rat, vec: geo.Vec) void {
        self.scroll_remainder.add(vec);
        const x: i32 = @intFromFloat(self.scroll_remainder.x);
        const y: i32 = @intFromFloat(self.scroll_remainder.y);
        if (x != 0) self.server.scrollHorizontal(x);
        if (y != 0) self.server.scrollVertical(y);
        self.scroll_remainder.x -= @floatFromInt(x);
        self.scroll_remainder.y -= @floatFromInt(y);
    }

    pub fn setMode(self: *Rat, mode: io.Mode) void {
        if (self.mode != mode) self.speed.setNull();
        self.mode = switch (self.mode != mode) {
            true => mode,
            false => io.Mode.Normal,
        };
        self.acceleration = switch (self.mode) {
            io.Mode.Normal => config.NORMAL_ACCELERATION,
            io.Mode.Scroll => config.SCROLL_ACCELERATION,
            else => 0,
        };
    }

    pub fn accelerate(self: *Rat) void {
        var accelerated = false;
        for (&self.keys) |*key| {
            if (key.isClicked(self.time.now)) continue;
            if (key.isPressed()) {
                self.speed.add(key.direction.vec(self.acceleration));
                accelerated = true;
            }
        }
        const abs = self.speed.getAbs();
        if (abs > config.MAX_SPEED) self.speed.scale(config.MAX_SPEED / abs);
        if (!accelerated and abs != 0) {
            const deceleration = @min(self.acceleration, abs);
            self.speed.x -= deceleration * self.speed.x / abs;
            self.speed.y -= deceleration * self.speed.y / abs;
        }
    }

    pub fn pressKey(self: *Rat, direction: geo.Direction) bool {
        const key = &self.keys[@intFromEnum(direction)];
        if (!key.press(self.time.now)) return false;
        if (self.speed.dot(direction.unitVec()) < 0) self.speed.setNull();
        return true;
    }

    pub fn releaseKey(self: *Rat, direction: geo.Direction) void {
        const key = &self.keys[@intFromEnum(direction)];
        key.release(self.time.now);
    }

    pub fn handlePress(self: *Rat, input: io.Input) void {
        switch (input) {
            io.Input.direction => |direction| if (self.pressKey(direction)) self.step(direction),
            io.Input.button => |button| self.server.pressButton(button),
            io.Input.mode => |mode| self.setMode(mode),
        }
    }

    pub fn handleRelease(self: *Rat, input: io.Input) void {
        switch (input) {
            io.Input.direction => |direction| self.releaseKey(direction),
            io.Input.button => |button| self.server.releaseButton(button),
            io.Input.mode => {},
        }
    }

    pub fn handleEvents(self: *Rat) void {
        while (self.server.nextEvent()) {
            const event: io.Event = self.server.event orelse continue;
            const input = io.Input.read(event) orelse continue;
            switch (event.type) {
                .Press => self.handlePress(input),
                .Release => self.handleRelease(input),
            }
        }
    }
};
