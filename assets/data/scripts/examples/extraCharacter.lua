local char = Character.new(boyfriend.position + Vector2(240, -325), 'pico', true)
add_char(char) -- helper function only for Gameplay, adds a char and lets it dance to the beat/hold timer shit automatically

function goodNoteHit(id, dir, type)
    char.sing(dir) -- sing when bf hits a note
end

function goodSustainPress(id, dir, type)
    char.sing(dir, '', false) -- sing when bf hits a sustain
end
