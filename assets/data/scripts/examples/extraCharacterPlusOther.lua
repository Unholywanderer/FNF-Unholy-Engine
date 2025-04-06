if variant == 'bf' and file_exists('songs/'.. song_root ..'/chart.json') then
    -- same as extraChar example but this follows a chart
    local leJson = parse_json('songs/'..song_root..'/chart') -- parse_json starts in 'assets/'
    local funny = Chart.new()

    local char = Character.new(boyfriend.position - Vector2(650, 325), 'pico')
    char.flip_char()
    add_char(char)

    local le_chart = funny.load_chart(leJson, 'v_slice', 'hard') -- has second param for specifying the chart type 
    -- legacy, psych_v1, v_slice fps_plus, codename, maru, osu (assumes legacy by default)

    -- then only get the must hit notes from the chart
    char.chart = funny.get_must_hits(le_chart)
    Conductor.add_audio(3, 'Voices-player', 2)
end