pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--
--

menu_state = 0

all_level_slots = {}

cursor_pos = 1

palettes = split[[
	1,2,10,   128,132,142,15, 8,9,10,138,    12,9,14,13, 0,
	1,131,10, 2,8,9,10,       3,138,135,143, 12,138,14,13, 0,
	143,15,10,  142,143,0,7, 130,2,136,8,  12,2,13,6, 142,
	143,15,10,  130,2,0,7,   130,136,8,9,   12,136,13,6, 142,
	
	143,15,10,  130,2,0,7,   130,8,9,10,   12,8,13,6, 142,
	2,14,10,  128,130,0,7,   130,136,143,15,   12,136,13,6, 130,
	136,142,10,  128,130,0,7,   130,136,14,15,   12,136,13,6, 2,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  0,
	
	129,2,3,4,5,6,7,8,9,10,11,12,13,14,15,5,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,
	5,7,3,4,5,6,7,8,5,4,3,2,7,14,15,0,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,
	
	133,134,11, 129,1,0,7 ,134,13,6,7, 12,6,14,13,  0,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  0,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  0,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  0,
	

	
	
	
	0,1,2, 0,1,2,2, 0,1,2,2, 0,1,2,2,  0,
	0,1,2, 0,1,2,2, 0,1,2,2, 0,1,2,2,  0,
	1,1,2, 0,0,1,2, 0,1,2,2, 0,1,2,2,  0,
	1,2,2, 1,2,2,2, 4,4,5,5, 0,1,2,2,  0,
	
	0,1,2, 0,1,2,2, 0,1,2,2, 0,1,2,2,  1,
	1,2,2, 0,1,2,2, 0,0,1,2, 0,1,2,2,  1,
	1,1,2, 0,0,1,2, 4,4,5,5, 0,1,2,2,  1,
	0,0,0, 0,0,1,2, 4,4,5,5, 0,1,2,2,  1,
	
	1,1,2, 0,1,2,2, 0,1,2,2, 0,1,2,2,  2,
	0,0,0, 4,5,2,2, 0,0,1,2, 0,1,2,2,  2,
	0,0,1, 0,1,1,2, 4,4,5,5, 0,1,2,2,  2,
	0,1,1, 5,5,1,2, 4,4,5,5, 0,1,2,2,  2,
					
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  12,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  4,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  5,
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  12,

]]

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


		local pal_transp_col = unpack_pal(all_level_h_slots[i][5]+16)[16]
		
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
	cls(unpack_pal(loaded_level[1][5]+16)[16])
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
	print_outl(s_text,cam_x,cam_y+121,7,9)
	
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
	
	local l_c = 1
	local t_c = 1
	if (alt_l) l_c = 7
	if (alt_t) t_c = 7
	
	print_outl("layout ", cam_x+92,cam_y+76,l_c,0)
	print_outl("texture ",cam_x+92,cam_y+86,t_c,0)
	
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

	pal(unpack_pal(loaded_level[1][4]), 1)
	
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
	l_set_cursor_pos = mid(1,l_set_cursor_pos,23)
	
	
	if btnp(4) then
		loaded_level[1][l_set_cursor_pos] += 1
		loaded_level[1][l_set_cursor_pos] &= settings_bit_limits[l_set_cursor_pos]
		
		if l_set_cursor_pos == 1 then

		elseif l_set_cursor_pos == 3 then
			music(loaded_level[1][3] * 8 + 2, 1000)
		elseif l_set_cursor_pos == 4 then
			pal(unpack_pal(loaded_level[1][4]), 1)
		end
		
	end
	if btnp(5) then
		loaded_level[1][l_set_cursor_pos] -= 1
		loaded_level[1][l_set_cursor_pos] &= settings_bit_limits[l_set_cursor_pos]
		
		if l_set_cursor_pos == 1 then

		elseif l_set_cursor_pos == 3 then
			music(loaded_level[1][3] * 8 + 2, 1000)
		elseif l_set_cursor_pos == 4 then
			pal(unpack_pal(loaded_level[1][4]), 1)
		end
		
	end	
	
end

function draw_bg(m_st_x,m_st_y,len_x,len_y, scale, scroll_a_x, scroll_a_y, timescroll_x,timescroll_y, wrap_x,wrap_y,offset_x,offset_y)
	pal(unpack_pal(loaded_level[1][5]+16), 0)
	
	
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
	cls(unpack_pal(loaded_level[1][5]+16)[16])

	
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
		pal(unpack_pal(loaded_level[1][5]+16), 0)
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
		
		if (mouse_index == i) r_col = 7
		
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
	
	local l_c = 0
	local t_c = 0
	if (tex_alt_l) l_c = 7
	if (tex_alt_t) t_c = 7
	
	
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
555545554555445544554455545544559ddd9ddddd99dddddadddddddddda9ddbaa8baa888888888aa9bba9b55455545f4ff44fe7377337ebaa8d999baa8baa8
44444444444444445445544554455445a9baa9aaa99999aaaaadaaaaaadaaadabaa8baa899999999ba9bba9b55455545fff44ffe7773377ebaa89999baa8baa8
55455545544554455544554455445545dddddd9999dddd99dddddddddddddddda888888888899988ba9bba9b55455545ff44fffe7733777ea88899dda8888888
44444444444444444554455455544555baadaaa9baadaa99addddaadaadaaddddddd9ddd99999999ba9bba9b55455545f44ff4fe7337737eddddbbbabbbaddd9
45554555454445554455445554554455999d9ddddd9dddd9ddd9d99ddddd9d9dd9d99d9d99999999ba9bba9b55455545f4ff44fe7377337ed9ddbaa8baa8dd99
44444444444444445445544554455445adaaa9aa999aa9aa9d99d999d9dd999d99999d9999999999ba9bba9b55455545fffffffe7777777ed99dbaa8baa89d9d
555455545554555455445544555555559999ddd99dd9999999999999d9d999999999999999999999ba9bba9b55455445eeeeeeeeeeeeeeee99998888a888999d
05050500000500000000000500000005b9b9b9b90000000099999999999999999999999999999999aa9bba9bbba9a99a9bb99bb9554444449999bbba444fe844
05050500000500005555555500000055a89898980000000099999999999999999999999999999999ba9bba9ba222222599bb99bb554444559999baa85557e855
5555050000050500050505050000050599a999a90000000099999999999999999dd99d9d99999999ba9baa9b92272225b99bb99b554444449999baa8444fe844
055555500505050050505055500000559999999a000000009999999999999999dddddddd99999989ba9bba9b92722225bb99bb99554444459999888877f7f7f7
0505050005050500050505050500050599999999000000009999999999999a99bbbabbba88888888ba9bba9b922222259bb99bb955444444bbbaddd9eeefeeee
05050500050505005555555555555555999999990000000099999999a99aaaa9baa8baa899989999ba9bba9ba222222599bb99bb55444455baa8d9d98887e888
05550500050555505555555555555555999999990000000099999999999a9999baa8baa888888888ba99aa99bbaaa99ab99bb99b55444444baa8d999444fe844
0505050005055500555555555555555599999999000000009999999999999aaaa8888888999998999988998899999999bb99bb9955444445a888999d555fe854
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
008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee00ee00000
008e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e8eee00eeeee00
008ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eee8ee66eeeeee0
0080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeee8866eeeeee8
0080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee88866eeee888
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e888668888688888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066688668866600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000686336860000
00000000000000000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086336800000
00070700000707000007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008668000000
00000000000707000070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008ff800000880000000000003000000eeeeeee60000000000666600000000000000000000022000002222000000000000000000000000000000000000000000
0e7fffe000efff00000000000e000000666663e6000000000666666600000000000220000023320002377320000000000000000000000000000000ee77000000
877feee80e7ffe80000000006e6660006666363600000000666666666600000000233200023773202377773200000000000000000000000000007ee77eee0000
fffeee888fffee86000000006e666600633663660000000066666666666600000237732023733732277777720000000000000000000000000007ee799eeee000
ffeeee868ffee88600000000e3e33e3e36e36666000000006666666666666600023773202373373227777772000000000000000000000000007ee966669eee00
8feee8860fee886000000000eeeeeeee3e63666600000000666666666666666600233200023773202377773200000000000000000000000000ee96666669ee00
0ee88860008886000000000066666600633e666600000000eee666666666666600022000002332000237732000000000000000000000000007ee66663666eee0
008866000006600000000000666666006666666600000000666eeeeeeeeeeeee0000000000022000002222000000000000000000000000000ee9636363669ee0
cc7c7cccf97f97794444477700eee60000eee60000eee600666666666666666600eeee0000660660060666000000000000eeee00000000000e79666636669ee0
c7e7ec7c9f7f7798444777e70ee666600ee666600ee6666066666666666666e30eeeeee06060660006666066000000000eeeeee00000000007ee6e666666eee0
c78787e7ef777989457efe67366366363e366363e3663663666666666666e3e3e3eeeee3666666666066066000000000e8e66ee80000000000ee96e66669ee00
77eee877ef77777757efe67466666666666666666666666666666eeee6e3e3e3ee7eee3e066336066603366600000000ee6336e80000000000eee966669eee00
e788ee8eef777777547e66746666666666666666666666660666e6666ee3e300eee773e8606336606663306600000000ee63368800000000000eeee99eeee000
7eee8e77ef77798847e76744336666333366663377666677006e666666e30000eee7ee86666666660660660600000000eee66886000000000000eeeeeeee0000
c7eee7cc9f7f77987e747544773663770036630000766700000e66666e0000000ee3e8600066060666066660000000000ee8886000000000000000eeee000000
cc777cccf97f9779e744544407700770700000070000000000000000000000000083860006606600006660600000000000886600000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000aa888000a08000008000aa8a8000000aaaaaaaaaa88800
0000000000000000000000000000000000000000000000000000000000000000000000000000000000aa8880000abb00a80000aa080000000aaaaaaaaaa88800
0000000000000000000000000000000000000000000000000000000000000000000000000000000000a888000000abbb00000a0a00800bb000aaaaaaaaaa8000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000a888000000aa88000000a0080abb8000aaaaaaaaaa8000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000a88800000aaa8800000000000aa880000aaaaaaaaa0000
000000000000000000000000000000000000000000000000000000000000000000000000000000000aa88000000aa88000bbb000000aa880000aaaaaaa000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000a888000000aa88000bbbb00000aa8800000aaaa00000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000a880000000aa88000abbbb0000aa8800000aa0000000000
__gff__
8808080801010101010001010008838388888888010101018100010108880800080808080101010101010108888801010808080801008101010101010808010800080808000001010000000000000000080808080000010100000000000000000808080800000101000001010000000008080808000001010001000100000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d50000000000000000d3007170007100707173222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd36c4d6d7c6c513c4c70000d3c0c1c2e2d361607270736070632222222222222222eaeb00000000eeef0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d936d6dbdccfdd36d413131313131313c0c1e0d2d0d1d2c362616363616163622222222222222222fafb00ebed00feff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d93613dbdcdfdd361313131313131313d0d1d2e3e11010e366676667676667672222222222222222fdfaeeedfdedebed0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000076767676062627272626272614f676767676f61546470607aaaaaaaa26262726210321203232323266666766e0e0e0e04120202000000000202024211b0b1b1b005c00015e0b5e0b0008001c242020202020202421212121202020200000000025253636363614365b4b5b5b001c001c000000002627262700000000
0000000076767676143636363636363614f676767676f61556571617babababa393939396262626260606060f6f6f6f6224647224141030300000000212124210008005c005c001c230800080008001c242003202020202422222222020202020000000036f936f936f914368a9a8a8a001c001c000000001636371700000000
0000000076767676373636363636363614f676767676f61526262627e5fb37e5606061602627262760606160f6f6f6f6225657222626272646470527200324201e081e5c0a0b0a0a0a0b5e0b1e0b1e232420202020202024cf02cf0203cf02ce3232323236421442254214361e011e1e5b4b5b5b32323232ce02232300000000
0000000076767676163736173636363614f676767676f6153736361725252425131313133939393904040404f9f9f9f9e0e0e0e01636363676760437030324030008005c0008001c000823080008001c2420202020202024cececfce262626260202cf0236e925e936e91436000000008a9a8a8a06072627cf0202ce00000000
0202020202e0e002e0e0e0e001202020202020201313131300000000011e1e011f3736362b2b2b2b02232302131313131e011e1e20131313717071711e231e23001c001c1ee0e0e00202010200000000000000000000000020202020e0e0e0e0001c001c00000000000000000000000000000000000000000000000000000000
0202020220e0e020e0e0e0e0202021202003200320202020323232321ce0e01c131f36372b2b2b2b231d213d13131313001c00002013131361706070001c001c001c001c30e0e0e0e0e0e00100000000000000003100310002020202e0e0e0e0001c001c00000000000000000000000000000000000000000000000000000000
0202020220e0e020e0e0e0e0212020202001200121202020212020201ce0e01c13131f3621202021231d033d131313131e011e1e20131313606361601e231e23002300231ee0e0e0e0e0e0020000000000c3002b30313031000000001e011e1ee0e0e0e000003100000000000000000000000000000000000000000000000000
0202020202e0e002e0e0e0e0424242422020202002cecfcf02020202011e1e012020201f032021200202020213131313000000002013131363626163001c001c001c001c001c011ce0e0e0023232323232c3c32b302120300000000000000000e0e0e0e031333031000000000000000000000000000000000000000000000000
0252220a7b4141038d400000000000000082220b7841610c92000000000000000053220c58426004800000000000000000a34104880060048a000000000000000082410b8500600488000000000000000283220b9842400488000000000000000282410b8500600388000000000000000018041b886400000000000000000000
070000003000000000000031000000001905000000007000007000000000060200003033333333000000191a3030000000000000000000002224242d000022190000000e0e183400000000000000311900000000006f0000006f6c6f006c6f6c0500000019191a6c6c6f08080000000000000000000000000000000000000000
00000000000000311919050808080401590500000000700000717400330050060e00710c4c4c0c710c58191a71712c2c00000000000061242d6b242d00006119000000191919056c2c0b0b2d00002f196c2d000000000000003100000b0b2c2c0008086c6f6c0808080405000000001900000000000000000000000000000000
30333400302f292f0b0733311d333300195958584e342f7171711b1b1b5b191a1a2c71363600007177775623713106193400000000084c4c4c6b622d00006104020000191919056c6c6f25252d0031230000333400710000006f0071000071000500000019191a6c6c6f25256c6c070000000000000000000000000000000000
00294e26292e261e5e0208300030080819056f710b0b716200097171583004011a2c7771712c2f717777191a71310219191a4d00002f61242d6b622d00006102052c6c1919190558580c19052d076f19006c0203110e0603446f2f00252500000025250071002525250405350000000400000000000000000000000000000000
0303034d021c020d2348456e034d2a3319053071222d3171465229711b301b0b02000071311b08300034191a71614519191a0500383061245e6b4c2d0000610f05000057230823620c1919052d6f6c1919191a052d6f003333713471330e29332533343508080834357108080000310000000000000000000000000000000000
332408454b4b6e6e231e582717650949080871712329357151121771711b1b082d582e71700031302608080832614519191a057171300917160d162d58180902052c6c040362026c2c0b0b0b297100196c6c1902100610014419191a030900001702036c6f6c0203092525222e35184400000000000000000000000000000000
0101010405500403030303040101030309097130024746524202034d5718160d034d2a71084e11024d0d170d23084501191a0103030303030303030303030303056c2c0b086208226223082357716c0419191a052d31191919191a0219191a050d0957575717575757095757570e090300000000000000000000000000000000
030303030303036e0606030303030401051030305004055004040101030303030103085e0804100401010103030303030303010102030303030303030303030301575757174a5757571709030331000300001202120213024419191a01050d0e0101010031000401021709030303030300000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00100000000000000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c07230013
0113800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
000380003f3043e05338033320032e0622a04226022220711c05118021120010e0600803004010020003eb673ab3734b1730b762ab4626b1620b751ab4516b1510b640a3500a0500a0500a0500a0500a0500a050
0103000018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc30
00108000000000000000000000000000000000000000000022136281462a146221162e1762e1762e1762e1072c1072c1072c1762c1262c1662c1662c1662c1662c1662c1662c1262211622147361473813736127
00108000000000000000000000002a1562a15626166261662c14628166281662a1762a1762a1763010730107301073010730107301072e1762e1762e1662e1762e1762c1762e1762e1762e1662c1662c1662c166
0111800010105101050e174243540a1441833406124029643e06338033320032c87322071180110a00038b072ab2318b050ab2400b6338a332aa132ea032ea622aa5228a4226a1224a2224a1222a1222a1222a12
520080003f6103f6103f6100e6100e6100e6100e6100e610356103561036610366103761037610376103761000000376003760037600376103761037610376103761037600376003760037600376003760037600
5a0200003e6103e6303e6303e6203e6103e6103e6103c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000301004010080100e01023333233130c313083100d210082100821008210082000821001200082102f60024600306001f600306001b60018600306001560013600126003860038600336000000000000
510200001f6232861028610286150161019311313210a614026150030000300003000030000300003000030000300003000000000000000000000000000000000000000000000000000000000000000000000000
520200003e6100f3233b6103b6103d6133d6132c61519614266000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52010000143710d361043510135100340366502533025340366403664036640366303663036630366303663036630366303663536635366253663536645366353662536625366103661000000000000000000000
480200003c6100e3230c21337613296133661325024062102761008210366000321039605012003b6000420008200042000820008200082000820001200366000820036600366000000000000000000000000000
50010000193600d350063400333001430014200362003620036100561009610076100161009600066000260000600066000660005600056000460000000000000000000000000000000000000000000000000000
5a020000183730537301363016600565002650086400f6400164006635056350063004620086200662004620036200761006615056150161503610036100c6100261304613016150160500605086050060408604
0a0200003e6201b6403e620376403c62037640376201c6403962032630386200d620366200262033620016202f620026202d620026102a6100361523615026101e61502615146050260032600326003260032600
020200002435314353093533d6503c6503c6403a6503964037640356302f630336202f620306202d6202f6202f610286102f61024610306101f610306101b6101861030610156101361012650386003860033600
0f0100003e6203e6203d6203d6103b610386102f6102a91025910219101d9101b9101791015910113100f3100d3100c2100a21008210072100621004110041100311003110020100001002000000000000000000
4002000031630112202b6101122024610112101d610112101f610112201e6201121025610112102a610112102c61011210296101121026610112102261011200236001120022600112001d600112001a60012200
0a0100001275016760197601b75022750257502874000000000002c6602c6602c6402c630000003b6503b6303b6303b6253b6203b6203b6103b61500000000001370017700187001c70000000000000000000000
0a0100003b6303b6303b6303b6303b6303b6303c6002c6202c6202c6202c6202c6202c6200000025745227501f7501b7401774514730127200e7200e720000000000000000000000000000000000000000000000
080200000f64014641186311d610156532a740227601b750167400f7300a720087100571004710037100300000601000030060400600006010300004700037000070000700000000000000000000000000000000
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

