const rl = @import("raylib");

pub const Timer = struct {
    duration: f32,
    start_time: f32 = 0,
    active: bool = false,
    repeat: bool = false,
    auto_start: bool = false,
    called: bool = false,
    grace: f32 = 0.0,
    
    pub fn init(self: *Timer) void {
        if(self.auto_start) self.activate();
    }
    
    pub fn activate(self: *Timer) void {
        self.active = true;
        self.start_time = @floatCast(rl.getTime());
    }
    
    pub fn deactivate(self: *Timer) void
    {
        self.active = false;
        self.start_time = 0;
        if(self.repeat) self.activate();
    }
    
    pub fn update(self: *Timer) void {
        if (self.active and (rl.getTime() - self.start_time >= self.duration)) {
            self.called = true;
            self.grace = 1;
            self.deactivate();
        }
        
        if(self.grace >= 0.0) self.grace -= 1;
        if(self.called and self.grace < 0.0) self.called = false;
    }
};