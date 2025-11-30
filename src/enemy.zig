const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const crsh = @import("crash.zig");
const ti = @import("timer.zig");
const ent = @import("entity.zig");
const pl = @import("player.zig");
const sha = @import("shake.zig");
const res = @import("resources.zig");

pub var enemies: std.array_list.Managed(Enemy) = undefined;

pub fn initEnemies() void {
    enemies = std.array_list.Managed(Enemy).init(main.allocator);
}

pub fn deinitEnemies() void {
    enemies.deinit();
}

pub fn summonEnemy(enemy_type: EnemyType, enemy_pos: rl.Vector2) void {
    var enemy = switch (enemy_type) {
        .SIMPLE_TRIANGLE => Enemy{ .SIMPLE_TRIANGLE = SimpleTriangle{} },
        .ENRAGED_TRIANGLE => Enemy{ .ENRAGED_TRIANGLE = EnragedTriangle{} },
        .FLYING_TRIANGLE => Enemy{ .FLYING_TRIANGLE = FlyingTriangle{ .set_down_pos = enemy_pos.y } },
    };
    
    enemy.getData().pos = enemy_pos;
    enemies.append(enemy) catch crsh.crash(.OUT_OF_MEMORY);
}

pub const EnemyType = enum {
    SIMPLE_TRIANGLE,
    ENRAGED_TRIANGLE,
    FLYING_TRIANGLE
};

pub const Enemy = union(EnemyType) {
    SIMPLE_TRIANGLE: SimpleTriangle,
    ENRAGED_TRIANGLE: EnragedTriangle,
    FLYING_TRIANGLE: FlyingTriangle,
    
    pub fn getData(self: *Enemy) *ent.EntityData {
        return switch (self.*) {
            .SIMPLE_TRIANGLE => |*s| &s.data,
            .ENRAGED_TRIANGLE => |*e| &e.data,
            .FLYING_TRIANGLE => |*f| &f.data,
        };
    }
     
    pub fn update(self: *Enemy) void {
        switch (self.*) {
            .SIMPLE_TRIANGLE => |*s| s.update(),
            .ENRAGED_TRIANGLE => |*e| e.update(),
            .FLYING_TRIANGLE => |*f| f.update(),
        }
    }
    
    pub fn draw(self: *Enemy) void {
        switch (self.*) {
            .SIMPLE_TRIANGLE => |*s| s.draw(),
            .ENRAGED_TRIANGLE => |*e| e.draw(),
            .FLYING_TRIANGLE => |*f| f.draw(),
        }
    }
};

fn rotatePoint(point: rl.Vector2, center: rl.Vector2, rot: f32) rl.Vector2 {
    const sine = @sin(rot * std.math.pi / 180);
    const cosine = @cos(rot * std.math.pi / 180);
    
    const init_x = point.x - center.x;
    const init_y = point.y - center.y;
    
    const new_x = cosine * init_x - sine * init_y;
    const new_y = sine * init_x + cosine * init_y;
    
    return rl.Vector2{ .x = new_x + center.x, .y = new_y + center.y }; 
}

fn drawGameTriangle(data: ent.EntityData, color: rl.Color, rotation: f32, equilateral: bool) void {
    const buf = 5;
    const outline_color = rl.colorBrightness(color, -0.2);
    const thickness = 4;
    
    const p1 = rl.Vector2{ .x = data.pos.x + data.size.x / 2, .y = data.pos.y + buf + if(equilateral) data.size.y - data.size.y * @sqrt(0.75) else 0 };
    const p2 = rl.Vector2{ .x = data.pos.x + buf, .y = data.pos.y + data.size.y - buf };
    const p3 = rl.Vector2{ .x = data.pos.x + data.size.x - buf, .y = data.pos.y + data.size.y - buf };
    
    const center = rl.Vector2{ .x = (p1.x + p2.x + p3.x) / 3, .y = (p1.y + p2.y + p3.y) / 3 }; 
    
    const rp1 = rotatePoint(p1, center, rotation);
    const rp2 = rotatePoint(p2, center, rotation);
    const rp3 = rotatePoint(p3, center, rotation);
    
    const tinted_color_alpha: f32 = if(data.immunity_timer.active and !data.hit_timer.active) 0.6 else 1;
    
    const fully_tinted_color = if(data.hit_timer.active) rl.Color.white else color.alpha(tinted_color_alpha);
    const fully_tinted_outline_color = if(data.hit_timer.active) rl.Color.white else outline_color.alpha(tinted_color_alpha);
    
    rl.drawTriangle(rp1, rp2, rp3, fully_tinted_color);
    rl.drawLineEx(rp1, rp2, thickness, fully_tinted_outline_color);
    rl.drawLineEx(rp2, rp3, thickness, fully_tinted_outline_color);
    rl.drawLineEx(rp1, rp3, thickness, fully_tinted_outline_color);
}

fn drawTriangleEyes(data: *ent.EntityData, angry: bool, for_equilateral: bool) void {
    const flip: f32 = if(data.last_direction_right) 1 else -1;
    const anger: f32 = if(angry) 48 else 0;
    const offset: f32 = if(for_equilateral) 3 else 0;
    const src = rl.Rectangle{ .x = 0, .y = anger - offset, .width = 48 * flip, .height = 48 };
    rl.drawTexturePro(res.triangle_eyes, src, data.getRect(), .{ .x = 0, .y = 0 }, 0, data.color);
}

fn updatePlayerSwordCollisions(hurt_box: rl.Rectangle, data: *ent.EntityData, is_knockable: bool) void {
    if(hurt_box.checkCollision(main.player.data.getRect()) and !data.immunity_timer.active and main.player.data.pos.y < data.pos.y - pl.def_player_size.y / 2) {
        main.player.data.jumpMidAir(6);
        data.health -= 10;
        data.hit_timer.activate();
        data.immunity_timer.activate();
        main.player.data.immunity_timer.activate();
        sha.shakeScreen(0.1, 2);
    }
    
    if(hurt_box.checkCollision(main.player.data.getRect()) and !main.player.data.immunity_timer.active) {
        main.player.data.health -= 10;
        main.player.data.immunity_timer.activate();
        main.player.data.hit_timer.activate();
        main.player.data.knockBack(data.pos.x < main.player.data.pos.x, 7);
        sha.shakeScreen(0.2, 4);
    }
    
    if(main.player.sword.checkSwordCollision(hurt_box) and !data.immunity_timer.active) {
        data.health -= 10;
        data.hit_timer.activate();
        data.immunity_timer.activate();
        if(is_knockable) data.knockBack(main.player.data.pos.x < data.pos.x, 5);
        sha.shakeScreen(0.1, 2);
    }
}

const SimpleTriangle = struct {
    data: ent.EntityData = .{ .size = .{ .x = 48, .y = 48 }, .health = 30, .speed = 1.5 },
    idle_direction_right: bool = true,
    
    pub fn getHurtBox(self: *SimpleTriangle) rl.Rectangle {
        const buf = 10;
        return rl.Rectangle{ .x = self.data.pos.x + buf, .y = self.data.pos.y + buf, .width = self.data.size.x - buf * 2, .height = self.data.size.y - buf * 2 };
    }
    
    pub fn update(self: *SimpleTriangle) void {
        if(self.data.collisionsX[0] or self.data.collisionsX[1]) self.idle_direction_right = !self.idle_direction_right;
        if(self.idle_direction_right) self.data.moveRight() else self.data.moveLeft();
        
        self.data.update();
        updatePlayerSwordCollisions(self.getHurtBox(), &self.data, true);
    }
    
    pub fn draw(self: *SimpleTriangle) void {
        drawGameTriangle(self.data, .blue, 0, false);
        drawTriangleEyes(&self.data, false, false);
        if(main.f3) rl.drawRectangleLinesEx(self.getHurtBox(), 3, .red);
    }
};

const EnragedTriangle = struct {
    data: ent.EntityData = .{ .size = .{ .x = 48, .y = 48 }, .health = 30, .speed = 1.2 },
    idle_direction_right: bool = true,
    
    pub fn getHurtBox(self: *EnragedTriangle) rl.Rectangle {
        const buf = 10;
        return rl.Rectangle{ .x = self.data.pos.x + buf, .y = self.data.pos.y + buf, .width = self.data.size.x - buf * 2, .height = self.data.size.y - buf * 2 };
    }
    
    pub fn playerClose(self: *EnragedTriangle) bool {
        const player = main.player.data;
        const radius: f32 = 250;
        if(player.pos.x - self.data.pos.x >= -radius 
            and player.pos.x - self.data.pos.x < radius 
            and player.pos.y - self.data.pos.y >= -radius / 3
            and player.pos.y - self.data.pos.y < radius / 3
            and !self.data.immunity_timer.active) return true;
        return false;
    }
    
    pub fn update(self: *EnragedTriangle) void {
        if(self.data.collisionsX[0] or self.data.collisionsX[1]) {
            if(self.playerClose()) self.data.jump() else self.idle_direction_right = !self.idle_direction_right;
        }
        
        if(self.idle_direction_right) self.data.moveRight() else self.data.moveLeft();
        
        if(self.playerClose()) {
            self.data.speed = 2.2;
            if(self.data.pos.x >= main.player.data.pos.x) self.data.moveLeft() else self.data.moveRight();
        } else {
            self.data.speed = 1.2;
        }
        
        self.data.update();
        updatePlayerSwordCollisions(self.getHurtBox(), &self.data, true);
    }
    
    pub fn draw(self: *EnragedTriangle) void {
        drawGameTriangle(self.data, .orange, 0, false);
        drawTriangleEyes(&self.data, self.playerClose(), false);
        if(main.f3) rl.drawRectangleLinesEx(self.getHurtBox(), 3, .red);
    }
};

const FlyingTriangle = struct {
    data: ent.EntityData = .{ .size = .{ .x = 64, .y = 64 }, .health = 40, .speed = 1.7, .gravity = 0, .terminal_velocity = 0 },
    cycle_direction_up: bool = true,
    set_down_pos: f32,
    is_angry: bool = false,
    rotation: f32 = 0,
    
    pub fn getHurtBox(self: *FlyingTriangle) rl.Rectangle {
        const buf = 10;
        return rl.Rectangle{ .x = self.data.pos.x + buf, .y = self.data.pos.y + buf, .width = self.data.size.x - buf * 2, .height = self.data.size.y - buf * 2 };
    }
    
    pub fn playerClose(self: *FlyingTriangle) bool {
        const player = main.player.data;
        const radius: f32 = 250;
        if(player.pos.x - self.data.pos.x >= -radius 
            and player.pos.x - self.data.pos.x < radius 
            and player.pos.y - self.data.pos.y >= -radius / 3
            and player.pos.y - self.data.pos.y < radius / 3
            and !self.data.immunity_timer.active) return true;
        return false;
    }
    
    pub fn update(self: *FlyingTriangle) void {
        self.data.last_direction_right = if(main.player.data.pos.x < self.data.pos.x) false else true;
        if(self.cycle_direction_up and self.set_down_pos - 100 > self.data.pos.y) self.cycle_direction_up = !self.cycle_direction_up;
        if(!self.cycle_direction_up and self.set_down_pos < self.data.pos.y) self.cycle_direction_up = !self.cycle_direction_up;
        
        if(self.data.collisionsY[0]) {
            self.cycle_direction_up = !self.cycle_direction_up;
        } else if(self.data.collisionsY[1]) {
            self.cycle_direction_up = !self.cycle_direction_up;
            self.set_down_pos = self.data.pos.y;
        }
        
        if(self.cycle_direction_up) self.data.moveUp() else self.data.moveDown();
        self.rotation += main.dt * 2;
        
        self.data.update();
        updatePlayerSwordCollisions(self.getHurtBox(), &self.data, false);
    }
    
    pub fn draw(self: *FlyingTriangle) void {
        drawGameTriangle(self.data, .green, self.rotation, true);
        drawTriangleEyes(&self.data, self.playerClose(), true);
        if(main.f3) rl.drawRectangleLinesEx(self.getHurtBox(), 3, .red);
    }
};