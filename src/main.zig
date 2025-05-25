pub fn main() anyerror!void {
    // TODO(philippwendel): fix memory on emscripten and switch to regular allocator
    var buffer: [50000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    rl.setConfigFlags(.{ .window_resizable = true, .window_highdpi = true });
    rl.initWindow(screenWidth, screenHeight, "cloth particle sim");
    rl.setWindowMinSize(320, 240);
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var particles: std.ArrayList(Particle) = .init(allocator);
    var constraints: std.ArrayList(Constraint) = .init(allocator);

    rl.traceLog(.info, "Create particles", .{});
    // Create Particles
    for (0..ROWS) |row| {
        for (0..COLS) |col| {
            const x = DistanceBetweenPoints + tof32(col) * DistanceBetweenPoints;
            const y = DistanceBetweenPoints + tof32(row) * DistanceBetweenPoints;
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
    for (2..7) |i| try particles.append(.init(1200, 50 * tof32(i), false));

    rl.traceLog(.info, "Create constraints", .{});
    // Create Constraints
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

    // Main loop
    rl.traceLog(.info, "Main loop", .{});
    while (!rl.windowShouldClose()) {
        const force = blk: {
            var f: rl.Vector2 = .init(0, Gravity);
            if (rl.isMouseButtonDown(.left)) // mouse moves particles
                f = f.add(rl.getMouseDelta().scale(0.25));
            break :blk f;
        };
        //apply force and update particles
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

        rl.drawFPS(10, 10);
        rl.drawText(
            "Click mouse left and drag in a directon to apply a force.",
            200,
            10,
            30,
            .white,
        );
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

// Constants
const screenWidth = 1280;
const screenHeight = 720;

const Gravity = 9.81;
const TimeStep = 0.1;

const ROWS = 10;
const COLS = 20;
const DistanceBetweenPoints = 50.0;

// Own Code
const Particle = @import("Particle.zig");
const Constraint = @import("Constraint.zig");

// Libs
const std = @import("std");
const rl = @import("raylib");
