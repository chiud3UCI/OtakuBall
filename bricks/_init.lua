--This file is in charge of including all of the brick files
--Some bricks are dependent on other bricks so I can't include
--them in any order

local filenames = 
	{"brick",
	 "normal",
	 "gold",
	 "platinum",
	 "metal",
	 "oneway",
	 "conveyor",
	 "copper",
	 "speed",
	 "funky",
	 "shooter",
	 "glass",
	 "detonator",
	 "switch",
	 "sequence",
	 "gate",
	 "alien",
	 "shove",
	 "factory",
	 "comet",
	 "onix",
	 "tiki",
	 "lasereye",
	 "boulder",
	 "launcher",
	 "twinlauncher",
	 "triggerdetonator",
	 "jumper",
	 "rainbow",
	 "slotmachine",
	 "green",
	 "parachute",
	 "shovedetonator",
	 "powerup",
	 "ghost",
	 "split",
	 "title"
	}

for i, v in ipairs(filenames) do
	require("bricks/"..v)
end

function activateAllBricks()
	initAllSlotMachines()
	for k, v in pairs(game.bricks) do
		v:activate()
	end
end