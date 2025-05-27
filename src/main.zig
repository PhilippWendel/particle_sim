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

    var myFirstSimulation = try @import("Simulations/MyFirstSimulation/MyFirstSimulation.zig").init(allocator);

    var camera2d: rl.Camera2D = .{
        .offset = .zero(),
        .target = .zero(),
        .rotation = 0,
        .zoom = 1,
    };
    // Main loop
    rl.traceLog(.info, "Main loop", .{});
    while (!rl.windowShouldClose()) {
        panCamera(&camera2d);
        zoomCamera(&camera2d);
        //apply force and update particles
        myFirstSimulation.step();

        rl.beginDrawing();
        defer rl.endDrawing();

        camera2d.begin();
        defer drawUi();
        defer camera2d.end();

        drawBackground();
        myFirstSimulation.draw();
    }
}

fn drawUi() void {
    rl.drawFPS(10, 10);
    rl.drawText("Click mouse left and drag in a directon to apply a force.", 200, 10, 30, .white);
}

fn panCamera(camera2d: *rl.Camera2D) void {
    if (rl.isMouseButtonDown(.middle)) camera2d.target = camera2d.target.subtract(rl.getMouseDelta());
}

fn zoomCamera(camera2d: *rl.Camera2D) void {
    camera2d.zoom += rl.getMouseWheelMoveV().y * 0.05;
    camera2d.zoom = rl.math.clamp(camera2d.zoom, 0.1, 5.0);
}

pub inline fn tof32(number: anytype) f32 {
    return @as(f32, @floatFromInt(number));
}

fn drawBackground() void {
    const grid_size: f32 = 25;
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
    rl.drawRectangleLines(0, 0, screenWidth, screenHeight, .red);
}

// Constants
pub const screenWidth = 1280;
pub const screenHeight = 720;

// Libs
const std = @import("std");
const rl = @import("raylib");
