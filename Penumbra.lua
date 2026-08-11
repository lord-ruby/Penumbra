Penumbra = SMODS.current_mod
Penumbra.loc_keys = {}
Penumbra.loc_names = {} --bad practice to use this, exists because of jsons
Penumbra.loc_authors = {}
Penumbra.tags = {}
SMODS.Atlas {key = "modicon",path = "icon.png",px = 34,py = 34,}:register()
Penumbra.config.Enabled = Penumbra.config.Enabled or {}	
assert(SMODS.load_file("Jukebox.lua"))()

function Penumbra.manual_parse(text, args)
    if not text then return end
    if type(text) ~= "table" then text = {text} end
    local args = args or {}
    local dir = G.localization
    if args.loc_dir then
        for _,v in ipairs(args.loc_dir) do
            dir[v] = dir[v] or {}
            dir = dir[v]
        end
    else
        dir = G.localization.misc.v_text_parsed
    end
    local key = args.loc_key or "SMODS_stylize_text"
    local function deep_find(t, index)
        if type(index) ~= "table" then index = {index} end
        for _,idv_index in ipairs(index) do
            if t[idv_index] then return true end
            for i,v in pairs(t) do
                if i == idv_index then return true end
                if type(v) == "table" then
                    return deep_find(v, idv_index)
                end
            end
        end
        return false
    end
    if deep_find(text, "control") and not args.refresh then
        if not args.no_loc_save then dir = text end
        return text
    end

    local a = {"text", "name", "unlock"}
    if not args.no_loc_save then
        local loc = dir
        loc[key] = {}
        if deep_find(text, a) then
            for _,v in ipairs(a) do
                text[v] = text[v] or {}
                text[v.."_parsed"] = (args.refresh and {}) or text[v.."_parsed"] or {}
            end
            if text.text then
                for _,v in ipairs(text.text) do
                    if type(v) == "table" then
                        text.text_parsed[#text.text_parsed+1] = {}
                        for _, vv in ipairs(v) do
                            text.text_parsed[#text.text_parsed][#text.text_parsed[#text.text_parsed]+1] = loc_parse_string(vv)
                        end
                    else
                        text.text_parsed[#text.text_parsed+1] = loc_parse_string(v)
                    end
                end
            end
            if text.name then
                for _,v in ipairs((type(text.name) == "string" and {text.name}) or text.name) do
                    text.name_parsed[#text.name_parsed+1] = loc_parse_string(v)
                end
            end
            if text.unlock then
                for _,v in ipairs(text.unlock) do
                    text.unlock_parsed[#text.unlock_parsed+1] = loc_parse_string(v)
                end
            end
            loc[key] = text
        else
            for i,v in ipairs(text) do
                loc[key][i] = loc_parse_string(v)
            end
        end

        return loc[key]
    else
        local loc = {}
        if deep_find(text, a) then
            for _,v in ipairs(a) do
                text[v] = text[v] or {}
                text[v.."_parsed"] = (args.refresh and {}) or text[v.."_parsed"] or {}
            end
            if text.text then
                for _,v in ipairs(text.text) do
                    if type(v) == "table" then
                        text.text_parsed[#text.text_parsed+1] = {}
                        for _, vv in ipairs(v) do
                            text.text_parsed[#text.text_parsed][#text.text_parsed[#text.text_parsed]+1] = loc_parse_string(vv)
                        end
                    else
                        text.text_parsed[#text.text_parsed+1] = loc_parse_string(v)
                    end
                end
            end
            if text.name then
                for _,v in ipairs((type(text.name) == "string" and {text.name}) or text.name) do
                    text.name_parsed[#text.name_parsed+1] = loc_parse_string(v)
                end
            end
            if text.unlock then
                for _,v in ipairs(text.unlock) do
                    text.unlock_parsed[#text.unlock_parsed+1] = loc_parse_string(v)
                end
            end
            loc = text
        else
            for i,v in ipairs(text) do
                loc[i] = loc_parse_string(v)
            end
        end

        return loc
    end
end


PenumbraConfigTab = function()
	if not G.PENUMBRA_PAGE then G.PENUMBRA_PAGE = 1 end
	pbra_nodes = {
	}
	pbra_nodes2 = {
	}
	left_settings = { n = G.UIT.C, config = { align = "tl", padding = 0.05 }, nodes = {} }
	right_settings = { n = G.UIT.C, config = { align = "tl", padding = 0.05 }, nodes = {} }
	config = { n = G.UIT.R, config = { align = "tm", padding = 0 }, nodes = { left_settings, right_settings } }
	pbra_nodes2[#pbra_nodes2 + 1] = config
	pbra_nodes2[#pbra_nodes2 + 1] = create_toggle({
		label = localize("k_shuffle_same_prio"),
		active_colour = HEX("40c76d"),
		ref_table = Penumbra.config,
		ref_value = "shuffle",
	})
	pbra_nodes2[#pbra_nodes2 + 1] = create_toggle({
		label = localize("k_display_track_info"),
		active_colour = HEX("40c76d"),
		ref_table = Penumbra.config,
		ref_value = "info",
	})
	local real_buffer = {}
	for i, v in ipairs(SMODS.Sound.obj_buffer) do
		if SMODS.Sound.obj_table[v].select_music_track or SMODS.Sound.obj_table[v].replace then
			real_buffer[#real_buffer + 1] = v
			if Penumbra.config.Enabled[v] == nil then Penumbra.config.Enabled[v] = true end
		end
	end
	local per_page = 7
	local page = (G.PENUMBRA_PAGE and G.PENUMBRA_PAGE * per_page or per_page) - (per_page - 1)
	local max_pages = math.floor(#real_buffer/per_page)
	if max_pages *per_page < #real_buffer then --idk why this is needed but it is
		max_pages = max_pages + 1
	end
	local sound_options = {}
	for i = 1, max_pages do
		table.insert(
			sound_options,
			localize("k_page") .. " " .. tostring(i) .. "/" .. tostring(max_pages)
		)
	end	
	for i = page, math.min(page + per_page - 1, #real_buffer) do
		local key = real_buffer[i]
		local astr = ""
		if Penumbra.get_artist(key, Penumbra.tags[key]) ~= "" then
			astr = " - "..Penumbra.get_artist(key, Penumbra.tags[key])
		end
		table.insert(pbra_nodes, create_toggle({
			label = localize("b_play").." "..Penumbra.get_name(key, Penumbra.tags[key] or {})..astr,
			active_colour = HEX("40c76d"),
			ref_table = Penumbra.config.Enabled,
			ref_value = key,
			--callback = Cryptid.reload_localization,
		}))
	end
	return {
		n = G.UIT.ROOT,
		config = {
			emboss = 0.05,
			minh = 6,
			r = 0.1,
			minw = 10,
			align = "cm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
			{ n = G.UIT.R, config = { align = "cm", r = 0.1, colour = {0,0,0,0}, emboss = 0.05 }, nodes = pbra_nodes2 },
			{ n = G.UIT.R, config = { align = "cm", r = 0.1, colour = {0,0,0,0}, emboss = 0.05 }, nodes = pbra_nodes },
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					create_option_cycle({
						options = sound_options,
						w = 4.5,
						cycle_shoulders = true,
						opt_callback = "penumbra_set_config_page",
						current_option = G.PENUMBRA_PAGE or 1,
						colour = G.C.RED,
						no_pips = true,
						focus_args = { snap_to = true, nav = "wide" },
					}),
				},
			}
		},
	}
end
G.FUNCS.penumbra_set_config_page = function(args)
	G.PENUMBRA_PAGE = args.cycle_config.current_option
	G.FUNCS["openModUI_pbra"]()
end
SMODS.current_mod.config_tab = PenumbraConfigTab

SMODS.Sound.get_current_music = function(self)
	local track
	local maxp = -math.huge
	local tracks = {}
	for _, v in ipairs(self.obj_buffer) do
		local s = self.obj_table[v]
		if type(s.select_music_track) == 'function' then
			if Penumbra.config.Enabled[v] == nil then
				Penumbra.config.Enabled[v] = true
			end
			local res = s:select_music_track()
			if not Penumbra.config.Enabled[v] then res = nil end
			if s.key == PBJukebox.ActuallyPlaying then res = math.huge end
			if res then
				if type(res) ~= 'number' then res = -1e300 end
				if not tracks[res] then tracks[res] = {} end
				tracks[res][#tracks[res]+1] = {v, maxp, res}
			end
		end
	end
	local tbl_prio = -math.huge
	local tbl = {}
	for i, v in pairs(tracks) do
		if i > tbl_prio then
			tbl = v
			tbl_prio = i
		end
	end
	if #tbl < 1 then return nil end
	if #tbl == 1 then return tbl[1][1] end
	if not G.SHUFFLE_INDEX then
		G.SHUFFLE_COUNT = 2
	end
	G.SHUFFLE_INDEX = G.SHUFFLE_INDEX or pseudorandom("shuffle_next_song", 1, #tbl)
	if not Penumbra.config.shuffle then
		G.SHUFFLE_INDEX = #tbl
	end
	return tbl[G.SHUFFLE_INDEX][1]
end

SMODS.Sound.register = function(self)
	if self.registered then
		sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
		return
	end
	self.sound_code = self.key
	if self.replace then
		local replace, times, args
		if type(self.replace) == 'table' then
			replace, times, args = self.replace.key, self.replace.times or -1, self.replace.args
		else
			replace, times = self.replace, -1
		end
		self.replace_sounds[replace] = self.replace_sounds[replace] or {}
		self.replace_sounds[replace][#self.replace_sounds[replace]+1]={key = self.key, times = times, args = args, get_priority = function()
			return not Penumbra.config.Enabled[self.key] and -1e300 or 0
		end}
	end
	-- TODO detect music state based on if select_music_track exists
	assert(not self.select_music_track or self.key:find('music'), ("Object \"%s\" has a defined \"select_music_track\" but is not a music track."):format(self.key))
	SMODS.Sound.super.register(self)
end

function Penumbra.GetReplaceMusic(desired_track)
	local track = nil
	local prio = -1e299
	local tracks = SMODS.Sound.replace_sounds[desired_track]
	for i, v in pairs(tracks or {}) do
		if v.get_priority() > prio then
			prio = v.get_priority()
			track = v
		end
	end
	return track
end

SMODS.load_file("SoundLoader.lua")()
Penumbra.LoadMusic()

local play_ref = play_sound
function play_sound(sound_code, ...)
	if Penumbra.config.shuffle and SMODS.Sound.obj_table[sound_code] and (SMODS.Sound.obj_table[sound_code].replace or SMODS.Sound.obj_table[sound_code].select_music_track) then
		G.SHUFFLE_COUNT = G.SHUFFLE_COUNT - 1
		if G.SHUFFLE_COUNT < 1 then G.SHUFFLE_INDEX = nil end
	end
	play_ref(sound_code, ...)
end

function Penumbra.GCM(loc)
	local key = G.video_soundtrack or
	(G.STATE == G.STATES.SPLASH and '') or
	SMODS.Sound:get_current_music() or
	(G.booster_pack_sparkles and not G.booster_pack_sparkles.REMOVED and 'music2') or
	(G.booster_pack_meteors and not G.booster_pack_meteors.REMOVED and 'music3') or
	(G.booster_pack and not G.booster_pack.REMOVED and not disable_booster_music and 'music2') or
	(G.shop and not G.shop.REMOVED and 'music4') or
	(G.GAME.blind and G.GAME.blind.boss and 'music5') or 
	('music1')
	if loc then
		return (Penumbra.loc_names[key] or (Penumbra.loc_keys[key] and localize(Penumbra.loc_keys[key])) or key)
	end
	return key
end

function Penumbra.register_track(info)
	Penumbra.loc_names[info.key] = info.name
	Penumbra.loc_keys[info.key] = info.loc_key
	Penumbra.loc_authors[info.key] = info.author
	if info.icon_path then
		local path = SMODS.current_mod.path .. info.icon_path
		local image_data = SMODS.NFS.newFileData(path)
		local image = love.graphics.newImage(image_data)
		G.ASSET_ATLAS[info.key] = {
			path = "",
			full_path = "",
			image_data = img_data,
			px = image:getWidth(),
			py = image:getHeight(),
			image = image,
			type = "",
			name = name
		}
	end
	local tag = {}
	if SMODS.Sounds[info.key] then
		_, tag = pcall(PBJukebox.read_music_tags, SMODS.Sounds[info.key].full_path, SMODS.Sounds[info.key].key)
	end
	Penumbra.tags[info.key] = tag
	G.localization.descriptions.pbra_jukebox = G.localization.descriptions.pbra_jukebox or {}
	G.localization.descriptions.pbra_jukebox[info.key] = G.localization.descriptions.pbra_jukebox[info.key] or {}
	if Penumbra.get_name(info.key, tag) ~= "ERROR" then
	G.localization.descriptions.pbra_jukebox[info.key].name = G.localization.descriptions.pbra_jukebox[info.key].name or
		{ Penumbra.get_name(info.key, tag), "{C:edition,s:0.6}" .. Penumbra.get_artist(info.key, tag) }
	end
	G.localization.descriptions.pbra_jukebox[info.key].text = G.localization.descriptions.pbra_jukebox[info.key].text or
		SMODS.Sounds[info.key] and SMODS.Sounds[info.key].pbra_purpose or { "???" }

	Penumbra.manual_parse(G.localization.descriptions.pbra_jukebox, {})

	if Penumbra.config.Enabled[info.key] == nil then
		Penumbra.config.Enabled[info.key] = true
	end
end

function Penumbra.display_track()
	Penumbra.ease_towards_zero = true
	Penumbra.nowplaying_timer = 0
	Penumbra.nowplaying_xoff = Penumbra.nowplaying_xoff or -1000
end

function Penumbra.get_artist(key, tag)
	if not SMODS.Sounds[key] then	
		return "LouisF"
	end
	return Penumbra.loc_authors[key] or "???"
end
function Penumbra.get_name(key, tag)
	return (Penumbra.loc_names[key] or (Penumbra.loc_keys[key] and localize(Penumbra.loc_keys[key]))) or tag.title or key or ""
end

local update_ref = Game.update
function Game:update(dt, ...)
	update_ref(self, dt, ...)
	if Penumbra.nowplaying_timer then	
		if Penumbra.ease_towards_zero then
			local p = 1-(1.95*dt)
			Penumbra.nowplaying_xoff = Penumbra.nowplaying_xoff * p + 20 * (1-p)
			Penumbra.nowplaying_timer = Penumbra.nowplaying_timer + dt
		elseif Penumbra.nowplaying_timer > 3.5 and not Penumbra.ease_towards_zero then
			local p = 1-(1.95*dt)
			Penumbra.nowplaying_xoff = Penumbra.nowplaying_xoff * p - (1000 * (1-p))
			if Penumbra.nowplaying_xoff <= -999 then
				Penumbra.nowplaying_timer = nil
			end
		end
		if Penumbra.nowplaying_timer and (Penumbra.nowplaying_timer > 3.5) then
			Penumbra.ease_towards_zero = nil
		end
	end
end

Penumbra.register_track({key = "music1", loc_key = "k_main_theme", author = "LouisF"})
Penumbra.register_track({key = "music2", loc_key = "k_arcana_theme", author = "LouisF"})
Penumbra.register_track({key = "music3", loc_key = "k_celestial_theme", author = "LouisF"})
Penumbra.register_track({key = "music4", loc_key = "k_shop_theme", author = "LouisF"})
Penumbra.register_track({key = "music5", loc_key = "k_boss_theme", author = "LouisF"})

Penumbra.extra_tabs = function()
	return {
		-- Jukebox
		{
			label = "Jukebox",
			tab_definition_function = PBJukebox.MusicTab
		},
	}
end
