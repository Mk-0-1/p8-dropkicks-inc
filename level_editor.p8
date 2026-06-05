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
	rect(x_l_l+128, y_l_l+128, x_u_l, y_u_l, 8)
	
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
					
					rect(-8*4,-8*4,(255-8)*4,(255-8)*4,3)
					
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

	pal({peek(loaded_level_info[12],16)}, 1)

	-- defaults
	mod_tabl(_ENV,"time_c,t_enms,t_e_clear,t_tr_collected,t_trinkets,lvl_prevmus/0,0,0,0,0,0,0")
	mod_tabl(_ENV,"lvl_enms,lvl_e_clear,lvl_e_req,x_u_l,y_u_l,trn_bnc,trn_slp,grav,lvl_tr_collected,lvl_trinkets,sludg_l,sl_c,sl_smth,sl_vx,sl_vy,sl_dmg,alert,l_time_c,sl_r,sl_h,sl_spd/0,0,0,0,0,0.2,0.75,0.22,0,0,1024,6,0.9,0,-0.16,0.6,false,0,0,0.04,5")
	
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
	poke(loaded_level_info[14],lvl_bg1[1]+lvl_bg1[2]*16,lvl_bg1[7]+lvl_bg1[8]*2,lvl_bg1[3]+128,lvl_bg1[4]+128,lvl_bg1[5]+128,lvl_bg1[6]+128,lvl_bg1[9]+128,lvl_bg1[10]+128)
	poke(loaded_level_info[15],lvl_bg2[1]+lvl_bg2[2]*16,lvl_bg2[7]+lvl_bg2[8]*2,lvl_bg2[3]+128,lvl_bg2[4]+128,lvl_bg2[5]+128,lvl_bg2[6]+128,lvl_bg2[9]+128,lvl_bg2[10]+128)
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
bg_slots_pre = split"4192,4200,4208,4216"
bg_slots = {}
bg_slot_index1 = 1
bg_slot_index2 = 1
for i=1, #bg_slots_pre do
	add(bg_slots,bg_slots_pre[i])
	add(bg_slots,bg_slots_pre[i]+128)
	add(bg_slots,bg_slots_pre[i]+128*2)
	add(bg_slots,bg_slots_pre[i]+128*3)
	
	add(bg_slots,bg_slots_pre[i]+128*4)
	add(bg_slots,bg_slots_pre[i]+128*5)
	add(bg_slots,bg_slots_pre[i]+128*6)
	add(bg_slots,bg_slots_pre[i]+128*7)
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
rope,rX,rY/2,16,0
rope,rX,rY/2,-16,0
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
txtB/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️4⬇️44⬇️42⬇️2⬇️1
rope,rX,rY,rope_e/8,-45,-8,d_o➡️2
/
txtB/\fastaff is advised\n to only \fcgrab the\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1
decal/\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!\*f \*f \*f \*5 \^h\n🅾️\n\n\|c \-e+\n\n\|c\-f\^:10387c1010100010
decal/\f2\^o0ff\^:00008064320f0204 \^h ❎\|e\n\ng\|fr\|fa\|fb  \|e\^:0000070c90a0c0f0
/
actF/600
actF,rngF,rngN,ai_a/600,160,25,_V_AIAfllw]],"\n")

-->8
-- data
#include dropkicks_inc.p8:B

__gfx__
00000000555555545555555444444444aabbbaa900000000e9a8abeabaeae9abbe8448eab9b9b9b9ebebebebbbbbbabb444444450000000077777d7877787778
00000000555555445444444455555554beeeeee800000000e9e8b9e999999999bb8448baa89898988ae9e98a8b8998b844545455000000007dd78788ddd88d88
00000000544444445444444454444444be9999e800000000e9e8a999e9e9e9e9bebeebea99a999a9aabaaba998b88b8945454545000000007dd788787877d888
00000000555555445444444454445454be9999e8000000009998a9e9e9e999e9b98bb89aaaaa8aaaaaeaaea9449bb94444545455000000007d78ddd8d8d888dd
00000000544444445444444454454454ae9999e800000000e9e89999e99999e9b98bb89a9998a9998aaaaa98449bb94445454545000000007788ddd8778d7788
00000000555555445444444454444454ae9999e800000000e998a9e999999999bebeeaea998a9999aabaab9898b88a89445454550000000078d78dd8dd888dd8
00000000444444445444444454444454aeeeeee800000000e9e8a9e9999999e9bb8448aa98a99999aaeaaea98b8998a845454545000000007dddd8d878dddd88
0000000055544444444444444455555498888889000000009988a99999999999be8448ea88888888baa99aa9aaaaaaaa5555555500000000d888888d8dd88888
44444444555555552222222211111111aaa9e99999999e9aabababab88888888ff999fdd8444445a55555555ebebebeb54005554444444445555555589889988
44444444555555552222222211111111a999e99999999e998a8a8a8a88888888fd9999df8444454a500000058a8a8a8a540550545555555554444445489aaaa9
44444444555555552222222211111111bbaaeaa9999e9aaa8888888888888888ddf999ff8444444a50000005bbbbbbbb54550054444444445500005544899999
44444444555555552222222211111111baa9e999999e9a998998999988888888dff99ffd8444444a5000000599aaaa9955500054555555550550055044489999
44444444555555552222222211111111a9e9e999999e9e998888888888888888ff999fdd8444444a50000005888aa88855500054444444440055550044448998
44444444555555552222222211111111baeaa999999eaeaa8888888888888888fd9999df8444444a50000005888aa888545500545555555500055000554448aa
44444444555555552222222211111111b9e9999999999e998888888888888888ddf999ff8444444a5000000588aaaa8854055054444444445555555544444489
44444444555555552222222211111111a9e9999999999aaa8888888888888888dff99ffd9aaaaaaa55555555eeeeeeee54005554555555554444444445554448
44444444444444444554455455555555baa9baa99aa99999bbaebbbabbebbbbe0000000099888989ba9bba9b55455545fffffffd7777777d88888888babbbbba
5555455545554455445544555455445599e9e9e9e999e999baaebaa9aaebaaa90000000088888888aa9bba9b55455545fdffddfd7377337d89999999b9aaaa9a
44444444444444445445544554455445a9baa9aa999999aabaaea99999ea99990000000099999999ba9bba9b55455545fffddffd7773377d89899989babaabaa
5545554554455445554455445544554599e9e9e9e9e99999aaae999999eeeee90000000088899988ba9bba9b55455545ffddfffd7733777d89999999aaaaaaa9
44444444444444444554455455544555baa9aaa9aaa9aa99eeee99ee999999990000000099999999ba9bba9b55455545fddffdfd7337737d89999999baaaaaa9
4555455545444555445544555455445599e9e9e9e9999999999999999999eee90000000099999999ba9bba9b55455545fdffddfd7377337d89899989aabaaba8
44444444444444445445544554455445a9aaa9a9999aa9aa99999999999999e90000000099999999ba9bba9b55455545fffffffd7777777d89999999a9aaaa98
555455545554555455445544555555559999999999999999999999999999e9990000000099999999ba9bba9b55455445dddddddddddddddd8888888888888888
05000505050000050000000500000005b8bbbbbbbbbbbbbb999999999eee9e9e545b45b499999999aa9bba9bbbbbbbbb999999995544444499999898babbbbba
050005050500000555555555000000558bbeeebeeebeeebe99999999999e999e54a5a5ab99999999ba9bba9bbbbbbbbb9999999955444455999aa984aaa999a9
55005555050005050505050500000505be899989998999899999999999e99e9e4b5a4aa599999999ba9baa9baaaaaaaa999999995544444499999844aaaaaaaa
55500555050005055050505550000055be999998888888889999999999999999a9b45baa99999989ba9bba9ba99aa9aa99a999995544444599888444aaaaaaaa
05000505050005050505050505000505be9999988beeeeb89999999999999a999bba99a988888888ba9bba9b9999999999a9aa9a5544444499984444aaaaaa9a
05000505050005055555555555555555be9999988899998899999999a9eaaaae9a89aa9999989999ba9bba9b99999999aaaaaaaa55444455aa845554a9aa9a99
05000555550055055555555555555555888888888b9999b8999999999eea9e9ea9aa99a988888888ba99aa9999999999bbbbbbbb554444449844444499999999
5500050555000505555555555555555588889998888888889999999999999aaa8aa88988888888889988998899999999bbbbbbbb554444458544444488888888
030000005554454455444554555444555b9b99550000000077f9f9fffff9f9ff909fd09066666666f7ffffff99900999ddddddd600dddd00000dd0003d666dd3
0d0000005455444445544544544545559bbbb9bb000000007f7fffffffff9fff999fd090666666667f7fff7f9f7fffff666663d60dddddd00dddddd0d66d6663
6d666000444445544454554445444554bbbabb9b00000000f7ffff7fffff7fff009ffd9866666666f7fffff7f7ff7fff66663636d8d66dd86dddddd366663630
6d666600554555445444454545445544abb9ab9a00000000fffffffffff7ffff0f9dd88866966868fff7ffff8fffffff63366366dd6336d866ddd36863dddd30
d3d33d3d5445545444445454445454449ab9a9aa00000000ffffffffffffff7ffd9fd99068968888ffffffff9f8f8f8f36d36666dd6336886663688363dddd30
dddddddd445544455544544444444444aa9a9aa900000000fffffffff7fff7f7ddddd08068998988f8f8f8f80888f8f83d636666ddd668866668836866666630
66666600445444445444554455444445999a9a9900000000f9fffff9f9ffff79080fd9806999999889898989f989897f633666660dd8886006636860d66d6663
6666660044444455444445445444445599999999000000009f9f9f9f9f9fff9f089fd8008999999898989898f80099ff6666666600886600006866003d666dd3
454445450000000000000000000000009899999999999989baabbbabaaaaaaaa689998689a5a959a54545055f7ffffff05445050aaaaaaaa0000000054999999
545444440000000000f0000000000000899999999999999898899999a000000a669998669454a49a550505057ffff7ff05045550a000000a0555555054499a99
544444540088800000f6600000fff000889999999999998888888888a0000a0a669998664954a49440550555ffffffff55055500a0000a0a05555554445999a9
444445440c8d800000f3330000676600588999999999998988988899a000a00a668999669599999440050054f9f9f9f905454505a000a00a5555555445494999
4444444400cdd0000066600000f6d600589999999999988988888899a00a000a668996664549449a505505549f9f9f9f05554555a00a000a5454545445494999
44454444008000000000000000f00000899999999999998599888888a0a0000a6669966649a9594a455005508989898900454500a0a0000a4545454555454449
44445445000000000000000000000000899999999999999899888898a000000a668999669aa49a59505055008888088805454500a000000a5454445555455459
45444444000000000000000000000000999999999999998988898888aaaaaaaa688998669a44aa59550554050808008004454550aaaaaaaa0404040455555454
454455455454554455545554555455549bbb99a99ba999995b5bb5b55b55bb5b000000004a54ba5aba9bbab94545545500000000005550000000000d70000000
54545454455454545554555455545544bbaaaa99ba999999bbbbbbbbbbbbbbbb00000000ab94aa4ba99babab44455455055555004444550000000007e0000000
55444544545544545554555455544454aaaaaa9b99999bb9abbbaababbababbb00000000a9b9a99aba9b9ba945455445000445555555525000d0007dee000e00
454545454554545544444444444444449aaaa9999999baa9ababaa9aabaabaab0000000099aa9a9aba9a9ba9454554450444544c5cc444200007d0d99e0ee000
54545444545545545554555455544444b99999bbbbb9aa999a9aa9a9aaa9ba9a00000000999a9a9aba9b9ba94544445544c445544444c440000dd966669ee000
45454445454544555554555455544454aaa9bbbaaa99999aa99b9aa9a9a99a9a0000000099a99a99aa9b9a99454554554c4c4544454c4c40000096d666690000
45455454454544545554555454444554aa99baaaa999ba9aa9ab9a9aa99a99a90000000099999999ba9b9ba94545545544c445000544c440007d6d663666ee00
54445454554554554444444444444444a9999aaa999aaa9999a9999a999999a90000000099999999ba9baba9454544550444000000044400d7d9666363669eee
50450405000500500000000000000000bbbabbbabba9bba90000300099a99999aaaaaaaa99999999ba9b9ba96666666654545454aaaaaaaa7dd9666636669eee
44540455050450450000400400000000baa8baa8baa8baa8003666309a99a999a000000aa99999a9ab9baab86666666654555455a000000a00dd666666e6ee00
04545454045540055054004005004500baa8baa8a998aa980300600399999a99a0000a0a99899a99ba8a8bab6666666654444444a0000a0a000096666e690000
54544044054040540405005454045040a888888898888888036666639999a9a9a000a00a99599999bb8aab8b68a6686645555555a000a00a000dd966669ee000
55454540454540450545050445055405bbbabbba88b88988030060039a99a9aaa00a000aa9895999bababa8aa8aaa88844444444a00a000a000dd0d99e0ee000
54504545505445554545454540050454baa8baa88baa898800366630a99999a9a0a0000a5a858989a9baba8b9899989844444444a0a0000a00d000ddee000e00
54555045545445545405554554505455baa8baa8aaa9898900006000999a999aa000000a59885989b9b998899999999855545554a000000a0000000de0000000
44545445045404555554555554545545a888a8888a9899890fd666df99999999aaaaaaaa88585885b99bab899999999944545454aaaaaaaa0000000de0000000
40d8611070ea211050bad140d0d631112242815100000000000000000000000001e0351001e374107043441060b4e31060c4b110000000000000000000000000
02a51181c1d69191e105d210c1c2e0910204f08100000000000000000000000000000000080808087710284808ca08083d102828050a080814102828050ae9d7
507351207042112040d4017050c7d04022f401617028f11000000000000000002161211021b72110f0d6b0100121311001c4911060c211106025011000000000
a181a110a1e2e110a122c11011d3a11000000000000000000000000000000000261028280b4918084d0028eb0a0c08083e1038480a8a0808161058480a66daa7
50a1c110f0d071104094d12070f3803070b480107042c31042c682800000000021f32230506220802148413001d2711070a2001042e530800000000000000000
0292221002d4b120c1d3e110c1d533100246a12002377210c123031000000000201028280b49f70850003828080808083e10e70a0a0c0808273038080866e917
42c2508042a2b18042f0508042c1d22100000000000000000000000000000000610500a001439110000000000000000000000000000000000000000000000000
71621110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000036102889bc0c0808273048880a4cda26
4242344042c3d0407026412070c5013070d4f210428443805054b48042b21180e13251c000000000000000000000000000000000000000000000000000000000
1242b22002a60081702600811265d11000000000000000000000000000000000100048880c28080800000000000000003e10288a086d08082710384808e8e908
b0c1f01080c4e1a0000000000000000000000000000000000000000000000000b1223250918123d0b121e250b112e41091d4941091f364e00000000000000000
0192701012445110f1b812100263501042433280000000000000000000000000171038185ae80808000000000000000031102809084b0808271058880829cb08
5056418070e341106032510160b4011000000000000000000000000000000000b1c4d310c1c2d310c1f271100243b120f041f010b14121100000000000000000
f0a376101243d410d1f22310124342100131e2500000000000000000000000001300588883880808000000000000000000080000000000000008000000000000
d0b1d14121a3a130701541102126a11000000000000000000000000000000000b1325301c132b110c1c5611002545110910221f00145b2100000000000000000
80f0e01012c2431012c1b210f152f110000000000000000000000000000000000a10588805870808000000000000000000080000000000000008000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000d066dd66000ddd60000ddd60000ddd6000066066006066600006066000000000000022000000cc000000000000000000000000000
0000000000000000000003d06d6666d30dd666600dd666600dd6666060606600066660660606666000022000023773200cf77fc0000000000000000000000000
000000000000000066663d0066d66d66366366363d366363d366366366606666606606606606600600233200037777300f7dd7f0000000000000000000000000
00000000000000003667777766d66dd36666666666666666666666660666600666066666666666600237732027777772c7dccd7c000000000000000000000000
0000000000000000366ddddd66d33d666666666666666666666666666006666066666066066666660237732027777772c7dccd7c000000000000000000000000
00000000000000003366d30066d33dd333666633336666337766667766660666066066066006606600233200037777300f7dd7f0000000000000000000000000
000000000000000006000d30d6d66d6d77366377003663000076670000660606660666600666606000022000023773200cf77fc0000000000000000000000000
0000000000000000000000dd0dd66dd00770077070000007000000000660660000666060006606000000000000022000000cc000000000000000000000000000
00000000000333000000000002220000000000000000000000000000000000000000000000000000abbabbab0000000000000000000a99990000000000000a99
00000000233333300222200022222200000000000000000000666600000000000000ddd00ddd0000baabba8a00000000aa900000000a99999999000000aaa999
000000223333333333322222233322220044400000000000066666660000000000dddd6dd6dddd0089a88b8800000aaaaa99000000aa999999999999aaa99a99
0002222233232223323322233322320000444400000004406666666666000000dddd886dd688dddd88a899b800aaaaaa9999900000a99999999999999aaa9999
0222222333321232222223332122130000444400004404446666666666660000d866d86dd68d868d8a8899a8aaaaa999aa9999000aa999a999999999aa999a99
223332332321212212223332121112200444440000440444666666666666660088636d6666d63688aa988aaaaa999aaaaa9999900a9a99a9999999999aaa9999
23333332322333312111332121111122444444004044044466666666666666660086366336636800a8a88a8a99aaaaaaaa999999aa9a99a999999999aa999a99
333323222133333311133212112221124444444044444444ddd6666666666666000d63666636d000a8a88a88aaaaaaaa99999999a9aa9999999999999aaa9999
333231211333323211132222000000004440000000000000dddddddddddddddd00ddd660066ddd0097f9f979aaaaa999aa999999a9aa999999889889aa999a99
222212333333222112322211000000004444440000000000dd666666666666660d8d68600686d8d07f7f97f7aa999aaaaa9999999aaa9999989898989aaa9999
1212332332321212222121110000000044444444000004406d666666666666d3ddd8068668608dddf7f9f97999aaaaaaaa9999999aaa999998899988aa999a99
11233222232121221211132200000000444444440004444066d666666666d3d3dddd68633686dddd9f9f9f9faaaaaaaa99999999aaa99999999999999aaa9999
133222122222112121113221000000004444444400044440d66dddddddd3d3d38ddd08633680ddd8f979f9f9aaaaa999aa999999aaa999a998899988aa999a99
3321211122111211111212110000000044444444440444400d63636366d3d30080ddd086680ddd0897f7f7ffaa999aaaaa999999aa9a99a9989898989aaa9999
12121111111111111121211100002220444444444444444400ddddddddd300000606d000000d6080f9797f7999aaaaaaaa999999aa9a99a999889889aa999a99
112111111111111111111111222222224444444444444444000d66666d00000000606600006606009f9f97ffaaaaaaaa99999999a9aa9999999999999aaa9999
0022222201011111111111110000000000000000010000000000000010101010111111110000000000000300a88000000000000000bb000000000000000b8000
02222233101011111101011100fffd000330033000d010d001000d3d000000001111111100000000030003000800000000bb0000bbbbbb00000000000b888800
2222333311010101011010110f7fdd800300003006360000000006d610101010212121210030000003000300a080000000abb000abbb88000000000ba8888880
2223332301000010101101100ffddd80000000001000001010001000010101011111111100030000030030000800000000a88000aaa88800000000baa8888880
2332222200100000010100010fddd88000000000001000010010001010101010212121210000300003003000000000000aa88000aaa8800000000baaaa888888
3321212100000000001000000ddd8860030000300000d0d0d636d00101010101121212120000033033033003000000008aa80000aaa880000000baaaaa888888
121211110000000000000000008886000330033001066d660060100d11111111222222220000003333033003000000000aa00000aaa88000000baaaaaaa88888
112111110000000000000000000000000000000000001300010000000101010112121212000000033b033030000000000a000000aa88000000baaaaaaaa88888
00000000fd0000df00ffff0000dddd00000000220ff7fff000dfddd00ddf700000ddd0000033003a33b3b030000a080000aa88808a80000000aaaaaaaaaa8880
00fffc00d7f00ff80f7ffdd00dddddd022222252f7fffff70fffffdddff777f00ddddd000000330393b3a3300000bb0000aa88800800000000aaaaaaaaaa8880
0f7cccc00fddddf0f7fdddd8d3ddddd325a2aa20fffffffd0dfff880dd777fd0008880003300a33b3b8ab3300000abbb00a8880000800bb0000aaaaaaaaaa800
0fcccc8000d7c800ffdddd88dd7ddd3d02222220dfffdddd0ffcffddf77ccfff0ddddd00003330a9b3a8b3000000aa8800a88800080abb80000aaaaaaaaaa800
0fcccc8000dcc800ffdddd86ddd773d802aa2a208d8888880ffcff88777ccfff08dddd00000033389b898bb0000aaa8800a88800000aa8800000aaaaaaaaa000
0cccc8800fd88df0fdddd886ddd7dd8602222220080888800dfff880d7ffffd0008880000000baba8ab89a33000aa8800aa88000000aa8800000aaaaaaa00000
00c88800dff00ff80dd888600dd3d86002aaa252000800800fffff88dffffff008dddd0033333aab88ab8390000aa8800a888000000aa88000000aaaa0000000
00000000f800008f0088660000838600252222200000000000df88800ddff000008880000000333a8888aa89000aa8800a880000000aa88000000aa000000000
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
88080808010001010100010188808383088888880101018101010801088808080808080801010101000101088c8c81810808080801018101810101010188888100080808010011111125111100000000080000000101010025010811080008080808080001010101000101080808000008080808010100010001012508000000
0000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010001000000000000000000000000001100000001000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d400000000d3c0c1c2c30071707173727371730000000000cbcc0000fb00000000eeef00e90000e9000000e7e7e7e7e7e7e7e7e5e6e6e5e6e6e5e6000000c8c90000008f0f0a8e8f0007820288080c0d02068e8a8789018300070081838b0e8d810c03818c87008100070082020e0c0d820600
cfce00dbdc00dd36c4d5c5c4c510c4c5c0c1e0d1d0d1d0c36160417061616060d5e7cdcee7dbdce7edfc00ecfb00feff0000e90000000000e8e8e8e8e8e8e8e8e5e5e6e5e5e5e5e5000000d8d90000008f0f0a808200078288088f0c0d88068e0f0789858d0007008204090e0d820c8f020e0a8082000782888e0f0c0d880682
df36d5dbdccfdd361010101010101010d0d1d2131313d2d2604243414342426010e8dd36d4dbdce8fbfdeeedfced00ed0000000000e900e91212121212121212e5e6e5e5e6e5e6e6000000d8d90000000d06098d0d0007008181018c8581868d80820880820007008505860c0d800600888e0a8082000782880e0f0c0d880602
df3607dbdcdfdd361010101010101010e1e1e2e1e1e2e2e166666766676767661012dd3610dbdc12fcfbfbebecebeceb000000e9000000001212121212121212e5e5e6e5e6e5e6e5000000d8d9000000060709008100078202020e0c8502860d89090a88080007028280000c0d82060880850880850007820d06060c8d0d8600
ccddddcc012020208a46474620202020042727264746070641202020676667661b0a1b1b005c00015e0a5e0bdc08881c20202020020201022121212120202020717071711a1a1a1a60101010202020243636373e0000000014f676766667143677253636363614155b4a5b5b001c001c001c001c1e415e415e415e5e1f363636
89898989202021204701202020032003143636154607060741410303767676760008005c005c001c1e088008dc08881c02070702e0e0e0012222222202020202617060701a1a1a1a601010102020202436373e013232323214f676767676143676f936f936f914158b8b8b8b001c001c001c001cc01cc01cc01cc0c03d1f3736
98545598212020204620021020012001143636370707070727262627f6f676761e081e5c0b0a0b0b0b0a5e0b1e0a8a0102393902e0e0e0020202020203cf02ce60636160020202026010101074747424363e3d213435353414f67676b976143776d914d925d914151e011e1e5b4a5b5b000100015e415e415e015e5e02105f37
98545598474747474720101020202020253636360707070737363636f6f676760008005c0008001c00081c08dc08881c20202020e0e0e002ce02cfce26272626636261632020202060101010757575243e2102202222222214f6767657b9041576e925e936e93715001c00008b8b8b8b001c001cc01cc05cc0c0c0c03d1dbd5f
e0e0e0e002e0e00202020202101010102464652501d0d03c203d2002187655980223230200000000060706002b2b2b2b1ee0e0e0e0f0f0e0e0e0e0e0001c001c000000000000000000000000000000002020202020202020767676766a6a6a6a21032120363776770000000000000000353434342f1d1d022f3f3f2f16161616
e0e0e0e020e0e0201ae0e01a2020202025646524222203a2aaaa2a2a18765598231d213d72723232060706002b2b2b2b30e0e0e0e0f0f0e0e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf76767676babababa62626262373976760000000000000000467676760823233d220c0c34172e2e2e
e0e0e0e020e0e0201ae0e01a21202020256465251d1d11bdeaea2a2a18765598231d033d424242021b1b1b00212020211ee0e0e0e0f0f0e01e011e1ee0e0e0e00031c32b30313031000031000000000002026626470706077676767602020202262726272001b9b94132323232323232467676760835353434350c3439393939
e0e0e0e002e0e0020202020202cecfcf246564253b3b3b3b7a7a3a3a187655980202020261606060409c400003202120001c011c2b2b2b2b00000000e0e0e0e032c3c32b302120303133303132323232222276367636063676767676101010103939393921102120161616560202cf0235aeae352f1b1b2f2f3f222f22222222
1e1dac808080801baf80808018801880181818a18080bb1980808080049c80bb808080808080808018393f391699128080808080bb80808080809480808080809f808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808064456e4652f2f1526c79d95a5a797676
8038ac80b03333af3880808018801880bb0303a18080b62580808080161d8037ae1d80809b80a01e18b8b89816991280808080bb278080808080068080808080068080808080808080808080808080808080808080808080808080808080808080808080808080bbbbbbbbbbbbbb3172d045727943464d78806c6cf172505f76
1e1eac1e1806c7a0af80bbbb18801880271803128080b61980808080162f2928a02f29298e29af29373f3fa33f3f1229292929b6278080808080aa808080808098808080808080808080808080808080808080808080338080808080801cbb80bbbc80808080804747472e2e444744d0d0454c4352f96c6c8080dcf56e6ccf79
8080b8ac18191d1eadbb189318801880273703128080b61980808080018f8f0f3506060f8f8f8f35018e8e820d288e8f850407070702bcbcbc3e2a3f3f3f3f3f988080808080808033333333b00fb3b33a3abb3a808087bb1abb8033808b0c29ac9f80808080807679d9507164767644d0456ef5526edadbdb6adc7971505f47
80801c3418199c809cb418b406808080a780033838381837736a737316041636902436360418180418868f0e8fa6073604b7b7b7800c0c9702131e1e1e1e1e1e1e808080808080a91d1a340c3f37b53525a5a6a533bbb7b62626bb0c309da2971c978080808080d97461c161645876d9646a7279526a806e5ddc5b50c25ae857
30801aa023239c809cb60193188019a787a70307b7b718070707070707903917191818191718181918070707070707079680808080800c979702b7b73eb7b7962d2d2d2dbcbc010707073c3c353c3c3f3f3f1a803c3c3d06269d9b9b263d13269b3c3c7f7fb774d2f453c646d064d979794646cf525c7150ea46cfc2615061d7
068080ae18199a9a9a9a199318800b1c80808080800b80803f3f3d3f3c2a801a1a1a1a801a1a9a9a1a1a1a1aa01ab7b7b535069e2a800c97973d01012501f696a6a8ad3404bc983c3c3c3f3f1a1a1a1a808080801f1616bf1a1a9a9a1a1a1a1a1ebf3f929b9a97d2c35fd958d0d6fc7878363636c646cfcfc57676c6f8c646c5
1880808018199a9a9a9a193406800b1b803a803abb0bbbbb878729bb131e1d8402820dbb318080802a1daabca0807f02bc881f052a060685d79211111111a4bd9daf8097591e9899b425808080092c0980808080808080808019809718181819808080a18c1b9747f852617979d6f8f453808080af8080321031507180808080
18aeae3023811c1d1e1e199718803c143ab73ab4a63f268202bcbc133c809c9f020cb42eac1e8080809c80bbae3b8080139d899d85f9f6bc13a4060606060696b61d8ca16480989993198080801a1a1a808080808080808080193497b4b4a525298b26e666a197d9c152f478c6f8f8f856808080ae1aae2cf641ce9772808080
373b6a3737370d370c0634a681808f8fa501a5258080802cac2e2e2e2c1e2c822811b429a6061e801e1e1e2c85058080808080801cb59dbc3e3d2501a525b796a18cadb6d880808080181912800312808080801899bb3abbb7198093f625259f22b41834bca197456e45455c7172805c6a80805d80801aacc7ce4df4ac806a80
07474707860f0635b8b8b83838803c3c3c3c1a1a8080801a1a8080801a1a1a1a9a1a1a1a1a1a808080801a1a1a1a3c3c17808080899d8734b502b7b7b7bcb496a1b6b6b6978080a2ac3f24128003128080803181998d22a2261980b4f6f625971e9d180cd8a9976e805a6a5c6c45455b5b71485c8072801cd6c24c975c717872
26808080801c80801819803231301c80801c80801c80808080801c801c808092202020121c80247271507f7f863e9697970606060696bd02973d38be38383896bfbfbfbf17088033a00303122983981280ac931896b522b59f19809718181819128027979b7f648080716c4c436e6e5a45c14d5071c1505068418f1249c150c1
2f33802b291c2929041934068f371cb2301c80803434062980801c801c29bb20200f35069b1b2475f878b8061386a5bc97b7b7b7b796b99280809ca280809c37b6870101978b1baea0971a1819868712bb37931899ad22223c278097f6b4f693128027e45846d7455d525b5d6c8072804547c6c545454747474747474747c646
07070786041b07060d3797363686260407862981b48505b8a9291a801a8185040799961280801a8080808080802b93169780808080b992a41a1aa2801a8d9799bfbf37bc978b96b2ae381d981919040735060518142e3fae9f27803425a58fa51280272fb7d797488052455b5b5b6a8045507172c07271507172f38080727150
36363636991a173607070707363636363607070707073617248638b8380799163617043506383880808080802b37b41686850505863d3d852e2ea61a1a1c9796010606bf9789342ca0af2cb69819993636363636b680aa0297198097181818191280270b7834d74580526a43526c5c8045d047c1504747c3c3f8467150c3d064
3c3c3f3f3f3f3f3cb6223f3cf6f6f7968c3f3fd6f6b425970997a4a496a20ca297b58080b8b8803a3a80b506063d13168080808080808080a11a1a1c1d1c979698b6bcb697881a1a80ae98a118193c3c3c3c3c14b68080a124278034f6f6f6341280270b2d2dd76a69526ccf525c5c80cac476e3437979524de379c2c34cd8d0
b6b6282828b63838b696b6a6268eb5b496f6f6c70425bc970b970c0c96a10ca10b0abbbb0436807f7f1b7f7f7f7f7f7f968080bbbb8080970687af9719a18599878797969824b21cb11b84a118198121213fb6a8828080a19f27801818181819128027ad2c8c97444d525bd9525a6c80446459c2c37846c2614645c3c24dc1d8
3c3c3c3d13bfbfbfbda6133c7ff697163d9d09d62e2e9fa40b97a1a196a287a2080a96ac16368078417878010f780f78b68080afaf8080b61896809719a197173f3f3f8d98b910af202020343636b6282228a0213f3333339727802718181819128018801cac97d95e415279525d5c805779f961414d794d4c764542c34cc2d7
f634133997983d3e99393934f60df63e05050505bdbc13bd0b0b0c0c0b803480893e96af167680808080808080808080962929230d2929342821800e8e340d3f0d8d263497ababa02a20ad18363638212821810c0c2c2e06850180271818183412801892aa0cd77969485280525c5d5b47c1414341cc4d434d79f9c3c14dc1d7
863d01133d06073d8f8f133da613013d3a3a3a3a3a3a3a3a899d9d869da63c869d1396015636808080808080808080808445844747074584181a1a191a1818a626a61713133838383838382436368080802f1a1aa0ad801f369980271818181912801892788bd7c65b5b45475bcac84a76c64141797841454141c541c54541c5
__sfx__
010900001802018020180701807118061180511804118031180211802118021180211801118011180011800109000100000e0001000000000000002b0502c0503005030031300212b01030020300103002130011
0013800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
010300000c57018570185701857018550185301852018520185100000018570185701855018540185301852018510185001850000000185701855018540185301852018510185101850000000000000000000000
0103001e0c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c10011100
49100020143261b3160f3201b326143101b3100f3201b3160f3201b3100f3261b3160f32011310123200d3200f3200f3101632016316163200f3200f32014320140111422014326143100f3101b3201232011320
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
0120000022125220141601027015250250d0241901025015240250c024180100c010230252301417010019142202522014160100a0101e0251e0140601012010200252001408010080101c0250b9141c0100d914
791000200332003410033200321003210032200f415034250332003410033200321003215032100391003910064200f4100642003210031210302106020031300432012420043200621006410124100631006310
312000000a1140a1100a1100a12003923039160f9170f9240c1240c1200c1200c1200c1200491600120049160b1100b1100b1100b1100b110110200b110120200d1200d1200d1220d12212917121201491414122
5910000020326273161b3202732620316273101b320273161b326273161b326273161b3100b3201e3101d3201b3251b3252232022316253200f3301b32120320200200f33020320203201b310273201e3201d320
591000001b3261e3161b3201e3261b310273101b3201b3101b326203101b32020326273101b3101b3201d3202932612320293261e320293261e320293261e3202a326143202a326203202a326203202a32620320
4b1000201d32324c0015313214133e6201d621153133e6101531324c102141324c10214130f3243c6250f322153231cd0039625213133e6101d621396253e6102131324c12214231532338620386243862538620
3d100020120230672006125067201262506710061250612512023061250612506720126150671006125060101202306710061250671012625060250671006125120230612506125067202a615067100663406125
891000201292506a240692506925156330692506915069250c023069150692506925156330691509925069101e0231212512a10069251563312a100692512a101e02306215069150621515633139150492504925
5d40000006210062110621109212062100621106211092120621006210062110b2100621006211062110921006210062110621109212062100621106211092120221002210022110b21202210022110221109212
811000201e4201241012520120151241012315153101231006135061351741219412174121741219312193121e320124101212006010124161231715310123100613506135123151231215312123121941212312
d74000001e01328716197161c7161e71128016190161c016220132a716257161e716227172a016250161e0161e01328716247161c7161e01728016240161c0161a0132a716257161e7161a0132a016250161e016
692000201e213122111bd3227c4206c5012c5312c562a3162ab2625b2625b262ab262ab162ab16062241e2211e2131221123d322cc4208c5214c5314c562a31631b2631b262db272db271531515316213122d315
d540000019124121241912412124121240b124121240b124121240912412124091241012409124101240912419124121241912412124121241912412124191241712410124171241012419124151241912417124
890b00201642306615066250661533625126150662506625160230662506625066152a6251e6152a6251e6251642306615066250661533625126150662506625160230662506625066151e625126252a62525627
5d160020030440f220037400f220030440f220037400f2200f2350f220122350f220031240f220142350f220030440f220037400f220030440f220037400f2200f2350f220122350f220031240f220162350f220
715800000f9200f91112527125270992009911125271252608920089110d5270d52704920089110f5270f5270f9200f9110d5270d5270c9200c9110f5270f5260b9200b9110d5270d5270a9200a9110f5270f526
792c00201b026220261e02727822290222a0221b02027011190262202620027278222a0222902225020270211b026200261702627822195222252222531205311e5302053120531205311b532225322253520532
412c00202252222532225321e532207321b7221e7311e73122522225322253220532257321b7221e732207321d7321e732225321b5321b5322273222732207322073220732207321b7321e745207451d7321e732
891600201642022a301542016a501e42022a20194202eb650f4250f425164200f4210f4200f4220f4250f42509420278750e420278750f420278750d420278750f4250f425124220f4210f4220f425194250f425
8d5800000a2300f0320d2300f0320c2300f0320b2300d0320f2300f032062300d032082300c032042300b0320a23016a300d230165320c23016a300e230165310f23006a301723014a301923019a300623016a30
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
00 2a301b2c
00 2b30552c
00 2c307f7f
00 2d306c04
00 2c30702e
02 2c306c2f
00 317f727f
01 31327f44
00 3233347f
00 3235737f
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


