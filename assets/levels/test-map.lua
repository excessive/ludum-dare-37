-- Dickburger 2016.8.27 export
local t = {
	version = 2016827,
	objects = {
		{
			name = "Sky",
			path = "assets/models/sky.iqm",
			rigid_body = false,
			mass = 0,
			elasticity = 0.0,
			actor = false,
			ghost = false,
			visible = true,
			position = { 0.0, 0.0, 0.0 },
			orientation = { 0.0, 0.0, 0.0, 1.0 },
			scale = { 1.0, 1.0, 1.0 },
			sky = true,
			no_shadow = true
		},
		{
			name = "birds 1",
			position = { 20, -14, 8 },
			sound = "assets/sfx/birdsong_a.wav"
		},
		{
			name = "birds 2",
			position = { -26, -4, 1.2 },
			sound = "assets/sfx/birdsong_b.wav"
		},
		{
			name = "Stage",
			path = "assets/models/StagePolish0.11.iqm",
			textures = {
				Column  = "assets/textures/column.png",
				Stage      = "assets/textures/Stage.png",
				Grid       = "assets/textures/grid.png",
				Rock       = "assets/textures/rock.png",
				Water      = "assets/textures/Water.png",
				Wood       = "assets/textures/wood.png",
				Plant      = "assets/textures/grassThing.png",
			},
			rigid_body = true,
			mass = 0,
			elasticity = 0.0,
			actor = true,
			ghost = false,
			visible = true,
			position = { 0.0, 0.0, -0.02 },
			orientation = { 0.0, 0.0, 0.0, 1.0 },
			scale = { 1.0, 1.0, 1.0 }
		},
	},
}

return t
