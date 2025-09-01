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
	split"1,131,4, 2,8,9,10,       3,138,135,143, 7,12,14,13, 0",
	
	split"142,15,9,  130,2,6,7,   2,8,9,10,   7,12,14,13, 143",

	split"142,15,141,  142,15,6,7, 130,2,136,8,  7,12,14,13, 143",
	
	
	split"129,2,3,4,5,6,7,8,9,10,11,12,13,14,15,5",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0",
	split"5,7,3,4,5,6,7,8,5,4,3,2,7,14,15,0",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0",
	
	
	split"1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  0",
	
	split"4,2,3, 1,1,6,7, 1,0,2,11, 12,13,14,15,  0",
	
	split"4,5,3, 4,5,6,7, 1,0,2,11, 12,13,14,15,  1",
	
	split"4,5,3, 4,5,6,7, 1,0,2,11, 12,13,14,15,  1",
	
	
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  10",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  15",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  7",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  12"
}

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
	get_lvls()
	
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
	for i=1, #all_level_h_slots do
		local yval = i*s + 12
	
		local l_txt_col = 7
		if cursor_pos == i then
			l_txt_col = 12
			rect(1, yval - s\2, 127, yval + s\2,l_txt_col)
		end


		local pal_transp_col = palettes[all_level_h_slots[i][5]+1][16]
		
		-- col
		rectfill(2, yval - s\2+1, 126, yval + s\2-1,pal_transp_col)
		rect(2, yval - s\2+1, 126, yval + s\2-1,l_txt_col)
		

		
		-- bg sample
		for	j=0, s-4 do
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, all_level_h_slots[i][6]*8,  j/8+1, 1/8, 0)
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, all_level_h_slots[i][6+9]*8,j/8+1, 1/8, 0)
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
	
	cursor_pos = mid(1,cursor_pos, #all_level_h_slots)
	
	if btnp(4) then
		load_l_editor()
	end
	
end

l_size_x = 16
l_size_y = 8
l_head_size_x = 10
l_head_size_y = 1

ld_l_size_x = 16
ld_l_size_y = 8

function get_lvls()
	all_level_h_slots = {}

	for i=1, ((l_end-l_start)\9) * 8 do 
		local lvl_h = load_lvl_header(i-1)
		
		add(all_level_h_slots, lvl_h)
	end
end


function load_lvl_header(index)
	local header = {}
	
	local map_pos_x =  (index%8) * l_size_x
	local map_pos_y =  (index\8) *(l_size_y + l_head_size_y) + l_start

	local o = 0
	local function add_h(i,n,s)
		add(header,(mget0x20(map_pos_x+i+o,map_pos_y)&n)>>s)
	end 

	-- shape
	add_h(0,0b00000011,0)
	-- extend
	add_h(0,0b00001100,2)
	
	-- mus
	add_h(0,0b11110000,4)
	
	-- pals
	add_h(1,0b00001111,0)
	add_h(1,0b11110000,4)
	
	local function add_bg()
		add_h(2,0b00001111,0)
		add_h(2,0b11110000,4)
		
		add_h(3,0b00000111,0)
		add_h(3,0b00001000,3)
		add_h(3,0b00010000,4)
		
		add_h(4,0b00001111,0)
		add_h(4,0b11110000,4)
		
		add_h(5,0b00001111,0)
		add_h(5,0b01110000,4)
	end
	
 add_bg()
	o = 4
 add_bg()

	return header
	
end


--get from og map
function mget0x20(x,y)
	if (x >= 128 or y >= 64 or x < 0 or y < 0) return 0
	if y < 32 then
		return @(0x2000 + x + y*128)
	else
		return @(0x1000 + x + y*128)
	end
end

function mset0x20(x,y,v)
	if (x >= 128 or y >= 64 or x < 0 or y < 0) return false
	if y < 32 then
		poke(0x2000 + x + y*128, v)
		return true
	else
	 poke(0x1000 + x + y*128)
		return true
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
	
	
	load_level(cursor_pos-1)
	
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
l_curs_x = 0
l_curs_y = 0
l_c_col = 13
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
	cls(palettes[loaded_level[1][5]+1][16])
	camera(cam_x,cam_y)
	camera_x,camera_y = cam_x,cam_y
	
	draw_loaded_bg()
	
	
	for i=1, ld_l_size_x do
		line(i*8*4, 0, i*8*4, ld_l_size_y*32,1)
	end
	for i=1, ld_l_size_y do
		line(0, i*8*4 ,ld_l_size_x*32, i*8*4,  1)
	end

	map(0,0)
	

	rect(l_curs_x*32, l_curs_y*32,l_curs_x*32+32, l_curs_y*32+32, l_c_col)
	
	draw_sidebar()
	
	
	print_outl(w_text,cam_x+1,cam_y+1,7,1)
	print_outl(s_text,cam_x,cam_y+121,7,1)
	
	draw_cursor()
	
--stat(34) -- mouse buttons (bitfield))
	
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
	
	local alt_l = (extra_t & 0b1 == 0b1)
	local alt_t = (extra_t & 0b10 == 0b10)
	
	local tx,ty = get_texture(t2)
	
	-- texture

	for j=0,3 do
		for i=0,3 do
			local t_spr = tile_spr(mget0x20(tx+i,ty+j), alt_l, alt_t)
			spr(t_spr,cam_x+94+i*8,cam_y+95+j*8)
		end
	end
	
	local l_c = 5
	local t_c = 5
	if (alt_l) l_c = 12
	if (alt_t) t_c = 12
	
	print_outl("layout ", cam_x+92,cam_y+76,l_c,1)
	print_outl("texture ",cam_x+92,cam_y+86,t_c,1)
	
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
	
	if (mous_p == 0) mouse_ready = true

	if not mouse_on_canvas then
		s_text = ""
		l_c_col = 1
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
			l_c_col = 13
			l_can_place = true
		else
			l_c_col = 2
			l_can_place = false
		end
		
		local curs_arr_pos = l_curs_x%ld_l_size_x + (l_curs_y*ld_l_size_x) + 1
		
		--place tile
		if l_can_place and mouse_ready and (btnp(4) or mous_prim==1) then
			draw_tile(selected_tex, l_curs_x, l_curs_y)
			loaded_level[2][curs_arr_pos] = selected_tex
			w_text = "editing level " .. cursor_pos
		end
		
		--sample tile
		if l_can_place and mouse_ready and (btnp(5) or (mous_scnd==0b10)) then
			selected_tex = loaded_level[2][curs_arr_pos]
		end
		
	end

	
	mous_prev = mous_p
end


function load_level(index)
	loaded_level = {load_lvl_header(index),{}}

	local map_pos_x =  (index%8) * l_size_x
	local map_pos_y =  (index\8) *(l_size_y + l_head_size_y) + l_start


	for j=0, l_size_y-1 do
		for i=0, l_size_x-1 do
		 add(loaded_level[2], mget0x20(map_pos_x+i,map_pos_y+l_head_size_y+j))
		end
	end
	
	if loaded_level[1][2] == 0b01 then
		for j=0, l_size_y-1 do
			for i=0, l_size_x-1 do
				add(loaded_level[2], mget0x20(map_pos_x+i,map_pos_y+l_head_size_y+j))
			end
		end
	end

	mset_level()

	pal(palettes[loaded_level[1][4]+1], 1)
	
end

function mset_level()

	ld_l_size_x = 16
	ld_l_size_y = 8
	
	if loaded_level[1][1] & 0b10 != 0 then
		ld_l_size_x = 32
		ld_l_size_y = 4
	end
	if loaded_level[1][1] & 0b01 != 0 then
		ld_l_size_x,ld_l_size_y = ld_l_size_y,ld_l_size_x
	end


	-- clear map
	memset(0x8000, 0, 0x2000)
	for t_c=0, #loaded_level[2]-1 do
		draw_tile(loaded_level[2][t_c+1], t_c%ld_l_size_x, t_c\ld_l_size_x)
	end
end


function get_texture(index)
	return (index%32)*4 ,(index\32)*4 +4
end

function tile_spr(s, alt_l, alt_t, random, rs)
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
	
	if alt_t and not fget(s1,7) then
	 -- alt texture
		s1 += 0b01000000
	end
	
	
	if random and (s1 & 0b100000 != 0) and (s1 & 0b001000 == 0) then -- in bottom left part of spr page
		srand(rs)
		local r = rnd(10)
		-- flip 1st bit
		if (r > 9) s1 ^^= 0b1 
	end
	


	return s1
end

function draw_tile(t,x,y)
	
	local tiles = {}
	
	local t2 = t & 0b00111111
	local extra_t = (t & 0b11000000) >> 6
	
	local alt_l = (extra_t & 0b1 == 0b1)
	local alt_t = (extra_t & 0b10 == 0b10)
	
	 
	local t_x,t_y = get_texture(t2)
	
	for j=0,3 do
		for i=0,3 do
			add(tiles, mget0x20(t_x+i,t_y+j))
		end
	end
	
	
	for j=0,3 do
		for i=0,3 do
			local mod_tile = tile_spr(tiles[i + j*4 +1], alt_l, alt_t, true, (x*4+i) + (y*4+j)*ld_l_size_x)
		
			mset(x*4+i,y*4+j, mod_tile)
		end
	end		

end

function save_level()
	
	level_h_bytes = {}
	
	-- ext/mus
	add(level_h_bytes, loaded_level[1][1] + (loaded_level[1][2]<<2) + (loaded_level[1][3]<<4))
	-- pals
	add(level_h_bytes, loaded_level[1][4] + (loaded_level[1][5]<<4))
	
	-- bg1
	add(level_h_bytes, loaded_level[1][6] + (loaded_level[1][7]<<4))
	add(level_h_bytes, loaded_level[1][8] + (loaded_level[1][9]<<3) + (loaded_level[1][10]<<4))

	add(level_h_bytes, loaded_level[1][11] + (loaded_level[1][12]<<4))
	
	add(level_h_bytes, loaded_level[1][13] + (loaded_level[1][14]<<4))
	
	-- bg2
	add(level_h_bytes, loaded_level[1][6+9] + (loaded_level[1][7+9]<<4))
	add(level_h_bytes, loaded_level[1][8+9] + (loaded_level[1][9+9]<<3) + (loaded_level[1][10+9]<<4))

	add(level_h_bytes, loaded_level[1][11+9] + (loaded_level[1][12+9]<<4))
	
	add(level_h_bytes, loaded_level[1][13+9] + (loaded_level[1][14+9]<<4))
	
	
	-- tiles
	
	local map_pos_x =  ((cursor_pos-1)%8) * l_size_x
	local map_pos_y = ((cursor_pos-1)\8) * (l_size_y + l_head_size_y) + l_start
	
	for i=0, #level_h_bytes-1 do
		mset0x20(map_pos_x + i%l_size_x, map_pos_y + i\l_size_x, level_h_bytes[i+1])
	end
	
	for i=0, #loaded_level[2]-1 do
		mset0x20(map_pos_x + i%l_size_x,map_pos_y+l_head_size_y+ i\l_size_x, loaded_level[2][i+1])
	end

	
	cstore(0x2000,0x2000,0x1000)
	
	w_text = "level saved!"
	return false
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

settings_bit_limits = {0b11, 0b11, 0b1111, 0b1111,0b1111, 
0b1111,0b1111, 0b111,0b1,0b1, 0b1111,0b1111 ,0b1111,0b111,  
0b1111,0b1111, 0b111,0b1,0b1, 0b1111,0b1111 ,0b1111,0b111}

function _update_l_settings()
	mous_x, mous_y = stat(32),stat(33)+l_set_list_cam*8-8
	
	if (btnp(2)) then
		l_set_cursor_pos -= 1
		if (l_set_list_cam - l_set_cursor_pos > 1) l_set_list_cam -= 1
		
		if l_set_cursor_pos == 3 then
			music(loaded_level[1][3] * 8 + 2, 1000)
		else
			music(-1)
		end
		
	end
	if (btnp(3)) then
		l_set_cursor_pos += 1
		if (l_set_cursor_pos - l_set_list_cam > 10) l_set_list_cam += 1
		
		
		if l_set_cursor_pos == 3 then
			music(loaded_level[1][3] * 8 + 2, 1000)
		else
			music(-1)
		end
		
	end
	l_set_cursor_pos = mid(1,l_set_cursor_pos,22)
	
	
	if btnp(4) then
		loaded_level[1][l_set_cursor_pos] += 1
		loaded_level[1][l_set_cursor_pos] &= settings_bit_limits[l_set_cursor_pos]
		
		if l_set_cursor_pos == 1 then

		elseif l_set_cursor_pos == 3 then
			music(loaded_level[1][3] * 8 + 2, 1000)
		elseif l_set_cursor_pos == 4 then
			pal(palettes[loaded_level[1][4]+1], 1)
		end
		
	end
	if btnp(5) then
		loaded_level[1][l_set_cursor_pos] -= 1
		loaded_level[1][l_set_cursor_pos] &= settings_bit_limits[l_set_cursor_pos]
		
		if l_set_cursor_pos == 1 then

		elseif l_set_cursor_pos == 3 then
			music(loaded_level[1][3] * 8 + 2, 1000)
		elseif l_set_cursor_pos == 4 then
			pal(palettes[loaded_level[1][4]+1], 1)
		end
		
	end	
	
end

function draw_bg(m_st_x,m_st_y,len_x,len_y, scale, scroll_a_x, scroll_a_y, timescroll_x,timescroll_y, wrap_x,wrap_y,offset_x,offset_y)
	pal(palettes[loaded_level[1][5]+1], 0)
	
	
	local scroll_x = (-offset_x or 0) + camera_x*scroll_a_x
	scroll_x += time()*(timescroll_x or 0)
	local scroll_y = (-offset_y or 0) + camera_y*scroll_a_y
	scroll_y += time()*(timescroll_y or 0)
	
	if(wrap_x) scroll_x %= len_x*8*scale
	if(wrap_y) scroll_y %= len_y*8*scale

	local function map_scaled(ox,oy)
		for	i=0,len_x-1 do
			for	j=0,len_y-1 do
			 local n = mget0x20(m_st_x+i,m_st_y+j)
				sspr((n&0b1111)*8,(n\16)*8,8,8, camera_x-scroll_x+i*8*scale+ox, camera_y-scroll_y+j*8*scale+oy, scale*8,scale*8)
			end
		end
	end
	
	for i=0, (128\(len_x*scale*8)+1)*tonum(wrap_x) do
		for j=0, (128\(len_y*scale*8)+1)*tonum(wrap_y) do
			map_scaled(len_x*8*scale*i,len_y*8*scale*j)
		end
	end

	pal(0)
end

l_set_list_cam = 1
camera_x = 0
camera_y = 1




l_bg_timescrolls = {0,    1, 2, 6, 15, 30, 60, 90,
																				150, -1,-2,-6,-15,-30,-60,-90}

function draw_loaded_bg()

	local header = loaded_level[1]

	bg1_index = header[6]*8
 bg2_index = header[6+9]*8

	bg1_scrl_x = (header[7]/12)^2
	bg1_scrl_y = (header[7]/12)^2
	bg2_scrl_x = (header[7+9]/12)^2
	bg2_scrl_y = (header[7+9]/12)^2

	bg1_scale = header[8]   +1
	bg2_scale = header[8+9] +1
	
	bg1_wrap_x = header[9]!= 0
	bg1_wrap_y = header[10]!= 0
	bg2_wrap_x = header[9+9]!= 0
	bg2_wrap_y = header[10+9]!= 0
	
	bg1_offset_x = header[11]*16 -128
	bg1_offset_y = header[12]*16 -128

	bg2_offset_x = header[11+9]*16 -128
	bg2_offset_y = header[12+9]*16 -128
	

	bg1_timescroll = l_bg_timescrolls[header[13]   +1]
	bg2_timescroll = l_bg_timescrolls[header[13+9] +1]
	
	
	bg1_timescroll_angle = header[14]/16
	bg2_timescroll_angle = header[14+9]/16
	bg1_timescroll_vec = vec2_rotate(vec2_up, bg1_timescroll_angle)
	bg2_timescroll_vec = vec2_rotate(vec2_up, bg2_timescroll_angle)
	

	draw_bg(bg1_index, 0, 8, 4, bg1_scale, bg1_scrl_x,  bg1_scrl_y,   bg1_timescroll_vec.x * bg1_timescroll, bg1_timescroll_vec.y * bg1_timescroll, bg1_wrap_x,bg1_wrap_y, bg1_offset_x, bg1_offset_y)
	draw_bg(bg2_index, 0, 8, 4, bg2_scale, bg2_scrl_x,  bg2_scrl_y,   bg2_timescroll_vec.x * bg2_timescroll, bg2_timescroll_vec.y * bg2_timescroll, bg2_wrap_x,bg2_wrap_y, bg2_offset_x, bg2_offset_y)

end

function _draw_l_settings()
	cls(palettes[loaded_level[1][5]+1][16])

	
	camera_y = l_set_list_cam*8-8
 camera(0, camera_y)
	
 draw_loaded_bg()
	
	local l_shape = "16x8 blocks"
	if loaded_level[1][1] == 0b01 then
		l_shape = "8x16 blocks"
	elseif loaded_level[1][1] == 0b10 then
		l_shape = "32x4 blocks"
	elseif loaded_level[1][1] == 0b11 then
		l_shape = "4x32 blocks"
	end
	
	local l_extend = "unused option lol"
	if loaded_level[1][2] == 0b01 then
		l_extend = "was supposed to load"
	elseif loaded_level[1][2] == 0b10 then
		l_extend = "next lvl's tiles"
	elseif loaded_level[1][2] == 0b11 then
		l_extend = "but rn does nothing"
	end
	
	rectfill(0,l_set_cursor_pos*8+4,128,l_set_cursor_pos*8+12,13)
	
	print_outl("level " .. cursor_pos .. " settings",0,0,7,1)
	
	print_outl("shape: "  .. 
		l_shape,0,14,7,1)
	print_outl("extensions: "  .. 
		l_extend,0,14+8*1,7,1)
	print_outl("music: " .. 
		loaded_level[1][3],0,14+8*2,7,1)
	print_outl("main palette: " .. 
		loaded_level[1][4],0,14+8*3,7,1)
	print_outl("bg palette: " .. 
		loaded_level[1][5],0,14+8*4,7,1)
		
	print_outl("bg 1 (back): " .. 
		loaded_level[1][6],0,14+8*5,7,1)
	print_outl("bg 1 parallax: " .. 
		bg1_scrl_x, 0,14+8*6,7,1)
		
	print_outl("bg 1 scale: " .. 
		bg1_scale,0,14+8*7,7,1)
	print_outl("bg 1 wrap x: " .. 
		tostr(bg1_wrap_x),0,14+8*8,7,1)
	print_outl("bg 1 wrap y: " .. 
		tostr(bg1_wrap_y),0,14+8*9,7,1)
		
	
	print_outl("bg 1 x offset: " .. 
		bg1_offset_x,0,14+8*10,7,1)
	print_outl("bg 1 y offset: " .. 
		bg1_offset_y,0,14+8*11,7,1)
		
		
	print_outl("bg 1 timescroll: " .. 
		bg1_timescroll,0,14+8*12,7,1)
	print_outl("bg 1 timescroll angle: " .. 
		bg1_timescroll_angle,0,14+8*13,7,1)

	
	
	print_outl("bg 2 (front): " .. 
		loaded_level[1][15],0,14+8*14,7,1)
	print_outl("bg 2 parallax: " .. 
		bg2_scrl_x,0,14+8*15,7,1)
		
	print_outl("bg 2 scale: " .. 
		bg2_scale,0,14+8*16,7,1)
		
		
	print_outl("bg 2 wrap x: " .. 
		tostr(bg2_wrap_x),0,14+8*17,7,1)
	print_outl("bg 2 wrap y: " .. 
		tostr(bg2_wrap_y),0,14+8*18,7,1)

	print_outl("bg 2 x offset: " .. 
		bg2_offset_x,0,14+8*19,7,1)
	print_outl("bg 2 y offset: " .. 
		bg2_offset_y,0,14+8*20,7,1)
		
	print_outl("bg 2 timescroll: " .. 
		bg2_timescroll,0,14+8*21,7,1)
	print_outl("bg 2 timescroll angle: " .. 
		bg2_timescroll_angle,0,14+8*22,7,1)




	local function draw_pal()
		for j=0,3 do
			for i=0,3 do
				rectfill(92 + i*8,8 + j*8,99+ i*8, 15 + j*8, j*4 + i)
			end
		end
	
	end

	if l_set_cursor_pos == 4 then
		draw_pal()
		
		spr(1,92,60)
		spr(3,104,60)
		spr(4,116,60)
		
		spr(40,92,70)
		spr(12,104,70)
		spr(14,116,70)
	elseif l_set_cursor_pos == 5 then
		pal(palettes[loaded_level[1][5]+1], 0)
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
	
	l_textures_cursor = mid(-1,l_textures_cursor,48)
	
	mouse_index = 1
	if (mous_x < 42) mouse_index = 0
	if (mous_x > 84) mouse_index = 2
	
	mouse_index += ((mous_y-8)\38)*3
	
	if btnp(4) or (mous_prim==1 and (mous_prev&0b1) != 1) then
		if mous_y-tex_cam_y > 10 then
			if mouse_index > -1 and mouse_index < 64 then
				unedit_l_texture()
			end
		else
			if mous_x < 64 then
				tex_alt_l = not tex_alt_l
			else
				tex_alt_t = not tex_alt_t
			end
		end
	end
	
	mous_prev = mous
end

function _draw_l_textures()
	cls(0)

	camera(0, tex_cam_y)

	local grid_x = 0
	local grid_y = 0
	
	for i=0, 63 do
		
		local draw_x = grid_x * 38 + 8
		local draw_y = grid_y * 38 + 8
		
		local r_col = 5
		
		if (mouse_index == i) r_col = 12
		
		rect(draw_x-1,draw_y-1,draw_x+32,draw_y+32,r_col)
		
		
		local t_x,t_y = get_texture(i)
		
		for j=0,3 do
			for i=0,3 do
				local t_spr = tile_spr(mget0x20(t_x+i,t_y+j), tex_alt_l, tex_alt_t)
				spr(t_spr,draw_x+i*8,draw_y+j*8)
			end
		end
	
		
		
		grid_x+=1
		if grid_x > 2 then
			grid_x = 0
			grid_y += 1
		end
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
	
	local l_c = 5
	local t_c = 5
	if (tex_alt_l) l_c = 12
	if (tex_alt_t) t_c = 12
	
	
	print_outl("alt layout ", 12,tex_cam_y+2,l_c,1)
	print_outl("alt texture ",74,tex_cam_y+2,t_c,1)
	
	
	draw_cursor()
	
end

function unedit_l_texture()
	mouse_ready = false
	selected_tex = mouse_index + tonum(tex_alt_l)*0b01000000 + tonum(tex_alt_t)*0b10000000 
	
		_draw = _draw_l_editor
	_update = _update_l_editor
end


__gfx__
00000000555555544444444444444444aabbbaa9ba9999aabbbbbaabbaaabbbbb808808a0b0b0b0bbbbbbabb8b8b8b8b000cd00011111f11cccccfc8ccc8ccc8
00000000555555444444444455555554b99999989988889aba999999a999999bba0880aa8a8a8a8a8a8888a8aaaaaaaa000cd000151fcfcfcffc8c88fff88f88
00000000544444444444444454444444b99999989a999899a9999999999999aab8a88a8abbbbbbbb00a00a00bbbbbbbb00cccc0011111c11cffc88c8c8ccf888
00000000555555444444444454445454b9999998a8888889a999999999999999b80aa08a00888800888aa888aba88abacccddccc5f155f15cfc8fff8f8f888ff
00000000544444444444444454454454a99999989999999a9999999999999999b80aa08a00088000888aa8888abaaba8ddcddcdd1f511111cc88fff8cc8fcc88
00000000555555444444444454444454a99999989988889aa999999999999999b8a88a8a0008800000a00a008a8bb8a800cccc00cfcf115fc8fc8ff8ff888ff8
00000000444444444444444454444454a9999998a9998999a9999998a9999998aa0880aa008888008a8888a8aabaabaa000cd0001c111111cffff8f8c8ffff88
0000000055544444444444444455555498888889aa999a9aaa999888aa999888a808808aaaaaaaaaaaaaaaaaab8888ba000cd0005f515f51f888888f8ff88888
00000000000000005555555500000000aaa99999999999ab9999999999999999000000000000000000000000444444c450044005444444445555555559559959
00000000000000005555555500000000ba9999999999999a9999999999999999000000000000000000000000dddd4ddd55044055555555550500005045999999
00000000000000005555555500000000baaa99999aa9aaabaa99999999999999000000000000000000000000444444c450544505444444440050050044599555
00000000000000005555555500000000a99a9999999999ab99999999999aa9990000000000000000000000005d45554550055005555555554445544444459999
00000000000000005555555500000000baaaaa9999aaaaaaa99999aaa99999aa0000000000000000000000004d44444450055005444444444445544444445999
00000000000000005555555500000000ba9999999999a99bbaaaa999999999990000000000000000000000004d5545c550544505555555550050050055444599
00000000000000005555555500000000aaa99aa99999aaab99a9999999999aab000000000000000000000000cdcccccc55044055444444440500005044444459
00000000000000005555555500000000b9999999999999abbaabbba999bbbabb0000000000000000000000005d5455c450044005555555555555555545554445
44444444444444444554455455555555baa9baa9aaa99999bbbbbaababbbbbaababbbbba44444444ba9cba9b55455545444cc44405020f002222222122222121
5555455545554455445544555455445599999999999999999a9999999999a999b8aaaa8a88888888aa9bba9b5545554545554555555fcfcf2111111122121212
44444444444444445445544554455445a9baa9aaa99999aaaaa9aaaaaa9aaa9ababaabaa44444444ba9bba9b5545554544cccc4405020c002222211121212111
5545554554455445554455445544554599999999999999999999999999999999aaaaaaaa88888888ba9bba9b55455545c5cddc4c2f222f20f277772ff577775f
44444444444444444554455455544555baa9aaa9baa9aa99a9999aa9aa9aa999baaaaaa899888989ba9bba9b55455545d4cddc4d0f02050072fff22275fff555
4555455545444555445544555455445599999999999999999999999999999999aabaaba888888888ba9bba9b5545554545cccc55cfcf555f7221111772111117
44444444444444445445544554455445a9aaa9aa999aa9aa9999999999999999a8aaaa8899999999ba9bba9b55455545444444440c0205007111111771211117
5554555455545554554455445555555599999999999999999999999999999999aa888a8899999999ba9bba9b55455445554cc5540f000f002211111251111115
05050500000500000000000500000005b9b9b9b9000000009999999999999999bbbabbba99999999aa9bba9bbba9a99a4f7777f40d0210c0fccc2cfcccfccc2c
05050500000500005555555500000055a8989898000000009999999999999999baaabaaa99999999ba9bba9ba1111112f4444445ddddddddcffff12fcffff1f2
5555050000050500050505050000050599a999a9000000009999999999999999baa8aaa899999989ba9baa9b91121112744444450d0210c0cf111f22cf11ff22
055555500505050050505055500000559999999a000000009999999999999999a888a88888888888ba9bba9b91211112744444472d2222c2cf11f212cf11f112
0505050005050500050505050500050599999999000000009999999999999a99bbb8bbba99989999ba9bba9b91111112744444451d1211c1cf1f2112cf221112
05050500050505005555555555555555999999990000000099999999a99aaaa9baaabaa888888888ba9bba9ba11111127444444f0d0210c0c11111122f1112f2
05550500050555505555555555555555999999990000000099999999999a9999aaa8baa844444444ba99aa99bbaaa99a5444444fcdcccccc21122122cf111112
0505050005055500555555555555555599999999000000009999999999999aaaaa88aa88888884889988998899999999fffffff40d0210c0fcfcf222c2cc2222
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
5544554554545544545555455545545400000000000000005b5bb5b55b55bb5b0000000000000000bb233322bbb2232200000000000000000000000000000000
545454554554545454555455454544540000000000000000bbbbbbbbbbbbbbbb0000000000000000b332222bb333322b00000000000000000000000000000000
554445455455445454555455454545550000000000000000abbbaababbababbb00000000000000003322bb22333332b300000000000000000000000000000000
454554454554545555555545544545450000000000000000ababaa9aabaabaab0000000000000000222b33323333222200000000000000000000000000000000
5454544454554554554555445455554500000000000000009a9aa9a9aaa9ba9a0000000000000000bb22332b22222bbb00000000000000000000000000000000
454544454545445555455454555545550000000000000000a99b9aa9a9a99a9a0000000000000000333222bb332bbb3300000000000000000000000000000000
454454544545445455545455455545450000000000000000a9ab9a9aa99a99a90000000000000000332bbb23322b333300000000000000000000000000000000
45445454554554555554555555555545000000000000000099a9999a999999a9000000000000000032bb33322222333300000000000000000000000000000000
0054005400000005000040040400450000000000000000009999999999a999990000000099599999bbb22b222222b23300000000000000000000000000000000
055440454000005440540040440450400000000000000000999999a99a99a9990000000095595999bb33b33bbb2bb32200000000000000000000000000000000
045440054050454504050054450554050000000000000000999999a999999a9900000000594559593332333bb332322b00000000000000000000000000000000
05404454454045500545050450050454000000000000000099a999999999a9a9000000005945595533322322232b222200000000000000000000000000000000
4540404544544500454545455450545500000000000000009a9999999a99a9aa0000000055454459b23322bbb2b332bb00000000000000000000000000000000
5054405545544504540555455454554500000000000000009a999999a99999a90000000045444549332b2bb333232bbb00000000000000000000000000000000
54544554550445045554555554555454000000000000000099999999999a999a000000005454545432b33b333332bb3300000000000000000000000000000000
44545454055445444555545555555455000000000000000099999999999999990000000054445444222322333322233300000000000000000000000000000000
00000000000000000577775056777766000000000000000000777700000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000571e11755181e11500000066cc00000007777770000000000000000000000444000000000000000055766555555555552222222222222222
0088800000400840711e11177181e1170000766cc666000076777776000550000000000000014004000000000000000000006660000000000000000000000000
008f8000000f0f0071e1111771811117000766c55666600077677776005885000000000000241424000000000000000015766511111111111000000000000000
008ff000004202407e55eee761811117007665777756660077767766005885000000000000420704000000000000000077776777777777777110000000000000
00800000000000007885111776666667006657118175660077767665000550000000000004003004000000000000000066666666666666666667100000000000
008000000000000068851115555555550766711e8117666007766650000000000000000040014004000000000000000077777777777777777777771000000000
00000000000000005555555515151515066571e18117566000665500000000000000000044444444000000000000000066666666666666666666666700000000
0000000000000000767776677766777706657e558ee7566007077600007607600000000000000000000000000000000066666666666666666666666666600000
00000000000000000005500000055000066c7885811766600c67606670c666000000000000000000000000000000000066666666657111111111115611170000
0000000000000000057777500577775000c6788581156600c0766660766766660000000000000000000000000000000065111156671111111111111611111000
000000000000000057e1117557e111750066655555566600766556660c6556660000000000000000000000000000000061111116611111111111111611111100
000000000000000071e1555771e15557000666655666600076655666766556600000000000000000000000000000000061177116611111111111111611111110
000000000000000078e1568778e15687000066666666000007666606776666660000000000000000000000000000000061711716611111111111111611111111
000000000000000068e1586568e15865000000666600000076076660007666060000000000000000000000000000000061111116651111111111117611111115
00000000000000000577775005777750000000000000000000766060077066000000000000000000000000000000000061177116666677777777776677777777
0057750000055000000000000200000000000000000000000000000000c667000000000000000000000000000000000061711716666666666000000000000000
06c777600067770000022000020000000000000000000000000000000c6677600000000000000000000000000000000061111116666666666000000000000000
5cc7666506c77650002ee20072770000000000000000000000000000c66776660000000000000000000000000000000061177116666666666600000000000000
777666555777665102ecce207fff7000000000000000000000000000667556660000000000000000000000000000000061711716666666666600000000000000
776666515776655102ecce2012eee7f2000000000000000000000000677556660000000000000000000000000000000061111116666666666660000000000000
5766655107665510002ee20071222222000000000000000000000000776666660000000000000000000000000000000051111115555555555550000000000000
066555100055510000022000171ff000000000000000000000000000066666600000000000000000000000000000000066555566666666666660000000000000
00551100000110000000000011717000000000000000000000000000006666000000000000000000000000000000000055555555555555555550000000000000
11c1c11188c89c89000000000000000098ff98898888888911ff1111111c511111111ccc00000000000000000000000000000000000000000000000000000000
1cfcf1c18fc9ca9800000000000000008afca89898a98a981fff111111c51c11111ccc5c00000000000000000000000000000000000000000000000000000000
1c5c5cfc87cca98900000000000000008ca9caa889a9ca981ff5f11115c5c1c115c5651c00000000000000000000000000000000000000000000000000000000
ccfff5cc57cccccc0000000000000000aaccccc8affca9881f5cccc155c61c155c5651c100000000000000000000000000000000000000000000000000000000
fc55ff5ff7caaa99000000000000000089ccaa998fff999811ccaa995c65555c51c511c100000000000000000000000000000000000000000000000000000000
cfff5fccf7cc998800000000000000009cacc998f5ffaaa81cacc9111c51ccc11c5c1c1100000000000000000000000000000000000000000000000000000000
1cfffc1188cac89800000000000000008a8a9c898f5f98881a1a9c11c5cc1551c5c1c51100000000000000000000000000000000000000000000000000000000
11ccc11188c89c89000000000000000098898898f5888988911911915c1155115c11511100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000544440000000000000055
aa000000000aaaaa00000000000000aa000000000000000000000000000000000000000000000055554400000000000055400000000544444444000000005555
00aa00000aaa000000000000000aaaa0005550000000000000000550000000000000000000000555554400000000055555440000005544444444444400555544
00000000000000000aaaa00000000000005555000000055000055550000005500000000000000555554400000055555544444000005444444444444455554444
00000000000000000000000000000000005555000055055000055550005505550000000005555555544444445555544455444400055444544444444455444544
0990000000aaaaa00000000000000000055555000055055555055550005505550000000055555555544444445544455555444440054544544444444445554444
000000000aa999aa0000990000000000555555000555555555555555005505550000000055555555544444444455555555444444554544544444444455444544
00000000aaaa9999990000000aaa0000555555005555555555555555005555550000000054545454544444445555555544444444545544444444444445554444
0000009aaa9999999aa00000aaa9a999555555005550000000000000000055500000000055555555544444445555544455444444545544445400000055444544
000999aa9999999999aa000aa99a9a00555555505555550000000000000055550000000054445454544444445544455555444444455544445444000045554444
99aaaaaa99aaaa009999a0aa99999999555555555555555500000000000055550000000055555555544444444455555555444444455544445444440055444544
0aaaaaa9aaa99aaa99999a999a999990555555505555555500055000000055550000000054545454544444445555555544444444555444445444444445554444
aaaa999aa999999a9999999aa99aa999555555555555555500555555000055550000000055555555544444445555544455444444555444545444444455444544
aa9999aa999aaa9999aaa9999aaa9a9a555555555555555500555555005055550000000054545444544444445544455555444444554544545444444445554444
a99aaaaa99aaa9999aa9999999a9a9aa555555505555555500555555505555550000000055555555544444444455555555444444554544545444444455444544
99aaaaa99aa999999999999999aaaaa9555555505555555500555555555555550000000054445444544444445555555544444444545544445444444445554444
9aaa99999999999999999900aaa99999000000000000000000000000000000000000000000000000000000000990000000000000000000000000000094440000
aaa9999999999aaaaaaa9090a00aaaa9000000000000000000000000000000000000000000000000005400099999900000000000009400000000000944444000
a9999aa9999aaaa999aaa9090aa99999000000000000000000000000000000000000000000990000005440059994400000000000994440000000009544444000
99999999999999999a99aa00aa9aa999000000000000000000000000000000000000000000599000005440055544400000000099944440000000095554444400
aaaaaaa999999999999999a0a9aa9990000000000000000000000000000000000000000000544000005400055544000000000999444444000009555555444400
aaaa999999999999999999909a999909000000000000000000000000000000000000544005544000054400555544000000009995544444400095555555444440
a99909099999999999999aa900909090000000000000000000000000000000000000544445540000054000555544000000099555544444400555555555544440
9990909099aa99990099aa9900000000000000000000000000000000000000000005544405500000050000555440000000955555554444005555555555544400
00000000000000000000000000000000000000000000000000000000000000000005544405040000004000555400000005555555554444005555555555554400
00000000000000000000000000000000000000000000000000000000000000000005544400599000540000554000000005555555555440000555555555554400
00000000000000000000000000000000000000000000000000000000000000000005444000059990000005050400990000555555555440000555555555555400
00000000000000000000000000000000000000000000000000000000000000000005444000055440000000504059940000555555555540000055555555555000
00000000000000000000000000000000000000000000000000000000000000000005444000555440000000000055440000055555555500000055555555550000
00000000000000000000000000000000000000000000000000000000000000000055440000554400009990000055440000055555550000000005555555000000
00000000000000000000000000000000000000000000000000000000000000000054440000554400009999000055440000005555000000000005555500000000
00000000000000000000000000000000000000000000000000000000000000000054440000554400005999900055440000005500000000000000550000000000
__gff__
8808880801010101010101018484838308088808010101010000000808880800080808080101010101010108848482820808080801008101010101018384838308080808000001010000000000000000080808080000010100000000000000000808080800000101000001010000000008080808000001010001000100000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d50000c00000c300c1c2c37170707100707173000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd02c4d6d7c6c512c4c7c2c1d0d3d0d1d2e26160616071606162000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9dac5dbdccfdd02d412121212121212e3e1d3d0e0e1d1d06260636361616362000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9da12dbdcdfdd021212121212121212d0d1d0e0e2e1d1e26667666767666767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000036363636062627272626272614f676767676f615464706072a2a2a2a26262726210321203232323226272626e0e0e0e0042020200000000020202421090b0909005c0001090b090b0008001c242020202020202421212121202020200000000014f936f936f914150000000000000000000000000000000000000000
0000000036363636143636053636363614f676767676f615565716173a3a3a3a39393939626262626060606036363636224647220404030300000000212124210008001c005c001c230800080008001c242003202020202422222222cfcece020000000036421442254214150000000000000000000000000000000000000000
0000000036363636373636153636363614f676767676f61506070607363b252460606160262726276060616036363636225657222626272605272627200324201e081e230a0b0a0a0a0b0a0b1e0b1e2324202020202020240e0f0f0fcecfcecf3232323236e925e936e914150000000000000000000000000000000000000000
0000000036363636163736173636363614f676767676f615161716172525242502020202393939390404040439393939e0e0e0e01636363604363637030324030008001c0008001c000823080008001c24202020202020240f0f0e0e2626262602cececf25363636363614150000000000000000000000000000000000000000
02020202222222222020202001202020020202020202020232323332011e1e011f3736362b2b2b2b23c0c023011e1e011e011e1e02020200717071711e23c11e00000000001cc01c3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202022222222221e0e020202021200202020220202021202020211c22221c021f36372b2b2b2b1cc0c01c30000030c0f0c0c00202020061706070c0f0c0c000000000001cc01c3000000000000000000000003100310000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202022222222220e0e021212020200202020221202020212020201c22221c02021f362120202123c0c023300000231e011e1e02020200606361601e23c11e00000000001cc01c30000000000000000003002b3031303100000000000000000000000000000000000000000000000000000000000000000000000000000000
02020202222222222020202042424242020202022222222222222222011e1e012020201f032021201cc0c01c01323201000000000202020063626163001cc01c000000000023c02330000000323232323203032b3021203000000000000000000000000000000000000000000000000000000000000000000000000000000000
0093220b88414103ab000000000000000093220b9841610ca2000000000000000081220c78426104a8000000000000000081220b98424104980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000004052c2c0405310000000b0b00000000000000006a6c2a30000000000000000000000000000000000002450100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000040500000405713333340f23000000004c4c0c0c6a0014012d000000052d000000000000000000006c04150100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000026e2d00000000000000000004052c2c04057108080b020300000000000000006a6c14042d0c2900052d0000000e0000000000006c02150100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000045a2d2e35342e0a2e2e0a160405000008086f6f2c2f0401006a6a6a6c6c6c6c6c6c14011402032d052d002f6c6c6c6c6c6c6c6c6c6c150100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000045a456e030303030303032a080800000000316f6c6c02010000006a00000000002e09021404012d232d002f292d00000e0000006a00080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b000000000e332908084504010101010101011725296c6c6c6c2971342e04012b6c6c6b00002e512e0823632308082d03021548080800000e0000006a2e0c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030d0210030302090b0b040101010101010103030302000002030303030101022e300200001002090949034949093001020909490900000e1100028649090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201015a130101010101010401010101010101010101050000040101010101010306100210100201010101010102020201012525020200100e1300060601010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00100000000000000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c07230013
0113800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
000380003f3043e05338033320032e0622a04226022220711c05118021120010e0600803004010020003eb673ab3734b1730b762ab4626b1620b751ab4516b1510b640a3500a0500a0500a0500a0500a0500a050
0103000018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc30
00108000000000000000000000000000000000000000000022136281462a146221162e1762e1762e1762e1072c1072c1072c1762c1262c1662c1662c1662c1662c1662c1662c1262211622147361473813736127
00108000000000000000000000002a1562a15626166261662c14628166281662a1762a1762a1763010730107301073010730107301072e1762e1762e1662e1762e1762c1762e1762e1762e1662c1662c1662c166
0111800010105101050e174243540a1441833406124029643e06338033320032c87322071180110a00038b072ab2318b050ab2400b6338a332aa132ea032ea622aa5228a4226a1224a2224a1222a1222a1222a12
520080003f6103f6103f6100e6100e6100e6100e6100e610356103561036610366103761037610376103761000000376003760037600376103761037610376103761037600376003760037600376003760037600
5b0200003d6103d6303d6303d6203d6103d6103d6103c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030200002435314353093533d6503c6503c6403a6503964037640356302f630336202f620306202d6202f6202f610286102f61024610306101f610306101b6101861030610156101361012650386003860033600
52010000143200d3110a3110a3112062020620206200d3303d620253203d6203d6103d6103a6101f610086102a6050d6033b6033f6033f6053f6053f6053f6053f6053e6053f6053f6053f605006050060500000
52010000143200d3110a3110a31019620196200d3303863025330253203e6203d6102b6101c610166100f61005610036000060000600006000000000000000000000000000000000000000000000000000000000
52010000143710d361043510135100340366502533025340366403664036640366303663036630366303663036630366303663536635366253663536645366353662536625366103661000000000000000000000
500100001533008330034200042001320016100161000610006100461009600096000960009600096000960009600000000000000000000000000000000000000000000000000000000000000000000000000000
50010000193600d350063500335001340013400363003630036200562009610096100961009610096100861007610066100661005610056000460000000000000000000000000000000000000000000000000000
5a020000183730537301373016700566002660086600f6500165006645056450064004630086300663004620036200762006625056250162503610036100c6100261304613056150061500615086150061408614
0a0200003e6201b6403e620376403c62037640376201c6403962032630386200d620366200262033620016202f620026202d620026102a6100361523615026101e61502615146050260032600326003260032600
080400001e0631465105350216432d6502c653276402264020640186301f63010333176300d333146300a3230f6230e62308323083130c6130c6130b613073130631306313053130431303313013130031300313
0e0100003e6203e6203d6203d6103b610386102f6102a91025910219101d9101b9101791015910113100f3100d3100c2100a21008210072100621004110041100311003110020100001002000000000000000000
000200002c620326103061530014310102c010200101901308700057000370002000110000100301003010030100301003010032e600186001100001003010030100301003010030000000000000000000000000
0a0100001275016760197601b75022750257502874000000000002c6602c6602c6402c630000003b6503b6303b6303b6253b6203b6203b6103b61500000000001370017700187001c70000000000000000000000
0a0100003b6303b6303b6303b6303b6303b6303c6002c6202c6202c6202c6202c6202c6200000025745227501f7501b7401774514730127200e7200e720000000000000000000000000000000000000000000000
080200000f64014641186311d610156532a740227601b750167400f7300a720087100571004710037100300000601000030060400600006010300004700037000070000700000000000000000000000000000000
030100003d6303d6303d6202c61026610266101e6001e6003a6303a6203a6103a6100000000000010000100002000030000400006000082000a0000f0000f00019700197001a7001e700217001a7000070000700
3148002027d151ed1503d140ad150fd151ed1512d150dd1427d151ed150fd140ad150fd151ed150cd1508d1522c1503d1403d1403d1424c1506d141bc1508d1425c150000029c0020d150fd151ed1512d150dd14
317e000003d141ed150dd1503d140ad1503d141ed150dd1503d1403d141bc1503d1403d141bc1503c0003c0003d141ed150dd1503d1420d1503d141ed150dd150000000000000000000000000000000000000000
031000201bc2003c21306001bc2003c210000030600000003864038620386103864038620386103b600396001bc301bc101bc301ec201ec0019c301ac30376001bc203b6001bc203c6001bc203b60022c2021c10
611000000332003320033200f300003000035503355033200332003325033000f30003335033000a3000a3350b3200b3200b3200b320013200132001320013200332003320033200332003325033250332503325
151200000f430124300d4300f43014430034200f43016430034100d4350d430034100d430034100e430034100f430124300a4300f43014430034100f43016430014100d4350d430014100d430014100e43003410
091200000f3330000033610000000f3330000033610000000f3230000027610000000f3230000033610000000f3330000033610000000f3330000033610000000f3430000033610336150f343000003361000000
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
012000000eb5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

