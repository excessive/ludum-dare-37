local slider    = {}
local slider_mt = {}

local function new(in_low, in_high, out_low, out_high)
	local t = {
		input = {
			low  = in_low,
			high = in_high,

		},
		output = {
			low  = out_low,
			high = out_high
		}
	}
	t = setmetatable(t, slider_mt)
	return t
end

slider_mt.__index = slider
slider_mt.__call  = function(_, ...)
	return new(...)
end

function slider:map(input)
	return (input - self.input.low) / (self.input.high - self.input.low) * (self.output.high - self.output.low) + self.output.low
end

return setmetatable({ new = new }, slider_mt)
