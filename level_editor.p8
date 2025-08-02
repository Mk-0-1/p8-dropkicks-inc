pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--
--

menu_state = 0

all_level_slots = {}

cursor_pos = 1

palettes = {
	split"1,2,3,   128,132,142,15, 8,9,10,138,    7,12,14,13, 0",
	split"1,2,9,   1,5,13,6,       8,9,10,10,     7,12,14,13, 0",
	
	split"1,131,4, 2,8,9,10,       3,138,135,143, 7,12,14,13, 0",
	
	split"3,2,3,130,5,6,7,8,9,10,11,12,13,14,15,3",
	
	split"129,2,3,4,5,6,7,8,9,10,11,12,13,14,15,5",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0",
	split"5,7,3,4,5,6,7,8,5,4,3,2,7,14,15,0",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0",
	
	
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  9",
	
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  6",
	split"11,4,3,4,5,6,7,8,9,10,11,12,13,14,15, 4",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  10",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  10",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  15",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  7",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  12"
}

cam_x = 0
cam_y = 0

l_start = 10 
l_end = 31 

function _init()
-- enable mouse buttons
	poke(0x5f2d, 0b1)
	
	poke(0x5f2e, 0b1)


	load_m_menu()
end

w_text = "main menu"
s_text = "select a level slot:"
s_col = 7

function load_m_menu()
	menu_state = 0
	get_lvls()
	
	poke(0x5f5c, 0)
	poke(0x5f5d, 0)
	w_text = "main menu"
	s_text = "select a level slot:"
	s_col = 7
	
	_draw = _draw_m_menu
	_update = _update_m_menu
end

function print_outl(txt,x,y,col,out_col)
			print(txt, x-1,y  ,out_col)
			print(txt, x  ,y-1,out_col)
			print(txt, x+1,y  ,out_col)
			print(txt, x  ,y+1,out_col)
			
			print(txt, x,y,col)

end

function _draw_m_menu()
	cls(0)
	
	local s = 14
	
	cam_y = cursor_pos*s-20
	camera(cam_x, cam_y)
	
	local level_num = 1
	for i=1, #all_level_slots do
		local yval = i*s + 12
	
		local l_txt_col = 7
		if cursor_pos == i then
			l_txt_col = 12
			rect(1, yval - s\2, 127, yval + s\2,l_txt_col)
		end

		if all_level_slots[i][1] == 0 then
			local pal_bg_col = palettes[all_level_slots[i][3]+1][16]
			
			-- col
			rectfill(2, yval - s\2+1, 126, yval + s\2-1,pal_bg_col)
			rect(2, yval - s\2+1, 126, yval + s\2-1,l_txt_col)
			
			-- bg sample
			for	j=0, s-4 do
				tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, all_level_slots[i][4]*8,j/8+2, 1/8, 0)
				tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, all_level_slots[i][5]*8,j/8+2, 1/8, 0)
			end
			
		
			print_outl("level " .. i, 4,yval-2,l_txt_col,0)
			level_num = i
		
		else
			l_txt_col = 13
			rect(2, yval - s\2+1, 126, yval + s\2-1,13)
			print("[extension of " .. level_num .. "]", 4,yval-2,13)
		end
	end
	

	
	rectfill(cam_x,cam_y,cam_x+128,cam_y+15,0)
	line(cam_x+2,cam_y+15,cam_x+126,cam_y+15,1)
	?w_text,1,cam_y+1,7
	?s_text,1,cam_y+9,s_col
	
end

function _update_m_menu()
	if btnp(2) then
		cursor_pos -= 1
		s_text = "select a level slot:"
		s_col = 7
	end
	if btnp(3) then
		cursor_pos += 1
		s_text = "select a level slot:"
		s_col = 7
	end
	
	cursor_pos = mid(1,cursor_pos, #all_level_slots)
	
	if btnp(4) then
		if all_level_slots[cursor_pos][1] == 0 then
			load_l_editor()
		else
			s_text = "cannot load an extension!"
			s_col = 9
		end
	end
	
end

function get_lvls()

	local map_counter = l_start

	while(map_counter <= l_end) do
		local lvl = {}
		
		add(lvl, 0)
		
		local byt_ext = mget(0,map_counter)
		local num_xtra_lvls = byt_ext & 0b11
		add(lvl, num_xtra_lvls)
		
		local byt_pal = mget(1,map_counter)
		add(lvl, (byt_pal & 0b11110000) >> 4)
		
		
		local byt_bg1 = mget(2,map_counter)
		local byt_bg2 = mget(4,map_counter)
		
		add(lvl, byt_bg1 & 0b1111)
		add(lvl, byt_bg2 & 0b1111)
		
		add(all_level_slots, lvl)
		
		map_counter += 1
		if num_xtra_lvls != 0 then
			for j=1, num_xtra_lvls do
				local lvl_ext = {}
				add(lvl_ext, 1)
				add(all_level_slots, lvl_ext)
			end
			map_counter += num_xtra_lvls
		end
		
	end
end

-->8
-- token savers

function unstr(str)
	return unpack(split(str))
end

function mod_tabl(tab, kv)
	local k,v = unpack(split(kv, "/"))
	k,v = split(k),split(v)
	for i=1,#k do
		tab[k[i]]=_pars(v[i])
	end
	return tab
end


-->8
-- main level editor

function load_l_editor()
	menu_state = 1
	load_lvl(cursor_pos+l_start-1)
	cam_x,cam_y = 0,0
	l_curs_x = 0
	l_curs_y = 0
	w_text = "editing level " .. cursor_pos
	s_text = "x:0 y:0"
	
	-- shorted delay for movement
	poke(0x5f5c, 8)
	poke(0x5f5d, 1)
	-- set map
	poke(0x5f56,0x80)
	unpack_lvl()
	
	menuitem(2 | 0x300, "level settings",
	edit_l_settings)
	
	menuitem(3 | 0x300, "save level",
	save_level)
	
	_draw = _draw_l_editor
	_update = _update_l_editor
end

loaded_level = {}
l_curs_x = 0
l_curs_y = 0
l_c_col = 13
l_can_place = false

lvl_tile_limit = 19

mous_x = 0
mous_y = 0

mous_prev = 0b0

edit_mode = 0
t_text = "mode: add"

select_texture_for_tile = false
s_t_f_t_tile_id = 0
selected_tex = 88

tile_selection = false
selected_tile_x = -1
selected_tile_y = -1
selected_tile_i = 0
editing_tile_index = 0
moving_tile = false

ord_curs_pos = 1

function draw_cursor()
	pset(mous_x, mous_y,7)
	pset(mous_x-1, mous_y,5)
	pset(mous_x+1, mous_y,5)
	pset(mous_x, mous_y-1,5)
	pset(mous_x, mous_y+1,5)
end

function _draw_l_editor()
	cls(palettes[loaded_level[1][4]+1][16])
	camera(cam_x,cam_y)
	camera_x,camera_y = cam_x,cam_y
	
	draw_loaded_bg()
	
	for i=1, 128 do
		if (i < 64) line(0,i*8,128*8,i*8,1)
		line(i*8,0,i*8,64*8,1)
	end
	
	map(0,0)
	
	if tile_selection then
		local tile = loaded_level[2][editing_tile_index]
		rect(tile[2]*8-1, tile[3]*8-1, (tile[2]+tile[4]+1)*8, (tile[3]+tile[5]+1)*8, 7)
	end
	
	rect(l_curs_x*8, l_curs_y*8,l_curs_x*8+8, l_curs_y*8+8, l_c_col)
	draw_sidebar()
	
	if tile_selection and not moving_tile then
		draw_edit_bar()
	end
	
	print_outl(w_text,cam_x+1,cam_y+1,7,0)
	print_outl(s_text,cam_x,cam_y+121,7,0)
	print_outl(t_text,cam_x+85,cam_y+121,7,0)
	
	draw_cursor()
	
--STAT(34) -- Mouse buttons (bitfield))
	
end



function draw_sidebar()
	rectfill(cam_x+100,cam_y,cam_x+128,cam_y+128, 0)

	
	if tile_selection then
		rectfill(cam_x+100,(editing_tile_index-ord_curs_pos)*10+cam_y+9,cam_x+128,(editing_tile_index-ord_curs_pos+1)*10+cam_y+8,13)
	end

	if mouse_on_sidebar then
		rectfill(cam_x+100,((mous_y-cam_y-9)\10)*10+cam_y+9,cam_x+128,((mous_y-cam_y-9)\10+1)*10+cam_y+8,12)
	end

	for i=1, #loaded_level[2] do
		local tex = loaded_level[2][i][1]
		local start_t1
		poke(0x5f56,0x20)
		if tex < 16 then
			start_t = mget(tex,tex_start)
		elseif tex < 32 then
			start_t = mget(tex-16,tex_start+1)
			tex_mode = 1
		elseif tex < 88 then
			start_t = mget((tex-32)*2+16,tex_start)
			tex_mode = 2
		else
			start_t = mget((tex-88)*4,tex_start+2)
			tex_mode = 3
		end
		poke(0x5f56,0x80)
		
		local y_pos = cam_y+(i-ord_curs_pos+1)*10
		
		rect(cam_x+110, y_pos, cam_x+110+7, y_pos+7,1)
		spr(start_t, cam_x+110, y_pos)
		print_outl(i,cam_x+120, y_pos + 1,7,0)
		
		line(cam_x+103, y_pos+2,cam_x+107, y_pos+2, 7)
		line(cam_x+104, y_pos+1,cam_x+106, y_pos+1, 7)
		pset(cam_x+105, y_pos+0,7)
		
		line(cam_x+103, y_pos+5, cam_x+107, y_pos+5, 6)
		line(cam_x+104, y_pos+6, cam_x+106, y_pos+6, 6)
		pset(cam_x+105, y_pos+7,6)
		
	end
	
	rectfill(cam_x+100,cam_y+100,cam_x+128,cam_y+128, 1)
	line(cam_x+100,cam_y+100,cam_x+128,cam_y+100, 7)
	line(cam_x+100,cam_y,cam_x+100,cam_y+128, 7)


	t_col = 13
	if (mouse_on_sidebar and mous_y-cam_y >= 102) t_col = 7

	rect(cam_x+105, cam_y+102, cam_x+106+16, cam_y+103+16,t_col)
	
	
	local tx,ty,t_m = get_texture(selected_tex)
	
	local prev_map_pos = peek(0x5f56)
	poke(0x5f56,0x20)
	
	
	spr(mget(tx,ty), cam_x+106, cam_y+103)
	
	if selected_tex < 32 then
		spr(mget(tx,ty), cam_x+114, cam_y+103)
		spr(mget(tx,ty), cam_x+106, cam_y+111)
		spr(mget(tx,ty), cam_x+114, cam_y+111)
			
	else
		spr(mget(tx+1,ty  ), cam_x+114, cam_y+103)
		spr(mget(tx  ,ty+1), cam_x+106, cam_y+111)
		spr(mget(tx+1,ty+1), cam_x+114, cam_y+111)
	
	end
	poke(0x5f56,prev_map_pos)
	
	
	print_outl(#loaded_level[2].."/"..lvl_tile_limit,cam_x+106,cam_y+2,7,0)
	
	
end

function pack_tile(tile)
	local p_tile = {}
	add(p_tile, tile[1])
	add(p_tile, tile[2] + (tile[9] << 7))
	add(p_tile, tile[3] + (tile[10] << 6))
	add(p_tile, tile[4] + ((tile[7]&0b11000) << 3))
	
	add(p_tile, tile[5] + (tile[8] << 5))
	add(p_tile, tile[6] + ((tile[7]&0b111) << 5))
	
	return p_tile
end


function unpack_tile(tile)
	local u_tile = {}
	
	local function add_u(i,n,s)
		add(u_tile,(tile[i]&n)>>s)
	end
	add_u(1,0b01111111,0)--1:texture
	add_u(2,0b01111111,0)--2:xpos
	add_u(3,0b00111111,0)--3:ypos
	add_u(4,0b00111111,0)--4:xlen
	add_u(5,0b00011111,0)--5:ylen
	
	add_u(6,0b00011111,0)--6:xoffset
	add_u(6,0b11100000,5)--7:yoffset
	u_tile[7] += ((tile[4]&0b11000000)>>3)
	
	add_u(5,0b11100000,5)--8:repeat num
	add_u(2,0b10000000,7)--9:square repeat

	add_u(3,0b11000000,6)--10:rng seed
	
	return u_tile
end


mouse_on_sidebar = false
mouse_on_edit = false
mouse_on_canvas = false

function _update_l_editor()
	mous_x, mous_y = stat(32)+cam_x,stat(33)+cam_y
	l_curs_x = mous_x\8
	l_curs_y = mous_y\8
	s_text = "x:"..l_curs_x.." y:"..l_curs_y

	local should_reload = false

	mouse_on_sidebar = mous_x >= cam_x+100
	mouse_on_edit = tile_selection and not moving_tile and mous_x < cam_x+32 and mous_y > cam_y + 16 and mous_y < cam_y + 112
	mouse_on_canvas = not mouse_on_sidebar and not mouse_on_edit


	local tile_m_x, tile_m_y = 0,0
	if mouse_on_canvas then
		if btnp(0) then
			if moving_tile then
				tile_m_x -= 1
			end
			cam_x-=8
		end
		if btnp(1) then
			if moving_tile then
				tile_m_x += 1
			end
			cam_x+=8
		end
		if btnp(2) then
			if moving_tile then
				tile_m_y -= 1
			end
			cam_y-=8
		end
		if btnp(3) then
			if moving_tile then
				tile_m_y += 1
			end
			cam_y+=8
		end
	end
	
	if tile_m_x !=0 or tile_m_y !=0 then
		local tile = loaded_level[2][editing_tile_index]
		tile[2] += tile_m_x
		tile[3] += tile_m_y
		
		tile[2] = mid(0,tile[2],127)
		tile[3] = mid(0,tile[3],63)
		
		should_reload = true
	end
	
	if editing_tile_index != 0 then
		-- positions
		loaded_level[2][editing_tile_index][2] = mid(0,loaded_level[2][editing_tile_index][2], 127)
		loaded_level[2][editing_tile_index][3] = mid(0,loaded_level[2][editing_tile_index][3], 63)
	end
	
	local mous = stat(34)
	local mous_prim = mous&0b1
	local mous_scnd = mous&0b10
	

	
	if not mouse_on_canvas then
		s_text = ""
		l_c_col = 1
	end
	
	if mouse_on_sidebar then
		if btnp(2) then
			ord_curs_pos -= 1
			ord_curs_pos = mid(1,ord_curs_pos,#loaded_level[2])
		end		
		if btnp(3) then
			ord_curs_pos += 1
			ord_curs_pos = mid(1,ord_curs_pos,#loaded_level[2])
		end
		
		if (btnp(4) or (mous_prim==1 and (mous_prev&0b1) != 1)) and edit_mode != 3 then
			
			if mous_y-cam_y < 102 then
			
				local mouse_loc = ((mous_y-cam_y-9)\10) + ord_curs_pos

				if mouse_loc > 0 and mouse_loc <= #loaded_level[2] then
					if mous_x-cam_x > 109 then
						edit_mode = 4
						tile_selection = true
						editing_tile_index = mouse_loc
						w_text = "editing tile " .. editing_tile_index .. "\nx:" .. loaded_level[2][editing_tile_index][2] .. " y:" .. loaded_level[2][editing_tile_index][3]
					else
						local mouse_offset_y = (mous_y-cam_y-9)%10
						
						if mouse_offset_y <= 4 then
							if mouse_loc > 1 then
								loaded_level[2][mouse_loc],loaded_level[2][mouse_loc-1] = loaded_level[2][mouse_loc-1],loaded_level[2][mouse_loc]
								ord_curs_pos -= 1
								ord_curs_pos = mid(1,ord_curs_pos,#loaded_level[2])
								if editing_tile_index == mouse_loc then
									editing_tile_index -= 1
									w_text = "editing tile " .. editing_tile_index .. "\nx:" .. loaded_level[2][editing_tile_index][2] .. " y:" .. loaded_level[2][editing_tile_index][3]
								end
								should_reload = true
							end						
						else
							if mouse_loc < #loaded_level[2] then
								loaded_level[2][mouse_loc],loaded_level[2][mouse_loc+1] = loaded_level[2][mouse_loc+1],loaded_level[2][mouse_loc]
								ord_curs_pos += 1
								ord_curs_pos = mid(1,ord_curs_pos,#loaded_level[2])
								if editing_tile_index == mouse_loc then
									editing_tile_index += 1
									w_text = "editing tile " .. editing_tile_index .. "\nx: " .. loaded_level[2][editing_tile_index][2] .. " y:" .. loaded_level[2][editing_tile_index][3]
								end
								should_reload = true
							end		
						end
						
					end
				end
			else
				select_texture_for_tile = false
				edit_l_texture()
			end
		end
	
		
	end
	
	if mouse_on_edit then
		
		
		
	end
	

	
	if edit_mode < 3 then
	
		if mouse_on_canvas then
			if l_curs_x >= 0 and l_curs_x < 128 and l_curs_y >= 0 and l_curs_y < 64 then
				l_c_col = 13
				l_can_place = true
			else
				l_c_col = 2
				l_can_place = false
			end
		end
	
		-- mode 3 is unused (was supposed to be delete but doing it in edit is kinda better)
		if btnp(5) or (mous_scnd==0b10 and (mous_prev&0b10) != 0b10) then
			edit_mode += 1
			edit_mode %= 2
			if edit_mode == 0 then
				t_text = "mode: add"
			else
				t_text = "mode: edit"
			end
		end
		

		if mouse_on_canvas and l_can_place and (btnp(4) or (mous_prim==1 and (mous_prev&0b1) != 1)) then
			if edit_mode == 0 then 
				if #loaded_level[2] < lvl_tile_limit then
					edit_mode = 3
					w_text = "placing tile"
					
					add(loaded_level[2],{selected_tex,l_curs_x,l_curs_y,0,0,0,0,0,0,0})
					editing_tile_index = #loaded_level[2]
					should_reload = true
				else
					w_text = "at tile limit!"
				end
				
			elseif edit_mode == 1 then
				selected_tile_x, selected_tile_y = l_curs_x, l_curs_y
				local did_select = unpack_lvl(true)
				if did_select then
					edit_mode = 4
					editing_tile_index = selected_tile_i
					tile_selection = true
					w_text = "editing tile " .. editing_tile_index .. "\nx:" .. loaded_level[2][editing_tile_index][2] .. " y:" .. loaded_level[2][editing_tile_index][3]

				end
			end
		
		end
	
	elseif edit_mode == 3 then
	
		l_c_col = 13
		l_can_place = true
			
		loaded_level[2][editing_tile_index][4] = mid(0, l_curs_x - loaded_level[2][editing_tile_index][2], 63)
		loaded_level[2][editing_tile_index][5] = mid(0, l_curs_y - loaded_level[2][editing_tile_index][3], 31)
		should_reload = true 
		
		if mouse_on_canvas and l_can_place and (btnp(4) or (mous_prim==1 and (mous_prev&0b1) != 1)) then
			edit_mode = 0
			w_text = "editing level ".. cursor_pos
			t_text = "mode: add"
		end
		
	elseif edit_mode == 4 then
		if mouse_on_canvas and (btnp(4) or (mous_prim==1 and (mous_prev&0b1) != 1)) then
			tile_selection = false
			edit_mode = 1
			moving_tile = false
			w_text = "editing level ".. cursor_pos
			t_text = "mode: edit"
		elseif mouse_on_canvas and (btnp(5) or (mous_scnd==0b10 and (mous_prev&0b10) != 0b10)) then
			moving_tile = not moving_tile
			
			if moving_tile then
				w_text = "moving tile"
			else
				w_text = "editing tile " .. editing_tile_index .. "\nx:" .. loaded_level[2][editing_tile_index][2] .. " y:" .. loaded_level[2][editing_tile_index][3]
			end
		
		elseif mouse_on_edit and (btnp(4) or (mous_prim==1 and (mous_prev&0b1) != 1)) then
			local mouse_loc = ((mous_y-cam_y-7)\10)
			
			if mouse_loc == 1 then
				select_texture_for_tile = true
				s_t_f_t_tile_id = editing_tile_index
				edit_l_texture()
			elseif mouse_loc == 2 then
				tile_selection = false
				edit_mode = 3
				
			elseif mouse_loc == 3 then
				loaded_level[2][editing_tile_index][8] += 1
				loaded_level[2][editing_tile_index][8] &= 0b111
			elseif mouse_loc == 5 then
				loaded_level[2][editing_tile_index][6] += 1
				loaded_level[2][editing_tile_index][6] &= 0b11111
			elseif mouse_loc == 6 then
				loaded_level[2][editing_tile_index][7] += 1
				loaded_level[2][editing_tile_index][7] &= 0b11111
			elseif mouse_loc == 7 then
				loaded_level[2][editing_tile_index][9] += 1
				loaded_level[2][editing_tile_index][9] &= 0b1
			elseif mouse_loc == 8 then
				loaded_level[2][editing_tile_index][10] += 1
				loaded_level[2][editing_tile_index][10] &= 0b11
			elseif mouse_loc == 9 then
				tile_selection = false
				edit_mode = 1
				w_text = "deleted tile " .. editing_tile_index
				deli(loaded_level[2], editing_tile_index)
				
				editing_tile_index = 0
		 end
			should_reload = true
		
		elseif mouse_on_edit and (btnp(5) or (mous_scnd==0b10 and (mous_prev&0b10) != 0b10)) then
			local mouse_loc = ((mous_y-cam_y-7)\10)
		
			if mouse_loc == 3 then
				loaded_level[2][editing_tile_index][8] -= 1
				loaded_level[2][editing_tile_index][8] &= 0b111
			elseif mouse_loc == 5 then
				loaded_level[2][editing_tile_index][6] -= 1
				loaded_level[2][editing_tile_index][6] &= 0b11111
			elseif mouse_loc == 6 then
				loaded_level[2][editing_tile_index][7] -= 1
				loaded_level[2][editing_tile_index][7] &= 0b11111
			elseif mouse_loc == 7 then
				loaded_level[2][editing_tile_index][9] -= 1
				loaded_level[2][editing_tile_index][9] &= 0b1
			elseif mouse_loc == 8 then
				loaded_level[2][editing_tile_index][10] -= 1
				loaded_level[2][editing_tile_index][10] &= 0b11
		 end
			should_reload = true
		
		end
			
	end

	if (should_reload) unpack_lvl()
	
	mous_prev = mous
end


function load_lvl(index)
	loaded_level = {{},{}}


	local function add_l(i,n,s)
		add(loaded_level[1],(mget(i,index)&n)>>s)
	end 

	-- ext/mus
	add_l(0,0b11,0)
	add_l(0,0b111100,2)
	
	-- pals
	add_l(1,0b00001111,0)
	add_l(1,0b11110000,4)
	
	-- bg1
	add_l(2,0b00001111,0)
	add_l(2,0b11110000,4)
	
	add_l(3,0b00000111,0)
	add_l(3,0b00001000,3)
	add_l(3,0b00010000,4)
	
	add_l(4,0b00001111,0)
	add_l(4,0b11110000,4)
	
	add_l(5,0b00011111,0)
	add_l(5,0b11100000,5)

	
	-- bg2
	add_l(6,0b00001111,0)
	add_l(6,0b11110000,4)
	
	add_l(7,0b00000111,0)
	add_l(7,0b00001000,3)
	add_l(7,0b00010000,4)
	
	add_l(8,0b00001111,0)
	add_l(8,0b11110000,4)
	
	add_l(9,0b00001111,0)
	add_l(9,0b01110000,4)

	
	
	
 local tile = {}
	for j=index,index+loaded_level[1][1] do
		
		local st = 0
		if (j == index) st = 10
			
		for i=st,127 do
			add(tile,mget(i,j))
			if #tile == 6 then
				if not (tile[2] == 0 and tile[3] == 0 and tile[4] == 0 and tile[5] == 0 and tile[6] == 0) then
					local u_tile = unpack_tile(tile)
					add(loaded_level[2],u_tile)
				end
				tile = {}
			end
		end
	end
	
	lvl_tile_limit = (118 + 128*loaded_level[1][1])\6
	
	pal(palettes[loaded_level[1][3]+1], 1)
	
end

function get_texture(index)

		local t_pos_x, t_pos_y
		local t_type
		
		if index < 16 then
			t_pos_x, t_pos_y = index,tex_start -- 1x1 first section
			t_type = 0
		elseif index < 32 then
			t_pos_x, t_pos_y = index-16,tex_start+1 -- 1x1 second section
			t_type = 1
		elseif index < 88 then
			t_pos_x, t_pos_y = (index-32)*2+16,tex_start-- 2x2
			t_type = 2
		else
			t_pos_x, t_pos_y = (index-88)*4,tex_start+2
			t_type = 3
		end

		return t_pos_x, t_pos_y, t_type
end

function draw_tile(t,x,y,xlen,ylen)

	local t_x,t_y, tex_mode = get_texture(t)
	local did_select = false
	
	local prev_map_pos = peek(0x5f56)
	poke(0x5f56,0x20)
	local tiles = {}
	local tiles_var1 = {}
	

	
		if tex_mode == 0 or tex_mode == 1 then
			add(tiles,mget(t_x,t_y))
		elseif tex_mode == 2 then
		
			for j=0,1 do
				for i=0,1 do
					add(tiles,mget(t_x+i,t_y+j))
				end
			end
			
		else
		
		
			local function add_t(arr,nums)
				for i=1, #nums do
					local x = nums[i]%4
					local y = nums[i]\4
					add(arr,mget(t_x+x,t_y+y))
				end
			end
			
			add_t(tiles,split"0,1,3,4,5,7,12,13,15")
			add_t(tiles_var1,split"0,2,3,8,6,11,12,14,15")
		
			
		end
	
	poke(0x5f56,prev_map_pos)
	
	local max_x = x+xlen
	local max_y = y+ylen
	
	for yi=y, max_y do
		local draw_y = yi
		draw_y &= 0b111111
		for xi=x, max_x do
			local draw_x = xi
			draw_x &= 0b1111111
		
			local tile
			local rval = rnd(100)
			
			if tex_mode == 0 or tex_mode == 1 then
				tile = tiles[1]
			elseif tex_mode == 2 then
				-- random
				local index=1
				
				if rval > 58 + 25 + 12 then
					index=4
				elseif rval > 58 + 25 then
					index=3
				elseif rval > 58  then
					index=2
				end
				
				tile = tiles[index]

			else
				-- random + random sides + corners	
				local index=5
				
				if xi == x then
					index -= 1
				elseif xi == x+xlen then
					index += 1		
				end
				
				
				if yi == y then
					index -= 3
				elseif yi == y+ylen then
					index += 3		
				end


				tile = tiles[index]
				rval -= (min(min(xi-x,max_x-xi), min(yi-y,max_y-yi)))^2
				if rval > 80 then
					tile = tiles_var1[index]
				end
			
			end
			
			if (tile != 0) then 
				if (tile == 16) tile = 0
				mset(draw_x,draw_y,tile)
			end
			
			if draw_x == selected_tile_x and draw_y == selected_tile_y and tile != 0 then
				did_select = true
			end
		
		end
	end
	
	return did_select

end

tex_start = 4
-- main decompression algorithm
function unpack_lvl(select_tile)
	-- clean map
	memset(0x8000, 0x0, 0x2000)
	local did_select = false
	
	-- get texture
	for i=1, #loaded_level[2] do
		local tex = loaded_level[2][i][1]
		
		local xpos = loaded_level[2][i][2]
		local ypos = loaded_level[2][i][3]
		
		local xlen = loaded_level[2][i][4]
		local ylen = loaded_level[2][i][5]
		

		local rep = loaded_level[2][i][8]
		local sqrep = loaded_level[2][i][9]
		local xoffset = loaded_level[2][i][6]
		local yoffset = loaded_level[2][i][7]
		if xoffset >= 0b10000 then
			xoffset -= 32
		end
		if yoffset >= 0b10000 then
			yoffset -= 32
		end
		
		local seed = loaded_level[2][i][10]
		srand(seed)
		
		local res = false
		
		if sqrep == 0 then
			for j=0,rep do
				local res2 = draw_tile(tex,xpos,ypos,xlen,ylen)
				if (res2 == true) res = res2
				
				xpos += xoffset
				ypos += yoffset
			end
		else
			for j=0,rep do
				local xpos2 = xpos
				
				for k=0,rep do
					local res2 = draw_tile(tex,xpos2,ypos,xlen,ylen)
					if (res2 == true) res = res2
				
					xpos2 += xoffset
				end
					
				ypos += yoffset
			end

		end

			

		
		if res and select_tile then
			did_select = true
			selected_tile_i = i
		end
	end

	return did_select
end

function save_level()
	local prev_map_pos = peek(0x5f56)
	poke(0x5f56,0x20)
	
	local function add_l(i,n,s)
		add(loaded_level[1],(mget(i,index)&n)>>s)
	end 
	
	level_bytes = {}
	
	-- ext/mus
	add(level_bytes, loaded_level[1][1] + (loaded_level[1][2]<<2))
	-- pals
	add(level_bytes, loaded_level[1][3] + (loaded_level[1][4]<<4))
	
	-- bg1
	add(level_bytes, loaded_level[1][5] + (loaded_level[1][6]<<4))
	add(level_bytes, loaded_level[1][7] + (loaded_level[1][8]<<3) + (loaded_level[1][9]<<4))

	add(level_bytes, loaded_level[1][10] + (loaded_level[1][11]<<4))
	
	add(level_bytes, loaded_level[1][12] + (loaded_level[1][13]<<5))
	
	-- bg2
	add(level_bytes, loaded_level[1][5+9] + (loaded_level[1][6+9]<<4))
	add(level_bytes, loaded_level[1][7+9] + (loaded_level[1][8+9]<<3) + (loaded_level[1][9+9]<<4))

	add(level_bytes, loaded_level[1][10+9] + (loaded_level[1][11+9]<<4))
	
	add(level_bytes, loaded_level[1][12+9] + (loaded_level[1][13+9]<<5))
	
	
	-- tiles
	
	for i=1, #loaded_level[2] do
		local p_tile = pack_tile(loaded_level[2][i])
		for j=1, 6 do
			add(level_bytes, p_tile[j])
		end
	end
	
	local byte_c = 1
	
	for j=0, loaded_level[1][1] do
		for i=0, 127 do
			mset(i,j+10+(cursor_pos-1), level_bytes[byte_c])
			byte_c += 1
		end
	end

	
	poke(0x5f56,prev_map_pos)
	
	cstore(0x2000,0x2000,0x1000)
	
	w_text = "level saved!"
	return false
end

function draw_edit_bar()
	local tile = loaded_level[2][editing_tile_index]
	rectfill(cam_x, cam_y+16, cam_x+32, cam_y + 112, 0)
	
	if mouse_on_edit then
		rectfill(cam_x,((mous_y-cam_y-7)\10)*10+cam_y+7,cam_x+32,((mous_y-cam_y-7)\10+1)*10+cam_y+6,13)
	end
	
	
	print_outl("tx:".. tile[1],cam_x,cam_y+20,7,0)
	print_outl("resize",cam_x,cam_y+30,7,0)
	print_outl("repeat:" .. tile[8],cam_x,cam_y+40,7,0)
	print_outl("offset",cam_x,cam_y+50,7,0)
	local xoffset = tile[6]
	if xoffset >= 0b10000 then
		xoffset -= 32
	end
	local yoffset = tile[7]
	if yoffset >= 0b10000 then
		yoffset -= 32
	end
	
	print_outl("x:" .. xoffset,cam_x,cam_y+60,7,0)
	print_outl("y:" .. yoffset,cam_x,cam_y+70,7,0)
	print_outl("square:" .. tile[9],cam_x,cam_y+80,7,0)
	print_outl("seed:" .. tile[10],cam_x,cam_y+90,7,0)
	print_outl("delete",cam_x,cam_y+100,14,0)
	
end


l_set_cursor_pos = 1

function edit_l_settings()
		menuitem(2 | 0x300, "back to editor",
		unedit_l_settings)
		
	l_set_cursor_pos = 1
	l_set_list_cam = 1
	
	camera_x = 0
	camera_y = 0
	
	_update = _update_l_settings
 _draw = _draw_l_settings

end

settings_bit_limits = {0b11,0b1111, 0b1111,0b1111, 
0b1111,0b1111, 0b111,0b1,0b1, 0b1111,0b1111 ,0b1111,0b111,  
0b1111,0b1111, 0b111,0b1,0b1, 0b1111,0b1111 ,0b1111,0b111}

function _update_l_settings()
	mous_x, mous_y = stat(32),stat(33)+l_set_list_cam*8-8
	
	if (btnp(2)) then
		l_set_cursor_pos -= 1
		if (l_set_list_cam - l_set_cursor_pos > 1) l_set_list_cam -= 1
		
		if l_set_cursor_pos == 2 then
			music(loaded_level[1][2] * 8 + 2, 1000)
		else
			music(-1)
		end
		
	end
	if (btnp(3)) then
		l_set_cursor_pos += 1
		if (l_set_cursor_pos - l_set_list_cam > 10) l_set_list_cam += 1
		
		
		if l_set_cursor_pos == 2 then
			music(loaded_level[1][2] * 8 + 2, 1000)
		else
			music(-1)
		end
		
	end
	l_set_cursor_pos = mid(1,l_set_cursor_pos,22)
	
	
	if btnp(4) then
		loaded_level[1][l_set_cursor_pos] += 1
		loaded_level[1][l_set_cursor_pos] &= settings_bit_limits[l_set_cursor_pos]
		
		if l_set_cursor_pos == 1 then
			lvl_tile_limit = (118 + 128*loaded_level[1][1])\6
		elseif l_set_cursor_pos == 2 then
			music(loaded_level[1][2] * 8 + 2, 1000)
		elseif l_set_cursor_pos == 3 then
			pal(palettes[loaded_level[1][3]+1], 1)
		end
		
	end
	if btnp(5) then
		loaded_level[1][l_set_cursor_pos] -= 1
		loaded_level[1][l_set_cursor_pos] &= settings_bit_limits[l_set_cursor_pos]
		
		if l_set_cursor_pos == 1 then
			lvl_tile_limit = (118 + 128*loaded_level[1][1])\6
		elseif l_set_cursor_pos == 2 then
			music(loaded_level[1][2] * 8 + 2, 1000)
		elseif l_set_cursor_pos == 3 then
			pal(palettes[loaded_level[1][3]+1], 1)
		end
		
	end	
	
end

function draw_bg(m_st_x,m_st_y,len_x,len_y, scale, scroll_a_x, scroll_a_y, timescroll_x,timescroll_y, wrap_x,wrap_y,offset_x,offset_y)
	pal(palettes[loaded_level[1][4]+1], 0)
	
	
	local scroll_x = (-offset_x or 0) + camera_x*scroll_a_x
	scroll_x += time()*(timescroll_x or 0)
	local scroll_y = (-offset_y or 0) + camera_y*scroll_a_y
	scroll_y += time()*(timescroll_y or 0)
	
	if(wrap_x) scroll_x %= len_x*8*scale
	if(wrap_y) scroll_y %= len_y*8*scale

	local function map_scaled(ox,oy)
		for	i=0,len_x-1 do
			for	j=0,len_y-1 do
			 local n = mget(m_st_x+i,m_st_y+j)
				sspr((n&0b1111)*8,(n\16)*8,8,8, camera_x-scroll_x+i*8*scale+ox, camera_y-scroll_y+j*8*scale+oy, scale*8,scale*8)
			end
		end
	end
	
	map_scaled(0,0)
	if (wrap_x) map_scaled(len_x*8*scale,0)
	if (wrap_y) map_scaled(0,len_y*8*scale)
	if (wrap_x and wrap_y) map_scaled(len_x*8*scale,len_y*8*scale)


	pal(0)
end

l_set_list_cam = 1
camera_x = 0
camera_y = 1

l_bg_scales = {1,2,3,4,5,6,8,12}
l_bg_scrolls_x = {0, 0x.02, 0x.02, 0x.04, 0x0.1, 0x0.1, 0x0.2, 0x0.4, 0x0.8, 1, 1, 0x1.2, 0x1.2, 0x1.4, 0x1.4, 0x1.8}
l_bg_scrolls_y = {0, 0x.02, 0x.00, 0x.04, 0x0.1, 0x0.0, 0x0.2, 0x0.4, 0x0.8, 1, 0, 0x1.2, 0x0, 0x1.4, 0x1.0, 0x1.8}


l_bg_timescrolls = {0,    1, 3, 6, 15, 30, 60, 90,
																				150, -1,-3,-6,-15,-30,-60,-90}

l_bg_angles_x = {0,0.5,0.5,  1,1,   1,  0.5, 0.5}
l_bg_angles_y = {1,  1,0.5,0.5,0,-0.5, -0.5,  -1}


function draw_loaded_bg()

	local prev_map_pos = peek(0x5f56)
	poke(0x5f56,0x20)


	bg1_index = loaded_level[1][5]*8
 bg2_index = loaded_level[1][5+9]*8

	bg1_scrl_x = l_bg_scrolls_x[loaded_level[1][6] + 1]
	bg1_scrl_y = l_bg_scrolls_y[loaded_level[1][6] + 1]
	bg2_scrl_x = l_bg_scrolls_x[loaded_level[1][6+9] + 1]
	bg2_scrl_y = l_bg_scrolls_y[loaded_level[1][6+9] + 1]

	bg1_scale = l_bg_scales[loaded_level[1][7]   +1]
	bg2_scale = l_bg_scales[loaded_level[1][7+9] +1]
	
	bg1_wrap_x = false or (loaded_level[1][8]   != 0)
	bg1_wrap_y = false or (loaded_level[1][9]   != 0)
	bg2_wrap_x = false or (loaded_level[1][8+9] != 0)
	bg2_wrap_y = false or (loaded_level[1][9+9] != 0)
	
	bg1_offset_x = ((loaded_level[1][10] &0b0111) - (loaded_level[1][10]&0b1000)) * 24
	bg1_offset_y = ((loaded_level[1][11] &0b0111) - (loaded_level[1][11]&0b1000)) * 24

	bg2_offset_x = ((loaded_level[1][10+9]&0b0111) - (loaded_level[1][10+9]&0b1000)) * 24
	bg2_offset_y = ((loaded_level[1][11+9]&0b0111) - (loaded_level[1][11+9]&0b1000)) * 24 
	

	bg1_timescroll = l_bg_timescrolls[loaded_level[1][12]   +1]
	bg2_timescroll = l_bg_timescrolls[loaded_level[1][12+9] +1]
	
	bg1_timescroll_x = l_bg_angles_x[loaded_level[1][13]   +1]
	bg1_timescroll_y = l_bg_angles_y[loaded_level[1][13]   +1]
	bg2_timescroll_x = l_bg_angles_x[loaded_level[1][13+9] +1]
	bg2_timescroll_y = l_bg_angles_y[loaded_level[1][13+9] +1]
	


	draw_bg(bg1_index, 0, 8, 4, bg1_scale, bg1_scrl_x,  bg1_scrl_y,   bg1_timescroll_x * bg1_timescroll, bg1_timescroll_y * bg1_timescroll, bg1_wrap_x,bg1_wrap_y, bg1_offset_x, bg1_offset_y)
	draw_bg(bg2_index, 0, 8, 4, bg2_scale, bg2_scrl_x,  bg2_scrl_y,   bg2_timescroll_x * bg2_timescroll, bg2_timescroll_y * bg2_timescroll, bg2_wrap_x,bg2_wrap_y, bg2_offset_x, bg2_offset_y)

	poke(0x5f56,prev_map_pos)

end

function _draw_l_settings()
	cls(palettes[loaded_level[1][4]+1][16])

	
	camera_y = l_set_list_cam*8-8
 camera(0, camera_y)
	
 draw_loaded_bg()
	
	
	rectfill(0,l_set_cursor_pos*8+4,128,l_set_cursor_pos*8+12,13)
	
	print_outl("level " .. cursor_pos .. " settings",0,0,7,0)
	
	print_outl("extensions: "  .. 
		loaded_level[1][1],0,14,7,0)
	print_outl("music: " .. 
		loaded_level[1][2],0,14+8*1,7,0)
	print_outl("main pallette: " .. 
		loaded_level[1][3],0,14+8*2,7,0)
	print_outl("bg pallette: " .. 
		loaded_level[1][4],0,14+8*3,7,0)
		
	print_outl("bg 1 (back): " .. 
		loaded_level[1][5],0,14+8*4,7,0)
	print_outl("bg 1 parallax: x:" .. 
		bg1_scrl_x .. " y:" .. bg1_scrl_y, 0,14+8*5,7,0)
		
	print_outl("bg 1 scale: " .. 
		bg1_scale,0,14+8*6,7,0)
	print_outl("bg 1 wrap x: " .. 
		tostr(bg1_wrap_x),0,14+8*7,7,0)
	print_outl("bg 1 wrap y: " .. 
		tostr(bg1_wrap_y),0,14+8*8,7,0)
		
	
	print_outl("bg 1 x offset: " .. 
		bg1_offset_x,0,14+8*9,7,0)
	print_outl("bg 1 y offset: " .. 
		bg1_offset_y,0,14+8*10,7,0)
		
		
	print_outl("bg 1 timescroll: " .. 
		bg1_timescroll,0,14+8*11,7,0)
	print_outl("bg 1 timescroll dir: x:" .. 
		bg1_timescroll_x .. " y:" .. bg1_timescroll_y,0,14+8*12,7,0)

	
	
	print_outl("bg 2 (front): " .. 
		loaded_level[1][14],0,14+8*13,7,0)
	print_outl("bg 2 parallax: " .. 
		bg2_scrl_x .. " y:" .. bg2_scrl_y,0,14+8*14,7,0)
		
	print_outl("bg 2 scale: " .. 
		bg2_scale,0,14+8*15,7,0)
		
		
	print_outl("bg 2 wrap x: " .. 
		tostr(bg2_wrap_x),0,14+8*16,7,0)
	print_outl("bg 2 wrap y: " .. 
		tostr(bg2_wrap_y),0,14+8*17,7,0)

	print_outl("bg 2 x offset: " .. 
		bg2_offset_x,0,14+8*18,7,0)
	print_outl("bg 2 y offset: " .. 
		bg2_offset_y,0,14+8*19,7,0)
		
	print_outl("bg 2 timescroll: " .. 
		bg2_timescroll,0,14+8*20,7,0)
	print_outl("bg 2 timescroll dir: " .. 
		bg2_timescroll_x .. " y:" .. bg2_timescroll_y,0,14+8*21,7,0)




	local function draw_pal()
		for j=0,3 do
			for i=0,3 do
				rectfill(92 + i*8,8 + j*8,99+ i*8, 15 + j*8, j*4 + i)
			end
		end
	
	end

	if l_set_cursor_pos == 3 then
		draw_pal()
		
		spr(1,92,60)
		spr(3,104,60)
		spr(4,116,60)
		
		spr(40,92,70)
		spr(12,104,70)
		spr(14,116,70)
	elseif l_set_cursor_pos == 4 then
		pal(palettes[loaded_level[1][4]+1], 0)
		draw_pal()
		pal(0)
	end




	draw_cursor()
end

function unedit_l_settings()
		menuitem(2 | 0x300, "level settings",
		edit_l_settings)
	_update = _update_l_editor
 _draw = _draw_l_editor
end



function edit_l_texture()
	
	_draw = _draw_l_textures
	
	_update = _update_l_textures
	
end

l_textures_cursor = 0

mouse_index = 0

function _update_l_textures()
	mous_x, mous_y = stat(32),stat(33)+ l_textures_cursor * 32
	
	local mous = stat(34)
	local mous_prim = mous&0b1
	local mous_scnd = mous&0b10
	
	if (btnp(3)) l_textures_cursor += 1
	if (btnp(2)) l_textures_cursor -= 1
	
	l_textures_cursor = mid(0,l_textures_cursor,48)
	
	mouse_index = 1
	if (mous_x < 42) mouse_index = 0
	if (mous_x > 84) mouse_index = 2
	
	mouse_index += ((mous_y-8)\38)*3
	
	if btnp(4) or (mous_prim==1 and (mous_prev&0b1) != 1) then
		if mouse_index > -1 and mouse_index < 120 then
			unedit_l_texture()
		end
	end
	
	mous_prev = mous
end

function _draw_l_textures()
	cls(0)
	camera(0, l_textures_cursor * 32)

	
	local prev_map_pos = peek(0x5f56)
	poke(0x5f56,0x20)
	
	local grid_x = 0
	local grid_y = 0
	

	for i=0, 119 do
		
		local draw_x = grid_x * 38 + 8
		local draw_y = grid_y * 38 + 8
		
		local r_col1, r_col2 = 5,13
		
		if (mouse_index == i) r_col1,r_col2 = 12, 7
		
		rect(draw_x-1,draw_y-1,draw_x+32,draw_y+32,r_col1)
		
		local t_x,t_y,t_mode = get_texture(i)
		
		local xl,yl = 1,1
		
		if t_mode == 2 then
			xl,yl = 2,2
		elseif t_mode == 3 then
			xl,yl = 4,4
		end
	
		for j=0,3 do
			for i=0,3 do
				local t_spr = mget(t_x+i%xl,t_y+j%yl)
				spr(t_spr,draw_x+i*8,draw_y+j*8)
			end
		end
		
		rect(draw_x-1,draw_y-1,draw_x+xl*8,draw_y+yl*8,r_col2)
		
		
		grid_x+=1
		if grid_x > 2 then
			grid_x = 0
			grid_y += 1
		end
		
	end
	

	poke(0x5f56,prev_map_pos)
	
	
	draw_cursor()
	
end

function unedit_l_texture()
		_draw = _draw_l_editor
	_update = _update_l_editor
	
	if select_texture_for_tile then
		loaded_level[2][s_t_f_t_tile_id][1] = mouse_index
	else
		selected_tex = mouse_index
	end
	
	unpack_lvl()

end


__gfx__
00000000aaaaa99a9aaaaaaa89aa99980b0b0b0b2b2b2b2b32022023333333330000000200000002222222221111111116777761167777610502050000000000
00000000a98888888888898898888882232323233333333333022033232222320000002222222222221111221222112265115155611111155555757500000000
00000000999899999988998998888882bbbbbbbbbbbbbbbb32322323003003000000020202020202222222221111111176611115711111150502070000000000
00000000988888888888888898888882002222003b3223b332033023222332222000002220202022211111122112211271165117711111172522252000000000
000000008888888888888889988888820002200023b33b3232033023222332220200020202020202222222221111111175151115711111150502050000000000
0000000098888888888888899888888200022000232bb23232322323003003002222222222222222221111221211122271115616711111167575555500000000
000000009888888288888888988888820022220033b33b3333022033232222322222222222222222222222221111111156615151511111160702050000000000
00000000988882228822228882222228333333333b2222b332022023333333332222222222222222222222222221222151176111666666610500050000000000
77777770899888888888888888888888000000000000000000000000000000001111111120011002000200002222222265777756000000001111111100000000
70000077a98888888888888888888888000000000000000000000000000000001111111122011022000200000200002051611115000000001211717200000000
70000707a99988888888898888888888000000000000000000000000000000001111111120211202000202000020020076111565000000001111171100000000
70007007988988889889999888888888000000000000000000000000000000001111111120022002020202001112211171115667000000002112211200000000
70070007a99999888889888888888888000000000000000000000000000000001111111120022002020202001112211176156115000000001121111100000000
70700007a98888888888899988888888000000000000000000000000000000001111111120211202020202000020020071661116000000007172112200000000
77000007999889988888888888888888000000000000000000000000000000001111111122011022020222200200002061156166000000001711111100000000
07777777988888888888888888888888000000000000000000000000000000001111111120011002020222002222222256575561000000002221222100000000
aaaaa99a9aaaaa99a9a9a9a9a2a2a2a2000000000000000000000000111111111111111122222221020202000000000000000000000006000000000000000000
a9888888888898889888988892222222000000000000000000000000222222221222122222222211020202000000000000000000000075500000000000000000
99989999998999898898889888988898000000000000000000000000111111111111111121111111222202000000000000000000000750570000000000000000
88888888888888888888888988828289000000000000000000000000222222222212221222222211022222200000000065777756007500000000000000000000
98888998998998888888888888888288000000000000000000000000882228281111111121111111020202000000000075666555075000000000000000000000
88888888888888888888888888888888000000000000000000000000222222221222122222222211020202000000000070000007650000000000000000000000
88888888888888888888888888888888000000000000000000000000888888881111111111111111022202000000000070000007075000000000000000000000
88888888888888888888888888888888000000000000000000000000888888882221222122211111020202000000000050000005007000000000000000000000
9998888888888888a98888998888889a000000000000000000000000888888882222211121111121222222220000000022222221222221210000000000000000
98888888888888888821128988888888000000000000000000000000882888282111121221111121222222220000000021111111221212120000000000000000
aa88888888888888898882888998999a000000000000000000000000222222222111211221111121222222220000000022222111212121110000000000000000
a888888888888888921111288888889a000000000000000000000000288828881111111221111121222222220000000065777756657777560000000000000000
99998899888888998888888988999999000000000000000000000000222222221111111221222221222222220000000075666555756665550000000000000000
a988898888888888882112898888988a000000000000000000000000111111111121111221111111222222220000000072211117721111170000000000000000
aa99999888999999988828888888999a000000000000000000000000212222222222222211111111222222220000000071111117712111170000000000000000
a99aaa99a9aaa99a998889898888889a000000000000000000000000111111111111111122212221222222220000000052111115511111150000000000000000
0aaa9988888888200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9988888899888820000000000000000000010010000000000000000000000000000000000000000000000000000000055766555555555555555555555555555
a9888888888888820000000000000000100100100000000000000000000000000000000000000000000000000000000000006660000000000000000000000000
a8888888888888880000000000000000010101010000000000000000000000000000000000000000000000000000000015766511111111111000000000000000
98988888888888880000000000000000011101010000000000000000000000000000000000000000000000000000000077776777777777777110000000000000
98888888888888880000000000000000011112110000000000000000000000000000000000000000000000000000000066666666666666666667100000000000
88888888888828880000000000000000010121120000000000000000000000000000000000000000000000000000000077777777777777777777771000000000
88888888888888880000000000000000201221120000000000000000000000000000000000000000000000000000000066666666666666666666666700000000
8888888888888888799279927272a2a2121221220000000000000000000000000000000000000000000000000000000066666666666666666666666666600000
88888888888888827989798979a8a898121212210000000000000000000000000000000000000000000000000000000066666666657111111111115611170000
8888888888882282a989a989a8a8a898122121210000000000000000000000000000000000000000000000000000000065111156671111111111111611111000
8888888888888882a989a989a8a8a8a8212121210000000000000000000000000000000000000000000000000000000061111116611111111111111611111100
8888888888288882a989a989a8a898a8212122210000000000000000000000000000000000000000000000000000000061177116611111111111111611111110
88228888888888229989a98998a8a898212121210000000000000000000000000000000000000000000000000000000061711716611111111111111611111111
2888888888888221a989a989a898a8a8121211220000000000000000000000000000000000000000000000000000000061111116651111111111117611111115
0288222222222210a989a989a898a8a8121212120000000000000000000000000000000000000000000000000000000061177116666677777777776677777777
0000000088828882a989a989a8a8a8a8121212120000000000000000000000000000000000000000000000000000000061711716666666666000000000000000
00000000222222229989a989a898a8a8121221210000000000000000000000000000000000000000000000000000000061111116666666666000000000000000
0000000082888288a989a989a8a8a898122122210000000000000000000000000000000000000000000000000000000061177116666666666600000000000000
0000000022222222a989a98998a898a8212212210000000000000000000000000000000000000000000000000000000061711716666666666600000000000000
0000000088828882a989a989a8a898a8212212210000000000000000000000000000000000000000000000000000000061111116666666666660000000000000
0000000022222222a9899989a8a8a898222222220000000000000000000000000000000000000000000000000000000051111115555555555550000000000000
0000000082888288a989a989a8a8a8a8221222220000000000000000000000000000000000000000000000000000000066555566666666666660000000000000
0000000022222222a989a989a8a8a8a8221222220000000000000000000000000000000000000000000000000000000055555555555555555550000000000000
00000000888888829989a989a8a8a8a82a2aa2a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088228888a989a989a898a8a8aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888a9899989a8a8a8989aaa99a80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000028222282a989a98998a898a89a8a99890000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088828888a989a989a8a898a8898998980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000082222222a989a989a8a8a898988a89980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888288a9889988a898a888989a89890000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000228222228822882288228822889888890000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000056666505d6666dd000000000000000000666600000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000561e11655181e115000000dd7700000006666660000000000000000000000000000000000000000000000000000000000000000000000000
0044400000000000611e11166181e11600006dd77ddd00006d66666d000550000000000000000000000000000000000000000000000000000000000000000000
004f40000000000061e11116618111160006dd755dddd00066d6666d005885000000000000000000000000000000000000000000000000000000000000000000
004ff000000000006e55eee6d1811116006dd566665ddd00666d66dd005885000000000000000000000000000000000000000000000000000000000000000000
0040000000000000688511166dddddd600dd56118165dd00666d6dd5000550000000000000000000000000000000000000000000000000000000000000000000
0040000000000000d88511155555555506dd611e8116ddd0066ddd50000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000055555555151515150dd561e181165dd000dd5500000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006d766dd666dd76660dd56e558ee65dd006066d00006d06d00000000000000000000000000000000000000000000000000000000000000000
000000000000000000055000000550000dd768858116ddd007d6d0dd607ddd000000000000000000000000000000000000000000000000000000000000000000
00000000000000000566665005666650007d68858115dd00706dddd06dd6dddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000056e1116556e1116500ddd555555ddd006dd55ddd07d55ddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000061e1555661e15556000dddd55dddd0006dd55ddd6dd55dd00000000000000000000000000000000000000000000000000000000000000000
000000000000000068e15d8668e15d860000dddddddd000006dddd0d66dddddd0000000000000000000000000000000000000000000000000000000000000000
0000000000000000d8e158d5d8e158d5000000dddd0000006d06ddd0006ddd0d0000000000000000000000000000000000000000000000000000000000000000
000000000000000005666650056666500000000000000000006dd0d00660dd000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000006dd7000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000006dd77d00000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000006dd77ddd0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000dd755ddd0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000d7755ddd0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000077dddddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000dddddd00000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000dddd000000000000000000000000000000000000000000000000000000000000000000
0056650011175111111117778888888911dd111198dd988988889899000000000000000000000000000000000000000000000000000000000000000000000000
0d7666d0117517111117775798a98a981ddd11118ad7a8988d89aa98000000000000000000000000000000000000000000000000000000000000000000000000
5776ddd5157571711575651789a97a981dd5d11187a97aa8869aa989000000000000000000000000000000000000000000000000000000000000000000000000
666ddd555576171557565171add7a9881d577771aa777778567777aa000000000000000000000000000000000000000000000000000000000000000000000000
66dddd5157655557517511718ddd99981177aa998977aa99d677aa99000000000000000000000000000000000000000000000000000000000000000000000000
56ddd5511751777117571711d5ddaaa817a7791197a77998d6aaa988000000000000000000000000000000000000000000000000000000000000000000000000
0dd5551075771551757175118d5d98881a1a97118a8a9789889a9898000000000000000000000000000000000000000000000000000000000000000000000000
005511005711551157115111d588898891191191988988988888a989000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000211110000000000000022
aa000000000aaaaa00000000000000aa000000000000000000000000000000001111110000000022221100000000000022100000000211111111000000002222
00aa00000aaa000000000000000aaaa0001110000000000000000110000000001111111100000222221100000000022222110000002211111111111100222211
00000000000000000aaaa00000000000001111000000011000011110000001101111111100000222221100000022222211111000002111111111111122221111
00000000000000000000000000000000001111000011011000011110001101111111111102222222211111112222211122111100022111211111111122111211
0990000000aaaaa00000000000000000011111000011011111011110001101111111111122222222211111112211122222111110021211211111111112221111
000000000aa999aa0000990000000000111111000111111111111111001101111111111122222222211111111122222222111111221211211111111122111211
00000000aaaa9999990000000aaa0000111111001111111111111111001111111111111121212121211111112222222211111111212211111111111112221111
9000009aaa9999999aa00000aaa9a999111111000000000000000000000000000000111022222222211111112222211122111111212211112100000022111211
000999aa9999999999aa000aa99a9a00111111100000000000000000000000000000111121112121211111112211122222111111122211112111000012221111
99aaaaaa99aaaa009999a0aa99999999111111110000000000000000000000000000111122222222211111111122222222111111122211112111110022111211
0aaaaaa9aaa99aaa99999a999a999990111111100000000000011000000000000000111121212121211111112222222211111111222111112111111112221111
aaaa999aa999999a9999999aa99aa999111111110000000000111111000000000000111122222222211111112222211122111111222111212111111122111211
aa9999aa999aaa9999aaa9999aaa9a9a111111110000000000111111000000000010111121212111211111112211122222111111221211212111111112221111
a99aaaaa99aaa9999aa9999999a9a9aa111111100000000000111111000000001011111122222222211111111122222222111111221211212111111122111211
99aaaaa99aa999999999999999aaaaa9111111100000000000111111000000001111111121112111211111112222222211111111212211112111111112221111
9aaa99999999999999990900aaa99999000000000000000000000000000000000000000000000000000000000880000000000000000000000000000081110000
aaa9999999999aaaaaaa9090a00aaaa9000000000000000000000000000000000000000000000000002100088888800000000000008100000000000811111000
a9999aa9999aaaa999aaa9090aa99999000000000000000000000000000000000000000000880000002110028881100000000000881110000000008211111000
99999999999999999a99aa00aa9aa999000000000000000000000000000000000000000000288000002110022211100000000088811110000000082221111100
aaaaaaa999999999909999a0a9aa9990000000000000000000000000000000000000000000211000002100022211000000000888111111000008222222111100
aaaa999009099999090900009a999909000000000000000000000000000000000000211002211000021100222211000000008882211111100082222222111110
a99090099099999990900aa900909090000000000000000000000000000000000000211112210000021000222211000000088222211111100222222222211110
9909090009aa99990000aa9000000000000000000000000000000000000000000002211102200000020000222110000000822222221111002222222222211100
00000000000000000000000000000000000000000000000000000000000000000002211102010000001000222100000002222222221111002222222222221100
00000000000000000000000000000000000000000000000000000000000000000002211100288000210000221000000002222222222110000222222222221100
00000000000000000000000000000000000000000000000000000000000000000002111000028880000002020100880000222222222110000222222222222100
00000000000000000000000000000000000000000000000000000000000000000002111000022110000000201028810000222222222210000022222222222000
00000000000000000000000000000000000000000000000000000000000000000002111000222110000000000022110000022222222200000022222222220000
00000000000000000000000000000000000000000000000000000000000000000022110000221100008880000022110000022222220000000002222222000000
00000000000000000000000000000000000000000000000000000000000000000021110000221100008888000022110000002222000000000002222200000000
00000000000000000000000000000000000000000000000000000000000000000021110000221100002888800022110000002200000000000000220000000000
__gff__
0001010101010101000000000303040000010101000000000000000003000400010101010000000100000000020000000000010100000001000000000202000000000000000000000000000000000000000000000000000000000008000000000001000000000000000000080000000000010000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce000000000000000000c3c000000000c20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd180000000000c80000c00000c300c1c2c34444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9dac5dbdccfdd18c4d6d8c6c518c4c7c2c1d0d3d0d1d2e25464546454646454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9da18dbdcdfdd18d418181818181818e3e1d3d0e0e1d1d07474747474747474000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1003133a1861711227372854000000000000131261717113282854640c1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e1e2c3c00000000000000000000000000000302716113710b2854541c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0120210203222332050404050a09080a38290a380a09080a401313415252525274747474444444440a1b1b0a1a00001a0a09080a30313111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11131233111313330600000628280b2838181838d93a3ad913131213727272721313131354545454190000192a00002a1900001933101011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1202033211031233060000060b28282838181838d93a3ad913131313123271611313131364645464190000191a00001a1900001933101011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3031033137373737050707051818181839290a390ad9d90a501313517171617113131313646454640a1b1b0a0a09090a0a09090a02020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0181120b01816103100063057307692a6404740829605a043c0d2025580079042765010c39020600241a1e095c6a01873400206504221e035a6a623e30004a285c9b2600a1615c503b1002005b1e1e001b005917792a474f582121000f005824214312e2582c2b080a005c29260140c05920330320a6262337020100592c3508
0000260f3a01010009ae2d01208308ae2f01208303ae2e0120835b41352405005854160b1f00593e350a410f6556300705005c57310323416471370086035e603bc448c5586e3a05472601713700800301602e01060000612cc1459f625f25090200016225022244011936c040e30000003fe50f21193a0d474f000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
018061031000700231005c0607090b0058110c0305005e0d0f0303005e080a040500581608020200581a0a01020058180f040400581e1501030058201301030058221101040058211802030058241701020058251500010058271203030058271703030058261b030200582c17010300582b1302030058311503040000000000
__sfx__
0010000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c072300133202336043
0113800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
000380003f3043e05338033320032e0622a04226022220711c05118021120010e0600803004010020003eb673ab3734b1730b762ab4626b1620b751ab4516b1510b640a3500a0500a0500a0500a0500a0500a050
011180001075010750107501d7501f750000002eb0730b1732b1734b3634b2730b2734b3736b673e3000201004020060300604008040080400201002010028762eb762eb662cb662ab762eb0730b2734b3736b47
00108000000000000000000000000000000000000000000022136281462a146221162e1762e1762e1762e1072c1072c1072c1762c1262c1662c1662c1662c1662c1662c1662c1262211622147361473813736127
00108000000000000000000000002a1562a15626166261662c14628166281662a1762a1762a1763010730107301073010730107301072e1762e1762e1662e1762e1762c1762e1762e1762e1662c1662c1662c166
0111800010105101050e174243540a1441833406124029643e06338033320032c87322071180110a00038b072ab2318b050ab2400b6338a332aa132ea032ea622aa5228a4226a1224a2224a1222a1222a1222a12
520080003f6103f6103f6100e6100e6100e6100e6100e610356103561036610366103761037610376103761000000376003760037600376103761037610376103761037600376003760037600376003760037600
4b0200003d6103d6303d6303d6203d6103d6103d6103c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52010000143200d31109311093112062020620206200d33020320253303d6203d610396103561510615066152a6050d6033b6033f6033f6053f6053f6053f6053f6053e6053f6053f6053f605006050060500000
52010000143200d3110a3110a31019620196200d3303863025330253203e6203d6102b6101c610166100f61005610036000060000600006000000000000000000000000000000000000000000000000000000000
52010000143710d361043510135100340366502533025340366403664036640366303663036630366303663036630366303663536635366253663536645366353662536625366103661000000000000000000000
500100001533008330034200042001320016100161000610006100461009600096000960009600096000960009600000000000000000000000000000000000000000000000000000000000000000000000000000
50010000193600d350063500335001340013400363003630036200562009610096100961009610096100861007610066100661005610056000460000000000000000000000000000000000000000000000000000
5a020000183730537301373016700566002660086600f6500165006645056450064004630086300663004620036200762006625056250162503610036100c6100261304613056150061500615086150061408614
080200001007008070030700006000050156700f6700c6600b6650b6550a655096400863007630066300562004620046250361502615016150161002610016100161301613006150061500615006150061400614
4801000014300105000c6000a30007400056000460006600064000640006600046000060000600006000960009600000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030200000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
0a0100001275016760197601b75022750257502774000000000002c6602c6602c6402c630000003b6503b6303b6303b6253b6203b6203b6103b61500000000001370017700187001c70000000000000000000000
0a0100003b6303b6303b6303b6303b6303b6303c6002c6202c6202c6202c6202c6202c6200000025745227501f7501b7401774514730127200f7200f720000000000000000000000000000000000000000000000
080200000f64014641186311d610156532a730227601e750167400f7300a720087100371003710037100300000601000030060400600006010300004700037000070000700000000000000000000000000000000
001000001d75019750137500f7500f750107501075010750107201172011710117001870018700187001b700197001970019700197001970019700197001a7001e700217001a7000070000700007000070000700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
511200000331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f3200331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f320
511200000131001310013100131001310013100131001310013100c3200c3200c32012320123200f3200f32001310013100131001310123200f3200131012320013100f320013110131016320153241532514320
4b1200002e625029002e6252e60037625396002e6252e6250000037625000000a6252e6252560537625376053a6103a6253a6103a62537625396002e6252e6251362537625000000000037625000001362537625
0412000027c251bc201b3261bc00273261bc351bc051bc351bc001bc351b3161bc3519c20193151ac201ac100fc251bc201b3261b400273261bc351b4001bc351b4101bc351b4161bc351ec201b3151bc201bc10
041200001bc251bc201b3260f325273261bc201bc120d3251bc251bc351b3161bc351ec201931520c2020c101bc251ec201b3261b4002732620c2220c1222c351b41020c351b4161bc001ec201b31519c201ac20
0112000027c251bc201b3260f323273261bc351b3131bc350f3231bc351b3261bc351b326193151ac201ac101b3261bc101b3261b32222c2222c221631220c2220c2220c221ec221ec22183121ec1219c201ac10
4d1200001bd201bd201bd201bd201bd101bd101bd101bd101bd101bd101bd1019d2020d2022d2020d201bd201ed201bd201bd201bd201bd101bd101bd101bd103361533614336153361019d2019d201ed201ed20
4d1200001bd201bd201bd201bd201bd101bd101bd101bd101bd101bd101bd101bd101bd101bd101bd101bd1022d3519d2022d3519d2021d3519d2021d3519d2020d351ad2020d351ad201ed301bd2019d301ad20
0b1200000f33303c002e62503c003e63503c002e6252e62503c043e62503c000a6253e62503c00376253e6250f33300c003e6250f32300c003e6150f3232e6252e6003e615376252e6003a6253a6253a6253a625
0b12000003c2003c2003c2503c2003c3503c2003c2003c2203c1403c2503c2003c2003c2503c2003c2503c2001c2001c2001c3501c2001c2001c2501c2001c2001c2301c2001c2101c2303c2003c2006c2006c30
0b12000000c3000c2000c2500c3000c2000c2000c2300c2200c1000c2000c2000c2506c2006c2003c2003c200ac200ac200ac250ac200ac2516c200ac200ac250dc200dc2001c2001c250fc2008c2008c2506c20
4d12000020d2020d2020d2020d2020d1020c1020c1020c10204102041022420224202242022d102241022410224350b420224350b42027d350b42027d350b42022c350d42022c350d42022c351e43020c301a420
0010000018430184300c4310c4301f4301f4001d4321d4321d4321d2321d2221d2221d2121d2121d2020000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000018430184300c4310c4301f4303660311432114321143211232112221122211222112221122211212053550735505355073550a3550c355073550c35505355073550a3550c35511355133551635518355
001000000215502100001000e155001000d10002155021550215002155021550e1500e100001000f100021000210002100001000010002100021000e1000e1000010000100001000010000100001000010000100
010900201bc2620c1627c2620c161bc2624c161bc2620c161bc2623c161bc2620c1627c2624c161bc2620c161bc2627c161bc2620c1627c2628c161bc2617c261bc2627c2623c2627c261bc2627c2623c2627c26
0109002017c2620c1623c2620c1617c2624c161bc2623c1623c2623c1617c2620c1623c2624c1617c2620c1623c2627c1617c2620c1623c2628c1617c261bc2617c2627c2623c2627c2617c2627c2623c2627c26
01100000022500730002250073000a3000c3001630018300052500000005250000000000000000000000000004250000000425000000000000000000000000000325000000022500000000000000000000000000
311000000a2300a2300323003230032100323003410034100d2300d23003230034200331003230034100341006230062300343003430032100323003210032100a2300a220084300843003230032100343003420
01100000143361b3160f3301b336143101b3100f3301b3160f3301b3100f3361b3260f3300d31012330113300f3350f3201633016326163300f3160f320143300f3361402014336143200f3101b3301233011330
011000000f336123160f330123360f3101b3100f3300f3100f336143100f330143361b3100f3200f330113301d3260f3201d3260f3201d3260f3201d3260f3201e3260f4201e3260f4201e3260f4201e3260f420
011000002c3263331627310333362c3163331627316273162733633316273363332627312273142a3202933027335273352e3202e3262e33027316273102c330273262c0102c3362c31027330333302a33029330
1110000020336273161b3302733620316273101b330273161b336273161b33627326193101b3101e330193301b3351b3352232022326223301b3161b320203301b3362003020336203201b310273301e3301d330
311000000a1100a1200a1300a1300a1300a1300a1300a1200393003130039300312003933039330392003920069300313006930031300c1200c1200c1200c1200493003130049300392003923039230392303923
311000000b1100b1200b1300b1300b1200b1200b1220b1220493004130049300422203923039230392203922069300313006930031300d1220d1220d1220d1220793003130121320693206932069331212212922
3110000003350034400335003220032200323003410034100335003440033500322003210032300393003930064500f4400645003230032200323003210032100435012d40043500622006220063100631006310
31100000049500b450049500322003220032300341003410043500b440043500322003220032100340003400064500f9400645003220032200323003210032100735012d400735006d400622012d300631006310
111000001b3361e3161b3301e3361b310273101b3301b3101b336203101b33020336273101b3201b3301d330293261b320293261b320293261b320293261b3202a3261b3202a3261b3202a3261b3202a3261b420
03100000213333500015333214233e6301d611153233e6401532300300214332d600214230f3343c6350f332153330030039635213333e6301d621396253e6302133300300214231532338640386443864538640
01100000220502203022020160401603016030270402702025050250300d020190401903019030250402502024050240300c0201804018030180300c0400c0202305023030230201704017030170300b0400b020
011000002205022030160200a0400a0300a03016030160301e0501e0301e020060400603006030120301203020050200302002008040080300803014030140301c0501c030040200404004030040300403004030
012000000395000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 20222360
02 21222367
01 2028236f
02 21282470
00 2928256f
02 2a282470
00 29282644
00 2a282744
00 20282644
02 21282b44
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
01 323c3944
00 323c3944
00 3d3c3944
02 3e3c3a44
00 373c3344
02 383c3444
00 393c3644
02 3a3c3b44
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344

