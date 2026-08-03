pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--
--

cursor_pos = 1
cam_x,cam_y = 0,0

function _init()
-- enable mouse buttons
	poke(0x5f2d, 0b1)
-- enable extended palette
	poke(0x5f2e, 0b1)

-- use extended map
	poke(0x5f56,0x80)

	load_m_menu()
end

w_text,s_text = "",""
s_col = 7

function load_m_menu()
	-- input delay
	poke(0x5f5c, 8)
	poke(0x5f5d, 2)
	
	w_text = "select a level to edit"
	s_text = ""
	s_col = 7
	
	_draw = _draw_m_menu
	_update = _update_m_menu
	
	x_off,y_off,mm_scale,skip_borders = 0,0,4,false
	menuitem(2,"view map", view_map)
	menuitem(3,"compress extras", compress_extras)
end

function compress_extras()

	local output_string = 'ntt_extras=split("'
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
			local map_st, map_of = 4096,32
			if (ntt_mempos > 8192) map_st, map_of = 8192, 0
			local ntt_map_x,ntt_map_y = ((ntt_mempos-map_st)%128) * mm_scale, ((ntt_mempos-map_st)\128+map_of)*mm_scale
			
			
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
		
		if mm_scale > 2 then
			for i=1, #lvls_info_2 do
				local lvl_info = split(lvls_info_2[i],"`")
				local ntt_mempos, num_ntts = lvl_info[16],lvl_info[17]
				local map_st, map_of = 4096,32
				if (ntt_mempos > 8192) map_st, map_of = 8192, 0
				local ntt_map_x,ntt_map_y = ((ntt_mempos-map_st)%128) * mm_scale, ((ntt_mempos-map_st)\128+map_of)*mm_scale
				
				local d_col = i%12 + 4
				color(d_col)
				print("\^o0ff"..i,ntt_map_x+num_ntts*8-2,ntt_map_y)
			end
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

function bg_mem(index)

	return 4704 + index%8*128+index\8*8
end

function _draw_m_menu()
	cls(0)
	
	local s = 14 -- main menu height
	
	cam_y = cursor_pos*s-20
	camera(cam_x, cam_y)
	
	-- have to temporarily switch maps for tline
	poke(0x5f56,0x20)

	for i=1, #lvls_info_2 do
		local lvl_info = split(lvls_info_2[i],"`")
	
		local yval = i*s + 12
	
		local l_txt_col = 7
		if cursor_pos == i then
			l_txt_col = 12
			rect(1, yval - s\2, 127, yval + s\2,l_txt_col)
		end


		-- col
		rectfill(2, yval - s\2+1, 126, yval + s\2-1,lvl_info[13])
		rect(2, yval - s\2+1, 126, yval + s\2-1,l_txt_col)
		

		
		-- bg sample
		for	j=0, s-4 do
			bg1_loc = peek(bg_mem(lvl_info[14]))
			bg2_loc = peek(bg_mem(lvl_info[15])) -- is also the location as its the first byte
		
			tline(62,yval-s\2+2+j,125,yval-s\2+2+j, (bg1_loc%16)*8, j/8+1, 1/8, 0)
			tline(62,yval-s\2+2+j,125,yval-s\2+2+j, (bg2_loc%16)*8, j/8+1, 1/8, 0)
		end
		
		print_outl("level " .. i, 4,yval-2,l_txt_col,1)
		
	end
	
	poke(0x5f56,0x80)

	
	rectfill(cam_x,cam_y,cam_x+128,cam_y+8,0)
	line(cam_x+2,cam_y+8,cam_x+126,cam_y+8,1)
	
	-- title
	?w_text,1,cam_y+1,7
	
end

function _update_m_menu()

	if btnp(2) or btnp(3) then
		cursor_pos -= 1
		if btnp(3) then
			cursor_pos += 2
		end
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

function mod_tabl(tab, kv, splitter, delim)
	local k,v = unpack(split(kv, splitter or "/"))
	k,v = split(k,delim),split(v,delim)
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


-->8
-- main level editor

function load_l_editor()
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
	rectfill(-256,sl_l,1024,2048,sl_c)
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
		print("\^o95aextras (" .. entity.extrainfo_loc .. "):\n\^rf" .. ntt_extras[entity.extrainfo_loc],10,35,type_c,9)
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
		local vec = ({vec2_right,vec2_down,vec2_left,vec2_up})[i%4+1]*((i+3)\4)
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

-- TODO Snap to block
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
	rect(lhx, lhy, llx, lly, 8)
	
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
				
					-- works slightly differently, assumes is to ground -- TODO here
					local link=mod_tabl2(
					{},"from,to,len,strenght,draw_type,col,is_front,width",
					{entity, entity.pos + vec2_new(entity.rX,entity.rY),peek(4536 + entity.rope*128,7)})
					link.true_len=link.len
					if (entity.rope_e) mod_tabl(link, entity.rope_e, "➡️", "`")
					draw_link(link)
					
				end
				
				draw_entity(entity)
				if (entity.decal) draw_decal(entity)
				
			end
			
			if i==4 then
				if (mous_x>(ex-ntt_rad) and mous_x<(ex+ntt_rad)) and (mous_y>(ey-ntt_rad) and mous_y<(ey+ntt_rad)) then
					rect(ex-ntt_rad, ey-ntt_rad, ex+ntt_rad-1, ey+ntt_rad-1,3)
					
					rect(-32,-128,988,892,3) -- entity placement borders
					s_text = j .. ". e:" .. entity.template .. " x:"..entity.pos.x .." y:".. entity.pos.y .. " x:" .. entity.extrainfo_loc
					if entity.txtb then
						text_box(unpack(split(entity.txtb,"⬇️")))
					end
					
				end
			end
		
		end
		
	end

end


function draw_sidebar()
	rectfill(cam_x+90,cam_y+74,cam_x+128,cam_y+128, 1)
	
	t_col = 13
	if mouse_on_sidebar then

		if mous_y-cam_y >= 93 then
			t_col = 7
		elseif mous_y-cam_y >= 84 then
			rectfill(cam_x+90, cam_y+84, cam_x+128, cam_y+92, 2)
		else
			rectfill(cam_x+90, cam_y+74, cam_x+128, cam_y+83, 2)
		end
	end

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
		local txt_x_off = 114
		if (#lvl_entities >= 10) txt_x_off -= 4
		if (lvl_ntt_limit >= 10) txt_x_off -= 4
		print_outl(#lvl_entities .."/"..lvl_ntt_limit, cam_x+txt_x_off,cam_y+10,7,4,8)
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
	
	sl_l += sl_r + sin(time_c/sl_spd)*sl_h

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
			
				if btnp(4) or btnp(5) then
					e_type += 1
					if (btnp(5)) e_type -= 2
					e_type = ((e_type-1)%#ntt_types)+1
				end

			else
			
				if btnp(4) or btnp(5) then
					e_extra += 1
					if (btnp(5)) e_extra -= 2
					e_extra = ((e_extra-1)%#ntt_extras)+1
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
			
			if show_ntt_details then
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

function reload_bg(bg_index)
	local bg = {peek(bg_mem(bg_index%32),8)}

	add(bg,bg[1]\16,2) -- unpack vars from a byte
	bg[1] %= 16
	add(bg,(bg[3]\2)%2,4) -- limit wrap to prevent accidental lag
	bg[3] %= 2
	
	return bg
end


function create_entity(e_type,ex,ey,e_extra)

	
	local entity = mod_tabl2({},"pos,template,extrainfo_loc",{vec2_new(ex, ey), e_type,e_extra})
	
	mod_tabl2(entity,"xtra_src,rds,mass,sprite",{peek(7676+e_type*4,4)})
	entity.rds/=10
	entity.mass/=20
	
	-- some defaults
	mod_tabl(entity, "is_left,coll_rng,actN,actF,rngn,rngf,Iarm,Irss,spr_size,d_o,outl/false,0,55,100,0,35,0,1,8,3,0")

	if (entity.xtra_src != 0) mod_tabl(entity,ntt_types[entity.xtra_src])
	-- props
	mod_tabl(entity,ntt_types[e_type])
	
	
	extraprops = ntt_extras[e_extra]
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
	
	lvl_bg1 = reload_bg(loaded_level_info[14])
	bg1_edited = false
	lvl_bg2 = reload_bg(loaded_level_info[15])
	bg2_edited = false
	
	
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

	pal({peek(8272 + loaded_level_info[12]%4*128 + loaded_level_info[12]\4*16,16)}, 1)


	-- defaults
	-- kinda obsolete names
	mod_tabl(_ENV,"time_c,t_enms,t_e_clear,t_tr_collected,t_trinkets,lvl_prevmus/0,0,0,0,0,0,0")
	mod_tabl(_ENV,"aC,lvl_enms,lvl_e_c,e_rq,llx,lly,grav,lvl_tr_c,lvl_trinkets,sl_l,sl_c,sl_smth,sl_vx,sl_vy,sl_dmg,alert,l_t_c,sl_r,sl_h,sl_spd/1,0,0,0,0,0,0.217,0,0,1024,6,0.982,0,-0.2,0,false,0,0,0.04,5")
	
	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1
	lhx=l_border_x
	lhy=l_border_y
	
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
	local bg1_packed = {}
	local bg2_packed = {}
	add(bg1_packed,lvl_bg1[1]+lvl_bg1[2]*16)
	add(bg2_packed,lvl_bg2[1]+lvl_bg2[2]*16)
	
	add(bg1_packed,lvl_bg1[3]+lvl_bg1[4]*2)
	add(bg2_packed,lvl_bg2[3]+lvl_bg2[4]*2)
	
	for i=5,10 do
		add(bg1_packed,lvl_bg1[i])
		add(bg2_packed,lvl_bg2[i])
	end
	
	poke(bg_mem(loaded_level_info[14]),unpack(bg1_packed))
	poke(bg_mem(loaded_level_info[15]),unpack(bg2_packed))

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


-- bgs are organized in 8x1 slots, fit inside 32x8 memblock, but +y is the lower num
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
				local index = loaded_level_info[12] + l_add
				index %= 12
				loaded_level_info[12] = index
			
			elseif l_set_cursor_pos == 14 or l_set_cursor_pos == 15 then
				local index = (loaded_level_info[l_set_cursor_pos] + l_add) % 32
				loaded_level_info[l_set_cursor_pos] = index
				
			elseif l_set_cursor_pos == 16 then
				loaded_level_info[l_set_cursor_pos] += l_add*4
			else
				loaded_level_info[l_set_cursor_pos] += l_add
			end

			if l_set_cursor_pos == 10 or l_set_cursor_pos == 11 then
				update_mus()
				if (not stat(57) or l_set_cursor_pos == 10) music(loaded_level_info[10], 1000)
			elseif l_set_cursor_pos == 12 then
				pal({peek(8272 + loaded_level_info[12]%4*128 + loaded_level_info[12]\4*16,16)}, 1)
			end
		else
		
		end
		
		
		if l_set_cursor_pos == 14 then
			lvl_bg1 = reload_bg(loaded_level_info[14])
			bg1_edited = false	
			time_c = 0
		end
		
		if l_set_cursor_pos == 15 then
			lvl_bg2 = reload_bg(loaded_level_info[15])
			bg2_edited = false
			time_c = 0
		end
		
		-- background settings 
		if l_set_cursor_pos >= 18 then
			time_c = 0
			if l_set_cursor_pos >= 28 then
				lvl_bg2[l_set_cursor_pos-27] += l_add
				lvl_bg2[l_set_cursor_pos-27] = lvl_bg2[l_set_cursor_pos-27] % 256
				bg2_edited = true
			else 
				lvl_bg1[l_set_cursor_pos-17] += l_add
				lvl_bg1[l_set_cursor_pos-17] = lvl_bg1[l_set_cursor_pos-17] % 256
				bg1_edited = true
			end
			
			
			lvl_bg1[1] %= 16 
			lvl_bg1[2] %= 8
			lvl_bg2[1] %= 16
			lvl_bg2[2] %= 8
			
			lvl_bg1[3] &= 1 -- keep limiting wrap stuff
			lvl_bg1[4] &= 1
			lvl_bg2[3] &= 1
			lvl_bg2[4] &= 1
			
		end
			
	end
	
end

function draw_bg(arr) 
	mod_tabl2(_ENV,"b_img_indx,b_pal,b_wx,b_wy,b_sc,b_prlx,b_ofx,b_ofy,b_timx,b_timy",arr)
	b_sc -= 128
	b_prlx -= 128
	b_ofx -= 128
	b_ofy -= 128
	b_timx -= 128
	b_timy -= 128
	
	
	local bg_sampl = {}
	for i=0, 16 do
		add(bg_sampl, peek(11776 + b_pal*4 + i%4))
	end
	if (cursor_pos != 37) pal(bg_sampl)
	
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
"1 x wrap: ",
"1 y wrap: ",
"1 scale: ",
"1 parallax: ",
"1 x offset: ",
"1 y offset: ",
"1 x timescroll: ",
"1 y timescroll: ",

"bg 2 image: ",
"2 palette: ",
"2 x wrap: ",
"2 y wrap: ",
"2 scale: ",
"2 parallax : ",
"2 x offset: ",
"2 y offset: ",
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
			local mempos = 8272 + dat_str%4*128 + dat_str\4*16
			mx = (mempos-8192)%128
			my = (mempos-8192)\128

			dat_str = dat_str .. " ("..mempos..", " ..mx .. "x " .. my .. "y)"
		elseif i==14 or i==15 then
			local mempos = bg_mem(dat_str)
			mx = (mempos-4096)%128
			my = (mempos-4096)\128+32
				
			p_col = 15
			if i == 15 then
				p_col = 11
			end

			dat_str = dat_str .. " ("..mempos..", " ..mx .. "x " .. my .. "y)"
		
		elseif i==16 then
			local mx,my,ind
			if (dat_str >= 8192) then
				mx = (dat_str-8192)%128
				my = (dat_str-8192)\128
			else
				mx = (dat_str-4096)%128
				my = (dat_str-4096)\128 + 32
			end
			
			dat_str = dat_str .. " (" ..mx .. "x " .. my .. "y)"

		elseif i == 17 then
			dat_str = dat_str .. "/" .. lvl_ntt_limit
		end
		
		print_outl(desc_strings[i]  .. dat_str , 0,16+8*(i-1),p_col,6)
	
	end


	for i=18, #desc_strings do
		
		local bg,t_col,off = lvl_bg1, 15,17
		
		if i >= 28 then
			bg,t_col,off = lvl_bg2, 11,27
		end
		local val = bg[i-off]
		if (i > 21 and i < 28 or i > 31) val -= 128
		print_outl(desc_strings[i]  .. val, 0,16+8*(i-1),t_col,6)
		
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
	
		local bg_sampl = {}
		for i=0, 15 do
			add(bg_sampl, @(11776 + lvl_bg1[2]*4 + i%4))
		end
		pal(bg_sampl)
		
		
		draw_pal(139)
		pal(0)
	elseif l_set_cursor_pos == 29 then
	
		local bg_sampl = {}
		for i=0, 15 do
			add(bg_sampl, @(11776 + lvl_bg2[2]*4 + i%4))
		end
		pal(bg_sampl)
		
		draw_pal(219)
		pal(0)
	end

	if (bg1_edited) print_outl("unsaved changes!\nlost if you\nswitch bgs",64,160,3,6)
	if (bg2_edited) print_outl("unsaved changes!\nlost if you\nswitch bgs",64,240,3,6)

	
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
			if bcheck(loaded_level_info[11], 1<<j) and fl&0b00111111 != 63 then
				fl &= 0b10111111
			else
				fl |= 0b01000000
			end
			
			poke(addr,fl)
		end

	end
end


ntt_extrainfos_pre=split([[/
p_a/t
next_e/11
rX,rY/20,0
rX,rY/-20,0
rX,rY/0,-20
rX,rY/-16,-16
Btyp,prst,rope,ai_a,rngn,rngf/5,t,nil,_V_funcaa,35,70
gi,boss/29,nil
boss/t
rope,rX,rY/1,76,-20
b_f/_V_d_ld
/
/
/
rX,rY/-16,16
txtb/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️-30⬇️44⬇️42⬇️2⬇️1
rope,rX,rY,rope_e/1,-45,-8,len➡️50
txtb/\f3(a terminal is unlocked.\nsome of the files seem\nto imply a mass\nsurveillance program.\nyou copy the data.)⬇️false⬇️98⬇️98⬇️104⬇️38⬇️8⬇️1
txtb/\fastaff is advised\n to only \fcgrab the\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1
decal/\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!\*f \*f \*f \*5 \^h\n🅾️\n\n\|c \-e+\n\n\|c\-f\^:10387c1010100010
decal/\f2\^o0ff\^:00008064320f0204 \^h ❎\|e\n\ng\|fr\|fa\|fb  \|e\^:0000070c90a0c0f0
decal/\f2\^o0ffk\|ee\|fep\n\n\|er\|fu\|fn\|fn\|fing\^;10387c1010100010
actF/600
actF,rngf,rngn,ai_a/600,160,25,_V_funcaa
gi/29
enemy/f
enemy,boss,sprite,outl/true,t,207,12
gi/15
next_e/39
actF,enemy/600,f]],"\n")

-->8
-- data
#include dropkicks_inc.p8:B

__gfx__
00000000555555545555555444444444aabbbaa900000009e9a8abeabaeae9abbe8448eab9b9b9b9ebebebebbbbbbabb44444445545b45b477777d7877787778
00000000555555445444444455555554b999999800000000e9e8b9e999999999bb8448baa89898988ae9e98a8b8998b84454545554a5a5ab7dd78788ddd88d88
00000000544444445444444454444444b9999998000aa990e9e8a999e9e9e9eebebeebea99a999a9aabaaba998b88b89454545454b5a4aa57dd788787877d888
00000000555555445444444454445454b999999800aa99999998a9e999999999b98bb89aaaaa8aaaaaeaaea9449bb94444545455a9b45baa7d78ddd8d8d888dd
00000000544444445444444454454454a999999800a99990e9e89999999999e9b98bb89a9998a9998aaaaa98449bb944454545459bba99a97788ddd8778d7788
00000000555555445444444454444454a999999800999990e998a9e999999999bebeeaea998a9999aabaab9898b88a89445454559a89aa9978d78dd8dd888dd8
00000000444444445444444454444454a999999800999900e9e8a9e9999999e9bb8448aa98a99999aaeaaea98b8998a845454545a9aa99a97dddd8d878dddd88
0000000055544444444444444455555498888889000900009988a99999999999be8448ea88888888baa99aa9aaaaaaaa555555558aa88988d888888d8dd88888
44444444555555552222222211111111aaae9999999999eaabababab00000000339993dd8444445a55555555ebebebeb54005554444444445555555589889988
44444444555555552222222211111111a9999999999999998a8a8a8a0ff00ff03d999dd38444454a500000058a8a8a8a540550545555555554444445489aaaa9
44444444555555552222222211111111bbaaeaae99999aaa888888880f0000f0dd3999338444444a50000005bbbbbbbb54550054444444445500005544899999
44444444555555552222222211111111baae9e9999999aee8998999900000000d339993d8444444a5000000599aaaa9955500054555555550550055044489999
44444444555555552222222211111111a9999999999999998888888800000000339993dd8444444a50000005888aa88855500054444444440055550044448998
44444444555555552222222211111111baeaae9999e9a9aa888888880f0000f03d999dd38444444a50000005888aa888545500545555555500055000554448aa
44444444555555552222222211111111b99e9999999999ee888888880ff00ff0dd3999338444444a5000000588aaaa8854055054444444445555555544444489
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
0d0000005455444445544544544545559bbbb9bb0300000073733333333393339993d09088888888737333739373333366666fd60dddddd0887dddd87f8dddd8
6d666000444445544454554445444554bbbabb9b00733070373333733333733300933d988888888837333337373373336666f6f6d8d66dd88f8ddd8f78f8ddd8
6d666600554555445444454545445544abb9ab9a0037d7003333333333373333039dd88888988e8e33373333833333336ff66f66dd6ff6d8787888f87d87888f
dfdffdfd5445545444445454445454449ab9a9aa037dd07033333333333333733d93d9908e98eeee3333333393838383f6df6666dd6ff6887d877f887d877ff8
dddddddd445544455544544444444444aa9a9aa9000000003333333337333737ddddd0808e99e9ee3838383808883838fd6f6666ddd668867d8788867d878888
66666600445444445444554455444445999a9a990000000039333339393333790803d9808999999e89898989398989736ff666660dd888608d8f88687d8f8dd8
66666600444444554444454454444455999999990000000093939393939333930893d800e999999e98989898380099336666666600886600d88f868dd88f8888
454445450000000000000000000000009899999999999989bbabbaab000000008e999e8e9a5a959a545450553733333305445050000000000000000054999999
545444440000000000300000030000008999999999999998999999990300000088999e889454a49a550505057333373305045550000000000555555054499a99
544444540088800000366000003330008899999999999988999999990033300088999e884954a4944055055533333333550555000000000005555554445999a9
444445440c8d8000003fff000067660058899999999999899aa999a90077d77088e9998895999994400500543939393905454505000000005555555445494999
4444444400cdd000006660000336d60058999999999998899aa99999033dd00088e998884549449a505505549393939305554555000000005454545445494999
4445444400800000000000000000000089999999999999859999aa99000000008889988849a9594a455005508989898900454500000000004545454555454449
44445445000000000000000000000000899999999999999899a9aa990000000088e999889aa49a59505055008888088805454500000000005454445555455459
4544444400000000000000000000000099999999999999899999999a000000008ee99e889a44aa59550554050808008004454550000000000404040455555454
454455455454554455545554555455549bbb99a99ba999995b5bb5b55b55bb5b44544f544a54ba5aba9bbab94545545510101010101010100000000570000000
54545454455454545554555455545544bbaaaa99ba999999bbbbbbbbbbbbbbbbf45faf54ab94aa4ba99babab4445545500000000000000000000000740000000
55444544545544545554555455544454aaaaaa9b99999bb9abbbaababbababbb5f5fafa4a9b9a99aba9b9ba94545544510101510101010100050007544000400
454545454554545544444444444444449aaaa9999999baa9ababaa9aabaabaabafaaffaf99aa9a9aba9a9ba94545544501050501010101010007505994044000
54545444545545545554555455544444b99999bbbbb9aa999a9aa9a9aaa9ba9abff8fbf9999a9a9aba9b9ba94544445510151510101010100005596666944000
45454445454544555554555455544454aaa9bbbaaa99999aa99b9aa9a9a99a9afaf8f9bf99a99a99aa9b9a994545545501050501010101010000965666690000
45455454454544545554555454444554aa99baaaa999ba9aa9ab9a9aa99a99a9baffbaa999999999ba9b9ba945455455111515521111111100756566f6664400
54445454554554554444444444444444a9999aaa999aaa9999a9999a999999a9a8fba88899999999ba9baba94545445501050522010101015759666f6f669444
50450405000500500000000000000000bbbabbbabba9bba90000f00099a99999f44b95af99999999ba9b9ba988888888545454541111111175596666f6669444
44540455050450450000400400000000baa8baa8baa8baa800f666f09a99a9995fa9fff5a99999a9ab9baab88888888854555455111111110055666666464400
04545454045540055054004005004500baa8baa8a998aa980f00600f99999a995ffb95aa99899a99ba8a8bab8888888854444444212121210000966664690000
54544044054040540405005454045040a8888888988888880f66666f9999a9a94aba9f5f99599999bb8aab8b8ea88e8845555555111111110005596666944000
55454540454540450545050445055405bbbabbba88b889880f00600f9a99a9aaff5994f5a9895999bababa8aaeaaaeee44444444212121210005505994044000
54504545505445554545454540050454baa8baa88baa898800f666f0a99999a95559ffaa5a858989a9baba8b9e999e9e44444444121212120050005544000400
54555045545445545405554554505455baa8baa8aaa9898900006000999a999af4b9f44459885989b9b998899999999e55545554222222220000000540000000
44545445045404555554555554545545a888a8888a98998903d666d3999999994f599ff488585885b99bab899999999944545454121212120000000540000000
4242654042b3f38070e5723070a2f13070e3753042c444804245c54042037280619481a00163b210e132d2c0e0f0114a4a420899084a4af7f718f7f7f7616262
62525a6942a0d94223c113716b72916b6b826bf9106b080848111111111111111111637a080872443c25c6546cc6b5c54446951c3c2c3c2c166464142cd41c8d
0101b6100143d5107044d51060c4f5404205f280b1c41540c1e25530c1f2f21002433320f0216210b141a2100101117a39200873084a4ae8e8e8e8e8e86171f3
7373f3694280d99b01fa213ad072636b8222826b7b0a3333f97060e40260e402607099297208729de6b5254497d5c5c575979f163cd43cd4c46754243cd42c7d
21a8a310f04252100154f31070a2333050c2838060aac23070c981304229b18042580480b1c1d350b1436601b0f011684b78080808084a020202020202f1f3d0
d8d0624379b831baba0a21818163638378826b5bb1f2f26058707070707070707070637a0808729796c6251f25d514b5741cc43c2cccd43cd454243c1cd41c7d
b152d401c152231002c5e2100254d2309141c11091c3c11070c2a5b1d16208b1b0d254c1d0d2343162d3c1c0f03111422960606060185a6f6f6f6f6f6f826a62
626a71d33178c383838383424263630808f2f2e2a168b1f163636363636363636363997a8708726cb5b5547474b5ac8c676c645454445c54141414145c54145c
739041d808101008101010c39081d8c7308038901010e17002a808280ac8111110423204086af010a7a151a0834180780858c10822101000811040d020200000
0236a281c1c67391e1055410c1c262910244728100000000000000000000000000000000080808087410282808ca080836102828050a080813102828050ae9d7
643204f8f82120f72010104641807808181008a01010ff1000080810100821611060320408834110689151b0610201a80728830a329110008100208020200000
d143153042b6b280d1b694400264a230d1a65510d1326530d1e4853042138580231028280b4918080000080808080808371038480a8a0808131058480a66daa7
a552607806101000301010054120780738c368c01010649081e897301038311010a5110508a6181008c17110963286f8c99010e742c0d100500020c000209000
42f4838002d36310c146131060d6043002467430c1d3043060b2c33001419410201028280b49f708552018f80a0808083710e70a0a0c0808243038080866e917
a03204f88970108750c110e67081a8b918a00cd0f0b1103204080a462008412110e1528008c890b07ab18110c3528078b930418e5210e1005000307000209000
7172031050e2b34040d1e6606011243040718760f031d51000000000000000000000000008080808811018080808080833102889bc0c0808243048880a4cda26
403204f8e4e0108840c110c33204f80a812008b0d030e10184d7f7101008613160e10201080848af08a09140239081d8870410db12101000310020d020200000
12d2832002c200f1708200f19141e1109162e1100215d22012c2d3e1f1f5a2d1100048880c280808811018080808e7083710288a086d08082410384808e8e908
649041d8b740704870a11055510108081010a8e01010a05141080810100871417000000000000000000000000000000000000000000000000000000000000000
f1431230f14555101291343012f124300133541050b6d34002686230f1c8a2d1141038185ae808088010182808d7b70830102809084b0808241058880829cb08
64528078172041b88010206412c0a80828cd08a09130829081d80810100881108000000000000000000000000271e4301235b5e1d182a530c174351002f45520
424224400181f210c1c3f21080d1c42080b3c4201283d130f1e16220f1f20210120058888388080820102838082c080800000808080808084010284808cc0808
643204f879a020e760c03064a181080a101008010110879081d80810100851109000000000000000000000008006c1303141e09061581130c15383307247f110
31d081b1f08bf11012f2d430f134c2303181f0a17251d41000000000e131f1c00510588805870808000008080808080894002808080c080860003809040d0808
000dd000fd666ddf000660000000000c00ddd60000ddd60000ddd6000066066006066600006066000000000000022000000cc00000d3ddd00dd3700000ddd000
0dddddd0d66d666f006d6000c088880c0dd666600dd666600dd666606060660006666066060666600002200002f77f200c3773c0033333ddd33777300ddddd00
6ddddddf6666f6f0006d6000c888877cf66f66f6fdf66f6fdf66f66f666066666066066066066006002ff2000f7777f0037dd7300d333880dd7773d000888000
66dddf686fddddf00666d600c778877666666666666666666666666606666006660666666666666002f77f2027777772c7dccd7c033c33dd377cc3330ddddd00
666f688f6fddddf06dd6d660c77dddd666666666666666666666666660066660666660660666666602f77f2027777772c7dccd7c033c3388777cc33308dddd00
66688f68666666f06dd6ddd086ddddd6ff6666ffff6666ff77666677666606660660660660066066002ff2000f7777f0037dd7300d333880d73333d000888000
066f6860d66d666f6dd6d66006dddd6077f66f7700f66f00007667000066060666066660066660600002200002f77f200c3773c003333388d333333008dddd00
00686600fd666ddf06666000000666000770077070000007000000000660660000666060006606000000000000022000000cc00000d388800dd3300000888000
00000000000bbb00000000000222000000000000000000000000000000000000000000000000000000000a990000000000000000000a99990000000000000022
000000002bbbbbb00222200022222200000000000000000000666600000000000000ddd00ddd000000aaa99900000000aa900000000a99999999000022222252
00000022bbbbbbbbbbb222222bbb22220044400000000000066666660000000000dddd6dd6dddd00aaa99a9900000aaaaa99000000aa99999999999925a2aa20
00022222bb2b222bb2bb222bbb22b20000444400000004406666666666000000dddd886dd688dddd9aaa999900aaaaaa9999900000a999999999999902222220
0222222bbbb212b222222bbb21221b0000444400004404446666666666660000d866d86dd68d868daa999a99aaaaa999aa9999000aa999a99999999902aa2a20
22bbb2bb2b2121221222bbb21211122004444400004404446666666666666600886f6d6666d6f6889aaa9999aa999aaaaa9999900a9a99a99999999902222220
2bbbbbb2b22bbbb12111bb2121111122444444004044044466666666666666660086f66ff66f6800aa999a9999aaaaaaaa999999aa9a99a99999999902aaa252
bbbb2b2221bbbbbb111bb212112221124444444044444444ddd6666666666666000d6f6666f6d0009aaa9999aaaaaaaa99999999a9aa99999999999925222220
bbb2b1211bbbb2b2111b2222000000004440000000000000dddddddddddddddd00ddd660066ddd00aa999a99aaaaa999aa999999a9aa99990000060000000000
222212bbbbbb222112b22211000000004444440000000000dd666666666666660d8d68600686d8d09aaa9999aa999aaaaa9999999aaa999900006c0000066000
1212bb2bb2b21212222121110000000044444444000004406d666666666666dfddd8068668608dddaa999a9999aaaaaaaa9999999aaa999900000c66660c6000
112bb2222b21212212111b2200000000444444440004444066d666666666dfdfdddd686ff686dddd9aaa9999aaaaaaaa99999999aaa9999900007688886c6000
1bb22212222211212111b221000000004444444400044440d66ddddddddfdfdf8ddd086ff680ddd8aa999a99aaaaa999aa999999aaa999a90088788788c60000
bb21211122111211111212110000000044444444440444400d6f6f6f66dfdf0080ddd086680ddd089aaa9999aa999aaaaa999999aa9a99a900086dd78c860000
12121111111111111121211100002220444444444444444400dddddddddf00000606d000000d6080aa999a9999aaaaaaaa999999aa9a99a900006ddd8c800000
112111111111111111111111222222224444444444444444000d66666d00000000606600006606009aaa9999aaaaaaaa99999999a9aa9999000006d888800000
002222220101111111111111000000007d0000d36df0000001000000000000000033733333733300000898a6ccc666cc66cc6aaa000000000000006886000000
022222bb101011111101011100333c00d730033806df0000006010600100063603733337333333300008998a666777666ccc6aaa000000000088800666000000
2222bbbb1101010101101011037cccc003dddd30006df000063600000000066603333333333337d000089986667666776ccc6aaa0000000088aa66ccc6600000
222bbb2b010000101011011003cccc8000d7c800000df00010000010100010000d3333ddddddddd000089967766777766cc66aaa00000088aaaa6ccccc660000
2bb22222001000000101000103cccc8000dcc8000006ff00001000010010001008d888888888888000089677677777666666aaaa000088aaaaa6c6ccccc68800
bb21212100000000001000000cccc88003d88d300000df0000006060663660010080888808880880000896767776666aa66aaaaa0008aaaaaa6cc6ccc6c6aa88
12121111000000000000000000c88800d330033800006ff0010666660060100600008008008000800008967677666aaaaaaaaaaa00088aaa66cc6cccc6c66aaa
112111110000000000000000000000003800008300000df0000013000100000000000000000000000008967677768aaaaaaaaaaa000888a66ccc6cccc6cc6aaa
0032804000a1c01500802000812350048123500b812360d400c3304b8187c36c000240ab0041805400e1203e008209e000a582fc20418075b08240db0032104e
8123a08d81b4871b70c88c8c0041a0bb9000907181a5c18c203280350023a0048141419e0064097b0037418e7005508d8164a0e681d250677005054b7064508c
81c14025000a41009023100081c380c44141e0ab700f0a8cb0e1205e000000000000000000000000000000000000000000000000000000000000000000000000
__label__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
8888888888f88888888888ff88888888888ffeeffffffffffffffff8888f888888fffffffffffffffffffffffffffffffffffffffffffffffffffeeeffffffff
88888888228888888888888888888888882feeeeffffffffffffff8888288888888888f88888888888ff88888888888f888888888fffffffffffeeeeeffffff8
88888888888888888888288888888888882fffffffffffffff88888822888888888882888888888882888888888888288888888888ffffffefffffffffffff88
88888828888888888882288888888888222ffffffffffffff888888288888888888828888888888828888888888822888888888882ffffffffffffffff888888
2222222288888888822288888888888282ffffffffffff888888882888888888882288888888888288888888888288888888888882fffffffffffffff8888882
2222222222200000022222222220000022ffffff0000088222222200000222222222000022000002222200000222200000222222220000ff00000f8880000028
88888888220cccccc0888288880ccccc0f888800ccccc028888880ccccc088888880ccc000ccc0088820ccc0188000cccc02222220ccc000ccc008820ccccc02
8888888280ccccccc088288880cc000cc08880cccccccc0888880cc000cc0888880ccc00cccc0018820ccc01d800cccccc0222220ccc00cccc001220cccccc08
888888280ccc0cccc02288880cc0660cc0880ccc00ccc0088880cc0660cc088880ccc0cccc00111820ccc01d10cccc00cc0ffff0ccc0cccc0011180ccc0ccc08
88888280ccc0d0ccc0888880cc0d60ccc080ccc0d0ccc018880cc0d60ccc08880ccccccc0011dd120ccc01d10ccc00110018880ccccccc0011dd180ccc0cc002
2222220ccc0d60ccc022220ccc000ccc010ccc0d60ccc11220ccc000ccc01220cccccc0011dd1220ccc01d10ccc011dd111220cccccc0011dd18880ccc000018
888880ccc0d60ccc018880cccccccc0010ccc0d60ccc01d80cccccccc001180ccccc0011dd11880ccc01d10ccc01dd1188880ccccc0011dd1122000ccc0111d2
88880ccc0d60cccc01820cccccc0001110cc0d60ccc01d10cccc0000011180cccccc01dd118880ccc01d180ccc0d11888880cccccc01dd111880cc0ccc01dd18
8880bbbb000bbbb01d20bbbbbbb011dd0bbbb00bbb01d10bbbb0111111180bbbbbbb011118880bbb01d180bbb0111888880bbbbbbb011118880bbb0bbb011188
880ccccccccccc01d10cccc0ccc0dd110cccccccc01d10cccc01ddddd180cccc0ccc01188880ccc01d1880cccc00088880cccc0ccc01188880cccccccc011882
20bbbbbbbbbb001d10bbbb0bbbb011220bbbbbbb01d10bbbb01d1111120bbbb010bbb022220bbb01d18880bbbbbb08880bbbb010bbb0888880bbbbbbb0118828
0bbbbbbbbb0011d10bbbb00bbbb0888810bbbb001d10bbbb01d1888880bbbb0110bbb02220bbb01d1222210bbb001220bbbb0110bbb02222200bbb0001d12222
000000000011dd10000000000000888811000011d10000001d1888880000001d11000008000001d1228886100011d20000001d1100000888810000001d188888
1111111111dd11811111111111118882611111dd18111111d1888882111111d18111111811111d128888816111dd18111111d1811111188886111111d1888888
666666666611188666666d66666d882816666d118866666d1888882866666d18866666d86666d1288888881666118866666d18866666d888816666d118888882
11111111111888811111111111112222211112222211111122222288111111888211111811111288888888811128881111118828111118888811111888888828
22222222222222222222222288888888882888888888822888822222222222222222222222222222222222822222222228889999922222222222222222222288
88888822888888888822222888888888228888888888288888888888288888888888288888888888999999998222222288999999999888888888822888822222
88888288888888888222ee8888888882888888888882888888888882888888888882888888888829999999888822222889900009999998888888288888888888
888828888888888822ee888888888828888888888828888888888828888888888228888888888299999999999998888889990000000998888882888888888882
882288888888882222ee222222222222222222222222222222222222222222222888888888882999999999992299828888999900999988ffffffffffffffffff
2222222222288888888e8888888888888228888888888288888888888288888882222222222222990099999992222222222999009999999922999922fffffff2
8888882888888888888e88888888888828888888888828888888888828888888888228888888888002999998822288888899990999999999989999999888888f
88882288888888888888888888888882888888888882888888888822888888888828888999988829999998882288888888999009999000099999999999888888
88828888888888888822888888888828888888888228888888888288888888888288889999992299999988888888888899990099999090000999900999998822
88288888888882222222222222222222222222222222222222222222222222222222222229922299998888888822888999990999990099900999000009998288
222222222222222222222222222222222222222222222222222222222222222222222222229222f2992222222222229999000999900999900990099999922222
ffffffffffffff2222ee222222222222222222222fe2222222222e2222222222222222222222fff2922888888888899000000999909999009990999999988888
8888fffffffffeeeeeeeeeeeeeee22222222222fffeeeeeeeeeeee2222222222222ffffffffffff2928888888888299990000009009990099900999999988888
8822fffffffffffffffffffffffffff22222222fffeeeeeeeeeeee2222222222222ffeeffffffffff88888888882999999999909909990099900999999998822
ffffffffffffffffffeeeeeeeeee22222222222fffeeeeeeeeeeee2222222222222feeeefffffff8888888888828889999999999999999999990099999998822
2222fffffffeeeeeeeeeeeeeeeee22222222222fffeeeeeeeeeeee2222222222222ffffffffffff2222222222222229299999222992299999999000990998822
22fffffffffeeeeeeeeeeeeeeeee22222222222fffeeeeeeeeeeee2222222222222ffffffffffff2222222222222222299292222292299229999099999988822
fffffeeefffeeeeeeeeeeeeeeeee22222222222fffeeeeeeeeeeee2222222222222ffffffffffff22222222222f22222922922f2222299229299992992222222
ffffeeeeeffeeeeeeeeeeeeeeeee22222222222fffeeeeeeeeeeee2222222222222ffffffffeeefffffffffffffffff222292ff222229922922992229222222f
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeeeeeeeeeeee2222222222222fffffffeeeeefefffffffffffffffffffffffffff9ffffff9922292222fff
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeeeeeeeeeeee2222222222222fffffffffffffffffffffffffffffffffffffffff9fffffffffff9fffffff
ffeefffefffeeeeeeeeeeeeeeeee22222222222faaaeeeeeeeeeee2222222222222fffffffffffffffffffffffffffffffffffffff22222222222fffffffffff
feeeeffffffeeeeeeeeeeeeeeeee22222222222faaaaaaaaaeeeee2222222222222fffffafffffffffffffffffffffffffffffeeee22222222222222ffffffff
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeaaaaaeaaaae2222222222222ffffffffffffffffffffffffffffeeeeeeeeeee22222222222222ffffffff
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeeeeeeaaaaaaaaa2222222222fffffffffffffffffffffffeeeeeeeeeeeeeeee22222222222222222222ff
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeeeeeeeeeeeaaaaaaa2222222fffffffffaffffffffeeeeeeeeeeeeeeeeee2222222222222222222222222
fffffffffffeeeeeeeeeeeeeeeee22222222222fffeeeeeeeeeeee2222aaaaaaa22fffffffffffaffffffeeeeeeeeeeeeeeeeeeeeee222222222222222222222
eeeee2fffffeeeeeeeeeeeeeeeee22a22222222fffeeeeeeeeeeee22222222aaaa2ffffffffffffafffffeeeeeeeeeeeeeeeeeeeeee222222222222222222fff
eeeee22ffffeeeeeeeeeeeeeeeee22aaa222222fffeeeeeeeeeeee2222222222222fffffffffffffaafffeeeeeeeeeeeeeeeeeffefffffffffffffffffffffff
eeeee222fffeeeeeeeeeeeeeeeee2222aa22222fffeeeeeeee22ee2222222222222f101f0f111fffffaafeeeeeeeeeeeeeeeeeeeeee222222222e22222222222
eeeee2222ffeeeeeeeeeeeeeeeee22222aaaa22fffeeeeee2222222222222222222f100000101ffffffaaaeeeeeee111eeeeeeeeeee22222eeeee22222222fff
fffffff222feeeeeeeeeeeeeeeee2222222aaaaf22eeee222222222222222222222ff00111001f1ffffaaeaaeeee11e111eeeeee11eeeeeeeeeee22222222222
feeee222222eeeeeeeeeeeeeeeee222222222aaa22eeee222222222222222222222f1011f1111f11ffffaaeeaaeeeeeeeeeeeee11111eeeeeeeee22222222222
eeeee222222eeeeeeeeeeeeeeeee2222222222aaaaeeee2222222222222222222220001fff101fff11fffaaeeeaaaeeeeeeeee111ee1eeeeeee2222222222222
eeeee222222eeeeeeeeeeeeeeeee22222222222faaaaee222222222222222222aa211111f1111ffffffffeeeeeeeaaaeaeeeeee11e111eeeeeeee22222222222
eeeee222222eeeeeeeeeeeeeeeee22222222222f22aaae22222222222222222aaeee10011100ffff1ffffeeeeeeeeeeaaaaaeeee1111eeeeeeeee22222222222
eeeee222222eeeeeeeeeeeeeeeee22222222222222eeaaaaaa22222222222aaaaaae10010000022221fffe1eeeeeeeeeeaaaaaaee1eeeeeeeeeee22222222222
eee22222222eeeeeeeeeeeeeeeee22222222222222eeeeaaaaaaa22222aaaaaaaaaee11e01a1112221122e000001111eeeeeeeeeeeeeeeeeeeeee22222222222
eeeee222222eeeeeeeeeeeeeeeee22222222222222eeee22aaaaaa22aaaaaaaaaaeeaeee11aaaaa000000000000000011111111111eeeeeeeeeee22222222222
eeeee222222eeeeeeeeeeeeeeeee22222222222222eeee222a2aaaaaaaaaaaaaeeeeeaaaaaaaaaaaa222ee000000000000d000000111111111eee22222222222
eeeee7777777ee11eeeeeeeeeeee22222222222222eeee222aa22aaaaaaaaaaeeeeeeeeaaaaaaaaaaaaaee110000000000d00000000000000011112222222222
eeeee222222eeee11cccceeeeeee22222222222222eeee2222aa22222aaaaeeeeeeeeeeeaaaaaaaaaaaaaaa10000000000d00000000000000000011112222222
eeeee222222eeeeeee111ccc11ee22222222222222eeee22222aaaaaaa222eeeeeeeeeeee2aaa2aaaaaaaaaa110000000dd00000000000000000001122222222
eeeee222222eeeeeeeeeee111cc1121122222111111111111111122222222eeeeeeeeeeee2222aaa222aaaae111110000d0000000000aa000000001222222222
eeeee222222eeeeeeeeeeee1111111111112222222e11111111111111111111111e11111122222211aaaaaaaaaaaaaaa000000000000aaa00000001222222222
eccccccccccccccccc111111121117711112111111eeee222222222211111111111111111111111111111aaaa11aeaaa11000000000d000aaa00012211122222
eeeee211ccccccccccccc122111777771d11ccc11111111111111111111666666666666666666677777777771aaaaaeaa1a11000000d00000aaa012100011122
cccccccccccccccccccc1122211777771dd1cccccc66666666666666666666666666666666666677777777777111aaaaaaaaa100000d0000000a012100001122
888888ccccccccccccccc122221177711dd11cccccccccccccccccccc11666666666666666666677777777777771111aaaaaa1dddddd00000000188110001888
22222211cccccccccccc11222221111ddddd1cccccccccc66666666666666666666666666666667777777777777777112aaa10000dd000000000122221001212
88888881cccccccc1111112222221ddddddd1ccccccccccccccccccccc11666666666666666666777777777777777aaaaaaa00000000000d0000188822100211
2222222111cc11111122212222221ddddddd1ccccccccccccccccccccc1166666666666666666677777777711111aaaaaaa100000000000d0000111222211211
88888888211118822222222222221ddddddd1ccccccccccccccccccccc1166666611111111111111111111111711aaaaaa100000000000ddddd0100011118881
2222222222222222222221111111111111dd1c1111111111111cccccccc1166666666666666666677777777777777a7aaa10d000000000d000dd100000001111
888cccccccc111111888211122211777711d1cccccccccccccc1ccccccc116666666666666666667777777777777771aa100dddd000000000000111120000000
888888811cccccc1111111111111177777111ccccccccccccccc1cccccc116666666666666666667777777777777777aa000000dddd000000001811811118800
22222221cccccccccccccccc112117777711ccccccccccccccccccc666666666666666666666666677700000000000000000000000ddd0000001211188811111
8cccccccccccccccccccccccc11117771111c111111111111116666666666666666666666666666677777777000000000000000000000aaa0011881188888888
888cccccccccccccccccccccccc11111111111828888888888888811111111116666666666666666777777777777771100000000000000000012288888ffffff
8888cccccccccc1111111111111111118888882288888888811111111111111111111111111111aaaaaaa11111171110aaa000000000000000182888ffffffff
222222222222222222222221111ccc12222222111111111111111111111111111111222222aaaaaaaaaaa2222a11100000aa0000000100000012222222222222
88888888888777777788881ccc111886666666666666666666668882288888888888888aaaaaaa288aa888aa00000000000a0000000100000118822222888888
888888888882888888811ccc188888888882888888888888888222222888888888888888888888aaa88aa10000000000000a0000011100000188888888888888
8888888887777778881cc888888888888822222222888888888888888888888888888888888aaa8288aa80000000000000000011110000111188882222222222
888888888888888888888888888888888888888888888888888888888888888888888888aaa88800000000000000000111111111111111188888888888888888
8888822222888888888888888888888888888888888888888888888828888888888888aaa8888882a88888800000000011888818228888888888888888888888
22222222222222222222222222222222222222222222222222222222222222222222aa2222222222a22211112211112221222122222222222222222222222222
8888888888888888882228888888888888888888888888888888888888888888888aa88888888888a88882221118888111881888882a88888888228888888888
888888888888888888228888888888888888888888888888888888888888888888a8888888888888a8822222288888111881818888aa88888888282888888888
88888888888888888888888888888888888888888888888822222222288888888aa8888888888888aa8888888888811888181888aa8888888888888288888888
88822228888888888888888888888888888888888888aaaaaaa88888888888888a888888888888888a888888888811888888888a888888888888888822228888
88822222222228888228888888888888888888888888888888aaaaaaa8888118a8888888888888888a8888822811188888888aa8888888888888888888888888
8888888888888888822888222222228228888aaaaaaaaaaaaaaaaaa88aaa811111111111188888888a888888881888888888a888888888888fffffffffffffff
888888888888888888888888822222aaaaaaaaaaaaaa8888822222288888111111111111111111111a88888811288888888aa8888888888888888ff888288888
88888888888888888888888888888888888828888888888888228888888111888811888888811111111111111888222228aaa888888888888888888888888888
888888888888882222222222228888888882888888888888888888888118888111888888888888aa11111111882222228aa88888888888888888888822882288
8888822222222222888888888888888888222888888888888828888111111111888888888888aa8888881188888888888a888888888888888888888888888228
fffff888888888888888888888888228222222222222822222221111111112222222222222aa2222222222222222222222222222222222222222222222222222
88ffffffff88888888888888888888822222222222228888881111882111222222222222aa222222222228888888888888888888888888888888888888888888
888888888888fffff88888888888888822222222111288811118888112222222222222aa28888888888822888888888888888888888888888888888888888888
888888888888888888888882222222222222222111821111881111118888888888888aa888888222222222222228888888888888888888888888888888888888
88888888888888888888888882222222222222118111118811188888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888822222222221111112888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888882222222221111111111188888888888888888888888888888888888888882222222222888888888888888888888888888888
88888888888888888888888888822222222111222888888888888888888888888888888888888888888888822888888888888888888888888888888888888888
88888888888888888888888888822222111111228888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
fff88888ffffffff8888888888222221111112282288888888888888888888888888888888888888882222222288888888888888888888888888888888888888
ffffff88888888888888888888222211111122888888888888888888888888888888888888888888888888882222888888888888888888888888888888888888
fffffffff88888888888888882221111111128888888888888888888888888888888888888888888888882222222888888888888888888888888888888888888
8888888888888888888888888221111111128888888888888888888888888888888888888888882222222222228888888888888888ffffffffffffffffffffff
8888888888888888888888822888888881288888888888888888888888888888888888888888888822222222888888888888888888888888ffffffffffffffff
88888888888888888888888222211111888888888888888888888888888888888888888888882222222222222222228888888888888888888888888888888888
88888888888888888888882222211111228888888888888888888888888888888888888888888888888888888222222888888888888888888888888888888888
88888888888888888888882222212112288888888888888888888888888888888888888888888888888888882222222222288888888888888888888888888888
88888888888888888888888222111122288888888888888888888888888888888888888888888888888822222222222288888888888888888888888888888888
88888888888888888888882221111222888888888888888888888888888888888888888822222222222222222222222228888888888888888888888888888888
22222228888888888888882221112288288888888888888888888888888888888888888888888882222222222222222228888888888888888888888888888888
22222222222222222222222222212222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222211222222222222222222222222222
fffff222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222212121212222112112121222211122
ffffffffffffffffffffffff22222222222222222222222222222222222222222222222222222222222222222222222222211222122222121212112211212122
ffffffffffffffffffffffffffffffffffffffff2222222222222222222222222222222222222222222222222222222222212122122222122212121222211122
22222222222ffffffffffffffffffffffffffffffffffff222222222222222222222222222222222222222222222222222211222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222fffffffffffffffffffffffffffffffff222222222222222
2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222fffffffffffffffffffffffffffffffffffff
ffffffffff22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222ffffffffffffffffffff

__gff__
80080808010001010101010188810303088888880101010001010801088808080808080801010101410101088c8c81810808080801018101410101010188888100080808010011110101111100002323080000000101010001010811080008080808080801010101410101080000000008080808010100014101010108000000
0000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000008080800000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d400000000d3c0c1c2c30071707173727371736d6d6cc0c1c2c36d001c00363600001c00000000000000006d6d6d6d6d6d6d6de6e7e7e6e7e7e6e700000000000005008f0f068e8f0007820288080c0d020a8e8a870c018300070081838b0e8d818903818c06008100070082020e0c0d028700
cace00dbdc00dd36c4d5c5c4c510c4c5c0c1e0d1d0d1d0c36160417061616060c2c1e0d1d0d1d0c300361e363600001c000000000000dedf7d7d7d7d7d7d7d7de6e6e7e6e6e6e6e600000000000000008f0f06808200078288088f0c0d880a8e0f070c858d0007008004090e0d82898f020e06808200078202888f0c0d020a82
da36d5dbdccadd361010101010101010d0d1d2131313d2d26042434143424260d0d1d2131313d2d2001c0054361e1e360000000000edeeef1212121212121212e6e7e6e6e7e6e7e76d6d6d6d6d6d6d6d0d06868d0d0007008181018c8581098d8082068082000781858d0d8c0d820800880e068082000782888e0f0c0d880a02
da3607dbdcdadd361010101010101010e1e1e2e1e1e2e2e166666766676767661313131313131313001c00363600001c00d3c0c1c3eaebec1212121212121212e6e6e7e6e7e6e7e67d7d7d7d7d7d7d7d0607868d0d00070001018c0c8501090d89090688080007028280000c0d820a0880858680850007820d06060c8d0d0800
ccddddcc012020208a464746b8202020042727264746070641202020676667661b0a1b1b005c00015e0a5e0bdc08881c20a0a020020201022121212120202020717071719a9a9a9a60101010202020243636373e0000000014f676766667143677253636363614155b4a5b5b001c001c001c001c1e415e415e415e5e1f363636
988989982020212047012020b8032003143636154607060741410303767676760008005c005c001c1e088008dc08881c02070702e0e0e0012222222202020202617060709a9a9a9a601010102020202436373e010000000014f676767676143676f936f936f914158b8b8b8b001c001c001c001cc01cc01cc01cc0c03d1f3736
985455982120202046200210b8012001143636370707070727262627f6f676761e081e5c0b0a0b0b0b0a5e0b1e0a8a0102393902e0e0e0020202020203cf02ce60636160020202026010101074747424363e3d210000000014f676767676143776d914d936d914151e011e1e5b4a5b5b000100015e415e415e015e5e02105f37
985455984747474747201010b8202020253636360707070737363636f6f676760008005c0008001c00081c08dc08881c20a0a020e0e0e002ce02cfce2627262663626163a0a0a0a060101010757575243e2102200000000014f67676b9b9041576e925e925e93715001c00008b8b8b8b001c001cc01cc05cc0c0c0c03d1dbd5f
e0e0e0e002e0e00202020202101010102464652501d0d03c203d2002187655980223230200000000060706002b2b2b2b1ee1e0e1e0e1e178e0e0e0e0001c001c000000000000000000000000000000002020202020202020767676766a6a6a6a2103212036377677000000000000000035343434041d1d022f3f3f2f16161616
e0e0e0e020e0e0201ae0e01a2020202025646524222203a2aaaa2a2a18765598231d213d72723232060706002b2b2b2b30e0e0e1e1e0e178e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf76767676babababa62626262373976760000000000000000467676762523233d220c0c342e2e2e2e
e0e0e0e020e0e0201ae0e01a21202020256465251d1d11bdeaea2a2a18765598231d033d424242021b1b1b00212020211ee1e0e0e1e0e0781e011e1ee0e0e0e00031c32b30313031000031000000000002026626470706077676767602020202262726272001b9b941323232323232324676767624f5f5f434350c3439393939
e0e0e0e002e0e0020202020202cecfcf246564253b3b3b3b7a7a3a3a187655980202020261606060409c400003202120001c011c202121b800000000e0e0e0e032c3c32bb0a120303133b0b132323232222276367636063676767676101010103939393921102120161616560202cf0235aeae352f3f3f2f2f3f222f22222222
80808080803333af388080801819831273808093bcb7bcbc9c80bb8080808080808080188080808383128080808080b780333333a033333318198080808080980524808080248080808080802a182480808080808080803c3c803abbbfbf3c1a3c3c3c1a1d1a1d1a1a3f3f3f3ca11a3636369936173607070707808312bbbb18
1a8aac1d0635c7a0a0bbbbbb181934014f010106b8b8b5b81d8037a01d80809b80a01e18bbbbbb83831280808080bb0080a0a0afafafa0a0181980808080803c3c3cbbbbbb248080808080809c18241d1d241d8f1d8f8f0b1c29b7bbbb1c0b1e1e0b801c1c1c1c1c2cb6b6b634062cb69f3f3f3f3c9411111f3c800012b6b618
8088a01b18191daea0931893182797181818181827b720272f2928a02f29298e29a02937b6b6b683831229292929b627801eaeaeaeaeae1e2933802b29332929040734068f37293230328029343406061d8c09bc87bc973c3c20b6b6a1860b1e800b801c1c1cac1c343cb6b90606852825b6b6b638389392b6a6292712b6b6b7
8080ad1d1f199c809c931834062720b7b7b7b718271220278f8f0f3506060f8f8f063501b6b6820d858e8f068504070733331b338080808007070786041b07060d3797363686260407862981b48505241d8a1a1ab99f978f2501069b9b9f8080c01a801c1ca01c1b3c3d06851a1a1a3c3c3c3c3c3c3c3d853c3c078406063585
30801aa0a3239c809cb601971827014f010106060012202704163690243636041818043686063507240736363636142c2e2c2e2e8080808036363636991c173607070707363636363607070707073624bd1b06242486853c3c3c9a9a9a973c1ec080801b1b1b1b8080808080808080fa6445c0c05272716c6c79c35a5a797676
068080ae18199a9a9a9a199718181818181897182712202707071736391799363636363c3c363636363636363636a11a3438db381e1e1e3780fbfb271896968080bbbb8080978080801c801c8080922020121c802480808080802e1f86b7bcbc25bcbc80808097bbbbbbbbbbbbbb716464457271524dc35b806c6c5d72505f76
1880808018199a9a9a9a1934061818181819171800122027069f99144e2e2eb2200b7fb92020b7b79f02b7b7b7b78086802c2c0ba78080755b0d20271896b68080afaf8080b62980801c801c29bb20200f351b9b248080808080802e9f963f3f02bcbcbbbbbbb447472e2e444747f86464455a6c52cc6c6c80dc6c5b6e6ccf79
18b3b33023811d1e1d1d19971836361111939736271220279997993402f01a08200b203820b80780808080bbbb87809f801a1d0ba7808080192020271896962929230e292934b8a9291a801a8185040799121c801a80808080808080801a08342c1f99860606857676505064d97676446445c05b52459a9b5b9bdc7971505f47
370c9a9a37370d37963406a681252501012534010012202724818187811a2e8b81818181351608808080800c2096802e80801b0ba7808080254141971896844584474707458417248638b8380799163617043506388080808080808080808b1a1c803c92249224d979c1d164445879d9646a7279526adc6e5d805b50615ae857
07474707860f063506b8b83838363636363697362712202708f6f61af638c78bf61bf6a4051689060606060617bd060606068a3fbbbb5a8018181997189696b6b6b6a0808087bbbbbb803a8080bbbbbb3a333337b0bab33a3abb3a8080808b1aa11d16a73aa30179c1745744f9614dc3e34646cf525071506a716141c25061d7
8080808080808080bbbbbb1b360736368080801c1c1c80808bb9f6f6f69f968bf60bf6f69f361111f6371e1d1e1e1d808080800101b65cf0b7b7b7ad8e8e96a626b61133bbb7b62626bbb73037a1041c9f340c3f3f3f342525a6a58080808b1d801b99a7b72036c2c1575879c374f86d78767676c6cf5b5bc45b5b455b7878c5
80808080333333330c0607073c3c36368080801d2c1d80808bf6f6f6f6f6f68bf6f6f6f6f60b2201281a801bac801b24a424929307a4074507070735b8013d06a1b6b63c3c3d38bc069b9b9b3d26269b3c07070606353c3f1a1a80808080801c80801a80372e2747fd5fd6c3c357d9c759808080808080321031507180808080
2a8080801a1d3c3cb89936360b0b363680bbbb2f2f2fbbbb891b09091b1b1b891b1b1b1b1b9996b7a180808b1eac0bf0202d1220802012802bbb8004bb0496b6a18cb61f1616bf1a1a9a9a9a1a1a1a9abf3c3c3f3f1a1a808080850707070707079826a74080275759c6cfd1c2cf78f85680805a801aae2cce4dc1b972808080
1e1d5aa01d1c983f363636360b0b36360a3c3c3c3c3c3c3c80808080703333373c3c8080b7b71e1e0080801aac1e0bb7b436070736a4242b3783bb16811696b6b6adb6b69f80aa808080802412808312808080801819bb3abca49e9d9d06348ab79d36a79f8027456e456a5c717280458080805d80801a2c41c34c742c806a80
2a1c1c1b1b853c3c363636360b0b36361b3f3c3c363c3c3f71726a727f049d9e02258080008e8e8e271e1e1e1eac0b24b406062597a42401b84f8f038216963565e5a6b6978baa8080a2ac2412808312808080318117a1b797a50f25259786250fa536a737a29f6e805a6c5c6c6a5b5b5b715a5c8072711cd6c261975c717872
1b1b042a0b3f3f0b36363636363636360a808c1636368c80c64144f80625a50f0136808027f6f6f62780808080983c921201252597929336363636122b163d06931794b6858b2a02bb80a08312298397028080968436a1b697363636362d3636363636a726a2978080716c5ac35d6e6c45c14d5071417450684141525b4150c1
00010200000001000001010001010201010202010405000005040404000405058080808027a3a3a32780808080800ba4929f363636929302b7b7828c0c56b6a5250363a1241c0aa71b80a0981819868712a1bbb9363686b43c3f3f3f3f833f3f3f3f99e7af2e85458052415d624180804547c6c545455747474747474745c646
048d250107ae220104ab2d040d6d23112224281505493008074d1e03062325100666230125a8a3a8353a3a3a3a3a0ba7809714809f2da4b98c914ef6f6569616363637a1161c09a79632ae3818181904073506053614aaa09f11111111111111111136a778802748696d456a5a5a6a8045507172807271727172f38080727150
04332d0207242902044d280705742504224f2816076d38010b1c2701084c360a0000000036454545aa1a1a1a1a1a0b24a4a91233930393bd8fb7043d4e16963737b7a6b69f8b0aa7342ca02c2b2719993636363636b680a09307b83838383838b80736a71c80274543525ac3526c6c5c456447c15047f8c3c3f8467150c36464
051739030f0d2f01043f3502073920030743220124653808220f6e170d1533141232320307472b01125a3201808080022001802693038236368c1607bd16963f373c02b6978b0a881a1aae018127193c3c3c3c3c1428808084a54f25a54fa5254fa536a798a7366ac2526c41525c5c5ccac476c3c37979524de379c2c3f5d864
__sfx__
010900001802018020180701807118061180511804118031180211802118021180211801118011180011800109000100000e0001000000000000002b0502c0503005030031300212b01030020300103002130011
0013800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
010300000c57018570185701857018550185301852018520185100000018570185701855018540185301852018510185001850000000185701855018540185301852018510185101850000000000000000000000
0103001e0c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c10011100
49100020143261b3160f3201b326143101b3100f3201b3160fc701b4100f4261b4160f42011410124200d3200f3200f3101632016316163200f4200f32014420140111422014426144100f4101b3201232011320
631200001b4251b425194251b420366101e420336211b4200f420164203361619420386121a42036625366101b4251b325193251b426366101e420366161b4200f32016420366111942038610224203861538615
5302000019353063300142003620036200961001610183730537301373016700566002660086500f6500165006645056450064004630086300663004630036300762006625056250162503620036200c61002613
020400003b6303b6313b6313963136631326312c621256211e62117621156211562115621166211762117611196111a6111b6111d6111f6112161123611246112561127615286152861529615296142961429614
53111b00193001b30019300193001b300193000860019300000001a300006001b30006600183001e300000001b3000160003600036000c6000260004600016000160000600086000060008600000000000000000
0a0116001276016770197701b76022760257602875000000000002c6702c6702c6402c640000003b6703b6703b6403b6353b6303b6203b6203b62500000000001370017700187001c70000000000000000000000
51020000123430d623036210d32119321253353c6200e3330c2233762329623366232503406220276200822036600032200000000000000000000000000000000000000000000000000000000000000000000000
53011d00143710d371043610136100350366602535025370366703667036670366503665036650366503665036650366503665536655366453665536665366453663536625366203661036610366003660000000
0924002016514165101651016515165141651016510165151e5141e5101e5151f51420511205102051020515165141b0100a52416510165101651522514225102051120510181151b51022510191101a1151b115
0a0120003e6303d6303d6203c6203b620396202d92026920229201f9201d9101a910189101591013910119100f9100d1100b11009110081100711006110040100401003010030110300103001030010300103001
380100002b94029940279402594023930219301f9301d9301b9301a930189301793015930149201292011920109200c920159201092008920069100f91005910049100691007910089100791004910019100e910
450803000d22001211010110000031630112202b6101123024620112201d620112201f620112301e6301122025620112202a620112202c6101121029610112102661011210226100000000000000000000000000
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
79200020039100392003325033100cc6000c630f83003210039100392003325034120cc6200c631087006212049100b92004312032120dc6208c630f2120331004d500fc60063100fc600fc60123120631106311
792000000a1140a1210a1310a1210a125039160f9170f9140c1240c1310c1210c1200c12504d760cd7404d760b1100b1200b1200b1200b120110200b120120200d1200d1200d1220d12212917121201491414122
5910000020326273161b3202732620316273101b320273161e320273161b320273161b3100b3201e3101d3201b3251b3252232022316253200f3301b32120320200200f33020320203201b310273201e3201d320
591000001b3261e3161b3201e3261b310273101b3201b3101b326203101b32020326273101b3101b3201d3202932612320293261e320293261e320293261e3202a326143202a326203202a326203202a32620320
4b1000201d32324c0015313214133e6201d621153133e6101531324c102141324c10214130f3243c6250f322153231cd0039625213133e6101d621396253e6102131324c12214231532338620386243862538620
3d1000201203306720061250672012625067100612506125110330612506125067202561506710061250601012033067100612506710126250602506710061251203306125061250672025615067100663406125
891000201292506a240692506925156330692506915069250f733069150692506925156330691509925069100f7331212512a10069251563312a100692512a100f73306215069150621515633139150492504925
a540000006220062110622109222062200622106221092220622006211062210b2200622006221062210922006220062110622109222062200622106221092220222002211022210b22202220022210222109222
811000201e4201242012510120241241012325153201232006115061351742219422174121742219322193221e420123201211012020124261232715320123200611506135123251232215312123221942212322
c54000001e32328826258261c8261e32728826258261c826222232a826258261e826222272a826258261e8261e32328826248261c8261e32728826248261c8261a3232a826258261e8261a2272a826258261e826
692000201e413124111bd3227c4206c5012c5312c562a3162ab2625b2625b262ab262ab162ab16064241e4211e4131241123d322cc4208c5214c5314c562a31631b2631b262db272db271531515316213122d315
d540000019124121241912412124121240b124121240b124121240912412124091241012409124101240912419124121241912412124121241912412124191241712410124171241012419124151241912417124
890b00201642306615066250661533625126150662506625160230662506625066152a6251e6152a6251e6251642306615066250661533625126150662506625160230662506625066151e625126102a62525627
5d160020030540f220037400f220030440f220037400f2200f2350f220122350f220031240f220142350f220030540f220037400f220030540f220037400f2200f2350f220122350f220031240f220162350f220
715800000f9200f91112527125270992009911125271252608920089110d5270d52704920089110f5270f5270f9200f9110d5270d5270c9200c9110f5270f5260b9200b9110d5270d5270a9200a9110f5270f527
792c00201b026220261e02727822290222a0221b02027011190262202620027278222a0222902225020270211b026200261702627822195222252222531205311e5302053120531205311b532225322253520532
412c00202252222532225321e532207321b7221e7311e73122522225322253220532257321b7221e732207321d7321e732225321b5321b5322273222732207322073220732207321b7321e732207321d7321e732
891600201642022a301542016a501e42022a20194202eb650f4250f425164200f4210f4200f4220f4250f42509420278750e420278750f420278750d420278750f4250f425124220f4210f4220f425194250f425
8d5800000a2300f0320d2300f0320c2300f0320b2300d0320f2300f032062300d03208230040320b032140320a2300f1220d2300f1220c230161220e230141220f23212122121221612214122171221913211132
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 12151412
00 15141212
00 12151412
00 1215141d
00 15141d12
02 1215141d
03 13150c55
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
00 383a3978
00 383a3b78
00 383e3c79
02 383e3978

