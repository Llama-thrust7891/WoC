x=00025000
y=00025000

local Group_USA_NASAM = {
	["visible"] = false,
	["taskSelected"] = true,
    ["lateActivation"] = true,
	["route"] = 
	{
	}, -- end of ["route"]
	--["groupId"] = 2,
	["tasks"] = 
	{
	}, -- end of ["tasks"]
	["hidden"] = false,
	["units"] = 
	{
		[1] = 
		{
			["type"] = "Hawk pcp",
			["transportable"] = 
			{
				["randomTransportable"] = false,
			}, -- end of ["transportable"]
			--["unitId"] = 2,
			["skill"] = "Average",
			["y"] = x+100,
			["x"] = y+100,
			["name"] = "Group_USA_Hawk_CP",
			["playerCanDrive"] = true,
			["heading"] = 0.28605144170571,
		}, -- end of [1]
        [2] = 
		{
			["type"] = "Hawk sr",
			["transportable"] = 
			{
				["randomTransportable"] = false,
			}, -- end of ["transportable"]
			["unitId"] = 2,
			["skill"] = "Average",
			["y"] = x+100,
			["x"] = y+110,
			["name"] = "Group_USA_Hawk__SR_Radar",
			["playerCanDrive"] = true,
			["heading"] = 0.28605144170571,
		}, -- end of [2]
        [3] = 
		{
			["type"] = "Hawk tr",
			["transportable"] = 
			{
				["randomTransportable"] = false,
			}, -- end of ["transportable"]
			["unitId"] = 2,
			["skill"] = "Average",
			["y"] = x+100,
			["x"] = y+120,
			["name"] = "Group_USA_Hawk_tr_Radar",
			["playerCanDrive"] = true,
			["heading"] = 0.28605144170571,
		}, -- end of [3]
        [4] = 
		{
			["type"] = "Hawk cwar",
			["transportable"] = 
			{
				["randomTransportable"] = false,
			}, -- end of ["transportable"]
			["unitId"] = 2,
			["skill"] = "Average",
			["y"] = x+130,
			["x"] = y+100,
			["name"] = "Group_USA_Hawk_CWAR",
			["playerCanDrive"] = true,
			["heading"] = 0.28605144170571,
		}, -- end of [4]
        [5] = 
		{
			["type"] = "Hawk ln",
			["transportable"] = 
			{
				["randomTransportable"] = false,
			}, -- end of ["transportable"]
			["unitId"] = 2,
			["skill"] = "Average",
			["y"] = x-100,
			["x"] = y+130,
			["name"] = "Group_USA_Hawk_LN_1",
			["playerCanDrive"] = true,
			["heading"] = 0.28605144170571,
		}, -- end of [5]
        [6] = 
		{
			["type"] = "Hawk ln",
			["transportable"] = 
			{
				["randomTransportable"] = false,
			}, -- end of ["transportable"]
			["unitId"] = 2,
			["skill"] = "Average",
			["y"] = x-80,
			["x"] = y+110,
			["name"] = "Group_USA_Hawk_LN_1",
			["playerCanDrive"] = true,
			["heading"] = 0.28605144170571,
		}, -- end of [6]
        [6] = 
		{
			["type"] = "Hawk ln",
			["transportable"] = 
			{
				["randomTransportable"] = false,
			}, -- end of ["transportable"]
			["unitId"] = 2,
			["skill"] = "Average",
			["y"] = x-60,
			["x"] = y+90,
			["name"] = "Group_USA_Hawk_LN_2",
			["playerCanDrive"] = true,
			["heading"] = 0.28605144170571,
		}, -- end of [6]
        [7] = 
		{
			["type"] = "Hawk ln",
			["transportable"] = 
			{
				["randomTransportable"] = false,
			}, -- end of ["transportable"]
			["unitId"] = 2,
			["skill"] = "Average",
			["y"] = x-40,
			["x"] = y+70,
			["name"] = "Group_USA_Hawk_LN_3",
			["playerCanDrive"] = true,
			["heading"] = 0.28605144170571,
		}, -- end of [7]
        [8] = 
		{
			["type"] = "Hawk ln",
			["transportable"] = 
			{
				["randomTransportable"] = false,
			}, -- end of ["transportable"]
			["unitId"] = 2,
			["skill"] = "Average",
			["y"] = x-20,
			["x"] = y+50,
			["name"] = "Group_USA_Hawk_LN_4",
			["playerCanDrive"] = true,
			["heading"] = 0.28605144170571,
		}, -- end of [8]

	}, -- end of ["units"]
	["y"] = x+100,
	["x"] = y+100,
	["name"] = "Group_USA_NASAM",
	["start_time"] = 0,
	["task"] = "Ground Nothing",
  } -- end of [1]

  --coalition.addGroup(country.id.USA, Group.Category.GROUND, groupData)