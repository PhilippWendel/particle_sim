particles: std.ArrayList(Particle),
constraints: std.ArrayList(Constraint),

pub fn init(allocator: std.mem.Allocator) !Simulation {
    var particles: std.ArrayList(Particle) = .init(allocator);
    var constraints: std.ArrayList(Constraint) = .init(allocator);

    rl.traceLog(.info, "Create particles", .{});
    for (0..ROWS) |row| {
        for (0..COLS) |col| {
            const x = DistanceBetweenPoints + util.tof32(col) * DistanceBetweenPoints;
            const y = DistanceBetweenPoints + util.tof32(row) * DistanceBetweenPoints;
            const is_pinned = (row == 0 or row == 9) and (col == 0 or col == 19);
            try particles.append(.init(x, y, is_pinned));
        }
    }
    const box_pos = particles.items.len;
    try particles.append(.init(1050, 50, false));
    try particles.append(.init(1050, 100, false));
    try particles.append(.init(1100, 50, false));
    try particles.append(.init(1100, 100, false));
    const pendulum_pos = particles.items.len;
    try particles.append(.init(1200, 50, true));
    for (2..7) |i| try particles.append(.init(1200, 50 * util.tof32(i), false));

    rl.traceLog(.info, "Create constraints", .{});
    for (0..ROWS) |row| {
        for (0..COLS) |col| {
            if (col < COLS - 1)
                try constraints.append(.init(&particles.items[row * COLS + col], &particles.items[row * COLS + col + 1])); // Horizontal constraint
            if (row < ROWS - 1)
                try constraints.append(.init(&particles.items[row * COLS + col], &particles.items[(row + 1) * COLS + col])); // Vertical constraint
        }
    }
    for (particles.items[box_pos .. box_pos + 4]) |*p1|
        for (particles.items[box_pos .. box_pos + 4]) |*p2|
            if (p1 != p2) try constraints.append(.init(p1, p2));
    for (particles.items[pendulum_pos .. pendulum_pos + 4], particles.items[pendulum_pos + 1 .. pendulum_pos + 5]) |*p1, *p2|
        try constraints.append(.init(p1, p2));

    return .{ .particles = particles, .constraints = constraints };
}

pub fn step(self: *Simulation) void {
    const force = blk: {
        var f: rl.Vector2 = .init(0, Gravity);
        if (rl.isMouseButtonDown(.left)) // mouse moves particles
            f = f.add(rl.getMouseDelta().scale(0.25));
        break :blk f;
    };
    for (self.particles.items) |*p| {
        p.apply_force(force);
        p.update(TimeStep);
        p.constrain_to_bounds(util.screenWidth, util.screenHeight);
    }

    for (0..5) |_|
        for (self.constraints.items) |*c| c.satisfy();
}

pub fn draw(self: *Simulation) void {
    for (self.constraints.items) |c|
        if (c.active) rl.drawLineV(c.p1.position, c.p2.position, .white);
    for (self.particles.items) |p|
        rl.drawCircleV(p.position, 5.0, if (p.is_pinned) .red else .white);
}

const Gravity = 9.81;
const TimeStep = 0.1;

const ROWS = 10;
const COLS = 20;
const DistanceBetweenPoints = 50.0;

const Simulation = @This();
const Particle = @import("Particle.zig");
const Constraint = @import("Constraint.zig");
const util = @import("../../main.zig");

const std = @import("std");
const rl = @import("raylib");
