love.conf = function(t)
   t.gammacorrect = false
   t.title, t.identity = "repl-example", "repl-example"
   t.modules.joystick = false
   t.modules.physics = false
   t.window.width = 1280-- 720 * 21 / 9 -- 1280 -- 1920
   t.window.height = 720 -- 720 -- 1080
   t.window.vsync = true
   t.window.resizable = true
   t.window.fullscreen = true
   t.version = "11.5"
end
