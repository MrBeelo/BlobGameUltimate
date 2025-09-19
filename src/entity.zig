const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const ch = @import("crash_handler.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");
const ti = @import("timer.zig");

pub const CollisionDirectionX = enum {
    LEFT,
    RIGHT,
    NONE
};

pub const CollisionDirectionY = enum {
    UP,
    DOWN,
    NONE
};

pub const DefaultAnimState = enum {
    IDLE1,
    IDLE2,
    WALK1,
    WALK2,
    JUMP1,
    JUMP2
};

pub const EntityData = struct {
    pos: rl.Vector2 = .{ .x = 0, .y = 0 },
    size: rl.Vector2,
    vel: rl.Vector2 = .{ .x = 0, .y = 0 },
    collisionsX: [2]bool = .{ false, false },
    collisionsY: [2]bool = .{ false, false },
    speed: f32 = 3,
    last_direction_right: bool = true,
    anim_state: DefaultAnimState = .IDLE1,
    leg_move_toggle: bool = false,
    
    pub fn update(self: *EntityData) void {
        if(self.vel.y < 15) self.vel.y += 0.5 * main.dt;
        
        self.pos.x += self.vel.x * main.dt;
        self.manageCollisions(true);
        self.pos.y += self.vel.y * main.dt;
        self.manageCollisions(false);
    }
    
    pub fn moveLeft(self: *EntityData) void {
        self.vel.x = -self.speed;
        self.last_direction_right = false;
    }
    
    pub fn moveRight(self: *EntityData) void {
        self.vel.x = self.speed;
        self.last_direction_right = true;
    }
    
    pub fn jump(self: *EntityData) void {
        if(self.collisionsY[@intFromEnum(CollisionDirectionY.DOWN)]) self.vel.y = -10;
    }
    
    pub fn getRect(self: *EntityData) rl.Rectangle {
        return rl.Rectangle{ .x = self.pos.x, .y = self.pos.y, .width = self.size.x, .height = self.size.y };
    }
    
    fn colliding(self: *EntityData, tile: mm.Tile) bool {
        return rl.checkCollisionRecs(self.getRect(), tile.dest_rect);
    }
    
    fn getDirectionX(self: *EntityData) CollisionDirectionX {
        if (self.vel.x < 0) {
            return .LEFT;
        } else if (self.vel.x > 0) {
            return .RIGHT;
        } else return .NONE;
    }
    
    fn getDirectionY(self: *EntityData) CollisionDirectionY {
        if (self.vel.y < 0) {
            return .UP;
        } else if (self.vel.y > 0) {
            return .DOWN;
        } else return .NONE;
    }
    
    fn collideX(self: *EntityData, tile: mm.Tile, direction: CollisionDirectionX) void {
        self.collisionsX[@intFromEnum(direction)] = true;
        switch (direction) {
            CollisionDirectionX.LEFT => self.pos.x = tile.dest_rect.x + tile.dest_rect.width,
            CollisionDirectionX.RIGHT => self.pos.x = tile.dest_rect.x - self.size.x,
            else => {}
        }
    }
    
    fn collideY(self: *EntityData, tile: mm.Tile, direction: CollisionDirectionY) void {
        self.collisionsY[@intFromEnum(direction)] = true;
        self.vel.y = 0.1;
        switch (direction) {
            CollisionDirectionY.UP => self.pos.y = tile.dest_rect.y + tile.dest_rect.height,
            CollisionDirectionY.DOWN => self.pos.y = tile.dest_rect.y - self.size.y,
            else => {}
        }
    }
    
    pub fn manageCollisions(self: *EntityData, horizontal: bool) void {
        if(horizontal) self.collisionsX = [_]bool{ false } ** 2 else self.collisionsY = [_]bool{ false } ** 2;
        
        for (main.test_map.data) |tile| {
            switch (tile.type) {
                mm.TileType.AIR => {},
                mm.TileType.SOLID => {
                    if(self.colliding(tile) and horizontal) {
                        self.collideX(tile, self.getDirectionX());
                    } else if (self.colliding(tile) and !horizontal) {
                        self.collideY(tile, self.getDirectionY());
                    }
                }
            }
        }
    }
    
    pub fn handleBaseAnims(self: *EntityData) void {
        if(self.vel.x == 0) {
            self.anim_state = if(self.anim_state == .IDLE1) .IDLE2 else .IDLE1;
        } else {
            if(self.anim_state == .WALK1 or self.anim_state == .WALK2) {
                self.anim_state = .IDLE1;
            } else if(self.anim_state == .IDLE1) {
                self.anim_state = if(self.leg_move_toggle) .WALK1 else .WALK2;
                self.leg_move_toggle = !self.leg_move_toggle;
            }
        }
    }
    
    pub fn handleAnimEdgeCases(self: *EntityData) void {
        if(!self.collisionsY[@intFromEnum(CollisionDirectionY.DOWN)]) {
            self.anim_state = if(self.vel.y < -2.5 or self.vel.y > 2.5) .JUMP1 else .JUMP2;
        } else if(self.anim_state == .JUMP1 or self.anim_state == .JUMP2) {
            self.anim_state = if(self.vel.x == 0) .IDLE1 else .WALK1;
        } else if(self.anim_state == .WALK1 or self.anim_state == .WALK2) {
            if(self.vel.x == 0) self.anim_state = .IDLE1;
        } else if(self.anim_state == .IDLE2) {
            if(self.vel.x != 0) self.anim_state = .IDLE1;
        }
    }
};