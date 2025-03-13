-- hmm this might be overly complicated
if Game.speaker ~= nil then
    local bleef = Character.new(gf.position, 'bf-funnier', true)
    gf.position = gf.position + Vector2(70, 0)
    bleef.position = gf.position - Vector2(220, -30)
    if gf.cur_char:find('nene') then
        bleef.position = gf.position - Vector2(220, -50)
    end
    gf.flip_char()
    Game.speaker.offset = Game.speaker.offset + Vector2(75, 0)
    if gf.cur_char ~= 'nene' then Game.speaker.flip_h = true end
    add_char(bleef)
    bleef.reparent(gf)
    bleef.use_parent_material = true
    bleef.show_behind_parent = true
end