
ESX = exports["es_extended"]:getSharedObject()
local Radari = {}

function LoadRadari()
    local ucitaj = LoadResourceFile(GetCurrentResourceName(), "/json/radars.json")
    if ucitaj then
        Radari = json.decode(ucitaj)
    else
        print("^4[earthRadars]:^0 Not available radars")
        Radari = {}
    end
end

function SaveJobs()
    SaveResourceFile(GetCurrentResourceName(), "/json/radars.json", json.encode(Radari, {indent = true}), -1)
end

function getajRadare()
    local ucitaj = LoadResourceFile(GetCurrentResourceName(), "/json/radars.json")
    local druga = {}
    if ucitaj then
        druga = json.decode(ucitaj)
        return druga
    else
        print("^4[earthRadars]:^0 No radars data")
        return {}
    end
end

ESX.RegisterServerCallback('earth:getajRadare', function(source, cb)
    local radarikastm = getajRadare()
    cb(radarikastm)
end)


AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadRadari()
        print("^4[earthRadars]:^0 Successfully loaded")
    end
end)

ESX.RegisterServerCallback('radari:isPolice', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.job.name == 'police' then
        cb(true)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('earth:sacuvajRadar', function(source, cb, datainfo)
    local igrac = ESX.GetPlayerFromId(source)
	table.insert(Radari, datainfo)
	SaveJobs()
end)


RegisterServerEvent('fineAmount')
AddEventHandler('fineAmount', function(mphspeed, maxspeed)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        local fineAmount = (mphspeed - maxspeed) * 10
        xPlayer.removeAccountMoney('bank', fineAmount)
        TriggerClientEvent('esx:showNotification', src, 'Speeding fine: $' .. fineAmount)
        TriggerEvent("earthRadars:log", source, fineAmount)
    end
end)

ESX.RegisterServerCallback('earth:obrisiRadar', function(source, callback, name)
    local Radari = json.decode(LoadResourceFile(GetCurrentResourceName(), "/json/radars.json"))
    for i, radarko in ipairs(Radari) do
        if radarko.ime == name then
            table.remove(Radari, i)
            SaveResourceFile(GetCurrentResourceName(), "/json/radars.json", json.encode(Radari, {indent = true}), -1)
            callback(true)
            LoadRadari()
            return
        end
    end
    callback(false)
end)


RegisterNetEvent("earthRadars:log", function(source, paraKoliko)
	local ime1 = GetPlayerName(source)
	local steamid1 = "Nepoznato"
    local discord1 = "Nepoznato"

    if ime1 == nil then
        ime1 = "Nepoznato"
    end
    for k, v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            steamid1 = v
        elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
            discordid1 = string.sub(v, 9)
            discord1 = "<@" .. discordid1 .. ">"
		end
    end

    local connect = {
            {
                ["color"] = "38855",
                ["title"] = "Radars Logs",
                ["description"] = "Igrac " .. GetPlayerName(source) .. " je dobio kaznu u iznosu " .. parekoliko .. "$",
                ["footer"] =
                {
                    ["text"] = "earthDevelopement // radarsLogs",
                },
				["fields"] = {
					{
						["name"] = "Player: ".. GetPlayerName(source),
						["value"] = "**ID**: " .. source .. "\n**Steam**: " .. steamid1 .. "\n**Discord**: " .. discord1,
						["inline"] = true
					},
				},
            }
        }
    PerformHttpRequest("https://discord.com/api/webhooks/1249351700834156644/unEEasnxa6hyFm_dh4c0wB9_SD9F9zSDkWnYHpQSZSggWgD1XZt9UnSL2BUBDhPrzil3", function(err, text, headers) end, 'POST', json.encode({username = "Luanda Roleplay", embeds = connect}), { ['Content-Type'] = 'application/json' })
end)