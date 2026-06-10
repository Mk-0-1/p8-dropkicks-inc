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
				
				lvl_mus,layers_active=0,0b1111
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
	mod_tabl(_ENV,"cX,cY,timers,lvl_mus,layers_active/0,0,{},0,15")
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
			if (#ntt.vel > 3) particles(ntt.pos, split"6,5,0,0.3,9") -- todo remove
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
	if (y >= 32) s = 0 -- bc 32*128 is already 0x1000
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
	mod_tabl(entity, "ts,bnce,slip,grav,ifi,Uf,Df,is_left,coll_rng,actN,actF,rngN,rngF,Iarm,Irss,spr_size,d_o,outl,magnetcharge,lzr_thck,dash,jumping_d,ray_iters/{},_V_trn_bnc,_V_trn_slp,_V_grav,_V_e,_V_e,_V_Dntt,false,0,55,100,0,35,0,1,8,3,0,70,10,0,0,2")

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
	if ntt == player or ntt.parent == player then -- todo remove parent check?
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
			if bcheck(layers_active, 1<<j) and fl&0b00111111 != 63 then
				fl &= 0b10111111
			else
				fl |= 0b01000000 -- disable channel
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
				local did, normal, dist = collsqr(p_in, rds, p2, 4)
				
				if (did) return true, p2, normal, dist
		end

		end
	end

	return false
end

function collntt(ntt, pos, rds)

	-- ultra slow with lots of primary entities - limit is about 15
	-- only ntt can be a second-tier entity
	--if (#ntt.vel > 0.2) then
	
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
		
	--end
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
	local coll_t, t_pos, norm_t = colltrn(pos_t, rds_t)
	if coll_t then
		for i=1, 6 do
			for j=0, 7 do
				local s_v = (up_override and vec2_up or norm_t)*8 -- start from most likely exit point (or up), then spin
				if (j > 3) s_v = vec2_rotate(s_v, 0.125)
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
					return true, true, true, m_v, tmpTrnE(t_pos) -- out now - ignore entities
				end

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
	if (fget(ntt.tile,6)) ntt.Cdmg,ntt.kb = 10,0.4
	return ntt
end

function coll_p(e,p,i,o)
	local cdmg = o.Cdmg
	if e.stmn and o.thrown and o.coll_func != Chook then -- first block hit is buffed
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


	local sf = 6
	if impact > 11 then
		sf=8
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
function ray_coll(pos,vec,angle_range,leg_entity,entity)
	for i=1,entity.ray_iters do
		local t_vec = vec2_rotate(vec*(rnd()+0.1),angle_range*(rnd()-0.5))
		local t_pos = pos + t_vec
		local coll_land,with_t,out,away_vector,other_ntt = unclip(leg_entity, t_pos, leg_entity.rds+2, true)
		local is_magnet = entity.magnetcharge > 0 and (fget(mget(t_pos.x\8, t_pos.y\8), 2) or other_ntt and other_ntt.tile == 24) -- only 44 & 45 get wallset
		
		if (coll_land and out and vec2_dot(t_vec,away_vector) <= 0) return true, t_vec, with_t, away_vector, other_ntt, is_magnet

		if is_magnet then 
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


	local prev_jump=jump_g -- todo jump_g can be replaced with g_mode
	envstr.mod_tabl(entity, "sSt,g_mode,jump_g,g_no_slide,slide/false,false,false,false,false") -- todo this false chain isnt needed
	sticky,magnetwalk = permastick
	
	-- proc move legs
	
	local stand_vec,max_dist,max_leg,max_stand_center = envstr.vec2_norm(entity.leg_facing)*leg_len*1.25, stnd_height/2

	-- move target with highest distance to optimal target position (if outside tolerant distance)
	local st_pos,st_away,st_c = envstr.vec2_zero*1,envstr.vec2_zero*1,0

	for leg in envstr.all(m_l_legs) do
		stand_vec_l = envstr.vec2_rotate(stand_vec,leg.angle * envstr.tonum_flip(is_left))
		if (prev_jump)stand_vec_l+=vel*leg_len*0.75
		local stand_center = pos + stand_vec_l -- optimal place to stand on
		local dist = #(leg.t_pos - stand_center)
		if (leg.magnetwalk and #iDir > 0 and ts.jump_cooldown <= 0 and magnetcharge > 0) then
			sticky = true
		end
		
		--envstr.dT(0, function() envstr.circ(leg.t_pos.x, leg.t_pos.y, 2, 3) end )
		
		if (dist > leg_len*1.4 --[[or envstr.aC%30==#m_l_legs]] or ts.jump_cooldown != 0) leg.t_active = false
		
		if envstr.timer_ready(entity,"jump_cooldown") then

			if not leg.t_active and not slide then -- dont check if already sliding to save cpu

				local did, t_vec, with_t, away_vector, other_ntt, magnetwalk = envstr.ray_coll(pos, stand_vec_l,leg_angle_range, leg, entity)
				leg.magnetwalk = magnetwalk

				if did then
					stand_center = pos + t_vec + away_vector
					
					leg.surface_away,ground_entity,dist=envstr.vec2_norm(away_vector),other_ntt,#(leg.t_pos - stand_center)
					
					if dist > max_dist then
						max_dist,max_leg,max_stand_center = dist,leg,stand_center
					end
					if dist <= leg_len*1.4 then
						leg.t_active = true
					end

				end

			end

			-- move legs to targets
			if leg.t_active and not fget(ground_entity.tile,5) then
				g_mode,jump_g,slide=true,true,ground_entity.tile and iDir.y > 0
				g_no_slide = g_mode and not slide
				st_pos+=leg.t_pos--+leg.surface_away*stnd_height
				st_away+=leg.surface_away
				st_c+=1
				
				if (leg.magnetwalk) magnetwalk = true
				
				if g_no_slide then
					envstr.move_towards(leg,leg.t_pos, leg_speed)
				
					if #vel < 8 then
					
						if sticky then -- TODO REMOVE?
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

	if (st_away.y <= -0.5) st_away.x = 0
	surface_away=envstr.vec2_norm(st_away)


	if sSt then

		vel.y *= 0.85

		local stand_p_lh = st_pos/st_c


		stand_p_lh += surface_away * (stnd_height + envstr.aC\48%2)

		
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
	local surface_normal,input_dir_l,jump_cooldown = ntt.surface_away, vec2_limit(ntt.iDir), ntt.ts.jump_cooldown
	
	if ntt.ts.hitshock < 2 then
	
		
		-- grabbing ----

		if #ntt.m_l_arms > 0 then
		
			local input_dir_h = vec2_norm(input_dir_l + vec2_up*0.04 + vec2_right*(tonum_flip(not ntt.is_left))*0.05)
			local hold_pos,throw_str = ntt.pos + input_dir_h*ntt.arm_len,1.6

			-- check if grab still valid
			if ntt.in_grab and first_lnk(ntt,ntt.grabbed_e) == nil then
				ungrab(ntt)
			end
			


			if ntt.b5 then
			
				local hp_clip,hp_with_t,hp_out,hp_dir,hp_coll_e = unclip(ntt,hold_pos,0.75, false, 6)
				--local hp_2 = hold_pos+(hp_dir or vec2_zero)

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
						sfx(9)
						
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

		local leg_pos,j_sf = (ntt.m_l_legs[1] or ntt).pos, ntt==player and 10 or 0
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
				j_ntt,j_sf = mod_tabl2({},"pos,vel,mass,Iarm,Irss,bnce",{ntt.pos,ntt.vel,ntt.mass*3,0,1,1.6}),11
				
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
					j_sf = 12
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
			align_down -= surface_normal
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
		if (input_dir_l.y < 0) ntt.grapple.len -= 2
		
		if ntt.b4 or ntt.grapple.len < 4 then
			delete_link(ntt.grapple)
			ntt.grapple = nil
			ntt.vel.y -= 4.1
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
	
	mod_tabl(enm,"outl,sSt,b4/0,false,nil")

	enm.iDir *= 0 -- this here is why no one else uses slides
	
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
		
		
		
		if colltrn(enm.pos + vec2_norm(look_dir)*enm.rds*1.5, enm.rds) and not enm.melee then
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

m_i,start_lvls,m_titles,m_splashes,m_lore_infos=0,split"1,7,14,21,28",split"task d1,task d2,task d3,task ??,task ??",split("finally, a day where our\n  name matches our service`you did bring a\n  parachute, right?```","`"),split("from: hq\n\nsome construction company's\nbots went haywire -\nthey're hoping we could\n'clean' up the situation\nbefore the public notices\nand it turns into a mess\nof paperwork.\nPERFECT OPPORTUNITY FOR \nYOUR 'SKILLS' :]`from: hq\n \nsame guys as yesterday,\nthis time it's one of their\nautomated cargo transports.\nmakes you wonder what\nthey're doing to get rogues\ntwice in a row, but hey as\nlong as they're paying i'm\nnot complaining.`from: hq`from: address unknown\n`","`")

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
lvls_info_2 = split([[   the construction site  `2`24`26`y_u_l/-32`0`28`23`3`6`1`8272`1`4832`5216`4608`5
1: roadblock`3`7`66`/`23`27`16`4`7`3`8272`2`4832`5472`4736`6
2: magnetizing yourself`4`6`328`/`69`25`15`11`7`3`8272`2`4832`5472`4864`7
3: detour`5`4`188`y_u_l,lvl_e_req/-72,3`55`29`7`7`7`3`8272`2`5344`5600`4992`4
4: mayhem square`6`4`200`y_u_l,lvl_e_req/-64,4`0`12`13`11`7`7`8400`0`4712`5600`5120`8
5: the small issue in question`-1`4`116`y_u_l,lvl_e_req/-32,1`29`12`12`6`7`7`8400`0`4712`5600`5248`2
  the hijacked transport  `8`16`88`x_u_l,y_l_l/-128,320`66`12`14`5`18`5`8528`2`4728`4856`5376`4
1: what a blast`9`10`88`/`0`30`12`4`18`5`8528`1`4984`5112`5504`4
2: hang in there`10`4`300`y_l_l/416`78`25`11`11`18`5`8528`1`4984`5112`4640`5
3: nice weather up here`11`10`115`y_l_l/164`88`12`17`5`18`13`8656`12`5240`5368`4768`7
4: broken access bridge`12`8`92`lvl_e_req,y_u_l/4,-96`102`12`18`4`18`13`8656`12`5240`5368`4896`6
5: annoyingly out of reach`13`8`35`y_u_l,lvl_e_req/-96,1`53`12`11`4`18`13`8656`12`5240`5368`5024`2
control cabin`-2`6`52`x_l_l,y_l_l,y_u_l/256,96,-96`62`12`4`3`6`1`8656`12`5240`5368`5152`1
  the lowlands  `15`240`56`/`103`16`10`9`-1`7`8288`2`4720`4848`5280`3
1: bouncy castle`16`4`315`/`103`25`10`11`28`3`8288`4`4720`4976`5408`6
2: the horrid sludge pits`17`8`170`sludg_l/196`113`16`15`7`28`3`8288`5`4976`5232`5536`4
3: hunted`18`4`154`y_u_l,sludg_l,lvl_e_req/-96,169,3`113`23`15`6`28`3`8288`2`5104`5232`4672`5
4: the moat`19`4`28`y_u_l,sludg_l,lvl_e_req/-96,205,5`113`29`15`7`28`7`8416`1`4832`5360`4928`7
`20`11`66`y_u_l/-32`39`22`9`3`-1`3`8416`1`4832`5360`4928`0
`-2`17`75`y_u_l/-32`120`12`8`4`35`7`8416`1`4832`5360`5056`1
     the cache    `22`4`83`sludg_l,sl_vx,sl_vy,sl_h,sl_spd,sl_smth/244,-0.75,-0.75,0.44,12,0.90`39`27`12`8`-1`1`8544`0`4960`4704`5060`0
1: into the system`23`4`70`/`11`30`15`6`42`5`8544`4`4704`4704`4800`2
2: floodgates`24`4`44`sludg_l,sl_vy,sl_smth,sl_dmg,sl_h,sl_spd/92,-0.2,0.985,0,-0.9,22`32`17`14`9`42`5`8544`1`4704`4704`4808`4
3: lost in the architecture`25`4`124`/`46`16`12`11`42`5`8544`4`4704`4704`5440`0
4: `26`4`458`sludg_l,sl_r,sl_c,sl_dmg,y_l_l,sl_h/520,-0.38,2,1,600,0.2`62`21`7`15`42`11`8672`8`4704`4704`5060`3
5: `27`80`490`sludg_l,sl_r,sl_c,sl_dmg,y_l_l/580,-0.36,2,1,600`98`20`5`16`42`11`8672`4`4704`4704`5200`2
exit`-1`50`144`y_u_l/-80`34`27`4`5`6`1`8544`0`4960`4704`4928`0
1: over the fence`29`4`34`/`41`12`12`6`49`3`8304`0`4712`5472`5184`4
2: courtyards`30`4`178`y_u_l/-64`10`12`19`6`49`3`8304`0`4712`5472`5312`5
3: corporate ladder`31`7`370`/`89`23`10`13`49`3`8304`0`4712`5472`5440`6
4: `32`12`312`x_u_l,x_l_l,y_u_l/-128,248,-128`56`21`7`11`49`3`8304`0`4712`5472`5568`4
5: high alert`33`12`40`/`23`12`32`6`49`7`8304`0`4712`5472`4928`0
6: `34`12`40`/`5`12`16`13`49`7`8304`0`4712`5472`4928`0
parking lot`-1`8`10`y_u_l,y_l_l/-160,-80`0`34`10`2`49`7`8304`0`4712`5472`4928`0
         `38`4`70`/`71`15`25`4`57`39`8560`0`4832`5368`4928`0
`38`4`45`y_u_l/8`69`17`15`4`57`39`8560`0`4832`5368`4928`0
`-1`4`45`/`58`12`7`5`57`39`8560`0`4832`5368`4928`0]],"\n")





-- need: 5 boss, 6 boss
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
	19: PROJECTILE (lvl4): sawblade
	20: PROJECTILE (lvl2): grabbable missle
	21: PROJECTILE (lvl3): laser targeting recticle

	22: BOSS (lvl2): big aircraft
	23: BOSS (lvl3): cool shades
	
	24: ENEMY TEMPLATE
	
	25: Spike hazard - UNUSED
	26: Sawblade hazard
	
	27: Grabbable bouncable mushroom
	28: ENEMY (lvl3): sniper drone
	29: ENEMY (lvl4): melee sawblade spider
	30: alarm
	31: ENEMY (lvl5): spawner drone
	32: ENEMY (lvl3): shotgun drone
	33: ENEMY (lvl5): robot
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
0, 2,  0.6,81|Uf,Df,Btyp,stmn,stmn_h_dmg,Iarm,Irss,slip,Etyp,in_grab,grabbed_e,col,outl,ray_iters/_V_Uply,_V_Dply,2,70,0,5,5,0.99,player,false,nil,12,9,6
0, 0.9,0.1,nil|Df,slip/_V_e,0.9
24,5,  0.4,64|rope,rX,rY,hz/1,0,15,t
24,5,  0.4,78|rope,rX,rY,gun/2,0,16,9
24,5,  0.9,77|rope,rX,rY,rope_e,stmn,gun/8,0,-45,d_o➡️2,90,2
0, 6,  0.3,180|ifi,Uf,Df,Btyp,stmn,Iarm,gun,ai_p,ai_a,enemy,smok,flying,rngF,rngN,slip,f_c,dash/_V_Ienm,_V_Uenm,_V_Dntt,1,50,2,1,_V_AIPfly,_V_AIAfllw,true,1,true,35,12,0.9,3,0.4
24,12, 3,  198|Btyp,stmn,Iarm,Irss,gun,ai_a,smok,rngN,rngF,spr_size,actN,actF,g_i,sprW,sprH,grav/4,175,2,2,6,_V_AIAfllw,5,35,55,16,55,2000,t,2,2,0.05
0, 3.3,0.4,186|Cdmg,grav,smok,stmn,bnce,dur/14,0,3,0,0.8,60
0, 2  ,0.4,83|Btyp,Df,dur,next_e,col/3,_V_Dply,40,14,6
0, 2,  0.1,240|Uf,item,amount,smok,ignS/_V_Uitm,5,25,2,true
0, 4,  30,  14|Etyp,smok,g_i/tmp tile,1,t
0, 9,  2,  244|Uf,nophys,d_o/_V_Usgn,t,1
2, 2,  0.4,83|Uf,Btyp,dur,break_func,iDir,col,b4/_V_Uply,3,60,_V_d_load_next,_V_vec2_right,6,t
0, 4,  0.2,246|Uf,item,smok,ignS,f_c,f_l/_V_Uitm,4,4,true,3,6
0, 2, 0.14,241|coll_func,respawn,grav/_V_Chook,true,0.10
0, 3.5,0.2,77|ifi,Uf,nophys,gun,ai_p,ai_a,stmn,hz,actN/_V_Ienm,_V_Uenm,t,20,_V_e,_V_e,1000,t,70
24,7.5,6,  79|Iarm,gun,rngF,spr_size,hz,actN,actF,g_i/0.2,10,90,16,true,70,130,t
0, 7,  0.04,183|Cdmg,kb,grav,stmn,bnce,ignS,outl,f_c,f_l,dur/4,1.5,0.05,90,0.95,true,3,3,1,150
0, 2,  0.4,187|Uf,smok,stmn,ignS,expl,grav,slip,f_c,f_l,dur/_V_Umsl,3,0.3,true,2,0,0.97,2,4,110
9, -9,0.45,228|Uf,Cdmg,break_func,expl,slip,stmn,Irss,smok,dur/_V_Umsl,nil,_V_Blzr,3,0.89,100,500,6,75
24,9,  3  ,200|Btyp,spr_size,ai_p,ai_a,actN,actF,rngN,rngF,gun,stmn,smok,flying,Iarm,g_i,sprW/6,16,_V_AIPfly,_V_AIAhvr,110,2000,40,80,11,250,5,true,1,t,2
2 ,2,  0.4,83|ifi,Uf,Btyp,stmn,boss,ai_p,ai_a,gun,col,rngF,rngN,actF,actN,jumping_d,next_e,enemy/_V_Ienm,_V_Uenm,3,200,t,_V_AIPstbl,_V_AIAfllw,22,6,100,60,500,500,20,10,f
0, 5,  0.5,64|ifi,Uf,Df,Btyp,stmn,Iarm,gun,ai_p,ai_a,enemy,smok/_V_Ienm,_V_Uenm,_V_Dntt,1,60,2,1,_V_AIPstbl,_V_e,true,1
0, 7,  1  ,233|Uf,nophys,spr_size,d_o,Cdmg,kb,sprW,sprH/_V_e,true,8,2,8,1.5,2,2
25,7,  1  ,183|spr_size,Cdmg,f_c,f_l,sprW,sprH,outl/16,20,3,2,1,1,9
0, 7.8,0.2,245|Uf,rope,rX,rY,bnce,spr_size,d_o/_V_e,13,21,0,0.4,16,4
7, 8,  0.4,216|Btyp,gun,rngN,rngF,actN,actF,stmn,ai_a,sprW,f_c,dash/6,14,50,70,70,130,70,_V_AIAhvr,2,1,0
24,4,  0.7,179|Btyp,stmn,gun,ai_a,rngF,actF,Irss,melee/8,90,15,_V_AIAfllw,6,170,3,tr
24,3.5,0.25,118|Btyp,gun,stmn,procalert/1,18,30,true
7, 8,  4,  180|spr_size,gun,dash,Btyp,rngF,rngN,actF,stmn/16,17,0,6,80,40,200,200
7, 8,  0.7,200|Btyp,gun,stmn,sprW,f_c,rngN,dash/7,19,55,2,1,30,0.8
24,3.5,0.2,82|Btyp,stmn,ai_a,gun,col,outl,rngF,rngN,actF,actN,dash/3,80,_V_AIAfllw,25,3,3,50,30,250,70,0.8
0, 16,  1  ,nil|Df,nophys,d_o,decal/_V_Ddcl,t,1,▒▒▒▒
9, 5,0.01,   0|Cdmg,kb,break_func,lzr_thck,smok,bnce,dur/10,0.4,_V_Blzr,4,7,0.1,6
24,6,  0.7,76|stmn,Irss,gun,rope,rX,rY,dash/85,3,3,2,0,16,0.6
20, 2, 0.7,186|expl,slip,dur/1,0.985,50]],"\n")



-- modifications for certain entities in level, no newlines to keep control chars (made in lvl editor)
ntt_extrainfos=split("/⬅️procalert/true⬅️next_e/11⬅️rX,rY/16,0⬅️rX,rY/-16,0⬅️rX,rY/0,-16⬅️rX,rY/-13,-13⬅️Btyp,rope,ai_a,rngN,rngF/5,nil,_V_AIAfllw,35,70⬅️gun/9⬅️boss/true⬅️rope,rX,rY/6,76,-20⬅️break_func/_V_d_load_next⬅️is_left/t⬅️is_up/t⬅️is_left,is_up/t,t⬅️rX,rY/-15,15⬅️txtB/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️-30⬇️44⬇️42⬇️2⬇️1⬅️rope,rX,rY,rope_e/8,-45,-8,d_o➡️2⬅️/⬅️txtB/\fastaff is advised\n to only \fcgrab the\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1⬅️decal/\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!\*f \*f \*f \*5 \^h\n🅾️\n\n\|c \-e+\n\n\|c\-f\^:10387c1010100010⬅️decal/\f2\^o0ff\^:00008064320f0204 \^h ❎\|e\n\ng\|fr\|fa\|fb  \|e\^:0000070c90a0c0f0⬅️/⬅️actF/600⬅️actF,rngF,rngN,ai_a/600,160,25,_V_AIAfllw","⬅️")


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
ntt_b_types = split([[false` 0.15`0.15`3`3`2.6` 18`1`20` 3`3`0.01
false` 0.8`0.21`2.07`1.05`2.1` 8`5`7.5` 3.2`2`0.2`  3`l`0.015` 10`➡️`  3`a`0.02` 9`➡️`  3`l`-0.015` 10`d_o➡️3`  3`a`-0.02` 9`d_o➡️3
false` 0.3`0.21`2.07`1.05`2.1` 8`5`7.5` 3.2`2`0.2`  3`l`0.015` 10`col➡️15`  3`a`0.02` 9`col➡️6`  3`l`-0.015` 10`d_o,col➡️3,15`  3`a`-0.02` 9`d_o,col➡️3,6
false` 0.2`0.05`1.2`1`0` 42`1`40` 10`3`0.10`  3`l`0.03` 12`➡️` 3`l`-0.03` 12`➡️
true` 0.10`0.05`1.5`1`2.4` 15`1`12` 4`6`0.6` 3`l`0` 11`➡️` 3`l`0.5` 11`➡️
false` 0.14`0.14`1.5`1.5`0` 15`1`20` 3`3`0.01
false` 0.18`0.18`4`4`3.1` 15`1`20` 3`3`0.01
true` 0.08`0.02`1.1`1`2` 15`1`16` 4`6`0.2` 3`l`0` 11`➡️` 3`l`0.5` 11`➡️]],"\n")



--[[
1:standard
2:lvl2 laser sweep
3:lvl1 missle
4:UNUSED (l1 bomb)
5:sawblade
6,7,8:boss 1 sequence(x4 spread, x2 missle, laser sweep)
9:standard burst
10:grabbable missle
11,12,13:boss 2 sequence(x3 slow missles, x1 saucer, downward storm -- TODO rework)
14:laser snipe
15:melee sawblade
16:UNUSED (sawblade 2)
17:drone spawner
18:empty gun
19:shotgun
20:laser spin
21,22,23,24: boss 3 sequence (laser, hook throw, dropkick + proj, projectile)
25,26: robot sequence (gun, melee)
]]
-- cooldown,projectile entity,p speed,fire sfx,angle,is global,burst amount,burst delay, burst angle shift,next gun,extra projectile props, entity prop modifiers
guns = split([[45`9`2.5`13`0`fls`1`1`0`1`/`/
70`35`13`-3`0.12`fls`18`2`-0.012`2`/`/
90`37`0.7`7`-0.25`fls`1`1`1`3`/`/
65`10`3`7`0`fls`1`1`0`4`/`/
60`19`3`15`0`tru`1`1`0`5`/`/
70`9`2.25`13`-0.03`fls`4`7`0.01`7`kb/0.7`/
70`37`1`7`-0.11`fls`2`20`0.09`8`/`rngN,rngF/45,90
70`35`13`-3`0.22`fls`10`2`-0.022`6`Cdmg,rds,hz,lzr_thck,break_func,dly_expl,dur/0,2,true,8,_V_DlEx,4,15`rngN,rngF/35,55
60`9`3`13`-0.03`fls`3`8`0.03`9`/`/
100`20`1`7`0`tru`1`1`0`10`/`/
20`20`1`7`0.25`tru`3`60`0.1`12`hz/t`ai_a,rngN,rngF,hz/_V_AIAhvr,40,80,nil
75`7`3`13`0.1`tru`1`10`0.5`13`stmn,enemy,next_e,dur/60,f,11,225`rngF/45
120`35`13`-3`0.25`fls`32`2`0`11`hz,lzr_thck/t,9`ai_a,rngN,rngF,hz/_V_AIAfllw,2,2,true
75`21`2`0`0`fls`1`1`0.08`14`/`/
1`19`7`0`-0.40`fls`999`1`0.03`15`dur,hz,melee/1,t,5`/
1`19`8`0`0.40`fls`40`1`-0.02`16`dur/1`/
50`7`4`7`-0.1`tru`2`4`0.2`10`enemy/f`/
999`1`0`0`0`fls`1`1`0`18`dur/0`/
70`9`3`14`-0.07`fls`3`1`0.05`19`/`/
1`35`9`0`0.25`fls`999`1`0.495`20`melee,dur/t,7`/
30`16`8`-4`-0.01`fls`1`1`0`22`respawn,dur/nil,60`rngF,rngN,b5/0,0,nil
10`21`2.5`0`0`fls`1`1`0`23`dur/55`rngF,rngN,dash,b5/120,60,0.5,t
40`9`3`13`0`fls`1`1`0`24`/`rngF,rngN,jumping_d,b5/3,0,30,nil
120`9`3`13`0`fls`1`1`0`21`/`rngF,rngN,dash,jumping_d,b5/90,80,0.9,10,t
45`9`4`13`0`fls`1`1`0`26`/`rngN,rngF,jumping_d/2,4,22
45`9`4`13`0`fls`1`1`0`25`/`rngN,rngF,jumping_d/30,50,0]],"\n")

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
12,3,-5
7,8,-2,-4,7
3,3,14
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
ex_sfx = split"\a63s2v2i6g#3<d4c4i0c4c#4g#3g#2,\a63s7v2i3x3f2fv7i6f<f<f<f<f<\*ffi2f0\*ff\*ff,\a63s5v1i2c2c1c0,\a63s2v3i6x3g2c>x0d#2i7f#3x1g1a#2f0d#d#,\a63s2i7v6d#0a#g#d#1g#c#g#g#2d#3g#3..<g#3..<g#3..<g#3"
-- all of these should overwrite empty slot 63 with \a63


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
00000000555555545555555444444444aabbbaa900000000e9a8abeabaeae9abbe8448eab9b9b9b9ebebebebbbbbbabb44444445545b45b477777d7877787778
00000000555555445444444455555554beeeeee800000000e9e8b9e999999999bb8448baa89898988ae9e98a8b8998b84454545554a5a5ab7dd78788ddd88d88
00000000544444445444444454444444be9999e800000000e9e8a999e9e9e9e9bebeebea99a999a9aabaaba998b88b89454545454b5a4aa57dd788787877d888
00000000555555445444444454445454be9999e8000000009998a9e9e9e999e9b98bb89aaaaa8aaaaaeaaea9449bb94444545455a9b45baa7d78ddd8d8d888dd
00000000544444445444444454454454ae9999e800000000e9e89999e99999e9b98bb89a9998a9998aaaaa98449bb944454545459bba99a97788ddd8778d7788
00000000555555445444444454444454ae9999e800000000e998a9e999999999bebeeaea998a9999aabaab9898b88a89445454559a89aa9978d78dd8dd888dd8
00000000444444445444444454444454aeeeeee800000000e9e8a9e9999999e9bb8448aa98a99999aaeaaea98b8998a845454545a9aa99a97dddd8d878dddd88
0000000055544444444444444455555498888889000000009988a99999999999be8448ea88888888baa99aa9aaaaaaaa555555558aa88988d888888d8dd88888
44444444555555552222222211111111aaa9e99999999e9aabababab88888888ff999fdd8444445a55555555ebebebeb54005554444444445555555589889988
44444444555555552222222211111111a999e99999999e998a8a8a8a88888888fd999ddf8444454a500000058a8a8a8a540550545555555554444445489aaaa9
44444444555555552222222211111111bbaaeaa9999e9aaa8888888888888888ddf999ff8444444a50000005bbbbbbbb54550054444444445500005544899999
44444444555555552222222211111111baa9e999999e9a998998999988888888dff999fd8444444a5000000599aaaa9955500054555555550550055044489999
44444444555555552222222211111111a9e9e999999e9e998888888888888888ff999fdd8444444a50000005888aa88855500054444444440055550044448998
44444444555555552222222211111111baeaa999999eaeaa8888888888888888fd999ddf8444444a50000005888aa888545500545555555500055000554448aa
44444444555555552222222211111111b9e9999999999e998888888888888888ddf999ff8444444a5000000588aaaa8854055054444444445555555544444489
44444444555555552222222211111111a9e9999999999aaa8888888888888888dff999fd9aaaaaaa55555555eeeeeeee54005554555555554444444445554448
44444444444444444554455455555555baa9baa99aa99999bbaebbbabbebbbbea373373a99888989ba9bba9b55455545fffffffd7777777d88888888babbbbba
5555455545554455445544555455445599e9e9e9e999e999baaebaa9aaebaaa93777777388888888aa9bba9b55455545fdffddfd7377337d89999999b9aaaa9a
44444444444444445445544554455445a9baa9aa999999aabaaea99999ea99995373373599999999ba9bba9b55455545fffddffd7773377d89899989babaabaa
5545554554455445554455445544554599e9e9e9e9e99999aaae999999eeeee93777777388899988ba9bba9b55455545ffddfffd7733777d89999999aaaaaaa9
44444444444444444554455455544555baa9aaa9aaa9aa99eeee99ee99999999b373373b99999999ba9bba9b55455545fddffdfd7337737d89999999baaaaaa9
4555455545444555445544555455445599e9e9e9e9999999999999999999eee93777777399999999ba9bba9b55455545fdffddfd7377337d89899989aabaaba8
44444444444444445445544554455445a9aaa9a9999aa9aa99999999999999e9b373373b99999999ba9bba9b55455545fffffffd7777777d89999999a9aaaa98
555455545554555455445544555555559999999999999999999999999999e999bbbaabbb99999999ba9bba9b55455445dddddddddddddddd8888888888888888
05000505050000050000000500000005b8bbbbbbbbbbbbbb999999999eee9e9eba3bb3ab99999999aa9bba9bbbbbbbbb999999995544444499999898babbbbba
050005050500000555555555000000558bbeeebeeebeeebe99999999999e999ea373373a99999999ba9bba9bbbbbbbbb9999999955444455999aa984aaa999a9
55005555050005050505050500000505be899989998999899999999999e99e9e3777777399999999ba9baa9baaaaaaaa999999995544444499999844aaaaaaaa
55500555050005055050505550000055be999998888888889999999999999999b373373b99999989ba9bba9ba99aa9aa99a999995544444599888444aaaaaaaa
05000505050005050505050505000505be9999988beeeeb89999999999999a993777777388888888ba9bba9b9999999999a9aa9a5544444499984444aaaaaa9a
05000505050005055555555555555555be9999988899998899999999a9eaaaaea373373a99989999ba9bba9b99999999aaaaaaaa55444455aa845554a9aa9a99
05000555550055055555555555555555888888888b9999b8999999999eea9e9e3777777388888888ba99aa9999999999bbbbbbbb554444449844444499999999
5500050555000505555555555555555588889998888888889999999999999aaa53733735888888889988998899999999bbbbbbbb554444458544444488888888
030000005554454455444554555444555b9b99550000000077f9f9fffff9f9ff909f000066666666f7ffffff99900999ddddddd600dddd00000dd0003d666dd3
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
454455455454554455545554555455549bbb99a99ba999995b5bb5b55b55bb5b445443544a54ba5aba9bbab94545545500000000005550000000000d70000000
54545454455454545554555455545544bbaaaa99ba999999bbbbbbbbbbbbbbbb3453a354ab94aa4ba99babab44455455055555004444550000000007e0000000
55444544545544545554555455544454aaaaaa9b99999bb9abbbaababbababbb5353a3a4a9b9a99aba9b9ba945455445000445555555525000d0007dee000e00
454545454554545544444444444444449aaaa9999999baa9ababaa9aabaabaaba3aa33a399aa9a9aba9a9ba9454554450444544c5cc444200007d0d99e0ee000
54545444545545545554555455544444b99999bbbbb9aa999a9aa9a9aaa9ba9ab3383b39999a9a9aba9b9ba94544445544c445544444c440000dd966669ee000
45454445454544555554555455544454aaa9bbbaaa99999aa99b9aa9a9a99a9a3a3839b399a99a99aa9b9a99454554554c4c4544454c4c40000096d666690000
45455454454544545554555454444554aa99baaaa999ba9aa9ab9a9aa99a99a9ba33baa999999999ba9b9ba94545545544c445000544c440007d6d663666ee00
54445454554554554444444444444444a9999aaa999aaa9999a9999a999999a9a83ba88899999999ba9baba9454544550444000000044400d7d9666363669eee
50450405000500500000000000000000bbbabbbabba9bba90000300099a99999344b95a399999999ba9b9ba96666666654545454aaaaaaaa7dd9666636669eee
44540455050450450000400400000000baa8baa8baa8baa8003666309a99a99953a93335a99999a9ab9baab86666666654555455a000000a00dd666666e6ee00
04545454045540055054004005004500baa8baa8a998aa980300600399999a99533b95aa99899a99ba8a8bab6666666654444444a0000a0a000096666e690000
54544044054040540405005454045040a888888898888888036666639999a9a94aba935399599999bb8aab8b68a6686645555555a000a00a000dd966669ee000
55454540454540450545050445055405bbbabbba88b88988030060039a99a9aa33599435a9895999bababa8aa8aaa88844444444a00a000a000dd0d99e0ee000
54504545505445554545454540050454baa8baa88baa898800366630a99999a9555933aa5a858989a9baba8b9899989844444444a0a0000a00d000ddee000e00
54555045545445545405554554505455baa8baa8aaa9898900006000999a999a34b9344459885989b9b998899999999855545554a000000a0000000de0000000
44545445045404555554555554545545a888a8888a9899890fd666df999999994359933488585885b99bab899999999944545454aaaaaaaa0000000de0000000
6b6b8282826b83836b696b6a04e8003010791a6f4f7c5210527908080808080808080808080808f74af7f7f7f74af7f7f7f7f7080808086078fa79917a589942
19c05a69894223c113b148787291181212f36b8a2808081af9720881818181912908727ac1c172443425b59d25a5c6084446952c3c87642c1664543c2cd41c8d
c3c3c3d331c3c3c3d36a317676287230aa79c06f3969207bf94a0808080808080808080808080828c028d028d0c028d028d0280808080881690879917a797173
73737369899b01fa213a3ad072636b8222820a12f333333379720872818181912908817a8dc1729de614259725d5c50875979f1614d497d4c46754243cc42c7d
08080808080808080808c3769908723856cbcb10d9d3d0bb394a080808080808080808080808088714878710f087f04487878708080808821208e0e843d0f3d0
d8d0044b79baba0aa228da8163638312821218c0c0c2e26058100872818181182108817ac5c172979684251f25c5d5b5741c143c14ccd43cd4979f3c1cd41c7d
08080808080808080808f37699086004505050505071d3cb5adb080808080808080808080808080808080808080808080808080808080881a1a191a181816a62
626a71d731838383838383426363080808f2a1a10ada08f163990872818181912908817a87c5726cb5b55474b5ac8ca4676c14149787145414145c145c54145c
40d8e01070eaa01040ba5140d0d6b0112242015100000000000000000000000001e0351001e374107043441060b4e31060c4b110000000000000000000000000
02a51181c1d69191e105d210c1c2e0910204f08100000000000000000000000000000000080808087710284808ca08083d102828050a080814102828050ae9d7
401361207042112040d4017050c7e04022f4016170f6021000000000000000002161211021b72110f0d6b0100121311001c4911060c211106025011000000000
11c4f110d1a7c110d142e310d144341042d36480027604100000000000000000261028280b4918084d0028eb0a0c08083e1038480a8a0808161058480a66daa7
50a1c110f0d071104094d12070f3803070b4801070c1c2104296d18000000000216322305062208021c7413001d2711070a2001042e530800000000000000000
0292221002d4b120c1d3e110c1d533100246a12002377210c123031000000000201028280b49f70850003828080808083e10e70a0a0c0808273038080866e917
42c2508042a2b18042f0508042c1d22100000000000000000000000000000000610500a001439110000000000000000000000000000000000000000000000000
7162111070d142104021e51050226410000000000000000000000000000000000000000000000000000000000000000036102889bc0c0808273048880a4cda26
4242344042c3d0407026412070c5013070d4f210428443805054b48042b21180e13251c000000000000000000000000000000000000000000000000000000000
1242b22002a60081702600811265d1104041b0104062b0100000000000000000100048880c28080800000000000000003e10288a086d08082710384808e8e908
b0c1f01080c4e1a0000000000000000000000000000000000000000000000000b1223250b121e250b112e4100000000000000000000000000000000000000000
01d17010f109321012f351104262f180f1460210000000000000000000000000171038185ae80808000000000000000031102809084b0808271058880829cb08
5056418070e341106032510160b4011000000000000000000000000000000000b1c4d310c1c2d310c1f271100243b120f041f010b14121100000000000000000
f0a376101243c410d1f223101243421001b333506032911000000000000000001300588883880808000000000000000000080000000000000008000000000000
d0b1d14121a3a130701541102126a11000000000000000000000000000000000b1325301c132b110c1c5611002545110000000000145b2100000000000000000
80730010124393101261321002c1c110000000000000000000000000000000000a10588805870808000000000000000000080000000000000008000000000000
00000000000000000000000d066dd66000ddd60000ddd60000ddd6000066066006066600006066000000000000022000000cc00043444344333a900000000300
0000000000000000000003d06d6666d30dd666600dd666600dd6666060606600066660660606666000022000023773200cf77fc0434543540033983303000300
000000000000000066663d0066d66d66366366363d366363d366366366606666606606606606600600233200037777300f7dd7f053543453300ab00003000300
00000000000000003667777766d66dd36666666666666666666666660666600666066666666666600237732027777772c7dccd7c534435433309ab0003003000
0000000000000000366ddddd66d33d666666666666666666666666666006666066666066066666660237732027777772c7dccd7c33b33a3400309a0303003000
00000000000000003366d30066d33dd333666633336666337766667766660666066066066006606600233200037777300f7dd7f03aa343353003893033033003
000000000000000006000d30d6d66d6d77366377003663000076670000660606660666600666606000022000023773200cf77fc03ab3a3430338330033033003
0000000000000000000000dd0dd66dd00770077070000007000000000660660000666060006606000000000000022000000cc000aba89b3a000ba0333b033030
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
88080808010001010101010188818383088888880101018101010801088808080808080801010101610101088c8c81810808080801018101610101010188888100080808010011110121111100000000080000000101010021010811080008080808080801010101610101080808000008080808010100016101012108000000
0000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010001000000000000000000000000001100000001000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000d400000000d3c0c1c2c30071707173727371730000000000cbcc0000fb00000000eeef00e90000e9000000e7e7e7e7e7e7e7e7e5e6e6e5e6e6e5e6000000c8c90000008f0f0a8e8f0007820288080c0d02068e8a8789018300070081838b0e8d810c03818c87008100070082020e0c0d820600
cfce00dbdc00dd36c4d5c5c4c510c4c5c0c1e0d1d0d1d0c36160417061616060d5e7cdcee7dbdce7edfc00ecfb00feff0000e90000000000e8e8e8e8e8e8e8e8e5e5e6e5e5e5e5e5000000d8d90000008f0f0a808200078288088f0c0d88068e0f0789858d0007008204090e0d820c8f020e0a8082000782888e0f0c0d880682
df36d5dbdccfdd361010101010101010d0d1d2131313d2d2604243414342426010e8dd36d4dbdce8fbfdeeedfced00ed0000000000e900e91212121212121212e5e6e5e5e6e5e6e6000000d8d90000000d06098d0d0007008181018c8581868d80820880820007008505860c0d800600888e0a8082000782880e0f0c0d880602
df3607dbdcdfdd361010101010101010e1e1e2e1e1e2e2e166666766676767661012dd3610dbdc12fcfbfbebecebeceb000000e9000000001212121212121212e5e5e6e5e6e5e6e5000000d8d9000000060709008100078202020e0c8502860d89090a88080007028280000c0d82060880850880850007820d06060c8d0d8600
ccddddcc012020208a464746b8202020042727264746070641202020676667661b0a1b1b005c00015e0a5e0bdc08881c20a0a020020201022121212120202020717071719a9a9a9a60101010202020243636373e0000000014f676766667143677253636363614155b4a5b5b001c001c001c001c1e415e415e415e5e1f363636
988989982020212047012020b8032003143636154607060741410303767676760008005c005c001c1e088008dc08881c02070702e0e0e0012222222202020202617060709a9a9a9a601010102020202436373e013232323214f676767676143676f936f936f914158b8b8b8b001c001c001c001cc01cc01cc01cc0c03d1f3736
985455982120202046200210b8012001143636370707070727262627f6f676761e081e5c0b0a0b0b0b0a5e0b1e0a8a0102393902e0e0e0020202020203cf02ce60636160020202026010101074747424363e3d213435353414f67676b976143776d914d925d914151e011e1e5b4a5b5b000100015e415e415e015e5e02105f37
985455984747474747201010b8202020253636360707070737363636f6f676760008005c0008001c00081c08dc08881c20a0a020e0e0e002ce02cfce2627262663626163a0a0a0a060101010757575243e2102202222222214f6767657b9041576e925e936e93715001c00008b8b8b8b001c001cc01cc05cc0c0c0c03d1dbd5f
e0e0e0e002e0e00202020202101010102464652501d0d03c203d2002187655980223230200000000060706002b2b2b2b1ee1e0e1e0e1e178e0e0e0e0001c001c000000000000000000000000000000002020202020202020767676766a6a6a6a2103212036377677000000000000000035343434041d1d022f3f3f2f16161616
e0e0e0e020e0e0201ae0e01a2020202025646524222203a2aaaa2a2a18765598231d213d72723232060706002b2b2b2b30e0e0e1e1e0e178e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf76767676babababa62626262373976760000000000000000467676762523233d220c0c34172e2e2e
e0e0e0e020e0e0201ae0e01a21202020256465251d1d11bdeaea2a2a18765598231d033d424242021b1b1b00212020211ee1e0e0e1e0e0781e011e1ee0e0e0e00031c32b30313031000031000000000002026626470706077676767602020202262726272001b9b941323232323232324676767624f5f5f434350c3439393939
e0e0e0e002e0e0020202020202cecfcf246564253b3b3b3b7a7a3a3a187655980202020261606060409c400003202120001c011c202121b800000000e0e0e0e032c3c32bb0a120303133b0b132323232222276367636063676767676101010103939393921102120161616560202cf0235aeae352f3f3f2f2f3f222f22222222
1e1dac808080801baf80808018a718bb18a283129e9e9e1980808080049c80bb808080808080808018393f391699128080808080338033333333b00fb3b33a3abb3a8080338080808080801cbb80bbbc9480808080809f800b1c80808080800b80803f3f3d3f3c2a801a1a1a1a801a1a9a9a1a1a1a1aa01a968080bbbb808097
8038ac80b03333af3880808018a7838383a183128080bb9380808080161d8037ae1d80809b80a01e18b8b89816991280808080bb00a91d1a340c3f37b5352525a6a5808087bb1abb8033808b0c29ac9f06808080808006800b1b803a803abb0bbbbb878729bb131d1d8402820dbb318080802a1daabca080b68080afaf8080b6
1e1eac1e1806c7a0af80bbbb18a79818182783128080b62580808080162f2928a02f29298e29af29373f3fa33f3f1229292929b6270707073c3c353c3c3f3f3f1a8033bbb7b62626bb0c309da2971c97aa808080808098803c143ab73ab4a63f268202bcbc133c1d1c9f020cb42eac1e8080809cbbbba03b962929230d292934
8080b8ac18191d1eadbb189318a79818182783128080b61980808080018f8f0f3506060f8f8f8f35018e8e820d288e8f85040707073c3c3c3f3f1a1a1a1a808080803c3c3d06269d9b9b263d13269b3c2a3f3f3f3f3f98808f8f250125258080802cac2e2e2c8f1b1b1b1b1b1b1ba6061e801e1d1b1b85058445844747074584
80801c3418199c809cb418b4061e351eab1e833838383819736a737316041636902436360418180418868f0e8fa607368080808080808080808080808080808080801f1616bf1a1a9a9a1a1a1a1a1ebf1e1e1e1e1e1e1e803c3c3c3c1a1a8080801a8080801a1a80808080808080808064456e46527271526c79d95a5a797676
30801aa023239c809cb6019318a7278087198307b7b7180707070707079039179936363636363699360707070707070780808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080bbbbbbbbbbbbbb3172d0457279c3464d78806c6c7172505f76
068080ae18199a9a9a9a19931880808080808080808080808080808080808080066534062020202020658e2020208080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080804747472e2e444744d0d0454cc352f96c6c8080dcf56e6ccf79
1880808018199a9a9a9a193406808080808080808080808080808080808080803667971420204020a70b202020208080808080808080808080808080808080808080808080808080808080808080808080808080803c3c808080808080808080808080808080807679d9507164767644d0456ef5526edadbdb6adc7971505f47
18aeae3023811c1d1e1e199718808080808080808080808080808080808080803c679781b581673d810b8181406580808080808080808080808080808080808080808080808080808080808080807271507f7f863e969780808080808080808080803ca47f9220d974c2c161645879d9646a7279526a806e5ddc5b50c25ae857
373b6a3737370d370c0634a68180808080808080808080808080808080808080d6f6f6f60bf61f05f60bf6c7676780808080808080808080a4b7b7b7b7b79621ad21ad212180808080808080808075f878b8061386a5bc808080808080808080808080adadad40d6d744fd46d0f9c2c3e34646cf525c71506a46cfc2615061d7
07474707860f0635b8b8b83838808080808080808080808080808080808080808bf6c7f60bf6f69ff60bf6c79f6780808080808080808080a4010101010196a626a8b6970480808080808080808080808080808080808080808080808080808080803ca1202067d2c25fd958d0c2f86d78363636c646cfcf857676c6f8c646c5
80808080808080808080808080808080808080808080808080808080808080808bc7f6f60bf6f6d7f60bf6f6f60b80808080808080808080a411111111113d06adb60197598080808080808080808080808080808080808080198097181818198080808037202747fd52617979fd78c759808080af8080321031507180808080
80808080808080808080808080808080808080808080808080808080808080808bc7c70c0bf6f6f6f60bf6c7c70b808080808080808080803d01010101a496b6b6b68ca1648080808080808080808080808080808080808080193497b4b42565298b26a7402027d9d452f478c6f8f8f856808080ae1aae2cf641ce9772808080
80808080808080808080808080808080808080808080808080808080808080808906060684060606068a0909098a8080808080808080808002b7b7b7b7a4960c0c0cadb6df80808080181912808312808080801899bb3abbb7191a1af625259f222227a79f2027456e45455c7172805c6a80805d80801aacc7ce4df4ac806a80
80808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080809281818181a4960c8c0c8cb6978080a2ac3f24128083128080803181998d22a2261980b4f6f62597b49d27a777209f6e805a6a5c6c45455b5b71485c8072801cd6c24c975c717872
80808080808080808080808080808080808080808080808080801c801c808092202020121c80248080808080802b33802b930480808080803d25be3838139637bf1794b69702bb33a08383122983981280ac931896b522b59f19809718181819128027a70ca2a48080716c4cc36e6e5a45c14d5071c1505068418f1249c150c1
2933802b29332929040734068f3729b230b280803434062980801c801c29bb20200f35061b9b2480808033332b3782bbb493048080808080809ca280809c37bd87b9878c97a71baea093021819868712bb37931899ad22223c278097f6b4f613128027e7ef8213455d525b5d6c8072804547c6c545454747474747474747c646
07070786041b07060d3797363686260407862981b48505b8a9291a801a8185040799961280801a3a3abab506063d350613ac16808080801a1aa2801a8d979924bfbf37bc97a79632ae381d981919040735060518142e3fae9f2780b525258f25871e27a7781c2748806d455b5b5b6a8045507172807271727172f38080727150
36363636991a173607070707363636363607070707073617248638b838079916361704350638387f047f7f7f7f7f7f9996b516808080802e2ea61a1a1c9796010106b8bf97a7342ca0af2c2b2719993636363636b680aa029719809718181819928027a71c1c274580526ac3526c5c8045d047c1504747c3c3f8467150c3d064
3c3c3f3f3f3f3f3cb6223f3cb90d2882039ff6c7f6d6b4b4259f80808080808080808080808080789e4606010f46069e7f815680808080a11a1a1c1d1d9796b9b68702b697881a1a80ae988127193c3c3c3c3c14b68080a1242780b5f6f6f6b4871e27a7981c276a69526ccf525c5c80cac476e3c37979524de379c2c34cd8d0
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
01 2a307f5b
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

