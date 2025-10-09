const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const map = @import("map.zig");
const ti = @import("timer.zig");
const obj = @import("object.zig");
const sav = @import("savefile.zig");
const crsh = @import("crash.zig");

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
    health: f32 = 5,
    hit_timer: ti.Timer = .{ .duration = 0.05 },
    immunity_timer: ti.Timer = .{ .duration = 1.5 },
    color: rl.Color = .white,
    is_being_knocked: bool = false,
    is_player: bool = false,
    can_walljump: bool = false,
    
    pub fn update(self: *EntityData) void {
        if(self.vel.y < 15) self.vel.y += 0.5 * main.dt;
        self.can_walljump = false;
        
        self.pos.x += self.vel.x * main.dt;
        self.manageCollisions(true);
        self.pos.y += self.vel.y * main.dt;
        self.manageCollisions(false);
        
        self.hit_timer.update();
        self.immunity_timer.update();
        
        self.color = if(self.immunity_timer.active and !self.hit_timer.active) rl.Color{ .r = 255, .g = 255, .b = 255, .a = 125 } else .white;
        
        if(self.is_being_knocked) {
            if((self.is_player and self.vel.y >= 0) or (!self.is_player and self.collisionsY[@intFromEnum(CollisionDirectionY.DOWN)])) self.is_being_knocked = false;
        }
        //if(self.collisionsY[@intFromEnum(CollisionDirectionY.DOWN)] and self.is_being_knocked) self.is_being_knocked = false;
    }
    
    pub fn moveLeft(self: *EntityData) void {
        if(!self.is_being_knocked) self.vel.x = -self.speed;
        self.last_direction_right = false;
    }
    
    pub fn moveRight(self: *EntityData) void {
        if(!self.is_being_knocked) self.vel.x = self.speed;
        self.last_direction_right = true;
    }
    
    pub fn jump(self: *EntityData) void {
        if(self.collisionsY[@intFromEnum(CollisionDirectionY.DOWN)]) self.vel.y = -10;
    }
    
    pub fn jumpMidAir(self: *EntityData, power: f32) void {
        self.vel.y = -power;
    }
    
    pub fn knockBack(self: *EntityData, right: bool, power: f32) void {
        self.is_being_knocked = true;
        self.vel.x += if(right) power else -power;
        self.vel.y -= 3;
    }
    
    pub fn getRect(self: *EntityData) rl.Rectangle {
        return rl.Rectangle{ .x = self.pos.x, .y = self.pos.y, .width = self.size.x, .height = self.size.y };
    }
    
    fn colliding(self: *EntityData, rect: rl.Rectangle) bool {
        return rl.checkCollisionRecs(self.getRect(), rect);
    }
    
    fn walljumpCollisionCheck(self: *EntityData, rect: rl.Rectangle) bool {
        return rl.checkCollisionRecs(self.getWallJumpHitBox(), rect);
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
    
    fn collideX(self: *EntityData, rect: rl.Rectangle, direction: CollisionDirectionX) void {
        self.collisionsX[@intFromEnum(direction)] = true;
        switch (direction) {
            CollisionDirectionX.LEFT => self.pos.x = rect.x + rect.width,
            CollisionDirectionX.RIGHT => self.pos.x = rect.x - self.size.x,
            else => {}
        }
    }
    
    fn collideY(self: *EntityData, rect: rl.Rectangle, direction: CollisionDirectionY) void {
        self.collisionsY[@intFromEnum(direction)] = true;
        self.vel.y = 0.1;
        switch (direction) {
            CollisionDirectionY.UP => self.pos.y = rect.y + rect.height,
            CollisionDirectionY.DOWN => self.pos.y = rect.y - self.size.y,
            else => {}
        }
    }
    
    fn manageSolidCollisions(self: *EntityData, rect: rl.Rectangle, horizontal: bool) void {
        if(self.colliding(rect) and horizontal) {
            self.collideX(rect, self.getDirectionX());
        } else if (self.colliding(rect) and !horizontal) {
            self.collideY(rect, self.getDirectionY());
        }
        
        if(horizontal and self.walljumpCollisionCheck(rect)) self.can_walljump = true;
    }
    
    pub fn manageCollisions(self: *EntityData, horizontal: bool) void {
        if(horizontal) self.collisionsX = [_]bool{ false } ** 2 else self.collisionsY = [_]bool{ false } ** 2;
        
        for (map.maps[main.savefile.current_map].data) |tile| {
            switch (tile.type) {
                .AIR,.CUSTOM,.TRIGGER => {},
                .SOLID => {
                    self.manageSolidCollisions(tile.dest_rect, horizontal);
                },
                .HAZARD => {
                    if(self.colliding(tile.dest_rect) and self.is_player) self.health -= 100; 
                }
            }
        }
        
        for (map.maps[main.savefile.current_map].objects) |*object| {
            if(!object.is_disabled) switch (object.obj_type) {
                .HAZARD => { if(self.colliding(object.rect) and self.is_player) self.health -= 100; },
                .SOLID => { self.manageSolidCollisions(object.rect, horizontal); },
                .ADVANCE_MAP => { if(self.colliding(object.rect) and self.is_player) map.advanceMap(); },
                .MILK => {
                    if(self.colliding(object.rect) and self.is_player) {
                        const m = map.maps[main.savefile.current_map];
                        for(m.milk_poses) |milk_pos_index| {
                            const milk_tile = m.data[milk_pos_index - 1];
                            if(!(milk_tile.dest_rect.x == object.rect.x and milk_tile.dest_rect.y == object.rect.y)) break;
                            m.data[milk_pos_index - 1].should_draw = false;
                            object.is_disabled = true;
                            main.savefile.milk += 1;
                            sav.saveSaveFile(&main.savefile) catch crsh.crash(.SAVE_ERROR);
                        }
                    }
                }
            };
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
    
    pub fn updateAnimations(self: *EntityData, animation_timer: *ti.Timer) void {
        animation_timer.update();
        if(animation_timer.called) self.handleBaseAnims();
        self.handleAnimEdgeCases();
    }
    
    pub fn getHit(self: *EntityData, damage: f32) void {
        self.health -= damage;
    }
    
    pub fn getWallJumpHitBox(self: *EntityData) rl.Rectangle {
        const thickness: f32 = 5;
        return .{ .x = self.pos.x - thickness, .y = self.pos.y, .width = self.size.x + thickness * 2, .height = self.size.y }; 
    }
};