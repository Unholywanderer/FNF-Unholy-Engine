-- hmm this might be overly complicated
if Game.speaker ~= nil then
    local bleef = Character.new(gf.position, 'bf-funnier', true)
    gf.position = gf.position + Vector2(70, 0)
    bleef.position = gf.position - Vector2(220, -30)
    gf.flip_char()
    Game.speaker.offset = Game.speaker.offset + Vector2(75, 0)
    Game.speaker.flip_h = true
    add_char(bleef)
    bleef.reparent(gf)
    bleef.show_behind_parent = true
end