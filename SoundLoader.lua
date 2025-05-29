function Penumbra.LoadMusic()
    local files = NFS.getDirectoryItems(SMODS.Mods.pbra.path.."assets/sounds/")
    for _, file in ipairs(files) do
        if string.match(file, ".json") then
            local json = JSON.decode(NFS.read(SMODS.Mods.pbra.path.."assets/sounds/"..file))
            if json.sounds then
                for i, v in pairs(json.sounds) do
                    SMODS.Sound{
                        key = string.gsub(v.file, ".ogg", ""),
                        path = v.file,
                        pitch = v.pitch,
                        volume = v.volume,
                        sync = v.sync,
                        replace = v.replace,
                        select_music_track = v.priority and function()
                            return v.priority
                        end
                    }
                    Penumbra.loc_names["pbra_"..string.gsub(v.file, ".ogg", "")] = v.loc_name
                end
            else
                if type(json.file) == "string" then
                    SMODS.Sound{
                        key = string.gsub(json.file, ".ogg", ""),
                        path = json.file,
                        pitch = json.pitch,
                        volume = json.volume,
                        sync = json.sync,
                        replace = json.replace,
                        select_music_track = json.priority and function()
                            return json.priority
                        end
                    }
                    Penumbra.loc_names["pbra_"..string.gsub(json.file, ".ogg", "")] = json.loc_name
                else    
                    for i, v in pairs(json.file) do
                        SMODS.Sound{
                            key = string.gsub(v.file, ".ogg", ""),
                            path = v.file,
                            pitch = v.pitch,
                            volume = v.volume,
                            sync = v.sync,
                            replace = v.replace,
                            select_music_track = v.priority and function()
                                return v.priority
                            end
                        }
                        Penumbra.loc_names["pbra_"..string.gsub(v.file, ".ogg", "")] = v.loc_name
                    end
                end
            end
        end
    end
end