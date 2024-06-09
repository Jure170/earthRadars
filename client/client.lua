ESX = exports["es_extended"]:getSharedObject()
local RadarBlips = {}
local Objects = {}
local default = {
    ime = "",
    kordinate = {pos = vector3(0.0, 0.0, 0.0), heading = 0.0},
    model = "",
    maxSpeed = "",
}

Citizen.CreateThread(function()
    Wait(200)
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

AddEventHandler("onResourceStop", function(res)
  if GetCurrentResourceName() == res then
    for i = 1, #Objects do
      DeleteObject(Objects[i])
    end
  end
end)

RegisterCommand('radars', function()
    ESX.TriggerServerCallback('radari:isPolice', function(isPolice)
        if isPolice and PlayerData.job.grade >= 4 then
            openRadarMenu()
        else
            ESX.ShowNotification('You do not have access')
        end
    end)
end)

function openRadarMenu()
    lib.registerContext({
        id = 'radar_menu',
        title = 'Radars Menu',
        options = {
            {
                title = 'Current Radars',
                description = 'Display current radars',
                icon = 'fa-solid fa-map-marker-alt',
                onSelect = function()
                    showCurrentRadars()
                end
            },
            {
                title = 'Set Radar',
                description = 'Set a new radar',                
                icon = 'fa-solid fa-plus',
                onSelect = function()
                    placeRadar()
                end
            }
        }
    })
    lib.showContext('radar_menu')
end

function showCurrentRadars()
    ESX.TriggerServerCallback("earth:getajRadare", function(ucitano)
        local options = {}
        if ucitano == nil or #ucitano == 0  then
            table.insert(options, {
                title = 'No Radars',
                description = 'There are currently no radars set.',
            })
        else
            for k, v in pairs(ucitano) do
                table.insert(options, {
                    title = "Radar: " .. v.ime,
                    description = "Max speed: " .. v.maxSpeed .. "km/h\nPress if you want to delete it",
                    onSelect = function()
                        deleteRadar(v.ime)
                    end,
                })
            end
        end

        lib.registerContext({
            id = 'radarss',
            title = 'List Radars',
            options = options
        })
        lib.showContext('radarss')
    end)
end

function placeRadar()
    local input = lib.inputDialog('Set Radar', {
        {type = 'input', label = 'Radar Name', description = 'Enter the radar name', required = true},
        {type = 'number', label = 'Speed Limit (km/h)', description = 'Enter the speed limit', required = true}
    })    
    if not input then return end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local pos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)
    local heading = GetEntityHeading(playerPed)
    default.ime = input[1]
    default.kordinate = vector3(pos.x, pos.y, pos.z)
    default.heading = heading
    default.model = "prop_cctv_pole_01a"
    default.maxSpeed = input[2]
   -- StvoriRadar(default.ime .. "_radar", default.kordinate, default.heading, default.model)
  --  createRadarBlip(default.kordinate, default.ime, default.maxSpeed)
    ESX.TriggerServerCallback("earth:sacuvajRadar", function()
    end, default)
    ESX.TriggerServerCallback("earth:getajRadare", function(ucitano)
        for k,v in pairs(ucitano) do
            StvoriRadar(v.ime .. "_radar", v.kordinate, v.heading, v.model)
            createRadarBlip(v.kordinate, v.ime, v.maxSpeed)
        end
    end)
end

function StvoriRadar(pedName, pos, heading, pedType)
    prposspawn = CreateObject(pedType, vector3(pos.x, pos.y, pos.z -1), false, true)
    SetEntityHeading(prposspawn, heading)
    FreezeEntityPosition(prposspawn, true) 
    SetEntityInvincible(prposspawn, true)
    PlaceObjectOnGroundProperly(prposspawn)
    table.insert(Objects, prposspawn)
    SetModelAsNoLongerNeeded(pedType)
end

function createRadarBlip(kordinatice, imenjega, kolikojespeed)
    local blip = AddBlipForCoord(kordinatice.x, kordinatice.y, kordinatice.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 0.75)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Radar - " .. imenjega .. "(" .. kolikojespeed .. "km/h)")
    EndTextCommandSetBlipName(blip)
    RadarBlips[imenjega] = blip
end

function deleteRadarBlip(imenjega)
    local blip = RadarBlips[imenjega]
    if blip then
        RemoveBlip(blip)
        RadarBlips[imenjega] = nil
    end
end

Citizen.CreateThread(function()
    Wait(200)
    ESX.TriggerServerCallback("earth:getajRadare", function(ucitano)
        for k,v in pairs(ucitano) do
            StvoriRadar(v.ime .. "_radar", v.kordinate, v.heading, v.model)
            createRadarBlip(v.kordinate, v.ime, v.maxSpeed)
--[[
            exports.qtarget:RemoveZone("Radar - " .. v.ime)
            exports.qtarget:AddBoxZone("Radar - " .. v.ime, v.kordinate, 3.4, 3.4, {
                name = "Radar - " .. v.ime,
                heading = v.heading,
                debugPoly = false,
                minZ =  v.kordinate.z - 2,
                maxZ =  v.kordinate.z,
                }, 
                {
                options = {
                {
                    action = function()
                        editradar()
                    end,
                    icon = "fas fa-circle",
                    label = "Manage Radar",
                },
                },
                job = "police",
                distance = 2.0
            })]]
        end
    end)
end)

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        ESX.TriggerServerCallback("earth:getajRadare", function(ucitano)
            for k,v in pairs(ucitano) do
                local player = PlayerPedId()
                local coords = GetEntityCoords(player, true)
                local distance = #(coords - vector3(v.kordinate.x, v.kordinate.y, v.kordinate.z))
                if distance < 20.0 then
                    if PlayerData.job ~= nil and not (PlayerData.job.name == 'police' or PlayerData.job.name == 'ambulance') then
                        checkSpeed(v.maxSpeed)
                    end
                end
            end
        end)
    end
end)



function checkSpeed(brziniakastm)
    local pP = PlayerPedId()
    local speed = GetEntitySpeed(pP)
    local vehicle = GetVehiclePedIsIn(pP, false)
    local driver = GetPedInVehicleSeat(vehicle, -1)
    local plate = GetVehicleNumberPlateText(vehicle)
    local maxspeed = brziniakastm
    local mphspeed = math.ceil(speed*2.236936)
    local fineamount = nil
    local finelevel = nil
    local truespeed = mphspeed
    
    if mphspeed > maxspeed and driver == pP then
        Citizen.Wait(250)
        TriggerServerEvent('fineAmount', mphspeed, maxspeed)
    end
end

--[[
function editradar()
    ESX.TriggerServerCallback("earth:getajRadare", function(ucitano)
        for k,v in pairs(ucitano) do
            lib.registerContext({
                id = 'edit_menu',
                title = 'Radar Meni',
                options = {
                    {
                        title = 'Obrisi radar',
                        description = 'Obrisi radar',
                        icon = 'fa-solid fa-map-marker-alt',
                        onSelect = function()
                            obrisiGa(v.ime)
                        end
                    },
                }
            })
            lib.showContext('edit_menu')
        end
    end)
end

function obrisiGa(radarName)
    ESX.TriggerServerCallback("earth:obrisiRadar", function(success)
        if success then
            -- Pretpostavimo da su objekti povezani s radarom po imenu
            for i = 1, #Objects do
                DeleteObject(Objects[i])
            end

            ESX.TriggerServerCallback("earth:getajRadare", function(ucitano)
                for k,v in pairs(ucitano) do
                    StvoriRadar(v.ime .. "_radar", v.kordinate, v.heading, v.model)
                    createRadarBlip(v.kordinate, v.ime, v.maxSpeed)
        
                    exports.qtarget:RemoveZone("Radar - " .. v.ime)
                    exports.qtarget:AddBoxZone("Radar - " .. v.ime, v.kordinate, 3.4, 3.4, {
                        name = "Radar - " .. v.ime,
                        heading = v.heading,
                        debugPoly = false,
                        minZ =  v.kordinate.z - 2,
                        maxZ =  v.kordinate.z,
                        }, 
                        {
                        options = {
                        {
                            action = function()
                                editradar()
                            end,
                            icon = "fas fa-circle",
                            label = "Upravljaj Radarom",
                        },
                        },
                        job = "police",
                        distance = 2.0
                    })
                end
            end)
        end
    end, radarName)
end
]]


function deleteRadar(radarName)
    ESX.TriggerServerCallback("earth:obrisiRadar", function(success)
        if success then
            for i = 1, #Objects do
                DeleteObject(Objects[i])
            end
            deleteRadarBlip(radarName)
            ESX.TriggerServerCallback("earth:getajRadare", function(ucitano)
                for k,v in pairs(ucitano) do
                    StvoriRadar(v.ime .. "_radar", v.kordinate, v.heading, v.model)
                    createRadarBlip(v.kordinate, v.ime, v.maxSpeed)
                end
            end)
        end
    end, radarName)
end