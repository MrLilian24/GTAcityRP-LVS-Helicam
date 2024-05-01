-- sh_helicam.lua - Shared
-- Created by Rémi.L (https://steamcommunity.com/id/lilian24)

local PLUGIN = PLUGIN or {}
local PLATE = LL_PLATES_SYSTEM or {}

local helicam = false

local entVis = nil

local plate = "Unknown"

-- Zoom de la caméra
local zoom = 0
local zoomMax = 100
local zoomMin = 0
local zoomSpeed = 0.1

-- Rotation de la caméra
local rot = 0
local rotSpeed = 0.1

-- Déplacement de la caméra
local rotV = 0
local rotVMax = 100
local rotVMin = -100
local rotSpeed = 0.1

surface.CreateFont( "HeliCamLogo", {
	font = "Arial",
	extended = false,
	size = 72,
	weight = 1200,
} )

surface.CreateFont( "HeliCamLegend", {
	font = "Arial",
	extended = false,
	size = 28,
	weight = 1200,
} )

surface.CreateFont( "MiddleCross", {
	font = "CenterPrintText",
	extended = false,
	size = 40,
	weight = 600,
} )

surface.CreateFont( "HeliCamAnnexe", {
	font = "DermaDefault",
	extended = false,
	size = 28,
	weight = 600,
} )

surface.CreateFont( "HeliCamAnnexe2", {
	font = "DermaDefault",
	extended = false,
	size = 24,
	weight = 600,
} )

surface.CreateFont( "HeliCamAnnexe3", {
	font = "Roboto",
	extended = false,
	size = 20,
	weight = 600,
} )

surface.CreateFont( "HeliCamAnnexe4", {
	font = "Arial",
	extended = false,
	size = 16,
	weight = 600,
} )

-- Découpage de l'écran en sections pour le HUD
--! MODIFIED
local upperBandeauPos = 0
local upperBandeauHeight = 100
local lowerBandeauPos = ScrH() - 100
local lowerBandeauHeight = 100

-- Fonction pour le zoom de la caméra
--! MODIFIED
local function ZoomCam()
	if helicam then
		local zoomChanged = false

		if input.IsKeyDown(KEY_PAD_PLUS) and zoom < zoomMax then
			zoom = zoom + zoomSpeed
			zoomChanged = true
		end

		if input.IsKeyDown(KEY_PAD_MINUS) and zoom > zoomMin then
			zoom = zoom - zoomSpeed
			zoomChanged = true
		end

		-- Débug
		if zoomChanged then
			print("Zoom : " .. zoom)
		end
	end
end


-- Fonction pour la rotation de la caméra
--! MODIFIED
local function RotCam()
	if helicam then
		local rotChanged = false

		if input.IsKeyDown(KEY_PAD_6) then
			rot = rot - rotSpeed
			rotChanged = true
		end

		if input.IsKeyDown(KEY_PAD_4) then
			rot = rot + rotSpeed
			rotChanged = true
		end

		-- Débug
		if rotChanged then
			print("Rotation : " .. rot)
		end
	end
end


-- Fonction pour le déplacement de la caméra
--! MODIFIED
local function PosCam()
	if helicam then
		local rotVChanged = false

		if input.IsKeyDown(KEY_PAD_2) and rotV < rotVMax then
			rotV = rotV + rotSpeed
			rotVChanged = true
		end

		if input.IsKeyDown(KEY_PAD_8) and rotV > rotVMin then
			rotV = rotV - rotSpeed
			rotVChanged = true
		end

		-- Débug
		if rotVChanged then
			print("Rotation verticale : " .. rotV)
		end
	end
end


net.Receive("SendLicensePlate", function(len)
	plate = net.ReadString()
end)

-- Affiche le informations du véhicule (Nom, vitesse et plaque)
--! MODIFIED
local function DrawVehicleInfo()
	if helicam and entVis:IsVehicle() then
		local veh = entVis
		local ply = LocalPlayer()
		local vehClass = veh:GetVehicleClass()
		local vehName = list.Get("Vehicles")[vehClass].Name
		local vehSpeed = math.Round(veh:GetVelocity():Length() * 0.0568182)

		-- Appeler la fonction GetLicensePlate avec le joueur, le véhicule et la fonction de rappel
		--TODO Limiter le nombre d'appels
		net.Start("RequestVehiclePlate")
        net.WriteEntity(ply)
        net.WriteEntity(veh)
        net.SendToServer()

		draw.SimpleTextOutlined("Modèle: " .. vehName, "HeliCamAnnexe2", ScrW() / 2 - 75, ScrH() - 80, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
		draw.SimpleTextOutlined("Vitesse: " .. vehSpeed .. " MPH", "HeliCamAnnexe2", ScrW() / 2 - 75, ScrH() - 50, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
		draw.SimpleTextOutlined("Plaque: " .. plate, "HeliCamAnnexe2", ScrW() / 2 - 75, ScrH() - 20, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 255))
	end
end


-- Getter de la direction de l'hélicoptère
local function GetDirection(angle)
    local directions = {
        {22.5, "N ↑"},
        {67.5, "NE ↗"},
        {112.5, "E →"},
        {157.5, "SE ↘"},
        {-157.5, "S ↓"},
        {-112.5, "SW ↙"},
        {-67.5, "W ←"},
        {-22.5, "NW ↖"}
    }

    for _, dir in ipairs(directions) do
        if angle >= dir[1] or angle <= -dir[1] then
            return dir[2]
        end
    end

    return ""
end

-- Fonction qui affiche la direction de l'hélicoptère et ses coordonnées GPS
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

local function RotatePoint(x, y, centerX, centerY, angle)
    local radians = math.rad(angle)
    local cosTheta = math.cos(radians)
    local sinTheta = math.sin(radians)

    local translatedX = x - centerX
    local translatedY = y - centerY

    local rotatedX = translatedX * cosTheta - translatedY * sinTheta
    local rotatedY = translatedX * sinTheta + translatedY * cosTheta

    local finalX = rotatedX + centerX
    local finalY = rotatedY + centerY

    return finalX, finalY
end

local function ToggleHeliCam()
    helicam = !helicam
    if helicam then
        RunConsoleCommand("cl_drawhud", "0") -- Désactive le HUD de base
    else
        RunConsoleCommand("cl_drawhud", "1") -- Réactive le HUD de base
    end
end

local function IsInHeli(ply)
    return ply and ply:GetVehicle():GetParent().Base:find("lvs_base")
end

local function GetInput()
	ZoomCam()
	RotCam()
	PosCam()
end

concommand.Add("lvs_helicam", function(ply)
	if IsInHeli(ply) then
		local heli = ply:GetVehicle():GetParent()
		ToggleHeliCam()


		hook.Add("HUDPaint", "DrawHeliCam", function()
			if (helicam) then
				GetInput()

				local screenW, screenH = ScrW(), ScrH() -- Prendre la résolution de l'écran

				-- Changer la position de la caméra du joueur (ply) avec CalcView
				hook.Add("CalcView", "HeliCamView", function(ply, pos, angles, fov)
					if (helicam) then
						local view = {}
						view.origin = heli:GetPos() + Vector(-200.4,9.67,-7.14) -- Position de la caméra
						-- Calculer la rotation de la caméra (horizontale rot et verticale pos)
						view.angles = Angle(0, heli:GetAngles().y + rot, 0) + Angle(rotV, 0, 0)
						-- Calculer le zoom de la caméra
						view.fov = fov - zoom

						-- Récupération des entités visées par la caméra
						local tr = util.TraceLine({
							start = view.origin,
							endpos = view.origin + view.angles:Forward() * 10000,
							filter = ply,
							mask = MASK_SHOT_HULL
						})
						entVis = tr.Entity

						return view
					end
				end)
						

				local BandeauHeight = 100 -- Hauteur du bandeau
				local BandeauWidth = ScrW() -- Largeur du bandeau
							
				surface.SetDrawColor(0, 0, 0, 240) -- Couleur du bandeau (Noir transparant)
				surface.DrawRect(0, screenH - BandeauHeight, BandeauWidth, BandeauHeight) -- Dessiner le bandeau du haut
				surface.DrawRect( 0, 0, BandeauWidth, BandeauHeight*0.6) -- Dessiner le bandeau du bas


				-- Position et la taille du texte
				local textX = BandeauWidth - 30
				local textY = 75


				-- Texte en haut à droite (sous le bandeau supérieur)
				draw.SimpleText("D.C.S.O.", "HeliCamLogo", textX, textY, Color(225, 225, 225, 155), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
				draw.SimpleText("DAVIDSON COUNTY", "HeliCamLegend", textX-12, textY+66, Color(225, 225, 225, 155), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
				-- Jauge de zoom sous le texte
				surface.SetDrawColor(255, 255, 255, 155)
				surface.DrawRect(textX-240, textY+140, 240, 3)
				surface.DrawRect(textX-240, textY+125, 3, 15)
				surface.DrawRect(textX-3, textY+125, 3, 15)
				surface.DrawRect(textX-120, textY+130, 3, 10)

				-- Triangle de zoom à gauche DrawPoly à bouger en fonction du zoom
				surface.SetDrawColor(255, 255, 255, 155)
				local points = {
					{x = textX-248 + zoom*2.4, y = textY+111},
					{x = textX-228 + zoom*2.4, y = textY+111},
					{x = textX-238 + zoom*2.4, y = textY+121}
				}
				surface.DrawPoly(points)

				--TODO Optimiser tout ça avec des images et des textures
				-- ### Cadre au centre de l'écran ###
				draw.SimpleText("x", "MiddleCross", screenW/2, screenH/2, Color(225, 225, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				-- Barre horizontale à gauche et à droite de la croix
				surface.SetDrawColor(255, 255, 255, 155)
				surface.DrawRect(screenW/2-260, screenH/2, 160, 2)
				surface.DrawRect(screenW/2+100, screenH/2, 160, 2)
				-- Petites Barres verticales sur les extrémités des barres horizontales
				surface.DrawRect(screenW/2-263, screenH/2-6, 3, 14)
				surface.DrawRect(screenW/2+260, screenH/2-6, 3, 14)

				-- Barre verticale au dessus et en dessous de la croix
				surface.DrawRect(screenW/2, screenH/2-160, 2, 100)
				surface.DrawRect(screenW/2, screenH/2+70, 2, 100)
				-- Petites Barres horizontales sur les extrémités des barres verticales
				surface.DrawRect(screenW/2-6, screenH/2-163, 14, 3)
				surface.DrawRect(screenW/2-6, screenH/2+170, 14, 3)

				-- Coin en haut à gauche
				surface.DrawRect(screenW/2-206, screenH/2-135, 24, 2)
				surface.DrawRect(screenW/2-206, screenH/2-135, 2, 14)
				-- Coin en haut à droite
				surface.DrawRect(screenW/2+182, screenH/2-135, 24, 2)
				surface.DrawRect(screenW/2+204, screenH/2-135, 2, 14)
				-- Coin en bas à gauche
				surface.DrawRect(screenW/2-206, screenH/2+140, 24, 2)
				surface.DrawRect(screenW/2-206, screenH/2+127, 2, 14)
				-- Coin en bas à droite
				surface.DrawRect(screenW/2+182, screenH/2+140, 24, 2)
				surface.DrawRect(screenW/2+204, screenH/2+127, 2, 14)


				-- Texte en haut à gauche (sous le bandeau supérieur) avec la date du jour (jj/mm/aa), l'heure en dessous et le fuseau horaire du joueur en dessous
				draw.SimpleText(os.date("%d/%m/%y"), "HeliCamAnnexe3", 30, textY-74, Color(225, 225, 225, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText(os.date("%H:%M:%S"), "HeliCamAnnexe3", 30, textY-55, Color(225, 225, 225, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("UTC "..os.date("%z"), "HeliCamAnnexe3", 30, textY-36, Color(225, 225, 225, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			
				-- En suite par dessus le bandeau supérieur, on affiche 3 rectangles un à côté de l'autre
				-- Derrière chaque rectangle, on affiche un petit rectangle blanc
				surface.SetDrawColor(225, 225, 225, 50)
				surface.DrawRect(screenW/2-246, 4, 92, 47)
				
				surface.SetDrawColor(225, 225, 225, 50)
				surface.DrawRect(screenW/2-46, 4, 92, 47)

				surface.SetDrawColor(225, 225, 225, 50)
				surface.DrawRect(screenW/2+164, 4, 92, 47)

				-- Le premier rectangle est le rectangle de gauche, il contient le texte LOCK
				surface.SetDrawColor(0, 0, 0, 255)
				surface.DrawRect(screenW/2-245, 5, 90, 45)
				draw.SimpleText("LOCK", "HeliCamAnnexe", screenW/2-231, 10, Color(0, 200, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				-- Petite barre en dessous du texte de 50 pixels de long
				surface.SetDrawColor(0, 200, 0, 255)
				surface.DrawRect(screenW/2-224, 40, 45, 3)

				-- Le deuxième rectangle est le rectangle du milieu, il contient le texte FLIR
				surface.SetDrawColor(0, 0, 0, 255)
				surface.DrawRect(screenW/2-45, 5, 90, 45)
				draw.SimpleText("FLIR", "HeliCamAnnexe", screenW/2-26, 10, Color(150, 0, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				-- Petite barre en dessous du texte de 50 pixels de long
				surface.SetDrawColor(150, 0, 0, 255)
				surface.DrawRect(screenW/2-23, 40, 45, 3)

				-- Le troisième rectangle est le rectangle de droite, il contient le texte SPTL
				surface.SetDrawColor(0, 0, 0, 255)
				surface.DrawRect(screenW/2+165, 5, 90, 45)
				draw.SimpleText("SPTL", "HeliCamAnnexe", screenW/2+182, 10, Color(0, 200, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				-- Petite barre en dessous du texte de 50 pixels de long
				surface.SetDrawColor(0, 200, 0, 255)
				surface.DrawRect(screenW/2+186, 40, 45, 3)

				-- Ensuite on affiche une barre en dessous du centre de l'écran de 200 pixels de long
				surface.SetDrawColor(225, 225, 225, 255)
				surface.DrawRect(screenW/2-150, screenH/2+350, 300, 3)
				-- Avec marqué au dessus "Scan en cours" en rouge
				draw.SimpleText("SCAN EN COURS . . .", "HeliCamAnnexe", screenW/2, screenH/2+300, Color(225, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			
				entVis = LocalPlayer():GetEyeTrace().Entity
				-- Ensuite au dessus du bandeau inférieur, on affiche le nom du véhicule, la plaque et la vitesse (en MPH)
				if entVis:IsVehicle() then
					DrawVehicleInfo()
				end

				-- AI communication system
				surface.SetDrawColor(155, 0, 0, 255)
				surface.DrawRect(16, screenH-37, 250, 3)
				draw.SimpleText("AI COMMUNICATION SYSTEM", "HeliCamAnnexe", 180, screenH-80, Color(155, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				draw.SimpleText("OFF", "HeliCamAnnexe", 300, screenH-50, Color(155, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			

			end
		end)
    end
end)