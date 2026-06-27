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
	
	l_m()
	
	--init global vars
	-- camera x & y, anim counter, _ , time counter
	mod_tabl(_ENV,"cX,cY,aC,aL,t_c,t_enms,lvl_enms,t_e_c,lvl_e_c,t_tr,t_tr_c,l_lock,vInfo/0,-256,0,2048,0,0,0,0,0,0,0,false,false")
	
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


function _update_m_menu()

	-- drawing
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
	

	t_c+=0.0333
	

	if btnp(0) or btnp(1) then

		local xdir=-28
		m_i-=1

		if btnp(1) then
			xdir=28
			m_i+=2
		end
		
		m_i %= #start_lvls
		
		l_lock=m_i>0 and dget(m_i-1)<=0
		
		scrW(xdir,8,
			function() 
				load_lvl(start_lvls[m_i+1])
				
				lvl_mus,layers_active=0,0b1111
				update_mus()
				
				if (l_lock) pal(split"1,1,1, 129,129,0,7, 129,129,129,129, 12,129,14,13,  1",1)
			end
		)

	end

	if btnp(4) and not l_lock then
	
		scrW(24,9,
			function()
				cls(9)
				camera()
				print("\f7\^o80b\^j22"..m_title.."\n\^5\^j05\#a\^x5\^o8ff\^d1"..lvl_title.."\^x4\^o80b\#9\^j25\n\^5\^d1\n  "..m_splashes[m_i+1])
					--pal(7,6,1),pal(7,13,1)&pal(7,5,1) with pauses inbetween. the 13 is 1d as 0d is newline
					print("\^5\^@5f170001⁶\^3\^@5f170001。\^3\^@5f170001⁵\^3")
				--end
				cls(9)
				b_l(false)
			end
		)
		
	end
	
	if (btnp(5)) vInfo = not vInfo
	Utimers()
end


function scrW(spd,col,midfunction,m_args)
	
	dT(0,function() -- delay until frame end to not mess with other calculations
		local len = 400\abs(spd)
		
		local start_x = 128
		if (spd<0) start_x = -240
		
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


-- begin level
function b_l(cont,retry)

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
		mod_tabl(_ENV,"t_c,t_enms,t_e_c,t_tr_c,t_tr,lvl_prevmus/0,0,0,0,0,0,0")
	end
	
	-- lvl var defaults
	mod_tabl(_ENV,"aC,lvl_enms,lvl_e_c,lvl_e_req,x_u_l,y_u_l,trn_bnc,trn_slp,grav,lvl_tr_c,lvl_trinkets,sl_l,sl_c,sl_smth,sl_vx,sl_vy,sl_dmg,alert,l_t_c,sl_r,sl_h,sl_spd,wind/1,0,0,0,0,0,0.2,0.75,0.217,0,0,1024,6,0.982,0,-0.2,0,false,0,0,0.04,5,0")
	x_l_l,y_l_l=l_border_x,l_border_y
	
	-- lvl extra globals and defaults
	mod_tabl(_ENV,extraglobals)
	
	sl_vec = vec2_new(sl_vx,sl_vy)
	
	update_mus()
	if (lvl_mus != lvl_prevmus)	start_mus()

	menuitem(2 | 0x300, "retry area",retry_lvl)
	menuitem(3 | 0x300, "exit level",exit_lvl)

	-- init entities, clear all
	entities,all_links={},{}
	player = spawn_entity(p_spawn_x,p_spawn_y,2)

	add(entities,player)

	for i=1, lvl_numentities do
		sp_lvl_e(i)
	end
	
	
	cX,cY,prev_cam_speed=player.pos.x-64,player.pos.y-64,vec2_zero+vec2_zero
	limit_camera()
end

function load_next()
	t_enms+=lvl_enms
	t_e_c+=lvl_e_c
	
	t_tr+=lvl_trinkets
	t_tr_c+=lvl_tr_c

	if lvl_next_level >= 0 then
		loaded_lvl_index=lvl_next_level
		b_l(true)
	else

		lvl_score = t_e_c/t_enms*75
		if (t_tr > 0) lvl_score += t_tr_c/t_tr*25
		lvl_score\=1
		if(lvl_score > dget(m_i)) dset(m_i,lvl_score)
		lvl_mus=-1
		start_mus()

		menuitem(2)
		menuitem(3)
		
		camera()
		print("\f7\n\n\^w\^t\^o8ff\^2\^d1 \as8....a#0.a#0.d#2d#..a#1a#d#2d# \^2"..m_title.."\n\^d0       \^4\^3complete!\n\n\n\^-w\^-t\^6◆ \as9x5d#2d#3 "..t_e_c.."/"..t_enms.." machines 'disassembled'\n\n\^5\^4◆ \as9x5d#2d#3 "..t_tr_c.."/"..t_tr.." trinkets recovered\n\n\^5\^4   \as9x5d#2d#3 time: " .. t_c .. " s\n",0,0)
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

-- load menu
function l_m()
	mod_tabl(_ENV,"cX,cY,timers,lvl_mus,layers_active/0,0,{},0,15")
	clear_timers()
	menuitem(2)
	menuitem(3)
	update_mus()
	start_mus()
	_update=_update_m_menu
end

function exit_lvl()
	scrW(24,12, 
	function()
		--[[_draw=Dmenu]] 
		load_lvl(start_lvls[m_i+1]) 
		l_m()
	end)
end

function sp_lvl_e(i)
	local Etyp,ex,ey,e_extra = peek(lvl_entity_loc+i*4-4,4)
	ex,ey,e_extra = ex*4-32,ey*4-128,ntt_extrainfos[e_extra]
	local e=spawn_entity(ex,ey,Etyp,nil,e_extra)
	e.lvl_i = i
	add(entities,e)
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
	
	
	t_c+=0.0333
	l_t_c+=0.0333
	aC+=1
	aC%=aL
	if aC%8==0 then
		alert=false
		update_mus()
	end
	
	sl_l += sl_r + sin(l_t_c/sl_spd)*sl_h
	
	for ntt in all(entities) do

		for subntt in all(ntt.all_ntts) do
			
			
			-- move entity
			if (not subntt.nophys) then
			
				subntt.pos += subntt.vel


				-- clip out
				local did_c,with_t,out,surface_dir,coll_e = unclip(subntt)
				if did_c and out then
					subntt.pos += surface_dir
				end


				if did_c then

					if out then
						impact(subntt, with_t, surface_dir, coll_e)
						subntt.coll_rng=0
					else
						if with_t then
							subntt.coll_rng += 6
						else
							subntt.pos += vec2_norm(subntt.pos - coll_e.pos)
						end
					end
				else
					subntt.coll_rng=0
				end
				

				-- update stand
				subntt.is_stnd=false
				local down_pos = subntt.pos+vec2_down
				-- if 1st is true 2nd does not evaluate so no much lag
				if colltrn(down_pos, subntt.rds) or collntt(subntt, down_pos) then
					subntt.is_stnd=true
				end

				
				-- rope
				if first_lnk(subntt, subntt.rope_ntt) then
					subntt.pos = subntt.pos*0.95 + (subntt.rope_ntt.pos - vec2_new(subntt.rX,subntt.rY))*0.05
					AIPfly(subntt)
				end
				
				--fall
				if not subntt.sSt then

					if subntt.is_stnd then
						subntt.vel.y *= 0.95
						subntt.vel.x *= 0.6 + max(subntt.slip, trn_slp)*0.4 -- friction
					else
						subntt.vel += vec2_new(wind, subntt.grav)
					end
				end
			
			end

			
			
			
			-- call its update function
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
		
		if ntt.pos.y > y_l_l+80 then
			rmE(ntt)
		end

		if ntt.pos.y > sl_l then
			if (#ntt.vel > 3.8) particles(ntt.pos, split"14,5,0,0.3,9")
			ntt.vel = (ntt.vel + sl_vec) * sl_smth
			lose_stmn(ntt, sl_dmg)
		end
	
		for name, timer in pairs(ntt.ts) do
			ntt.ts[name] = max(0, timer-1)
		end
	end

	--check links
	foreach(all_links, tug)


	if player.pos.x > x_l_l+12 and btn(1) and lvl_next_level > -2 and lvl_e_c >= lvl_e_req then
		if lvl_next_level > 0 then
			scrW(24,8,load_next)
		else 
			load_next()
		end
	end -- todo maybe add else here to skip cam update after lvl exit
	
	-- camera tracking
	local t_p=player.pos+player.vel*20
	t_p.x += tonum_flip(not player.is_left)*8
	t_p.y += player.iDir.y*18

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
		if lvl_e_c < lvl_e_req then
			c = 3
			txtB("\^o95a"..lvl_e_c.."/"..lvl_e_req,false,x_l_l-14,player.pos.y)
		end
		
		local function l(o_x)
			line(x_l_l-o_x,y_u_l,x_l_l-o_x,l_border_y,c) -- use default y limits here only for upper
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
			map(unstr"0,0,0,0,128,64,1")
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
	rectfill(-256,sl_l,2048,1024,sl_c)
	poke(0x5f5e, 0b11111111)
	
	
	-- ui
	
	camera()

	fillp(0b10111010.1)
	rectfill(unstr"3,2,75,8,8")
	fillp(0)
	
	rectfill(3,1,75-player.stmn_h_dmg,8,8)
	rectfill(4,6,player.magnetcharge+4,7,3)
	rectfill(4+player.stmn,2,player.ts.hurt/2+4+player.stmn,4,7)
	rectfill(4,2,player.stmn+4,4,12)
	
	rc()


end



-->8
-- token savers

function unstr(str)
	return unpack(split(str))
end

-- thank you Lokistriker whoever you may be
-- modifies/appends to table. can target _ENV to change globals

-- note when doing implicit nils the value size shouldnt be 0 as the first elem is "" instead
function mod_tabl(tab, kv, splitter, delim)
	local k,v = unpack(split(kv, splitter or "/"))
	k,v = split(k,delim),split(v,delim)
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
	if(v=="nil")return
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


function spawn_entity(x,y,type,parent,extraprops)
	local entity = mod_tabl2({},"pos,vel",{vec2_new(x, y),vec2_zero+vec2_zero})

	local pr = split(ntt_types[type], "|")
	local props_c,props_e = pr[1], pr[2]
	
	-- defaults
	mod_tabl(entity,"ts,bnce,slip,grav,Uf,Df,is_left,coll_rng,actN,actF,rngN,rngF,Iarm,Irss,spr_size,d_o,outl,magnetcharge,lzr_thck,dash,jumping_d,ray_iters,j_cldwn,X,rds,mass,sprite/{},_V_trn_bnc,_V_trn_slp,_V_grav,_V_e,_V_Dntt,false,0,55,100,0,35,0,1,8,3,0,70,10,0,0,2,8," .. props_c)
	
	-- only primary entities can have timers(ts) - non-custom ones, anyway -- why...
	-- type (template) removed - maybe re-add if needed
	mod_tabl2(entity,"iDir,all_ntts",{-vec2_zero,{entity}})


	-- xtra props from a source
	if (entity.X != 0) mod_tabl(entity,split(ntt_types[entity.X], "|")[2])
	
	-- props
	mod_tabl(entity,props_e)
	
	if (extraprops) mod_tabl(entity,extraprops)
	mod_tabl(entity.ts,"hurt,hitshock,jump_cooldown/0,0,0")

	-- applying table indexes
	mod_tabl2(entity,"smok",{split(smokes[entity.smok])})
	if (entity.gunid) get_gun(entity)
	
	if parent then
		entity.parent=parent
		entity.pos+=parent.pos
		entity.vel+=parent.vel
	end

	entity.stmn_l_t = entity.stmn

	if (entity.enemy == true) lvl_enms+=1 -- == true is needed here

	if entity.item==4 then
		lvl_trinkets+=1
	end

	if entity.Btyp then

		-- init complex
		local b_info = split(ntt_b_types[entity.Btyp])
		entity.props = b_info
		-- todo merge?
		--more defaults,subentity mappings for limbs & cooldown for leg movement
		mod_tabl(entity,"g_mode,gr_e,leg_facing,facing,surface_away,rDir,m_l_legs,m_l_arms,leg_cd/false,nil,_V_vec2_down,_V_vec2_up,_V_vec2_up,_V_vec2_up,{},{},0")
		
		mod_tabl2(entity,"g_acc,a_acc,g_max,a_max,jump_str,leg_len,arm_len,stnd_height,leg_speed,leg_cooldown,leg_angle_range",b_info)

		for i=12, #b_info, 4 do
			local l_typ,angle,l_i,l_ex = unpack(b_info,i)
			local l_e = spawn_entity(0,0,3,entity)
			mod_tabl2(l_e,"t_pos,angle,t_active",{l_e.pos,angle--[[,nil]]})

			add(entity.all_ntts, l_e)

			if l_typ=="l" then
				add(entity.m_l_legs, l_e)
			else
				add(entity.m_l_arms, l_e)
			end
			-- is 4664 but 1 indexing, could use refactoring
			make_link(entity,l_e,{peek(4536 + l_i*128,7)}, l_ex)
		end
	
	end

	if entity.rope then
		entity.rope_ntt = tmpTrnE(entity.pos + vec2_new(entity.rX,entity.rY))
		make_link(entity, entity.rope_ntt, {peek(4536 + entity.rope*128,7)}, entity.rope_e)
	end
	
	if (entity.dur) dT(entity.dur,rmE,{entity})
	
	return entity
end

function Uitm(i)
	if #(i.pos-player.pos) < 10 then
		if i.item == 5 then
			player.stmn_h_dmg,player.stmn=max(0,player.stmn_h_dmg-i.amount),min(player.stmn+i.amount,70)
		else
			lvl_tr_c+=1
			txtB("\^ocfftrinket!",0,i.pos.x,i.pos.y,unstr"0,0,0,0,45")
		end
		rmE(i)
	end
end



function retry_lvl()
	scrW(-24,8,b_l,{true,true})
end

function rmE(ntt, noeffect)
	if ntt == player then
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
			lvl_e_c+=1
			local txt="\^oc09"..lvl_e_c.."/"..lvl_enms
			if (lvl_e_c >= lvl_enms)txt="\^oc09area clear!"

			txtB(txt,0,player.pos.x,player.pos.y,unstr"0,0,0,0,50")
		end
		
		local pos = ntt.pos
		
		if (ntt.expl) expl(ntt.pos, ntt.expl)
		
		if (ntt.rspw) sp_lvl_e(ntt.lvl_i)
		if (ntt.next_e) add(entities,spawn_entity(ntt.pos.x,ntt.pos.y,ntt.next_e)) -- todo check if needed?
		
		if ntt.boss then
			lvl_mus=-1
			start_mus()
		end
	
		if (ntt.smok) particles(pos,ntt.smok,ntt.vel)
		if (ntt.b_f) ntt.b_f(ntt)

	end

	return is_present
end

function make_link(e1,e2,link_props,extraprops)
	local link=mod_tabl2(
	{},"from,to,len,str,d_t,col,width,d_o,outl",
	{e1,e2,unpack(link_props)})
	mod_tabl(link,extraprops or "➡️", "➡️","`")
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
	local lvl_bg,bg_sampl = {peek(loc,8)},{}
	
	for i=3,8 do
		lvl_bg[i] = lvl_bg[i]-128
	end
	
	mod_tabl2(_ENV,"b_ip,b_wxy,b_sc,b_prlx,b_ofx,b_ofy,b_timx,b_timy",lvl_bg)
	
	for i=0, 15 do
		add(bg_sampl, @(11776 + b_ip\16*4 + i%4))
	end
	pal(bg_sampl)

	local p_sc = b_sc*8
	
	local a_p_sc,scroll_x,scroll_y = abs(p_sc),-b_ofx+cX*b_prlx/64+t_c*b_timx, -b_ofy+cY*b_prlx/64+t_c*b_timy

	if(b_wxy%2==1) scroll_x %=8*a_p_sc
	if(b_wxy>1) scroll_y %=4*a_p_sc



	for i=0, (128\(8*a_p_sc)+1)*(b_wxy%2) do
		for j=0, (128\(4*a_p_sc)+1)*(b_wxy\2) do
			camera(scroll_x - 8*a_p_sc*i, scroll_y - 4*a_p_sc*j)
			
			for x=0,7 do
				for y=0,3 do
					local n = @(0x2000 + b_ip%16*8 + x + y*128)
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
		e_spr += ((aC\(entity.f_l or 2))%(entity.f_c or 1))--*s_x
		
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
	
	if d_t == 3 then
	
		local pos_2 = p1 + envstr.vec2_norm(-from.facing)*3
		envstr.line_vec(p1, pos_2, l_c2, t_w)
		
		p1,left,t_l = pos_2, not left, (true_len - 3)/2
		
	elseif d_t == 4 then
		left = false
	end
	

	
	-- draw_joint
	if p1 != p2 then

		-- circl intersect
		local d,mid_p = #(p2-p1),(p1+p2)/2
		local op = (p2-p1)*envstr.sqrt(t_l*t_l-d*d/4)/d
		local op2 = envstr.vec2_new(op.y,-op.x)
		local k_2, k = mid_p+op2, mid_p-op2

		
		if (left) k=k_2
		envstr.line_vec(p1,k,l_c,t_w)
		envstr.line_vec(k,p2,l_c,t_w)
	end
	
end


function line_vec(v1,v2,col,thickness)
	for i=0, thickness or 0 do
		local vec = ({vec2_right,vec2_down,vec2_left,vec2_up})[i%4+1]*((i+3)\4)
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


-->8
-- sounds

function update_mus()

	for i=0, 63 do
		--0x3100 is start, 0x3101 means target 2nd channel
		for j=0,3 do

			local addr = (0x3100+j + i*4)
			local fl = @addr
			if bcheck(layers_active, 1<<j) and fl&63 != 63 then
				fl &= 191
			else
				fl |= 64 -- disable channel
			end

			poke(addr,fl)
		end

	end
	
	--[[
	if player and player.pos.y > sl_l then
		poke(0x5f43,0b1111)
	else
		poke(0x5f43,0b0)
	end
	]]
end

function set_mus()
	mus_e=not mus_e

	music(-1)
	local s="music:off"
	if mus_e then
		s="music:on"
	end
	start_mus()
	menuitem(5,s,set_mus)
	return true
end

function start_mus()
	if mus_e then
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


-- to copy, either do +vec2_zero, *1 or -negative (if constant)

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


function vec2_rotate(v,a)
	return vec2_new(v.x*cos(a) + v.y*sin(a), -v.x*sin(a) + v.y*cos(a))
end


-->8
-- helper functions

function e()
end

-- todo remove/inline/replace these?
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
	-- projection
	-- if s is 0,
	-- (0/0) is is max num
	-- * 0 is 0
	local vc = s*(vec2_dot(v,s)/vec2_dot(s,s))

	local v1,v2 = vc*m1, (v-vc)*m2
	return v1+v2,v1,v2
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

	mod_tabl(tmp_ntt,"Etyp,stmn,stmn_l_t,rds,Iarm,Irss,bnce,mass,Cdmg,g_i/tile,50,50,3.5,5,3,0.45,0.27,nil,nil")
	tmp_ntt.sprite=tmp_ntt.tile
	if (fget(tmp_ntt.tile,5)) tmp_ntt.expl,tmp_ntt.stmn = 2,11.5

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


function expl(pos, e_prop_i) -- also is 4140
	local radius, str, sf = peek(4012 + e_prop_i*128,3)


	local function get_expl_ntt(other)
		local dist = other.pos - pos
		-- no damage falloff! simpler and removes some jank from game
		expl_ntt = mod_tabl2({},"pos,vel",{pos,vec2_norm(dist)*str/2 + other.vel})
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

		ts.hitshock = dmg*0.5+0.7

		-- SOME MINIONS HAVE ENEMY TO "f" SO IT'S NOT THE TRUE BOOL ELSEWHERE BUT DOES EVALUATE HERE
		if enemy and stmn > 0 and total_dmg > 1 then
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
	if (fget(ntt.tile,6)) ntt.Cdmg,ntt.kb = 12,0.5
	return ntt
end

function coll_p(e,p,i,o)
	-- first thrown hit is buffed
	if e.stmn and o.thrown and o.coll_func != Chook then 
		i,o.thrown = i*3+8--,false
	end
	
	if o.Cdmg then
		lose_stmn(e, o.Cdmg)
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
	
		impact_2 += rnd(1)
		coll_e = tile2ntt(coll_e)
		coll_e.vel *= 4
		
		if (impact_2>2.1) coll_e.sprite = 15
		if (impact_2>2.5 or #entities > 10) rmE(coll_e)
		
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



function tug(link)

	local e1,e2 = link.from, link.to
	local e2_pos = e2.pos

	local diff = e2_pos - e1.pos
	local move_dist = #diff - link.len

	-- amount that entities need to move to remain in link range
	local move_need, do_move = vec2_norm(diff) * move_dist--,nil

	-- check if tugging is needed
	-- small tolerance (0.6) so it isn't constantly active
	if (move_dist >  0.6) do_move = true
	
	-- break if too far
	if link.str > 0 and move_dist >  link.str then
		delete_link(link)
		return
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
			if (vec2_dot(move_need, e2.vel - e1.vel) >= 0) transferMMT(e1,e2, 0.1, 1)
			
		end

	end

end

-- rough iterative raycast with angling
-- todo inline? check if worth it
function ray_coll(pos,vec,angle_range,leg_entity,entity)
	for i=1,entity.ray_iters do
		local t_vec = vec2_rotate(vec*(rnd()+0.1),angle_range*(rnd()-0.5))
		local t_pos = pos + t_vec
		local coll_land,with_t,out,away_vector,other_ntt = unclip(leg_entity, t_pos, leg_entity.rds+2, true)
		local is_magnet = entity.magnetcharge > 0 and (fget(mget(t_pos.x\8, t_pos.y\8), 2) or other_ntt and other_ntt.tile == 24) -- only 44 & 45 get wallset
		
		-- todo if need away vec check?
		if (coll_land and out and (vec2_dot(t_vec,away_vector) <= 0 or is_magnet)) return true, t_vec, with_t, away_vector, other_ntt, is_magnet

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


	local prev_jump,stand_vec,max_dist,max_leg,max_stand_center = g_mode,envstr.vec2_norm(entity.leg_facing)*leg_len*1.25, stnd_height/2

	envstr.mod_tabl(entity, "sSt,g_mode,g_no_slide,slide,magnetwalk/false") -- implicit nil chain
	sticky = permastick
	
	-- proc move legs

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
					
					leg.surface_away,gr_e,dist=envstr.vec2_norm(away_vector),other_ntt,#(leg.t_pos - stand_center)
					
					if dist > max_dist then
						max_dist,max_leg,max_stand_center = dist,leg,stand_center
					end
					if dist <= leg_len*1.4 then
						leg.t_active = true
					end

				end

			end

			-- move legs to targets
			if leg.t_active and not fget(gr_e.tile,6) then
				g_mode,slide=true,gr_e.tile and iDir.y > 0
				g_no_slide = not slide
				
				st_pos+=leg.t_pos
				st_away+=leg.surface_away
				st_c+=1
				
				if (leg.magnetwalk) magnetwalk = true
				
				if g_no_slide then
					envstr.move_towards(leg,leg.t_pos, leg_speed)
				
					if #vel < 8 then
					
						if (sticky) leg.vel*=0.75
						

						if leg.is_stnd and leg.surface_away.y<0 or sticky then
							sSt = true
						end
						
					end
				end
			end
		end

	end

	-- assign new target - only if off cooldown and outside tolerance range
	if leg_cd <= 0 and max_leg then
		max_leg.t_pos,max_leg.t_active,leg_cd  = max_stand_center,true,leg_cooldown
	else
		leg_cd -= 1
	end

	if (st_away.y <= -0.5) st_away.x = 0
	surface_away=envstr.vec2_norm(st_away)


	if sSt then

		vel.y *= 0.85
		
		if not sticky then

			pos.y = pos.y*0.9 + (st_pos/st_c + surface_away * (stnd_height + envstr.aC\48%2)).y*0.1

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
	
	if ntt.ts.hitshock < 3 then
	
		
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
						ntt.vel *= 0.5 + trn_slp*0.4 -- wallslide
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
						
						make_link(ntt,ntt.grabbed_e,split(ntt.arm_len .. ",40,0,14,0,0,0"))
					end
				end

			else
				--throw if holding, else nothing

				if ntt.in_grab then

					sfx2(-4)
					if (ntt.grabbed_e.mass < 0.125) throw_str *= ntt.grabbed_e.mass/0.125 -- limit on throw speed
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

		


		local pv_add = vec2_norm(vec2_new(input_dir_l.x, (ntt.flying or (ntt.sSt and ntt.sticky)) and input_dir_l.y or 0))*accel

		if ntt.sSt then
			if (not ntt.magnetwalk) ntt.magnetcharge += 10
			if (input_dir_l.x == 0) ntt.vel.x *= 0.15 -- brakes
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
		local align_down,al_of,g_e=-vec2_up,ntt.vel*0.5,ntt.gr_e
		
		if (g_e) g_is_ntt = g_e.Etyp != "tmp tile"
		-- jumping ----

		local jump_str,input_dir_j=ntt.jump_str,vec2_norm(input_dir_l + vec2_up*0.7*tonum(input_dir_l.y<=0))
		

		
		if ntt.b4 and jump_cooldown <= 0 then

		
			local function apply_jump()
				sfx2(j_sf)
				-- store jump state
				
				-- todo can replace min(g_e.bnce, 0.7) with fixed bounce for less tokens
				ntt.st_vel,ntt.g_bounce = ntt.vel*1, (ntt.g_mode and g_e.bnce >= 0.35 and min(g_e.bnce,0.7) * tonum_flip(vec2_dot(ntt.vel, surface_normal) >= 0)) or 0.05
				ntt.ts.jump_cooldown,jump_cooldown,ntt.st_surf,ntt.st_input=ntt.j_cldwn,ntt.j_cldwn,ntt.flying and input_dir_l or surface_normal,input_dir_l
			end
			
			

			
			-- jump cases
			
			
			-- the titular drop kick
			if ntt.g_mode and g_is_ntt then
			
				lose_stmn(g_e, 20+#ntt.vel*5)
				j_ntt,j_sf = mod_tabl2({},"pos,vel,mass,Iarm,Irss,bnce",{ntt.pos,ntt.vel,ntt.mass*3,0,1,1.6}),11
				
				impact(j_ntt, false, align_down, g_e, false, true)
				
				surface_normal=vec2_norm(ntt.pos-g_e.pos)

				align_down+=surface_normal*40
				
				if (g_e.enemy) particles(g_e.pos, split"6,3.5,0,0.35,10",j_ntt.vel)
				
				ntt.magnetcharge += 50
				
				apply_jump()
				
			-- ground - no jump fall damage parries
			elseif ntt.g_mode and vec2_dot(ntt.vel,surface_normal) > -4 or ntt.flying then
				
				for leg in all(ntt.m_l_legs) do
					if leg.t_active then
						particles(leg.t_pos,split"7,1.6,0,0.5,6", surface_normal)
					end
				end
				
				if ntt.magnetwalk then
					if (input_dir_l.y > 0) surface_normal = input_dir_l*1.25
					ntt.magnetcharge -= 21
					j_sf = 12
					--particles(leg_pos,split"3,2.6,0,0.4,8",p_prevvel)
					wallset()
				end
				
				apply_jump()
			end

			


		end
		
		

		
		-- apply jump & calculate new velocity 
 		if jump_cooldown == ntt.j_cldwn or ntt == player and jump_cooldown >= 5 and #input_dir_l > 0.1 and input_dir_l != ntt.st_input then
			local st_surf = ntt.st_surf*0.95 + vec2_up*0.25
			
			
			local jump_vel = (recomp_mul(input_dir_j, st_surf,0.10,0.8) + st_surf)
			uR(ntt)
			
			for e in all(ntt.all_ntts) do
				if (not e.e_proj) e.vel = recomp_mul(ntt.st_vel,st_surf, ntt.g_bounce, 0.55) + jump_vel*jump_str
			end
			
			ntt.st_input = input_dir_l
		end

			
		if ntt.g_no_slide then
			align_down -= surface_normal+al_of
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
			ntt.vel.y -= 2.4
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
	
	for y=0, ld_l_size_y-1 do
		for x=0, ld_l_size_x-1 do
		
			-- draw tile
			local t,x,y = @(0x2000*tonum(map_pos_y+y < 32) + map_pos_x+x + (map_pos_y+y)*128), x, y

			local t2 = t&63

			for j=0,3 do
				for i=0,3 do
					local m_x,m_y = x*4+i, y*4+j
					srand(m_x + m_y*ld_l_size_x)
					
					local s = @(8704 + t2*4+tonum(t2 >= 32)*384 +i+j*128)
					local s1 = s&63

					-- alt layout
					if bcheck(t, 128) then
						if bcheck(s,64) then
							-- flip 3rd bit
							s1 ^^= 4
							-- swap to first sprite in 2x2 segment
							s1 &= 238
						end
						if bcheck(s,128) then
							s1 ^^= 8
							s1 &= 238
						end
					end

					if bcheck(s1, 32) and (s1 & 8 == 0) then -- in bottom left part of spr page
						-- flip 1st bit
						if (rnd(20) > 19) s1 ^^= 1
					end

					-- alt texture
					if (bcheck(t, 64) and not fget(s1,7)) s1+=64
					
					mset(m_x,m_y, s1)
				end
			end
			
			
		end
	end

	l_border_x,l_border_y = ld_l_size_x*32-1, ld_l_size_y*32-1
	
	
	pal({peek(lvl_pal_addr,16)}, 1)
end


-->8
-- enemy ais

function Uenm(enm)
	local look_dir = player.pos+player.vel*2 - enm.pos
	local dist = #look_dir
	
	mod_tabl(enm,"outl,sSt,b4/0")

	enm.iDir *= 0 -- this here is why no one else uses slides OR wall-magnetwalking bc the move_humanoid in ai_p happens when iDir is 0 
	-- that is OK things work better when others dont do slides
	
	-- passive ai
	enm.ai_p(enm)

	local t_gun = enm.ts.gun
	
	
	if enm.active then
		enm.outl=15
		if (t_gun<14 and t_gun%4>=2) enm.outl=10
		
		if (enm.hz) look_dir.y = 0
		
		
		if (dist > enm.rngF) enm.iDir=look_dir
		
		if dist < enm.jumping_d then 
			enm.b4 = true
		end
		
		if (player.grabbed_e != enm and not enm.in_burst) enm.shoot_dir = look_dir
		
		uR(enm)
		
		if aC%20 == 0 then
			enm.rDir = vec2_rotate(enm.iDir/2,rnd())
			if (enm.p_a) alert = true
			
			if rnd(1) < enm.dash and (#enm.iDir > 0 or dist < enm.rngN) then
				enm.iDir += enm.rDir
				enm.b4 = true
			end
			
			-- deco damage
			if (enm.stmn/enm.stmn_l_t < 0.35) particles(enm.pos, split"6, 2.4,0,0.2,8")

		end
		
		if (dist < enm.rngN) enm.iDir=-look_dir
		
		if colltrn(enm.pos + vec2_norm(enm.iDir)*enm.rds*1.5, enm.rds) then
			if (not enm.melee) enm.iDir = -enm.rDir
		elseif timer_ready(enm, "gun") then
			fire_gun(enm)
		end
		
		
		
		-- active ai
		enm.ai_a(enm)
		
	else
		enm.ts.gun=enm.gun[1]/2
	end


	-- late update so doesn't bug out when immediately spawning in range
	
	if dist < enm.actN or alert then
		enm.active=true
	end
	if dist > enm.actF then
		enm.active=false
	end
	

end

-- passive ais
function AIPstbl(enm)
	move_humanoid(enm)
end

function AIPfly(enm)
	enm.vel *= 0.9
	enm.sSt = true
end

-- active ais
function AIAfllw(enm)
	move_control(enm)
end

function AIAhvr(enm)
	if (enm.pos.y - player.pos.y > -enm.rngN) enm.iDir.y = -100.75
	AIAfllw(enm)
end

function get_gun(e)
	local id = e.gunid-1 -- todo edit arrays to remove line
	e.gun={peek(4608 +(id%8)*128+(id\8)*11,11)}
	e.gun[5] = e.gun[5]/128-1
end

function fire_gun(e)
	if not e.in_burst then
		get_gun(e)
	end
	
	mod_tabl2(_ENV,"cldwn,p_t,spd,sf,angl,p_gl_b_amount,b_delay,b_angl,nxt,p_extraprops,p_mods", e.gun)
	p_extraprops = prop_mods[p_extraprops]
	p_mods = prop_mods[p_mods]
	
	sfx2(sf-128)
	local proj = spawn_entity(0,0,p_t,e,p_extraprops)
	if (e.is_left and not proj.gmelee) angl = -angl
	if (proj.ghz) e.shoot_dir.y = 0
	proj.vel+=vec2_rotate(vec2_norm(e.shoot_dir),angl)*spd/8
	
	if p_gl_b_amount\128 == 1 then
		proj.parent=nil
		add(entities, proj)
		proj.pos+=vec2_norm(e.shoot_dir)*e.rds*1.7
	else
		add(e.all_ntts, proj)
		proj.e_proj=true
	end
	
	
	if p_gl_b_amount%128 > 1 then
		e.in_burst,e.ts.gun = true,b_delay
		e.gun[6] -= 1--p_gl_b_amount
		e.gun[5] += b_angl/128-1
	else
		mod_tabl(e,p_mods)
		e.gunid=nxt
		get_gun(e)
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
			line_vec(p1,p2,15,timer_t)
		end,
		{ntt.pos,ntt.parent.pos},true
	)
end

function DlEx(ntt)
	Blzr(ntt)
	dT(30,expl,{ntt.pos,ntt.dly_expl})
end

function Chook(ntt,other)
	local thrower = ntt.thrown or ntt.parent
	if thrower then
		delete_link(thrower.grapple)
		thrower.grapple = make_link(thrower, other, split(min(#(thrower.pos-other.pos),180) .. ",30,4,3,2,3,0"))
		rmE(ntt)
	end
end

-->8
-- data

-- levels present in the menu and some strings

m_i,start_lvls,m_titles,m_splashes,m_lore_infos=0,split"1,6,12,19,26,32",split"task d1,task d2,task d3,task ??,task ??,epilogue",split("finally, a day where our\n  name matches our service`you did bring a\n  parachute, right?````","`"),split("from: hq\n\nsome construction company's\nbots went haywire -\nthey're hoping we could\n'clean' up the situation\nbefore the public notices\nand it turns into a mess\nof paperwork.\nPERFECT OPPORTUNITY FOR \nYOUR 'SKILLS' :]`from: hq\n \nsame guys as yesterday,\nthis time it's one of their\nautomated cargo transports.\nmakes you wonder what\nthey're doing to get rogues\ntwice in a row, but hey as\nlong as they're paying i'm\nnot complaining.`from: hq`from: address unknown\n``","`")

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

lvls_info_2 = split([[   the construction site  `2`24`24`y_u_l/-32`56`14`23`3`6`1`8272`1`4832`5216`11904`5
1: roadblock`3`7`66`/`70`17`15`4`7`3`8272`2`4832`5472`12032`6
2: magnetizing yourself`4`6`328`/`71`25`14`11`7`3`8272`2`4832`5472`12160`7
3: mayhem square`5`4`170`y_u_l,lvl_e_req/-64,4`0`12`13`10`7`7`8400`0`4712`5600`4096`8
4: the small issue in question`-1`4`116`y_u_l,lvl_e_req/-32,1`24`12`12`6`7`7`8400`0`4712`5600`12056`2
  the hijacked transport  `7`16`58`x_u_l,y_l_l,y_u_l/-128,320,-32`67`21`14`4`18`5`8528`2`4728`4856`11924`4
1: what a blast`8`10`88`/`111`12`11`4`18`5`8528`1`4984`5112`12188`4
2: hang in there`9`4`300`y_l_l/416`79`25`10`11`18`5`8528`1`4984`5112`4224`5
3: too much fresh air?`10`10`115`y_l_l,y_u_l/180,-64`87`12`24`5`18`13`8656`12`5240`5368`4352`9
4: annoyingly out of reach`11`8`56`y_u_l,y_l_l,lvl_e_req/-96,111,1`81`21`9`4`18`13`8656`12`5240`5368`4128`2
control cabin`-2`6`50`x_l_l,y_l_l,y_u_l/256,96,-96`87`21`4`3`6`1`8656`12`5240`5368`4136`1
  middle of nowhere `13`210`59`/`103`16`10`9`-1`7`8288`2`4720`4848`4388`2
1: bouncy castle`14`4`315`/`103`25`10`11`28`3`8288`4`4720`4976`4244`6
2: horrid sludge pits`15`8`170`sl_l,sl_c,sl_dmg/193,1,0.75`113`16`15`7`28`3`8288`5`4976`5232`4480`4
3: hunted`16`4`154`y_u_l,lvl_e_req/-96,3`113`23`15`6`28`3`8288`2`5104`5232`4672`5
4: dry moat`17`4`28`y_u_l,lvl_e_req/-96,5`113`29`15`7`28`7`8416`1`4832`5360`4928`8
`18`11`66`y_u_l/-32`24`25`10`3`-1`3`8416`1`4832`5360`4928`0
`-2`17`75`y_u_l/-32`62`17`8`4`35`7`8416`1`4832`5360`5056`1
     the cache    `20`4`83`y_l_l,sl_l,sl_vy,sl_smth/540,382,-0.75,0.93`55`24`7`12`-1`1`8544`0`4960`4704`5060`0
1: into the system`21`4`122`sl_l,sl_h,sl_spd/200,0.75,12`38`15`14`7`42`5`8544`4`4704`4704`4800`3
2: floodgates`22`4`44`sl_l,sl_h,sl_spd/145,0.48,7`24`17`14`8`42`5`8544`1`4704`4704`4812`5
3: hideout`23`109`-6`sl_l/364`47`23`8`13`42`5`8544`4`4704`4704`4496`6
4: do you smell smoke?`24`4`458`sl_l,sl_r,sl_c,sl_dmg,y_l_l,sl_h,sl_spd/533,-0.42,2,1,600,0.40,6.75`62`21`7`15`42`11`8672`8`4976`4704`5060`4
5: `25`80`490`sl_l,sl_r,sl_c,sl_dmg/530,-0.55,2,1`98`20`5`16`42`11`8672`0`4968`4704`5196`2
"exit discreetly if possible"`-1`70`492`y_l_l,y_u_l,sl_l,sl_vy,sl_r,sl_smth/740,-2048,380,-0.6,-0.6,0.93`55`24`7`12`6`1`8544`1`4960`4704`5060`0
`27`12`86`/`122`12`6`4`-1`48`8304`0`4712`5472`5184`0
1: over the fence`28`36`-4`/`35`12`13`6`49`3`8304`0`4712`5472`5184`3
2: elevatorspace`29`3`306`/`13`12`11`10`49`3`8304`1`4968`4704`5312`4
3: the garages`30`5`81`y_u_l/-128`89`24`9`12`49`3`8304`0`4712`5472`5440`3
4: `31`12`114`y_u_l/-16`56`12`31`5`49`7`8304`0`4712`5600`5568`1
5: `-1`12`181`sl_l,sl_c,y_u_l,sl_vy,x_l_l/197,1,-64,-0.7,448`52`17`10`7`49`7`8304`0`4712`5472`5572`3
         `33`71`174`y_l_l/280`85`17`18`7`57`39`8432`0`5096`5240`5328`4
`34`71`174`grav/0.19,0.18`37`22`7`9`57`39`8432`0`5096`4832`5328`0
`35`57`-12`grav,y_u_l,y_l_l/0.19,-96,190`49`12`7`3`57`39`8560`0`5224`4832`5452`2
`36`4`170`grav,y_u_l/0.19,-64`0`22`16`6`57`39`8560`0`5352`5480`5548`5
`37`4`138`grav,x_u_l,x_l_l/0.19,-64,320`16`22`8`6`57`39`8560`0`4712`5480`4520`1
`-2`9`329`grav,x_u_l,x_l_l,y_u_l/0.19,-128,192,-128`69`25`2`11`57`39`8560`0`4712`5480`4524`0]],"\n")

--[[
	1: default box/template - UNUSED?
	2: player - high slipperiness allows for easy 2 block climb
	3: UTIL: basic limb for entities

	4: E: horizontal turret

	5: E: basic targeting turret

	6: E: laser turret
	7: E: flying drone

	8: B: big walker tank

	9: standard projectile
	10: boss 3 defeat cutscene part 1

	11: ITEM: hp

	12: MISC: tmp tile - 30x (!!) the mass to enable proper bounces
	13: MISC: sign - ignores physics, displays a text box on player coll (text is added as extra in level)

	14: boss 3 defeat cutscene part 2
	15: ITEM: trinket

	16: MISC: grappling hook

	17: E: static laser drone
	18: E: missle base
	19: B: helicopter of mass destruction
	20: P: grabbable missle
	21: P: laser targeting recticle

	22: B: big aircraft
	23: B: cool shades
	
	24: ENEMY TEMPLATE
	
	25: Projectile spawner
	26: Big sawblade
	
	27: Bounce mushroom
	28: E: sniper drone
	29: E: melee minefish
	30: alarm
	31: E: spawner drone
	32: E: shotgun drone
	33: E: robot
	34: decal
	35: laser bolt
	36: E: missle spider
	37: P: slow missle
	38: final boss
]]


-- NOTES: masses lower than 0.1 bug link-related movements
-- enemies with flying ais need "flying" prop in order to move up/down
-- template, radius, mass, sprite | extra properties (key1,key2/val1,val2)
-- prefix _V_ means an env variable of that name (minus the prefix obv)
ntt_types = split([[0,3.5,0.4,241|Df/_V_e
0, 2,  0.6,81|Uf,Df,Btyp,stmn,stmn_h_dmg,Iarm,Irss,slip,Etyp,in_grab,grabbed_e,col,outl,ray_iters/_V_Uply,_V_Dply,2,70,0,5,5.5,0.99,player,false,nil,12,9,6
0, 0.9,0.1,nil|Df,slip/_V_e,0.9
24,5,  0.25,64|rope,rX,rY,hz/1,0,16,t
24,5,  0.25,176|rope,rX,rY,gunid/1,0,16,9
24,5,  0.3,77|rope,rX,rY,rope_e,stmn,gunid/1,0,-45,len➡️50,90,2
0, 6,  0.175,180|Uf,Df,Btyp,stmn,Iarm,gunid,ai_p,ai_a,enemy,smok,flying,rngF,rngN,slip,f_c,dash/_V_Uenm,_V_Dntt,1,50,2,1,_V_AIPfly,_V_AIAfllw,true,1,true,36,22,0.9,3,0.5
24,12, 3,  198|Btyp,stmn,Iarm,Irss,gunid,ai_a,smok,rngN,rngF,spr_size,actN,actF,g_i,sprW,sprH,grav/4,170,2,2,6,_V_AIAfllw,4,40,55,16,55,2000,t,2,2,0.05
0, 3.3,0.2,186|Cdmg,grav,smok,stmn,bnce,dur/12,0,3,0,0.8,60
0, 2  ,0.4,83|Btyp,Df,dur,next_e,col/3,_V_Dply,40,14,6
0, 2,  0.1,240|Uf,item,amount,smok,ignS,g_i/_V_Uitm,5,25,2,true,true
0, 4,  30,  14|Etyp,smok,g_i/tmp tile,1,t
0, 9,  2,  244|Uf,nophys,grav,d_o/_V_Usgn,t,0,1
2, 2,  0.4,83|Uf,Btyp,dur,b_f,iDir,col,b4/_V_Uply,3,60,_V_d_load_next,_V_vec2_right,6,t
0, 4,  0.2,246|Uf,item,smok,ignS,f_c,f_l,g_i/_V_Uitm,4,2,true,3,6,true
0, 3.5, 0.02,241|coll_func,rspw/_V_Chook,true
24, 5,0.5,216|rope,rX,rY,gunid,ai_p,ai_a,stmn,hz,actN,actF,sprW/2,21,0,20,_V_AIPfly,_V_e,20,t,150,160,2
24,7.5,6,  177|Iarm,gunid,rngF,spr_size,hz,actN,actF,g_i/0.2,10,90,16,true,70,130,t
7, 14,  10,200|flying,actF,actN,rngF,rngN,gunid,Btyp,spr_size,sprW,f_c,melee/nil,2000,2000,10,0,27,7,24,2,1,t
0, 2,  0.4,187|Uf,smok,stmn,ignS,expl,grav,slip,f_c,f_l,dur/_V_Umsl,3,0.3,true,2,0,0.97,2,4,110
9, -9,0.45,228|Uf,Cdmg,b_f,expl,slip,stmn,Irss,smok,dur/_V_Umsl,nil,_V_Blzr,1,0.89,100,500,5,75
24,9,  3  ,200|Btyp,spr_size,ai_p,ai_a,actN,actF,rngN,rngF,gunid,stmn,smok,flying,Iarm,sprW/6,16,_V_AIPfly,_V_AIAhvr,110,2000,35,60,11,250,4,true,1,2
2 ,2,   0.4,83|Uf,Btyp,stmn,boss,ai_p,ai_a,gunid,col,rngF,rngN,actF,actN,jumping_d,next_e,enemy/_V_Uenm,3,200,t,_V_AIPstbl,_V_AIAfllw,22,6,100,60,500,500,20,10,f
0, 5,   0.5,64|Uf,Df,Btyp,stmn,Iarm,gunid,ai_p,ai_a,enemy,smok,is_left,sSt/_V_Uenm,_V_Dntt,1,60,2,1,_V_AIPstbl,_V_e,true,1,true,true
24,2,   1,233|Df,enemy,nophys,grav,gunid,actN,actF,hz/_V_e,nil,t,0,16,2048,2048,t
0 ,7,  20,183|spr_size,grav,Cdmg,kb,f_c,f_l,sprW,sprH,outl/16,0,5,1.5,3,2,1,1,15
0, 8.8,0.2,245|rope,rX,rY,bnce,spr_size,d_o/2,21,0,0.4,16,4
7, 8,  0.35,216|Btyp,gunid,rngN,rngF,actN,actF,stmn,ai_a,sprW,f_c,dash/6,14,20,55,70,170,70,_V_AIAhvr,2,1,0
24,7,  0.5,110|Btyp,stmn,gunid,ai_a,rngF,rngN,actF,Irss,flying,slip,sprW,sprH,Cdmg,kb,dash,jumping_d,j_cldwn,expl/8,140,18,_V_AIAfllw,5,5,170,4,t,0,2,2,11,1,0.1,40,45,1
24,4.5,0.25,118|Btyp,gunid,stmn,p_a/1,18,30,true
7, 8,  4,  180|spr_size,gunid,dash,Btyp,rngF,rngN,actF,stmn,expl/16,17,0,6,55,30,200,150,1
7, 7,  0.35,200|Btyp,gunid,stmn,sprW,f_c,rngN,dash,j_cldwn/7,19,55,2,1,30,0.8,40
24,3.5,0.22,82|Btyp,stmn,ai_a,gunid,col,outl,rngF,rngN,actF,actN,dash,b5,slip/3,85,_V_AIAfllw,25,15,15,60,30,250,60,0.8,true,0.99
0, 16,  1  ,nil|Df,nophys,grav,d_o,decal/_V_Ddcl,t,0,1,▒▒▒▒
9, 5,0.01,   0|Cdmg,kb,b_f,lzr_thck,smok,bnce,dur/10,0.4,_V_Blzr,4,3,0.1,6
24,6,  0.4,76|stmn,Irss,gunid,rope,rX,rY,dash/85,3,3,1,0,16,0.6
20, 2, 0.7,186|expl,slip,dur/1,0.985,50
24, 24,10, 200|sprW,sprH,spr_size/2,2,32]],"\n")



-- modifications for certain entities in level, no newlines to keep control chars (made in lvl editor)
ntt_extrainfos=split("/⬅️p_a/true⬅️next_e/11⬅️rX,rY/20,0⬅️rX,rY/-20,0⬅️rX,rY/0,-20⬅️rX,rY/-16,-16⬅️Btyp,permastick,rope,ai_a,rngN,rngF/5,true,nil,_V_AIAfllw,35,70⬅️gun/9⬅️boss/true⬅️rope,rX,rY/1,76,-20⬅️b_f/_V_d_load_next⬅️is_left/t⬅️is_up/t⬅️is_left,is_up/t,t⬅️rX,rY/-16,16⬅️txtB/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️-30⬇️44⬇️42⬇️2⬇️1⬅️rope,rX,rY,rope_e/1,-45,-8,len➡️50⬅️txtB/\faidk⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1⬅️txtB/\fastaff is advised\n to only \fcgrab the\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1⬅️decal/\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!\*f \*f \*f \*5 \^h\n🅾️\n\n\|c \-e+\n\n\|c\-f\^:10387c1010100010⬅️decal/\f2\^o0ff\^:00008064320f0204 \^h ❎\|e\n\ng\|fr\|fa\|fb  \|e\^:0000070c90a0c0f0⬅️decal/\f2\^o0ffk\|ee\|fep\n\n\|eg\|fo\|fi\|fng\^;10387c1010100010⬅️actF/600⬅️actF,rngF,rngN,ai_a/600,160,25,_V_AIAfllw⬅️gun/29","⬅️")


-- body info for complex/limbed entities
--[[
1: box (no limbs), air move ok - basic drone
2: humanoid
3: enemy humanoid
4: big walker
5: bipod spider
6: slow boss drone
7: fast drone
8: hunter fish
]]


-- TODO REDUCE/MOVE; REMAIN LIMB LIST
-- grnd_accel,air_a,g_max_spd,a_m_s,jump, leg_len,arm_len,stand_height, leg speed,leg group cd, max leg target rotation,
-- IMPORTANT: MAKE LEG_LEN SIGNIFICANTLY LOWER THAN ACTUAL LINK RANGE OTHERWISE CAN GET STUCK
-- limb info at 13+th array slot:
-- limb type (a/l arm or leg), angle, link array index, link extraprops
ntt_b_types = split([[0.15,0.15,3,3,2.6, 18,1,20, 3,3,0.01
0.8,0.21,2.07,1.05,2.1, 8.75,5,7.7, 3.2,2,0.2,l,0.015,4,len➡️8.8,a,0.02,3,➡️,l,-0.015,4,d_o`len➡️3`8.8,a,-0.02,3,d_o➡️3
0.3,0.21,2.07,1.05,2.1, 8,5,7.5, 3.2,2,0.2,l,0.015,4,col`len➡️3`8.7,a,0.02,3,col➡️6,l,-0.015,4,d_o`col`len➡️3`3`8.7,a,-0.02,3,d_o`col➡️3`6
0.2,0.05,1.2,1,0, 42,1,40, 10,3,0.10,l,0.03, 5,len`width➡️50`14,l,-0.03,5,len`width➡️50`14
0.10,0.05,1.5,1,2.4, 15,1,12,4,6,0.6,l,0,5,➡️,l,0.5, 5,➡️
0.13,0.13,1.5,1.5,0, 15,1,14, 3,3,0.01
0.18,0.18,4,4,3.1, 15,1,14, 3,3,0.01
0.15,0.15,1.25,1.25,3.7, 13,1,14, 4,6,0.2]],"\n")


-- NEW
-- cooldown,projectile entity,p speed,sfx(conv:x-128),angle(conv:(x-128)/128),
-- is global (high 1), burst amount (low 7),b delay, b angle shift(conv:(x-128)/128) 
-- next gun, proj prop mod index, ntt prop mod index
-- 11 VARS WOOOHOOO

-- mapspace 0 36

prop_mods = split([[/
rngF,rngN/90,45
rngF,rngN,hz/60,40,nil
rngF,rngN/45,25
rngF,rngN/1,0
rngF,rngN,b5/1,0,nil
rngF,rngN,dash,b5/120,60,0.5,t
rngF,rngN,jumping_d,b5/3,0,30,nil
rngF,rngN,dash,jumping_d,b5/90,80,0.9,10,t
rngN,rngF,jumping_d,b5/0,8,10,nil
rngN,rngF,jumping_d/15,20,10
Cdmg,rds,ghz,lzr_thck,b_f,dly_expl,dur/0,2,true,8,_V_DlEx,3,15
ghz,dur,lzr_thck/t,10,9
dur,ghz/2,t
enemy,stmn,next_e,dur,actF,actN/f,60,11,225,700,700
dur,ghz/170,t
enemy,stmn,dur/f,20,260
Cdmg,dur,lzr_thck,ghz/15,16,8,t
rspw,dur/nil,60
dur/55
dur,smok/2,nil
dur/0
enemy,rope,dur,gmelee,Irss,bnce/f,nil,100,t,40,0
dur,slip,b_f,lzr_thck/70,0.99,_V_Blzr,6
enemy,actF,actN,next_e/f,600,600,11
kb/0.7
rngF,rngN,hz/0,0,t]],"\n")

--[[
4096 + 4x128
1(0x0y):standard
2(0x1y):lvl2 laser sweep
3:lvl1 missle
4: 
5:
6,7,8: boss 1 sequence: x4 spread, x2 missle, laser sweeo)
9(11x0y):standard burst
10:grabbable missle
11,12,13:boss 2 sequence(x3 slow missles, x1 saucer, downward storm)
14:laser snipe
15:
16:big sawblade
17:drone spawner
18:empty gun
19:shotgun
20:static laser hazard
21,22,23,24: boss 3 sequence (laser, hook throw, dropkick + proj, projectile)
25,26: robot sequence (gun, melee)
27,28: boss 5 sequence (laser drone, missle rain)
29: more drone spawner
]]
-- cooldown,projectile entity,p speed*8,sfx(conv:x-128),
-- angle(conv:(x-128)/128), is global (high 1)+ burst amount (low 7),b delay, b angle shift(conv:(x-128)/128) 
-- next gun, proj prop mod index, ntt prop mod index


-- 1 standard machine holder
-- 2 mushroom stem
-- 3 playerlimb - arm 
-- 4 playerlimb - leg
-- 5 enemylimb - spiders, walkers etc
-- 
-- len, str, draw_type (DEPRECATED[0-none, 1-line] 2-joint,3-legjoint,4-noflip joint)
-- col, width, draw order (0-4, outside is none), outline color (0 is none)
-- map 56,36

-- 1-col, 2-radius, 3-sfx (0 if none), [ 4-decay rate ], [ 5-time ]
--[[
1 standard break,
2 hp pickup,  
3 projectile smoke, 
4 boss explode,
5 laser
]]
smokes=split([[13,3.5,16
12,3,-5
7, 2.5,0
7,8,-2,-4,7
15,3,14]],"\n")


-- radius, str*2, sfx
--[[ 
1 standard
2 bigger
3 small (dly laser)
]]
-- be VERY CAREFUL with the str val
-- map 44,23

-- end todo


-- player hurt noises, giga explosion, mini laser, throw, hp pickup
ex_sfx = split"\a63s2v2i6g#3<d4c4i0c4c#4g#3g#2,\a63s7v2i3x3f2fv7i6f<f<f<f<f<\*ffi2f0\*ff\*ff,\a63s5v1i2c2c1c0,\a63s2v3i6x3g2c>x0d#2i7f#3x1g1a#2f0d#d#,\a63s2i7v6d#0a#g#d#1g#c#g#g#2d#3g#3..<g#3..<g#3..<g#3"
-- all of these should overwrite empty slot 63 with \a63

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
454445450000000000000000000000009899999999999989bbabbaabaaaaaaaa8e999e8e9a5a959a545450553733333305445050aaaaaaaa0000000054999999
54544444000000000030000000000000899999999999999899999999a000000a88999e889454a49a550505057333373305045550a000000a0555555054499a99
54444454008880000036600000333000889999999999998899999999a0000a0a88999e884954a494405505553333333355055500a0000a0a05555554445999a9
444445440c8d8000003fff000067660058899999999999899aa999a9a000a00a88e9998895999994400500543939393905454505a000a00a5555555445494999
4444444400cdd000006660000036d60058999999999998899aa99999a00a000a88e998884549449a505505549393939305554555a00a000a5454545445494999
4445444400800000000000000030000089999999999999859999aa99a0a0000a8889988849a9594a455005508989898900454500a0a0000a4545454555454449
44445445000000000000000000000000899999999999999899a9aa99a000000a88e999889aa49a59505055008888088805454500a000000a5454445555455459
4544444400000000000000000000000099999999999999899999999aaaaaaaaa8ee99e889a44aa59550554050808008004454550aaaaaaaa0404040455555454
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
4242554042b3f38070e572107082d13070e3751042c444804245c54042037280619481a001c2f210e132d2c0e0f0114a4a420899084a4af7f718f7f7f7616250
50525a6942a0d94223c113716b72916b6b826bf9106b080848111111111111111111637a080872443425c69d6cc6b5c54446951c3c2c3c2c166464142cd41c8d
0101b6100143d5107044d51060c4f54042a40380b1c41540c1e25510c1f2f21002433320f0417210b141a2100101117a39200873084a4ae8e8e8e8e8e86171f3
7373f3694280d99b01fa213ad072636b8222826b7bda3333f960e4020260e402026099297208729de6b5257597d5c5c575979f163cd43cd4c46754243cd42c7d
21452310f042521001a673107064531050b2838060b6e210705b811042e9b1804208f280b1c1d350b1334601b0e011684b78080808084a020202020202f1f3d0
d8d0624379b831baba0a21818163638378826b5bfa58c26058707070707070707070637a0808729796c6251f25d514b5741cc43c2cccd43cd454243c1cd41c7d
b152d401c1522310c1c5e2100254d2109141c11091c3c11070c29510d1620810b0b2d310d0d2b3316253821008080842296060606018586f6f6f6f6f6f826a62
626a71d33178c383838383424263630808f2f2f2b1dadaf163636363636363636363997a8708726cb5b5547474b5ac8c676c645454445c54141414145c54145c
739041d808101008101010c39081d8c7308038901010e17002c808280ac8111110913204086af010a7a151a0000000000000000000000000811040d020200000
0236a281c1c67391e1055410c1c262910244728100000000000000000000000000000000080808087410282808ca080836102828050a080813102828050ae9d7
643286d7f82120f72010104641807808181008a01010ff1000080810100821611070320408834110689151b00000000000000000000000008100208020200000
d143151042d6b280d1b694400264a210d1a65510d1326510d1e4851042138580231028280b4918080000080808080808371038480a8a0808131058480a66daa7
a552607806101000301010054120780738c368c01010649081e897301038311010a5110508a6181008c17110000000000000000000000000500020c000209000
42f4838002d36310c146131060d6041002467410c1d3041060b2c31001419410201028280b49f708552018f80a0808083710e70a0a0c0808243038080866e917
14a0817808101008401010e67081d8b918a00cd0f0b1103206080a462008412110e1528008c890b07ab181100000000000000000000000005000307000209000
7172031050e2b34040f156606011243040b1f6600000000000000000000000000000000008080808811018080808080833102889bc0c0808243048880a4cda26
c33181f808181008501010233286d70a022008b0d030e10184c7f7101008613160e10201080848af08a09140000000000000000000000000310020d020200000
1282142002b67281707632819141e1109162e110000000000000000000000000100048880c280808811018080808e7083710288a086d08082410384808e8e908
649021d8b740702870a110b4510108081010a8e01010a05141080810100871417000000000000000000000000000000000000000000000000000000000000000
02846310f1b2151012b4a28112b425100133d41050b6d34012881310f1e8c210141038185ae80808801018280808b70830102809084b0808241058880829cb08
64528078172041b8801020ff31020806821038f0e010829081d80810100881108000000000000000000000000000000000000000000000000000000000000000
80c1c42080c3c42012d3d110f1615210f1235210000000000000000000000000120058888388080820102838082c080800000808080808080000080808080808
643286d7c9a020d760c030b4a181080a101008010110879081d8081010085110900000000000000000000000f153c2108046d11031d071a161976110c143b310
31d081101252a420f1a303103181f0a1000000000000000000000000000000000510588805870808000008080808080800000808080808080000080808080808
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
00222222010111111111111100000000000000000100000000000000101010101111111100000000000000000000000000000000000000000000000000000000
02222233101011111101011100333d000ff00ff00060106001000636000000001111111100000000000000000000000000000000000000000000000000000000
2222333311010101011010110373dd800f0000f00636000000000666101010102121212100f00000000000000000000000000000000000000000000000000000
222333230100001010110110033ddd800000000010000010100010000101010111111111000f0000000000000000000000000000000000000000000000000000
23322222001000000101000103ddd88000000000001000010010001010101010212121210000f000000000000000000000000000000000000000000000000000
3321212100000000001000000ddd88600f0000f00000606066366001010101011212121200000ff0000000000000000000000000000000000000000000000000
121211110000000000000000008886000ff00ff001066666006010061111111122222222000000ff000000000000000000000000000000000000000000000000
1121111100000000000000000000000000000000000013000100000001010101121212120000000f000000000000000000000000000000000000000000000000
000000003d0000d30033330000dddd00000000220337333000d3ddd00dd3700000ddd00000000000000000000000000000000000000000000000000000000000
00333c00d730033803733dd00dddddd02222225237333337033333ddd33777300ddddd0000000000000000000000000000000000000000000000000000000000
037cccc003dddd30373dddd8dfdddddf25a2aa203333333d0d333880dd7773d00088800000000000000000000000000000000000000000000000000000000000
03cccc8000d7c80033dddd88dd7dddfd02222220d333dddd033c33dd377cc3330ddddd0000000000000000000000000000000000000000000000000000000000
03cccc8000dcc80033dddd86ddd77fd802aa2a208d888888033c3388777cc33308dddd0000000000000000000000000000000000000000000000000000000000
0cccc88003d88d303dddd886ddd7dd8602222220080888800d333880d73333d00088800000000000000000000000000000000000000000000000000000000000
00c88800d33003380dd888600ddfd86002aaa2520008008003333388d333333008dddd0000000000000000000000000000000000000000000000000000000000
000000003800008300886600008f8600252222200000000000d388800dd330000088800000000000000000000000000000000000000000000000000000000000
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
000000cbcc00cdce0000000000d400000000d3c0c1c2c30071707173727371730000000000cbcc00001c00363600001c00e90000e9000000e7e7e7e7e7e7e7e7e5e6e6e5e6e6e5e600000000000000008f0f068e8f0007820288080c0d020a8e8a870c018300070081838b0e8d818903818c06008100070082020e0c0d028700
cfce00dbdc00dd36c4d5c5c4c510c4c5c0c1e0d1d0d1d0c36160417061616060d5e7cdcee7dbdce700361e363600001c0000e90000000000e8e8e8e8e8e8e8e8e5e5e6e5e5e5e5e500000000000000008f0f06808200078288088f0c0d880a8e0f070c858d0007008004090e0d82898f020e068082000782888e0f0c0d880a82
df36d5dbdccfdd361010101010101010d0d1d2131313d2d2604243414342426010e8dd36d4dbdce8001c0054361e1e360000000000e900e91212121212121212e5e6e5e5e6e5e6e600000000000000000d06868d0d0007008181018c8581098d8082068082000781858d0d0c0d820800888e068082000782880e0f0c0d880a02
df3607dbdcdfdd361010101010101010e1e1e2e1e1e2e2e166666766676767661012dd3610dbdc12001c00363600001c000000e9000000001212121212121212e5e5e6e5e6e5e6e500000000000000000607868d0d00078101018c0c8501090d89090688080007028280000c0d820a0880858680850007820d06060c8d0d0800
ccddddcc012020208a464746b8202020042727264746070641202020676667661b0a1b1b005c00015e0a5e0bdc08881c20a0a020020201022121212120202020717071719a9a9a9a60101010202020243636373e0000000014f676766667143677253636363614155b4a5b5b001c001c001c001c1e415e415e415e5e1f363636
988989982020212047012020b8032003143636154607060741410303767676760008005c005c001c1e088008dc08881c02070702e0e0e0012222222202020202617060709a9a9a9a601010102020202436373e010000000014f676767676143676f936f936f914158b8b8b8b001c001c001c001cc01cc01cc01cc0c03d1f3736
985455982120202046200210b8012001143636370707070727262627f6f676761e081e5c0b0a0b0b0b0a5e0b1e0a8a0102393902e0e0e0020202020203cf02ce60636160020202026010101074747424363e3d210000000014f676767676143776d914d936d914151e011e1e5b4a5b5b000100015e415e415e015e5e02105f37
985455984747474747201010b8202020253636360707070737363636f6f676760008005c0008001c00081c08dc08881c20a0a020e0e0e002ce02cfce2627262663626163a0a0a0a060101010757575243e2102200000000014f67676b9b9041576e925e925e93715001c00008b8b8b8b001c001cc01cc05cc0c0c0c03d1dbd5f
e0e0e0e002e0e00202020202101010102464652501d0d03c203d2002187655980223230200000000060706002b2b2b2b1ee1e0e1e0e1e178e0e0e0e0001c001c000000000000000000000000000000002020202020202020767676766a6a6a6a2103212036377677000000000000000035343434041d1d022f3f3f2f16161616
e0e0e0e020e0e0201ae0e01a2020202025646524222203a2aaaa2a2a18765598231d213d72723232060706002b2b2b2b30e0e0e1e1e0e178e0e0e0e0001c001c000000003100310000000000000000000202020202cecfcf76767676babababa62626262373976760000000000000000467676762523233d220c0c342e2e2e2e
e0e0e0e020e0e0201ae0e01a21202020256465251d1d11bdeaea2a2a18765598231d033d424242021b1b1b00212020211ee1e0e0e1e0e0781e011e1ee0e0e0e00031c32b30313031000031000000000002026626470706077676767602020202262726272001b9b941323232323232324676767624f5f5f434350c3439393939
e0e0e0e002e0e0020202020202cecfcf246564253b3b3b3b7a7a3a3a187655980202020261606060409c400003202120001c011c202121b800000000e0e0e0e032c3c32bb0a120303133b0b132323232222276367636063676767676101010103939393921102120161616560202cf0235aeae352f3f3f2f2f3f222f22222222
80808080803333af38808080181980bcbcbcbc93bc3306069c80bb8080808080808080189836363696128080808080b780333333a033333318198080808080980524808080248080808080802a182480808080808080803c3c803abb04bf1ebf3c3f3f3f3c3c1a1a1d1a3c1a1aac1a3636369936173607070707808312bbbbbb
1a1aac1d0635c7a0a080bbbb1819802712202734060606971d8037ae1d80809b80a01e18069e9d9e921280808080bb0080a0a0afafafa0a0181980808080803c3c3cbbbbbb248080808080809c18241d1d241d8f1d8f8f0b1c29b7bb9fbb80809f34b6b69f921e1d1e800b801cac1db69f3f3f3f3c9411111f3c808312b6b600
8080ad1b18191daeadbb18931837fb00122027111111b7972f2928a02f29298e29af2937249824b9961229292929b627801eaeaeaeaeae1e2933802b29332929040734068f37293230328029343406061d8c09bc87bc973c3c20200d9787a2a23497b6b6b6062c8080801a801ca01c2825b6b6b638389392b6a6298312b6b616
8080ad1d18199c809cb418340607972712200006060601978f8f0f3506060f8f8f8f35018e8e820d288e8f0685040707808080808080808007070786041b07060d3797363686260407862981b48505241d8a1a1ab99f978f250106069b9b9b9b3c3cb6b9061b853c1e8080801b1b1b3c3c3c3c3c3c3c3d853c3c070706350616
30801aa023239c809cb6019718a59727122027181818199704163690243636041818043686060635a60736363636142c2e2c2e2e8080808036363636991c173607070707363636363607070707073624bd1b06242486853c3c3c3c1a1a9a9a9a9a3d06851a1a1a8080808080808080fa6445c0c05272714d6c79d95a5a797676
068080ae18199a9a9a9a19971818b8001220271111b5b49707071736391799363636363c3c363636363636363636a11a3438db38001e1e37fbfbfb971896968080bbbb8080978080801c801c8080922020121c802480808080802e1f86b7bcbc25bcbc80808097bbbbbbbbbbbbbb716464457271524dc378806c6c7172505f76
1880808018199a9a9a9a19340618182712200001010fa517069f99144e2e2eb2200b7fb92020b7b79f02b7b7b7b78086802c2c0b27808087750d20271896b68080afaf8080b62980801c801c29bb20200f351b9b248080808080802e9f963f3f3f3c3cbbbbbb9747472e2e444747f86464455a6c52cc6c6c80dc6cf56e6ccf79
18b0803023811d1e1d1d19971825340012202718181818979997993402f01a08200b203820b80780808080bbbb87809f801a1d0b27808080192020271896962929230e292934b8a9291a801a8185040799121c801a80808080808080801a08872c1f99060687857676505064d97676446445c05b52ea9a9b5b9bdc7971505f47
379a9a9a37370d37193406a681189727122000250125a59724818187811a2e8b81818181351608808080800c2096802e80801b0b06808080254101971896844584474707458417248638b8380799163617043506388080808080808080808b1a1c803c92249224d979c1d164445879d964ea7279526adc6e5d805b50615ae857
07474707860f063506b8b83838250100122027181818199708f6f61af638c78bf61bf6a4051689060606060617bd060606068a3f19bb808018181997189696b6b6b6a0808087bb1abb803a8080bbbbbbbc333333b00fb33a3abb3a8080808b1aa18016a73aa30179c1745744f9614dc3e34646cf525071506a716141c25061d7
8080808080808080808080801b8a070780808080808080808bb9f6f6f69f968bf60bf6f69f36111111f61636808080808080808081876af0b7b7b7ad8e8e96a626b61133bbb7b62626bbb73037a1971c9f1d340c3f37b52525a6a58080808b1d1b8099a7b72036c2c1575879c374f86d78767676c6cf4146c4414145c64678c5
8080808080808080800606070b0b36368080801c1c1c80808bf6f6f6f6f6f68bf6f6f6f6f60b82a30d28173600000024a424929307a4b80707070735b8013d06a1b6b63c3c3d38bc069b9b9b3d26269b3c073c3c353c3c3f1a1a80808080801c80801a80372e2747fd5fd6c3c357d9c759808080808080321031507180808080
80aaba805a1d3c3cb89936360b0b36368080801dac1d8080891b09091b1b1b891b1b1b1b1b9911ad11f69736000000f0202d1220802012802bbb8004bb0496b6a18cb61f1616bf1a1a9a9a9a1a1a1a1ebf3c3f3f1a1a80808080850707070707079826a74080275759c678c2c2cf78f85680805a801aae2cce4dc1b972808080
80aa1a80ac1c983f363636360b0b36368080801c1c1c808080808080703333373c3c8080803f2222228f2525000000b7b436070736a4242b3783bb16811696b6b6adb6b69f80aa808080802412808312808080801819bb3abca49e9d9d06348a9e9d36a79f8027456e456a5c7172806a8080805d80801a2c41c34c742c806a80
802a1c1b1b853c3c363636360b0b3636093f3c3c3c3c3c3f71726a727f049d9e02258080800682410d16363680808024b406062597a42401b84f8f03821696356565a6b6978baa8080a2ac2412808312808080318117a1b797a50f25259786250fa536a737a29f6e805a6c5c6c6a5b5b5b715a5c8072711cd6c261975c717872
1b1b042a0b3f3f0b36363636363636360a1e8c1636368c1ec64144f80625a50f01368080803622a222160225808080921201252597929336363636122b163d06931794b6858b2a02bb80a0831229839702808096843634879736363636a43636363636a726a2978080716c5ac35d6e6c45c14d5071417450684141525b4150c1
000102000000010000010100010102010102020104050000050404040004050580808080803641a34117a436808080a4929f363636929302b7b7828c8c56b6a5250363b6271c0aa71b80a0981819868712a1bbb93636a2a23c3f3f3f3fa43f3f3f3f99e7af2e854580525b5d624180804547c6c545455747474747474745c646
048d250107ae220104ab2d040d6d23112224281505493008074d1e0106232510066623018025a3a8a325a525808080a7809714809f2da4b97fbd4ef6f6569637373737b6271c09a79632ae381818190407350605363686af9f11111111111111111136a778802748696d456a5a5a6a8045507172807271727172f38080727150
04332d0207242902044d280705742504224f2816076d38010b1c2701084c360a00000000803607450736363680808024a4a91280930393068fb7043d4e16963f373f07b69f8b0aa7342ca02c2b2719993636363636b7b7a0853838383838383838b836a71c80274543525ac3526c6c5c456447c15047f8c3c3f8467150c36464
051c3e050f0d2f01043f350207392003074320012465380822106e170d1533141232320307472b01125a32018080800220fc802693038236368c1607bd169626269302b6978b0a881a1aae018127193c3c3c3c3c14282ead97a54f25a54fa5254fa536a798a7366ac2526ccf525c5c5ccac476c3c37979524de379c2c34cd864
__sfx__
010900001802018020180701807118061180511804118031180211802118021180211801118011180011800109000100000e0001000000000000002b0502c0503005030031300212b01030020300103002130011
0013800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
010300000c57018570185701857018550185301852018520185100000018570185701855018540185301852018510185001850000000185701855018540185301852018510185101850000000000000000000000
0103001e0c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c12211122181220c10011100
49100020143261b3160f3201b326143101b3100f3201b3160fc701b4100f4261b4160f42011410124200d3200f3200f3101632016316163200f4200f32014420140111422014426144100f4101b3201232011320
631200001b4251b425194251b420366101e420336211b4200f420164203361619420386121a42036625366101b4251b325193251b426366101e420366161b4200f32016420366111942038610224203861538615
50010d00193600d360063500334001440014300363003620036200562009610076100161009600066000260000600066000660005600056000460000000000000000000000000000000000000000000000000000
020400003b6303b6313b6313963136631326312c621256211e62117621156211562115621166211762117611196111a6111b6111d6111f6112161123611246112561127615286152861529615296142961429614
5a021b00183730537301373016700566002660086500f6500165006645056450064004630086300663004630036300762006625056250162503620036200c6100261304613016150160500605086050060408604
0a0116001276016770197701b76022760257602875000000000002c6702c6702c6402c640000003b6703b6703b6403b6353b6303b6203b6203b62500000000001370017700187001c70000000000000000000000
51020600123430d623036210d32119321253352930402305003000030000300003000030000300003000030000300000000000000000000000000000000000000000000000000000000000000000000000000000
53011d00143710d371043610136100350366602535025370366703667036670366503665036650366503665036650366503665536655366453665536665366453663536625366203661036610366003660000000
49020c003c6200e3330c22337623296233662325034062202762008220366000322039605012003b6000420008200042000820008200082000820001200366000820036600366000000000000000000000000000
0a0120003e6303d6303d6203c6203b620396202d92026920229201f9201d9101a910189101591013910119100f9100d1100b11009110081100711006110040100401003010030110300103001030010300103001
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
79200020039100392003325033100cc6000c630f83003210039100392003325034120cc6200c631087006212049100b92004312032120dc6208c630f2120331004d500fc60063100fc600fc60123120631106311
792000000a1140a1210a1310a1210a125039160f9170f9140c1240c1310c1210c1200c12504d760cd7404d760b1100b1200b1200b1200b120110200b120120200d1200d1200d1220d12212917121201491414122
5910000020326273161b3202732620316273101b320273161e320273161b320273161b3100b3201e3101d3201b3251b3252232022316253200f3301b32120320200200f33020320203201b310273201e3201d320
591000001b3261e3161b3201e3261b310273101b3201b3101b326203101b32020326273101b3101b3201d3202932612320293261e320293261e320293261e3202a326143202a326203202a326203202a32620320
4b1000201d32324c0015313214133e6201d621153133e6101531324c102141324c10214130f3243c6250f322153231cd0039625213133e6101d621396253e6102131324c12214231532338620386243862538620
3d1000201203306720061250672012625067100612506125110330612506125067202561506710061250601012033067100612506710126250602506710061251203306125061250672025615067100663406125
891000201292506a240692506925156330692506915069250f733069150692506925156330691509925069100f7331212512a10069251563312a100692512a100f73306215069150621515633139150492504925
a540000006220062110622109222062200622106221092220622006211062210b2200622006221062210922006220062110622109222062200622106221092220222002211022210b22202220022210222109222
811000201e4201242012510120241241012325153201232006115061351742219422174121742219322193221e420123201211012020124261232715320123200611506135123251232215312123221942212322
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

