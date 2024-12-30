-- Simple example of adding a static sprite --
local spr = Sprite.new()
spr.load_texture('logoBumpin') -- helper function, starts in 'images'
spr.position = Vector2(300, 200) -- Position is a vector, there is no 'thing.x' in godot
spr.scale = Vector2(0.7, 0.7) -- Scale is a vector as well, works pretty much like haxe
add(spr)