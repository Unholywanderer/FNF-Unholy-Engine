--broken womp
--[[-- same as extraChar example but this follows a chart
local leJson = parse_json('songs/stress/charts/pico-speaker') -- parse_json starts in 'assets/'
local funny = Chart.new()

local char = Character.new(boyfriend.position + Vector2(240, -325), 'pico', true)
add_char(char)
char.chart = funny.load_chart(leJson) -- has second param for specifying the chart type (assumes legacy by default)
]]