Penumbra = {}
Penumbra.loc_keys = {}
Penumbra.loc_names = {} --bad practice to use this, exists because of jsons
Penumbra.config = SMODS.current_mod.config
SMODS.Atlas {key = "modicon",path = "icon.png",px = 34,py = 34,}:register()
Penumbra.config.Enabled = Penumbra.config.Enabled or {}	
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
	local real_buffer = {}
	for i, v in ipairs(SMODS.Sound.obj_buffer) do
		if SMODS.Sound.obj_table[v].select_music_track or SMODS.Sound.obj_table[v].replace then
			real_buffer[#real_buffer + 1] = v
			if Penumbra.config.Enabled[v] == nil then Penumbra.config.Enabled[v] = true end
		end
	end
	local page = (G.PENUMBRA_PAGE and G.PENUMBRA_PAGE * 6 or 6) - (6 - 1)
	local max_pages = math.floor(#real_buffer/6)
	if max_pages * 6 < #real_buffer then --idk why this is needed but it is
		max_pages = max_pages + 1
	end
	local sound_options = {}
	for i = 1, max_pages do
		table.insert(
			sound_options,
			localize("k_page") .. " " .. tostring(i) .. "/" .. tostring(max_pages)
		)
	end	
	for i = page, math.min(page + 6 - 1, #real_buffer) do
		local key = real_buffer[i]
		table.insert(pbra_nodes, create_toggle({
			label = localize("b_play").." "..(Penumbra.loc_names[key] or (Penumbra.loc_keys[key] and localize(Penumbra.loc_keys[key])) or key),
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
			local res = s:select_music_track()
			if not Penumbra.config.Enabled[v] then res = nil end
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
		G.SHUFFLE_INDEX = nil
	end
	play_ref(sound_code, ...)
end