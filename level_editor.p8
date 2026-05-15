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
	
	w_text = "select a level to edit"
	s_text = ""
	s_col = 7
	
	_draw = _draw_m_menu
	_update = _update_m_menu
	--pal(split"1,129,3,130,2,0,7,136,8,9,10,12,13,14,15,131",1)
	
	x_off,y_off,mm_scale,skip_borders = 0,0,4,false
	menuitem(2,"view map", view_map)
	menuitem(3,"compress extras", compress_extras)
end

function compress_extras()

	output_string = 'ntt_extrainfos=split("'
	local splitter = "⬅️"
	
	local invalid_first = -1
	for i=1, #ntt_extrainfos_pre do
		output_string ..= ntt_extrainfos_pre[i]
		
		if #(split(ntt_extrainfos_pre[i],"/")) != 2 and invalid_first == -1 then
			invalid_first = i
		end
		
		if i != #ntt_extrainfos_pre then
			output_string ..= splitter
		end
	end

	output_string ..= '","'.. splitter ..'")\n'
	
	printh(output_string, "@clip")
	
	if invalid_first == -1 then
		w_text = "extras copied to clip!"
	else
		w_text = "\f8invalid element " .. invalid_first .. "!"
	end
		
end

function view_map()
	_update,_draw=_update_mapview
	menuitem(2,"back to menu", quit_map)
	menuitem(3)
	draw_map_miniview()
end

function quit_map()
	_update,_draw = _update_m_menu,_draw_m_menu
	menuitem(2,"view map", view_map)
	menuitem(3,"compress extras", compress_extras)
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
			local lvl_info = split(lvls_info_2[i],"`")

			local map_pos_x = lvl_info[6]*mm_scale
			local map_pos_y = lvl_info[7]*mm_scale
			local ld_l_size_x = lvl_info[8]*mm_scale
			local ld_l_size_y = lvl_info[9]*mm_scale
			
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

function _draw_m_menu()
	cls(0)
	
	local s = 14
	
	cam_y = cursor_pos*s-20
	camera(cam_x, cam_y)
	
	-- have to temporarily switch maps for tline
	poke(0x5f56,0x20)
	
	local level_num = 1
	for i=1, #lvls_info_2 do
		local lvl_info = split(lvls_info_2[i],"`")
	
		local yval = i*s + 12
	
		local l_txt_col = 7
		if cursor_pos == i then
			l_txt_col = 12
			rect(1, yval - s\2, 127, yval + s\2,l_txt_col)
		end


		local pal_transp_col = lvl_info[13]
		
		-- col
		rectfill(2, yval - s\2+1, 126, yval + s\2-1,pal_transp_col)
		rect(2, yval - s\2+1, 126, yval + s\2-1,l_txt_col)
		

		
		-- bg sample
		for	j=0, s-4 do
			bg1_loc = peek(lvl_info[14])
			bg2_loc = peek(lvl_info[15]) -- is also the location as its the first byte
		
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, bg1_loc*8, j/8+1, 1/8, 0)
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, bg2_loc*8, j/8+1, 1/8, 0)
		end
		
	
		print_outl("level " .. i, 4,yval-2,l_txt_col,1)
		level_num = i
		
	end
	
	poke(0x5f56,0x80)

	
	rectfill(cam_x,cam_y,cam_x+128,cam_y+8,0)
	line(cam_x+2,cam_y+8,cam_x+126,cam_y+8,1)
	?w_text,1,cam_y+1,7
	?s_text,1,cam_y+9,s_col
	
end

function _update_m_menu()
	if btnp(2) then
		cursor_pos -= 1
		s_col = 7
		w_text = "select a level to edit"
	end
	if btnp(3) then
		cursor_pos += 1
		s_col = 7
		w_text = "select a level to edit"
	end
	cursor_pos = ((cursor_pos-1)%#lvls_info_2)+1
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

function mod_tabl(tab, kv, splitter)
	local k,v = unpack(split(kv, splitter or "/"))
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
	cls(loaded_level_info[13])
	camera(cam_x,cam_y)
	camera_x,camera_y = cam_x,cam_y
	
	draw_loaded_bg()
	
	-- draw grid 
	if mous_prev&0b10 == 0 or show_ntt_details then
		for i=1, ld_l_size_x do
			line(i*8*4, 0, i*8*4, ld_l_size_y*32,1)
		end
		for i=1, ld_l_size_y do
			line(0, i*8*4 ,ld_l_size_x*32, i*8*4,  1)
		end
	end
	
	map(unstr"0,0,0,0,128,64,0b1000")
	map(0,0)
	
	
	if (mous_prev&0b10 == 0 or show_ntt_details) then
		if not ntt_draggable and not show_ntt_details then
			rect(l_curs_x*32, l_curs_y*32,l_curs_x*32+32, l_curs_y*32+32, l_c_col)
		end
	end
	
	if (mous_prev&0b10 == 0) draw_extras()
	draw_entities()
	
	poke(0x5f5e, 0b01110111)
	rectfill(-256,sludg_l,512,1024,sl_c)
	poke(0x5f5e, 0b11111111)
	
	
	if (mous_prev&0b10 == 0) draw_sidebar()
	
	
	if (mous_prev&0b10 == 0) print_outl(w_text,cam_x+1,cam_y+1,7,4)
	print_outl(s_text,cam_x,cam_y+121,7,9)
	
	if show_ntt_details then
		local type_c = 7
		if (ntt_editing_type == 0) type_c = 12
		local entity = lvl_entities[ntt_in_drag]
		print_outl("n. " .. ntt_in_drag,cam_x+80,cam_y+2,type_c,9)
		type_c = 7
		if (ntt_editing_type == 1) type_c = 12
		print_outl("e type:" .. entity.template,cam_x+80,cam_y+9,type_c,9)
		
		print_outl("pos:\n x:" .. entity.pos.x .. " (" .. entity.pos.x\4+8 .. ")\n y:"  .. entity.pos.y .. " (" .. entity.pos.y\4+8 .. ")" ,cam_x+80,cam_y+16,7,9)

		camera(-70,0)
		type_c = 7
		if (ntt_editing_type == 2) type_c = 12
		print("\^o95aextras (" .. entity.extrainfo_loc .. "):\n\^rf" .. ntt_extrainfos[entity.extrainfo_loc],10,35,type_c,9)
		camera(camera_x,camera_y)
	end
	
	draw_cursor()
	
--stat(34) -- mouse buttons (bitfield))
	
end

function draw_entity(entity,pos,flip_x,flip_y)
	pos,flip_x,flip_y,e_spr,s_x,s_y = pos or entity.pos,flip_x or entity.is_left, flip_y or entity.is_up,entity.sprite,entity.spr_width or 1,entity.spr_height or 1
	if e_spr then
		local spr_sw,spr_sh = s_x*entity.spr_size, s_y*entity.spr_size
		--e_spr += ((anim_c\(entity.framedur or 2))%(entity.numframes or 1))*s_x
		
		sspr(e_spr%16*8,e_spr\16*8,s_x*8,s_y*8,pos.x-spr_sw/2,pos.y-spr_sh/2,spr_sw,spr_sh,flip_x,flip_y)
	end
end

function draw_decal(entity)
	print(entity.decal,entity.pos.x,entity.pos.y)
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

	local p1,p2,l=from.pos,to,from.is_left


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
	
	local pl_x,pl_y = loaded_level_info[3], loaded_level_info[4]
	
	print("pl" ,pl_x, pl_y-8, 12)
	
	rect(pl_x-2,pl_y-2,pl_x+2,pl_y+2,12)
	

	
	-- todo decal rework
	--[[for i=1, #(loaded_level_signs or {}), 3 do
		local x,y,text = unpack(loaded_level_signs,i)
		text_box(text,false,x,y)
	end]]--


end

function draw_entities()

	for i=1, 4 do
	
		if i==3 then
			-- solid map
			map(unstr"0,0,0,0,128,64,0b00000111")
		end
		
		for j=1, #lvl_entities do
			local entity = lvl_entities[j]
			local ex,ey,ntt_rad = entity.pos.x, entity.pos.y, entity.rds
			if (entity.d_o or 3) == i then
				
				if entity.rope then
				
					-- works slightly differently, assumes is to ground
					local link=mod_tabl2(
					{},"from,to,l_type,len,strenght,draw_type,col,is_front,width",
					{entity, entity.pos + vec2_new(entity.rX,entity.rY),unpack(split(links[entity.rope]))})
					link.true_len=link.len

					draw_link(link)
					
				end
				
				draw_entity(entity)
				if (entity.decal) draw_decal(entity)
				
			end
			
			if i==4 then
				if (mous_x>(ex-ntt_rad) and mous_x<(ex+ntt_rad)) and (mous_y>(ey-ntt_rad) and mous_y<(ey+ntt_rad)) then
					rect(ex-ntt_rad, ey-ntt_rad, ex+ntt_rad-1, ey+ntt_rad-1,3)
					
					rect(-8*4,-8*4,(255-8)*4,(255-8)*4,3)
					
					s_text = j .. ". e:" .. entity.template .. " x:"..entity.pos.x .." y:".. entity.pos.y .. " x:" .. entity.extrainfo_loc
					
					if entity.text_box then
						text_box(unpack(split(entity.text_box,"⬇️")))
					end
					
				end
			end
		
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
	
	local add_col,add_fill,icon = 8,12,"\^:0008083e08080000"
	if (mouse_on_ntt_add) then
		add_col,add_fill = 7,12
		local x_off = 114
		if (#lvl_entities >= 10) x_off -= 4
		if (lvl_ntt_limit >= 10) x_off -= 4
		print_outl(#lvl_entities .."/"..lvl_ntt_limit, cam_x+x_off,cam_y+10,7,4,8)
	end
	if (#lvl_entities >= lvl_ntt_limit) add_col,add_fill,icon = 15,13,"\^:4028183e0c0a0100"
	if show_ntt_details then
		add_col,add_fill,icon = 8,10,"\^:0022140814220000"
		if (mouse_on_ntt_add) add_col,add_fill = 7,11
	end
	rectfill(cam_x+119,cam_y+8,cam_x+127,cam_y,add_fill)
	rect(cam_x+119,cam_y+8,cam_x+127,cam_y,add_col)
	print(icon, cam_x+120,cam_y+1,add_col)
end



mouse_on_sidebar = false
mouse_on_ntt_add = false
mouse_on_canvas = false

mouse_ready = false

show_ntt_details = false
ntt_editing_type = 1

function _update_l_editor()
	time_c+=0.0333333
	
	mous_x, mous_y = stat(32)+cam_x,stat(33)+cam_y
	l_curs_x = mous_x\32
	l_curs_y = mous_y\32
	s_text = "x:"..l_curs_x.." y:"..l_curs_y
	
	sludg_l += sl_r + sin(time_c/sl_spd)*sl_h

	local should_reload = false

	mouse_on_sidebar = mous_x >= cam_x+90 and mous_y >= cam_y+74 
	mouse_on_ntt_add = mous_x >= cam_x+120 and mous_y < cam_y+8 
	mouse_on_canvas = not mouse_on_sidebar and not mouse_on_ntt_add



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

	if ntt_dragged then
		local entity = lvl_entities[ntt_in_drag]
		
		entity.pos.x=mous_x\4*4
		entity.pos.y=mous_y\4*4
		
		entity.pos.x = mid((0-8)*4,entity.pos.x, (255-8)*4)
		entity.pos.y = mid((0-8)*4,entity.pos.y, (255-8)*4)
	end
	
	ntt_dragged,ntt_draggable = false,false
	
	
	if mouse_on_canvas then

		for i=1, #lvl_entities do
			local entity = lvl_entities[i]
			local ex,ey,ntt_rad = entity.pos.x, entity.pos.y, entity.rds

			-- since they snap to grid, it's hard to move ntts with small rad
			ntt_rad2 = max(ntt_rad,5)
			
			if (mous_x>(ex-ntt_rad2) and mous_x<(ex+ntt_rad2)) and (mous_y>(ey-ntt_rad2) and mous_y<(ey+ntt_rad2)) then
				ntt_draggable = true
				if (not show_ntt_details or ((mous_p&0b10) != 0) and ((mous_prev&0b10) == 0)) then
					if (ntt_in_drag != i) ntt_editing_type = 0
					ntt_in_drag = i
				end
				if mous_prim==1 then
					ntt_dragged = true
					break
				end
			end

		end

		if not ntt_dragged and not show_ntt_details then
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
				w_text = "editing level " .. cursor_pos
			end
		end
	end
	
	if ntt_draggable and ((mous_p&0b10) != 0) and ((mous_prev&0b10) == 0) then
		if not show_ntt_details then
			ntt_editing_type = 1
		else
			ntt_editing_type += 1
			ntt_editing_type %= 3
		end
		show_ntt_details = true
	end
	
	if (not ntt_draggable) and (mous_p != 0) and (mous_prev == 0) and mouse_on_canvas then
		show_ntt_details = false
	end
	
	if show_ntt_details then
	
		if btnp(4) or btnp(5) then
			local entity = lvl_entities[ntt_in_drag]
			local e_type,ex,ey,e_extra = entity.template, entity.pos.x, entity.pos.y, entity.extrainfo_loc
			
			
			if ntt_editing_type == 0 then
				if btnp(4) then
					if ntt_in_drag < #lvl_entities then
						-- swap
						lvl_entities[ntt_in_drag] = lvl_entities[ntt_in_drag+1]
						lvl_entities[ntt_in_drag+1] = entity
						ntt_in_drag += 1
					end

				end
				
				if btnp(5) then
					if ntt_in_drag > 1 then
						lvl_entities[ntt_in_drag] = lvl_entities[ntt_in_drag-1]
						lvl_entities[ntt_in_drag-1] = entity
						ntt_in_drag -= 1
					end

				end
			
			elseif ntt_editing_type == 1 then
				if btnp(4) then
					e_type += 1
					e_type = ((e_type-1)%#ntt_types)+1
				end
				
				if btnp(5) then
					e_type -= 1
					e_type = ((e_type-1)%#ntt_types)+1
				end
				
			else
				if btnp(4) then
					e_extra += 1
					e_extra = ((e_extra-1)%#ntt_extrainfos)+1
				end
				
				if btnp(5) then
					e_extra -= 1
					e_extra = ((e_extra-1)%#ntt_extrainfos)+1
				end
			end
			
			
			if ntt_editing_type != 0 then
				-- reload entity
				entity = create_entity(e_type,ex,ey,e_extra)
				lvl_entities[ntt_in_drag] = entity
			end
		end
	
	end
	
	if mouse_on_ntt_add then
	
		if ((mous_p&0b1) != 0) and ((mous_prev&0b1) == 0) then
			
			if (show_ntt_details) then
				-- remove
				show_ntt_details = false
				deli(lvl_entities,ntt_in_drag)
				loaded_level_info[17]=#lvl_entities
			else
				if (#lvl_entities < lvl_ntt_limit) then
					-- add
					local e_type,ex,ey,e_extra = 4,cam_x+64,cam_y+64,1
					local entity = create_entity(e_type,ex,ey,e_extra)
					
					add(lvl_entities,entity)
					loaded_level_info[17]=#lvl_entities
				end
			
			
			end
		end
		
	
	end
	
	
	mous_prev = mous_p
end

function reload_bg1()
	lvl_bg1 = {peek(loaded_level_info[14],10)}
	
	for i=1, 10 do
		lvl_bg1[i] = lvl_bg1[i]-128
	end
	
	lvl_bg1[7] = min(lvl_bg1[7],1) -- limit wrap to prevent lag
	lvl_bg1[8] = min(lvl_bg1[8],1)
	
	local valid,index = find_in_arr(loaded_level_info[14],bg_slots)
	if (valid) then
		bg_slot_index1 = index
	else
		bg_slot_index1 = 1
	end
	bg1_edited = false
end

function reload_bg2()
	lvl_bg2 = {peek(loaded_level_info[15],10)}
	for i=1, 10 do
		lvl_bg2[i] = lvl_bg2[i]-128
	end
	
	lvl_bg2[7] = mid(0,lvl_bg2[7],1) -- limit wrap to prevent lag
	lvl_bg2[8] = mid(0,lvl_bg2[8],1)
	
	local valid,index = find_in_arr(loaded_level_info[15],bg_slots)
	if (valid) then
		bg_slot_index2 = index
	else
		bg_slot_index2 = 1
	end
	bg2_edited = false
end


function create_entity(e_type,ex,ey,e_extra)

	local pr = split(ntt_types[e_type], "|")
	local props_c,props_e = pr[1], pr[2]
	
	local entity = mod_tabl2({},"pos,template,extrainfo_loc",{vec2_new(ex, ey), e_type,e_extra})
	
	mod_tabl(entity,"xtra_src,rds,mass,sprite/" .. props_c)
	
	-- some defaults
	mod_tabl(entity, "is_left,coll_rng,actN,actF,rngN,rngF,Iarm,Irss,spr_size,d_o,outl/false,0,55,100,0,35,0,1,8,3,0")

	if (entity.xtra_src != 0) mod_tabl(entity,split(ntt_types[entity.xtra_src], "|")[2])
	-- props
	mod_tabl(entity,props_e)
	
	
	extraprops = ntt_extrainfos[e_extra]
	mod_tabl(entity,extraprops)
	
	return entity

end

lvl_ntt_limit = 0

function load_level(index)
	
	loaded_level_info = split(lvls_info_2[index],"`")
	
	-- keep these global for saving
	map_pos_x = loaded_level_info[6]
	map_pos_y = loaded_level_info[7]
	ld_l_size_x = loaded_level_info[8]
	ld_l_size_y = loaded_level_info[9]
	
	reload_bg1()
	reload_bg2()
	
	lvl_entities = {}
	
	local num_e = 0
	for i=1, loaded_level_info[17] do
		ntt_mempos = loaded_level_info[16] + (i-1)*4
		local e_type,ex,ey,e_extra = peek(ntt_mempos,4)
		if e_type == 0 then
			local mx,my = (ntt_mempos-4096)%128, ((ntt_mempos-4096)\128)+32
			stop("\^o0ff\f7entity slot ".. i .." (" .. ntt_mempos .. ",x:" .. mx .. " y:" .. my ..")\nis empty!\nplease correct map/level data")
		end
		
		
		ex = (ex-8)*4 
		ey = (ey-8)*4
		
		entity = create_entity(e_type,ex,ey,e_extra)
		
		add(lvl_entities, entity)
		num_e = i
	end
	lvl_ntt_limit = num_e
	
	-- hard limit of 16
	for i=num_e+1, 16 do
		ntt_mempos = loaded_level_info[16] + (i-1)*4
		local e_type,ex,ey,e_extra = peek(ntt_mempos,4)
		if e_type != 0 then
			break
		end
		lvl_ntt_limit = i
	end
	
	
	lvl_tiles={}
	for j=0, ld_l_size_y-1 do
		for i=0, ld_l_size_x-1 do
		 add(lvl_tiles, mget0x20(map_pos_x+i,map_pos_y+j))
		end
	end

	mset_level()

	pal(unpack_pal(loaded_level_info[12]), 1)
	
	-- defaults
	mod_tabl(_ENV,"time_c,t_enms,t_e_clear,t_tr_collected,t_trinkets,lvl_prevmus/0,0,0,0,0,0,0")
	mod_tabl(_ENV,"lvl_enms,lvl_e_clear,lvl_e_req,x_u_l,y_u_l,trn_bnc,trn_slp,grav,lvl_tr_collected,lvl_trinkets,sludg_l,sl_c,sl_smth,sl_vx,sl_vy,sl_dmg,alert,l_time_c,sl_r,sl_h,sl_spd/0,0,0,0,0,0.2,0.75,0.22,0,0,512,6,0.9,0,-0.16,0.6,false,0,0,0.04,5")
	
	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1
	x_l_l=l_border_x-127
	y_l_l=l_border_y-127
	
	-- lvl extra globals and defaults
	mod_tabl(_ENV,loaded_level_info[5])
	
	
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
	
	-- output settings to clipboard
	lvl_string = ""
	for i=1, #loaded_level_info do
		local dat = loaded_level_info[i]
		if (i!=1) lvl_string ..= "`"
		lvl_string ..= dat
	end
	
	printh(lvl_string .."\n", "@clip")
	
	-- geometry tiles
	
	-- do NOT take new level values for pos and size to not break stuff
	
	for i=0, ld_l_size_x*ld_l_size_y-1 do
		mset0x20(map_pos_x + i%ld_l_size_x, map_pos_y+i\ld_l_size_x, lvl_tiles[i+1])
	end

	
	-- backgrounds
	for i=0, 9 do
		val = lvl_bg1[i+1]
		val += 128
		poke(loaded_level_info[14] + i,val)
	
		val = lvl_bg2[i+1]
		val += 128
		poke(loaded_level_info[15] + i,val)
	end
	
	bg1_edited,bg2_edited = false, false
	
	-- entity info
	for i=1, loaded_level_info[17] do
		local entity = lvl_entities[i]
		local e_t,e_x,e_y,e_ex = entity.template, entity.pos.x,entity.pos.y,entity.extrainfo_loc
		e_x = e_x\4+8
		e_y = e_y\4+8
		
		local ntt_mempos = loaded_level_info[16] + (i-1)*4
		poke(ntt_mempos,e_t,e_x,e_y,e_ex)
	end

	for i=loaded_level_info[17]+1, lvl_ntt_limit do
		local ntt_mempos = loaded_level_info[16] + (i-1)*4
		poke(ntt_mempos,0,0,0,0)
	end
	
	cstore(0x1000,0x1000,0x2000)
	
	w_text = "saved! header is in clipboard"
	return false
end

l_set_cursor_pos = 1

function edit_l_settings()
		menuitem(2 | 0x300, "back to editor",
		unedit_l_settings)
		
	l_set_cursor_pos = 2
	r_col = 12
	l_set_list_cam = 1
	
	camera_x = 0
	camera_y = 0
	
	
	
	_update = _update_l_settings
 _draw = _draw_l_settings

end

function in_tbl(element, table)
	for key, value in pairs(table) do
		if (value == element) return true
	end
	return false
end

function find_in_arr(element, arr)
	for i=1, #arr do
		if (arr[i] == element) return true, i
	end
	return false
end


-- these plus the 3 slots lower than them on the map
bg_slots_pre = split"4184,4696,4194,4706,4204,4716,4214,4726,8300,8310"
bg_slots = {}
bg_slot_index1 = 1
bg_slot_index2 = 1
for i=1, #bg_slots_pre do
	add(bg_slots,bg_slots_pre[i])
	add(bg_slots,bg_slots_pre[i]+128)
	add(bg_slots,bg_slots_pre[i]+128*2)
	add(bg_slots,bg_slots_pre[i]+128*3)
end
bg1_edited = false
bg2_edited = false

function _update_l_settings()
	time_c+=0.0333333
	mous_x, mous_y = stat(32),stat(33)+l_set_list_cam*8-8
	
	local uneditable = split"1,5,17"
	
	if btnp(2) then
		l_set_cursor_pos -= 1
		if (l_set_list_cam - l_set_cursor_pos > 1) l_set_list_cam -= 1
	end
	if btnp(3) then
		l_set_cursor_pos += 1
		if (l_set_cursor_pos - l_set_list_cam > 10) l_set_list_cam += 1
	end
	
	if btnp(2) or btnp(3) then
		if l_set_cursor_pos == 10 or l_set_cursor_pos == 11 then
			update_mus()
			if (not stat(57)) music(loaded_level_info[10], 1000)
		else
			music(-1)
		end
		
	end
	
	l_set_cursor_pos = mid(1,l_set_cursor_pos,#desc_strings)
	if in_tbl(l_set_cursor_pos, uneditable) then
		r_col = 15
	else
		r_col = 12
	end
	
	
	l_add=0
	if btnp(4) then
		l_add=1
	end
	if btnp(5) then
		l_add=-1
	end
	
	if (btnp(4) or btnp(5)) and not in_tbl(l_set_cursor_pos, uneditable) then
	
		-- regular settings
		if l_set_cursor_pos < 18 then
		
			if l_set_cursor_pos == 14 or l_set_cursor_pos == 15 then
				local valid,index = find_in_arr(loaded_level_info[l_set_cursor_pos],bg_slots)
				if valid then
					index = ((index + l_add - 1) % #bg_slots) + 1
				else
					index = 1
				end
				loaded_level_info[l_set_cursor_pos] = bg_slots[index]
				if l_set_cursor_pos == 14 then
					bg_slot_index1 = index
				else
					bg_slot_index2 = index
				end
			elseif l_set_cursor_pos == 16 then
				loaded_level_info[l_set_cursor_pos] += l_add*4
			else
			
				loaded_level_info[l_set_cursor_pos] += l_add
			
			end

			if l_set_cursor_pos == 10 or l_set_cursor_pos == 11 then
				update_mus()
				if (not stat(57) or l_set_cursor_pos == 10) music(loaded_level_info[10], 1000)
			elseif l_set_cursor_pos == 12 then
				pal(unpack_pal(loaded_level_info[12]), 1)
			end
		else
		
		end
		
		
		if l_set_cursor_pos == 14 then
			reload_bg1()
			time_c = 0
		end
		
		if l_set_cursor_pos == 15 then
			reload_bg2()
			time_c = 0
		end
		
		-- background settings 
		if l_set_cursor_pos >= 18 then
			time_c = 0
			if l_set_cursor_pos >= 28 then
				lvl_bg2[l_set_cursor_pos-27] += l_add
				lvl_bg2[l_set_cursor_pos-27] = ((lvl_bg2[l_set_cursor_pos-27] + 128) % 256) - 128
				bg2_edited = true
			else 
				lvl_bg1[l_set_cursor_pos-17] += l_add
				lvl_bg1[l_set_cursor_pos-17] = ((lvl_bg1[l_set_cursor_pos-17] + 128) % 256) - 128
				bg1_edited = true
			end
			lvl_bg1[7] = mid(0,lvl_bg1[7],1) -- keep limiting wrap stuff
			lvl_bg1[8] = mid(0,lvl_bg1[8],1)
			lvl_bg2[7] = mid(0,lvl_bg2[7],1)
			lvl_bg2[8] = mid(0,lvl_bg2[8],1)
		end
			
	end
	
end

function draw_bg(arr) 
	mod_tabl2(_ENV,"b_img_indx,b_pal,b_sc,b_prlx,b_ofx,b_ofy,b_wx,b_wy,b_timx,b_timy",arr)

	pal(unpack_pal(b_pal+16), 0)
	
	local p_sc = b_sc*8
	local a_p_sc = abs(p_sc)
	local scrl,ts_x,ts_y = b_prlx/64, b_timx,b_timy
	local wrap_x,wrap_y = b_wx==1, b_wy==1
	
	local scroll_x,scroll_y = -b_ofx+camera_x*scrl+time_c*ts_x, -b_ofy+camera_y*scrl+time_c*ts_y
	
	if(wrap_x) scroll_x %=8*a_p_sc
	if(wrap_y) scroll_y %=4*a_p_sc

	local function map_scaled(ox,oy)
		for	i=0,7 do
			for	j=0,3 do
				local n = mget0x20(b_img_indx*8+i, j)
				if (n != 0) sspr((n&0b1111)*8,n\16*8,8,8, camera_x-scroll_x+i*p_sc+ox, camera_y-scroll_y+j*p_sc+oy,p_sc,p_sc)
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

	draw_bg(lvl_bg1)
	draw_bg(lvl_bg2)

end

desc_strings={
"title: ",
"next level: ",
"player x: ",
"player y: ",
"global vars: ",

"map x: ",
"map y: ",
"x size: ",
"y size: ",
"music index: ",
"music layers: ",
"main palette: ",
"clear color: ",

"bg 1 (back) : ",
"bg 2 (front): ",
"entity array: ",
"num entities: ",

"bg 1 image: ",
"1 palette: ",
"1 scale: ",
"1 parallax: ",
"1 x offset: ",
"1 y offset: ",
"1 x wrap: ",
"1 y wrap: ",
"1 x timescroll: ",
"1 y timescroll: ",

"bg 2 image: ",
"2 palette: ",
"2 scale: ",
"2 parallax : ",
"2 x offset: ",
"2 y offset: ",
"2 x wrap: ",
"2 y wrap: ",
"2 x timescroll: ",
"2 y timescroll: "
}



function _draw_l_settings()
	cls(loaded_level_info[13])

	camera_y = l_set_list_cam*8-8
	camera(0, camera_y)
	
	draw_loaded_bg()


	rectfill(0,l_set_cursor_pos*8+6,128,l_set_cursor_pos*8+14,r_col)
	
	print_outl("level " .. cursor_pos .. " settings",0,0,7,6)
	
	if l_set_cursor_pos > 5 and l_set_cursor_pos <= 9 then
		print_outl("only applied\nafter restart!",64,64,3,6)
	end
	
	if l_set_cursor_pos == 16 then
		print_outl("only edit if\nyou know what\nyou're doing!",75,136,3,6)
	end


	
	-- non bg settings are stored in string
	for i=1, 17 do
		local dat_str=loaded_level_info[i]
		p_col =7
		if i==11 then
			-- NOTE: Layers are displayed in reverse binary to correspond to the channels, but are stored normally
			-- so 0001 would be 3rd channel active, and would be stored as 8 (0b1000)
			dat_str=""
			for j=0,3 do
				if (bcheck(loaded_level_info[i], 1<<j)) then
					dat_str..="1"
				else
					dat_str..="0"
				end
			end

		elseif i==14 or i==15 then
			local mx,my,ind
			if (dat_str >= 8192) then
				mx = (dat_str-8192)%128
				my = (dat_str-8192)\128
			else
				mx = (dat_str-4096)%128
				my = (dat_str-4096)\128 + 32
			end
			ind = bg_slot_index1
			p_col = 15
			if (i == 15) then
				p_col = 11
				ind = bg_slot_index2
			end
			
			dat_str = ind .. " (" .. dat_str .. " " ..mx .. "x " .. my .. "y)"
		elseif i == 17 then
			dat_str = dat_str .. "/" .. lvl_ntt_limit
		end
		
		print_outl(desc_strings[i]  .. dat_str , 0,16+8*(i-1),p_col,6)
	
	end


	for i=18, 27 do
	
		print_outl(desc_strings[i]  .. lvl_bg1[i-17] , 0,16+8*(i-1),15,6)

	end
	
	for i=28, #desc_strings do
	
		print_outl(desc_strings[i]  .. lvl_bg2[i-27], 0,16+8*(i-1),11,6)

	end
	
	

	local function draw_pal(y_of)
		for j=0,3 do
			for i=0,3 do
				rectfill(92 + i*8, 8+j*8+y_of, 99+ i*8, 15 + j*8 + y_of, j*4 + i)
			end
		end
	
	end

	if l_set_cursor_pos == 12 then
		local s_x,s_y,x_of,y_of = 92,68,12,10
		local demosprites = split"1,28,4,27,102,36,14,44,45,164,165,183,167,176,240"
	
		draw_pal(24)
		for j=0,4 do
			for i=0,2 do
				spr(demosprites[1+i+j*3],s_x+x_of*i,s_y+y_of*j)
			
			end
		end
		
	--elseif l_set_cursor_pos == 7 then
	--	pal(unpack_pal(loaded_level_main[1][5]+16), 0)
		--draw_pal(0)
	--	pal(0)
	elseif l_set_cursor_pos == 19 then
		pal(unpack_pal(lvl_bg1[2]+16), 0)
		draw_pal(139)
		pal(0)
	elseif l_set_cursor_pos == 29 then
		pal(unpack_pal(lvl_bg2[2]+16), 0)
		draw_pal(219)
		pal(0)
	end

	if (bg2_edited) print_outl("unsaved changes!\nlost if you\nswitch bgs",64,240,3,6)
	if (bg1_edited) print_outl("unsaved changes!\nlost if you\nswitch bgs",64,160,3,6)

	
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
			if bcheck(loaded_level_info[11], 1<<j) then
				fl &= 0b10111111
			else
				fl |= 0b01000000
			end
			
			poke(addr,fl)
		end

	end
end

ntt_extrainfos_pre=split([[/
procalert/true
next_e/11
rX,rY/16,0
rX,rY/-16,0
rX,rY/0,-16
rX,rY/-13,-13
Btyp,rope,ai_a,rngN,rngF/5,nil,AIAfllw,35,70
gun/9
boss/true
rope,rX,rY/6,76,-20
break_func/d_load_next
is_left/t
is_up/t
is_left,is_up/t,t
rX,rY/-15,15
text_box/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️4⬇️44⬇️42⬇️2⬇️1
rope,rX,rY,rope_e/8,-45,-8,d_o➡️2
/
text_box/\famaintenance staff is advised\n to only \fcgrab the\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1
decal/\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!\*f \*f \*f \*5 \^h\n🅾️\n\n\|c \-e+\n\n\|c\-f\^:10387c1010100010
decal/\f2\^o0ff\^:00008064320f0204 \^h ❎\|e\n\ng\|fr\|fa\|fb  \|e\^:0000070c90a0c0f0
/
/
actF,rngF,rngN,ai_a/310,220,38,AIAfllw]],"\n")

-->8
-- data
#include dropkicks_inc.p8:B

__gfx__
00000000555555545555555444444444aabbbaaeba999999ba9a99ab99a8ab9ab984489a000000009b9b9b9bbbbbbabb444444450000000077777d7877787778
00000000555555445444444455555554b99999e8a9888899999999999998b999bb8448ba000000008a99998a8b8998b844545455000000007dd78788ddd88d88
00000000544444445444444454444444b99eeee899999999999999999998a999b9b99b9a00000000aabaaba998b88b8945454545000000007dd788787877d888
00000000555555445444444454445454b9eeeee8a8888889999999999998a999b98bb89a00000000aa9aa9a9449bb94444545455000000007d78ddd8d8d888dd
00000000544444445444444454454454a9eeeee8999999999999999999989999b98bb89a000000008aaaaa98449bb94445454545000000007788ddd8778d7788
00000000555555445444444454444454a9eeeee899888898999999999998a999b9b99a9a00000000aabaab9898b88a89445454550000000078d78dd8dd888dd8
00000000444444445444444454444454aeeeeee899999998999999999998a999bb8448aa00000000aa9aa9a98b8998a845454545000000007dddd8d878dddd88
00000000555444444444444444555554e888888e99999888999999999988a999b984489a00000000baa99aa9aaaaaaaa5555555500000000d888888d8dd88888
11111111222222225555555544444444aaa999999999999aabababab88888888ff999fdd8444445a000000009b9b9b9b54005554444444445555555589889988
11111111222222225555555544444444a9999999999999998a8a8a8a88888888fd9999df8444454a000000008a8a8a8a540550545555555554444445489aaaa9
11111111222222225555555544444444bbaa9aa999999aaa8888888888888888ddf999ff8444444a00000000bbbbbbbb54550054444444445500005544899999
11111111222222225555555544444444baa9999999999a998998999988888888dff99ffd8444444a0000000099aaaa9955500054555555550550055044489999
11111111222222225555555544444444a9999999999999998888888888888888ff999fdd8444444a00000000888aa88855500054444444440055550044448998
11111111222222225555555544444444ba9aa9999999a9aa8888888888888888fd9999df8444444a00000000888aa888545500545555555500055000554448aa
11111111222222225555555544444444b9999999999999998888888888888888ddf999ff8444444a0000000088aaaa8854055054444444445555555544444489
11111111222222225555555544444444a999999999999aaa8888888888888888dff99ffd9aaaaaaa000000009999999954005554555555554444444445554448
44444444444444444554455455555555baa9baa99aa99999bba9bbbabb9bbbb90000000099888989ba9bba9b55455545fffffffd7777777d88888888babbbbba
555545554555445544554455545544559999999999999999baa9baa9aa9baaa90000000088888888aa9bba9b55455545fdffddfd7377337d89999999b9aaaa9a
44444444444444445445544554455445a9baa9aa999999aabaa9a999999a99990000000099999999ba9bba9b55455545fffddffd7773377d89899989babaabaa
554555455445544555445544554455459999999999999999aaa999999e999ee90000000088899988ba9bba9b55455545ffddfffd7733777d89999999aaaaaaa9
44444444444444444554455455544555baa9aaa9aaa9aa999999999999999ee90000000099999999ba9bba9b55455545fddffdfd7337737d89999999baaaaaa9
45554555454445554455445554554455999999999999999999999999999999990000000099999999ba9bba9b55455545fdffddfd7377337d89899989aabaaba8
44444444444444445445544554455445a9aaa9aa999aa9aa99999999999999990000000099999999ba9bba9b55455545fffffffd7777777d89999999a9aaaa98
55545554555455545544554455555555999999999999999999999999999999990000000099999999ba9bba9b55455445dddddddddddddddd8888888888888888
05000505050000050000000500000005b8bbbbbbbbbbbbbb9999999999999999545b45b499999999aa9bba9babababab999999995544444455544444babbbbba
050005050500000555555555000000558bb999b999b999b9999999999999999954a5a5ab99999999ba9bba9ba999999b999999995544445555544444aaa999a9
55005555050005050505050500000505b98999899989998999999999999999994b5a4aa599999999ba9baa9ba988888b999999995544444455555444aaaaaaaa
55500555050005055050505550000055b9999998888888889999999999999999a9b45baa99999989ba9bba9ba998999b99a999995544444555544444aaaaaaaa
05000505050005050505050505000505b99999988b9999b89999999999999a999bba99a988888888ba9bba9ba988888b99a9aa9a5544444455554444aaaaaa9a
05000505050005055555555555555555b99999988899998899999999a99aaaa99a89aa9999989999ba9bba9ba988888baaaaaaaa5544445555554444a9aa9a99
05000555550055055555555555555555888888888b9999b899999999999a9999a9aa99a988888888ba99aa99a988888bbbbbbbbb554444445554444499999999
5500050555000505555555555555555588889998888888889999999999999aaa8aa889888888888899889988abbbbbbbbbbbbbbb554444455555444488888888
aaaaaaaa555445445544455455544455ab9b9995babbba9877f9f9fffff9f9ff909fd090abbabbabf7ffffff99900999aaaaaaaa44444445aaaaaaaaaaaaaaaa
a000000a5455444445544544544545559bbbbbb9b8baa8987f7fffffffff9fff999fd090baabba8a7f7fff7f9f7fffffa000000a46666665a000000aa000000a
a0000a0a444445544454554445444554abbababab8baa898f7ffff7fffff7fff009ffd9889a88b88f7fffff7f7ff7fffa0000a0a46444445a0000a0aa0000a0a
a000a00a554555445444454545445544abbaaa9aa8a88888fffffffffff7ffff0f9dd88888a899b8fff7ffff8fffffffa000a00a46545555a000a00aa000a00a
a00a000a5445545444445454445454449ab9b9aababbba98ffffffffffffff7ffd9fd9908a8899a8ffffffff9f8f8f8fa00a000a46444445a00a000aa00a000a
a0a0000a4455444555445444444444449a9a9aa9b8baa898fffffffff7fff7f7ddddd080aa988aaaf8f8f8f80888f8f8a0a0000a46555555a0a0000aa0a0000a
a000000a445444445444554455444445999a9a99b8baa898f9fffff9f9ffff79080fd980a8a88a8a89898989f989897fa000000a46444445a000000aa000000a
aaaaaaaa44444455444445445444445589999999a8a888889f9f9f9f9f9fff9f089fd800a8a88a8898989898f80099ffaaaaaaaa55555555aaaaaaaaaaaaaaaa
aaaaaaaa11111111aaaaaaaa454445459899999999999989baabbbabaaaaaaaaaaaaaaaa4a5a959a00000000f7ffffff05445050aaaaaaaa0000000054999999
a000000a11010111a000000a54544444899999999999999898899999a000000aa000000aa454a49a000000007ffff7ff05045550a000000a0555555054499a99
a0000a0a01101011a0000a0a54444454889999999999998888888888a0000a0aa0000a0a4954a49400000000ffffffff55055500a0000a0a05555554445999a9
a000a00a10110110a000a00a44444544588999999999998988988899a000a00aa000a00a4599999400000000f9f9f9f905454505a000a00a5555555445494999
a00a000a01010001a00a000a44444444589999999999988988888899a00a000aa00a000a4549449a000000009f9f9f9f05554555a00a000a5454545445494999
a0a0000a00100000a0a0000a44454444899999999999998599888888a0a0000aa0a0000a99a9594a000000008989898900454500a0a0000a4545454555454449
a000000a00000000a000000a44445445899999999999999899888898a000000aa000000a9aa49a59000000008888088805454500a000000a5454445555455459
aaaaaaaa00000000aaaaaaaa45444444999999999999998988898888aaaaaaaaaaaaaaaa9a44aa59000000000808008004454550aaaaaaaa0404040455555454
454455455454554455545554555455549bbb99a99ba999995b5bb5b55b55bb5b000000004a54ba5aba9bbab900000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
54545454455454545554555455545544bbaaaa99ba999999bbbbbbbbbbbbbbbb00000000ab94aa4ba99babab00000000a000000aa000000aa000000aa000000a
55444544545544545554555455544454aaaaaa9b99999bb9abbbaababbababbb00000000a9b9a99aba9b9ba900000000a0000a0aa0000a0aa0000a0aa0000a0a
454545454554545544444444444444449aaaa9999999baa9ababaa9aabaabaab0000000099aa9a9aba9a9ba900000000a000a00aa000a00aa000a00aa000a00a
54545444545545545554555444455444b99999bbbbb9aa999a9aa9a9aaa9ba9a00000000999a9a9aba9b9ba900000000a00a000aa00a000aa00a000aa00a000a
45454445454544555554555444555544aaa9bbbaaa99999aa99b9aa9a9a99a9a0000000099a99a99aa9b9a9900000000a0a0000aa0a0000aa0a0000aa0a0000a
45455454454544545554555444455544aa99baaaa999ba9aa9ab9a9aa99a99a90000000099999999ba9b9ba900000000a000000aa000000aa000000aa000000a
54445454554554554444444444445444a9999aaa999aaa9999a9999a999999a90000000099999999ba9baba900000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
50450405000500500000000000000000bbbabbbabbba88b8aaaaaaaa99a99999aaaaaaaa99999999ba9b9ba997f9f979545454545445454444444454bbbabbba
44540455050450450000400400000000baa8baa8baa88baaa000000a9a99a999a000000aa99999a9ab9baab87f7f97f7545554555445454454555554baa8baa8
04545454045540055054004005004500baa8baa8baa8aaa9a0000a0a99999a99a0000a0a99899a99ba8a8babf7f9f979544444445444454444444444baa8baa8
54544044054040540405005454045040a8888888a8888aa8a000a00a9999a9a9a000a00a99599999bb8aab8b9f9f9f9f455555555445545455554454a8888888
55454540454540450545050445055405bbbabbbabba98888a00a000a9a99a9aaa00a000aa9895999bababa8af979f9f944444444544445444444454588e88e88
54504545505445554545454540050454baa8baa8ba988988a0a0000aa99999a9a0a0000a5a858989a9baba8b97f7f7ff444444445444454444554454e8e88e98
54555045545445545405554554505455baa8baa8a9988989a000000a999a999aa000000a59885989b9b99889f9797f7955545554544455554544445499989e99
44545445045404555554555554545545a888a88898889989aaaaaaaa99999999aaaaaaaa88585885b99bab899f9f97ff44545454544444445444445488888888
40d8611070ea211050bad140d0d63111224281510000000000000000000000000000000001e0f41001e3f3100125731070941410604463506043244000000000
c1168091c1f6a191e105d210c163d091c1e4309100000000080808080808080808087878284808ca180808080800000000000000000038d82828050a18080808
500351207042112040d4017050c7d04022f40161000000000000000000000000000000006012713060c4216021b5a110f0d6b0100112521001c5521001477110
a181a110a1e2e110a122c110000000000000000000000000286828280b491808180848d828eb0a0c080808080800000000000000000038e838480a8a18080808
50a1c110f0d0711050b2c3214094d12070f3803070b4801070c1b21042c6e1800000000021e322306035328021b8613000000000000000000000000000000000
000000000000000000000000000000000000000000000000280828280b491808f708580838280808080808080800000000000000000038e8e70a0a0d18080808
42c2408042a2c1804241408042c1c22100000000000000000000000000000000000000006145a1a0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000008000000000000000000080000000000000000000800000000000000000038682889bc0c18080808
424234404224a4214253e0407056412070e5e03042656280508443807005c4105026245012b131c0000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000180848880c2808080808080000000000000000000800000000000000000038e8288a086d18080808
b04271108015d1a000000000000000000000000000000000000000000000000000000000b1423250918123d0b121e250b112e41091d4941091f374e000000000
000000000000000000000000000000000000000000000000187838185ae818080808080000000000000000000800000000000000000038182809084b18080808
40b302207014611050c28140504531400000000000000000000000000000000000000000b1c49310b1c21201f1c2d310c152911002c2b120f041f010b1412110
00000000000000000000000000000000000000000000000018385888838808080808080000000000000000000800000000000000000008000000000000000000
d0b1d14121a3a130701541102126a1100000000000000000000000000000000000000000b1424301c1c1b110c1c551100244d110917281e00000000000000000
00000000000000000000000000000000000000000000000008a85888058718080808080000000000000000000800000000000000000008000000000000000000
000000003d666dd3000dd0000000000d03000000ddddddd600dddd000000000000022000000cc000000000000000000000000000000000000000000d70000000
00000000d66d66630dddddd0000003d00d000000666663d60dddddd000022000023773200cf77fc000666600000000000000ddd00ddd000000000007e0000000
00888000666636306dddddd366663d006d66600066663636d8d66dd800233200037777300f7dd7f0066666660000000000dddd6dd6dddd0000d0007dee000e00
0c8d800063dddd3066ddd368366777776d66660063366366dd6336d80237732027777772c7dccd7c6666666666000000dddd886dd688dddd0007d0d99e0ee000
00cdd00063dddd3066636883366dddddd3d33d3d36d36666dd6336880237732027777772c7dccd7c6666666666660000d866d86dd68d868d000dd966669ee000
0080000066666630666883683366d300dddddddd3d636666ddd6688600233200037777300f7dd7f0666666666666660088636d6666d63688000096d666690000
00000000d66d66630663686006000d3066666600633666660dd8886000022000023773200cf77fc066666666666666660086366336636800007d6d663666ee00
000000003d666dd300686600000000dd6666660066666666008866000000000000022000000cc000ddd6666666666666000d63666636d000d7d9666363669eee
000000000000000000003000066dd66000ddd60000ddd60000ddd600006606600606660000606600dddddddddddddddd00ddd660066ddd007dd9666636669eee
00f0000000000000003666306d6666d30dd666600dd666600dd66660606066000666606606066660dd666666666666660d8d68600686d8d000dd666666e6ee00
00f66000009990000300600366d66d66366366363d366363d36636636660666660660660660660066d666666666666d3ddd8068668608ddd000096666e690000
00f333000087d7000366666366d66dd366666666666666666666666606666006660666666666666066d666666666d3d3dddd68633686dddd000dd966669ee000
00666000009990000300600366d33d66666666666666666666666666600666606666606606666666d66dddddddd3d3d38ddd08633680ddd8000dd0d99e0ee000
00000000000000000036663066d33dd33366663333666633776666776666066606606606600660660d63636366d3d30080ddd086680ddd0800d000ddee000e00
000000000000000000006000d6d66d6d77366377003663000076670000660606660666600666606000ddddddddd300000606d000000d60800000000de0000000
00000000000000000fd666df0dd66dd0077007707000000700000000066066000066606000660600000d66666d00000000606600006606000000000de0000000
00000000000333000000000022220000000000000000000000000000bbb99b999999b9aa9bb9aaa95bbbaa9a0000000000000000000a99990000000000000a99
00000000233333300222200022222220000000000000000000000000bbaabaabbb9bba99bbaa9999baa9999900000000aa900000000a99999999000000aaa999
00000022333333333332222222222200004440000000000000000440aaa9aaabbaa9a99b9aa99bb9ba99a99900000aaaaa99000000aa999999999999aaa99a99
00022222332322233233222323333220004444000000044000044440aaa99a999a9b99999999baaab999999900aaaaaa9999900000a99999999999999aaa9999
02222223333212322222233333232222004444000044044400044440b9aa99bbb9baa9bbbbb99aa9a9a99999aaaaa999aa9999000aa999a999999999aa999a99
22333233232121221222333232312112044444000044044444044440aa9b9bbaaa9a9bbbaaaa999ba9999999aa999aaaaa9999900a9a99a9999999999aaa9999
23333332322333312111332112121111444444004044044444444444a9baabaaaaa9bbaaaaa9bbb99999999999aaaaaaaa999999aa9a99a999999999aa999a99
33332322213333331113321221211133444444404444444444444444999a99aaaa999aaa9a9bbaaa89999998aaaaaaaa99999999a9aa9999999999999aaa9999
33323121133332322233322100000000444000000000444000000000000bbb00d980fd8089898998baaabbbbaaaaa999aa999999a9aa999999889889aa999a99
222212333333222123322222000000004444440000004444000000000baa99a0d99fd980a989895888ab9898aa999aaaaa9999999aaa9999989898989aaa9999
121233233232121232232111000000004444444400004444000000000a99809a09ffd90098998599888a888899aaaaaaaa9999999aaa999998899988aa999a99
11233222232121222232111200000000444444440000444400000000ba9099000ffd98009899589888898888aaaaaaaa99999999aaa99999999999999aaa9999
13322212222211212121112300000000444444440000444400000000ba08aba00fd980009999959a88898888aaaaa999aa999999aaa999a998899988aa999a99
33212111221112111211123200000000444444440040444400000000098a80b90d989900a9a9595a89898899aa999aaaaa999999aa9a99a9989898989aaa9999
12121111111111111111112100002220444444444044444400000000009898b9f988d9008ab5bb5b8899889999aaaaaaaa999999aa9a99a999889889aa999a99
112111111111111111111211222222224444444444444444000000000098a9b9d989f980bb5babb599999888aaaaaaaa99999999a9aa9999999999999aaa9999
0022222201011111000000001113233200000000010000000000000010101010111111110000000000000300a88000000000000000bb000000000000000b8000
022222331010111100222000122222110330033000d010d001000d3d000000001111111100000000030003000800000000bb0000bbbbbb00000000000b888800
222233331101010122222220222121110300003006360000000006d610101010212121210030000003000300a080000000abb000abbb88000000000ba8888880
22233323010000103333222212111322000000001000001010001000010101011111111100030000030030000800000000a88000aaa88800000000baa8888880
2332222200100000322232002111322100000000001000010010001010101010212121210000300003003000000000000aa88000aaa8800000000baaaa888888
33212121000000002122130011121211030000300000d0d0d636d00101010101121212120000033033033003000000008aa80000aaa880000000baaaaa888888
121211110000000012111220112121110330033001066d660060100d11111111222222220000003333033003000000000aa00000aaa88000000baaaaaaa88888
112111110000000021111122111111110000000000001300010000000101010112121212000000033b033030000000000a000000aa88000000baaaaaaaa88888
000000000000000000ffff0000dddd00000000220ff7fff000dfddd00ddf700000ddd0000033003a33b3b030000a080000aa88808a80000000aaaaaaaaaa8880
00fffc0000fffd000f7ffdd00dddddd022222252f7fffff70fffffdddff777f00ddddd000000330393b3a3300000bb0000aa88800800000000aaaaaaaaaa8880
0f7cccc00f7fdd80f7fdddd8d3ddddd325a2aa20fffffffd0dfff880dd777fd0008880003300a33b3b8ab3300000abbb00a8880000800bb0000aaaaaaaaaa800
0fcccc800ffddd80ffdddd88dd7ddd3d02222220dfffdddd0ffcffddf77ccfff0ddddd00003330a9b3a8b3000000aa8800a88800080abb80000aaaaaaaaaa800
0fcccc800fddd880ffdddd86ddd773d802aa2a208d8888880ffcff88777ccfff08dddd00000033389b898bb0000aaa8800a88800000aa8800000aaaaaaaaa000
0cccc8800ddd8860fdddd886ddd7dd8602222220080888800dfff880d7ffffd0008880000000baba8ab89a33000aa8800aa88000000aa8800000aaaaaaa00000
00c88800008886000dd888600dd3d86002aaa252000800800fffff88dffffff008dddd0033333aab88ab8390000aa8800a888000000aa88000000aaaa0000000
00000000000000000088660000838600252222200000000000df88800ddff000008880000000333a8888aa89000aa8800a880000000aa88000000aa000000000
__label__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
8888888888f88888888888ff88888888888ffffffffffffffffffff8888f888888ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
88888888228888888888888888888888882fffffffffffffffffff8888288888888888f88888888888ff88fffffffffffffffffffffffffffffffffffffffff8
88888888888888888888288888888888882fffffffffffffff88888822888888888882888888888882888888888888288888888888ffffffffffffffffffff88
88888828888888888882288888888888222ffffffffffffff888888288888888888828888888888828888888888822888888888882ffffffffffffffff888888
2222222288888888822288888888888282ffffffffffff888888882888888888882288888888888288888888888288888888888882fffffffffffffff8888882
2222222222222222222222222222222222fffffffffff8822222222222222222222222222222222222222222222222222222222222ffffffffffff8888800828
888888882280000000888288888000002f88888880008228888888000008888888880000880000088822000008888000002222222f0000ff00000882200cc022
88888882880cccccc0882888880ccccc088888800ccc0888888880ccccc088888880ccc000ccc0088280ccc0d88800cccc02222220ccc000ccc002280ccccc08
8888882880ccccccc022888880cc000cc088880cccccc08888880cc000cc0888880ccc00cccc00d8280ccc0dd880cccccc0fffff0ccc00cccc00d880cccccc08
888882880ccc0cccc08888880cc0660cc08880cc00ccc0888880cc0660cc088880ccc0cccc00ddd280ccc0ddd80ccc000c088880ccc0cccc00ddd80ccccccc02
22222220ccc060ccc0222220ccc000ccc0220cc0d0ccc022220ccc000ccc02220ccccccc00ddddd20ccc0ddd20ccc0d60002220ccccccc00ddddd80ccc0cc0d8
8888880ccc0660ccc088820cccccccc00d20cc0d0ccc0d8880cccccccc00d880cccccc00ddddd880ccc0ddd80ccc0dd666d880cccccc00ddddd2200cccc00dd2
888880ccc0660ccc0d8220cccccccc0ddd0cc0d0ccc088880cccc000006d880ccccc00ddddd8880ccc0ddd80ccc0dddddd880ccccc00dddddd88000cccc08888
88880bbbb000bbbb0d280bbbbbbb00ddd0bbb00bbb0dd880bbbb0d66666d80bbbbbbb0dddd8880bbb0ddd80bbb0ddd888880bbbbbbb0dddd8880bbb0bbb0dd88
8880ccccccccccc0dd80cccc0ccc0dddd0ccccccc0ddd80cccc0dd6666d80cccc0ccc0dd88880ccc0ddd880cccc00088880cccc0ccc0dd88880ccccccc0dd882
220bbbbbbbbbb00ddd0bbbb0bbbb0ddd20bbbbbb0ddd20bbbb0ddddddd20bbbb0d0bbb022220bbb0ddd8880bbbbbb08880bbbb0d0bbb088880bbbbbbb0dd8828
80bbbbbbbbb000ddd0bbbb00bbb0dd8880bbbb00ddd80bbbb0dd8888880bbbb0dd0bbb02220bbb0ddd2222d0bbb00d220bbbb0dd0bbb02222d0bbbb00ddd2222
000000000000dddd000000000000d8882d0000dddd8000000ddd88882000000dddd00000800000ddd28888d600066d2000000ddd600000888d6000066dd88888
d6666666666dddd8d66666dd6666d8828d6666ddd88d6666ddd888828d6666ddd8d6666d8d666ddd888888d666666d8d6666ddd8d6666d888d6666666d888888
d6666666666ddd88d66666dd666d88288d6666dd882d6666dd8888288d6666dd88d6666d8d666dd88888888d666dd88d6666dd82d6666d8888d666ddd8888882
dddddddddddd8882dddddddddddd222222dddd22222dddddd22222888dddddd8828ddddd8ddddd8888888888ddd8888dddddd8288ddddd88882ddd8888888828
22222222222222222222222288888888882888888888822888822222222222222222222222222222222229999922222228882222222222222222222222222288
88888822888888888822222888888888228888888888288888888888288888888888ddd888888888288ddddddd99022288888888882888888888822888822222
88888288888888888222ee88888888828888888888828888888888828888888dd00999dd88888822ddd89d0099dd022888899999999988888888288888888888
888828888888888822ee888888888828888888888828888888888828888888890ddd9999888882888889dd099dd900dddd999009999988888882888888888882
882288888888882222ee22222222222222222222222222222222222222288889099ddd099998289099dd9990ddddddd888999900009998ffffffffffffffffff
2222222222288888888e8888888888888228888888888288888888888288888099990dd099dd22900dd99dddd9900022229999099999922222222222fffffff2
ff88882888888888888e88888888888828888888888828888888888828dddddddddddd009dd8889dd099ddd9909988888999909999998998888882888888888f
fffffff88888888888888888888888828888888888828888888888228888888ddddd9999999888dd0099d099898f888889990099999999999888288888888888
88828888888888888822888888888828888888888228888888888288888888888ddddd9990982299900099988888888999900999990000998882888888888822
88288888888882222222222222222222222222222222222222222222222222222222922292222298800898888822889999909999990090999999999988888288
222222222222222222222222222222222222222222222222222222222222222222229222222222f2202222222222299000009999900990099990000999222222
ffffffffffffff2222ee222222222222222222222fe2222222222e2222222222222222222222fff2222888888888899900000999909999099900990999888888
8888ffffffffffffffffffeeeeee22222222222fffeeeeeeeeee222222222222222ffffffffffff2228888888888298999900099909990099009999999888888
88222ffffffeeeeeeeefffffffee22222222222fffeeeeeeee22222222222222222ffffffffffffff88888888882888899998899999990999099999999222222
22222ffffffeeeeeeeeeeeeeeeee22222222222fffeeeee22222222222222222222ffffffffffff8888888888828888898998298899999999000999992992222
2222fffffffeeeeeeeeeeeeeeeee22222222222fffeee2222222222222222222222ffffffffffff2222222222222222292292222992299999990099099992222
22fffffffffeeeeeeeeeeeeeeeee22222222222fffeee2222222222222222222222ffffffffffff222222222222222222229222299222999999999999998822f
fffffffffffeeeeeeeeeeeeeeeee22222222222faaaee2222222222222222222222fffffaffffff22222222222f2222222292fe2292228888999999999882fff
fffffffffffeeeeeeeeeeeeeeeee22222222222faaaaaaaaa222222222222222222fffffaafffffffffffffffeeeeeeeeeeeeeeeeeee8888888888898888222f
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeaaaaa2aaaa22222222222222fffffffaafffffffffeeeeeeeeeeeeeeeeeeeeeee8888888888888882222f
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeee222aaaaaaaaa2222222222ffffffffaaffffffffeeeeeeeeeeeeeeeeeeeeee888888888888888822222
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeee22222222aaaaaaa2222222fffffffffaafffffffeeeeeeeeeeeeeeeeeeeeee222222222222222222222
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeee2222222222222aaaaaaa22fffffffffffaffffffeeeeeeeeeeeeeeeeeeeeee222222222222222222222
eeeee222fffeeeeeeeeeeeeeeeee22a22222222fffeee22222222222222222aaaa2ffffffffffffafffffeeeeeeeeeeeeeeeeeeeeee222222222222222222222
eeeee222fffeeeeeeeeeeeeeeeee22aaa222222fffeee2222222222222222222222fffffffffffffaafffeeeeeeeeeeeeeeeeeeeeee22eeeeeeee22222222222
eeeee222fffeeeeeeeeeeeeeeeee2222aa22222fffeee2222222222222222222222f101f0f111fffffaafeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222222222
eeeee2222ffeeeeeeeeeeeeeeeee22222aaaa22fffeee2222222222222222222222f100000101ffffffaaaeeeeeee111eeeeeeeeeeeeeeeeeeeee22222222222
eeeee22222feeeeeeeeeeeeeeeee2222222aaaaf22eee2222222222222222222222ff00111001f1ffffaaeaaeeee11e111eeeeee11eeeeeeeeeee22222222222
eeeee222222eeeeeeeeeeeeeeeee222222222aaa22eee2222222222222222222222f1011f1111f11ffffaaeeaaeeeeeeeeeeeee11111eeeeeeeee22222222222
eeeee222222eeeeeeeeeeeeeeeee2222222222aaaaeee22222222222222222222220001fff101fff11fffaaeeeaaaeeeeeeeee111ee1eeeeeeeee22222222fff
eeeee222222eeeeeeeeeeeeeeeee22222222222faaaae2222222222222222222aa211111f1111ffffffffeeeeeeeaaaeaeeeeee11e111eeeeeeee2222fffffff
eeeee222222eeeeeeeeeeeeeeeee22222222222f22aaa222222222222222222aaeee10011100ffff1ffffeeeeeeeeeeaaaaaeeee1111eeeeeeeee222222ffff2
eeeee222222eeeeeeeeeeeeeeeee22222222222222eeaaaaaa22222222222aaaaaae10010000022221fffe1eeeeeeeeeeaaaaaaee1eeeeeeeeeee222222222ff
eeeee222222eeeeeeeeeeeeeeeee22222222222222eee2aaaaaaa22222aaaaaaaaaee11e01a1112221122e000001111eeeeeeeeeeeeeeeeeeeeee22222222222
eeeee222222eeeeeeeeeeeeeeeee22222222222222eee222aaaaaa22aaaaaaaaaaeeaeee11aaaaa000000000000000011111111111eeeeeeeeeee22222222222
eeeee222222eeeeeeeeeeeeeeeee22222222222222eee2222a2aaaaaaaaaaaaaeeeeeaaaaaaaaaaaa222ee000000000000d000000111111111eee22222222222
eeeee7777777ee11eeeeeeeeeeee22222222222222eee2222aa22aaaaaaaaaaeeeeeeeeaaaaaaaaaaaaaee110000000000d00000000000000011112222222222
eeeee222222eeee111111eeeeeee22222222222222eee22222aa22222aaaaeeeeeeeeeeeaaaaaaaaaaaaaaa10000000000d00000000000000000011112222222
eeeee222222eeeeeee11111111ee22222222222222eee222222aaaaaaa222eeeeeeeeeeee2aaa2aaaaaaaaaa110000000dd00000000000000000001122222222
eeeee222222eeeeeeeeeee111111121122222111111111111111122222222eeeeeeeeeeee2222aaa222aaaae111110000d0000000000aa000000001222222222
eeeee222222eeeeeeeeeeee1111111111112222222e11111111111111111111111e11111122222211aaaaaaaaaaaaaaa000000000000aaa00000001222222222
eccccccccccccccccc111111121117711112111111eee2222222222211111111111111111111111111111aaaa11aeaaa11000000000d000aaa00012222222222
eeeee211ccccccccccccc122111777771d11ccc11111111111111111111666666666666666666677777777771aaaaaeaa1a11000000d00000aaa012222222222
cccccccccccccccccccc1122211777771dd1cccccc66666666666666666666666666666666666677777777777111aaaaaaaaa100000d0000000a012222222222
888888ccccccccccccccc122221177711dd11cccccccccccccccccccc11666666666666666666677777777777771111aaaaaa1dddddd00000000188888888888
22222211cccccccccccc11222221111ddddd1cccccccccc66666666666666666666666666666667777777777777777112aaa10000dd000000000122222222222
88888881cccccccc1111112222221ddddddd1ccccccccccccccccccccc11666666666666666666777777777777777aaaaaaa00000000000d0000188222222222
2222222111cc11111122212222221ddddddd1ccccccccccccccccccccc1166666666666666666677777777711111aaaaaaa100000000000d0001222222222222
88888888211118822222222222221ddddddd1ccccccccccccccccccccc1166666611111111111111111111111711aaaaaa100000000000ddddd1888888888888
2222222222222222222221111111111111dd1c1111111111111cccccccc1166666666666666666677777777777777a7aaa10d000000000d000d1288888222222
888cccccccc111111888211122211777711d1cccccccccccccc1ccccccc116666666666666666667777777777777771aa100dddd000000000001882222222222
888888811cccccc1111111111111177777111ccccccccccccccc1cccccc116666666666666666667777777777777777aa000000dddd000000019999992298899
22222221cccccccccccccccc112117777711ccccccccccccccccccc666666666666666666666666677700000000000000000000000ddd0000012288888888888
8cccccccccccccccccccccccc11117771111c111111111111116666666666666666666666666666677777777000000000000000000000aaa0012999888888888
888cccccccccccccccccccccccc11111111111828888888888888811111111116666666666666666777777777777771100000000000000000012299999ffffff
8888cccccccccc1111111111111111118888882288888888811111111111111111111111111111aaaaaaa11111171110aaa000000000000000192999ffffffff
22222222222222222222222111111112222222111111111111111111111111111111222222aaaaaaaaaaa2222a11100000aa0000000100000012222222222222
88888888888777777788881111111886666666666666666666668882288888888888888aaaaaaa288aa888aa00000000000a0000000100000118822222888888
888888888882888888811111188888888882888888888888888222222888888888888888888888aaa88aa10000000000000a0000011100000188888888888888
888888888777777888111888888888888822222222888888888888888888888888888888888aaa8288aa80000000000000000011110000111188882222222222
888888888888888888888888888888888888888888888888888888888888888888888888aaa88800000000000000000111111111111111188888888888888888
8888822222888888888888888888888888888888888888888888888828888888888888aaa8888882a88888800000000011888818228888888888888888888888
22222222222222222222222222222222222222222222222222222222222222222222aa2222222222a22211112211112221222122222222222222222222222222
8888888888888888882228888888888888888888888888888888888888888888888aa88888888888a88882221118888111881888882a88888888228888888888
888888888888888888228888888888888888888888888888888888888888888888a8888888888888a8822222288888111881818888aa88888888222228888888
88888888888888888888888888888888888888888888888822222222288888888aa8888888888888aa8888888888811888181888aa8888888888888888888888
88822228888888888888888888888888888888888888aaaaaaa88888888888888a888888888888888a888888888811888888888a888888888882222222228888
8882222222222888822888888888888888888aaaaaaaaaaaaaaaaaaaa8888118a8888888888888888a8888822811188888888aa8888888888888888888888888
8888888888888888822888222222228228888aaaaaaaaaaaaaaaaaa88aaa811111111111188888888a888888881888888888a888888888888fffffffffffffff
888888888888888888888888822222aaaaaaaaaaaaaa8888822222288888111111111111111111111a88888811288888888aa8888888888888888fffffffffff
88888888888888888888888888888888888828888888888888228888888111888811888888811111111111111888222228aaa888888888888888888888888888
888888888888882222222222228888888882888888888888888888888118888111888888888888aa11111111882222228aa88888888888888888888822882288
8888822222222222888888888888888888222888888888888828888111111111888888888888aa8888881188888888888a888888888888888888888888888228
f8888888888888888888888888888228222222222222822222221111111112222222222222aa2222222222222222222222222222222222222222222222222222
88ffffffff88888888888888888888822222222222228888881111882111222222222222aa222222222228888888888888888888888888888888888888888888
888888888888fffff88888888888888822222222111288811118888112222222222222aa28888888888822888888888888888888888888888888888888888888
888888888888888888888882222222222222222111821111881111118888888888888aa888888222222222222228888888888888888888888888888888888888
88888888888888888888888882222222222222118111118811188888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888822222222221111112888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888882222222221111111111188888888888888888888888888888888888888882222222222888888888888888888888888888888
88888888888888888888888888822222222111222888888888888888888888888888888888888888888888822888888888888888888888888888888888888888
88888888811188888888888888822222111111228888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888f1aa111f8888888888222221111112282288888888888888888888888888888888888888882222222288888888888888888888888888888888888888
ffffffff1aaaaaa1fff88888882222111111228888888888888888888888888888888888888888888888888822228888888888ffffffffffffffffff88888888
ffffffff1aaaaaaa18888888822111111111288888888888888888888888888888888888888888888888822222228888888888888888888888f8888888888888
88888881aaaaaaaaa1888888821aaaaa1111888888888888888888888888888888888888888888222222222222ff88888888888fffffffffffffffffffffffff
8888881aaaaaaaaaa118888221aaaaaaaa118888888888888888888888888888888888888888888822222222888ffffffffffffffffffffffffffffff8888888
8888811aaaa111aaaa1888821aaaa1aaaa1888888888888888888888888888888888888888882222222222222222228888888888888888888888888888888888
888881aaaa1cc11aaa1888211aaa1111111881111888888888888888888888888888888888888888888888888222222888888888888888888888888888888888
88881aaaa1cccc1aaa188821aaaa1111118811aa1188881888888888888888888888888888888888888888882222222222288888888888888888888888888888
8881aaaa1c11c11aaa18881aaaaaaaa111881aaa1188111118888881188888888888888888888888888822222222222288888888888888888888888888888888
8811aaaaa11111aaaa1881aaaaa1111118881aaaa1111aaa1888811aa11188888888888822222222222222222222222228888888888888888888888888888888
221aaaaaaa11aaaaaa1811aaaaaaa11118811aaaa11aaaaa18881aaaaaaa188888888888888888822222222222222222288888888888ffffffffffffffffffff
22111aaaaaaaaaaaa1121aaaaaaaaa112221aaa1aaaaaaa11221aaaaaaaaa1222222222222222222222222222222222ffffffffffffffffffffff22222222222
221c111aaaaaaaaa112111aaaaaaa1122221aaa1aaaa1aa1221aaaa11aaaa1222222222222222222222222222222222222222222222222222222222222222222
221ccc111111111111211111111111122221aa1111111aa1221aa11cc11aa1122222222222222222222222222222222222222222222222222222222222222222
221111cccccccc111121ccccccccc111222111111cc11a11221aa1cccc1aaa122222222222222222222222222222222222222222222222222222222222222222
2222211111cc1111222111111111111222221ccc11111a1221aaa11c111aaa122222222222222222222222222222222222222222222222222222222222ffffff
22222221111111222222222222222222222211112221111221aaaa111aaaa112222222222222222222222222222222222222222222222222222222222222222f
22222222222222222222222222222222222222222221c122111aaaaaaaaa11122222222222222222222222222222222222222222222222222222222222222222
f22222222222222222222222222222222222222222221122111111aa1111cc122222222222222222222222222222222222222222222222222222222222222222
fffffffffffffff222222222222222222222222222222222211cccc11cccc1222222222222222222222222222222222222222222222222222222222222222222
22222222222fffffffffffffffffffffff22222222222222221111cccc1111222222222222222222222222222222222fffffffffffffffffffffffffffffffff
2222222222222222222222222222222222ffff22222222222222111111122222222222222222222ffffffffffffffffffffffffffffffffff222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222fffffffffffffff
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222fffffffffffffffffffffffffffffffffffff

__gff__
8808080801010101010001018800838388888808010101818101000108880808080808080101010100010108888881810808080801018101810101010108080100080808010111111101111100080000000000080101010000010011080008080808080801010101000101000000000008080808010100010001011108080801
0000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001000001000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d400000000d3c0c1c2e2d371707173727371730c0c7d7e7d0c0c0c00fb00000000eeef00e90000e9000000e7e7e7e7e7e7e7e7e5e6e6e5e6e6e5e6000000acad000000001c00001c00001c24243615000000000000000000000000000000008184828250a081809e7d82878384808e81809e80
cfce00dbdc00dd36c4c6d5c6c513c4c5c0c1e0d2d0d1d2c361604170616160601d1d7d7e7d4d4d1dedfc00ecfb00feff0000e90000000000e8e8e8e8e8e8e8e8e5e5e6e5e5e5e5e5000000bcbd0000001e1a1e1e1a1e1e1a242436150000000000000000000000000000000081868584a0668180ad7a8287858880928180bc80
df36d5dbdccfdd361313131313131313d0d1d2e31010e3e36042434143424260231d7c7e7d1e4d1dfbfdeeedfced00ed0000000000e900e91111111111111111e5e6e5e5e6e5e6e6000000bcbd000000001c00001c00001c242436150000000000000000000000000000000082878380806681819e7180000000000000000000
df3606dbdcdfdd361313131313131313e1e151e1e15151e166666666666666661d1d7e7d7c4d4d1dfcfbfbebecebeceb000000e9000000001111111111111111e5e5e6e5e6e5e6e5000000bcbd000000001c00001c00001c242436150000000000000000000000000000000082878488a0c48181ad6280000000000000000000
00000000012020200202020220202020042727264647060741202020676667661b0a1b1b005c00015e0a5e0bdc08881c2020202002020102212121212020202071707171000000006013131320202024000000001717171714f676766667143677253636363614155b4a5b5b001c001c001c001c1e415e415e415e5e1f363636
00000000202021200202020220032003143636154706070641410303767676760008005c005c001c1e088008dc08881c02060602e0e0e001222222220202020261706070000000006013131320202024000000001717171714f676767676143676f936f936f914158b8b8b8b001c001c001c001c001c001c001c00003d1f3736
00000000212020200202020220012001143636370606060627262627f6f676761e081e5c0b0a0b0b0b0a5e0b1e0a8a0102393902e0e0e0020202020203cf02ce60636160000000006013131374747424000000001717171714f67676b976143776d914d925d914151e011e1e5b4a5b5b000100015e415e415e015e5e02131f37
00000000424242420202020220202020253636360606060637363636f6f676760008005c0008001c00081c08dc08881c20202020e0e0e002ce02cfce2627262663626163000000006013131375757524000000001717171714f6767657b9041576e925e936e93715001c00008b8b8b8b001c001c001c005c000000003d1d3d1f
e0e0e0e002e0e002011e1e01131313132424252500000000203d2002000000000223230200000000070707002b2b2b2b1ee0e0e0e0f0f0e0e0e0e0e0001c001c000000000000000000000000000000002020202020202020767676766a6a6a6a21032120363736370000000000000000353434342f1d1d022f3f3f2f16161616
e0e0e0e020e0e0201ce0e01c202020202524252400000000aaaa2a2a00000000231d213d72723232070607002b2b2b2b30e0e0e0e0f0f0e0e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf76767676babababa62626262373936360000000000000000477676760823233d220c0c34172e2e2e
e0e0e0e020e0e0201ce0e01c212020202524252500000000eaea2a2a00000000231d033d424242021b1b1b00212020211ee0e0e0e0f0f0e01e011e1ee0e0e0e00031c32b3031303100003100000000000202662646060706767676760202020226272627200139394132323232323232477676760835353434380c3439393939
e0e0e0e002e0e002011e1e0102cecfcf24252425000000007a7a3a3a000000000202020261606060001c000003202120001c011c2b2b2b2b00000000e0e0e0e032c3c32b302120303133303132323232222276377636073676767676131313133939393921132120161616560202cf0235aeae352f1b1b2f2f3f222f22222222
1e1dac0000001b1baf000000001819000000180312bb181900001c18199c0000000000000000000018393fb91699120000000016000000001c00000000001c00001c3c00000000a21eacaeac1e0000000000000000000000000000000000000000000000000000000000000000000000e4456e4652f2f1f9d95a5a5a5af97676
0038ac00b033339caf090000001881bbbbbb180312ad010100ac1c18191d00002b1e1d009b00a01e18b8b8981699120000000016000000001c1eacb300001aa2001c9f0000ac0000001c00ac000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbb3172d04572f943464d78006c6cf172505f76
1e1eac1e1806c7ad1d9c32320018192eaeae18a112ad181933a11dbbbb2f29293fa0afbb28bbafbb373f3fa33f3f1229292929a60033bb221d1a1da00ca230a297a1010000a000008da000ae0000000000000000000000000000000000000000000000000000004747472e2e444747d0d0454c4352f94d6200dcdc5b5e41cf79
0000b8a218191d1ead1e1818ac18191d00acad0338b418192c1bac372d8f8f0f3506060f8f8f8f35810202020202b40604070707003c3c3c3d35a69b9ba63c3cbd1d3c0033ad3333b00fb3b33a3a000000000000000000000000000000000000000000000000007679d95071647676e4d0456e5b526edbdb006adcf900415f47
00001c3418199c009cb419341da3a31b1b1bb881811237370c0b1c0e2c041636902436360418180418868e0e8e0c973600000000001f1616bf1a1a9a9a1a1a1a1a1ebfa91d1a340c3f37b535b83800000000000000000000000000000000000000000000000000d974614161645876d9e46a72f952ea0000005d5b61715ae857
30001aa223239c009c00819793181900000007070704181988098a8a8a90b9171918181917181819180707070707070700000000000000000000962d2d2d2dbabb3a003c3c3c3c3c353c3c3f3f3f00000000000000000000000000000000000000000000000000d2f453c646d064d979794646fa525c716dea46cf6161c361d7
060000ae18199a9a9a9a199793183d2faf00001f992d3f3f1a1a9d1a3c2a000033acae00acae1eac00000000000000000000000000000000000096a6a8ad3438b8130036363c3f3f1a1a1a1a000000000000000000000000000000000000000000000000000000d2c35fd958d0d6fc7878363636c646cfcfc57676c646f846c5
1800000018199a9a9a9a193493183cac0033300d3f2e2e2e2c0c29bb971e1d1e3d28871eac1eae9daeaeaa000000000000000000000000000000bd9daf80973f1a1e1e001819120003120000000018171e1e1d379612009718181900000000000000000000000047f85261f9f9d6f8f453000000af000032103150f400000000
18aeae3023011c1d1e1e199793183c82292812b4b62c1e1e0606063e3c009c001f8d34bba200009c0000af00aabb00000000000000000000000096b61d8ca1050000a2ac3f24120003120000ac000117a11d38a696120097181819298b26000000000000000000d94152f478c6f8f8f856000000aeaeaeacf6cd2097ac000000
373b6a3737370d370c063406a601a3a3a381133c3c3c3dbbbc3cbc2e1d009cb3288f341ea01eaeaeaeaeae1d2f8500000000000000000000000096a18cadb697080033a00303122983981200ac93183c0c1c9f3c96120034f6f63422b418000000000000000000456e45455c7172005c6a0000000000aeacc7adadf4ac007200
07474707860f0635b8b8b83838a63c3c3c3c1a1a1a1a1a1a1a1a1a001c1e1a1a1a1a1a1a1a1a00000000001a1a1a3c3c0000000000000000000096a1b6b6b697961baea0971a1819868712bb0c931817861ca236961200971818191e8b180000000000000000006e005a6a5c4c45455b5b7172000072001c968d689773007872
26000000001c00001819003231301c00001c00001c00000000001c001c000092202020121c00247271507f7f3f3f96970000000000000000000096bfbfbfbf179296b2ae381d9819190407350605183c1e1e1d3c961200973f3f171200180000000000000000000000716c5d436e6e5a45414d5071c1505068cf8f1278715041
2f33002b291c2929041934068f371cb2301c00003434062900001c001c29bb20200f35069b1b24f8f878b87838a613bd0000000000000000000099b687818197861da0a0a02cb698199936363636363c00809c9796120034f6f634120016000000000000000000455d525b5d6c0072004547c6c545474747474747474747c646
07070786041b07060d3797363686260407862901b48505b8a9291a001a0185040799961200001a0000000000002b93160000001a1aa2001aa19799bfbf37bc97081a1a001c98a118193c3c3c3cb7b7a800003f979612009718181912009900000000000000000048005245455b5b410045717200727171507172000000000000
36363636991a173607070707363636363607070707073695178638b8380799163617043506383800000000002b37b4160000002e2ea61a1aa19796810606bf97961010b11b84a118190121213fa0b63f0000ae85961200971818191200980000000000000000004500526a43526c5c0045474750414747c3c347474d4d474747
3c3c3f3f3f3f3f3cb6223f3cf6f6f7968c3f3f9600000000090bf689f6f6088a000096000000973a3a00b506063d1316000000a11a1a1c1d1c979698b6bcb697968d02202020b43636b6282228b6ad283333339796120034f6f6341200980000000000000000006a69526ccf525c5c00ca7676524379794d4d4d4d4d4d4d4d4d
b6b6282828b63838b696b6a6268eb5b496f6f687000000000b0ba20ba1a20a06000096bb3abb977f7f1b7f7f7f7f7f7f0000000687af9719a185998787979698aba0982dad2d1836363f2128218181852eae068596120097181819120098000000000000000000444d525bd9525a6c004476d943434d4d4d4d4d4d4d4d4d4d4d
3c3c3c3d13bfbfbfbda6133c7ff697163d9d0996000000000b0b0c0b1c138b3e0000b68e8e8e9778817878810f780f780000001896009719a197173f3f3f8d983838383838382436360000002f1a1a1a80801f3696120097181819120098000000000000000000d95ec15279525d5c0057797943434d4d4d4d4d4d4d4d4d4d4d
f634133997983d3e99393934f60df63e0505050000000000899e9d9e9dbcbc1300008445b845840000000000000000000000002821000e8e340d3f0d8d2634970000000000000000000000000000000000000000011200971818341200980000000000000000007969485200525c5d5b47414d41474d4d4d4d4d4d4d4d4d4d4d
863d81133d06073d8f8f133da613813d0000000000000000000000000000000000000000000000000000000000000000000000181a1a191a1818a626a617979700000000000000000000000000000000000000009912000d971819120098000000000000000000c65b5b45475bcac84a76414d4d794d4d4d4d4d4d4d4d4d4d4d
__sfx__
01090000180201802018070180711806118051180411803118021180211802118021180111801118001180010000000000000000000000000000002b0502c0503005030031300212b01030020300103002130011
0013800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
010300000c57018570185701857018550185301852018520185100000018570185701855018540185301852018510185001850000000185701855018540185301852018510185101850000000000000000000000
0103001e0c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c10011100
310900001f70020700247002470024700247002470024700187001870018700187001870018700187001870018700187001870018700187001870018700187001870018700187001870018700187001870018700
01100000000000000000000000002a1002a10026100261002c10028100281002a1002a1002a1003010030100301003010030100301002e1002e1002e1002e1002e1002c1002e1002e1002e1002c1002c1002c100
0110000010100101000e100243000a1001830006100029003e00038000320002c80022000180000a00038b002ab0018b000ab0000b0038a002aa002ea002ea002aa0028a0026a0024a0024a0022a0022a0022a00
0102000020300143000c300316001c40027600164002960028600266002d6002c600296002460024600236002260020600206001f6001e6001c6001a6001760014600106000b6000660004600036000060000600
000213000f543085530a5500f570145700d7701476020770277702c7702c7052c7052c7602c700000002c74000000000002c71000000000000000000000000000000000000000000000000000000000000000000
9112002001612006120061201612026120461006611086110c6110961103611046100261201612016100061000610006100061000610026100161000610006100561103611016110361001610026100261001610
50020600123430d623036210d32119321253352930402305003000030000300003000030000300003000030000300000000000000000000000000000000000000000000000000000000000000000000000000000
00021300226432263312920179401b3301633113231101310e1210c1210a121080100703006030040300302003020010200101000000000000000000000000000000000000000000000000000000000000000000
52011d00143710d371043610136100350366602535025370366703667036670366503665036650366503665036650366503665536655366453665536665366453663536625366203661036610366003660000000
48020c003c6200e3330c22337623296233662325034062202762008220366000322039605012003b6000420008200042000820008200082000820001200366000820036600366000000000000000000000000000
50010d00193600d360063500334001440014300363003620036200562009610076100161009600066000260000600066000660005600056000460000000000000000000000000000000000000000000000000000
5a021b00183730537301373016700566002660086500f6500165006645056450064004630086300663004630036300762006625056250162503620036200c6100261304613016150160500605086050060408604
0a021a003e6301b6503e630376503c63037650376301c6503963032640386300d630366300263033630016202f620026202d620026202a6100361523615026101e61502615146050260032600326003260032600
0002000020343143430c333316201c43327620164332962028613266102d6202c610296102461024610236102261020610206101f6101e6101c6101a6101761014610106100b6100661004610036100061000610
0e011b003e6603d6603d6303b630386302f6302a93025930219301d9301b9301793015920113200f3200d3200c2200a2200822007220062100411004110031100311002010000100200000000000000000000000
000100002f9402b940299402894026930249302393021930209301f9301d9301c9301b930199201892017920159200c920159201092008920069100f91005910049100691007910089100791004910019100e910
4002170031630112202b6101123024620112201d620112201f620112301e6301122025620112202a620112202c61011210296101121026610112102261011200236001120022600112001d600112001a60012200
0a0116001276016770197701b76022760257602875000000000002c6702c6702c6402c640000003b6703b6703b6403b6353b6303b6203b6203b62500000000001370017700187001c70000000000000000000000
08020f001b63314651186411d610156632a750227701b760167500f7400a730087200572004710037100300000601000030060400600006010300004700037000070000700000000000000000000000000000000
030400003b6303b6313b6313963136631326312c621256211e62117621156211562115621166211762117611196111a6111b6111d6111f6112161123611246112561127615286152861529615296142961429614
31240020270151ba001e0151e810030141e0100a010160150f115000001e0151e810120151e0150d0140d01427015000001e0151e810030141e0150a0150d0151e01503000200152081003000200152501422010
3148000003114031101b810081140311403110120151b81003114031101b810081140311403110120151e810031141ba101b0150f810031141ba101b0150f81006114061101ba1012810081140811022a1016810
814800001682216822168221682208024080220a0211e02504124041150612122b240612406121081211402422a22128221aa22090221182211822118201d83121a221282223a220b822188260c52518a270c624
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
85240000010750d8542c81401850011450d8502c814018501004510850238350485006145128501e810168200207502854268140e850091450285026814028500607512850218350685008145148501582415823
cd2400202c8002c800191002c8002c8002c8000d1002c8002f8002f800191002f8002e0000d1002a0002c00028000288002800028800288000d10028800288002d0002e8002e0002f8002e0000d100270002a000
69240020149001b9001e9001b900099000d9001290014900149001c9001e90022900209000d90012900149000d900199001b90019900159001c9001c9001d9001e90004900049000490012900069001290021900
6b090020149230802008011080152a6152a60036600149133c6103c613080100801536615081140811008020149230310003100089133c6100802514914089133c6003c60009100149152a625090100911009115
692400200f1251052512525141250f1251052512525141251952519525198300d82015525155251c8341c8240d1251152512525141250d1251152512525141250a1250a5250e5250e1251212514525105250c134
791000000a2100a2100321003210032150321003410034100d2100d2100321003410033150321003412034120621006210034100341003215032100a2110a2120841008410033100331003212032100341203410
49100020143261b3160f3201b326143101b3100f3201b3160f3201b3100f3261b3160f32011310123200d3200f3200f3101632016316163200f3200f32014320140111422014326143100f3101b3201232011320
491000000f300123000f300123000f3001b3000f3000f3000f300143000f300143001b3000f3000f300113001d3000f3001d3000f3001d3000f3001d3000f3001e3000f4001e3000f4001e3000f4001e3000f400
5910000020326273161b3202732620316273101b320273161b326273161b326273161b3100b3201e3101d3201b3251b3252232022316253200f3301b32120320200200f33020320203201b310273201e3201d320
591000001b3261e3161b3201e3261b310273101b3201b3101b326203101b32020326273101b3101b3201d3202932612320293261e320293261e320293261e3202a326143202a326203202a326203202a32620320
312000000a1140a1100a1100a12003923039160f9170f9240c1240c1200c1200c1200c1200491600120049160b1100b1100b1100b1100b110110200b110120200d1200d1200d1220d12212917121201491414122
311000000b1000b1000b1000b1000b1000b1000b1000b1000490004100049000420003900039000390003900069000310006900031000d1000d1000d1000d1000f9000f1000f9000f90012100121001210012100
791000200332003410033200321003210032200f415034250332003410033200321003215032100391003910064200f4100642003210031210302106020031300432012420043200621006410124100631006310
79100000049000b400049000320003200032000340003400043000b400043000320003200032000340003400064000f9000640003200032000320003200032000730012d000730006d000620012d000630006300
0120000022125220141601027015250250d0241901025015240250c024180100c010230252301417010019142202522014160100a0101e0251e0140601012010200252001408010080101c0250b9141c0100d914
4b1000201d3233500015313214133e6201d621153133e6101531300300214132d600214130f3243c6250f322153230030039625213133e6101d621396253e6102131300300214231532338620386243862538620
812400002cb35149151412514915149150891514125149151791533b341b12517915179150b9151b1252eb3519915119151912511915119151191519125119151e91504915049150491512915069151291515915
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
01 1a1f305f
00 1f30317d
00 1f30317d
00 31301a62
00 2d301f7f
00 2d303d5f
02 2d313d5f
00 41424344
00 41424344
00 41424344
01 327c5f5f
00 327c5f79
00 3b7c5f79
00 39797c7c
00 377c3973
00 397c5f75
02 397c5f76
00 41424344
00 41424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344

