const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const ch = @import("crash_handler.zig");
const im = @import("input_manager.zig");
const mm = @import("map_manager.zig");
const ti = @import("timer.zig");

var player_atlas: rl.Texture2D = undefined;
pub const def_player_size = rl.Vector2{ .x = 40, .y = 60 };
var animation_timer: ti.Timer = ti.Timer{ .auto_start = true, .duration = 0.3, .repeat = true };

const PlayerAnimState = enum {
    IDLE1,
    IDLE2,
    WALK1,
    WALK2,
    JUMP1,
    JUMP2
};

const CollisionDirectionX = enum {
    LEFT,
    RIGHT,
    NONE
};

const CollisionDirectionY = enum {
    UP,
    DOWN,
    NONE
};

pub const Player = struct {
    pos: rl.Vector2,
    vel: rl.Vector2,
    anim_state: PlayerAnimState = .IDLE1,
    collisionsX: [2]bool = .{ false, false },
    collisionsY: [2]bool = .{ false, false },
    speed: f32 = 3,
    leg_move_toggle: bool = false,
    last_direction_right: bool = true,
    
    pub fn update(self: *Player) void {
        if(im.getHoldKey(.LEFT)) {
            self.vel.x = -self.speed;
            self.last_direction_right = false;
        } else if(im.getHoldKey(.RIGHT)) {
            self.vel.x = self.speed;
            self.last_direction_right = true;
        } else {
            self.vel.x = 0;
        }
        
        if(self.vel.y < 15) self.vel.y += 0.5 * main.dt;
        if(im.getPressKey(.JUMP) and self.collisionsY[@intFromEnum(CollisionDirectionY.DOWN)]) self.vel.y = -10;
        
        self.pos.x += self.vel.x * main.dt;
        self.manageCollisions(true);
        self.pos.y += self.vel.y * main.dt;
        self.manageCollisions(false);
        
        self.manageAnimations();
    }
    
    pub fn draw(self: *Player) void {
        const flip: f32 = if(self.last_direction_right) 1 else -1;
        rl.drawTexturePro(player_atlas, .{ .x = 20 * @as(f32, @floatFromInt(@intFromEnum(self.anim_state))), .y = 0, .width = 20 * flip, .height = 30 }, 
            self.getRect(), .zero(), 0, .white);
        if (main.f3) rl.drawRectangleLinesEx(self.getRect(), 3, .orange);
    }
    
    pub fn getRect(self: *Player) rl.Rectangle {
        return rl.Rectangle{ .x = self.pos.x, .y = self.pos.y, .width = def_player_size.x, .height = def_player_size.y };
    }
    
    fn colliding(self: *Player, tile: mm.Tile) bool {
        return rl.checkCollisionRecs(self.getRect(), tile.dest_rect);
    }
    
    fn getDirectionX(self: *Player) CollisionDirectionX {
        if (self.vel.x < 0) {
            return .LEFT;
        } else if (self.vel.x > 0) {
            return .RIGHT;
        } else return .NONE;
    }
    
    fn getDirectionY(self: *Player) CollisionDirectionY {
        if (self.vel.y < 0) {
            return .UP;
        } else if (self.vel.y > 0) {
            return .DOWN;
        } else return .NONE;
    }
    
    fn collideX(self: *Player, tile: mm.Tile, direction: CollisionDirectionX) void {
        self.collisionsX[@intFromEnum(direction)] = true;
        switch (direction) {
            CollisionDirectionX.LEFT => self.pos.x = tile.dest_rect.x + tile.dest_rect.width,
            CollisionDirectionX.RIGHT => self.pos.x = tile.dest_rect.x - def_player_size.x,
            else => {}
        }
    }
    
    fn collideY(self: *Player, tile: mm.Tile, direction: CollisionDirectionY) void {
        self.collisionsY[@intFromEnum(direction)] = true;
        self.vel.y = 0.1;
        switch (direction) {
            CollisionDirectionY.UP => self.pos.y = tile.dest_rect.y + tile.dest_rect.height,
            CollisionDirectionY.DOWN => self.pos.y = tile.dest_rect.y - def_player_size.y,
            else => {}
        }
    }
    
    pub fn manageCollisions(self: *Player, horizontal: bool) void {
        self.collisionsX = [_]bool{ false } ** 2;
        self.collisionsY = [_]bool{ false } ** 2;
        
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
    
    pub fn manageAnimations(self: *Player) void {
        animation_timer.update();
        
        if(animation_timer.called) {
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

pub fn loadPlayer() void {
    player_atlas = rl.loadTexture("res/sprite/player_atlas.png") catch ch.crash(.RAYLIB_ERROR);
    animation_timer.init();
}

pub fn unloadPlayer() void {
    defer rl.unloadTexture(player_atlas);
}

pub fn newPlayer() Player {
    return Player{ .pos = .{ .x = 10, .y = 10 }, .vel = .zero() };
}

