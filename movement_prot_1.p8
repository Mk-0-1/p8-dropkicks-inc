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
	
	cartdata("mk_0_test1")
	
	--dset(0,10)

	mod_tabl(_ENV,"trn_bnc,trn_slp,grav/0.2,0.75,0.19")
	mod_tabl(_ENV,"camera_x,camera_y/0,0")

	mod_tabl(_ENV,"delay_timers,delay_timers_draw/{},{}")

 -- timers & counters
 mod_tabl(_ENV,"anim_c,max_anim_len/0,2048")
 mod_tabl(_ENV,"t_enms,lvl_enms,t_e_clear,lvl_e_clear,t_boss/0,0,0,0,false")
	
	-- use extended map by default
	poke(0x5f56,0x80)
	
	-- no repeat btnp
 poke(0x5f5c,255)

	-- EDITOR ONLY - keep pal changes when esc
	poke(0x5f2e, 1)

	load_lvl(0)
	
	_update,_draw = _update_m_menu,_draw_m_menu
end


function text_box(str,screen,x,y,xlen,ylen,c1,c2)
	if (screen=="true") camera(0,0)
	if (c1>-1)rrectfill(x,y,xlen,ylen,0,c1)
	if (c2>-1)rrect(x+1,y+1,xlen-2,ylen-2,0,c2)
	print(str,x+6,y+4,7)
	camera(camera_x,camera_y)
end

function fade_text(x,y,text,t)
	print(text,x,y,7)
	if (t>0) delay_timer(delay_timers_draw,1,fade_text,{x,y-0.5,text,t-1})
end

function _draw_m_menu()
	draw_common()
	
	if not lvl_loading then 
		if lvl_locked then
			text_box(unstr("???\n\ncomplete previous\nlevel to unlock,true,8,8,80,32,8,9"))
		else
			text_box(unstr(lvl_extrainfo(1).."\n\nhiscore:"..lvl_hiscore..",true,8,8,56,28,8,9"))
			text_box(unstr("\^o80b🅾️:begin           ❎:info,true,0,112,56,28,-1,-1"))
		end
	end

	update_timer_tbl(delay_timers_draw)
end

function _update_wait()
	menuitem(2)
	update_timer_tbl(delay_timers)
end

lvl_hiscore,lvl_locked,lvl_loading=0,false,false
function _update_m_menu()

	if btnp(0) then
		m_index -= 1
		screenwipe(unstr"-28,32,8")
	end
	if btnp(1) then
		m_index += 1
		screenwipe(unstr"28,32,8")
	end
	if btnp(0) or btnp(1) then
		m_index %= #start_lvls
		
		
		local function lvl_ds()
			l_index = start_lvls[m_index+1]
			load_lvl(l_index)
			if (lvl_locked) pal(split"133,134,11, 129,1,0,7 ,134,13,6,7, 12,6,14,13,  0",1)
			lvl_loading=false
		end
		lvl_loading=true
		lvl_locked=m_index>0 and dget(m_index-1)<=0 
		delay_timer(delay_timers,8,lvl_ds,{})
	end
	
	if btnp(4) and not lvl_locked then
		screenwipe(unstr"24,56,9")

		local function bgn_scr()
			cls(9)
			camera(0,0)
			print("\^w\^t\^o80b\^j22"..lvl_extrainfo(1).."\^-w\^-t\n\^5\^j25"..lvl_extrainfo(7).."\^5")
			if lvl_hiscore <= 0 then
				text_box(unstr("\^4\^d1"..lvl_extrainfo(8).."\^5,true,8,40,112,80,8,10"))
				--pal(7,6,1),pal(7,13,1)&pal(7,5,1) with pauses inbetween. the 13 is 1d as 0d is newline
				print("\^@5f170001⁶\^3\^@5f170001。\^3\^@5f170001⁵\^3")
			end
			cls(9)
			begin_lvl(false)
		end

		delay_timer(delay_timers_draw,16,bgn_scr,{16})
		
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
	
	load_lvl(loaded_lvl_index)
	_update,_draw,delay_timers=_update_inlvl,_draw_inlvl,{}
	
	menuitem(2 | 0x300, "retry area",retry_lvl)
	menuitem(3 | 0x300, "exit level",exit_lvl)
	
	
	if cont then
		if retry then
			player.stmn,player.stmn_l_b=80,max(0,player.stmn_l_b-5)
		else
			t_enms+=lvl_enms
			t_e_clear+=lvl_e_clear
		end
		mod_tabl(_ENV,"lvl_enms,lvl_e_clear/0,0")
	else
		mod_tabl(_ENV,"t_enms,lvl_enms,t_e_clear,lvl_e_clear,t_boss/0,0,0,0,false")
	end
	
	init_entities(cont)
	camera_x,camera_y,prev_cam_speed=player.pos.x-64,player.pos.y-64,vec2_zero
end

function load_next()
	if lvl_extrainfo(2) >= 0 then
		loaded_lvl_index=lvl_extrainfo(2)
		begin_lvl(true)
	else
		t_enms+=lvl_enms
		t_e_clear+=lvl_e_clear
		lvl_score = ((t_e_clear/t_enms)*100+player.stmn_l_b/40*100+tonum(t_boss)*100)\1
		if(lvl_score > dget(m_index)) dset(m_index,lvl_score)
		
		menuitem(3)
		_update = _update_finish
		_draw = _draw_finish
	end
end

function lvl_transition()

local sc_col=8
if (lvl_extrainfo(2) < 0) sc_col=12
	screenwipe(24,48,sc_col)
	_update = _update_wait
	delay_timer(delay_timers,8,load_next,{})
end

function exit_lvl()
	delay_timers={}
	menuitem(2)
	menuitem(3)
	_update,_draw = _update_m_menu,_draw_m_menu
	load_lvl(start_lvls[m_index+1])
end

function _update_finish()
	if btnp(4) then
		screenwipe(unstr"24,40,8")
		exit_lvl()
	end
end

function _draw_finish()
	cls(12)
	camera(0,0)
	color(7)
	print("\n\n\^w\^t\^o80b\^3\^d1 "..lvl_extrainfo(1).."\n\^d0       \^4\^3complete!\n\n")
	print("\^5\^4\^o80b ◆ "..t_e_clear.."/"..t_enms.." machines 'disassembled'\n")
	print("\^5\^4\^o80b ◆ "..player.stmn_l_b/40*100\1 .."% armor preserved\n")
	if t_boss then
		print("\^5\^4\^o80b ◆  boss defeated!\n\n")
	elseif loaded_lvl_index != 1 then
		print("\^5\^4\^o80b ◆ boss disengaged...\n\n")
	end
	print("\^5\^4\^o80b\*3 score: \^5" .. lvl_score)
	print("\^5\^4\^o80b\n\n\*6 press 🅾️ to continue")
	_draw = empty_f
end


function init_entities(keep_prevs)
	
	-- clear ALL
	entities,all_links={},{}
	
	local p_d = player
	player=spawn_player(lvl_extrainfo(3),lvl_extrainfo(4))
	
	if keep_prevs then
		-- if keeping player's info
		player.stmn,player.stmn_l_b,player.items=p_d.stmn,p_d.stmn_l_b,p_d.items
	end
	add(entities,player)
	
	local e_arr = lvl_arr(2)
	for i=1, #e_arr, 4 do
		local e_type,ex,ey,e_extra = unpack(e_arr, i)
		local e=spawn_entity(ex,ey,e_type,nil,e_extra)
		add(entities,e)
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
	anim_c+=1
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
	
	
	update_mus()


	-- update entities
	for ntt in all(entities) do
	
		for subntt in all(ntt.all_ntts) do

			move_entity(subntt)
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
	
		
	local text_arr = lvl_arr(3)
	
	for i=1,#text_arr,14 do
		local x1,y1,x2,y2,mspr_i,turn = unpack(text_arr,i)
		deco_ntt = mod_tabl2({},"pos,m_sprite",{vec2_new(x1+x2,y1+y2)/2, split(m_sprites[mspr_i])})
		deco_ntt.is_left = turn and player.pos.x < deco_ntt.pos.x
		draw_entity(deco_ntt)
		
		if player.pos.x > x1 and player.pos.y > y1 and player.pos.x < x2 and player.pos.y < y2 then
			text_box(unpack(text_arr,i+6))
		end
	end
	
	draw_ui()
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

function get_first_link(e1,e2)
	for link in all(all_links) do
		if ((link.from == e1 and link.to == e2) or (link.from == e2 and link.to == e1)) return link
	end
end

function timer_ready(e,n)
	return e.timers[n] <= 0
end

function spawn_entity(x,y,type,parent,extrainfo)
	local entity = mod_tabl2({},"pos,vel",{vec2_new(x, y),v2c(vec2_zero)})
	
	
	local props_c,props_e = ntt_types[type*2-1],ntt_types[type*2]
	mod_tabl(entity,"rds,mass/" .. props_c)
	
	local m_spri,ifi,ufi,dfi = unpack(split(props_c),3)
	-- only primary entities can have timers - non-custom ones, anyway
	mod_tabl2(entity,"template,timers,m_sprite,update_func,draw_func,input_dir,all_ntts,extra",{type,{},split(m_sprites[m_spri]), ntt_updates[ufi], ntt_draws[dfi],v2c(vec2_zero),{entity},extrainfo}) 
	
	mod_tabl(entity, "is_left,coll_rng/false,0")
	
	mod_tabl(entity,props_e)
	mod_tabl(entity.timers,"hurt,jump_cooldown/0,0")
	
	entity.coll_func = ntt_extra_funcs[entity.coll_func] -- table[nil] is nil so works without if
	entity.break_func = ntt_extra_funcs[entity.break_func]
	entity.smoke = smokes[entity.smoke]
	
	if parent then
		entity.parent=parent
		entity.pos+=parent.pos
		entity.vel+=parent.vel	
	end
	
	entity.stmn_l_t = entity.stmn

	
	if (entity.enemy) lvl_enms+=1
	
	if entity.b_type then
		init_complex(entity)
	end
	
	ntt_inits[ifi](entity)
	
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
		player.items |= 1 << (i.template-8)
		fade_text(i.pos.x,i.pos.y,item_names[i.template-7],45)
		remove_entity(i)
	end
end


local function spawn_next(e)
	add(entities,spawn_entity(e.pos.x,e.pos.y,e.extra))
end

function init_enemy(enm)
	mod_tabl2(enm,"gun,ai,e_type,is_left",{split(guns[enm.gun]),enm_ais[enm.ai],"enm",true})
	
	if enm.extra and enm.extra > 0 then
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
	
	local is_present=false
	if e.parent then
		is_present=del(e.parent.all_ntts, e) and in_tbl(e.parent, entities)
	else
		is_present=del(entities, e)
	end
	
	if not noeffect then
		if e.enemy then 
			lvl_e_clear+=1
			local txt="\^oc09"..lvl_e_clear.."/"..lvl_enms
			if (lvl_e_clear >= lvl_enms)txt="\^oc09area clear!"
			fade_text(player.pos.x,player.pos.y,txt,30)
			
		end
		
		if (e.boss) t_boss=true
		if is_present then
			if (e.smoke) particles(e.pos,split(e.smoke),e.vel)
			if (e.break_func) e.break_func(e)
		end
		
	end
	
	return is_present
end

-- link_type, link_len, to_ground, link_strenght, draw_type, col, is_front, width
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
	
	local rcol = 3
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
		if e_spr >= 0 then
			local spr_size = entity.spr_size or 8
			local spr_sw,spr_sh = s_x*spr_size, s_y*spr_size
			e_spr += ((anim_c\a_t)%a_n)*s_x
			sspr(e_spr%16*8,e_spr\16*8,s_x*8,s_y*8,entity.pos.x-spr_sw/2,entity.pos.y-spr_sh/2,spr_sw,spr_sh,entity.is_left)
		end
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
	
	local enm_col,g_t,hurt=3,enm.timers.gun, not timer_ready(enm,"hurt")
	if (hurt) enm_col=7
	
	if enm.active or hurt then
		if (g_t < 8 and g_t%4>1) enm_col=11
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

	local p1,p2,l=from.pos,to.pos,false
	if (to_ground) p2 = to
	
	l = from.is_left
	
	if draw_type == 1 then
		envstr.line_vec(p1, p2, col,width)
	elseif draw_type == 2 then
		envstr.draw_joint(p1, p2, len/2, col, l,width)
		
	elseif draw_type == 3 then
		local pos_2 = p1 + envstr.vec2_normalized(from.leg_facing)*3
		envstr.line_vec(p1, pos_2, from.col or 13, width)
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
	
	--[[
	local col_t = 14
	if (ntt.m_l_legs[1].t_active) col_t=3
	circ(ntt.m_l_legs[1].t_pos.x,ntt.m_l_legs[1].t_pos.y,3,col_t)
	
	col_t = 14
	if (ntt.m_l_legs[2].t_active) col_t=3
	circ(ntt.m_l_legs[2].t_pos.x,ntt.m_l_legs[2].t_pos.y,3,col_t)
	]]
	
	--eyes
	
	local hurt_tmr = ntt.timers.hurt
	
	local e_pos_y = head_sprite_pos.y
	if (btn(3) or hurt_tmr > 20) e_pos_y += 1
	
	local spr_i = 0
	
	if (vec2_len(ntt.vel) > 4) spr_i = 1
	if hurt_tmr > 50 then
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
		ui_line(3,82,i,8)
	end
	
	for i=2, 4 do
		ui_line(4,player.stmn + player.timers.hurt/2,i,7)
		ui_line(4,player.stmn-1,i,12)
		ui_line(4,player.stmn_l_b,i,14)
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
	if (sf >=0 and vec2_len(src_pos - player.pos) < 180) sfx(sf)
end

function sfx2(sf)
	if sf >= 0 then
		sfx(sf)
	else
		print(split(ex_sfx)[-sf])
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
 			if (sq_sq_coll(p_in, rds, p2, 4)) return true, p2
 		end
			
		end
	end
	
	return false
end

function check_coll_ntts(ntt, pos, rds)
	-- ultra slow with lots of primary entities - limit is about 15
	-- todo maybe do grid cell separation table -- yeah right with this many tokens -- timesplits could work
	for other in all(entities) do
		if not (in_tbl(other, {ntt,ntt.parent,ntt.grabbed_e}) or ntt == other.grabbed_e or (ntt.parent and other == ntt.parent.grabbed_e) ) then
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
		for i=1, 4 do
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

	particles(pos, {7, radius/2, sf, -radius/6, 5})
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
		-- also acts as iframes
		if ntt != envstr.player or timers.hurt <= 4 then
			--printh("damage dealt to " .. tostr(ntt.id) .. ": " .. tostr(dmg))
			local p_s=stmn
			stmn-=dmg
			
			if stmn_l_b and stmn < stmn_l_b then
				local dmg2 = stmn_l_b-stmn
				dmg2/=4
				stmn_l_b -= dmg2
				stmn = stmn_l_b
			end

			local total_dmg = p_s - stmn
			timers.hurt=total_dmg*2
				
			if e_type=="enm" and stmn > 0 and total_dmg > 1 then
				envstr.fade_text(pos.x,pos.y,"\^o05a"..(stmn/stmn_l_t*100)\1 .."%",18)
			end
					
		end
	end
end

function get_tmp_trn_e(pos)
	local px,py=pos.x\8,pos.y\8
	local ntt=spawn_entity(px*8+4,py*8+4,10)
	ntt.tile = mget(px, py)
	if (fget(ntt.tile,1)) ntt.mass = 2.4
	return ntt
end

function impact(entity, with_t, surface_dir, coll_e, no_sfx, no_sq_coll, no_convert)
	
	local prev_v1,prev_v2 = v2c(entity.vel), v2c(coll_e.vel)
	
	local function get_nrg(v1,v2)
		return vec2_len(v1)^2*entity.mass + vec2_len(v2)^2*coll_e.mass
	end
	
	local slp = max(entity.slip or trn_slp, coll_e.slip or trn_slp)
	local bnc = max(entity.bounce or trn_bnc, coll_e.bounce or trn_bnc)

	transfer_momentum(entity, coll_e, bnc, slp, not no_sq_coll)

	local impact=get_nrg(prev_v1,prev_v2)-get_nrg(entity.vel,coll_e.vel)
	local impact_1,impact_2=split_vector(impact, entity.mass, coll_e.mass)
	
	
	-- if broke terrain turn tmp tile to entity tile
	if with_t and vec2_len(coll_e.vel) > 0.6 and coll_e.pos.y\8 < ld_l_size_y*4-1 then
		
		if not no_convert then
			coll_e.tile = 14 + rnd(2)\1
			coll_e.mass=2.4
		end
		
		coll_e = tile_to_entity(coll_e)
		coll_e.vel *= 4
	end
	
	-- old bounce
	--entity.vel = recomp_mul(entity.vel, surface_dir, -trn_bnc, trn_slp)
	
	function coll_p(e,p,i,o)
		if o.contact_dmg then
			lose_stmn(e, o.contact_dmg)
			if (e==player) sfx2(-1)
			local cnt_vel=vec2_normalized(e.pos-o.pos)*o.contact_dmg/10
			e.vel += cnt_vel
			o.vel -= cnt_vel
		end
		
		if e.coll_func then
			e.coll_func(e, p, i, o)
		end
		if i >= (e.armor or 0) then
			lose_stmn(e, i^1.5)
		end
		--if (e.e_type == "enm" and o.e_type == "tile") e.timers.hurt=30+i
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

	-- move
	--MAC_per_frame += 1
	
	-- apply movement
	entity.pos += entity.vel
	
	-- clip out
	local did_c,with_t,out,surface_dir,coll_e = unclip(entity)
	if did_c and out then
		entity.pos += surface_dir
	end
	
	
	if did_c then
		--printh("coll! " .. tostr(entity.id))
	
		if out then
			impact(entity, with_t, surface_dir, coll_e)
			entity.coll_rng=0
		else
			if with_t then
				entity.coll_rng += 4
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
			entity.vel.y += grav
		end
	end
	--entity.vel *= 0.999 --air friction
	
	-- prevent micromovements
	--if (vec2_len(entity.vel) < 0.09) entity.vel *= 0
	
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

-- basically a raycast with spotlight angling
function ray_coll(pos,vec,angle_range,entity,sticky)
	for t_vec in all({vec*0.1,vec*0.4,vec*0.6,vec,vec2_rotate(vec,angle_range),vec2_rotate(vec,-angle_range)}) do
		local t_pos = pos + t_vec
		local coll_land,with_t,out,away_vector,other_ntt = unclip(entity, t_pos,nil, true)
		if (coll_land and out) return true, t_vec, with_t, away_vector, other_ntt, false
		
		if in_tbl(mget(t_pos.x\8, t_pos.y\8), {44,45}) and sticky then
			return true, t_vec, true, v2c(vec2_up), get_tmp_trn_e(t_pos), true
		end
		
	end
	
	return false
end



function move_towards(ntt, target_pos, speed)
	--local prev_pos = v2c(ntt.pos)
	
	--local m = 
	--move_and_unclip(ntt, vec2_limit((target_pos-ntt.pos)/speed)*speed)
	ntt.pos+=vec2_limit((target_pos-ntt.pos)/speed)*speed
	--if parent_move and ntt.parent then
	--	ntt.parent.pos -= m*ntt.mass/ntt.parent.mass
	--end
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
	
	
	if (timers.hurt > 50) return

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
						
						--[[
						local lx,ly = leg.pos.x\8,leg.pos.y\8
						if envstr.in_tbl(envstr.mget(lx,ly) ,{44,45}) then
							envstr.mset(lx,ly,45)
							local function unset()
								envstr.mset(lx,ly,44)
							end
							envstr.delay_timer(envstr.delay_timers,1,unset, {})
						end
						]]
						
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
		
		if envstr.abs(vel.y) < 2.6 then
			vel.y *= 0.85
		end
			
		-- stabilise pos
		
		
		local stand_p_lh = st_pos/st_c
		
		if crouch or envstr.sq_trn_coll(pos+envstr.vec2_up*5, 0.5) then
			stand_p_lh -= surface_away * 4
		else
			stand_p_lh += surface_away * (envstr.anim_c\48%2)
		end
		
		if not sticky then
			pos.y = pos.y*0.85 + stand_p_lh.y*0.15
			
			local function stabl_arm(arm)
				if envstr.vec2_len(arm.vel) < 0.15 and not armgrab then
					--arm.vel *= 0
					arm.special_stand=true
					--local d_vec = envstr.vec2_rotate(envstr.vec2_down*(envstr.get_first_link(entity,arm).len - envstr.tonum(crouch)), angl)
					--arm.pos = pos+d_vec
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
end


function ungrab(ntt)
	ntt.grabbed_e = nil
	ntt.in_grab = false
end

function move_control(ntt, b4, b5)

	local surface_normal = ntt.surface_away
	local input_dir_l = vec2_limit(ntt.input_dir or v2c(vec2_zero))
	local input_dir_h = vec2_normalized(input_dir_l + vec2_right*(tonum_flip(not ntt.is_left))*0.05)
	local hold_pos = ntt.pos + input_dir_h*ntt.arm_len
	
	local jump_cooldown = ntt.timers.jump_cooldown
	
		
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
		if (ntt.in_grab and input_dir_l.y <= 0) hold_pos = ntt.pos + vec2_up*ntt.arm_len*1.75
		local hp_clip,hp_with_t,hp_out,hp_dir,hp_coll_e = unclip(arm_1,hold_pos)
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
						--if not arm.t_active then
							--arm.t_pos = chosen_t
							--if (arm.is_stnd) arm.t_pos = arm.pos
							--arm.t_active = true
						--end
						jump_s = true
						arm.mass = 1.1
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
					sfx(20)
					ntt.grabbed_e = hp_coll_e
										
					make_link(arm_1,hp_coll_e,split"1,0.1,false,20,0,14,false,0")
				end
			end
			
			if ntt.in_grab then

				--rotate grabbed object
				--counter_mmnt((arm_1.pos - ntt.grabbed_e.pos)/32, ntt.grabbed_e, ntt)

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
				counter_mmnt(vec2_normalized(input_dir_h + vec2_up*0.2) * throw_str, ntt.grabbed_e, ntt)
				ntt.grabbed_e.timers.hurt=30
				--end
				
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

	--local b0i,b1i,b2i,b3i = tonum(input_dir_l.x < 0),tonum(input_dir_l.x > 0),tonum(input_dir_l.y < 0),tonum(input_dir_l.y > 0)

	local accel,vel_limit =  ntt.a_acc, ntt.a_max -- air drift
	
	if ntt.grounded_mode and ntt.surface_away.y != 0 then
		accel,vel_limit = ntt.g_acc,ntt.g_max -- ground movement
	end
	
	if ntt.grounded_mode or b5 or ntt.on_ladder then
		update_right(ntt)
	end
	
	
	--if (ntt.crouch) vel_limit /= 2

	local pv_add = input_dir_l*accel
	
	--pv_add.x*=1-tonum(b4)*0.75
	
	if (input_dir_l.x == 0 and ntt.special_stand) ntt.vel.x *= 0.5
	
	if (not (ntt.flying or ntt.on_ladder or (ntt.special_stand and ntt.sticky))) pv_add.y = 0
	
	if vec2_len(ntt.vel + pv_add) <= vec2_len(ntt.vel) or vec2_len(ntt.vel) <= vel_limit then
		ntt.vel += pv_add
	end
	
	
	-- jumping -----------------------------------
	

	-- jump control

	local g_e = ntt.ground_entity
	local g_is_ntt
	if (g_e) g_is_ntt = g_e.e_type != "tmp tile"
		
	-- jump away from surface
	local input_dir_u = vec2_normalized(input_dir_l + vec2_up*0.1)
	local input_dir_j = vec2_up*0.4 + input_dir_u*0.6
	input_dir_j.y*=2
	
	if b4 and jump_cooldown <= 0 then
	
		local jump_str,leg_pos,p_prevvel,j_sf		= ntt.jump_str,ntt.m_l_legs[1].pos,v2c(ntt.vel), 10+rnd(2)
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
			input_dir_j += surface_normal*1.2
			
			-- try to stabilise jump
			if vec2_dot(ntt.vel, input_dir_j) < -1 then
				jump_str *= 1.2
			end
			

		elseif on_magnet then
			mset(tx,ty,45)
			
			delay_timer(delay_timers,4,function() mset(tx,ty,44) end, {})
			particles(leg_pos,split"3,2.6,-1,0.4,8",p_prevvel)
			j_sf=13
		else
			jump_str=0
		end

		if jump_str > 0 then
			local jump_vel = vec2_limit(input_dir_j)*jump_str
			
			-- jump start
			--printh("jump'd")
			
			-- 9 frames of jump cooldown
			ntt.timers.jump_cooldown=9
			
			-- drop kick
			if ntt.grounded_mode and g_is_ntt then
				
				impact({pos=ntt.pos, vel=p_prevvel-jump_vel, mass=ntt.mass}, not g_is_ntt, jump_vel, g_e)
				lose_stmn(g_e, 3)
				
				j_sf=12
			end
			
			sfx2(j_sf)
			
			--printh("surface: " .. surface_normal.x .. "  " .. surface_normal.y)
			
			for leg in all(ntt.m_l_legs) do
				if leg.t_active then
					particles(leg.t_pos,split"7,1.6,-1,0.5,6", input_dir_j)
					break
				end
			end
			
			for ntt in all(ntt.all_ntts) do
				-- add less if already going fast
				ntt.vel *= 0.65	

				ntt.vel+=jump_vel
			end
		end
	end
	
	-- alignment direction

 local align_down,al_of=v2c(vec2_down),mid(-2,ntt.vel.x*0.35,2)
	
	if ntt.grounded_mode or ntt.on_ladder then
		align_down.x-=al_of
	else
			if b5 then
				align_down-=input_dir_l*3
			else
				align_down+=vec2_new(al_of,0)-input_dir_l*0.6
			end
			
	end
	
	ntt.leg_facing = vec2_limit(ntt.leg_facing*0.8 + align_down*0.2)
	
	-- only used for head drawing
	ntt.facing = vec2_normalized(input_dir_j*0.2 - vec2_normalized(ntt.leg_facing) + vec2_up*0.3)
	
end


function update_player(player)
	move_humanoid(player)
	
	local hurt = player.timers.hurt
	if (hurt >= 50) return
	-- regen stamina
	if (player.stmn < player.stmn_l_t and hurt <= 8) player.stmn += 0x0.3
	
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
			if (btn(4) and timer_ready(player, "jump_cooldown"))	l_l_len *= 0.8

		end
		
		l_link.len = l_l_len
		
		i+=1
	end
 
end



-->8
-- level managment

function lvl_arr(index)
	return split(lvls_extra_info[loaded_lvl_index+1][index],"|") or {}
end

function lvl_extrainfo(index)
	return lvl_arr(1)[index]
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

function unpack_pal(o,n)
	local pal_l = (loaded_level[1][o]+n)*16
	return {unpack(palettes, pal_l+1, pal_l+16)}
end

function load_lvl(index)
	loaded_lvl_index,lvl_hiscore = index,dget(m_index)
	camera_x,camera_y = lvl_extrainfo(5),lvl_extrainfo(6)

	local map_pos_x = (index%8) * l_size_x
	local map_pos_y = (index\8) *(l_size_y + l_head_size_y) + l_start

	loaded_level = {load_lvl_header(map_pos_x,map_pos_y),{}}
	ll_head_size, ll_tiles = loaded_level[1][1], loaded_level[2]

	for j=0, l_size_y-1 do
		for i=0, l_size_x-1 do
		 add(ll_tiles, mget0x20(map_pos_x+i,map_pos_y+l_head_size_y+j))
		end
	end
	
	-- set size
	ld_l_size_x,ld_l_size_y = 16,8

	if bcheck(ll_head_size,0b10) then
		ld_l_size_x,ld_l_size_y=32,4
	end
	if bcheck(ll_head_size,0b01) then
		ld_l_size_x,ld_l_size_y=ld_l_size_y,ld_l_size_x
	end

	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1
	
	
	-- clear map
	memset(0x8000, 0, 0x2000)
	for t_c=0, #ll_tiles-1 do
		draw_tile(ll_tiles[t_c+1], t_c%ld_l_size_x, t_c\ld_l_size_x)
	end
	
	lvl_pal1,lvl_pal2 = unpack_pal(4,0),unpack_pal(5,16)

	pal(lvl_pal1, 1)
	

end


function tile_spr(s, alt_l, alt_t)
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

	if bcheck(s1, 0b00100000) and (s1 & 0b00001000 == 0) then -- in bottom left part of spr page
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
			mset(m_x,m_y, tile_spr(mget0x20((t2%32)*4+i,(t2\32)*4 +4+j), bcheck(extra_t, 0b01000000), bcheck(extra_t, 0b10000000)))
		end
	end
	

end

-->8
-- enemy ai


function update_enm(enm)
	
	update_right(enm)
	
	local stunned = not timer_ready(enm,"hurt")
	
	if vec2_len(enm.pos - player.pos) < 55 then
		enm.active=true
	end
	if vec2_len(enm.pos - player.pos) > 110 or stunned then
		enm.active=false
	end
	
	mod_tabl2(enm,"input_dir,prevstand,special_stand",{v2c(vec2_zero), enm.special_stand, false})
	
	if not stunned then
		-- passive ai
		enm_ais[enm.ai_p](enm)
	end
	
	if enm.active then
		if (player.grabbed_e != enm) enm.shoot_dir=player.pos - enm.pos
		-- active ai
		enm_ais[enm.ai_a](enm)
		if timer_ready(enm, "gun") then
			fire_gun(enm)
		end
	else
		enm.timers.gun=enm.gun[1]
	end
	
	if (enm.stmn/enm.stmn_l_t < 0.35 and anim_c%12==0) particles(enm.pos, split"6, 2.4,-1,0.2,8", vec2_up*0.5)
	
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
	enm.shoot_dir.y=0
	enm.input_dir = enm.shoot_dir

	enm.stnd_height = mid(4, enm.pos.y - player.pos.y +9, 15)
end

function ai_follow(enm)
	local dist = vec2_len(enm.shoot_dir)
	
	if (dist > enm.range_out)	enm.input_dir=v2c(enm.shoot_dir)
	if (dist < enm.range_in)	enm.input_dir=-enm.shoot_dir
	
	move_control(enm,false,false)
end

--[[
function ai_follow_flying(enm)
	enm.input_dir=vec2_limit(player.pos - enm.pos)
	
	local dist = vec2_len(player.pos - enm.pos)
	if (dist > 50)	enm.vel += enm.input_dir/4
	if (dist < 35)	enm.vel -= enm.input_dir/4
end
]]



--cooldown,projectile entity,p speed,fire sfx
function fire_gun(e)
	local cldwn,p_t,spd,sfx,angl,dur,global,nxt = unpack(e.gun)
	sp_sfx(sfx,e.pos)
	local proj = spawn_entity(0,0,p_t,e)
	proj.vel+=vec2_rotate(vec2_normalized(e.shoot_dir),angl)*spd
	if global=="tru" then
		add(entities, proj)
		proj.pos+=vec2_normalized(proj.vel)*e.rds*1.5
	else
		add(e.all_ntts, proj)
	end
	
	delay_timer(delay_timers,dur,remove_entity,{proj})
	
	e.gun=split(guns[nxt])
	e.timers.gun=e.gun[1]
end

-->8
-- data

-- list of almost all entity types.
-- features: common array{radius, mass, metasprite index, init function index, update function index, draw function index}
-- & extra properties {key1,key2/val1,val2}

-- NOTE: masses lower than 0.1 bug link-related movements
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

ntt_inits = {empty_f,init_enemy}
ntt_updates = {empty_f,update_player,update_enm,update_item}
ntt_draws = {empty_f,draw_entity,draw_humanoid,draw_enm}
ntt_extra_funcs = {empty_f, spawn_next}
enm_ais = {empty_f,ai_stabilise,ai_stabilise_flying,ai_h_turret,ai_follow}

m_sprites = {
	-- sprite,x size,y size, anim frame len, anim total frames
	"160,1,1,3000,1", -- default
	"-1,1,1,3000,1", -- blank (no draw)
	"128,1,1,3000,1", -- player
	
	-- enemies (4+)
	"163,1,1,3000,1", -- turret
	"164,1,1,3000,1", -- box
	"179,1,1,2,3", -- saucer
	"166,2,2,3000,1", -- tank
	
	-- projectiles (8+)
	"168,1,1,3000,1", -- small
	"185,1,1,1,2", -- sawblade
	
	-- items (10+)
	"176,1,1,3000,1" -- grab
}

-- body info for complex/limbed entities
ntt_b_types = {
-- sticky_walk, g_accel,a_accel,g_max_speed,a_max_speed,jump, leg_len,arm_len,stand h, leg speed,leg g cooldown,max leg target rotation, 
-- limb info starts at 13th array slot
-- limb info list: [11 things - entity type, limb type (a/l arm or leg), angle, link props (link_type, link_len, to_ground, link_strenght, draw_type, col, is_front,width)]
-- some limb stuff is kinda redundant like len but it's used for leg/arm targeting (maybe change?)
"false, 0.15,0.15,4,4,0, 18,1,20, 3,3,0.01", -- box (no limbs), air move ok - basic drone

"false, 0.7,0.15,2.2,1.5,2.9, 8.7,5,7.5, 3,3,0.07,  3,l,0.015, 1,8.7,false,0,3,7,false,0,  3,a,0.02, 1,5,false,0,2,12,false,0,  3,l,-0.015, 1,8.7,false,0,3,7,true,0,  3,a,-0.02, 1,5,false,0,2,12,true,0", -- humanoid


"false, 0,0,0,0,0, 18,1,16, 3,3,0.01,  3,l,-0.05, 1,18,false,0,2,14,false,2", -- standing turret
"true, 0.3,0.08,2,1,0, 18,1,12, 4,6,0.2,  3,l,0, 1,18,false,0,2,14,false,2,  3,l,0.3, 1,18,false,0,2,14,false,2,  3,l,0.6, 1,18,false,0,2,14,false,2", -- tripod spider
{},
{}
}

guns = {
--cooldown,projectile entity,p speed,fire sfx,angle,p lifetime, is global, next gun
	"45,7,3.5,18,0,100,fls,1",
	"60,8,3.5,19,0,80,fls,2",
	
}

smokes = {
-- 1-col, 2-radius, 3-sfx (- if none), [ 4-decay rate ], [ 5-time ]
	-- standard break, item pickup, projectile collide
 "14, 3.5,16", "12,3,20", "7, 2.5,-1"
}

ex_sfx = "\as2v2i6g#3<d4x5c4i0x4c4x0c#4g#3g#2x3c#2,\as4v6i0x3f#2<i6x1g#1i3x0f0i6x3<a2x0>a3x3g#3<d#3a#2g#2<c2g2i3x3e1x0i6b1x3i3c#1x0i6g#1<x3i3a#0i6d#1d1i3g#0v1g#0i6c1c1b0i3g0f#0f#0f0e0d#0c#0c0c0"


l_size_x,l_size_y,l_head_size_x,l_head_size_y = 16,8,10,1
l_start,l_end = 12, 32 -- 32 is excluded

ld_l_size_x,ld_l_size_y = 16,8

item_names = split"\^o9ffultragrab"

lvls_extra_info = {
--1st array: general extra info
-- name/m_menu title
-- next lvl (0-indexed, -1 is finish)
-- player spawnpos x & y
-- camera pos in main menu
-- sub title
-- intro text

--2nd: entity spawns
-- type, xpos, ypos, extrainfo

--3rd: signs/deco
-- x1,y1,x2,y2, metasprite,turn to player, textbox info (str,screen,x,y,xlen,ylen,c1,c2)

-- NOTE: try to not have more than 6 legs active at once. More kinda lags
{"mission 1| 1| 30|54| 464|0|construction site|from: hq                \n\nhello!        \n\nthis is some testing text.        \ngood luck with whatever\nyou're doing!",
		"4|510|84|0| 4|680|64|0| 4|864|84|0| 6|950|52|0", 
		"80|32|160|100|-1|false|press or hold\n🅾️ to jump!|false|80|86|60|18|9|-1| 470|40|540|100|0|false|jump off\n\f3hostile machines\f7\nto deal damage.|true|3|7|76|24|8|9| 720|20|800|120|0|false|❎ to grab objects\nlike \f3machines\f7 or\n\feunstable tiles\f7.|true|3|7|104|25|8|9",},
{"tutorial| 2| 6|200| 0| 0||",
		"4|194|194|0| 6|210|135|0| 4|150|56|0| 4|400|50|0| 5|450|190|0",
		"20|160|80|240|-1|false|you can 🅾️ jump on \n\ffmetal walls\f7 or\n❎ latch onto them.|true|3|7|116|25|8|9"
},
{"mission 1| 3| 8|180| 60|80||",
		"6|420|210|0",
},
{"mission 1| -1| 6|80| 60|80||",
},
{"1-3| 5| 10|40| 60|80||",
},
{"mission 1| -1| 10|180| 60|80||",
},
{"placeholder| -1| 10|180| 60|80||",
},
{"placeholder| -1| 10|180| 60|80||",
},
{"placeholder| -1| 10|180| 60|80||",
},
{"placeholder| -1| 10|180| 60|80||",
},
{"placeholder| -1| 10|180| 60|80||",
},
{"placeholder| -1| 10|180| 60|80||",
}

}

m_index,start_lvls=0,split"0,1,2,3"


-- storable in map maybe
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
c78787e7ef777989457efe67366366363e366363e3663663666666666666e3e3e3eeeee3666066666066066000000000e8e66ee80000000000ee96e66669ee00
77eee877ef77777757efe67466666666666666666666666666666eeee6e3e3e3ee7eee3e066330066603366600000000ee6336e80000000000eee966669eee00
e788ee8eef777777547e66746666666666666666666666660666e6666ee3e300eee773e8600336606663306600000000ee63368800000000000eeee99eeee000
7eee8e77ef77798847e76744336666333366663377666677006e666666e30000eee7ee86666606660660660600000000eee66886000000000000eeeeeeee0000
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
52020000123230e3233b6103b6153b61019315253253f614026150030000300003000030000300003000030000300003000000000000000000000000000000000000000000000000000000000000000000000000
52020000113230c3233a6103a6103c6133c6133f6153f6143f6040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

