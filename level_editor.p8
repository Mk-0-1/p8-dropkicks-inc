pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--
--

menu_state = 0

all_level_slots = {}

cursor_pos = 1

function unpack_pal(n)
	return {unpack(palettes, n*16+1, n*16+16)}
end


cam_x = 0
cam_y = 0

l_start = 12
l_end = 32 -- not inclusive - shouldn't write to row 32+ in map

function _init()
-- enable mouse buttons
	poke(0x5f2d, 0b1)
-- enable extended palette
	poke(0x5f2e, 0b1)

-- use extended map
	poke(0x5f56,0x80)

	load_m_menu()
end

w_text = "main menu"
s_text = "select a level slot:"
s_col = 7

function load_m_menu()
	menu_state = 0
	-- input delay
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
	
	-- have to temporarily switch maps for tline
	poke(0x5f56,0x20)
	
	local level_num = 1
	for i=1, #lvls_info do
		local lvl_title_info = split(lvls_info[i][1],"|")
		local lvl_main_info = split(lvls_info[i][2],"|")
	
		local yval = i*s + 12
	
		local l_txt_col = 7
		if cursor_pos == i then
			l_txt_col = 12
			rect(1, yval - s\2, 127, yval + s\2,l_txt_col)
		end


		local pal_transp_col = lvl_main_info[7]
		
		-- col
		rectfill(2, yval - s\2+1, 126, yval + s\2-1,pal_transp_col)
		rect(2, yval - s\2+1, 126, yval + s\2-1,l_txt_col)
		

		
		-- bg sample
		for	j=0, s-4 do
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, lvl_main_info[8]*8,  j/8+1, 1/8, 0)
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, lvl_main_info[8+10]*8,j/8+1, 1/8, 0)
		end
		
	
		print_outl("level " .. i, 4,yval-2,l_txt_col,1)
		level_num = i
		
	end
	
	poke(0x5f56,0x80)

	
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
	
	cursor_pos = mid(1,cursor_pos, #lvls_info)
	
	if btnp(4) then
		load_l_editor()
	end
	
end

ld_l_size_x = 16
ld_l_size_y = 8

function unpack_myb(a)
	if (type(a) == "table") return unpack(a)
	return a
end

function chain_call(f,args)
	local res = {}
	for i=1, #args do
		add(res,f(unpack_myb(args[i])))
	end
	return unpack(res)
end



--get from og map
function mget0x20(x,y)
	if (x >= 128 or y >= 64 or x < 0 or y < 0) return 0
	if y < 32 then
		return @(0x2000 + x + y*128)
	else
		return @(0x1000 + x + (y-32)*128)
	end
end

function mset0x20(x,y,v)
	if (x >= 128 or y >= 64 or x < 0 or y < 0) return false
	if y < 32 then
		poke(0x2000 + x + y*128, v)
		return true
	else
	 poke(0x1000 + x + (y-32)*128, v)
		return true
	end
end

-->8
-- token savers

function unstr(str)
	return unpack(split(str))
end

function _pars(v)
	if(v=="true")return true
 if(v=="false")return false
 if(v=="nil")return nil
 if(v=="{}")return {}
	return v
end

function mod_tabl(tab, kv)
	local k,v = unpack(split(kv, "/"))
	k,v = split(k),split(v)
	for i=1,#k do
		tab[k[i]]=_pars(v[i])
	end
	return tab
end

function mod_tabl2(tab, k,v)
	local k = split(k)
	for i=1,#k do
		tab[k[i]]=_pars(v[i])
	end
	return tab
end

-->8
-- vector implementation

--2d vector operations
function vec2_new(vx,vy)
 a={x=vx, y=vy}
 setmetatable(a,vec2)
	return a
end

vec2={
	
	--add/sub 2 vectors 	
	__add=function(a,b)return vec2_new(a.x+b.x,a.y+b.y)end,
	__unm=function(a,b)return vec2_new(-a.x,-a.y)end,
	__sub=function(a,b)return a+(-b)end,
	--mul div vector by a scalar
	__mul=function(a,s)return vec2_new(a.x*s,a.y*s)end,
	__div=function(a,s)return a*(1/s)end,
	__idiv=function(a,s)return vec2_new(a.x\s,a.y\s)end,
	__eq=function(a,b)return a.x==b.x and a.y==b.y end
}
-- some basic vectors
vec2_zero=vec2_new(0,0)
vec2_right=vec2_new(1,0)
vec2_down=vec2_new(0,1)
vec2_left=-vec2_right
vec2_up=-vec2_down

--copying
function v2c(v)return v*1 end

function vec2_len(v)
	-- alternate way of getting hypotenuse by trigonometry
	-- avoids squaring, more accurate in almost all cases
	-- and does not break at very small or big values
	local v2, v2_c = v2c(v), v.x
	-- take bigger side, otherwise can ultrasmall/ultrasmall and horrible accuracy

	if abs(v.x) > abs(v.y) then
		v2.y = 0
	else
		v2.x = 0
		v2_c = v2.y
	end
	local l = abs(v2_c)/cos(vec2_angle(v,v2))
	--if (l < 0.1) l = 0
	return l
end

function vec2_normalized(v)
	if (vec2_len(v) == 0) return v
	return v/vec2_len(v)
end

function vec2_limit(v)
	if (vec2_len(v) > 1) return vec2_normalized(v)
	return v
end

function vec2_dot(v1,v2)
	return v1.x*v2.x+v1.y*v2.y
end

function vec2_angle(v1,v2) -- gives shortest angle between two vectors
	local angle = atan2(v1.x,v1.y) - atan2(v2.x,v2.y)
	if (angle> 0.5)angle-=1
	if (angle<-0.5)angle+=1
	return angle
end

function projection(a,b)
	local k = vec2_dot(a,b)/vec2_dot(b,b)
	return vec2_new(k*b.x,k*b.y)
end

function vec2_rotate(v,a)
	return vec2_new(v.x*cos(a) + v.y*sin(a), -v.x*sin(a) + v.y*cos(a))
end

-->8
-- main level editor

function load_l_editor()
	menu_state = 1
	mouse_ready = false
	
	
	load_level(cursor_pos)
	
	cam_x,cam_y = 0,0
	l_curs_x = 0
	l_curs_y = 0
	w_text = "editing level " .. cursor_pos
	s_text = "x:0 y:0"
	
	-- shorted delay for movement
	poke(0x5f5c, 8)
	poke(0x5f5d, 1)
	
	
	menuitem(2 | 0x300, "level settings",
	edit_l_settings)
	
	menuitem(3 | 0x300, "save level",
	save_level)
	
	_draw = _draw_l_editor
	_update = _update_l_editor
end

loaded_level = {}
loaded_level_title = {}
loaded_level_main = {}

l_curs_x = 0
l_curs_y = 0
l_c_col = 12
l_can_place = false


mous_x = 0
mous_y = 0

mous_prev = 0b0

selected_tex = 0


function draw_cursor()
	pset(mous_x, mous_y,7)
	pset(mous_x-1, mous_y,5)
	pset(mous_x+1, mous_y,5)
	pset(mous_x, mous_y-1,5)
	pset(mous_x, mous_y+1,5)
end

function _draw_l_editor()
	cls(loaded_level_main[7])
	camera(cam_x,cam_y)
	camera_x,camera_y = cam_x,cam_y
	
	draw_loaded_bg()
	
	if mous_prev&0b10 == 0 then
		-- draw grid 
		for i=1, ld_l_size_x do
			line(i*8*4, 0, i*8*4, ld_l_size_y*32,1)
		end
		for i=1, ld_l_size_y do
			line(0, i*8*4 ,ld_l_size_x*32, i*8*4,  1)
		end

		-- draw sign deco
		for i=1, #(loaded_level_signs or {}), 15 do
			local x1,y1,x2,y2,mspr_i,turn,size_mult = unpack(loaded_level_signs,i)
			rect(x1,y1,x2,y2,14)
			
			local spr_pos = vec2_new(x1+x2,y1+y2)/2
			draw_m_sprite(spr_pos, split(m_sprites[mspr_i]), turn=="true" and mous_x < spr_pos.x, 8*size_mult)
		end
	end
	
	map(0,0)
	

	rect(l_curs_x*32, l_curs_y*32,l_curs_x*32+32, l_curs_y*32+32, l_c_col)
	
	
	if (mous_prev&0b10 == 0) draw_extras()
	
	draw_sidebar()
	
	
	print_outl(w_text,cam_x+1,cam_y+1,7,4)
	print_outl(s_text,cam_x,cam_y+121,7,9)
	
	draw_cursor()
	
--stat(34) -- mouse buttons (bitfield))
	
end

function draw_m_sprite(pos,m_spr,is_left,spr_size)
	if m_spr then
		local e_spr,s_x,s_y,a_t,a_n = unpack(m_spr)
		if e_spr >= 0 then
			local spr_size = spr_size or 8
			local spr_sw,spr_sh = s_x*spr_size, s_y*spr_size
			--e_spr += ((anim_c\a_t)%a_n)*s_x
			sspr(e_spr%16*8,e_spr\16*8,s_x*8,s_y*8,pos.x-spr_sw/2,pos.y-spr_sh/2,spr_sw,spr_sh,is_left)
		end
	end
end

function text_box(str,screen,x,y,xlen,ylen,c1,c2)
	if (screen=="true") camera(0,0)
	if (c1>-1)rrectfill(x,y,xlen,ylen,0,c1)
	if (c2>-1)rrect(x+1,y+1,xlen-2,ylen-2,0,c2)
	print(str,x+6,y+4,7)
	camera(cam_x,cam_y)
end

function draw_extras()
	
	print("menu cam pos" ,loaded_level_title[5], loaded_level_title[6]-8, 4)
	rect(loaded_level_title[5],loaded_level_title[6],loaded_level_title[5]+128,loaded_level_title[6]+128,4)
	
	print("pl" ,loaded_level_title[3], loaded_level_title[4]-8, 12)
	
	rect(loaded_level_title[3]-2,loaded_level_title[4]-2,loaded_level_title[3]+2,loaded_level_title[4]+2,12)
	

	for i=1, #(loaded_level_entities or {}), 4 do
		local e_type,ex,ey,e_extra = unpack(loaded_level_entities, i)
		local props_c,props_e = ntt_types[e_type*2-1],ntt_types[e_type*2]
		local entity = mod_tabl({},props_e)
		
		draw_m_sprite(vec2_new(ex,ey), split(m_sprites[split(props_c)[3]]), entity.is_left, entity.spr_size)

	end
	
	for i=1, #(loaded_level_signs or {}), 15 do
		local x1,y1,x2,y2,mspr_i,turn,size_mult = unpack(loaded_level_signs,i)
		rect(x1,y1,x2,y2,14)
		
		if mous_x > x1 and mous_y > y1 and mous_x < x2 and mous_y < y2 then
			text_box(unpack(loaded_level_signs,i+7))
		end
	end


end


function draw_sidebar()
	rectfill(cam_x+90,cam_y+74,cam_x+128,cam_y+128, 1)

	rectfill(cam_x+90,cam_y+92,cam_x+128,cam_y+128, 0)
	

	t_col = 13
	if mouse_on_sidebar then

		if mous_y-cam_y >= 93 then
			t_col = 7
		elseif mous_y-cam_y >= 84 then
			rectfill(cam_x+90, cam_y+84, cam_x+128, cam_y+90, 2)
		else
			rectfill(cam_x+90, cam_y+74, cam_x+128, cam_y+83, 2)
		end
	end


	line(cam_x+90,cam_y+74,cam_x+128,cam_y+74, 7)
	line(cam_x+90,cam_y+92,cam_x+128,cam_y+92, 7)
	
	
	line(cam_x+90,cam_y+74,cam_x+90,cam_y+128, 7)
	
	rect(cam_x+93, cam_y+94, cam_x+94+32, cam_y+95+32,t_col)
	
	
	local t2 = selected_tex & 0b00111111
	local extra_t = (selected_tex & 0b11000000) >> 6
	
	local alt_t = (extra_t & 0b1 == 0b1)
	local alt_l = (extra_t & 0b10 == 0b10)
	
	local tx,ty = get_texture(t2)
	
	-- texture

	for j=0,3 do
		for i=0,3 do
			local t_spr = tile_spr(mget0x20(tx+i,ty+j), alt_t, alt_l)
			spr(t_spr,cam_x+94+i*8,cam_y+95+j*8)
		end
	end
	
	local t_c = 1
	local l_c = 1
	if (alt_t) t_c = 7
	if (alt_l) l_c = 7
	
	print_outl("texture ",cam_x+92,cam_y+76,t_c,0)
	print_outl("layout ", cam_x+92,cam_y+86,l_c,0)
	
end



mouse_on_sidebar = false
mouse_on_canvas = false

mouse_ready = false

function _update_l_editor()
	mous_x, mous_y = stat(32)+cam_x,stat(33)+cam_y
	l_curs_x = mous_x\32
	l_curs_y = mous_y\32
	s_text = "x:"..l_curs_x.." y:"..l_curs_y
	

	local should_reload = false

	mouse_on_sidebar = mous_x >= cam_x+90 and mous_y >= cam_y+74 
	mouse_on_canvas = not mouse_on_sidebar



	if (btnp(0)) cam_x-=8
	if (btnp(1)) cam_x+=8
	if (btnp(2)) cam_y-=8
	if (btnp(3)) cam_y+=8

	local mous_p = stat(34)
	local mous_prim = mous_p&0b1
	local mous_scnd = mous_p&0b10
	
	if (btnp(5) or mous_scnd==0b10) s_text = "x:"..mous_x.." y:"..mous_y
	
	
	if (mous_p == 0) mouse_ready = true

	if not mouse_on_canvas then
		s_text = ""
		l_c_col = 2
	end
	
	if mouse_on_sidebar then
	
		if btnp(4) or (mous_prim==1 and (mous_prev&0b1) != 1) then
			if mous_y >= cam_y+93 then
				edit_l_texture()
			elseif mous_y >= cam_y+84 then
				selected_tex ^^= 0b10000000
			else
				selected_tex ^^= 0b01000000
			end
		end
	
	end


	if mouse_on_canvas then
		if l_curs_x >= 0 and l_curs_x < ld_l_size_x and l_curs_y >= 0 and l_curs_y < ld_l_size_y then
			l_c_col = 12
			l_can_place = true
		else
			l_c_col = 3
			l_can_place = false
		end
		
		local curs_arr_pos = l_curs_x%ld_l_size_x + (l_curs_y*ld_l_size_x) + 1
		
		--place tile
		if l_can_place and mouse_ready and (btnp(4) or mous_prim==1) then
			draw_tile(selected_tex, l_curs_x, l_curs_y)
			lvl_tiles[curs_arr_pos] = selected_tex
			w_text = "editing level " .. cursor_pos
		end
		
		--sample tile
		if l_can_place and mouse_ready and (btnp(5) or (mous_scnd==0b10)) then
			selected_tex = lvl_tiles[curs_arr_pos]
		end
		
	end

	
	mous_prev = mous_p
end


function load_level(index)

	loaded_level = lvls_info[index]
	loaded_level_title = split(loaded_level[1],"|")
	loaded_level_main = split(loaded_level[2],"|")
	loaded_level_entities = split(loaded_level[3],"|")
	loaded_level_signs = split(loaded_level[4],"|")
	

	local map_pos_x = loaded_level_main[1]
	local map_pos_y = loaded_level_main[2]
	ld_l_size_x = loaded_level_main[3]
	ld_l_size_y = loaded_level_main[4]
	

	lvl_tiles={}
	for j=0, ld_l_size_y-1 do
		for i=0, ld_l_size_x-1 do
		 add(lvl_tiles, mget0x20(map_pos_x+i,map_pos_y+j))
		end
	end

	mset_level()

	pal(unpack_pal(loaded_level_main[6]), 1)
end

function mset_level()

	-- clear map
	memset(0x8000, 0, 0x4000)
	
	-- draw all tiles
	for t_c=0, #lvl_tiles-1 do
		draw_tile(lvl_tiles[t_c+1], t_c%ld_l_size_x, t_c\ld_l_size_x)
	end
	
end


function get_texture(index)
	return (index%32)*4 ,(index\32)*4 +4
end

function tile_spr(s, alt_t, alt_l, random, rs)
	extra_b = (s & 0b11000000) >> 6
	s1 = s & 0b00111111
	

	
	if alt_l then
		if (extra_b & 0b1) == 0b1 then
			-- flip 3rd bit
			s1 ^^= 0b100
			-- swap to first sprite in 2x2 segment
			s1 &= 0b11101110
		end
		if (extra_b & 0b10) == 0b10 then
			-- flip 4th bit
			s1 ^^= 0b1000
			-- swap to first sprite in 2x2 segment
			s1 &= 0b11101110
		end
	end
	
	
	if random and (s1 & 0b100000 != 0) and (s1 & 0b001000 == 0) then -- in bottom left part of spr page
		srand(rs)
		local r = rnd(10)
		-- flip 1st bit
		if (r > 9) s1 ^^= 0b1 
	end
	
	
	if alt_t and not fget(s1,7) then
	 -- alt texture
		s1 += 0b01000000
	end


	return s1
end

function draw_tile(t,x,y)
	
	local tiles = {}
	
	local t2 = t & 0b00111111
	local extra_t = (t & 0b11000000) >> 6
	
	local alt_t = (extra_t & 0b1 == 0b1)
	local alt_l = (extra_t & 0b10 == 0b10)
	
	 
	local t_x,t_y = get_texture(t2)
	
	for j=0,3 do
		for i=0,3 do
			add(tiles, mget0x20(t_x+i,t_y+j))
		end
	end
	
	
	for j=0,3 do
		for i=0,3 do
			local mod_tile = tile_spr(tiles[i + j*4 +1], alt_t, alt_l, true, (x*4+i) + (y*4+j)*ld_l_size_x)
		
			mset(x*4+i,y*4+j, mod_tile)
		end
	end		

end

function save_level()
	
	lvl_string=""

	for i=1, #loaded_level_main do
		local dat = loaded_level_main[i]
		if i==11 or i==21 then
			dat = tostr(dat, true)
		end
	
		if (i!=1) lvl_string = lvl_string .. "|"
		lvl_string = lvl_string .. dat
	end
		
	printh(lvl_string, "editor_level_".. cursor_pos .."_settings.txt", true)
	
	-- tiles
	
	local map_pos_x = loaded_level_main[1]
	local map_pos_y = loaded_level_main[2]
	
	for i=0, ld_l_size_x*ld_l_size_y-1 do
		mset0x20(map_pos_x + i%ld_l_size_x, map_pos_y+i\ld_l_size_x, lvl_tiles[i+1])
	end

	
	cstore(0x1000,0x1000,0x2000)
	
	w_text = "level saved!"
	return false
end

l_set_cursor_pos = 6

function edit_l_settings()
		menuitem(2 | 0x300, "back to editor",
		unedit_l_settings)
		
	l_set_cursor_pos = 6
	l_set_list_cam = 1
	
	camera_x = 0
	camera_y = 0
	
	_update = _update_l_settings
 _draw = _draw_l_settings

end

function _update_l_settings()
	mous_x, mous_y = stat(32),stat(33)+l_set_list_cam*8-8
	
	if btnp(2) then
		l_set_cursor_pos -= 1
		if (l_set_list_cam - l_set_cursor_pos > 1) l_set_list_cam -= 1
	end
	if btnp(3) then
		l_set_cursor_pos += 1
		if (l_set_cursor_pos - l_set_list_cam > 10) l_set_list_cam += 1
	end
	
	if btnp(2) or btnp(3) then
		if l_set_cursor_pos == 5 then
			music(loaded_level_main[l_set_cursor_pos], 1000)
		else
			music(-1)
		end
	end
	
	l_set_cursor_pos = mid(1,l_set_cursor_pos,27)
	
	
	l_add=0
	if btnp(4) then
		l_add=1
	end
	if btnp(5) then
		l_add=-1
	end
	
	if (btnp(4) or btnp(5)) and l_set_cursor_pos > 4 then
	
		if l_set_cursor_pos == 11 or l_set_cursor_pos == 21 then
			l_add *= 0x0.08
		end
	
		loaded_level_main[l_set_cursor_pos] += l_add
	
		loaded_level_main[14] %= 2
		loaded_level_main[15] %= 2
		loaded_level_main[24] %= 2
		loaded_level_main[25] %= 2
		
		
		if l_set_cursor_pos == 1 then

		elseif l_set_cursor_pos == 5 then
			music(loaded_level_main[l_set_cursor_pos], 1000)
		elseif l_set_cursor_pos == 6 then
			pal(unpack_pal(loaded_level_main[l_set_cursor_pos]), 1)
		end
			
	end
	
end

function draw_bg(offset) 

	mod_tabl2(_ENV,"b_img_indx,b_pal,b_sc,b_prlx,b_ofx,b_ofy,b_wx,b_wy,b_timx,b_timy",{unpack(loaded_level_main,offset+8)})

	pal(unpack_pal(b_pal+16), 0)
	
	local p_sc = b_sc*8
	local a_p_sc = abs(p_sc)
	local scrl,ts_x,ts_y = b_prlx, b_timx,b_timy
	local wrap_x,wrap_y = b_wx==1, b_wy==1
	
	local scroll_x,scroll_y = -b_ofx+camera_x*scrl+time()*ts_x, -b_ofy+camera_y*scrl+time()*ts_y
	
	if(wrap_x) scroll_x %=8*a_p_sc
	if(wrap_y) scroll_y %=4*a_p_sc

	local function map_scaled(ox,oy)
		for	i=0,7 do
			for	j=0,3 do
			 local n = mget0x20(b_img_indx*8+i, j)
				sspr((n&0b1111)*8,n\16*8,8,8, camera_x-scroll_x+i*p_sc+ox, camera_y-scroll_y+j*p_sc+oy,p_sc,p_sc)
			end
		end
	end
	
	for i=0, (128\(8*a_p_sc)+1)*b_wx do
		for j=0, (128\(4*a_p_sc)+1)*b_wy do
			map_scaled(8*a_p_sc*i,4*a_p_sc*j)
		end
	end

	pal(0)
end

l_set_list_cam = 1
camera_x = 0
camera_y = 1



function draw_loaded_bg()

	draw_bg(0)
	draw_bg(10)

end

function _draw_l_settings()
	cls(loaded_level_main[7])

	camera_y = l_set_list_cam*8-8
 camera(0, camera_y)
	
 draw_loaded_bg()

	r_col = 12
	if (l_set_cursor_pos <= 4) r_col = 14
	rectfill(0,l_set_cursor_pos*8+6,128,l_set_cursor_pos*8+14,r_col)
	
	print_outl("level " .. cursor_pos .. " settings",0,0,7,6)
	
	if l_set_cursor_pos <= 4 then
		print_outl("please change these manually",0,8,3,6)
		print_outl("in the .p8 file",56,16,3,6)
	end
	
	desc_strings={
	"map x: ",
	"map y: ",
	"x size (megatiles): ",
	"y size: ",
	"music index: ",
	"main palette: ",
	"clear color: ",
	
	"background 1 (back) : ",
	"1 palette : ",
	"1 scale : ",
	"1 parallax : ",
	"1 x offset: ",
	"1 y offset: ",
	"1 x wrap: ",
	"1 y wrap: ",
	"1 x timescroll: ",
	"1 y timescroll: ",
	
	"background 2 (back) : ",
	"2 palette : ",
	"2 scale : ",
	"2 parallax : ",
	"2 x offset: ",
	"2 y offset: ",
	"2 x wrap: ",
	"2 y wrap: ",
	"2 x timescroll: ",
	"2 y timescroll: "
	}
	
	for i=1, 27 do
		local dat_str=loaded_level_main[i]
		if i==11 or i==21 then
			dat_str=tostr(loaded_level_main[i],true)
		end
			print_outl(desc_strings[i]  .. dat_str , 0,16+8*(i-1),7,6)
	end



	local function draw_pal(y_of)
		for j=0,3 do
			for i=0,3 do
				rectfill(92 + i*8, 8+j*8+y_of, 99+ i*8, 15 + j*8 + y_of, j*4 + i)
			end
		end
	
	end

	if l_set_cursor_pos == 6 then
		draw_pal(0)
		
		spr(1,92,60)
		spr(28,104,60)
		spr(4,116,60)
		
		spr(27,92,70)
		spr(102,104,70)
		spr(36,116,70)
		
		spr(14,92,80)
		spr(44,104,80)
		spr(45,116,80)
		
		spr(164,92,90)
		spr(165,104,90)
		spr(183,116,90)
		
		spr(167,92,100)
		spr(176,104,100)
		spr(240,116,100)
		
	elseif l_set_cursor_pos == 7 then
	--	pal(unpack_pal(loaded_level_main[1][5]+16), 0)
		draw_pal(0)
	--	pal(0)
	elseif l_set_cursor_pos == 9 then
		pal(unpack_pal(loaded_level_main[9]+16), 0)
		draw_pal(0)
		pal(0)
	elseif l_set_cursor_pos == 19 then
		pal(unpack_pal(loaded_level_main[19]+16), 0)
		draw_pal(112)
		pal(0)
	end

	draw_cursor()
end

function unedit_l_settings()
		menuitem(2 | 0x300, "level settings",
		edit_l_settings)
	_update = _update_l_editor
 _draw = _draw_l_editor
	mset_level()
end



function edit_l_texture()
	_draw = _draw_l_textures
	_update = _update_l_textures
	
end

l_textures_cursor = -1

mouse_index = 0

tex_alt_l = false
tex_alt_t = false

tex_cam_y = 0

function _update_l_textures()
	tex_cam_y = l_textures_cursor * 32

	mous_x, mous_y = stat(32),stat(33) + tex_cam_y
	
	local mous = stat(34)
	local mous_prim = mous&0b1
	local mous_scnd = mous&0b10
	
	if (btnp(3)) l_textures_cursor += 1
	if (btnp(2)) l_textures_cursor -= 1
	
	l_textures_cursor = mid(-1,l_textures_cursor,13)
	
	mouse_index = 0
	if (mous_x > 32) mouse_index = 1
	if (mous_x > 64) mouse_index = 2
	if (mous_x > 96) mouse_index = 3
	
	mouse_index += ((mous_y)\32)*4
	
	if btnp(4) or (mous_prim==1 and (mous_prev&0b1) != 1) then
		if mous_y-tex_cam_y > 10 then
			if mouse_index > -1 and mouse_index < 64 then
				unedit_l_texture()
			end
		else
			if mous_x < 64 then
				tex_alt_t = not tex_alt_t
			else
				tex_alt_l = not tex_alt_l
			end
		end
	end
	
	mous_prev = mous
end

function _draw_l_textures()
	cls(14)

	camera(0, tex_cam_y)

	local grid_x = 0
	local grid_y = 0
	
	for i=0, 63 do
		
		local draw_x = grid_x * 32
		local draw_y = grid_y * 32
		

		
		
		local t_x,t_y = get_texture(i)
		
		for j=0,3 do
			for i=0,3 do
				local t_spr = tile_spr(mget0x20(t_x+i,t_y+j), tex_alt_t, tex_alt_l)
				spr(t_spr,draw_x+i*8,draw_y+j*8)
			end
		end
	
		
		
		grid_x+=1
		if grid_x > 3 then
			grid_x = 0
			grid_y += 1
		end
	end

		
	if (mouse_index >= 0 and mouse_index < 64) then
	
		rect(mous_x\32*32-1,mous_y\32*32-1,mous_x\32*32+32,mous_y\32*32+32,7)

	end
	
	
	
	rectfill(0,tex_cam_y,128,tex_cam_y+10,0)
	
	
	if mous_y-tex_cam_y < 10 then
		if mous_x < 64 then
			rectfill(0,tex_cam_y,63,tex_cam_y+10,1)
		else
			rectfill(64,tex_cam_y,128,tex_cam_y+10,1)
		end
	end
	line(0,tex_cam_y+10,128,tex_cam_y+10,2)
	
	local l_c = 0
	local t_c = 0
	if (tex_alt_t) t_c = 7
	if (tex_alt_l) l_c = 7
	
	
	print_outl("alt texture ", 12,tex_cam_y+2,t_c,1)
	print_outl("alt  layout",74,tex_cam_y+2,l_c,1)
	
	
	draw_cursor()
	
end

function unedit_l_texture()
	mouse_ready = false
	selected_tex = mouse_index + tonum(tex_alt_t)*0b01000000 + tonum(tex_alt_l)*0b10000000 
	
		_draw = _draw_l_editor
	_update = _update_l_editor
end


-->8
-- data


lvls_info = {
--1st array: title info
-- name/m_menu title
-- next lvl (0-indexed, -1 is finish)
-- player spawnpos x & y
-- camera pos in main menu
-- sub title
-- intro text


--2nd: ALL LEVEL PROPS

-- (1)map pos x, (2)map pos y, (3)x size, (4)y size
-- max level dimensions are 32x28 (cause of extended map limits and sprite sheet, for y you'd have to start at top)
-- (5)mus index
-- (6)pal index, (7)bg col

-- bg 1:
-- (8)image index
-- (9)pal index

-- (10)scale
-- (11)parallax
-- (12)offset x
-- (13)offset y
-- (14)wrap x
-- (15)wrap y
-- (16)timescroll x
-- (17)timescroll y

-- same for bg 2
--(10 things, 18-27)


--3rd: entity spawns
-- type, xpos, ypos, extrainfo

--4th: signs/deco
-- x1,y1,x2,y2, metasprite,turn to player, sprite size multiplier, textbox info (str,screen,x,y,xlen,ylen,c1,c2)

-- NOTE: try to not have more than 6 legs active at once. More kinda lags
{"mission 1|  2| 30|54| 464|0|construction site|from: hq                \n\nhello!        \n\nthis is some testing text.        \ngood luck with whatever\nyou're doing!",
	"0|22|30|4|0|2|1|2|7|3|0x0000.0800|48|-16|1|0|1|0|1|0|4|0x0000.2000|64|2|0|0|0|0",
		"4|510|84|0| 4|680|56|0| 4|825|83|0| 6|890|38|0", 
		"80|32|160|100|-1|false|1|press or hold\n🅾️ to jump!|false|80|86|60|18|9|-1| 440|20|510|100|0|false|1|jump off\n\f3hostile machines\f7\nto deal damage.|true|3|7|76|24|8|9| 720|20|780|120|0|false|1|❎ to grab objects\nlike \f3machines\f7 or\n\feunstable tiles\f7.|true|3|7|104|25|8|9",},
{"1-2| 3| 6|180| 0| 0||",
	"0|15|16|7|0|2|2|2|6|3|0x0000.0800|48|-12|1|0|1|0|1|3|5|0x0000.2800|-72|8|0|0|0|0",
		"4|194|152|0| 5|450|104|0",
		"20|130|80|220|-1|false|1|you can 🅾️ jump on \n\ffmetal walls\f7 or\n❎ latch onto them.|true|3|7|116|25|8|9"
},
{"1-3| 4| 8|170| 60|80||",
	"32|12|16|8|0|3|2|1|7|3|0x0000.1000|-102|20|1|0|0|0|0|10|4|0x0000.2000|-40|16|0|0|0|0",
		"6|420|190|0",
},
{"1-4| 5| 6|50| 60|80||",
	"0|12|7|5|0|3|2|1|7|3|0x0000.1000|-115|24|1|0|0|0|0|10|4|0x0000.3000|-156|36|1|0|0|0",
},
{"mission 1| -1| 6|80| 60|80||",
	"48|12|12|6|0|3|2|1|7|3|0x0000.1000|-160|28|1|0|0|0|0|10|4|0x0000.3000|-220|28|1|0|0|0",
},
}

m_index,start_lvls=0,split"0,1,2,3"


-- storable in map maybe
palettes = split[[
	1,2,10,   128,132,142,15, 8,9,10,138,    12,9,14,13, 0,
	1,131,10, 2,8,9,10,       3,138,135,143, 12,138,14,13, 0,
	143,15,10,  142,143,0,7, 130,2,136,8,  12,2,13,6, 142,
	143,15,10,  128,130,0,7,   130,136,8,10,   12,136,13,6, 142,
	
	143,15,10,  142,143,0,7,   130,136,8,10,   12,136,13,6, 142,
	2,14,10,  128,130,0,7,   130,136,142,15,   12,136,13,6, 130,
	136,142,10,  128,130,0,7,   130,136,14,15,   12,136,13,6, 2,
	136,142,10,  2,136,0,7,   128,130,2,8,   12,130,13,6, 2,
	
	141,15,10, 130,141,0,7, 130,136,8,10,  12,136,13,6, 130,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,
	5,7,3,4,5,6,7,8,5,4,3,2,7,14,15,0,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,
	
	133,134,11, 129,1,0,7 ,134,13,6,7, 12,6,14,13,  0,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  0,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  0,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  0,
	

	
	
	
	0,1,2, 0,0,1,2, 0,0,1,2, 0,0,1,2,  0,
	0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,  0,
	0,0,1, 0,0,0,1, 0,0,0,1, 0,0,0,1,  0,
	0,1,1, 0,0,1,1, 0,0,1,1, 0,0,1,1,  0,
	
	0,2,2, 1,0,2,2, 1,0,2,2, 1,0,2,2,  1,
	2,1,1, 2,2,1,1, 2,2,1,1, 2,2,1,1,  2,
	1,1,2, 1,1,1,2, 1,1,1,2, 1,1,1,2,  1,
	1,2,2, 1,1,2,2, 1,1,2,2, 1,1,2,2,  1,
	
	2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2,  2,
	5,0,1, 2,5,0,1, 2,5,0,1, 2,5,0,1,  2,
	4,5,0, 0,4,5,0, 0,4,5,0, 0,4,5,0,  2,
	4,4,5, 2,4,4,5, 2,4,4,5, 2,4,4,5,  2,
					
	4,5,5, 4,4,5,5, 4,4,5,5, 4,4,5,5,  4,
	4,4,4, 4,4,4,4, 4,4,4,4, 4,4,4,4,  4,
	5,5,5, 5,5,5,5, 5,5,5,5, 5,5,5,5,  5,
	5,5,5, 5,5,5,5, 5,5,5,5, 5,5,5,5,  5,

]]


-- extras

ntt_types = {
 "3.5,0.4,1, 1,1,2","", -- default box - used as template sometimes
 "1,0.6,3, 1,2,3","b_type,stmn,stmn_l_b,armor,slip/2,80,40,1.1,0.98", -- player - high slipperiness allows for easy 2 block climb
	
	-- utils (3+)
	"0.5,0.1,2, 1,1,1","slip/0.7", -- basic limb for entities
	
	-- enemies (4+)
	"4,0.5,4, 2,3,4","b_type,stmn,armor,gun,ai_p,ai_a,enemy,smoke/3,10,1.1,1,2,4,true,1", -- basic turret
	"4,0.8,5, 2,3,4","b_type,stmn,armor,gun,ai_p,ai_a,enemy,smoke,range_in,range_out/4,30,1.1,2,2,5,true,1,0,30", -- spider box
	"6,0.3,6, 2,3,4","b_type,stmn,armor,gun,ai_p,ai_a,enemy,smoke,flying,range_in,range_out/1,20,0.4,1,3,5,true,1,true,0,35", -- flying drone - easy mode, no retreat
	

	-- projectiles (7+)
	"3,0.1,8, 1,1,2","contact_dmg,special_stand,smoke,stmn/15,true,3,0.1", -- small
	"3,0.1,9, 1,1,2","contact_dmg,special_stand,smoke,stmn,bounce/12,true,3,10,0.85", -- sawblade
	
	-- items (9+)
	"3.5,0.1,10,1,4,2","smoke/2",
	
	"4,6,1, 1,1,2","e_type,smoke/tmp tile,1" -- tmp tile
	-- 6x the mass to enable proper bounces

}

m_sprites = {
	-- sprite,x size,y size, anim frame len, anim total frames
	"176,1,1,3000,1", -- default
	"-1,1,1,3000,1", -- blank (no draw)
	"160,1,1,3000,1", -- player
	
	-- enemies (4+)
	"164,1,1,3000,1", -- turret
	"165,1,1,3000,1", -- box
	"180,1,1,2,3", -- saucer
	"170,2,2,3000,1", -- tank
	
	-- projectiles (8+)
	"167,1,1,3000,1", -- small
	"184,1,1,1,2", -- sawblade
	
	-- items (10+)
	"176,1,1,3000,1" -- grab
}


__gfx__
00000000555555545555555444444444aabbbaadba9999aabbbbbaabaaaabbbbb980089a00000000bbbbbabb8b8b8b8b000000005554555477777e7877787778
00000000555555445444444455555554b99999d89988889abadddddddddddddbbb8008ba000000008b8998b8aaaaaaaa00000000544454447ee78788eee88e88
00000000544444445444444454444444b99dddd899999999adddd9ddddddddaab9b99b9a0000000098b88b89bbbbbbbb00000000544454447ee788787877e888
00000000555555445444444454445454b9ddddd8a8888889add9d9ddddd9ddddb98bb89a00000000009bb900aba88aba00000000444444447e78eee8e8e888ee
00000000544444445444444454454454a9ddddd89999999addd9999dd999d999b98bb89a00000000009bb9008abaaba800000000555455547788eee8778e7788
00000000555555445444444454444454a9ddddd89988889aad999999d9999999b9b99a9a0000000098b88a898a8bb8a8000000005444544478e78ee8ee888ee8
00000000444444445444444454444454adddddd8a9999999ad99999999999998bb8008aa000000008b8998a8aabaabaa00000000544454447eeee8e878eeee88
00000000555444444444444444555554d888888daa999a9aaa99988899999888b980089a00000000aaaaaaaaab8998ba0000000044444444e888888e8ee88888
11111111222222225555555544444444aaa99999999999ab9999999999999999779997ff00000000babbbbba9b9b9b9b54005554444444445555555559559959
11111111222222225555555544444444ba9999999999999a9d9d999999d999d97f9999f700000000b8aaaa8a9a9a9a9a54055054555555555444444545999999
11111111222222225555555544444444baaa99999aa9aaabaa9d9d9d99d99dd9ff79997700000000babaabaabbbbbbbb54550054444444445500005544599555
11111111222222225555555544444444a99a9999999999abdd9ddd999ddaad9df779977f00000000aaaaaaaa99aaaa9955500054555555550550055044459999
11111111222222225555555544444444baaaaa9999aaaaaaadddddaaaddd9daa779997ff00000000baaaaaa8888aa88855500054444444440055550044445999
11111111222222225555555544444444ba9999999999a99bbaaaaddddddddddd7f9999f700000000aabaaba8888aa88854550054555555550005500055444599
11111111222222225555555544444444aaa99aa99999aaabddaddddd9ddddaabff79997700000000a8aaaa8888aaaa8854055054444444445555555544444459
11111111222222225555555544444444b9999999999999abbaabbbad9dbbbabbf779977f00000000aa888a889999999954005554555555554444444445554445
44444444444444444554455455555555baa9baa9aaa99999bbbbbaababbbbbaabbbabbba99888989ba97ba9b55455545fffffffe7777777ebbbad999bbbabbba
555545554555445544554455545544559ddd9ddddd99dddddadddddddddda9ddbaa8baa888888888aa9bba9b55455545feffeefe7377337ebaa8d999baa8baa8
44444444444444445445544554455445a9baa9aaa99999aaaaadaaaaaadaaadabaa8baa899999999ba9bba9b55455545fffeeffe7773377ebaa89999baa8baa8
55455545544554455544554455445545dddddd9999dddd99dddddddddddddddda888888888899988ba9bba9b55455545ffeefffe7733777ea88899dda8888888
44444444444444444554455455544555baadaaa9baadaa99addddaadaadaaddddddd9ddd99999999ba9bba9b55455545feeffefe7337737eddddbbbabbbaddd9
45554555454445554455445554554455999d9ddddd9dddd9ddd9d99ddddd9d9dd9d99d9d99999999ba9bba9b55455545feffeefe7377337ed9ddbaa8baa8dd99
44444444444444445445544554455445adaaa9aa999aa9aa9d99d999d9dd999d99999d9999999999ba9bba9b55455545fffffffe7777777ed99dbaa8baa89d9d
555455545554555455445544555555559999ddd99dd9999999999999d9d999999999999999999999ba9bba9b55455445eeeeeeeeeeeeeeee99998888a888999d
05000505050000050000000500000005b9b9b9b90000000099999999999999999999999999999999aa9bba9bbba9a99a9bb99bb9554444449999bbba444fe844
05000505050000055555555500000055a89898980000000099999999999999999999999999999999ba9bba9ba222222599bb99bb554444559999baa85557e855
5500555505000505050505050000050599a999a90000000099999999999999999dd99d9d99999999ba9baa9b92272225b99bb99b554444449999baa8444fe844
555005550500050550505055500000559999999a000000009999999999999999dddddddd99999989ba9bba9b92722225bb99bb99554444459999888877f7f7f7
0500050505000505050505050500050599999999000000009999999999999a99bbbabbba88888888ba9bba9b922222259bb99bb955444444bbbaddd9eeefeeee
05000505050005055555555555555555999999990000000099999999a99aaaa9baa8baa899989999ba9bba9ba222222599bb99bb55444455baa8d9d98887e888
05000555550055055555555555555555999999990000000099999999999a9999baa8baa888888888ba99aa99bbaaa99ab99bb99b55444444baa8d999444fe844
5500050555000505555555555555555599999999000000009999999999999aaaa8888888888888889988998899999999bb99bb9955444445a888999d555fe854
0000000000000000000000000000000000000000000000009bbbaa9aaaba99880000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000baa99999999999980000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000ba99a999a99999980000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000b9999999999999990000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000a9a99999999999990000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000a9999999999999990000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000099999999999989990000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000089999998899999980000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000099999999999999990000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000099999999999999980000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000099999999999988980000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000099999999999999980000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000099999999998999980000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000099889999999999880000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000089999999999998880000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088998888888888880000000000000000000000000000000000000000000000000000000000000000
5544554554545544545555455545545400000000000000005b5bb5b55b55bb5b0000000000000000bb9aaa99bbb99a9900000000000000000000000000000000
545454554554545454555455454544540000000000000000bbbbbbbbbbbbbbbb0000000000000000baa9999bbaaaa99b00000000000000000000000000000000
554445455455445454555455454545550000000000000000abbbaababbababbb0000000000000000aa99bb99aaaaa9ba00000000000000000000000000000000
454554454554545555555545544545450000000000000000ababaa9aabaabaab0000000000000000999baaa9aaaa999900000000000000000000000000000000
5454544454554554554555445455554500000000000000009a9aa9a9aaa9ba9a0000000000000000bb99aa9b99999bbb00000000000000000000000000000000
454544454545445555455454555545550000000000000000a99b9aa9a9a99a9a0000000000000000aaa999bbaa9bbbaa00000000000000000000000000000000
454454544545445455545455455545450000000000000000a9ab9a9aa99a99a90000000000000000aa9bbb9aa99baaaa00000000000000000000000000000000
45445454554554555554555555555545000000000000000099a9999a999999a90000000000000000a9bbaaa99999aaaa00000000000000000000000000000000
0054005400000005000040040400450000000000000000009999999999a999990000000099599999bbb99b999999b9aa00000000000000000000000000000000
055440454000005440540040440450400000000000000000999999a99a99a9990000000095595999bbaabaabbb9bba9900000000000000000000000000000000
045440054050454504050054450554050000000000000000999999a999999a990000000059455959aaa9aaabbaa9a99b00000000000000000000000000000000
05404454454045500545050450050454000000000000000099a999999999a9a90000000059455955aaa99a999a9b999900000000000000000000000000000000
4540404544544500454545455450545500000000000000009a9999999a99a9aa0000000055454459b9aa99bbb9baa9bb00000000000000000000000000000000
5054405545544504540555455454554500000000000000009a999999a99999a90000000045444549aa9b9bbaaa9a9bbb00000000000000000000000000000000
54544554550445045554555554555454000000000000000099999999999a999a0000000054545454a9baabaaaaa9bbaa00000000000000000000000000000000
44545454055445444555545555555455000000000000000099999999999999990000000054445444999a99aaaa999aaa00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000003000000eeeeeee600eeee00000000000002200000222200006666000000000000000000000000000000000000000000
000000000000000000000000000000000e000000666663e60eeeeee000022000002332000237732006666666000000000000000000000000000000ee77000000
008880000000000000000000007000706e66600066663636e8e66ee8002332000237732023777732666666666600000000000ee00ee0000000007ee77eee0000
008e80000007070000070700000707006e66660063366366ee6336e8023773202373373227777772666666666666000000e8eee00eeeee000007ee799eeee000
008ee000000000000007070000700070e3e33e3e36e36666ee63368802377320237337322777777266666666666666000eee8ee66eeeeee0007ee966669eee00
00800000000000000000000000000000eeeeeeee3e636666eee668860023320002377320237777326666666666666666eeeee8866eeeeee800ee96666669ee00
0080000000000000000000000000000066666600633e66660ee88860000220000023320002377320eee6666666666666eeee88866eeee88807ee66663666eee0
00000000000000000000000000000000666666006666666600886600000000000002200000222200666eeeeeeeeeeeeee8886688886888880ee9636363669ee0
00000000cc7c7ccc3b73b77b4444477700eee60000eee60000eee600006606600606660000606600666666666666666600666886688666000e79666636669ee0
0e0000e0c7e7ec7cb37377b8444777e70ee666600ee666600ee6666060606600066660660606666066666666666666e3000068633686000007ee6e666666eee0
eeff7feec78787e7e3777b8b457efe67366366363e366363e3663663666066666066066066066006666666666666e3e3000008633680000000ee96e66669ee00
eec7cce877eee877e377777757efe67466666666666666666666666606633006660336666663366066666eeee6e3e3e3000000866800000000eee966669eee00
e8cccc88e788ee8ee3777777547e66746666666666666666666666666003366066633066066336660666e6666ee3e3000000000000000000000eeee99eeee000
88eeee887eee8e77e3777b8847e76744336666333366663377666677666606660660660660066066006e666666e3000000000000000000000000eeeeeeee0000
08000080c7eee7ccb37377b87e747544773663770036630000766700006606066606666006666060000e66666e0000000000000000000000000000eeee000000
00000000cc777ccc3b73b77be7445444077007707000000700000000066066000066606000660600000000000000000000000000000000000000000000000000
00000000000333000000000022220000000000000000000000000000000000000000000000000000000000000000000000000000000a999900000000000000aa
000000002333333002222000222222200000000000000000000000000000000000000000000000aaa999000000000000aa900000000a9999999900000000aaaa
00000022333333333332222222222200004440000000000000000440000000000000000000000aaaa999000000000aaaaa99000000aa99999999999900aaaa99
00022222332322233233222323333220004444000000044000044440000004400000000000000aaaa999000000aaaaaa9999900000a9999999999999aaaa9999
0222222333321232222223333323222200444400004404400004444000440444000000000aaaaaaa99999999aaaaa999aa9999000aa999a999999999aa999a99
223332332321212212223332323121120444440000440444440444400044044400000000aaaaaaaa99999999aa999aaaaa9999900a9a99a9999999999aaa9999
233333323223333121113321121211114444440004444444444444440044044400000000aaaaaaaa9999999999aaaaaaaa999999aa9a99a999999999aa999a99
333323222133333311133212212111334444440044444444444444440044444400000000a9a9a99a99999999aaaaaaaa99999999a9aa9999999999999aaa9999
333231211333323222333221000000004444440044400000000000000000444000000000aaaaaaaa00000000aaaaa999aa999999a9aa9999a9000000aa999a99
222212333333222123322222000000004444444044444400000000000000444400000000a99a999a00000000aa999aaaaa9999999aaa9999a99900009aaa9999
121233233232121232232111000000004444444444444444000000000000444400000000aaaaaaaa0000000099aaaaaaaa9999999aaa9999a9999900aa999a99
112332222321212222321112000000004444444044444444000440000000444400000000a9a9a99a00000000aaaaaaaa99999999aaa99999a99999999aaa9999
133222122222112121211123000000004444444444444444004444440000444400000000aaaaaaaa00000000aaaaa999aa999999aaa999a9a9999999aa999a99
332121112211121112111232000000004444444444444444004444440040444400000000a9a9a99a00000000aa999aaaaa999999aa9a99a9a99999999aaa9999
121211111111111111111121000022204444444044444444004444444044444400000000aaaaaaaa0000000099aaaaaaaa999999aa9a99a9a9999999aa999a99
112111111111111111111211222222224444444044444444004444444444444400000000a999a99a00000000aaaaaaaa99999999a9aa9999a99999999aaa9999
002222221113331100000000111323320000000000000000000000000000000000000000000000000000000000000000000000000bb000000000000000b80000
02222233133333310022200012222211000000000000000000000000000000000000000000000000000000000000000000a8000bbbbbb00000000000b8888000
2222333333323233222222202221211100000000000000000000000000000000000000000000000000000000000bb00000a8800abbb88000000000ba88888800
2223332323232223333322221211132200000000000000000000000000000000000000000000000000000000000abb0000a8800aaa88800000000baa88888800
2332222212321211322232002111322100000000000000000000000000000000000000000000000000000000000a880000a8000aaa8800000000baaaa8888880
33212121212121112122130011121211000000000000000000000000000000000000000000000000000a880000aa88000a8800aaaa880000000baaaaa8888888
12121111121211111211122011212111000000000000000000000000000000000000000000000000000a888008aa80000a8000aaaa88000000baaaaaaa888880
1121111121111111211111221111111100000000000000000000000000000000000000000000000000aa888000aa00000a0000aaa88000000baaaaaaaa888880
00ffff000000000000eeee000000000000000000000000000000000000000000000000000000000000aa888000a08000008000aa8a8000000aaaaaaaaaa88800
0f7ffee000fffe000eeeeee00000000000000000000000000000000000000000000000000000000000aa8880000abb00a80000aa080000000aaaaaaaaaa88800
f7feeee80f7fee80e3eeeee30000000000000000000000000000000000000000000000000000000000a888000000abbb00000a0a00800bb000aaaaaaaaaa8000
ffeeee880ffee880ee7eee3e0000000000000000000000000000000000000000000000000000000000a888000000aa88000000a0080abb8000aaaaaaaaaa8000
ffeeee860feee860eee773e80000000000000000000000000000000000000000000000000000000000a88800000aaa8800000000000aa880000aaaaaaaaa0000
feeee8860ee88660eee7ee86000000000000000000000000000000000000000000000000000000000aa88000000aa88000bbb000000aa880000aaaaaaa000000
0ee88860008866000ee3e860000000000000000000000000000000000000000000000000000000000a888000000aa88000bbbb00000aa8800000aaaa00000000
008866000000000000838600000000000000000000000000000000000000000000000000000000000a880000000aa88000abbbb0000aa8800000aa0000000000
__gff__
8808080801010101010001010008838388888888010101018100010108880800080808080101010101010108888801010808080801008101010101010808010800080808000001010000000000000000080808080000010100000000000000000808080800000101000001010000000008080808000001010001000100000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d50000000000000000d3007170007100707173222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd36c4d6d7c6c513c4c70000d3c0c1c2e2d361607270736070632222222222222222eaeb00000000eeef0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d936d6dbdccfdd36d413131313131313c0c1e0d2d0d1d2c362616363616163622222222222222222fafb00ebed00feff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d93613dbdcdfdd361313131313131313d0d1d2e3e11010e366676667676667672222222222222222fdfaeeedfdedebed0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000012020200202020220202020062627274647060766666766000000001b0b1b1b005c00015e0b5e0b0008001ce0e0e0e00202010221212121202020207170717120202020242020202020202414f676767676f615262627262103212025253636363614365b4b5b5b001c001c001c001c1e231e231e011e1e1f373636
000000002020212002020202200320031436363656571617f6f6f6f6000000000008005c005c001c230800080008001c22464722e0e0e00122222222020202026170607002020202242003202020202414f676767676f615393939396262626236f936f936f914368a9a8a8a001c001c001c001c001c001c001c0000131f3637
000000002120202002020202200120013736363626262627f6f6f6f6000000001e081e5c0a0b0a0a0a0b5e0b1e0b1e2322565722e0e0e002cf02cf0203cf02ce6063616000000000242020202020202414f676767676f615606061602627262736421442254214361e011e1e5b4b5b5b002300231e231e231e011e1e13131f36
000000004242424202020202202020201637361737363617f9f9f9f9000000000008005c0008001c000823080008001ce0e0e0e0e0e0e002cececfce262626266362616300000000242020202020202414f676767676f615131313133939393936e925e936e91436000000008a9a8a8a001c001c001c001c000000002020201f
e0e0e0e002e0e002011e1e0113131313242425363625242426262726412020200223230200000000aaaaaaaa2b2b2b2b1ee0e0e0e0f0f0e0e0e0e0e0001c001c00000000000000000000000000000000000000000000000076767676000000002627262732323232000000000000000000000000000000002013131300000000
e0e0e0e020e0e0201ce0e01c2020202024242536362524243636363641410303231d213d72723232babababa2b2b2b2b30e0e0e0e0f0f0e0e0e0e0e0001c001c00000000310031000000000000000000000000000000000076767676000000001636371760606060000000000000000000000000000000002013131300000000
e0e0e0e020e0e0201ce0e01c2120202024242536362524243636363626262726231d033d61606020e5fb37e5212020211ee0e0e0e0f0f0e01e011e1ee0e0e0e000c3002b303130310000310000000000464705260000000076767676000000002020203d60606160323232323232323200000000000000002013131300000000
e0e0e0e002e0e002011e1e0102cecfcf2424253636252424363636361636363602020202424242422525242503202120001c011c1e2b2b1e00000000e0e0e0e032c3c32b30212030313330313232323276760437000000007676767600000000cf0202ce04040404060726270202cf0200000000000000002013131300000000
00000000193ebb030303030303030300000000000000000000000003030303030000000000001819000018199c9c0000000000001c00001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b230b3b3198c1903000000000000030000000000000000000000000000000000000000000000181900001819afaf33330000ac1eacacadac000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18192eae203e04030303030303030300000000000000000000000000000000009e9e9d9dad9e01010000a3a3a11c27270000ac001cacadac000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18190000199016000000000000002fa40000000000000000000000000000000000001b1b00ac1819aeac1815a11c1a0500001c001cacacac9ead00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18191e1e1804a3acad1e2b00000003a40000000000000000000000000000000000001c0000ac18191eac1815aeaea095000009951815179c009c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18190000181805afacb403aca0a08dbe000000000000000000000000000000003300ac0000ac1819aeac18150000a0951818181918151818181818180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18190000181815a0201806a9b03b95a400000000000000000000000000000000a7331ba91616160d390c1616a1a90c14191a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
969600008e8e0da0a018361a1a1a1aa40000000000000000000000000000000026262626a727aa9727aaaaaa97a41a140303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8e8facad278505adad08881d1e1e1ea400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
26269c9c1818199c9c0b0a1c000000a400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a000000001c00001c000000001c1d0000000000000000181915161614150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2f330000001c2929842a3333331b1c002b34bbbbbbbbbbb8881a1c0016160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
262626a7041b06170d969526a7171c3303b89597a7060f0d38280e85a78f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3636363615882626262626361526262626260406060606061426262626150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00100000000000000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c07230013
0113800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
000380003f3043e05338033320032e0622a04226022220711c05118021120010e0600803004010020003eb673ab3734b1730b762ab4626b1620b751ab4516b1510b640a3500a0500a0500a0500a0500a0500a050
0103000018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc30
00108000000000000000000000000000000000000000000022136281462a146221162e1762e1762e1762e1072c1072c1072c1762c1262c1662c1662c1662c1662c1662c1662c1262211622147361473813736127
00108000000000000000000000002a1562a15626166261662c14628166281662a1762a1762a1763010730107301073010730107301072e1762e1762e1662e1762e1762c1762e1762e1762e1662c1662c1662c166
0111800010105101050e174243540a1441833406124029643e06338033320032c87322071180110a00038b072ab2318b050ab2400b6338a332aa132ea032ea622aa5228a4226a1224a2224a1222a1222a1222a12
520080003f6103f6103f6100e6100e6100e6100e6100e610356103561036610366103761037610376103761000000376003760037600376103761037610376103761037600376003760037600376003760037600
000200000f523085330a5300f540145400d7401473020740277402c7402c7052c7052c7302c700000002c72000000000002c71000000000000000000000000000000000000000000000000000000000000000000
010200000300004000080000e00023300233000c300083000d200082000820008200082000820001200082002f60024600306001f600306001b60018600306001560013600126003860038600336000000000000
52020000123230e3233b6103b6153b61019315253253b614026150030000300003000030000300003000030000300003000000000000000000000000000000000000000000000000000000000000000000000000
52020000123330e32339610396153c6103c615253131d614126150061001600003000030000300003000030000300003000000000000000000000000000000000000000000000000000000000000000000000000
52010000143710d361043510135100340366502533025340366403664036640366303663036630366303663036630366303663536635366253663536645366353662536625366103661000000000000000000000
480200003c6100e3230c21337613296133661325024062102761008210366000321039605012003b6000420008200042000820008200082000820001200366000820036600366000000000000000000000000000
50010000193600d350063400333001430014200362003620036100561009610076100161009600066000260000600066000660005600056000460000000000000000000000000000000000000000000000000000
5a020000183730537301363016600565002650086400f6400164006635056350063004620086200662004620036200761006615056150161503610036100c6100261304613016150160500605086050060408604
0a0200003e6201b6403e620376403c62037640376201c6403962032630386200d620366200262033620016202f620026202d620026102a6100361523615026101e61502615146050260032600326003260032600
020200002435314353093533d6503c6503c6403a6503964037640356302f630336202f620306202d6202f6202f610286102f61024610306101f610306101b6101861030610156101361012650386003860033600
0e0100003e6203e6203d6203d6103b610386102f6102a91025910219101d9101b9101791015910113100f3100d3100c2100a21008210072100621004110041100311003110020100001002000000000000000000
020100003c6703c6502c6402c630209301d920129201c920129201a92010910189100e910159100b91010910089100c9100591008910059100491003910039100091000910009100a10000000000000000000000
4002000031630112202b6101122024610112101d610112101f610112201e6201121025610112102a610112102c61011210296101121026610112102261011200236001120022600112001d600112001a60012200
0a0100001275016760197601b75022750257502874000000000002c6602c6602c6402c630000003b6503b6303b6303b6253b6203b6203b6103b61500000000001370017700187001c70000000000000000000000
080200001b62314641186311d610156532a740227601b750167400f7300a720087100571004710037100300000601000030060400600006010300004700037000070000700000000000000000000000000000000
020100003d6303d6303d6202c61026610266101e6001e6003a6303a6203a6103a610010000d210082100820008210012000821019700197001a7001e700217001a70000700007000000000000000000000000000
3148002027d151ed1503d140ad150fd151ed1512d150dd1427d151ed150fd140ad150fd151ed150cd1508d1522c1503d1403d1403d1424c1506d141bc1508d1425c150000029c0020d150fd151ed1512d150dd14
317e000003d141ed150dd1503d140ad1503d141ed150dd1503d1403d141bc1503d1403d141bc1503c0003c0003d141ed150dd1503d1420d1503d141ed150dd150000000000000000000000000000000000000000
031000201bc2003c21306001bc2003c210000030600000003864038620386103864038620386103b600396001bc301bc101bc301ec201ec0019c301ac30376001bc203b6001bc203c6001bc203b60022c2021c10
611000000332003320033200f300003000035503355033200332003325033000f30003335033000a3000a3350b3200b3200b3200b320013200132001320013200332003320033200332003325033250332503325
151200000f430124300d4300f43014430034200f43016430034100d4350d430034100d430034100e430034100f430124300a4300f43014430034100f43016430014100d4350d430014100d430014100e43003410
091200000f3330000033610000000f3330000033610000000f32303220276100f2200f3230000033610000000f3330000033610000000f3330000033610072200f3430322033610336150f343000003361000000
531200001b6351b635376300c6310c6313763037610376300d300376352d6302d610376453764537645376451b6351b635376300c6310c6313763037610376300d300376352d6302d61037645376453764537645
5147000003c2003c2003c2003c2001c2001c2001c2001c2000c2000c2000c2000c200ac200ac2001c2003c2003c2003c2003c2003c2001c2001c2001c2001c2000c2000c2000c2000c200bc200bc200dc200ac20
511200000331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f3200331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f320
511200000131001310013100131001310013100131001310013100c3200c3200c32012320123200f3200f32001310013100131001310123200f3200131012320013100f320013110131016320153241532514320
4b1200202e62518b002e6252e60037625396002e6252e6250000037625000000a6252e6252560537625376053a6103a6253a6103a62537625396002e6252e6251362537625000000000037625000001362537625
0412000027c251bc201b3261bc00273261bc3519b001bc351bc001bc351b3161bc3519c20193151ac201ac100fc251bc201b3261b400273261bc351b4001bc351b4101bc351b4161bc351ec201b3151bc201bc10
051200001bc251bc201b3260f325273261bc220fc140d3251bc251bc351b3161bc351ec201931520c2020c101bc251ec201b3261b4002732620c2220c1222c351b41020c351b4161bc001ec201b31519c201ac20
0112000027c251bc201b3260f323273261bc351b3131bc350f3231bc351b3261bc351b326193151ac201ac101b3261bc101b3261b32222c2222c221631220c2220c2220c221ec221ec22183121ec1219c201ac10
051200001bd101bd201bd201bd201bd101bd101bd101bd101bd101bd101bd1019d2020d2022d2020d201bd201ed201bd201bd201bd201bd101bd101bd101bd103361533614336153361019d2019d201ed201ed20
051200001bd201bd201bd201bd201bd101bd101bd101bd101bd101bd101bd101bd101bd101bd101bd101bd1022d3519d2022d3519d2021d3519d2021d3519d2020d351ad2020d351ad201ed301bd2019d301ad20
0b1200000f33303c002e62503c003e63503c002e6252e62503c043e62503c000a6253e62503c00376253e6250f33300c003e6250f32300c003e6150f3232e6252e6003e615376252e6003a6253a6253a6253a625
0b12000003c2003c2003c2503c2003c3503c2003c2003c2203c1403c2503c2003c2003c2503c2003c2503c2001c2001c2001c3501c2001c2001c2501c2001c2001c2301c2001c2101c2303c2003c2006c2006c30
0b12000000c3000c2000c2500c3000c2000c2000c2300c2200c1000c2000c2000c2506c2006c2003c2003c200ac200ac200ac250ac200ac2516c200ac200ac250dc200dc2001c2001c250fc2008c2008c2506c20
0512000020d2020d2020d2020d2020d1020c1020c1020c10204102041022420224202242022d102241022410224350b420224350b42027d350b42027d350b42022c350d42022c350d42022c351e43020c301a420
0010000018430184300c4310c4301f4301f4001d4321d4321d4321d2321d2221d2221d2121d2121d2020000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000018430184300c4310c4301f4303660311432114321143211232112221122211222112221122211212053550735505355073550a3550c355073550c35505355073550a3550c35511355133551635518355
001000000215502100001000e155001000d10002155021550215002155021550e1500e100001000f100021000210002100001000010002100021000e1000e1000010000100001000010000100001000010000100
010900201bc2620c1627c2620c161bc2624c161bc2620c161bc2623c161bc2620c1627c2624c161bc2620c161bc2627c161bc2620c1627c2628c161bc2617c261bc2627c2623c2627c261bc2627c2623c2627c26
0109002017c2620c1623c2620c1617c2624c161bc2623c1623c2623c1617c2620c1623c2624c1617c2620c1623c2627c1617c2620c1623c2628c1617c261bc2617c2627c2623c2627c2617c2627c2623c2627c26
01100000032500730003250073000a3000c3001630018300062500000006250000000000000000000000000005250000000525000000000000000000000000000425000000032500000000000000000000000000
311000000a2300a2300323003230032100323003410034100d2300d2300323003420033100323003410034100623006230034300343003210032300a2310a2300843008430033300333003230032100343003420
01100000143361b3160f3301b336143101b3100f3301b3160f3301b3100f3361b3260f33011310123300d3300f3300f3201633016326163300f3160f320143300f3361402014336143200f3101b3301233011330
011000000f336123160f330123360f3101b3100f3300f3100f336143100f330143361b3100f3200f330113301d3260f3201d3260f3201d3260f3201d3260f3201e3260f4201e3260f4201e3260f4201e3260f420
1110000020336273161b3302733620316273101b330273161b336273161b336273261b3200b3401e3301d3301b3351b3352232022326223300f3401b32020330200300d34020330203201b310273301e3301d330
111000001b3361e3161b3301e3361b310273101b3301b3101b336203101b33020336273101b3201b3301d330293261b320293261b320293262232029326223202a326203202a326203202a3261e3202a3261d320
311000000a1100a1200a1300a1300a1300a1300a1300a1200393003130039300312003933039330392003920069300313006930031300c1200c1200c1200c1200493003130049300392003923039230392303923
311000000b1100b1200b1300b1300b1200b1200b1220b1220493004130049300422203923039230392203922069300313006930031300d1220d1220d1220d1220793003130121320693206932069331212212922
3110000003350034400335003220032200323003410034100335003440033500322003210032300393003930064500f4400645003230032200323003210032100435012d40043500622006220063100631006310
31100000049500b450049500322003220032300341003410043500b440043500322003220032100340003400064500f9400645003220032200323003210032100735012d400735006d400622012d300631006310
0120000022050220201603027040250500d0201903025040240500c020180300c0402305023020170300b0402205022030160200a0101e0501e0300602012010200502003008020080101c0501c0301002010010
03100000213333500015333214233e6301d611153233e6401532300300214332d600214230f3343c6350f332153330030039635213333e6301d621396253e6302133300300214231532338640386443864538640
01100000220502203022020160401603016030270402702025050250300d020190401903019030250402502024050240300c0201804018030180300c0400c0202305023030230201704017030170300b0400b020
011000002205022030160200a0400a0300a03016030160301e0501e0301e020060400603006030120301203020050200302002008040080300803014030140301c0501c030040200404004030040300403004030
011000000fc550fc550fc550fc551ec551bc551bc551bc550fc550fc550fc550fc5520c551bc551bc551bc5500000000000000000000000000000000000000000000000000000000000000000000000000000000
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
01 1e1d1f44
00 1e1d1c44
00 1e1d1f44
02 1c1d1f44
00 57424344
00 57424344
00 57424344
00 57424344
03 18196244
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
00 393c3544
02 3a3c3644
00 1a1b3c44
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

