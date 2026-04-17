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

w_text = ""
s_text = ""
s_col = 7

function load_m_menu()
	menu_state = 0
	-- input delay
	poke(0x5f5c, 0)
	poke(0x5f5d, 0)
	
	w_text = "main menu"
	s_text = "select level \fd(❎ to output all)"
	s_col = 7
	
	_draw = _draw_m_menu
	_update = _update_m_menu
	
	x_off,y_off,mm_scale,skip_borders = 0,0,4,false
	menuitem(2,"view map", view_map)
end

function view_map()
	_update,_draw=_update_mapview
	menuitem(2,"back to menu", quit_map)
	draw_map_miniview()
end

function quit_map()
	_update,_draw = _update_m_menu,_draw_m_menu
	menuitem(2,"view map", view_map)
end

function draw_map_miniview()
	cls()
	
	camera(x_off, y_off)
	
	
	local p1_time = 0
	
	for j=max(y_off\mm_scale,12),min((y_off+128)\mm_scale-1,39) do
		for i=x_off\mm_scale,min((x_off+128)\mm_scale-1,127) do
			
			local tile = mget0x20(i,j)
			local t2,alttex,altlay = tile&0b00111111,bcheck(tile, 0b01000000), bcheck(tile, 0b10000000)
			local tex_x_coord,tex_y_coord = (t2%32)*4, (t2\32)*4+4
			
			for y=0,3, 4\mm_scale do
			
				local tex_y_coord2 = tex_y_coord+y
				
				for x=0,3, 4\mm_scale do
					local tile_tex = mget0x20(tex_x_coord+x,tex_y_coord2)
					
					local mod_tile = tile_spr(tile_tex, alttex,altlay)
					
					local d_p, p_col = false,0
					
					if fget(mod_tile,3) and mod_tile != 0 then
						d_p,p_col = true,1
					end
					if fget(mod_tile,0) then
						d_p,p_col = true,2
					end

					if (d_p) pset(i*mm_scale+x*mm_scale/4,j*mm_scale+y*mm_scale/4,p_col)

				end
			end
		end
	end
	
	if not skip_borders then
		for i=1, #lvls_info_2 do
			local level_main = lvl_arr(i,2)

			local map_pos_x = level_main[1]*mm_scale
			local map_pos_y = level_main[2]*mm_scale
			local ld_l_size_x = level_main[3]*mm_scale
			local ld_l_size_y = level_main[4]*mm_scale
			
			local d_col = i%4
			if (d_col < 3) d_col |= 0b100
			
			local fill_p = 0b1010010110100101
			if (i%2 == 1) then
				fill_p ^^= 0b1111111111111111
			end
			
			fill_p += 0b0.1
			fillp(fill_p)
			rect(map_pos_x,map_pos_y,map_pos_x+ld_l_size_x,map_pos_y+ld_l_size_y,d_col)
			fillp()
			color(d_col)
			print("\^o0ff"..i,map_pos_x+ld_l_size_x/2-2,map_pos_y+ld_l_size_y/2-2)
		end
	end
	
	
	fillp(0b1101101101111110.1)
	rectfill(0,40*mm_scale,128*mm_scale-1,128*mm_scale-1,5)
	rectfill(0,0,128*mm_scale-1,12*mm_scale-1,5)
	fillp()
end

function _update_mapview()
	
	flip()
	if (btnp(0)) x_off -= 64
	if (btnp(1)) x_off += 64
	if (btnp(2)) y_off -= 32
	if (btnp(3)) y_off += 32
	
	if btnp(4)  then
		if mm_scale == 2 then
			mm_scale = 4
		else
			mm_scale = 2
		end
	end
	if btnp(5) then
		skip_borders = not skip_borders
	end
	
	if btnp() != 0 then
		
		x_off %= 128*mm_scale
		y_off %= 32*mm_scale
	
		draw_map_miniview()
	end
	
end


function print_outl(txt,x,y,col,out_col)
			print(txt, x-1,y  ,out_col)
			print(txt, x  ,y-1,out_col)
			print(txt, x+1,y  ,out_col)
			print(txt, x  ,y+1,out_col)
			
			print(txt, x,y,col)

end

function lvl_arr(lvl_index,index)
	local arr = split(split(lvls_info_2[lvl_index],"⬅️")[index],"`")
	if (#arr <= 1) return {}
	return arr
end

function _draw_m_menu()
	cls(0)
	
	local s = 14
	
	cam_y = cursor_pos*s-20
	camera(cam_x, cam_y)
	
	-- have to temporarily switch maps for tline
	poke(0x5f56,0x20)
	
	local level_num = 1
	for i=1, #lvls_info_2 do
		local lvl_title_info = lvl_arr(i,1)
		local lvl_main_info = lvl_arr(i,2)
	
		local yval = i*s + 12
	
		local l_txt_col = 7
		if cursor_pos == i then
			l_txt_col = 12
			rect(1, yval - s\2, 127, yval + s\2,l_txt_col)
		end


		local pal_transp_col = lvl_main_info[13]
		
		-- col
		rectfill(2, yval - s\2+1, 126, yval + s\2-1,pal_transp_col)
		rect(2, yval - s\2+1, 126, yval + s\2-1,l_txt_col)
		

		
		-- bg sample
		for	j=0, s-4 do
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, lvl_main_info[14]*8,  j/8+1, 1/8, 0)
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, lvl_main_info[14+10]*8,j/8+1, 1/8, 0)
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
		s_col = 7
	end
	if btnp(3) then
		cursor_pos += 1
		s_col = 7
	end
	cursor_pos = ((cursor_pos-1)%#lvls_info_2)+1
	if btnp(4) then
		load_l_editor()
	end
	if btnp(5) then
		compress_data()
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
	
	time_c = 0
	_draw = _draw_l_editor
	_update = _update_l_editor
end

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
	cls(loaded_level_main[13])
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
	end
	
	map(unstr"0,0,0,0,128,64,0b1000")
	map(0,0)


	rect(l_curs_x*32, l_curs_y*32,l_curs_x*32+32, l_curs_y*32+32, l_c_col)
	
	
	if (mous_prev&0b10 == 0) draw_extras()
	
	poke(0x5f5e, 0b01110111)
	rectfill(-256,sludg_l-(t()\2)%2,512,1024,sl_c)
	poke(0x5f5e, 0b11111111)
	
	
	draw_sidebar()
	
	
	print_outl(w_text,cam_x+1,cam_y+1,7,4)
	print_outl(s_text,cam_x,cam_y+121,7,9)
	
	draw_cursor()
	
--stat(34) -- mouse buttons (bitfield))
	
end

function draw_m_sprite(pos,m_spr,spr_size,is_left,is_up)
	if m_spr then
		local e_spr,s_x,s_y,a_t,a_n = unpack(m_spr)
		if e_spr >= 0 then
			local spr_size = spr_size or 8
			local spr_sw,spr_sh = s_x*spr_size, s_y*spr_size
			--e_spr += ((anim_c\a_t)%a_n)*s_x
			sspr(e_spr%16*8,e_spr\16*8,s_x*8,s_y*8,pos.x-spr_sw/2,pos.y-spr_sh/2,spr_sw,spr_sh,is_left,is_up)
		end
	end
end

function text_box(str,screen,x,y,xlen,ylen,c1,c2)
	if (screen=="true") camera(0,0)
	if (c1 and c1>-1)rrectfill(x-6,y-4,xlen,ylen,0,c1)
	if (c2 and c2>-1)rrect(x-5,y-3,xlen-2,ylen-2,0,c2)
	print(str,x,y,7)
	camera(camera_x,camera_y)
end


-- assumes both have same radius
function circ_intersect(p1,p2,r)
	local d,mid_p=vec2_len(p2-p1),(p1+p2)/2

	local op=(p2-p1)*sqrt(r*r-d*d/4)/d

	local op2=vec2_new(op.y,-op.x)

	return mid_p+op2, mid_p-op2
end

function line_vec(v1,v2,col,thickness)


	for i=0, thickness or 0 do
		local vec = vec2_rotate(vec2_right,(i%4)/4)*i\4
		local v1_1,v2_1=v1+vec,v2+vec
		line(v1_1.x,v1_1.y,v2_1.x,v2_1.y,col)
	end

end

function draw_joint(p1,p2,rds,col,is_left,width)
	if p1 != p2 then
		local k_2, k = circ_intersect(p1,p2,rds)
		if (is_left) k=k_2

		line_vec(p1,k,col,width)
		line_vec(k,p2,col,width)
	end
end

function draw_link(link)
	local envstr,_ENV = _ENV,link -- forbidden token-saving reality warping spell
	-- link's members are now "globals" and all previously global variables are now accessed trough envstr
	-- local makes it work only inside this function (and luckily not inside envstr's)

	local p1,p2,l=from.pos,to.pos,from.is_left
	if (to_ground) p2 = to


	if draw_type == 1 then
		envstr.line_vec(p1, p2, col,width)
	elseif draw_type == 2 then
		envstr.draw_joint(p1, p2, len/2, col, l,width)
	elseif draw_type == 3 then
		local pos_2 = p1 + envstr.vec2_normalized(-from.facing)*3
		envstr.line_vec(p1, pos_2, from.col or 13, width)
		envstr.draw_joint(pos_2, p2, (true_len - 3)/2, col, not l,width)
	elseif draw_type == 4 then
		envstr.draw_joint(p1, p2, len/2, col, false,width)
	end

end

function draw_extras()
	
	-- level camera borders
	rect(x_l_l+128, y_l_l+128, x_u_l, y_u_l, 8)
	
	print("menu cam pos" ,loaded_level_title[5], loaded_level_title[6]-8, 4)
	rect(loaded_level_title[5],loaded_level_title[6],loaded_level_title[5]+128,loaded_level_title[6]+128,4)
	
	print("pl" ,loaded_level_title[3], loaded_level_title[4]-8, 12)
	
	rect(loaded_level_title[3]-2,loaded_level_title[4]-2,loaded_level_title[3]+2,loaded_level_title[4]+2,12)
	
	for i=1, 4 do
	
		if i==3 then
			-- solid map
			map(unstr"0,0,0,0,128,64,0b00000111")
		end
		
		for j=1, #(loaded_level_entities or {}), 4 do
			local e_type,ex,ey,e_extra = unpack(loaded_level_entities, j)
			local pr = split(ntt_types[e_type], "|")
			local props_c,props_e = pr[1], pr[2]
			
			local entity = mod_tabl({},props_e)
			-- TODO preset extras
			if (e_extra) mod_tabl(entity,e_extra)
			
			entity.pos = vec2_new(ex,ey)
			local ntt_rad = split(props_c)[2]
			
			if (entity.d_o or 3) == i then
				
				if entity.rope then
				
					local link=mod_tabl2(
					{},"from,to,l_type,len,to_ground,strenght,draw_type,col,is_front,width",
					{entity, vec2_new(ex,ey) + vec2_new(entity.rX,entity.rY),unpack(split(links[entity.rope]))})
					link.true_len=link.len

					draw_link(link)
					
				end
				
				draw_m_sprite(vec2_new(ex,ey), split(split(props_c)[4],":"), entity.spr_size, entity.is_left, entity.is_up)
				
			end
			
			if i==4 then
				if (mous_x>(ex-ntt_rad) and mous_x<(ex+ntt_rad)) and (mous_y>(ey-ntt_rad) and mous_y<(ey+ntt_rad)) then
					rect(ex-ntt_rad, ey-ntt_rad, ex+ntt_rad, ey+ntt_rad,3)
					if entity.text_box then
						text_box(unpack(split(entity.text_box,"⬇️")))
					end
				end
			end
		
		end
		
	end
	
	for i=1, #(loaded_level_signs or {}), 3 do
		local x,y,text = unpack(loaded_level_signs,i)
		text_box(text,false,x,y)
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
			local t_spr = tile_spr(mget0x20(tx+i,ty+j), alt_t, alt_l, true)
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
	time_c+=0.0333333
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

	if (ntt_in_drag and ntt_in_drag > -1) then
		
		loaded_level_entities[ntt_in_drag+1]=mous_x
		loaded_level_entities[ntt_in_drag+2]=mous_y
		s_text = "n:".. (ntt_in_drag\4)+1 .. " t:" .. loaded_level_entities[ntt_in_drag] .. " x:"..mous_x.." y:"..mous_y
	end
	
	ntt_in_drag = -1
	
	
	if mouse_on_canvas then

		for i=1, #(loaded_level_entities or {}), 4 do
			local e_type,ex,ey,e_extra = unpack(loaded_level_entities, i)
			local pr = split(ntt_types[e_type], "|")
			local props_c,props_e = pr[1], pr[2]

			local entity = mod_tabl({},props_e)
			if (e_extra) mod_tabl(entity,e_extra)

			local ntt_rad = split(props_c)[2]

			if (mous_x>(ex-ntt_rad) and mous_x<(ex+ntt_rad)) and (mous_y>(ey-ntt_rad) and mous_y<(ey+ntt_rad)) then
				
				if mous_prim==1 then
					ntt_in_drag = i
					break
				end
			end

		end

		if (ntt_in_drag == -1) then
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
	end

	
	mous_prev = mous_p
end


function load_level(index)

	loaded_level_title = lvl_arr(index,1)
	loaded_level_main = lvl_arr(index,2)
	loaded_level_entities = lvl_arr(index,3)
	loaded_level_signs = lvl_arr(index,4)
	

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

	pal(unpack_pal(loaded_level_main[12]), 1)
	
	mod_tabl(_ENV,"lvl_enms,lvl_e_clear,x_u_l,y_u_l,trn_bnc,trn_slp,grav,lvl_tr_collected,lvl_trinkets,sludg_l,sl_c/0,0,0,0,0.2,0.75,0.22,0,0,512,6")
	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1
	x_l_l=l_border_x-127
	y_l_l=l_border_y-127
	
	-- lvl extra globals and defaults
	mod_tabl(_ENV,loaded_level_title[9])
	
	
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


-- flags:

-- 0: is solid
-- 1: is grabable
-- 2: 
-- 3:
-- 4: is bg
-- 7: keeps texture on switch

function tile_spr(s, alt_t, alt_l, norand)
	local s1,extra_b = s&0b00111111, s&0b11000000

	-- alt layout
	if alt_l then
		if bcheck(extra_b,0b01000000) then
			-- flip 3rd bit
			s1 ^^= 0b100
			-- swap to first sprite in 2x2 segment
			s1 &= 0b11101110
		end
		if bcheck(extra_b,0b10000000) then
			s1 ^^= 0b1000
			s1 &= 0b11101110
		end
	end

	if bcheck(s1, 0b00100000) and (s1 & 0b00001000 == 0) then -- in bottom left part of spr page
		-- flip 1st bit
		if (rnd(20) > 19 and not norand) s1 ^^= 0b1
	end

	-- alt texture
	if (alt_t and not fget(s1,7)) s1+=0b01000000

	return s1
end

function draw_tile(t,x,y)

	local t2 = t&0b00111111

	for j=0,3 do
		for i=0,3 do
			local m_x,m_y = x*4+i, y*4+j
			srand(m_x + m_y*ld_l_size_x)
			mset(m_x,m_y, tile_spr(mget0x20((t2%32)*4+i,(t2\32)*4 +4+j), bcheck(t, 0b01000000), bcheck(t, 0b10000000)))
		end
	end


end

function save_level()
	
	-- settings & entities
	
	local lvl_filename = "editor_level_".. cursor_pos .."_settings.txt"
	
	
	printh("lvl settings (2nd field):", lvl_filename, true)
	
	lvl_string = ""
	for i=1, #loaded_level_main do
		local dat = loaded_level_main[i]
		if i==17 or i==27 then
			dat = tostr(dat, true)
		end
	
		if (i!=1) lvl_string ..= "`"
		lvl_string ..= dat
	end
	
	printh(lvl_string, lvl_filename, false)
	printh("	[[" .. lvl_string .. "]],\n", "@clip")
	
	printh("\nentity type + positions:", lvl_filename, false)
	
	for i=1, #(loaded_level_entities or {}), 4 do
		lvl_string = tostr(loaded_level_entities[i])
		lvl_string ..= "`" .. loaded_level_entities[i+1]
		lvl_string ..= "`" .. loaded_level_entities[i+2]
		
		printh(lvl_string, lvl_filename, false)
	end
	
	
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
	time_c+=0.0333333
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
		if l_set_cursor_pos >= 5 and l_set_cursor_pos <= 11 then
			update_mus()
			if (not stat(57)) music(loaded_level_main[5], 1000)
		else
			music(-1)
		end
	end
	
	l_set_cursor_pos = mid(1,l_set_cursor_pos,33)
	
	
	l_add=0
	if btnp(4) then
		l_add=1
	end
	if btnp(5) then
		l_add=-1
	end
	
	if (btnp(4) or btnp(5)) and l_set_cursor_pos > 4 then
	
		if l_set_cursor_pos == 17 or l_set_cursor_pos == 27 then
			l_add *= 0x0.08
		end
	
		loaded_level_main[l_set_cursor_pos] += l_add
	
		loaded_level_main[6] %= 16
		loaded_level_main[7] %= 2
		loaded_level_main[8] %= 2
		loaded_level_main[9] %= 2
		loaded_level_main[10] %= 2
		loaded_level_main[11] %= 2
	
	
		loaded_level_main[20] %= 2
		loaded_level_main[21] %= 2
		loaded_level_main[30] %= 2
		loaded_level_main[31] %= 2
		
		
		if l_set_cursor_pos == 1 then

		elseif l_set_cursor_pos >= 5 and l_set_cursor_pos <= 11 then
			update_mus()
			if (not stat(57) or l_set_cursor_pos == 5) music(loaded_level_main[5], 1000)
		elseif l_set_cursor_pos == 12 then
			pal(unpack_pal(loaded_level_main[l_set_cursor_pos]), 1)
		end
		
		if l_set_cursor_pos >= 14 then
			time_c = 0
		end
			
	end
	
end

function draw_bg(offset) 

	mod_tabl2(_ENV,"b_img_indx,b_pal,b_sc,b_prlx,b_ofx,b_ofy,b_wx,b_wy,b_timx,b_timy",{unpack(loaded_level_main,offset+14)})

	pal(unpack_pal(b_pal+16), 0)
	
	local p_sc = b_sc*8
	local a_p_sc = abs(p_sc)
	local scrl,ts_x,ts_y = b_prlx, b_timx,b_timy
	local wrap_x,wrap_y = b_wx==1, b_wy==1
	
	local scroll_x,scroll_y = -b_ofx+camera_x*scrl+time_c*ts_x, -b_ofy+camera_y*scrl+time_c*ts_y
	
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
	cls(loaded_level_main[13])

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
	
	"music layers: ",
	"(unused slots): ",
	"(): ",
	"(): ",
	"(): ",
	"(): ",
	

	"main palette: ",
	"clear color: ",
	
	"background 1 (back) : ",
	"bg 1 palette : ",
	"1 scale : ",
	"1 parallax : ",
	"1 x offset: ",
	"1 y offset: ",
	"1 x wrap: ",
	"1 y wrap: ",
	"1 x timescroll: ",
	"1 y timescroll: ",
	
	"background 2 (front) : ",
	"bg 2 palette : ",
	"2 scale : ",
	"2 parallax : ",
	"2 x offset: ",
	"2 y offset: ",
	"2 x wrap: ",
	"2 y wrap: ",
	"2 x timescroll: ",
	"2 y timescroll: "
	}
	
	
	
	for i=1, 33 do
		local dat_str=loaded_level_main[i]
		if i==17 or i==27 then
			dat_str=tostr(loaded_level_main[i],true)
		elseif i==6 then
			-- NOTE: Layers are displayed in reverse binary to correspond to the channels, but are stored normally
			-- so 0001 would be 3rd channel active, and would be stored as 8 (0b1000)
			dat_str=""
			for j=0,3 do
				if (bcheck(loaded_level_main[i], 1<<j)) then
					dat_str..="1"
				else
					dat_str..="0"
				end
			end

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

	if l_set_cursor_pos == 12 then
		draw_pal(16)
		
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
		
	--elseif l_set_cursor_pos == 7 then
	--	pal(unpack_pal(loaded_level_main[1][5]+16), 0)
		--draw_pal(0)
	--	pal(0)
	elseif l_set_cursor_pos == 15 then
		pal(unpack_pal(loaded_level_main[15]+16), 0)
		draw_pal(64)
		pal(0)
	elseif l_set_cursor_pos == 25 then
		pal(unpack_pal(loaded_level_main[25]+16), 0)
		draw_pal(160)
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
	cls(13)

	camera(0, tex_cam_y)

	local grid_x = 0
	local grid_y = 0
	
	for i=0, 63 do
		
		local draw_x = grid_x * 32
		local draw_y = grid_y * 32
		

		
		
		local t_x,t_y = get_texture(i)
		
		for j=0,3 do
			for i=0,3 do
				local t_spr = tile_spr(mget0x20(t_x+i,t_y+j), tex_alt_t, tex_alt_l, true)
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

mus_p,mus_layer = true,false


function bcheck(v,b)
	return (v or 0) & b != 0
end

function update_mus()

	for i=0, 63 do
		--0x3100 is start, 0x3101 means target 2nd channel
		for j=0,3 do
		
			local addr = (0x3100+j + i*4)
			local fl = @addr
			if bcheck(loaded_level_main[6], 1<<j) then
				fl &= 0b10111111
			else
				fl |= 0b01000000
			end
			
			poke(addr,fl)	
		end

	end
end


-->8
-- data
#include dropkicks_inc.p8:B

#include data_compressor.p8:1
#include data_compressor.p8:2

__gfx__
00000000555555545555555444444444aabbbaaeba999999ba9a99ab99a8ab9ab984489aaaaaaaaabbbbbabb8b8b8b8b000000000000000077777d7877787778
00000000555555445444444455555554b99999e8a9888899999999999998b999bb8448baa999999b8b8998b8aaaaaaaa00000000000000007dd78788ddd88d88
00000000544444445444444454444444b99eeee899999999999999999998a999b9b99b9aa900000b98b88b89bbbbbbbb00000000000000007dd788787877d888
00000000555555445444444454445454b9eeeee8a8888889999999999998a999b98bb89aa900000b449bb944aba88aba00000000000000007d78ddd8d8d888dd
00000000544444445444444454454454a9eeeee8999999999999999999989999b98bb89aa900000b449bb9448abaaba800000000000000007788ddd8778d7788
00000000555555445444444454444454a9eeeee899888898999999999998a999b9b99a9aa900000b98b88a898a8bb8a8000000000000000078d78dd8dd888dd8
00000000444444445444444454444454aeeeeee899999998999999999998a999bb8448aaa900000b8b8998a8aabaabaa00000000000000007dddd8d878dddd88
00000000555444444444444444555554e888888e99999888999999999988a999b984489aabbbbbbbaaaaaaaaab8998ba0000000000000000d888888d8dd88888
11111111222222225555555544444444aaa999999999999a9a9a9a9a88888888ff999fdd8444445ababbbbba9b9b9b9b54005554444444445555555589889988
11111111222222225555555544444444a9999999999999998989898988888888fd9999df8444454ab9aaaa9a8a8a8a8a540550545555555554444445489aaaa9
11111111222222225555555544444444bbaa9aa999999aaa8888888888888888ddf999ff8444444ababaabaabbbbbbbb54550054444444445500005544899999
11111111222222225555555544444444baa9999999999a998998999988888888dff99ffd8444444aaaaaaaa999aaaa9955500054555555550550055044489999
11111111222222225555555544444444a9999999999999998888888888888888ff999fdd8444444abaaaaaa9888aa88855500054444444440055550044448998
11111111222222225555555544444444ba9aa9999999a9aa8888888888888888fd9999df8444444aaabaaba8888aa888545500545555555500055000554448aa
11111111222222225555555544444444b9999999999999998888888888888888ddf999ff8444444aa9aaaa9888aaaa8854055054444444445555555544444489
11111111222222225555555544444444a999999999999aaa8888888888888888dff99ffd9aaaaaaa888888889999999954005554555555554444444445554448
44444444444444444554455455555555baa9baa99aa99999bba9bbbabb9bbbb9bbbabbba99888989ba9bba9b55455545fffffffd7777777d8888888800000000
555545554555445544554455545544559999999999999999baa9baa9aa9baaa9baa8baa888888888aa9bba9b55455545fdffddfd7377337d8999999900000000
44444444444444445445544554455445a9baa9aa999999aabaa9a999999a9999baa8baa899999999ba9bba9b55455545fffddffd7773377d8989998900000000
554555455445544555445544554455459999999999999999aaa999999e999ee9a888888888899988ba9bba9b55455545ffddfffd7733777d8999999900000000
44444444444444444554455455544555baa9aaa9aaa9aa999999999999999ee9eeee9eee99999999ba9bba9b55455545fddffdfd7337737d8999999900000000
4555455545444555445544555455445599999999999999999999999999999999e9e99e9e99999999ba9bba9b55455545fdffddfd7377337d8989998900000000
44444444444444445445544554455445a9aaa9aa999aa9aa999999999999999999999e9999999999ba9bba9b55455545fffffffd7777777d8999999900000000
55545554555455545544554455555555999999999999999999999999999999999999999999999999ba9bba9b55455445dddddddddddddddd8888888800000000
05000505050000050000000500000005bbbbb8bbbbbbbbbb99999999999999999999999999999999aa9bba9b0000000000000000554444440000000000000000
0500050505000005555555550000005599b98bb999b999b999999999999999999999999999999999ba9bba9b0000000000000000554444550000000000000000
550055550500050505050505000005059988b9899989998999999999999999999ee99e9e99999999ba9baa9b0000000000000000554444440000000000000000
555005550500050550505055500000559998b999888888889999999999999999eeeeeeee99999989ba9bba9b0000000000000000554444450000000000000000
050005050500050505050505050005059998b9998b9999b89999999999999a99bbbabbba88888888ba9bba9b0000000000000000554444440000000000000000
050005050500050555555555555555559998b9998899998899999999a99aaaa9baa8baa899989999ba9bba9b0000000000000000554444550000000000000000
05000555550055055555555555555555888888888b9999b899999999999a9999baa8baa888888888ba99aa990000000000000000554444440000000000000000
5500050555000505555555555555555599988888888888889999999999999aaaa888888888888888998899880000000000000000554444450000000000000000
aaaaaaaa555445445544455455544455ab9b9995babbba9877f9f9fffff9f9ff909fd0900000000099900999f7ffffff0000000000000000aaaaaaaaaaaaaaaa
a000000a5455444445544544544545559bbbbbb9b8baa8987f7fffffffff9fff999fd090000000009f7fffff7f7fff7f0000000000000000a000000aa000000a
a0000a0a444445544454554445444554abbababab8baa898f7ffff7fffff7fff009ffd9800000000f7ff7ffff7fffff70000000000000000a0000a0aa0000a0a
a000a00a554555445444454545445544abbaaa9aa8a88888fffffffffff7ffff0f9dd888000000008ffffffffff7ffff0000000000000000a000a00aa000a00a
a00a000a5445545444445454445454449ab9b9aababbba98ffffffffffffff7ffd9fd990000000009f8f8f8fffffffff0000000000000000a00a000aa00a000a
a0a0000a4455444555445444444444449a9a9aa9b8baa898fffffffff7fff7f7ddddd080000000000888f8f8f8f8f8f80000000000000000a0a0000aa0a0000a
a000000a445444445444554455444445999a9a99b8baa898f9fffff9f9ffff79080fd98000000000f989897f898989890000000000000000a000000aa000000a
aaaaaaaa44444455444445445444445589999999a8a888889f9f9f9f9f9fff9f089fd80000000000f80099ff989898980000000000000000aaaaaaaaaaaaaaaa
aaaaaaaa11111111aaaaaaaa454445459899999999999989baabbbab44aa9485aaaaaaaa4a5a959a97f9f979f7ffffff05445050444444450000000054999999
a000000a11010111a000000a545444448999999999999998988999995a998445a000000aa454a49a7f7f97f77ffff7ff05045550445454550555555054499a99
a0000a0a01101011a0000a0a54444454889999999999998888888888a9988884a0000a0a4954a494f7f9f979ffffffff550555004545454505555554445999a9
a000a00a10110110a000a00a4444454458899999999999898888888888898855a000a00a459999949f9f9f9ff9f9f9f905454505445454555555555445494999
a00a000a01010001a00a000a4444444458999999999998898898889989888544a00a000a4549449af979f9f99f9f9f9f05554555454545455454545445494999
a0a0000a00100000a0a0000a4445444489999999999999858888889988888888a0a0000a99a9594a97f7f7ff8989898900454500445454554545454555454449
a000000a00000000a000000a4444544589999999999999989988888888888898a000000a9aa49a59f9797f798888088805454500454545455454445555455459
aaaaaaaa00000000aaaaaaaa4544444499999999999999899989989958888985aaaaaaaa9a44aa599f9f97ff0808008004454550555555550404040455555454
454455455454554455545554555444449bbb99a99ba999995b5bb5b55b55bb5b000000004a54ba5aba9bbab90000000045d444fdff4774ff9999999900000000
54545454455454545554555455544444bbaaaa99ba999999bbbbbbbbbbbbbbbb00000000ab94aa4ba99babab000000005dffdfd44ff77ffd9988988900000000
55444544545544545554555455544544aaaaaa9b99999bb9abbbaababbababbb00000000a9b9a99aba9b9ba9000000004fffdff44ff77fd49898989800000000
454545454554545544444444444455549aaaa9999999baa9ababaa9aabaabaab0000000099aa9a9aba9a9ba9000000004ffdffd6777337779889998800000000
54545444545545545554555455445555b99999bbbbb9aa999a9aa9a9aaa9ba9a00000000999a9a9aba9b9ba9000000004fdfffd6f773377f9999999900000000
45454445454544555554555455444554aaa9bbbaaa99999aa99b9aa9a9a99a9a0000000099a99a99aa9b9a99000000004ddffd664ff77ff49889998800000000
45455454454544545554555454544444aa99baaaa999ba9aa9ab9a9aa99a99a90000000099999999ba9b9ba90000000054fdd66dffd77fdd9898989800000000
54445454554554554444444444444444a9999aaa999aaa9999a9999a999999a90000000099999999ba9baba900000000d54666d4fd47f4dd9988988900000000
50450405000500500000000000000000bbbabbbabbba88b8aaaaaaaa99a999990000000099999999ba9b9ba90000000000000000544545440000000000000000
44540455050450450000400400000000baa8baa8baa88aaba000000a9a99a99900000000a99999a9ab9baab80000000000000000544545440000000000000000
04545454045540055054004005004500baa8baa8baa8aaa9a0000a0a99999a990000000099499a99ba8a8bab0000000000000000544445440000000000000000
54544044054040540405005454045040a8888888a8888aa8a000a00a9999a9a90000000099599999bb8aab8b0000000000000000544554540000000000000000
55454540454540450545050445055405bbbabbbabba98888a00a000a9a99a9aa00000000a9495999bababa8a0000000000000000544445440000000000000000
54504545505445554545454540050454baa8baa8ba988988a0a0000aa99999a9000000005a454949a9baba8b0000000000000000544445440000000000000000
54555045545445545405554554505455baa8baa8a9988989a000000a999a999a0000000059445949b9b998890000000000000000544455550000000000000000
44545445045404555554555554545545a888a88898889989aaaaaaaa999999990000000044545445b99bab890000000000000000544444440000000000000000
ba988898999999990000000000000300000bbb00aa0000ba444fd8445bbbaa9aaaba998800000000bbb99b999999b9aa9bb9aaa9444454444544544500000000
b88ba88899bba99a00000000030003000baa99a0999bba995557d855baa999999999999800000000bbaabaabbb9bba99bbaa9999444454444544444400000000
b8baaa849aaa999900300000030003000a99809a89bba988444fd844ba99a999a999999800000000aaa9aaabbaa9a99b9aa99bb9444554444544544400000000
a8baa884999999a90003000003003000ba9099000bba988977f7f7f7b99999999999999900000000aaa99a999a9b99999999baaa445544444444445400000000
888a8984999a999b0000300003003000ba08aba0baa989abdddfdddda9a999999999999900000000b9aa99bbb9baa9bbbbb99aa9555445554454445500000000
88884854b9999ba90000033033033003098a80b9a99809998887d888a99999999999999900000000aa9b9bbaaa9a9bbbaaaa999b444455444454454500000000
48884454ba99baa90000003333033003009898b988000008444fd844999999999999899900000000a9baabaaaaa9bbaaaaa9bbb9444454444445454400000000
545855549aa99aa9000000033b0330300098a9b900000000555fd854899999988999999800000000999a99aaaa999aaa9a9bbaaa444454445445444400000000
00000000999ba9990033003a33b3b030bbaba99a888888888888889999999999999999999999999999999999b9b9b9b900000000baaabbbb9a98999a00000000
00000000a9ba99990000330393b3a330babaa9aa88988888898888999999999999999998999999a999999aa9a89898980000000088ab9898a9a98a9900000000
0000000099a999a93300a33b3b8ab330abb9999a88889988888888889999999999998898999999a999999aa999a999a900000000888a88889abaaaa900000000
000000009999ba99003330a9b3a8b300ba9ba8a88988998888899888999999999999999899a99999999999999999999a00000000888988889baaaaa900000000
000000009ba99999000033389b898bb0ba9aa8a8888888888889988899999999998999989a99999999a999999999999900000000888988889aaaaa9800000000
00000000baa99b990000baba8ab89a33abb8898a888888889888888999889999999999889a9999999999aa99999999990000000089898899a9aaa99800000000
00000000ba95baa933333aab88ab83909a9aa8a88888888898889889899999999999988899999999999999999999999900000000889988998a9a998900000000
0000000045554ba40000333a8888aa89a9a9a888888888888898888888998888888888889999999999999999999999990000000099999888a899989800000000
000000003d666dd3000dd0000000000d03000000ddddddd600dddd000000000000022000000cc00000666600000000000008ddd00dddd0000000000d70000000
00000000d66d66630dddddd0000003d00d000000666663d60dddddd000022000023773200cf77fc006666666000000000ddd8dd66dddddd000000007e0000000
00888000666636303dddddd666663d006d66600066663636d8d66dd800233200037777300f7dd7f06666666666000000ddddd8866dddddd800d0007dee000e00
0c8d800063dddd30638ddd66366777776d66660063366366dd6336d80237732027777772c7dccd7c6666666666660000dddd88888dddd8880007d0d99e0ee000
00cdd00063dddd3086836666366dddddd3d33d3d36d36666dd6336880237732027777772c7dccd7c6666666666666600d888668668688888000dd966669ee000
0080000066666630838666663366d300dddddddd3d636666ddd6688600233200037777300f7dd7f066666666666666660066686336866600000096d666690000
00000000d66d66630683666006000d3066666600633666660dd8886000022000023773200cf77fc0ddd66666666666660000686336860000007d6d663666ee00
000000003d666dd300866600000000dd6666660066666666008866000000000000022000000cc000666ddddddddddddd0000008668000000d7d9666363669eee
000000000000000000003000066dd66000ddd60000ddd60000ddd600006606600606660000606600666666666666666600000000000000007dd9666636669eee
00fffc0000000000003666306d6666d30dd666600dd666600dd6666060606600066660660606666066666666666666d300f000000000000000dd666666e6ee00
0f7cccc0000000000300600366d66d66366366363d366363d3663663666066666066066066066006666666666666d3d300f6600000999000000096666e690000
0fcccc80000000000366666366d66dd366666666666666666666666606666006660666666666666066666dddd6d3d3d300f333000087d700000dd966669ee000
0fcccc80000000000300600366d33d666666666666666666666666666006666066666066066666660666d6666dd3d3000066600000999000000dd0d99e0ee000
0cccc880000000000036663066d33dd3336666333366663377666677666606660660660660066066006d666666d30000000000000000000000d000ddee000e00
00c888000000000000006000d6d66d6d773663770036630000766700006606066606666006666060000d66666d00000000000000000000000000000de0000000
00000000000000000fd666df0dd66dd0077007707000000700000000066066000066606000660600000000000000000000000000000000000000000de0000000
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
002222220101111100000000111323320000000000003003ff0ff0fd000000007fffffff7f7fffff0000000000000000000000000bb000000000000000b80000
022222331010111100222000122222110000000030003003fdffffd90f9ff9d0fc7ccccdfc7ccccd000000000000000000a8000bbbbbb00000000000b8888000
2222333311010101222222202221211100000000030003030fdffd9000dffd90f777cccd77c77ccd00000000000bb00000a8800abbb88000000000ba88888800
2223332301000010333322221211132200000000003b03a3fff77fff0ff77ff00d7ccc800d7ccc8000000000000abb0000a8800aaa88800000000baa88888800
23322222001000003222320021113221000000000033a03bfff77ffd0ff77ff00dcccc800d7ccc8000000000000a880000a8000aaa8800000000baaaa8888880
33212121000000002122130011121211000000000003b9390fdffdd009dffd90008cc800008cc800000a880000aa88000a8800aaaa880000000baaaaa8888888
12121111000000001211122011212111000000003330ab98fd9ffd990d9ff990008cc800008cc800000a888008aa80000a8000aaaa88000000baaaaaaa888880
11211111000000002111112211111111000000000003b8b8dd0fd09900000000000880000008800000aa888000aa00000a0000aaa88000000baaaaaaaa888880
000000000000000000ffff0000dddd00000000220ff7fff000dfddd00ddf700000ddd000dddddddd00aa888000a08000008000aa8a8000000aaaaaaaaaa88800
0000000000fffd000f7ffdd00dddddd022222252f7fffff70fffffdddff777f00ddddd003d6d6dd300aa8880000abb00a80000aa080000000aaaaaaaaaa88800
000ff0000f7fdd80f7fdddd8d3ddddd325a2aa20fffffffd0dfff880dd777fd0008880003d66666300a888000000abbb00000a0a00800bb000aaaaaaaaaa8000
00f7d8000ffddd80ffdddd88dd7ddd3d02222220dfffdddd0ffcffddf77ccfff0ddddd00366336d300a888000000aa88000000a0080abb8000aaaaaaaaaa8000
00fdd8000fddd880ffdddd86ddd773d802aa2a208d8888880ffcff88777ccfff08dddd003d63366300a88800000aaa8800000000000aa880000aaaaaaaaa0000
000880000ddd8860fdddd886ddd7dd8602222220080888800dfff880d7ffffd000888000366666d30aa88000000aa88000bbb000000aa880000aaaaaaa000000
00000000008886000dd888600dd3d86002aaa252000800800fffff88dffffff008dddd003dd6d6d30a888000000aa88000bbbb00000aa8800000aaaa00000000
00000000000000000088660000838600252222200000000000df88800ddff0000088800003dddd300a880000000aa88000abbbb0000aa8800000aa0000000000
__gff__
8808080801010101010101010000838388888808010101018101010108080808080808080101010101010108888801000808080801018101010101000008000000080808010111111101111100000000000000080101000100011111080808080808080801010101000101000808000008080808010100010001010000080000
0100000000000801010000010100080001000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d500000000d3c0c1c2e2d37170717372737173000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd36c4d6d7c6c513c4c7c0c1e0d2d0d1d2c361604170616160600000000000000000eaeb00000000eeef0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d936d6dbdccfdd361313131313131313d0d1d2e31010e3e360424341434242600000000000000000fafb00ebed00feff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d93613dbdcdfdd361313131313131313e1e151e1e15151e166666666666666660000000000000000fdfaeeedfdedebed0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000012020200202020220202020042727264647060741202020676667661b0b1b1b005c00015e0b5e0b0008001c2020202002020102212121212020202071707171000000006013131320202024000000001717171714f676766667143625253636363614155b4b5b5b001c001c001c001c1e011e011e011e1e1f363636
00000000202021200202020220032003143636154706070641410303767676760008005c005c001c1e0800080008001c02060602e0e0e001222222220202020261706070000000006013131320202024000000001717171714f676767676143636f936f936f914158a9a8a8a001c001c001c001c001c001c001c00003d1f3736
00000000212020200202020220012001143636370606060627262627f6f676761e081e5c0a0b0a0a0a0b5e0b1e0b1e0102393902e0e0e002cf02cf0203cf02ce60636160000000006013131374747424000000001717171714f67676b976143736d914d925d914151e011e1e5b4b5b5b000100011e011e011e011e1e02131f37
00000000424242420202020220202020253636360606060637363636f6f676760008005c0008001c00081c080008001c20202020e0e0e002cececfce2627262663626163000000006013131375757524000000001717171714f6767657b9041536e925e936e93715000000008a9a8a8a001c001c001c001c000000003d1d3d1f
e0e0e0e002e0e002011e1e01131313132424253600000000203d2002000000000223230200000000070707002b2b2b2b1ee0e0e0e0f0f0e0e0e0e0e0001c001c00000000000000000000000000000000202020202020202076767676eaeaeaea21032120363736370000000000000000353434340b1d1d020000000016161616
e0e0e0e020e0e0201ce0e01c202020202424253600000000aaaa2a2a00000000231d213d72723232070607002b2b2b2b30e0e0e0e0f0f0e0e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf767676767a7a7a7a62626262373936360000000000000000073636360823233d00000000172e2e2e
e0e0e0e020e0e0201ce0e01c212020202424253600000000eaea2a2a00000000231d033d424242021b1b1b00212020211ee0e0e0e0f0f0e01e011e1ee0e0e0e00031c32b303130310000310000000000464627260607040476767676424242422627262720013939323232323232323207363636083535340000000039393939
e0e0e0e002e0e002011e1e0102cecfcf24242536000000007a7a3a3a000000000202020261606060001c000003202120001c011c2b2b2b2b00000000e0e0e0e032c3c32b302120303133303132323232767636370406073676767676131313133939393921132120060726270202cf02352e2e351a1b1b1a0000000022222222
1e1dac000000000000000000181819001c1c181818bb1819001c1c00009c0000000000000000000018000000000000000000000000001c00000000001c00001c3c000000221e1d1e1e1d1e00000000000000000000000000000000000000000000000000000000000000000000000000e4456ef9526e4d4543c461506e435f76
00a01c00b0330000ac00000018181900afaf0303122d231200afa0aea29d1eac3aadadacac9b000018000000000000000000000000001c1eacb300001aa2001c9f00000000001c0000ac0000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbb3172d04500467800f8786ef96ee65e41cf79
1e1eac1e1819ac009c32b0001818190000af181818ae181933ac1dbbbb2f001d9e1d00acac000000370000000000000000000033bb221d1a1da00ca230a297a1a30000ac008d2c0000ae00000000000000000000000000000000000000000000000000000000004747472e2e444747d0d06a00f952000052006c00f9005b5f47
0000aca218199dae9e1819ac181881bbbbae0d2012ac1819ac1bac372d8f001cb09c001ca0acadb001000000000000000000003c3c3c3db51bbbbba63c3c9e9d3c0033ad333323b0b3b33a3a0000000000000000000000000000000000000000000000000000007679d95071647676e4d0dc7271524871525b5b5b6171616157
00001cb418199c00001819af181819aeaeae350505af3737ac9c1c0e2c0435a6902635260618180418000000000000000000001f1616bf1a1a1e1e1a1a1a9e9ebfa91d1ab4a23f1ab435b838000000000000000000000000000000000000000000000000000000d8f461416164d87676e44747c6cff4c6cf6160f4c678c6cfd7
30001aa223239c0000a323aea3a3190000001818189e18198809898a3d90b917191818191718181918000000000000000000000000000000003abb3a00000000003c3c3c3c3c873c3c3c3c3f000000000000000000000000000000000000000000000000000000d2f4f8c646d06476797936363636363636c666474747d94747
340000ae1819aeaeac18190018183d9ea200a21f982d3f3f1a1a1a1a3c2a000000169600acae1eac000000000000000000000000000000000038b813000000000036363c3f3f1a1a1a1a00000000456e45455c000000006a000000000000000000000000000000d2c3f4dfd8d057794df4000000af000032103150f400000000
180000001819ac009c1819ae18183cac0033308d3f2e2eae2c0c29bb971e1d1e1d1f961eac1eae9daeaa0000001e00000000000000000000003f1a1e1e00181912000312000000001817be9e9d376e00456a5c5b45455b5b00000000000000000000000000000047f85252d3d261f44d57000000aeaeaeacf68c209700000000
18aeaeb01819a2a29c1819bb18183ca0293d382e2e2c1e1eb83db8b43c001d00378db4bb9c00009c00af00aa00000000000000000000000000003300000090241200a1120000a0ae0117a11d38a6000052525d525a6a5a45000000000000000000000000000000d94152f4f8f8c64644470000000000aeacc7adadf4ac007200
37003b3737370da20c8738b80101a3a3a63c3c3c3c3c3dbbbc3f3f9e9d001b3d8181b41ea01e1eae1eae1d2f0000000000000000000000000000341e1daf8d23123ab4351200af00183c0c1c9fbc455d525b5d6e0000004500000000000000000000000000000000000000000000000000717200007200ac968d689773007872
07474707860f0635b8b80634a6a43c3c3c3c1a1a1a1a1a1a1a001c001c1e1a1a1a1a1a1a1a1a000000001a1a1a1a0000000000000000000000001932afa0ae1a181986871200a01e1817861ba23648005245455b5b00004500000000000000000000000000000000000000000000000000414d5071c1505068cf8f1278715041
26000000001c00001819003231301c00001c00001c00000000001c001c000092202020121c002400000000000000000000000000000000000000192caeae1e2c1819180407350685183c9e9ea03c4400524043525a5c00450000000000000000000000000000000000000000000000000047c6c545474747474747474747c646
2f33002b291c29290419b4348f371cb2301c0000b4b4342900001c001c29bb20200f35359b9b2400000000000000000000000000000000000000192faeaead2f18193c98983c3c3c3c3cad809c97765d5269cf52005c00ca00000000000000000000000000000000000000000000000000000000000000000000000000000000
07070786041b07060d3797363686260407862901b48505b8a9291a001a0185040799961200001a000000000000000000000000000000000000001920313204a018193f3f3f3f3f37371d0ca2ac97760052c5d9525a5a004400000000000000000000000000000000000000000000000000000000000000000000000000000000
36363636991a1736070707073636363636070707070736951786b5b8380799163617043534b53400000000000000000000000000000000000000192020102c2d18193d38212821b6b63f1a1aaf3cd9de5b5279525d5c005700000000000000000000000000000000000000000000000000000000000000000000000000000000
3c3c3f3f3f3f3f3cb6223f3c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001920a038181836363c3f2822283fa2288080ae994d69485200525c5d5b4700000000000000000000000000000000000000000000000000000000000000000000000000000000
b6b6282828b63838b696b681000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003720a020902436360d2e2e282c0d34852eae8505c65b5b45475bcac84a7600000000000000000000000000000000000000000000000000000000000000000000000000000000
3c3c3c3d133c3c3cbda6133c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000634343490243636000000002f2f1a1a80801f360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010900001802018020180701807118061180511804118031180211802118021180211801118011180011800124b0028b002cb0032300200002c0002c0002c0002c0002c0002c0002c0002c0002c0002c00028000
0013800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
010300000c57018570185701857018550185301852018520185100000018570185701855018540185301852018510185001850000000185701855018540185301852018510185101850000000000000000000000
0103001e0c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c10011100
310900001f70020700247002470024700247002470024700187001870018700187001870018700187001870018700187001870018700187001870018700187001870018700187001870018700187001870018700
00108000000000000000000000002a1562a15626166261662c14628166281662a1762a1762a1763010730107301073010730107301072e1762e1762e1662e1762e1762c1762e1762e1762e1662c1662c1662c166
0111800010105101050e174243540a1441833406124029643e06338033320032c87322071180110a00038b072ab2318b050ab2400b6338a332aa132ea032ea622aa5228a4226a1224a2224a1222a1222a1222a12
0002000020333143330c333316201c43327620164332962028613266102d6202c610296102461024610236102261020610206101f6101e6101c6101a6101761014610106100b6100661004610036100061000610
000200000f543085530a5500f570145700d7701476020770277702c7702c7052c7052c7602c700000002c74000000000002c71000000000000000000000000000000000000000000000000000000000000000000
9112002001612006120061201612026120461006611086110c6110961103611046100261201612016100061000610006100061000610026100161000610006100561103611016110361001610026100261001610
50020000123630d643036210d33119331253452930402305003000030000300003000030000300003000030000300000000000000000000000000000000000000000000000000000000000000000000000000000
00020000226432263312920179401b3301633113231101310e1210c1210a121080100703006030040300302003020010200101000000000000000000000000000000000000000000000000000000000000000000
52010000143710d371043610136100350366602535025370366703667036670366503665036650366503665036650366503665536655366453665536665366453663536625366203661036610366003660000000
480200003c6200e3330c22337623296233662325034062202762008220366000322039605012003b6000420008200042000820008200082000820001200366000820036600366000000000000000000000000000
50010000193600d360063500334001440014300363003620036200562009610076100161009600066000260000600066000660005600056000460000000000000000000000000000000000000000000000000000
5a020000183730537301373016700566002660086500f6500165006645056450064004630086300663004630036300762006625056250162503620036200c6100261304613016150160500605086050060408604
0a0200003e6301b6503e630376503c63037650376301c6503963032640386300d630366300263033630016202f620026202d620026202a6100361523615026101e61502615146050260032600326003260032600
020200002436314363093633d6603c6603c6503a6603965037650356402f640336302f630306302d6302f6202f620286202f62024620306101f610306101b6001860030600156001360012600386003860033600
0e0100003e6603e6603d6603d6303b630386302f6302a93025930219301d9301b9301793015920113200f3200d3200c2200a22008220072200621004110041100311003110020100001002000000000000000000
020100003c6703c6602c6602c650209501d950129401c940129401a93010930189300e930159300b92010920089200c9200592008920059200492003910039100091000910009100a10000000000000000000000
4002000031630112202b6101123024620112201d620112201f620112301e6301122025620112202a620112202c61011210296101121026610112102261011200236001120022600112001d600112001a60012200
0a0100001276016770197701b76022760257602875000000000002c6702c6702c6402c640000003b6703b6703b6403b6353b6303b6203b6203b62500000000001370017700187001c70000000000000000000000
080200001b63314651186411d610156632a750227701b760167500f7400a730087200572004710037100300000601000030060400600006010300004700037000070000700000000000000000000000000000000
020100003d6603d6603d6502c64026640266401e6001e6003a6503a6403a6303a630010000d230082300820008220012000821019700197001a7001e700217001a70000700007000000000000000000000000000
31240020270151ba001e0151e810030141e0100a010160150f115000001e0151e810120151e0150d0140d01427015000001e0151e810030141e0150a0150d0151e01503000200152081003000200152501422010
3148000003114031101b810081140311403110120151b81003114031101b810081140311403110120151e810031141ba101b0150f810031141ba101b0150f81006114061101ba1012810081140811022a1016810
834800001612522b34121251eb3408124081200a1211e0250412520b240612522b240612406120081211402422a20128201aa20098203572508124297250e02521a201282022a200b8201db351612420b350c924
316c0020031001e8000d1000f0000a100031001e0000d10003100031001b00003100031001b0000d00012000031001e1000d1000310020100031001e1000d1002200003000030000300024000060001b00008000
5d1200200f420124200d4200f42014420034100f42016420034100d4250d420034100d420034100e420034100f420124200a4200f42014420034100f42016420014100d4250d4200d4230d420014100e42303420
511200200f023000002e610000000f123000002e610000000f32303210276100f2100f3130000027610000000f4131d40027610115000f2231d81227610072200f323032202e6102e6150f3331e8152e61020815
a31200001b6251b625366200c6210c62136610366113662113615366152d6202d611366253662536625366251b6251b625366101b6250c62136615366103662013615366152d6153061136625366253662536625
011200001710020100231002010017100241001b100231002310023100171002010023100241001710020100231002710017100201002310028100171001b1001710027100231002710017100271002310027100
0d12002006020030100f0200f0110f0010f0100f0010f010030100d0220d0220d01212020120110f0200f01103010030100f0100f0010f0100f0100f0010f010030120d0220d0220d01212022120120f0200f011
0d1200200d0200d01101020010100f0100f0100101501020000100c0220c0220c01012020120200f0200f01001020010100102001020120200f0200102012020010200f020010230102016020150241502514020
531200202e6150f515316151b0153c6152701531615316150d000376150d0000a615316151b5253a6153a6153a6103a6153a6103a61537615186153161531615123133a615120151b01537615376151b0153a615
011200201b5250f0151b5260f1251b1250f0151b1000f1160f5001b1250f5001b125191200f5001a1200f5200f5001b1250f5061b5160f5201b1250f0001b1250f5251b1250f5261b1251e1201b5251b1201b125
011200201b1151b1101b0000d1250d1101b1120d0250d0151b1151b1150c0251b1151e1101e015201101b0151b1251e1100f5170c020275162011220112221151b010201151b0160d0201e1101b115191101a110
092400200f01503510035200f0100f8100f8210f0150f0150f0150f01003520035100f8100f821030150f01501514015200d510015200d8100d821120150d0150a0140a0100a0100a01012810140150d01012015
394800000f5100f5210f5110f5150f5120f5210f5110f5110d5210d5210d5220d522165221652212522145210f5200f5210f5110f5120d5210d5220d5220d5220c5210c5210c5200c5220b520170120d5220a522
011200200f5150f51027b250f51027b250f5100f515277250f51027b250f5100f5151b1150f51027b2527b252eb251b5100f5100f515277100f51027b25277100f51027b250f5100f51512525125001b5151b525
112400201b7251b8201b7251b8201b7251981020725227251e7251b8201b7251b8201b7251b820197251e7251b725198101b725198201b725178201b725197252272522725217252172520725207251e72519725
9d1200000d4100e4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d410
631200001b4251b425194251b420366101e420336211b4200f420164203361619420386121a42036625366101b4251b325193251b426366101e420366161b4200f32016420366111942038610224203861538615
5112000018220184200c2210c4211f42012200122001d2201d220225351d220225352253520535205352053516220184200c2211b4211f4201220012200112201122013055112201305516055180551305518055
11120000165301652114530145211253514531145210f53511500115000f5330f5350f5350f535085350a535165301652114531145211253514530145210e535005000f5350f5350f5320f5120f535125350f535
851200200113520112201000d135201102011301125011250113020112181000d13520115201100112520110231112311104135221102211106116221100413522110221101b100061351e110201112011020110
87120020201101b1110a100041351b1101b11104135270210412527021081000d1351b1101b1210d1351b120211112111106145221102211106135221102211022110221100d100081350f110151111b11021110
69240020149151b9151e9151b915099150d9151291514915149151c9151e91522915209150d91512915149150d915199151b91519915159151c9151c9151d9151e91504915049150491512915069151291521915
6b090020149230802008011080152a6152a60036600149133c6103c613080100801536615081140811008020149230310003100089133c6100802514914089133c6003c60009100149152a625090100911009115
692400200f1251052512525141250f1251052512525141251952519525198300d82015525155251c84427b200d1251152512525141250d1251152512525141250a1250a5250e5250e1251212512525145250c134
791000000a2100a2100321003210032150321003410034100d2100d2100321003410033150321003412034120621006210034100341003215032100a2110a2120841008410033100331003212032100341203410
48100000143261b3160f3201b326143101b3100f3201b3160f3201b3100f3261b3160f32011310123200d3200f3200f3101632016316163200f3160f310143200f3261401014326143100f3101b3201232011320
481000000f326123160f320123260f3101b3100f3200f3100f326143100f320143261b3100f3100f320113201d3260f3201d3260f3201d3260f3201d3260f3201e3260f4201e3260f4201e3260f4201e3260f420
5910000020326273161b3202732620316273101b320273161b326273161b326273161b3100b3201e3101d3201b3251b32522320223161d3200f3301b32020320200200d33020320203201b310273201e3201d320
591000001b3261e3161b3201e3261b310273101b3201b3101b326203101b32020326273101b3101b3201d3202932612320293261e320293261e320293261e3202a326143202a326203202a326203202a32620320
311000000a1100a1100a1100a1100a1100a1100a1210a1200a120031200392003120039230392303920039200692000120069200c1200c1200c1200c1200c1200492003120049200392003923039230f1230f120
311000000b1100b1100b1100b1100b1100b1100b1120b1220492004110049100422203913039130392203922069200312006920031200d1220d1220d1220d1220f9200f1200f9220f92212122121221212212122
7910002003320034100332003210032100322003415034150332003410033200321003210032100391003910064200f4100642003210032100321003215032150432012d20043200621006210063100631006310
79100000049200b420049200321003221032110341003410043200b410043200321203222032120340003400064200f9200642003220032210322103211032100732012d200732006d200621012d200631006321
0120000022025220141601027015250250d0241901025015240250c024180100c010230252301417010019142202522014160100a0101e0251e0140601012010200252001408010080101c0250b9141c0100d914
4b1000201d3233500015313214133e6201d621153133e6101531300300214132d600214130f3243c6250f322153230030039625213133e6101d621396253e6102131300300214231532338620386243862538620
812400202cb34149151412514915149150891514125149151791533b3417915179151791517915179151791519915119151191511915119151191510915119151e91504915049150491512915069151291515915
011000002200022000160000a0000a0000a00016000160001e0001e0001e000060000600006000120001200020000200002000008000080000800014000140001c0001c000040000400004000040000400004000
011000000fc550fc550fc550fc551ec551bc551bc551bc550fc550fc550fc550fc5520c551bc551bc551bc5500000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
01 1f19181f
00 19181f1f
00 1f19181f
00 1f191827
00 1918271f
02 1f191827
03 09626249
01 201f2368
00 211f2363
00 20222367
00 21222464
00 25222763
00 25272263
00 20272263
00 21272263
00 20262249
00 20222849
00 21222849
00 09222349
00 09222349
00 1f222749
02 1f271f49
00 60625d63
01 1e091f49
00 1e091949
00 1e092549
02 1e251f5f
01 1e5d2909
00 1e5d091c
00 1e5d291d
00 1e5d291c
00 255d2a1d
00 25592a1d
00 2b5d291d
00 295d2c1d
00 1e5e291d
02 1e5d1d2c
00 41424344
01 1a71707d
01 1a317070
00 6f71301f
00 6f71301f
00 1a313070
00 2d307d71
00 2e307d71
00 2d303d31
02 1a71306f
01 323c1f79
00 323c1f39
00 3b3c1f39
00 373c331f
00 383c341f
00 393c351f
02 3a3c361f
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344

