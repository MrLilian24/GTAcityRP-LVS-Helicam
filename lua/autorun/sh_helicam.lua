-- sh_helicam.lua - Shared
-- Created by Rémi.L (https://steamcommunity.com/id/lilian24)

function GetDirection(angle)
    local directions = {
        {0, "N ↑"},
        {45, "NE ↗"},
        {90, "E →"},
        {135, "SE ↘"},
        {180, "S ↓"},
        {-135, "SW ↙"},
        {-90, "W ←"},
        {-45, "NW ↖"}
    }

    for _, dir in ipairs(directions) do
        if math.abs(angle - dir[1]) <= 22.5 then
            return dir[2]
        end
    end

    return ""
end

function RotatePoint(x, y, centerX, centerY, angle)
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

function IsInHeli(ply)
    return ply and ply:GetVehicle():GetParent().Base:find("lvs_base")
end
