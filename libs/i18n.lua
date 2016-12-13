local i18n = {}
i18n.__index = i18n
i18n.__call  = function(self, key)
	return self:get(key)
end

local d = console and console.d or print
local i = console and console.i or print
local e = console and console.e or print

local ok, memoize = pcall(require, "memoize")
if not ok then
	i("Memoize not available. Using passthrough.")
	memoize = function(f)
		return f
	end
end

local function new()
	return setmetatable({
		locale   = false,
		fallback = false,
		strings  = {},
	}, i18n)
end

function i18n:load(file)
	if not love.filesystem.isFile(file) then
		return false
	end
	local locale
	local bork = function(msg)
		e(string.format("Error loading locale %s: %s", file, tostring(msg)))
		return false
	end
	local ok, msg = pcall(function()
		local ok, chunk = pcall(love.filesystem.load, file)
		if not ok then
			return bork(chunk)
		end
		local data = chunk()

		-- Sanity check!
		assert(type(data)           == "table")
		assert(type(data.locale)    == "string")
		assert(type(data.name)      == "string")
		assert(type(data.audio_dir) == "string")
		assert(type(data.quotes)    == "table")
		assert(#data.quotes         == 2)
		assert(type(data.strings)   == "table")

		locale = data
	end)
	if not ok then
		return bork(msg)
	end

	locale.strings._audio_dir   = locale.audio_dir
	locale.strings._language    = locale.name
	self.strings[locale.locale] = locale.strings

	i(string.format("Loaded locale \"%s\" from \"%s\"", locale.locale, file))
	self:invalidate_cache()

	return true
end

function i18n:set_fallback(locale)
	self:invalidate_cache()
	self.fallback = locale
end

function i18n:set_locale(locale)
	self:invalidate_cache()
	self.locale = locale
end

function i18n:get_locale()
	return self.locale, self.strings[self.locale]._language
end

-- Returns 4 values: text, duration, audio, fallback.
-- - Text is mandatory and is guaranteed to be a string.
-- - Duration is mandatory and is guaranteed to be a number.
-- - Audio is optional and will return the full path to the audio clip for the
--   key. If missing, will return false.
-- - Fallback will be true if the key was missing from your selected language,
--   but present in the fallback locale.
local function gen_get()
	return function(self, key)
		assert(type(key) == "string", "Expected key of type 'string', got type '"..type(key).."'")

		local lang     = self.strings[self.locale]
		local fallback = false

		-- Language doesn't exist or key doesn't exist in language
		if not lang or type(lang) == "table" and not lang[key] then
			lang = self.strings[self.fallback]
			fallback = true
		end

		-- Language exists, key exists, text exists
		if lang and type(lang[key]) == "table" and type(lang[key].text) == "string" then
			local value = lang[key]
			local sfx   = false

			-- Do not return audio for different languages if we're falling back.
			-- The voice mismatch would be strange, subtitles-only is better.
			if not fallback then
				sfx = value.audio and string.format("%s/%s", lang._audio_dir, value.audio) or false
			end

			return value.text, value.duration or 5, sfx, fallback
		else
			d(string.format(
				"String \"%s\" missing from locale %s and fallback (%s)",
				key, self.locale, self.fallback
			))
			return key, 5, false, false
		end
	end
end

function i18n:invalidate_cache()
	self._get_internal = gen_get()
end

function i18n:get(key)
	if not self._get_internal then
		self:invalidate_cache()
	end
	return memoize(self._get_internal)(self, key)
end

return setmetatable({new=new},{__call=function(_,...) return new(...) end})
