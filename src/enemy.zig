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
        .FLYING_TRIANGLE => Enemy{ .FLYING_TRIANGLE = FlyingTriangle{} },
    };
    
    enemy.setPos(enemy_pos);
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
    
    pub fn isAlive(self: *Enemy) bool {
        return switch (self.*) {
            .SIMPLE_TRIANGLE => |*s| s.data.health > 0,
            .ENRAGED_TRIANGLE => |*e| e.data.health > 0,
            .FLYING_TRIANGLE => |*f| f.data.health > 0,
        };
    }
    
    pub fn getHurtBox(self: *Enemy) rl.Rectangle {
        const buf: f32 = 8;
        return switch (self.*) {
            .SIMPLE_TRIANGLE => |*s| rl.Rectangle{ .x = s.data.pos.x + buf, .y = s.data.pos.y + buf, .width = s.data.size.x - buf * 2, .height = s.data.size.y - buf * 2 },
            .ENRAGED_TRIANGLE => |*e| rl.Rectangle{ .x = e.data.pos.x + buf, .y = e.data.pos.y + buf, .width = e.data.size.x - buf * 2, .height = e.data.size.y - buf * 2 },
            .FLYING_TRIANGLE => |*f| rl.Rectangle{ .x = f.data.pos.x + buf, .y = f.data.pos.y + buf, .width = f.data.size.x - buf * 2, .height = f.data.size.y - buf * 2 }
        };
    }
    
    pub fn setPos(self: *Enemy, pos: rl.Vector2) void {
        switch (self.*) {
            .SIMPLE_TRIANGLE => |*s| s.data.pos = pos,
            .ENRAGED_TRIANGLE => |*e| e.data.pos = pos,
            .FLYING_TRIANGLE => |*f| f.data.pos = pos,
        }
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

fn drawGameTriangle(data: ent.EntityData, color: rl.Color) void {
    const buf = 5;
    const outline_color = rl.colorBrightness(color, 0.3);
    const thickness = 3;
    
    const p1 = rl.Vector2{ .x = data.pos.x + data.size.x / 2, .y = data.pos.y + buf };
    const p2 = rl.Vector2{ .x = data.pos.x + buf, .y = data.pos.y + data.size.y - buf };
    const p3 = rl.Vector2{ .x = data.pos.x + data.size.x - buf, .y = data.pos.y + data.size.y - buf };
    
    const tinted_color_alpha: f32 = if(data.immunity_timer.active and !data.hit_timer.active) 0.6 else 1;
    
    rl.drawTriangle(p1, p2, p3, color.alpha(tinted_color_alpha));
    rl.drawLineEx(p1, p2, thickness, outline_color.alpha(tinted_color_alpha));
    rl.drawLineEx(p2, p3, thickness, outline_color.alpha(tinted_color_alpha));
    rl.drawLineEx(p1, p3, thickness, outline_color.alpha(tinted_color_alpha));
}

fn drawTriangleEyes(data: *ent.EntityData, angry: bool) void {
    const flip: f32 = if(data.last_direction_right) 1 else -1;
    const anger: f32 = if(angry) 48 else 0;
    const src = rl.Rectangle{ .x = 0, .y = anger, .width = 48 * flip, .height = 48 };
    rl.drawTexturePro(res.triangle_eyes, src, data.getRect(), .{ .x = 0, .y = 0 }, 0, data.color);
}

fn updatePlayerSwordCollisions(data: *ent.EntityData) void {
    if(data.getRect().checkCollision(main.player.data.getRect()) and !data.immunity_timer.active and main.player.data.pos.y < data.pos.y - pl.def_player_size.y / 2) {
        main.player.data.jumpMidAir(6);
        data.health -= 10;
        data.hit_timer.activate();
        data.immunity_timer.activate();
        main.player.data.immunity_timer.activate();
    }
    
    if(data.getRect().checkCollision(main.player.data.getRect()) and !main.player.data.immunity_timer.active) {
        main.player.data.health -= 10;
        main.player.data.immunity_timer.activate();
        main.player.data.hit_timer.activate();
        main.player.data.knockBack(data.pos.x < main.player.data.pos.x, 7);
        sha.shakeScreen(0.2, 3);
    }
    
    if(main.player.sword.checkSwordCollision(data.getRect()) and !data.immunity_timer.active) {
        data.health -= 10;
        data.hit_timer.activate();
        data.immunity_timer.activate();
        data.knockBack(main.player.data.pos.x < data.pos.x, 5);
    }
}

const SimpleTriangle = struct {
    data: ent.EntityData = .{ .size = .{ .x = 48, .y = 48 }, .health = 30, .speed = 1.5 },
    idle_direction_right: bool = true,
    
    pub fn update(self: *SimpleTriangle) void {
        if(self.data.collisionsX[0] or self.data.collisionsX[1]) self.idle_direction_right = !self.idle_direction_right;
        if(self.idle_direction_right) self.data.moveRight() else self.data.moveLeft();
        
        self.data.update();
        updatePlayerSwordCollisions(&self.data);
    }
    
    pub fn draw(self: *SimpleTriangle) void {
        drawGameTriangle(self.data, .blue);
        drawTriangleEyes(&self.data, false);
    }
};

const EnragedTriangle = struct {
    data: ent.EntityData = .{ .size = .{ .x = 48, .y = 48 }, .health = 30, .speed = 1.2, .gravity = 0, .terminal_velocity = 0 },
    idle_direction_right: bool = true,
    
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
        updatePlayerSwordCollisions(&self.data);
    }
    
    pub fn draw(self: *EnragedTriangle) void {
        drawGameTriangle(self.data, .orange);
        drawTriangleEyes(&self.data, self.playerClose());
    }
};

const FlyingTriangle = struct {
    data: ent.EntityData = .{ .size = .{ .x = 64, .y = 64 }, .health = 40, .speed = 1.7 },
    
    pub fn update(self: *FlyingTriangle) void {
        self.data.update();
        updatePlayerSwordCollisions(&self.data);
    }
    
    pub fn draw(self: *FlyingTriangle) void {
        drawGameTriangle(self.data, .green);
        drawTriangleEyes(&self.data, false);
    }
};