pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--
--

menu_state = 0

all_level_slots = {}

cursor_pos = 1

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
	poke(0x5f5c, 8)
	poke(0x5f5d, 2)
	
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
	
	for j=max(y_off\mm_scale,12),min((y_off+128)\mm_scale-1,47) do
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
			
			local ntt_mempos, num_ntts = lvl_info[16],lvl_info[17]
			local ntt_map_x,ntt_map_y = ((ntt_mempos-4096)%128) * mm_scale, ((ntt_mempos-4096)\128+32)*mm_scale
			
			
			local d_col = i%12 + 4
			
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
		
			rect(ntt_map_x,ntt_map_y,ntt_map_x+num_ntts*4*mm_scale,ntt_map_y+mm_scale-1,d_col)

		
		end
	end
	
	
	fillp(0b1101101101111110.1)
	rectfill(0,48*mm_scale,128*mm_scale-1,128*mm_scale-1,5)
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
		y_off %= 40*mm_scale
	
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
		
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, (bg1_loc%16)*8, j/8+1, 1/8, 0)
			tline(94-32,yval-s\2+2+j,125,yval-s\2+2+j, (bg2_loc%16)*8, j/8+1, 1/8, 0)
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
	rectfill(-256,sludg_l,1024,2048,sl_c)
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
	pos,flip_x,flip_y,e_spr,s_x,s_y = pos or entity.pos,flip_x or entity.is_left, flip_y or entity.is_up,entity.sprite,entity.sprW or 1,entity.sprH or 1
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
	rect(x_l_l, y_l_l, x_u_l, y_u_l, 8)
	
	local pl_x,pl_y = loaded_level_info[3], loaded_level_info[4]
	
	print("pl" ,pl_x, pl_y-8, 12)
	
	rect(pl_x-2,pl_y-2,pl_x+2,pl_y+2,12)


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
					
					rect(-8*4,-32*4,(255-8)*4,(255-32)*4,3)
					
					s_text = j .. ". e:" .. entity.template .. " x:"..entity.pos.x .." y:".. entity.pos.y .. " x:" .. entity.extrainfo_loc
					
					if entity.txtB then
						text_box(unpack(split(entity.txtB,"⬇️")))
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
	
	if (#lvl_entities >= lvl_ntt_limit) add_col,add_fill,icon = 3,13,"\^:4028183e0c0a0100"
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
		entity.pos.y = mid((0-32)*4,entity.pos.y, (255-32)*4)
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
	lvl_bg1_pre = {peek(loaded_level_info[14],8)}
	lvl_bg1 = {}
	
	lvl_bg1[1] = lvl_bg1_pre[1]%16
	lvl_bg1[2] = lvl_bg1_pre[1]\16
	lvl_bg1[7] = lvl_bg1_pre[2]%2
	lvl_bg1[8] = lvl_bg1_pre[2]\2
	lvl_bg1[3] = lvl_bg1_pre[3]-128
	lvl_bg1[4] = lvl_bg1_pre[4]-128
	lvl_bg1[5] = lvl_bg1_pre[5]-128
	lvl_bg1[6] = lvl_bg1_pre[6]-128
	lvl_bg1[9] = lvl_bg1_pre[7]-128
	lvl_bg1[10] =lvl_bg1_pre[8]-128
	
	
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
	lvl_bg2_pre = {peek(loaded_level_info[15],8)}
	lvl_bg2 = {}
	lvl_bg2[1] = lvl_bg2_pre[1]%16
	lvl_bg2[2] = lvl_bg2_pre[1]\16
	lvl_bg2[7] = lvl_bg2_pre[2]%2
	lvl_bg2[8] = lvl_bg2_pre[2]\2
	lvl_bg2[3] = lvl_bg2_pre[3]-128
	lvl_bg2[4] = lvl_bg2_pre[4]-128
	lvl_bg2[5] = lvl_bg2_pre[5]-128
	lvl_bg2[6] = lvl_bg2_pre[6]-128
	lvl_bg2[9] = lvl_bg2_pre[7]-128
	lvl_bg2[10] =lvl_bg2_pre[8]-128
	
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
		ey = (ey-32)*4
		
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

	pal({peek(loaded_level_info[12],16)}, 1)

	-- defaults
	mod_tabl(_ENV,"time_c,t_enms,t_e_clear,t_tr_collected,t_trinkets,lvl_prevmus/0,0,0,0,0,0,0")
	mod_tabl(_ENV,"lvl_enms,lvl_e_clear,lvl_e_req,x_u_l,y_u_l,trn_bnc,trn_slp,grav,lvl_tr_collected,lvl_trinkets,sludg_l,sl_c,sl_smth,sl_vx,sl_vy,sl_dmg,alert,l_time_c,sl_r,sl_h,sl_spd/0,0,0,0,0,0.2,0.75,0.22,0,0,1024,6,0.9,0,-0.16,0.6,false,0,0,0.04,5")
	
	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1
	x_l_l=l_border_x
	y_l_l=l_border_y
	
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
	poke(loaded_level_info[14],lvl_bg1[1]+lvl_bg1[2]*16,lvl_bg1[7]+lvl_bg1[8]*2,lvl_bg1[3]+128,lvl_bg1[4]+128,lvl_bg1[5]+128,lvl_bg1[6]+128,lvl_bg1[9]+128,lvl_bg1[10]+128)
	poke(loaded_level_info[15],lvl_bg2[1]+lvl_bg2[2]*16,lvl_bg2[7]+lvl_bg2[8]*2,lvl_bg2[3]+128,lvl_bg2[4]+128,lvl_bg2[5]+128,lvl_bg2[6]+128,lvl_bg2[9]+128,lvl_bg2[10]+128)
	bg1_edited,bg2_edited = false, false
	
	-- entity info
	for i=1, loaded_level_info[17] do
		local entity = lvl_entities[i]
		local e_t,e_x,e_y,e_ex = entity.template, entity.pos.x,entity.pos.y,entity.extrainfo_loc
		e_x = e_x\4+8
		e_y = e_y\4+32
		
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


-- the 8 bg slots are 4 y levels below these
bg_slots_pre = split"4192,4200,4208,4216"
bg_slots = {}
bg_slot_index1 = 1
bg_slot_index2 = 1
for i=1, #bg_slots_pre do
	add(bg_slots,bg_slots_pre[i]+128*4)
	add(bg_slots,bg_slots_pre[i]+128*5)
	add(bg_slots,bg_slots_pre[i]+128*6)
	add(bg_slots,bg_slots_pre[i]+128*7)
	
	add(bg_slots,bg_slots_pre[i]+128*8)
	add(bg_slots,bg_slots_pre[i]+128*9)
	add(bg_slots,bg_slots_pre[i]+128*10)
	add(bg_slots,bg_slots_pre[i]+128*11)
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
		
			if l_set_cursor_pos == 12 then
				local valid,index = find_in_arr(loaded_level_info[l_set_cursor_pos],palette_slots)
				if valid then
					index = ((index + l_add - 1) % #palette_slots) + 1
				else
					index = 1
				end
				loaded_level_info[l_set_cursor_pos] = palette_slots[index]
			
			elseif l_set_cursor_pos == 14 or l_set_cursor_pos == 15 then
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
				pal({peek(loaded_level_info[12],16)}, 1)
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
			
			lvl_bg1[1] %= 16
			lvl_bg1[2] %= 16
			lvl_bg2[1] %= 16
			lvl_bg2[2] %= 16
		end
			
	end
	
end

function draw_bg(arr) 
	mod_tabl2(_ENV,"b_img_indx,b_pal,b_sc,b_prlx,b_ofx,b_ofy,b_wx,b_wy,b_timx,b_timy",arr)

	local bg_sampl = bg_pals[b_pal+1]
	pal(split(bg_sampl..","..bg_sampl..","..bg_sampl..","..bg_sampl), 0)
	
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
		print_outl("only edit if\nyou know what\nyou're doing!",75,144,3,6)
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
		elseif i == 12 then
			mx = (dat_str-8192)%128
			my = (dat_str-8192)\128
			
			dat_str = dat_str .. " (" ..mx .. "x " .. my .. "y)"
		
		elseif i==14 or i==15 or i==16 then
			local mx,my,ind
			if (dat_str >= 8192) then
				mx = (dat_str-8192)%128
				my = (dat_str-8192)\128
			else
				mx = (dat_str-4096)%128
				my = (dat_str-4096)\128 + 32
			end
			
			if i==14 or i==15 then
				ind = bg_slot_index1
				p_col = 15
				if (i == 15) then
					p_col = 11
					ind = bg_slot_index2
				end
				
				dat_str = ind .. " (" .. dat_str .. " " ..mx .. "x " .. my .. "y)"
			else
				dat_str = dat_str .. " (" ..mx .. "x " .. my .. "y)"
			end
			
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
	
		local bg_sampl = bg_pals[lvl_bg1[2]+1]
		pal(split(bg_sampl..","..bg_sampl..","..bg_sampl..","..bg_sampl), 0)
		
		
		
		draw_pal(139)
		pal(0)
	elseif l_set_cursor_pos == 29 then
	
		local bg_sampl = bg_pals[lvl_bg2[2]+1]
		pal(split(bg_sampl..","..bg_sampl..","..bg_sampl..","..bg_sampl), 0)
		
		
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

--[[
function write_pal(num,addr)
	local tabl = split(palettes[num])
	poke(addr,unpack(tabl))
end

function write_pals()
	write_pal(3,8192+80)
	write_pal(4,8192+80+128)
	write_pal(1,8192+80+128*2)
	write_pal(5,8192+80+128*3)
	
	write_pal(9,8192+96)
	write_pal(10,8192+96+128)
	write_pal(11,8192+96+128*2)
	write_pal(13,8192+96+128*3)
	
	write_pal(8,8192+112)
	write_pal(6,8192+112+128)
	write_pal(7,8192+112+128*2)
	write_pal(12,8192+112+128*3)

	cstore(0x1000,0x1000,0x2000)
end
]]

palette_slots = {}

for i=0,2 do
	for j=0,3 do
		add(palette_slots, 8192+80+16*i+128*j)
	end
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
			if bcheck(loaded_level_info[11], 1<<j) and fl&0b00111111 != 63 then
				fl &= 0b10111111
			else
				fl |= 0b01000000
			end
			
			poke(addr,fl)
		end

	end
end

-- todo add rope modifiers that also define (add) rope
-- add enm=false
ntt_extrainfos_pre=split([[/
procalert/true
next_e/11
rX,rY/16,0
rX,rY/-16,0
rX,rY/0,-16
rX,rY/-13,-13
Btyp,rope,ai_a,rngN,rngF/5,nil,_V_AIAfllw,35,70
gun/9
boss/true
rope,rX,rY/6,76,-20
break_func/_V_d_load_next
is_left/t
is_up/t
is_left,is_up/t,t
rX,rY/-15,15
txtB/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️-30⬇️44⬇️42⬇️2⬇️1
rope,rX,rY,rope_e/8,-45,-8,d_o➡️2
txtB/\faidk⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1
txtB/\fastaff is advised\n to only \fcgrab the\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1
decal/\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!\*f \*f \*f \*5 \^h\n🅾️\n\n\|c \-e+\n\n\|c\-f\^:10387c1010100010
decal/\f2\^o0ff\^:00008064320f0204 \^h ❎\|e\n\ng\|fr\|fa\|fb  \|e\^:0000070c90a0c0f0
decal/test
actF/600
actF,rngF,rngN,ai_a/600,160,25,_V_AIAfllw
gun/29]],"\n")

-->8
-- data
#include dropkicks_inc.p8:B

__gfx__
00000000555555545555555444444444aabbbaa900000000e9a8abeabaeae9abbe8448eab9b9b9b9ebebebebbbbbbabb44444445545b45b477777d7877787778
00000000555555445444444455555554b999999800000000e9e8b9e999999999bb8448baa89898988ae9e98a8b8998b84454545554a5a5ab7dd78788ddd88d88
00000000544444445444444454444444b999999800000000e9e8a999e9e9e9eebebeebea99a999a9aabaaba998b88b89454545454b5a4aa57dd788787877d888
00000000555555445444444454445454b9999998000000009998a9e999999999b98bb89aaaaa8aaaaaeaaea9449bb94444545455a9b45baa7d78ddd8d8d888dd
00000000544444445444444454454454a999999800000000e9e89999999999e9b98bb89a9998a9998aaaaa98449bb944454545459bba99a97788ddd8778d7788
00000000555555445444444454444454a999999800000000e998a9e999999999bebeeaea998a9999aabaab9898b88a89445454559a89aa9978d78dd8dd888dd8
00000000444444445444444454444454a999999800000000e9e8a9e9999999e9bb8448aa98a99999aaeaaea98b8998a845454545a9aa99a97dddd8d878dddd88
0000000055544444444444444455555498888889000000009988a99999999999be8448ea88888888baa99aa9aaaaaaaa555555558aa88988d888888d8dd88888
44444444555555552222222211111111aaae9999999999eaabababab00000000339993dd8444445a55555555ebebebeb54005554444444445555555589889988
44444444555555552222222211111111a9999999999999998a8a8a8a000000003d999dd38444454a500000058a8a8a8a540550545555555554444445489aaaa9
44444444555555552222222211111111bbaaeaae99999aaa8888888800000000dd3999338444444a50000005bbbbbbbb54550054444444445500005544899999
44444444555555552222222211111111baae9e9999999aee8998999900000000d339993d8444444a5000000599aaaa9955500054555555550550055044489999
44444444555555552222222211111111a9999999999999998888888800000000339993dd8444444a50000005888aa88855500054444444440055550044448998
44444444555555552222222211111111baeaae9999e9a9aa88888888000000003d999dd38444444a50000005888aa888545500545555555500055000554448aa
44444444555555552222222211111111b99e9999999999ee8888888800000000dd3999338444444a5000000588aaaa8854055054444444445555555544444489
44444444555555552222222211111111a999999999999aaa8888888800000000d339993d9aaaaaaa55555555eeeeeeee54005554555555554444444445554448
44444444444444444554455455555555baaebaae9aaee99ebbaebbbabbebbbbeaf7ff7fa99888989ba9bba9b554555453333333d7777777d88888888babbbbba
555545554555445544554455545544559999999999999999baaebaa9aaebaaa9f777777f88888888aa9bba9b554555453d33dd3d7f77ff7d89999999b9aaaa9a
44444444444444445445544554455445aebaaeaaee999eaabaaea99999ea99995f7ff7f599999999ba9bba9b55455545333dd33d777ff77d89899989babaabaa
554555455445544555445544554455459999999999999999aaae999999eeeee9f777777f88899988ba9bba9b5545554533dd333d77ff777d89999999aaaaaaa9
44444444444444444554455455544555baaeaaaeaaaeaa9eeeee99ee99999999bf7ff7fb99999999ba9bba9b554555453dd33d3d7ff77f7d89999999baaaaaa9
455545554544455544554455545544559999999999999999999999999999eee9f777777f99999999ba9bba9b554555453d33dd3d7f77ff7d89899989aabaaba8
44444444444444445445544554455445aeaaaeaaee9aaeaa9999999999999999bf7ff7fb99999999ba9bba9b554555453333333d7777777d89999999a9aaaa98
5554555455545554554455445555555599999999999999999999999999999999bbbaabbb99999999ba9bba9b55455445dddddddddddddddd8888888888888888
05000505050000050000000500000005b8bbbbbbbbbbbbbb9999999999999e99bafbbfab99999999aa9bba9bbbbbbbbb999999995544444499999898babbbbba
050005050500000555555555000000558bbeeebeeebeeebe9999999999999999af7ff7fa99999999ba9bba9bbbbbbbbb9999999955444455999aa984aaa999a9
55005555050005050505050500000505be899989998999899999999999999e99f777777f99999999ba9baa9baaaaaaaa999999995544444499999844aaaaaaaa
55500555050005055050505550000055be999998888888889999999999999999bf7ff7fb99999989ba9bba9ba99aa9aa99a999995544444599888444aaaaaaaa
05000505050005050505050505000505be9999988beeeeb89999999999999a99f777777f88888888ba9bba9b9999999999a9aa9a5544444499984444aaaaaa9a
05000505050005055555555555555555be9999988899998899999999a9eaaaa9af7ff7fa99989999ba9bba9b99999999aaaaaaaa55444455aa845554a9aa9a99
05000555550055055555555555555555888888888b9999b899999999999a9999f777777f88888888ba99aa9999999999bbbbbbbb554444449844444499999999
5500050555000505555555555555555588889998888888889999999999e99aaa5f7ff7f5888888889988998899999999bbbbbbbb554444458544444488888888
0f0000005554454455444554555444555b9b995500000000773939333339393390930000888888883733333399900999ddddddd600dddd00d8d7778d77777778
0d0000005455444445544544544545559bbbb9bb0000000073733333333393339993d09088888888737333739373333366666fd60dddddd0887dddd87f8dddd8
6d666000444445544454554445444554bbbabb9b00000000373333733333733300933d988888888837333337373373336666f6f6d8d66dd88f8ddd8f78f8ddd8
6d666600554555445444454545445544abb9ab9a000000003333333333373333039dd88888988e8e33373333833333336ff66f66dd6ff6d8787888f87d87888f
dfdffdfd5445545444445454445454449ab9a9aa0000000033333333333333733d93d9908e98eeee3333333393838383f6df6666dd6ff6887d877f887d877ff8
dddddddd445544455544544444444444aa9a9aa9000000003333333337333737ddddd0808e99e9ee3838383808883838fd6f6666ddd668867d8788867d878888
66666600445444445444554455444445999a9a990000000039333339393333790803d9808999999e89898989398989736ff666660dd888608d8f88687d8f8dd8
66666600444444554444454454444455999999990000000093939393939333930893d800e999999e98989898380099336666666600886600d88f868dd88f8888
454445450000000000000000000000009899999999999989baabbbabaaaaaaaa8e999e8e9a5a959a545450553733333305445050aaaaaaaa0000000054999999
54544444000000000030000000000000899999999999999898899999a000000a88999e889454a49a550505057333373305045550a000000a0555555054499a99
54444454008880000036600000333000889999999999998888888888a0000a0a88999e884954a494405505553333333355055500a0000a0a05555554445999a9
444445440c8d8000003fff0000676600588999999999998988988899a000a00a88e9998895999994400500543939393905454505a000a00a5555555445494999
4444444400cdd000006660000036d600589999999999988988888899a00a000a88e998884549449a505505549393939305554555a00a000a5454545445494999
44454444008000000000000000300000899999999999998599888888a0a0000a8889988849a9594a455005508989898900454500a0a0000a4545454555454449
44445445000000000000000000000000899999999999999899888898a000000a88e999889aa49a59505055008888088805454500a000000a5454445555455459
45444444000000000000000000000000999999999999998988898888aaaaaaaa8ee99e889a44aa59550554050808008004454550aaaaaaaa0404040455555454
454455455454554455545554555455549bbb99a99ba999995b5bb5b55b55bb5b44544f544a54ba5aba9bbab94545545500000000005550000000000570000000
54545454455454545554555455545544bbaaaa99ba999999bbbbbbbbbbbbbbbbf45faf54ab94aa4ba99babab4445545505555500444455000000000740000000
55444544545544545554555455544454aaaaaa9b99999bb9abbbaababbababbb5f5fafa4a9b9a99aba9b9ba94545544500044555555552500050007544000400
454545454554545544444444444444449aaaa9999999baa9ababaa9aabaabaabafaaffaf99aa9a9aba9a9ba9454554450444544c5cc444200007505994044000
54545444545545545554555455544444b99999bbbbb9aa999a9aa9a9aaa9ba9abff8fbf9999a9a9aba9b9ba94544445544c445544444c4400005596666944000
45454445454544555554555455544454aaa9bbbaaa99999aa99b9aa9a9a99a9afaf8f9bf99a99a99aa9b9a99454554554c4c4544454c4c400000965666690000
45455454454544545554555454444554aa99baaaa999ba9aa9ab9a9aa99a99a9baffbaa999999999ba9b9ba94545545544c445000544c44000756566f6664400
54445454554554554444444444444444a9999aaa999aaa9999a9999a999999a9a8fba88899999999ba9baba94545445504440000000444005759666f6f669444
50450405000500500000000000000000bbbabbbabba9bba90000f00099a99999f44b95af99999999ba9b9ba98888888854545454aaaaaaaa75596666f6669444
44540455050450450000400400000000baa8baa8baa8baa800f666f09a99a9995fa9fff5a99999a9ab9baab88888888854555455a000000a0055666666464400
04545454045540055054004005004500baa8baa8a998aa980f00600f99999a995ffb95aa99899a99ba8a8bab8888888854444444a0000a0a0000966664690000
54544044054040540405005454045040a8888888988888880f66666f9999a9a94aba9f5f99599999bb8aab8b8ea88e8845555555a000a00a0005596666944000
55454540454540450545050445055405bbbabbba88b889880f00600f9a99a9aaff5994f5a9895999bababa8aaeaaaeee44444444a00a000a0005505994044000
54504545505445554545454540050454baa8baa88baa898800f666f0a99999a95559ffaa5a858989a9baba8b9e999e9e44444444a0a0000a0050005544000400
54555045545445545405554554505455baa8baa8aaa9898900006000999a999af4b9f44459885989b9b998899999999e55545554a000000a0000000540000000
44545445045404555554555554545545a888a8888a98998903d666d3999999994f599ff488585885b99bab899999999944545454aaaaaaaa0000000540000000
81910808080808c3c3c308080842080808080808c98142d1d14269f8d15bf8f80808086363636399a17163707070707a39200899084a4a6078fa79917a586250
50525a69424223c113b148787291181212f36b8a2808081af9111111111111111111727ac1c172443425b59d25a5c6084446952c3c87642c1664543c2cd41c8d
923308b29233929240704360f87392230323089243436060d1c869cbd1cb7942080808826bf9f3f3f3c3496b22f9c37a0808087308084a81690879917a7971f3
7373f369429b01fa213a3ad072636b8222820a12f33333337960e4020260e4020260997e72c1729de614259725d5c50875979f1614d497d4c46754243cc42c7d
7070706840b17060d073796363686240706892184b585042d1a89bfb9bf979420808088282526b6b6b8383396b6b6a684b781818431839821208e0e843d0f3d0
d8d0624379baba0aa228da8163638312821218c0c0c2e26058707070707070707070637ac5c172979684251f25c5d5b5741c143c14ccd43cd4979f3c1cd41c7d
6363636399a1716370707070636363636370707070706342dbb1604242685842080808c3c3c3c3c3c3c3c3d36a31c3422960606060395a81a1a191a181816a62
626a71d331838383838383426363080808f2a1a10ada08f163636363636363636363997a87c5726cb5b55474b5ac8ca4676c14149787145414145c145c54145c
40d8621070ea221040bad240d0d632112242825100000000000000000000000001e0b61001e3f5107043c51060b4651060c43310000000000000000000000000
02a59281c1d61391e1055410c1c262910204728100000000000000000000000000000808080808087710282808ca08083d102828050a080814102828050ae9d7
4013e2207042922040d4827050c7624022f4826170f6831000000000000000002161a21021b7a210f0d632100121b21001c4131060c292106025821000000000
d143151042d6b280d147944002c3d210d1b6c510d142b510d1a4d51042130580261028280b4918084d0028eb0a0c08083e1038480a8a0808161058480a66daa7
50b1d350f0d0f2104094532070f3023070b402104296538000000000000000002143a3305062e18021c7d13001d2f21070a2b11042e5c1800000000000000000
0292a31002d43320c1d36310c1d5b410024623200237f310c123841000000000201028280b49f7085020282b080808a83e10e70a0a0c0808273038080866e917
42c2d18042a2338042f0d18042c1542100000000000000000000000000000000610581a001431310000000000000000000000000000000000000000000000000
717203105093644040f156606011243040b1f6600000000000000000000000000000080808080808821018080808080836102889bc0c0808273048880a4cda26
4242b54042c352407026c22070c5823070d474104284c4805054368042b29280e132d2c09141c11091c3c11070c29510d1728810b0325410d052343100000000
1282142002b67281707632819141e1109162e110000000000000000000000000100048880c280808821018080808e7083e10288a086d08082710384808e8e908
b0c1721080c463a0f1f263108026f21031d0c1a112c2151042b5838061873210b122b350b1216450b11266100000000000000000000000000000000000000000
02846310f1b2151012b4a28112b425100133d4105056d34012f71310f148a210171038185ae80808801018280808b70831102809084b0808271058880829cb08
5056c28070e3c2106032d20160b48210000000001223531012c2532061249210b1c45510c1c25510c1f2f21002433320f0417210b141a2100000000000000000
80c1c42080c3c42012d3d110f1615210f1235210000000000000000000000000130058888388080820102838082c080800000808080808080000080808080808
d091334121a3233070f4b2102126231000000000000000006253821000000000b132d401c1323310c1c5e2100254d21000000000000000000000000000000000
31d08110f14133a112a35520f1837310c1e1b2100000000000000000000000000a10588805870808000008080808080800000808080808080000080808080808
000dd000fd666ddf0000000d066dd66000ddd60000ddd60000ddd6000066066006066600006066000000000000022000000cc000000000000000000000000000
0dddddd0d66d666f00000fd06d6666df0dd666600dd666600dd666606060660006666066060666600002200002f77f200c3773c0000000000000000000000000
6ddddddf6666f6f06666fd0066d66d66f66f66f6fdf66f6fdf66f66f666066666066066066066006002ff2000f7777f0037dd730000000000000000000000000
66dddf686fddddf0f667777766d66ddf66666666666666666666666606666006660666666666666002f77f2027777772c7dccd7c000000000000000000000000
666f688f6fddddf0f66ddddd66dffd6666666666666666666666666660066660666660660666666602f77f2027777772c7dccd7c000000000000000000000000
66688f68666666f0ff66df0066dffddfff6666ffff6666ff77666677666606660660660660066066002ff2000f7777f0037dd730000000000000000000000000
066f6860d66d666f06000df0d6d66d6d77f66f7700f66f00007667000066060666066660066660600002200002f77f200c3773c0000000000000000000000000
00686600fd666ddf000000dd0dd66dd00770077070000007000000000660660000666060006606000000000000022000000cc000000000000000000000000000
00000000000333000000000002220000000000000000000000000000000000000000000000000000abbabbab0000000000000000000a99990000000000000a99
00000000233333300222200022222200000000000000000000666600000000000000ddd00ddd0000baabba8a00000000aa900000000a99999999000000aaa999
000000223333333333322222233322220044400000000000066666660000000000dddd6dd6dddd0089a88b8800000aaaaa99000000aa999999999999aaa99a99
0002222233232223323322233322320000444400000004406666666666000000dddd886dd688dddd88a899b800aaaaaa9999900000a99999999999999aaa9999
0222222333321232222223332122130000444400004404446666666666660000d866d86dd68d868d8a8899a8aaaaa999aa9999000aa999a999999999aa999a99
2233323323212122122233321211122004444400004404446666666666666600886f6d6666d6f688aa988aaaaa999aaaaa9999900a9a99a9999999999aaa9999
23333332322333312111332121111122444444004044044466666666666666660086f66ff66f6800a8a88a8a99aaaaaaaa999999aa9a99a999999999aa999a99
333323222133333311133212112221124444444044444444ddd6666666666666000d6f6666f6d000a8a88a88aaaaaaaa99999999a9aa9999999999999aaa9999
333231211333323211132222000000004440000000000000dddddddddddddddd00ddd660066ddd0097393979aaaaa999aa999999a9aa999999889889aa999a99
222212333333222112322211000000004444440000000000dd666666666666660d8d68600686d8d073739737aa999aaaaa9999999aaa9999989898989aaa9999
1212332332321212222121110000000044444444000004406d666666666666dfddd8068668608ddd3739397999aaaaaaaa9999999aaa999998899988aa999a99
11233222232121221211132200000000444444440004444066d666666666dfdfdddd686ff686dddd93939393aaaaaaaa99999999aaa99999999999999aaa9999
133222122222112121113221000000004444444400044440d66ddddddddfdfdf8ddd086ff680ddd839793939aaaaa999aa999999aaa999a998899988aa999a99
3321211122111211111212110000000044444444440444400d6f6f6f66dfdf0080ddd086680ddd0897373733aa999aaaaa999999aa9a99a9989898989aaa9999
12121111111111111121211100002220444444444444444400dddddddddf00000606d000000d60803979737999aaaaaaaa999999aa9a99a999889889aa999a99
112111111111111111111111222222224444444444444444000d66666d000000006066000066060093939733aaaaaaaa99999999a9aa9999999999999aaa9999
0022222201011111111111110000000000000000010000000000000010101010111111110000000000000000a88000000000000000bb00000000000000000000
02222233101011111101011100333d000ff00ff00060106001000636000000001111111100000000000000000800000000bb0000bbbbbb000000000000000000
2222333311010101011010110373dd800f0000f00636000000000666101010102121212100f0000000000000a080000000abb000abbb88000000000000000000
222333230100001010110110033ddd800000000010000010100010000101010111111111000f0000000000000800000000a88000aaa888000000000000000000
23322222001000000101000103ddd88000000000001000010010001010101010212121210000f00000000000000000000aa88000aaa880000000000000000000
3321212100000000001000000ddd88600f0000f00000606066366001010101011212121200000ff000000000000000008aa80000aaa880000000000000000000
121211110000000000000000008886000ff00ff001066666006010061111111122222222000000ff00000000000000000aa00000aaa880000000000000000000
1121111100000000000000000000000000000000000013000100000001010101121212120000000f00000000000000000a000000aa8800000000000000000000
000000003d0000d30033330000dddd00000000220337333000d3ddd00dd3700000ddd0000000000000000000000a080000aa88808a8000000000000000000000
00333c00d730033803733dd00dddddd02222225237333337033333ddd33777300ddddd0000000000000000000000bb0000aa8880080000000000000000000000
037cccc003dddd30373dddd8dfdddddf25a2aa203333333d0d333880dd7773d00088800000000000000000000000abbb00a8880000800bb00000000000000000
03cccc8000d7c80033dddd88dd7dddfd02222220d333dddd033c33dd377cc3330ddddd0000000000000000000000aa8800a88800080abb800000000000000000
03cccc8000dcc80033dddd86ddd77fd802aa2a208d888888033c3388777cc33308dddd000000000000000000000aaa8800a88800000aa8800000000000000000
0cccc88003d88d303dddd886ddd7dd8602222220080888800d333880d73333d0008880000000000000000000000aa8800aa88000000aa8800000000000000000
00c88800d33003380dd888600ddfd86002aaa2520008008003333388d333333008dddd000000000000000000000aa8800a888000000aa8800000000000000000
000000003800008300886600008f8600252222200000000000d388800dd33000008880000000000000000000000aa8800a8800000000a8000000000000000000
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
88080808010001010101010188810303088888880101010001010801088808080808080801010101410101088c8c81810808080801018101410101010188888100080808010011110101111100002323080000000101010001010811080008080808080801010101410101080808000008080808010100014101010108000000
0000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010001000000000000000000000000001100000001000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d400000000d3c0c1c2c30071707173727371730000000000cbcc0000fbfd00000000ec00e90000e9000000e7e7e7e7e7e7e7e7e5e6e6e5e6e6e5e600000000000000008f0f068e8f0007820288080c0d020a8e8a870c018300070081838b0e8d818903818c06008100070082020e0c0d028700
cfce00dbdc00dd36c4d5c5c4c510c4c5c0c1e0d1d0d1d0c36160417061616060d5e7cdcee7dbdce7edfc00ecfb00ecfd0000e90000000000e8e8e8e8e8e8e8e8e5e5e6e5e5e5e5e500000000000000008f0f06808200078288088f0c0d880a8e0f070c858d0007008004090e0d82898f020e068082000782888e0f0c0d880a82
df36d5dbdccfdd361010101010101010d0d1d2131313d2d2604243414342426010e8dd36d4dbdce8fbfd00edfcfd00000000000000e900e91212121212121212e5e6e5e5e6e5e6e600000000000000000d06868d0d0007008181018c8581098d8082068082000781858d0d0c0d820800888e068082000782880e0f0c0d880a02
df3607dbdcdfdd361010101010101010e1e1e2e1e1e2e2e166666766676767661012dd3610dbdc12fc00fbebec0000ed000000e9000000001212121212121212e5e5e6e5e6e5e6e50000000000000000060786008100078202020e0c8502090d89090688080007028280000c0d820a0880858680850007820d06060c8d0d0800
ccddddcc012020208a464746b8202020042727264746070641202020676667661b0a1b1b005c00015e0a5e0bdc08881c20a0a020020201022121212120202020717071719a9a9a9a60101010202020243636373e0000000014f676766667143677253636363614155b4a5b5b001c001c001c001c1e415e415e415e5e1f363636
988989982020212047012020b8032003143636154607060741410303767676760008005c005c001c1e088008dc08881c02070702e0e0e0012222222202020202617060709a9a9a9a601010102020202436373e010000000014f676767676143676f936f936f914158b8b8b8b001c001c001c001cc01cc01cc01cc0c03d1f3736
985455982120202046200210b8012001143636370707070727262627f6f676761e081e5c0b0a0b0b0b0a5e0b1e0a8a0102393902e0e0e0020202020203cf02ce60636160020202026010101074747424363e3d210000000014f676767676143776d914d925d914151e011e1e5b4a5b5b000100015e415e415e015e5e02105f37
985455984747474747201010b8202020253636360707070737363636f6f676760008005c0008001c00081c08dc08881c20a0a020e0e0e002ce02cfce2627262663626163a0a0a0a060101010757575243e2102200000000014f67676b9b9041576e925e936e93715001c00008b8b8b8b001c001cc01cc05cc0c0c0c03d1dbd5f
e0e0e0e002e0e00202020202101010102464652501d0d03c203d2002187655980223230200000000060706002b2b2b2b1ee1e0e1e0e1e178e0e0e0e0001c001c000000000000000000000000000000002020202020202020767676766a6a6a6a2103212036377677000000000000000035343434041d1d022f3f3f2f16161616
e0e0e0e020e0e0201ae0e01a2020202025646524222203a2aaaa2a2a18765598231d213d72723232060706002b2b2b2b30e0e0e1e1e0e178e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf76767676babababa62626262373976760000000000000000467676762523233d220c0c342e2e2e2e
e0e0e0e020e0e0201ae0e01a21202020256465251d1d11bdeaea2a2a18765598231d033d424242021b1b1b00212020211ee1e0e0e1e0e0781e011e1ee0e0e0e00031c32b30313031000031000000000002026626470706077676767602020202262726272001b9b941323232323232324676767624f5f5f434350c3439393939
e0e0e0e002e0e0020202020202cecfcf246564253b3b3b3b7a7a3a3a187655980202020261606060409c400003202120001c011c202121b800000000e0e0e0e032c3c32bb0a120303133b0b132323232222276367636063676767676101010103939393921102120161616560202cf0235aeae352f3f3f2f2f3f222f22222222
1e1dac808080801baf808080181980bcbcbcbc93bc33060680aa9c80bb8080808080808080189836363696128080808080b78080801c801c808092202020121c80248080338080808080801cbb80bbbc9480808080801f800b1c80808080800b80803f3f3d3f3c2a801a1a1a1a801a1a9a9a1a1a1a1aa01a968080bbbb808097
8038ac80b03333af388080801819802712202734060606978baa1d8037ae1d80809b80a01e18069e9d9e921280808080bb002980801c801c29bb20200f35061b9b24808087bb1abb8033808b0c29ac9f068080808080b5800b1b803a803abb0bbbbb878729bb131d1d8402820dbb318080802a1daabca080b68080afaf8080b6
1e1eac1e1806c7a0af80bbbb1837fb00122000111111b7978b2a2f2928a02f29298e29af2937249824b9961229292929b627b8a9291a801a8185040799961280801a33bbb7b62626bb0c309da2971c97aa8080808080b5803c143ab73ab4a63f268202bcbc133c1d1c9f020cb42eac1e8080809cbbbba03b962929230e292934
8080b8ac18191d1eadbb18931807972712202706060625171c0a8f8f0f3506060f8f8f8f35018e8e820d288e8f068504070717248638b838079916361704350638383c3c3d06269d9b9b263d13269b3c2a3f3f3f3f3f98808f8f250125258080802cac2e2e2c8f1b1b1b1b1b1b1ba6061e801e1d1b1b85058445844747074584
80801c3418199c809cb418b406a5972712202718181819971c0904163690243636041818043686060635a60736363636142e2c2e2e2e2e802bbb8004bb04808080801f1616bf1a1a9a9a1a1a1a1a1ebf1e1e1e1e1e1e1e803c3c3c3c1a1a8080801a8080801a1a80808080808080808064456e46527271526c79d95a5a797676
30801aa023239c809cb601931818b8001220271111b5b4978b0a07071736391799363636363c3c363636363636363636922a1cdb38db382b3783bb1681168080808080808080808080808080971896808312bbbbbbbb808080802e1f25b7bcbc25bcbc80808097bbbbbbbbbbbbbb3172d0457279c3464d78806c6c7172505f76
068080ae18199a9a9a9a19931818182712200001010fa5978b0a069f9914202e2e2e7f087fb92020b7b79f02b7b7b7b7371b1b802c2c0b01b84f8f038216333333a0333333001e1eab75fb6a971896808312b6b6b60080808080802e9f963f3f3f3c3c808080974747472e2e444744d0d0454cc352f96c6c8080dcf56e6ccf79
1880808018199a9a9a9a19340625340012202718181802970a9d9997993487f031b2208b203820b80780808080bbbb87809f14801a1c0b36363636122b16a0a0afafafa0a02780db87060d20271896298312b6b6b616808080808080801a08872c1f99b40606857679d9507164767644d0456ef5526e9a9b9b6adc7971505f47
18aeae3023811c1d1e1e199718189727122000252525a597089d24819787811a1a0881818181356708808080800c2096802e2e80801b0b02b7b7828c8c561eaeaeaeaeae1e278080801920202718960707070635061680808080808080808b1a1c803c92249224d974c2c161645879d9646a7279526a806e5ddc5b50c25ae857
373b6a3737370d370c0634a68125010012202718181819978b1388f6f61af606c78bf6f6f6a40567890606060606061706b8060606068ab97f86f6f6f65696b6b6b6a02121068080802541019718968033333333b00fb3b33a3abb3a80808b1aa18016a7011201d6d744fd46d0f9c2c3e34646cf525c71506a46cfc2615061d7
07474707860f0635b8b8b838381818271220271818181997873c8bf6f6f6f69f968bf61bf6f69f3699111111f6163624a424929324a424068fb704230e1696a626b6b6970419bb8080181819971896a91d1a340c3f37b5352525a6a580808b1d1b8099a7b71236d2c25fd958d0c2f86d78363636c646cfcf857676c6f8c646c5
80808080808080808080808080808080808080808080808080808b34f6f6f6f6f90bf60bf60cf60b9982a30d281736f0202d122080201236368c160735163d06adb68f935981876af0b7b7b7ad8e8e0707073c3c353c3c3f3f3f1a808080801c80801a1237b62747fd52617979fd78c759808080af8080321031507180808080
808080808080808080808080808085078080801c1c1c808080808bf6f6f6f6f6f60bf6f6f6f6f60b9911ad11f6973637b436070736a4247f7f817f7f7f1696b6b6b60ca1640707b80707070735b8013c3c3c3f3f1a1a1a1a8080850707070707079826a740b627d9d452f478c6f8f8f856808080ae1aae2cf641ce9772808080
8080808080808080808080801b8a36368080801dac1d808080808906098a888a898a0909098a8a8a3f2222228f252524b4b4062597a4248e8e8e8e8e8e1696b435b6adb69f80808080181912808312808080801899bb3abbb7a49e9d9d06348a9e9d27a79fb627456e45455c7172805c6a80805d80801aacc7ce4df4ac806a80
8080808080808080800606070b0b36368080801c1c1c8080808080808080808080703333373c3c3c0682410d16363692b48525259792932020202020201696256565a6b6978080a2ac3f24128083128080803181998d22a226a50f25259786250fa527a737a29f6e805a6a5c6c45455b5b71485c8072801cd6c24c975c717872
80aaba801a1d3c3cb89936360b0b3636093f3c3c3c3c3c3f808080808071726a727f049d9e9d02253622a222160225a4929f36363692938e8e8e8e8e8e1f3d06931794b68502bb80a08383122983981280ac931896b522b59f36363636a43636363627a726a2978080716c4cc36e6e5a45c14d5071c1505068418f1249c150c1
80aa1a80ac1c983f363636360b0b36360a1e8c1636368c1e8080808080c64144f80625a50f258f363641a34117a436a7809714809f2da4f6f6f6f6f6f628b6a5250363b627a71b80a093021819868712bb37931899ad22223c3f3f3f3fa43f3f3f3f27e7af8285455d525b5d6c8072804547c6c545454747474747474747c646
802a1c1b1b853c3c363636360b0b363680808080808080808080808080808080808080808080808025a3a8a325a52524a4a912809303931a1aa2801a8d979637373737b627a79632ae381d981919040735060518142e3fae9f11111111111111111127a7781c2748806d455b5b5b6a8045507172807271727172f38080727150
1b1b042a0b3f3f0b3636363636363636808080808080808080808080808080808080808080808080360745073636360220fc80269303822e2ea61a1a1c97963f373f07b69fa7342ca0af2c2b2719993636363636b680aa02973838383838383838b827a71c1c274580526ac3526c5c8045d047c1504747c3c3f8467150c3d064
18198080808080980524808080248080808080802a1824808080808080808080808080808080808080808080808080a4a424809980a4a4a11a1a1c1d1d979626269302b697881a1a80ae988127193c3c3c3c3c14b68080a124a54f25a54fa5254fa527a798a7676a69526ccf525c5c80cac476e3c37979524de379c2c34cd8d0
__sfx__
010900001802018020180701807118061180511804118031180211802118021180211801118011180011800109000100000e0001000000000000002b0502c0503005030031300212b01030020300103002130011
0013800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
010300000c57018570185701857018550185301852018520185100000018570185701855018540185301852018510185001850000000185701855018540185301852018510185101850000000000000000000000
0103001e0c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c10011100
49100020143261b3160f3201b326143101b3100f3201b3160fc701b4100f4261b4160f42011410124200d3200f3200f3101632016316163200f4200f32014420140111422014426144100f4101b3201232011320
631200001b4251b425194251b420366101e420336211b4200f420164203361619420386121a42036625366101b4251b325193251b426366101e420366161b4200f32016420366111942038610224203861538615
50010d00193600d360063500334001440014300363003620036200562009610076100161009600066000260000600066000660005600056000460000000000000000000000000000000000000000000000000000
03040000000003b6303b6313b6313963136631326312c621256211e62117621156211562115621166211762117611196111a6111b6111d6111f61121611236112461125611276152861528615296152961429614
5b021b00183730537301373016700566002660086500f6500165006645056450064004630086300663004630036300762006625056250162503620036200c6100261304613016150160500605086050060408604
0a0116001276016770197701b76022760257602875000000000002c6702c6702c6402c640000003b6703b6703b6403b6353b6303b6203b6203b62500000000001370017700187001c70000000000000000000000
51020600123430d623036210d32119321253352930402305003000030000300003000030000300003000030000300000000000000000000000000000000000000000000000000000000000000000000000000000
53011d00143710d371043610136100350366602535025370366703667036670366503665036650366503665036650366503665536655366453665536665366453663536625366203661036610366003660000000
49020c003c6200e3330c22337623296233662325034062202762008220366000322039605012003b6000420008200042000820008200082000820001200366000820036600366000000000000000000000000000
0a0120003e6303d6303d6203b62038620366202992024920209201e9201b91019910179101591012910109100f9100d9100a11009110081100711006110041100411003110031110301103011030110301103011
380100002b94029940279402594023930219301f9301d9301b9301a930189301793015930149201292011920109200c920159201092008920069100f91005910049100691007910089100791004910019100e910
4102170031630112202b6101123024620112201d620112201f620112301e6301122025620112202a620112202c61011210296101121026610112102261011200236001120022600112001d600112001a60012200
0a021a003e6301b6503e630376503c63037650376301c6503963032640386300d630366300263033630016202f620026202d620026202a6100361523615026101e61502615146050260032600326003260032600
0002000020343143430c333316201c43327620164332962028613266102d6202c610296102461024610236102261020610206101f6101e6101c6101a6101761014610106100b6100661004610036100061000610
011200001800018000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9112002001612006120061201612026120461006611086110c6110961103611046100261201612016100061000610006100061000610026100161000610006100561103611016110361001610026100261001610
31240020270151ba001e0151e810030141e0100a010160150f115000001e0151e810120151e0150d0140d01427015000001e0151e810030141e0150a0150d0151e01503000200152081003000200152501422010
3148000003114031101b810081140311403110120151b81003114031101b810081140311403110120151e810031141ba101b0150f810031141ba101b0150f81006114061101ba1012810081140811022a1016810
0d12002006020030100f0200f0110f0010f0100f0010f010030100d0220d0220d01212020120110f0200f01103010030100f0100f0010f0100f0100f0010f010030120d0220d0220d01212022120120f0200f011
0d1200200d0200d01101020010100f0100f0100101501020000100c0220c0220c01012020120200f0200f01001020010100102001020120200f0200102012020010200f020010230102016020150241502514020
531200202e6150f515316151b0153c6152701531615316150d000376150d0000a615316151b5253a6153a6153a6103a6153a6103a61537615186153161531615123133a615120151b01537615376151b0153a615
011200201b5250f0151b5260f1251b1250f0151b1000f1160f5001b1250f5001b125191200f5001a1200f5200f5001b1250f5061b5160f5201b1250f0001b1250f5251b1250f5261b1251e1201b5251b1201b125
011200201b1151b1101b0000d1250d1101b1120d0250d0151b1151b1150c0251b1151e1101e015201101b0151b1251e1100f5170c020275162011220112221151b010201151b0160d0201e1101b115191101a110
092400200f01503510035200f0100f8100f8210f0150f0150f0150f01003520035100f8100f821030150f01501514015200d510015200d8100d821120150d0150a0140a0100a0100a01012810140150d01012015
394800000f5100f5210f5110f5150f5120f5210f5110f5110d5210d5210d5220d522165221652212522145210f5200f5210f5110f5120d5210d5220d5220d5220c5210c5210c5200c5220b520170120d5220a522
011200200f5150f51027b250f51027b250f5100f515277250f51027b250f5100f5151b1150f51027b2527b252eb251b5100f5100f515277100f51027b25277100f51027b250f5100f51512525125001b5151b525
112400201b7251b8201b7251b8201b7251981020725227251e7251b8201b7251b8201b7251b820197251e7251b725198101b725198201b725178201b725197252272522725217252172520725207251e72519725
a31200001b6251b625366200c6210c62136610366113662113615366152d6202d611366253662536625366251b6251b625366101b6250c62136615366103662013615366152d6153061136625366253662536625
511200200f023000002e610000000f123000002e610000000f32303210276100f2100f3130000027610000000f4131d40027610115000f2231d81227610072200f323032202e6102e6150f3331e8152e61020815
9d1200000d4100e4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d410
5d1200200f420124200d4200f42014420034100f42016420034100d4250d420034100d420034100e420034100f420124200a4200f42014420034100f42016420014100d4250d4200d4230d420014100e42303420
5112000018220184200c2210c4211f42012200122001d2201d220225351d220225352253520535205352053516220184200c2211b4211f4201220012200112201122013055112201305516055180551305518055
11120000165301652114530145211253514531145210f53511500115000f5330f5350f5350f535085350a535165301652114531145211253514530145210e535005000f5350f5350f5320f5120f535125350f535
814800001682216822168221682208024080220a0211e02504124041150612122b240612406121081211402422a22128221aa22090221182211822118201d83121a221282223a220b822188260c52518a270c624
6b090020149230802008011080152a6152a60036600149133c6103c613080100801536615081140811008020149230310003100089133c6100802514914089133c6003c60009100149152a625090100911009115
692400200f1251052512525141250f1251052512525141251952519525198300d82015525155251c8341c8240d1251152512525141250d1251152512525141250a1250a5250e5250e1251212514525105250c134
85240000010750d8542c81401850011450d8502c8140185010045108502f8250485006145128502a820168200207502854268140e850091450285026814028500607512850218350685008145148501582415823
812400002cb35149151412514915149150891514125149151791533b341b12517915179150b9151b1252eb3519915119151912511915119151191519125119151e91504915049150491512915069151291515915
791000000a2100a2100321003210032150321003410034100d2100d2100321003410033150321003412034120621006210034100341003215032100a2110a2120841008410033100331003212032100341203410
4920000022125220141601027015250250d0241901025015240250c024180100c010230252301417010019142202522014160100a0101e0251e0140601012010200252001408010080101c0250b9141c0100d912
79200020039100392003325033200cc7000c730f83003220039100392003325034220cc7000c731087006212049100b92004322032220dc7208c730f2120332004d500fc70063200fc700fc70123120631106311
792000000a1140a1210a1200a1110a115039160f9170f9140c1140c1210c1200c1110c1150491600910049110b1140b1210b1200b1110b115110200b120120200d1200d1200d1220d12212917121201491414122
5910000020326273161b3202732620316273101b320273161b326273161b326273161b3100b3201e3101d3201b3251b3252232022316253200f3301b32120320200200f33020320203201b310273201e3201d320
591000001b3261e3161b3201e3261b310273101b3201b3101b326203101b32020326273101b3101b3201d3202932612320293261e320293261e320293261e3202a326143202a326203202a326203202a32620320
4b1000201d32324c0015313214133e6201d621153133e6101531324c102141324c10214130f3243c6250f322153231cd0039625213133e6101d621396253e6102131324c12214231532338620386243862538620
3d1000201202306720061250672012625067100612506125120230612506125067202561506710061250601012023067100612506710126250602506710061251202306125061250672025615067100663406125
891000201292506a240692506925156330692506915069250c023069150692506925156330691509925069101e0231212512a10069251563312a100692512a101e02306215069150621515633139150492504925
a540000006220062110622109222062200622106221092220622006211062210b2200622006221062210922006220062110622109222062200622106221092220222002211022210b22202220022210222109222
811000201e4201241012520120201241012315153101231006135061351741219412174121741219312193121e420123101211012020124161231715310123100613506135123151231215312123121941212312
c54000001e22328826258261c8261e22728826258261c826222232a826258261e826222272a826258261e8261e22328826248261c8261e22728826248261c8261a2232a826258261e8261a2272a826258261e826
692000201e213122111bd3227c4206c5012c5312c562a3162ab2625b2625b262ab262ab162ab16062241e2211e2131221123d322cc4208c5214c5314c562a31631b2631b262db272db271531515316213122d315
d540000019124121241912412124121240b124121240b124121240912412124091241012409124101240912419124121241912412124121241912412124191241712410124171241012419124151241912417124
890b00201642306615066250661533625126150662506625160230662506625066152a6251e6152a6251e6251642306615066250661533625126150662506625160230662506625066151e625126252a62525627
5d160020030440f220037400f220030440f220037400f2200f2350f220122350f220031240f220142350f220030440f220037400f220030440f220037400f2200f2350f220122350f220031240f220162350f220
715800000f9200f91112527125270992009911125271252608920089110d5270d52704920089110f5270f5270f9200f9110d5270d5270c9200c9110f5270f5260b9200b9110d5270d5270a9200a9110f5270f526
792c00201b026220261e02727822290222a0221b02027011190262202620027278222a0222902225020270211b026200261702627822195222252222531205311e5302053120531205311b532225322253520532
412c00202252222532225321e532207321b7221e7311e73122522225322253220532257321b7221e732207321d7321e732225321b5321b5322273222732207322073220732207321b7321e732207321d7321e732
891600201642022a301542016a501e42022a20194202eb650f4250f425164200f4210f4200f4220f4250f42509420278750e420278750f420278750d420278750f4250f425124220f4210f4220f425194250f425
8d5800000a2300f0320d2300f0320c2300f0320b2300d0320f2300f032062300d032082300c032042300b0320a23016a300d230165320c23016a300e230165320f23006a301723014a301923019a300623016a30
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 12151412
00 15141212
00 12151412
00 1215141d
00 15141d12
02 1215141d
03 13585853
01 1612195e
00 17121959
00 1618195d
00 17181a5a
00 1b181d59
00 1b1d1859
00 161d1859
00 171d1859
00 161c1853
00 16181e53
02 17181e53
01 1f602113
00 1f601322
00 1f602120
00 1f602122
00 1b600520
00 1b550520
00 23602120
00 21602420
00 1f5f2120
02 1f602024
01 2512265b
00 12262767
00 12262767
00 27262558
00 26281253
00 2826295b
02 2827295b
01 387f7f78
00 38397f78
00 38397f7a
00 387f3b7a
00 38393b78
00 38393d7e
02 38393d7c
01 2a307f1b
00 2a305b1b
00 2b30552c
00 2d305504
00 2c307f2e
00 2c306a2f
02 2c306a7f
00 317f727f
01 31327f44
00 3233347f
00 3235337f
00 31367f44
00 31367f44
00 31337f44
02 3137334d
01 387f7f78
00 38397f78
00 38397f78
00 38393a78
00 383a3b78
00 383e3c78
02 38393e78

