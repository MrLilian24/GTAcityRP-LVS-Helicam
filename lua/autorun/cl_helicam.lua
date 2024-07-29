-- cl_helicam.lua - Client side
-- Created by Rémi.L (https://steamcommunity.com/id/lilian24)

local helicam = false
local entVis = nil
local scanning = false
local scanComplete = false
local lastScannedVehicle = nil
local plate = "Unknown"
local zoom, zoomMax, zoomMin, zoomSpeed = 0, 72, 0, 0.4
local rot, rotSpeed = 0, 0.2
local rotV, rotVMax, rotVMin, rotSpeed = 0, 60, -20, 0.2
local rotateSoundH, rotateSoundV, zoomSound = nil, nil, nil
local minSpeedFactor = 0.05
--local flirMode = false

surface.CreateFont("HeliCamLogo", {font = "Arial", extended = false, size = 72, weight = 1200})
surface.CreateFont("HeliCamLegend", {font = "Arial", extended = false, size = 28, weight = 1200})
surface.CreateFont("MiddleCross", {font = "CenterPrintText", extended = false, size = 40, weight = 600})
surface.CreateFont("HeliCamAnnexe", {font = "DermaDefault", extended = false, size = 28, weight = 600})
surface.CreateFont("HeliCamAnnexe2", {font = "DermaDefault", extended = false, size = 24, weight = 600})
surface.CreateFont("HeliCamAnnexe3", {font = "Roboto", extended = false, size = 20, weight = 600})
surface.CreateFont("HeliCamAnnexe4", {font = "Arial", extended = false, size = 16, weight = 600})

local function StartScan()
    if IsValid(entVis) and entVis:IsVehicle() then
        if entVis == lastScannedVehicle then return end

        scanning = true
        scanComplete = false
        lastScannedVehicle = entVis
        surface.PlaySound("ambient/levels/labs/electric_explosion1.wav")

        timer.Simple(3, function()
            scanning = false
            scanComplete = true
            surface.PlaySound("ambient/levels/labs/electric_explosion1.wav")
        end)
    end
end

-- Zoom and unzoom the camera
local function HandleZoom()
    local zoomChanged = false

    if input.IsKeyDown(KEY_PAD_PLUS) and zoom < zoomMax then
        zoom = zoom + zoomSpeed
        if !zoomSound then
            surface.PlaySound("helicam/move-start.wav")
            zoomSound = CreateSound(LocalPlayer(), "helicam/rotating.wav")
            zoomSound:Play()
        end
        zoomChanged = true
    elseif input.IsKeyDown(KEY_PAD_MINUS) and zoom > zoomMin then
        zoom = zoom - zoomSpeed
        if !zoomSound then
            surface.PlaySound("helicam/move-stop.wav")
            zoomSound = CreateSound(LocalPlayer(), "helicam/rotating.wav")
            zoomSound:Play()
        end
        zoomChanged = true
    else
        if zoomSound then
            zoomSound:Stop()
            zoomSound = nil
        end
    end

    if zoomChanged then
        print("Zoom : " .. zoom)
    end
end

-- Horizontal rotation of the camera
local function HandleRotation()
    local rotChanged = false
    local adjustedRotSpeed = rotSpeed * (1 - zoom / zoomMax * (1 - minSpeedFactor))

    if input.IsKeyDown(KEY_PAD_6) then
        rot = rot - adjustedRotSpeed
        if rot < 0 then rot = 360 end
        if !rotateSoundH then
            rotateSoundH = CreateSound(LocalPlayer(), "helicam/rotating.wav")
            rotateSoundH:Play()
        end
        rotChanged = true
    elseif input.IsKeyDown(KEY_PAD_4) then
        rot = rot + adjustedRotSpeed
        if rot > 360 then rot = 0 end
        if !rotateSoundH then
            rotateSoundH = CreateSound(LocalPlayer(), "helicam/rotating.wav")
            rotateSoundH:Play()
        end
        rotChanged = true
    else
        if rotateSoundH then
            rotateSoundH:Stop()
            rotateSoundH = nil
        end
    end

    if rotChanged then
        print("Rotation : " .. rot)
    end
end

-- Vertical rotation of the camera
local function HandleVerticalMovement()
    local rotVChanged = false
    local adjustedRotVSpeed = rotSpeed * (1 - zoom / zoomMax * (1 - minSpeedFactor))

    if input.IsKeyDown(KEY_PAD_2) and rotV < rotVMax then
        rotV = rotV + adjustedRotVSpeed
        if !rotateSoundV then
            rotateSoundV = CreateSound(LocalPlayer(), "helicam/rotating.wav")
            rotateSoundV:Play()
        end
        rotVChanged = true
    elseif input.IsKeyDown(KEY_PAD_8) and rotV > rotVMin then
        rotV = rotV - adjustedRotVSpeed
        if !rotateSoundV then
            rotateSoundV = CreateSound(LocalPlayer(), "helicam/rotating.wav")
            rotateSoundV:Play()
        end
        rotVChanged = true
    else
        if rotateSoundV then
            rotateSoundV:Stop()
            rotateSoundV = nil
        end
    end

    if rotVChanged then
        print("Rotation verticale : " .. rotV)
    end
end

local function DrawVehicleInfo(veh)
    if helicam and IsValid(veh) and veh:IsVehicle() then
        local ply = LocalPlayer()
        local vehClass = veh:GetVehicleClass()
        local vehName = list.Get("Vehicles")[vehClass].Name or "Unknown"
        local vehSpeed = math.Round(veh:GetVelocity():Length() * 0.0568182)
        local lastPlateRequest = 0
        local plateRequestCooldown = 3 -- délai en secondes entre les requêtes (anti-spam)

        if CurTime() - lastPlateRequest > plateRequestCooldown then
            net.Start("RequestVehiclePlate")
            net.WriteEntity(ply)
            net.WriteEntity(veh)
            net.SendToServer()
            lastPlateRequest = CurTime()
        end

        draw.SimpleTextOutlined("Modèle: " .. vehName, "HeliCamAnnexe2", ScrW() / 2 - 75, ScrH() - 80, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
        draw.SimpleTextOutlined("Vitesse: " .. vehSpeed .. " MPH", "HeliCamAnnexe2", ScrW() / 2 - 75, ScrH() - 50, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
        draw.SimpleTextOutlined("Plaque: " .. plate, "HeliCamAnnexe2", ScrW() / 2 - 75, ScrH() - 20, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
    end
end

local function DrawDirection()
    local heliAngles = LocalPlayer():GetAngles()
    local direction = GetDirection(heliAngles.y)

    local heliPos = LocalPlayer():GetPos()
    local gpsCoordinates = math.floor(heliPos.x) .. ", " .. math.floor(heliPos.y) .. ", " .. math.floor(heliPos.z)

    surface.SetFont("HeliCamAnnexe3")
    surface.SetTextColor(255, 255, 255)
    surface.SetTextPos(ScrW() - 300, ScrH() - 70)
    surface.DrawText("Direction: " .. direction)

    surface.SetTextPos(ScrW() - 300, ScrH() - 45)
    surface.DrawText("GPS: " .. gpsCoordinates)
end

local function GetInput()
    HandleZoom()
    HandleRotation()
    HandleVerticalMovement()
end

local function ToggleHeliCam(ply)
    helicam = !helicam
    if helicam then
        RunConsoleCommand("cl_drawhud", "0") -- Disable default HUD
        local heli = ply:GetVehicle():GetParent()
        hook.Add("HUDPaint", "DrawHeliCam", function()
            if helicam then
                GetInput()
                local screenW, screenH = ScrW(), ScrH()

                local BandeauHeight = 100
                local BandeauWidth = ScrW()

                surface.SetDrawColor(0, 0, 0, 240)
                surface.DrawRect(0, screenH - BandeauHeight, BandeauWidth, BandeauHeight)
                surface.DrawRect(0, 0, BandeauWidth, BandeauHeight * 0.6)

                local textX = BandeauWidth - 30
                local textY = 75

                draw.SimpleText("D.C.S.O.", "HeliCamLogo", textX, textY, Color(225, 225, 225, 155), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                draw.SimpleText("DAVIDSON COUNTY", "HeliCamLegend", textX - 12, textY + 66, Color(225, 225, 225, 155), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                surface.SetDrawColor(255, 255, 255, 155)
                surface.DrawRect(textX - 240, textY + 140, 240, 3)
                surface.DrawRect(textX - 240, textY + 125, 3, 15)
                surface.DrawRect(textX - 3, textY + 125, 3, 15)
                surface.DrawRect(textX - 120, textY + 130, 3, 10)

                surface.SetDrawColor(255, 255, 255, 155)
                local points = {
                    {x = textX - 248 + zoom * 3.25, y = textY + 111},
                    {x = textX - 228 + zoom * 3.25, y = textY + 111},
                    {x = textX - 238 + zoom * 3.25, y = textY + 121}
                }
                surface.DrawPoly(points)

                draw.SimpleText("x", "MiddleCross", screenW / 2, screenH / 2, Color(225, 225, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(255, 255, 255, 155)
                surface.DrawRect(screenW / 2 - 260, screenH / 2, 160, 2)
                surface.DrawRect(screenW / 2 + 100, screenH / 2, 160, 2)
                surface.DrawRect(screenW / 2 - 263, screenH / 2 - 6, 3, 14)
                surface.DrawRect(screenW / 2 + 260, screenH / 2 - 6, 3, 14)
                surface.DrawRect(screenW / 2, screenH / 2 - 160, 2, 100)
                surface.DrawRect(screenW / 2, screenH / 2 + 70, 2, 100)
                surface.DrawRect(screenW / 2 - 6, screenH / 2 - 163, 14, 3)
                surface.DrawRect(screenW / 2 - 6, screenH / 2 + 170, 14, 3)
                surface.DrawRect(screenW / 2 - 206, screenH / 2 - 135, 24, 2)
                surface.DrawRect(screenW / 2 - 206, screenH / 2 - 135, 2, 14)
                surface.DrawRect(screenW / 2 + 182, screenH / 2 - 135, 24, 2)
                surface.DrawRect(screenW / 2 + 204, screenH / 2 - 135, 2, 14)
                surface.DrawRect(screenW / 2 - 206, screenH / 2 + 140, 24, 2)
                surface.DrawRect(screenW / 2 - 206, screenH / 2 + 127, 2, 14)
                surface.DrawRect(screenW / 2 + 182, screenH / 2 + 140, 24, 2)
                surface.DrawRect(screenW / 2 + 204, screenH / 2 + 127, 2, 14)

                draw.SimpleText(os.date("%d/%m/%y"), "HeliCamAnnexe3", 30, textY - 74, Color(225, 225, 225, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(os.date("%H:%M:%S"), "HeliCamAnnexe3", 30, textY - 55, Color(225, 225, 225, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText("UTC " .. os.date("%z"), "HeliCamAnnexe3", 30, textY - 36, Color(225, 225, 225, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                surface.SetDrawColor(225, 225, 225, 50)
                surface.DrawRect(screenW / 2 - 246, 4, 92, 47)
                surface.SetDrawColor(225, 225, 225, 50)
                surface.DrawRect(screenW / 2 - 46, 4, 92, 47)
                surface.SetDrawColor(225, 225, 225, 50)
                surface.DrawRect(screenW / 2 + 164, 4, 92, 47)

                surface.SetDrawColor(0, 0, 0, 255)
                surface.DrawRect(screenW / 2 - 245, 5, 90, 45)
                draw.SimpleText("LOCK", "HeliCamAnnexe", screenW / 2 - 231, 10, Color(150, 0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                surface.SetDrawColor(150, 0, 0, 255)
                surface.DrawRect(screenW / 2 - 224, 40, 45, 3)

                if flirMode then
                    surface.SetDrawColor(0, 0, 0, 255)
                    surface.DrawRect(screenW / 2 - 45, 5, 90, 45)
                    draw.SimpleText("FLIR", "HeliCamAnnexe", screenW / 2 - 26, 10, Color(0, 200, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    surface.SetDrawColor(0, 200, 0, 255)
                    surface.DrawRect(screenW / 2 - 23, 40, 45, 3)
                else
                    surface.SetDrawColor(0, 0, 0, 255)
                    surface.DrawRect(screenW / 2 - 45, 5, 90, 45)
                    draw.SimpleText("FLIR", "HeliCamAnnexe", screenW / 2 - 26, 10, Color(150, 0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    surface.SetDrawColor(150, 0, 0, 255)
                    surface.DrawRect(screenW / 2 - 23, 40, 45, 3)
                end

                surface.SetDrawColor(0, 0, 0, 255)
                surface.DrawRect(screenW / 2 + 165, 5, 90, 45)
                draw.SimpleText("SPTL", "HeliCamAnnexe", screenW / 2 + 182, 10, Color(0, 200, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                surface.SetDrawColor(0, 200, 0, 255)
                surface.DrawRect(screenW / 2 + 186, 40, 45, 3)

                surface.SetDrawColor(225, 225, 225, 255)
                surface.DrawRect(screenW / 2 - 150, screenH / 2 + 350, 300, 3)

                DrawDirection()

                if scanning then
                    draw.SimpleText("SCAN EN COURS . . .", "HeliCamAnnexe", screenW / 2, screenH / 2 + 300, Color(225, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                elseif scanComplete and IsValid(lastScannedVehicle) then
                    DrawVehicleInfo(lastScannedVehicle)
                end

                surface.SetDrawColor(155, 0, 0, 255)
                surface.DrawRect(16, screenH - 37, 250, 3)
                draw.SimpleText("AI COMMUNICATION SYSTEM", "HeliCamAnnexe", 180, screenH - 80, Color(155, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                draw.SimpleText("OFF", "HeliCamAnnexe", 300, screenH - 50, Color(155, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end)

        hook.Add("CalcView", "HeliCamView", function(ply, pos, angles, fov)
            print("CalcView Hook Triggered")
            if helicam then
                print("Helicam is active")
                local view = {}
                view.origin = heli:GetPos() + Vector(0, 0, 100)
                view.angles = Angle(0, heli:GetAngles().y + rot, 0) + Angle(rotV, 0, 0)
                view.fov = fov - zoom

                local tr = util.TraceLine({
                    start = view.origin,
                    endpos = view.origin + view.angles:Forward() * 100000,
                    filter = {ply, heli},
                    mask = MASK_SHOT_HULL
                })
                entVis = tr.Entity

                if IsValid(entVis) and entVis:IsVehicle() and not scanning then
                    StartScan()
                end

                return view
            end
        end)
    else
        RunConsoleCommand("cl_drawhud", "1")
        hook.Remove("HUDPaint", "DrawHeliCam")
        hook.Remove("CalcView", "HeliCamView")
    end
end

net.Receive("SendLicensePlate", function(len)
    plate = net.ReadString()
end)

/*
hook.Add("Think", "CheckHelicamExit", function()
    local ply = LocalPlayer()
    if helicam and !ply:InVehicle() then
        ToggleHeliCam(ply)
    end
end)
*/

concommand.Add("lvs_helicam", function(ply)
    if IsInHeli(ply) then
        ToggleHeliCam(ply)
    end
end)

/*
hook.Add("PlayerButtonDown", "ToggleFLIR", function(ply, key)
    if key == KEY_F then
        flirMode = !flirMode
        if flirMode then
            RunConsoleCommand("thermal_vision")
        else
            RunConsoleCommand("thermal_vision")
        end
    end
end)
*/