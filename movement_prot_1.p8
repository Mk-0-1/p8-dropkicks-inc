pico-8 cartridge // http://www.pico-8.com
version 42
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
printh("start------------")

	--init global vars
	debug_visuals = false
	
	mod_tabl(_ENV,"trn_bnc,trn_slp,grav/0.4,0.4,0.175")
	mod_tabl(_ENV,"b_lmt_x,t_lmt_x,b_lmt_y,t_lmt_y/-400,2000,-2000,400")

--global player vars
	mod_tabl(_ENV,"p1_jump,p1_h_g_spd_lmt,p1_h_a_spd_lmt,p1_st_rng/2.6,2.2,1.5,10")
 --jump, ground/air speed limit, stand range

 -- timers & counters
 mod_tabl(_ENV,"anim_c,max_anim_len/0,2048")
	
	-- use extended map by default
	poke(0x5f56,0x80)


	camera_x,camera_y=64,128
	prev_cam_speed = vec2_zero
	
	load_lvl(1)
	
	init_entities()	
end

function init_entities()
	player=spawn_player(132,127+64) -- reference to the controllable entity
	add(entities,player)
	
	local box_1=spawn_entity(150,150,3,11)
	box_1.bnc=1
	add(entities,box_1)
	
	local box_2=spawn_entity(170,130,0.3,5)
	box_2.bnc=1
	add(entities,box_2)
	
	
	enm_1=spawn_complex(195,150,ntt_b_types[2],0b00000100,0b00001011)
	enm_1.update_func = update_e1
	enm_1.draw_func = draw_enm
	enm_1.sprite=163
	add(entities,enm_1)
	
	--music(0)
	
end

tugs_per_frame=0
MAC_per_frame=0
frame_c=0

delay_timers = {}

function delay_func(ticks, func, args)
	add(delay_timers, {t=ticks,f=func,a=args})
end

function _update()
	frame_c += 1
	anim_c += 1
	anim_c%=max_anim_len

	if frame_c>=30then
		printh("tugs in second: "..tugs_per_frame)
		tugs_per_frame=0
		printh("MAC in second: "..MAC_per_frame)
		MAC_per_frame=0
		frame_c=0
	end
	
	
	-- update delays and timers
	for timer in all(delay_timers) do
		timer.t -= 1
		if timer.t <= 0 then
			timer.f()
			del(delay_timers,timer)
		end
	end
	
	for ntt_ts in all(entity_timers) do
		for name, timer in pairs(ntt_ts) do
			if (timer > 0) ntt_ts[name] = timer-1
		end
	end

	update_mus()

	-- update entities
	for ntt in all(entities) do
		
		if not is_oob(ntt.pos) then
			ntt.update_func(ntt)
		end
		
			-- cleanup tile entities
		if ntt.e_type == "tile" then
			if ntt.is_stnd and ntt.stnd_on_trn and vec2_len(ntt.vel) < 0.05 and not (player.in_grab and ntt == player.grabbed_e) then
				entity_to_tile(ntt)
			end
		end
		
	end

	--check entity links and pull/push them if needed
	--ordering is important - if this happened during entity move 
 --then the first moved entity would pull the other much more
	--can be iterative. 
	--run this for loop multiple times for slightly more accurate link physics
	for j=1, 1 do
		foreach(all_links, tug)
	end


	-- camera tracking
	local follow_pos=player.pos+player.vel*20 + vec2_normalized(player.prev_input_dir*2 + vec2_right*(tonum(player.is_right)*2-1))*20
	
	--local cam_tol=16
	-- move camera to player
	
	-- separate x & y
	local distance = vec2_new(
		follow_pos.x-camera_x-64,
		follow_pos.y-camera_y-64
	)
	local speed=prev_cam_speed*0.85 + distance/24*0.15
	
	--if abs(distance.x) > cam_tol then
	camera_x+=speed.x\1
	--end
	camera_y+=speed.y\1
	
	camera_x = mid(-64,camera_x,512)
	camera_y = mid(-64,camera_y,128)
	
	prev_cam_speed=speed
end
 
function _draw()
	cls(9)
	camera(camera_x, camera_y)
	
	draw_loaded_bgs()

	draw_fall_zone(255)

 draw_map()
	draw_entities()
	draw_links()
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
	if (type(a) == "TABLE") return unpack(a)
	return a
end

function chain_call(f,args)
	local res = {}
	for i=1, #args do
		add(res,f(unpack_myb(args[i])))
	end
	return res
end

function bcheck(v,b)
	return v & b != 0
end

-->8
-- entity managment

mod_tabl(_ENV, "entities,max_entities,entity_id_stack/{},256,{}")

for i=1,max_entities do
	add(entity_id_stack,max_entities+1-i)
end

function take_id()
	return deli(entity_id_stack)
end

function give_id_back(id)
	add(entity_id_stack,id)
end

--physical "ropes" connecting entities
all_links={} -- contains all of them
entity_links={} -- this one works as a set where key is entity's id
-- and value is a list of links (also keyed by id other's id) (both ways are recorded) 
-- each pair can only have 1 link
for i=1,max_entities do
	add(entity_links,{})
end

--these tick down every update until 0
entity_timers={}
for i=1,max_entities do
	add(entity_timers,{})
end

function set_timer(e,n,v)
	entity_timers[e.id][n] = v 
end

function get_timer(e,n)
	return entity_timers[e.id][n] or 0
end

function spawn_entity(px,py,m,r,e_typ)
 local ntt={
  id=take_id(),
		pos=vec2_new(px, py),
  vel=vec2_new(0,0),
		mass=m or 1,
		-- half of square edge len
 	rds=r or 0.5,
		e_type = e_typ or "none"
		}

		--test whether is standing on or touching something
		mod_tabl(ntt, "is_stnd,stnd_on_trn,stnd_on,is_tch,tch_trn,tch/false,false,nil,false,false,nil")
		mod_tabl(ntt, "coll_mask_on,coll_mask_see/0b00000001,0b00001111")
		--coll_mask_on:  those who see one of these layers will detect this entity 
		--coll_mask_see: detects those on these layers	
 
	-- point to self when asked who moves
	ntt.update_func,ntt.draw_func,ntt.all_ntts=move_entity,draw_entity,{ntt} 
 return ntt
end

function remove_listed_entity(e)
	foreach(e.all_ntts, cleanup_entity)
	del(entities, e)
end

function cleanup_entity(e)
	for to_entity_id,link in pairs(entity_links[e.id]) do		
		delete_link(link)
	end
	
	give_id_back(e.id)
end

ntt_b_types = {
{0.6,1,{split"8.7,l,0.015,7,tru",split"5,a,0.02,15",split"8.7,l,-0.015,12,tru",split"5,a,-0.02,13"}},
{1,4,{split"10,l,0,14"}},
{1,4,{split"10,l,0,5"},{split"10,l,0.3,5"},{split"10,l,0.6,5"}},
{},
{},
{}

}

function spawn_complex(px,py, props, c_on,c_see)
	local e = spawn_entity(px,py,props[1],props[2])
	
	e.leg_facing,e.facing,e.surface_away = v2c(vec2_down),v2c(vec2_up),v2c(vec2_up)

	mod_tabl(e,"e_type,is_right,grounded_mode,ground_is_entity,ground_pos_entity,walking,crouch/humanoid,true,false,false,nil,false,false")
	mod_tabl(e,"stmn,prev_stmn,stmn_l_b,stmn_l_t/1.0,1.0,0.5,1.0")

	
	--subentity mappings. moving them in bulk is a lot easier
	e.all_ntts = {e}
	e.m_l_legs = {cd=0} -- cooldown for movement
 e.l_angles = {}
 e.m_l_arms = {cd=0}
 e.a_angles = {}
	
	e.total_mass=e.mass
	
	for limb in all(props[3]) do
		local l_e = spawn_entity(px,py,0.1,0.1)
		
		l_e.t_pos = l_e.pos
		l_e.t_active = false
		
		add(e.all_ntts, l_e)
		e.total_mass+=0.1
			
		if limb[2]=="l" then
			add(e.m_l_legs, l_e)
			add(e.l_angles, limb[3])
		else
			add(e.m_l_arms, l_e)
			add(e.a_angles, limb[3])
		end
		local l_draw = 2
		if (limb[5] == "tru") l_draw = 3
	 
		local l_link = make_link(e,l_e,1,limb[1],false,0, l_draw,limb[4], e)
		l_link.true_len = limb[1]
	end
	
	local function set_coll(e)
		--doesn't collide with other parts
		e.coll_mask_on=c_on
		e.coll_mask_see=c_see
	end
	

	foreach(e.all_ntts, set_coll)


	e.update_func,e.draw_func = move_humanoid,draw_humanoid
 return e
end


function spawn_player(px,py)
	
 local player_l = spawn_complex(px,py,ntt_b_types[1],0b00000010,0b00001101)
	player_l.col = 13
	--grabbing
	mod_tabl(player_l,"in_grab,grabbed_e,grabbed_coll_on,grabbed_coll_see/false,nil,0b00000000,0b00000000")
	player_l.update_func = update_player

	return player_l
end


function make_link(e1, e2, link_type, link_len, to_ground, link_strenght, draw_type, col, ref_e)

	local t_t_g = to_ground or false

	local link = {
		from = e1,
		to = e2,
		l_type = link_type, -- 0-keep at exact distance, 1-limit max distance, 2-limit min
	 len = link_len,
		to_ground = t_t_g,
		strenght = link_strenght or 0, -- 0 means unbreakable
		draw_type = draw_type or 0, -- 0-invis,1-normal,2-joint,3-leg joint (draw torso as well)
		col = col or 14,
		ref_e = ref_e or nil -- used when drawing joints
	}
	
	local e1_id,e2_id=e1.id,e2.id
	if (t_t_g) e2_id=-1

	entity_links[e1_id][e2_id]=link
	
	-- no need for second link entry if it's to ground
		-- this one will have a reversed direction so checks may be needed
	if (not t_t_g) entity_links[e2_id][e1_id]=link
		
	add(all_links, link)	
	return link
	
end

function delete_link(l)

	local e1 = l.from

	if l.to_ground then -- delete ground link
		entity_links[e1.id][-1] = nil
	else
		local e2 = l.to
		entity_links[e1.id][e2.id] = nil
		entity_links[e2.id][e1.id] = nil
	end
	
	del(all_links,l)
end

-->8
-- drawing

l_bg_timescrolls=split"0,1,2,6,15,30,60,90,150,-1,-2,-6,-15,-30,-60,-90"

function draw_bg(offset) 
	pal(lvl_pal2, 0)
	
	local function h(i) return loaded_level[1][i+offset] end
	
	local len_x,len_y,p_sc = 8,4, h(8)*8+8
	local scrl,ts = (h(7)/12)^2, vec2_rotate(vec2_up, h(14)/16)*l_bg_timescrolls[h(13)+1]
	local wrap_x,wrap_y = h(9)!=0, h(10)!=0
	
	local scroll_x = -(h(11)*16 -128)+camera_x*scrl+time()*ts.x
	local scroll_y = -(h(12)*16 -128)+camera_y*scrl+time()*ts.y
	
	if(wrap_x) scroll_x %=len_x*p_sc
	if(wrap_y) scroll_y %=len_y*p_sc

	local function map_scaled(ox,oy)
		for	i=0,len_x-1 do
			for	j=0,len_y-1 do
			 local n = mget0x20(h(6)*8+i, j)
				sspr((n&0b1111)*8,n\16*8,8,8, camera_x-scroll_x+i*p_sc+ox, camera_y-scroll_y+j*p_sc+oy,p_sc,p_sc)
			end
		end
	end
	
	map_scaled(0,0)
	
	-- todo maybe work if bg is smaller than screen
	if (wrap_x) map_scaled(len_x*p_sc,0)
	if (wrap_y) map_scaled(0,len_y*p_sc)
	if (wrap_x and wrap_y) map_scaled(len_x*p_sc,len_y*p_sc)


	pal(0)
end



function draw_loaded_bgs()
	draw_bg(0)
	draw_bg(9)
end

function draw_fall_zone(height)
local function f(y)
	line(-256,height-y,4096,height-y,2)
end
	f(0)
	f(1)
	f(3)
	f(5)
end

function draw_map()
	map(0,0,0,0,128,32)
end

function spr_outl(n,x,y, col)
	local pal_o = {}
	
	for i=1,16 do
		add(pal_o,col)
	end
	
	pal(pal_o,0)
		spr(n,x-1,y)
		spr(n,x+1,y)
		spr(n,x,y+1)
		spr(n,x,y-1)
	pal(0)

	spr(n,x,y)
end

function draw_entities()
	for ntt in all(entities) do
		ntt.draw_func(ntt)
	end
end

function draw_entity(entity)

	local ep,r=entity.pos,entity.rds
	
	if entity.sprite != nil then
		local e_spr_pos = ep - vec2_new(3.5,3.5)
		spr(entity.sprite, e_spr_pos.x, e_spr_pos.y)
	else

		rectfill(ep.x-r, ep.y-r, ep.x+r, ep.y+r,entity.col or 7)
	end
	

	if debug_visuals then
		local d_col = 4

		if entity.is_stnd then
			d_col = 12
			if (entity.stnd_on_trn) d_col = 11
		end
		
		local p = entity.pos+entity.vel
		circ(p.x, p.y, entity.rds/2,d_col)	
	end
end

function draw_enm(enm)
	local e_spr_pos = enm.pos - vec2_new(3.5,3.5)
	spr_outl(enm.sprite, e_spr_pos.x, e_spr_pos.y,14)
	
end

function draw_links()
	for link in all(all_links) do
		draw_link(link)
	end
end

function draw_link(link)


	local p1,p2,r=link.from.pos, link.to.pos,false
	if (link.to_ground) p2 = link.to
	
	if (link.ref_e != nil) r = link.ref_e.is_right
	
	if link.draw_type == 1 then
		line_vec(p1, p2, link.col)
	elseif link.draw_type == 2 then
		draw_joint(p1, p2, link.len/2, link.col, not r)
		
	elseif link.draw_type == 3 then
		local pos_2 = p1 + link.ref_e.leg_facing*3
		line_vec(p1, pos_2, link.ref_e.col or 13)
		draw_joint(pos_2, p2, (8.7 - 3)/2, link.col, r)
	end
end

-- assumes both have same radius
function circ_intersect(p1,p2,r)

	local d,mid_p=vec2_len(p2-p1),(p1+p2)/2 

	local op=(p2-p1)*sqrt(r*r-d*d/4)/d
	
	local op2=vec2_new(op.y,-op.x)
	local m1,m2=mid_p+op2,mid_p-op2
	
	return m1, m2
end

function line_vec(v1,v2,col) 
	col_t=col or 1
	line(v1.x,v1.y,v2.x,v2.y,col)
end

function draw_joint(p1,p2,rds,col,is_right)
	if p1 != p2 then
		local k_2, k = circ_intersect(p1,p2,rds)
		
		if (is_right) k=k_2
		
		line_vec(p1,k,col)
		line_vec(k,p2,col)
	end
end

function spr_1bit(n,b_ind,col,x,y,w,h,f_x,f_y)
		for j=0, h-1 do
			for i=0, w-1 do 
	
				if sget(n%8*8+i,n\8*4+j) & 1<<b_ind != 0 then
					local dx,dy = x+i,y+j
					if (f_x) dx = x+w-1-i
					if (f_y) dy = y+h-1-j
					pset(dx,dy, col)
				end
				
			end
		end
end

function draw_humanoid(ntt)
	
	--pset(ntt.la.pos.x,ntt.la.pos.y, 15)

	--head
	local head_pos_sprite=ntt.pos+vec2_normalized(ntt.facing)*2 +vec2_new(-4,-4)	
	local flip_r,flip_u=not ntt.is_right,false
	
	if (not btn(4) and flip_r and btn(1)) flip_r = not flip_r
	if (not btn(4) and not flip_r and btn(0)) flip_r = not flip_r
	
	if vec2_normalized(ntt.facing).y > 0.7 then
		flip_u = true
		flip_r = not flip_r
	end
	
	if (flip_r == false) head_pos_sprite.x += 1
	spr(128, head_pos_sprite.x, head_pos_sprite.y, 1, 1, flip_r, flip_u)
	
	--eyes
	
	local e_p_s = head_pos_sprite
	if (btn(3)) e_p_s.y += 1
	
	local spr_i,e_c = 0,12
	if (vec2_len(ntt.vel) > 4) spr_i = 1
	
	local dmg = ntt.prev_stmn - ntt.stmn
	local hurt_tmr = get_timer(ntt, "hurt")
	
	if (dmg*100 > hurt_tmr) set_timer(ntt, "hurt", dmg*100)
	
	if hurt_tmr > 20 then
		spr_i = 2
		e_c = 7
	elseif hurt_tmr > 10 then
		e_p_s.y = head_pos_sprite.y+1
	end
	
	if anim_c%(55 + ntt.id) > 3 or vec2_len(ntt.vel) > 0.5 then
		spr_1bit(129, spr_i, e_c, e_p_s.x, e_p_s.y, 8, 8, flip_r, flip_u)
	end
	
	ntt.prev_stmn=ntt.stmn
	
	--pset(ntt.ra.pos.x,ntt.ra.pos.y, 15)
	
	
	if debug_visuals then
		
		for ntt in e.all_ntts do
			if (ntt.t_active or ntt.t_locked) circ(ntt.t_pos.x,ntt.t_pos.y, 2, 14)
		end

	end


end

function draw_ui()

	local function ui_line(x1,xlen,y,col1,col2)
		line(camera_x+x1,camera_y+y,camera_x+x1+xlen  ,camera_y+y,col2)
		line(camera_x+x1,camera_y+y,camera_x+x1+xlen-1,camera_y+y,col1)
	end

	for i=1, 5 do
		ui_line(3,82,i,0,0)
	end

	for i=2, 4 do
		ui_line(4,80*(player.stmn + get_timer(player,"hurt")/100),i,12)
		ui_line(4,80*player.stmn,i,13,12)
		ui_line(4,80*player.stmn_l_b,i,1,15)
	end

end

-->8
-- sounds

mus_p = true
mus_layer = false

function update_mus()
	if(stat(50) == 31 and mus_p) then
		printh("Ok")
		
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
-- helper functions

function apply_vel(e,v)
 e.vel+=v
end

function apply_momentum(e, m)
	e.vel+=m/e.mass
end

function counter_mmnt(m, e1, e2)
	apply_momentum(e1,m)
	apply_momentum(e2,-m)
end

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
	local tmp, v1_c, v2_c
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

-- slightly modified foreach that works with more params
-- and also gives function's results in a table
function foreach_in_do(list, do_function, ...)
	local results = {}
	if list != nil then
		for i=1, #list do
			add(results, do_function(list[i], ...))
		end
	end
	return results
end

-->8
-- terrain & collisions

function point_trn_coll(point)
	return fget(mget(point.x/8,point.y/8),0) -- solid tile
end


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
	point_max,point_min = point+vec2_new(rds,rds),point-vec2_new(rds,rds)

	-- go over all tiles in rectangle range
	for j=point_min.y\8,point_max.y\8 do
		for i=point_min.x\8,point_max.x\8 do
			
			if fget(mget(i,j),0) then -- solid tile
				-- test coll
				local p2 = vec2_new(i*8+4,j*8+4)
				local did, normal = sq_sq_coll(point, rds, p2, 4)
				
				if (did) return did, p2, normal
			end
			
		end
	end
	
	return false
end

function check_coll_ntts(ntt, pos, rds)
	local p_t,r_t = pos or ntt.pos, rds or ntt.rds

	-- ultra slow with lots of primary entities - limit is about 15
	-- todo maybe do grid cell separation table
	for other in all(entities) do
		if other.id != ntt.id and (ntt.coll_mask_see & other.coll_mask_on != 0) then
			local did, normal, dist = sq_sq_coll(p_t, r_t, other.pos, other.rds)
			
			if (did) return true, other, normal, dist
		end
	end
	return false, nil	
end


function tile_to_entity(tile_pos)
	local tpx, tpy = tile_pos.x, tile_pos.y
	local t_dat,t_set = mget(tpx, tpy),0
	-- todo different masses?
	local mass = 0.4

	-- fill bg: insert most common bg tile in <^>
	local chosen = false
	local t_l,t_u,t_r = mget(tpx-1, tpy),mget(tpx, tpy-1),mget(tpx+1, tpy)
	
	if (fget(t_l) & 0b11 == 0) t_set = t_l
	if fget(t_u) & 0b11 == 0 then
		t_set = t_u
		if (t_l == t_u) chosen = true
	end
	if (fget(t_r) & 0b11 == 0 and not chosen) t_set = t_r

	
	mset(tpx, tpy, t_set)

	local t_e = spawn_entity(tpx*8+4,tpy*8+4,mass,3.7)
	t_e.sprite = t_dat
	t_e.e_type = "tile"
	
	add(entities, t_e)
	return t_e
end


function entity_to_tile(e)
	mset(e.pos.x\8, e.pos.y\8, e.sprite)
	remove_listed_entity(e)
end


function in_tbl(element, table)
  for key, value in pairs(table) do
    if (value == element) return true
  end
  return false
end



-->8
-- movement

function is_oob(pos)
	return 
			pos.x < b_lmt_x or
			pos.x > t_lmt_x or
			pos.y < b_lmt_y or
			pos.y > t_lmt_y
end

-- NO TERRAIN CLIPPING 

function unclip(entity,pos,rds)
	local pos_t, rds_t = pos or entity.pos, rds or entity.rds

	local coll_t, t_pos = sq_trn_coll(pos_t, rds_t)
	
	if coll_t then
	
		local vec_rep = {vec2_up, vec2_down, vec2_left, vec2_right,
			vec2_up + vec2_left, vec2_up + vec2_right, vec2_down + vec2_left, vec2_down + vec2_right}

		for i=1, 10 do
			for v in all(vec_rep) do 
			
				local m_v = v*i*0.98
				if (not sq_trn_coll(pos_t + m_v, rds_t)) return true, true, true, m_v, t_pos -- out now - ignore entities
			end
		end
		return true, true, false, vec2_zero, t_pos
		
	else
	
		local coll_e, e, norm, dist = check_coll_ntts(entity, pos_t, rds_t)
		
		if coll_e then
			local m_v = norm * dist
		
			if (not sq_trn_coll(pos_t + m_v, rds_t) and not check_coll_ntts(entity, pos_t + m_v, rds_t)) return true, false, true, m_v, e
			
			return true, false, false, m_v, e
		end
	end
	
	return false
end

function move_and_unclip(entity, move_vec)

	local did_m = false
	-- prevent micromovements
	if vec2_len(move_vec) > 0.01 then
		MAC_per_frame += 1
		
		-- apply movement
		entity.pos += move_vec
		did_m = true
	end
		
	-- clip out
	local clip,with_t,out,dir,coll_t_e = unclip(entity)
	if clip and out then
		entity.pos += dir
	end

	return did_m, clip,with_t,out,dir,coll_t_e
end



function update_touch(entity, rds)

	local r = rds or entity.rds+1
	
	local coll_t, t_point = sq_trn_coll(entity.pos, r)
	local coll_e, e = check_coll_ntts(entity, nil, r)
	
	entity.is_tch = coll_t or coll_e
	entity.tch_trn = coll_t
	entity.tch = e
		
 if (coll_t) entity.tch = t_point

	
	return entity.is_tch, entity.tch_trn, entity.tch
	
end

function update_stand(entity, do_entities, override_vel)
	
	-- clear standing
	-- but not if not checking entities and ntt standing
	if (do_entities or entity.stnd_on_trn) entity.is_stnd = false

	local down_pos = entity.pos + vec2_down*1
	
	local function g_stand()
		entity.is_stnd = true -- ground stand
		entity.stnd_on_trn = true
	end
	
	local function e_stand(e)
		entity.is_stnd = true -- entity stand
		entity.stnd_on_trn = false
		entity.stnd_on = e
	end
	
	-- if not in bounce
	if abs(entity.vel.y) < (override_vel or 0.5) then
	
		-- first check terrain
		if sq_trn_coll(down_pos, entity.rds) then
			g_stand()
			return
		end
		
		if do_entities then
		
		-- then entity below
			local touch_e, e = check_coll_ntts(entity, down_pos)
			
			if touch_e and e.is_stnd then -- if standing on a stable entity
				e_stand(e)
				return
			end
			

			-- then linked entities
			if vec2_len(entity.vel) < 0.15 then
				for to_id, link in pairs(entity_links[entity.id]) do
					if link.to_ground then
						g_stand()
						return
					else
						local other = link.to
						if (other == entity) other = link.from
						if other.is_stnd then
							e_stand(other)
							return
						end
					end

				end
				
			end
		

		-- legs give special stand property

		end

	end
	
	
end

function trn_impact(t,impct)
	local t2 = t\8
	-- break grabbables or any non-bedrock tiles if strong enough
	local tile = mget(t2.x, t2.y)
	if (impct > 1.4 and fget(tile,1)) or (impct > 15 and fget(tile,0) and t2.y != 31) then
		local t_e = tile_to_entity(t2)
		return true, t_e
	end
	return false
end


function dampen_vel(ntt, factor, support_e)
	counter_mmnt(-ntt.vel*factor*ntt.mass, ntt, support_e)
end

function move_entity(entity)

	-- move
	local did_m, did_c, with_t, out, surface_dir, coll_t_e = move_and_unclip(entity, entity.vel)
	
	if (not did_m) entity.vel *= 0
	
	if did_c then
		printh("coll!")
	
		if out then
			-- todo trigger coll events for entities
			local prev_e = vec2_len(entity.vel)^2 * entity.mass
			
			
			-- if broke terrain
			if with_t then
				local brk, new_e = trn_impact(coll_t_e, vec2_len(projection(entity.vel, surface_dir))^2 *entity.mass)
				if (brk) with_t,coll_t_e=false,new_e
			end
			
			-- bounce
			if with_t then
				entity.vel = recomp_mul(entity.vel, surface_dir, -trn_bnc, trn_slp)
			else
				transfer_momentum(entity, coll_t_e, 0.8, 1, true)
			end
			
		
			
			local impact, pl_hit = abs(prev_e - vec2_len(entity.vel)^2  *entity.mass), true

			if entity==player then 
				impact *= 1.4
			elseif in_tbl(entity, player.m_l_arms) then
				impact *= 0.1
			elseif in_tbl(entity, player.m_l_legs) then
				impact *= 1.0
			else
				pl_hit = false
			end
			
			if (pl_hit and impact > 1.5) player.stmn -= impact*0.02
			
			local e_p = entity.pos
			if impact > 8 then
				sp_sfx(15, e_p)
			elseif impact > 3.5 then
				sp_sfx(14, e_p)
			elseif impact > 1.1 then
				sp_sfx(13, e_p)
			end
			
			
	 else
			printh("sus")
			entity.vel *= 0
			if with_t then
				entity.pos.y -= 1
			else
				entity.pos += vec2_normalized(entity.pos - coll_t_e.pos)
			end
		end
		
	end
	
	update_stand(entity, true)
	update_touch(entity)
	
	
	local function check_stand_chain(entity, rem_depth)
		-- either invalid stand or too far
		if (rem_depth <= 0) return false

		if (entity.special_stand) return true

		if entity.is_stnd then
			if (entity.stnd_on_trn) return true
			return check_stand_chain(entity.stnd_on, rem_depth-1)
		end
		
		return false
	end
	
	if (not check_stand_chain(entity, 5)) entity.is_stnd = false
	
	--fall
	if entity.is_stnd then
  local slip = trn_slp
		if (not entity.stnd_on_trn) slip = entity.stnd_on.slipperiness or 0.5

		entity.vel.y = 0
	 entity.vel.x *= 0.8 + slip*0.2 --ground/ntt friction
 elseif not entity.special_stand then
		entity.vel.y += grav
		entity.vel *= 0.998 --air friction
	end

	-- prevent micromovements
	if (vec2_len(entity.vel) < 0.09) entity.vel *= 0

end

-- called when an entity is outside its link range
function tug(link)

	local e1,e2 = link.from, link.to
	e1m = e1.mass
	local e2_pos = e2.pos
	if (link.to_ground) e2_pos = e2
	
	local diff = e2_pos - e1.pos
	
	local move_dist = vec2_len(diff) - link.len
	
	-- the amount that the entities need to move so they stay in proper link range
	local move_need = vec2_normalized(diff) * move_dist
	
	
	-- todo fix (links of type 1/2 will break even if ok ykwim)
	-- break if too far
	local do_move = false
	
	if link.l_type & 0b10 == 0 then
		if (move_dist > 0.6) do_move = true
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
		tugs_per_frame += 1

		if link.to_ground then
			e1.pos += move_need
			-- remove vel component towards ground
			e1.vel = recomp_mul(e1.vel, e1.pos - e2_pos, 0, 1)
		else
			--printh(e1.id .. " tugs " .. e2.id)

			local e2m = e2.mass
			-- move proportionally and equalize velocities

			-- the amount each entity needs to move
			local m_total = e1m+e2m
			local move_1,move_2 = move_need*e2m/m_total, move_need*e1m/m_total -- == move_need/(e2m/e1m)
			
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

	-- almost a raycast
	local function try_find(vec, rds)
		local out
		local vec_rep = {vec,vec + vec2_right*p1_st_rng*0.48,vec + vec2_left*p1_st_rng*0.48}
		for vec in all(vec_rep) do
			for j=1, 4 do 
				local t_vec = vec * j/4
				
				local coll_land,with_t,out,away_vector,other_t_ntt = unclip(entity, entity.pos + t_vec, rds)
				if (coll_land and out) return true, t_vec, with_t, away_vector, other_t_ntt
				
			end
		end
		return false
	end


			-- where is landing point
	local stand_vec = vec2_normalized(entity.leg_facing + vec2_new(entity.vel.x*0.3,0))*p1_st_rng	

	local max_dist = -1
	local max_index = 0
	
	local stand_centers = {}
		
	-- move target with highest distance to optimal target position
	for j=1, #ntt_group do
		local ntt = ntt_group[j]

		ntt.t_active = false
		if get_timer(entity,"jump_cooldown") <= 0 then
		
			local did, t_vec, with_t, away_vector, other_t_ntt = try_find(vec2_rotate(stand_vec,t_angles[j]), entity.m_l_legs[1].rds)
			
			if did then
				stand_centers[j] = entity.pos + t_vec + away_vector
				
				entity.grounded_mode,entity.surface_away,entity.ground_is_entity,entity.ground_pos_entity = 
				true,vec2_normalized(away_vector),not with_t, other_t_ntt

	
				local dist = vec2_len(ntt.t_pos - stand_centers[j])
				
				if dist > max_dist then
					max_dist = dist
					max_index = j
				end
				
				if (dist <= entity.tol) ntt.t_active = true
				
			end	
			
		end -- of jump cooldown check
		
	end 
	
	-- only if not on cooldown and if outside tolerance range
	if ntt_group.cd <= 0 then		
		if max_dist > entity.tol then
			ntt_group[max_index].t_pos = stand_centers[max_index]
			ntt_group[max_index].t_active = true
			ntt_group.cd = 3
		end
	else 
		ntt_group.cd -= 1
	end
	
	
end


function move_towards(ntt, target_pos, speed, tol, support_e)
	local pos1 = v2c(ntt.pos)
	local at_t = false
	local dist = target_pos - ntt.pos
	
	if vec2_len(dist) > tol then
		move_and_unclip(ntt, vec2_limit((target_pos- ntt.pos)/speed)*speed)
	else
		ntt.pos = target_pos
		at_t = true
	end
	
	if support_e != nil then
		move_and_unclip(support_e, (pos1 - ntt.pos) /support_e.mass*ntt.mass)
	end
	
	return at_t
end

function move_humanoid(entity)
	
	foreach(entity.all_ntts, move_entity) -- moves comps separately
	
	entity.special_stand = false

local hurt_tmr = get_timer(entity,"hurt")
if (hurt_tmr > 20) return
	
	-- leg move parameters
	local stnd_height,leg_speed =
		 unstr"7.5,3"
	entity.tol = 2.5		
	
 -- preferred offset from center, in pico8 degrees
	-- offset tolerance	
	
	if entity.walking and not entity.crouch then
		stnd_height,leg_speed, entity.tol =
		 unstr"7,5,5"
	end


	-- defaults - no leg support	
	mod_tabl(entity, "grounded_mode,ground_is_entity,ground_pos_entity/false,false,nil")
	
	update_targets(entity, entity.m_l_legs, entity.l_angles)
	

	
	if entity.grounded_mode then
	-- try to stand

		-- move legs to targets
		for leg in all(entity.m_l_legs) do

			if vec2_len(entity.vel) < 5 then
				if leg.t_active then

					if (move_towards(leg,leg.t_pos, leg_speed, 2, entity)) then
						leg.vel *= 0.98
					end

				end
				update_stand(leg, false, 3.0)
				if (leg.is_stnd) entity.special_stand = true
				
			end
		end
	end

	
	if entity.special_stand then -- really is standing (or about to hit ground)
		
		--custom friction
		entity.vel *= 0.83

		-- transfer keep percent
		local t_v1 = 0.92

		if abs(entity.vel.y) < 2.4 then
			if not entity.walking then
				entity.vel *= 0.80
				entity.vel.x *= 0.60
			end
			t_v1 = 0.85
		end
			
			
		-- stabilise pos
		
		local stand_p_lh = vec2_zero
		for l in all(entity.m_l_legs) do
			stand_p_lh += l.pos
		end
		stand_p_lh /= #entity.m_l_legs
		
		 stand_p_lh += entity.surface_away*(stnd_height)
		
		if entity.crouch then
			stand_p_lh -= entity.surface_away * 4
		else
			stand_p_lh += entity.surface_away * ((anim_c\48)%2)
		end

		entity.pos.y = entity.pos.y*t_v1 + stand_p_lh.y*(1-t_v1)
		
		
		local function stabl_arm(arm,angl)
			if arm.is_stnd and not entity.armgrab then
				arm.vel *= 0
				local d_vec = vec2_rotate(vec2_down*(entity_links[arm.id][entity.id].len - 0.5*tonum(entity.crouch)), angl * (1-2*tonum(entity.is_right))*(1+4*tonum(entity.crouch)))
				arm.pos = (entity.pos+d_vec)
			end
		end
		
		for i=1, #entity.m_l_arms do
			stabl_arm(entity.m_l_arms[i], entity.a_angles[i])
		end
		
	-- wallstand
	--elseif ntt_rl.is_tch or ntt_ll.is_tch then
	--	entity.vel *= 0.95
	end -- of leg stand check


end





function update_player(player, b_bfield)


	move_humanoid(player)
	
	
	if (get_timer(player, "hurt") >= 20) return
	
	local b_bfield = btn()

	local function bcheck2(b)
		return b_bfield & b != 0
	end

	local b0,b1,b2,b3,b4,b5 = unpack(chain_call(bcheck2,split"0b1,0b10,0b100,0b1000,0b10000,0b100000"))
	local b0i,b1i,b2i,b3i,b4i,b5i = unpack(chain_call(tonum,{b0,b1,b2,b3,b4,b5}))

	-- controls
	
	local v_x,v_y = 0,0
	
	local input_dir =	vec2_left  * b0i
																	+ vec2_right * b1i
																	+ vec2_up    * b2i
																	+ vec2_down  * b3i
	
	local input_dir_l = vec2_limit(input_dir)
	local input_dir_j = vec2_normalized(vec2_up*0.2 + input_dir)
	local input_dir_h = vec2_normalized(input_dir_l + vec2_right*(tonum(player.is_right)*2-1)*0.2)
		
	local hold_pos = player.pos + input_dir_h*5

	
	player.prev_input_dir = input_dir
	

	player.crouch = b3


	local jump_cooldown = get_timer(player, "jump_cooldown")


	-- regen stamina
	if (player.stmn < player.stmn_l_t) player.stmn += 0x0.008
	
	local jump_s = false
	
	
	-- grabbing -----------------------------------

	player.armgrab,player.on_ladder = false, false
	
	local hold_str,throw_str = 0.15,1.5
	
	for arm in all(player.m_l_arms) do
	
		if vec2_len(arm.t_pos - player.pos) > 9 then
			arm.t_locked = false	
			arm.t_ladder = false
		end
		arm.mass = 0.1
		
		if b5 then
			player.armgrab = true
			
			if (not arm.t_locked) then
				arm.t_pos = hold_pos
				arm.t_ladder = false
			end
		
			local on_ladder = fget(mget(hold_pos.x\8, hold_pos.y\8), 2)
		
			-- figure out grab targets
			if (on_ladder and vec2_len(player.vel) < 4.5) and get_timer(player, "l_grab_cooldown") <= 0 then
				
				
				if not arm.t_locked or (vec2_len(arm.t_pos - hold_pos) > 4 and vec2_len(player.vel) < 1.2 and vec2_len(input_dir) > 0) then
					
					arm.t_locked = true
					arm.t_ladder = true
					arm.t_pos = hold_pos
					
					local c=3
					if player.long_l_g_c then
						player.vel *= 0.9
						c = 15
						player.long_l_g_c = false
					end
					
					set_timer(player, "l_grab_cooldown", c)

				end
			elseif arm.is_tch then
				if not arm.t_locked then
					arm.t_locked = true
					arm.t_pos = arm.pos
				end
			end
			
			
			arm.vel *= 0.95
			if (player.grounded_mode) arm.vel *= 0.9
		
			-- move arm
			move_towards(arm,arm.t_pos, 3, 2)

			-- slowdown if grabbing
			if jump_cooldown <= 0 then
			
				if arm.t_ladder then
						player.on_ladder = true
						arm.vel *= 0.4
						
						v_x += 0.1
						v_y += 0.2
						
						if get_timer(player, "l_grab_cooldown") > 3 then
							v_x += 0.125
							v_y += 0.125
						end
						
						jump_s = true
						
						arm.mass = 1.1
				else
				
					if arm.is_stnd then
						arm.mass = 0.3
						arm.vel *= trn_slp

						v_x += 0.15
						v_y += 0.25

					end
					if arm.is_tch then
						arm.vel *= 0.8 + trn_slp*0.2
						
						player.vel *= trn_slp*0.05 + 1*0.95
					end
					


				end
			end

			
			if not player.in_grab then
				if arm.is_tch and not arm.tch_trn then
						if arm.tch.mass < 3 and arm.tch.rds < 10 and not player.in_grab then
							player.in_grab = true
						end
						
				else
				
					local g_pos = arm.pos
					if (arm.is_tch) g_pos = arm.tch
					
					if fget(mget(g_pos.x\8, g_pos.y\8),1) then --grabbable
						-- convert tile to entity
						local t_e = tile_to_entity(g_pos\8)
						player.in_grab = true
						arm.tch_trn = false
						arm.tch = t_e
					end
					
				end
				
				if player.in_grab then -- take the thing
					sfx(20)
					local grab_e = arm.tch
					player.grabbed_e = grab_e
					player.grabbed_coll_on = grab_e.coll_mask_on
					player.grabbed_coll_see = grab_e.coll_mask_see
					
					-- assumes all of subentities have same coll
					for nt in all(grab_e.all_ntts) do
						nt.coll_mask_on = player.coll_mask_on
						nt.coll_mask_see = player.coll_mask_see
					end
					
					make_link(player,grab_e,1,4,false,0)
				end
			end
		

			
			-- rotate grabbed object
			if player.in_grab then
			
				local grab_e = player.grabbed_e
				local diff_l = vec2_limit(hold_pos - grab_e.pos)
				local mmnt = diff_l * hold_str
				counter_mmnt(mmnt, grab_e, player)
				
				--grab_e.vel = grab_e.vel*0.8 + player.vel*0.2
			end	
		else
			--throw if holding, else nothing
		
			if player.in_grab then
				local grab_e = player.grabbed_e
				player.in_grab = false
				if vec2_len(input_dir) <= 0 then
					sfx(21)
				else
					sfx(22)
					-- extra move so doesn't immediately clip in player
					move_and_unclip(grab_e, input_dir_l * 10)
					local throw_vel = throw_str
					throw_vel = min(throw_vel/grab_e.mass, 3)
					counter_mmnt(input_dir_l * throw_vel*grab_e.mass, grab_e, player)
				end
				
				for nt in all(grab_e.all_ntts) do
					nt.coll_mask_on = player.grabbed_coll_on
					nt.coll_mask_see = player.grabbed_coll_see
				end

				player.grabbed_e = nil
				delete_link(entity_links[player.id][grab_e.id])
			end
		
			-- ungrab
			arm.t_ladder = false
			arm.t_locked = false
		end -- of btn5 check
		
	end -- of for
		
	

	
	-- walking/air move -----------------------------------

	local vel_limit = p1_h_a_spd_lmt
	
	if player.grounded_mode and player.surface_away.y != 0 then 
		v_x += 0.7 - 0.3*tonum(b3) -- movement
		vel_limit = p1_h_g_spd_lmt
	else -- air drift
		v_x += 0.05
		if (player.on_ladder) vel_limit *= 2
	end
	
	player.walking = player.grounded_mode and	(b0 or b1)
	if player.grounded_mode then
		if (b0) player.is_right = false 
		if (b1) player.is_right = true
	end
	
	if (player.crouch) vel_limit /= 2

	local pv_add = vec2_new(
		v_x*b1i - v_x*b0i,
		v_y*b3i - v_y*b2i
	)
	
	if vec2_len(player.vel + pv_add) <= vec2_len(player.vel) or vec2_len(player.vel) <= vel_limit then
		player.vel += pv_add
	end
	
	
	-- jumping -----------------------------------
	
	local surface_normal = player.surface_away
	-- jump control
	local input_dir_j2 = input_dir_j
	input_dir_j2.y *= 2
	
	local jump_g = false
	
	for l in all(player.m_l_legs) do
		if vec2_len(l.pos - l.t_pos) < 3 then
			jump_g = true
			break
		end
	end
	
		
		jump_g = jump_g
		-- no downjumps and sidejumps
		and not (surface_normal.y < 0 and (input_dir_j2.y > 0.0 or player.leg_facing.y < 0.3) )
		-- or upjumps from ceilings cause that's possible apparently
		and vec2_dot(input_dir_j2, surface_normal) >= -0.02
		-- and no jump clutches
		and (vec2_len(projection(player.vel,surface_normal)) < 2 or vec2_dot(player.vel, input_dir_j2) >= 0)
	

	
	if b4 and (jump_g or jump_s) and jump_cooldown <= 0 then
	
		local jump_str = p1_jump
		
		if jump_g then
		
			player.stmn -= 0x0.05
			
			-- small speed reduction if slamming
			local b_mul = 0.1
			if (vec2_dot(player.vel, input_dir_j2) > 0) b_mul = 0.8
			
				-- away from surface
			input_dir_j2 += surface_normal*0.2
			

			local s2 = surface_normal + input_dir_j2
			-- decomponentize
			player.vel, pv_1, pv_2 = recomp_mul(player.vel, input_dir_j2, b_mul, 0.4)
			for l in all(player.m_l_legs) do
				l.vel = recomp_mul(l.vel, input_dir_j2, b_mul, 0.4)
			end
			
			-- add less if already going fast
			-- todo add special case for bouncy materials
			if (vec2_dot(pv_1, input_dir_j2) > 0) jump_str = max(0.1, jump_str - (vec2_len(pv_1)/p1_jump*1.35)^2)
		
			
			printh("surface: " .. surface_normal.x .. "  " .. surface_normal.y)

		-- CAREFUL WHEN JUMPING AFTER LADDER GRAB

			if player.grounded_mode and not player.ground_is_entity then
				local v_i = vec2_len(projection(player.vel, surface_normal))
				local impct = v_i*v_i*player.total_mass
				local brk, new_e = trn_impact(player.ground_pos_entity,impct + jump_str*0.43)	
				if brk then
					player.ground_is_entity = true
					player.ground_pos_entity = new_e
				end
			end

			
		else
		
			-- enable swings - boost velocity, but reduce if too big
			jump_str = max(1, jump_str + 0.25 - (vec2_len(player.vel)/2-0.25)^2)*0.75
			
			player.long_l_g_c=true
			set_timer(player, "l_grab_cooldown",10)
		end
		
				-- jump start
		printh("jump'd")
		set_timer(player, "jump_cooldown", 9) -- 9 frames of jump cooldown
	
		if player.grounded_mode and player.ground_is_entity and 
			not (surface_normal.x == 0 and surface_normal.y < 0 and player.ground_pos_entity.is_stnd) then
			-- simulate entity bounce
			local st_m = player.mass
			player.mass = player.total_mass
			transfer_momentum(player, player.ground_pos_entity, 1, 1, true)
			player.mass = st_m
		
			printh("drop kick! technically at least..")	
			local ce_mass = player.ground_pos_entity.mass
			
			-- split jump_vel in 2
			-- prevents troll physics and allows for proper drop kicks
			local j_v1,j_v2 = split_vector(vec2_normalized(input_dir_j2)*jump_str*1.25, player.total_mass, ce_mass)
			jump_str = vec2_len(j_v1)
			player.ground_pos_entity.vel -= j_v2
			sfx(12)
		else
			sfx(10 + flr(rnd(2)))
		end


		foreach_in_do(player.all_ntts, apply_vel, vec2_normalized(input_dir_j2)*jump_str)

	end

	-- jump control
	if jump_cooldown > 4 and not btn(4) then
		player.vel *= 0.8
	end
	
	
	-- rotation -----------------------------------

	-- alignment direction

 local align_down
	
	if not player.grounded_mode then

		if btn(4) then -- can stay tilted
			align_down=player.leg_facing+vec2_new(player.vel.x * 0.01,0) - input_dir_l*3
		else
			align_down = player.leg_facing*0.80 + vec2_limit(vec2_down + vec2_new(player.vel.x*0.20,0))*0.2
		end
	else
	 align_down = player.leg_facing*0.90 + (vec2_down - vec2_right*input_dir_l.x)*0.10
	end
	
	player.leg_facing = vec2_limit(align_down)
	
	-- only used for head drawing
	player.facing = vec2_normalized(input_dir_j*0.4 - player.leg_facing + vec2_up*0.6)

	local i=1
	for leg in all(player.m_l_legs) do
		
		local l_link = entity_links[leg.id][player.id]
		local l_l_len = l_link.true_len
	
		if not player.grounded_mode then
		
			local align_vec = vec2_normalized(player.leg_facing)/10
		
			if (player.is_stnd and vec2_len(input_dir) == 0) align_vec *= 0
			if (not b4) align_vec /= 2
			
			counter_mmnt(align_vec/i, leg, player)
			
			if not player.grounded_mode then
				l_l_len *= 0.9
				if (btn(4))	l_l_len *= 0.8
			end
		end
		
		l_link.len = l_l_len
		
		i+=1
	end
 
end

-->8
-- level managment


l_size_x,l_size_y,l_head_size_x,l_head_size_y = 16,8,10,1
l_start,l_end = 12, 32 -- 32 is excluded

ld_l_size_x,ld_l_size_y = 16,8


-- storable in map maybe
palettes = split[[
	1,2,3,128,132,142,15,8,9,10,138,7,12,14,13,0,
	1,2,9,1,5,13,6, 8,9,10,10,7,12,14,13, 0,
	1,131,4,2,8,9,10,3,138,135,143,7,12,14,13,0,
	3,2,3,130,5,6,7,8,9,10,11,12,13,14,15,3,
	129,2,3,4,5,6,7,8,9,10,11,12,13,14,15,5,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,
	5,7,3,4,5,6,7,8,5,4,3,2,7,14,15,0,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,9,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,6,
	11,4,3,4,5,6,7,8,9,10,11,12,13,14,15,4,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,10,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,10,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,15,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,7,
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,12
]]

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

function load_lvl(index)

	local map_pos_x = (index%8) * l_size_x
	local map_pos_y = (index\8) *(l_size_y + l_head_size_y) + l_start

	loaded_level = {load_lvl_header(map_pos_x,map_pos_y),{}}

	for j=0, l_size_y-1 do
		for i=0, l_size_x-1 do
		 add(loaded_level[2], mget0x20(map_pos_x+i,map_pos_y+l_head_size_y+j))
		end
	end

	-- clear map
	memset(0x8000, 0, 0x2000)
	for t_c=0, #loaded_level[2]-1 do
		draw_tile(loaded_level[2][t_c+1], t_c%l_size_x, t_c\l_size_x)
	end
	
	local function unpack_pal(o)
		local pal_l = loaded_level[1][o]*16
		return {unpack(palettes, pal_l+1, pal_l+16)}
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
	if (alt_t and not fget(s1,7)) s1 += 0b01000000
	
	if random and bcheck(s1, 0b100000) and (s1 & 0b001000 == 0) then -- in bottom left part of spr page
		
		-- flip 1st bit
		if (rnd(100) > 85) s1 ^^= 0b1
	end
	
	return s1
end

function draw_tile(t,x,y)
	
	local extra_t = t&0b11000000

	local t2 = t&0b00111111
	
	for j=0,3 do
		for i=0,3 do
			local m_x,m_y = x*4+i, y*4+j
			srand(m_x + m_y*l_size_x)
			mset(m_x,m_y, tile_spr(mget0x20((t2%32)*4+i,(t2\32)*4 +4+j), bcheck(extra_t, 0b1000000), bcheck(extra_t, 0b10000000), true))
		end
	end
	

end

-->8
-- enemy ai

function update_e1(enm)
move_humanoid(enm)
	--foreach(enm.all_ntts, move_entity)

end

__gfx__
0000000022222221111111111111111189aa9998a9888899aaaaa99aa999aaaab20220230b0b0b0bbbbbb3bb2b2b2b2b05020500000000006577775646777764
000000002222221111111111222222219888888288211289a98888888888888ab302203323232323232222323333333355557575000000005464444565445455
0000000021111111111111112111111198888882898882889998999999889999b2322323bbbbbbbb00300300bbbbbbbb05020700000000007644456576644445
0000000022222211111111112111212198888882921111289888888888888889b203302300222200222332223b3223b325222520000000007444566774465447
0000000021111111111111112112112198888882888888898888888888888899b2033023000220002223322223b33b3205020500000000007645644575454445
0000000022222211111111112111112198888882882112899888888888888888b23223230002200000300300232bb23275755555000000007466444674445646
000000001111111111111111211111219888888298882888988888888998888233022033002222002322223233b33b3307020500000000006445646656645454
00000000222111111111111111222221822222289988898988888222888888223202202333333333333333333b2222b305000500000000005657556454476444
00000000000000000000000000000000899888888888889a88888888888888880000000000000000000000000000000020011002111111112222222228228828
00000000000000000000000000000000a98888888888888888888888888888880000000000000000000000000000000022011022222222220200002012888888
00000000000000000000000000000000a99988888998999a99888888888888880000000000000000000000000000000020211202111111110020020011288222
00000000000000000000000000000000988988888888889a88888888888998880000000000000000000000000000000020022002222222221112211111128888
00000000000000000000000000000000a99999888899999998888899988888990000000000000000000000000000000020022002111111111112211111112888
00000000000000000000000000000000a98888888888988aa9999888888888880000000000000000000000000000000020211202222222220020020022111288
00000000000000000000000000000000999889988888999a88988888888889980000000000000000000000000000000022011022111111110200002011111128
00000000000000000000000000000000988888888888889aa99aaa9888aaa99a0000000000000000000000000000000020011002222222222222222212221112
111111111111111112211221222222229882988288888882aaaaa99a9aaaaa99b3bbbbb311111111a98ca98a2212221211111111000000002222222122222121
222212221222112211221122212211222222222288228888a988888888889888b133331322222222998aa98a2212221212117172000000002111111122121212
1111111111111111211221122112211282988288888888889998999999899989b3b33b3311111111a98aa98a2212221211111711000000002222211121212111
22122212211221122211221122112212222222222822228288888888888888883333333322222222a98aa98a2212221221122112000000006577775665777756
1111111111111111122112212221122298828882988288889888899899899888b333333188222828a98aa98a2212221211211111000000007566655575666555
122212221211122211221122212211222222222282222222888888888888888833b33b3122222222a98aa98a2212221271721122000000007221111772111117
11111111111111112112211221122112828882888888828888888888888888883133331188888888a98aa98a2212221217111111000000007111111771211117
22212221222122212211221122222222222222222282222288888888888888883311131188888888a98aa98a2212211222212221000000005211111551111115
02020200000200000000000200000002a2a2a2a2000000008888888888888888bbb3bbb388888888998aa98aaa38388346777764000000000000000000000000
0202020000020000222222220000002292222222000000008888888888888888b333b33388888888a98aa98a3111111264444445000000000000000000000000
2222020000020200020202020000020288988898000000008888888888888888b331333188888828a98a998a8112111274444445000000000000000000000000
02222220020202002020202220000022888282890000000088888888888888883111311122222222a98aa98a8121111274444447000000000000000000000000
0202020002020200020202020200020288888288000000008888888888888988bbb1bbb388828888a98aa98a8111111274444445000000000000000000000000
0202020002020200222222222222222288888888000000008888888898899998b333b33122222222a98aa98a3111111274444446000000000000000000000000
02220200020222202222222222222222888888880000000088888888888988883331b33111111111a9889988aa33388354444446000000000000000000000000
02020200020222002222222222222222888888880000000088888888888889993311331122222122882288228888888866666664000000000000000000000000
0000000000000000000000000000000000000000000000002aaa9989888888218828888800000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000a9988888899888828228288800000000000000000000000055766555555555555555555555555555
000000000000000000000000000000000000000000000000a9889888888888822812282800000000000000000000000000006660000000000000000000000000
000000000000000000000000000000000000000000000000a8888888888888882812282200000000000000000000000015766511111111111000000000000000
00000000000000000000000000000000000000000000000098988888888888882212112800000000000000000000000077776777777777777110000000000000
00000000000000000000000000000000000000000000000098888888888888881211121800000000000000000000000066666666666666666667100000000000
00000000000000000000000000000000000000000000000088888888888828882121212100000000000000000000000077777777777777777777771000000000
00000000000000000000000000000000000000000000000028888882888888882111211100000000000000000000000066666666666666666666666700000000
00000000000000000000000000000000000000000000000088888888888888880000000000000000000000000000000066666666666666666666666666600000
00000000000000000000000000000000000000000000000088888888888888820000000000000000000000000000000066666666657111111111115611170000
00000000000000000000000000000000000000000000000088888888888822820000000000000000000000000000000065111156671111111111111611111000
00000000000000000000000000000000000000000000000088888888888888820000000000000000000000000000000061111116611111111111111611111100
00000000000000000000000000000000000000000000000088888888882888820000000000000000000000000000000061177116611111111111111611111110
00000000000000000000000000000000000000000000000088228888888888220000000000000000000000000000000061711716611111111111111611111111
00000000000000000000000000000000000000000000000028888888888882210000000000000000000000000000000061111116651111111111117611111115
00000000000000000000000000000000000000000000000012882222222222110000000000000000000000000000000061177116666677777777776677777777
2211221221212211212222122212212100000000000000002a2aa2a22a22aa2a0000000000000000bb233322bbb2232261711716666666666000000000000000
212121221221212121222122121211210000000000000000aaaaaaaaaaaaaaaa0000000000000000b332222bb333322b61111116666666666000000000000000
2211121221221121212221221212122200000000000000009aaa99a9aa9a9aaa00000000000000003322bb22333332b361177116666666666600000000000000
1212211212212122222222122112121200000000000000009a9a99899a99a99a0000000000000000222b33323333222261711716666666666600000000000000
212121112122122122122211212222120000000000000000898998989998a9890000000000000000bb22332b22222bbb61111116666666666660000000000000
121211121212112222122121222212220000000000000000988a8998989889890000000000000000333222bb332bbb3351111115555555555550000000000000
121121211212112122212122122212120000000000000000989a8989988988980000000000000000332bbb23322b333366555566666666666660000000000000
1211212122122122222122222222221200000000000000008898888988888898000000000000000032bb33322222333355555555555555555550000000000000
00210021000000020000100101001200000000000000000088888888889888880000000000000000bbb22b222222b23300000000000000000000000000000000
02211012100000211021001011012010000000000000000088888898898898880000000000000000bb33b33bbb2bb32200000000000000000000000000000000
012110021020121201020021120221020000000000000000888888988888898800000000000000003332333bb332322b00000000000000000000000000000000
0210112112101220021202012002012100000000000000008898888888889898000000000000000033322322232b222200000000000000000000000000000000
12101012112112001212121221202122000000000000000089888888898898990000000000000000b23322bbb2b332bb00000000000000000000000000000000
20211022122112012102221221212212000000000000000089888888988888980000000000000000332b2bb333232bbb00000000000000000000000000000000
2121122122011201222122222122212100000000000000008888888888898889000000000000000032b33b333332bb3300000000000000000000000000000000
11212121022112111222212222222122000000000000000088888888888888880000000000000000222322333322233300000000000000000000000000000000
00000000000000000577775056777766000000000000000000777700000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000574e44755484e445000000dd7700000007777770000000000000000000000000000000000000000000000000000000000000000000000000
0044400000400840744e44477484e44700006dd77ddd000076777776000550000000000000000000000000000000000000000000000000000000000000000000
004f4000000f0f0074e44447748444470006dd755dddd00077677776005885000000000000000000000000000000000000000000000000000000000000000000
004ff000004202407e55eee764844447006dd566665ddd0077767766005885000000000000000000000000000000000000000000000000000000000000000000
0040000000000000788544477666666700dd56448465dd0077767665000550000000000000000000000000000000000000000000000000000000000000000000
0040000000000000688544455555555506dd644e8446ddd007766650000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000055555555454545450dd564e484465dd000665500000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000076777667776677770dd56e558ee65dd006066d00006d06d00000000000000000000000000000000000000000000000000000000000000000
000000000000000000055000000550000dd768858446ddd007d6d0dd607ddd000000000000000000000000000000000000000000000000000000000000000000
00000000000000000577775005777750007d68858445dd00706dddd06dd6dddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000057e4447557e4447500ddd555555ddd006dd55ddd07d55ddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000074e4555774e45557000dddd55dddd0006dd55ddd6dd55dd00000000000000000000000000000000000000000000000000000000000000000
000000000000000078e4568778e456870000dddddddd000006dddd0d66dddddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000068e4586568e45865000000dddd0000006d06ddd0006ddd0d0000000000000000000000000000000000000000000000000000000000000000
000000000000000005777750057777500000000000000000006dd0d00660dd000000000000000000000000000000000000000000000000000000000000000000
000000000000000065777756000000e0000000000000000000000000006dd7000000000000000000000000000000000000000000000000000000000000000000
0000000000000000546444450000005000000000000000000000000006dd77d00000000000000000000000000000000000000000000000000000000000000000
000000000000000076444565000077570000000000000000000000006dd77ddd0000000000000000000000000000000000000000000000000000000000000000
00000000000000007444566700076667000000000000000000000000dd755ddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000076456445ee7eeeee000000000000000000000000d7755ddd0000000000000000000000000000000000000000000000000000000000000000
0000000000000000746644465555554e00000000000000000000000077dddddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000064456466000664e40000000000000000000000000dddddd00000000000000000000000000000000000000000000000000000000000000000
00000000000000005657556400074e4400000000000000000000000000dddd000000000000000000000000000000000000000000000000000000000000000000
0057750011175111111117778888888911dd111198dd988988889899000000000000000000000000000000000000000000000000000000000000000000000000
06c77760117517111117775798a98a981ddd11118ad7a8988d89aa98000000000000000000000000000000000000000000000000000000000000000000000000
5cc76665157571711575651789a97a981dd5d11187a97aa8869aa989000000000000000000000000000000000000000000000000000000000000000000000000
777666555576171557565171add7a9881d577771aa777778567777aa000000000000000000000000000000000000000000000000000000000000000000000000
7766665157655557517511718ddd99981177aa998977aa99d677aa99000000000000000000000000000000000000000000000000000000000000000000000000
576665511751777117571711d5ddaaa817a7791197a77998d6aaa988000000000000000000000000000000000000000000000000000000000000000000000000
0665551075771551757175118d5d98881a1a97118a8a9789889a9898000000000000000000000000000000000000000000000000000000000000000000000000
005511005711551157115111d588898891191191988988988888a989000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000211110000000000000022
aa000000000aaaaa00000000000000aa000000000000000000000000000000001111110000000022221100000000000022100000000211111111000000002222
00aa00000aaa000000000000000aaaa0001110000000000000000110000000001111111100000222221100000000022222110000002211111111111100222211
00000000000000000aaaa00000000000001111000000011000011110000001101111111100000222221100000022222211111000002111111111111122221111
00000000000000000000000000000000001111000011011000011110001101111111111102222222211111112222211122111100022111211111111122111211
0990000000aaaaa00000000000000000011111000011011111011110001101111111111122222222211111112211122222111110021211211111111112221111
000000000aa999aa0000990000000000111111000111111111111111001101111111111122222222211111111122222222111111221211211111111122111211
00000000aaaa9999990000000aaa0000111111001111111111111111001111111111111121212121211111112222222211111111212211111111111112221111
9000009aaa9999999aa00000aaa9a999111111000000000000000000000000000000111022222222211111112222211122111111212211112100000022111211
000999aa9999999999aa000aa99a9a00111111100000000000000000000000000000111121112121211111112211122222111111122211112111000012221111
99aaaaaa99aaaa009999a0aa99999999111111110000000000000000000000000000111122222222211111111122222222111111122211112111110022111211
0aaaaaa9aaa99aaa99999a999a999990111111100000000000011000000000000000111121212121211111112222222211111111222111112111111112221111
aaaa999aa999999a9999999aa99aa999111111110000000000111111000000000000111122222222211111112222211122111111222111212111111122111211
aa9999aa999aaa9999aaa9999aaa9a9a111111110000000000111111000000000010111121212111211111112211122222111111221211212111111112221111
a99aaaaa99aaa9999aa9999999a9a9aa111111100000000000111111000000001011111122222222211111111122222222111111221211212111111122111211
99aaaaa99aa999999999999999aaaaa9111111100000000000111111000000001111111121112111211111112222222211111111212211112111111112221111
9aaa99999999999999999900aaa99999000000000000000000000000000000000000000000000000000000000880000000000000000000000000000081110000
aaa9999999999aaaaaaa9090a00aaaa9000000000000000000000000000000000000000000000000002100088888800000000000008100000000000811111000
a9999aa9999aaaa999aaa9090aa99999000000000000000000000000000000000000000000880000002110028881100000000000881110000000008211111000
99999999999999999a99aa00aa9aa999000000000000000000000000000000000000000000288000002110022211100000000088811110000000082221111100
aaaaaaa999999999999999a0a9aa9990000000000000000000000000000000000000000000211000002100022211000000000888111111000008222222111100
aaaa999999999999999999909a999909000000000000000000000000000000000000211002211000021100222211000000008882211111100082222222111110
a99909099999999999999aa900909090000000000000000000000000000000000000211112210000021000222211000000088222211111100222222222211110
9990909099aa99990099aa9900000000000000000000000000000000000000000002211102200000020000222110000000822222221111002222222222211100
00000000000000000000000000000000000000000000000000000000000000000002211102010000001000222100000002222222221111002222222222221100
00000000000000000000000000000000000000000000000000000000000000000002211100288000210000221000000002222222222110000222222222221100
00000000000000000000000000000000000000000000000000000000000000000002111000028880000002020100880000222222222110000222222222222100
00000000000000000000000000000000000000000000000000000000000000000002111000022110000000201028810000222222222210000022222222222000
00000000000000000000000000000000000000000000000000000000000000000002111000222110000000000022110000022222222200000022222222220000
00000000000000000000000000000000000000000000000000000000000000000022110000221100008880000022110000022222220000000002222222000000
00000000000000000000000000000000000000000000000000000000000000000021110000221100008888000022110000002222000000000002222200000000
00000000000000000000000000000000000000000000000000000000000000000021110000221100002888800022110000002200000000000000220000000000
__gff__
8000800001010101010101018400838300000000010101010000000000800000000000000101010101010100840082820000000001008101010101018300008000000000000001010000000000000000000000000000010100000000000000000000000000000101000001010000000000000000000001010000010100000000
0000000000000000000000000000000000000000000000000000000000000000000083000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce0000000000c80000c00000c300c1c2c37170707100707173000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd02c4d6d8c6c502c4c7c2c1d0d3d0d1d2e26160616071606162000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9dac5dbdccfdd02d402020202020202e3e1d3d0e0e1d1d06260636361616362000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9da02dbdcdfdd020202020202020202d0d1d0e0e2e1d1e26667666767666767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000036363636042607272626272614f676767676f615464706072a2a2a2a26262726210321203232323226272604e0e0e0e0000000000000000000000000090b0909005c0001090b090b0008001c242020202020202400000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000036363636143636153637363614f676767676f615565716173a3a3a3a39393939626262626060606036363636224647220000000000000000000000000008001c005c001c230800080008001c242003202020202400000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000036363736373636053636363614f676767676f61506070607363b252460606160262726276060616036363637225657220000000000000000000000001e081e230a0b0a0a0a0b0a0b1e0b1e23242020202020202400000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000036363636163736173636363614f676767676f615161716172525242502020202393939390404040439393939e0e0e0e00000000000000000000000000008001c0008001c000823080008001c242020202020202400000000000000000000000000000000000000000000000000000000000000000000000000000000
02020202222222220120202001202020020202020202020200000000012021011f3736362b2b2b2b23c0c02301c0c0011e011e1e02020200717071710c00000c202020200c1c0c0030000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202022222222221e0e02020202120020202022020202100000000d92222d9021f36372b2b2b2b1c00001c30000030c01cc0c002020200617060700c00000ccecece020c1c0c0030000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202022222222220e0e02121202020020202022120202000000000d92222d902021f362120202123c0c023300000231e011e1e02020200606361600c00000ccececece0c1c0c0030000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020222222222202020204242424202020202222222220000000001d9d9012020201f032021201c00001c013232010000000002020200636261630c00000c262626260c230c0030000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0081220b9842410498000000000000000081220c78426104a800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000002450100000000000000006a6c2a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
052d000000000000000000006c041501000000004c4c0c0c6a0014012d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
052d0000000e0000000000006c02150100000000000000006a6c14042d0c2900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
052d002f6c6c6c6c6c6c6c6c6c6c1501006a6a6a6c6c6c6c6c6c14011402032d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232d002f292d00000e0000006a0008080000006a00000000002e09021404012d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03021548484800000e0000006a2e0c0c2b6c6c6b00002e512e0823632308082d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020909490900000e11000286490909022e3002000010020909490349490930000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01012525020200100e1300060601010103061002101002010101010101020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0110000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c072300133202336043
0113800020b0620b0620b0622b161e0711e0711e0711e0712ea2306b5408b242ca753e01408b05143733e0041ab651eb0620b751cb55320422aa62143251411512105101740e1640a154081340491402b7334a62
000380003f3043e05338033320032e0622a04226022220711c05118021120010e0600803004010020003eb673ab3734b1730b762ab4626b1620b751ab4516b1510b640a3500a0500a0500a0500a0500a0500a050
011180001075010750107501d7501f750000002eb0730b1732b1734b3634b2730b2734b3736b673e3000201004020060300604008040080400201002010028762eb762eb662cb662ab762eb0730b2734b3736b47
00108000000000000000000000000000000000000000000022136281462a146221162e1762e1762e1762e1072c1072c1072c1762c1262c1662c1662c1662c1662c1662c1662c1262211622147361473813736127
00108000000000000000000000002a1562a15626166261662c14628166281662a1762a1762a1763010730107301073010730107301072e1762e1762e1662e1762e1762c1762e1762e1762e1662c1662c1662c166
0111800010105101050e174243540a1441833406124029643e06338033320032c87322071180110a00038b072ab2318b050ab2400b6338a332aa132ea032ea622aa5228a4226a1224a2224a1222a1222a1222a12
520080003f6103f6103f6100e6100e6100e6100e6100e610356103561036610366103761037610376103761000000376003760037600376103761037610376103761037600376003760037600376003760037600
4b0200003d6103d6303d6303d6203d6103d6103d6103c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52010000143200d31109311093112062020620206200d33020320253303d6203d610396103561510615066152a6050d6033b6033f6033f6053f6053f6053f6053f6053e6053f6053f6053f605006050060500000
52010000143200d3110a3110a31019620196200d3303863025330253203e6203d6102b6101c610166100f61005610036000060000600006000000000000000000000000000000000000000000000000000000000
52010000143710d361043510135100340366502533025340366403664036640366303663036630366303663036630366303663536635366253663536645366353662536625366103661000000000000000000000
500100001533008330034200042001320016100161000610006100461009600096000960009600096000960009600000000000000000000000000000000000000000000000000000000000000000000000000000
50010000193600d350063500335001340013400363003630036200562009610096100961009610096100861007610066100661005610056000460000000000000000000000000000000000000000000000000000
5a020000183730537301373016700566002660086600f6500165006645056450064004630086300663004620036200762006625056250162503610036100c6100261304613056150061500615086150061408614
080200001007008070030700006000050156700f6700c6600b6650b6550a655096400863007630066300562004620046250361502615016150161002610016100161301613006150061500615006150061400614
493d030014300105000c6000a30007400056000460006600064000640006600046000060000600006000960009600000000000000000000000000000000000000000000000000000000000000000000000018050
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030200000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
0a0100001275016760197601b75022750257502774000000000002c6602c6602c6402c630000003b6503b6303b6303b6253b6203b6203b6103b61500000000001370017700187001c70000000000000000000000
0a0100003b6303b6303b6303b6303b6303b6303c6002c6202c6202c6202c6202c6202c6200000025745227501f7501b7401774514730127200f7200f720000000000000000000000000000000000000000000000
080200000f64014641186311d610156532a730227601e750167400f7300a720087100371003710037100300000601000030060400600006010300004700037000070000700000000000000000000000000000000
001000001d75019750137500f7500f750107501075010750107201172011710117001870018700187001b700197001970019700197001970019700197001a7001e700217001a7000070000700007000070000700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
151200000f430124300d4300f43014430034200f43016430034100d4350d430034100d430034100e430034100f430124300a4300f43014430034100f43016430014100d4350d430014100d430014100e43003410
091200000f3330000033610000000f3330000033610000000f3230000027610000000f3230000033610000000f3330000033610000000f3330000033610000000f3430000033610336150f343000003361000000
531200001b6351b635376300c6310c6313763037610376300d300376352d6302d610376453764537645376451b6351b635376300c6310c6313763037610376300d300376352d6302d61037645376453764537645
5147000003c2003c2003c2003c2001c2001c2001c2001c2000c2000c2000c2000c200ac200ac2001c2003c2003c2003c2003c2003c2001c2001c2001c2001c2000c2000c2000c2000c200bc200bc200dc200ac20
511200000331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f3200331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f320
511200000131001310013100131001310013100131001310013100c3200c3200c32012320123200f3200f32001310013100131001310123200f3200131012320013100f320013110131016320153241532514320
4b1200002e625029002e6252e60037625396002e6252e6250000037625000000a6252e6252560537625376053a6103a6253a6103a62537625396002e6252e6251362537625000000000037625000001362537625
0412000027c251bc201b3261bc00273261bc351bc051bc351bc001bc351b3161bc3519c20193151ac201ac100fc251bc201b3261b400273261bc351b4001bc351b4101bc351b4161bc351ec201b3151bc201bc10
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
012000000395000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00 57424344
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
00 57424344

