p1: *Particle,
p2: *Particle,
initial_length: f32,
active: bool,

pub fn init(p1: *Particle, p2: *Particle) Constraint {
    return .{
        .p1 = p1,
        .p2 = p2,
        .initial_length = p2.position.distance(p1.position),
        .active = true,
    };
}
pub fn satisfy(self: *Constraint) void {
    if (!self.active) return;

    const delta = self.p2.position.subtract(self.p1.position);
    const current_length = self.p2.position.distance(self.p1.position);
    const difference = (current_length - self.initial_length) / current_length;
    const correction = delta.scale(difference * 0.5);

    if (!self.p1.is_pinned) self.p1.position = self.p1.position.add(correction);
    if (!self.p2.is_pinned) self.p2.position = self.p2.position.subtract(correction);
}
pub fn deactivate(self: *Constraint) void {
    self.active = false;
}

const Particle = @import("Particle.zig");
const Constraint = @This();
