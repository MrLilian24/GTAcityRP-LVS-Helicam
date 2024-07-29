local ThermalVisionActive = false
local ThermalVisionDelayON = false
local ThermalVisionDelayOFF = false
local DarkRP_Whitelist_thermal = {}

if not ConVarExists("thermal_vision_walls") then
	CreateClientConVar("thermal_vision_walls", "1", true, false, "To see entities through walls while using thermal vision.")
end

if not ConVarExists("thermal_vision_range") then
	CreateClientConVar("thermal_vision_range", "0", true, false, "Maximum range of thermal vision.")
end

local function ThermalVisionToggleON()
	local TMWalls = GetConVar("thermal_vision_walls"):GetInt()
	local TMRange = math.abs(GetConVar("thermal_vision_range"):GetInt())
	local cur_pos_player = LocalPlayer():GetPos()
	local extraGlowEnts = {}
	
	render.ClearStencil()
	
	render.SetStencilEnable(true)
		render.SetStencilWriteMask(255)
		render.SetStencilTestMask(255)
		render.SetStencilReferenceValue(1)
		
		for _, ent in ipairs(ents.GetAll()) do
			if (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
				if (ent == LocalPlayer()) then
					if (!ent:Alive()) then
						ThermalVisionActive = false
						
						hook.Remove("PreDrawViewModel", "ThermalVisionViewmodelColorON")
						hook.Remove("PostDrawTranslucentRenderables", "ThermalVisionToggleON")
						
						return
					end
				else
					if TMRange != 0 then
						if (ent:GetPos():DistToSqr(cur_pos_player) > TMRange) then continue end
					end
					
					render.SetStencilCompareFunction(STENCIL_ALWAYS)
					
					if (TMWalls == 1) then
						render.SetStencilZFailOperation(STENCIL_REPLACE)
					else
						render.SetStencilZFailOperation(STENCIL_KEEP)
					end
					
					render.SetStencilPassOperation(STENCIL_REPLACE)
					render.SetStencilFailOperation(STENCIL_KEEP)
					ent:DrawModel()
					
					render.SetStencilCompareFunction(STENCIL_EQUAL)
					render.SetStencilZFailOperation(STENCIL_KEEP)
					render.SetStencilPassOperation(STENCIL_KEEP)
					render.SetStencilFailOperation(STENCIL_KEEP)
					
					cam.Start2D()
						surface.SetDrawColor(255, 255, 35, 255)
						surface.DrawRect(0, 0, ScrW(), ScrH())
					cam.End2D()
					
					table.insert(extraGlowEnts, ent)
				end
			end
		end
		
		if (TMWalls == 1) then
			halo.Add(extraGlowEnts, Color(255, 0, 0), 1, 1, 1, true, true)
		else
			halo.Add(extraGlowEnts, Color(255, 0, 0), 1, 1, 1, true, false)
		end
		
		render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		
		cam.Start2D()
			surface.SetDrawColor(0, 0, 150, 220)
			surface.DrawRect(0, 0, ScrW(), ScrH())
		cam.End2D()
		
	render.SetStencilEnable(false)
end

local function ThermalVisionAction()
	if (GAMEMODE_NAME == "darkrp") then
		if not table.HasValue(DarkRP_Whitelist_thermal, LocalPlayer():Team()) then
			return
		end
	end
	
	if (!ThermalVisionActive) then
		if (!ThermalVisionDelayON) then
			ThermalVisionActive = true
			surface.PlaySound("kuma96/thermal_vision/tactical_goggles_on.wav")
			
			hook.Add("PreDrawViewModel", "ThermalVisionViewmodelColorON", function()
				render.SetColorModulation(0, 0, 1)
			end)
			
			hook.Add("PostDrawTranslucentRenderables", "ThermalVisionToggleON", ThermalVisionToggleON)
			ThermalVisionDelayON = true
			
			timer.Simple(1, function()
				ThermalVisionDelayON = false
			end)
		end
	else
		if (!ThermalVisionDelayOFF) then
			ThermalVisionActive = false
			hook.Remove("PreDrawViewModel", "ThermalVisionViewmodelColorON")
			hook.Remove("PostDrawTranslucentRenderables", "ThermalVisionToggleON")
			surface.PlaySound("kuma96/thermal_vision/tactical_goggles_off.wav")
			
			ThermalVisionDelayOFF = true
			
			timer.Simple(2, function()
				ThermalVisionDelayOFF = false
			end)
		end
	end
end

hook.Add("PostGamemodeLoaded", "thermal_vision_start", function()
	concommand.Add("thermal_vision", ThermalVisionAction)
	
	if (GAMEMODE_NAME == "darkrp") then
		net.Receive("thermal_vision_darkrp_jobs", function(len, ply)
			DarkRP_Whitelist_thermal = net.ReadTable()
		end)
		
		hook.Add("OnPlayerChangedTeam", "thermal_vision_job_checker", function(ply, oldteam, newteam)
			if not table.HasValue(DarkRP_Whitelist_thermal, newteam) then
				if (ThermalVisionActive) then
					ThermalVisionActive = false
					
					hook.Remove("PreDrawViewModel", "ThermalVisionViewmodelColorON")
					hook.Remove("PostDrawTranslucentRenderables", "ThermalVisionToggleON")
				end
			end
		end)
	end
end)