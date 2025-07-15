pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

--movement prototype


--abbreviations
--tabl:table
--ntt/e:entity
--trn:terrain
--bnc:bounciness/bounce
--slp:slipperiness
--sq:square
--coll:collision
--b:bottom/min
--t:top/max
--lmt:limit
--h:horizontal
--v:vertical
--stnd:stand/standing
--tch:touch/touching
--rds:radius
--c:counter/clock
--mmnt:momentum

function _init()
printh("start------------")

	--init global vars

	debug_visuals = false
	
	mod_tabl(_ENV,"trn_bnc,trn_slp,grav/0.4,0.4,0.14")
	mod_tabl(_ENV,"b_lmt_x,t_lmt_x,b_lmt_y,t_lmt_y/-400,2000,-2000,400")

--global player vars
	mod_tabl(_ENV,"p1_jump,p1_h_g_spd_lmt,p1_h_a_spd_lmt,p1_st_rng/3.1,2,1,7.5")
 --jump, ground/air speed limit, stand range

 -- timers & counters
 mod_tabl(_ENV,"anim_c,max_anim_len/0,2048")

	for i=0, 15 do
		add(pal,i)
	end
	rainb_pal = {unstr("1,2,8,9,10,11,12")}

	camera_x,camera_y=32,128
	camera(camera_x,camera_y)
	
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
	
	--music(0)
	
end

tugs_per_frame=0
MAC_per_frame=0
frame_c = 0

c_face_offset_x = 1
c_face_offset_y = 1

pal = {}
rainb_pal = {}

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

	update_mus()

	-- move enttites
	for num, ntt in pairs(entities) do
		
		if not is_oob(ntt.pos) then
			if ntt.e_type == "humanoid" then
				move_humanoid(ntt)
			else 
				foreach_in_do(ntt.move_list, move_entity)
			end
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


 if player != nil then
	 player_control(player, btn(0),btn(1),btn(2),btn(3),btn(4),btn(5))

		c_face_offset_x=0.975*c_face_offset_x+0.025*(-1 + 2*tonum(player.is_right))
		c_face_offset_y=0.975*c_face_offset_y+0.025*(tonum(btn(3)) - tonum(btn(2)))
		
		local follow_pos=player.pos+player.vel*4+vec2_right*28*c_face_offset_x + vec2_down*36*c_face_offset_y
	 local f_x,f_y=follow_pos.x, follow_pos.y
		
		
	 local camera_tolerance = 8
	 local camera_center = vec2_new(camera_x + 64, camera_y + 64)
	 -- move camera to player
		
		-- separate x & y
	 local distance = vec2_new(
	 	abs(camera_center.x-f_x),
	 	abs(camera_center.y-f_y)
	 )
		
		local speed = distance \ (camera_tolerance * 1)
		
		if abs(f_x-camera_center.x) > camera_tolerance then
			camera_x += speed.x * sgn(f_x - camera_center.x)
		end
		
		if abs(f_y-camera_center.y) > camera_tolerance then
			camera_y += speed.y * sgn(f_y - camera_center.y)
			camera_y = min(max(camera_y,-64), 128)
		end
	
		camera(camera_x, camera_y)
 end

end
 
function _draw()
	cls(9)
	
	draw_bg(120,60,8,4, 4, 0x0.08,0x0.0, 0x1,0x0, true,true,64,0)
	draw_bg(112,60,8,4, 6, 0x0.2 ,0x0.2, 0x0,0x0, false,false,32,-48)


	draw_fall_zone(255)

 draw_map()
	draw_entities()
	draw_links()
	draw_ui()

end
-->8
-- token savers

function unstr(str)
	return unpack(split(str))
end

-- thank you Lokistriker whoever you may be
function make_tabl(kv)
	local tab,k,v = {},unpack(split(kv, "/"))
	k,v = split(k),split(v)
	for i=1,#k do
		tab[k[i]]=_pars(v[i])
	end
	return tab
end

-- modifies/appends to table. can target _ENV to change globals
function mod_tabl(tab, kv)
	local k,v = unpack(split(kv, "/"))
	k,v = split(k),split(v)
	for i=1,#k do
		tab[k[i]]=_pars(v[i])
	end
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

-->8
-- entity managment

mod_tabl(_ENV, "entities,max_entities,entity_id_stack/{},256,{}")

player_col=12

for i=0,max_entities+0 do
	add(entity_id_stack,max_entities+1 - i)
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

function spawn_entity(px,py,m,r,e_typ)
 local ntt = {
  id = take_id(),
  
		pos = vec2_new(px, py),
  vel = vec2_new(0,0),
 	
		mass = m or 1,
		
		-- half of edge len if squares
 	rds=r or 1,
		
		e_type = e_typ or "none"
		}

		--test whether is standing on or touching something
		mod_tabl(ntt, "is_stnd,stnd_on_trn,stnd_on,is_tch,tch_trn,tch/false,false,nil,false,false,nil")
	
		mod_tabl(ntt, "coll_mask_on,coll_mask_see/0b00000001,0b00001111")
		--coll_mask_on:  those who see one of these layers will detect this entity 
		--coll_mask_see: detects those on these layers	
 
	-- point to self when asked who moves
	ntt.move_list = {ntt}
	ntt.all_ntts = {ntt}
 
 return ntt
end

function remove_listed_entity(e)
	foreach(e.all_ntts, cleanup_entity)
	del(entities, e)
end

function cleanup_entity(e)
	give_id_back(e.id)
	
	for to_entity_id, link in pairs(links) do		
		if link.to_ground then
			delete_link(e)
		else
			delete_link(e, entity_links[e.id].to)
		end
	end
end

function spawn_humanoid(px,py)
	local e = spawn_entity(px,py,0.3,1)
	
	e.e_type = "humanoid"
	
	e.rl_target = spawn_entity(px+2,py+6) --subentity: right leg's target
	e.ll_target = spawn_entity(px-2,py+6)
	
	e.leg_facing = v2c(vec2_down)
	e.facing = v2c(vec2_up)
	
	mod_tabl(e,"is_right,grounded_mode,ground_is_entity,ground_pos_entity,walking,crouch/true,false,false,nil,false,false")
	
	e.stmn = 1.0
	e.stmn_l_t = 1.0
	e.stmn_l_b = 0.5

	e.rl=spawn_entity(px+2,py+6,0.1,0.5)--right leg
	e.ll=spawn_entity(px-2,py+6,0.1,0.5)--left
	e.uh=spawn_entity(px  ,py-2,0.3,1)--upper half of body
	e.ra=spawn_entity(px+3,py-1,0.1,0.5)--right arm
	e.la=spawn_entity(px-3,py-1,0.1,0.5)

	e.total_mass = 1 -- precalculated but all of these added
	
	local rl,ll,uh,ra,la = e.rl,e.ll,e.uh,e.ra,e.la
	
	make_link(e ,rl,1,5.4,false,0,0,7)
	make_link(e ,ll,1,5.4,false,0,0,11)	
	make_link(e ,uh,1,3.3,false,0,0,player_col)
	make_link(uh,ra,1,4.5,false,0,0,7)
	make_link(uh,la,1,4.5,false,0,0,11)
		


	--subentity mappings. moving them in bulk is a lot easier

	--maps self too, so don't go deeper than 1 in subentities
 e.move_list = {e,uh,rl,ll,ra,la}
	--targets are only mapped here
 e.all_ntts = {e,uh,rl,ll,ra,la,rl_target,ll_target}
 e.m_l_prim = {e,uh}
 e.m_l_walk = {e,uh,rl,ll}
 e.m_l_legs = {rl,ll}
 uh.m_l_legs ={rl,ll}
 e.m_l_arms = {ra,la}

	local function set_coll(e)
		--doesn't collide with other parts
		mod_tabl(e, "coll_mask_on,coll_mask_see/0b00000010,0b00001101")
	end
	
	foreach(e.move_list, set_coll)

	mod_tabl(e,"in_grab,grabbed_e,grabbed_coll_on,grabbed_coll_see/false,nil,0b00000000,0b00000000")


	

 return e
end

function spawn_player(px,py)
	
 local player_l = spawn_humanoid(px,py)
	
	-- timers
	mod_tabl(player_l, "jump_cooldown_t,jump_control_t,stuck_timer/0,0,0")
	
	-- vars
	player_l.surface_away = v2c(vec2_up)
	
	return player_l
end


function make_link(e1, e2, link_type, link_len, to_ground, link_strenght, draw_type, col)

	local t_t_g = to_ground or false

	local link = {
		from = e1,
		to = e2,
		l_type = link_type, -- 0-keep at exact distance, 1-limit max distance, 2-limit min
	 len = link_len,
		to_ground = t_t_g,
		strenght = link_strenght or 0, -- 0 means unbreakable
		draw_type = draw_type or 0, -- 0-invis,1-normal,2-joint
		col = col or 14
	}
	
	if(entity_links[e1.id] == nil) entity_links[e1.id] = {}
	
	local e2_id = e2.id
	if (t_t_g) e2_id = -1

	entity_links[e1.id][e2_id] = link
	
	if not t_t_g then -- no need for second link entry if it's to ground
		-- this one will have a reversed direction so checks may be needed
		
		if(entity_links[e2.id] == nil) entity_links[e2.id] = {}
		entity_links[e2.id][e1.id] = link
	end
	
	add(all_links, link)
	
	return link
end

function delete_link(e1,e2)
	local link
	if e2 == nil then -- delete ground link
		link = entity_links[e1.id][-1]
		entity_links[e1.id][-1] = nil
	else
	 link = entity_links[e1.id][e2.id]
		entity_links[e1.id][e2.id] = nil
		entity_links[e2.id][e1.id] = nil
	end
	
	del(all_links,link)
end

-->8
-- drawing

function draw_bg(m_st_x,m_st_y,len_x,len_y, scale, scroll_a_x, scroll_a_y, timescroll_x,timescroll_y, wrap_x,wrap_y,offset_x,offset_y)
	
	local scroll_x = (-offset_x or 0) + camera_x*scroll_a_x
	scroll_x += time()*(timescroll_x or 0)
	local scroll_y = (-offset_y or 0) + camera_y*scroll_a_y
	scroll_y += time()*(timescroll_y or 0)
	
	if(wrap_x) scroll_x %= len_x*8*scale
	if(wrap_y) scroll_y %= len_y*8*scale

	local function map_scaled(ox,oy)
		for	i=0,len_x-1 do
			for	j=0,len_y-1 do
			 local n = mget(m_st_x+i,m_st_y+j)
				sspr((n&0b1111)*8,(n\16)*8,8,8, camera_x-scroll_x+i*8*scale+ox, camera_y-scroll_y+j*8*scale+oy, scale*8,scale*8)
			end
		end
	end
	
	map_scaled(0,0)
	if (wrap_x) map_scaled(len_x*8*scale,0)
	if (wrap_y) map_scaled(0,len_x*8*scale)
	if (wrap_x and wrap_y) map_scaled(len_x*8*scale,len_x*8*scale)


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

function draw_entities()
	for i=1, #entities do
		if entities[i].e_type == "humanoid" then
			draw_humanoid(entities[i])
		else
		--default
			draw_entity(entities[i], 7)
		end
	end
end

function draw_entity(entity, col)
	--circfill(entity.pos.x, entity.pos.y, entity.rds, col)
	if entity.sprite != nil then
		e_spr_pos = entity.pos - vec2_new(3.5,3.5)
		spr(entity.sprite, e_spr_pos.x, e_spr_pos.y)
	else
		rectfill(entity.pos.x - entity.rds, entity.pos.y - entity.rds, entity.pos.x + entity.rds, entity.pos.y + entity.rds,col)
	end
	
	if debug_visuals then
		if entity.is_stnd then
			if entity.stnd_on_trn then
				circ(entity.pos.x + entity.vel.x, entity.pos.y + entity.vel.y, entity.rds/2,11)
			else
				circ(entity.pos.x + entity.vel.x, entity.pos.y + entity.vel.y, entity.rds/2,12)		
			end
		else
			circ(entity.pos.x + entity.vel.x, entity.pos.y + entity.vel.y, entity.rds/2,4)	
		end
	end
end

function draw_links()
	for i=1, #all_links do
			draw_link(all_links[i])
	end
end

function draw_link(link)
	local other_p=link.to
	if (not link.to_ground) other_p = link.to.pos
	if link.draw_type == 1 or debug_visuals then
		line_vec(link.from.pos, other_p, link.col)
	end
end

-- assumes both have same radius
function circ_intersect(p1,p2,r)
	local d=vec2_len(p2-p1)
	local offset=sqrt(r*r-d*d/4)
	
	local mid_p=(p1+p2)/2 
	
	local ox=offset*(p2.y-p1.y)/d
	local oy=offset*(p2.x-p1.x)/d
	
	return vec2_new(mid_p.x+ox,mid_p.y-oy), vec2_new(mid_p.x-ox,mid_p.y+oy)

end

function line_vec(v1,v2,col) 
	col_t=col or 1
	line(v1.x,v1.y,v2.x,v2.y,col)
end

function line_entity(e1,e2,col) 
	col_t=col or 1
	line_vec(e1.pos,e2.pos,col)
end

function draw_joint(p1,p2,rds,col,is_right)
	local k_1, k_2 = circ_intersect(p1,p2,rds)
	
	if is_right then
		line_vec(p1, k_1, col)
		line_vec(k_1, p2, col)
		--circ(rk_1.x, rk_1.y, 1, 3)
	else
		line_vec(p1, k_2, col)
		line_vec(k_2, p2, col)	
	end

end

function draw_humanoid(ntt)
	
	-- locals
	-- all of these are read-only so it's fine
	local ntt_pos,uh_pos,rl_pos,ll_pos,ra_pos,la_pos,is_r = 
	      ntt.pos,ntt.uh.pos,ntt.rl.pos,ntt.ll.pos,ntt.ra.pos,ntt.la.pos,ntt.is_right



	line_vec(ntt_pos, uh_pos, player_col)
	
	--head
	local head_pos_center = uh_pos + (vec2_normalized(ntt.facing)*2)
	local head_pos_sprite = head_pos_center + vec2_new(-4,-4)	
	local flip_r = not is_r
	local flip_u = false
	if (not btn(4) and flip_r and btn(1)) flip_r = not flip_r
	if (not btn(4) and not flip_r and btn(0)) flip_r = not flip_r
	if vec2_normalized(ntt.facing).y > 0.7 then
		flip_u = true
		flip_r = not flip_r
	end
	if (flip_r == false) head_pos_sprite.x += 1
	spr(12, head_pos_sprite.x, head_pos_sprite.y, 1, 1, flip_r, flip_u)
	
	--eyes
	local e_p_s = head_pos_center+vec2_new(1-2*tonum(flip_r),-1)
	if (btn(3)) e_p_s.y += 1
	
	if anim_c%(55 + ntt.id) > 3 or vec2_len(ntt.vel) > 0.5 then
		pset(e_p_s.x+1, e_p_s.y, 7)
		pset(e_p_s.x-1, e_p_s.y, 7)
		if vec2_len(player.vel) > 4 then
			pset(e_p_s.x+1, e_p_s.y+1, 7)
			pset(e_p_s.x-1, e_p_s.y+1, 7)
		end
	end

	
	if debug_visuals then
		if ntt.grounded_mode then
			draw_entity(ntt.rl_target, 7)
			draw_entity(ntt.ll_target,14)
			
			local st_point = (ntt.rl_target.pos+ntt.ll_target.pos)/2
			circ(st_point.x,st_point.y,2,12)
		end
	end

	
	-- intersections of 2 cicles
	
	draw_joint(ntt_pos, rl_pos, 2.75, 7, is_r)
	draw_joint(ntt_pos, ll_pos, 2.75, 11,is_r)
	
	--draw_entity(ntt.rl, 13)
	--draw_entity(ntt.ll, 13)

	draw_joint(uh_pos, ra_pos, 2.25, 7,  not is_r)
	draw_joint(uh_pos, la_pos, 2.25, 11, not is_r)

	--draw_entity(ntt.ra, 13)
	--draw_entity(ntt.la, 13)
end

function draw_ui()

for i=1, 5 do
		line(camera_x+3, camera_y + i, camera_x + 85, camera_y + i,0)
	end



	for i=2, 4 do
		line(camera_x + 4, camera_y + i, camera_x + 80*player.stmn + 4, camera_y + i,12)
		line(camera_x + 4, camera_y + i, camera_x + 80*player.stmn_l_b + 4, camera_y + i,1)
	end
	
	line(camera_x+4+80*player.stmn_l_t, camera_y+1, camera_x+4+80*player.stmn_l_t, camera_y+5,1)
	line(camera_x+4+80*player.stmn_l_b, camera_y+1, camera_x+4+80*player.stmn_l_b, camera_y+5,1)
	line(camera_x+4+80*player.stmn,     camera_y+2, camera_x+4+80*player.stmn, camera_y+4,7)
	
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

	if (vec2_len(src_pos - player.pos) < 200) then
		sfx(sf)
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
	__add=function(a,b)
 	return vec2_new(a.x+b.x,a.y+b.y)
	end,
	__unm=function(a,b)
 	return vec2_new(-a.x,-a.y)
	end,
	__sub=function(a,b)
 	return a + (-b)
	end,
	--mul div vector by a scalar
	__mul=function(a,s)
 	return vec2_new(a.x*s,a.y*s)
	end,
	__div=function(a,s)
 	return a*(1/s)
	end,
	__idiv=function(a,s)
 	return vec2_new(a.x\s,a.y\s)
	end,
	__eq=function(a,b)
		return a.x==b.x and a.y==b.y
	end
}
-- some basic vectors
vec2_zero=vec2_new(0,0)
vec2_right=vec2_new(1,0)
vec2_down=vec2_new(0,1)
vec2_left=-vec2_right
vec2_up=-vec2_down

--copying
function v2c(vec)
	return vec2_new(vec.x, vec.y)
end

function vec2_len(vec)
	-- alternate way of getting hypotenuse by trigonometry
	-- avoids squaring, more accurate in almost all cases
	-- and does not break at very small or big values
	local v2, v2_c = v2c(vec), vec.x
	-- take bigger side, otherwise can ultrasmall/ultrasmall and horrible accuracy

	if abs(vec.x) > abs(vec.y) then
		v2.y = 0
	else
		v2.x = 0
		v2_c = v2.y
	end
	local l = abs(v2_c)/cos(vec2_angle(vec,v2))
	--if (l < 0.1) l = 0
	return l
end

function vec2_normalized(vec)
	if (vec2_len(vec) == 0) return v2c(vec2_zero)
	return vec/vec2_len(vec)
end

function vec2_limit(vec)
	if (vec2_len(vec) == 0) return v2c(vec2_zero)
	if (vec2_len(vec) > 1) return vec2_normalized(vec)
	return vec
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

function vec2_center(v)
	return v\1 + vec2_new(0.5,0.5)
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
	local diff = e2.pos - e1.pos
	
	if square_coll then
		if diff.x > diff.y then
			diff.y = 0
		else
			diff.x = 0
		end
	end

	local e1m, e2m = e1.mass, e2.mass
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
	local v2_f= v1_c*2*e1m     +v2_c*(e2m - e1m)
	
	-- for sticky collision - equalize velocities
	local final_v=v1_c*e1m+v2_c*e2m
	
	-- readd modified components
	e1.vel+=(final_v*(1-bnc) +v1_f*bnc)/total_m
	e2.vel+=(final_v*(1-bnc) +v2_f*bnc)/total_m
end

-- slightly modified foreach that also gives function's results
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
	local tile = mget(point.x/8,point.y/8)
	return fget(tile,0) -- solid tile
end


function sq_sq_coll(p1, r1, p2, r2)
	local l_max_x = p1.x + r1
	local r_min_x = p2.x - r2
	local u_max_y = p1.y + r1
	local d_min_y = p2.y - r2

	if p1.x > p2.x then
		l_max_x = p2.x + r2
		r_min_x = p1.x - r1
	end

	if p1.y > p2.y then
		u_max_y = p2.y + r2
		d_min_y = p1.y - r1
	end

	if l_max_x > r_min_x and u_max_y > d_min_y then
		local s_normal = v2c(vec2_up)
		local dist = 0

		if abs(p1.x-p2.x) > abs(p1.y-p2.y) then
			s_normal = vec2_left * sgn(p2.x - p1.x)
			dist = (r1 + r2) - abs(p2.x - p1.x)
		else
			s_normal = vec2_up * sgn(p2.y - p1.y)
			dist = (r1 + r2) - abs(p2.y - p1.y)
		end

		return true, s_normal, dist
	end

	return false

end


function sq_trn_coll(point, rds, find_closest)
	point_max = point+vec2_new(rds,rds)
	point_min = point+vec2_new(-rds,-rds)
	local found,min_dist,closest,closest_n = false,32000

	-- go over all tiles in rectangle range
	for j=flr(point_min.y/8),flr(point_max.y/8) do
		for i=flr(point_min.x/8),flr(point_max.x/8) do
			local tile = mget(i,j)
			
			if fget(tile,0) then -- solid tile
			
				-- test coll
				local p2 = vec2_new(i*8+4,j*8+4)
				local did, normal = sq_sq_coll(point, rds, p2, 4)
				
				if did then 
					if (not find_closest) return did, p2, normal
					
					found = true
					
					local dist = vec2_len(point - p2)				
					if dist < min_dist then
						min_dist = dist
						closest = p2*1
						closest_n = normal*1
					end	
					
				end
				
				
			end
			
		end
	end
	
	return found, closest, closest_n
end

function check_coll_ntts(ntt, pos, rds)
	local p_t = pos or ntt.pos
	local r_t = rds or ntt.rds

	-- ultra slow with lots of entities - limit is about 15
	-- todo maybe check subentities
	-- todo maybe do grid cell separation table
	for i=1, #entities do
		local other = entities[i]
		if other.id != ntt.id and (ntt.coll_mask_see & other.coll_mask_on != 0) then
			local did, normal, dist = sq_sq_coll(p_t, r_t, other.pos, other.rds)
			
			if (did) return true, other, normal, dist
		end
	end
	return false, nil	
end


function tile_to_entity(tile_pos)
	local t_dat,t_set,hitb,mass = mget(tile_pos.x, tile_pos.y),0,3.7,0.4
	
	if t_dat == 56 then
		t_dat -= 16
	end
	
	if t_dat == 40 then
		hitb = 2.4
		mass = 0.1
	end
	
	-- insert most common tile in <^>
	local chosen = false
	local t_l,t_u,t_r = mget(tile_pos.x-1, tile_pos.y),mget(tile_pos.x, tile_pos.y-1),mget(tile_pos.x+1, tile_pos.y)
	if (fget(t_l) & 0b11 == 0) t_set = t_l
	if fget(t_u) & 0b11 == 0 then
		t_set = t_u
		if t_l == t_u then
			chosen = true
		end
	end
	if (fget(t_r) & 0b11 == 0 and not chosen) t_set = t_r

	
	mset(tile_pos.x, tile_pos.y, t_set)

	local t_e = spawn_entity(tile_pos.x*8+4,tile_pos.y*8+4,mass,hitb)
	t_e.sprite = t_dat
	t_e.e_type = "tile"
	
	add(entities, t_e)
	return t_e
end


function entity_to_tile(e)
	local prev_tile = mget(e.pos.x\8, e.pos.y\8)
	if e.sprite == 40 and prev_tile != 0 then
		mset(e.pos.x\8, e.pos.y\8, e.sprite + 16)
	
	else
		mset(e.pos.x\8, e.pos.y\8, e.sprite)
	end
	
	remove_listed_entity(e)
end




-->8
-- movement

function is_oob(pos)

	if pos.x < b_lmt_x or
	   pos.x > t_lmt_x or
	   pos.y < b_lmt_y or
	   pos.y > t_lmt_y then
				return true
	end
	return false
	
end

-- NO TERRAIN CLIPPING 

function unclip(entity,pos,rds)
	local pos_t, rds_t = pos or entity.pos, rds or entity.rds

	local coll_t, t_pos = sq_trn_coll(pos_t, rds_t)
	
	if coll_t then
	
		local vec_rep = {vec2_up, vec2_down, vec2_left, vec2_right,
			vec2_up + vec2_left, vec2_up + vec2_right, vec2_down + vec2_left, vec2_down + vec2_right}

		for i=1, 9 do
			for j=1, #vec_rep do 
			
				local m_v = vec_rep[j] * i
				if not sq_trn_coll(pos_t + m_v, rds_t) then	
					return true, true, true, m_v, t_pos -- out now - ignore entities
				end
				
			end
		end
		
		return true, true, false, vec2_zero, t_pos
		
	else
	
		local coll_e, e, norm, dist = check_coll_ntts(entity, pos_t, rds_t)
		
		if coll_e then
			local m_v = norm * dist
		
			if not sq_trn_coll(pos_t + m_v, rds_t) and not check_coll_ntts(entity, pos_t + m_v, rds_t) then
				return true, false, true, m_v, e
			end
			
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
	if (clip) printh("clip")
	return did_m, clip,with_t,out,dir,coll_t_e
	
end



function update_touch(entity, rds)

	local r = rds or entity.rds+1
	
	local coll_t, t_point = sq_trn_coll(entity.pos, r)
	local coll_e, e = check_coll_ntts(entity, nil, r)
	
 if coll_t then
		entity.is_tch = true
		entity.tch_trn  = true
		entity.tch = t_point
		return true, true, t_point
	elseif coll_e then
		entity.is_tch = true
		entity.tch_trn  = false
		entity.tch = e
		return true, false, e
	else
		entity.is_tch = false
		entity.tch_trn = false
		entity.tch = nil
		return false, false
	end

end

function update_stand(entity)
	
	-- clear standing
	entity.is_stnd = false

	local down_pos = entity.pos + vec2_down
	
	-- if not in bounce
	if abs(entity.vel.y) < 0.5 then
	
		-- first check terrain
	 local touch, point, norm = sq_trn_coll(down_pos, entity.rds)

		if touch then
			entity.is_stnd = true -- ground stand
			entity.stnd_on_trn = true
			return
		end
		
		-- then entity below
		local touch_e, e, norm_e = check_coll_ntts(entity, down_pos)
		
		if touch_e and e.is_stnd then -- if standing on a stable entity
			entity.is_stnd = true -- entity stand
			entity.stnd_on_trn = false
			entity.stnd_on = e
			return
		end
		

		-- then linked entities
		if vec2_len(entity.vel) < 0.15 then
			local links = entity_links[entity.id]
			if links != nil then
				for to_entity_id, link in pairs(links) do
					if link.to_ground then
							entity.is_stnd = true -- ground stand
							entity.stnd_on_trn = true
						return
					else
						local other = link.to
						if (other == entity) other = link.from
						if other.is_stnd then
							entity.is_stnd = true -- entity stand
							entity.stnd_on_trn = false
							entity.stnd_on = other
							return
						end
						
					end
					
				end
			end
		end
		
		-- then legs
		
		if entity.m_l_legs != nil then
			for i=1, #entity.m_l_legs do
				if entity.m_l_legs[i].is_stnd then
					entity.is_stnd = true -- entity stand
					entity.stnd_on_trn = false
					entity.stnd_on = entity.m_l_legs[i]
					return
				end
			end
		end

	end
	
	
end

function trn_impact(t,impct)
	local t2 = t\8
	-- break grabbables or any non-bedrock tiles if strong enough
	if (impct > 1.4 and fget(mget(t2.x, t2.y),1)) or (impct > 15 and fget(mget(t2.x, t2.y),0) and t2.y != 31) then
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
	
	
	if did_c then
		printh("coll!")
	
		if out then
	
			-- todo trigger coll events for entities
			local prev_e = vec2_len(entity.vel)*vec2_len(entity.vel) * entity.mass
			
			
			-- if broke terrain
			if with_t then
				local v_i = vec2_len(projection(entity.vel, surface_dir))
				local impct = v_i*v_i*entity.mass
				local brk, new_e = trn_impact(coll_t_e, impct)
				if brk then
					with_t,coll_t_e=false,new_e
				end
			end
			
			-- bounce
			if with_t then
				entity.vel = recomp_mul(entity.vel, surface_dir, -trn_bnc, trn_slp)
			else
				transfer_momentum(entity, coll_t_e, 0.8, 1, true)
			end
			
			
			local pos_e = vec2_len(entity.vel)*vec2_len(entity.vel)  * entity.mass
			
			
			local impact = abs(prev_e - pos_e)
			local pl_hit = false
			if entity == player.uh or entity == player then 
				impact *= 1.4
				pl_hit = true	
			elseif (entity == player.ra or entity == player.la) then
				impact *= 0.01
				pl_hit = true
			elseif (entity == player.rl or entity == player.ll) then
				impact *= 0.5
				pl_hit = true	
			end
			
			if pl_hit then
				if (impact > 1.5) player.stmn -= impact*0.02
			end
			
			local e_p = entity.pos
			if impact > 8 then
				sp_sfx(15, e_p)
			elseif impact > 3.5 then
				sp_sfx(14, e_p)
			elseif impact > 1.1 then
				sp_sfx(13, e_p)
			end
			
			
	 else 
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
		if rem_depth <= 0 then -- either invalid stand or too far
			return false
		end
		if entity.is_stnd then
			if entity.stnd_on_trn then
				return true
			else
				return check_stand_chain(entity.stnd_on, rem_depth-1)
			end
		else
			return false
		end
	end
	
	if not check_stand_chain(entity, 5) then
		entity.is_stnd = false
	end
	
	--fall
	if entity.is_stnd then
  local slip = trn_slp
		if not entity.stnd_on_trn then
			slip = entity.stnd_on.slipperiness or 0.5
		end	
		entity.vel.y = 0
	 entity.vel.x *= 1 * 0.8 + (slip) * 0.2 --ground/ntt friction
 elseif not entity.special_stand then
		entity.vel.y += grav
		entity.vel *= 0.998 --air friction
	end

	if vec2_len(entity.vel) < 0.09 then -- prevent micromovements
		entity.vel = v2c(vec2_zero)
	end
	
end

-- called when an entity is outside its link range
function tug(link)
	--printh(e1.id .. " tugs " .. link.to.id)

	local e1 = link.from
	
	e1m = e1.mass
	
	e2 = link.to
	local e2_pos = e2.pos
	if (link.to_ground) e2_pos = e2
	
	local diff = e2_pos - e1.pos
	local diff_norm,diff_len = vec2_normalized(diff),vec2_len(diff)
	
	local move_dist = diff_len - link.len
	
	-- the amount that the entities need to move so they stay in proper link range
	local move_need = diff_norm * move_dist
	
	
	-- break if too far
	if link.strenght > 0 and abs(move_dist) > link.strenght then
		if link.to_ground then
			delete_link(e1)
		else
			delete_link(e1,e2)
		end
		return
	end
	
	-- check if tugging is needed
	-- small tolerance so it isn't constantly active
	local tol = 0.6
	if  (move_dist >  tol and link.l_type & 0b10 == 0) 
		or (move_dist < -tol and link.l_type & 0b1  == 0)
		then
		-- continue with pulling

		tugs_per_frame += 1

		if link.to_ground then
		
			e1.pos += move_need
			-- remove vel component towards ground
			e1.vel = recomp_mul(e1.vel, e1.pos - e2_pos, 0, 1)
		else
			
			e2m = e2.mass
			-- move proportionally and equalize velocities

			-- the amount each entity needs to move
			local m_total = e1m+e2m
			local move_1 = move_need*e2m/m_total
			local move_2 = move_need*e1m/m_total -- == move_need/(e2m/e1m)
			
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



function move_humanoid(entity)
	

	-- local variables - help a lot in token reduction
	-- do NOT REASSIGN THESE, they cannot be at left side of an =
	-- ntt_rl = .. NOT OK
	-- ntt_rl.pos = .. is fine tho
	
	-- also do NOT TRY to do this with ntt_rl_pos and the like, it breaks
	
	local ntt_uh,ntt_rl,ntt_ll,ntt_rl_t,ntt_ll_t,ntt_ra,ntt_la = entity.uh,entity.rl,entity.ll,entity.rl_target,entity.ll_target,entity.ra,entity.la

	foreach_in_do(entity.move_list, move_entity) -- moves comps separately
	
	entity.special_stand = false
	ntt_uh.special_stand = false
	ntt_ra.special_stand = false
	ntt_la.special_stand = false
	
	-- leg move parameters
	local stand_height,st_o,tol,leg_move_speed,solo_distance =
		 4.8, 1,	3, 0.1, 2	 
			
 -- preferred offset from center
	-- offset tolerance	

	if entity.walking and not entity.crouch then
		stand_height,st_o,tol,leg_move_speed =
		 3.8, 4, 6, 0.2
	end
	
	local stand_offset = vec2_new(st_o,0)
	
	-- defaults - no leg support
	player_col = 13
	
	mod_tabl(entity, "grounded_mode,ground_is_entity,ground_entity,stand_type/false,false,nil,0")
	 -- floor
	
	ntt_ll.at_target = false
	ntt_rl.at_target = false

	local x_hitbox,y_hitbox = 1.0,1.0

	-- where is landing point
	
	local stand_vec = vec2_normalized(entity.leg_facing)*p1_st_rng
	
	local stand_center, coll_land, away_vector, with_t, other_t_ntt
	
	local function try_find(vec)
		local out
		local vec_rep = {vec,vec + vec2_right*3, vec + vec2_left*3}
		
		for i=1, #vec_rep do
			for j=1, 4 do 
				local t_vec = vec_rep[i] * (j/4)
				coll_land,with_t,out,away_vector,other_t_ntt = unclip(entity, entity.pos + t_vec, 0)
				if (coll_land and out) return true, t_vec
				
			end
		
		end
		
		return false
	end
	
	local did_find, vec = try_find(stand_vec)

	if did_find then
	
		stand_center = entity.pos + vec + away_vector
		away_vector = vec2_normalized(away_vector)

		if entity.jump_cooldown_t <= 0 then	
	
			-- try to stand
			entity.grounded_mode,entity.surface_away,entity.ground_is_entity,entity.ground_pos_entity = 
			true,v2c(away_vector),not with_t, other_t_ntt

		
			-- no clipping
			if with_t then 
				stand_center = stand_center\1 
			else
				stand_center += away_vector*0.75
			end
			
			local run_v = recomp_mul(player.vel, away_vector, 0, 0.4)
			--stand_center -= run_v*2


			if away_vector.x != 0 then
				entity.stand_type = 1 -- wall
			elseif away_vector.y > 0 then
				entity.stand_type = 2 -- ceiling
			end
		
			-- xy flip stuff on wall
			if entity.stand_type == 1 then
				stand_offset.x, stand_offset.y = stand_offset.y, stand_offset.x
				x_hitbox, y_hitbox = y_hitbox, x_hitbox
			end

			-- find default good standing positions
			local right_pos,left_pos = stand_center + stand_offset, stand_center - stand_offset
			
			-- if invalid standing point (in wall or not on ground)
			local function correct(pos, leg) 
				if (point_trn_coll(pos + away_vector*2) or check_coll_ntts(leg, pos + away_vector*2, leg.rds)) or not (point_trn_coll(pos - away_vector*2) or check_coll_ntts(leg, pos - away_vector*2, leg.rds)) then
					return stand_center		
				end
				return pos
			end

			right_pos = correct(right_pos, ntt_rl)
			left_pos = correct(left_pos, ntt_ll)
			
			
			-- position targets if needed
			local function check_leg_target(target,center)
				local offset = target.pos - center		
				
				if entity.stand_type == 1 then
					offset.x, offset.y = offset.y, offset.x
				end
				
				if abs(offset.x) > tol or abs(offset.y) > 5 then
					target.state = 0 -- invalid
				elseif abs(offset.x) <= solo_distance then
					target.state = 3 -- solo-ing (in the middle)
				elseif sgn(offset.x) >= 0 then
					target.state = 2 -- right
				else
					target.state = 1 -- left
				end
			end
			
			
			local function position_leg_target(target, other_t, leg, center)
				if target.state == 0 then
					
					if other_t.state == 2 then
						target.pos = left_pos
					elseif other_t.state == 1 then
						target.pos = right_pos 
					else
						local offset_l_x = leg.pos.x - entity.pos.x
						-- default - closer to leg
						if sgn(offset_l_x) >= 0 then
							target.pos = right_pos 
						else
							target.pos = left_pos 
						end
					end
					
				elseif target.state == 3 then
					-- good lmao
					
				elseif target.state == other_t.state then
					
					-- if i'm the further one
					local c = center.x
					local m = target.pos.x
					local o = other_t.pos.x
					if entity.stand_type == 1 then
						c = center.y
						m = target.pos.y
						o = other_t.pos.y
					end
					
					local me_further = abs(m - c) >= abs(o - c)
					
					
					if me_further then
						target.pos = right_pos
						if (other_t.state == 2) target.pos = left_pos
					end		
				end
				
				-- otherwise ok	
				check_leg_target(target, center)
			end
			
			check_leg_target(ntt_rl_t, stand_center)
			check_leg_target(ntt_ll_t, stand_center)
			
			position_leg_target(ntt_rl_t, ntt_ll_t, ntt_rl, stand_center)
			position_leg_target(ntt_ll_t, ntt_rl_t, ntt_ll, stand_center)
			

			-- targets are ok now
			local function move_leg(leg, target)
				
				if abs(target.pos.x - leg.pos.x) < x_hitbox and abs(target.pos.y - leg.pos.y) < y_hitbox  then
					leg.vel *= 0.9
					leg.pos = target.pos
					leg.at_target = true
					leg.terrain_normal = v2c(away_vector)
					update_stand(leg)
					
				else
					printh("move " .. leg.id .. "  " .. t())
					local move_vec = vec2_normalized(target.pos - leg.pos) * leg_move_speed
					counter_mmnt(move_vec, leg, entity)
					dampen_vel(leg, 0.1, entity)

				end
			end

			-- move legs to targets
			move_leg(ntt_rl,ntt_rl_t)
			move_leg(ntt_ll,ntt_ll_t)
			
			-- transfer_v1
			local t_v1,t_v2 = 0.90,0.10
			
			if ntt_rl.is_stnd or ntt_ll.is_stnd then -- really is standing 
		
				-- player's stand info will be updated later automatically

				
				--custom friction
				entity.vel *= 0.96
				ntt_uh.vel *= 0.96
				ntt_ra.vel *= 0.95
				ntt_la.vel *= 0.95

				
				if (ntt_rl.is_stnd) ntt_rl.vel *= 0.75
				if (ntt_ll.is_stnd) ntt_ll.vel *= 0.75


				if vec2_len(ntt_ra.vel) < 0.04 then
					ntt_ra.vel *= 0
					ntt_ra.pos = vec2_center(ntt_uh.pos\1+vec2_new(1,4))
						ntt_ra.special_stand = true
				end
				if vec2_len(ntt_la.vel) < 0.04 then
					ntt_la.vel *= 0
					ntt_la.pos = vec2_center(ntt_uh.pos\1+vec2_new(-1,4))
					ntt_la.special_stand = true
				end

				player_col = 12
								
				t_v1,t_v2 = 0.70,0.30
				
				if ntt_rl.is_stnd and ntt_ll.is_stnd then -- and is standing on both legs	
					entity.vel *= 0.70
					ntt_uh.vel *= 0.70
					t_v1,t_v2 = 0.65,0.35
					entity.special_stand = true
					ntt_uh.special_stand = true
				end
				
		-- wallstand
			elseif ntt_rl.is_tch or ntt_ll.is_tch then
			
				entity.vel *= 0.95
				entity.uh.vel *= 0.95		

			end -- of leg stand check
				
			
			-- stabilise pos
			local stand_p_lh = vec2_center(stand_center\1 + away_vector*stand_height)
			local stand_p_uh = vec2_center(stand_p_lh + vec2_normalized(away_vector + run_v)*(2 + tonum(not player.crouch) * (anim_c\48)%2))
			
			if entity.crouch then
				stand_p_lh -= away_vector * 4
				stand_p_uh -= away_vector * 4
			end
			
			if away_vector.x != 0 then

			else
				entity.pos.y = entity.pos.y*t_v1 + stand_p_lh.y*t_v2
				
				ntt_uh.pos.x = ntt_uh.pos.x*t_v1 + stand_p_uh.x*t_v2
				ntt_uh.pos.y = ntt_uh.pos.y*t_v1 + stand_p_uh.y*t_v2
			end
			
		
		end -- of jump cooldown check
						
	end -- of if_coll

end





function player_control(player, b0,b1,b2,b3,b4,b5) -- buttons are bools
	
	-- local refs
	local p_rl,p_ll,p_ra,p_la,p_uh = 
	player.rl,player.ll,player.ra,player.la,player.uh

	
	local b0i,b1i,b2i,b3i,b4i,b5i = 
	tonum(b0),tonum(b1),tonum(b2),tonum(b3),tonum(b4),tonum(b5)

	-- controls
	
	local v_x,v_y = 0,0
	
	local input_dir =	vec2_left  * b0i
																	+ vec2_right * b1i
																	+ vec2_up    * b2i
																	+ vec2_down  * b3i
	
	local input_dir_n = vec2_normalized(input_dir)
	local input_dir_l = vec2_limit(input_dir)
	
	-- defaults
	player.walking = false	
	player.crouch = false
	if (b3) player.crouch = true
	
	-- process timers
	
	if (player.jump_cooldown_t > 0) player.jump_cooldown_t -= 1
	if (player.jump_control_t > 0) player.jump_control_t -= 1
	if (player.stuck_timer > 0) player.stuck_timer -= 1

	local stand = player.is_stnd
	
	-- unstuck
	if player.grounded_mode and not stand then
		if player.stuck_timer <= 0 then		
			p_ll.pos = player.ll_target.pos
			p_rl.pos = player.rl_target.pos
			printh("sike")
			player.stuck_timer = 15
		end
	else
		player.stuck_timer = 15
	end
	
	
	
	-- regen stamina
	if (player.stmn < player.stmn_l_t) player.stmn += 0x0.008
	
	
	local can_jump = (player.grounded_mode and (vec2_len(p_rl.pos - player.rl_target.pos) < 4.5 or vec2_len(p_ll.pos - player.ll_target.pos) < 4.5))
	local j_scale = 1
	
	-- grabbing -----------------------------------
	
	if btn(5) then
		local input_dir_h = vec2_normalized(input_dir_l + vec2_right * tonum(player.is_right) * 0.2 + vec2_left * tonum(not player.is_right) * 0.2)
		
		local hold_pos = player.pos + input_dir_l*10

		counter_mmnt(input_dir_h/16, p_ra, p_uh)
		
		if not player.in_grab then	
			counter_mmnt(input_dir_h/24, p_la, p_uh)
		end
		
		
		local function slowdown(ntt, f)
			ntt.vel *= 1*0.3 + f*0.7
		end
		

		-- todo cleanup
		local function arm_grab(arm)

			local grab = false

			local function att_grab_tile(pos)	
				local t = mget(pos.x\8, pos.y\8)

				if fget(t,1) then --grabbable
					-- convert tile to entity
					local t_e = tile_to_entity(pos\8)
					
					grab = true
					arm.tch_trn = false
					arm.tch = t_e
				elseif fget(t, 2) and vec2_len(player.vel) < 4 then
					if player.jump_cooldown_t <= 0 then
						slowdown(arm, 0.6)				
						slowdown(p_uh, 0.3)		
						slowdown(player, 0.3)
						slowdown(p_rl, 0.3)
						slowdown(p_ll, 0.3)
						v_x += 0.2
						v_y += 0.2
						can_jump = true
						j_scale = 0.7
					end
					

				end
			end


			if player.in_grab then
				if arm.is_tch or fget(mget(arm.pos.x\8, arm.pos.y\8), 2) then
					slowdown(arm, trn_slp)				
					slowdown(p_uh, trn_slp)				
				end
			else
				if arm.is_tch then
					if arm.tch_trn then
						att_grab_tile(arm.tch)
					else
						if arm.tch.mass < 3 and arm.tch.rds < 10 and not player.in_grab then
							grab = true
						else
							slowdown(arm, trn_slp)
							slowdown(p_uh, trn_slp)		
						end
					end
				else
					att_grab_tile(arm.pos)
				end
			end
		
			if grab then -- take the thing
				sfx(20)
				player.in_grab = true
				grab_e = arm.tch
				player.grabbed_e = grab_e
				player.grabbed_coll_on = grab_e.coll_mask_on
				player.grabbed_coll_see = grab_e.coll_mask_see
				
				grab_e.coll_mask_on = player.coll_mask_on
				grab_e.coll_mask_see = player.coll_mask_see
				
				make_link(p_uh,grab_e,1,4,false,10)
			end
		
		end
		
		arm_grab(p_ra)
		arm_grab(p_la)
		
		local hold_str = 0.15
		
			-- rotate grabbed object
		local function arm_hold(arm, hold_grab)

			if player.in_grab and hold_grab then
			
				local grab_e = player.grabbed_e
				local diff = grab_e.pos - hold_pos
				local diff_l = vec2_limit(diff)
				local mmnt = diff_l * hold_str
				
				apply_momentum(p_uh, mmnt/2)
				apply_momentum(player, mmnt/2)
				apply_momentum(grab_e, -mmnt)
				
				grab_e.vel = grab_e.vel*0.8 + p_uh.vel*0.2

			elseif arm.is_tch then
			
				slowdown(player,0.9)
				apply_momentum(p_uh,input_dir * hold_str * 0.8)
				slowdown(p_uh,0.8)
				
				apply_momentum(arm,-input_dir * hold_str * 0.4)
				slowdown(arm,0.6)
			end
			
		end
		
		arm_hold(p_ra, false)
		arm_hold(p_la, true)
			
	else
	
		-- throw
		local throw_str = 1.5
	
		local function arm_throw(arm)
			if player.in_grab then
				local grab_e = player.grabbed_e
				player.in_grab = false
				if vec2_len(input_dir) <= 0 then
					sfx(21)
				else
					sfx(22)
					-- extra move so doesn't immediately clip in player
					move_and_unclip(grab_e, input_dir_n * 7)
					local throw_vel = throw_str
					throw_vel = min(throw_vel/grab_e.mass, 3)
					counter_mmnt(input_dir_n * throw_vel*grab_e.mass, grab_e, p_uh)
				end
				grab_e.coll_mask_on = player.grabbed_coll_on
				grab_e.coll_mask_see = player.grabbed_coll_see
				player.grabbed_e = nil
				delete_link(p_uh,grab_e)
			end
		end
		
		arm_throw(p_ra)
		arm_throw(p_la)
	end
	
	
	
	-- walking/air move -----------------------------------

	local vel_limit = p1_h_a_spd_lmt
	
	if player.grounded_mode and player.surface_away.y != 0 then 
		v_x += 1 - 0.5*tonum(b3) -- movement
		vel_limit = p1_h_g_spd_lmt
	else -- air drift
		v_x += 0.04		
	end
	
	if player.grounded_mode then
		if b0 or b1 then
			player.walking = true
			player.is_right = false 
			if (b1) player.is_right = true
			player.stmn -= 0x0.002
		end
	end
	

	local v_p_x,v_n_x,v_p_y,v_n_y = v_x,v_x,v_y,v_y
	
	v_p_x = max(0, min(v_p_x, vel_limit - player.vel.x))
	v_n_x = max(0, min(v_n_x, vel_limit + player.vel.x))
	
	v_p_y = max(0, min(v_p_y, vel_limit - player.vel.y))
	v_n_y = max(0, min(v_n_y, vel_limit + player.vel.y))
	
	
	local pv_add = vec2_new(
	v_p_x * tonum(btn(1)) - v_n_x * tonum(btn(0)) ,
	v_p_y * tonum(btn(3)) - v_n_y * tonum(btn(2))
	)
	
	foreach_in_do(player.m_l_prim, apply_vel, pv_add)
	if (player.grounded_mode and player.surface_away.y != 0) then
		foreach_in_do(player.m_l_legs, apply_vel, pv_add/3)
	else
		foreach_in_do(player.m_l_legs, apply_vel, pv_add*1.5)
	end

	if (b0 or b1) and stand then 
		player.vel.y -= 0.03
		p_uh.vel.y -= 0.03
	end

	-- jumping -----------------------------------
	
	if btn(4) and player.jump_cooldown_t <= 0 then -- try to jump
	
		local jump_vel,surface_normal,did_jump=v2c(vec2_zero),v2c(vec2_up),false
		
		-- jump control	
		local input_dir_j = vec2_normalized(vec2_up*0.3 + input_dir)
		if (player.surface_away.x != 0) input_dir_j += player.surface_away * 0.3
		input_dir_j.y *= 2
		
		local function do_jump()
			did_jump = true
		
			printh("jump'd")
			player.jump_cooldown_t=9 -- 10 frames of jump cooldown
			player.jump_control_t=10 -- 10 frames of jump control
			
			jump_vel = vec2_normalized(input_dir_j) * p1_jump * j_scale
		end
	
		if can_jump then
			
			if vec2_len(player.vel * 0.3) < 1 and player.stmn > player.stmn_l_b then

				player.stmn -= 0x0.05

				surface_normal = player.surface_away
				--surface_normal = surface_normal*0.8 + input_dir*0.2
				
				-- small speed reduction if slamming
				b_mul = 0.2
				
				-- small boost if surfaceboosting
				if (vec2_dot(player.vel, surface_normal) > 0) b_mul = 0.1
				
				-- decomponentize
				player.vel = recomp_mul(player.vel, surface_normal, b_mul, 0.2)
				p_uh.vel = recomp_mul(p_uh.vel, surface_normal, b_mul, 0.2)
				p_rl.vel = recomp_mul(p_rl.vel, surface_normal, b_mul, 0.2)
				p_ll.vel = recomp_mul(p_ll.vel, surface_normal, b_mul, 0.2)

				-- jump start
				do_jump()
				
				printh("surface: " .. surface_normal.x .. "  " .. surface_normal.y)

				jump_vel = jump_vel * 0.90 + vec2_normalized(jump_vel) * vec2_len(projection(jump_vel, surface_normal)) * 0.10

			end
		
		end
		
		-- CAREFUL WHEN JUMPING AFTER GRAB
		if did_jump then
			
			if player.grounded_mode and not player.ground_is_entity then
				local v_i = vec2_len(projection(player.vel, surface_normal))
				local impct = v_i*v_i*player.total_mass
				local brk, new_e = trn_impact(player.ground_pos_entity,impct + vec2_len(jump_vel)*0.43)	
				if brk then
					player.ground_is_entity = true
					player.ground_pos_entity = new_e
				end
			end
		
		
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
				local j_v1,j_v2 = split_vector(jump_vel*1.5, player.total_mass, ce_mass)
				jump_vel = j_v1
				player.ground_pos_entity.vel -= j_v2
				
			
				sfx(12)
			else
				sfx(10 + flr(rnd(2)))
				
			end

			foreach_in_do(player.m_l_prim, apply_vel, jump_vel)
			foreach_in_do(player.m_l_legs, apply_vel, jump_vel*0.5)
			foreach_in_do(player.m_l_arms, apply_vel, jump_vel*0.75)
		end
	
	end

	-- jump control
	if (player.jump_control_t > 0 and not btn(4)) then
		player.vel *= 0.9
		p_uh.vel *= 0.9
	end
	
	
	-- rotation -----------------------------------

	-- alignment direction
 local align_up   = vec2_up
 local align_down = vec2_down
	
	if not player.grounded_mode then

		if btn(4) then -- can stay tilted
			align_up=player.facing+input_dir_l			
			align_down=player.leg_facing+vec2_new(player.vel.x * 0.01,0) - input_dir_l
		else
			local input_dir_down=v2c(input_dir_l)
			input_dir_down.x = -input_dir_down.x*0.1
			input_dir_down.y = 0
			align_up = player.facing*0.25 + vec2_up*0.45 + input_dir_l*0.2
			align_down = player.leg_facing*0.40 + vec2_down*0.60 + vec2_new(player.vel.x*0.20,0) - input_dir_down
		end

	end
	
	-- slight mixing to prevent weird bending (jump and hold down)
	align_up, align_down = align_up*0.8-align_down*0.2, align_down*0.8-align_up*0.2
	
	
	player.facing = vec2_limit(align_up)
	player.leg_facing = vec2_limit(align_down)

	local ll_link = entity_links[p_ll.id][player.id]
	local rl_link = entity_links[p_rl.id][player.id]
	ll_link.len = 5.5
	rl_link.len = 5.5
	
	if not player.grounded_mode and not player.is_stnd then
	
		counter_mmnt(vec2_normalized(player.facing) / 10, p_uh, player)
	
		local align_vec = vec2_normalized(player.leg_facing) / 16
	
		counter_mmnt(align_vec, p_rl, player)
		counter_mmnt(align_vec * 0.75, p_ll, player)

		
		if not player.grounded_mode then
			ll_link.len = 5
			if btn(4) then
				ll_link.len = 3
				rl_link.len = 5
			end
		end
	end
 
end



__gfx__
00000000aaaaa99a9aaaaaaa89aa9998a988889900000002000000022222222215666651000000000d020d000000000000000000000000000000000000000000
00000000a98888888888898898888882882112890000002222222222221111225d11d1dd00000000dddd6d6d0000000000000000000000000000000000000000
00000000999899999988998998888882898882880000020202020202222222226551111d000000000d0206000000000000111000000000000000000000000000
00000000988888888888888898888882921111282000002220202022211111126115d116000000002d222d200000000000151000000000000000000000000000
00000000888888888888888998888882888888890200020202020202222222226d1d111d000000000d020d0000000000001dd000000000000000000000000000
00000000988888888888888998888882882112892222222222222222221111226111d515000000006d6ddddd0000000000100000000000000000000000000000
0000000098888882888888889888888298882888222222222222222222222222d551d1d10000000006020d000000000000100000000000000000000000000000
0000000098888222882222888222222899888989222222222222222222222222d1165111000000000d000d000000000000000000000000000000000000000000
77777770899888888888888888888888888888981111111120000002000200005d6666d500000000111111110056650000000000000000000000000000000000
70000077a988888888888888888888888888888a111111112200002200020000d151111d00000000121161620d7666d000000000000000000000000000000000
70000707a999888888888988888888888998999a11111111202002020002020065111d5d00000000111116115776ddd500111000000000000000000000000000
70007007988988889889999888888888888888991111111120022002020202006111d5560000000021122112666ddd55001dd000000000000000000000000000
70070007a999998888898888888888888899999a111111112002200202020200651d511d000000001121111166dddd5100150000000000000000000000000000
70700007a988888888888999888888888888988a11111111202002020202020061551115000000006162112256ddd55100100000000000000000000000000000
7700000799998998888888888888888888889999111111112200002202022220511d515500000000161111110dd5551000100000000000000000000000000000
0777777798898888888888888888888888888899111111112000000202022200d5d6dd5100000000222122210055110000000000000000000000000000000000
11111111aaaaa99a9aaaaa99a9a9a9a9a2a2a2a21111111122222221020202000000000000000500000000000000000000000000000000000000000000000000
22222222a98888888888988898889888922222221222122222222211020202000000000000006dd0000000000000000000000000000000000000000000000000
1111111199989999998999898898889888988898111111112111111122220200000000000006d0d6000000000000000000000000000000000000000000000000
22222222888888888888888888888889888282892212221222222211022222205d6666d5006d0000000000000000000000000000000000000000000000000000
88222828988889989989988888888888888882881111111121111111020202006d555ddd06d00000000000000000000000000000000000000000000000000000
2222222288888888888888888888888888888888122212222222221102020200600000065d000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888881111111111111111022202006000000606d00000000000000000000000000000000000000000000000000000
8888888888888888888888888888888888888888222122212221111102020200d000000d00600000000000000000000000000000000000000000000000000000
888888880a0a0a0a2a2a2a2a92022029999999992222211121111121222222222222222122222121000000000000000000000000000000000000000000000000
88288828292929299999999999022099292222922111121221111121222222222111111122121212000000000000000000000000000000000000000000000000
22222222aaaaaaaaaaaaaaaa92922929009009002111211221111121222222222222211121212111000000000000000000000700000000000000000000000000
28882888002222009a9229a992099029222992221111111221111121222222225d6666d55d6666d5000000000000000000070700000000000000000000000000
222222220002200029a99a9292099029222992221111111221222221222222226d555ddd6d555ddd000000000000000000000000000000000000000000000000
1111111100022000292aa29292922929009009001121111221111111222222226221111662111116000000000000000000000000000000000000000000000000
212222220022220099a99a9999022099292222922222222211111111222222226111111661211116000000000000000000000000000000000000000000000000
11111111999999999a2222a99202202999999999111111112221222122222222d211111dd111111d000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002111100000000000000000000000000000000
aa000000000aaaaa00000000000000aa000000000000000000000000000000000000000000000000000000000002111111110000000000002210000000000000
00aa00000aaa000000000000000aaaa0000111000000011100000000000000000000000000000000000000000022111111111111000002222211000000000000
00000000000000000aaaa00000000000000111100000011100000110000000000000000000000000000000000021111111111111002222221111100000000000
00000000000000000000000000000000000111100011011100011111000000000000000000000000000000000221112111111111222221112211110000000000
0990000000aaaaa00000000000000000000111100011011100011111000001100000000000000000000000000212112111111111221112222211111000000000
000000000aa999aa0000990000000000000111100011011100011111001101110000000000000000000000002212112111111111112222222211111100000000
00000000aaaa99999900000000aa0000110111100011011111011111001101110000000000000000000000002122111111111111222222221111111100000000
0000099aaa9999999aa00000aaa0a090111111101111111100000000001111110000000000000000000000002122111100000000222221112211111100000000
099999aa9999999999aa000aa99a9a09111111101111111100000000011111110000000000000022221100001222111100000000221112222211111100000000
00aaaaaa99aaaa999999a0aa99999990111111111111111100000000011111110000000000000222221100001222111100000000112222222211111100000000
0aaaaaa9aaa99aaa99999a999a999990111111101111111100000000111111110000000000000222221100002221111100000000222222221111111100000000
aaaa999aa999999a9999999aa99aa999111111111111111100000000111111110000000002222222211111112221112100000000222221112211111100000000
aa9999aa999aaa9999aaa9999aaa9a9a111111111111111100000000111111110000000022222222211111112212112100000000221112222211111100000000
a99aaaaa99aaa9999aa9999999a9a9aa111111101111111100000000111111110000000022222222211111112212112100000000112222222211111100000000
99aaaaa99aa999999999999999aaaaa9111111101111111100000000111111110000000021212121211111112122111100000000222222221111111100000000
9aaa99999999999990090900aaa99999000000000000000000000000000000000000000022222222211111110000002221000000000000000000000000000000
aaa9999999999aaaaaaa9090a00aaaa9000000000000000000000000000000000000000021112121211111110000222221110000000000000000000000000000
a9999aa9999aaaa999aaa9090aa99999000000000000000000000000000000000000000022222222211111110022221121111100000000000000000000000000
99999999999999999a99aa00aa9aa999000000000000000000000000000000000000000021212121211111112222111121111111000000000000000000000000
aaaaaaa999999999909999a0a9aa9990000000000000000000000000000000000000000022222222211111112211121121111111000000000000000000000000
aaaa999009099999090900009a999909000000000000000000000000000000000000000021212111211111111222111121111111000000000000000000000000
a99090099099999990900aa900909090000000000000000000000000000000000000000022222222211111112211121121111111000000000000000000000000
9909090009aa99990000aa9000000000000000000000000000000000000000000000000021112111211111111222111121111111000000000000000000000000
1117511100000000000000008888888911dd11110000000011111777988898890000000000000000000000002211121100000000000000000000000000000000
11751711000000000000000098a98a981ddd111100000000111777578a87a8980000000000000000000000001222111100000000000000000000000000000000
15757171000000000000000089a97a981dd5d111000000001575651787a97aa80000000000000000000000002211121100000000000000000000000000000000
557617150000000000000000add7a9881d5777710000000057565171aa7777780000000000000000000000001222111100000000000000000000000000000000
5765555700000000000000008ddd99981177aa9900000000517511718977aa990000000000000000000000002211121100000000000000000000000000000000
175177710000000000000000d5ddaaa817a77911000000001757171197a779980000000000000000000000001222111100000000000000000000000000000000
7577155100000000000000008d5d98881a1a971100000000757175118a8a97890000000000000000000000002211121100000000000000000000000000000000
571155110000000000000000d5888988911911910000000057115111988988980000000000000000000000001222111100000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000d4e400b4c400000000000000000034040000000024
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000095a500d5e500b55500000000000064000400003400142434
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000096a654d5e5b6b55574447464545455442414053505152526
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000096a675d5e5b7b55575455555755555553616350506163505
__gff__
0001010101000000030004000000000000010101010000000300040000000000010101010100000002000000000000000101010101000000020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525252515151500080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525252515152122020200000000000000000000000000000000000000000000000000000000000001222223222222222222250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000002535353525353503262603131214000000000000000000000000000000000000000000000000000000000000111313131313131313131a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000002536363625363602151513131314000000000000000000000000000000000000000000000000000000000000111313131313131313131a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000017000000000000000000000000000000000000252525252525250215150113021400000000000000000000000000000000000000000000000000000000000011131313131313131313250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000027000000000000000000000000000000000000253535352535350326260313131200000000000000252525150000000000000000000000000000000000000011131313131313131313250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000027000000000000000000000000000000000000253636362536362515151113121425252525151500253525150000000000000000000000000000000000000011131313131313131313142626262603030326260303032626030000000000000000000000000000000000000000000000000000000000000000
000000000000000a000000000000000000000000000000000000252525252525252515151113131425252525153508253625070738000000000000000000000000000000000011131313131313131314350000000003040300001600160000000000000000000000000000000000000000000000000000000000000000000000
000000000000000a000000000000000000000000000000000000253535352635350326260112131425252525012322232223230202000000000000000000000000000000000011131313131313131314252626262603030326260303030000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0a0a0000000000000000000000000000000000253636362536360115151113131225262625121330301330301214000000000000000000000000000000000011131313131313131314250000000000000000000304030000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a030a0000000000000000000000000000000000252525252525250415151113131425252525111337371315151214000000000300000000000000000000000011131313131313131314350000000000000000000303030000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0a0a0000000000000000000000000000000000253535352535350115151213131425252525111320201320201314000000000300000000000000000000000011131313131313131313140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000a000000000700000000000000000000000000263636362536360326261113121425252525121213131313131314000000001600000000000000000000000011131313131313131313140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000a000000000a00170000000000000000000000252525252525252515150313021225252525111330301230301314000000001600000000000000000000000011142323232323231113140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000a000000000a00270000000000000000000000253535352535352515151113131425262625111337371337371314000000001600000000000000000000000011142615151515151113140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000030a0a0a0a030a030000000000000000000000253636362536030323030102010125252525111320201320201314000000001600000000000000000000000811141535001515351113140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000270000002a160a270000000000000000000000250303251a25252515153625252525252525121313131313131314000000001600000000000017000008081811143737151515361113140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000027000000001600270000000000000000000003253535351a35352515151525252525252525032323232323232323000000001600002828380727001818081811131302252502020213140303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000027000000000300170000000000000000000016253636361a36362515151525252525252525152526252525251515000000000301242323222202020202020202030303252503030303140303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818080000000027000000001600270000000000000000000016252525251a25252515151818012104022525152525252525251515000000001603031313030303030335350703030303151515151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0121232204000027000000001608270000000000000000000102240225252525252515181818111312143625152525253525251515030303001635252515151516353515151515151515151515151515150000000000000003000300000300000300000003000005060606060000000000000000000000000000000000000000
1113131314000027000000000303030000000000000028381113130423232323232323232324030303030236032525253625251503030303031635352515151516151515151515151515150303151515151500030303000016001600001600001600000016000037030303030303030303000000000000000000000000000000
0313131314060607050606060303031800000017050601031213131313131313131313131313131313232322232222232121232103021213122302352515151516151515151515151515151515151515151503030303000016001600001600001600000016000001031313030000000003030303030303030303030303030303
1113131314210223230303033316331818080027073711131313131313131313131313131313131313131313131313131313131313131313131313232122232316151515150715151515151515151515150303030303232323020200001600001627000016001711031313030000000000000000000000000000000000000000
1112031314020212220134012202323132313132313111121313131313131313131313131313131313131313131313131313131313131313131313131313131302222225220202252503032525250102020203030303131313131302022222220202020016002703131313140000000000000000000000000000000000000000
1113131313131212030333033303330016000016000011131313131313131313131313131313131313131313131313131313131313131313131313131313131313131325252525252525252525251313131313131313131313131313131313131313131313131311131313140000000000000000000000000000000000000000
1113131313131313030333033303330016000316000011121313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313041313131313131313131313131313131313131313131313131313131311030303140000000000000000000000000000000000000000
__sfx__
0010000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c072300133202336043
001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002300021000210002005022050
000380003f3043e05338033320032e0622a04226022220711c05118021120010e0600803004010020003eb673ab3734b1730b762ab4626b1620b751ab4516b1510b640a3500a0500a0500a0500a0500a0500a050
011180001075010750107501d7501f750000002eb0730b1732b1734b3634b2730b2734b3736b673e3000201004020060300604008040080400201002010028762eb762eb662cb662ab762eb0730b2734b3736b47
01108000000000000000000000000000000000000001a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a051
01108000000000000000000000001a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a051
0111800010105101050e174243540a1441833406124029643e06338033320032c87322071180110a00038b072ab2318b050ab2400b6338a332aa132ea032ea622aa5228a4226a1224a2224a1222a1222a1222a12
520080003f6103f6103f6100e6100e6100e6100e6100e610356103561036610366103761037610376103761000000376003760037600376103761037610376103761037600376003760037600376003760037600
4b0200003d6103d6303d6303d6203d6103d6103d6103c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52010000143200d31109311093112062020620206200d33020320253303d6203d610396103561510615066152a6050d6033b6033f6033f6053f6053f6053f6053f6053e6053f6053f6053f605006050060500000
52010000143200d3110a3110a31019620196200d3303863025330253203e6203d6102b6101c610166100f61005610036000060000600006000000000000000000000000000000000000000000000000000000000
52010000143710d361043510135100340366502533025340366403664036640366303663036630366303663036630366303663536635366253663536645366353662536625366103661000000000000000000000
500100001533008330034200042001620016100161000610006100461009600096000960009600096000960009600000000000000000000000000000000000000000000000000000000000000000000000000000
50010000193600d350063500335001340013400363003630036200562009610096100961009610096100861007610066100661005610056000460000000000000000000000000000000000000000000000000000
5a020000183730537301373016700566002660086600f6500165006645056450064004630086300663004620036200762006625056250162503610036100c6100261304613056150061500615086150061408614
080200001007008070030700006000050156700f6700c6600b6650b6550a655096400863007630066300562004620046250361502615016150161002610016100161301613006150061500615006150061400614
4801000014300105000c6000a30007400056000460006600064000640006600046000060000600006000960009600000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030200000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
0a0100001275016760197601b75022750257502774000000000002c6602c6602c6402c630000003b6503b6303b6303b6253b6203b6203b6103b61500000000001370017700187001c70000000000000000000000
0a0100003b6303b6303b6303b6303b6303b6303c6002c6202c6202c6202c6202c6202c6200000025745227501f7501b7401774514730127200f7200f720000000000000000000000000000000000000000000000
080200000f64014641186311d610156532a730227601e750167400f7300a720087100371003710037100300000601000030060400600006010300004700037000070000700000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
981200000331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f3200331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f320
991200000131001310013100131001310013100131001310013100c3200c3200c32012320123200f3200f32001310013100131001310123200f3200131012320013100f320013100131016320153200131014320
4a1200002e6152e6052e6152e60037615396002e6152e6150000037615000000000037615000002e600376152e6152e6052e6152e60037615396002e6152e6152e61537615000000000037615000002e61537615
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000245002430024200241002415004000e4500e4300e4200e4100e415004050040500405004050040500405004050040500405004050040500405004000240002400094000940015400154001540015400
001000000e15000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000215502100001000e155001000d10002155021550215002155021550e1500e100001000f100021000210002100001000010002100021000e1000e1000010000100001000010000100001000010000100
001000001d75019750137500f7500f750107501075010750107201172011710117001870018700187001b700197001970019700197001970019700197001a7001e700217001a7000070000700007000070000700
00100000053550735505355073550a3550c3551635518355000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000018430184300c4310c4301f4301f4001d4321d4321d4321d2321d2221d2221d2121d2121d2020000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000053550735505355073550a3550c355073550c355073550a3550c3550f3551135513355163551835500000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003f7003f7003e7003e7003d7003b7003870035700327002d70027700227001c70017700107000b70008700057000270002700017000170001700017000170001700017000170002700007000070000700
0010000005355073550a3550c35511355133551635518355000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001100001075010750107501d7501f750000001870000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000018430184300c4310c4301f430366031143211432114321123211232112321123211232112320000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000001895000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 20226260
02 21226261
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344
00 70424344

