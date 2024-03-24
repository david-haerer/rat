const std = @import("std");

pub const NS_PER_CLICK = std.time.ns_per_ms * 50;
pub const MAX_SPEED = 100000;
pub const NORMAL_ACCELERATION = 0.4;
pub const NORMAL_STEP = 5;
pub const SCROLL_ACCELERATION = 0.01;
pub const SCROLL_STEP = 1;
