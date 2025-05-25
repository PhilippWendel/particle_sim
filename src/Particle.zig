position: rl.Vector2,
previous_position: rl.Vector2,
acceleration: rl.Vector2,
is_pinned: bool,

pub fn init(x: f32, y: f32, is_pinned: bool) Particle {
    return .{
        .position = .init(x, y),
        .previous_position = .init(x, y),
        .acceleration = .zero(),
        .is_pinned = is_pinned,
    };
}
pub fn apply_force(self: *Particle, force: rl.Vector2) void {
    if (!self.is_pinned) self.acceleration = self.acceleration.add(force);
}
pub fn update(self: *Particle, time_step: f32) void {
    // verlet intergration
    if (!self.is_pinned) {
        const velocity = self.position.subtract(self.previous_position);
        self.previous_position = self.position;
        self.position = self.position.add(velocity.add(self.acceleration.scale(time_step * time_step)));
        self.acceleration = .zero(); // reset after update
    }
}
pub fn constrain_to_bounds(self: *Particle, width: f32, height: f32) void {
    if (self.position.x < 0) self.position.x = 0;
    if (self.position.x > width) self.position.x = width;
    if (self.position.y < 0) self.position.y = 0;
    if (self.position.y > height) self.position.y = height;
}

const Particle = @This();

const rl = @import("raylib");
