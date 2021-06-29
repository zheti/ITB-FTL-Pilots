
local this = {}

local pilot = {
	Id = "Pilot_lmn_Engi",
	Personality = "lmn_Engi",
	Name = "Virus", --tmp?
	Rarity = 1,
	Voice = "/voice/gana",
	Skill = "lmn_engi_repair",
}

-- make a copy of tipimage to not change replaceRepair.
local tipImage = shallow_copy(replaceRepair_internal.OrigTipImage)
tipImage.Fire = Point(2,2) -- apply fire removed by replaceRepair.

lmn_Engi_Repair = Skill:new{
	Name = "Nano Repair",
	Description = "Repair a nearby unit for 2 damage and remove Fire, Ice, and A.C.I.D.",
	Amount = -2,
	PathSize = 1,
	TipImage = tipImage,
}

function lmn_Engi_Repair:GetTargetArea(p)
	local ret = PointList()
	ret:push_back(p)
	
	for dir = DIR_START, DIR_END do
		local loc = p + DIR_VECTORS[dir]
		if Board:IsValid(loc) and Board:GetPawnTeam(loc) == TEAM_PLAYER then
			ret:push_back(loc)
		end
	end
	
	return ret
end

function lmn_Engi_Repair:RepairTrain(p2)
	local mission = GetCurrentMission()
	
	local train = Board:GetPawn(mission.Train)
	if train then
        Board:RemovePawn(train)

		if train:IsDead() then
			train = PAWN_FACTORY:CreatePawn("Train_Damaged")
		else
			train = PAWN_FACTORY:CreatePawn("Train_Pawn")
			mission.TrainStopped = false

			mission.TurnLimit = mission.TurnLimit + 1
		end

		Board:AddPawn(train, mission.TrainLoc)

		mission.Train = train:GetId()
	end
end

-- original train repair by Lemonymous
--[[function lmn_Engi_Repair:RepairTrain(p2)
	local mission = GetCurrentMission()
	
	local train = Board:GetPawn(mission.Train)
	if train then
		Board:RemovePawn(train)
		train = PAWN_FACTORY:CreatePawn("Train_Pawn")
		Board:AddPawn(train, mission.TrainLoc)
		
		mission.Train = train:GetId()
		mission.TrainStopped = false
	end
end--]]


function lmn_Engi_Repair:RepairFiller(p2)
	local mission = GetCurrentMission()
	
	local filler = Board:GetPawn(mission.Filler)
	if filler then
		Board:RemovePawn(filler)
		filler = PAWN_FACTORY:CreatePawn("Filler_Pawn")
		Board:AddPawn(filler, "filler")
		
		mission.Filler = filler:GetId()

		mission.TurnLimit = mission.TurnLimit + 1
	end
end

function lmn_Engi_Repair:RepairSatelliteRocket1(p2)
	local mission = GetCurrentMission()
	
	local rocket = Board:GetPawn(mission.Satellites[1])
	if rocket then
		Board:RemovePawn(rocket)
		new_rocket = PAWN_FACTORY:CreatePawn("SatelliteRocket")
		Board:AddPawn(new_rocket, rocket:GetSpace())
		new_rocket:SetPowered(false)
		
		mission.Satellites[1] = new_rocket:GetId()

		mission.TurnLimit = mission.TurnLimit + 1
	end
end

function lmn_Engi_Repair:RepairSatelliteRocket2(p2)
	local mission = GetCurrentMission()
	
	local rocket = Board:GetPawn(mission.Satellites[2])
	if rocket then
		Board:RemovePawn(rocket)
		new_rocket = PAWN_FACTORY:CreatePawn("SatelliteRocket")
		Board:AddPawn(new_rocket, rocket:GetSpace())
		new_rocket:SetPowered(false)
		
		mission.Satellites[2] = new_rocket:GetId()

		mission.TurnLimit = mission.TurnLimit + 1
	end
end

function lmn_Engi_Repair:GetSkillEffect(p1, p2)
	local ret = replaceRepair_internal.OrigGetSkillEffect(self, p1, p2)
	local pawn = Board:GetPawn(p2)
	local id = pawn:GetId()
	local mission = GetCurrentMission()
	
	-- if not a mech, add repair_mech sound
	if id > 2 then
		ret:AddSound("/ui/map/repair_mech")
	end

	-- repair train
	if
		pawn				and
		id == mission.Train	and
		mission.TrainStopped
	then
		ret:AddScript("lmn_Engi_Repair:RepairTrain(".. p2:GetString() ..")")
	end

	-- repair filler aka earth mover
	if
		pawn					and
		id == mission.Filler	and
		not Board:IsPawnAlive(mission.Filler)
	then
		ret:AddScript("lmn_Engi_Repair:RepairFiller(".. p2:GetString() ..")")
	end

	-- repair satellite rocket
	if
		pawn						and
		mission.Satellites			and
		id == mission.Satellites[1]	and
		not Board:IsPawnAlive(id)
	then
		ret:AddScript("lmn_Engi_Repair:RepairSatelliteRocket1(".. p2:GetString() ..")")
	end

	if
		pawn						and
		mission.Satellites			and
		id == mission.Satellites[2]	and
		not Board:IsPawnAlive(id)
	then
		ret:AddScript("lmn_Engi_Repair:RepairSatelliteRocket2(".. p2:GetString() ..")")
	end

	return ret
end

function this:init(mod)
	CreatePilot(pilot)
	
	require(mod.scriptPath .."personality_engi")
	
	modApi:appendAsset("img/portraits/pilots/Pilot_lmn_Engi.png", mod.resourcePath .."img/portraits/pilots/pilot_engi.png")
	modApi:appendAsset("img/portraits/pilots/Pilot_lmn_Engi_2.png", mod.resourcePath .."img/portraits/pilots/pilot_engi_2.png")
	modApi:appendAsset("img/portraits/pilots/Pilot_lmn_Engi_blink.png", mod.resourcePath .."img/portraits/pilots/pilot_engi_blink.png")
	
	require(mod.scriptPath .."replaceRepair/replaceRepair")
		:ForPilot(
			"lmn_engi_repair",
			"lmn_Engi_Repair",
			{lmn_Engi_Repair.Name, "Repairs 2 damage.\nCan repair adjacent units."}
		)
end

function this:load(modApiExt, options)
end

return this