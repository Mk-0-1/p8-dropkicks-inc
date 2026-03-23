pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

--dropkicks inc
--by mk_0

function _init()
	cartdata("mk_0_dropkicks_inc")
	-- use extended map by default
	poke(0x5f56,0x80)

	-- EDITOR ONLY - keep pal changes when esc
	poke(0x5f2e, 1)
	
	-- intro
	
	print("\^c0\n\^d1> initialising dropkicks inc.\asci0v2c0x1c#dd#eff#gg#aa#bc1 \n  job repositor\^d7y...\n\av3c2c3v2c3v1c3c3c3c3 \^d0  ready!\^6")
	load_lvl(1)
	
	--init global vars
	mod_tabl(_ENV,"camera_x,camera_y,delay_timers,anim_c,max_anim_len,time_c,t_enms,lvl_enms,t_e_clear,lvl_e_clear,t_trinkets,t_tr_collected,lvl_locked,view_info/328,-256,{},0,2048,0,0,0,0,0,0,0,false,false")
	
	lvl_hiscore=dget(m_index)
	load_menu()
	set_mus()
	
	for i=0,56 do
		dc2()
		camera_y *= 0.95
		flip()
	end
	

end

function rc() -- reset camera
	camera(camera_x,camera_y)
end

function text_box(str,screen,x,y,boxlen_x,boxlen_y,boxc1,boxc2,t,rel,dx,dy)
	if (screen=="true") camera()
	if (boxc1)rrectfill(x-5,y-4,boxlen_x,boxlen_y,0,boxc1)
	if (boxc2)rrect(x-4,y-3,boxlen_x-2,boxlen_y-2,0,boxc2)
	print(str,x,y,7)

	if t then
		if t<(rel or 1000) then
			x+=dx or 0
			y+=dy or -0.5
		end
		if (t>0) delay_timer(1,text_box,{str,screen,x,y,boxlen_x,boxlen_y,boxc1,boxc2,t-1,rel,dx,dy})
	end

	rc()
end

function _draw_m_menu()
	dc2()
		
		if lvl_locked then
			text_box(unstr("???\n\ncomplete previous\ntask to unlock,true,10,8,80,32,8,9"))
		else
			
			text_box(unstr(lvl_extrainfo(1).."\n\nbest rating:"..lvl_hiscore.."%,true,10,8,73,27,8,9"))
			
			if time_c > 0.5 then
				local t_col = "\f7"
				if (view_info) t_col = "\fe"
				text_box(unstr("\^o80b<\*f \*d >\*9\n🅾️/c:begin			 "..t_col.."❎/x:info,true,5,64,56,28"))
				
				if view_info then
					text_box(unpack(split(lvl_extrainfo(10).."⬆️true⬆️10⬆️36⬆️120⬆️76⬆️8⬆️9","⬆️")))
				end
				
			end
			

		end
	end



function _update_wait()
	draw_common()
	menuitem(2)
	update_timer_tbl()
end



function _update_m_menu()
	_draw_m_menu()
	time_c+=0.033333333
	


	if btnp(0) or btnp(1) then

		local xdir=-28
		m_index-=1

		if btnp(1) then
			xdir=28
			m_index+=2
		end
		
		m_index %= #start_lvls

		local function lvl_ds()
			l_index = start_lvls[m_index+1]
			load_lvl(l_index)
			
			lvl_mus,layers_active=1,0b1111
			update_mus()
			
			if (lvl_locked) pal(split"1,1,1, 129,129,0,7, 129,129,129,129, 12,129,14,13,  1",1)
		end
		
		lvl_locked=m_index>0 and dget(m_index-1)<=0
		
		screenwipe(xdir..",8",lvl_ds)

	end

	if btnp(4) and not lvl_locked then
		

		local function bgn_scr()
			cls(9)
			camera()
			print("\f7\^o80b\^j22"..lvl_extrainfo(1).."\n\^5\^j05\#a\^x5\^o8ff\^d1"..lvl_extrainfo(7).."\^x4\^o80b\#9\^j25\n\^5\^d1\n  "..lvl_extrainfo(8))
				--pal(7,6,1),pal(7,13,1)&pal(7,5,1) with pauses inbetween. the 13 is 1d as 0d is newline
				print("\^5\^@5f170001⁶\^3\^@5f170001。\^3\^@5f170001⁵\^3")
			--end
			cls(9)
			begin_lvl(false)
		end

		screenwipe("24,9",bgn_scr)
		
	end
	if (btnp(5)) view_info = not view_info
	update_timer_tbl()
end

function screenwipe(props,midf,args)

	local spd,col = unstr(props)
	local len = 400\abs(spd)
	
	local start_x = 128
	if (spd<0) start_x = -210
	
	for d=0,len do
		dc2()
		
		camera()
		for i=0, 5 do
			for j=0,210,7 do -- 30
				circfill(start_x + (i%2)*32+j,i*32,16,col)
			end
		end
		rc()
		
		start_x -= spd
		
		
		if d == len\2 then
			midf(unpack(args or {}))
		end
		
		flip()
	end
	
end



function begin_lvl(cont,retry)

	_update,delay_timers=_update_inlvl,{}
	clear_tbl(timer_q)

	if cont then
		lvl_prevmus = lvl_mus or 0
		if retry then
			--idk
		else

			if (lvl_extrainfo(7) != "") then
				delay_timer(1,text_box,{"\#6 "..lvl_extrainfo(7).."\^-#\f6\|f\^:7f3f1f0f07030100","true", unstr"0,8,0,0,0,0,84,20,-8,0"})
			end

		end
		
	else
		mod_tabl(_ENV,"time_c,t_enms,t_e_clear,t_tr_collected,t_trinkets,lvl_prevmus/0,0,0,0,0,0,0")
	end

	load_lvl(loaded_lvl_index)
	
	-- lvl var defaults
	mod_tabl(_ENV,"lvl_enms,lvl_e_clear,x_u_l,y_u_l,trn_bnc,trn_slp,grav,lvl_tr_collected,lvl_trinkets/0,0,0,0,0.2,0.75,0.22,0,0")
	x_l_l=l_border_x-127
	y_l_l=l_border_y-127
	
	
	-- lvl extra globals and defaults
	mod_tabl(_ENV,lvl_extrainfo(9))

	update_mus()
	if (lvl_mus != lvl_prevmus)	start_mus()

	menuitem(2 | 0x300, "retry area",retry_lvl)
	menuitem(3 | 0x300, "exit level",exit_lvl)

	init_entities()
	camera_x,camera_y,prev_cam_speed=player.pos.x-64,player.pos.y-64,vec2_zero+vec2_zero
	limit_camera()
end

function load_next()
	t_enms+=lvl_enms
	t_e_clear+=lvl_e_clear
	
	t_trinkets+=lvl_trinkets
	t_tr_collected+=lvl_tr_collected

	if lvl_extrainfo(2) >= 0 then
		loaded_lvl_index=lvl_extrainfo(2)
		begin_lvl(true)
	else

		lvl_score = t_e_clear/t_enms*75
		if (t_trinkets > 0) lvl_score += t_tr_collected/t_trinkets*25
		lvl_score\=1
		if(lvl_score > dget(m_index)) dset(m_index,lvl_score)
		lvl_mus=-1
		start_mus()

		menuitem(3)
		
		dc2()
		camera()
		print("\f7\n\n\^w\^t\^o8ff\^2\^d1 \as8....a#0.a#0.d#2d#..a#1a#d#2d# \^2"..lvl_extrainfo(1).."\n\^d0       \^4\^3complete!\n\n\n\^-w\^-t\^6◆ \as9x5d#2d#3 "..t_e_clear.."/"..t_enms.." machines 'disassembled'\n\n\^5\^4◆ \as9x5d#2d#3 "..t_tr_collected.."/"..t_trinkets.." trinkets recovered\n\n\^5\^4   \as9x5d#2d#3 time: " .. time_c .. " s\n")
		print("\f7\^5\^4\^o8ff\*3 rating: \^5\as9x5d#2d#3x6<<d#2<d#3<d#2<d#3<d#2<d#3 " .. lvl_score .. "%\^4\n\n\n\*a 🅾️ to continue")
		rc()
		flip()
		
		_update = _update_finish
	end

end

function lvl_transition()
	if lvl_extrainfo(2) > 0 then
		screenwipe("24,8",load_next)
	else 
		load_next()
	end
end

function load_menu()
	mod_tabl(_ENV,"delay_timers,lvl_mus,layers_active/{},1,15")
	clear_tbl(timer_q)
	menuitem(2)
	menuitem(3)
	update_mus()
	start_mus()
	_update=_update_m_menu
end

function exit_lvl()
	screenwipe("24,12", 
	function()
		--[[_draw=_draw_m_menu]] 
		load_lvl(start_lvls[m_index+1]) 
	end)
	load_menu()
end

function _update_finish()
	if btnp(4) then
		exit_lvl()
	end
end


function init_entities()

	-- clear ALL
	entities,all_links={},{}
	player = spawn_entity(lvl_extrainfo(3),lvl_extrainfo(4),2)

	add(entities,player)

	local e_arr = lvl_arr(3)
	for i=1, #e_arr, 4 do
		local Etyp,ex,ey,e_extra = unpack(e_arr, i)
		local e=spawn_entity(ex,ey,Etyp,nil,e_extra)
		add(entities,e)
	end

end

function delay_timer(ticks, func, args)
	local timer = {t=ticks,f=func,a={}}
	if (args) timer.a=args
	add(delay_timers, timer)
end

-- clears all indexable items in table without re-initializing the reference
function clear_tbl(tbl)
	if tbl then
		for i=1, #tbl do
			deli(tbl,1)
		end
	end
end

function update_timer_tbl()
	-- put all present timers in a separate queue so the main table can be updated
	-- queue is global so it can be flushed if needed
	timer_q = {}
	for timer in all(delay_timers) do
		add(timer_q, timer)
	end

	for timer in all(timer_q) do
		timer.t -= 1
		if timer.t <= 0 then
			timer.f(unpack(timer.a))
			del(delay_timers,timer)
		end
	end

end

function _update_inlvl()
	
	time_c+=0.033333333
	anim_c+=1
	anim_c%=max_anim_len
	if anim_c%8==0 then
		alert=false
		update_mus()
	end
	
	for ntt in all(entities) do

		for subntt in all(ntt.all_ntts) do

			if (not subntt.ignore_physics) move_entity(subntt)
			if (subntt.update_func) subntt.update_func(subntt)

				-- cleanup tile entities
			if subntt.Etyp == "tile" and subntt.is_stnd
			and vec2_len(subntt.vel) < 0.02 and subntt != player.grabbed_e then
				entity_to_tile(subntt)
			end

			if subntt.stmn and subntt.stmn < 0 then
				remove_entity(subntt)
			end

			test_borders(subntt)
		end

		for name, timer in pairs(ntt.timers) do
			ntt.timers[name] = max(0, timer-1)
		end
	end

	--check links
	foreach(all_links, tug)


	if player.pos.x > l_border_x+4 and btn(1) and lvl_extrainfo(2) > -2 then
		lvl_transition()
	end


	-- camera tracking
	local t_p=player.pos+player.vel*20
	t_p.x += tonum_flip(not player.is_left)*8
	t_p.y += player.input_dir.y*28

	local distance = vec2_new(
		t_p.x-camera_x-64,
		t_p.y-camera_y-64
	)
	local speed=prev_cam_speed*0.85 + distance/20*0.15

	camera_x+=(speed.x+0.5)\1
	camera_y+=(speed.y+0.5)\1

	prev_cam_speed = speed
	limit_camera()
	
	
	_draw_inlvl()
	update_timer_tbl()
end

function limit_camera()
	camera_x,camera_y=mid(x_u_l,camera_x,x_l_l),mid(y_u_l,camera_y,y_l_l)
end


function draw_common()
	cls(lvl_maininfo(13))

	draw_bg(0)
	draw_bg(10)
	
	rc()
end

function dc2()
	draw_common()
	map()
end

function _draw_inlvl()
	draw_common()
	map(unstr"0,0,0,0,128,64,0b1000")
	if (lvl_extrainfo(2) > -2) draw_lvl_borders()
	
	local drawables = {}
	
	for ntt in all(entities) do
		for subntt in all(ntt.all_ntts) do
			add(drawables,subntt)
		end
	end
	
	for link in all(all_links) do
		add(drawables,link)
	end

	-- decals
	local text_arr = lvl_arr(4)
	for j=1,#text_arr,3 do
		local x,y,text = unpack(text_arr,j)
		text_box(text,false,x,y)
	end	

	
	for i=1, 4 do
	
		if i==3 then
			-- solid map
			map(unstr"0,0,0,0,128,64,0b00000111")
		end
		
		-- entities
		for dr in all(drawables) do
			
			-- outlines 
			if dr.outl != 0 and i==2 then
				if dr.draw_func == draw_link then
					dr.draw_func(dr,true)
				else
					
					local pal_o = {}

					for i=1,16 do
						add(pal_o,dr.outl)
					end

					pal(pal_o,0)
					
					local function dr1(x,y)
						camera(camera_x+x,camera_y+y)
						dr.draw_func(dr)
					end

					dr1(-1,0)
					dr1( 1,0)
					dr1(0,-1)
					dr1(0, 1)
					rc()
					pal(0)
				end
			end
			
			-- normal
			if dr.d_o == i then
			 dr.draw_func(dr)
			end
			
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

-->8
-- token savers

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

-- mod tabl but v can be variables
function mod_tabl2(tab, k,v)
	local k = split(k)
	for i=1,#k do
		tab[k[i]]=_pars(v[i])
	end
	return tab
end



function _pars(v)
	if(v=="true")return true
	if(v=="false")return false
	if(v=="nil")return nil
	if(v=="{}")return {}
	return v
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
	local entity = mod_tabl2({},"pos,vel",{vec2_new(x, y),vec2_zero+vec2_zero})

	local pr = split(ntt_types[type], "|")
	local props_c,props_e = pr[1], pr[2]
	mod_tabl(entity,"xtra_src,rds,mass/" .. props_c)

	local m_spri,ifi,ufi,dfi = unpack(split(props_c),4)
	-- only primary entities can have timers - non-custom ones, anyway
	mod_tabl2(entity,"template,timers,bnce,slip,grav,m_sprite,update_func,draw_func,input_dir,all_ntts",{type,{},trn_bnc,trn_slp,grav,split(m_spri,":"), _ENV[ufi], _ENV[dfi],vec2_zero+vec2_zero,{entity}})

	-- some defaults
	mod_tabl(entity, "is_left,coll_rng,actN,actF,rngN,rngF,Iarm,Irss,spr_size,d_o,outl/false,0,55,100,0,35,0,1,8,3,0")

	-- xtra props from a source
	if (entity.xtra_src != 0) mod_tabl(entity,split(ntt_types[entity.xtra_src], "|")[2])
	
	-- props
	mod_tabl(entity,props_e)
	
	if (extraprops) mod_tabl(entity,extraprops)
	mod_tabl(entity.timers,"hurt,hitshock,jump_cooldown,stun/0,0,0,0")

	entity.coll_func = _ENV[entity.coll_func] 
	entity.break_func = _ENV[entity.break_func]
	entity.smok = smokes[entity.smok]

	if parent then
		entity.parent=parent
		entity.pos+=parent.pos
		entity.vel+=parent.vel
	end

	entity.stmn_l_t = entity.stmn


	if (entity.enemy == true) lvl_enms+=1

	if entity.item==4 then
		lvl_trinkets+=1
	end

	if entity.Btyp then
		init_complex(entity)
	end

	if entity.rope then
		init_roped(entity)
	end
	
	_ENV[ifi](entity)

	return entity
end

function init_complex(e)
	local b_info = split(ntt_b_types[e.Btyp])
	e.props = b_info
	mod_tabl(e,"grounded_mode,ground_entity,crouch/false,nil,false")
	mod_tabl2(e,"leg_facing,facing,input_dir,surface_away",{vec2_down,vec2_up,vec2_zero,vec2_up})
	mod_tabl2(e,"sticky,g_acc,a_acc,g_max,a_max,jump_str,leg_len,arm_len,stnd_height,leg_speed,leg_cooldown,leg_angle_range",b_info)

	--subentity mappings for limbs
	mod_tabl(e,"m_l_legs,l_angles,m_l_arms,a_angles/{},{},{},{}")
	-- cooldown for movement
	e.m_l_arms.cd,e.m_l_legs.cd=0,0

	for i=13, #b_info, 5 do
		local e_typ,l_typ,angle = unpack(b_info,i)
		local l_e = spawn_entity(0,0,e_typ,e)
		mod_tabl2(l_e,"t_pos,t_active,angle",{l_e.pos,false,angle})

		add(e.all_ntts, l_e)

		if l_typ=="l" then
			add(e.m_l_legs, l_e)
		else
			add(e.m_l_arms, l_e)
		end

		make_link(e,l_e,split(links[b_info[i+3]]), b_info[i+4])
	end

 return e
end

function Uitm(i)
	if vec2_len(i.pos-player.pos) < 8 then
		if i.item == 5 then
			player.stmn_h_dmg,player.stmn=max(0,player.stmn_h_dmg-i.amount),min(player.stmn+i.amount,80)
		else
			lvl_tr_collected+=1
			text_box("\^ocfftrinket!",0,i.pos.x,i.pos.y,unstr"0,0,0,0,45")
		end
		remove_entity(i)
	end
end

local function spawn_next(e)
	add(entities,spawn_entity(e.pos.x,e.pos.y,e.next_e))
end

function Ienm(enm)
	mod_tabl2(enm,"gun,Etyp,is_left,special_stand",{split(guns[enm.gun]),"enm",true,true})

	if enm.next_e and enm.next_e > 0 then
		enm.break_func = spawn_next
	end

end

function retry_lvl()
	screenwipe("-24,8",begin_lvl,{true,true})
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
		if e.enemy == true then
			lvl_e_clear+=1
			local txt="\^oc09"..lvl_e_clear.."/"..lvl_enms
			if (lvl_e_clear >= lvl_enms)txt="\^oc09area clear!"

			text_box(txt,0,player.pos.x,player.pos.y,unstr"0,0,0,0,50")

		end

		function c_r(v,t)
			y_u_l=-220
			prev_cam_speed.y-=v
			if (t>0) delay_timer(1, c_r, {v+0.05,t-1})
		end

		if e.boss then
			lvl_mus=-1
			start_mus()
			delay_timer(50, c_r, {0,90})
			delay_timer(115, lvl_transition)
		end
		if is_present then
			if (e.smok) particles(e.pos,split(e.smok),e.vel)
			if (e.break_func) e.break_func(e)
		end

	end

	return is_present
end

function make_link(e1,e2,link_props,extraprops)
	local link=mod_tabl2(
	{},"from,to,l_type,len,to_ground,strenght,draw_type,col,width,d_o,outl",
	{e1,e2,unpack(link_props)})
	mod_tabl(link,extraprops or "/")
	link.true_len,link.draw_func=link.len,draw_link
	add(all_links, link)
	return link
end

function delete_link(l)
	del(all_links,l)
end

-->8
-- drawing

function draw_bg(offset)
	mod_tabl2(_ENV,"b_img_indx,b_pal,b_sc,b_prlx,b_ofx,b_ofy,b_wx,b_wy,b_timx,b_timy",{unpack(lvl_arr(2),offset+14)})

	pal(unpack_pal(b_pal+16), 0)

	local p_sc,scrl,baddr = b_sc*8,b_prlx,0x2000 + b_img_indx*8
	local a_p_sc = abs(p_sc)
	
	local scroll_x,scroll_y = -b_ofx+camera_x*scrl+time_c*b_timx, -b_ofy+camera_y*scrl+time_c*b_timy

	if(b_wx==1) scroll_x %=8*a_p_sc
	if(b_wy==1) scroll_y %=4*a_p_sc

	local function map_scaled()
		for	i=0,7 do
			for	j=0,3 do
				--local n = mget0x20(b_img_indx*8+i, j)
				local n = @(baddr+i + j*128)
				if (n != 0) sspr((n&0b1111)*8,n\16*8,8,8, i*p_sc, j*p_sc,p_sc,p_sc)
			end
		end
	end

	for i=0, (128\(8*a_p_sc)+1)*b_wx do
		for j=0, (128\(4*a_p_sc)+1)*b_wy do
			camera(scroll_x - 8*a_p_sc*i, scroll_y - 4*a_p_sc*j)
			map_scaled()
		end
	end

	pal(0)
end

function draw_lvl_borders()

	local function l(o_x)
		line(l_border_x-o_x,0,l_border_x-o_x,l_border_y,12)
	end

	l(0)
	l(1)
	l(flr(time_c*9)%9)

end


function Dntt(entity)
	if (entity.m_sprite) draw_m_sprite(entity.pos,entity.m_sprite,entity.spr_size,entity.is_left)
end

function draw_m_sprite(pos,m_spr,spr_size,flip_x,flip_y)
	local e_spr,s_x,s_y,a_t,a_n = unpack(m_spr)
	if e_spr >= 0 then
		local spr_sw,spr_sh = s_x*spr_size, s_y*spr_size
		e_spr += ((anim_c\a_t)%a_n)*s_x
		sspr(e_spr%16*8,e_spr\16*8,s_x*8,s_y*8,pos.x-spr_sw/2,pos.y-spr_sh/2,spr_sw,spr_sh,flip_x,flip_y)
	end
end

function draw_link(link, is_outl)
	local envstr,_ENV = _ENV,link -- forbidden token-saving reality warping spell
	-- link's members are now "globals" and all previously global variables are now accessed trough envstr
	-- local makes it work only inside this function (and luckily not inside envstr's)

	local p1,p2,left,t_l,t_c,t_c2,t_w= from.pos,to.pos,from.is_left, len/2, col, from.col,width
	if (to_ground) p2 = to

	if is_outl then
		t_w += 4
		t_c,t_c2 = outl, outl
	end
	
	if draw_type == 3 then
	
		local pos_2 = p1 + envstr.vec2_normalized(-from.facing)*3
		envstr.line_vec(p1, pos_2, t_c2, t_w)
		
		p1,left,t_l = pos_2, not left, (true_len - 3)/2
		
	elseif draw_type == 4 then
		left = false
	end
	

	
	-- draw_joint
	if p1 != p2 then

		-- TODO merge function
		local k_2, k = envstr.circ_intersect(p1,p2,t_l)
		
		if (left) k=k_2
		envstr.line_vec(p1,k,t_c,t_w)
		envstr.line_vec(k,p2,t_c,t_w)
	end
	
end

function circ_intersect(p1,p2,r)
	local d,mid_p=vec2_len(p2-p1),(p1+p2)/2
	local op=(p2-p1)*sqrt(r*r-d*d/4)/d
	local op2=vec2_new(op.y,-op.x)

	return mid_p+op2, mid_p-op2
end

function line_vec(v1,v2,col,thickness)
	for i=0, thickness or 0 do
		local vec = v_spin[i%4+1]*((i+3)\4)
		local v1_1,v2_1=v1+vec,v2+vec
		line(v1_1.x,v1_1.y,v2_1.x,v2_1.y,col)
	end
end



function Dply(ntt)

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
	p_expr = "0000002800000000"
	
	if timer_active(ntt, "hitshock") then
		p_expr = "0000442844000000"
	elseif vec2_len(ntt.vel) > 4 then
		p_expr = "0000002828000000"
	elseif btn(3) then
		e_pos_y += 1
	end

	if anim_c%(55) < 52 then
		print("\f7\^:"..p_expr, e_pos_x,e_pos_y)	end
	

end

function draw_ui()
	camera()

	rectfill(unstr"3,1,85,5,8")
	
	rectfill(4,2,player.stmn+4,4,12)
	rectfill(4+player.stmn,2,player.timers.hurt/4+4+player.stmn,4,7)
	fillp(0b1101101101111110.1)
	rectfill(85,2,85-player.stmn_h_dmg,4,11)
	fillp(0)
	
	rc()
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

function set_mus()
	mus_enabled=not mus_enabled

	music(-1)
	local s="music:off"
	if mus_enabled then
		s="music:on"
	end
	start_mus()
	menuitem(5,s,set_mus)
	return true
end

function start_mus()
	if mus_enabled then
		music(lvl_mus)
	end
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

v_spin = {vec2_right,vec2_down,vec2_left,vec2_up}

-- to copy, either do +vec2_zero or *1

function vec2_len(v)
	-- alternate way of getting hypotenuse by trigonometry
	-- avoids squaring, more accurate in almost all cases
	-- and does not break at very small or big values
	local v2, v2_c = v+vec2_zero, v.x
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

function empt()
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
function transfer_momentum(e1, e2, bnc, slipperiness, square_coll)
	-- normalized bc when offscreen with high diff it freaks out
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
	local v1_f,v2_f = v1_c*(e1m-e2m) + v2_c*2*e2m,  v1_c*2*e1m + v2_c*(e2m-e1m)

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
	local p_in = point+vec2_zero
	--extend terrain offscreen
	p_in.x = mid(0,p_in.x,l_border_x)
	p_in.y = mid(0,p_in.y,l_border_y)

	local point_max,point_min = p_in+vec2_new(rds,rds),p_in-vec2_new(rds,rds)

 	-- go over all tiles in rectangle range
	for j=point_min.y\8,point_max.y\8 do
		for i=point_min.x\8,point_max.x\8 do

			if fget(mget(i,j),0) then -- solid tile
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
		if not (other.ignore_physics or in_tbl(other, {ntt,ntt.parent,ntt.grabbed_e}) or (ntt.parent and other.ignS) or ntt == other.grabbed_e or (ntt.parent and other == ntt.parent.grabbed_e)) then
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
	mod_tabl2(tmp_ntt,"Etyp,stmn,rds,Iarm",{"tile",tmp_ntt.mass*20,3.5,2})

	tmp_ntt.stmn_l_t,tmp_ntt.g_i = tmp_ntt.stmn
	tmp_ntt.m_sprite[1]=t_dat
	tmp_ntt.mass/=6 -- 1 or 0.5, depending on tile (og is 6 or 3)


	-- fill bg: insert adjacent < or ^ bg tile
	local t_l,t_u,t_set = mget(tpx-1, tpy),mget(tpx, tpy-1), 0
	if (fget(t_u,0)) t_set = 2
	if (fget(t_u,3)) t_set = t_u
	if (fget(t_l,3)) t_set = t_l
	mset(tpx, tpy, t_set)


	add(entities, tmp_ntt)
	return tmp_ntt
end


function entity_to_tile(e)
	mset(e.pos.x\8, e.pos.y\8, e.m_sprite[1])
	remove_entity(e,true)
end


-->8
-- movement

-- NO TERRAIN CLIPPING
function unclip(entity,pos,rds, up_override, ntt_mul)
	local pos_t, rds_t = pos or entity.pos, rds or entity.rds
	local rds_e,is_exit,exit_v = rds_t * (ntt_mul or 1), false

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
	local coll_e, e, norm, dist = check_coll_ntts(entity, pos_t, rds_e)

	if coll_e then
		local m_v = norm*dist
		if (not sq_trn_coll(pos_t + m_v, rds_t) and not check_coll_ntts(entity, pos_t + m_v, rds_e)) return true, false, true, m_v, e
		return true, false, false, m_v, e
	end
	return false
end


function update_stand(entity)

	entity.is_stnd=false
	local down_pos = entity.pos+vec2_down

	if sq_trn_coll(down_pos, entity.rds) then
		entity.is_stnd=true
		return
	end

	if check_coll_ntts(entity, down_pos) then
		entity.is_stnd=true
	end
end

function explode_self(e)
	explosion(e.pos, explosions[e.explosion])
end

function explosion(pos, e_props)
	local radius, str, sf = unstr(e_props)


	local function get_expl_ntt(other)
		local dist = other.pos - pos
		-- no damage falloff! simpler and removes some jank from game
		expl_ntt = mod_tabl2({},"pos,vel",{pos,vec2_normalized(dist)*str + other.vel})
		return mod_tabl(expl_ntt, "mass,Iarm,Irss/1,0,1")
	end

	for ntt in all(entities) do
		if (vec2_len(ntt.pos-pos) < radius) impact(get_expl_ntt(ntt), false, ntt.pos-pos, ntt, true, true)
	end

	-- go over all tiles in rectangle range
	for j=pos.y-radius,pos.y+radius,8 do
		for i=pos.x-radius,pos.x+radius,8 do
			local t_pos = vec2_new(i,j)
			if fget(mget(t_pos.x/8,t_pos.y/8),0) then
				local tmp_ntt = get_tmp_trn_e(t_pos)
				if (vec2_len(t_pos-pos) < radius) impact(get_expl_ntt(tmp_ntt), true, tmp_ntt.pos-pos, tmp_ntt, true, true, rnd(3)>2)
			end
		end
	end

	particles(pos, {7, radius/2, sf, -radius/3, 3})
end

-- c smokes for props
function particle_delay(p,v,r,c,dc,t)
	circfill(p.x,p.y,r,c)
	if t > 0 then
		delay_timer(1,particle_delay,{p+v,v,r-dc,c,dc,t-1})
	end
end

function particles(pos, props, vel)
	local co,rd,sf,dc,ti = unpack(props)
	sfx2(sf)
	for i=1, 5 do
		particle_delay(pos+vec2_zero,vec2_new(rnd(2)-1,rnd(2)-1) + (vel or vec2_zero),rd, co, dc or 0.3, ti or 11)
	end
end


function lose_stmn(ntt, dmg)
	local envstr, _ENV = _ENV,ntt

	if stmn then
		local p_s=stmn
		
		stmn-=dmg
		if (stmn_h_dmg) stmn_h_dmg = max((stmn_l_t-stmn)/2,stmn_h_dmg)
		
		local total_dmg = p_s - stmn
		timers.hurt=total_dmg*4

		timers.hitshock = 12

		if Etyp=="enm" and stmn > 0 and total_dmg > 1 then
			envstr.text_box("\^o05a"..(stmn/stmn_l_t*100)\1 .."%",0,pos.x,pos.y,envstr.unstr"0,0,0,0,18")
		end

	end

end

function get_tmp_trn_e(pos)
	local px,py=pos.x\8,pos.y\8
	local ntt=spawn_entity(px*8+4,py*8+4,12)
	ntt.tile = mget(px, py)
	if fget(ntt.tile,1) then
		ntt.mass,ntt.g_i = 3
	end
	return ntt
end

function impact(entity, with_t, surface_dir, coll_e, no_sfx, no_sq_coll, no_convert)

	local prev_v1,prev_v2 = entity.vel+vec2_zero, coll_e.vel+vec2_zero

	local function get_nrg(v1,v2)
		return vec2_len(v1)^2*entity.mass + vec2_len(v2)^2*coll_e.mass
	end

	local slp,bnc = max(entity.slip, coll_e.slip), max(entity.bnce, coll_e.bnce)

	transfer_momentum(entity, coll_e, bnc, slp, not no_sq_coll)

	local impact=get_nrg(prev_v1,prev_v2)-get_nrg(entity.vel,coll_e.vel)
	local impact_1,impact_2=split_vector(impact, entity.mass, coll_e.mass)


	-- if broke terrain turn tmp tile to entity tile
	if with_t and vec2_len(coll_e.vel) > 0.5 then

		if not no_convert then
			coll_e.tile,coll_e.mass = 14+rnd(2)\1, 2.4
		end
		coll_e = tile_to_entity(coll_e)
		coll_e.vel *= 4
	end

	function coll_p(e,p,i,o)
		local cdmg = o.Cdmg
		-- MINIONS HAVE ENEMY TO "f" SO IT'S NOT THE TRUE BOOL BUT DOES EVALUATE
		if e.enemy and o.Etyp=="tile" and o.thrown then
			cdmg = 14
			lose_stmn(o, 22)
		end
		if (e.Etyp=="tile") cdmg=nil

		if cdmg then
			lose_stmn(e, cdmg)
			if (e==player) sfx2(-1)
			local cnt_vel=vec2_normalized(e.pos-o.pos)*(o.kb or 0)
			apply_momentum(e, cnt_vel)
		end

		if e.coll_func then
			e.coll_func(e, p, i, o)
		end
		if i >= e.Iarm then
			lose_stmn(e, i*i/2.5/e.Irss)
		end
	end

	coll_p(entity,prev_v1,impact_1,coll_e)
	coll_p(coll_e,prev_v2,impact_2,entity)


	local sf = 14
	if impact > 11 then
		sf=15
	end

	if impact > 2.5 and not no_sfx then
		sfx2(sf)
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

	if ntt.pos.y > y_l_l+160 and not ntt.parent then
		remove_entity(ntt)
	end

end


function move_entity(entity)
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
			entity.vel.x *= 0.6 + max(entity.slip, trn_slp)*0.4 -- friction
		else
			entity.vel.y += entity.grav
		end
	end

end

function tug(link)

	local e1,e2 = link.from, link.to
	local e2_pos = e2.pos
	if (link.to_ground) e2_pos = e2

	local diff = e2_pos - e1.pos

	local move_dist = vec2_len(diff) - link.len


	-- amount that entities need to move to remain in link range
	local move_need, do_move = vec2_normalized(diff) * move_dist, false

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

		if link.to_ground then
			e1.pos += move_need
			-- remove vel component towards ground
			e1.vel = recomp_mul(e1.vel, e1.pos - e2_pos, 0, 1)
		else
			-- the amount each entity needs to move
			local move_1,move_2 = split_vector(move_need, e1.mass, e2.mass)

			e1.pos += move_1*0.98
			e2.pos -= move_2*0.98

			-- equalize velocity components
			transfer_momentum(e1,e2, 0.1, 1)
		end

	end

end

-- rough iterative raycast with angling
function ray_coll(pos,vec,angle_range,entity,sticky)
	for i=1,3 do
		local t_vec = vec2_rotate(vec*(rnd()+0.15),angle_range*(rnd()-0.5))
		local t_pos = pos + t_vec
		local coll_land,with_t,out,away_vector,other_ntt = unclip(entity, t_pos, nil, true)
		if (coll_land and out and vec2_dot(t_vec,away_vector) <= 0) return true, t_vec, with_t, away_vector, other_ntt

		if in_tbl(mget(t_pos.x\8, t_pos.y\8), split"44,45") and sticky then
			return true, t_vec, true, vec2_up+vec2_zero, get_tmp_trn_e(t_pos)
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


	local prev_jump=jump_g
	envstr.mod_tabl(entity, "special_stand,grounded_mode,jump_g/false,false,false")

	-- proc move legs
	
	local stand_vec,max_dist,max_leg,max_stand_center = envstr.vec2_normalized(entity.leg_facing)*leg_len*1.25, stnd_height/2

	-- move target with highest distance to optimal target position (if outside tolerant distance)
	local st_pos,st_away,st_c = envstr.vec2_zero*1,envstr.vec2_zero*1,0

	for leg in envstr.all(m_l_legs) do
		stand_vec_l = envstr.vec2_rotate(stand_vec,leg.angle * envstr.tonum_flip(is_left))
		if (prev_jump)stand_vec_l.x+=vel.x*leg_len*0.9
		local stand_center = pos + stand_vec_l
		local dist = envstr.vec2_len(leg.t_pos - stand_center)

		if (dist > leg_len or envstr.anim_c%20==#m_l_legs) leg.t_active = false

		if envstr.timer_ready(entity,"jump_cooldown") then

			if not leg.t_active then

				local did, t_vec, with_t, away_vector, other_ntt = envstr.ray_coll(pos, stand_vec_l,leg_angle_range, leg,sticky)


				if did then
					stand_center = pos + t_vec + away_vector

					if (sticky) away_vector = envstr.vec2_up*1
					
					leg.surface_away,ground_entity,dist=envstr.vec2_normalized(away_vector),other_ntt,envstr.vec2_len(leg.t_pos - stand_center)
					
					if dist > max_dist then
						max_dist,max_leg,max_stand_center = dist,leg,stand_center
					end
					if dist <= leg_len*1.5 then
						leg.t_active = true
					end

				end

			end

			-- move legs to targets
			if leg.t_active then
				grounded_mode,jump_g=true,true
				envstr.move_towards(leg,leg.t_pos, leg_speed)

				st_pos+=leg.t_pos+leg.surface_away*stnd_height
				st_away+=leg.surface_away
				st_c+=1
				
				if envstr.vec2_len(vel) < 5 then
					if sticky then
						leg.vel*=0.75
					end
					if (leg.surface_away.y<0 and leg.is_stnd or sticky) special_stand = true
				end
				
			end
		end

	end

	-- assign new target - only if off cooldown and outside tolerance range
	if m_l_legs.cd <= 0 and max_leg then
		max_leg.t_pos,max_leg.t_active,m_l_legs.cd  = max_stand_center,true,leg_cooldown
	else
		m_l_legs.cd -= 1
	end

	if (st_away.y < -0.5) st_away.x = 0
	surface_away=envstr.vec2_normalized(st_away)


	if special_stand then

		vel.y *= 0.85

		local stand_p_lh = st_pos/st_c

		if crouch then
			stand_p_lh -= surface_away * 6
		else
			stand_p_lh += surface_away * (envstr.anim_c\48%2)
		end

		if not sticky then
			pos.y = pos.y*0.9 + stand_p_lh.y*0.1

			for arm in envstr.all(m_l_arms) do
				arm.vel*=0.95
				if envstr.vec2_len(arm.vel) < 0.15 and not armgrab then
					arm.special_stand=true
				end
			end

		end

	end

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

	local surface_normal,input_dir_l,jump_cooldown = ntt.surface_away, vec2_limit(ntt.input_dir), ntt.timers.jump_cooldown
	local input_dir_h = vec2_normalized(input_dir_l + vec2_up*0.03 + vec2_right*(tonum_flip(not ntt.is_left))*0.05)
	local hold_pos,jump_s,throw_str = ntt.pos + input_dir_h*ntt.arm_len,false,2.3


	-- grabbing ----

	if #ntt.m_l_arms > 0 then

		-- check if grab still valid
		if ntt.in_grab and get_first_link(ntt,ntt.grabbed_e) == nil then
			ungrab(ntt)
		end
		
		if ntt.in_grab then

			--redirect grabbed object's fire - can still hit me
			ntt.grabbed_e.shoot_dir=input_dir_h
		end
		


		local hp_clip,hp_with_t,hp_out,hp_dir,hp_coll_e = unclip(ntt,hold_pos,0.75,false,4)
		local hp_2 = hold_pos+(hp_dir or vec2_zero)

		for arm in all(ntt.m_l_arms) do
			arm.mass = 0.1
		end


		if b5 or ntt.on_ladder then
		
			for arm in all(ntt.m_l_arms) do

				local chosen_t = hp_2
				if hp_clip then
					ntt.vel *= 0.6 + trn_slp*0.4 -- wallslide
				end

				-- stop if grabbing wall panels
					if ntt.on_ladder then
						chosen_t,jump_s,arm.mass = ntt.ladder_pos,true,1.1
						arm.vel*=0.2
					end

					counter_mmnt((chosen_t-arm.pos)/64,arm,ntt)
					move_towards(arm,chosen_t, 1.5)
			end
		
		end

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
				end

			end

			-- try to grab
			if not ntt.in_grab and not ntt.grab_c then
			
				if hp_clip and not hp_coll_e.g_i then
					ntt.in_grab = true
					if hp_with_t then
						hp_coll_e = tile_to_entity(hp_coll_e)
					end
				end

				if ntt.in_grab then -- grab
					sfx(21)
					ntt.grabbed_e = hp_coll_e
					
					make_link(ntt,hp_coll_e,split("1," .. ntt.arm_len .. ",false,20,0,14,0,0,0"))
				end
			end


		else
			--throw if holding, else nothing

			if ntt.in_grab then

				sfx(22)
				local v = vec2_normalized(input_dir_h) * throw_str * tonum_flip(ntt.grabbed_e.template != 17)  -- grapple orb
				ntt.grabbed_e.vel *= 0.1
				counter_mmnt(v, ntt.grabbed_e, ntt)

				ntt.grabbed_e.timers.stun,ntt.grabbed_e.thrown,ntt.in_grab,ntt.grab_c=10,true,false,true
				delete_link(get_first_link(ntt,ntt.grabbed_e))

				-- delay collision swap so doesn't immediately clip in ntt
				delay_timer(5, function() 
					ntt.grab_c = false
					ungrab(ntt)
				end)
				
			end


		end

	end



	-- walking/air move ----


	local accel,vel_limit =  ntt.a_acc, ntt.a_max -- air drift

	if ntt.grounded_mode and surface_normal.y != 0 then
		accel,vel_limit = ntt.g_acc,ntt.g_max -- ground movement
	end
	if ntt.grounded_mode or b5 or ntt.on_ladder then
		update_right(ntt)
	end



	local pv_add = input_dir_l*accel

	if (input_dir_l.x == 0 and ntt.special_stand) ntt.vel.x *= 0.5

	if (not (ntt.flying or ntt.on_ladder or (ntt.special_stand and ntt.sticky))) pv_add.y = 0

	if vec2_dot(ntt.vel,pv_add) < 0 or vec2_len(ntt.vel) <= vel_limit then
		ntt.vel += pv_add
	end

	-- alignment direction
	local align_down,al_of,g_e=-vec2_up,ntt.vel*0.5,ntt.ground_entity
	if (g_e) g_is_ntt = g_e.Etyp != "tmp tile"
	-- jumping ----


	
	local side_mul,jump_str,input_dir_j,can_jump=0.7,ntt.jump_str,vec2_normalized(input_dir_l + vec2_up*0.7*tonum(input_dir_l.y<=0)),true


	if b4 and jump_cooldown <= 0 then

		local leg_pos,p_prevvel,j_sf = ntt.m_l_legs[1].pos,ntt.vel, 10
		local tx,ty = leg_pos.x\8,leg_pos.y\8

		-- 1 calculate jump consequences except velocity
		
		-- jump cases
		if ntt.grounded_mode and g_is_ntt then
		
			-- the titular drop kick
			lose_stmn(g_e, 24)
			j_ntt,j_sf = mod_tabl2({},"pos,vel,mass,Iarm,Irss",{ntt.pos,p_prevvel*2,ntt.mass,0,1}),12
			impact(j_ntt, false, -p_prevvel, g_e)

			surface_normal=vec2_normalized(ntt.pos-g_e.pos)
			align_down+=surface_normal*40
			
			if (g_e.Etyp=="enm") particles(g_e.pos, split"6,3,0,0.3,10",j_ntt.vel)
			
		-- ground - no jump fall damage parries
		elseif ntt.jump_g and vec2_dot(ntt.vel,surface_normal) > -3 then
			
			if surface_normal.x != 0 then
				surface_normal*=0.8
				side_mul = 0.4
			end
			
			for leg in all(ntt.m_l_legs) do
				if leg.t_active then
					particles(leg.t_pos,split"7,1.6,0,0.5,6", surface_normal)
				end
			end
			
		elseif jump_s then -- panelgrab


		elseif in_tbl(mget(tx,ty), {44,45}) then -- panelhop
			mset(tx,ty,45)
			j_sf,side_mul=13, 0.43
			delay_timer(4,function() mset(tx,ty,44) end)
			particles(leg_pos,split"3,2.6,0,0.4,8",p_prevvel)

		else
			can_jump=false
		end

		

		if can_jump then
			if ntt.on_ladder then
				mset(ntt.ladder_pos.x\8,ntt.ladder_pos.y\8,44)
			end

			sfx2(j_sf)
			
			-- 2 store jump state
			for e in all(ntt.all_ntts) do
				e.st_vel = recomp_mul(e.vel, surface_normal, 0.1, side_mul)
			end
			ntt.timers.jump_cooldown,jump_cooldown,ntt.st_surf,ntt.on_ladder=8,8,surface_normal,false
		end


	end
	
	-- 3 apply jump & calculate new velocity 
	if jump_cooldown == 8 or jump_cooldown >= 4 and vec2_len(input_dir_l) > 0.1 then
		local st_surf = ntt.st_surf

		if (vec2_len(st_surf) == 0) st_surf = input_dir_j
		
		local jump_vel = (recomp_mul(input_dir_j, st_surf,0.1,0.6) + st_surf)*jump_str
		update_right(ntt)
		
		for e in all(ntt.all_ntts) do
			e.vel = e.st_vel + jump_vel
		end
		
	end
		
	if ntt.grounded_mode then
		align_down.x-=al_of.x
	else
		if b5 then
			align_down-=input_dir_l*2.5
		elseif jump_cooldown==0 then
			align_down+=al_of+vec2_up*0.5
		else
			align_down-=al_of*0.5
		end
	end

	ntt.leg_facing = ntt.leg_facing*0.8 + align_down*0.2
	ntt.facing = -vec2_limit(ntt.leg_facing)

end


function Uply(player)
	move_humanoid(player)
	
	-- regen stamina
	if (player.stmn < player.stmn_l_t-player.stmn_h_dmg and player.timers.hurt <= 2) player.stmn += 0x0.28

	mod_tabl2(player,"input_dir,crouch,armgrab",{
				vec2_left  * tonum(btn(0))
				+ vec2_right * tonum(btn(1))
				+ vec2_up    * tonum(btn(2))
				+ vec2_down  * tonum(btn(3)),btn(3) and player.special_stand,false})

	move_control(player, btn(4), btn(5))

	local i=1
	for leg in all(player.m_l_legs) do

		local l_link = get_first_link(player,leg)
		local l_l_len = l_link.true_len

		if not player.grounded_mode then

			move_towards(leg, player.pos + vec2_limit(player.leg_facing)*player.leg_len, 3/i)

			l_l_len *= 0.9
			if (timer_active(player,"jump_cooldown")) l_l_len /= i

		end

		l_link.len = l_l_len

		i+=1
	end

end



-->8
-- level managment

function lvl_arr(index)
	local arr = split(split(lvls_info_2[loaded_lvl_index],"⬅️")[index],"`")
	if (#arr <= 1) return {}
	return arr
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

	mod_tabl2(_ENV, "map_pos_x,map_pos_y,ld_l_size_x,ld_l_size_y,lvl_mus,layers_active", lvl_arr(2))

	-- clear map
	memset(0x8000, 0, 0x4000)
	
	for j=0, ld_l_size_y-1 do
		for i=0, ld_l_size_x-1 do
			draw_tile(mget0x20(map_pos_x+i,map_pos_y+j), i, j)
		end
	end

	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1

	pal(unpack_pal(lvl_maininfo(12)), 1)
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
		if (rnd(20) > 19) s1 ^^= 0b1
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

-->8
-- enemy ai and inits

function init_roped(e)
	make_link(e,e.pos + vec2_new(e.rX,e.rY), split(links[e.rope]), e.rope_e)
end

function Uenm(enm)

	update_right(enm)

	mod_tabl2(enm,"input_dir,prevstand,special_stand,outl",{vec2_zero+vec2_zero, enm.special_stand, false,0})
	if timer_ready(enm, "stun") then
		-- passive ai
		_ENV[enm.ai_p](enm)

		if enm.active then
			enm.outl=3
			if (enm.timers.gun<9 and anim_c%4>1) enm.outl=10
			
			if (player.grabbed_e != enm) enm.shoot_dir=player.pos - enm.pos
			local dist = vec2_len(enm.shoot_dir)

			if (dist > enm.rngF) enm.input_dir=enm.shoot_dir+vec2_zero
			if (dist < enm.rngN) enm.input_dir=-enm.shoot_dir
			
			if (enm.horizontal) enm.shoot_dir.y=0
			
			-- active ai
			_ENV[enm.ai_a](enm)
			if timer_ready(enm, "gun") then
				fire_gun(enm)
			end
		else
			enm.timers.gun=enm.gun[1]/2
		end
	end

	-- late update so doesn't bug out when immediately spawning in range
	local dist = vec2_len(enm.pos - player.pos)
	if dist < enm.actN or alert then
		enm.active=true
		if (enm.procalert) alert = true
	end
	if dist > enm.actF then
		enm.active=false
	end
	
	if (enm.stmn/enm.stmn_l_t < 0.35 and anim_c%12==0) particles(enm.pos, split"6, 2.4,0,0.2,8", vec2_up*0.5)

end

-- passive ai components
function AIPstbl(enm)
	if enm.prevstand and not enm.active then
		enm.special_stand = true
	else
		move_humanoid(enm)
	end
end

function AIPfly(enm)
	enm.vel *= 0.9
	enm.special_stand = true
end


-- active ai components
function AIAturr(enm)
	local l = get_first_link(enm)
	if l then
		enm.pos = enm.pos*0.9 + (l.to - vec2_new(enm.rX,enm.rY))*0.1
		AIPfly(enm)
	end
end

function AIAfllw(enm)
	move_control(enm,false,false)
end

function AIAhvr(enm)
	if (enm.pos.y - player.pos.y > -50) enm.input_dir.y = -0.75
	AIAfllw(enm)
end

function fire_gun(e)
	mod_tabl2(_ENV,"cldwn,p_t,spd,sf,angl,dur,p_global,b_amount,b_delay,b_angl,nxt", e.gun)
	sfx2(sf)
	local proj = spawn_entity(0,0,p_t,e)
	if (e.is_left) angl = -angl
	proj.vel+=vec2_rotate(vec2_normalized(e.shoot_dir),angl)*spd
	if p_global=="tru" then
		proj.parent=nil
		add(entities, proj)
		proj.pos+=vec2_normalized(proj.vel)*e.rds*1.7
	else
		add(e.all_ntts, proj)
	end

	if (dur > -1) delay_timer(dur,remove_entity,{proj})

	if b_amount > 1 then
		e.gun[8] -= 1
		e.timers.gun = b_delay
		e.gun[5] += b_angl
	else
		e.gun=split(guns[nxt])
		e.timers.gun=e.gun[1]
	end

end

function Umsl(ntt)
	if not ntt.thrown then
		ntt.vel *= 0.97
		ntt.vel += vec2_normalized(player.pos - ntt.pos)/3.6
	end
end

function Usgn(ntt)
	if sq_sq_coll(ntt.pos, ntt.rds, player.pos, 1) then
		delay_timer(1, text_box, split(ntt.text_box,"⬇️"))
	end
end

-->8
-- data

-- the colossal ominous intimidating level data string
lvls_info_2 = split("task 01` 2` 28`58` 328`-32`   the construction site  `finally, a day where our\n  name matches our service`/`from: hq\n\nsome construction company's\nbots went haywire -\nthey're hoping we could\n'clean' up the situation\nbefore the public notices\nand it turns into a mess\nof paperwork.\nPERFECT OPPORTUNITY FOR \nYOUR 'SKILLS' :] ⬅️0`23`24`4`7`1`0`0`0`0`0`2`1`2`7`3`0x0000.0800`48`8`1`0`1`0`1`0`4`0x0000.2000`64`2`0`0`0`0⬅️4`520`52`rY/12`5`659`42`rX,rY/-11,4`13`404`44`text_box/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️4⬇️44⬇️42⬇️2⬇️1⬅️115`61`\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!`258`78`\f2\^o150\^:00130e3a0a190800`262`86`\f2\^o068\^:84ef565692df9249\|e\^o0d0\^:e058517575edeb91`328`66`\f2\^o0ff🅾️\n\n\|c \-f+\n\n\|c\^:10387c1010100010➡️1-2` 3` 6`76` 0` 0`1: roadblock``/`⬅️23`22`16`5`8`3`0`0`0`0`0`2`2`2`6`3`0x0000.0800`48`12`1`0`1`0`1`3`5`0x0000.2800`-72`8`0`0`0`0⬅️5`104`66`procalert/true`4`154`109`/`4`278`52`rope,rX,rY/4,-16,0`5`464`34`rX,rY/16,0`7`398`124`/⬅️302`45`\f2\^o0ff❎\|e\n\ng\|fr\|fa\|fb`286`49`\f2\^o0ff\^:00008064320f0204		\|e\^:0000070c90a0c0f0➡️1-3` 4` 6`290` 0` 0`2: magnetizing yourself``/`⬅️0`12`14`10`8`3`0`0`0`0`0`2`2`2`6`3`0x0000.0800`48`16`1`0`1`0`1`3`5`0x0000.2800`-170`8`1`0`0`0⬅️13`51`291`text_box/\fae.m. wall\nusage manual\n\n❎-attach\n🅾️-release⬇️false⬇️22⬇️246⬇️58⬇️42⬇️2⬇️1`13`148`214`text_box/\fa\-dnotice to workers:\njumping directly\non the panels is\nstill considered\na workplace hazard\nregardless of how\n'sick' it may look⬇️false⬇️100⬇️164⬇️88⬇️50⬇️2⬇️1`4`78`154`rY/-16`15`20`72`/`7`80`90`/`5`240`51`next_e,rX,rY/11,-16,8`4`326`69`rX,rY/-12,12`6`410`138`actN,procalert/30,true`7`408`96`procalert,actN/true,40⬅️➡️1-4` 5` 4`110` 60`80`3: don't look down``/`⬅️14`12`16`6`8`3`0`0`0`0`0`2`2`1`7`3`0x0000.1000`-102`36`1`0`0`0`0`10`4`0x0000.2000`-40`36`0`0`0`0⬅️5`79`76`rY/-16`7`240`10`procalert/true`6`274`44`next_e,procalert/11,true`6`432`75`Btyp,procalert/5,true`7`390`6`next_e/11⬅️➡️1-5` 6` 4`72` 60`80`4: mayhem square``/`⬅️30`12`16`7`8`7`0`0`0`0`0`3`2`0`3`3`0x0000.1000`208`-4`1`0`0`0`0`12`5`0x0000.2000`-140`-16`0`0`0`0⬅️11`108`60`/`16`146`110`rX,rY/16,0`7`272`110`rngN/25`6`302`148`next_e,Btyp,procalert/11,5,true`5`396`132`rX,rY/-16,0`7`436`80`/`7`370`44`/`16`232`40`rX,rY,gun,procalert/-12,-12,4,true⬅️➡️task 01` -1` 4`116` 60`80`5: the small issue in question``/`⬅️57`12`12`6`8`7`0`0`0`0`0`3`2`1`7`5`0x0000.1000`-48`-10`1`0`0`0`0`10`5`0x0000.3000`-242`4`1`0`0`0⬅️11`108`48`/`8`250`104`boss/true⬅️➡️task 02` 8` 48`88` 48`0`  the hijacked transport  `you did bring a\n  parachute, right?`y_l_l/64`from: hq\n \nsame guys as yesterday,\nthis time it's one of their\nautomated cargo transports.\nmakes you wonder what\nthey're doing to get rogues\ntwice in a row, but hey as\nlong as they're paying i'm\nnot complaining. ⬅️39`19`15`5`24`7`0`0`0`0`0`0`2`1`4`2`0x0000.0800`-48`32`1`0`30`-3`1`6`5`0x0000.1000`32`-26`1`0`45`-6⬅️4`205`99`procalert/true`7`230`57`rngN/16`16`150`54`rX,rY/12,12`16`315`20`rX,rY,actF/12,12,80⬅️➡️2-8` 9` 10`88` 48`0`1: what a blast``/`⬅️0`26`12`4`28`5`0`0`0`0`0`1`1`2`7`3`0x0000.1000`0`-26`1`0`30`0`2`7`4`0x0000.1000`32`68`1`0`60`0⬅️13`76`84`text_box/\fato maintenance staff:\nplease only \fcgrab\nheat-seeking bolts\fa\nif absolutely\nnecessary⬇️false⬇️36⬇️40⬇️94⬇️40⬇️2⬇️1`18`200`68`rope,rX,rY,next_e/1,0,16,11`7`295`50`/`18`360`75`rope,rX,rY/1,0,16⬅️➡️2-9` 10` 20`233` 48`0`2: hang in there``y_l_l/256`⬅️47`19`12`11`28`5`0`0`0`0`0`1`1`2`7`3`0x0000.1000`0`-26`1`1`30`-3`2`7`4`0x0000.1000`32`68`1`1`60`-6⬅️17`57`233`rope,rX,rY/6,76,-20`16`213`238`rX,rY/12,-12`17`279`266`rope,rX,rY/8,0,-50`17`306`153`rope,rX,rY/8,0,-40`16`308`183`/`16`309`66`rX,rY/14,0⬅️➡️2-10` 11` 10`150` 48`0`3: nice weather up here``/`⬅️14`17`15`6`28`13`0`0`0`0`0`4`12`2`0`3`0x0000.3000`0`10`1`0`30`0`2`0`6`0x0000.4000`32`0`1`0`60`0⬅️18`100`88`next_e/11`16`164`60`rX,rY,next_e/12,-12,11`17`232`119`rope,rX,rY/7,0,-120`16`272`69`rX,rY,next_e/0,-14,11`17`380`108`rope,rX,rY/6,79,-10`18`456`88`/`15`384`28`/⬅️➡️2-11` 12` 76`72` 48`0`4: broken access bridge``/`⬅️28`19`18`4`28`13`0`0`0`0`0`4`12`2`0`3`0x0000.1000`0`14`1`0`30`0`2`3`5`0x0000.2000`0`18`1`0`60`0⬅️18`216`72`next_e,procalert/11,true`16`172`20`rX,rY/-12,12`6`330`44`gun,Btyp,next_e,actN/9,5,11,55`18`534`98`rope,rX,rY,next_e/1,0,16,11`16`499`75`rX,rY,next_e,procalert/16,0,11,true⬅️➡️task 02` -2` 8`128` 48`0`5: annoyingly out of reach``y_u_l/-96`⬅️46`12`11`7`28`13`0`0`0`0`0`4`12`2`7`3`0x0000.1000`0`14`1`0`30`0`2`3`5`0x0000.2000`0`18`1`0`60`0⬅️22`304`72`boss/true`17`316`88`rope,rX,rY/6,0,-80⬅️","➡️")

-- levels present in the menu
m_index,start_lvls=0,split"1,2,3,4,6,7,12"

-- list of almost all entity types
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

	-- TODO more checks if missed entity shifts

	12: MISC: tmp tile - 6x the mass to enable proper bounces
	13: MISC: sign - ignores physics, displays a text box on player coll (text is added as extra in level)

	14: PROJECTILE (lvl1): small with knockback
	15: ITEM: trinket

	16: ENEMY (lvl1): turret with all-dir targeting

	17: MISC: orb - for grabbing
	18: ENEMY (lvl2): missle base
	19: PROJECTILE (lvl2?): sawblade
	20: PROJECTILE (lvl2): missle
	21: PROJECTILE (lvl1?2?): medium projectile

	22: BOSS (lvl2): big aircraft
	23: BOSS: boss2 drone minion
	
	24: ENEMY TEMPLATE
]]

-- features: common array{"preset", radius, mass, metasprite, init function (name), update function, draw function}
-- & extra properties {key1,key2/val1,val2}
-- inner arrays are split with :

-- metasprite format: sprite index (upper left), x size, y size, anim frame len, anim total frames
-- NOTES: masses lower than 0.1 bug link-related movements
-- enemies with flying ais need "flying" prop in order to move up/down

ntt_types = split([[0,3.5,0.4,176:1:1:99:1,empt,empt,empt|
0, 1,  0.6,160:1:1:99:1,empt,Uply,Dply|Btyp,stmn,stmn_h_dmg,Iarm,Irss,slip,Etyp,in_grab,grabbed_e,col,outl/2,80,0,5,4,0.99,player,false,nil,12,9
0, 0.5,0.1, -1:1:1:99:1,empt,empt,empt|slip/0.8
24,5,  0.5,164:1:1:99:1,Ienm,Uenm,Dntt|rope,rX,rY,horizontal/1,0,14,t
24,5,  0.5,166:1:1:99:1,Ienm,Uenm,Dntt|rope,rX,rY,horizontal,gun/2,0,16,t,2
24,5,  0.8,165:1:1:99:1,Ienm,Uenm,Dntt|Btyp,stmn,gun,ai_a,rngF,Irss/3,100,4,AIAfllw,25,3
0, 6,  0.3,180:1:1:2: 3,Ienm,Uenm,Dntt|Btyp,stmn,Iarm,gun,ai_p,ai_a,enemy,smok,flying,rngF/1,50,2,1,AIPfly,AIAfllw,true,1,true,35
24,14, 5,  170:2:2:99:1,Ienm,Uenm,Dntt|Btyp,stmn,Iarm,gun,ai_a,smok,rngN,rngF,spr_size,actN,actF,g_i/4,175,15,6,AIAfllw,5,35,40,16,55,2000,t
0, 3.3,0.5,167:1:1:99:1,empt,empt,Dntt|Cdmg,grav,smok,stmn,bnce/10,0,3,0,0.8
0, 3.5,0.5,167:1:1:2: 2,empt,empt,Dntt|smok,stmn,ignS,break_func,explosion/3,0.01,true,explode_self,1
0, 2,  0.1,176:1:1:99:1,empt,Uitm,Dntt|item,amount,smok,ignS/5,25,2,true
0, 4,  6,  14: 1:1:99:1,empt,empt,Dntt|Etyp,smok,g_i/tmp tile,1,t
0, 9,  2,  244:1:1:99:1,empt,Usgn,Dntt|ignore_physics,d_o/t,1
9, 3.5,0.7,167:1:1:99:1,empt,empt,Dntt|Cdmg,kb/7,0.7
0, 3,  0.1,246:1:1:6: 3,empt,Uitm,Dntt|item,smok,ignS/4,4,true
24,4,  0.5,166:1:1:99:1,Ienm,Uenm,Dntt|rope,rX,rY,horizontal,gun/2,0,16,t,9
0, 3.5,0.4,241:1:1:99:1,empt,empt,Dntt|/
24,7.5,6,  161:1:1:99:1,Ienm,Uenm,Dntt|Iarm,gun,rngF,spr_size,horizontal,actN,actF,g_i/0.2,10,90,16,true,70,130,t
0, 4,  0.3,183:1:1:1: 3,empt,empt,Dntt|Cdmg,kb,grav,smok,stmn,bnce,ignS/12,0.5,0.05,3,90,0.95,true
0, 2  ,0.4,168:1:1:4: 2,empt,Umsl,Dntt|smok,stmn,ignS,break_func,explosion,grav/3,0.3,true,explode_self,2,0
9, 3.2,0.5,167:1:1:99:1,empt,empt,Dntt|Cdmg/20
24,9,  5  ,172:2:1:99:1,Ienm,Uenm,Dntt|Btyp,spr_size,ai_p,ai_a,actN,actF,rngN,rngF,gun,stmn,horizontal,smok,flying,Iarm,g_i/6,16,AIPfly,AIAhvr,110,2000,0,40,11,125,true,5,true,0.2,t
7, 6,  0.4,180:1:1:2: 3,Ienm,Uenm,Dntt|stmn,enemy,next_e/60,f,11
0, 5,  0.5,164:1:1:99:1,Ienm,Uenm,Dntt|Btyp,stmn,Iarm,gun,ai_p,ai_a,enemy,smok/1,60,2,1,AIPstbl,AIAturr,true,1]],"\n")


-- body info for complex/limbed entities
--[[
1: box (no limbs), air move ok - basic drone
2: humanoid
3: tripod spider - slow
4: big walker
5: bipod spider (like tri but less cpu intensive)
6: slow drone?
]]

-- sticky_walk, grnd_accel,air_a,g_max_spd,a_m_s,jump, leg_len,arm_len,stand_height, leg speed,leg group cd, max leg target rotation,
-- limb info at 13+th array slot:
-- entity type, limb type (a/l arm or leg), angle, link array index, link extraprops
ntt_b_types = split([[false, 0.15,0.15,4,4,0, 18,1,20, 3,3,0.01
false, 0.6,0.15,2.28,1.5,2.23, 8.7,5,7.5, 3,3,0.225,  3,l,0.015, 10,/,  3,a,0.02, 9,/,  3,l,-0.015, 10,d_o/3,  3,a,-0.02, 9,d_o/3
true, 0.15,0.05,1.5,1,0, 18,1,12, 4,6,0.2,  3,l,0, 11,/,  3,l,0.3, 11,/,  3,l,0.6, 11,/
false, 0.3,0.05,1.1,1,0, 35,1,35, 4,16,0.15,  3,l,0.04, 12,/, 3,l,-0.04, 12,/
true, 0.15,0.2,1.5,1,0, 20,1,19, 4,6,0.2, 3,l,0, 11,/, 3,l,0.5, 11,/
false, 0.14,0.14,1.5,1.5,0, 18,1,20, 3,3,0.01]],"\n")

--[[
1:standard
2,3:area burst sequence (x4, x4)
4:lvl1 bomb
5:sawblade
6,7,8:boss 1 sequence(x3 spread, x3 bomb, x8 area burst)
9:standard burst
10:missle
11,12:boss 2 sequence(x3 slow missles, downward storm,  x1 saucer)
]]
-- cooldown,projectile entity,p speed,fire sfx,angle,p lifetime,is global,burst amount,burst delay, burst angle shift,next gun
guns = split([[45,9,2.5,18,0,60,fls,1,1,0,1
55,9,2,18,0,60,fls,4,1,0.25,3
55,9,2,18,0.125,60,fls,4,1,0.25,2
65,10,3,11,0,60,fls,1,1,0,4
60,19,3,20,0,150,tru,1,1,0,5
70,14,2.25,18,-0.03,60,fls,4,7,0.01,7
70,10,3,11,-0.11,60,fls,3,10,0.09,8
90,14,2.25,18,-0.1,40,fls,16,2,0.11,6
60,9,2.5,18,-0.01,60,fls,3,8,0.01,9
65,20,3,11,0,120,tru,1,1,0,10
100,20,1,11,0.25,150,tru,3,40,0.1,12
75,23,3,13,0.35,225,tru,1,10,0.5,13
120,9,3,18,0.225,70,fls,14,4,0.002,11]],"\n")

-- 1-col, 2-radius, 3-sfx (0 if none), [ 4-decay rate ], [ 5-time ]
-- standard break, hp pickup,  projectile collide, item pickup, boss explode
smokes=split([[14, 3.5,16
12,3,8
7, 2.5,0
12,3,8
7,8,-2,-4,7]],"\n")



-- 1 directional turret joint
-- 2 standard machine joint
-- 3 longer machine
-- 4 easy break (TODO maybe remove)
-- 5 very long (also maybe remove)
-- 6 super long, unbreakable (swing)
-- 7 swing, even longer
-- 8 swing, shorter
-- 9 playerlimb - arm
-- 10 playerlimb - leg
-- 11 enemylimb - spiders
-- 12 enemylimb - big walker
-- link_type (0-keep at distance, 1-keep close, 2-keep far), link_len, to_ground, link_strenght, draw_type (1-line,2-joint,3-legjoint,4-noflip joint), col, width, draw order, outline color (0 is none)
links = split([[1,20,true,1,2,14,2,2,0
1,20,true,1,4,14,2,2,0
1,28,true,1,4,14,2,2,0
1,20,true,0.5,4,14,2,2,0
1,38,true,2.5,4,14,2,2,0
1,80,true,0,4,14,2,2,0
1,120,true,0,4,14,2,2,0
1,50,true,0,4,14,2,2,0
1,5,false,0,2,12,0,2,9
1,8.7,false,0,3,7,0,2,9
1,19,false,0,2,14,2,2,0
1,45,false,0,2,14,12,2,0]],"\n")

-- radius, str, sfx
-- small, medium
-- be VERY CAREFUL with the str val
explosions = split([[11,7,7
15,7.5,7]],"\n")

-- player hurt noises, giga explosion
ex_sfx = split"\as2v2i6g#3<d4x5c4i0x4c4x0c#4g#3g#2x3c#2,\as4v6i0x3f#2<i6x1g#1i3x0f0i6x3<a2x0>a3x3g#3<d#3a#2g#2<c2g2i3x3e1x0i6b1x3i3c#1x0i6g#1<x3i3a#0i6d#1d1i3g#0v1g#0i6c1c1b0i3g0f#0f#0f0e0d#0c#0c0c0"


-- storable in map maybe
palettes = split[[
	13,6,9,   141,141,0,7, 0,129,129,129,    140,129,133,134, 141,
	13,6,9,   0,129,0,7,   130,141,141,7,   12,141,133,134, 141,
	143,15,10,  142,143,0,7, 130,2,136,8,  12,2,13,6, 142,
	143,15,10,  128,130,0,7,   130,136,8,143,   12,136,13,6, 142,

	6,7,9, 0,129,0,7, 130,2,2,14, 12,2,133,134, 13,
	2,14,10,  128,130,0,7,   130,136,142,15,   12,136,13,6, 130,
	136,142,10,  128,130,0,7,   130,136,14,15,   12,136,13,6, 2,
	136,142,10,  2,136,0,7,   0,128,130,2,   12,128,13,6, 2,

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
00000000555555545555555444444444aabbbaadba999999baabbbabbaaabbbbb984489aaaaaaaaabbbbbabb8b8b8b8b000000005554555477777e7877787778
00000000555555445444444455555554b99999d8a988889999999999998ba9a9bb8448baa999999b8b8998b8aaaaaaaa00000000555455547ee78788eee88e88
00000000544444445444444454444444b99dddd89999999999999999998a9999b9b99b9aa900000b98b88b89bbbbbbbb00000000555455547ee788787877e888
00000000555555445444444454445454b9ddddd8a888888999999999998a9999b98bb89aa900000b449bb944aba88aba00000000444444447e78eee8e8e888ee
00000000544444445444444454454454a9ddddd8999999999999999999899999b98bb89aa900000b449bb9448abaaba800000000555455547788eee8778e7788
00000000555555445444444454444454a9ddddd89988889899999999998a9999b9b99a9aa900000b98b88a898a8bb8a8000000005554555478e78ee8ee888ee8
00000000444444445444444454444454adddddd89999999899999999988a9999bb8448aaa900000b8b8998a8aabaabaa00000000555455547eeee8e878eeee88
00000000555444444444444444555554d888888d9999988899999999888aa988b984489aabbbbbbbaaaaaaaaab8998ba0000000044444444e888888e8ee88888
11111111222222225555555544444444aaa999999999999a9a9a9a9a88888888ff999fee8444445ababbbbba9b9b9b9b54005554444444445555555589889988
11111111222222225555555544444444a9999999999999998989898988888888fe9999ef8444454ab9aaaa9a8a8a8a8a540550545555555554444445489aaaa9
11111111222222225555555544444444bbaa9aa999999aaa8888888888888888eef999ff8444444ababaabaabbbbbbbb54550054444444445500005544899999
11111111222222225555555544444444baa9999999999a998998999988888888eff99ffe8444444aaaaaaaa999aaaa9955500054555555550550055044489999
11111111222222225555555544444444a9999999999999998888888888888888ff999fee8444444abaaaaaa9888aa88855500054444444440055550044448998
11111111222222225555555544444444ba9aa9999999a9aa8888888888888888fe9999ef8444444aaabaaba8888aa888545500545555555500055000554448aa
11111111222222225555555544444444b9999999999999998888888888888888eef999ff8444444aa9aaaa9888aaaa8854055054444444445555555544444489
11111111222222225555555544444444a999999999999aaa8888888888888888eff99ffe9aaaaaaa888888889999999954005554555555554444444445554448
44444444444444444554455455555555baa9baa99aa99999bba9bbbabb9bbbb9bbbabbba99888989ba9bba9b55455545fffffffe7777777ebbbad999bbbabbba
555545554555445544554455545544559999999999999999baa9baa9aa9baaa9baa8baa888888888aa9bba9b55455545feffeefe7377337ebaa8d999baa8baa8
44444444444444445445544554455445a9baa9aa999999aabaa9a999999a9999baa8baa899999999ba9bba9b55455545fffeeffe7773377ebaa89999baa8baa8
554555455445544555445544554455459999999999999999aaa999999d999dd9a888888888899988ba9bba9b55455545ffeefffe7733777ea88899dda8888888
44444444444444444554455455544555baa9aaa9aaa9aa999999999999999dd9dddd9ddd99999999ba9bba9b55455545feeffefe7337737eddddbbbabbbaddd9
4555455545444555445544555455445599999999999999999999999999999999d9d99d9d99999999ba9bba9b55455545feffeefe7377337ed9ddbaa8baa8dd99
44444444444444445445544554455445a9aaa9aa999aa9aa999999999999999999999d9999999999ba9bba9b55455545fffffffe7777777ed99dbaa8baa89d9d
55545554555455545544554455555555999999999999999999999999999999999999999999999999ba9bba9b55455445eeeeeeeeeeeeeeee99998888a888999d
05000505050000050000000500000005bbbbb8bbbbbbbbbb99999999999999999999999999999999aa9bba9bbba9a99a88888888554444449999bbba444fe844
0500050505000005555555550000005599b98bb999b999b999999999999999999999999999999999ba9bba9ba222222589999999554444559999baa85557e855
550055550500050505050505000005059988b9899989998999999999999999999dd99d9d99999999ba9baa9b9227222589899989554444449999baa8444fe844
555005550500050550505055500000559998b999888888889999999999999999dddddddd99999989ba9bba9b9272222589999999554444459999888877f7f7f7
050005050500050505050505050005059998b9998b9999b89999999999999a99bbbabbba88888888ba9bba9b922222258999999955444444bbbaddd9eeefeeee
050005050500050555555555555555559998b9998899998899999999a99aaaa9baa8baa899989999ba9bba9ba22222258989998955444455baa8d9d98887e888
05000555550055055555555555555555888888888b9999b899999999999a9999baa8baa888888888ba99aa99bbaaa99a8999999955444444baa8d999444fe844
5500050555000505555555555555555599988888888888889999999999999aaaa88888888888888899889988999999998888888855444445a888999d555fe854
aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b9b9b9b955544444aaaaaaaaaaaaaaaa
a000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a898989855544444a000000aa000000a
a0000a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099a999a955544544a0000a0aa0000a0a
a000a00a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999999a44445554a000a00aa000a00a
a00a000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999999955445555a00a000aa00a000a
a0a0000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999999955444554a0a0000aa0a0000a
a000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999999954544444a000000aa000000a
aaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999999944444444aaaaaaaaaaaaaaaa
aaaaaaaa11111111aaaaaaaaaaaaaaaa00000000000000000000000000000000aaaaaaaa00000000000000000000000000000000000000000000000099999999
a000000a11010111a000000aa000000a00000000000000000000000000000000a000000a00000000000000000000000000000000000000000000000099999aa9
a0000a0a01101011a0000a0aa0000a0a00000000000000000000000000000000a0000a0a00000000000000000000000000000000000000000000000099999aa9
a000a00a10110110a000a00aa000a00a00000000000000000000000000000000a000a00a00000000000000000000000000000000000000000000000099999999
a00a000a01010001a00a000aa00a000a00000000000000000000000000000000a00a000a00000000000000000000000000000000000000000000000099a99999
a0a0000a00100000a0a0000aa0a0000a00000000000000000000000000000000a0a0000a0000000000000000000000000000000000000000000000009999aa99
a000000a00000000a000000aa000000a00000000000000000000000000000000a000000a00000000000000000000000000000000000000000000000099999999
aaaaaaaa00000000aaaaaaaaaaaaaaaa00000000000000000000000000000000aaaaaaaa00000000000000000000000000000000000000000000000099999999
5544554554545544545555455545545400000000000000005b5bb5b55b55bb5b0000000099999999bb9aaa99bbb99a99aaaaaaaaaaaaaaaa8bbbaa9aaaba9988
545454554554545454555455454544540000000000000000bbbbbbbbbbbbbbbb00000000999999a9baa9999bbaaaa99ba000000aa000000abaa9999999999998
554445455455445454555455454545550000000000000000abbbaababbababbb00000000999999a9aa99bb99aaaaa9baa0000a0aa0000a0aba99a999a9999998
454554454554545555555545544545450000000000000000ababaa9aabaabaab0000000099a99999999baaa9aaaa9999a000a00aa000a00ab999999999999999
5454544454554554554555445455554500000000000000009a9aa9a9aaa9ba9a000000009a999999bb99aa9b99999bbba00a000aa00a000aa9a9999999999999
454544454545445555455454555545550000000000000000a99b9aa9a9a99a9a000000009a999999aaa999bbaa9bbbaaa0a0000aa0a0000aa999999999999999
454454544545445455545455455545450000000000000000a9ab9a9aa99a99a90000000099999999aa9bbb9aa99baaaaa000000aa000000a9999999999998999
45445454554554555554555555555545000000000000000099a9999a999999a90000000099999999a9bbaaa99999aaaaaaaaaaaaaaaaaaaa8999999889999998
005400540000000500004004040045000000000000000000aaaaaaaa99a999990000000099599999bbb99b999999b9aa00000000000000009999999999999999
055440454000005440540040440450400000000000000000a000000a9a99a9990000000095595999bbaabaabbb9bba9900000000000000009999999999999998
045440054050454504050054450554050000000000000000a0000a0a99999a990000000059455959aaa9aaabbaa9a99b00000000000000009999999999998898
054044544540455005450504500504540000000000000000a000a00a9999a9a90000000059455955aaa99a999a9b999900000000000000009999999999999998
454040454454450045454545545054550000000000000000a00a000a9a99a9aa0000000055454459b9aa99bbb9baa9bb00000000000000009999999999899998
505440554554450454055545545455450000000000000000a0a0000aa99999a90000000045444549aa9b9bbaaa9a9bbb00000000000000009988999999999988
545445545504450455545555545554540000000000000000a000000a999a999a0000000054545454a9baabaaaaa9bbaa00000000000000008999999999999888
445454540554454445555455555554550000000000000000aaaaaaaa999999990000000054445444999a99aaaa999aaa00000000000000008899888888888888
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
000000003e666ee3000ee0000000000e03000000eeeeeee600eeee0000000000000220000000000000666600000000000008eee00eeee0000000000e70000000
00000000e66e66630eeeeee0000003e00e000000666663e60eeeeee000022000023773200027720006666666000000000eee8ee66eeeeee000000007e0000000
00888000666636303eeeeee666663e006e66600066663636e8e66ee80023320003777730027ee7206666666666000000eeeee8866eeeeee800e0007eee000e00
0c8e800063eeee30638eee66366777776e66660063366366ee6336e8023773202777777207effe706666666666660000eeee88888eeee8880007e0e99e0ee000
00cee00063eeee3086836666366eeeeee3e33e3e36e36666ee633688023773202777777207effe706666666666666600e888668668688888000ee966669ee000
0080000066666630838666663366e300eeeeeeee3e636666eee668860023320003777730027ee72066666666666666660066686336866600000096e666690000
00000000e66e66630683666006000e3066666600633666660ee88860000220000237732000277200eee66666666666660000686336860000007e6e663666ee00
000000003e666ee300866600000000ee666666006666666600886600000000000002200000000000666eeeeeeeeeeeee0000008668000000e7e9666363669eee
0000000000000000000000000000000000eee60000eee60000eee60000f0ff000f0fff0000ff0ff0666666666666666600000000000000007ee9666636669eee
00fffc000000000000000000000000000ee666600ee666600ee666600f0feef00ffee0fff0e0fe0066666666666666e300f000000000000000ee666666e6ee00
0f7cccc0000000000000000000000000366366363e366363e3663663fe0ee00ff0ee0ef0fee0eeef666666666666e3e300f6600000999000000096666e690000
0fcccc80000000000000000000000000666666666666666666666666feeeeef0fe0eeeef0feee00f66666eeee6e3e3e300f333000087e700000ee966669ee000
0fcccc800000000000000000000000006666666666666666666666660feeeeeffeeee0eff00eeef00666e6666ee3e3000066600000999000000ee0e99e0ee000
0cccc880000000000000000000000000336666333366663377666677f00ee0ef0fe0ee0ffeee0eef006e666666e30000000000000000000000e000eeee000e00
00c888000000000000000000000000007736637700366300007667000feef0f0ff0eeff000ef0e0f000e66666e00000000000000000000000000000ee0000000
0000000000000000000000000000000007700770700000070000000000ff0f0000fff0f00ff0ff00000000000000000000000000000000000000000ee0000000
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
00222222010111110000000011132332000000000000000000000000000000007fffffff7f7fffff0000000000000000000000000bb000000000000000b80000
0222223310101111002220001222221100000000000000000000000000000000fc7ccccefc7cccce000000000000000000a8000bbbbbb00000000000b8888000
2222333311010101222222202221211100000000000000000000000000000000f777ccce77c77cce00000000000bb00000a8800abbb88000000000ba88888800
22233323010000103333222212111322000000000000000000000000000000000e7ccc800e7ccc8000000000000abb0000a8800aaa88800000000baa88888800
23322222001000003222320021113221000000000000000000000000000000000ecccc800e7ccc8000000000000a880000a8000aaa8800000000baaaa8888880
3321212100000000212213001112121100000000000000000000000000000000008cc800008cc800000a880000aa88000a8800aaaa880000000baaaaa8888888
1212111100000000121112201121211100000000000000000000000000000000008cc800008cc800000a888008aa80000a8000aaaa88000000baaaaaaa888880
1121111100000000211111221111111100000000000000000000000000000000000880000008800000aa888000aa00000a0000aaa88000000baaaaaaaa888880
000000000000000000ffff0000eeee00000000220000000000efeee00eef700000eee000eeeeeeee00aa888000a08000008000aa8a8000000aaaaaaaaaa88800
0000000000fffe000f7ffee00eeeeee022222252000000000fffffeeeff777f00eeeee003e6e6ee300aa8880000abb00a80000aa080000000aaaaaaaaaa88800
000ff0000f7fee80f7feeee8e3eeeee325a2aa20000000000efff880ee777fe0008880003e66666300a888000000abbb00000a0a00800bb000aaaaaaaaaa8000
00f7e8000ffeee80ffeeee88ee7eee3e02222220000000000ffcffeef77ccfff0eeeee00366336e300a888000000aa88000000a0080abb8000aaaaaaaaaa8000
00fee8000feee880ffeeee86eee773e802aa2a20000000000ffcff88777ccfff08eeee003e63366300a88800000aaa8800000000000aa880000aaaaaaaaa0000
000880000eee8860feeee886eee7ee8602222220000000000efff880e7ffffe000888000366666e30aa88000000aa88000bbb000000aa880000aaaaaaa000000
00000000008886000ee888600ee3e86002aaa252000000000fffff88effffff008eeee003ee6e6e30a888000000aa88000bbbb00000aa8800000aaaa00000000
00000000000000000088660000838600252222200000000000ef88800eeff0000088800003eeee300a880000000aa88000abbbb0000aa8800000aa0000000000
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
8808080801010101010101010008838388888888010101018101010108080808080808080101010101010108888801010808080801018101010101010108010800080808000000000100000001080000000000000000000000000000000000010808080800000101000101010000010108080808000000010001000100000101
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d500000000d3c0c1c2e2d37170007100707173222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd36c4d6d7c6c513c4c7c0c1e0d2d0d1d2c361607270736070632222222222222222eaeb00000000eeef0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d936d6dbdccfdd361313131313131313d0d1d2e31010e3e362616363616163622222222222222222fafb00ebed00feff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d93613dbdcdfdd361313131313131313e1e151e1e15151e166676667676667672222222222222222fdfaeeedfdedebed0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000012020200202020220202020042727264647060741202020272627261b0b1b1b005c00015e0b5e0b0008001ce0e0e0e002020102212121212020202071707171202020202420202020202024000000001717171714f676766667143625253636363614155b4b5b5b001c001c001c001c1e231e231e011e1e1f363636
00000000202021200202020220032003143636154706070641410303363636360008005c005c001c230800080008001c22464622e0e0e001222222220202020261706070020202022420032020202024000000001717171714f676767676143636f936f936f914158a9a8a8a001c001c001c001c001c001c001c00003d1f3736
00000000212020200202020220012001143636370606060627262627363636361e081e5c0a0b0a0a0a0b5e0b1e0b1e2322b9b922e0e0e002cf02cf0203cf02ce60636160000000002420202020202024000000001717171714f67676b976143736d914d925d914151e011e1e5b4b5b5b002300231e231e231e011e1e02131f37
00000000424242420202020220202020253636363636363737363636363636360008005c0008001c000823080008001ce0e0e0e0e0e0e002cececfce2627262663626163000000002420202020202024000000001717171714f6767657b9041536e925e936e93715000000008a9a8a8a001c001c001c001c000000003d1d3d1f
e0e0e0e002e0e002011e1e0113131313242425360000000046464646000000000223230200000000aaaaaaaa2b2b2b2b1ee0e0e0e0f0f0e0e0e0e0e0001c001c000000000000000000000000000000002020202020202020767676762626272621032120000000000000000000000000343434350b1d1d022013131316161616
e0e0e0e020e0e0201ce0e01c202020202424253600000000f6f6f6f600000000231d213d72723232babababa2b2b2b2b30e0e0e0e0f0f0e0e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf7676767639393939626262620000000000000000000000003c36363c0823233d20131313173c3c3c
e0e0e0e020e0e0201ce0e01c212020202424253600000000f6f6f6f600000000231d033d42424202e5fb37e5212020211ee0e0e0e0f0f0e01e011e1ee0e0e0e00000c32b303130310000310000000000464627260607040476767676606061602627262700000000323232323232323205363605083535342013131339393939
e0e0e0e002e0e002011e1e0102cecfcf2424253600000000f9f9f9f90000000002020202616060602525242503202120001c011c2b2b2b2b00000000e0e0e0e032c3c32b302120303133303132323232767636370406073676767676131313133939393900000000060726270202cf02353c3c351a1b1b1a2013131322222222
0000001c18193e0003033e9c001819001c1c181818bb1819001c1c00009c0000001c0018199e9e9e1819afaf3333000000221e1d1e1e1d1e0099000000000000001c0000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300001d90248c008c033e9d9e181900afaf03033e2d233e00afa0aea29d3000001c002301000000a323a11c343400000000001c0000ac0000991eac3aadadacac9b0000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
34001dafa3233e3ab4342baf0018190000af181818ae181933ac1dbbbb2f3400001aae1819aeaeac1819a11c1a050000ac008d2c0000ae0000991e1d9e1d001cac000000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1932afa01a1a18188601038c1e1881bbbbae0d203eac1819ac1bac372d8f990000ae9e1819ac00ac1819aeaea0160033ad333323b0b3b33a3a3e001cb09c001cacacadb0180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
192caeaead2d8405188601a0bb3719aeaeae350505af3737ac9c1c0e2c0499adaeaeb018198ca28c18190000a016a91d1ab4a23f1ab435131a0435a61918a6a638380f04040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
192f313204a008881819b0b48507190000001818189e18198809898a3d90991ba9003737370da20c3838a1a90c163c3c3c3c3c873c3c3f1a001926262626262626262626260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
192020102c2d840a1819881a1aa40a9ea200a21f982d3f3f1a1a1a1a3c0026262626860faa35b8aaaaaab8a41a1636363c3f3f1a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1920a038181818881819881d1ea43cac0033308d3f2e2eae2c0c29bb97001c001c0202111f3c3f000000001c00000000001c00001c3c17be9e9d37000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3720a0209824360a18190a1c00a43cac293d382e2e2c1e1e853db8b43c001c00378db4bba21111000000001c1eacb300001aa2001c9f17a11d3838000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
063434349024360a18190a1c00a43ea3b43c3c3f3f3c34343f3f3f9e9d001b3d8181b41ea11e3f0033bb221d1a1da00ca230a297a1a33c0c1c9fbc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000003c3c3c3c3f3f3f0a000000001c001c0000920316991a1e1a24003c3c3c3db51bbbbb853c3c9e9d3c17861ba236000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a000000001c00001819003231301c00001c0000001c000000001c001c00bb92202335b0b3b024001f2626bf1a1a1e1e1a1a1a9e9ebf3c9e9ea03c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2f33002b291c29290419b4348f371cb2301c00009234b43400001b008f29b4aaaa2604b79a9a2400000000000000003c98983c3c3c3c3cad809c97000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070786041b07060d3797363686a6040786292901b4853604a91c3a3a0c99043636923e00003700000000000000003f3f3f3f3f37371d0ca2ac97000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
36363636991a17360707070736363636360707070707363626262626262699163636863435353400000000000000003daa212821b6b63f1a1aaf3c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c3c3f3f3f3f3f3cb6223f3c00000000000000000000000000000000000000000000000000000000000000000000003c3f2822283fa2288080ae99000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b6b6282828b63838b696b68100000000000000000000000000000000000000000000000000000000000000000000000d2e2e282c0d34852eae8505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3c3c3c3d3c3c3c3cbdaabd3c0000000000000000000000000000000000000000000000000000000000000000000000000000002f2f1a1a80801f36000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010900001802018020180701807118061180511804118031180211802118021180211801118011180011800124b0028b002cb0032300200002c0002c0002c0002c0002c0002c0002c0002c0002c0002c00028000
0113800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
010300000c57018570185701857018550185301852018520185100000018570185701855018540185301852018510185001850000000185701855018540185301852018510185101850000000000000000000000
010300000c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122
00108000060200000000000000000000000000000000406038075281462a146221162e1762e1762e1762e1072c1072c1072c1762c1262c1662c1662c1662c1662c1662c1662c126221162214736147381371a144
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
094800000f0001600016a001e8000f000160001480015000270001e0000f0000a0001e000200001e0001e0002200003000030000300024000060001b00008000250001b0001b000200000f0001e000120000d000
316c0020031001e8000d1000f0000a100031001e0000d10003100031001b00003100031001b0000d00012000031001e1000d1000310020100031001e1000d1002200003000030000300024000060001b00008000
5d1200000f420124200d4200f42014420034100f42016420034100d4250d420034100d420034100e420034100f420124200a4200f42014420034100f42016420014100d4250d4200d4230d420014100e42303420
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
0110000018430184300c4310c4301f4303660311432114321143211232112221122211222112221122211212053550735505355073550a3550c355073550c35505355073550a3550c35511355133551635518355
001000000215502100001000e155001000d10002155021550215002155021550e1500e100001000f100021000210002100001000010002100021000e1000e1000010000100001000010000100001000010000100
111200200f526145261b625145260f527185270f626145200b5260f526176251b5260f527185200f626145201b5260f5261b625145260f5261c5260f6261c5261b526175261b625175261b526175261b62517526
011200201710020100231002010017100241001b100231002310023100171002010023100241001710020100231002710017100201002310028100171001b1001710027100231002710017100271002310027100
01100000032500730003250073000a3000c3001630018300062500000006250000000000000000000000000005250000000525000000000000000000000000000425200000032520000000000000000000000000
791000000a2100a2100321003210032150321003410034100d2100d2100321003410033150321003412034120621006210034100341003215032100a2110a2120841008410033100331003212032100341203410
48100000143261b3160f3201b326143101b3100f3201b3160f3201b3100f3261b3160f32011310123200d3200f3200f3101632016316163200f3160f310143200f3261401014326143100f3101b3201232011320
481000000f326123160f320123260f3101b3100f3200f3100f326143100f320143261b3100f3100f320113201d3260f3201d3260f3201d3260f3201d3260f3201e3260f4201e3260f4201e3260f4201e3260f420
5910000020326273161b3202732620316273101b320273161b326273161b326273161b3100b3201e3101d3201b3251b32522320223161d3200f3301b32020320200200d33020320203201b310273201e3201d320
591000001b3261e3161b3201e3261b310273101b3201b3101b326203101b32020326273101b3101b3201d3202932612320293261e320293261e320293261e3202a326143202a326203202a326203202a32620320
311000000a1100a1100a1100a1100a1100a1100a1210a1200a120031200392003120039230392303920039200692000120069200c1200c1200c1200c1200c1200492003120049200392003923039230f1230f120
311000000b1100b1100b1100b1100b1100b1100b1120b1220492004110049100422203913039130392203922069200312006920031200d1220d1220d1220d122079200312012122079220792206923121220f920
7910002003320034100332003210032100322003415034150332003410033200321003210032100391003910064200f4100642003210032100321003215032150432012d20043200621006210063100631006310
79100000049200b420049200321003221032110341003410043200b410043200321203222032120340003400064200f9200642003220032210322103211032100732012d200732006d200621012d200631006321
0120000022025220141601027015250250d0241901025015240250c024180100c010230252301417010019142202522014160100a0101e0251e0140601012010200252001408010080101c0250b9141c0100d914
4b1000201d3233500015313214133e6201d621153133e6101531300300214132d600214130f3243c6250f322153230030039625213133e6101d621396253e6102131300300214231532338620386243862538620
01100000220002200022000160001600016000270002700025000250000d000190001900019000250002500024000240000c0001800018000180000c0000c0002300023000230001700017000170000b0000b000
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
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 323c1f39
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
