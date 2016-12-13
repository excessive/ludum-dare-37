local cpml = require"cpml"

local dialog = require "dialog"
local moment = require "moment"
local cutscene = require "cutscene"

local hero_eye_level = -1.5
local boss_eye_level = -7.5

local l = require "i18n"()
l:set_fallback("en")
l:set_locale(_G.PREFERENCES.language)
l:load(string.format("assets/locales/%s.lua", _G.PREFERENCES.language))

local function camera_info(player,boss)
	boss.direction = boss.orientation * cpml.vec3.unit_y
	return {
		hero = {
			position = {
				close_up = player.position + player.direction * 0.25,
				face = player.position + player.direction * 0.75,
				body = player.position + player.direction * 2,
				behind =  player.position + player.direction * -2,
				--left = player.position + cpml.vec3.cross(cpml.vec3(), player.direction, cpml.vec3.unit_z)*2,
				--right = player.position + cpml.vec3.cross(cpml.vec3(), player.position, cpml.vec3.unit_z)*-2,
				--back =  player.position + player.direction * -2,
				--front =  player.position + player.direction * 2,
			},
			orientation = {
				front = player.orientation,
				right = player.orientation * cpml.quat.rotate(math.pi/2,cpml.vec3.unit_z),
				left = player.orientation * cpml.quat.rotate(math.pi,cpml.vec3.unit_z),
				back = player.orientation * cpml.quat.rotate(math.pi*3/4,cpml.vec3.unit_z),
			},
		},
		boss = {
			position = {
				close_up = boss.position + boss.direction * -2,
				face = boss.position + boss.direction * -4,
				body = boss.position + boss.direction * -8,
			},
			orientation = {
				front = boss.orientation,
				right = boss.orientation * cpml.quat.rotate(math.pi/2,cpml.vec3.unit_z),
				left = boss.orientation * cpml.quat.rotate(math.pi,cpml.vec3.unit_z),
				back = boss.orientation * cpml.quat.rotate(math.pi*3/4,cpml.vec3.unit_z),
			},
		}
	}
end

return {
	-- SCENE 1
	function(camera,player,boss)
		local cutscene = cutscene.new{camera=camera}

		local i = camera_info(player,boss)

		cutscene:addMoment(moment.new{
			position = i.hero.position.close_up,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,-0.25),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("1_01"),
			audio = "assets/locales/en/1_01.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("1_02"),
			audio = "assets/locales/en/1_02.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("1_03"),
			audio = "assets/locales/en/1_03.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("1_04"),
			audio = "assets/locales/en/1_04.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("1_05"),
			audio = "assets/locales/en/1_05.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("1_06"),
			audio = "assets/locales/en/1_06.ogg",
		})

		--cutscene:addMoment(moment.new{
		--	position = i.hero.position.behind,
		--	orientation = i.hero.orientation.left,
		--	offset = cpml.vec3(0,0,hero_eye_level),
		--	orbit_offset = cpml.vec3(0,0,0),
		--})

		return cutscene

	end,
	-- SCENE 2
	function(camera,player,boss)
		local cutscene = cutscene.new{camera=camera}

		local i = camera_info(player,boss)

		cutscene:addMoment(moment.new{
			position = i.boss.position.close_up,
			orientation = i.boss.orientation.front,
			offset = cpml.vec3(0,0,boss_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("2_01"),
			audio = "assets/locales/en/2_01.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("2_02"),
			audio = "assets/locales/en/2_02.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.boss.position.body,
			orientation = i.boss.orientation.front,
			offset = cpml.vec3(0,0,boss_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("2_03"),
			audio = "assets/locales/en/2_03.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.face,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("2_04"),
			audio = "assets/locales/en/2_04.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.close_up,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("2_05"),
			audio = "assets/locales/en/2_05.ogg",
		})

		return cutscene

	end,
	-- SCENE 3
	function(camera,player,boss)
		local cutscene = cutscene.new{camera=camera}

		local i = camera_info(player,boss)

		cutscene:addMoment(moment.new{
			position = i.boss.position.body,
			orientation = i.boss.orientation.front,
			offset = cpml.vec3(0,0,boss_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("3_01"),
			audio = "assets/locales/en/3_01.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("3_02"),
			audio = "assets/locales/en/3_02.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.boss.position.face,
			orientation = i.boss.orientation.front,
			offset = cpml.vec3(0,0,boss_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("3_03"),
			audio = "assets/locales/en/3_03.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.boss.position.close_up,
			orientation = i.boss.orientation.front,
			offset = cpml.vec3(0,0,boss_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("3_04"),
			audio = "assets/locales/en/3_04.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.body,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("3_05"),
			audio = "assets/locales/en/3_05.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.face,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("3_06"),
			audio = "assets/locales/en/3_06.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.close_up,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("3_07"),
			audio = "assets/locales/en/3_07.ogg",
		})

		return cutscene

	end,
	-- SCENE 4
	function(camera,player,boss)
		local cutscene = cutscene.new{camera=camera}

		local i = camera_info(player,boss)

		cutscene:addMoment(moment.new{
			position = i.boss.position.face,
			orientation = i.boss.orientation.front,
			offset = cpml.vec3(0,0,boss_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("4_01"),
			audio = "assets/locales/en/4_01.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("4_02"),
			audio = "assets/locales/en/4_02.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.body,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("4_03"),
			audio = "assets/locales/en/4_03.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("4_04"),
			audio = "assets/locales/en/4_04.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("4_05"),
			audio = "assets/locales/en/4_05.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.face,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("4_06"),
			audio = "assets/locales/en/4_06.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.close_up,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("4_07"),
			audio = "assets/locales/en/4_07.ogg",
		})

		return cutscene

	end,
	-- SCENE 5
	function(camera,player,boss)
		local cutscene = cutscene.new{camera=camera}

		local i = camera_info(player,boss)

		cutscene:addMoment(moment.new{
			position = i.boss.position.body,
			orientation = i.boss.orientation.front,
			offset = cpml.vec3(0,0,boss_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("5_01"),
			audio = "assets/locales/en/5_01.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.boss.position.face,
			orientation = i.boss.orientation.front,
			offset = cpml.vec3(0,0,boss_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("5_02"),
			audio = "assets/locales/en/5_02.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.boss.position.close_up,
			orientation = i.boss.orientation.front,
			offset = cpml.vec3(0,0,boss_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("5_03"),
			audio = "assets/locales/en/5_03.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.face,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("5_04"),
			audio = "assets/locales/en/5_04.ogg",
		})

		return cutscene

	end,
	-- SCENE 6
	function(camera,player,boss)
		local cutscene = cutscene.new{camera=camera}

		local i = camera_info(player,boss)

		cutscene:addMoment(moment.new{
			position = i.hero.position.close_up,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("6_01"),
			audio = "assets/locales/en/6_01.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.face,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("6_02"),
			audio = "assets/locales/en/6_02.ogg",
		})

		cutscene:addMoment(moment.new{
			position = i.hero.position.body,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		local pos
		pos = player.position + player.direction * 4
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-2),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_03"),
			audio = "assets/locales/en/6_03.ogg",
		})
		pos = player.position + player.direction * 6
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-4),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_04"),
			audio = "assets/locales/en/6_04.ogg",
		})
		pos = player.position + player.direction * 8
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-6),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_05"),
			audio = "assets/locales/en/6_05.ogg",
		})
		pos = player.position + player.direction * 10
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-8),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_06"),
			audio = "assets/locales/en/6_06.ogg",
		})
		pos = player.position + player.direction * 12
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-10),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_07"),
			audio = "assets/locales/en/6_07.ogg",
		})
		pos = player.position + player.direction * 14
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-12),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_08"),
			audio = "assets/locales/en/6_08.ogg",
		})
		pos = player.position + player.direction * 16
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-14),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_09"),
			audio = "assets/locales/en/6_09.ogg",
		})
		pos = player.position + player.direction * 18
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-16),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_10"),
			audio = "assets/locales/en/6_10.ogg",
		})
		pos = player.position + player.direction * 20
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-18),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_11"),
			audio = "assets/locales/en/6_11.ogg",
		})
		pos = player.position + player.direction * 22
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-20),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_12"),
			audio = "assets/locales/en/6_12.ogg",
		})
		pos = player.position + player.direction * 24
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-22),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_13"),
			audio = "assets/locales/en/6_13.ogg",
		})
		pos = player.position + player.direction * 26
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-24),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_14"),
			audio = "assets/locales/en/6_14.ogg",
		})

		-- LOL WHY DO YOU WANT 6_15 ANYWAY?
		pos = player.position + player.direction * 28
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-26),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_16"),
			audio = "assets/locales/en/6_16.ogg",
		})
		pos = player.position + player.direction * 30
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-28),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_17"),
			audio = "assets/locales/en/6_17.ogg",
		})
		pos = player.position + player.direction * 32
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-30),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_18"),
			audio = "assets/locales/en/6_18.ogg",
		})
		pos = player.position + player.direction * 34
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-32),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_19"),
			audio = "assets/locales/en/6_19.ogg",
		})
		pos = player.position + player.direction * 36
		cutscene:addMoment(moment.new{
			position = pos,
			orientation = i.hero.orientation.front,
			offset = cpml.vec3(0,0,hero_eye_level-34),
			orbit_offset = cpml.vec3(0,0,0),
		})
		cutscene:addDialog(dialog.new{
			text=l:get("6_20"),
			audio = "assets/locales/en/6_20.ogg",
		})

		return cutscene

	end,
		-- SCENE 7
	function(camera,player,boss)
		local cutscene = cutscene.new{camera=camera}

		cutscene:addDialog(dialog.new{
			text=l:get("7_01"),
			audio = "assets/locales/en/7_01.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("7_02"),
			audio = "assets/locales/en/7_02.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("7_03"),
			audio = "assets/locales/en/7_03.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("7_04"),
			audio = "assets/locales/en/7_04.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("7_05"),
			audio = "assets/locales/en/7_05.ogg",
		})

		cutscene:addDialog(dialog.new{
			text=l:get("7_06"),
			audio = "assets/locales/en/7_06.ogg",
		})

		return cutscene

	end,
	-- Meme cutscene
	function(camera,player,boss)

		local cutscene = cutscene.new{camera=camera}

		local new_position = player.position + player.direction * 0.75
		local new_orientation = player.orientation-- * cpml.quat.rotate(math.pi,cpml.vec3.unit_z)

		cutscene:addMoment(moment.new{
			position = new_position,
			orientation = new_orientation,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("8_01"),
			audio = "assets/locales/en/meme.ogg",
		})

		new_position = player.position + player.direction * 0.25

		cutscene:addMoment(moment.new{
			position = new_position,
			orientation = new_orientation,
			offset = cpml.vec3(0,0,hero_eye_level),
			orbit_offset = cpml.vec3(0,0,0),
		})

		cutscene:addDialog(dialog.new{
			text=l:get("8_02"),
			audio = "assets/locales/en/meme_response.ogg",
		})

		return cutscene

	end,
	-- Yes
	function(camera,player,boss)
		local cutscene = cutscene.new{camera=camera}
		cutscene:addDialog(dialog.new{
			text=l:get("9_01"),
			audio = "assets/locales/en/meme_response.ogg",
		})
		return cutscene
	end,
}
