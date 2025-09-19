pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

--movement prototype


--[[
abbreviations
-------------
tabl:table
ntt/e:entity
trn:terrain
bnc:bounciness/bounce
slp:slipperiness
sq:square
coll:collision
b:bottom/min
t:top/max
lmt:limit
h:horizontal
v:vertical
stnd:stand/standing
tch:touch/touching
rds:radius
c:counter/clock
mmnt:momentum
]]

function _init()
--printh("start------------")
	--init global vars
	--debug_visuals = false
	
	mod_tabl(_ENV,"trn_bnc,trn_slp,grav/0.2,0.75,0.19")
	mod_tabl(_ENV,"b_lmt_x,t_lmt_x,b_lmt_y,t_lmt_y/-400,2000,-2000,2000")
	mod_tabl(_ENV,"loaded_lvl_index/0")

	mod_tabl(_ENV,"delay_timers,delay_timers_draw,dt_draw_ltr/{},{},{}")
 --jump, ground/air speed limit, stand range

 -- timers & counters
 mod_tabl(_ENV,"anim_c,max_anim_len/0,2048")
	
	-- use extended map by default
	poke(0x5f56,0x80)
	
	-- no repeat btnp
 poke(0x5f5c, 255)


	load_lvl(loaded_lvl_index)
	
	_update,_draw = _update_m_menu,_draw_m_menu
end

camera_x,camera_y=0,0

function scr_text_box(x,y,str,lines,c1,c2)
	print(str,x,y,12)
	camera(0,0)
	local len = print(str,x,y,12)
	rectfill(x-4,y-4,len+2,y+lines*6+1,c1)
	rect(x-3,y-3,len+1,y+lines*6,c2)
	print(str,x,y,12)
	camera(camera_x,camera_y)
end

function fade_text(x,y,text,t)
	print(text,x,y,12)
	if (t>0) delay_timer(delay_timers_draw,1,fade_text,{x,y-1,text,t-1})
end

function _draw_m_menu()
	draw_common()
	scr_text_box(unstr"64,8,test,2,0,12")
	update_timer_tbl(delay_timers_draw)
	update_timer_tbl(dt_draw_ltr)
end

function _update_wait()
	update_timer_tbl(delay_timers)
end



function _update_m_menu()
	if btnp(0) then
		m_index -= 1
		screenwipe(unstr"-32,34,1")
	end
	if btnp(1) then
		m_index += 1
		screenwipe(unstr"32,34,1")
	end
	if btnp(0) or btnp(1) then
		m_index %= #start_lvls
		loaded_lvl_index=start_lvls[m_index+1]
		delay_timer(delay_timers,7,load_lvl,{loaded_lvl_index})
	end
	
	if btnp(5) then
		screenwipe(unstr"24,128,2")
		--delay_timer(delay_timers,6,load_lvl,{loaded_lvl_index})
		delay_timer(delay_timers,32,begin_lvl,{false})
		
		local function txt(t)
			scr_text_box(unstr"46,60,lvl begin!,1,2,2")
			if (t>0) delay_timer(dt_draw_ltr,1,txt,{t-1})
		end
		delay_timer(dt_draw_ltr,16,txt,{16})
		
		_update = _update_wait
	end
	update_timer_tbl(delay_timers)
end

function screenwipe(spd,len,col)

	local function circw(x,y,t)
		for i=0,len do
			circfill(x+i*7+camera_x,y+camera_y,16,col)
		end
		if t > 0 then
			delay_timer(delay_timers_draw,1,circw,{x-spd,y,t-1})
		end
	end
	
	local start_x = 160
	if (spd<0) start_x = -32-len*7
	for i=0, 5 do
		circw(start_x + (i%2)*32,i*32,len)
	end

end



function begin_lvl(cont)
	delay_timers={}
	
	_update,_draw=_update_inlvl,_draw_inlvl
	
	init_entities(cont)	
	camera_x,camera_y,prev_cam_speed=player.pos.x-64,player.pos.y-64,vec2_zero
	pal(13,col_tbl[1],1)
end

function load_next()
	load_lvl(loaded_lvl_index)
	begin_lvl(true)
end

function lvl_transition()
	screenwipe(18,40,1)
	
	if (lvl_extrainfo(2) >= 0) then
		loaded_lvl_index = lvl_extrainfo(2)
		delay_timer(delay_timers,12,load_next,{})
	else
		
	end
end





function init_entities(keep_prevs)
	--clear
	
	for e in all(entities) do
		if not(keep_prevs and (e==player or e==player.grabbed_e)) then
			remove_entity(e)
		end
	end
	
	if not keep_prevs then 
		player=spawn_player(lvl_extrainfo(3),lvl_extrainfo(4)) -- reference to the controllable entity
		add(entities,player)
	else
		for subntt in all(player.all_ntts) do
			subntt.pos = vec2_new(lvl_extrainfo(3),lvl_extrainfo(4))
			subntt.vel = v2c(vec2_zero)
		end
		if (player.in_grab) player.grabbed_e.pos = player.pos
	end
	
	local enm_arr = lvls_extra_info[loaded_lvl_index+1][2]
	for i=1, #enm_arr, 4 do
		local ex,ey,e_type,e_item = unpack(enm_arr, i)
		local enm=spawn_enm(ex,ey,enm_types[e_type])
		enm.item = e_item
		add(entities,enm)
		
		local function b_e(e)
			add(entities, spawn_item(e.pos.x,e.pos.y,e.item))
		end
		if (e_item > 0) enm.break_func=b_e
	end

	
	--music(0)
end

--tugs_per_frame,MAC_per_frame,frame_c=0,0,0



function delay_timer(tbl, ticks, func, args)
	local timer = {t=ticks,f=func,a=args}
	add(tbl, timer)
	return timer
end

function update_timer_tbl(tbl)
	-- put all present timers in a separate queue so the main table can be updated
	local timer_q = {}
	for timer in all(tbl) do
		add(timer_q, timer)
	end
	
	for timer in all(timer_q) do
		timer.t -= 1
		if timer.t <= 0 then
			timer.f(unpack_myb(timer.a))
			del(tbl,timer)
		end
	end
	
end

function _update_inlvl()
	anim_c += 1
	anim_c%=max_anim_len

	--[[frame_c += 1
	if frame_c>=30then
		printh("tugs in second: "..tugs_per_frame)
		tugs_per_frame=0
		printh("MAC in second: "..MAC_per_frame)
		MAC_per_frame=0
		frame_c=0
	end]]
	
	
	-- update delays and timers
 update_timer_tbl(delay_timers)
	
	for ntt, ntt_ts in pairs(entity_timers) do
		for name, timer in pairs(ntt_ts) do
			ntt_ts[name] = max(0, timer-1)
		end
	end
	
	update_mus()


	-- update entities
	for ntt in all(entities) do
	
		for subntt in all(ntt.all_ntts) do

			move_entity(subntt)
			if (subntt.update_func) subntt.update_func(subntt)

			
				-- cleanup tile entities
			if subntt.e_type == "tile" and subntt.is_stnd and subntt.stnd_on_trn 
			and vec2_len(subntt.vel) < 0.05 and not (player.in_grab and subntt == player.grabbed_e) then
				entity_to_tile(subntt)
			end
			
			if subntt.stmn and subntt.stmn <= 0 then
				if subntt != player then 
					remove_entity(subntt)
					particles(subntt.pos, split"6, 3.5,16", subntt.vel)
				else
					
				end
			end
			
			test_borders(subntt)
		end
	end
	
	--check entity links and pull/push them if needed
	--run this for loop multiple times for slightly more accurate link physics
	--for j=1, 1 do
	foreach(all_links, tug)
	--end

		
	if player.pos.x > l_border_x+4 and btn(1) and timer_ready(player, "lvl_t") then
		set_timer(player,"lvl_t", 64)
		lvl_transition()
	end


	-- camera tracking
	local follow_pos=player.pos+player.vel*20
	follow_pos.x += tonum_flip(not player.is_left)*8
	follow_pos.y += player.input_dir.y*28
	-- move camera to player
	
	-- separate x & y
	local distance = vec2_new(
		follow_pos.x-camera_x-64,
		follow_pos.y-camera_y-64
	)
	local speed=prev_cam_speed*0.85 + distance/20*0.15
	
	--if abs(distance.x) > cam_tol then
	camera_x+=(speed.x+0.5)\1
	--end
	camera_y+=(speed.y+0.5)\1
	
	camera_x,camera_y,prev_cam_speed=mid(0,camera_x,l_border_x-127),mid(0,camera_y,l_border_y-127),speed
end
 
function draw_common()
	cls(lvl_pal2[16])
	camera(camera_x, camera_y)
	
	draw_bg(0)
	draw_bg(9)

 map(unstr"0,0,0,0,128,64,0b1000")
	draw_lvl_borders()
	map(unstr"0,0,0,0,128,64,0b00000111")

end
	
function _draw_inlvl()
	draw_common()
	
	draw_links(false)
	
	for ntt in all(entities) do
		ntt.draw_func(ntt)
	end
	
	draw_links(true)

	-- update delayed draw functions
	update_timer_tbl(delay_timers_draw)
	update_timer_tbl(dt_draw_ltr)
	
	
	draw_ui()
	
	--print("\#0\fc test\n test 2 - longer test\^:447cb67c3e7f0106\ac.c...e-g",camera_x,camera_y+40)
	
	local text_arr = lvls_extra_info[loaded_lvl_index+1][3]

	for i=1,#text_arr,6 do
		if player.pos.x > text_arr[i] and player.pos.y > text_arr[i+1] and player.pos.x < text_arr[i+2] and player.pos.y < text_arr[i+3] then
			scr_text_box(5,11,text_arr[i+4],text_arr[i+5],8)
		end
	end
	

end


--get/set from starting map
-- assume range is valid
function maddr0x20(x,y)
	local s = 0x2000
	if (y >= 32) s = 0x1000
	return s + x + y*128
end

function mget0x20(x,y)
	return @(maddr0x20(x,y))
end

function mset0x20(x,y,v)
	poke(maddr0x20(x,y),v)
end


-->8
-- token savers

-- NOTICE: function return vals will only expand as arguments if the function is the last arg
-- f(1,2 a(50)) OK, f(a(50), 1,2 ) ONLY first return val of a
function unstr(str)
	return unpack(split(str))
end

-- thank you Lokistriker whoever you may be
-- modifies/appends to table. can target _ENV to change globals
function mod_tabl(tab, kv)
	local k,v = unpack(split(kv, "/"))
	k,v = split(k),split(v)
	for i=1,#k do
		tab[k[i]]=_pars(v[i])
	end
	return tab
end

-- mod tabl but v can be variables. more tokens but more savings lol
function mod_tabl2(tab, k,v)
	local k = split(k)
	for i=1,#k do
		tab[k[i]]=v[i]
	end
	return tab
end

-- NOTICE: bool false and nil are the only false vals
-- anything else can be used as a true bool

-- modified cause paranoia
function _pars(v)
	if(v=="true")return true
 if(v=="false")return false
 if(v=="nil")return nil
 if(v=="{}")return {}
	return v
end

-- unstr with parse
function unstr_p(str)
	local t = split(str)
	for i=1, #t do
		t[i] = _pars(t[i])
	end
	return unpack(t)
end

-- convert array or single arg to args
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

function bcheck(v,b)
	return (v or 0) & b != 0
end

function tonum_flip(b)
	return tonum(b)*2-1
end

-->8
-- entity managment

mod_tabl(_ENV, "entities,max_entities/{},256")


--physical "ropes" connecting entities
all_links,entity_timers={},{}

function get_first_link(e1,e2)
	for link in all(all_links) do
		if ((link.from == e1 and link.to == e2) or (link.from == e2 and link.to == e1)) return link
	end
end

function set_timer(e,n,v)
	entity_timers[e][n] = v 
end

function get_timer(e,n)
	return entity_timers[e][n] or 0
end

function timer_ready(e,n)
	return get_timer(e,n) <= 0
end

function spawn_entity(px,py,m,r,e_typ,parent)

 local ntt=mod_tabl2({},"pos,vel,mass,rds,e_type,parent,draw_func",
	{vec2_new(px, py),v2c(vec2_zero),m, r, e_typ or "none",parent,draw_entity})

	-- point to self when asked who moves
	--have to do after initial assignment
	ntt.all_ntts={ntt}

	--test whether is standing on terrain
	mod_tabl(ntt, "is_stnd,stnd_on_trn/false,false")
	
	--coll_mask_on:  those who see one of these layers will detect this entity 
	--coll_mask_see: detects those on these layers	
	mod_tabl(ntt, "coll_mask_on,coll_mask_see/0b00000001,0b00001111")
	
	if parent then
		ntt.coll_mask_on,ntt.coll_mask_see=parent.coll_mask_on,parent.coll_mask_see
		ntt.pos+=parent.pos
		ntt.vel+=parent.vel	
	end
	
	entity_timers[ntt]={}
	
 return ntt
end


function remove_entity(e)

 for ntt in all(e.all_ntts) do

		for link in all(all_links) do		
			if (link.from == ntt or link.to == ntt) delete_link(link)
		end
	end
	
	local is_present=false
	if e.parent then
		is_present=del(e.parent.all_ntts, e)
	else
		is_present=del(entities, e)
	end
	
	if is_present and e.break_func then
		e.break_func(e)
	end
	
	entity_timers[e]=nil
	return is_present
end


function spawn_complex(px,py, props, h_props, c_on,c_see)
	local p_m,p_r, p_stick, p_g_acc,p_a_acc,p_g_mspd,p_a_mspd,p_jump, p_l_len,p_l_width,p_a_len,p_a_width,p_st,p_lspd,p_lcool,p_ltol,p_langl=unpack(props)
	local p_hp,p_lhp=unpack(h_props)

	local e = spawn_entity(px,py,p_m,p_r)
	e.props=props
	mod_tabl(e,"e_type,is_left,grounded_mode,ground_is_entity,ground_pos_entity,walking,crouch/complex,false,false,false,nil,false,false")
	
	-- todo: all of these mod_tabls can be joined for extra token savings but no readability
	mod_tabl2(e,"leg_facing,facing,input_dir,surface_away,update_func",{vec2_down,vec2_up,vec2_zero,vec2_up,move_humanoid})

	mod_tabl2(e,"stmn,stmn_l_t,stmn_l_b",{p_hp,p_hp,p_lhp})
	
	--subentity mappings. moving them in bulk is a lot easier
	mod_tabl(e,"m_l_legs,l_angles,m_l_arms,a_angles/{},{},{},{}")
	-- cooldown for movement
	e.m_l_arms.cd,e.m_l_legs.cd=0,0
	
	mod_tabl2(e,"sticky,jump_str,g_acc,a_acc,g_max,a_max,stnd_height,leg_speed,leg_tol,leg_angle_range",{p_stick=="tru",p_jump,p_g_acc,p_a_acc,p_g_mspd,p_a_mspd,p_st,p_lspd,p_ltol,p_langl})
	
	e.coll_mask_on,e.coll_mask_see=c_on,c_see
	
	for i=18, #props, 5 do
		local l_e = spawn_entity(0,0,0.1,0.1,"limb",e)
		
		l_e.t_pos,l_e.t_active = l_e.pos,false
		add(e.all_ntts, l_e)
		
		local typ,angle,col,do_l_draw,front = unpack(props,i)
		local len,width=p_l_len,p_l_width
		
		if typ=="l" then
			add(e.m_l_legs, l_e)
			add(e.l_angles, angle)
		else
			add(e.m_l_arms, l_e)
			add(e.a_angles, angle)
			len,width=p_a_len,p_a_width
		end
		
		local l_draw,is_front = 2,false
		if (do_l_draw == "tru") l_draw = 3
		if (front == "tru") is_front = true
	 
		local l_link = make_link(e,l_e,1,len,false,0, l_draw, col, e, is_front,width)
	end
	
 return e
end


function spawn_player(px,py)
	
 local player_l = spawn_complex(px,py,ntt_b_types[2],{80,40},0b00000010,0b00001101)
	
	--grabbing
	mod_tabl(player_l,"e_type,in_grab,grabbed_e,grabbed_coll_on,grabbed_coll_see,items/player,false,nil,0b00000000,0b00000000,0")
	
	mod_tabl2(player_l,"col,update_func,draw_func,m_sprite",{13,update_player,draw_humanoid,split"128,1,1,1,3000"})

	return player_l
end


function spawn_enm(ex,ey,e_type)
	local hp,m_spr_i,b_type,gun,e_init,e_ai = unpack(e_type)
	local enm=spawn_complex(ex,ey,ntt_b_types[b_type],{hp,0},0b00000100,0b00001011)
	mod_tabl2(enm,"e_type,gun,update_func,ai,is_left,draw_func,m_sprite",{"enm",guns[gun],update_enm,enm_ais[e_ai],true,draw_enm,m_sprites[m_spr_i]})
	enm_inits[e_init](enm)
	return enm
end

function spawn_item(ix,iy,it)
	local item = spawn_entity(ix, iy, 1, 4, "item")
	item.coll_mask_on, item.coll_mask_see = 0b0000,0b0010
	item.it = it
	item.m_sprite = {175 + it,1,1,3000,1}
	
	local function a_add(i,prev_v,impact,other_e)
		if other_e == player then
			player.items |= 1 << (i.it-1)
			particles(i.pos,split"13,3,20")
			fade_text(i.pos.x,i.pos.y,item_names[i.it],45)
			remove_entity(i)
		end
	end
	
	item.coll_func = a_add
	return item
end

function make_link(e1, e2, link_type, link_len, to_ground, link_strenght, draw_type, col, ref_e, is_front,width)

	local t_t_g = to_ground or false
	
	local link=mod_tabl2(
	{},"from,to,l_type,len,true_len,to_ground,strenght,draw_type,col,ref_e,is_front,width",
	{e1,e2,link_type,link_len,link_len,t_t_g,link_strenght or 0,draw_type or 0,col or 14, ref_e, is_front or false,width or 0})

	add(all_links, link)	
	return link
	
end

function delete_link(l)
	del(all_links,l)
end

-->8
-- drawing

l_bg_timescrolls=split"0,1,2,6,15,30,60,90,150,-1,-2,-6,-15,-30,-60,-90"

function draw_bg(offset) 
	pal(lvl_pal2, 0)
	
	mod_tabl2(_ENV,"h6,h7,h8,h9,h10,h11,h12,h13,h14",{unpack(loaded_level[1],offset+6)})
	
	local p_sc = h8*8+8
	local scrl,ts = (h7/12)^2, vec2_rotate(vec2_up, h14/16)*l_bg_timescrolls[h13+1]
	local wrap_x,wrap_y = h9!=0, h10!=0
	
	local scroll_x,scroll_y = -(h11*16 -128)+camera_x*scrl+time()*ts.x, -(h12*16 -128)+camera_y*scrl+time()*ts.y
	
	if(wrap_x) scroll_x %=8*p_sc
	if(wrap_y) scroll_y %=4*p_sc

	local function map_scaled(ox,oy)
		for	i=0,7 do
			for	j=0,3 do
			 local n = mget0x20(h6*8+i, j)
				sspr((n&0b1111)*8,n\16*8,8,8, camera_x-scroll_x+i*p_sc+ox, camera_y-scroll_y+j*p_sc+oy,p_sc,p_sc)
			end
		end
	end
	
	for i=0, (128\(8*p_sc)+1)*h9 do
		for j=0, (128\(4*p_sc)+1)*h10 do
			map_scaled(8*p_sc*i,4*p_sc*j)
		end
	end

	pal(0)
end

function draw_lvl_borders()
	
	local rcol = 13
	if (lvl_extrainfo(2) <= -1) rcol = 12
	
	local l_x = l_border_x
	local function l()
		line(l_x,0,l_x,l_border_y,rcol)
	end
	l()
	l_x-=1
	l()
	l_x-=flr(time()*9)%9
	l()
end


function ntt_outl(ntt,col)
	local pal_o = {}
	
	for i=1,16 do
		add(pal_o,col)
	end
	
	pal(pal_o,0)
		local function spr1(x,y)
			camera(camera_x+x,camera_y+y)
			draw_entity(ntt)
		end
		
		spr1(-1,0)
		spr1( 1,0)
		spr1(0,-1)
		spr1(0, 1)
		camera(camera_x,camera_y)
	pal(0)
	
end


function draw_entity(entity)
	
	if entity.m_sprite then
		local e_spr,s_x,s_y,a_t,a_n = unpack(entity.m_sprite)
		e_spr += ((anim_c\a_t)%a_n)*s_x
		spr(e_spr, entity.pos.x-s_x*8/2,entity.pos.y-s_y*8/2,s_x,s_y,entity.is_left)
	end
	

	--[[if debug_visuals then
		local d_col = 7

		if entity.is_stnd then
			d_col = 12
			if (entity.stnd_on_trn) d_col = 11
		end
		
		local p = ep+entity.vel
		circ(p.x, p.y, entity.rds/2,d_col)	
	end]]
	
end

function draw_enm(enm)
	local e_spr_x,e_spr_y = enm.pos.x-4,enm.pos.y-4
	
	local enm_col,g_t,hurt=14,get_timer(enm,"gun"), not timer_ready(enm,"hurt")
	if (hurt) enm_col=12
	
	if enm.active or hurt then
		if (g_t < 8 and g_t%4>1) enm_col=10
		ntt_outl(enm, enm_col)
	end
	
	for i=1, #enm.all_ntts do
		draw_entity(enm.all_ntts[i])
	end
end

function draw_links(front)
	for link in all(all_links) do
		if link.is_front == front then
			draw_link(link)
		end
	end
end

function draw_link(link)
	local envstr,_ENV = _ENV,link -- forbidden token-saving reality warping spell
	-- link's members are now "globals" and all previously global variables are now accessed trough envstr
	-- local makes it work only inside this function (and luckily not inside envstr's)

	local p1,p2,l=from.pos, to.pos,false
	if (to_ground) p2 = to
	
	if (ref_e) l = ref_e.is_left
	
	if draw_type == 1 then
		envstr.line_vec(p1, p2, col,width)
	elseif draw_type == 2 then
		envstr.draw_joint(p1, p2, len/2, col, l,width)
		
	elseif draw_type == 3 then
		local pos_2 = p1 + envstr.vec2_normalized(ref_e.leg_facing)*3
		envstr.line_vec(p1, pos_2, ref_e.col or 13, width)
		envstr.draw_joint(pos_2, p2, (true_len - 3)/2, col, not l,width)
	end

end

-- assumes both have same radius
function circ_intersect(p1,p2,r)
	local d,mid_p=vec2_len(p2-p1),(p1+p2)/2 

	local op=(p2-p1)*sqrt(r*r-d*d/4)/d
	
	local op2=vec2_new(op.y,-op.x)
	
	return mid_p+op2, mid_p-op2
end

function line_vec(v1,v2,col,thickness) 

	local vec_rep = {[0]=vec2_zero,vec2_right,vec2_up,vec2_left,vec2_down}
	for i=0, thickness or 0 do
		local vec = vec_rep[i%4]*i\4
		v1+=vec
		v2+=vec
		line(v1.x,v1.y,v2.x,v2.y,col)
		v1-=vec
		v2-=vec
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

function draw_humanoid(ntt)
	
	--pset(ntt.la.pos.x,ntt.la.pos.y, 15)

	--head
	local head_sprite_pos=ntt.pos+ntt.facing*2-vec2_new(4,4)
	
	local flip_r,flip_u=ntt.is_left,false
	if ntt.facing.y > 0.7 then
		flip_u,flip_r = true,not flip_r
	end
	
	if (flip_r == false) head_sprite_pos.x += 1
	spr(ntt.m_sprite[1], head_sprite_pos.x, head_sprite_pos.y, 1, 1, flip_r, flip_u)
	
	--eyes
	
	local hurt_tmr = get_timer(ntt, "hurt")
	
	local e_pos_y = head_sprite_pos.y
	if (btn(3) or hurt_tmr > 10) e_pos_y += 1
	
	local spr_i = 0
	
	if (vec2_len(ntt.vel) > 4) spr_i = 1
	if hurt_tmr > 20 then
		spr_i = 2
	end
	
	if anim_c%(55) > 3 or vec2_len(ntt.vel) > 0.5 then
		spr(144+spr_i, head_sprite_pos.x, e_pos_y,1,1,flip_r,flip_u)
	end
	
	--pset(ntt.ra.pos.x,ntt.ra.pos.y, 15)
	
	--[[if debug_visuals then
		for subntt in all(ntt.all_ntts) do
			if (subntt.t_active or subntt.t_locked) circ(subntt.t_pos.x,subntt.t_pos.y, 2, 14)
		end
	end]]

end

function draw_ui()
	camera(0,0)

	local function ui_line(x1,xlen,y,col1)
		line(x1,y,x1+xlen,y,col1)
	end

	for i=1, 5 do
		ui_line(3,82,i,1)
	end
	
	for i=2, 4 do
		ui_line(4,player.stmn + get_timer(player,"hurt"),i,12)
		ui_line(4,player.stmn-1,i,13)
		ui_line(4,player.stmn_l_b,i,15)
	end
	
	camera(camera_x,camera_y)
end

-->8
-- sounds

mus_p,mus_layer = true,false

function update_mus()
	if(stat(50) == 31 and mus_p) then
		--printh("Ok")
		
		local ptrn = stat(54)
		local addr = 0x3101 + (ptrn+1)*4
		local addr_info = 0x3101 + (ptrn)*4
		
		if (@addr_info) & 0b10000000 != 0 then
			addr = 0x3101 + (ptrn\8)*4
		end
		
		local fl = @addr
		if mus_layer then
			fl |= 0b01000000
		else
			fl &= 0b10111111
		end
		
		poke(addr,fl)
		
		mus_p = false
		
	elseif(stat(53) != 0 ) then
		mus_p = true
	end
	
end

function sp_sfx(sf, src_pos)
	if (vec2_len(src_pos - player.pos) < 200) sfx(sf)
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
	--mul/div vector by a scalar
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
-- helper functions

function empty_f()
end

function apply_momentum(e, m)
	e.vel+=m/e.mass
end

function counter_mmnt(m, e1, e2)
	apply_momentum(e1,m)
	apply_momentum(e2,-m)
end

-- works on scalars as well
function split_vector(v, m1, m2)
	return v*m2/(m1+m2),v*m1/(m1+m2)
end

-- multiply components separately
function recomp_mul(v,s,m1,m2)
	local vc = projection(v,s)
	return vc*m1+(v-vc)*m2, vc*m1, (v-vc)*m2
end

-- used in collisions and link pulling/pushing
function transfer_momentum(e1, e2, bnc, slipperiness, square_coll) -- b is from 0 to 1
	-- magnitude of diff should not matter
	local diff = e2.pos-e1.pos

	if square_coll then
		if abs(diff.x) > abs(diff.y) then
			diff.y=0
		else
			diff.x=0
		end
	end
	
	local e1m,e2m=e1.mass,e2.mass
	local total_m = e1m+e2m

	-- find components	
	-- decomponentizes and multiplies these
	tmp, v1_c, e1.vel = recomp_mul(e1.vel, diff, 1, slipperiness)
	tmp, v2_c, e2.vel = recomp_mul(e2.vel, diff, 1, slipperiness)

	if diff.x == 0 then
		if diff.y > 0 and e2.is_stnd then
			e1.vel += -v1_c*bnc
			return
		elseif diff.y < 0 and e1.is_stnd then
			e2.vel += -v2_c*bnc
			return
		end
	end

	-- for elastic bounce
	local v1_f= v1_c*(e1m-e2m) +v2_c*2*e2m
	local v2_f= v1_c*2*e1m     +v2_c*(e2m-e1m)
	
	-- for sticky collision - equalize velocities
	local final_v=v1_c*e1m+v2_c*e2m
	
	-- readd modified components
	e1.vel+=(final_v*(1-bnc) +v1_f*bnc)/total_m
	e2.vel+=(final_v*(1-bnc) +v2_f*bnc)/total_m
end

function in_tbl(element, table)
  for key, value in pairs(table) do
   if (value == element) return true
  end
  return false
end


-->8
-- terrain & collisions

function sq_sq_coll(p1, r1, p2, r2)
	local l_max_x,r_min_x,u_max_y,d_min_y = p1.x + r1,p2.x - r2,p1.y + r1,p2.y - r2

	if (p1.x > p2.x) l_max_x,r_min_x = p2.x + r2,p1.x - r1
	if (p1.y > p2.y) u_max_y,d_min_y = p2.y + r2,p1.y - r1

	if l_max_x > r_min_x and u_max_y > d_min_y then
		local s_normal,dist
		
		if abs(p1.x-p2.x) > abs(p1.y-p2.y) then
			s_normal = vec2_left *sgn(p2.x - p1.x)
			dist = r1+r2 -abs(p2.x-p1.x)
		else
			s_normal = vec2_up *sgn(p2.y - p1.y)
			dist = r1+r2 -abs(p2.y-p1.y)
		end

		return true, s_normal, dist
	end

	return false

end


function sq_trn_coll(point, rds, find_closest)
	local p_in = v2c(point)
	--snap to inside lvl terrain -- like rain world's geometry extensions
	p_in.x = mid(0,p_in.x,l_border_x)
	p_in.y = mid(0,p_in.y,l_border_y)
	
	local point_max,point_min = p_in+vec2_new(rds,rds),p_in-vec2_new(rds,rds)
	
 	-- go over all tiles in rectangle range
	for j=point_min.y\8,point_max.y\8 do
		for i=point_min.x\8,point_max.x\8 do

			if fget(mget(i,j),0) then -- solid tile
 				-- test coll
				local p2 = vec2_new(i*8+4,j*8+4)
 				local did, normal = sq_sq_coll(p_in, rds, p2, 4)
 				
 				if (did) return did, p2, normal
 			end
			
		end
	end
	
	return false
end

function check_coll_ntts(ntt, pos, rds)
	local p_t,r_t = pos or ntt.pos, rds or ntt.rds

	-- ultra slow with lots of primary entities - limit is about 15
	-- todo maybe do grid cell separation table -- yeah right with this many tokens -- timesplits could work
	for other in all(entities) do
		if other != ntt and (ntt.coll_mask_see & other.coll_mask_on != 0) then
			local did, normal, dist = sq_sq_coll(p_t, r_t, other.pos, other.rds)
			
			if (did) return true, other, normal, dist
		end
	end
	return false, nil	
end


function tile_to_entity(tile_pos, convert)
	--printh("converted a tile to entity")
	local tpx, tpy = tile_pos.x, tile_pos.y
	local t_dat,t_set = mget(tpx, tpy),0
	
	if convert and not fget(t_dat, 1) then
		t_dat = 14 + rnd(2)
	end
	
	local t_stmn, mass = 150, 0.8

	if fget(t_dat, 1) then
		t_stmn,mass = 35, 0.4
	end

	-- fill bg: insert <^ bg tile
	local t_l,t_u = mget(tpx-1, tpy),mget(tpx, tpy-1)
	if (fget(t_u,3)) t_set = t_u
	if (fget(t_l,3)) t_set = t_l
	mset(tpx, tpy, t_set)

	local t_e = spawn_entity(tpx*8+4,tpy*8+4,mass,3.5)
	mod_tabl2(t_e,"m_sprite,e_type,stmn,stmn_l_b",{{t_dat,1,1,3000,1},"tile",t_stmn,0})
	
	add(entities, t_e)
	return t_e
end


function entity_to_tile(e)
 --printh("converted an entity to tile")
	mset(e.pos.x\8, e.pos.y\8, e.m_sprite[1])
	remove_entity(e)
end


-->8
-- movement

-- NO TERRAIN CLIPPING 
function unclip(entity,pos,rds)

	local pos_t, rds_t = pos or entity.pos, rds or entity.rds
	
	-- first test terrain
	local coll_t, t_pos = sq_trn_coll(pos_t, rds_t)
	if coll_t then
		for i=1, 10 do
			for j=0, 7 do 
				local s_v = v2c(vec2_up)
				if (j > 3) s_v.x=1
				local m_v = vec2_rotate(s_v,j/4)*i*0.98
				if (not sq_trn_coll(pos_t + m_v, rds_t)) return true, true, true, m_v, get_tmp_trn_e(t_pos) -- out now - ignore entities
			end
		end
		return true, true, false, vec2_zero, get_tmp_trn_e(t_pos)
	end
	
	-- then entities
	local coll_e, e, norm, dist = check_coll_ntts(entity, pos_t, rds_t)
	
	if coll_e then
		local m_v = norm*dist
		if (not sq_trn_coll(pos_t + m_v, rds_t) and not check_coll_ntts(entity, pos_t + m_v, rds_t)) return true, false, true, m_v, e
		return true, false, false, m_v, e
	end
	return false
end

function move_and_unclip(entity, move_vec)

	--MAC_per_frame += 1
	
	-- apply movement
	entity.pos += move_vec
	
	-- clip out
	local clip,with_t,out,dir,coll_e = unclip(entity)
	if clip and out then
		entity.pos += dir
	end

	return clip,with_t,out,dir,coll_e
end


function update_stand(entity)
	
	-- clear standing
	mod_tabl(entity,"is_stnd,stnd_on_trn/false,false")
	
	local down_pos = entity.pos + vec2_down

	-- first check entity below
	local touch_e, e = check_coll_ntts(entity, down_pos)
	if touch_e then
		entity.is_stnd=true
		return
	end
	
	-- then terrain
	local did, point = sq_trn_coll(down_pos, entity.rds)
	if did then
		mod_tabl(entity,"is_stnd,stnd_on_trn/true,true")
		return
	end
	
	-- legs give special stand property
	
end


function explosion(pos, radius, str, sf)

	local function get_expl_ntt(pos1)
		local dist = pos1 - pos
		return mod_tabl2({},"pos,vel,mass",{pos,vec2_normalized(dist)*str/max(1,vec2_len(dist)/radius*2),1})
	end
	
	for ntt in all(entities) do
		if (vec2_len(ntt.pos-pos) < radius) impact(get_expl_ntt(ntt.pos), false, ntt.pos-pos, ntt, true, true)
	end

	-- go over all tiles in rectangle range
	for j=pos.y-radius,pos.y+radius,8 do
		for i=pos.x-radius,pos.x+radius,8 do
			local t_pos = vec2_new(i,j)
			if fget(mget(t_pos.x/8,t_pos.y/8),0) then
				local tmp_ntt = get_tmp_trn_e(t_pos)
				if (vec2_len(t_pos-pos) < radius) impact(get_expl_ntt(tmp_ntt.pos), true, tmp_ntt.pos-pos, tmp_ntt, true, true, rnd(2)>1)
			end
		end
	end

	particles(pos, {12, radius/2, sf, -radius/6, 5})
end

function particle_delay(p,v,r,c,dc,t)
	circfill(p.x,p.y,r,c)
	if t > 0 then
		delay_timer(delay_timers_draw,1,particle_delay,{p+v,v,r-dc,c,dc,t-1})
	end
end


-- 1-col, 2-radius, 3-sfx (- if none), 4-decay rate, 5-time
function particles(pos, props, vel)
	local co,rd,sf,dc,ti = unpack(props)
	if (sf >=0) sp_sfx(sf,pos)
	for i=1, 5 do
		particle_delay(v2c(pos),vec2_new(rnd(2)-1,rnd(2)-1) + (vel or vec2_zero),rd, co, dc or 0.3, ti or 11)
	end
end


function lose_stmn(ntt, dmg)
	local envstr, _ENV = _ENV,ntt

	if stmn then
		-- also acts as iframes
		local prev_hurt = envstr.get_timer(ntt, "hurt")
		if ntt != envstr.player or prev_hurt <= 2 then
			--printh("damage dealt to " .. tostr(ntt.id) .. ": " .. tostr(dmg))
			local p_s=stmn
			stmn-=dmg
			

			if stmn < stmn_l_b then
				local dmg2 = stmn_l_b-stmn
				dmg2/=4
				stmn_l_b -= dmg2
				stmn = stmn_l_b
			end

			local total_dmg = p_s - stmn
			envstr.set_timer(ntt, "hurt", total_dmg)
				
			if e_type=="enm" and stmn > 0 and total_dmg > 1 then
				envstr.fade_text(pos.x,pos.y,tostr("\^o15a"..(stmn/stmn_l_t*100)\1).."%",18)
			end
					
		end
	end
end

function get_tmp_trn_e(pos)
	local ntt=mod_tabl2({},"pos,vel,mass,rds,e_type",
	-- 5x the mass to enable proper bounces
	{(pos\8)*8+vec2_new(4,4),v2c(vec2_zero),12,4,"tmp tile"})
	
	local t_dat = mget(pos.x\8, pos.y\8)
	if (fget(t_dat,1)) ntt.mass = 2
	if (pos.y\8 >= ld_l_size_y*4-1) ntt.mass = 1000
	
	return ntt
	
end

function impact(entity, with_t, surface_dir, coll_e, no_sfx, no_sq_coll, no_convert)
	
	local prev_v1,prev_v2 = v2c(entity.vel), v2c(coll_e.vel)
	
	local function get_nrg(v1,v2)
		return vec2_len(v1)^2*entity.mass + vec2_len(v2)^2*coll_e.mass
	end
	
	transfer_momentum(entity, coll_e, trn_bnc, trn_slp, not no_sq_coll)

	local impact=get_nrg(prev_v1,prev_v2)-get_nrg(entity.vel,coll_e.vel)
	
	local impact_1,impact_2=split_vector(impact, entity.mass, coll_e.mass)
	
	
	-- if broke terrain turn tile to entity
	if with_t and vec2_len(coll_e.vel) > 0.6 then
		local new_v = v2c(coll_e.vel)
		coll_e = tile_to_entity(coll_e.pos\8, not no_convert)
		coll_e.vel = new_v*4
	end
	
	-- old bounce
	--entity.vel = recomp_mul(entity.vel, surface_dir, -trn_bnc, trn_slp)
		
	function coll_p(e,p,i,o)
		if e.coll_func then
			e.coll_func(e, p, i, o)
		end
		if e.e_type=="tile" or i >= 1.1 then
			lose_stmn(e, i^1.5)
		end
		if (e.e_type == "enm" and o.e_type == "tile") set_timer(e, "hurt", 30 + i)
		
	end
	
	coll_p(entity,prev_v1,impact_1,coll_e)
	coll_p(coll_e,prev_v2,impact_2,entity)
	

	local sf = 13
	if impact > 6.5 then
		sf=14
	end
	if impact > 11 then
		sf=15
	end
	
	if impact > 2 and not no_sfx then
		sp_sfx(sf, entity.pos)
	end
	
end




function test_borders(ntt)

	if ntt.pos.x < -12 then
		ntt.vel.x /= 2
		ntt.pos.x += 1
	elseif ntt.pos.x > l_border_x+12 then
		ntt.vel.x /= 2
		ntt.pos.x -= 1
	end
	
	if ntt.pos.y > l_border_y+64 and ntt.parent == nil then
		remove_entity(ntt)
	end
	
end


function move_entity(entity)

	-- move
	local did_c, with_t, out, surface_dir, coll_e = move_and_unclip(entity, entity.vel)
	
	if did_c then
		--printh("coll! " .. tostr(entity.id))
	
		if out then
			impact(entity, with_t, surface_dir, coll_e)
	 else
			--printh("sus")
			entity.vel *= 0
			if with_t then
				entity.pos.y -= 7.9
			else
				entity.pos += vec2_normalized(entity.pos - coll_e.pos)
			end
		end
		
	end
	
	update_stand(entity)
	
	--fall
	if entity.is_stnd then
		entity.vel.y *= 0.95
	 entity.vel.x *= 0.6 + trn_slp*0.4 --ground/ntt friction
 elseif not entity.special_stand  then
		entity.vel.y += grav
	end
	
	entity.vel *= 0.999 --air friction

	-- prevent micromovements
	if (vec2_len(entity.vel) < 0.09) entity.vel *= 0
	
end

-- called when an entity is outside its link range
function tug(link)

	local e1,e2 = link.from, link.to
	local e1m,e2m = e1.mass,e2.mass
	local e2_pos = e2.pos
	if (link.to_ground) e2_pos = e2
	
	local diff = e2_pos - e1.pos
	
	local move_dist = vec2_len(diff) - link.len

	
	-- the amount that the entities need to move so they stay in proper link range
	local move_need = vec2_normalized(diff) * move_dist
	
	
	local do_move = false
	
	if link.l_type & 0b10 == 0 then
		if (move_dist > 0.6) do_move = true
	-- break if too far
		if link.strenght > 0 and move_dist > link.strenght then
			delete_link(link)
			return
		end
	end
	
	if link.l_type & 0b1 == 0 then
		if (move_dist < -0.6) do_move = true
		if link.strenght > 0 and move_dist < -link.strenght then
			delete_link(link)
			return
		end
	end

	-- check if tugging is needed
	-- small tolerance (0.6) so it isn't constantly active

	if do_move then
		-- continue with pulling
		--tugs_per_frame += 1

		if link.to_ground then
			e1.pos += move_need
			-- remove vel component towards ground
			e1.vel = recomp_mul(e1.vel, e1.pos - e2_pos, 0, 1)
		else
			--printh(e1.id .. " tugs " .. e2.id)
			
			-- move proportionally and equalize velocities

			-- the amount each entity needs to move
			local move_1,move_2 = split_vector(move_need, e1m, e2m) -- == move_need/(e2m/e1m)
			
			-- move towards (or away)	
			-- used to be slide, outclip is now accurate enough and faster
			e1.pos += move_1*0.98
			e2.pos -= move_2*0.98

			-- equalize velocity components
			transfer_momentum(e1,e2, 0.1, 1)
			-- can add small bounce so they're not super strechable
		end

	end
	
end

function update_targets(entity, ntt_group, t_angles)

	local st_range = entity.props[13]*1.25
	
	-- basically a raycast
	local function try_find(vec)
		for vec in all({vec*1.2,vec2_rotate(vec,entity.leg_angle_range),vec2_rotate(vec,-entity.leg_angle_range)}) do
			for j=1, 4 do 
				local t_vec = vec *j/4
				local t_pos = entity.pos + t_vec
				local coll_land,with_t,out,away_vector,other_ntt = unclip(entity, t_pos, 0.1)
				if (coll_land and out) return true, t_vec, with_t, away_vector, other_ntt
				
				if (fget(mget(t_pos.x\8, t_pos.y\8), 2) and entity.sticky) return true, t_vec, true, v2c(vec2_up), get_tmp_trn_e(t_pos)
			end
		end
		return false
	end

			-- where is landing point
	local stand_vec,max_dist,max_ntt,max_stand_center = vec2_normalized(entity.leg_facing + vec2_new(entity.input_dir.x*0.4,0))*st_range, -1
		
	-- move target with highest distance to optimal target position (if outside tolerant distance)
	for j=1, #ntt_group do
		local ntt = ntt_group[j]

		ntt.t_active = false
		if timer_ready(entity,"jump_cooldown") then	
			local did, t_vec, with_t, away_vector, other_ntt = try_find(vec2_rotate(stand_vec,t_angles[j] * tonum_flip(entity.is_left)))
			
			if did then
				local stand_center = entity.pos + t_vec + away_vector
				if (entity.sticky) away_vector = v2c(vec2_up)
				mod_tabl2(entity,"grounded_mode,surface_away,ground_is_entity,ground_pos_entity",
				{true,vec2_normalized(away_vector),not with_t, other_ntt})
				
				local dist = vec2_len(ntt.t_pos - stand_center)
				
				if dist > max_dist then
					max_dist,max_ntt,max_stand_center = dist,ntt,stand_center
				end
				
				if (dist <= entity.tmp_tol) ntt.t_active = true
			end	
			
		end -- of jump cooldown check
		
	end 
	
	-- only if not on cooldown and if outside tolerance range
	if ntt_group.cd <= 0 then		
		if max_dist > entity.tmp_tol then
			max_ntt.t_pos,max_ntt.t_active = max_stand_center,true
			ntt_group.cd = entity.props[15]
		end
	else 
		ntt_group.cd -= 1
	end
	
	
end


function move_towards(ntt, target_pos, speed)
	--local prev_pos = v2c(ntt.pos)
	
	move_and_unclip(ntt, vec2_limit((target_pos-ntt.pos)/speed)*speed)

	--if ntt.parent then
	--	move_and_unclip(ntt.parent, (prev_pos - ntt.pos)/ntt.parent.mass*ntt.mass)
	--end
end

function move_humanoid(entity)
	local envstr,_ENV=_ENV,entity

	for arm in envstr.all(m_l_arms) do
		arm.special_stand=false
	end

	-- leg move parameters
	local stnd_height,leg_speed=
		 stnd_height, leg_speed
	tmp_tol = leg_tol	
	
 -- preferred offset from center, in pico8 degrees
	-- offset tolerance	
	
	if (walking and not crouch) or surface_away.y >= 0 then
		stnd_height*=0.9
		leg_speed*=2
		tmp_tol*=2
	end

	-- defaults - no leg support	
	envstr.mod_tabl(entity, "special_stand,grounded_mode,ground_is_entity,ground_pos_entity/false,false,false,nil")
	
	
	if (envstr.get_timer(entity,"hurt") > 20) return
	
	envstr.update_targets(entity, m_l_legs, l_angles)
	
	if grounded_mode then
	-- try to stand

		-- move legs to targets
		for leg in envstr.all(m_l_legs) do
		
			if leg.t_active then
				envstr.move_towards(leg,leg.t_pos, leg_speed)
				if (sticky) special_stand = true
			end

			if envstr.vec2_len(vel) < 5 then
				if (leg.is_stnd) special_stand = true
			end
		end
		
	end

	
	if special_stand then -- really is standing (or about to hit ground)
		
		--custom friction
		vel *= 0.83

		-- transfer keep percent
		local t_v1 = 0.82

		if envstr.abs(vel.y) < 2.6 then
			if not walking then
				vel *= 0.80
				vel.x *= 0.60
			end
			t_v1 = 0.75
		end
			
			
		-- stabilise pos
		
		local stand_p_lh = m_l_legs[1].pos+surface_away*stnd_height

		if crouch or envstr.sq_trn_coll(pos+envstr.vec2_up*5, 0.5) then
			stand_p_lh -= surface_away * 4
		else
			stand_p_lh += surface_away * ((envstr.anim_c\48)%2)
		end

		if not sticky then
			pos.y = pos.y*t_v1 + stand_p_lh.y*(1-t_v1)
			
			local function stabl_arm(arm,angl)
				if envstr.vec2_len(arm.vel) < 0.15 and not armgrab then
					arm.vel *= 0
					arm.special_stand=true
					local d_vec = envstr.vec2_rotate(envstr.vec2_down*(envstr.get_first_link(entity,arm).len - envstr.tonum(crouch)), angl)
					arm.pos = pos+d_vec
				end
			end
			
			for i=1, #m_l_arms do
				m_l_arms[i].vel*=0.95
				stabl_arm(m_l_arms[i], a_angles[i])
			end
			
		end
			
	end -- of leg stand check
end



function update_right(ntt)
	local _ENV = ntt
	if (input_dir.x < 0) is_left = true
	if (input_dir.x > 0) is_left = false
end


function ungrab(ntt)
	for e in all(ntt.grabbed_e.all_ntts) do
		e.coll_mask_on = ntt.grabbed_coll_on
		e.coll_mask_see = ntt.grabbed_coll_see
	end
	ntt.grabbed_e = nil
	ntt.in_grab = false
end

function move_control(ntt, b4, b5)

	local surface_normal = ntt.surface_away

	local input_dir = ntt.input_dir or v2c(vec2_zero)
	local input_dir_l = vec2_limit(input_dir)
	local input_dir_j = vec2_normalized(vec2_up*0.2 + surface_normal*0.1 + input_dir)
	local input_dir_j2 = v2c(input_dir_j)
	input_dir_j2.y *= 2
	local input_dir_h = vec2_normalized(input_dir_l + vec2_right*(tonum_flip(not ntt.is_left))*0.05)
	local hold_pos = ntt.pos + input_dir_h*ntt.props[11]
	
	
	local accel = 0
	local jump_cooldown = get_timer(ntt, "jump_cooldown")
	
		
	-- grabbing -----------------------------------
	
	local jump_s = false
	
	if #ntt.m_l_arms > 0 then
		local arm_1 = ntt.m_l_arms[1]
			
		-- check if grab is still valid
		if ntt.in_grab and get_first_link(arm_1,ntt.grabbed_e) == nil then
			ungrab(ntt)
			sfx(21)
		end
		
		
		local ultragrab = bcheck(ntt.items,0b1)
		local throw_str = 2 + tonum(ultragrab)
		local hp_clip,hp_with_t,hp_out,hp_dir,hp_coll_e = unclip(arm_1,hold_pos)
		local hp_2 = hold_pos+(hp_dir or vec2_zero)
		
		for arm in all(ntt.m_l_arms) do
			if vec2_len(arm.t_pos - ntt.pos) > 14 or not b5 or jump_cooldown > 0 then
				arm.t_active = false
			end
			arm.mass = 0.1	
		end
		

		local function align_arms(do_grab)
			for arm in all(ntt.m_l_arms) do
			
				local chosen_t = hp_2
				-- move arm	
				if (arm.t_active) chosen_t = arm.t_pos
				local dist = chosen_t-arm.pos
				counter_mmnt(dist/64,arm,ntt)


				-- slowdown if grabbing terrain or scaffolding
				if jump_cooldown <= 0 then
				
					if ((arm.is_stnd and not ntt.special_stand) or fget(mget(chosen_t.x\8,chosen_t.y\8), 2)) and do_grab  then
						if not arm.t_active then
							arm.t_pos = chosen_t
							if (arm.is_stnd) arm.t_pos = arm.pos
							arm.t_active = true
						end
						jump_s = true
						arm.mass = 1.1
						arm.vel*=0.1
						accel += 0.2
					end
					
					if hp_clip then
						ntt.vel *= trn_slp*0.2 + 0.7
					end
					
					move_towards(arm,chosen_t, 2)
				end
				
			end -- of for
		end
		

		ntt.on_ladder = false

		if b5 then
			ntt.armgrab = true

			ntt.on_ladder = fget(mget(hold_pos.x\8, hold_pos.y\8), 2)
			align_arms(true)
			
			-- try to grab
			if not ntt.in_grab and not ntt.grab_c then

				if hp_clip then
					if hp_coll_e.mass < 5 and hp_coll_e.rds < 10 or ultragrab then
						ntt.in_grab = true
						if hp_with_t then
							hp_coll_e = tile_to_entity(hp_coll_e.pos\8, false)
						end
					end
				end
				
				if ntt.in_grab then -- take the thing
					sfx(20)
					ntt.grabbed_e = hp_coll_e
					ntt.grabbed_coll_on = hp_coll_e.coll_mask_on
					ntt.grabbed_coll_see = hp_coll_e.coll_mask_see
					
					-- assumes all of subentities have same coll
					for e in all(hp_coll_e.all_ntts) do
						e.coll_mask_on = ntt.coll_mask_on
						e.coll_mask_see = ntt.coll_mask_see
					end
					
					make_link(arm_1,hp_coll_e,1,0.1,false,20)
				end
			end
			
			if ntt.in_grab then

				--rotate grabbed object
				--counter_mmnt((arm_1.pos - ntt.grabbed_e.pos)/32, ntt.grabbed_e, ntt)

				ntt.grabbed_e.input_dir=input_dir_h
			end
		-- end of grab


		else
			--throw if holding, else nothing
		
			if ntt.in_grab then
			
				if vec2_len(input_dir) <= 0 then
					sfx(21)
				else
					sfx(22)
					counter_mmnt(vec2_normalized(input_dir) * throw_str, ntt.grabbed_e, ntt)
					set_timer(ntt.grabbed_e, "hurt", 10)
				end
				
				ntt.in_grab = false
				ntt.grab_c = true
				delete_link(get_first_link(arm_1,ntt.grabbed_e))
				
				-- delay collision swap so doesn't immediately clip in ntt
				function ungrab_d(ntt)
					ntt.grab_c = false
					ungrab(ntt)
				end
				
				delay_timer(delay_timers, 3, ungrab_d,{ntt})
			end
		
		
		end -- of btn5 check
	
	end -- of arms check


	
	-- walking/air move -----------------------------------

	local b0i,b1i,b2i,b3i = tonum(input_dir.x < 0),tonum(input_dir.x > 0),tonum(input_dir.y < 0),tonum(input_dir.y > 0)

	local vel_limit = ntt.a_max
	
	if ntt.grounded_mode and ntt.surface_away.y != 0 then
		accel += ntt.g_acc -- movement
		vel_limit = ntt.g_max
	else -- air drift
		accel += ntt.a_acc
		if (ntt.on_ladder) vel_limit *= 2
	end
	
	ntt.walking = ntt.grounded_mode and	(input_dir.x != 0)
	if not b4 then
		update_right(ntt)
	end
	
	if (ntt.crouch) vel_limit /= 2

	local pv_add = input_dir*accel
	pv_add.x*=(1-tonum(b4)*0.5)
	if ((not ntt.special_stand or #ntt.m_l_legs < 3) and not ntt.on_ladder) pv_add.y = 0
	
	if vec2_len(ntt.vel + pv_add) <= vec2_len(ntt.vel) or vec2_len(ntt.vel) <= vel_limit then
		ntt.vel += pv_add
	end
	
	
	-- jumping -----------------------------------
	

	-- jump control

	
	local jump_g = false
	
	for l in all(ntt.m_l_legs) do
		if vec2_len(l.pos - l.t_pos) < 3 then
			jump_g = ntt.grounded_mode
			break
		end
	end
	
		
		jump_g = jump_g
		-- no downjumps and sidejumps
		and not (surface_normal.y < 0 and (input_dir_j2.y > 0.0 or ntt.leg_facing.y < 0.5) )
		-- or upjumps from ceilings cause that's possible apparently
		and vec2_dot(input_dir_j2, surface_normal) >= -0.02
		-- and no jump clutches
		and (vec2_len(projection(ntt.vel,surface_normal)) < 3 or ntt.ground_is_entity or vec2_dot(ntt.vel, input_dir_j2) >= 0)
	

	local p_prevvel = v2c(ntt.vel)
	
	if b4 and (jump_g or jump_s) and jump_cooldown <= 0 then
	
		local jump_str = ntt.jump_str
	
		if jump_g then
			-- away from surface

			-- try to stabilise jump
			if vec2_dot(ntt.vel, input_dir_j2) < -1 then
				jump_str *= 1.25
			end
			
			input_dir_j2 += surface_normal*0.2
			
		end

		-- add less if already going fast
		for ntt in all(ntt.all_ntts) do
			ntt.vel *= 0.65	
		end		

		local jump_vel = vec2_normalized(input_dir_j2)*jump_str
		
		-- jump start
		--printh("jump'd")
		set_timer(ntt, "jump_cooldown", 9) -- 9 frames of jump cooldown
	
		local g_e = ntt.ground_pos_entity
		
		-- drop kick
		if ntt.ground_is_entity and g_e then
			
			local impct_e = {
				pos = ntt.pos,
				vel = p_prevvel-jump_vel,
				mass = ntt.mass
			}
			impact(impct_e, not ntt.ground_is_entity, jump_vel, g_e)
			lose_stmn(g_e, 3)
			
			sfx(12)
		else
			sfx(10 + flr(rnd(2)))
		end
		--printh("surface: " .. surface_normal.x .. "  " .. surface_normal.y)
		
		for ntt in all(ntt.all_ntts) do
			ntt.vel+=jump_vel
		end
	end
	
	-- alignment direction

 local align_down=v2c(vec2_down)
	
	if ntt.grounded_mode then
		align_down.x-=mid(-1,ntt.vel.x,1)/2
	else
			if b4 then
				align_down=input_dir_l*-3
			else
				align_down.x+=mid(-1,ntt.vel.x,1)/2
			end
			
	end
	
	ntt.leg_facing = vec2_limit(ntt.leg_facing*0.8 + align_down*0.2)
	
	-- only used for head drawing
	ntt.facing = vec2_normalized(input_dir_j*0.2 - vec2_normalized(ntt.leg_facing) + vec2_up*0.3)
	
end


function update_player(player)
	move_humanoid(player)
	
	
	if (get_timer(player, "hurt") >= 20) return
	-- regen stamina
	if (player.stmn < player.stmn_l_t) player.stmn += 0x0.2
	
	local b0i,b1i,b2i,b3i,b4i,b5i = chain_call(tonum,{chain_call(btn,split"0,1,2,3,4,5")})

	-- controls
	local input_dir =	vec2_left  * b0i
																	+ vec2_right * b1i
																	+ vec2_up    * b2i
																	+ vec2_down  * b3i
	
	mod_tabl2(player,"input_dir,crouch,armgrab",{input_dir,btn(3) and player.special_stand,false})
	
	move_control(player, btn(4), btn(5))

	
	-- rotation -----------------------------------

	local i=1
	for leg in all(player.m_l_legs) do
		
		local l_link = get_first_link(player,leg)
		local l_l_len = l_link.true_len
	
		if not player.grounded_mode then
		
			local align_vec = vec2_normalized(player.leg_facing)/9
		
			if (player.is_stnd and vec2_len(input_dir) == 0) align_vec *= 0
			
			counter_mmnt(align_vec/i, leg, player)
			
			l_l_len *= 0.9
			if (btn(4))	l_l_len *= 0.8

		end
		
		l_link.len = l_l_len
		
		i+=1
	end
 
end
-->8
-- data

ntt_b_types = {
--mass,radius, sticky_walk, g_accel,a_accel,g_max_speed,a_max_speed,jump, leg_len,leg_width,arm_len,arm_width,stand h, leg speed,leg g cooldown,leg tol,max leg target rotation, limb list [5 things - type, angle, col, leg_draw, is_front]
split"0.4,4,fls, 0,0,0,0,0, 18,0,1,0,20, 3,3,2.5,0.01", -- no limbs

split"0.6,1,fls, 0.7,0.08,2.2,1.5,2.7, 8.7,0,5,0,7.5, 3,3,2.5,0.05,l,0.015,7,tru,fls,a,0.02,13,fls,fls,l,-0.015,12,tru,tru,a,-0.02,13,fls,tru", -- humanoid


split"0.5,4,fls, 0,0,0,0,0, 18,2,1,0,18, 3,3,2,0.01,l,-0.05,15,fls,fls", -- standing turret
split"0.5,4,tru, 0.3,0.08,2,1,0, 18,2,1,0,12, 4,6,9,0.2,l,0,15,fls,fls,l,0.3,15,tru,fls,l,0.6,15,fls,fls", -- tripod spider

split"0.4,6,fls, 0,0,0,0,0, 18,0,1,0,20, 3,3,2.5,0.01", -- no limbs - generous hitbox
{},
{}
}

enm_types = {
--hp,metasprite,body type,gun,init func,ai index
	split"10,1,3,1,1,1", -- basic turret
	split"30,2,4,1,1,2", -- spider box
	split"20,3,5,1,2,3", -- flying drone
	split"30,4,3,1,1,1",
}

guns = {
--cooldown,projectile speed,p size,p damage,p msprite,fire sfx,p extra (explode, home)
split"45,3.5,3,15,5,18,0"
}

m_sprites = {
	-- sprite,x size,y size, anim total frames, anim frame len
	
	split"163,1,1,3000,1", -- enemies
	split"164,1,1,3000,1",
	split"179,1,1,2,3",
	split"166,2,2,3000,1",
	
	split"168,1,1,3000,1", -- projectiles
}

-- enm_ais has to go after the definitions



l_size_x,l_size_y,l_head_size_x,l_head_size_y = 16,8,10,1
l_start,l_end = 12, 32 -- 32 is excluded

ld_l_size_x,ld_l_size_y = 16,8

item_names = split[[
ultragrab
]]

-- storable in map maybe
palettes = split[[
	1,2,3,   128,132,142,15, 8,9,10,138,    7,12,14,13, 0,
	1,131,4, 2,8,9,10,       3,138,135,143, 7,12,14,13, 0,
	
	142,15,0,  130,2,6,7,   130,8,9,10,   7,12,10,13, 143,

	142,15,0,  142,143,6,7, 130,2,136,8,  7,12,10,13, 143,
	
	
	129,2,3,4,5,6,7,8,9,10,11,12,13,14,15,5,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,
	5,7,3,4,5,6,7,8,5,4,3,2,7,14,15,0,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,
	
	
	1,2,3, 4,5,6,7 ,8,9,10,11, 12,13,14,15,  0,
	
	4,2,3, 1,1,6,7, 1,0,2,11, 12,13,14,15,  0,
	
	4,5,3, 4,5,6,7, 1,0,2,11, 12,13,14,15,  1,
	
	4,5,3, 4,5,6,7, 1,0,2,11, 12,13,14,15,  1,
	
	
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  10,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  15,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  7,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,  12
]]


col_tbl=split"12, 137, 131"

lvls_extra_info = {
--1st array: general extra info
-- name
-- next lvl (0-indexed, -1 is finish)
-- player spawnpos x & y
-- camera pos in main menu

--2nd: enemy spawns
-- xpos, ypos, type, item(0 if none)

--3rd: signs
-- x1,y2,x2,y2, text,num lines

{split"tutorial, 1, 20,182, 150,80",split"455,120,1,0", split"50,80,150,260,press 🅾️ to jump.\nyou jump in the direction\nyou are currently holding.,3,410,100,470,140,jump off \fehostile machines\fc\nto deal damage.\nhold 🅾️ to rotate mid-air.,3",},
{split", -1, 20,116, 0, 0",split"180,180,1,0,420,180,3,0,420,50,1,1",{}},
{split"1-1, 3, 10,180, 60,80",split"420,210,3,0",{}},
{split"1-2, 4, 10,50, 60,80",{},{}},
{split"1-3, 5, 10,40, 60,80",{},{}},
{split"1-b, -1, 10,180, 60,80",{},{}}

}

m_index,start_lvls=0,split"0,1,2"


-->8
-- level managment
function lvl_extrainfo(index)
	return lvls_extra_info[loaded_lvl_index+1][1][index]
end

function load_lvl_header(mx,my)
	local header = {}

	local bits,bytes = 0,0
	local function add_bits(num)
		add(header,(mget0x20(mx+bytes,my)>>bits)&(2^num-1))
		bits += num
		if bits >= 8 then
			bits=0
			bytes += 1
		end
	end
	
	chain_call(add_bits,split"2,2,4,4,4")
	
	local function add_bg()
		chain_call(add_bits,split"4,4,3,1,4,4,4,4,4")
	end

 add_bg()
 add_bg()

	return header
end

function unpack_pal(o)
	local pal_l = loaded_level[1][o]*16
	return {unpack(palettes, pal_l+1, pal_l+16)}
end

function load_lvl(index)
	camera_x,camera_y = lvl_extrainfo(5),lvl_extrainfo(6)

	local map_pos_x = (index%8) * l_size_x
	local map_pos_y = (index\8) *(l_size_y + l_head_size_y) + l_start

	loaded_level = {load_lvl_header(map_pos_x,map_pos_y),{}}

	for j=0, l_size_y-1 do
		for i=0, l_size_x-1 do
		 add(loaded_level[2], mget0x20(map_pos_x+i,map_pos_y+l_head_size_y+j))
		end
	end
	
	-- set size
	ld_l_size_x,ld_l_size_y = 16,8
	
	
	if bcheck(loaded_level[1][1],0b10) then
		ld_l_size_x,ld_l_size_y=32,4
	end
	if bcheck(loaded_level[1][1],0b01) then
		ld_l_size_x,ld_l_size_y=ld_l_size_y,ld_l_size_x
	end

	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1
	
	
	-- clear map
	memset(0x8000, 0, 0x2000)
	for t_c=0, #loaded_level[2]-1 do
		draw_tile(loaded_level[2][t_c+1], t_c%ld_l_size_x, t_c\ld_l_size_x)
	end
	
	lvl_pal1 = unpack_pal(4)
	lvl_pal2 = unpack_pal(5)

	pal(lvl_pal1, 1)
	

	
end


function tile_spr(s, alt_l, alt_t, random)
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
	
	-- alt texture
	if (alt_t and not fget(s1,7)) s1+=0b01000000

	if random and bcheck(s1, 0b100000) and (s1 & 0b001000 == 0) then -- in bottom left part of spr page
		-- flip 1st bit
		if (rnd(10) > 9) s1 ^^= 0b1
	end
	
	return s1
end

function draw_tile(t,x,y)
	
	local extra_t = t&0b11000000

	local t2 = t&0b00111111
	
	for j=0,3 do
		for i=0,3 do
			local m_x,m_y = x*4+i, y*4+j
			srand(m_x + m_y*ld_l_size_x)
			mset(m_x,m_y, tile_spr(mget0x20((t2%32)*4+i,(t2\32)*4 +4+j), bcheck(extra_t, 0b1000000), bcheck(extra_t, 0b10000000), true))
		end
	end
	

end

-->8
-- enemy ai


function update_enm(enm)
	
	update_right(enm)
	
	local hurt = not timer_ready(enm,"hurt")
	
	if vec2_len(enm.pos - player.pos) < 55 then
		enm.active=true
	end
	if vec2_len(enm.pos - player.pos) > 110 or hurt then
		enm.active=false
	end


	enm.special_stand = false
	if enm.active then
		enm.ai(enm)
		if timer_ready(enm, "gun") then
			fire_gun(enm, enm.gun)
		end
	else
		set_timer(enm, "gun", enm.gun[1])
	end
	
	if (enm.flying and not hurt) enm.special_stand = true
	
	if (enm.stmn/enm.stmn_l_t < 0.35 and anim_c%12==0) particles(enm.pos, split"3, 2.4,-1,0.2,8", vec2_up*0.5)
	
end

function update_turret(enm)

	if player.grabbed_e != enm then
		enm.input_dir=vec2_limit(player.pos - enm.pos)
		enm.input_dir.y=0
		move_humanoid(enm)
	end

	enm.stnd_height = enm.stnd_height*0.5 + (mid(4, enm.pos.y - player.pos.y +9, 19))*0.5

end


function update_follow(enm)
	enm.input_dir=vec2_limit(player.pos - enm.pos)

	move_humanoid(enm)
	move_control(enm,false,false)
end

function init_flying(enm)
	enm.flying = true
end

function update_flying(enm)
	enm.input_dir=vec2_limit(player.pos - enm.pos)
	
	enm.vel *= 0.9
	local dist = vec2_len(player.pos - enm.pos)
	if (dist > 50)	enm.vel += enm.input_dir/4
	if (dist < 35)	enm.vel -= enm.input_dir/4
end

enm_inits = {empty_f,init_flying}
enm_ais = {update_turret,update_follow,update_flying}


function projectile_disappear(e,prev_v,impact,other_e)
	
	if remove_entity(e) and in_tbl(e.parent,entities) then
		
		particles(e.pos, split"12, 2.5,-1", e.vel)
		
		if other_e then
			if (other_e == player) sfx(19)
			lose_stmn(other_e, e.dmg)
			apply_momentum(other_e, prev_v/2)
		end
		
	end
end



--cooldown,projectile speed,p size,p damage,p msprite,fire sfx,p extra (explode, home)
function fire_gun(e, gun)
	local cldwn,spd,size,dmg,mspr,sfx,extra = unpack(gun)
	
	sp_sfx(sfx,e.pos)
	local proj = spawn_entity(0,0,0.1,size,"projectile",e)
	proj.vel+=vec2_normalized(e.input_dir)*spd
	mod_tabl2(proj, "dmg,coll_func,m_sprite,special_stand",{dmg,projectile_disappear,m_sprites[mspr],true})
	add(e.all_ntts, proj)
	
	set_timer(e, "gun", cldwn)
	delay_timer(delay_timers,60,remove_entity,{proj})
end

__gfx__
00000000555555544444444444444444aabbbaa9ba9999aabbbbbaabbaaabbbbb808808a0b0b0b0bbbbbbabb8b8b8b8b0007d00011111f11cccccfc8ccc8ccc8
00000000555555444444444455555554b99999989988889aba999999a999999bba0880aa8a8a8a8a8a8888a8aaaaaaaa0007d000151fcfcfcffc8c88fff88f88
00000000544444444444444454444444b99999989a999899a9999999999999aab8a88a8abbbbbbbb00a00a00bbbbbbbb0077770011111c11cffc88c8c8ccf888
00000000555555444444444454445454b9999998a8888889a999999999999999b80aa08a00888800888aa888aba88aba777dd7775f155f15cfc8fff8f8f888ff
00000000544444444444444454454454a99999989999999a9999999999999999b80aa08a00088000888aa8888abaaba8dd7dd7dd1f511111cc88fff8cc8fcc88
00000000555555444444444454444454a99999989988889aa999999999999999b8a88a8a0008800000a00a008a8bb8a800777700cfcf115fc8fc8ff8ff888ff8
00000000444444444444444454444454a9999998a9998999a9999998a9999998aa0880aa008888008a8888a8aabaabaa0007d0001c111111cffff8f8c8ffff88
0000000055544444444444444455555498888889aa999a9aaa999888aa999888a808808aaaaaaaaaaaaaaaaaab8888ba0007d0005f515f51f888888f8ff88888
11111111222222225555555500000000aaa99999999999ab9999999999999999000000000000000000000000444444c450044005444444445555555559559959
11111111222222225555555500000000ba9999999999999a9999999999999999000000000000000000000000dddd4ddd55044055555555550500005045999999
11111111222222225555555500000000baaa99999aa9aaabaa99999999999999000000000000000000000000444444c450544505444444440050050044599555
11111111222222225555555500000000a99a9999999999ab99999999999aa9990000000000000000000000005d45554550055005555555554445544444459999
11111111222222225555555500000000baaaaa9999aaaaaaa99999aaa99999aa0000000000000000000000004d44444450055005444444444445544444445999
11111111222222225555555500000000ba9999999999a99bbaaaa999999999990000000000000000000000004d5545c550544505555555550050050055444599
11111111222222225555555500000000aaa99aa99999aaab99a9999999999aab000000000000000000000000cdcccccc55044055444444440500005044444459
11111111222222225555555500000000b9999999999999abbaabbba999bbbabb0000000000000000000000005d5455c450044005555555555555555545554445
44444444444444444554455455555555baa9baa9aaa99999bbbbbaababbbbbaababbbbba44444444ba9cba9b554555454447744405020f002222222122222121
5555455545554455445544555455445599999999999999999a9999999999a999b8aaaa8a88888888aa9bba9b5545554545554555555fcfcf2111111122121212
44444444444444445445544554455445a9baa9aaa99999aaaaa9aaaaaa9aaa9ababaabaa44444444ba9bba9b554555454477774405020c002222211121212111
5545554554455445554455445544554599999999999999999999999999999999aaaaaaaa88888888ba9bba9b55455545757dd7472f222f20f277772ff577775f
44444444444444444554455455544555baa9aaa9baa9aa99a9999aa9aa9aa999baaaaaa899888989ba9bba9b55455545d47dd74d0f02050072fff22275fff555
4555455545444555445544555455445599999999999999999999999999999999aabaaba888888888ba9bba9b5545554545777755cfcf555f7221111772111117
44444444444444445445544554455445a9aaa9aa999aa9aa9999999999999999a8aaaa8899999999ba9bba9b55455545444444440c0205007111111771211117
5554555455545554554455445555555599999999999999999999999999999999aa888a8899999999ba9bba9b55455445554775540f000f002211111251111115
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008f8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000c000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c0c00000c0c00000c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000c0c0000c000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0086680000088000000000000e000000fffffff30000000000333300000000000000000000022000002222000000000000000000000000000000000000000000
0fc666f000f66600000000000f00000033333ef300000000033333330000000000022000002ee20002ecce20000000000000000000000000000000ffcc000000
8cc6fff80fc66f80000000003f3330003333e3e3000000003333333333000000002ee20002ecce202ecccce200000000000000000000000000007ffccfff0000
666fff888666ff83000000003f3333003ee33e3300000000333333333333000002ecce202eceece22cccccc20000000000000000000000000007ffc99ffff000
66ffff83866ff88300000000fefeefefe3fe333300000000333333333333330002ecce202eceece22cccccc2000000000000000000000000007ff9eeee9fff00
86fff88306ff883000000000ffffffffef3e3333000000003333333333333333002ee20002ecce202ecccce200000000000000000000000000ff9333f339ff00
0ff888300088830000000000333333003eef333300000000fff333333333333300022000002ee20002ecce2000000000000000000000000007ffe33ef33efff0
008833000003300000000000333333003333333300000000333fffffffffffff0000000000022000002222000000000000000000000000000ff9e3e3f33e9ff0
ddcdcddda9ca9cc911111ccc00fff30000fff30000fff300333333333333333300ffff00000000000c0ccf0000cf0cf000ffff00000000000fc9eeeef33e9ff0
dcfcfdcd9acacc98111ccc5c0ff333300ff333300ff3333033333333333333fe0ffffff0000000000cfcf0ffc0cfff000ffffff0000000000cffef3ef33efff0
dc8c8cfcf7ccc98915c5653cfe3e33e3efe33e3efe33e33e333333333333fefefefffffe00000000c0cffff0cffcfffff8fffff80003300000ff93fef339ff00
ccfff8ccf7cccccc5c5653c133333333333333333333333333333ffff3fefefeffcfffef00000000cffeefff0cfeefffff8ffff8003ee30000fff9eeee9fff00
fc88ff8ff7cccccc51c533c13333333333333333333333330333f3333ffefe00fffccef800000000cffeefffcffeeff0fff8ff88003ee300000ffff99ffff000
cfff8fccf7ccc9881c5c3c11ee3333eeee3333eecc3333cc003f333333fe0000fffcff83000000000cffff0fccfffffffff8f883000330000000ffffffff0000
dcfffcdd9acacc98c5c1c511cce33ecc00e33e0000c33c00000f33333f0000000ffef83000000000cf0cfff000cfff0f0ff8883000000000000000ffff000000
ddcccddda9ca9cc95c1151110cc00cc0c000000c000000000000000000000000008e83000000000000cff0f00cc0ff0000883300000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000544440000000000000055
aa000000000aaaaa00000000000000aa000000000000000000000000000000000000000000000055554400000000000055400000000544444444000000005555
00aa00000aaa000000000000000aaaa0001110000000000000000110000000000000000000000555554400000000055555440000005544444444444400555544
00000000000000000aaaa00000000000001111000000011000011110000001100000000000000555554400000055555544444000005444444444444455554444
00000000000000000000000000000000001111000011011000011110001101110000000005555555544444445555544455444400055444544444444455444544
0990000000aaaaa00000000000000000011111000011011111011110001101110000000055555555544444445544455555444440054544544444444445554444
000000000aa999aa0000990000000000111111000111111111111111001101110000000055555555544444444455555555444444554544544444444455444544
00000000aaaa9999990000000aaa0000111111001111111111111111001111110000000054545454544444445555555544444444545544444444444445554444
0000009aaa9999999aa00000aaa9a999111111001110000000000000000011100000000055555555544444445555544455444444545544445400000055444544
000999aa9999999999aa000aa99a9a00111111101111110000000000000011110000000054445454544444445544455555444444455544445444000045554444
99aaaaaa99aaaa009999a0aa99999999111111111111111100000000000011110000000055555555544444444455555555444444455544445444440055444544
0aaaaaa9aaa99aaa99999a999a999990111111101111111100011000000011110000000054545454544444445555555544444444555444445444444445554444
aaaa999aa999999a9999999aa99aa999111111111111111100111111000011110000000055555555544444445555544455444444555444545444444455444544
aa9999aa999aaa9999aaa9999aaa9a9a111111111111111100111111001011110000000054545444544444445544455555444444554544545444444445554444
a99aaaaa99aaa9999aa9999999a9a9aa111111101111111100111111101111110000000055555555544444444455555555444444554544545444444455444544
99aaaaa99aa999999999999999aaaaa9111111101111111100111111111111110000000054445444544444445555555544444444545544445444444445554444
9aaa99999999999999999900aaa99999000000000000000000000000000000000000000000000000000000000000000000000000099000000000000000940000
aaa9999999999aaaaaaa9090a00aaaa9000000000000000000000000000000000000000000000000000000000000000000540009999990000000000094444000
a9999aa9999aaaa999aaa9090aa99999000000000000000000000000000000000000000000000000000000000099000000544005999440000000009544444400
99999999999999999a99aa00aa9aa999000000000000000000000000000000000000000000000000000000000059900000544005554440000000095544444400
aaaaaaa999999999999999a0a9aa9990000000000000000000000000000000000000000000000000000000000054400000540005554400000000955554444440
aaaa999999999999999999909a999909000000000000000000000000000000000000000000000000000054400554400005440055554400000009555554444444
a99909099999999999999aa900909090000000000000000000000000000000000000000000000000000054444554000005400055554400000095555555444440
9990909099aa99990099aa9900000000000000000000000000000000000000000000000000000000000554440550000005000055544000000955555555444440
00000000000000000000000000000000000000000000000000000000000000000000000000000000000554440504000000400055540000000555555555544400
00000000000000000000000000000000000000000000000000000000000000000000000000000000000554440059900054000055400000000555555555544400
00000000000000000000000000000000000000000000000000000000000000000000000000000000000544400005999000000505040099000055555555554000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000544400005544000000050405994000055555555554000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000544400055544000000000005544000005555555550000
00000000000000000000000000000000000000000000000000000000000000000000000000000000005544000055440000999000005544000005555555000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000005444000055440000999900005544000000555500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000005444000055440000599990005544000000550000000000
__gff__
8808880801010101010101018484838308088800010101010000000808880800080808080101010101010108848482820808080801008101010101018384838308080808000001010000000000000000080808080000010100000000000000000808080800000101000001010000000008080808000001010001000100000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d50000c00000c300c1c2c37170707100707173000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd02c4d6d7c6c510c4c7c2c1d0d3d0d1d2e26160616071606162000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9dac5dbdccfdd02d410101010101010e3e1d3d0e0e1d1d06260636361616362000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9da10dbdcdfdd021010101010101010d0d1d0e0e2e1d1e26667666767666767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000036363636062627272626272614f676767676f615464706072a2a2a2a26262726210321203232323226272626e0e0e0e0042020200000000020202421090b0909005c0001090b090b0008001c242020202020202421212121202020200000000025253636363614360000000000000000000000000000000000000000
0000000036363636143636363636363614f676767676f615565716173a3a3a3a39393939626262626060606036363636224647220404030300000000212124210008001c005c001c230800080008001c242003202020202422222222cfcece020000000036f936f936f914360000000000000000000000000000000000000000
0000000036363636373636363636363614f676767676f61506070607363b252460606160262726276060616036363636225657222626272605272627200324201e081e230a0b0a0a0a0b0a0b1e0b1e2324202020202020240e0f0f0fcecfcecf3232323236421442254214360000000000000000000000000000000000000000
0000000036363636163736173636363614f676767676f615161716172525242502020202393939390404040439393939e0e0e0e01636363604363637030324030008001c0008001c000823080008001c24202020202020240f0f0e0e2626262602cececf36e925e936e914360000000000000000000000000000000000000000
02020202222222222020202001202020202020200202020232323332011e1e011f3736362b2b2b2b23c0c023011e1e011e011e1e02020200717071711e23c11e00000000001cc01c3000000000000000000000000000000020202020000000000000000000000000000000000000000000000000000000000000000000000000
020202022222222221e0e020202021202003200320202021202020211c22221c021f36372b2b2b2b1cc0c01c30000030c0f0c0c00202020061706070c0f0c0c000000000001cc01c3000000000000000000000003100310002020202000000000000000000000000000000000000000000000000000000000000000000000000
020202022222222220e0e021212020202001200121202020212020201c22221c02021f362120202123c0c023300000231e011e1e02020200606361601e23c11e00000000001cc01c30000000000000000003002b3031303100000000000000000000000000000000000000000000000000000000000000000000000000000000
02020202222222222020202042424242202020202222222222222222011e1e012020201f032021201cc0c01c01323201000000000202020063626163001cc01c000000000023c02330000000323232323203032b3021203000000000000000000000000000000000000000000000000000000000000000000000000000000000
0093220b88414103ab000000000000000093220b9841610ca2000000000000000093220c78426104a80000000000000002a3220b9842400488000000000000000082410b850060048800000000000000008241038800600398000000000000000282410b85006003880000000000000000000000000000000000000000000000
000000000000000000000000000000000000000004052c2c0405310000000b0b0000000000000000000031000000000000000000006f0000006f6c6f006c6f6c0000000e0e1834000000000000003119000000000024624c242024202d0022040500000019191a6c6c6f08080000000000000000000000000000000000000000
0000000000000000000000000000000000000000040500000405713333340f230000710c4c2c0c4c0c4c14026f6c6c6c6c2d000000000000003100000b0b2c2c000000191919056c2c0b0b2d00002f190000000000244c22242024202d0062040008086c6f6c0808080405000000001900000000000000000000000000000000
0000000000000000026e2d00000000000000000004052c2c04057108080b0203000071000000003100001404710019190000333400710000006f007100007100020000191919056c6c6f25252d003123000000000024626224204c202d0062040500000019191a6c6c6f25256c6c070000000000000000000000000000000000
0000000000000000045a2d2e35342e0a2e2e0a160405000008086f6f2c2f0401006c6f6c6f6c6c6f6c6c140471001919006c0203110e0603446f2f0025250000052c6c1919190558580c19052d076f190000000000224c2222204c202d0062020025250071002525250405350000000400000000000000000000000000000000
0700000000000000045a456e030303030303032a080800000000316f6c6c02010000006c6f000071001109026f6f191919191a052d6f003333713471330e293305000057230823620c1919052d6f6c190000333334230917230916202d18160f2533343508080834357108080000310000000000000000000000000000000000
2b000000000e332908084504010101010101012625296c6c6c6c29713416040100000000712e35712c2f23312f7119196c6c1902100610014419191a03090000052c6c040362026c2c0b0b0b29710019352e6f070203030303030303030303031702036c6f6c0203092525222e35184400000000000000000000000000000000
03030d0210030302090b0b040101010101010103030302000002030303030101030d3000710210020d0917093171040119191a052d31191919191a0219191a05056c2c0b086208226223082357716c04191a03030303030303030303030303030d0957575717575757095757570e090300000000000000000000000000000000
0201015a130101010101010401010101010101010101050000040101010101010103121010021001010303030303030300001202120213024419191a01050d0e01575757174a57575717090303310003191a01010101010101010101010101010101010031000401021709030303030300000000000000000000000000000000
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

