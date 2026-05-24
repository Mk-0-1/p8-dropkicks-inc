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
	
	--print("\^c0\n\^d1> initialising dropkicks inc.\asci0v2c0x1c#dd#eff#gg#aa#bc1 \n  job repositor\^d7y...\n\av3c2c3v2c3v1c3c3c3c3 \^d0  ready!\^6")
	load_lvl(1)
	
	load_menu()
	
	--init global vars
	-- camera x & y, anim counter, _ , time counter
	mod_tabl(_ENV,"cX,cY,aC,anim_len,t_c,t_enms,lvl_enms,t_e_clear,lvl_e_clear,t_tr,t_tr_collected,l_lock,vInfo/0,-256,0,2048,0,0,0,0,0,0,0,false,false")
	
	lvl_hiscore=dget(m_i)
	
	set_mus()
	
	for i=0,1 do
		dc2()
		cY *= 0.95
		flip()
	end
	

end

function rc() -- reset camera
	camera(cX,cY)
end

-- text box
function txtB(str,screen,x,y,boxlen_x,boxlen_y,boxc1,boxc2,t,rel,dx,dy)
	
	local function dt2()
		if (screen=="true") camera()
		if (boxc1)rrectfill(x-5,y-4,boxlen_x,boxlen_y,0,boxc1)
		if (boxc2)rrect(x-4,y-3,boxlen_x-2,boxlen_y-2,0,boxc2)
		print(str,x,y,7)
		
		if t then
			if t<(rel or 1000) then
				x+=dx or 0
				y+=dy or -0.5
			end
			t -= 1
		end
		
		rc()
	end


	if t then
		dT(t,dt2,{},true)
	else
		dt2()
	end

	
end

function Dmenu()
	dc2()
		
	if l_lock then
		txtB(unstr("???\n\ncomplete previous\ntask to unlock,true,10,8,80,32,8,9"))
	else
		
		txtB(unstr(m_title.."\n\nbest rating:"..lvl_hiscore.."%,true,10,8,73,27,8,9"))
		
		if t_c > 0.5 then
			local t_col = "\f7"
			if (vInfo) t_col = "\fe"
			txtB(unstr("\^o80b<\*f \*d >\*9\n🅾️/c:begin			 "..t_col.."❎/x:info,true,5,64,56,28"))
			
			if vInfo then
				txtB(unpack(split(m_lore_infos[m_i+1].."⬆️true⬆️10⬆️36⬆️120⬆️76⬆️8⬆️9","⬆️")))
			end
			
		end
		
	end
	
end

function _update_m_menu()
	Dmenu()
	t_c+=0.033333333
	


	if btnp(0) or btnp(1) then

		local xdir=-28
		m_i-=1

		if btnp(1) then
			xdir=28
			m_i+=2
		end
		
		m_i %= #start_lvls
		
		l_lock=m_i>0 and dget(m_i-1)<=0
		
		scrW(xdir..",8",
			function() 
				load_lvl(start_lvls[m_i+1])
				
				lvl_mus,layers_active=1,0b1111
				update_mus()
				
				if (l_lock) pal(split"1,1,1, 129,129,0,7, 129,129,129,129, 12,129,14,13,  1",1)
			end
		)

	end

	if btnp(4) and not l_lock then
	
		scrW("24,9",
			function()
				cls(9)
				camera()
				print("\f7\^o80b\^j22"..m_title.."\n\^5\^j05\#a\^x5\^o8ff\^d1"..lvl_title.."\^x4\^o80b\#9\^j25\n\^5\^d1\n  "..m_splashes[m_i+1])
					--pal(7,6,1),pal(7,13,1)&pal(7,5,1) with pauses inbetween. the 13 is 1d as 0d is newline
					print("\^5\^@5f170001⁶\^3\^@5f170001。\^3\^@5f170001⁵\^3")
				--end
				cls(9)
				begin_lvl(false)
			end
		)
		
	end
	
	if (btnp(5)) vInfo = not vInfo
	Utimers()
end


-- screenwipe, TODO remove props & replace with 2 args?
function scrW(props,midfunction,m_args)
	
	dT(0,function() -- delay until frame end to not mess with other calculations
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
				midfunction(unpack(m_args or {}))
			end
			
			flip()
		end
	end)
	
end



function begin_lvl(cont,retry)

	_update,dTs=_update_inlvl,{}
	clear_timers()

	if (cont) lvl_prevmus = lvl_mus or 0
	
	load_lvl(loaded_lvl_index)
	
	if cont then
		if retry then
			--idk
		else
			
			-- can exchange for compressed space, remove check, move box to left and add "    " to all titled level names
			if (lvl_title != "") then
				dT(1,txtB,{"\#6 "..lvl_title.."\^-#\f6\|f\^:7f3f1f0f07030100","true", unstr"0,8,0,0,0,0,84,20,-8,0"})
			end

		end
		
	else
		mod_tabl(_ENV,"t_c,t_enms,t_e_clear,t_tr_collected,t_tr,lvl_prevmus/0,0,0,0,0,0,0")
	end

	
	
	-- lvl var defaults
	mod_tabl(_ENV,"lvl_enms,lvl_e_clear,lvl_e_req,x_u_l,y_u_l,trn_bnc,trn_slp,grav,lvl_tr_collected,lvl_trinkets,sludg_l,sl_c,sl_smth,sl_vx,sl_vy,sl_dmg,alert,l_t_c,sl_r,sl_h,sl_spd/0,0,0,0,0,0.2,0.75,0.218,0,0,1024,6,0.9,0,-0.16,0.6,false,0,0,0.04,5")
	x_l_l,y_l_l=l_border_x,l_border_y
	
	-- lvl extra globals and defaults
	mod_tabl(_ENV,extraglobals)

	
	sl_vec = vec2_new(sl_vx,sl_vy)
	
	update_mus()
	if (lvl_mus != lvl_prevmus)	start_mus()

	menuitem(2 | 0x300, "retry area",retry_lvl)
	menuitem(3 | 0x300, "exit level",exit_lvl)

	init_entities()
	cX,cY,prev_cam_speed=player.pos.x-64,player.pos.y-64,vec2_zero+vec2_zero
	limit_camera()
end

function load_next()
	t_enms+=lvl_enms
	t_e_clear+=lvl_e_clear
	
	t_tr+=lvl_trinkets
	t_tr_collected+=lvl_tr_collected

	if lvl_next_level >= 0 then
		loaded_lvl_index=lvl_next_level
		begin_lvl(true)
	else

		lvl_score = t_e_clear/t_enms*75
		if (t_tr > 0) lvl_score += t_tr_collected/t_tr*25
		lvl_score\=1
		if(lvl_score > dget(m_i)) dset(m_i,lvl_score)
		lvl_mus=-1
		start_mus()

		menuitem(2)
		menuitem(3)
		
		camera()
		print("\f7\n\n\^w\^t\^o8ff\^2\^d1 \as8....a#0.a#0.d#2d#..a#1a#d#2d# \^2"..m_title.."\n\^d0       \^4\^3complete!\n\n\n\^-w\^-t\^6◆ \as9x5d#2d#3 "..t_e_clear.."/"..t_enms.." machines 'disassembled'\n\n\^5\^4◆ \as9x5d#2d#3 "..t_tr_collected.."/"..t_tr.." trinkets recovered\n\n\^5\^4   \as9x5d#2d#3 time: " .. t_c .. " s\n",0,0)
		print("\f7\^5\^4\^o8ff\*3 rating: \^5\as9x5d#2d#3x6<<d#2<d#3<d#2<d#3<d#2<d#3 " .. lvl_score .. "%\^4\n\n\n\*a 🅾️ to continue")
		
		while not btn(4) do
			flip()
		end
		exit_lvl()
	end

end


function d_load_next()
	dT(52,load_next)
end


function load_menu()
	mod_tabl(_ENV,"cX,cY,timers,lvl_mus,layers_active/0,0,{},1,15")
	clear_timers()
	menuitem(2)
	menuitem(3)
	update_mus()
	start_mus()
	_update=_update_m_menu
end

function exit_lvl()
	scrW("24,12", 
	function()
		--[[_draw=Dmenu]] 
		load_lvl(start_lvls[m_i+1]) 
		load_menu()
	end)
end

function spawn_lvlentity(i)
	local Etyp,ex,ey,e_extra = peek(lvl_entity_loc+i*4-4,4)
	ex,ey,e_extra = ex*4-32,ey*4-32,ntt_extrainfos[e_extra]
	local e=spawn_entity(ex,ey,Etyp,nil,e_extra)
	e.lvl_i = i
	add(entities,e)
end

function init_entities()

	-- clear ALL
	entities,all_links={},{}
	player = spawn_entity(p_spawn_x,p_spawn_y,2)

	add(entities,player)

	for i=1, lvl_numentities do
		spawn_lvlentity(i)
	end

end

function dT(ticks, func, args,continuous)
	local timer = {t=ticks,f=func,a=args or {},cont=continuous}
	add(timers, timer)
end

-- clears all indexable items in table without re-initializing the reference
function clear_tbl(tbl)
	if tbl then
		for i=1, #tbl do
			deli(tbl,1)
		end
	end
end

function clear_timers()
	clear_tbl(timers)
	clear_tbl(timer_q)
end

function Utimers()
	-- put all present timers in a separate queue so the main table can be updated
	-- queue is global so it can be flushed if needed
	timer_q = {}
	for timer in all(timers) do
		add(timer_q, timer)
	end

	for timer in all(timer_q) do
		timer.t -= 1
		timer_t=timer.t
		if timer_t <= 0 or timer.cont then
			timer.f(unpack(timer.a))
			if (timer_t <= 0) del(timers,timer)
		end
	end

end

function _update_inlvl()
	
	t_c+=0.033333333
	l_t_c+=0.033333333
	aC+=1
	aC%=anim_len
	if aC%8==0 then
		alert=false
		update_mus()
	end
	
	sludg_l += sl_r + sin(l_t_c/sl_spd)*sl_h
	
	for ntt in all(entities) do

		for subntt in all(ntt.all_ntts) do

			if (not subntt.nophys) move_entity(subntt)
			if (subntt.Uf) subntt.Uf(subntt)

				-- settle tile entities
			if subntt.Etyp == "tile" and subntt.is_stnd
			and #subntt.vel < 0.04 and not subntt.grabbed then
				ntt2tile(subntt)
			end
			subntt.grabbed=nil
			
			if subntt.stmn and subntt.stmn < 0 then
				rmE(subntt)
			end

			-- test borders
			if subntt.pos.x < x_u_l-16 then
				subntt.vel.x /= 2
				subntt.pos.x += 1
			elseif subntt.pos.x > x_l_l+16 then
				subntt.vel.x /= 2
				subntt.pos.x -= 1
			end

			
		end
		
		if ntt.pos.y > y_l_l+160 then
			rmE(ntt)
		end

		if ntt.pos.y > sludg_l then
			if (#ntt.vel > 3) particles(ntt.pos, split"6,5,0,0.3,9")
			ntt.vel = (ntt.vel + sl_vec) * sl_smth
			lose_stmn(ntt, sl_dmg)
		end
	
		for name, timer in pairs(ntt.ts) do
			ntt.ts[name] = max(0, timer-1)
		end
	end

	--check links
	foreach(all_links, tug)


	if player.pos.x > x_l_l+12 and btn(1) and lvl_next_level > -2 and lvl_e_clear >= lvl_e_req then
		if lvl_next_level > 0 then
			scrW("24,8",load_next)
		else 
			load_next()
		end
	end -- todo maybe add else here to skip cam update after lvl exit
	
	-- camera tracking
	local t_p=player.pos+player.vel*20
	t_p.x += tonum_flip(not player.is_left)*8
	t_p.y += player.iDir.y*28

	local distance = vec2_new(
		t_p.x-cX-64,
		t_p.y-cY-64
	)
	local speed=prev_cam_speed*0.85 + distance/20*0.15

	cX+=(speed.x+0.5)\1
	cY+=(speed.y+0.5)\1

	prev_cam_speed = speed
	limit_camera()
	
	_draw_inlvl()
	Utimers()
end

function limit_camera()
	cX,cY=mid(x_u_l,cX,x_l_l-127),mid(y_u_l,cY,y_l_l-127)
end


function draw_common()
	cls(lvl_clearcol)
	
	draw_bg(lvl_bg1_loc)
	draw_bg(lvl_bg2_loc)
	
	rc()
end

function dc2()
	draw_common()
	map()
end

function _draw_inlvl()
	draw_common()
	map(unstr"0,0,0,0,128,64,0b1000")
	if lvl_next_level > -2 then
	
		local c = 12
		if lvl_e_clear < lvl_e_req then
			c = 3
			txtB("\^o95a"..lvl_e_clear.."/"..lvl_e_req,false,x_l_l-14,player.pos.y)
		end
		
		local function l(o_x)
			line(x_l_l-o_x,0,x_l_l-o_x,l_border_y,c) -- use default y limits here
		end

		l(0)
		l(1)
		l(flr(t_c*8)%8)
		
	end
	
	local drawables = {}
	
	for ntt in all(entities) do
		for subntt in all(ntt.all_ntts) do
			add(drawables,subntt)
		end
	end
	
	for link in all(all_links) do
		add(drawables,link)
	end

	
	for i=1, 4 do
	
		if i==3 then
			-- solid map
			map(unstr"0,0,0,0,128,64,0b00000001")
		end
		
		-- entities
		for dr in all(drawables) do
			
			-- outlines 
			if dr.outl != 0 and i==2 then
				if dr.Df == Dlnk then
					dr.Df(dr,true)
				else
					
					local pal_o = {}

					for i=1,16 do
						add(pal_o,dr.outl)
					end

					pal(pal_o,0)
					
					local function dr1(x,y)
						camera(cX+x,cY+y)
						dr.Df(dr)
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
			 dr.Df(dr)
			end
			
		end
	
	end
	
	-- draw the sinister sludge
	poke(0x5f5e, 0b01110111)
	rectfill(-256,sludg_l,1024,1024,sl_c)
	poke(0x5f5e, 0b11111111)
	
	draw_ui()


end

--get/set from starting map
-- assume range is valid
function mget0x20(x,y)
	local s = 0x2000
	if (y >= 32) s = 0x1000
	return @(s + x + y*128)
end

-->8
-- token savers

function unstr(str)
	return unpack(split(str))
end

-- thank you Lokistriker whoever you may be
-- modifies/appends to table. can target _ENV to change globals
function mod_tabl(tab, kv, splitter)
	local k,v = unpack(split(kv, splitter or "/"))
	k,v = split(k),split(v)
	for i=1,#k do
		tab[k[i]]=_p(v[i])
	end
	return tab
end

-- mod tabl but v can be variables
function mod_tabl2(tab, k,v)
	local k = split(k)
	for i=1,#k do
		tab[k[i]]=_p(v[i])
	end
	return tab
end


-- parse
function _p(v)
	if (sub(v,1,3) == "_V_") return _ENV[sub(v,4)] -- cursed technique to get env variables
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

function first_lnk(e1,e2)
	for link in all(all_links) do
		if ((link.from == e1 and link.to == e2) or (link.from == e2 and link.to == e1)) return link
	end
end

function timer_ready(e,n)
	return e.ts[n] <= 0
end

-- TODO maybe merge mod_tables

function spawn_entity(x,y,type,parent,extraprops)
	local entity = mod_tabl2({},"pos,vel",{vec2_new(x, y),vec2_zero+vec2_zero})

	local pr = split(ntt_types[type], "|")
	local props_c,props_e = pr[1], pr[2]
	mod_tabl(entity,"X,rds,mass,sprite/" .. props_c)
	-- only primary entities can have timers(ts) - non-custom ones, anyway
	-- type (template) removed - maybe re-add if needed
	mod_tabl2(entity,"iDir,all_ntts",{vec2_zero+vec2_zero,{entity}})

	-- some defaults
	mod_tabl(entity, "ts,bnce,slp,grav,ifi,Uf,Df,is_left,coll_rng,actN,actF,rngN,rngF,Iarm,Irss,spr_size,d_o,outl,magnetcharge,lzr_thck,dash,jumping_d,ray_iters/{},_V_trn_bnc,_V_trn_slp,_V_grav,_V_e,_V_e,_V_Dntt,false,0,55,100,0,35,0,1,8,3,0,70,10,0,0,3")

	-- xtra props from a source
	if (entity.X != 0) mod_tabl(entity,split(ntt_types[entity.X], "|")[2])
	
	-- props
	mod_tabl(entity,props_e)
	
	if (extraprops) mod_tabl(entity,extraprops)
	mod_tabl(entity.ts,"hurt,hitshock,jump_cooldown/0,0,0")

	-- applying table indexes
	mod_tabl2(entity,"smok",{smokes[entity.smok]})

	
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

		-- init complex
		local b_info = split(ntt_b_types[entity.Btyp],"`")
		entity.props = b_info
		mod_tabl(entity,"g_mode,ground_entity,leg_facing,facing,surface_away,rDir/false,nil,_V_vec2_down,_V_vec2_up,_V_vec2_up,_V_vec2_up")
		mod_tabl2(entity,"permastick,g_acc,a_acc,g_max,a_max,jump_str,leg_len,arm_len,stnd_height,leg_speed,leg_cooldown,leg_angle_range",b_info)

		--subentity mappings for limbs
		mod_tabl(entity,"m_l_legs,l_angles,m_l_arms,a_angles/{},{},{},{}")
		-- cooldown for movement
		entity.m_l_arms.cd,entity.m_l_legs.cd=0,0

		for i=13, #b_info, 5 do
			local e_typ,l_typ,angle = unpack(b_info,i)
			local l_e = spawn_entity(0,0,e_typ,entity)
			mod_tabl2(l_e,"t_pos,t_active,angle",{l_e.pos,false,angle})

			add(entity.all_ntts, l_e)

			if l_typ=="l" then
				add(entity.m_l_legs, l_e)
			else
				add(entity.m_l_arms, l_e)
			end

			make_link(entity,l_e,split(links[b_info[i+3]]), b_info[i+4])
		end
	
	end

	if entity.rope then
		entity.rope_ntt = tmpTrnE(entity.pos + vec2_new(entity.rX,entity.rY))
		make_link(entity, entity.rope_ntt, split(links[entity.rope]), entity.rope_e)
	end
	
	if (entity.dur) dT(entity.dur,rmE,{entity})
	
	entity.ifi(entity)

	return entity
end

function Uitm(i)
	if #(i.pos-player.pos) < 8 then
		if i.item == 5 then
			player.stmn_h_dmg,player.stmn=max(0,player.stmn_h_dmg-i.amount),min(player.stmn+i.amount,70)
			sfx2(-5)
		else
			lvl_tr_collected+=1
			txtB("\^ocfftrinket!",0,i.pos.x,i.pos.y,unstr"0,0,0,0,45")
		end
		rmE(i)
	end
end

local function spawn_next(e)
	add(entities,spawn_entity(e.pos.x,e.pos.y,e.next_e))
end

-- TODO remove & move functionality?
function Ienm(enm)
	mod_tabl2(enm,"gun,Etyp,is_left,sSt",{split(guns[enm.gun],"`"),"enm",true,true})
end

function retry_lvl()
	scrW("-24,8",begin_lvl,{true,true})
end

function rmE(ntt, noeffect)
	if ntt == player or ntt.parent == player then
		retry_lvl()
		return
	end

 for subntt in all(ntt.all_ntts) do

		for link in all(all_links) do
			if (link.from == subntt or link.to == subntt) delete_link(link)
		end
	end

	local is_present=del(entities, ntt)

	if ntt.parent then
		is_present=is_present or del(ntt.parent.all_ntts, ntt) and in_tbl(ntt.parent, entities)
	end

	if not noeffect and is_present then

	
		if ntt.enemy == true then
			lvl_e_clear+=1
			local txt="\^oc09"..lvl_e_clear.."/"..lvl_enms
			if (lvl_e_clear >= lvl_enms)txt="\^oc09area clear!"

			txtB(txt,0,player.pos.x,player.pos.y,unstr"0,0,0,0,50")

		end
		
		if (ntt.expl) expl(ntt.pos, explosions[ntt.expl])
		if (ntt.respawn) spawn_lvlentity(ntt.lvl_i)
		if (ntt.next_e) spawn_next(ntt)

		if ntt.boss then
			lvl_mus=-1
			start_mus()
		end
	
		if (ntt.smok) particles(ntt.pos,split(ntt.smok),ntt.vel)
		if (ntt.break_func) ntt.break_func(ntt)

	end

	return is_present
end

function make_link(e1,e2,link_props,extraprops)
	local link=mod_tabl2(
	{},"from,to,l_type,len,strenght,draw_type,col,width,d_o,outl",
	{e1,e2,unpack(link_props)})
	mod_tabl(link,extraprops or "➡️", "➡️")
	link.true_len,link.Df=link.len,Dlnk
	add(all_links, link)
	return link
end

function delete_link(l)
	del(all_links,l)
end

-->8
-- drawing

function draw_bg(loc)
	local lvl_bg = {peek(loc,8)}
	
	for i=3,8 do
		lvl_bg[i] = lvl_bg[i]-128
	end
	
	mod_tabl2(_ENV,"b_img_indx_pal,b_wxy,b_sc,b_prlx,b_ofx,b_ofy,b_timx,b_timy",lvl_bg)
	
	-- TODO save 1 token
	local bg_sampl = bg_pals[b_img_indx_pal\16+1]
	pal(split(bg_sampl..","..bg_sampl..","..bg_sampl..","..bg_sampl), 0)

	local p_sc,scrl,baddr = b_sc*8,b_prlx/64,0x2000 + (b_img_indx_pal%16)*8
	local a_p_sc = abs(p_sc)
	
	local scroll_x,scroll_y = -b_ofx+cX*scrl+t_c*b_timx, -b_ofy+cY*scrl+t_c*b_timy

	if(b_wxy%2==1) scroll_x %=8*a_p_sc
	if(b_wxy>1) scroll_y %=4*a_p_sc



	for i=0, (128\(8*a_p_sc)+1)*(b_wxy%2) do
		for j=0, (128\(4*a_p_sc)+1)*(b_wxy\2) do
			camera(scroll_x - 8*a_p_sc*i, scroll_y - 4*a_p_sc*j)
			
			for	x=0,7 do
				for	y=0,3 do
					--local n = mget0x20(b_img_indx*8+x, y)
					local n = @(baddr+x + y*128)
					if (n != 0) sspr((n&0b1111)*8,n\16*8,8,8, x*p_sc, y*p_sc,p_sc,p_sc)
				end
			end
			
		end
	end

	pal(0)
end


function Dntt(entity,pos,flip_x,flip_y)
	pos,flip_x,flip_y,e_spr,s_x,s_y = pos or entity.pos,flip_x or entity.is_left, flip_y or entity.is_up,entity.sprite,entity.sprW or 1,entity.sprH or 1
	if e_spr then
		local spr_sw,spr_sh = s_x*entity.spr_size, s_y*entity.spr_size
		e_spr += ((aC\(entity.f_l or 2))%(entity.f_c or 1))*s_x
		
		sspr(e_spr%16*8,e_spr\16*8,s_x*8,s_y*8,pos.x-spr_sw/2,pos.y-spr_sh/2,spr_sw,spr_sh,flip_x,flip_y)
	end
end

function Ddcl(entity)
	print(entity.decal,entity.pos.x,entity.pos.y)
end

function Dlnk(link, is_outl)
	local envstr,_ENV = _ENV,link -- forbidden token-saving reality warping spell
	-- link's members are now "globals" and all previously global variables are now accessed trough envstr
	-- local makes it work only inside this function (and luckily not inside envstr's)

	local p1,p2,left,t_l,l_c,l_c2,t_w= from.pos,to.pos,from.is_left, len/2, col, from.col,width

	if is_outl then
		t_w += 4
		l_c,l_c2 = outl, outl
	end
	
	if draw_type == 3 then
	
		local pos_2 = p1 + envstr.vec2_norm(-from.facing)*3
		envstr.line_vec(p1, pos_2, l_c2, t_w)
		
		p1,left,t_l = pos_2, not left, (true_len - 3)/2
		
	elseif draw_type == 4 then
		left = false
	end
	

	
	-- draw_joint
	if p1 != p2 then

		-- TODO merge function
		local k_2, k = envstr.circ_intersect(p1,p2,t_l)
		
		if (left) k=k_2
		envstr.line_vec(p1,k,l_c,t_w)
		envstr.line_vec(k,p2,l_c,t_w)
	end
	
end

-- TODO inline?
function circ_intersect(p1,p2,r)
	local d,mid_p=#(p2-p1),(p1+p2)/2
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
	local head_sprite_pos,flip_r,flip_u=ntt.pos+ntt.facing*2,ntt.is_left

	if ntt.facing.y > 0.7 then
		flip_u,flip_r = true,not flip_r
	end


	if (not flip_r) head_sprite_pos.x += 1
	Dntt(ntt, head_sprite_pos, flip_r,flip_u)

	local e_pos_x,e_pos_y = head_sprite_pos.x-4, head_sprite_pos.y-4
	if (flip_r) e_pos_x-=1
	
	--eyes
	p_expr = "0000002800000000"
	
	if not timer_ready(ntt, "hitshock") then
		p_expr = "0000442844000000"
	elseif #ntt.vel > 4 then
		p_expr = "0000002828000000"
	elseif ntt.iDir.y > 0.5 then
		e_pos_y += 1
	end

	if ntt == player and aC%(55) < 52 then
		print("\f7\^:"..p_expr, e_pos_x,e_pos_y)
	end
	

end

function draw_ui()
	camera()

	fillp(0b0000000010111010.1)
	rectfill(unstr"3,2,75,8,8")
	fillp(0)
	
	rectfill(3,1,75-player.stmn_h_dmg,8,8)
	rectfill(4,6,player.magnetcharge+4,7,15)
	rectfill(4+player.stmn,2,player.ts.hurt/2+4+player.stmn,4,7)
	rectfill(4,2,player.stmn+4,4,12)
	
	
	rc()
end

-->8
-- sounds
-- TODO put in init mod_tabl
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
	__eq=function(a,b)return a.x==b.x and a.y==b.y end,
	
	__len=function(v)
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
		
		-- previously vec2_angle(v,v2)
		-- gives shortest angle between two vectors
		local angle = atan2(v.x,v.y) - atan2(v2.x,v2.y)
		if (angle> 0.5)angle-=1
		if (angle<-0.5)angle+=1
		
		local l = abs(v2_c)/cos(angle)
		--if (l < 0.1) l = 0
		return l
	end
		
}
-- some basic vectors
vec2_zero=vec2_new(0,0)
vec2_right=vec2_new(1,0)
vec2_down=vec2_new(0,1)
vec2_left=-vec2_right
vec2_up=-vec2_down

v_spin = {vec2_right,vec2_down,vec2_left,vec2_up}

-- to copy, either do +vec2_zero or *1

function vec2_norm(v)
	if (#v == 0) return v
	return v/#v
end

function vec2_limit(v)
	if (#v > 1) return vec2_norm(v)
	return v
end

function vec2_dot(v1,v2)
	return v1.x*v2.x+v1.y*v2.y
end

-- TODO inline?
function project(a,b) -- if b is 0,
	local k = vec2_dot(a,b)/vec2_dot(b,b) -- 0/0 is is max num
	return vec2_new(k*b.x,k*b.y) -- but then this is 0,0
end

function vec2_rotate(v,a)
	return vec2_new(v.x*cos(a) + v.y*sin(a), -v.x*sin(a) + v.y*cos(a))
end


-->8
-- helper functions

function e()
end

function addF(e, m)
	e.vel+=m/e.mass
end

function cntF(m, e1, e2)
	addF(e1,m)
	addF(e2,-m)
end

-- works on scalars as well
function splitV(v, m1, m2)
	return v*m2/(m1+m2),v*m1/(m1+m2)
end

-- multiply components separately
-- if s is 0 v1 is 0 and v2=v
function recomp_mul(v,s,m1,m2)
	local vc = project(v,s)
	return vc*m1+(v-vc)*m2, vc*m1, (v-vc)*m2
end

-- used in collisions and link pulling/pushing
function transferMMT(e1, e2, bnc, slipperiness, square_coll)
	-- normalized bc when offscreen with high diff it freaks out
	local diff = vec2_norm(e2.pos-e1.pos)

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

function collsqr(p1, r1, p2, r2)
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


function colltrn(point, rds)
	local p_in = point+vec2_zero
	--extend terrain offscreen
	p_in.x = mid(x_u_l,p_in.x,x_l_l)
	p_in.y = mid(y_u_l,p_in.y,y_l_l)

	local point_max,point_min = p_in+vec2_new(rds,rds),p_in-vec2_new(rds,rds)

 	-- go over all tiles in rectangle range
	for j=point_min.y\8,point_max.y\8 do
		for i=point_min.x\8,point_max.x\8 do

			if fget(mget(i,j),0) then -- solid tile
				local p2 = vec2_new(i*8+4,j*8+4)
 			if (collsqr(p_in, rds, p2, 4)) return true, p2
 		end

		end
	end

	return false
end

function collntt(ntt, pos, rds)

	-- ultra slow with lots of primary entities - limit is about 15
	-- only ntt can be a second-tier entity
	for other in all(entities) do
		if not (
			other.nophys or 
			in_tbl(other, {ntt,ntt.parent,ntt.grabbed_e}) or 
			(ntt.parent and other.ignS) or ntt == other.grabbed_e or 
			(ntt.parent and other == ntt.parent.grabbed_e) or
			ntt.e_proj and other.enemy
			)
			then
			local did, normal, dist = collsqr(pos or ntt.pos, rds or ntt.rds, other.pos, other.rds)

			if (did) return true, other, normal, dist
		end
	end
	return false, nil
end


function tile2ntt(tmp_ntt)
	--printh("converted a tile to entity")
	local tpx,tpy = tmp_ntt.pos.x\8, tmp_ntt.pos.y\8

	mod_tabl(tmp_ntt,"Etyp,stmn,stmn_l_t,rds,Iarm,Irss,bnce,mass,g_i/tile,50,50,3.5,5,3,0.45,0.3")
	tmp_ntt.sprite=tmp_ntt.tile


	-- fill bg: insert adjacent < or ^ bg tile
	local t_l,t_u,t_set = mget(tpx-1, tpy),mget(tpx, tpy-1), 0
	if (fget(t_u,0)) t_set = 2
	if (fget(t_u,3)) t_set = t_u
	if (fget(t_l,3)) t_set = t_l
	mset(tpx, tpy, t_set)


	add(entities, tmp_ntt)
	return tmp_ntt
end


function ntt2tile(e)
	mset(e.pos.x\8, e.pos.y\8, e.sprite)
	rmE(e,true)
end


-->8
-- movement

-- NO TERRAIN CLIPPING
function unclip(entity,pos,rds, up_override, ntt_mul)
	local pos_t, rds_t = pos or entity.pos, rds or entity.rds
	local rds_e,is_exit,exit_v = rds_t * (ntt_mul or 1), false

	-- first test terrain
	local coll_t, t_pos = colltrn(pos_t, rds_t)
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

				if not colltrn(pos_t + m_v, rds_t) then

					-- keep shorter one
					-- up_override here keeps first exiting vec of a distance iteration rather than shortest - which up has a high priority over others
					if (not is_exit or (not up_override and #m_v < #exit_v)) exit_v = m_v
					is_exit=true
				end

			end

			if is_exit then


				return true, true, true, exit_v, tmpTrnE(t_pos) -- out now - ignore entities
			end
		end
		return true, true, false, vec2_zero, tmpTrnE(t_pos)
	end

	-- then entities
	local coll_e, e, norm, dist = collntt(entity, pos_t, rds_e)

	if coll_e then
		local m_v = norm*dist
		if (not colltrn(pos_t + m_v, rds_t) and not collntt(entity, pos_t + m_v, rds_e)) return true, false, true, m_v, e
		return true, false, false, m_v, e
	end
	return false
end


function Ustnd(entity)

	entity.is_stnd=false
	local down_pos = entity.pos+vec2_down

	if colltrn(down_pos, entity.rds) then
		entity.is_stnd=true
		return
	end

	if collntt(entity, down_pos) then
		entity.is_stnd=true
	end
end

function expl(pos, e_props) -- todo probably move explosion table read here
	local radius, str, sf = unstr(e_props)


	local function get_expl_ntt(other)
		local dist = other.pos - pos
		-- no damage falloff! simpler and removes some jank from game
		expl_ntt = mod_tabl2({},"pos,vel",{pos,vec2_norm(dist)*str + other.vel})
		return mod_tabl(expl_ntt, "mass,Iarm,Irss/1,0,1")
	end

	for ntt in all(entities) do
		if (#(ntt.pos-pos) < radius) impact(get_expl_ntt(ntt), false, ntt.pos-pos, ntt, true, true)
	end

	-- go over all tiles in rectangle range
	for j=pos.y-radius,pos.y+radius,8 do
		for i=pos.x-radius,pos.x+radius,8 do
			local t_pos = vec2_new(i,j)
			if fget(mget(t_pos.x/8,t_pos.y/8),0) then
				local tmp_ntt = tmpTrnE(t_pos)
				if (#(t_pos-pos) < radius) impact(get_expl_ntt(tmp_ntt), true, tmp_ntt.pos-pos, tmp_ntt, true, true)
			end
		end
	end

	particles(pos, {7, radius/2, sf, -radius/3, 3})
end

-- c smokes for prop info
function particles(pos, props, vel)
	local co,rd,sf,dc,ti = unpack(props)
	sfx2(sf)
	for i=1, 5 do
	
		-- slightly cursed closure manipulation
		local p,v,r,c,dc = pos+vec2_zero,vec2_new(rnd(2)-1,rnd(2)-1) + (vel or vec2_zero),rd, co, dc or 0.3
		dT(ti or 11,
			function()
				circfill(p.x,p.y,r,c)
				p += v
				r -= dc
			end,
		
			{},true
		)
		
	end
end


function lose_stmn(ntt, dmg)
	local envstr, _ENV = _ENV,ntt

	if stmn then
		local p_s=stmn
		
		stmn-=dmg
		if (stmn_h_dmg) stmn_h_dmg = max((stmn_l_t-stmn)/2,stmn_h_dmg)
		
		
		local total_dmg = p_s - stmn
		ts.hurt=total_dmg*2

		ts.hitshock = dmg*0.5+0.9

		-- SOME MINIONS HAVE ENEMY TO "f" SO IT'S NOT THE TRUE BOOL ELSEWHERE BUT DOES EVALUATE HERE
		if ntt.enemy and stmn > 0 and total_dmg > 1 then
			envstr.txtB("\^o05a"..(stmn/stmn_l_t*100)\1 .."%",0,pos.x,pos.y,envstr.unstr"0,0,0,0,18")
		end

	end

end

function tmpTrnE(pos)
	local px,py=pos.x\8,pos.y\8
	local ntt=spawn_entity(px*8+4,py*8+4,12)
	ntt.tile = mget(px, py)
	if fget(ntt.tile,1) then
		ntt.mass,ntt.g_i = 15
	end
	if (fget(ntt.tile,4)) ntt.bnce = 0.99
	return ntt
end

function coll_p(e,p,i,o)
	local cdmg = o.Cdmg
	if e.stmn and o.thrown then -- first block hit is buffed
		i,o.thrown = i*3+8--,false
	end
	

		
	if cdmg then
		lose_stmn(e, cdmg)
		if (e==player) sfx2(-1)
		local cnt_vel=vec2_norm(e.pos-o.pos)*(o.kb or 0)
		addF(e, cnt_vel)
	end

	if e.Etyp=="tile" and o.e_proj then
		e.vel = p
	end
	
	if e.coll_func then
		e.coll_func(e, o, p, i)
	end
	if i >= e.Iarm then
		lose_stmn(e, i*i/2.5/e.Irss)
	end
end

function impact(entity, with_t, surface_dir, coll_e, no_sfx, no_sq_coll)

	local prev_v1,prev_v2 = entity.vel+vec2_zero, coll_e.vel+vec2_zero

	local function get_nrg(v1,v2)
		return (#v1)^2*entity.mass + (#v2)^2*coll_e.mass
	end

	local slp,bnc = max(entity.slip, coll_e.slip), max(entity.bnce, coll_e.bnce)

	transferMMT(entity, coll_e, bnc, slp, not no_sq_coll)

	local impact=get_nrg(prev_v1,prev_v2)-get_nrg(entity.vel,coll_e.vel)
	local impact_1,impact_2=splitV(impact, entity.mass, coll_e.mass)


	-- if broke terrain turn tmp tile to entity tile
	if with_t and #coll_e.vel > 0.08/(1-bnc) then
		coll_e = tile2ntt(coll_e)
		coll_e.vel *= 4
		impact_2 += rnd(1)
		if (impact_2>2.1) coll_e.sprite = 15
		if (impact_2>2.5) rmE(coll_e)
		
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
				entity.pos += vec2_norm(entity.pos - coll_e.pos)
			end
		end
	else
		entity.coll_rng=0
	end
	
	-- TODO inline?
	Ustnd(entity)

	
	-- rope
	local l = first_lnk(entity, entity.rope_ntt)
	if l then
		entity.pos = entity.pos*0.9 + (entity.rope_ntt.pos - vec2_new(entity.rX,entity.rY))*0.1
		AIPfly(entity)
	end
	
	--fall
	if not entity.sSt then

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
	local e2_pos, e2_vel = e2.pos, e2.vel

	local diff = e2_pos - e1.pos

	local move_dist = #diff - link.len


	-- amount that entities need to move to remain in link range
	local move_need, do_move = vec2_norm(diff) * move_dist

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

		if e2.Etyp == "tmp tile" then
			e1.pos += move_need
			-- remove vel component towards ground
			e1.vel = recomp_mul(e1.vel, e1.pos - e2_pos, 0, 1)
		else
			-- the amount each entity needs to move
			local move_1,move_2 = splitV(move_need, e1.mass, e2.mass)

			e1.pos += move_1*0.98
			e2.pos -= move_2*0.98

			-- equalize velocity components
			-- but only if not already moving in a way favorable for link
			-- fixes player bounce speed cancel (idk about link type 0)
			if (vec2_dot(move_need, e2_vel - e1.vel) >= 0) transferMMT(e1,e2, 0.1, 1)
			
		end

	end

end

-- rough iterative raycast with angling
function ray_coll(pos,vec,angle_range,entity,sticky,iter)
	for i=1,iter do
		local t_vec = vec2_rotate(vec*(rnd()+0.1),angle_range*(rnd()-0.5))
		local t_pos = pos + t_vec
		local coll_land,with_t,out,away_vector,other_ntt = unclip(entity, t_pos, entity.rds+2, true)
		
		
		if (coll_land and out and vec2_dot(t_vec,away_vector) <= 0) return true, t_vec, with_t, away_vector, other_ntt

		if in_tbl(mget(t_pos.x\8, t_pos.y\8), split"44,45") then
			return true, t_vec, true, vec2_up+vec2_zero, tmpTrnE(t_pos), true
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
		arm.sSt=false
	end


	local prev_jump=jump_g
	envstr.mod_tabl(entity, "sSt,g_mode,jump_g,g_no_slide/false,false,false,false")
	sticky,magnetwalk = permastick
	
	-- proc move legs
	
	local stand_vec,max_dist,max_leg,max_stand_center = envstr.vec2_norm(entity.leg_facing)*leg_len*1.25, stnd_height/2

	-- move target with highest distance to optimal target position (if outside tolerant distance)
	local st_pos,st_away,st_c = envstr.vec2_zero*1,envstr.vec2_zero*1,0

	for leg in envstr.all(m_l_legs) do
		stand_vec_l = envstr.vec2_rotate(stand_vec,leg.angle * envstr.tonum_flip(is_left))
		if (prev_jump)stand_vec_l.x+=vel.x*leg_len*0.9
		local stand_center = pos + stand_vec_l
		local dist = #(leg.t_pos - stand_center)
		if (leg.magnetwalk and #iDir > 0 and ts.jump_cooldown <= 0 and magnetcharge > 0) then
			sticky = true
		end
		
		if (dist > leg_len*1.5 or envstr.aC%30==#m_l_legs or ts.jump_cooldown != 0) leg.t_active = false
		
		if envstr.timer_ready(entity,"jump_cooldown") then

			if not leg.t_active then

				local did, t_vec, with_t, away_vector, other_ntt, magnetwalk = envstr.ray_coll(pos, stand_vec_l,leg_angle_range, leg,sticky, entity.ray_iters)
				leg.magnetwalk = magnetwalk

				if did then
					stand_center = pos + t_vec + away_vector
					
					leg.surface_away,ground_entity,dist=envstr.vec2_norm(away_vector),other_ntt,#(leg.t_pos - stand_center)
					
					if dist > max_dist then
						max_dist,max_leg,max_stand_center = dist,leg,stand_center
					end
					if dist <= leg_len*1.5 then
						leg.t_active = true
					end

				end

			end

			-- move legs to targets
			if leg.t_active and not(leg.magnetwalk and magnetcharge <= 0) then
				g_mode,jump_g,slide=true,true,ground_entity.tile and iDir.y > 0
				g_no_slide = g_mode and not slide
				st_pos+=leg.t_pos+leg.surface_away*stnd_height
				st_away+=leg.surface_away
				st_c+=1
				
				if (leg.magnetwalk) magnetwalk = true
				
				if not slide then
					envstr.move_towards(leg,leg.t_pos, leg_speed)
				
					if #vel < 8 then
						if sticky then
							leg.vel*=0.75
						end

						if leg.is_stnd and leg.surface_away.y<0 or sticky then
							sSt = true
						end
						
					end
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
	surface_away=envstr.vec2_norm(st_away)


	if sSt then

		vel.y *= 0.85

		local stand_p_lh = st_pos/st_c


		stand_p_lh += surface_away * (envstr.aC\48%2)

		
		if not sticky then
		-- todo maybe recomp mul surface vector or something
			pos.y = pos.y*0.9 + stand_p_lh.y*0.1

			for arm in envstr.all(m_l_arms) do
				arm.vel*=0.95
				if #arm.vel < 0.15 and not armgrab then
					arm.sSt=true
				end
			end

		end

	end

end



function uR(ntt)
	if ntt.iDir.x != 0 then
		ntt.is_left = ntt.iDir.x < 0
	end
	if (ntt.shoot_dir) ntt.is_left = ntt.shoot_dir.x < 0
end


function ungrab(ntt)
	ntt.in_grab,ntt.grabbed_e = false--,nil
end

function move_control(ntt)

	if ntt.ts.hitshock < 2 then
	
		local surface_normal,input_dir_l,jump_cooldown = ntt.surface_away, vec2_limit(ntt.iDir), ntt.ts.jump_cooldown
		local input_dir_h = vec2_norm(input_dir_l + vec2_up*0.04 + vec2_right*(tonum_flip(not ntt.is_left))*0.05)
		local hold_pos,throw_str = ntt.pos + input_dir_h*ntt.arm_len,1.6

		-- grabbing ----

		if #ntt.m_l_arms > 0 then

			-- check if grab still valid
			if ntt.in_grab and first_lnk(ntt,ntt.grabbed_e) == nil then
				ungrab(ntt)
			end
			

			


			local hp_clip,hp_with_t,hp_out,hp_dir,hp_coll_e = unclip(ntt,hold_pos,0.75,false,4)
			--local hp_2 = hold_pos+(hp_dir or vec2_zero)

			if ntt.b5 then
			
				for arm in all(ntt.m_l_arms) do

					if hp_clip then
						ntt.vel *= 0.6 + trn_slp*0.4 -- wallslide
					end
					
					cntF((hold_pos-arm.pos)/128,arm,ntt)
					--move_towards(arm,hp_2, 1.5)
				end
			
				ntt.armgrab = true

				-- try to grab
				if not ntt.in_grab and not ntt.grab_c then
				
					if hp_clip and not hp_coll_e.g_i then
						ntt.in_grab = true
						if hp_with_t then
							hp_coll_e = tile2ntt(hp_coll_e)
						end
					end

					if ntt.in_grab then -- grab
						sfx(21)
						
						ntt.grabbed_e = hp_coll_e
						
						make_link(ntt,ntt.grabbed_e,split("1," .. ntt.arm_len .. ",40,0,14,0,0,0"))
					end
				end

			else
				--throw if holding, else nothing

				if ntt.in_grab then

					sfx2(-4)
					local v = vec2_norm(ntt.shoot_dir or input_dir_h) * throw_str 
					cntF(v, ntt.grabbed_e, ntt)

					ntt.grabbed_e.ts.hitshock,ntt.grabbed_e.thrown,ntt.in_grab,ntt.grab_c=10,ntt,false,true
					delete_link(first_lnk(ntt,ntt.grabbed_e))
					-- delay collision swap so doesn't immediately clip in ntt
					dT(5, function() 
						ntt.grab_c = false
						ungrab(ntt)
					end)
					
				end

			end

			if ntt.in_grab then
				--ntt.magnetcharge += 1
				ntt.grabbed_e.grabbed = true
				--redirect grabbed object's fire - can still hit me
				--ntt.grabbed_e.shoot_dir=input_dir_h
			end
			
		end




		-- walking/air move ----

		local leg_pos,j_sf = (ntt.m_l_legs[1] or ntt).pos, ntt==player and 11 or 0
		local tx,ty = leg_pos.x\8,leg_pos.y\8
		
		local function wallset() -- panel gfx
			ntt.magnetcharge -= 1
			if in_tbl(mget(tx,ty),split"44,45") then
				mset(tx,ty,45)
				dT(5,function() mset(tx,ty,44) end)
			end
			
		end
		
		if (ntt.magnetwalk and #input_dir_l > 0) then -- and not slide?
			--if (input_dir_l.y < 0)
			--ntt.vel.y *= 0.2
			wallset()
		end
		
		local accel,vel_limit =  ntt.a_acc, ntt.a_max -- air drift

		if ntt.g_no_slide then
			accel,vel_limit = ntt.g_acc,ntt.g_max -- ground movement
		end
		if ntt.g_mode or ntt.b5 then
			uR(ntt)
		end



		local pv_add = input_dir_l*accel

		if ntt.sSt then
			if (not ntt.magnetwalk) ntt.magnetcharge += 10
			if (input_dir_l.x == 0) ntt.vel.x *= 0.15 -- brakes
		end

		if not (ntt.flying or (ntt.sSt and ntt.sticky)) then 
			pv_add.y = 0
		end

		
		local function can_add(vel,add)
			return vel*add < 0 or abs(vel) <= vel_limit
		end
		
		if can_add(ntt.vel.x,pv_add.x) then
			ntt.vel.x += pv_add.x
		end
		if can_add(ntt.vel.y,pv_add.y) then
			ntt.vel.y += pv_add.y
		end

		-- alignment direction
		local align_down,al_of,g_e=-vec2_up,ntt.vel*0.5,ntt.ground_entity
		
		if (g_e) g_is_ntt = g_e.Etyp != "tmp tile"
		-- jumping ----

		local jump_str,input_dir_j=ntt.jump_str,vec2_norm(input_dir_l + vec2_up*0.7*tonum(input_dir_l.y<=0))
		

		
		if ntt.b4 and jump_cooldown <= 0 then

		
			local function apply_jump()
				sfx2(j_sf)
				-- store jump state
				
				-- todo can replace min(g_e.bnce, 0.7) with fixed bounce for less tokens
				ntt.st_vel,ntt.g_bounce = ntt.vel*1, (ntt.g_mode and g_e.bnce >= 0.35 and min(g_e.bnce,0.7) * tonum_flip(vec2_dot(ntt.vel, surface_normal) >= 0)) or 0.05
				ntt.ts.jump_cooldown,jump_cooldown,ntt.st_surf,ntt.st_input=8,8,ntt.flying and input_dir_l or surface_normal,input_dir_l
			end
			
			

			
			-- jump cases
			
			
			-- the titular drop kick
			if ntt.g_mode and g_is_ntt then
			
				lose_stmn(g_e, 20+#ntt.vel*5)
				j_ntt,j_sf = mod_tabl2({},"pos,vel,mass,Iarm,Irss,bnce",{ntt.pos,ntt.vel,ntt.mass*3,0,1,1.6}),12
				
				impact(j_ntt, false, align_down, g_e, false, true)
				
				surface_normal=vec2_norm(ntt.pos-g_e.pos)

				align_down+=surface_normal*40
				
				if (g_e.Etyp=="enm") particles(g_e.pos, split"6,3,0,0.3,10",j_ntt.vel)
				
				ntt.magnetcharge += 50
				
				apply_jump()
				
			-- ground - no jump fall damage parries
			elseif ntt.jump_g and vec2_dot(ntt.vel,surface_normal) > -4 or ntt.flying then
				
				for leg in all(ntt.m_l_legs) do
					if leg.t_active then
						particles(leg.t_pos,split"7,1.6,0,0.5,6", surface_normal)
					end
				end
				
				if ntt.magnetwalk then
					if (input_dir_l.y > 0) surface_normal = -surface_normal
					ntt.magnetcharge -= 21
					j_sf = 13
					--particles(leg_pos,split"3,2.6,0,0.4,8",p_prevvel)
					wallset()
				end
				
				apply_jump()
			end

			


		end
		
		

		
		-- apply jump & calculate new velocity 
		if jump_cooldown == 8 or ntt == player and jump_cooldown >= 5 and #input_dir_l > 0.1 and input_dir_l != ntt.st_input then
			local st_surf = ntt.st_surf*0.95 + vec2_up*0.25
			
			
			local jump_vel = (recomp_mul(input_dir_j, st_surf,0.10,0.8) + st_surf)
			uR(ntt)
			
			for e in all(ntt.all_ntts) do
				if (not e.e_proj) e.vel = recomp_mul(ntt.st_vel,st_surf, ntt.g_bounce, 0.55) + jump_vel*jump_str
			end
			
			ntt.st_input = input_dir_l
		end

			
		if ntt.g_no_slide then
			align_down.x-=al_of.x
		else
			if ntt.b5 then
				align_down-=input_dir_l*2.5
			elseif jump_cooldown==0 then
				align_down+=al_of+vec2_up*0.5
			else
				align_down-=al_of*0.5
			end
		end

		ntt.leg_facing = ntt.leg_facing*0.8 + align_down*0.2
		ntt.facing = -vec2_limit(ntt.leg_facing)
		ntt.magnetcharge = mid(0,ntt.magnetcharge,70)
	end
	
	local i=1
	for leg in all(ntt.m_l_legs) do

		local l_link = first_lnk(ntt,leg)
		local l_l_len = l_link.true_len

		if not ntt.g_no_slide then

			move_towards(leg, ntt.pos + vec2_limit(ntt.leg_facing)*ntt.leg_len, 5-i)

			l_l_len *= 0.9
			if (not timer_ready(ntt,"jump_cooldown")) l_l_len /= i

		end

		l_link.len = l_l_len

		i+=1
	end
	
	if ntt.grapple then
		ntt.grapple.len -= 1.25
		
		if ntt.b4 or ntt.grapple.len < 3 then
			delete_link(ntt.grapple)
			ntt.grapple = nil
			ntt.vel.y -= 5
		end
	end
	
end


function Uply(pl)
	move_humanoid(pl)
	
	if pl == player then
		-- regen stamina
		if (pl.stmn < pl.stmn_l_t-pl.stmn_h_dmg and pl.ts.hurt <= 2) pl.stmn += 0x0.28

		mod_tabl2(pl,"iDir,armgrab,b4,b5",{
						vec2_left  * tonum(btn(0))
					+ vec2_right * tonum(btn(1))
					+ vec2_up    * tonum(btn(2))
					+ vec2_down  * tonum(btn(3)),false, btn(4), btn(5)})
	end

	move_control(pl)

end



-->8
-- level managment

function load_lvl(index)
	loaded_lvl_index,lvl_hiscore,m_title = index,dget(m_i),m_titles[m_i+1]

	loaded_level = split(lvls_info_2[index],"`")
	
	
	mod_tabl2(_ENV, "lvl_title,lvl_next_level,p_spawn_x,p_spawn_y,extraglobals,map_pos_x,map_pos_y,ld_l_size_x,ld_l_size_y,lvl_mus,layers_active,lvl_pal_addr,lvl_clearcol,lvl_bg1_loc,lvl_bg2_loc,lvl_entity_loc,lvl_numentities", loaded_level)

	-- clear map
	memset(0x8000, 0, 0x4000)
	
	for j=0, ld_l_size_y-1 do
		for i=0, ld_l_size_x-1 do
			draw_tile(mget0x20(map_pos_x+i,map_pos_y+j), i, j)
		end
	end

	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1
	
	
	pal({peek(lvl_pal_addr,16)}, 1)
end



function draw_tile(t,x,y)

	local t2 = t&0b00111111

	for j=0,3 do
		for i=0,3 do
			local m_x,m_y = x*4+i, y*4+j
			srand(m_x + m_y*ld_l_size_x)
			
			
			local s=mget0x20((t2%32)*4+i,(t2\32)*4 +4+j)
			local s1 = s&0b00111111

			-- alt layout
			if bcheck(t, 0b10000000) then
				if bcheck(s,0b01000000) then
					-- flip 3rd bit
					s1 ^^= 0b100
					-- swap to first sprite in 2x2 segment
					s1 &= 0b11101110
				end
				if bcheck(s,0b10000000) then
					s1 ^^= 0b1000
					s1 &= 0b11101110
				end
			end

			if bcheck(s1, 0b00100000) and (s1 & 0b00001000 == 0) then -- in bottom left part of spr page
				-- flip 1st bit
				if (rnd(20) > 19) s1 ^^= 0b1
			end

			-- alt texture
			if (bcheck(t, 0b01000000) and not fget(s1,7)) s1+=0b01000000
			
			mset(m_x,m_y, s1)
		end
	end


end

-->8
-- enemy ai and inits

function Uenm(enm)

	uR(enm)

	local look_dir = player.pos+player.vel*2 - enm.pos
	local dist = #look_dir
	
	enm.iDir *= 0
	mod_tabl(enm,"outl,sSt,b4/0,false,nil")

	-- passive ai
	enm.ai_p(enm)

	local t_gun = enm.ts.gun
	
	
	if enm.active then
		enm.outl=3
		if (t_gun<14 and t_gun%4>=2) enm.outl=10
		
		if (enm.hz) look_dir.y = 0
		
		
		if dist > enm.rngF then
			enm.iDir=look_dir
		end
		
		if dist < enm.jumping_d then 
			enm.b4 = true
		end
		
		if (player.grabbed_e != enm and not enm.in_burst) enm.shoot_dir = look_dir
		
		if colltrn(enm.pos + vec2_norm(look_dir)*enm.rds*1.5, enm.rds) then
			enm.iDir = -enm.rDir
		elseif timer_ready(enm, "gun") then
			fire_gun(enm)
		end
		
		if (dist < enm.rngN) enm.iDir=-look_dir
		
		if aC%20 == 0 then
			enm.rDir = vec2_rotate(enm.iDir,rnd())
			if rnd(1) < enm.dash and #enm.iDir > 0 then
				enm.iDir += enm.rDir
				enm.b4 = true
			end
		end
		
		
		-- active ai
		enm.ai_a(enm)

	else
		enm.ts.gun=enm.gun[1]/2
	end



	-- late update so doesn't bug out when immediately spawning in range
	
	if dist < enm.actN or alert then
		enm.active=true
		if (enm.procalert) alert = true
	end
	if dist > enm.actF then
		enm.active=false
	end
	
	-- TODO remove? 24 tokens
	if (enm.stmn/enm.stmn_l_t < 0.35 and aC%12==0) particles(enm.pos, split"6, 2.4,0,0.2,8", vec2_up*0.5)

end

-- passive ai
function AIPstbl(enm)
	move_humanoid(enm)
end

function AIPfly(enm)
	enm.vel *= 0.9
	enm.sSt = true
end

-- active ai
function AIAfllw(enm)
	move_control(enm)
end

function AIAhvr(enm)
	if (enm.pos.y - player.pos.y > -enm.rngN) enm.iDir.y = -0.75
	AIAfllw(enm)
end

function fire_gun(e)
	mod_tabl2(_ENV,"cldwn,p_t,spd,sf,angl,p_global,b_amount,b_delay,b_angl,nxt,p_extraprops,p_mods", e.gun)
	mod_tabl(e,p_mods)
	sfx2(sf)
	local proj = spawn_entity(0,0,p_t,e,p_extraprops)
	if (e.is_left and not proj.melee) angl = -angl
	if (proj.hz) e.shoot_dir.y = 0
	proj.vel+=vec2_rotate(vec2_norm(e.shoot_dir),angl)*spd
	if p_global=="tru" then
		proj.parent=nil
		add(entities, proj)
		proj.pos+=vec2_norm(proj.vel)*e.rds*1.7
	else
		add(e.all_ntts, proj)
		proj.e_proj=true
	end

	if b_amount > 1 then
		e.in_burst,e.ts.gun = true,b_delay
		e.gun[7] -= 1
		e.gun[5] += b_angl
	else
		e.gun=split(guns[nxt],"`")
		e.ts.gun,e.in_burst=e.gun[1]--,false
	end

end

function Umsl(ntt)
	if ntt.thrown != player then
		ntt.vel *= ntt.slip
		ntt.vel += vec2_norm(player.pos - ntt.pos)/8/ntt.mass
	end
end

function Usgn(ntt)
	if collsqr(ntt.pos, ntt.rds, player.pos, 1) then
		dT(1, txtB, split(ntt.txtB,"⬇️"))
	end
end

function Uhzd(ntt)
	local did,other = collntt(ntt)
	if did then
		coll_p(other,ntt.vel,2,ntt)
	end
end

function Blzr(ntt)
	dT(ntt.lzr_thck,
		function(p1,p2)
			line_vec(p1,p2,3,timer_t)
		end,
		{ntt.pos,ntt.parent.pos},true
	)
end

function DlEx(ntt)
	Blzr(ntt)
	dT(30,expl,{ntt.pos,explosions[ntt.dly_expl]})
end

function Chook(ntt,other)
	local thrower = ntt.thrown or ntt.parent
	if thrower then
		delete_link(thrower.grapple)
		thrower.grapple = make_link(thrower, other, split("1," .. min(#(thrower.pos-other.pos),180) .. ",30,4,15,2,3,0"))
		rmE(ntt)
	end
end

-->8
-- data

-- levels present in the menu and some strings

m_i,start_lvls,m_titles,m_splashes,m_lore_infos=0,split"1,7,14,21",split"task d1,task d2,task d3,task ??",split("finally, a day where our\n  name matches our service`you did bring a\n  parachute, right?``","`"),split("from: hq\n\nsome construction company's\nbots went haywire -\nthey're hoping we could\n'clean' up the situation\nbefore the public notices\nand it turns into a mess\nof paperwork.\nPERFECT OPPORTUNITY FOR \nYOUR 'SKILLS' :]`from: hq\n \nsame guys as yesterday,\nthis time it's one of their\nautomated cargo transports.\nmakes you wonder what\nthey're doing to get rogues\ntwice in a row, but hey as\nlong as they're paying i'm\nnot complaining.`from: hq`from: address unknown\n","`")

-- main info about all levels
-- 1: title
-- 2: next lvl (1-indexed, -1 is finish, -2 is no transition (for custom ones))
-- 3,4: player spawnpos x & y
-- 5: extra global vars

-- 6,7: map pos x & y
-- 8,9: x & y size
-- 10: music index
-- 11: music layers
-- 12: main palette address
-- 13: clear color

-- 14, 15: bg1 & 2 mem location
-- 16: entity array mem location (4096 + x + (y-32)*128)
-- 17: num entities

-- TODO update params to make sense
lvls_info_2 = split([[   the construction site  `2`28`58`/`0`23`23`4`7`1`8272`1`4312`4696`4096`5
1: roadblock`3`7`66`/`23`23`16`4`8`3`8272`2`4312`4952`4224`5
2: magnetizing yourself`4`6`328`/`69`21`15`11`8`3`8272`2`4312`4952`4352`8
3: detour`5`4`188`y_u_l,lvl_e_req/-72,3`56`25`7`7`8`3`8272`2`4824`5080`4480`4
4: mayhem square`6`4`200`y_u_l,lvl_e_req/-64,4`0`12`14`11`8`7`8400`0`4192`5080`4608`8
5: the small issue in question`-1`4`116`y_u_l,lvl_e_req/-32,1`29`12`12`6`8`7`8400`0`4192`5080`4736`2
  the hijacked transport  `8`16`88`x_u_l,y_l_l/-128,384`84`14`14`5`24`7`8528`2`4216`4344`4864`4
1: what a blast`9`10`88`/`0`26`12`4`28`5`8528`1`4472`4600`4992`4
2: hang in there`10`4`284`y_l_l/384`78`21`11`11`28`5`8528`1`4472`4600`4128`4
3: nice weather up here`11`10`115`/`14`18`15`5`28`13`8656`12`4728`4856`4256`7
4: broken access bridge`12`44`100`lvl_e_req,y_u_l/4,-96`28`18`18`5`28`13`8656`12`4728`4856`4384`6
5: annoyingly out of reach`13`8`128`y_u_l,lvl_e_req/-96,1`69`17`11`4`28`13`8656`12`4728`4856`4512`3
control cabin`-2`6`36`x_l_l,y_l_l,y_u_l/256,96,-96`78`17`4`3`7`1`8656`12`4728`4856`4640`1
  the lowlands  `15`240`56`/`103`12`10`9`-1`7`8288`2`4208`4336`4768`6
1: bouncy castle`16`4`315`/`103`21`10`11`38`3`8288`4`4208`4464`4896`6
2: the horrid sludge pits`17`8`170`sludg_l/196`113`12`15`7`38`3`8288`5`4464`4720`5024`5
3: hunted`18`4`154`y_u_l,sludg_l,lvl_e_req/-96,169,4`113`19`15`6`38`3`8288`2`4592`4720`4160`6
4: the moat`19`4`28`y_u_l,sludg_l,lvl_e_req/-96,205,5`113`25`15`7`38`7`8416`1`4312`4848`4416`6
`20`11`66`y_u_l/-32`39`22`9`3`-1`3`8416`1`4312`4848`4416`0
`-2`17`75`y_u_l/-32`58`12`8`4`38`7`8416`1`4312`4848`4544`1
     the cache    `22`4`83`sludg_l/142`39`25`9`5`38`7`8544`0`4440`4320`4548`0
`23`4`20`sludg_l,sl_vx,sl_h,sl_spd/93,-0.6,0.35,13`0`29`16`3`38`7`8544`9`4184`4184`4672`0
1: into the system`24`4`70`/`11`26`13`5`38`7`8544`4`4184`4184`4288`4
2: floodgate`25`4`44`sludg_l,sl_vy,sl_smth,sl_h,sl_spd/57,-0.9,0.97,-0.66,18`24`26`10`6`38`7`8544`1`4184`4184`4800`0
3: lost in the architecture`26`4`124`/`46`15`12`12`48`21`8544`4`4184`4184`4928`0
4: `27`4`458`sludg_l,sl_r,sl_c,sl_dmg,y_l_l,sl_h/498,-0.37,2,1,1024,0.2`63`17`6`15`48`7`8672`8`4320`4184`5056`0
5: `-1`80`458`sludg_l,sl_r,sl_c,sl_dmg,y_l_l/498,-0.37,2,1,1024`98`17`5`15`48`-5`8672`4`4320`4184`4416`0
1: over the fence`29`4`34`/`41`12`12`6`38`7`8304`0`4192`4952`4416`0
2: `30`4`178`/`10`12`19`6`38`7`8304`0`4192`4952`4416`0
3: `31`4`255`/`89`19`10`13`38`7`8304`0`4192`4952`4416`0
4: `32`12`314`x_u_l,x_l_l/-64,240`57`17`7`11`38`7`8304`0`4192`4952`4416`0
5: `32`12`314`/`5`12`16`13`38`7`8304`0`4192`4952`4416`0
6: `32`12`314`/`18`12`31`6`38`7`8304`0`4192`4952`4416`0]],"\n")






-- list of almost all entity types
--[[
	1: default box - used as template sometimes
	2: player - high slipperiness allows for easy 2 block climb
	3: UTIL: basic limb for entities

	4: ENEMY (lvl1): horizontal turret

	5: ENEMY (lvl1): basic targeting turret

	6: ENEMY (lvl1): laser turret
	7: ENEMY (lvl1): flying drone

	8: BOSS (lvl1): big walker tank

	9: standard projectile
	10: boss 3 defeat cutscene part 1

	11: ITEM: hp

	12: MISC: tmp tile - 30x (!!) the mass to enable proper bounces
	13: MISC: sign - ignores physics, displays a text box on player coll (text is added as extra in level)

	14: boss 3 defeat cutscene part 2
	15: ITEM: trinket

	16: MISC: grappling hook

	17: dual laser hazard
	18: ENEMY (lvl2): missle base
	19: PROJECTILE (lvl4?): sawblade
	20: PROJECTILE (lvl2): grabbable missle
	21: PROJECTILE (lvl3): laser targeting recticle

	22: BOSS (lvl2): big aircraft
	23: BOSS (lvl3): cool shades
	
	24: ENEMY TEMPLATE
	
	25: Spike hazard
	26: Sawblade hazard
	
	27: Grabbable bouncable mushroom
	28: ENEMY (lvl3): sniper drone
	29: ENEMY (lvl3): hunter spider
	30: alarm
	31: drone egg (spawns 28 by default) -- REMOVE?
	32: ENEMY (lvl3): shotgun drone
	33: passive-looking alarm
	34: decal
	35: laser bolt
	36: ENEMY (lvl1): missle spider
	37: PROJECTILE (lvl1): slow missle
]]

-- NOTES: masses lower than 0.1 bug link-related movements
-- enemies with flying ais need "flying" prop in order to move up/down

--[index, x size, y size, frame duration, num frames]

-- template, radius, mass, sprite | extra properties (key1,key2/val1,val2)
-- prefix _V_ means an env variable of that name (minus the prefix obv)
ntt_types = split([[0,3.5,0.4,241|Df/_V_e
0, 2,  0.6,160|Uf,Df,Btyp,stmn,stmn_h_dmg,Iarm,Irss,slip,Etyp,in_grab,grabbed_e,col,outl,ray_iters/_V_Uply,_V_Dply,2,70,0,5,5,0.99,player,false,nil,12,9,6
0, 0.9,0.1,nil|Df,slip/_V_e,0.9
24,5,  0.4,164|rope,rX,rY,hz/1,0,15,t
24,5,  0.4,162|rope,rX,rY,gun/2,0,16,9
24,5,  0.9,166|rope,rX,rY,rope_e,stmn,gun/8,0,-45,d_o➡️2,90,2
0, 6,  0.3,180|ifi,Uf,Df,Btyp,stmn,Iarm,gun,ai_p,ai_a,enemy,smok,flying,rngF,rngN,slip,f_c,dash/_V_Ienm,_V_Uenm,_V_Dntt,1,50,2,1,_V_AIPfly,_V_AIAfllw,true,1,true,35,20,0.9,3,0.6
24,12, 3,  170|Btyp,stmn,Iarm,Irss,gun,ai_a,smok,rngN,rngF,spr_size,actN,actF,g_i,sprW,sprH,grav/4,175,2,2,6,_V_AIAfllw,5,35,55,16,55,2000,t,2,2,0.05
0, 3.3,0.4,167|Cdmg,grav,smok,stmn,bnce,dur/14,0,3,0,0.8,60
0, 2  ,0.4,177|Btyp,Df,dur,next_e,col/3,_V_Dply,40,14,6
0, 2,  0.1,240|Uf,item,amount,smok,ignS/_V_Uitm,5,25,2,true
0, 4,  30,  14|Etyp,smok,g_i/tmp tile,1,t
0, 9,  2,  244|Uf,nophys,d_o/_V_Usgn,t,1
2, 2,  0.4,177|Uf,Btyp,dur,break_func,iDir,col,b4/_V_Uply,3,60,_V_d_load_next,_V_vec2_right,6,t
0, 4,  0.2,246|Uf,item,smok,ignS,f_c,f_l/_V_Uitm,4,4,true,3,6
0,3.5,0.28,241|coll_func,respawn,grav/_V_Chook,true,0.15
0, 3.5,0.2,166|ifi,Uf,nophys,gun,ai_p,ai_a,stmn,hz/_V_Ienm,_V_Uenm,t,20,_V_e,_V_e,1000,t
24,7.5,6,  161|Iarm,gun,rngF,spr_size,hz,actN,actF,g_i/0.2,10,90,16,true,70,130,t
0, 4,  0.1,183|Cdmg,kb,grav,stmn,bnce,ignS,outl,f_c,f_l,dur/4,1.5,0.05,90,0.95,true,3,3,1,150
0, 2,  0.4,168|Uf,smok,stmn,ignS,expl,grav,slip,f_c,f_l,dur/_V_Umsl,3,0.3,true,2,0,0.97,2,4,110
9, -9,0.45,228|Uf,Cdmg,break_func,expl,slip,stmn,Irss,smok,dur/_V_Umsl,nil,_V_Blzr,3,0.89,100,500,6,75
24,9,  3  ,172|Btyp,spr_size,ai_p,ai_a,actN,actF,rngN,rngF,gun,stmn,hz,smok,flying,Iarm,g_i,sprW/6,16,_V_AIPfly,_V_AIAhvr,110,2000,50,60,11,125,true,5,true,0.2,t,2
2 ,2,  0.4,177|ifi,Uf,Btyp,stmn,boss,ai_p,ai_a,gun,col,rngF,rngN,actF,actN,jumping_d,next_e,enemy/_V_Ienm,_V_Uenm,3,200,t,_V_AIPstbl,_V_AIAfllw,22,6,100,60,500,500,20,10,f
0, 5,  0.5,164|ifi,Uf,Df,Btyp,stmn,Iarm,gun,ai_p,ai_a,enemy,smok/_V_Ienm,_V_Uenm,_V_Dntt,1,60,2,1,_V_AIPstbl,_V_e,true,1
0, 7,  1  ,233|Uf,nophys,spr_size,d_o,Cdmg,kb,sprW,sprH/_V_Uhzd,true,8,2,8,1.5,2,2
25,7,  1  ,183|spr_size,Cdmg,f_c,f_l,sprW,sprH,outl/16,20,3,2,1,1,9
0, 7.8,0.2,245|Uf,rope,rX,rY,bnce,spr_size,d_o/_V_e,13,21,0,0.4,16,4
7, 8,  0.4,188|Btyp,gun,rngN,rngF,actN,actF,stmn,ai_a,sprW,f_c,dash/6,14,50,70,70,130,70,_V_AIAhvr,2,1,0
24,5,  0.7,179|Btyp,stmn,gun,ai_a,rngF,actF,Irss,melee/8,70,15,_V_AIAfllw,10,170,3,tr
24,3.5,0.25,178|Btyp,gun,stmn,procalert/1,18,30,true
24,4.5,4,  166|ai_a,next_e,enemy,actN/rmE,28,f,45
7, 8,  0.7,172|Btyp,gun,stmn,sprW,f_c/7,19,55,2,1
0, 3.5,0.2,  4|/
0, 8,  1  ,nil|Df,nophys,d_o,decal/_V_Ddcl,t,1,▒▒▒▒
9, 5,0.01,   0|Cdmg,kb,break_func,lzr_thck,smok,bnce,dur/10,0.4,_V_Blzr,4,7,0.1,6
24,6,  0.7,165|stmn,Irss,gun,rope,rX,rY,dash/85,3,3,2,0,16,0.6
20, 2, 0.7,167|expl,slip,dur/1,0.985,50]],"\n")



-- modifications for certain entities in level, no newlines to keep control chars (made in lvl editor)
ntt_extrainfos=split("/⬅️procalert/true⬅️next_e/11⬅️rX,rY/16,0⬅️rX,rY/-16,0⬅️rX,rY/0,-16⬅️rX,rY/-13,-13⬅️Btyp,rope,ai_a,rngN,rngF/5,nil,_V_AIAfllw,35,70⬅️gun/9⬅️boss/true⬅️rope,rX,rY/6,76,-20⬅️break_func/_V_d_load_next⬅️is_left/t⬅️is_up/t⬅️is_left,is_up/t,t⬅️rX,rY/-15,15⬅️txtB/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️4⬇️44⬇️42⬇️2⬇️1⬅️rope,rX,rY,rope_e/8,-45,-8,d_o➡️2⬅️/⬅️txtB/\fastaff is advised\n to only \fcgrab the\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1⬅️decal/\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!\*f \*f \*f \*5 \^h\n🅾️\n\n\|c \-e+\n\n\|c\-f\^:10387c1010100010⬅️decal/\f2\^o0ff\^:00008064320f0204 \^h ❎\|e\n\ng\|fr\|fa\|fb  \|e\^:0000070c90a0c0f0⬅️/⬅️/⬅️actF,rngF,rngN,ai_a/400,180,30,_V_AIAfllw","⬅️")


-- body info for complex/limbed entities
--[[
1: box (no limbs), air move ok - basic drone
2: humanoid
3: enemy humanoid
4: big walker
5: bipod spider
6: slow boss drone
7: fast drone
8: hunter spider
]]

-- sticky_walk, grnd_accel,air_a,g_max_spd,a_m_s,jump, leg_len,arm_len,stand_height, leg speed,leg group cd, max leg target rotation,
-- IMPORTANT: MAKE LEG_LEN SIGNIFICANTLY LOWER THAN ACTUAL LINK RANGE OTHERWISE CAN GET STUCK
-- limb info at 13+th array slot:
-- entity type, limb type (a/l arm or leg), angle, link array index, link extraprops
ntt_b_types = split([[false` 0.15`0.15`4`4`2.9` 18`1`20` 3`3`0.01
false` 0.8`0.21`2.05`1.05`2.1` 8`5`7.5` 3`2`0.2`  3`l`0.015` 10`➡️`  3`a`0.02` 9`➡️`  3`l`-0.015` 10`d_o➡️3`  3`a`-0.02` 9`d_o➡️3
false` 0.3`0.21`2.05`1.05`2.1` 8`5`7.5` 3`2`0.2`  3`l`0.015` 10`col➡️15`  3`a`0.02` 9`col➡️6`  3`l`-0.015` 10`d_o,col➡️3,15`  3`a`-0.02` 9`d_o,col➡️3,6
false` 0.2`0.05`1.2`1`0` 42`1`40` 10`3`0.10`  3`l`0.03` 12`➡️` 3`l`-0.03` 12`➡️
true` 0.15`0.05`1.5`1`2.4` 15`1`12` 4`6`0.6` 3`l`0` 11`➡️` 3`l`0.5` 11`➡️
false` 0.14`0.14`1.5`1.5`0` 18`1`20` 3`3`0.01
false` 0.18`0.18`4`4`3.1` 18`1`20` 3`3`0.01
true` 0.15`0.1`2`1`2` 18`1`16` 4`6`0.2` 3`l`0` 11`➡️` 3`l`0.5` 11`➡️]],"\n")



--[[
1:standard
2:lvl2 laser sweep
3:lvl1 missle
4:UNUSED (l1 bomb)
5:sawblade
6,7,8:boss 1 sequence(x4 spread, x2 missle, laser sweep)
9:standard burst
10:missle
11,12,13:boss 2 sequence(x3 slow missles, x1 saucer, downward storm -- TODO rework)
14:laser snipe
15:melee sawblade
16:UNUSED (sawblade 2)
17:empty,blink -- REMOVE?
18:empty
19:shotgun
20:laser spin
21,22,23,24: boss 3 sequence (laser, hook throw, dropkick, another hook throw)
]]
-- cooldown,projectile entity,p speed,fire sfx,angle,is global,burst amount,burst delay, burst angle shift,next gun,extra projectile props, entity prop modifiers
guns = split([[45`9`2.5`18`0`fls`1`1`0`1`/`/
70`35`13`-3`0.12`fls`18`2`-0.012`2`/`/
90`37`1`23`-0.25`fls`1`1`1`3`/`/
65`10`3`11`0`fls`1`1`0`4`/`/
60`19`3`20`0`tru`1`1`0`5`/`/
70`9`2.25`18`-0.03`fls`4`7`0.01`7`kb/0.7`/
70`37`1`23`-0.11`fls`2`20`0.09`8`/`rngN,rngF/45,90
70`35`13`-3`0.22`fls`10`2`-0.022`6`Cdmg,rds,hz,lzr_thck,break_func,dly_expl,dur/0,2,true,8,_V_DlEx,4,15`rngN,rngF/35,55
60`9`3`18`-0.03`fls`3`8`0.03`9`/`/
65`20`3`11`0`tru`1`1`0`10`/`/
140`20`1`11`0.25`tru`3`40`0.1`12`/`/
75`7`3`13`0.35`tru`1`10`0.5`13`stmn,enemy,next_e,dur/60,f,11,225`/
120`9`3`18`0.225`fls`14`4`0.002`11`dur/70`/
75`21`2`0`0`fls`1`1`0.08`14`/`/
1`19`9`0`-0.40`fls`50`1`0.02`15`dur/1`/
1`19`8`0`0.40`fls`40`1`-0.02`15`dur/1`/
12`1`0`0`0`fls`1`1`0`17`dur/0`/
999`1`0`0`0`fls`1`1`0`18`dur/0`/
70`9`3`19`-0.07`fls`3`1`0.05`19`/`/
1`35`10`0`0.25`fls`999`1`0.495`20`melee,dur/t,5`/
30`16`9`22`-0.02`fls`1`1`0`22`respawn,dur/nil,60`rngF,rngN,b5/0,0,nil
10`21`2.5`0`0`fls`1`1`0`23`dur/55`rngF,rngN,dash,b5/120,60,0.5,t
40`9`4`0`0`fls`1`1`0`24`/`rngF,rngN,jumping_d,b5/3,0,30,nil
120`9`2.5`0`0`fls`1`1`0`21`/`rngF,rngN,dash,jumping_d,b5/90,80,0.9,10,t
]],"\n")

-- 1-col, 2-radius, 3-sfx (0 if none), [ 4-decay rate ], [ 5-time ]
--[[ standard break,
hp pickup,  
projectile collide, 
item pickup, 
boss explode,
laser,
minilaser smoke
]]
smokes=split([[13,3.5,16
12,3,0
7, 2.5,0
12,3,8
7,8,-2,-4,7
3,3,19
7,2,0]],"\n")



-- 1 directional turret joint
-- 2 standard machine joint
-- 3 longer machine
-- 4 easy break (TODO remove)
-- 5 very long (also remove)
-- 6 super long, unbreakable (swing) -- TODO PROBABLY DONT NEED SWINGS (MAYBE KEEP 8 AS AN EXTRAPROP IS USING IT)
-- 7 swing, even longer -- AS WELL
-- 8 swing, shorter -- MAKE BREAKABLE?
-- 9 playerlimb - arm
-- 10 playerlimb - leg
-- 11 enemylimb - spiders
-- 12 enemylimb - big walker
-- 13 very short flowerswing
-- link_type (0-keep at distance, 1-keep close, 2-keep far), len, link_strenght, draw_type (DEPRECATED[0-none, 1-line,] 2-joint,3-legjoint,4-noflip joint), col, width, draw order, outline color (0 is none)
links = split([[1,20,1,2,13,2,2,0
1,20,1,4,13,2,2,0
1,28,1,4,13,2,2,0
1,20,0.5,4,13,2,2,0
1,38,2.5,4,13,2,2,0
1,80,0,4,13,2,3,0
1,120,0,4,13,2,3,0
1,50,1,4,13,2,3,0
1,5,0,2,12,0,2,9
1,8.7,0,3,7,0,2,9
1,19,0,2,13,2,2,0
1,50,0,2,13,14,2,0
1,25,0,2,94,2,3,0]],"\n")

-- radius, str, sfx
--[[ small, 
medium,
laser (sniper)
laser (delayed,mini)
]]
-- be VERY CAREFUL with the str val
explosions = split([[14,7.5,17
16,8,17
10,10,17
11,7,17]],"\n")

-- player hurt noises, giga explosion, mini laser, throw, hp pickup
ex_sfx = split"\as2v2i6g#3<d4c4i0c4c#4g#3g#2,\as7v2i3x3f2fv7i6f<f<f<f<f<\*ffi2f0\*ff\*ff,\as5v1i2c2c1c0,\as2v3i6x3g2c>x0d#2i7f#3x1g1a#2f0d#d#,\as2i7v6d#0a#g#d#1g#c#g#g#2d#3g#3..<g#3..<g#3..<g#3"

bg_pals = split([[0,1,2,0
0,0,0,0
0,0,1,0
0,1,1,0
0,2,2,1
2,1,1,2
1,1,2,1
1,2,2,1
2,2,2,2
5,0,1,2
4,5,0,0
4,4,5,2
4,5,5,4
5,4,4,4
0,4,5,5
5,5,5,5]],"\n")

__gfx__
00000000555555545555555444444444aabbbaa9ba999999e9a8abeabaeae9abbe8448ea00000000ebebebebbbbbbabb444444450000000077777d7877787778
00000000555555445444444455555554beeeeee8a9888899e9e8b9e999999999bb8448ba000000008ae9e98a8b8998b844545455000000007dd78788ddd88d88
00000000544444445444444454444444be9999e899999999e9e8a999e9e9e9e9bebeebea00000000aabaaba998b88b8945454545000000007dd788787877d888
00000000555555445444444454445454be9999e8a88888899998a9e9e9e999e9b98bb89a00000000aaeaaea9449bb94444545455000000007d78ddd8d8d888dd
00000000544444445444444454454454ae9999e899999999e9e89999e99999e9b98bb89a000000008aaaaa98449bb94445454545000000007788ddd8778d7788
00000000555555445444444454444454ae9999e899888898e998a9e999999999bebeeaea00000000aabaab9898b88a89445454550000000078d78dd8dd888dd8
00000000444444445444444454444454aeeeeee899999998e9e8a9e9999999e9bb8448aa00000000aaeaaea98b8998a845454545000000007dddd8d878dddd88
0000000055544444444444444455555498888889999998889988a99999999999be8448ea00000000baa99aa9aaaaaaaa5555555500000000d888888d8dd88888
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
05000505050000050000000500000005b8bbbbbbbbbbbbbb999999999eee9e9e545b45b499999999aa9bba9bbbbbbbbb999999995544444455544444babbbbba
050005050500000555555555000000558bbeeebeeebeeebe99999999999e999e54a5a5ab99999999ba9bba9bbbbbbbbb999999995544445555544444aaa999a9
55005555050005050505050500000505be899989998999899999999999e99e9e4b5a4aa599999999ba9baa9baaaaaaaa999999995544444455555444aaaaaaaa
55500555050005055050505550000055be999998888888889999999999999999a9b45baa99999989ba9bba9ba99aa9aa99a999995544444555544444aaaaaaaa
05000505050005050505050505000505be9999988beeeeb89999999999999a999bba99a988888888ba9bba9b9999999999a9aa9a5544444455554444aaaaaa9a
05000505050005055555555555555555be9999988899998899999999a9eaaaae9a89aa9999989999ba9bba9b99999999aaaaaaaa5544445555554444a9aa9a99
05000555550055055555555555555555888888888b9999b8999999999eea9e9ea9aa99a988888888ba99aa9999999999bbbbbbbb554444445554444499999999
5500050555000505555555555555555588889998888888889999999999999aaa8aa88988888888889988998899999999bbbbbbbb554444455555444488888888
aaaaaaaa555445445544455455544455ab9b9995babbba9877f9f9fffff9f9ff909fd090abbabbabf7ffffff99900999aaaaaaaa44444445aaaaaaaaaaaaaaaa
a000000a5455444445544544544545559bbbbbb9b8baa8987f7fffffffff9fff999fd090baabba8a7f7fff7f9f7fffffa000000a46666665a000000aa000000a
a0000a0a444445544454554445444554abbababab8baa898f7ffff7fffff7fff009ffd9889a88b88f7fffff7f7ff7fffa0000a0a46444445a0000a0aa0000a0a
a000a00a554555445444454545445544abbaaa9aa8a88888fffffffffff7ffff0f9dd88888a899b8fff7ffff8fffffffa000a00a46545555a000a00aa000a00a
a00a000a5445545444445454445454449ab9b9aababbba98ffffffffffffff7ffd9fd9908a8899a8ffffffff9f8f8f8fa00a000a46444445a00a000aa00a000a
a0a0000a4455444555445444444444449a9a9aa9b8baa898fffffffff7fff7f7ddddd080aa988aaaf8f8f8f80888f8f8a0a0000a46555555a0a0000aa0a0000a
a000000a445444445444554455444445999a9a99b8baa898f9fffff9f9ffff79080fd980a8a88a8a89898989f989897fa000000a46444445a000000aa000000a
aaaaaaaa44444455444445445444445589999999a8a888889f9f9f9f9f9fff9f089fd800a8a88a8898989898f80099ffaaaaaaaa55555555aaaaaaaaaaaaaaaa
45444545aaaaaaaa11111111aaaaaaaa9899999999999989baabbbabaaaaaaaaaaaaaaaa4a5a959aaaaaaaaaf7ffffff05445050aaaaaaaa0000000054999999
54544444a000000a11010111a000000a899999999999999898899999a000000aa000000aa454a49aa000000a7ffff7ff05045550a000000a0555555054499a99
54444454a0000a0a01101011a0000a0a889999999999998888888888a0000a0aa0000a0a4954a494a0000a0affffffff55055500a0000a0a05555554445999a9
44444544a000a00a10110110a000a00a588999999999998988988899a000a00aa000a00a45999994a000a00af9f9f9f905454505a000a00a5555555445494999
44444444a00a000a01010001a00a000a589999999999988988888899a00a000aa00a000a4549449aa00a000a9f9f9f9f05554555a00a000a5454545445494999
44454444a0a0000a00100000a0a0000a899999999999998599888888a0a0000aa0a0000a99a9594aa0a0000a8989898900454500a0a0000a4545454555454449
44445445a000000a00000000a000000a899999999999999899888898a000000aa000000a9aa49a59a000000a8888088805454500a000000a5454445555455459
45444444aaaaaaaa00000000aaaaaaaa999999999999998988898888aaaaaaaaaaaaaaaa9a44aa59aaaaaaaa0808008004454550aaaaaaaa0404040455555454
454455455454554455545554555455549bbb99a99ba999995b5bb5b55b55bb5b000000004a54ba5aba9bbab900000000000000000055500000000000aaaaaaaa
54545454455454545554555455545544bbaaaa99ba999999bbbbbbbbbbbbbbbb00000000ab94aa4ba99babab00000000055555004444550000000000a000000a
55444544545544545554555455544454aaaaaa9b99999bb9abbbaababbababbb00000000a9b9a99aba9b9ba900000000000445555555525000999000a0000a0a
454545454554545544444444444444449aaaa9999999baa9ababaa9aabaabaab0000000099aa9a9aba9a9ba9000000000444544c5cc444200087d700a000a00a
54545444545545545554555444455444b99999bbbbb9aa999a9aa9a9aaa9ba9a00000000999a9a9aba9b9ba90000000044c445544444c44000999000a00a000a
45454445454544555554555444555544aaa9bbbaaa99999aa99b9aa9a9a99a9a0000000099a99a99aa9b9a99000000004c4c4544454c4c4000000000a0a0000a
45455454454544545554555444455544aa99baaaa999ba9aa9ab9a9aa99a99a90000000099999999ba9b9ba90000000044c445000544c44000000000a000000a
54445454554554554444444444445444a9999aaa999aaa9999a9999a999999a90000000099999999ba9baba900000000044400000004440000000000aaaaaaaa
50450405000500500000000000000000bbbabbbabbba88b8aaaaaaaa99a99999aaaaaaaa99999999ba9b9ba997f9f979545454545445454444444454bbbabbba
44540455050450450000400400000000baa8baa8baa88baaa000000a9a99a999a000000aa99999a9ab9baab87f7f97f7545554555445454454555554baa8baa8
04545454045540055054004005004500baa8baa8baa8aaa9a0000a0a99999a99a0000a0a99899a99ba8a8babf7f9f979544444445444454444444444baa8baa8
54544044054040540405005454045040a8888888a8888aa8a000a00a9999a9a9a000a00a99599999bb8aab8b9f9f9f9f455555555445545455554454a8888888
55454540454540450545050445055405bbbabbbabba98888a00a000a9a99a9aaa00a000aa9895999bababa8af979f9f944444444544445444444454588988988
54504545505445554545454540050454baa8baa8ba988988a0a0000aa99999a9a0a0000a5a858989a9baba8b97f7f7ff44444444544445444455445498988998
54555045545445545405554554505455baa8baa8a9988989a000000a999a999aa000000a59885989b9b99889f9797f7955545554544455554544445499989999
44545445045404555554555554545545a888a88898889989aaaaaaaa99999999aaaaaaaa88585885b99bab899f9f97ff44545454544444445444445488888888
40d8611070ea211050bad140d0d631112242815100000000000000000000000001e0f41001e374107043441060b4031000000000000000000000000000000000
c156b091c1371291e105d210c103d091c14480910202711000000808080808087710284808ca080800000000000000003d102828050a080814102828050ae9d7
504351207042112040d4017050c7d04022f40161000000000000000000000000217281306005211021a72110f0d6b01001b332100157711060b1411000000000
a181a110a1e2e110a122c11011d3a1100000000000000000261028280b4918084d0028eb0a0c080800000000000000003e1038480a8a0808161058480a66daa7
50a1c110f0d0711050b2c3214094d12070f3803070b4801070c1b21042c6e18021f322306013308021c8c13001d271107075001042c540800000000000000000
0201131002821220c1b33210c1d53310025671200267a210201028280b49f708500038280808080800000000000000003e10e70a0a0c0808273038080866e917
42c2508042a2b18042f0508042c1d22100000000000000000000000000000000610500a001c1f010016431100000000000000000000000000000000000000000
71628110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000036102889bc0c0808273048880a4cda26
42423440422494214253e0407056412070e5e03042758280428443807005c410e13231c000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000100048880c280808000000000000000000000000000000003e10288a086d08082710384808e8e908
b04271108015d1a0000000000000000000000000000000000000000000000000b1223250918123d0b121e250b112e41091d4941091f364e00000000000000000
000000000000000000000000000000000000000000000000171038185ae808080000000000000000000000000000000031102809084b0808271058880829cb08
50b4f18070c3e0105042914050c4214000000000000000000000000000000000b1c4d310c1c29310c1f271100243b120f041f010b14121100000000000000000
00000000000000000000000000000000000000000000000013005888838808080000000000000000000000000000000000080000000000000008000000000000
d0b1d14121a3a130701541102126a11000000000000000000000000000000000b1325301c132b110c1c5611002545110910221f00145b2100000000000000000
0000000000000000000000000000000000000000000000000a105888058708080000000000000000000000000000000000080000000000000008000000000000
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
00f6600000fff0000300600366d66d66366366363d366363d36636636660666660660660660660066d666666666666d3ddd8068668608ddd000096666e690000
00f33300006766000366666366d66dd366666666666666666666666606666006660666666666666066d666666666d3d3dddd68633686dddd000dd966669ee000
0066600000f6d6000300600366d33d66666666666666666666666666600666606666606606666666d66dddddddd3d3d38ddd08633680ddd8000dd0d99e0ee000
0000000000f000000036663066d33dd33366663333666633776666776666066606606606600660660d63636366d3d30080ddd086680ddd0800d000ddee000e00
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
22221233333322212332222200000000444444000000444400fffd000baa99a0d99fd980a989895888ab9898aa999aaaaa9999999aaa9999989898989aaa9999
1212332332321212322321110000000044444444000044440f7fdd800a99809a09ffd90098998599888a888899aaaaaaaa9999999aaa999998899988aa999a99
1123322223212122223211120000000044444444000044440ffddd80ba9099000ffd98009899589888898888aaaaaaaa99999999aaa99999999999999aaa9999
1332221222221121212111230000000044444444000044440fddd880ba08aba00fd980009999959a88898888aaaaa999aa999999aaa999a998899988aa999a99
3321211122111211121112320000000044444444004044440ddd8860098a80b90d989900a9a9595a89898899aa999aaaaa999999aa9a99a9989898989aaa9999
12121111111111111111112100002220444444444044444400888600009898b9f988d9008ab5bb5b8899889999aaaaaaaa999999aa9a99a999889889aa999a99
112111111111111111111211222222224444444444444444000000000098a9b9d989f980bb5babb599999888aaaaaaaa99999999a9aa9999999999999aaa9999
0022222201011111000000001113233200000000010000000000000010101010111111110000000000000300a88000000000000000bb000000000000000b8000
022222331010111100222000122222110330033000d010d001000d3d000000001111111100000000030003000800000000bb0000bbbbbb00000000000b888800
222233331101010122222220222121110300003006360000000006d610101010212121210030000003000300a080000000abb000abbb88000000000ba8888880
22233323010000103333222212111322000000001000001010001000010101011111111100030000030030000800000000a88000aaa88800000000baa8888880
2332222200100000322232002111322100000000001000010010001010101010212121210000300003003000000000000aa88000aaa8800000000baaaa888888
33212121000000002122130011121211030000300000d0d0d636d00101010101121212120000033033033003000000008aa80000aaa880000000baaaaa888888
121211110000000012111220112121110330033001066d660060100d11111111222222220000003333033003000000000aa00000aaa88000000baaaaaaa88888
112111110000000021111122111111110000000000001300010000000101010112121212000000033b033030000000000a000000aa88000000baaaaaaaa88888
00000000fddddddf00ffff0000dddd00000000220ff7fff000dfddd00ddf700000ddd0000033003a33b3b030000a080000aa88808a80000000aaaaaaaaaa8880
00fffc00dffddffd0f7ffdd00dddddd022222252f7fffff70fffffdddff777f00ddddd000000330393b3a3300000bb0000aa88800800000000aaaaaaaaaa8880
0f7cccc0dfd7cdf8f7fdddd8d3ddddd325a2aa20fffffffd0dfff880dd777fd0008880003300a33b3b8ab3300000abbb00a8880000800bb0000aaaaaaaaaa800
0fcccc800ddccdd8ffdddd88dd7ddd3d02222220dfffdddd0ffcffddf77ccfff0ddddd00003330a9b3a8b3000000aa8800a88800080abb80000aaaaaaaaaa800
0fcccc800ddddd80ffdddd86ddd773d802aa2a208d8888880ffcff88777ccfff08dddd00000033389b898bb0000aaa8800a88800000aa8800000aaaaaaaaa000
0cccc88000dfdd80fdddd886ddd7dd8602222220080888800dfff880d7ffffd0008880000000baba8ab89a33000aa8800aa88000000aa8800000aaaaaaa00000
00c8880000dff8000dd888600dd3d86002aaa252000800800fffff88dffffff008dddd0033333aab88ab8390000aa8800a888000000aa88000000aaaa0000000
00000000000df8000088660000838600252222200000000000df88800ddff000008880000000333a8888aa89000aa8800a880000000aa88000000aa000000000
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
8808080801010101010001018800838308888888010101818101880108880808080808080101010100010108888881810808080801018101810101010108080100080808010111111101111100080000080000000101010000010011080008080808080801010101000101000808000008080808010100010001011108080801
0000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001000001000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d400000000d3c0c1c2e2d371707173727371730c0c7d7e7d0c0c0c00fb00000000eeef00e90000e9000000e7e7e7e7e7e7e7e7e5e6e6e5e6e6e5e6000000acad0000008f0f0a8e8f0007820288080c0d02068e8a8789018300070081838b0e8d810c03818c0e008100070082020e0c0d820600
cfce00dbdc00dd36c4c6d5c6c510c4c5c0c1e0d2d0d1d2c361604170616160601d1d7d7e7d4d4d1dedfc00ecfb00feff0000e90000000000e8e8e8e8e8e8e8e8e5e5e6e5e5e5e5e5000000bcbd0000008f0f0a808200078288088f0c0d88068e0f0789858d0007008204090e0d820c8f020e0a8082000782888e0f0c0d880682
df36d5dbdccfdd361010101010101010d0d1d2e31313e3e36042434143424260231d7c7e7d1e4d1dfbfdeeedfced00ed0000000000e900e91212121212121212e5e6e5e5e6e5e6e6000000bcbd0000000d06098d0d0007008181018c8581868d80820880820007008505860c0d800600888e0a8082000782880e0f0c0d880602
df3607dbdcdfdd361010101010101010e1e152e1e15252e166666766676767661d1d7e7d7c4d4d1dfcfbfbebecebeceb000000e9000000001212121212121212e5e5e6e5e6e5e6e5000000bcbd000000060709008100078202020e0c8502860d89090a88080007028280000c0d82060880850880850007820d06060c8d0d8600
00000000012020208a46474620202020042727264746070641202020676667661b0a1b1b005c00015e0a5e0bdc08881c20202020020201022121212120202020717071711a1a1a1a6010101020202024000000001717171714f676766667143677253636363614155b4a5b5b001c001c001c001c1e415e415e415e5e1f363636
00000000202021204701202020032003143636154607060741410303767676760008005c005c001c1e088008dc08881c02070702e0e0e0012222222202020202617060701a1a1a1a6010101020202024000000001717171714f676767676143676f936f936f914158b8b8b8b001c001c001c001cc01cc01cc01cc0c03d1f3736
00000000212020204620021020012001143636370707070727262627f6f676761e081e5c0b0a0b0b0b0a5e0b1e0a8a0102393902e0e0e0020202020203cf02ce60636160020202026010101074747424000000001717171714f67676b976143776d914d925d914151e011e1e5b4a5b5b000100015e415e415e015e5e02101f37
00000000474747474720101020202020253636360707070737363636f6f676760008005c0008001c00081c08dc08881c20202020e0e0e002ce02cfce2627262663626163202020206010101075757524000000001717171714f6767657b9041576e925e936e93715001c00008b8b8b8b001c001cc01cc05cc0c0c0c03d1d3d1f
e0e0e0e002e0e002011e1e011010101024646525d1d1013c203d2002000000000223230200000000060706002b2b2b2b1ee0e0e0e0f0f0e0e0e0e0e0001c001c000000000000000000000000000000002020202020202020767676766a6a6a6a21032120363776770000000000000000353434342f1d1d022f3f3f2f16161616
e0e0e0e020e0e0201ce0e01c202020202564652422032222aaaa2a2a00000000231d213d72723232060706002b2b2b2b30e0e0e0e0f0f0e0e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf76767676babababa62626262373976760000000000000000467676760823233d220c0c34172e2e2e
e0e0e0e020e0e0201ce0e01c21202020256465251dd1fd9deaea2a2a00000000231d033d424242021b1b1b00212020211ee0e0e0e0f0f0e01e011e1ee0e0e0e00031c32b30313031000031000000000002026626470706077676767602020202262726272001b9b94132323232323232467676760835353434380c3439393939
e0e0e0e002e0e002011e1e0102cecfcf246564253b3b3b3b7a7a3a3a000000000202020261606060001c000003202120001c011c2b2b2b2b00000000e0e0e0e032c3c32b302120303133303132323232222276377636063676767676101010103939393921102120161616560202cf0235aeae352f1b1b2f2f3f222f22222222
1e1dac0000001b1baf000000001819000018180312bb181900000000049c0000000000000000000018393f391699120000000000160000000000960000bbbb0000970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064456e4652f2f1526c79d95a5a797676
0038ac00b033339caf090000001819bbbb03030312b6010100000000161d00002b1e1d009b00a01e18b8b89816991200000000bb160000000000b60000afaf00009700000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbb3172d045727943464d78006c6cf172505f76
1e1eac1e1806c7ad1d9c32320018192e2e18180312a1181900000000162f29293fa0afbb28bbafbb373f3fa33f3f1229292929b6a60000000000962929230d2929b60000000000000000000000000000000000000000000000000000000000001d3c00000000004747472e2e444744d0d0454c4352f96c6c0000dcf56e6ccf79
0000b8a218191d1ead1e1818ac1819000018180338b4181900000000018f8f0f3506060f8f8f8f35018e8e828e8eb406040707070702bcbcbc3e84458447470745840000000000000000000000000000000000000000001d1eacb300001aa2001c9f00000000007679d9507164767644d0456ef5526edadbdb6adc7971505f47
00001c3418199c009cb419341da3a30000373703b793b7b7736a737316041636902436360418180418868e0e8e0c973604b9b7b7000c0c970213000000000000000000000000000000000000000000000000000033bb221d1a1dac0c302fa297a1820000000000d97461c161645876d9646a727952ea006e5ddc5b50c25ae857
30001aa223239c009c0001979318190000828203070418190707070707903917191818191718181918070707070707079600000000000c979702b7b73eb707962d2d2d2dbc0033333333b00fb3b33a3abb3a00003c3c3c3d35a69b9ba63c3cbd1d3c3c7f7fb774d2f453c646d064d979794646cf525c7150ea46cfc2615061d7
060000ae18199a9a9a9a199793183c2f2f001f3c3c2d3f3f1a1a3d1a3c2a001a1a1a1a001a1a9a9a1a1a1a1aa01ab7b7b535069e2a000c97973d01012501f696a6a8ad3404a91d1a340c3f37b535b838b81300001f1616bf1a1a9a9a1a1a1a1a1ebf3f929b9a97d2c35fd958d0d6fc7878363636c646cfcfc57676c6f8c646c5
1800000018199a9a9a9a19349318172c000028b73f822e2eb58d29bb131e1d1e02820dbb31100000009ca000ae007f02bc881f052a060685d79211111111a4bd9daf8097593c3c3c3c3c353c3c3f3f3f1a000000000000000096120097181819000000a18c1b9747f852617979d6f8f453000000af0000321031507100000000
18aeae3023811c1d1e1e199793183c02290c820d060c338006063e3c3c009c00020c342eac97aa00009ca0bbbcbb0000139d899d85f9f6bc13a4010101018f96b61d8ca16436363c3f3f1a1a1a1a000000000000000000000096120097181819298b26e666a197d9c152f478c6f8f8f856000000ae1aae2cf641ce9772000000
373b6a3737370d370c063406a6818f8f8f8f010d133c3d29bc2e2c2e1dbb9cbb2811b429a61d1e001e1eae2c2d850000000000001cb59dbc3e3d2501a525b796a18cadb6d800000000181912000312000000001817bb1cbb3796120034f6f63422b41834bca197456e45455c7172005c6a00000000001aacc7ce4df4ac006a00
07474707860f0635b8b8b83838a63c3c3c3c1a1a1a1a1a1a1a261b001c1a1a1a9a1a1a1a1a1a000000001a1a1a1a3c3c17000000899d8734b502b7b7b7bcb496a1b6b6b6970000a2ac3f24120003120000ac008117a18e8226961200971818191e8b180cd8a9976e005a6a5c6c45455b5b7148ca0072001cd6c24c975c717872
26000000001c00001819003231301c00001c00001c00000000001c001c000092202020121c00247271507f7f863e9697970606060696bd02973d38be38383896bfbfbfbf17080033a00303122983981200ac93183ca191823c96120097181817120018979b7f640000716c4c436e6e5a45c14d5071c1505068418f1249c150c1
2f33002b291c2929041934068f371cb2301c00003434062900001c001c29bb20200f35069b1b2475f878b8061386a5bc97b7b7b7b796b99200009c0000000037b687010197961baea0971a1819868712bb0c9318170c2ea13696120034a5a5a6120016e45846d7455d525b5d6c0072004547c6c545454747474747474747c646
07070786041b07060d3797363686260407862981b48505b8a9291a001a8185040799961200001a0000000000002b93169700000000b992a41a1aa2001a8d9799bfbf37bc979296b2ae381d981919040735060518962e803824961200971818191200992fb7d797480052455b5b5bea0045507172c07271507172f30000727150
36363636991a173607070707363636363607070707073695178638b8380799163617043506383800000000002b37b41686850505863d3d852e2ea61a1a1c9796010606bf97861da0a0a02cb69819993636363636962a009f3c961200971818191200980b7834d74500526a43526c5c0045d047c1504747c3c3f8467150c3d064
3c3c3f3f3f3f3f3cb6223f3cf6f6f7968c3f3fd6f6b425970997a4a496a20ca297b500000000003a3a00b506063d13160000000000000000a11a1a1c1d1c979698b6bcb697081a1a001c98a118193c3c3c3c821f3cae00ae9796120034f6f6341200980b2d2dd76a69526ccf525c5c00cac476e3437979524de379c2c34cd8d0
b6b6282828b63838b696b6a6268eb5b496f6f6c70425bc970b970c0c96a10ca10b0a00000000007f7f1b7f7f7f7f7f7f00000000000000000687af9719a18599878797969896b21cb11b84a118198121213fa0b6a80000003c96120097181819120098ad2c8c97444d525bd9525a6c00446459c2c37846c2614645c3c24dc1d8
3c3c3c3d13bfbfbfbda6133c7ff697163d9d09d62e2e9fa40b97a1a196a287a2080a000000000078417878010f780f7800000000000000001896009719a197173f3f3f8d989610af202020b43636b6282228b6ad3f3333339796120097181819120098001cac97d95e415279525d5c005779f9614d4d794d4c764542c34cc2d7
f634133997983d3e99393934f60df63e05050505bdbc13bd0b0b0c0c0b003400893e000000000000000000000000000000000000000000002821000e8e340d3f0d8d263497ababa02a20ad1836363f212821810c0c2c2e06850112009718183412009892aa0cd77969485200525c5d5b47c1414345744d434d79f9c3c14dc1d7
863d01133d06073d8f8f133da613013d0000000000000000899d9d869da63c869d1300000000000000000000000000000000000000000000181a1a191a1818a626a61713133838383838382436360000002f1a1aa0af801f369912000d97181912009892788bd7c65b5b45475bcac84a76c64141797841454141c541c54541c5
__sfx__
010900001802018020180701807118061180511804118031180211802118021180211801118011180011800109000100000e0001000000000000002b0502c0503005030031300212b01030020300103002130011
0013800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
010300000c57018570185701857018550185301852018520185100000018570185701855018540185301852018510185001850000000185701855018540185301852018510185101850000000000000000000000
0103001e0c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c10011100
0103000020600196001b6002a70013700097000570003700220000370003700006000300004700037000070000700000000000000000000000000000000000000000000000000000000000000000000000000000
01100000000000000000000000002a1002a10026100261002c10028100281002a1002a1002a1003010030100301003010030100301002e1002e1002e1002e1002e1002c1002e1002e1002e1002c1002c1002c100
0110000010100101000e100243000a1001830006100029003e00038000320002c80022000180000a00038b002ab0018b000ab0000b0038a002aa002ea002ea002aa0028a0026a0024a0024a0022a0022a0022a00
0102000020300143000c300316001c40027600164002960028600266002d6002c600296002460024600236002260020600206001f6001e6001c6001a6001760014600106000b6000660004600036000060000600
010213000f500085000a5000f500145000d7001470029000277002c7002c7002c7002c7002c700000002c70000000000002c70000000000000000000000000000000000000000000000000000000000000000000
9112002001612006120061201612026120461006611086110c6110961103611046100261201612016100061000610006100061000610026100161000610006100561103611016110361001610026100261001610
01020000123000d600036000d30019300253002930002300003000030000300003000030000300003000030000300000000000000000000000000000000000000000000000000000000000000000000000000000
51020600123430d623036210d32119321253352930402305003000030000300003000030000300003000030000300000000000000000000000000000000000000000000000000000000000000000000000000000
53011d00143710d371043610136100350366602535025370366703667036670366503665036650366503665036650366503665536655366453665536665366453663536625366203661036610366003660000000
48020c003c6200e3330c22337623296233662325034062202762008220366000322039605012003b6000420008200042000820008200082000820001200366000820036600366000000000000000000000000000
50010d00193600d360063500334001440014300363003620036200562009610076100161009600066000260000600066000660005600056000460000000000000000000000000000000000000000000000000000
5a021b00183730537301373016700566002660086500f6500165006645056450064004630086300663004630036300762006625056250162503620036200c6100261304613016150160500605086050060408604
0a021a003e6301b6503e630376503c63037650376301c6503963032640386300d630366300263033630016202f620026202d620026202a6100361523615026101e61502615146050260032600326003260032600
0002000020343143430c333316201c43327620164332962028613266102d6202c610296102461024610236102261020610206101f6101e6101c6101a6101761014610106100b6100661004610036100061000610
0f011b003e6503d6603d6503b640386302f63025930219301c93019920179201592013920111200f1200d1200c1100a1100811007110061100411004110031100311002010000100200000000000000000000000
380100002b94029940279402594023930219301f9301d9301b9301a930189301793015930149201292011920109200c920159201092008920069100f91005910049100691007910089100791004910019100e910
4102170031630112202b6101123024620112201d620112201f620112301e6301122025620112202a620112202c61011210296101121026610112102261011200236001120022600112001d600112001a60012200
0a0116001276016770197701b76022760257602875000000000002c6702c6702c6402c640000003b6703b6703b6403b6353b6303b6203b6203b62500000000001370017700187001c70000000000000000000000
01020f001b60014600186001d600156002a700227001b700167000f7000a700087000570004700037000300000600000000060000600006000300004700037000070000700000000000000000000000000000000
030400003b6303b6313b6313963136631326312c621256211e62117621156211562115621166211762117611196111a6111b6111d6111f6112161123611246112561127615286152861529615296142961429614
31240020270151ba001e0151e810030141e0100a010160150f115000001e0151e810120151e0150d0140d01427015000001e0151e810030141e0150a0150d0151e01503000200152081003000200152501422010
3148000003114031101b810081140311403110120151b81003114031101b810081140311403110120151e810031141ba101b0150f810031141ba101b0150f81006114061101ba1012810081140811022a1016810
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
316c0020031001e8000d1000f0000a100031001e0000d10003100031001b00003100031001b0000d00012000031001e1000d1000310020100031001e1000d1002200003000030000300024000060001b00008000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
a31200001b6251b625366200c6210c62136610366113662113615366152d6202d611366253662536625366251b6251b625366101b6250c62136615366103662013615366152d6153061136625366253662536625
511200200f023000002e610000000f123000002e610000000f32303210276100f2100f3130000027610000000f4131d40027610115000f2231d81227610072200f323032202e6102e6150f3331e8152e61020815
9d1200000d4100e4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100f4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d4100d410
5d1200200f420124200d4200f42014420034100f42016420034100d4250d420034100d420034100e420034100f420124200a4200f42014420034100f42016420014100d4250d4200d4230d420014100e42303420
631200001b4251b425194251b420366101e420336211b4200f420164203361619420386121a42036625366101b4251b325193251b426366101e420366161b4200f32016420366111942038610224203861538615
5112000018220184200c2210c4211f42012200122001d2201d220225351d220225352253520535205352053516220184200c2211b4211f4201220012200112201122013055112201305516055180551305518055
11120000165301652114530145211253514531145210f53511500115000f5330f5350f5350f535085350a535165301652114531145211253514530145210e535005000f5350f5350f5320f5120f535125350f535
814800001682216822168221682208024080220a0211e02504124041150612122b240612406121081211402422a22128221aa22090221182211822118201d83121a221282223a220b822188260c52518a270c624
6b090020149230802008011080152a6152a60036600149133c6103c613080100801536615081140811008020149230310003100089133c6100802514914089133c6003c60009100149152a625090100911009115
692400200f1251052512525141250f1251052512525141251952519525198300d82015525155251c8341c8240d1251152512525141250d1251152512525141250a1250a5250e5250e1251212514525105250c134
85240000010750d8542c81401850011450d8502c8140185010045108502f8250485006145128502a820168200207502854268140e850091450285026814028500607512850218350685008145148501582415823
812400002cb35149151412514915149150891514125149151791533b341b12517915179150b9151b1252eb3519915119151912511915119151191519125119151e91504915049150491512915069151291515915
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
791000000a2100a2100321003210032150321003410034100d2100d2100321003410033150321003412034120621006210034100341003215032100a2110a2120841008410033100331003212032100341203410
49100020143261b3160f3201b326143101b3100f3201b3160f3201b3100f3261b3160f32011310123200d3200f3200f3101632016316163200f3200f32014320140111422014326143100f3101b3201232011320
5910000020326273161b3202732620316273101b320273161b326273161b326273161b3100b3201e3101d3201b3251b3252232022316253200f3301b32120320200200f33020320203201b310273201e3201d320
591000001b3261e3161b3201e3261b310273101b3201b3101b326203101b32020326273101b3101b3201d3202932612320293261e320293261e320293261e3202a326143202a326203202a326203202a32620320
312000000a1140a1100a1100a12003923039160f9170f9240c1240c1200c1200c1200c1200491600120049160b1100b1100b1100b1100b110110200b110120200d1200d1200d1220d12212917121201491414122
791000200332003410033200321003210032200f415034250332003410033200321003215032100391003910064200f4100642003210031210302106020031300432012420043200621006410124100631006310
0120000022125220141601027015250250d0241901025015240250c024180100c010230252301417010019142202522014160100a0101e0251e0140601012010200252001408010080101c0250b9141c0100d914
4b1000201d3233500015313214133e6201d621153133e6101531300300214132d600214130f3243c6250f322153230030039625213133e6101d621396253e6102131300300214231532338620386243862538620
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000f0000f0000f0000f0001e0001b0001b0001b0000f0000f0000f0000f000200001b0001b0001b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00 60626a63
01 29091f49
00 29091949
00 29092549
02 29251f5f
01 296a2b09
00 296a092c
00 296a2b2a
00 296a2b2c
00 256a2d2a
00 25592d2a
00 2e6a2b2a
00 2b6a2f2a
00 29692b2a
02 296a2a2f
01 301f315f
00 1f313274
00 1f313274
00 32313062
00 33311f7f
00 3331345f
02 3332345f
00 41424344
00 41424344
00 41424344
01 363d5f5f
00 363d5f3b
00 3c3d5f3b
00 3b3b7d3d
00 3a3d7b37
00 3b3d5f38
02 3b3d5f39
00 41424344
00 41424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
00 57424344
