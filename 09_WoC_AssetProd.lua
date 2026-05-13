--------------------------------------------
--------------------------------------------
------------------Airwing Production--------
--------------------------------------------

local function ProduceAirwing(warehouseName, airwing, Coalition)
    local factory = STATIC:FindByName(warehouseName)
       -- Check that factory is alive.
    if factory and factory:IsAlive() then
        env.info(string.format("Producing for airwing: %s for %s", warehouseName, Coalition))
        
        -- Function to safely check payload and add if it's 2 or less
        local function IncreaseIfBelowLimit(payload)
            if payload then
                local currentAmount = airwing:GetPayloadAmount(payload) or 0
                if currentAmount <= 2 then
                    airwing:IncreasePayloadAmount(payload, 1)
                    env.info(string.format("Increased payload for %s, new amount: %d", warehouseName, currentAmount + 1))
                else
                    env.info(string.format("Skipped increasing payload for %s (already >2)", warehouseName))
                end
            else
                env.info(string.format("Warning: payload does not exist for %s", warehouseName))
            end
        end


        if Coalition == "Blue" then
            IncreaseIfBelowLimit(Blue_payload_Fighter_AA)
            IncreaseIfBelowLimit(Blue_payload_Fighter_SEAD)
            IncreaseIfBelowLimit(Blue_payload_Fighter_CAS)
            IncreaseIfBelowLimit(Blue_payload_LtFighter_AA)
            IncreaseIfBelowLimit(Blue_payload_LtFighter_CAS)
            IncreaseIfBelowLimit(Blue_payload_Attack_CAS)
        elseif Coalition == "Red" then
            IncreaseIfBelowLimit(Red_payload_Fighter_AA)
            IncreaseIfBelowLimit(Red_payload_Fighter_SEAD)
            IncreaseIfBelowLimit(Red_payload_Fighter_CAS)
            IncreaseIfBelowLimit(Red_payload_LtFighter_AA)
            IncreaseIfBelowLimit(Red_payload_LtFighter_CAS)
            IncreaseIfBelowLimit(Red_payload_Attack_CAS)
        else
            env.info("Coalition not found")
        end

        -- Function to safely get payload amount
        local function GetPayloadSafe(payload)
            return payload and airwing:GetPayloadAmount(payload) or 0
        end

        local N1, N2, N3, N4, N5, N6
        if Coalition == "Blue" then
            N1 = GetPayloadSafe(Blue_payload_Fighter_AA)
            N2 = GetPayloadSafe(Blue_payload_Fighter_SEAD)
            N3 = GetPayloadSafe(Blue_payload_Fighter_CAS)
            N4 = GetPayloadSafe(Blue_payload_LtFighter_AA)
            N5 = GetPayloadSafe(Blue_payload_LtFighter_CAS)
            N6 = GetPayloadSafe(Blue_payload_Attack_CAS)
        elseif Coalition == "Red" then
            N1 = GetPayloadSafe(Red_payload_Fighter_AA)
            N2 = GetPayloadSafe(Red_payload_Fighter_SEAD)
            N3 = GetPayloadSafe(Red_payload_Fighter_CAS)
            N4 = GetPayloadSafe(Red_payload_LtFighter_AA)
            N5 = GetPayloadSafe(Red_payload_LtFighter_CAS)
            N6 = GetPayloadSafe(Red_payload_Attack_CAS)
        else
            env.info("Coalition not found")
        end

        -- Log payload info
        env.info(string.format(
            "Payloads available after production at %s: AA=%d, SEAD=%d, CAS=%d, LtAA=%d, LtCAS=%d, AttackCAS=%d",
            warehouseName, N1 or 0, N2 or 0, N3 or 0, N4 or 0, N5 or 0, N6 or 0
        ))
        if Coalition == "Blue" then 
        local airfieldName = warehouseName:gsub("^warehouse_", "")
        local Sqn1 = airwing:GetSquadron("Blue Fighter Squadron "..airfieldName)
        local Sqn2 = airwing:GetSquadron("Blue Light Fighter Squadron "..airfieldName)
        local Sqn3 = airwing:GetSquadron("Blue Attack Squadron "..airfieldName)
        local Sqn4 = airwing:GetSquadron("Blue Transport Squadron "..airfieldName)
        env.info("Producing assets for Blue Airwing: " .. airfieldName)
            if Sqn1  then
                    local Nsqn1 = Sqn1:CountAssets()
                    if Nsqn1 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn1:GetName(), Nsqn1)) 
                    airwing:AddAssetToSquadron(Sqn1, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn1:GetName(), Sqn1:CountAssets()))
                else
                    env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn1:GetName(), Sqn1:CountAssets()))
                    end
            end
            if Sqn2  then
                    local Nsqn2 = Sqn2:CountAssets()
                    if Nsqn2 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn2:GetName(), Nsqn2)) 
                    airwing:AddAssetToSquadron(Sqn2, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn2:GetName(), Sqn2:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn2:GetName(), Sqn2:CountAssets()))
                    end
            end
            if Sqn3  then
                    local Nsqn3 = Sqn3:CountAssets()
                    if Nsqn3 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn3:GetName(), Nsqn3)) 
                    airwing:AddAssetToSquadron(Sqn3, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn3:GetName(), Sqn3:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn3:GetName(), Sqn3:CountAssets()))
                    end
            end
            if Sqn4  then
                    local Nsqn4 = Sqn4:CountAssets()
                    if Nsqn4 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn4:GetName(), Nsqn4)) 
                    airwing:AddAssetToSquadron(Sqn4, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn4:GetName(), Sqn4:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn4:GetName(), Sqn4:CountAssets()))
                    end
            end


        end
        if Coalition == "Red" then
        local airfieldName = warehouseName:gsub("^warehouse_", "")
        local Sqn1 = airwing:GetSquadron("Red Fighter Squadron "..airfieldName)
        local Sqn2 = airwing:GetSquadron("Red Light Fighter Squadron "..airfieldName)
        local Sqn3 = airwing:GetSquadron("Red Attack Squadron "..airfieldName)
        local Sqn4 = airwing:GetSquadron("Red Transport Squadron "..airfieldName)
        env.info("Producing assets for Red Airwing: " .. airfieldName)
            if Sqn1  then
                    local Nsqn1 = Sqn1:CountAssets()
                    if Nsqn1 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn1:GetName(), Nsqn1)) 
                    airwing:AddAssetToSquadron(Sqn1, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn1:GetName(), Sqn1:CountAssets()))
                else
                    env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn1:GetName(), Sqn1:CountAssets()))
                    end
            end
            if Sqn2  then
                    local Nsqn2 = Sqn2:CountAssets()
                    if Nsqn2 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn2:GetName(), Nsqn2)) 
                    airwing:AddAssetToSquadron(Sqn2, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn2:GetName(), Sqn2:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn2:GetName(), Sqn2:CountAssets()))
                    end
            end
            if Sqn3  then
                    local Nsqn3 = Sqn3:CountAssets()
                    if Nsqn3 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn3:GetName(), Nsqn3)) 
                    airwing:AddAssetToSquadron(Sqn3, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn3:GetName(), Sqn3:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn3:GetName(), Sqn3:CountAssets()))
                    end
            end
            if Sqn4  then
                    local Nsqn4 = Sqn4:CountAssets()
                    if Nsqn4 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn4:GetName(), Nsqn4)) 
                    airwing:AddAssetToSquadron(Sqn4, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn4:GetName(), Sqn4:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn4:GetName(), Sqn4:CountAssets()))
                    end
            end
        end    
    
    end
end
--------------------------------------------------
-- Function to produce brigade assets for a given warehouse and brigade
-- Coalition is either "Blue" or "Red"
--------------------------------------------------

function Producebrigade(warehouseName, brigade, Coalition)
    if Coalition == "Blue" then 
        local airfieldName = warehouseName:gsub("^warehouse_", "")
        local Plt1 = brigade:GetPlatoon("Blue Motorised Platoon "..airfieldName)
        local Plt2 = brigade:GetPlatoon("Blue Mechanised Platoon "..airfieldName)
        local Plt3 = brigade:GetPlatoon("Blue Armoured Platoon "..airfieldName)
        local Plt4 = brigade:GetPlatoon("Blue Artillary Platoon "..airfieldName)
        local Plt5 = brigade:GetPlatoon("Blue Logistics Platoon "..airfieldName)
        local Plt6 = brigade:GetPlatoon("Blue Infantry Platoon "..airfieldName)
        local Plt7 = brigade:GetPlatoon("Blue SAM Platoon "..airfieldName)
        env.info("Producing assets for Blue Brigade: " .. airfieldName)
        if Plt1  then
            local Nplt1 = Plt1:CountAssets()
            if Nplt1 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt1:GetName(), Nplt1)) 
            brigade:AddAssetToSquadron(Plt1, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt1:GetName(), Plt1:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt1:GetName(), Plt1:CountAssets()))
            end
        end
        if Plt2  then
            local Nplt2 = Plt2:CountAssets()
            if Nplt2 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt2:GetName(), Nplt2)) 
            brigade:AddAssetToSquadron(Plt2, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt2:GetName(), Plt2:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt2:GetName(), Plt2:CountAssets()))
            end
        end
        if Plt3  then
            local Nplt3 = Plt3:CountAssets()
            if Nplt3 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt3:GetName(), Nplt3)) 
            brigade:AddAssetToSquadron(Plt3, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt3:GetName(), Plt3:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt3:GetName(), Plt3:CountAssets()))
            end
        end 
        if Plt4  then
            local Nplt4 = Plt4:CountAssets()
            if Nplt4 < 2 then
            env.info(string.format("###Platoon %s has %d assets###", Plt4:GetName(), Nplt4)) 
            brigade:AddAssetToSquadron(Plt4, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt4:GetName(), Plt4:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt4:GetName(), Plt4:CountAssets()))
            end
        end
        if Plt5  then
            local Nplt5 = Plt5:CountAssets()
            if Nplt5 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt5:GetName(), Nplt5)) 
            brigade:AddAssetToSquadron(Plt5, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt5:GetName(), Plt5:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt5:GetName(), Plt5:CountAssets()))
            end
        end
        if Plt6  then
            local Nplt6 = Plt6:CountAssets()
            if Nplt6 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt6:GetName(), Nplt6)) 
            brigade:AddAssetToSquadron(Plt6, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt6:GetName(), Plt6:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt6:GetName(), Plt6:CountAssets()))
            end
        end
        if Plt7  then
            local Nplt7 = Plt7:CountAssets()
            if Nplt7 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt7:GetName(), Nplt7)) 
            brigade:AddAssetToSquadron(Plt7, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt7:GetName(), Plt7:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt7:GetName(), Plt7:CountAssets()))
            end
        end
    end

    if Coalition == "Red" then 
        local airfieldName = warehouseName:gsub("^warehouse_", "")
        local Plt1 = brigade:GetPlatoon("Red Motorised Platoon "..airfieldName)
        local Plt2 = brigade:GetPlatoon("Red Mechanised Platoon "..airfieldName)
        local Plt3 = brigade:GetPlatoon("Red Armoured Platoon "..airfieldName)
        local Plt4 = brigade:GetPlatoon("Red Artillary Platoon "..airfieldName)
        local Plt5 = brigade:GetPlatoon("Red Logistics Platoon "..airfieldName)
        local Plt6 = brigade:GetPlatoon("Red Infantry Platoon "..airfieldName)
        local Plt7 = brigade:GetPlatoon("Red SAM Platoon "..airfieldName)
        env.info("Producing assets for Red Brigade: " .. airfieldName)
        --motorised platoon
        if Plt1  then
            local Nplt1 = Plt1:CountAssets()
            if Nplt1 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt1:GetName(), Nplt1)) 
            brigade:AddAssetToSquadron(Plt1, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt1:GetName(), Plt1:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt1:GetName(), Plt1:CountAssets()))
            end
        end
        --mechanised platoon
        if Plt2  then
            local Nplt2 = Plt2:CountAssets()
            if Nplt2 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt2:GetName(), Nplt2)) 
            brigade:AddAssetToSquadron(Plt2, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt2:GetName(), Plt2:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt2:GetName(), Plt2:CountAssets()))
            end
        end
        --armoured platoon
        if Plt3  then
            local Nplt3 = Plt3:CountAssets()
            if Nplt3 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt3:GetName(), Nplt3))
            brigade:AddAssetToSquadron(Plt3, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt3:GetName(), Plt3:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt3:GetName(), Plt3:CountAssets()))
            end
        end
        --artillary platoon
        if Plt4  then
            local Nplt4 = Plt4:CountAssets()
            if Nplt4 < 2 then
            env.info(string.format("###Platoon %s has %d assets###", Plt4:GetName(), Nplt4)) 
            brigade:AddAssetToSquadron(Plt4, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt4:GetName(), Plt4:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt4:GetName(), Plt4:CountAssets()))
            end
        end
        --logistics platoon
        if Plt5  then
            local Nplt5 = Plt5:CountAssets()
            if Nplt5 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt5:GetName(), Nplt5)) 
            brigade:AddAssetToSquadron(Plt5, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt5:GetName(), Plt5:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt5:GetName(), Plt5:CountAssets()))
            end
        end
        --infantry platoon
        if Plt6  then
            local Nplt6 = Plt6:CountAssets()
            if Nplt6 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt6:GetName(), Nplt6)) 
            brigade:AddAssetToSquadron(Plt6, 2)
            env.info(string.format("Added 2 assets to Platoon %s. New total: %d", Plt6:GetName(), Plt6:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt6:GetName(), Plt6:CountAssets()))
            end
        end
        --SAM platoon
        if Plt7  then
            local Nplt7 = Plt7:CountAssets()
            if Nplt7 < 2 then
            env.info(string.format("###Platoon %s has %d assets###", Plt7:GetName(), Nplt7)) 
            brigade:AddAssetToSquadron(Plt7, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt7:GetName(), Plt7:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt7:GetName(), Plt7:CountAssets()))
            end
        end
    end
end
