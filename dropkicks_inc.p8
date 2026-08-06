pico-8 cartridge // http://www.pico-8.com
version 43
__lua__



-- functions that will not be referenced using _ENV can be made local to save comp space
-- but ONLY if all their calls are below their definition i think
local function d_cam(a)
	for i=a,0,-0.12 do
		dc2()
		camy += i
		flip()
	end
end

function _init()
	cartdata("mk_0_dropkicks_inc")
	-- use extended map by default
	poke(0x5f56,0x80)

	-- EDITOR ONLY - keep pal changes when esc
	--poke(0x5f2e, 1)

	-- intro

	poke(0x5f5c, 255) -- no repeat btnp, also for gun
	
	--print("\^c0\n\^d1> initialising dropkicks inc.\asci0v2c0x1c#dd#eff#gg#aa#bc1 \n  job repositor\^d7y...\n\av3c2c3v2c3v1c3c3c3c3 \^d0  ready!\^6")
	ll_l(1)
	
	l_m()
	
	--init global vars
	-- camera x & y, anim counter, anim len, time counter
	mdtbl(_ENV,"camx,camy,ac,t_c/0,-320,0,0")
	
	ll_hi=dget(m_i)
	
	set_mus()
	
	d_cam(8)
	
end

local function rc() -- reset camera
	camera(camx,camy)
end

-- text box
function txtb(str,screen,x,y,boxlen_x,boxlen_y,boxc1,boxc2,t,rel,dx,dy)
	
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
		dt(t,dt2,{},true)
	else
		dt2()
	end
	
end


function _u_menu()

	-- drawing
	dc2()
		
	if l_lock then
		txtb(unstr("???\n\ncomplete previous\ntask to unlock,true,10,8,80,32,8,9"))
	else
		
		txtb(unstr(m_title.."\n\nbest rating:"..ll_hi.."%,true,10,8,73,27,8,9"))
		
		if t_c > 0.5 then
			local t_col = "\f7"
			if (vinfo) t_col = "\fe"
			txtb(unstr("\^o80b<\*f \*d >\*9\n🅾️/c:begin			 "..t_col.."❎/x:info,true,5,64,56,28"))
			
			if vinfo then
				txtb(unpack(split(split("from: hq\n\nsome construction company's\nbots went haywire -\nthey're hoping we could\n'clean' up the situation\nbefore the public notices\nand it turns into a mess\nof paperwork.\nPERFECT OPPORTUNITY FOR \nYOUR 'SKILLS' :]`from: hq\n \nan automated cargo transport\ngot hacked and they need\na fast intervention.\npretty rare to get rogues\ntwice in a week, but it pays\nwell so i can't complain\nlol`from: hq\n\nremember that corpo bounty\nto locate the hacker?\nthink i've got something.\ni'd give them the place\nright away... if it weren't\nan ex-crewmember's outpost.\nthey cut off comms a while\nago, can you check it out?`from: unknown\n\nrude to barge in like that\nmaybe investigate those robo\ncorp scum first dummies\nthey got some bad plans\n\nhere if you need proof\ntry to exit discreetly\n\n[hideout_coords.txt]`from:hq\n\n...again, i've checked and\nit's all technically legal.\ni know it sucks, but we\ncan't do anything here\n(apart from something\nreally dumb and reckless\nlike raiding their storages)`from:hq\n\nyou're on like 10 news\nchannels?? ...i think i'll\nget in trouble if i don't\nfire you. though, tomorrow\nis their deployment day - i\ncould arrange a ship that\nconveniently passes by the\ncomms towers at 8:00 if\nyou want to finish this","`")[m_i+1].."⬆️true⬆️10⬆️36⬆️120⬆️76⬆️8⬆️9","⬆️")))
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
		
		m_i %= 6
		
		l_lock=m_i>0 and dget(m_i-1)<=0
		
		scrw(xdir,8,
			function() 
				ll_l(st_l[m_i+1])
				
				ll_mus,m_lyrs=0,15
				umus()
				
				if (l_lock) pal(split"1,1,1,129,129,0,7,129,129,129,129,129,129,129,129,1",1)
			end
		)

	end

	if btnp(4) and not l_lock then
	
		scrw(24,9,
			function()
				camera()
				print("\f7\^o80b\^j22"..m_title.."\n\^5\^j05\#a\^x5\^o8ff\^d1"..ll_title.."\^x4\^o80b\#9\^j25\n\^5\^d1\n  "..split("always a good day when\n  our service matches our name`you did bring a parachute,\n  right?`tip:grab walls to slow\n  down your fall`don't worry,\n  curiosity only harms cats`by myself, because someone\n  got to`good luck.","`")[m_i+1])
				--pal(7,6,1),pal(7,13,1)&pal(7,5,1) with pauses inbetween. the 13 is 1d as 0d is newline
				print("\^6\^@5f170001⁶\^3\^@5f170001。\^3\^@5f170001⁵\^3")
				--end
				cls(9)
				b_l(false)
			end
		)
		
	end
	
	if (btnp(5)) vinfo = not vinfo
	utimers()
end


function scrw(spd,col,midfunction,m_args)
	
	dt(0,function() -- delay until frame end to not mess with other calculations
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

	_update=_u_lvl
	cltm()

	if (cont) ll_pmus = ll_mus or 0
	
	ll_l(ll_i)
	
	if cont then
		if retry then
			--idk
		else
			
			-- can exchange for compressed space, remove check, move box to left and add "    " to all titled level names
			if (ll_title != "") then
				dt(1,txtb,{"\#6 "..ll_title.."\^-#\f6\|f\^:7f3f1f0f07030100","true", unstr"0,8,0,0,0,0,84,20,-8,0"})
			end

		end
		
	else
		mdtbl(_ENV,"t_c,t_enms,t_e_c,t_tr_c,t_tr,ll_pmus/0,0,0,0,0,0,0")
	end
	
	-- lvl var defaults
	mdtbl(_ENV,"ac,lvl_enms,lvl_e_c,e_rq,llx,lly,grav,lvl_tr_c,lvl_trinkets,sl_l,sl_c,sl_smth,sl_vx,sl_vy,sl_dmg,alert,l_t_c,sl_r,sl_h,sl_spd/1,0,0,0,0,0,0.217,0,0,1024,6,0.982,0,-0.2,0,false,0,0,0.04,5")
	lhx,lhy=l_border_x,l_border_y
	
	-- lvl extra globals and defaults
	mdtbl(_ENV,xtra_v)
	
	sl_vec = v2n(sl_vx,sl_vy)
	
	umus()
	if (ll_mus != ll_pmus)	st_mus()

	menuitem(2 | 0x300, "retry area",ll_r)
	menuitem(3 | 0x300, "exit level",ll_e)

	-- init entities, clear all
	ntts,links={},{}
	ply = spe(pl_x,pl_y,2)

	add(ntts,ply)

	for i=1, ll_ntt_num do
		sp_lvl_e(i)
	end
	
	
	camx,camy,p_c_spd=ply.pos.x-64,ply.pos.y-64,-v20
	lcam()
end

function _lnxt() -- can inline if need
	ll_i=ll_next
	b_l(true)
end

function lnxt()
	t_enms+=lvl_enms
	t_e_c+=lvl_e_c
	
	t_tr+=lvl_trinkets
	t_tr_c+=lvl_tr_c

	if ll_next >= 0 then
		scrw(24,8,_lnxt)
	else
	
		local ll_scr = t_e_c/t_enms*75
		if t_tr > 0 then 
			ll_scr += t_tr_c/t_tr*25
		else
			ll_scr /= 0.75 
		end
		ll_scr\=1
		if(ll_scr > dget(m_i)) dset(m_i,ll_scr)
		ll_mus=-1
		st_mus()

		menuitem(2)
		menuitem(3)
		
		camera()
		print("\f7\n\n\^w\^t\^o8ff\^2\^d1 \as8....a#0.a#0.d#2d#..a#1a#d#2d# \^2"..m_title.."\n\^d0       \^4\^3complete!\n\n\n\^-w\^-t\^6◆ \as9x5d#2d#3 "..t_e_c.."/"..t_enms.." machines 'disassembled'\n\n\^5\^4◆ \as9x5d#2d#3 "..t_tr_c.."/"..t_tr.." trinkets collected\n\n\^5\^4   \as9x5d#2d#3 time: " .. t_c .. " s\n\n\^5\^4\*3 rating: \^5\as9x5d#2d#3x6<<d#2<d#3<d#2<d#3<d#2<d#3 " .. ll_scr .. "%\^4" .. (ll_scr>=100 and " perfect!" or "") .. "\n\n\n\*a 🅾️ to continue",0,0)
		if (ll_scr >= 100) spr(unstr"178,100,80,2,1")

		while not btn(4) do
			flip()
		end
		

		ll_e()

	end
end


function d_ld()
	dt(52,lnxt)
end

-- load menu
function l_m()
	mdtbl(_ENV,"camx,camy,timers,timer_q,ll_mus,m_lyrs/0,-32,{},{},0,15")
	cltm()
	menuitem(2)
	menuitem(3)
	umus()
	st_mus()
	_update=_u_menu
end

function ll_e()
	if ll_i == 37 then
		memset(0x8000, 0, 0x4000)
		bg1_loc,bg2_loc,camx,camy,ll_mus,m_lyrs=unstr"30,31,0,-210,6,14"
		d_cam(9.7)
		umus()
		st_mus()
		
		camera()
		print("\f7\^o8ff\^d1\^w\^tgame complete!\^-w\^-t\^4\n\ntoday,\^4 a disaster was\navoided\^3 (with some minor\nproperty damages)\^4 all\nthanks to you!\^7\n\n...you should get\nback on the ship and\nleave the country for\na while,\^4 pretty sure\nthose still count\nas crime\^d0\^6\n\n\^6thanks for playing!\n\n\^6    🅾️ to exit",6,6)
		while not btn(4) do
			flip()
		end
	end

	scrw(24,12, 
		function()
			ll_l(st_l[m_i+1]) 
			l_m()
		end
	)
end

function sp_lvl_e(i)
	local Etyp,ex,ey,e_extra = peek(lvl_nttloc+i*4-4,4)
	ex,ey,e_extra = ex*4-32,ey*4-128,ntt_extras[e_extra]
	local e=spe(ex,ey,Etyp,nil,e_extra)
	e.lvl_i = i
	add(ntts,e)
end


function dt(ticks, func, args,continuous)
	local timer = {t=ticks,f=func,a=args or {},cont=continuous}
	add(timers, timer)
end

-- clears all indexable items in table without re-initializing the reference
function cltbl(tbl)
	for i=1, #tbl do
		deli(tbl,1)
	end
end

function cltm()
	cltbl(timers)
	cltbl(timer_q)
end

function utimers()
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

function _u_lvl()

	t_c+=0.0333
	l_t_c+=0.0333
	ac+=1
	ac%=2048
	if ac%8==0 then
		alert=false
		umus()
	end
	
	sl_l += sl_r + sin(l_t_c/sl_spd)*sl_h
	
	for ntt in all(ntts) do

		for subntt in all(ntt.all_ntts) do
			
			
			-- move entity
			if not subntt.nophys then
			
				subntt.pos += subntt.vel


				-- clip out
				local did_c,with_t,out,surface_dir,coll_e = unclip(subntt)
				if did_c and out then
					subntt.pos += surface_dir
				end


				if did_c then

					if out then
						impact(subntt, with_t, surface_dir, coll_e)
						subntt.collr=0
					else
						if with_t then
							subntt.collr += 6
						else
							subntt.pos += v2nrm(subntt.pos - coll_e.pos)
						end
					end
				else
					subntt.collr=0
				end
				

				-- update stand
				subntt.stnd=false
				local down_pos = subntt.pos+v2d
				-- if 1st is true 2nd does not evaluate so no much lag
				if colltrn(down_pos, subntt.rds) or collntt(subntt, down_pos) then
					subntt.stnd=true
				end

				
				-- rope
				if flnk(subntt, subntt.rope_ntt) then
					subntt.pos = subntt.pos*0.95 + (subntt.rope_ntt.pos - v2n(subntt.rX,subntt.rY))*0.05
					funcaf(subntt)
				end
				
				--fall
				if not subntt.sst then

					if subntt.stnd then
						subntt.vel.y *= 0.95
						subntt.vel.x *= 0.6 + max(subntt.slip, 0.75)*0.4 -- friction
					else
						subntt.vel.y += subntt.grav
					end
				end
			
			end

			
			
			
			-- call its update function
			if (subntt.Uf) subntt.Uf(subntt)

				-- settle tile entities
			if subntt.tile and subntt.stnd
			and #subntt.vel < 0.04 and not subntt.grabbed then
					-- convert entity to tile
					mset(subntt.pos.x\8, subntt.pos.y\8, subntt.sprite)
					rme(subntt,true)
			end
			subntt.grabbed=nil
			
			if subntt.stmn and subntt.stmn < 0 then
				rme(subntt)
			end

			-- test borders
			if subntt.pos.x < llx-16 then
				subntt.vel.x /= 2
				subntt.pos.x += 1
			elseif subntt.pos.x > lhx+16 then
				subntt.vel.x /= 2
				subntt.pos.x -= 1
			end

			
		end
		
		if ntt.pos.y > lhy+80 then
			rme(ntt,false,true)
		end

		if ntt.pos.y > sl_l then
			if (#ntt.vel > 3.8) particles(ntt.pos, split"14,5,0,0.3,9")
			ntt.vel = (ntt.vel + sl_vec) * sl_smth
			lstmn(ntt, sl_dmg)
		end
	
		for name, timer in pairs(ntt.ts) do
			ntt.ts[name] = max(0, timer-1)
		end
	end

	--check links
	foreach(links, tug)


	if ply.pos.x > lhx+12 and btn(1) and ll_next > -2 and lvl_e_c >= e_rq then
		lnxt()
	end
	
	-- camera tracking
	local t_p=ply.pos+ply.vel*20
	t_p.x += tnmf(not ply.left)*8
	t_p.y += ply.idir.y*18

	local distance = v2n(
		t_p.x-camx-64,
		t_p.y-camy-64
	)
	local speed=p_c_spd*0.85 + distance/20*0.15

	camx+=(speed.x+0.5)\1
	camy+=(speed.y+0.5)\1

	p_c_spd = speed --prev
	lcam()
	
	
	
	
	-- draw level
	dc()
	map(unstr"0,0,0,0,128,64,8")
	if ll_next > -2 then
	
		local c = 12
		if lvl_e_c < e_rq then
			c = 3
			txtb("\^o95a"..lvl_e_c.."/"..e_rq,false,lhx-14,ply.pos.y)
		end
		
		local function l(o_x)
			line(lhx-o_x,lly,lhx-o_x,l_border_y,c) -- use default y limits here only for upper
		end

		l(0)
		l(1)
		l(flr(l_t_c*8)%8)
		
	end
	
	local drawables = {}
	
	for ntt in all(ntts) do
		for subntt in all(ntt.all_ntts) do
			add(drawables,subntt)
		end
	end
	
	for link in all(links) do
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
						camera(camx+x,camy+y)
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
	poke(0x5f5e, 119)
	rectfill(-256,sl_l,2048,1024,sl_c)
	poke(0x5f5e, 255)
	
	
	-- ui
	
	camera()

	fillp(0b10111010.1)
	rectfill(unstr"3,2,75,8,8")
	fillp(0)
	
	rectfill(3,1,75-ply.stmnh,8,8)
	rectfill(4,6,ply.mgntc+4,7,3)
	rectfill(4+ply.stmn,2,ply.ts.hurt/2+4+ply.stmn,4,7)
	rectfill(4,2,ply.stmn+4,4,12)
	
	rc()
	
	
	
	
	
	utimers()
end

function lcam()
	camx,camy=mid(llx,camx,lhx-127),mid(lly,camy,lhy-127)
end


function dc()
	cls(lvl_clearcol)
	
	draw_bg(bg1_loc)
	draw_bg(bg2_loc)
	
	rc()
end

function dc2()
	dc()
	map()
end



-->8
-- token savers

function unstr(str)
	return unpack(split(str))
end

-- thank you Lokistriker whoever you may be
-- modifies/appends to table. can target _ENV to change globals

-- note when doing implicit nils the value size shouldnt be 0 as the first elem is "" instead
function mdtbl(tab, kv, splitter, delim)
	local k,v = unpack(split(kv, splitter or "/"))
	k,v = split(k,delim),split(v,delim)
	for i=1,#k do
		tab[k[i]]=_p(v[i])
	end
	return tab
end

-- mod tabl but v can be variables
function amdtbl(tab, k,v)
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


local function bcheck(v,b)
	return (v or 0) & b != 0
end

function tnmf(b)
	return tonum(b or false)*2-1
end

-->8
-- entity managment

function flnk(e1,e2)
	for link in all(links) do
		if ((link.from == e1 and link.to == e2) or (link.from == e2 and link.to == e1)) return link
	end
end

function timerr(e,n)
	return e.ts[n] <= 0
end


function spe(x,y,type,prt,extraprops)
	local entity = amdtbl({},"pos,vel",{v2n(x, y),-v20})
	
	-- defaults
	mdtbl(entity,"ts,bnce,slip,grav,Uf,Df,collr,actN,actF,rngn,rngf,iarm,irss,spr_size,d_o,outl,mgntc,lzr_thck,dash,jumping_d,ray_iters,j_cldwn/{},0.2,0.75,_V_grav,_V_e,_V_Dntt,0,55,100,0,35,0,1,8,3,0,70,10,0,0,3,8")
	amdtbl(entity,"X,rds,mass,sprite",{peek(7676+type*4,4)})
	entity.rds/=10
	entity.mass/=20
	-- only primary entities can have timers(ts) - non-custom ones, anyway -- why...
	-- type (template) removed - maybe re-add if needed
	amdtbl(entity,"idir,all_ntts",{-v20,{entity}})


	-- inherit props from another ntt
	if (entity.X != 0) mdtbl(entity,ntt_types[entity.X])
	
	-- props
	mdtbl(entity,ntt_types[type])
	
	if (extraprops) mdtbl(entity,extraprops)
	mdtbl(entity.ts,"hurt,htsc,jmp_cl,gun/0,0,0,0")

	-- applying table indexes
	amdtbl(entity,"smok",{split(smokes[entity.smok])})
	if (entity.gi) gg(entity)
	
	if prt then
		entity.prt=prt
		entity.pos+=prt.pos
		entity.vel+=prt.vel
	end

	entity.stmn_l_t = entity.stmn

	if (entity.enemy == true) lvl_enms+=1 -- == true is needed here

	if entity.item==2 then
		lvl_trinkets+=1
	end

	if entity.Btyp then

		-- init complex
		local b_info = split(ntt_b_types[entity.Btyp])
		entity.props = b_info
		-- todo merge?
		--more defaults,subentity mappings for limbs & cooldown for leg movement
		mdtbl(entity,"g_mode,gr_e,lgfc,fcng,snrm,rdir,legs,arms,leg_cd/false,nil,_V_v2d,_V_v2u,_V_v2u,_V_v2u,{},{},0")
		
		amdtbl(entity,"g_acc,a_acc,g_max,a_max,jump_str,leg_len,arm_len,stnd_h,l_spd,l_cld,l_a_r",b_info)

		for i=12, #b_info, 4 do
			local l_typ,angle,l_i,l_ex = unpack(b_info,i)
			local l_e = spe(0,0,3,entity)
			amdtbl(l_e,"t_pos,angle,t_ac",{l_e.pos,angle--[[,nil]]})

			add(entity.all_ntts, l_e)

			if l_typ=="l" then
				add(entity.legs, l_e)
			else
				add(entity.arms, l_e)
			end
			-- is 4641 but 1 indexing, could use refactoring
			mklnk(entity,l_e,{peek(4513 + l_i*128,7)}, l_ex)
		end
	
	end

	if entity.rope then
		entity.rope_ntt = tmptrne(entity.pos + v2n(entity.rX,entity.rY))
		mklnk(entity, entity.rope_ntt, {peek(4513 + entity.rope*128,7)}, entity.rope_e)
	end
	
	if (entity.dur) dt(entity.dur,rme,{entity})
	
	return entity
end

function Citm(i, ntt)
	if ntt == ply then

		if i.item == 1 then
			ply.stmnh,ply.stmn=max(0,ply.stmnh-i.amount),min(ply.stmn+i.amount,70)
		elseif i.item == 2 then
			lvl_tr_c+=1
		else
			ply.gi = 4
		end
		
		txtb("\^ocff"..i.txt,0,i.pos.x,i.pos.y,unstr"0,0,0,0,45")
		rme(i)
	end
end

function ll_r()
	scrw(-24,8,b_l,{true,true})
end

function rme(ntt, noeffect, oob)
	if ntt == ply then
		ll_r()
		return
	end

 for subntt in all(ntt.all_ntts) do

		for link in all(links) do
			if (link.from == subntt or link.to == subntt) delete_link(link)
		end
	end

	local is_present=del(ntts, ntt)

	if ntt.prt then
		is_present=is_present or del(ntt.prt.all_ntts, ntt) and in_tbl(ntt.prt, ntts)
	end

	if not noeffect and is_present then

		if ntt.enemy == true then
			lvl_e_c+=1
			local txt="\^oc09"..lvl_e_c.."/"..lvl_enms
			if (lvl_e_c >= lvl_enms)txt="\^oc09area clear!"

			txtb(txt,0,ply.pos.x,ply.pos.y,unstr"0,0,0,0,50")
		end
		
		local pos = ntt.pos
		
		if (ntt.expl) expl(ntt.pos, ntt.expl)
		
		if (ntt.rspw) sp_lvl_e(ntt.lvl_i)
		if (ntt.next_e) add(ntts,spe(ntt.pos.x,ntt.pos.y,ntt.next_e))
		
		if ntt.boss then
			ll_mus=-1
			st_mus()
		end
	
		if (ntt.smok and not oob) particles(pos,ntt.smok,ntt.vel)
		if (ntt.b_f) ntt.b_f(ntt)

	end
end

function mklnk(e1,e2,link_props,extraprops)
	local link=amdtbl(
	{},"from,to,len,str,d_t,col,width,d_o,outl",
	{e1,e2,unpack(link_props)})
	mdtbl(link,extraprops or "➡️", "➡️","`")
	link.true_len,link.Df=link.len,Dlnk
	add(links, link)
	return link
end

function delete_link(l)
	del(links,l)
end

-->8
-- drawing

function draw_bg(index)
	local lvl_bg,bg_sampl = {peek(4704 + index%8*128+index\8*8,8)},{}
	
	for i=3,8 do
		lvl_bg[i] = lvl_bg[i]-128
	end
	
	amdtbl(_ENV,"b_ip,b_wxy,b_sc,b_prlx,b_ofx,b_ofy,b_timx,b_timy",lvl_bg)
	
	for i=0, 15 do
		add(bg_sampl, @(7936 + b_ip\16*4 + i%4))
	end
	if (ll_i != 37) pal(bg_sampl)

	local p_sc = b_sc*8
	
	local a_p_sc,scroll_x,scroll_y = abs(p_sc),-b_ofx+camx*b_prlx/64+t_c*b_timx, -b_ofy+camy*b_prlx/64+t_c*b_timy

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
	local pos,flip_x,flip_y,e_spr,s_x,s_y = pos or entity.pos,flip_x or entity.left, flip_y,entity.sprite,entity.sprW or 1,entity.sprH or 1
	if e_spr then
		local spr_sw,spr_sh = s_x*entity.spr_size, s_y*entity.spr_size
		e_spr += ((ac\(entity.f_l or 2))%(entity.f_c or 1))--*s_x
		
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

	local p1,p2,left,t_l,l_c,l_c2,t_w= from.pos,to.pos,from.left, len/2, col, from.col,width

	if is_outl then
		t_w += 4
		l_c,l_c2 = outl, outl
	end
	
	if d_t == 3 then
	
		local pos_2 = p1 + envstr.v2nrm(-from.fcng)*3
		envstr.lvc(p1, pos_2, l_c2, t_w)
		
		p1,left,t_l = pos_2, not left, (true_len - 3)/2
		
	elseif d_t == 4 then
		left = false
	end
	

	
	-- draw_joint
	if p1 != p2 then

		-- circl intersect
		local d,mid_p = #(p2-p1),(p1+p2)/2
		local op = (p2-p1)*envstr.sqrt(t_l*t_l-d*d/4)/d
		local op2 = envstr.v2n(op.y,-op.x)
		local k_2, k = mid_p+op2, mid_p-op2

		
		if (left) k=k_2
		envstr.lvc(p1,k,l_c,t_w)
		envstr.lvc(k,p2,l_c,t_w)
	end
	
end


function lvc(v1,v2,col,thickness)
	for i=0, thickness or 0 do
		local vec = ({v2r,v2d,v2l,v2u})[i%4+1]*((i+3)\4)
		local v1_1,v2_1=v1+vec,v2+vec
		line(v1_1.x,v1_1.y,v2_1.x,v2_1.y,col)
	end
end



function Dply(ntt)

	--head
	local head_sprite_pos,flip_r,flip_u=ntt.pos+ntt.fcng*2,ntt.left

	if ntt.fcng.y > 0.7 then
		flip_u,flip_r = true,not flip_r
	end


	if (not flip_r) head_sprite_pos.x += 1
	Dntt(ntt, head_sprite_pos, flip_r,flip_u)

	--eyes
	local e_pos_x,e_pos_y,p_expr = head_sprite_pos.x-4, head_sprite_pos.y-4,"0000002800000000"
	if (flip_r) e_pos_x-=1
	
	
	if not timerr(ntt, "htsc") then
		p_expr = "0000442844000000"
	elseif #ntt.vel > 4 then
		p_expr = "0000002828000000"
	elseif ntt.idir.y > 0.5 then
		e_pos_y += 1
	end

	if ntt == ply and ac%(55) < 52 then
		print("\f7\^:"..p_expr, e_pos_x,e_pos_y)
	end
	

end


-->8
-- sounds

function umus()

	for i=0, 63 do
		--0x3100 is start, 0x3101 means target 2nd channel
		for j=0,3 do

			local addr = (0x3100+j + i*4)
			local fl = @addr
			if bcheck(m_lyrs, 1<<j) and fl&63 != 63 then
				fl &= 191
			else
				fl |= 64 -- disable channel
			end

			poke(addr,fl)
		end

	end
	
	--[[
	if ply and ply.pos.y > sl_l then
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
	st_mus()
	menuitem(5,s,set_mus)
	return true
end

function st_mus()
	if mus_e then
		music(ll_mus)
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
function v2n(vx,vy)
	a={x=vx, y=vy}
	setmetatable(a,vec2)
	return a
end

vec2={
	--add/sub 2 vectors
	__add=function(a,b)return v2n(a.x+b.x,a.y+b.y)end,
	__unm=function(a,b)return v2n(-a.x,-a.y)end,
	__sub=function(a,b)return a+(-b)end,
	--mul/div vector by a scalar
	__mul=function(a,s)return v2n(a.x*s,a.y*s)end,
	__div=function(a,s)return a*(1/s)end,
	__idiv=function(a,s)return v2n(a.x\s,a.y\s)end,
	__eq=function(a,b)return a.x==b.x and a.y==b.y end,
	
	__len=function(v)
		-- alternate way of getting hypotenuse by trigonometry
		-- avoids squaring, more accurate in almost all cases
		-- and does not break at very small or big values
		local v2, v2_c = v+v20, v.x
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
v20,v2r,v2d=v2n(0,0),v2n(1,0),v2n(0,1)
v2l,v2u=-v2r,-v2d
-- to copy, either do +v20, *1 or -negative (if available)

function v2nrm(v)
	if (#v == 0) return v
	return v/#v
end

function v2lmt(v)
	if (#v > 1) return v2nrm(v)
	return v
end

function v2dot(v1,v2)
	return v1.x*v2.x+v1.y*v2.y
end


function v2rot(v,a)
	return v2n(v.x*cos(a) + v.y*sin(a), -v.x*sin(a) + v.y*cos(a))
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
function rcmul(v,s,m1,m2)
	-- projection
	-- if s is 0,
	-- (0/0) is is max num
	-- * 0 is 0
	local vc = s*(v2dot(v,s)/v2dot(s,s))

	local v1,v2 = vc*m1, (v-vc)*m2
	return v1+v2,v1,v2
end

-- used in collisions and link pulling/pushing
function tmmtm(e1, e2, bnc, slipperiness, square_coll)
	-- normalized bc when offscreen with high diff it freaks out
	local diff = v2nrm(e2.pos-e1.pos)

	if square_coll then
		if abs(diff.x) > abs(diff.y) then
			diff.y=0
		else
			diff.x=0
		end
	end

	local e1m,e2m=e1.mass,e2.mass
	local total_m = e1m+e2m

	tmp, v1_c, e1.vel = rcmul(e1.vel, diff, 1, slipperiness)
	tmp, v2_c, e2.vel = rcmul(e2.vel, diff, 1, slipperiness)

	if diff.x == 0 then
		if diff.y > 0 and e2.stnd then
			e1.vel += -v1_c*bnc
			return
		elseif diff.y < 0 and e1.stnd then
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
			s_normal = v2l *sgn(p2.x - p1.x)
			dist = r1+r2 -abs(p2.x-p1.x)
		else
			s_normal = v2u *sgn(p2.y - p1.y)
			dist = r1+r2 -abs(p2.y-p1.y)
		end

		return true, s_normal, dist
	end

	return false

end


function colltrn(point, rds)
	local p_in = point+v20
	--extend terrain offscreen
	p_in.x = mid(llx,p_in.x,lhx)
	p_in.y = mid(lly,p_in.y,lhy)

	local point_max,point_min = p_in+v2n(rds,rds),p_in-v2n(rds,rds)

 	-- go over all tiles in rectangle range
	for j=point_min.y\8,point_max.y\8 do
		for i=point_min.x\8,point_max.x\8 do

			if fget(mget(i,j),0) then -- solid tile
				local p2 = v2n(i*8+4,j*8+4)
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
	
	for other in all(ntts) do
		if not (
			other.nophys or 
			in_tbl(other, {ntt,ntt.prt,ntt.grbe}) or 
			(ntt.prt and other.ignS) or ntt == other.grbe or 
			(ntt.prt and other == ntt.prt.grbe) or
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


function t2ntt(tmp_ntt)
	--printh("converted a tile to entity")
	local tpx,tpy = tmp_ntt.pos.x\8, tmp_ntt.pos.y\8
	mdtbl(tmp_ntt,"stmn,stmn_l_t,rds,iarm,irss,bnce,mass,tmp_tile,dmg,g_i/50,50,3.99,5,3,0.25,0.13")--nil,nil,nil
	tmp_ntt.sprite=tmp_ntt.tile
	if (fget(tmp_ntt.tile,5)) tmp_ntt.expl,tmp_ntt.stmn = 2,11.5

	-- fill bg: insert adjacent < or ^ bg tile
	local t_l,t_u,t_set = mget(tpx-1, tpy),mget(tpx, tpy-1), 0
	if (fget(t_u,0)) t_set = 2
	if (fget(t_u,3)) t_set = t_u
	if (fget(t_l,3)) t_set = t_l
	mset(tpx, tpy, t_set)


	add(ntts, tmp_ntt)
	return tmp_ntt
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
				local s_v = (up_override and v2u or norm_t)*8 -- start from most likely exit point (or up), then spin
				if (j > 3) s_v = v2rot(s_v, 0.125)
				local m_v = v2rot(s_v,j/4)*(i+entity.collr)


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
					return true, true, true, m_v, tmptrne(t_pos) -- out now - ignore entities
				end

			end

		end
		return true, true, false, v20, tmptrne(t_pos)
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


function expl(pos, e_prop_i) -- is 8064 but 1-indexed
	local radius, str, sf = peek(8061 + e_prop_i*3,3)


	local function get_expl_ntt(other)
		local dist = other.pos - pos
		-- no damage falloff! simpler and removes some jank from game
		expl_ntt = amdtbl({},"pos,vel",{pos,v2nrm(dist)*str/2 + other.vel})
		return mdtbl(expl_ntt, "mass,iarm,irss/1,0,1")
	end

	for ntt in all(ntts) do
		if (#(ntt.pos-pos) < radius) impact(get_expl_ntt(ntt), false, ntt.pos-pos, ntt, true, true)
	end

	-- go over all tiles in rectangle range
	for j=pos.y-radius,pos.y+radius,8 do
		for i=pos.x-radius,pos.x+radius,8 do
			local t_pos = v2n(i,j)
			if fget(mget(t_pos.x/8,t_pos.y/8),0) then
				local tmp_ntt = tmptrne(t_pos)
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
		local p,v,r,c,dc = pos+v20,v2n(rnd(2)-1,rnd(2)-1) + (vel or v20),rd, co, dc or 0.3
		dt(ti or 11,
			function()
				circfill(p.x,p.y,r,c)
				p += v
				r -= dc
			end,
		
			{},true
		)
		
	end
end


function lstmn(ntt, dmg)
	local envstr, _ENV = _ENV,ntt

	if stmn then
		local p_s=stmn
		
		stmn-=dmg
		if (stmnh) stmnh = max((stmn_l_t-stmn)/2,stmnh)
		
		
		local total_dmg = p_s - stmn
		ts.hurt=total_dmg*2

		ts.htsc = dmg*0.5+0.7

		-- SOME MINIONS HAVE ENEMY TO "f" SO IT'S NOT THE TRUE BOOL ELSEWHERE BUT DOES EVALUATE HERE
		if enemy and stmn > 0 and total_dmg > 1 then
			envstr.txtb("\^o05a"..(stmn/stmn_l_t*100)\1 .."%",0,pos.x,pos.y,envstr.unstr"0,0,0,0,18")
		end

	end

end

function tmptrne(pos)
	local px,py=pos.x\8,pos.y\8
	local ntt=spe(px*8+4,py*8+4,12)
	ntt.tile = mget(px, py)
	if fget(ntt.tile,1) then
		ntt.mass,ntt.g_i = 15
	end
	if (fget(ntt.tile,4)) ntt.bnce = 0.99
	if (fget(ntt.tile,6)) ntt.dmg,ntt.kb = 12,0.5
	return ntt
end

function coll_p(e,p,i,o)
	-- first thrown hit is buffed
	if e.stmn and o.thrown and o.thrown != e and o.funcC != Chook then 
		i,o.thrown = i*5+8--,false--.ts.thrown
	end
	
	if o.dmg then
		lstmn(e, o.dmg)
		if (e==ply) sfx2(-1)
		local cnt_vel=v2nrm(e.pos-o.pos)*(o.kb or 0)
		addF(e, cnt_vel)
	end

	if e.tile and o.e_proj then
		e.vel = p
	end
	
	if e.funcC then
		e.funcC(e, o, p, i)
	end
	if i >= e.iarm then
		lstmn(e, i*i*0.32/e.irss)
	end
end

function impact(entity, with_t, surface_dir, coll_e, no_sfx, no_sq_coll)

	local prev_v1,prev_v2 = entity.vel+v20, coll_e.vel+v20

	local function get_nrg(v1,v2)
		return (#v1)^2*entity.mass + (#v2)^2*coll_e.mass
	end

	local slp,bnc = max(entity.slip, coll_e.slip), max(entity.bnce, coll_e.bnce)
	
	tmmtm(entity, coll_e, bnc, slp, not no_sq_coll)

	local impact=get_nrg(prev_v1,prev_v2)-get_nrg(entity.vel,coll_e.vel)
	local impact_1,impact_2=splitV(impact, entity.mass, coll_e.mass)


	-- if broke terrain turn tmp tile to entity tile
	if with_t and #coll_e.vel > 0.08/(1-bnc) then
	
		impact_2 += rnd(1)
		coll_e = t2ntt(coll_e)
		coll_e.vel *= 4
		
		if (impact_2>2.1) coll_e.sprite = 15
		if (impact_2>2.5 or #ntts > 10) rme(coll_e)
		
	end

	coll_p(entity,prev_v1,impact_1,coll_e)
	coll_p(coll_e,prev_v2,impact_2,entity)


	if not no_sfx then
		if impact > 11 then
			sfx(6,-1,7,25)
		elseif impact > 4 then
			sfx(6,-1,0,7)
		end
	end
	
end



function tug(link)

	local e1,e2 = link.from, link.to
	local e2_pos = e2.pos

	local diff = e2_pos - e1.pos
	local move_dist = #diff - link.len

	-- amount that entities need to move to remain in link range
	local move_need, do_move = v2nrm(diff) * move_dist--,nil

	-- check if tugging is needed
	-- small tolerance (0.6) so it isn't constantly active
	if (move_dist >  0.6) do_move = true
	
	-- break if too far
	if link.str > 0 and move_dist >  link.str then
		delete_link(link)
		return
	end


	if do_move then

		if e2.tmp_tile then
			e1.pos += move_need
			-- remove vel component towards ground
			e1.vel = rcmul(e1.vel, e1.pos - e2_pos, 0, 1)
		else
			-- the amount each entity needs to move
			local move_1,move_2 = splitV(move_need, e1.mass, e2.mass)

			e1.pos += move_1*0.98
			e2.pos -= move_2*0.98

			-- equalize velocity components
			-- but only if not already moving in a way favorable for link
			-- fixes player bounce speed cancel (idk about link type 0)
			if (v2dot(move_need, e2.vel - e1.vel) >= 0) tmmtm(e1,e2, 0.1, 1)
			
		end

	end

end

-- rough iterative raycast with angling
-- todo inline? check if worth it
function ryc(pos,vec,angle_range,leg_entity,entity)
	for i=1,entity.ray_iters do
		local t_vec = v2rot(vec*(rnd()+0.1),angle_range*(rnd()-0.5))
		local t_pos = pos + t_vec
		local coll_land,with_t,out,away_vector,other_ntt = unclip(leg_entity, t_pos, leg_entity.rds+2, true)
		local is_magnet = entity.mgntc > 0 and (fget(mget(t_pos.x\8, t_pos.y\8), 2) or other_ntt and other_ntt.tile == 24) -- only 44 & 45 get wst
		
		-- todo if need away vec check?
		if (coll_land and out and (v2dot(t_vec,away_vector) <= 0 or is_magnet)) return true, t_vec, with_t, away_vector, other_ntt, is_magnet, false

		if is_magnet then 
			return true, t_vec, true, v2u+v20, tmptrne(t_pos), true, true
		end
	end
	return false
end



function mvt(ntt, target_pos, speed)
	ntt.pos+=v2lmt((target_pos-ntt.pos)/speed)*speed
end

function move_hmn(entity)
	local envstr,_ENV=_ENV,entity

	for arm in envstr.all(arms) do
		arm.sst=false
	end


	local prev_jump = g_mode

	envstr.mdtbl(entity, "sst,g_mode,gns,slide,mgntw/false") -- implicit nil chain
	sticky = prst
	
	-- proc move legs

	if #legs>0 then
		local stand_vec,max_dist,max_leg,max_stand_center=envstr.v2nrm(entity.lgfc)*leg_len*1.25, stnd_h/2
		
			-- move target with highest distance to optimal target position (if outside tolerant distance)
		local st_pos,st_away,st_c = envstr.v20*1,envstr.v20*1,0

		for leg in envstr.all(legs) do
			stand_vec_l = envstr.v2rot(stand_vec,leg.angle * envstr.tnmf(left))
			if (prev_jump)stand_vec_l+=vel*leg_len*0.75
			local stand_center = pos + stand_vec_l -- optimal place to stand on
			local dist = #(leg.t_pos - stand_center)
			if (leg.mgntw and #idir > 0 and ts.jmp_cl <= 0 and mgntc > 0) then
				sticky = true
			end
			
			--envstr.dt(0, function() envstr.circ(leg.t_pos.x, leg.t_pos.y, 2, 3) end )
			
			if (dist > leg_len*1.4 --[[or envstr.ac%30==#legs]] or ts.jmp_cl != 0) leg.t_ac = false
			
			if envstr.timerr(entity,"jmp_cl") then

				if not leg.t_ac and not slide then -- dont check if already sliding to save cpu

					local did, t_vec, with_t, away_vector, other_ntt, magnetwalk,m2 = envstr.ryc(pos, stand_vec_l,l_a_r, leg, entity)
					leg.mgntw = magnetwalk and (m2 or away_vector.x != 0)

					if did then
						stand_center = pos + t_vec + away_vector
						
						leg.snrm,gr_e,dist=envstr.v2nrm(away_vector),other_ntt,#(leg.t_pos - stand_center)
						
						if dist > max_dist then
							max_dist,max_leg,max_stand_center = dist,leg,stand_center
						end
						if dist <= leg_len*1.4 then
							leg.t_ac = true
						end

					end

				end

				-- move legs to targets
				if leg.t_ac and not fget(gr_e.tile,6) then
					g_mode,slide=true,gr_e.tile and idir.y > 0
					gns = not slide
					
					st_pos+=leg.t_pos
					st_away+=leg.snrm
					st_c+=1
					
					if (leg.mgntw) mgntw = true
					
					if gns then
						envstr.mvt(leg,leg.t_pos, l_spd)
					
						if #vel < 9 then
						
							if (sticky) leg.vel*=0.75
							

							if leg.stnd and leg.snrm.y<0 or sticky then
								sst = true
							end
							
						end
					end
				end
			end

		end
	
	

		-- assign new target - only if off cooldown and outside tolerance range
		if leg_cd <= 0 and max_leg then
			max_leg.t_pos,max_leg.t_ac,leg_cd  = max_stand_center,true,l_cld
		else
			leg_cd -= 1
		end

		if (st_away.y <= -0.5) st_away.x = 0
		snrm=envstr.v2nrm(st_away)

		if sst then

			vel.y *= 0.85
			
			if not sticky then

				pos.y = pos.y*0.9 + (st_pos/st_c + snrm * (stnd_h + envstr.ac\48%2)).y*0.1

				for arm in envstr.all(arms) do
					arm.vel*=0.95
					if #arm.vel < 0.15 and not armg then
						arm.sst=true
					end
				end

			end

		end
		
	end
end



function uR(ntt)
	if ntt.idir.x != 0 then
		ntt.left = ntt.idir.x < 0
	end
	if (ntt.sDir) ntt.left = ntt.sDir.x < 0
end


function move_ctrl(ntt)
	local surface_normal,input_dir_l,jump_cooldown = ntt.snrm, v2lmt(ntt.idir), ntt.ts.jmp_cl
	
	if ntt.ts.htsc < 3 then
	
		-- grabbing ----

		if #ntt.arms > 0 then
		
			local input_dir_h = input_dir_l + v2l*tnmf(ntt.left)*0.05
			
			local hold_pos = ntt.pos + v2nrm(input_dir_h)*ntt.arm_len
			-- check if grab still valid
			if ntt.in_grab and flnk(ntt,ntt.grbe) == nil then
					ntt.in_grab,ntt.grbe = false--,nil
			end
			


			if ntt.b5 then
			
				local hp_clip,hp_with_t,hp_out,hp_dir,hp_coll_e = unclip(ntt,hold_pos,3, false, 2)
				--local hp_2 = hold_pos+(hp_dir or v20)

				for arm in all(ntt.arms) do

					if hp_clip and not ntt.in_grab then
						ntt.vel *= 0.8 -- wallslide
					end
					
					cntF((hold_pos-arm.pos)/128,arm,ntt)
					--mvt(arm,hp_2, 1.5)
				end
			
				ntt.armg = true

				-- try to grab
				if not ntt.in_grab and not ntt.grab_c and not ntt.in_burst then
				
					if hp_clip and not hp_coll_e.g_i then
						ntt.in_grab = true
						if hp_with_t then
							hp_coll_e = t2ntt(hp_coll_e)
						end
					end

					if ntt.in_grab then -- grab
						sfx(9)
						
						ntt.grbe = hp_coll_e
						
						mklnk(ntt,ntt.grbe,split(ntt.arm_len/2 .. ",40,0,14,0,0,0"))
					end
				end

			else
				--throw if holding, else nothing

				if ntt.in_grab then
 
					sfx2(-3)
					  
					local v = v2nrm(ntt.sDir or v2nrm(input_dir_h + v2u*0.04)) * (ntt.grbe.mass <= 0.13 and 0.8 or 1.6) -- limit on throw speed, alt only * sqrt(ntt.grbe.mass/0.125) or smth maybe todo
					cntF(v, ntt.grbe, ntt)

					ntt.grbe.ts.htsc,ntt.grbe.thrown,ntt.in_grab,ntt.grab_c=10,ntt,false,true
					delete_link(flnk(ntt,ntt.grbe))
					-- delay collision swap so doesn't immediately clip in ntt
					dt(5, function() 
						ntt.grab_c = false
						ntt.in_grab,ntt.grbe = false--,nil
					end)
					
				end

			end

			if ntt.in_grab then
				--ntt.mgntc += 1
				ntt.grbe.grabbed = true
				--redirect grabbed object's fire - can still hit me

			end
			
		end




		-- walking/air move ----

		local leg_pos,j_sf,j_of,j_len = (ntt.legs[1] or ntt).pos, ntt==ply and 10 or 0,0,6
		local tx,ty = leg_pos.x\8,leg_pos.y\8
		
		local function wst() -- panel gfx
			ntt.mgntc -= 0.85
			if in_tbl(mget(tx,ty),split"44,45") then
				mset(tx,ty,45)
				dt(5,function() mset(tx,ty,44) end)
			end
			
		end
		
		if ntt.mgntw and #input_dir_l > 0 then -- and not slide?
			--if (input_dir_l.y < 0)
			--ntt.vel.y *= 0.2
			wst()
		end
		
		local accel,vel_limit =  ntt.a_acc, ntt.a_max -- air drift

		if ntt.gns then
			accel,vel_limit = ntt.g_acc,ntt.g_max -- ground movement
		end
		if ntt.g_mode or ntt.b5 then
			uR(ntt)
		end

		


		local pv_add = v2nrm(v2n(input_dir_l.x, (ntt.fly or (ntt.sst and ntt.sticky)) and input_dir_l.y or 0))*accel

		if ntt.sst then
			if (not ntt.mgntw) ntt.mgntc += 10
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
		local align_down,al_of,g_e=-v2u,ntt.vel*0.5,ntt.gr_e
		
		if (g_e) g_is_ntt = not g_e.tmp_tile
		-- jumping ----

		local jump_str,input_dir_j=ntt.jump_str,v2nrm(input_dir_l + v2u*0.7*tonum(input_dir_l.y<=0))
		

		
		if ntt.b4 and jump_cooldown <= 0 then

		
			local function apply_jump()
				if (j_sf>0)sfx(j_sf,-1,j_of,j_len)
				-- store jump state
				
				-- todo can replace min(g_e.bnce, 0.7) with fixed bounce for less tokens
				ntt.st_vel,ntt.g_bounce = ntt.vel*1, (surface_normal.x == 0 and ntt.g_mode and g_e.bnce >= 0.35 and min(g_e.bnce,0.75) * tnmf(v2dot(ntt.vel, surface_normal) >= 0)) or 0.05
				ntt.ts.jmp_cl,jump_cooldown,ntt.st_surf,ntt.st_input=ntt.j_cldwn,ntt.j_cldwn,ntt.fly and input_dir_l or surface_normal,input_dir_l
			end
			
			

			
			-- jump cases
			
			
			-- the titular drop kick
			if ntt.drp and ntt.g_mode and g_is_ntt and not g_e.d_i then
			
				lstmn(g_e, 16+#ntt.vel*4)
				j_ntt,j_sf,j_len = amdtbl({},"pos,vel,mass,iarm,irss,bnce",{ntt.pos,ntt.vel,ntt.mass*3,0,1,1.6}),11,29
				
				impact(j_ntt, false, align_down, g_e, false, true)
				
				surface_normal=v2nrm(ntt.pos-g_e.pos)

				align_down+=surface_normal*40
				
				if (g_e.enemy) particles(g_e.pos, split"6,3.5,0,0.35,10",j_ntt.vel)
				
				ntt.mgntc += 50
				
				apply_jump()
				
			-- ground - no jump fall damage parries
			elseif ntt.g_mode and v2dot(ntt.vel,surface_normal) > -4.5 or ntt.fly then
				
				for leg in all(ntt.legs) do
					if leg.t_ac then
						particles(leg.t_pos,split"7,1.6,0,0.5,6", surface_normal)
					end
				end
				
				if ntt.mgntw then
					if (input_dir_l.y > 0) surface_normal = input_dir_l*1.25
					ntt.mgntc -= 15
					j_of,j_len = 6,12
					--particles(leg_pos,split"3,2.6,0,0.4,8",p_prevvel)
					wst()
				else
					ntt.mgntc += 9
				end
				
				apply_jump()
			end

			


		end
		
		

		
		-- apply jump & calculate new velocity 
 		if jump_cooldown == ntt.j_cldwn or ntt == ply and jump_cooldown >= 5 and #input_dir_l > 0.1 and input_dir_l != ntt.st_input then
			local st_surf = ntt.st_surf*0.95 + v2u*0.25
			
			
			local jump_vel = (rcmul(input_dir_j, st_surf,0.10,0.8) + st_surf)
			uR(ntt)
			
			for e in all(ntt.all_ntts) do
				if (not e.e_proj) e.vel = rcmul(ntt.st_vel,st_surf, ntt.g_bounce, 0.55) + jump_vel*jump_str
			end
			
			ntt.st_input = input_dir_l
		end

			
		if ntt.gns then
			align_down -= surface_normal+al_of
		else
			if ntt.b5 then
				align_down-=input_dir_l*2.5
			elseif jump_cooldown==0 then
				align_down+=al_of+v2u*0.5
			else
				align_down-=al_of*0.5
			end
		end

		ntt.lgfc = ntt.lgfc*0.8 + align_down*0.2
		ntt.fcng = -v2lmt(ntt.lgfc)
		ntt.mgntc = mid(0,ntt.mgntc,70)
	end
	
	local i=1
	for leg in all(ntt.legs) do

		local l_link = flnk(ntt,leg)
		local l_l_len = l_link.true_len

		if not ntt.gns then

			mvt(leg, ntt.pos + v2lmt(ntt.lgfc)*ntt.leg_len, 5-i)

			l_l_len *= 0.9
			if (not timerr(ntt,"jmp_cl")) l_l_len /= i

		end

		l_link.len = l_l_len

		i+=1
	end
	
	if ntt.grapple then
		if (input_dir_l.y < 0 and ntt.grapple.len > 8) ntt.grapple.len -= 2
		
		if ntt.b4 then
			delete_link(ntt.grapple)
			ntt.grapple = nil
			ntt.vel.y -= 2.4
		end
	end
end


function Uply(pl)
	move_hmn(pl)
	
	if pl == ply then
		-- regen stamina
		if (pl.stmn < pl.stmn_l_t-pl.stmnh and pl.ts.hurt <= 2) pl.stmn += 0x0.1e

		amdtbl(pl,"idir,armg,b4,b5",{
						v2l  * tonum(btn(0))
					+ v2r * tonum(btn(1))
					+ v2u    * tonum(btn(2))
					+ v2d  * tonum(btn(3)),false, btn(4), btn(5)})
	end
	if ((btnp(5) or pl.in_burst) and not pl.in_grab and pl.gi and timerr(pl, "gun")) fire_gun(pl)
	
	move_ctrl(pl)

end



-->8
-- level managment

function ll_l(index)
	ll_i,ll_hi,m_title = index,dget(m_i),split"task 1,task 2,task 3,task 4,task 5,epilogue"[m_i+1]
	amdtbl(_ENV, "ll_title,ll_next,pl_x,pl_y,xtra_v,mpx,mpy,ld_s_x,ld_s_y,ll_mus,m_lyrs,lpi,lvl_clearcol,bg1_loc,bg2_loc,lvl_nttloc,ll_ntt_num", split(lvls_info_2[index],"`"))

	-- clear map
	memset(0x8000, 0, 0x4000)
	
	for y=0, ld_s_y-1 do
		for x=0, ld_s_x-1 do
		
			-- draw tile
			local t,x,y = @(0x2000*tonum(mpy+y < 32) + mpx+x + (mpy+y)*128), x, y

			local t2 = t&63

			for j=0,3 do
				for i=0,3 do
					local m_x,m_y = x*4+i, y*4+j
					srand(m_x + m_y*ld_s_x)
					
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

	l_border_x,l_border_y = ld_s_x*32-1, ld_s_y*32-1
	
	
	pal({peek(8272 + lpi%4*128 + lpi\4*16,16)}, 1)
end


-->8
-- enemy ais

function Uenm(enm)
	local look_dir = ply.pos+ply.vel*2 - enm.pos
	local dist = #look_dir
	
	mdtbl(enm,"outl,sst,b4/0")

	enm.idir *= 0 -- this here is why no one else uses slides OR wall-magnetwalking bc the move_hmn in ai_p happens when idir is 0 
	-- that is OK things work better when others dont do slides
	
	-- passive ai
	enm.ai_p(enm)

	local t_gun = enm.ts.gun
	
	
	if enm.ac then
		enm.outl=15
		if (t_gun<14 and t_gun%4>=2) enm.outl=10
		
		if (enm.hz) look_dir.y = 0
		
		
		if (dist > enm.rngf) enm.idir=look_dir
		
		if dist < enm.jumping_d then 
			enm.b4 = true
		end
		
		if (not enm.in_burst) enm.sDir = look_dir
		
		uR(enm)
		
		if ac%20 == 0 then
			enm.rdir = v2rot(enm.idir/2,rnd())
			if (enm.p_a) alert = true
			
			if rnd(1) < enm.dash and (#enm.idir > 0 or dist < enm.rngn) then
				enm.idir += enm.rdir
				enm.b4 = true
			end
			
			-- deco damage
			if (enm.stmn/enm.stmn_l_t < 0.35) particles(enm.pos, split"6, 2.4,0,0.2,8")

		end
		
		if (dist < enm.rngn) enm.idir=-look_dir
		
		if colltrn(enm.pos + v2nrm(enm.idir)*enm.rds*1.5, enm.rds) and not enm.rck then
			if (not enm.melee) enm.idir = -enm.rdir
		elseif timerr(enm, "gun") then
			fire_gun(enm)
		end
		
		
		
		-- active ai
		enm.ai_a(enm)
		
	else
		enm.ts.gun=enm.gun[1]/2
	end


	-- late update so doesn't bug out when immediately spawning in range
	
	if dist < enm.actN or alert then
		enm.ac=true
	end
	if dist > enm.actF then
		enm.ac=false
	end
	

end

-- passive ais
function funcas(enm)
	move_hmn(enm)
end

function funcaf(enm)
	enm.vel *= 0.9
	enm.sst = true
end

-- active ais
function funcaa(enm)
	move_ctrl(enm)
end

function funcah(enm)
	if (enm.pos.y - ply.pos.y > -enm.rngn) enm.idir.y = -100.75
	funcaa(enm)
end

function gg(e)
	local id = e.gi-1 -- todo edit arrays to remove line
	e.gun={peek(4649 +(id%8)*128+(id\8)*11,11)}
	e.gun[5] = e.gun[5]/128-1
end

function fire_gun(e)
	if not e.in_burst then
		gg(e)
	end
	
	local p_dir = (e.sDir or e.idir+v2l*tnmf(e.left)*0.1)*1
	-- cooldown,ntt,speed,sfx,angle,global/burst amount,b delay,b angle, next gun,p extraprops, ntt mods
	amdtbl(_ENV,"g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,gA", e.gun)
	g9 = prop_mods[g9]
	gA = prop_mods[gA]
	
	sfx2(g3-128)
	local proj = spe(0,0,g1,e,g9)
	if (e.left and not proj.gmelee) g4 = -g4
	if (proj.ghz) p_dir.y = 0
	proj.vel+=v2rot(v2nrm(p_dir),g4)*g2/8
	
	if g5\128 == 1 then
		proj.prt=nil
		add(ntts, proj)
		proj.pos+=v2nrm(p_dir)*e.rds*1.7
	else
		add(e.all_ntts, proj)
		if (e != ply) proj.e_proj=true
	end
	
	
	if g5%128 > 1 then
		e.in_burst,e.ts.gun = true,g6
		e.gun[6] -= 1--g5
		e.gun[5] += g7/128-1
	else
		mdtbl(e,gA)
		e.gi=g8
		gg(e)
		e.ts.gun,e.in_burst=e.gun[1]--,false
	end

end

function Umsl(ntt)
	if ntt.thrown != ply then
		ntt.vel *= ntt.slip
		ntt.vel += v2nrm(ply.pos - ntt.pos)/8/ntt.mass
	end
end

function Usgn(ntt)
	if collsqr(ntt.pos, ntt.rds, ply.pos, 1) then
		dt(1, txtb, split(ntt.txtb,"⬇️"))
	end
end

function Blzr(ntt)
	dt(ntt.lzr_thck,
		function(p1,p2)
			lvc(p1,p2,15,timer_t)
		end,
		{ntt.pos,ntt.prt.pos},true
	)
end

function DlEx(ntt)
	Blzr(ntt)
	dt(30,expl,{ntt.pos,ntt.dly_expl})
end

function Chook(ntt,other)
	local thrower = ntt.thrown or ntt.prt
	if thrower then
		delete_link(thrower.grapple)
		thrower.grapple = mklnk(thrower, other, split(min(#(thrower.pos-other.pos),180) .. ",30,4,3,2,3,0"))
		rme(ntt)
	end
end

-->8
-- data

-- levels present in the menu and some strings

m_i,st_l=0,split"1,6,12,19,26,32"

-- main info about all levels
-- 1: title
-- 2: next lvl (1-indexed, -1 is finish, -2 is no transition (for custom ones))
-- 3,4: player spawnpos x & y
-- 5: extra global vars

-- 6,7: map pos x & y
-- 8,9: x & y size
-- 10: music index
-- 11: music layers
-- 12: main palette index
-- 13: clear color

-- 14, 15: bg1 & 2 index
-- 16: entity array mem location (4096 + x + (y-32)*128)
-- 17: num entities

--bgs at 96,36

lvls_info_2 = split([[   the construction site  `2`24`24`lly/-32`56`14`23`3`6`1`0`1`1`4`11904`5
1: roadblock`3`7`66`/`70`17`15`4`7`3`0`2`1`6`12032`6
2: magnetizing yourself`4`6`328`/`71`25`14`11`7`3`0`2`1`6`12160`7
3: mayhem square`5`4`170`lly,e_rq/-64,4`0`12`13`10`7`7`1`0`8`7`4096`8
4: the small issue in question`-1`4`116`lly,e_rq/-32,1`24`12`12`6`7`7`1`0`8`7`12056`2
  the hijacked transport  `7`16`58`llx,lhy,lly,e_rq/-128,320,-32,4`67`21`14`4`18`5`2`2`24`25`11924`4
1: what a blast`8`10`88`/`111`12`11`4`18`5`2`1`26`27`12188`4
2: hang in there`9`4`300`lhy/416`79`25`10`11`18`5`2`1`26`27`4224`5
3: too much fresh air`10`10`115`lhy,lly,e_rq/180,-64,6`87`12`24`5`18`13`3`12`28`29`4352`9
4: annoyingly out of reach`11`8`56`lly,e_rq/-96,1`81`21`9`4`18`13`3`12`28`29`4128`2
control cabin`-2`6`50`lhx,lhy,lly/256,96,-96`87`21`4`3`6`1`3`12`28`29`4136`1
     middle of nowhere    `13`210`59`/`103`16`10`9`-1`7`4`2`16`17`4388`2
1: bouncy castle`14`4`315`/`103`25`10`11`28`3`4`4`16`18`4244`6
2: horrid sludge pits`15`8`170`sl_l,sl_c,sl_dmg/193,1,0.75`113`16`15`7`28`3`4`5`18`20`4480`4
3: hunted`16`4`154`lly,e_rq/-96,3`113`23`15`6`28`3`4`2`19`20`4608`5
4: dry moat`17`4`28`lly,e_rq/-96,6`113`29`15`7`28`7`5`1`1`21`4864`8
`18`11`66`lly/-32`24`25`10`3`-1`3`5`1`1`21`4864`0
gah! peer interactions`-2`17`75`lly/-32`62`17`8`4`35`7`5`1`1`21`4992`1
        the cache         `20`4`83`lhy,sl_l,sl_vy,sl_smth/540,382,-0.75,0.93`55`24`7`12`-1`1`6`0`2`0`4996`0
1: into the system`21`4`122`sl_l,sl_h,sl_spd/200,0.75,12`38`15`14`7`42`5`6`4`0`0`4736`3
2: floodgate aquarium`22`4`44`sl_l,sl_h,sl_spd,e_rq/145,0.48,7,4`24`17`14`8`42`5`6`1`0`0`4748`5
3: hideout`23`109`-6`sl_l,e_rq/364,1`47`23`8`13`42`5`6`4`0`0`4496`6
4: do you smell smoke?`24`4`458`sl_l,sl_r,sl_c,sl_dmg,lhy,sl_h,sl_spd/533,-0.42,2,1,600,0.40,6.75`62`21`7`15`42`11`7`8`18`0`4996`5
5: weekly core failure`25`80`490`sl_l,sl_r,sl_c,sl_dmg/530,-0.55,2,1`98`20`5`16`42`11`7`0`10`0`5132`2
"try to exit discreetly"`-1`70`492`lhy,lly,sl_l,sl_vy,sl_r,sl_smth/740,-2048,380,-0.6,-0.6,0.93`55`24`7`12`6`1`6`1`2`0`4996`0
  raiding their storages  `27`12`86`e_rq/1`122`12`6`4`49`51`8`0`8`6`5120`3
1: elevatorspace`28`3`273`lly,e_rq/-32,4`13`12`11`10`49`3`8`1`10`0`5248`4
2: the garages`29`5`81`lly,e_rq/-128,3`89`24`9`12`49`3`8`0`8`6`4628`3
3: けんと゛う`30`3`112`e_rq/3`35`12`13`6`49`7`8`0`8`0`5140`3
4: attention seeker`31`12`114`lly/-16`56`12`31`5`49`7`8`0`8`7`5504`2
5: cleanup`-1`12`181`sl_l,sl_c,lly,sl_vy,lhx,e_rq,sl_smth/197,1,-64,-0.75,448,3,0.83`51`17`11`7`49`7`8`0`8`6`5512`4
       the invasion       `33`71`174`lhy,e_rq/280,3`85`17`18`7`57`39`9`0`11`28`5264`4
`34`6`240`e_rq/5,0.18`36`22`11`9`57`39`9`0`12`28`11776`8
`35`11`14`lly,lhy,e_rq/-96,190,2`49`12`7`3`57`39`10`0`12`28`5400`2
the swarm`36`4`170`lly,e_rq/-64,4`0`22`16`6`57`39`10`0`13`23`5376`5
the payloader`37`18`132`llx,lhx,e_rq/-2048,2048,1`16`22`8`6`57`35`10`0`23`10`4520`1
`-2`9`329`grav,llx,lhx,lly/0.11,-128,192,-128`69`25`2`11`6`33`10`0`23`0`5532`1]],"\n")

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
	39: sword pickup
]]


-- NOTES: masses lower than 0.1 bug link-related movements
-- enemies with fly ais need "fly" prop in order to move up/down
-- template, radius, mass, sprite | extra properties (key1,key2/val1,val2)
-- prefix _V_ means an env variable of that name (minus the prefix obv)
ntt_types = split([[/
Uf,Df,Btyp,stmn,stmnh,iarm,irss,slip,col,outl,ray_iters,drp/_V_Uply,_V_Dply,2,70,0,5,5.5,0.99,12,9,6,t
Df,slip/_V_e,0.9
rope,rX,rY,hz/1,0,16,t
rope,rX,rY,gi/1,0,16,9
rope,rX,rY,rope_e,stmn,gi/1,0,-45,len➡️50,48,2
Uf,Df,Btyp,stmn,iarm,gi,ai_p,ai_a,enemy,smok,fly,rngf,rngn,slip,f_c,dash/_V_Uenm,_V_Dntt,1,40,2,1,_V_funcaf,_V_funcaa,true,1,true,36,22,0.9,3,0.5
Btyp,stmn,iarm,irss,gi,ai_a,smok,rngn,rngf,spr_size,actN,actF,g_i,sprW,sprH,grav/4,136,2,2,6,_V_funcaa,4,40,55,16,55,2000,t,2,2,0.05
dmg,grav,smok,stmn,bnce,dur/10,0,3,0,0.8,48
Btyp,Df,dur,next_e,col/3,_V_Dply,40,14,6
funcC,item,amount,smok,ignS,g_i,txt/_V_Citm,1,25,2,true,true,
tmp_tile,smok,g_i,mass/t,1,t,30
Uf,nophys,grav,d_o/_V_Usgn,t,0,1
Uf,Btyp,dur,b_f,idir,col,b4,drp/_V_Uply,3,60,_V_d_ld,_V_v2r,6,t,nil
item,f_c,f_l,txt/2,3,6,trinket!
funcC,rspw/_V_Chook,true
rope,rX,rY,gi,ai_p,ai_a,stmn,hz,actN,actF,sprW/2,21,0,20,_V_funcaf,_V_e,16,t,150,160,2
iarm,gi,rngf,spr_size,hz,actN,actF,g_i/0.2,10,90,16,true,70,130,t
fly,actF,actN,rngf,rngn,gi,Btyp,spr_size,sprW,f_c,melee,irss,stmn,g_i,smok,boss/nil,2000,2000,10,0,27,7,24,2,1,t,10,150,t,4,t
Uf,smok,stmn,ignS,expl,grav,slip,f_c,f_l,dur/_V_Umsl,3,0.1,true,2,0,0.985,2,4,90
Uf,dmg,b_f,expl,slip,stmn,irss,smok,dur,rds/_V_Umsl,nil,_V_Blzr,4,0.9,100,500,5,85,-9
Btyp,spr_size,ai_p,ai_a,actN,actF,rngn,rngf,gi,stmn,smok,fly,iarm,sprW,irss/6,16,_V_funcaf,_V_funcah,110,2000,35,60,11,280,4,true,1,2,2
Uf,Btyp,stmn,boss,ai_p,ai_a,gi,col,rngf,rngn,actF,actN,jumping_d,next_e,enemy/_V_Uenm,3,200,t,_V_funcas,_V_funcaa,22,6,100,60,500,500,20,10,f
Uf,Df,Btyp,stmn,iarm,gi,ai_p,ai_a,enemy,smok,left,sst/_V_Uenm,_V_Dntt,1,48,2,1,_V_funcas,_V_e,true,1,true,true
Df,enemy,nophys,grav,gi,actN,actF,hz/_V_e,nil,t,0,16,2048,2048,t
spr_size,grav,dmg,kb,f_c,f_l,sprW,sprH,outl/16,0,4,1.5,3,2,1,1,15
rope,rX,rY,bnce,spr_size,sprW,d_o,d_i/2,21,0,0.99,16,2,4,t
Btyp,gi,rngn,rngf,actN,actF,stmn,ai_a,sprW,f_c,dash/6,14,20,55,70,170,56,_V_funcah,2,1,0
Btyp,stmn,gi,ai_a,rngf,rngn,actF,irss,fly,slip,sprW,sprH,dmg,kb,dash,jumping_d,j_cldwn,expl/8,112,18,_V_funcaa,5,5,170,4,t,0,2,2,9,1,0.1,40,45,1
Btyp,gi,stmn,p_a/1,18,24,true
spr_size,gi,dash,Btyp,rngf,rngn,actF,stmn,expl,g_i/16,17,0,6,55,30,200,120,1,t
Btyp,gi,stmn,sprW,f_c,rngn,dash,j_cldwn/7,19,44,2,1,30,0.8,40
Btyp,stmn,ai_a,gi,col,outl,rngf,rngn,actF,actN,dash,b5,slip,ray_iters,drp/3,65,_V_funcaa,25,15,15,60,30,250,60,0.8,true,0.99,4,t
Df,nophys,grav,d_o,decal/_V_Ddcl,t,0,1,l
dmg,kb,b_f,lzr_thck,smok,bnce,dur/5,0.1,_V_Blzr,4,3,0.1,6
stmn,irss,gi,rope,rX,rY,dash/68,3,3,1,0,16,0.6
expl,slip,dur/1,0.985,50
sprW,sprH,spr_size,gi,dash,f_c,stmn,rngn,rngf,actN,actF,ai_a,g_i,rck,boss,smok,b/2,2,32,33,0,1,370,70,84,120,800,_V_funcah,t,t,t,4
item,outl,txt/3,12,V50 blade]],"\n")



-- modifications for certain entities in level, no newlines to keep control chars (made in lvl editor)
ntt_extras=split("/⬅️p_a/t⬅️next_e/11⬅️rX,rY/20,0⬅️rX,rY/-20,0⬅️rX,rY/0,-20⬅️rX,rY/-16,-16⬅️Btyp,prst,rope,ai_a,rngn,rngf/5,t,nil,_V_funcaa,35,70⬅️gi,boss/29,nil⬅️boss/t⬅️rope,rX,rY/1,76,-20⬅️b_f/_V_d_ld⬅️/⬅️/⬅️/⬅️rX,rY/-16,16⬅️txtb/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️-30⬇️44⬇️42⬇️2⬇️1⬅️rope,rX,rY,rope_e/1,-45,-8,len➡️50⬅️txtb/\f3(a terminal is unlocked.\nsome of the files seem\nto imply a mass\nsurveillance program.\nyou copy the data.)⬇️false⬇️98⬇️98⬇️104⬇️38⬇️8⬇️1⬅️txtb/\fastaff is advised\n to only \fcgrab the\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1⬅️decal/\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!\*f \*f \*f \*5 \^h\n🅾️\n\n\|c \-e+\n\n\|c\-f\^:10387c1010100010⬅️decal/\f2\^o0ff\^:00008064320f0204 \^h ❎\|e\n\ng\|fr\|fa\|fb  \|e\^:0000070c90a0c0f0⬅️decal/\f2\^o0ffk\|ee\|fep\n\n\|er\|fu\|fn\|fn\|fing\^;10387c1010100010⬅️actF/600⬅️actF,rngf,rngn,ai_a/600,160,25,_V_funcaa⬅️gi/29⬅️enemy/f⬅️enemy,boss,sprite,outl/true,t,207,12⬅️gi/15⬅️next_e/39⬅️actF,enemy/600,f","⬅️")


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
-- grnd_accel,air_a,g_max_spd,a_m_s,jump, [leg_len,arm_len,stand_height, leg speed,leg group cd, max leg target rotation]
-- IMPORTANT: MAKE LEG_LEN SIGNIFICANTLY LOWER THAN ACTUAL LINK RANGE OTHERWISE CAN GET STUCK
-- limb info at 13+th array slot:
-- limb type (a/l arm or leg), angle, link array index, link extraprops
ntt_b_types = split([[0.15,0.15,3,3,2.6
0.8,0.21,2.07,1.05,2.1,8.75,5,7.7,3.2,2,0.2,l,0.015,4,len➡️8.8,a,0.02,3,➡️,l,-0.015,4,d_o`len➡️3`8.8,a,-0.02,3,d_o➡️3
0.3,0.21,2.07,1.05,2.3,8.75,5,7.7,3.2,2,0.2,l,0.015,4,col`len➡️3`8.8,a,0.02,3,col➡️6,l,-0.015,4,d_o`col`len➡️3`3`8.8,a,-0.02,3,d_o`col➡️3`6
0.2,0.05,1.2,1,0,42,1,40,10,3,0.10,l,0.03,5,len`width➡️50`12,l,-0.03,5,len`width➡️50`12
0.10,0.05,1.5,1,2.4,15,1,12,4,6,0.6,l,0,5,➡️,l,0.5,5,➡️
0.11,0.11,1.25,1.25,0
0.18,0.18,4,4,3.1
0.15,0.15,1.25,1.25,3.7]],"\n")



prop_mods = split([[/
rngf,rngn/90,45
rngf,rngn,ai_a,hz/60,40,_V_funcaa,nil
rngf,rngn,fly/60,40,true
rngf,rngn/1,0
rngf,rngn,b5,jump_str/1,0,nil,2.9
rngf,rngn,dash,b5,jump_str/120,60,0.5,t,2.3
rngf,rngn,jumping_d,b5/3,0,30,nil
rngf,rngn,dash,jumping_d,b5/90,80,0.9,10,t
rngn,rngf,jumping_d,b5/0,8,10,nil
rngn,rngf,jumping_d/15,20,10
dmg,rds,ghz,lzr_thck,b_f,dly_expl,dur/nil,2,true,8,_V_DlEx,3,15
dmg,ghz,dur,lzr_thck/4,t,10,9
dur,ghz/2,t
enemy,stmn,next_e,dur,actF,actN/f,60,11,225,700,700
dur,ghz/170,t
enemy,stmn,dur/f,20,260
dmg,dur,lzr_thck,ghz/15,16,8,t
rspw,dur/nil,60
dur/55
dur,smok/2,nil
dur/0
enemy,rope,dur,gmelee,irss,bnce/f,nil,100,t,40,0
dur,slip,b_f,lzr_thck/70,0.99,_V_Blzr,6
enemy,actF,actN,next_e,b5/f,600,600,11,nil
kb/0.7
rngf,rngn,hz,ai_a/3,0,t,_V_funcah
dur,smok,kb,dmg/2,nil,0.04,12
ai_p,ai_a,irss,hz/_V_e,_V_e,300,t
ai_p,ai_a,irss,hz/_V_funcaf,_V_funcah,1,nil
enemy,actF,actN,next_e,dur/f,600,600,11,400]],"\n")

-- cooldown,  projectile entity,  p speed*8,   sfx(conv:x-128),
-- angle(conv:(x-128)/128), is global (high 1)+burst amount (low 7),  b delay,   b angle shift(conv:(x-128)/128) 
-- next gun, proj prop mod index, ntt prop mod index
-- mapspace 0 36


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
15:3x robot spawner, 10 switch
16:big sawblade
17:drone spawner
18:empty gun
19:shotgunsprH
20:static laser hazard
21,22,23,24: boss 3 sequence (hook throw, laser target, dropkick + gun, gun 2) (starts at 22)
25,26: robot sequence (slash up, slash down)
27,28: boss 5 sequence (laser drone, missle rain)
29: more drone spawner
30,31,32: empty
33-37: final boss sequence
(g missles,2 drones, drop shockwave, missles, burst)
]]

-- 1 standard machine holder
-- 2 mushroom stem
-- 3 playerlimb - arm 
-- 4 playerlimb - leg
-- 5 enemylimb - spiders, walkers etc
-- 
-- len, str, draw_type (DEPRECATED[0-none, 1-line] 2-joint,3-legjoint,4-noflip joint), col
-- width, draw order (0-4, outside is none), outline color (0 is none)
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
12,3,-4
7,2.5,0
7,8,-2,-4,7
15,3,14]],"\n")


-- radius, str*2, sfx
--[[ 
1 standard
2 bigger
3 small (dly laser)
4 very strong, concentrated (sniper laser)
]]
-- be VERY CAREFUL with the str val
-- map 44,32



-- player hurt noises, giga explosion, throw, hp pickup
ex_sfx = split"\a63s2v2i6g#3<d4c4i0c4c#4g#3g#2,\a63s7v2i3x3f2fv7i6f<f<f<f<f<\*ffi2f0\*ff\*ff,\a63s2v3i6x3g2c>x0d#2i7f#3x1g1a#2f0d#d#,\a63s2i7v6d#0a#g#d#1g#c#g#g#2d#3g#3..<g#3..<g#3..<g#3"
-- all of these should overwrite empty slot 63 with \a63

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
4242654042b3f38070e5723070a2f13070e3753042c444804245c54042037280619481a00163b210e132d2c00000004a4a420899084a4af7f718f7f7f7616262
62525a6942a0d94223c113716b72916b6b826bf9106b080848111111111111111111637a080872443c25c6546cc6b5c54446951c3c2c3c2c166464142cd41c8d
0101b6100143d5107044d51060c4f5404205f280b1c41540c1e25530c1f2f21002433320f0216210b141a2100000007a39200873084a4ae8e8e8e8e8e86171f3
7373f3694280d99b01fa213ad072636b8222826b7b0a3333f97060e40260e402607099297208729de6b5254497d5c5c575979f163cd43cd4c46754243cd42c7d
21a8a310f04252100154f31070a2333050c2838060aac23070c981304229b18042580480b1c1d350b1436601000000684b78080808084a020202020202f1f3d0
d8d0624379b831baba0a21818163638378826b5bb1f2f26058707070707070707070637a0808729796c6251f25d514b5741cc43c2cccd43cd454243c1cd41c7d
b152d401c152231002c5e2100254d2309141c11091c3c11070c2a5b1d16208b1b0d254c1d0d2343162d3c1c0000000422960606060185a6f6f6f6f6f6f826a62
626a71d33178c383838383424263630808f2f2e2a168b1f163636363636363636363997a8708726cb5b5547474b5ac8c676c645454445c54141414145c54145c
0236a281c1c67391e1055410c1c262910244728180d1c42080b3c4201283d13000811040d020200000739041d808101008101010c39081d8c7308038901010e1
7002a808280ac8111110423204086af010a7a151a0834180780858c10822101000000000080808087410282808ca080836102828050a080813102828050ae9d7
d143153042b6b280d1b694400264a230d1a65510d1326530d1e4853042138580008100208020200000643204f8f82120f72010104641807808181008a01010ff
1000080810100821611060320408834110689151b0610201a80728830a329110231028280b4918080000080808080808371038480a8a0808131058480a66daa7
42f4838002d36310c146131060d6043002467430c1d3043060b2c3300141941000500020c000209000a552607806101000301010054120780738c368c0101064
9081e897301038311010a5110508a6181008c17110963286f8c99010e742c0d1201028280b49f708552018f80a0808083710e70a0a0c0808243038080866e917
7172031050e2b34040d1e6606011243040718760f031d5100000000000000000005000307000209000a03204f88970108750c110e67081a8b918a00cd0f0b110
3204080a462008412110e1528008c890b07ab18110c3528078b930418e5210e10000000008080808811018080808080833102889bc0c0808243048880a4cda26
12d2832002c200f1708200f19141e1109162e1100215d22012c2d3e1f1f5a2d100310020d020200000403204f8e4e0108840c110c33204f80a812008b0d030e1
0184d7f7101008613160e10201080848af08a09140239081d8870410db121010100048880c280808811018080808e7083710288a086d08082410384808e8e908
f1431230f14555101291343012f124300133541050b6d34002686230f1c8a2d1000000000000000000649041d8b740704870a11055510108081010a8e01010a0
5141080810100871417000000000000000000000000000000000000000000000141038185ae808088010182808d7b70830102809084b0808241058880829cb08
8006c1303141e09061581130c15383307247f11000000000f1e16220f1f2021000000000000000000064528078172041b88010206412c0a80828cd08a0913082
9081d80810100881108000000000000000000000000000000000000000000000120058888388080820102838082c080800000808080808084010284808cc0808
31d081b1f08bf11012f2d430f134c2303181f0a17251d41000000000e131f1c0000000000000000000643204f879a020e760c03064a181080a10100801011087
9081d808101008511090000000000000000000000000000000000000000000000510588805870808000008080808080894002808080c080860003809040d0808
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00102000000010000010100010102010102020104050000050404040004050500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0f011010111b0f011f0311100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
20174e0321535b1e1d285a031c475301204f55022424420410182f011c3c2f010000000027a3a3a32780808080800ba4929f363636929302b7b7828c0c56b6a5250363a1241c0aa71b80a0981819868712a1bbb9363686b43c3f3f3f3f833f3f3f3f99e7af2e85458052415d624180804547c6c545455747474747474745c646
048d250107ae220104ab2d040d6d23112224281505493008074d1e03062325100666230125a8a3a8353a3a3a3a3a0ba7809714809f2da4b98c914ef6f6569616363637a1161c09a79632ae3818181904073506053614aaa09f11111111111111111136a778802748696d456a5a5a6a8045507172807271727172f38080727150
04332d0207242902044d280705742504224f2816076d38010b1c2701084c360a0000000036454545aa1a1a1a1a1a0b24a4a91233930393bd8fb7043d4e16963737b7a6b69f8b0aa7342ca02c2b2719993636363636b680a09307b83838383838b80736a71c80274543525ac3526c6c5c456447c15047f8c3c3f8467150c36464
051739030f0d2f01043f3502073920030743220124653808220f6e170d1533141232320307472b01125a3201000000022001802693038236368c1607bd16963f373c02b6978b0a881a1aae018127193c3c3c3c3c1428808084a54f25a54fa5254fa536a798a7366ac2526c41525c5c5ccac476c3c37979524de379c2c3f5d864
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

__meta:title__
dropkicks inc
by mk-0
