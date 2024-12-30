-- Another simple image, but mess with layers
local testSpr = Sprite.new()
testSpr.position = gf.position + Vector2(50, 100)
testSpr.load_texture('PIKMIN/pik-idle')
add(testSpr)
move(testSpr, get_layer(gf))