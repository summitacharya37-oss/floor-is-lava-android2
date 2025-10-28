function love.conf(t)
    t.identity = "floorislava"
    t.version = "11.4"
    t.console = false
    
    -- Window settings
    t.window.title = "Floor is Lava"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.fullscreen = false
    
    -- Mobile optimizations
    t.modules.joystick = false
    t.modules.physics = false
    
    -- Enable touch
    t.modules.touch = true
end