x = 0      -- Longitude (East-West)
y = 25000  -- Latitude (North-South)

----Define Hawk SAM battery
Group_USA_Hawk = {
    ["visible"] = false,
    ["taskSelected"] = true,
    ["lateActivation"] = true,
    ["route"] = {}, -- No predefined route
    ["tasks"] = {},
    ["hidden"] = false,
    ["units"] = {
        [1] = {
            ["type"] = "Hawk pcp",
            ["unitId"] = 1,
            ["skill"] = "Average",
            ["y"] = y + 100,
            ["x"] = x + 100,
            ["name"] = "Group_USA_Hawk_CP",
            ["playerCanDrive"] = true,
            ["heading"] = 0.286,
        },
        [2] = {
            ["type"] = "Hawk sr",
            ["unitId"] = 2,
            ["skill"] = "Average",
            ["y"] = y + 110,
            ["x"] = x + 100,
            ["name"] = "Group_USA_Hawk_SR_Radar",
            ["playerCanDrive"] = true,
            ["heading"] = 0.286,
        },
        [3] = {
            ["type"] = "Hawk tr",
            ["unitId"] = 3,
            ["skill"] = "Average",
            ["y"] = y + 120,
            ["x"] = x + 100,
            ["name"] = "Group_USA_Hawk_TR_Radar",
            ["playerCanDrive"] = true,
            ["heading"] = 0.286,
        },
        [4] = {
            ["type"] = "Hawk cwar",
            ["unitId"] = 4,
            ["skill"] = "Average",
            ["y"] = y + 100,
            ["x"] = x + 130,
            ["name"] = "Group_USA_Hawk_CWAR",
            ["playerCanDrive"] = true,
            ["heading"] = 0.286,
        },
        [5] = {
            ["type"] = "Hawk ln",
            ["unitId"] = 5,
            ["skill"] = "Average",
            ["y"] = y + 130,
            ["x"] = x - 100,
            ["name"] = "Group_USA_Hawk_LN_1",
            ["playerCanDrive"] = true,
            ["heading"] = 0.286,
        },
        [6] = {
            ["type"] = "Hawk ln",
            ["unitId"] = 6,
            ["skill"] = "Average",
            ["y"] = y + 110,
            ["x"] = x - 80,
            ["name"] = "Group_USA_Hawk_LN_2",
            ["playerCanDrive"] = true,
            ["heading"] = 0.286,
        },
        [7] = {
            ["type"] = "Hawk ln",
            ["unitId"] = 7,
            ["skill"] = "Average",
            ["y"] = y + 90,
            ["x"] = x - 60,
            ["name"] = "Group_USA_Hawk_LN_3",
            ["playerCanDrive"] = true,
            ["heading"] = 0.286,
        },
        [8] = {
            ["type"] = "Hawk ln",
            ["unitId"] = 8,
            ["skill"] = "Average",
            ["y"] = y + 70,
            ["x"] = x - 40,
            ["name"] = "Group_USA_Hawk_LN_4",
            ["playerCanDrive"] = true,
            ["heading"] = 0.286,
        },
    }, -- end of ["units"]
    ["y"] = y + 100,
    ["x"] = x + 100,
    ["name"] = "Group_USA_Hawk",
    ["start_time"] = 0,
    ["task"] = "Ground Nothing",
} -- end of Group definition

-- Spawn the group
coalition.addGroup(country.id.USA, Group.Category.GROUND, Group_USA_Hawk)
