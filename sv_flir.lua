util.AddNetworkString("thermal_vision_darkrp_jobs")
local thermal_vision_job_list = {}

local function thermal_vision_fill_job_list()
	if (GAMEMODE_NAME != "darkrp") then return end
	
	table.insert(thermal_vision_job_list, TEAM_POLICE)
	
	hook.Add("PlayerInitialSpawn", "thermal_vision_send_jobs", function(ply)
		net.Start("thermal_vision_darkrp_jobs")
		net.WriteTable(thermal_vision_job_list)
		net.Send(ply)
	end)
end

hook.Add("PostGamemodeLoaded", "thermal_vision_fill_job_list", thermal_vision_fill_job_list)