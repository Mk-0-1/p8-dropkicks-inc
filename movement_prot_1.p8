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
	--init global vars
	
	cartdata("mk_0_test1")
	
	--dset(0,10)

	mod_tabl(_ENV,"trn_bnc,trn_slp,grav/0.2,0.75,0.192")
	mod_tabl(_ENV,"camera_x,camera_y/0,0")

	mod_tabl(_ENV,"delay_timers,delay_timers_draw/{},{}")

 -- timers & counters
 mod_tabl(_ENV,"anim_c,max_anim_len/0,2048")
 mod_tabl(_ENV,"t_enms,lvl_enms,t_e_clear,lvl_e_clear,t_trinkets,t_tr_collected/0,0,0,0,0,0")
	
	-- use extended map by default
	poke(0x5f56,0x80)
	
	-- no repeat btnp
 poke(0x5f5c,255)

	-- EDITOR ONLY - keep pal changes when esc
	poke(0x5f2e, 1)

	load_lvl(1)
	menuitem(5,"music:on",set_mus)
	
	_update,_draw = _update_m_menu,_draw_m_menu
end


function text_box(str,screen,x,y,xlen,ylen,c1,c2)
	if (screen=="true") camera(0,0)
	if (c1 and c1>-1)rrectfill(x,y,xlen,ylen,0,c1)
	if (c2 and c2>-1)rrect(x+1,y+1,xlen-2,ylen-2,0,c2)
	print(str,x+6,y+4,7)
	camera(camera_x,camera_y)
end

function fade_text(x,y,text,t,dx,dy,rel,screen)
	if (screen=="true") camera(0,0)
	print(text,x,y,7)
	if t<(rel or 1000) then
		x+=dx or 0
		y+=dy or -0.5
	end
	if (t>0) delay_timer(delay_timers_draw,1,fade_text,{x,y,text,t-1,dx,dy,rel,screen})
	camera(camera_x,camera_y)
end

function _draw_m_menu()
	draw_common()
	map(unstr"0,0,0,0,128,64,0b1000")
	map(unstr"0,0,0,0,128,64,0b00000111")
	
	if not lvl_loading then 
		if lvl_locked then
			text_box(unstr("???\n\ncomplete previous\nlevel to unlock,true,8,8,80,32,8,9"))
		else
			text_box(unstr(lvl_extrainfo(1).."\n\nhiscore:"..lvl_hiscore..",true,8,8,56,28,8,9"))
			text_box(unstr("\^o80b🅾️:begin           ❎:info,true,0,112,56,28,-1,-1"))
		end
	end

	update_draw_timers()
end

function update_draw_timers()
	update_timer_tbl(delay_timers_draw)
end

function _update_wait()
	menuitem(2)
	update_timer_tbl(delay_timers)
end

lvl_hiscore,lvl_locked,lvl_loading=0,false,false
function _update_m_menu()

	if btnp(0) or btnp(1) then
	
		local xdir=-28
		m_index -= 1
		
		if btnp(1) then
				xdir=28
				m_index += 2
		end
		
		screenwipe(xdir,32,8)

		m_index %= #start_lvls
		
		
		local function lvl_ds()
			l_index = start_lvls[m_index+1]
			load_lvl(l_index)
			if (lvl_locked) pal(split"133,134,11, 129,1,0,7 ,134,13,6,7, 12,6,14,13,  0",1)
			lvl_loading=false
		end
		lvl_loading=true
		lvl_locked=m_index>0 and dget(m_index-1)<=0 
		delay_timer(delay_timers,8,lvl_ds)
	end
	
	if btnp(4) and not lvl_locked then
		screenwipe(unstr"24,56,9")

		local function bgn_scr()
			cls(9)
			camera(0,0)
			print("\^o80b\^j22"..lvl_extrainfo(1).."\n\^w\^t\^5\^j25"..lvl_extrainfo(7).."\^-w\^-t\^5\^d1"..lvl_extrainfo(8))
			--if lvl_hiscore <= 0 then
				--text_box(unstr("\^4\^d1"..lvl_extrainfo(8).."\^5,true,8,40,112,80,8,10"))
				--pal(7,6,1),pal(7,13,1)&pal(7,5,1) with pauses inbetween. the 13 is 1d as 0d is newline
				print("\^@5f170001⁶\^2\^@5f170001。\^2\^@5f170001⁵\^2")
			--end
			cls(9)
			begin_lvl(false)
		end

		delay_timer(delay_timers_draw,16,bgn_scr)
		
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



function begin_lvl(cont,retry)
	
	if cont then
		lvl_prevmus = lvl_mus or 0
		if retry then
			--idk
		else
			t_enms+=lvl_enms
			t_e_clear+=lvl_e_clear
			
			if (lvl_extrainfo(7) != "") then
				delay_timer(delay_timers_draw,10,fade_text,{0,2,"\#6 "..lvl_extrainfo(7).."\^-#\f6\|f\^:7f3f1f0f07030100",84,-8,0,20,"true"})
			end
			
		end
		mod_tabl(_ENV,"lvl_enms,lvl_e_clear/0,0")
		
	else
		mod_tabl(_ENV,"t_enms,lvl_enms,t_e_clear,lvl_e_clear,y_u_l/0,0,0,0,0")
	end
	
	load_lvl(loaded_lvl_index)
	_update,_draw,delay_timers=_update_inlvl,_draw_inlvl,{}
	

	update_mus()
	if (lvl_mus != lvl_prevmus and mus_enabled)	music(lvl_mus)
	
	
	menuitem(2 | 0x300, "retry area",retry_lvl)
	menuitem(3 | 0x300, "exit level",exit_lvl)
	

	init_entities()
	camera_x,camera_y,prev_cam_speed=player.pos.x-64,player.pos.y-64,vec2_zero
end

function load_next()
	if lvl_extrainfo(2) >= 0 then
		loaded_lvl_index=lvl_extrainfo(2)
		begin_lvl(true)
	else
		t_enms+=lvl_enms
		t_e_clear+=lvl_e_clear
		lvl_score = ((t_e_clear/t_enms + t_tr_collected/t_trinkets)*100)\1
		if(lvl_score > dget(m_index)) dset(m_index,lvl_score)
		music(-1,1000)
		menuitem(3)
		_update = _update_finish
		_draw = _draw_finish
	end
end

function lvl_transition()
	if (lvl_extrainfo(2) > 0) screenwipe(unstr"24,48,8")
	_update=_update_wait
	delay_timer(delay_timers,8,load_next)
end

function exit_lvl()
	screenwipe(unstr"24,40,12")
	delay_timers={}
	menuitem(2)
	menuitem(3)
	_update=_update_m_menu
	delay_timer(delay_timers,10,function() _draw=_draw_m_menu load_lvl(start_lvls[m_index+1]) end)
end

function _update_finish()
	if btnp(4) then
		
		exit_lvl()
	end
end

function _draw_finish()
	draw_common()
	map()
	camera(0,0)
	print("\f7\n\n\^w\^t\^o8ff\^3\^d1 "..lvl_extrainfo(1).."\n\^d0       \^4\^3complete!\n\n\n\^-w\^-t\^5\^4 ◆ "..t_e_clear.."/"..t_enms.." machines 'disassembled'\n\n\^5\^4 ◆ "..t_tr_collected.."/"..t_trinkets.." trinkets found\n")
	print("\f7\^5\^4\^o8ff\*3 score: \^5" .. lvl_score .. "\^4\n\n\n\*6 press 🅾️ to continue")
	camera(camera_x,camera_y)
	_draw=update_draw_timers
end


function init_entities()
	
	-- clear ALL
	entities,all_links={},{}
	player = spawn_player(lvl_extrainfo(3),lvl_extrainfo(4))
	add(entities,player)
	
	local e_arr = lvl_arr(3)
	for i=1, #e_arr, 4 do
		local e_type,ex,ey,e_extra = unpack(e_arr, i)
		local e=spawn_entity(ex,ey,e_type,nil,e_extra)
		add(entities,e)
	end

	--music(0)
end

--tugs_per_frame,MAC_per_frame,frame_c=0,0,0

function delay_timer(tbl, ticks, func, args)
	local timer = {t=ticks,f=func,a={}}
	if (args) timer.a=args
	add(tbl, timer)
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
			timer.f(unpack(timer.a))
			del(tbl,timer)
		end
	end
	
end

function _update_inlvl()
	anim_c+=1
	anim_c%=max_anim_len

	-- update delays and timers
 update_timer_tbl(delay_timers)

	mus_combat=false
	-- update entities
	for ntt in all(entities) do
		if (ntt.active) mus_combat=true
		for subntt in all(ntt.all_ntts) do

			if (not subntt.ignore_physics) move_entity(subntt)
			if (subntt.update_func) subntt.update_func(subntt)

			
				-- cleanup tile entities
			if subntt.e_type == "tile" and subntt.is_stnd
			and vec2_len(subntt.vel) < 0.02 and not (player.in_grab and subntt == player.grabbed_e) then
				entity_to_tile(subntt)
			end
			
			if subntt.stmn and subntt.stmn <= 0 then
				remove_entity(subntt)
			end
			
			test_borders(subntt)
		end
		
		for name, timer in pairs(ntt.timers) do
			ntt.timers[name] = max(0, timer-1)
		end
	end
	
	if (stat(50) == 31) update_mus()
	
	--check entity links and pull/push them if needed
	--run this for loop multiple times for slightly more accurate link physics
	--for j=1, 1 do
	foreach(all_links, tug)
	--end

		
	if player.pos.x > l_border_x+4 and btn(1) then
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
	
	camera_x,camera_y,prev_cam_speed=mid(0,camera_x,l_border_x-127),mid(y_u_l,camera_y,l_border_y-127),speed

end
 
function draw_common()
	cls(lvl_maininfo(13))
	camera(camera_x, camera_y)
	
	draw_bg(0)
	draw_bg(10)
end
	
function _draw_inlvl()
	draw_common()
	
	map(unstr"0,0,0,0,128,64,0b1000")
	draw_lvl_borders()
	
	for ntt in all(entities) do
		if (ntt.early_draw) ntt.draw_func(ntt)
	end
	
	map(unstr"0,0,0,0,128,64,0b00000111")
	
	local text_arr = lvl_arr(4)
	
	for i=1,#text_arr,3 do
		local x,y,text = unpack(text_arr,i)
		text_box(text,false,x,y)
	end
	
	draw_links(false)
	
	for ntt in all(entities) do
		if (not ntt.early_draw) ntt.draw_func(ntt)
	end
	
	draw_links(true)

	draw_ui()
	
	
	-- update delayed draw functions
	update_draw_timers()


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

--function mset0x20(x,y,v)
--	poke(maddr0x20(x,y),v)
--end


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
		tab[k[i]]=_pars(v[i])
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
--[[function unstr_p(str)
	local t = split(str)
	for i=1, #t do
		t[i] = _pars(t[i])
	end
	return unpack(t)
end
]]--


function bcheck(v,b)
	return (v or 0) & b != 0
end

function tonum_flip(b)
	return tonum(b)*2-1
end

-->8
-- entity managment

mod_tabl(_ENV, "entities,max_entities/{},256")

function get_first_link(e1,e2)
	if e2 then 
		for link in all(all_links) do
			if ((link.from == e1 and link.to == e2) or (link.from == e2 and link.to == e1)) return link
		end
	else
		for link in all(all_links) do
			if (link.from == e1 and link.to_ground) return link
		end
	end
end

function timer_ready(e,n)
	return e.timers[n] <= 0
end

function timer_active(e,n)
	return not timer_ready(e,n)
end

function spawn_entity(x,y,type,parent,extraprops)
	local entity = mod_tabl2({},"pos,vel",{vec2_new(x, y),v2c(vec2_zero)})
	
	local pr = split(ntt_types[type], "|")
	local props_c,props_e = pr[1], pr[2]
	mod_tabl(entity,"rds,mass/" .. props_c)
	
	local m_spri,ifi,ufi,dfi = unpack(split(props_c),3)
	-- only primary entities can have timers - non-custom ones, anyway
	mod_tabl2(entity,"template,timers,bounce,slip,grav,m_sprite,update_func,draw_func,input_dir,all_ntts",{type,{},trn_bnc,trn_slp,grav,split(m_spri,":"), _ENV[ufi], _ENV[dfi],v2c(vec2_zero),{entity}}) 
	
	mod_tabl(entity, "is_left,coll_rng/false,0")
	
	mod_tabl(entity,props_e)
	if (extraprops) mod_tabl(entity,extraprops)
	mod_tabl(entity.timers,"hurt,hitshock,jump_cooldown,stun/0,0,0,0")
	
	entity.coll_func = _ENV[entity.coll_func] -- table[nil] is nil so works without if
	entity.break_func = _ENV[entity.break_func]
	entity.smoke = smokes[entity.smoke]
	
	if parent then
		entity.parent=parent
		entity.pos+=parent.pos
		entity.vel+=parent.vel	
	end
	
	entity.stmn_l_t = entity.stmn

	
	if (entity.enemy) lvl_enms+=1
	
	if entity.item==4 then
		t_trinkets+=1
	end
	
	if entity.b_type then
		init_complex(entity)
	end
	
	if entity.rope then
		init_roped(entity)
	end
	
	_ENV[ifi](entity)
	
	return entity
end

function spawn_player(px,py)
	
 local player_l = spawn_entity(px,py,2)
	--spawn_complex(px,py,ntt_b_types[2],{80,40},0b00000010,0b00001101)
	mod_tabl(player_l,"e_type,in_grab,grabbed_e,items,col/player,false,nil,0,12")
	
	return player_l
end

function init_complex(e)
	local b_info = split(ntt_b_types[e.b_type])
	e.props = b_info
	mod_tabl(e,"grounded_mode,ground_entity,crouch/false,nil,false")
	mod_tabl2(e,"leg_facing,facing,input_dir,surface_away",{vec2_down,vec2_up,vec2_zero,vec2_up})
	mod_tabl2(e,"sticky,g_acc,a_acc,g_max,a_max,jump_str,leg_len,arm_len,stnd_height,leg_speed,leg_cooldown,leg_angle_range",b_info)
	
	--subentity mappings for limbs
	mod_tabl(e,"m_l_legs,l_angles,m_l_arms,a_angles/{},{},{},{}")
	-- cooldown for movement
	e.m_l_arms.cd,e.m_l_legs.cd=0,0
	
	for i=13, #b_info, 11 do
		local e_typ,l_typ,angle = unpack(b_info,i)
		local l_e = spawn_entity(0,0,e_typ,e)
		mod_tabl2(l_e,"t_pos,t_active,angle",{l_e.pos,false,angle})
		
		add(e.all_ntts, l_e)

		if l_typ=="l" then
			add(e.m_l_legs, l_e)
		else
			add(e.m_l_arms, l_e)
		end
	 
		make_link(e,l_e,{unpack(b_info,i+3,i+10)})
	end
	
 return e
end

function update_item(i)
	if vec2_len(i.pos-player.pos) < 8 then
		if i.item == 5 then
			player.stmn_l_b=mid(0,player.stmn_l_b+i.amount, 80)
		else
		
			if i.item == 4 then
				t_tr_collected+=1
			else
				player.items |= 1 << (i.item-1)
			end
			
			fade_text(i.pos.x,i.pos.y,item_names[i.item],45)
		end
		remove_entity(i)
	end
end

local function spawn_next(e)
	add(entities,spawn_entity(e.pos.x,e.pos.y,e.next_e))
end

function i_e(enm)
	mod_tabl2(enm,"gun,e_type,is_left,special_stand",{split(guns[enm.gun]),"enm",true,true})
	
	if enm.next_e and enm.next_e > 0 then
		enm.break_func = spawn_next
	end
	
end

function retry_lvl()
	screenwipe(-24,36,8)
	delay_timer(delay_timers,6,begin_lvl,{true,true})
	_update=_update_wait
end

function remove_entity(e, noeffect)
	if e == player or e.parent == player then
		retry_lvl()
		return
	end

 for ntt in all(e.all_ntts) do

		for link in all(all_links) do		
			if (link.from == ntt or link.to == ntt) delete_link(link)
		end
	end
	
	local is_present=del(entities, e)
	
	if e.parent then
		is_present=is_present or del(e.parent.all_ntts, e) and in_tbl(e.parent, entities)
	end

	if not noeffect then
		if e.enemy then 
			lvl_e_clear+=1
			local txt="\^oc09"..lvl_e_clear.."/"..lvl_enms
			if (lvl_e_clear >= lvl_enms)txt="\^oc09area clear!"
			fade_text(player.pos.x,player.pos.y,txt,50)
			
		end
		
		function c_r(v,t)
			y_u_l=-220
			prev_cam_speed.y-=v
			if (t>0) delay_timer(delay_timers, 1, c_r, {v+0.05,t-1})
		end
		
		if e.boss then
			music(-1, 5000)
			delay_timer(delay_timers, 50, c_r, {0,90})
			delay_timer(delay_timers, 115, lvl_transition)
		end
		if is_present then
			if (e.smoke) particles(e.pos,split(e.smoke),e.vel)
			if (e.break_func) e.break_func(e)
		end
		
	end
	
	return is_present
end

function make_link(e1,e2,link_props)

	local link=mod_tabl2(
	{},"from,to,l_type,len,to_ground,strenght,draw_type,col,is_front,width",
	{e1,e2,unpack(link_props)})
	link.true_len=link.len
	
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
	mod_tabl2(_ENV,"b_img_indx,b_pal,b_sc,b_prlx,b_ofx,b_ofy,b_wx,b_wy,b_timx,b_timy",{unpack(lvl_arr(2),offset+14)})
	
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

function draw_lvl_borders()
	
	--local rcol = 7
	--if (lvl_extrainfo(2) <= -1) rcol = 12
	
	local function l(o_x)
		line(l_border_x-o_x,0,l_border_x-o_x,l_border_y,12)
	end
	
	l(0)
	l(1)
	l(flr(time()*9)%9)
	
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
	if (entity.m_sprite) draw_m_sprite(entity.pos,entity.m_sprite,entity.spr_size,entity.is_left)
end

function draw_m_sprite(pos,m_spr,spr_size,flip_x,flip_y)
	local e_spr,s_x,s_y,a_t,a_n = unpack(m_spr)
	spr_size = spr_size or 8
	if e_spr >= 0 then
		local spr_sw,spr_sh = s_x*spr_size, s_y*spr_size
		e_spr += ((anim_c\a_t)%a_n)*s_x
		sspr(e_spr%16*8,e_spr\16*8,s_x*8,s_y*8,pos.x-spr_sw/2,pos.y-spr_sh/2,spr_sw,spr_sh,flip_x,flip_y)
	end
end

function d_e(enm)
	
	local enm_col,g_t=3, enm.timers.gun
	if (timer_active(enm,"hitshock")) enm_col=7
	
	if enm.active then
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
		envstr.draw_joint(p1, p2, len/2, col, fasle,width)
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

p_expr = "0000002800000000"
function draw_humanoid(ntt)

	--head
	local head_sprite_pos=ntt.pos+ntt.facing*2
	
	local flip_r,flip_u=ntt.is_left,false
	if ntt.facing.y > 0.7 then
		flip_u,flip_r = true,not flip_r
	end
	

	if (flip_r == false) head_sprite_pos.x += 1
	draw_m_sprite(head_sprite_pos, ntt.m_sprite, 8, flip_r,flip_u)
	
	local e_pos_x,e_pos_y = head_sprite_pos.x-4, head_sprite_pos.y-4
	if (flip_r == true) e_pos_x-=1
	--eyes
	
	if timer_active(ntt, "hitshock") then 
		p_expr = "0000442844000000"
	elseif vec2_len(ntt.vel) > 4 then
		p_expr = "0000002828000000"
	elseif btn(3) then
		e_pos_y += 1
	end


	if (anim_c%(55) > 3) then
		print("\f7\^:"..p_expr, e_pos_x,e_pos_y)
		--spr(161+spr_i, head_sprite_pos.x-4, e_pos_y,1,1,flip_r,flip_u)
	end
	p_expr = "0000002800000000"
	
end

function draw_ui()
	camera(0,0)

	local function ui_line(x1,xlen,y,col1)
		line(x1,y,x1+xlen,y,col1)
	end

	for i=1, 5 do
		ui_line(3,82,i,8)
	end
	
	for i=2, 4 do
		ui_line(4+player.stmn,player.timers.hurt/4,i,7)
		fillp(0b1110110110110111.1)
		ui_line(4,player.stmn,i,12)
		fillp(0)
		ui_line(4,player.stmn_l_b,i,12)
	end

	camera(camera_x,camera_y)
end

-->8
-- sounds

layers_active = 0b0
function update_mus()

	for i=0, 63 do
		--0x3100 is start, 0x3101 means target 2nd channel
		for j=0,3 do
		
			local addr = (0x3100+j + i*4)
			local fl = @addr
			if bcheck(layers_active, 1<<j) then
				fl &= 0b10111111
			else
				fl |= 0b01000000
			end
			
			poke(addr,fl)	
		end

	end
end

mus_enabled=true
function set_mus()
	mus_enabled=not mus_enabled
	
	music(-1)
	local s="music:off"
	if mus_enabled then
		music(lvl_mus)
		s="music:on"
	end
		menuitem(5,s,set_mus)
	return true
end

function sp_sfx(sf, src_pos)
	if (vec2_len(src_pos - player.pos) < 180) sfx2(sf)
end

function sfx2(sf)
	if sf > 0 then
		sfx(sf)
	elseif sf < 0 then
		print(ex_sfx[-sf])
	end
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

function projection(a,b) -- if b is 0,
	local k = vec2_dot(a,b)/vec2_dot(b,b) -- 0/0 is is max num
	return vec2_new(k*b.x,k*b.y) -- but then this is 0,0
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
-- if s is 0 v1 is 0 and v2=v
function recomp_mul(v,s,m1,m2)
	local vc = projection(v,s)
	return vc*m1+(v-vc)*m2, vc*m1, (v-vc)*m2
end

-- used in collisions and link pulling/pushing
function transfer_momentum(e1, e2, bnc, slipperiness, square_coll) -- b is from 0 to 1
	-- magnitude of diff should not matter -- BUT IT DOES -- when offscreen with high diff it freaks out
	local diff = vec2_normalized(e2.pos-e1.pos)

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
	--extend terrain offscreen
	p_in.x = mid(0,p_in.x,l_border_x)
	p_in.y = mid(0,p_in.y,l_border_y)
	
	local point_max,point_min = p_in+vec2_new(rds,rds),p_in-vec2_new(rds,rds)
	
 	-- go over all tiles in rectangle range
	for j=point_min.y\8,point_max.y\8 do
		for i=point_min.x\8,point_max.x\8 do

			if fget(mget(i,j),0) then -- solid tile
 				-- test coll
				local p2 = vec2_new(i*8+4,j*8+4)
 			if (sq_sq_coll(p_in, rds, p2, 4)) return true, p2
 		end
			
		end
	end
	
	return false
end

function check_coll_ntts(ntt, pos, rds)

	-- ultra slow with lots of primary entities - limit is about 15
	-- only ntt can be a second-tier entity
	for other in all(entities) do
		if not (other.ignore_physics or in_tbl(other, {ntt,ntt.parent,ntt.grabbed_e}) or (ntt.parent and other.ignore_seconds) or ntt == other.grabbed_e or (ntt.parent and other == ntt.parent.grabbed_e)) then
			local did, normal, dist = sq_sq_coll(pos or ntt.pos, rds or ntt.rds, other.pos, other.rds)
			
			if (did) return true, other, normal, dist
		end
	end
	return false, nil	
end


function tile_to_entity(tmp_ntt)
	--printh("converted a tile to entity")
	local tpx,tpy,t_dat = tmp_ntt.pos.x\8, tmp_ntt.pos.y\8, tmp_ntt.tile
	


	-- stmn is 38.4 or 96
	mod_tabl2(tmp_ntt,"e_type,stmn,rds",{"tile",tmp_ntt.mass*16,3.5})
	
	tmp_ntt.stmn_l_t = tmp_ntt.stmn
	tmp_ntt.m_sprite[1]=t_dat
	tmp_ntt.mass/=6 -- 0.4 or 1, depending on tile


	-- fill bg: insert adjacent < or ^ bg tile
	local t_l,t_u,t_set = mget(tpx-1, tpy),mget(tpx, tpy-1), 0
	if (fget(t_u,3)) t_set = t_u
	if (fget(t_l,3)) t_set = t_l
	mset(tpx, tpy, t_set)


	add(entities, tmp_ntt)
	return tmp_ntt
end


function entity_to_tile(e)
 --printh("converted an entity to tile")
	mset(e.pos.x\8, e.pos.y\8, e.m_sprite[1])
	remove_entity(e,true)
end


-->8
-- movement
-- NO TERRAIN CLIPPING 
function unclip(entity,pos,rds, up_override)
	local pos_t, rds_t = pos or entity.pos, rds or entity.rds
	local is_exit,exit_v = false
	
	-- first test terrain
	local coll_t, t_pos = sq_trn_coll(pos_t, rds_t)
	if coll_t then
		for i=1, 6 do
			for j=0, 7 do 
				local s_v = vec2_up*8
				if (j > 3) s_v.x=8
				local m_v = vec2_rotate(s_v,j/4)*(i+entity.coll_rng)
				
					
				-- ok to snap to grid
				function snap(v,p)
				
					if v != 0 then
					
						local rd=rds_t
						if (v > 0) rd=-rds_t

						v=(v+p+rd)\8*8-p-rd -- snap to block's lower edge
		
						if (v < 0) v +=8 -- reverse edge if outclipping to minus
					end
					
					return v
				end
				
				m_v.x,m_v.y = snap(m_v.x, pos_t.x), snap(m_v.y, pos_t.y)

				if not sq_trn_coll(pos_t + m_v, rds_t) then

					-- keep shorter one
					if (not is_exit or (not up_override and vec2_len(m_v) < vec2_len(exit_v))) exit_v = m_v
					is_exit=true
				end
				
			end
			
			if is_exit then			

				
				return true, true, true, exit_v, get_tmp_trn_e(t_pos) -- out now - ignore entities
			end
		end
		return true, true, false, vec2_zero, get_tmp_trn_e(t_pos)
	end
	
	-- then entities
	local coll_e, e, norm, dist = check_coll_ntts(entity, pos_t, rds_t)
	
	if coll_e --[[and anim_c%2==0]] then
		local m_v = norm*dist
		if (not sq_trn_coll(pos_t + m_v, rds_t) and not check_coll_ntts(entity, pos_t + m_v, rds_t)) return true, false, true, m_v, e
		return true, false, false, m_v, e
	end
	return false
end


function update_stand(entity)
	
	-- clear standing
	entity.is_stnd=false
	local down_pos = entity.pos+vec2_down
	
	-- first check terrain below
	if sq_trn_coll(down_pos, entity.rds) then
		entity.is_stnd=true
		return
	end
	
	-- then entity
	if check_coll_ntts(entity, down_pos) then
		entity.is_stnd=true
	end
	-- legs give special stand property
end

function explode_self(e)
	explosion(e.pos, explosions[e.explosion])
end

-- radius, str, sfx
function explosion(pos, e_props)
	local radius, str, sf = unstr(e_props)


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
				if (vec2_len(t_pos-pos) < radius) impact(get_expl_ntt(tmp_ntt.pos), true, tmp_ntt.pos-pos, tmp_ntt, true, true, rnd(3)>2)
			end
		end
	end

	particles(pos, {7, radius/2, sf, -radius/3, 3})
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
	sp_sfx(sf,pos)
	for i=1, 5 do
		particle_delay(v2c(pos),vec2_new(rnd(2)-1,rnd(2)-1) + (vel or vec2_zero),rd, co, dc or 0.3, ti or 11)
	end
end


function lose_stmn(ntt, dmg)
	local envstr, _ENV = _ENV,ntt

	if stmn then
		local p_s=stmn
		
		if (stmn_l_b) dmg*=2
		
		stmn-=dmg
		
		if stmn_l_b and stmn < stmn_l_b then
			local dmg2 = stmn_l_b-stmn
			dmg2/=2
			stmn_l_b -= dmg2
			stmn = stmn_l_b
		end

		local total_dmg = p_s - stmn
		timers.hurt=total_dmg*4

		timers.hitshock = 12
			
		if e_type=="enm" and stmn > 0 and total_dmg > 1 then
			envstr.fade_text(pos.x,pos.y,"\^o05a"..(stmn/stmn_l_t*100)\1 .."%",18)
		end
				
	end

end

function get_tmp_trn_e(pos)
	local px,py=pos.x\8,pos.y\8
	local ntt=spawn_entity(px*8+4,py*8+4,15)
	ntt.tile = mget(px, py)
	if (fget(ntt.tile,1)) ntt.mass = 2.4
	return ntt
end

function impact(entity, with_t, surface_dir, coll_e, no_sfx, no_sq_coll, no_convert)
	
	local prev_v1,prev_v2 = v2c(entity.vel), v2c(coll_e.vel)
	
	local function get_nrg(v1,v2)
		return vec2_len(v1)^2*entity.mass + vec2_len(v2)^2*coll_e.mass
	end
	
	local slp,bnc = max(entity.slip, coll_e.slip), max(entity.bounce, coll_e.bounce)

	transfer_momentum(entity, coll_e, bnc, slp, not no_sq_coll)

	local impact=get_nrg(prev_v1,prev_v2)-get_nrg(entity.vel,coll_e.vel)
	local impact_1,impact_2=split_vector(impact, entity.mass, coll_e.mass)
	
	
	-- if broke terrain turn tmp tile to entity tile
	if with_t and vec2_len(coll_e.vel) > 0.5 then
		
		if not no_convert then
			coll_e.tile = 14 + rnd(2)\1
			coll_e.mass=2.4
		end
		coll_e = tile_to_entity(coll_e)
		coll_e.vel *= 4
	end
	
	-- old bounce

	
	function coll_p(e,p,i,o)
		local cdmg = o.contact_dmg
		if e.enemy and o.e_type=="tile" then
			cdmg = 7
			lose_stmn(o, 15)
		end
		if (e.e_type=="tile") cdmg=nil
		
		if cdmg then
			lose_stmn(e, cdmg)
			if (e==player) sfx2(-1)
			local cnt_vel=vec2_normalized(e.pos-o.pos + o.vel)*(o.kb or 0)
			counter_mmnt(cnt_vel,e,o)
		end
		
		if e.coll_func then
			e.coll_func(e, p, i, o)
		end
		if i >= (e.i_armor or 0) then
			lose_stmn(e, i*4/(e.i_resist or 1))
		end
	end
	
	coll_p(entity,prev_v1,impact_1,coll_e)
	coll_p(coll_e,prev_v2,impact_2,entity)
	

	local sf = 14
	if impact > 11 then
		sf=15
	end
	
	if impact > 2.5 and not no_sfx then
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
	
	if ntt.pos.y > l_border_y+32 and not ntt.parent then
		remove_entity(ntt)
	end
	
end


function move_entity(entity)

	-- apply movement
	entity.pos += entity.vel
	
	-- clip out
	local did_c,with_t,out,surface_dir,coll_e = unclip(entity)
	if did_c and out then
		entity.pos += surface_dir
	end
	
	
	if did_c then
	
		if out then
			impact(entity, with_t, surface_dir, coll_e)
			entity.coll_rng=0
		else
			if with_t then
				entity.coll_rng += 6
			else
				entity.pos += vec2_normalized(entity.pos - coll_e.pos)
			end
		end
	else
		entity.coll_rng=0
	end
	
	update_stand(entity)
	
	--fall
	if not entity.special_stand then
	
		if entity.is_stnd then
			entity.vel.y *= 0.95
			entity.vel.x *= 0.6 + max(entity.slip or 0, trn_slp)*0.4 --ground/ntt friction
		else
			entity.vel.y += entity.grav
		end
	end
	--entity.vel *= 0.999 --air friction
	
end

-- called when an entity is outside its link range
function tug(link)

	local e1,e2 = link.from, link.to
	local e2_pos = e2.pos
	if (link.to_ground) e2_pos = e2
	
	local diff = e2_pos - e1.pos
	
	local move_dist = vec2_len(diff) - link.len

	
	-- the amount that the entities need to move so they stay in proper link range
	local move_need = vec2_normalized(diff) * move_dist
	
	
	local do_move = false
	
	-- check if tugging is needed
	-- small tolerance (0.6) so it isn't constantly active
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
			local move_1,move_2 = split_vector(move_need, e1.mass, e2.mass) -- == move_need/(e2m/e1m)
			
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

-- basically a raycast with spotlight angling
function ray_coll(pos,vec,angle_range,entity,sticky)
	for t_vec in all({vec*0.1,vec*0.4,vec*0.6,vec*0.8,vec,vec2_rotate(vec,angle_range),vec2_rotate(vec,-angle_range)}) do
		local t_pos = pos + t_vec
		local coll_land,with_t,out,away_vector,other_ntt = unclip(entity, t_pos,nil, true)
		if (coll_land and out) return true, t_vec, with_t, away_vector, other_ntt, false
		
		if in_tbl(mget(t_pos.x\8, t_pos.y\8), split"44,45") and sticky then
			return true, t_vec, true, v2c(vec2_up), get_tmp_trn_e(t_pos), true
		end
		
	end
	
	return false
end



function move_towards(ntt, target_pos, speed)
	ntt.pos+=vec2_limit((target_pos-ntt.pos)/speed)*speed
end

function move_humanoid(entity)
	local envstr,_ENV=_ENV,entity

	for arm in envstr.all(m_l_arms) do
		arm.special_stand=false
	end

	-- leg move parameters
	
 -- preferred offset from center, in pico8 degrees
	-- offset tolerance	

	-- defaults - no leg support	
	local prev_jump=jump_g
	envstr.mod_tabl(entity, "special_stand,grounded_mode,jump_g/false,false,false")

	-- update targets
	
			-- where is landing point
	local leg_range=leg_len
	local stand_vec,max_dist,max_leg,max_stand_center = envstr.vec2_normalized(entity.leg_facing)*leg_range*1.25, stnd_height/2
	
	-- move target with highest distance to optimal target position (if outside tolerant distance)
	local st_pos,st_away,st_c = envstr.vec2_zero*1,envstr.vec2_zero*1,0
	
	for leg in envstr.all(m_l_legs) do
		stand_vec_l = envstr.vec2_rotate(stand_vec,leg.angle * envstr.tonum_flip(is_left))
		if (prev_jump)stand_vec_l.x+=vel.x*leg_range
		local stand_center = pos + stand_vec_l*0.9
		local dist = envstr.vec2_len(leg.t_pos - stand_center)

		if (dist > leg_range or envstr.anim_c%20==#m_l_legs) leg.t_active = false
		--leg.t_active = false
		
		if envstr.timer_ready(entity,"jump_cooldown") then
		
			if not leg.t_active then

				local did, t_vec, with_t, away_vector, other_ntt, ladder = envstr.ray_coll(pos, stand_vec_l,leg_angle_range, leg,sticky)
				
				
				if did then
					stand_center = pos + t_vec + away_vector
					
					if (sticky) away_vector = envstr.v2c(envstr.vec2_up)		
					leg.surface_away=envstr.vec2_normalized(away_vector)
					ground_entity=other_ntt
					
					dist = envstr.vec2_len(leg.t_pos - stand_center)
					if dist > max_dist then
						max_dist,max_leg,max_stand_center,max_ladder = dist,leg,stand_center,ladder
					end
					if dist <= leg_range*1.5 then
						leg.t_active = true
					end
					
				end
			
			end
			
			-- try to stand
			-- move legs to targets
			if leg.t_active then
				grounded_mode=true
				envstr.move_towards(leg,leg.t_pos, leg_speed)
				
				st_pos+=leg.t_pos+leg.surface_away*stnd_height
				st_away+=leg.surface_away
				st_c+=1
				if envstr.vec2_len(vel) < 5 then
					jump_g = true
					if sticky then 
						leg.vel*=0.75
					end
					if (leg.surface_away.y<0 and leg.is_stnd or sticky) special_stand = true
					
				end
			end
		end -- of jump cooldown check
		
	end
	
	-- only if not on cooldown and if outside tolerance range
	if m_l_legs.cd <= 0 then		
		if max_leg then
			max_leg.t_pos = max_stand_center
			max_leg.t_active = true
			m_l_legs.cd = leg_cooldown	
		end
	else 
		m_l_legs.cd -= 1
	end
		
	if (st_away.y < -0.5) st_away.x = 0
	surface_away=envstr.vec2_normalized(st_away)

	
	if special_stand then -- really is standing (or about to hit ground)
		
		--custom friction
		vel *= 0.85
		vel.y*=0.9
		
		-- stabilise pos
		local stand_p_lh = st_pos/st_c
		
		if crouch or envstr.sq_trn_coll(pos+envstr.vec2_up*5, 0.5) then
			stand_p_lh -= surface_away * 6
		else
			stand_p_lh += surface_away * (envstr.anim_c\48%2)
		end
		
		if not sticky then
			pos.y = pos.y*0.85 + stand_p_lh.y*0.15
			
			local function stabl_arm(arm)
				if envstr.vec2_len(arm.vel) < 0.15 and not armgrab then

					arm.special_stand=true

				end
			end
			
			for arm in envstr.all(m_l_arms) do
				arm.vel*=0.95
				stabl_arm(arm)
			end
			
		end
			
	end -- of leg stand check
	
end



function update_right(ntt)
	if ntt.input_dir.x != 0 then
		ntt.is_left = ntt.input_dir.x < 0
	end
	if (ntt.shoot_dir) ntt.is_left = ntt.shoot_dir.x < 0
end


function ungrab(ntt)
	ntt.grabbed_e = nil
	ntt.in_grab = false
end

function move_control(ntt, b4, b5)

	local surface_normal,input_dir_l,jump_cooldown = ntt.surface_away, vec2_limit(ntt.input_dir or v2c(vec2_zero)), ntt.timers.jump_cooldown
	local input_dir_h = vec2_normalized(input_dir_l + vec2_right*(tonum_flip(not ntt.is_left))*0.05)
	local hold_pos = ntt.pos + input_dir_h*ntt.arm_len
	
		
	-- grabbing -----------------------------------
	
	local jump_s = false
	
	if #ntt.m_l_arms > 0 then
		local arm_1 = ntt.m_l_arms[1]
			
		-- check if grab is still valid
		if ntt.in_grab and get_first_link(arm_1,ntt.grabbed_e) == nil then
			ungrab(ntt)
		end
		
		
		local ultragrab = bcheck(ntt.items,0b1)
		local throw_str = 2 + tonum(ultragrab)
		if (ntt.in_grab and input_dir_l.y <= 0) hold_pos = ntt.pos + vec2_up*ntt.arm_len*1.75
		local hp_clip,hp_with_t,hp_out,hp_dir,hp_coll_e = unclip(ntt,hold_pos)
		local hp_2 = hold_pos+(hp_dir or vec2_zero)
		
		for arm in all(ntt.m_l_arms) do
			--arm.t_active = false
			arm.mass = 0.1	
		end
		
		
		
		local function align_arms()
			for arm in all(ntt.m_l_arms) do
			
				-- move arm	
				local chosen_t = hp_2
				if hp_clip then
					arm.vel *= trn_slp*0.5
				end

				-- slowdown if grabbing terrain or scaffolding
				if jump_cooldown <= 2 then
				
					if ntt.on_ladder or ntt.on_wall then
						chosen_t = ntt.ladder_pos

						jump_s,arm.mass = true,1.1
						arm.vel*=0.2
					end
					
					counter_mmnt((chosen_t-arm.pos)/64,arm,ntt)
					move_towards(arm,chosen_t, 1.5)
				end
				
			end -- of for
		end
		

		if (b5 or ntt.on_ladder or ntt.on_wall) align_arms()

		if b5 then
			ntt.armgrab = true

			if not ntt.on_ladder and jump_cooldown <= 4 then
				local hx,hy=hold_pos.x\8, hold_pos.y\8
				local t = mget(hx,hy)
				ntt.on_ladder = t==44 or t==45
				if ntt.on_ladder then
					ntt.ladder_pos = hold_pos
					mset(hx,hy,45)
					sfx(23)
				elseif hp_dir and hp_dir.y < 0 and not ntt.special_stand and hp_2.y < ntt.pos.y then
					ntt.on_wall = true
					ntt.ladder_pos = hp_2
				end
				
			end

			-- try to grab
			if not ntt.in_grab and not ntt.grab_c then

				if hp_clip then
					if hp_coll_e.mass < 5 and hp_coll_e.rds < 10 or ultragrab then
						ntt.in_grab = true
						if hp_with_t then
							hp_coll_e = tile_to_entity(hp_coll_e)
						end
					end
				end
				
				if ntt.in_grab then -- take the thing
					sfx(21)
					ntt.grabbed_e = hp_coll_e
										
					make_link(arm_1,hp_coll_e,split"1,0.1,false,20,0,14,false,0")
				end
			end
			
			if ntt.in_grab then

				--rotate grabbed object's fire
				ntt.grabbed_e.shoot_dir=input_dir_h
			end
		-- end of grab


		else
			--throw if holding, else nothing
		
			if ntt.in_grab then
			
				--if vec2_len(input_dir_l) <= 0 then
				--	sfx(21)
				--else
				sfx(22)
				counter_mmnt(vec2_normalized(input_dir_h + vec2_up*0.1) * throw_str, ntt.grabbed_e, ntt)
				--end
				
				ntt.grabbed_e.timers.stun=10
				ntt.in_grab,ntt.grab_c = false,true
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


	local accel,vel_limit =  ntt.a_acc, ntt.a_max -- air drift
	
	if ntt.grounded_mode and ntt.surface_away.y != 0 then
		accel,vel_limit = ntt.g_acc,ntt.g_max -- ground movement
	end
	if ntt.grounded_mode or b5 or ntt.on_ladder then
		update_right(ntt)
	end
	


	local pv_add = input_dir_l*accel
	
	if (input_dir_l.x == 0 and ntt.special_stand) ntt.vel.x *= 0.5
	
	if (not (ntt.flying or ntt.on_ladder or (ntt.special_stand and ntt.sticky))) pv_add.y = 0
	
	if vec2_len(ntt.vel + pv_add) <= vec2_len(ntt.vel) or vec2_len(ntt.vel) <= vel_limit then
		ntt.vel += pv_add
	end
	
	
	-- jumping -----------------------------------

	local g_e = ntt.ground_entity
	local g_is_ntt
	if (g_e) g_is_ntt = g_e.e_type != "tmp tile"
		
	-- jump away from surface
	local input_dir_j = vec2_normalized(input_dir_l + vec2_up*0.3)
	
	--input_dir_j.y*=1.5
	
	
	-- alignment direction
 local align_down,al_of=-vec2_up,ntt.vel*0.5
	local direct_mul,side_mul=0.3,0.74
	
	if b4 and jump_cooldown <= 0 then
	
		local jump_str,leg_pos,p_prevvel,j_sf		= ntt.jump_str,ntt.m_l_legs[1].pos,v2c(ntt.vel), 10
		local tx,ty = leg_pos.x\8,leg_pos.y\8
		local on_magnet = in_tbl(mget(tx,ty), {44,45})
		
		if jump_s then
			--input_dir_j=input_dir_u
			
			if ntt.on_ladder then
				mset(ntt.ladder_pos.x\8,ntt.ladder_pos.y\8,44)
			end
			ntt.on_ladder,ntt.on_wall=false,false
			
		elseif ntt.jump_g 
		-- no jump clutches 
		and (vec2_len(projection(ntt.vel,surface_normal)) < 3 or g_is_ntt or vec2_dot(ntt.vel, input_dir_j) >= 0)

		then
			input_dir_j = input_dir_j*0.7 + vec2_up*0.39 + surface_normal

			-- try to stabilise jump
			if vec2_dot(ntt.vel, input_dir_j) < -1 then
				jump_str *= 1.2
			end
			

		elseif on_magnet then
			mset(tx,ty,45)
			-- may still need some tweaking
			input_dir_j+=vec2_up*0.2
			input_dir_j.y*=3
			side_mul=0.72
			delay_timer(delay_timers,4,function() mset(tx,ty,44) end)
			particles(leg_pos,split"3,2.6,0,0.4,8",p_prevvel)
			j_sf=13
		else
			jump_str=0
		end

		if jump_str > 0 then
			local jump_vel = vec2_normalized(input_dir_j)*jump_str
			
			-- jump start

			ntt.timers.jump_cooldown=8
			
			-- drop kick
			if ntt.grounded_mode and g_is_ntt then
				lose_stmn(g_e, 12)
				impact({pos=ntt.pos, vel=p_prevvel-jump_vel, mass=ntt.mass}, not g_is_ntt, jump_vel, g_e)	
				j_sf=12
				if bcheck(ntt.items,0b10) then
					explosion(leg_pos, explosions[2])
					j_sf=17
				end
				
				align_down+=jump_vel*10
			end
			
			sfx2(j_sf)
			
			update_right(ntt)
			
			
			for leg in all(ntt.m_l_legs) do
				if leg.t_active then
					particles(leg.t_pos,split"7,1.6,0,0.5,6", input_dir_j)
					break
				end
			end
			
			for ntt in all(ntt.all_ntts) do
				-- add less if already going fast
				ntt.vel = recomp_mul(ntt.vel, surface_normal, direct_mul, side_mul)
				
				ntt.vel+=jump_vel
			end
			
		end
	end
	

	if ntt.grounded_mode or ntt.on_ladder then
		align_down.x-=al_of.x
	else 
			if b5 then
				align_down-=input_dir_l*2.5
			elseif timer_ready(ntt, "jump_cooldown") then
				align_down+=al_of+vec2_up*0.5
			else
				align_down-=al_of*0.5
			end
			
	end
	
	ntt.leg_facing = ntt.leg_facing*0.8 + align_down*0.2
	
	-- only used for head drawing
	ntt.facing = -vec2_limit(ntt.leg_facing)
	
end


function update_player(player)
	move_humanoid(player)
	-- regen stamina
	if (player.stmn < player.stmn_l_t and player.timers.hurt <= 2) player.stmn += 0x0.5

	-- controls
	local input_dir =	vec2_left  * tonum(btn(0))
																	+ vec2_right * tonum(btn(1))
																	+ vec2_up    * tonum(btn(2))
																	+ vec2_down  * tonum(btn(3))
	
	mod_tabl2(player,"input_dir,crouch,armgrab",{input_dir,btn(3) and player.special_stand,false})
	
	move_control(player, btn(4), btn(5))

	
	-- rotation -----------------------------------

	local i=1
	for leg in all(player.m_l_legs) do
		
		local l_link = get_first_link(player,leg)
		local l_l_len = l_link.true_len
	
		if not player.grounded_mode then
		
			--if (player.is_stnd and vec2_len(input_dir) == 0) align_vec *= 0
			
			move_towards(leg, player.pos + vec2_limit(player.leg_facing)*player.leg_len, 3/i)
			
			l_l_len *= 0.9
			if (timer_active(player,"jump_cooldown"))	l_l_len /= i

		end
		
		l_link.len = l_l_len
		
		i+=1
	end
 
end



-->8
-- level managment

function lvl_arr(index)
	return split(lvls_info[loaded_lvl_index][index],"|") or {}
end

function lvl_extrainfo(index)
	return lvl_arr(1)[index]
end

function lvl_maininfo(index)
	return lvl_arr(2)[index]
end


function unpack_pal(n)
	return {unpack(palettes, n*16+1, n*16+16)}
end

function load_lvl(index)
	loaded_lvl_index,lvl_hiscore = index,dget(m_index)
	camera_x,camera_y = lvl_extrainfo(5),lvl_extrainfo(6)
	

	-- set size and map position
	map_pos_x,map_pos_y,ld_l_size_x,ld_l_size_y,lvl_mus,layers_active = unpack(lvl_arr(2))

	ll_tiles={}
	for j=0, ld_l_size_y-1 do
		for i=0, ld_l_size_x-1 do
		 add(ll_tiles, mget0x20(map_pos_x+i,map_pos_y+j))
		end
	end

	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1
	
	
	-- clear map
	memset(0x8000, 0, 0x4000)
	for t_c=0, #ll_tiles-1 do
		draw_tile(ll_tiles[t_c+1], t_c%ld_l_size_x, t_c\ld_l_size_x)
	end
	
	lvl_pal = unpack_pal(lvl_maininfo(12))

	pal(lvl_pal, 1)
end


function tile_spr(s, alt_t, alt_l)
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
		if (rnd(10) > 9) s1 ^^= 0b1
	end
	
	-- alt texture
	if (alt_t and not fget(s1,7)) s1+=0b01000000
	
	return s1
end

function draw_tile(t,x,y)
	
	local extra_t,t2 = t&0b11000000, t&0b00111111
	
	for j=0,3 do
		for i=0,3 do
			local m_x,m_y = x*4+i, y*4+j
			srand(m_x + m_y*ld_l_size_x)
			mset(m_x,m_y, tile_spr(mget0x20((t2%32)*4+i,(t2\32)*4 +4+j), bcheck(extra_t, 0b01000000), bcheck(extra_t, 0b10000000)))
		end
	end
	

end

-->8
-- enemy ai and inits

function init_roped(e)
	make_link(e,e.pos + vec2_new(e.rope_x,e.rope_y), split(ropes[e.rope]))
end

function u_e(enm)
	
	update_right(enm)
	
	if vec2_len(enm.pos - player.pos) < (enm.active_in or 55) then
		enm.active=true
	end
	if vec2_len(enm.pos - player.pos) > (enm.active_out or 110) then
		enm.active=false
	end
	
	mod_tabl2(enm,"input_dir,prevstand,special_stand",{v2c(vec2_zero), enm.special_stand, false})
	if timer_ready(enm, "stun") then
		-- passive ai
		_ENV[enm.ai_p](enm)

		if enm.active then
			if (player.grabbed_e != enm) enm.shoot_dir=player.pos - enm.pos
			-- active ai
			_ENV[enm.ai_a](enm)
			if timer_ready(enm, "gun") then
				fire_gun(enm)
			end
		else
			enm.timers.gun=enm.gun[1]
		end
	end
	
	if (enm.stmn/enm.stmn_l_t < 0.35 and anim_c%12==0) particles(enm.pos, split"6, 2.4,0,0.2,8", vec2_up*0.5)
	
end

function ai_stabilise(enm)
	if enm.prevstand and not enm.active then
		enm.special_stand = true
	else
		move_humanoid(enm)
	end
end

function ai_stabilise_flying(enm)
	enm.vel *= 0.9
	enm.special_stand = true
end

function ai_h_turret(enm)
	local l = get_first_link(enm)
	if l then
		enm.pos = enm.pos*0.9 + (l.to - vec2_new(enm.rope_x,enm.rope_y))*0.1
		ai_stabilise_flying(enm)
	end
	
	if (enm.horizontal) enm.shoot_dir.y=0
	enm.input_dir=enm.shoot_dir
end

function ai_follow(enm)
	local dist = vec2_len(enm.shoot_dir)
	
	if (dist > enm.range_out)	enm.input_dir=v2c(enm.shoot_dir)
	if (dist < enm.range_in)	enm.input_dir=-enm.shoot_dir
	
	move_control(enm,false,false)
end

--cooldown,projectile entity,p speed,fire sfx
function fire_gun(e)
	local cldwn,p_t,spd,sfx,angl,dur,global,b_amount,b_delay,b_angl,nxt = unpack(e.gun)
	sp_sfx(sfx,e.pos)
	local proj = spawn_entity(0,0,p_t,e)
	proj.vel+=vec2_rotate(vec2_normalized(e.shoot_dir),angl)*spd
	if global=="tru" then
		proj.parent=nil
		add(entities, proj)
		proj.pos+=vec2_normalized(proj.vel)*e.rds*1.7
	else
		add(e.all_ntts, proj)
	end
	
	if (dur > -1) delay_timer(delay_timers,dur,remove_entity,{proj})
	
	if b_amount > 1 then
		e.gun[8] -= 1
		e.timers.gun = b_delay
		e.gun[5] += b_angl
	else
		e.gun=split(guns[nxt])
		e.timers.gun=e.gun[1]
	end

end


function update_sign(ntt)
	if sq_sq_coll(ntt.pos, ntt.rds, player.pos, 1) then
		delay_timer(delay_timers_draw, 1, text_box, split(ntt.text_box,":"))
	end
end

-->8
-- data


-- list of levels and all their data except the tiles

--1st array: title info
-- name/m_menu title
-- next lvl (1-indexed, -1 is finish)
-- player spawnpos x & y
-- camera pos in main menu
-- sub title
-- intro text


--2nd: ALL LEVEL PROPS

-- (1)map pos x, (2)map pos y, (3)x size, (4)y size
-- available map pos's:x:full range, y:12-39(inclusive)
-- 1 full stage should have about 600 tiles
-- max level dimensions are 32x28 (cause of extended map limits and sprite sheet, for y you'd have to start at top)
-- (5)mus index

-- (6)active music layers (4 bitfield)
-- (7) unused (up to 10)
-- (9) 
-- (8) 
-- (11)
-- (10)

-- (12)pal index, (13)bg col

-- bg 1:
-- (14)image index
-- (15)pal index

-- (16)scale
-- (17)parallax
-- (18)offset x
-- (19)offset y
-- (20)wrap x
-- (21)wrap y
-- (22)timescroll x
-- (23)timescroll y

-- same for bg 2
--(10 things, 24-33)


--3rd: entity spawns
-- type, xpos, ypos, extrainfo array (, and / separated, same as ntt info)

--(for signs: str,screen,x,y,xlen,ylen,c1,c2)

--4th: signs
-- x,y,text

-- NOTE: try to not have more than 6 legs active at once. More kinda lags

lvls_info = {
{"mission 1|  2| 30|54| 464|0|construction\n site|",
	"0|22|24|4|4|1|0|0|0|0|0|2|1|2|7|3|0x0000.0800|48|-16|1|0|1|0|1|0|4|0x0000.2000|64|2|0|0|0|0",
		"4|520|52|/| 5|625|72|rope_x,rope_y/16,0|16|404|44|text_box/\-e\^h\fadanger!\n\nrogue\nmachinery\nahead ->:false:380:0:44:42:2:1",
		"109|57|\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!|252|74|\f2\^o150\^:00130e3a0a190800|256|82|\f2\^o068\^:84ef565692df9249\|e\^o0d0\^:e058517575edeb91|322|62|\f2\^o0ff🅾️\n\n\|c \-f+\n\n\|c\^:10387c1010100010"
},
{"1-2| 3| 6|76| 0| 0|1: roadblock|",
	"23|21|16|5|8|1|0|0|0|0|0|2|2|2|6|3|0x0000.0800|48|-12|1|0|1|0|1|3|5|0x0000.2800|-72|8|0|0|0|0",
	"5|104|66|/| 4|154|109|/| 4|278|52|rope,rope_x,rope_y/4,-16,0| 5|464|34|rope_x,rope_y/16,0| 7|398|124|/",
	"296|41|\f2\^o0ff❎\|e\n\ng\|fr\|fa\|fb|280|45|\f2\^o0ff\^:00008064320f0204		\|e\^:0000070c90a0c0f0"
},
{"1-3| 4| 6|290| 0| 0|2: magnetizing yourself|",
	"0|12|14|10|8|1|0|0|0|0|0|2|2|2|6|3|0x0000.0800|48|-8|1|0|1|0|1|3|5|0x0000.2800|-170|8|1|0|0|0",
		"16|52|292|text_box/\-e\^h\fae.m. wall\nusage manual\n\n❎-attach\n🅾️-release\n\ndetached jumping\nis not safety\ncompliant!:false:16:222:72:64:2:1| 4|78|154|rope_y/-16| 18|20|72|/| 19|240|51|next_e,rope_x,rope_y/11,-16,8| 4|312|92|rope_x,rope_y/-12,12| 6|423|156|active_in/27"
},
{"1-4| 5| 4|110| 60|80|3: don't look down|",
	"14|12|16|6|8|1|0|0|0|0|0|2|2|1|7|3|0x0000.1000|-102|36|1|0|0|0|0|10|4|0x0000.2000|-40|36|0|0|0|0",
	"5|79|76|rope_y/-16| 7|240|50|range_in/25| 6|428|88|/| 7|380|136|next_e/11",
},
{"1-5| 6| 4|72| 60|80|4: mayhem|",
	"32|12|16|7|8|1|0|0|0|0|0|3|2|0|3|3|0x0000.1000|208|-4|1|0|0|0|0|12|5|0x0000.2000|-140|-16|0|0|0|0",
		"13|108|60|/| 19|146|110|rope_x,rope_y/16,0| 7|212|188|range_in/25| 6|302|148|next_e/11| 5|396|132|/| 7|436|80|/| 7|370|44|/| 19|232|40|rope_x,rope_y/-12,-12",
},
{"mission 1| -1| 4|116| 60|80|5: the small issue in question|",
	"48|12|12|6|19|1|0|0|0|0|0|3|2|1|7|5|0x0000.1000|-48|-10|1|0|0|0|0|10|5|0x0000.3000|-242|4|1|0|0|0",
	"11|108|48|/| 8|250|98|boss/true"
},
}


-- levels present in the menu
m_index,start_lvls=0,split"1,2,3,4,6"

-- list of almost all entity types.
-- note that these are sorted by order of appearance/implementation rather than type, reordering everything would be painful
--[[
	1: default box - used as template sometimes
	2: player - high slipperiness allows for easy 2 block climb
	3: UTIL: basic limb for entities
	
	4: ENEMY (lvl1): basic turret
	
	5: ENEMY (lvl1): areaspam turret
	
	6: ENEMY (lvl1): spider bomb "turret"
	7: ENEMY (lvl1): flying drone - easy mode, doesn't retreat
	
	
	8: BOSS (lvl1): big walker tank
	
	9: PROJECTILE (lvl1): small
	10: PROJECTILE (lvl1): small grav bomb
	
	11: ITEM: hp
	12: ITEM: grab
	13: ITEM: nuke
	14: ITEM: hook
	
	15: MISC: tmp tile - 6x the mass to enable proper bounces
	16: MISC: sign - ignores physics, displays a text box on player coll (text is added as extra in level)
	
	17: PROJECTILE (lvl1): small with knockback
	18: ITEM: trinket
	
	19: ENEMY (lvl1): turret with all-dir targeting
]]

-- features: common array{radius, mass, metasprite, init function (name), update function, draw function}
-- & extra properties {key1,key2/val1,val2}
-- inner arrays are split with :

-- metasprite format: sprite index (upper left), x size, y size, anim frame len, anim total frames
-- NOTE: masses lower than 0.1 bug link-related movements
ntt_types = split([[3.5,0.4,176:1:1:3000:1,empty_f,empty_f,empty_f|
1,0.6,160:1:1:3000:1,empty_f,update_player,draw_humanoid|b_type,stmn,stmn_l_b,i_armor,i_resist,slip/2,80,80,6,3.5,0.99
0.5,0.1,-1:1:1:3000:1,empty_f,empty_f,empty_f|slip/0.8
4,0.5,164:1:1:3000:1,i_e,u_e,d_e|b_type,stmn,i_armor,gun,ai_p,ai_a,enemy,smoke,rope,rope_x,rope_y,horizontal/1,30,0.6,1,ai_stabilise,ai_h_turret,true,1,1,0,14,t
4,0.5,166:1:1:3000:1,i_e,u_e,d_e|b_type,stmn,i_armor,gun,ai_p,ai_a,enemy,smoke,rope,rope_x,rope_y,horizontal/1,30,0.6,2,ai_stabilise,ai_h_turret,true,1,2,0,16,t
4,0.8,165:1:1:3000:1,i_e,u_e,d_e|b_type,stmn,i_armor,gun,ai_p,ai_a,enemy,smoke,range_in,range_out/4,50,0.6,4,ai_stabilise,ai_follow,true,1,0,25
6,0.3,180:1:1:2:3,i_e,u_e,d_e|b_type,stmn,i_armor,gun,ai_p,ai_a,enemy,smoke,flying,range_in,range_out/1,30,1.6,1,ai_stabilise_flying,ai_follow,true,1,true,0,35
14,4,170:2:2:3000:1,i_e,u_e,d_e|b_type,stmn,i_armor,gun,ai_p,ai_a,enemy,smoke,range_in,range_out,spr_size,active_in,active_out/5,100,20,6,ai_stabilise,ai_follow,true,5,35,40,16,60,2000
3.25,0.5,167:1:1:3000:1,empty_f,empty_f,draw_entity|contact_dmg,special_stand,smoke,stmn,bounce/6,true,3,0.01,0.8
3.5,0.5,167:1:1:2:2,empty_f,empty_f,draw_entity|contact_dmg,smoke,stmn,ignore_seconds,break_func,explosion/4,3,0.01,true,explode_self,1
2,0.1,176:1:1:3000:1,empty_f,update_item,draw_entity|item,amount,smoke,ignore_seconds/5,15,2,true
3.5,0.1,177:1:1:3000:1,empty_f,update_item,draw_entity|item,smoke,ignore_seconds/1,4,true 
3.5,0.1,178:1:1:3000:1,empty_f,update_item,draw_entity|item,smoke,ignore_seconds/2,4,true 
3.5,0.1,179:1:1:3000:1,empty_f,update_item,draw_entity|item,smoke,ignore_seconds/3,4,true
4,6,14:1:1:3000:1,empty_f,empty_f,draw_entity|e_type,smoke,contact_dmg/tmp tile,1
9,2,244:1:1:3000:1,empty_f,update_sign,draw_entity|early_draw,ignore_physics/t,t
3.5,0.7,167:1:1:3000:1,empty_f,empty_f,draw_entity|contact_dmg,kb,special_stand,smoke,stmn,bounce/7,0.75,true,3,0.01,0.8
3,0.1,232:1:1:5:2,empty_f,update_item,draw_entity|item,smoke,ignore_seconds/4,4,true
4,0.5,166:1:1:3000:1,i_e,u_e,d_e|b_type,stmn,i_armor,gun,ai_p,ai_a,enemy,smoke,rope,rope_x,rope_y/1,30,0.6,9,ai_stabilise,ai_h_turret,true,1,2,0,16]],"\n")

--[[
	"3,0.35,9, 1,1,2","contact_dmg,grav,smoke,stmn,bounce,slip,ignore_seconds/8,0.06,3,7,0.85,0.85,true", -- sawblade

	"4,6,1, 1,1,2","e_type,smoke/tmp tile,1", -- metal orb
]]



-- body info for complex/limbed entities
ntt_b_types = {
-- sticky_walk, g_accel,a_accel,g_max_speed,a_max_speed,jump, leg_len,arm_len,stand h, leg speed,leg g cooldown,max leg target rotation, 
-- limb info starts at 13th array slot
-- limb info list: [11 things - entity type, limb type (a/l arm or leg), angle, link props (link_type, link_len, to_ground, link_strenght, draw_type, col, is_front,width)]
-- some limb stuff is kinda redundant like len but it's used for leg/arm targeting (maybe change?)
"false, 0.15,0.15,4,4,0, 18,1,20, 3,3,0.01", -- box (no limbs), air move ok - basic drone

"false, 0.54,0.15,2.45,1.5,2.688, 8.7,5,7.5, 3,3,0.07,  3,l,0.015, 1,8.7,false,0,3,7,false,0,  3,a,0.02, 1,5,false,0,2,12,false,0,  3,l,-0.015, 1,8.7,false,0,3,7,true,0,  3,a,-0.02, 1,5,false,0,2,12,true,0", -- humanoid

"false, 0,0,0,0,0, 18,1,16, 3,3,0.01,  3,l,-0.05, 1,18,false,0,2,14,false,2", -- standing turret
"true, 0.17,0.05,1.5,1,0, 18,1,12, 4,6,0.2,  3,l,0, 1,18,false,0,2,14,false,2,  3,l,0.3, 1,18,false,0,2,14,false,2,  3,l,0.6, 1,18,false,0,2,14,false,2", -- tripod spider - slow
"false, 0.3,0.05,1.1,1,0, 44,1,40, 4,16,0.15,  3,l,0.04, 1,50,false,0,2,14,false,12, 3,l,0, 1,50,false,-0.04,2,14,false,12", -- big walker

{}
}


--[[
1:standard
2,3:area burst sequence (x4, x4)
4:bomb
5:sawblade
6,7,8:boss 1 sequence(x3 spread, x3 bomb, x8 area burst)
9:standard burst
]]
-- cooldown,projectile entity,p speed,fire sfx,angle,p lifetime,is global,burst amount,burst delay, burst angle shift,next gun
guns = split([[45,9,3.5,18,0,60,fls,1,1,0,1
55,9,2,18,0,60,fls,4,1,0.25,3
55,9,2,18,0.125,60,fls,4,1,0.25,2
65,10,3,11,0,60,tru,1,1,0,4
60,9,3.5,20,0,60,tru,1,1,0,5
45,17,3,18,-0.03,60,fls,5,7,0.01,7
45,10,4,11,-0.09,60,fls,3,10,0.09,8
75,17,2.25,18,-0.1,40,fls,16,2,0.11,6
60,9,2.5,18,-0.01,60,fls,3,8,0.01,9]],"\n")

-- 1-col, 2-radius, 3-sfx (0 if none), [ 4-decay rate ], [ 5-time ]
	-- standard break, hp pickup,  projectile collide, item pickup, boss explode
smokes=split([[14, 3.5,16 
12,3,8
7, 2.5,0
12,3,8
7,8,-2,-4,7]],"\n")



-- ?
-- standard machine
-- longer machine
-- easy break
-- very long
-- link_type (0-keep at distance, 1-keep close, 2-keep far), link_len, to_ground, link_strenght, draw_type (1-line,2-joint,3-legjoint,4-noflip joint), col, is_front, width
ropes = split([[1,20,true,2,2,14,false,2
1,20,true,1.5,4,14,false,2
1,28,true,1.75,4,14,false,2
1,20,true,0.5,4,14,false,2
1,38,true,2.5,4,14,false,2]],"\n")

-- radius, str, sfx
-- small, player item
explosions = split([[10,5,7
7,4,-1]],"\n")

-- player hurt noises, giga explosion
ex_sfx = split"\as2v2i6g#3<d4x5c4i0x4c4x0c#4g#3g#2x3c#2,\as4v6i0x3f#2<i6x1g#1i3x0f0i6x3<a2x0>a3x3g#3<d#3a#2g#2<c2g2i3x3e1x0i6b1x3i3c#1x0i6g#1<x3i3a#0i6d#1d1i3g#0v1g#0i6c1c1b0i3g0f#0f#0f0e0d#0c#0c0c0"

item_names = split"\^ocffultragrab,\^ocffexplosive kicks,,\^ocfftrinket!"


-- storable in map maybe
palettes = split[[
	1,2,10,   128,132,142,15, 8,9,10,138,    12,9,14,13, 0,
	1,131,10, 2,8,9,10,       3,138,135,143, 12,138,14,13, 0,
	143,15,10,  142,143,0,7, 130,2,136,8,  12,2,13,6, 142,
	143,15,10,  128,130,0,7,   130,136,8,143,   12,136,13,6, 142,
	
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
	141,13,9, 130,141,0,6, 129,130,141,141, 140,130,133,134,  130,
	130,141,4, 128,130,0,13 ,129,129,130,130, 1,129,130,133,  128,
	

	
	
	
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



__gfx__
00000000555555545555555444444444aabbbaadba9999aabbbbbaabaaaabbbbb980089a00000000bbbbbabb8b8b8b8b000000005554555477777e7877787778
00000000555555445444444455555554b99999d89988889abadddddddddddddbbb8008ba000000008b8998b8aaaaaaaa00000000544454447ee78788eee88e88
00000000544444445444444454444444b99dddd899999999adddd9ddddddddaab9b99b9a0000000098b88b89bbbbbbbb00000000544454447ee788787877e888
00000000555555445444444454445454b9ddddd8a8888889add9d9ddddd9ddddb98bb89a00000000009bb900aba88aba00000000444444447e78eee8e8e888ee
00000000544444445444444454454454a9ddddd89999999addd9999dd999d999b98bb89a00000000009bb9008abaaba800000000555455547788eee8778e7788
00000000555555445444444454444454a9ddddd89988889aad999999d9999999b9b99a9a0000000098b88a898a8bb8a8000000005444544478e78ee8ee888ee8
00000000444444445444444454444454adddddd8a9999999ad99999999999998bb8008aa000000008b8998a8aabaabaa00000000544454447eeee8e878eeee88
00000000555444444444444444555554d888888daa999a9aaa99988899999888b980089a00000000aaaaaaaaab8998ba0000000044444444e888888e8ee88888
11111111222222225555555544444444aaa99999999999ab9999999999999999779997ff8444445ababbbbba9b9b9b9b54005554444444445555555559559959
11111111222222225555555544444444ba9999999999999a9d9d999999d999d97f9999f78444454ab8aaaa8a9a9a9a9a54055054555555555444444545999999
11111111222222225555555544444444baaa99999aa9aaabaa9d9d9d99d99dd9ff7999778444444ababaabaabbbbbbbb54550054444444445500005544599555
11111111222222225555555544444444a99a9999999999abdd9ddd999ddaad9df779977f8444444aaaaaaaaa99aaaa9955500054555555550550055044459999
11111111222222225555555544444444baaaaa9999aaaaaaadddddaaaddd9daa779997ff8444444abaaaaaa8888aa88855500054444444440055550044445999
11111111222222225555555544444444ba9999999999a99bbaaaaddddddddddd7f9999f78444444aaabaaba8888aa88854550054555555550005500055444599
11111111222222225555555544444444aaa99aa99999aaabddaddddd9ddddaadff7999778444444aa8aaaa8888aaaa8854055054444444445555555544444459
11111111222222225555555544444444b9999999999999abbaabbbad9dbbbabbf779977f9aaaaaaaaa888a889999999954005554555555554444444445554445
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
00000000eeeeeeee000ee0000000000e03000000eeeeeee600eeee0000000000000000000022220000666600000000000008eee00eeee0000000000e70000000
000000003e6e6ee30eeeeee0000003e00e000000666663e60eeeeee000022000002332000237732006666666000000000eee8ee66eeeeee000000007e0000000
008880003e6666633eeeeee666663e006e66600066663636e8e66ee80023320002377320237777326666666666000000eeeee8866eeeeee800e0007eee000e00
0c8e8000366336e3638eee66366777776e66660063366366ee6336e80237732003733730277777726666666666660000eeee88888eeee8880007e0e99e0ee000
00cee0003e63366386836666366eeeeee3e33e3e36e36666ee6336880237732003733730277777726666666666666600e888668668688888000ee966669ee000
00800000366666e3838666663366e300eeeeeeee3e636666eee6688600233200023773202377773266666666666666660066686336866600000096e666690000
000000003ee6e6e30683666006000e3066666600633666660ee88860000220000023320002377320eee66666666666660000686336860000007e6e663666ee00
0000000063eeee3600866600000000ee666666006666666600886600000000000000000000222200666eeeeeeeeeeeee0000008668000000e7e9666363669eee
00000000cc7c7ccc3b73b77b4444477700eee60000eee60000eee600006066000606660000660660666666666666666600000000000000007ee9666636669eee
00fffc00c7e7ec7cb37377b8444777e70ee666600ee666600ee6666006066660066660666060660066666666666666e300f000000000000000ee666666e6ee00
0f7cccc0c78787e7e3777b8b457efe67366366363e366363e3663663660660066066066066606666666666666666e3e300f6600000999000000096666e690000
0fcccc8077eee877e377777757efe67466666666666666666666666666633660660336660663300666666eeee6e3e3e300f333000087e700000ee966669ee000
0fcccc80e788ee8ee3777777547e66746666666666666666666666660663366666633066600336600666e6666ee3e3000066600000999000000ee0e99e0ee000
0cccc8807eee8e77e3777b8847e76744336666333366663377666677600660660660660666660666006e666666e30000000000000000000000e000eeee000e00
00c88800c7eee7ccb37377b87e747544773663770036630000766700066660606606666000660606000e66666e00000000000000000000000000000ee0000000
00000000cc777ccc3b73b77be7445444077007707000000700000000006606000066606006606600000000000000000000000000000000000000000ee0000000
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
0022222211133311000000001113233200efeee00eef700000eee000000000007fffffff7f7fffff0000000000000000000000000bb000000000000000b80000
022222331333333100222000122222110fffffeeeff777f00eeeee000e0000e0fc7ccccefc7cccce000000000000000000a8000bbbbbb00000000000b8888000
222233333332323322222220222121110efff880ee777fe000888000eeff7feef777ccce77c77cce00000000000bb00000a8800abbb88000000000ba88888800
222333232323222333332222121113220ffcffeef77ccfff0eeeee00eec7cce80e7ccc800e7ccc8000000000000abb0000a8800aaa88800000000baa88888800
233222221232121132223200211132210ffcff88777ccfff08eeee00e8cccc880ecccc800e7ccc8000000000000a880000a8000aaa8800000000baaaa8888880
332121212121211121221300111212110efff880e7ffffe00088800088eeee88008cc800008cc800000a880000aa88000a8800aaaa880000000baaaaa8888888
121211111212111112111220112121110fffff88effffff008eeee0008000080008cc800008cc800000a888008aa80000a8000aaaa88000000baaaaaaa888880
1121111121111111211111221111111100ef88800eeff0000088800000000000000880000008800000aa888000aa00000a0000aaa88000000baaaaaaaa888880
000000000000000000ffff0000eeee00000000227f0ff0ff0007700000070000007000000000070000aa888000a08000008000aa8a8000000aaaaaaaaaa88800
0000000000fffe000f7ffee00eeeeee022222252f0effe0f0777777000777777077777700777777000aa8880000abb00a80000aa080000000aaaaaaaaaa88800
000ff0000f7fee80f7feeee8e3eeeee325a2aa200e77ffe00777777e0777777e077777700f77777700a888000000abbb00000a0a00800bb000aaaaaaaaaa8000
00f7e8000ffeee80ffeeee88ee7eee3e02222220ff7ccfff0ff77eee0fff77ee0fefefe00f77eeee00a888000000aa88000000a0080abb8000aaaaaaaaaa8000
00fee8000feee880ffeeee86eee773e802aa2a20fffccfff0fffeeee0fffffee0efefef00feeeee000a88800000aaa8800000000000aa880000aaaaaaaaa0000
000880000eee8860feeee886eee7ee86022222200effffe00fffeeee0fffffe00fefefe00feeeee00aa88000000aa88000bbb000000aa880000aaaaaaa000000
00000000008886000ee888600ee3e86002aaa252f0effe0f00ffeee00fffffe00efefef00feeeee00a888000000aa88000bbbb00000aa8800000aaaa00000000
0000000000000000008866000083860025222220ff0ff0ff000fe0000000ff000fefef0000ee00000a880000000aa88000abbbb0000aa8800000aa0000000000
__gff__
8808080801010101010001010008838388888888010101018101010108880800080808080101010101010108888801010808080801008101010101010808010800080808000001010000000000000000080808080000010100000000000000000808080800000101000001010000000008080808000001010001000100000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d50000000000000000d3007170007100707173222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd36c4d6d7c6c513c4c70000d3c0c1c2e2d361607270736070632222222222222222eaeb00000000eeef0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d936d6dbdccfdd36d413131313131313c0c1e0d2d0d1d2c362616363616163622222222222222222fafb00ebed00feff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d93613dbdcdfdd361313131313131313d0d1d2e3e11010e366676667676667672222222222222222fdfaeeedfdedebed0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000012020200202020220202020062627274647060766666766000000001b0b1b1b005c00015e0b5e0b0008001ce0e0e0e00202010221212121202020207170717120202020242020202020202414f676767676f615262627262103212025253636363614155b4b5b5b001c001c001c001c1e231e231e011e1e1f373636
000000002020212002020202200320031436363656571617f6f6f6f6000000000008005c005c001c230800080008001c22464722e0e0e00122222222020202026170607002020202242003202020202414f676767676f615393939396262626236f936f936f914158a9a8a8a001c001c001c001c001c001c001c0000131f3637
000000002120202002020202200120013736363626262627f6f6f6f6000000001e081e5c0a0b0a0a0a0b5e0b1e0b1e2322565722e0e0e002cf02cf0203cf02ce6063616000000000242020202020202414f676767676f615606061602627262736d914d925d914151e011e1e5b4b5b5b002300231e231e231e011e1e13131f36
000000004242424202020202202020201637361737363617f9f9f9f9000000000008005c0008001c000823080008001ce0e0e0e0e0e0e002cececfce262626266362616300000000242020202020202414f676767676f615131313133939393936e925e936e93715000000008a9a8a8a001c001c001c001c000000002020201f
e0e0e0e002e0e002011e1e0113131313242425363625242426262726412020200223230200000000aaaaaaaa2b2b2b2b1ee0e0e0e0f0f0e0e0e0e0e0001c001c00000000000000000000000000000000202020202020202076767676000000002627262732323232000000000000000000000000000000002013131300000000
e0e0e0e020e0e0201ce0e01c2020202024242536362524243636363641410303231d213d72723232babababa2b2b2b2b30e0e0e0e0f0f0e0e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf76767676000000001636371760606060000000000000000000000000000000002013131300000000
e0e0e0e020e0e0201ce0e01c2120202024242536362524243636363626262726231d033d42424202e5fb37e5212020211ee0e0e0e0f0f0e01e011e1ee0e0e0e000c3002b303130310000310000000000464705260607040476767676000000002020203d60606160323232323232323200000000000000002013131300000000
e0e0e0e002e0e002011e1e0102cecfcf2424253636252424363636361636363602020202616060602525242503202120001c011c2b2b2b2b00000000e0e0e0e032c3c32b30212030313330313232323276760437040607367676767600000000cf0202ce04040404060726270202cf0200000000000000002013131300000000
0000001c18193e0003033e9c001819001c001c1818bb1819001c1c00009c00000000001c0018199e9e9e1819afaf333315000000000000001c0000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300001d90248c008c033e9d9e181900af00af033e2d233e00afa0aea29d00003000001c002301000000a323a11c34271500ac3aadadacac9b0000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
34001dafa3233e3a0c032baf001819000000af1818ae181933ac1dbbbb2f00003400001aae1819aeaeac1819a11c1a0506001d9e1d001cac000000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1932afa01a1a181819a7038c1e1881bbbbbbae0d3eac1819ac1bac972d8f0000a50000ae9e1819ac00ac1815aeaea0953e001cb09c001cacacadb0180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
192caeaead2d840519150da0bb0219aeaeaeae3505af1819ac9c1c0e2c040000a5adaeaeb018198ca28c18150000a0950435171918979717170f04040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
192f313205a008881915a7b0b485190000000018189e18198809891a09900000a51ba9001616160da20c1616a1a90c141926262626152626262626260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
192020102c2d840a1915061a1aa400000000000000000000000000000000000026262626a70faa9727aaaaaa97a41a140303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1920a017181818881915881d1ea4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1620a0209824360a19150a1c00a4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
171717179024060a19150a1c00a40000000000000000000000001c001c00009203b814000000240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a00001c001c0000181900323130000000000000001c333300001c001c00bb92202338b0b3b0240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2f33002f291c29290419b4278f1600b230b100002b2fb42700001b008f29b4aaaa0406969a9a240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
262626a7041b06170d96952626a7b904262729291695060604a91c3a3a0c99042626923e0000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
36363636158826262626262626262626262604060606060604262626262699143636a7343535340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01100000000000000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c07230013
0113800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
000380003f3043e05338033320032e0622a04226022220711c05118021120010e0600803004010020003eb673ab3734b1730b762ab4626b1620b751ab4516b1510b640a3500a0500a0500a0500a0500a0500a050
0103000018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc3024c3018c301dc30
00108000000000000000000000000000000000000000000022136281462a146221162e1762e1762e1762e1072c1072c1072c1762c1262c1662c1662c1662c1662c1662c1662c1262211622147361473813736127
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
3148002027d151ed1503d140ad150fd151ed1512d150dd1427d151ed150fd140ad150fd151ed150cd1508d1522c1503d1403d1403d1424c1506d141bc1508d1425c150000029c0020d150fd151ed1512d150dd14
317e000003d141ed150dd1503d140ad1503d141ed150dd1503d1403d141bc1503d1403d141bc1503c0003c0003d141ed150dd1503d1420d1503d141ed150dd150000000000000000000000000000000000000000
031000201bc2003c21306001bc2003c210000030600000003864038620386103864038620386103b600396001bc301bc101bc301ec201ec0019c301ac30376001bc203b6001bc203c6001bc203b60022c2021c10
611000000332003320033200f300003000035503355033200332003325033000f30003335033000a3000a3350b3200b3200b3200b320013200132001320013200332003320033200332003325033250332503325
5d1200000f420124200d4200f42014420034100f42016420034100d4250d420034100d420034100e420034100f420124200a4200f42014420034100f42016420014100d4250d420014100d420014100e42003410
511200200f3230000033610000000f3230000033610000000f31303210276100f2100f3130000033610000000f3130000033610000000f3230000033610072200f3230322033610336150f333000003361000000
9b1200001b6251b625376200c6210c62137620376103762013615376252d6202d610376353763537635376351b6251b625376200c6210c62137620376103762013615376252d6202d61037635376353763537635
09120020031200311503120031150f1200f1150312503110031100d1200d1100d11012120121100f1200f110031200311503120031150f1200f1150312503120031120d1220d1220d11212132121120f1200f120
0d12002006020030100f0200f0110f0010f0100f0010f010030100d0420d0320d02212030120210f0300f02103010030100f0200f0010f0150f0100f0010f020030120d0420d0320d02212032120220f0300f011
0d1200000d0200d01101020010100f0100f0100101501020000100c0420c0320c03012030120200f0300f02001020010100102001020120200f0200102012020010200f020010230102016020150241502514020
521200202e6250f5252e6151b0153d635270252e6252e615000003d6253d6050a6152e615270253d6253d6353a6203a6153a6103a6153d625186152e6152e615123233d635120351b0253d6353a6151b0253d625
011200201b5250f0151b5260f1000f5261b1250f1001b5160f5001b1250f5001b125191200f5001a1200f5200f5001b1250f5061b5260f5161b1250f0001b1250f5261b1250f5261b1251e1200f5161b1201b125
011200201b1151b1101b0000d1250d1101b1120d0250d0151b1151b1150c0251b1151e1101e015201101b0151b1251e1100f5170c020275162011220112221151b010201151b0160d0201e1101b115191101a110
011200201b525271151b016270031b017271051b0161b1151e0001b1151b0161b1151b026190151a1101a1101b0161b1101b0161b0122211222112160222011220112201121e1121e112180221e112191101a110
414800000351003521035110351503512035210351103511015310153101522015220a5220a52206522085210352003521035110351201531015320153201532005310053100530005320b7200b0210d0320a032
051200001bd201bd201bd201bd201bd101bd101bd101bd101bd101bd101bd101bd101bd101bd101bd101bd1022d3519d2022d3519d2021d3519d2021d3519d2020d351ad2020d351ad201ed301bd2019d301ad20
092400000f0100f0200f0200f0200f0220f0220f0220f0220d0310d0210d0200d0100d0220d0320d0220d0320c0210c0200c0200c020000300c022000320c0220b0350b020160350b020060350d035120350d035
112400000d0200f0300f0300f0200f030035300f022030200d02214022120220d0220d022010220d0220d0220c0210c0200c0200c020000200c022000320c0220b0350b0350b0350b0300d0450d0450a0350b035
0b12000000c3000c2000c2500c3000c2000c2000c2300c2200c1000c2000c2000c2506c2006c2003c2003c200ac200ac200ac250ac200ac2516c200ac200ac250dc200dc2001c2001c250fc2008c2008c2506c20
0512000020d2020d2020d2020d2020d1020c1020c1020c10204102041022420224202242022d102241022410224350b420224350b42027d350b42027d350b42022c350d42022c350d42022c351e43020c301a420
0010000018430184300c4310c4301f4301f4001d4321d4321d4321d2321d2221d2221d2121d2121d2020000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000018430184300c4310c4301f4303660311432114321143211232112221122211222112221122211212053550735505355073550a3550c355073550c35505355073550a3550c35511355133551635518355
001000000215502100001000e155001000d10002155021550215002155021550e1500e100001000f100021000210002100001000010002100021000e1000e1000010000100001000010000100001000010000100
111200200f526145261b625145260f527185270f626145200b5260f526176251b5260f527185200f626145201b5260f5261b625145260f5261c5260f6261c5261b526175261b625175261b526175261b62517526
011200201711620116231162011617116241161b116231162311623116171162011623116241161711620116231162711617116201162311628116171161b1161711627116231162711617116271162311627116
01100000032500730003250073000a3000c3001630018300062500000006250000000000000000000000000005250000000525000000000000000000000000000425000000032500000000000000000000000000
791000000a2100a2100321003210032150321003410034100d2100d2100321003410033150321003410034100621006210034100341003215032100a2110a2100841008410033100331003210032100341003410
49100000143261b3160f3201b326143101b3100f3201b3160f3201b3100f3261b3160f32011310123200d3200f3200f3101632016316163200f3160f310143200f3261401014326143100f3101b3201232011320
001000000f336123160f330123360f3101b3100f3300f3100f336143100f330143361b3100f3200f330113301d3260f3201d3260f3201d3260f3201d3260f3201e3260f4201e3260f4201e3260f4201e3260f420
1010000020336273161b3302733620316273101b330273161b336273161b336273261b3200b3401e3301d3301b3351b3352232022326223300f3401b32020330200300d34020330203201b310273301e3301d330
101000001b3361e3161b3301e3361b310273101b3301b3101b336203101b33020336273101b3201b3301d330293261b320293261b320293262232029326223202a326203202a326203202a3261e3202a3261d320
301000000a1100a1100a1100a1100a1100a1100a1100a1100391003110039100311003913039130391003910069100312006920031200c1200c1200c1200c1200492003110049100391003913039130391303913
301000000b1100b1100b1100b1100b1100b1100b1120b1220492004110049100421203913039130392203922069200312006920031200d1220d1220d1220d1220792003120121220692206922069231212212922
7810002003320034100332003210032100322003415034150332003410033200321003210032100391003910064200f4100642003210032100321003215032150432012d10043200621006210063100631006310
79100000049100b410049100321003210032100341003410043200b410043200321003210032100340003400064200f9100642003210032100321003210032100732012d100732006d100621012d100631006310
0120000022025220141601027015250250d0241901025015240250c024180100c0102302523014170100b0102202522014160100a0101e0251e0140601012010200252001408010080101c0250b9141c0100d914
4b1000201d3233500015313214133e6201d611153133e6101531300300214132d600214130f3243c6250f322153230030039615213133e6101d611396153e6102131300300214231532338620386243862538620
00100000220202201022010160201601016010270202701025020250100d020190201901019010250402502024050240300c0201804018030180300c0400c0202305023030230201704017030170300b0400b020
011000002205022030160200a0400a0300a03016030160301e0501e0301e020060400603006030120301203020050200302002008040080300803014030140301c0501c030040200404004030040300403004030
011000000fc550fc550fc550fc551ec551bc551bc551bc550fc550fc550fc550fc5520c551bc551bc551bc5500000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
03 09622249
00 41424344
00 41424344
00 41424344
01 20496223
00 21626263
00 20626263
00 21226264
00 26202263
00 20622223
00 28622225
00 20622209
00 21622209
00 20622209
02 21622209
01 286f2f49
00 296f2f49
00 286f1d63
00 296f2f65
00 20621d63
02 21621d64
01 1e5d1d28
00 1e5d1d1c
00 1e5d1d28
02 1c5d1d28
00 57424344
00 41424344
00 41424344
01 323c3c39
00 323c3c39
00 3b3c3c39
00 373c3c33
02 383c3c34
00 41424344
00 393c3c35
02 3a3c3c36
00 41424344
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

