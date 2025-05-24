pub fn main() anyerror!void {
    const Gravity = 9.81;
    const TimeStep = 0.1;

    const ROWS = 10;
    const COLS = 20;
    const DistanceBetweenPoints = 50.0;

    const allocator = std.heap.page_allocator;

    rl.setConfigFlags(.{ .window_resizable = true, .window_highdpi = true });
    rl.initWindow(screenWidth, screenHeight, "cloth particle sim");
    rl.setWindowMinSize(320, 240);
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var particles: std.ArrayList(Particle) = .init(allocator);
    var constraints: std.ArrayList(Constraint) = .init(allocator);

    // Create Particles
    for (0..ROWS) |row| {
        for (0..COLS) |col| {
            const x = DistanceBetweenPoints + tof32(col) * DistanceBetweenPoints;
            const y = DistanceBetweenPoints + tof32(row) * DistanceBetweenPoints;
            const is_pinned = (row == 0 or row == 9) and (col == 0 or col == 19);
            try particles.append(.init(x, y, is_pinned));
        }
    }

    // Create Constraints
    for (0..ROWS) |row| {
        for (0..COLS) |col| {
            if (col < COLS - 1) {
                // Horizontal constraint
                try constraints.append(
                    .init(
                        &particles.items[row * COLS + col],
                        &particles.items[row * COLS + col + 1],
                    ),
                );
            }
            if (row < ROWS - 1) {
                // Vertical constraint
                try constraints.append(
                    .init(
                        &particles.items[row * COLS + col],
                        &particles.items[(row + 1) * COLS + col],
                    ),
                );
            }
        }
    }

    try particles.append(.init(1050, 50, false));
    try particles.append(.init(1050, 100, false));
    try particles.append(.init(1100, 50, false));
    try particles.append(.init(1100, 100, false));
    for (particles.items[particles.items.len - 4 ..]) |*p1|
        for (particles.items[particles.items.len - 4 ..]) |*p2|
            if (p1 != p2) try constraints.append(.init(p1, p2));

    while (!rl.windowShouldClose()) {
        const force = blk: {
            var f: rl.Vector2 = .init(0, Gravity);
            if (rl.isMouseButtonDown(.left))
                f = f.add(rl.getMouseDelta().scale(0.25));
            break :blk f;
        };
        //apply gravity and update particles
        for (particles.items) |*p| {
            p.apply_force(force);
            p.update(TimeStep);
            p.constrain_to_bounds(screenWidth, screenHeight);
        }

        for (0..5) |_|
            for (constraints.items) |*c| c.satisfy();

        rl.beginDrawing();
        defer rl.endDrawing();
        drawBackground();

        for (constraints.items) |c|
            if (c.active) rl.drawLineV(c.p1.position, c.p2.position, .white);
        for (particles.items) |p|
            rl.drawCircleV(p.position, 5.0, if (p.is_pinned) .red else .white);
    }
}

pub inline fn tof32(number: anytype) f32 {
    return @as(f32, @floatFromInt(number));
}

fn drawBackground() void {
    const grid_size: i32 = 25;
    const grid_color: rl.Color = .init(255, 255, 255, 32);

    rl.clearBackground(.init(32, 32, 32, 255));
    {
        var pos: i32 = 0;
        while (pos < screenHeight) : (pos += grid_size)
            rl.drawLine(0, pos, screenWidth, pos, grid_color);
    }
    {
        var pos: i32 = 0;
        while (pos < screenWidth) : (pos += grid_size)
            rl.drawLine(pos, 0, pos, screenHeight, grid_color);
    }
}

const screenWidth = 1280;
const screenHeight = 720;

const Particle = @import("Particle.zig");
const Constraint = @import("Constraint.zig");

const std = @import("std");
const rl = @import("raylib");
