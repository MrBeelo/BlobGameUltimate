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

const SimpleTriangle = struct {
    data: ent.EntityData = .{ .size = .{ .x = 48, .y = 48 }, .health = 30, .speed = 1.5 },
    idle_direction_right: bool = true,
    
    pub fn update(self: *SimpleTriangle) void {
        if(self.data.collisionsX[0] or self.data.collisionsX[1]) self.idle_direction_right = !self.idle_direction_right;
        if(self.idle_direction_right) self.data.moveRight() else self.data.moveLeft();
        
        self.data.update();
    }
    
    pub fn draw(self: *SimpleTriangle) void {
        const data = self.data;
        rl.drawTriangle(.{ .x = data.pos.x + data.size.x / 2, .y = data.pos.y }, .{ .x = data.pos.x, .y = data.pos.y + data.size.y }, 
            .{ .x = data.pos.x + data.size.x, .y = data.pos.y + data.size.y }, .blue);
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
    }
    
    pub fn draw(self: *EnragedTriangle) void {
        const data = self.data;
        rl.drawTriangle(.{ .x = data.pos.x + data.size.x / 2, .y = data.pos.y }, .{ .x = data.pos.x, .y = data.pos.y + data.size.y }, 
            .{ .x = data.pos.x + data.size.x, .y = data.pos.y + data.size.y }, if(self.data.last_direction_right) .orange else .yellow);
    }
};

const FlyingTriangle = struct {
    data: ent.EntityData = .{ .size = .{ .x = 64, .y = 64 }, .health = 40, .speed = 1.7 },
    
    pub fn update(self: *FlyingTriangle) void {
        self.data.update();
    }
    
    pub fn draw(self: *FlyingTriangle) void {
        const data = self.data;
        rl.drawTriangle(.{ .x = data.pos.x + data.size.x / 2, .y = data.pos.y }, .{ .x = data.pos.x, .y = data.pos.y + data.size.y }, 
            .{ .x = data.pos.x + data.size.x, .y = data.pos.y + data.size.y }, .green);
    }
};