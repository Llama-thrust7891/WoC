-------------
-----CTLD----
-------------
function BlueOpsCTLD()
    env.info(string.format("###Blue CTLD FILE Start Load ###"))
    
    SETTINGS:SetPlayerMenuOff()
    
       Blue_ctld = CTLD:New(coalition.side.BLUE,nil,"23rd Transport Squadron")
    
       Blue_ctld:SetOwnSetPilotGroups(SET_GROUP:New():FilterCoalitions("blue"):FilterCategoryHelicopter():FilterFunction(
        function(grp)
        local _type = grp:GetTypeName()
        local retval = false
        if _type == "CH-47Fbl1" or _type == "UH-1H" or _type == "Mi-8MT" or _type == "Mi-8MTV2" or _type == "Mi-24P" or _type == "UH-60L"   then
            retval = true;
        end
        return retval
        end ):FilterStart())
       
       Blue_ctld.maximumHoverHeight = 35
       Blue_ctld.forcehoverload = false
       Blue_ctld.dropcratesanywhere = true
       Blue_ctld.buildtime = 10
       Blue_ctld:UnitCapabilities("UH-1H", true, true, 2, 12, 15, 3000)
       Blue_ctld:UnitCapabilities("MI-24P", true, true, 2, 12, 15, 3000)
       Blue_ctld:UnitCapabilities("MI-24V", true, true, 2, 12, 15, 3000)
       Blue_ctld:UnitCapabilities("CH-47", true, true, 8, 24, 30, 7200)
    
       Blue_ctld:__Start(5)
    
       -- add infantry unit called "Anti-Tank Small" using template "ATS", of type TROOP with size 3
       -- infantry units will be loaded directly from LOAD zones into the heli (matching number of free seats needed)
          Blue_ctld:AddTroopsCargo("Infantry Squad",{Group_Blue_Inf},CTLD_CARGO.Enum.TROOPS,3)
    
       -- add infantry unit called "Anti-Tank" using templates "AA" and "AA"", of type TROOP with size 4. No weight. We only have 2 in stock:
          Blue_ctld:AddTroopsCargo("Anti-Air",{Group_Blue_SAM},CTLD_CARGO.Enum.TROOPS,3,nil)
          
          Blue_ctld:AddTroopsCargo("M113",{Group_Blue_APC},CTLD_CARGO.Enum.TROOPS,4,nil)
          Blue_ctld:AddTroopsCargo("SHORAD",{Group_Blue_SAM},CTLD_CARGO.Enum.TROOPS,4,nil)
    --      Blue_ctld:AddTroopsCargo("Mechanised",{"Blue_Mech_Marder_Template","Ground_Blue_SPG_Stryker"},CTLD_CARGO.Enum.TROOPS,8,nil)
    
    
          -- add an engineers unit called "Wrenches" using template "Engineers", of type ENGINEERS with size 2. Engineers can be loaded, dropped,
       -- and extracted like troops. However, the will seek to build and/or repair crates found in a given radius. Handy if you can\'t stay
       -- to build or repair or under fire.
          Blue_ctld:AddTroopsCargo("Wrenches",{"Blue_CTLD_Wrenches"},CTLD_CARGO.Enum.ENGINEERS,4)
          Blue_ctld.EngineerSearch = 2000 -- teams will search for crates in this radius.
    
          -- add vehicle called "Humvee" using template "Humvee", of type VEHICLE, size 2, i.e. needs two crates to be build
       -- vehicles and FOB will be spawned as crates in a LOAD zone first. Once transported to DROP zones, they can be build into the objects
          Blue_ctld:AddCratesCargo("Marder Group",{Group_Blue_Mech},CTLD_CARGO.Enum.VEHICLE,2,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          Blue_ctld:AddCratesCargo("Hawk_Site", {Group_Blue_SAM_Site},CTLD_CARGO.Enum.VEHICLE,8,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          --Blue_ctld:AddCratesCargo("NASAM",{"Blue_NASAM_Template"},CTLD_CARGO.Enum.VEHICLE,18)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          Blue_ctld:AddCratesCargo("Leopard Group",{Group_Blue_Armoured},CTLD_CARGO.Enum.VEHICLE,4,500)
          Blue_ctld:AddCratesCargo("M109 Group",{Group_Blue_Arty},CTLD_CARGO.Enum.VEHICLE,2,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
       -- add infantry unit called "Forward Ops Base" using template "FOB", of type FOB, size 4, i.e. needs four crates to be build:
          Blue_ctld:AddCratesCargo("Forward Ops Base",{"Blue_CTLD_FOB"},CTLD_CARGO.Enum.FOB,4)
    
       -- add crates to repair FOB or VEHICLE type units - the 2nd parameter needs to match the template you want to repair,
       -- e.g. the "Humvee" here refers back to the "Humvee" crates cargo added above (same template!)
          Blue_ctld:AddCratesRepair("Humvee Repair","Blue_Unarmed_Humvee_Template",CTLD_CARGO.Enum.REPAIR,1)
          Blue_ctld.repairtime = 300 -- takes 300 seconds to repair something
    
       -- add static cargo objects, e.g ammo chests - the name needs to refer to a STATIC object in the mission editor, 
       -- here: it\'s the UNIT name (not the GROUP name!), the second parameter is the weight in kg.
          --Blue_ctld:AddStaticsCargo("Blue_Ammo",500)
    
          blueAirfieldszoneset:ForEachZone(
            function(zone)
                local zonename = zone:GetName()
                Blue_ctld:AddCTLDZone(zonename,CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
              
                env.info("Blue ZONE added to CTLD LOAD ZONE: " .. zone:GetName())
            end
        )  
    
          -- Add a zone of type LOAD to our setup. Players can load any troops and crates here as defined in 1.2 above.
          -- "Loadzone" is the name of the zone from the ME. Players can load, if they are inside the zone.
          -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
           -- Add a zone of type DROP. Players can drop crates here.
          -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
          -- NOTE: Troops can be unloaded anywhere, also when hovering in parameters. 
          --moved  to zone empty function 
          --Blue_ctld:AddCTLDZone("Dropzone",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)
    
    
    env.info(string.format("###Blue CTLD FILE Loaded Succesfully###"))
    
end

function RedOpsCTLD()
    env.info(string.format("###Red CTLD FILE Start Load ###"))
    
    SETTINGS:SetPlayerMenuOff()
    
       Red_ctld = CTLD:New(coalition.side.RED,nil,"23rd Transport Squadron")
    
       Red_ctld:SetOwnSetPilotGroups(SET_GROUP:New():FilterCoalitions("red"):FilterCategoryHelicopter():FilterFunction(
        function(grp)
        local _type = grp:GetTypeName()
        local retval = false
        if _type == "CH-47Fbl1" or _type == "UH-1H" or _type == "Mi-8MT" or _type == "Mi-8MTV2" or _type == "Mi-24P" or _type == "UH-60L"   then
            retval = true;
        end
        return retval
        end ):FilterStart())
       
       Red_ctld.maximumHoverHeight = 35
       Red_ctld.forcehoverload = false
       Red_ctld.dropcratesanywhere = true
       Red_ctld.buildtime = 10
       Red_ctld:UnitCapabilities("UH-1H", true, true, 2, 12, 15, 3000)
       Red_ctld:UnitCapabilities("MI-24P", true, true, 2, 12, 15, 3000)
       Red_ctld:UnitCapabilities("MI-24V", true, true, 2, 12, 15, 3000)
       Red_ctld:UnitCapabilities("CH-47", true, true, 8, 24, 30, 7200)
    
       Red_ctld:__Start(5)
    
       -- add infantry unit called "Anti-Tank Small" using template "ATS", of type TROOP with size 3
       -- infantry units will be loaded directly from LOAD zones into the heli (matching number of free seats needed)
          Red_ctld:AddTroopsCargo("Infantry Squad",{Group_Red_Inf},CTLD_CARGO.Enum.TROOPS,3)
    
       -- add infantry unit called "Anti-Tank" using templates "AA" and "AA"", of type TROOP with size 4. No weight. We only have 2 in stock:
          Red_ctld:AddTroopsCargo("Anti-Air",{Group_Red_SAM},CTLD_CARGO.Enum.TROOPS,3,nil)
          
          Red_ctld:AddTroopsCargo("M113",{Group_Red_APC},CTLD_CARGO.Enum.TROOPS,4,nil)
          Red_ctld:AddTroopsCargo("SHORAD",{Group_Red_SAM},CTLD_CARGO.Enum.TROOPS,4,nil)
    --      Red_ctld:AddTroopsCargo("Mechanised",{"Red_Mech_Marder_Template","Ground_Red_SPG_Stryker"},CTLD_CARGO.Enum.TROOPS,8,nil)
    
    
          -- add an engineers unit called "Wrenches" using template "Engineers", of type ENGINEERS with size 2. Engineers can be loaded, dropped,
       -- and extracted like troops. However, the will seek to build and/or repair crates found in a given radius. Handy if you can\'t stay
       -- to build or repair or under fire.
          Red_ctld:AddTroopsCargo("Wrenches",{"Red_CTLD_Wrenches"},CTLD_CARGO.Enum.ENGINEERS,4)
          Red_ctld.EngineerSearch = 2000 -- teams will search for crates in this radius.
    
          -- add vehicle called "Humvee" using template "Humvee", of type VEHICLE, size 2, i.e. needs two crates to be build
       -- vehicles and FOB will be spawned as crates in a LOAD zone first. Once transported to DROP zones, they can be build into the objects
          Red_ctld:AddCratesCargo("Marder Group",{Group_Red_Mech},CTLD_CARGO.Enum.VEHICLE,2,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          Red_ctld:AddCratesCargo("Hawk_Site", {Group_Red_SAM_Site},CTLD_CARGO.Enum.VEHICLE,8,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          --Red_ctld:AddCratesCargo("NASAM",{"Red_NASAM_Template"},CTLD_CARGO.Enum.VEHICLE,18)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          Red_ctld:AddCratesCargo("Leopard Group",{Group_Red_Armoured},CTLD_CARGO.Enum.VEHICLE,4,500)
          Red_ctld:AddCratesCargo("M109 Group",{Group_Red_Arty},CTLD_CARGO.Enum.VEHICLE,2,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
       -- add infantry unit called "Forward Ops Base" using template "FOB", of type FOB, size 4, i.e. needs four crates to be build:
          Red_ctld:AddCratesCargo("Forward Ops Base",{"Red_CTLD_FOB"},CTLD_CARGO.Enum.FOB,4)
    
       -- add crates to repair FOB or VEHICLE type units - the 2nd parameter needs to match the template you want to repair,
       -- e.g. the "Humvee" here refers back to the "Humvee" crates cargo added above (same template!)
          Red_ctld:AddCratesRepair("Humvee Repair","Red_Unarmed_Humvee_Template",CTLD_CARGO.Enum.REPAIR,1)
          Red_ctld.repairtime = 300 -- takes 300 seconds to repair something
    
       -- add static cargo objects, e.g ammo chests - the name needs to refer to a STATIC object in the mission editor, 
       -- here: it\'s the UNIT name (not the GROUP name!), the second parameter is the weight in kg.
          --Red_ctld:AddStaticsCargo("Red_Ammo",500)
    
          redAirfieldszoneset:ForEachZone(
            function(zone)
                local zonename = zone:GetName()
                Red_ctld:AddCTLDZone(zonename,CTLD.CargoZoneType.LOAD,SMOKECOLOR.Red,true,true)
              
                env.info("Red ZONE added to CTLD LOAD ZONE: " .. zone:GetName())
            end
        )  
    
          -- Add a zone of type LOAD to our setup. Players can load any troops and crates here as defined in 1.2 above.
          -- "Loadzone" is the name of the zone from the ME. Players can load, if they are inside the zone.
          -- Smoke and Flare color for this zone is Red, it is active (can be used) and has a radio beacon.
           -- Add a zone of type DROP. Players can drop crates here.
          -- Smoke and Flare color for this zone is Red, it is active (can be used) and has a radio beacon.
          -- NOTE: Troops can be unloaded anywhere, also when hovering in parameters. 
          --moved  to zone empty function 
          --Red_ctld:AddCTLDZone("Dropzone",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)

    env.info(string.format("###Red CTLD FILE Loaded Succesfully###"))
    
end

BlueOpsCTLD()
RedOpsCTLD()

-------------------------------------------
-------------------------------------------
---------End CTLD------------------------
-------------------------------------------
-------------------------------------------