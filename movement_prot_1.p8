pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

--movement prototype


--some abbreviations

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


function _init()
printh("start------------")

	--init global vars

	debug_visuals = true
	
	mod_tabl(_ENV,"trn_bnc,trn_slp,grav/0.4,0.4,0.14")

	mod_tabl(_ENV,"b_lmt_x,t_lmt_x,b_lmt_y,t_lmt_y/-400,2000,-2000,400")

--global player vars
	mod_tabl(_ENV,"p1_jump,p1_h_g_spd_lmt,p1_h_a_spd_lmt,p1_st_rng/3.1,2,1,8")
 --jump, ground/air speed limit, stand range


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
	
end

tugs_per_frame=0
MAC_per_frame=0
frame_c = 0

function _update()
	frame_c += 1
	
	if frame_c>=30then
		printh("tugs in second: "..tugs_per_frame)
		tugs_per_frame=0
		printh("MAC in second: "..MAC_per_frame)
		MAC_per_frame=0
		frame_c=0
	end


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
  local follow_x = player.pos.x + player.vel.x +
		tonum(player.is_right) * 16 - tonum(not player.is_right) * 16
		
		local follow_y = player.pos.y + player.vel.y
		
	 player_control(player, btn(0),btn(1),btn(2),btn(3),btn(4),btn(5))
	 
	 local camera_tolerance = 8
	 local camera_center = vec2_new(camera_x + 64, camera_y + 64)
	 -- move camera to player
		
		-- separate x & y
	 local distance = vec2_new(
	 	abs(camera_center.x-follow_x),
	 	abs(camera_center.y-follow_y)
	 )
		
		local speed = distance \ (camera_tolerance * 2)
		
		if abs(follow_x - camera_center.x) > camera_tolerance then
			camera_x += speed.x * sgn(follow_x - camera_center.x)
		end
		
		if abs(follow_y - camera_center.y) > camera_tolerance then
			camera_y += speed.y * sgn(follow_y - camera_center.y)
			camera_y = min(max(camera_y,-64), 128)
		end
	
		camera(camera_x, camera_y)
 end

end
 
function _draw()
	cls(2)
	
	draw_bg(0, 0x0.04 ,0x1 , true)
	draw_bg(1, 0x0.4  ,0x0 , true)

	draw_fall_zone(255)

 draw_map()
	draw_entities()

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
	e.is_right = true
	
	e.grounded_mode = false
	e.ground_is_entity = false
	e.ground_entity = nil
 
	e.walking = false


	e.rl=spawn_entity(px+2,py+6,0.1,0.2)--right leg
	e.ll=spawn_entity(px-2,py+6,0.1,0.2)--left
	e.uh=spawn_entity(px  ,py-2,0.3,0.5)--upper half of body
	e.ra=spawn_entity(px+3,py-1,0.1,0.2)--right arm
	e.la=spawn_entity(px-3,py-1,0.1,0.2)

	local rl,ll,uh,ra,la = e.rl,e.ll,e.uh,e.ra,e.la
	
	make_link(e ,rl,1,5.5,false,0)
 make_link(e ,ll,1,5.5,false,0)	
	make_link(e ,uh,0,2.7,false,0)
	make_link(uh,ra,1,4.5,false,0)
	make_link(uh,la,1,4.5,false,0)
		
	e.total_mass = 1 -- precalculated but all of these added

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


function make_link(e1, e2, link_type, link_len, to_ground, link_strenght)

	local t_l_s = link_strenght or 0
	local t_t_g = to_ground or false

	local link = {
		from = e1,
		to = e2,
		l_type = link_type, -- 0-keep at exact distance, 1-limit max distance, 2-limit min
	 len = link_len,
		to_ground = t_t_g,
		strenght = t_l_s -- 0 means unbreakable
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
	if (e2 == nil) then -- delete ground link
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

function draw_bg(bg_num, scroll_amount,timescroll, wrap)
	
	local tile_x = 0 + bg_num*32
	
	local scroll_x = 0 + camera_x * scroll_amount 
	scroll_x += time()*timescroll
	
	if(wrap) scroll_x %= 256
		
	sspr(tile_x,32,32,16,
	camera_x - scroll_x, camera_y,256,128)
 
 if wrap then
 	sspr(tile_x,32,32,16,
		camera_x - scroll_x + 256, camera_y,256,128)
 end
 
end

function draw_fall_zone(height)
	line(-256, height  , 4096, height  , 2)
	line(-256, height-1, 4096, height-1, 2)
	line(-256, height-3, 4096, height-3, 2)
	line(-256, height-5, 4096, height-5, 2)
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

-- assumes both have same radius
function find_circle_intersections(p1, p2, r)

	local distance = vec2_len(p2 - p1)
	local offset = sqrt(r*r - (distance/2)*(distance/2))
	
	local midpoint = (p1 + p2) / 2 
	
	local ox = offset * (p2.y - p1.y) / distance
	local oy = offset * (p2.x - p1.x) / distance
	
	local k1 = vec2_new(midpoint.x + ox, midpoint.y - oy)
	local k2 = vec2_new(midpoint.x - ox, midpoint.y + oy)

	return k1, k2

end

function line_vec(v1,v2,col) 
	col_t = col or 1
	line(v1.x,v1.y,v2.x,v2.y,col)
end

function line_entity(e1,e2,col) 
	col_t = col or 1
	line_vec(e1.pos, e2.pos, col)
end

function draw_joint(p1, p2, rds, col, is_right)
	local k_1, k_2 = find_circle_intersections(p1, p2, rds)
	
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
	
	local head_pos_center = uh_pos + (ntt.facing*2)
	local head_pos_sprite = head_pos_center + vec2_new(-3.5,-4)
		
	local flip_r = not is_r
	local flip_u = false
	if (not btn(4) and flip_r and btn(1)) flip_r = not flip_r
	if (not btn(4) and not flip_r and btn(0)) flip_r = not flip_r

	if ntt.facing.y > 0.7 then
		flip_u = true
		flip_r = not flip_r
	end
	spr(12, head_pos_sprite.x, head_pos_sprite.y, 1, 1, flip_r, flip_u)
	
	local e_p_s = head_pos_sprite
	if (btn(3)) e_p_s.y += 1

	local e_s = 28
	if (vec2_len(player.vel) > 4) e_s = 44
	
 spr(e_s, e_p_s.x, e_p_s.y, 1, 1, flip_r, flip_u)

	
	if debug_visuals then

		
		if ntt.grounded_mode then
			draw_entity(ntt.rl_target, 7)
			draw_entity(ntt.ll_target,14)
		end
		
		local st_vec = vec2_normalized(ntt.leg_facing)*p1_st_rng
		local did_coll, closest_hit = coll_raycast(ntt_pos, st_vec, 1, 1, ntt, true)
		if did_coll then
			local stand_point = ntt_pos + st_vec*closest_hit
			circ(stand_point.x,stand_point.y,2,12)
		end

	end

	
	-- intersections of 2 cicles
	
	draw_joint(ntt_pos, rl_pos, 2.75, 7, is_r)
	draw_joint(ntt_pos, ll_pos, 2.75, 11,is_r)
	
	draw_entity(ntt.rl, 13)
	draw_entity(ntt.ll, 13)

	draw_joint(uh_pos, ra_pos, 2.25, 7,  not is_r)
	draw_joint(uh_pos, la_pos, 2.25, 11, not is_r)

	draw_entity(ntt.ra, 13)
	draw_entity(ntt.la, 13)
	

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


-->8
-- helper functions

function apply_vel(e,v)
 e.vel+=v
end

function apply_momentum(e, m)
	e.vel+=m/e.mass
end

function apply_counter_momentum(m, e1, e2)
	apply_momentum(e1,m)
	apply_momentum(e2,-m)
end

function split_vector(v, m1, m2)
	return v*m2/(m1+m2),v*m1/(m1+m2)
end

-- multiply components separately
function recomp_mul(v,s,m1,m2)
	local vc = projection(v,s)
	return vc*m1 + (v-vc)*m2,vc*m1,(v-vc)*m2
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


function ray_sq(r_pos, r_dir, sq_pos, sq_rad)

	-- figure out how much param
	local function get_ent_ext(do_x)

		-- position ray in center
		local sq_dist=(sq_pos - r_pos).y
		local r_d = r_dir.y
		if do_x then
			sq_dist=(sq_pos-r_pos).x
			r_d = r_dir.x
		end

		local p1_dist=(sq_dist-sq_rad)/r_d
		local p2_dist=(sq_dist+sq_rad)/r_d

		return min(p1_dist, p2_dist), max(p1_dist, p2_dist)
	end
	
	local enter_x, exit_x = get_ent_ext(true)
	local enter_y, exit_y = get_ent_ext(false)

	if enter_x < enter_y then
		if enter_y <= exit_x then
			return true, enter_y, min(exit_x,exit_y), vec2_new(0,-sgn(r_dir.y))
		end
	else
		if enter_x <= exit_y then
			return true, enter_x, min(exit_x,exit_y), vec2_new(-sgn(r_dir.x),0)
		end
	end

	return false

end


-- less lines but significantly slower
--function sq_sq_coll(p1, r1, p2, r2)

--	local did,ent,ext,norm = ray_sq(p1, p2-p1, p2, r1+r2)

--	if did and sgn(ent) != sgn(ext) then
--		return true, norm
--	end
--	return false

--end

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

		if abs(p1.x-p2.x) > abs(p1.y-p2.y) then
			s_normal = vec2_left * sgn(p2.x - p1.x)
		else
			s_normal = vec2_up * sgn(p2.y - p1.y)
		end

		return true, s_normal
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
			local did, normal = sq_sq_coll(p_t, r_t, other.pos, other.rds)
			
			if (did) return true, other, normal
		end
	end
	return false, nil	
end


function coll_raycast(start_point, move_vec, rds, substeps, who, with_entities)
	local t_r = rds or 0
	local t_steps = substeps or 1

	local max_steps = 5
	
	local did_coll,closest_hit,norm,with_t,coll_entity = false,1,v2c(vec2_up)


	for i=1, max_steps do
		local current_move = move_vec*(closest_hit*0.99)
	
		local did_t, point_t, norm_t = sq_trn_coll(start_point+current_move, t_r)
		
		if did_t then
			local did_r, enter_r, exit_r = ray_sq(start_point, move_vec, point_t, t_r + 4)
			if did_r then 
				did_coll = true
				closest_hit = enter_r
				with_t = true	

				if (enter_r <= 0) break -- inside tile somehow
			else
				printh("wtf.. t" .. i)
			end
			
		elseif with_entities then
			
			local did_e, other_e, norm_e = check_coll_ntts(who, start_point + current_move, t_r)
			-- this norm_e cannot be used as the pos is offseted by move
			
			if did_e then
				local did_r, enter_r, exit_r, norm_ee = ray_sq(start_point, move_vec, other_e.pos, t_r + other_e.rds)
				if did_r then 
					did_coll = true
					closest_hit = enter_r
					norm = norm_ee
					with_t = false
					coll_entity = other_e
					
					if (enter_r <= 0) break -- inside entity somehow
				else
					printh("wtf.. e" .. i)
				end
			else
				break
			end
			
		end
		
	end -- of for

	if with_t then
		norm = vec2_new(-sgn(move_vec.x),-sgn(move_vec.y))
		local h_c = sq_trn_coll(start_point+move_vec*closest_hit*1.1 + vec2_new(norm.x*2, 0), t_r)
		local v_c = sq_trn_coll(start_point+move_vec*closest_hit*1.1 + vec2_new(0, norm.y*2), t_r)
		if h_c or v_c then
			norm.x *= tonum(v_c)
			norm.y *= tonum(h_c)
		end			
	end

	if (closest_hit <= 0) printh("uhoh" .. closest_hit)
	return did_coll, closest_hit*0.99, norm, with_t, coll_entity

end




function tile_to_entity(tile_pos)
	local t_dat,t_set,hitb,mass = mget(tile_pos.x, tile_pos.y),0,3.9,0.5
	
	if t_dat & 0b10000 != 0 then
		t_set = 25
		t_dat -= 16
	end
	
	if t_dat & 0b100000 != 0 then
		hitb = 2.4
		mass = 0.1
	end
	
	mset(tile_pos.x, tile_pos.y, t_set)

	local t_e = spawn_entity(tile_pos.x*8+4,tile_pos.y*8+4,mass,hitb)
	t_e.sprite = t_dat
	t_e.e_type = "tile"
	
	add(entities, t_e)
	return t_e
end


function entity_to_tile(e)
	local prev_tile = mget(e.pos.x\8, e.pos.y\8)
	if prev_tile == 0 then
		mset(e.pos.x\8, e.pos.y\8, e.sprite)
	
	else
		mset(e.pos.x\8, e.pos.y\8, e.sprite + 16)
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


function move_until_collide(entity, move_vec, do_entites)
	-- default results
	local move_precoll,did_collide,with_terrain,coll_e,surface_normal=v2c(vec2_zero),false,false

	-- prevent micromovements
	if vec2_len(move_vec) > 0.01 then
		
		MAC_per_frame += 1
		
		local closest_p
		did_collide, closest_p, surface_normal, with_terrain, coll_e = coll_raycast(entity.pos, move_vec, entity.rds, 1, entity, do_entites)

		if did_collide then
			if closest_p > 1 or closest_p <= 0 then
				printh("UHOH " ..closest_p)
			else			
				move_precoll = move_vec*closest_p
			end
		else
			move_precoll = move_vec*1
		end
		
		-- finally, apply movement
		entity.pos += move_precoll
	end
	
	return move_precoll, did_collide, with_terrain, coll_e, surface_normal
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

-- NO TERRAIN CLIPPING 
function get_out_t(entity)

	local coll = sq_trn_coll(entity.pos, entity.rds-0.5)
	if coll then
	
		local function test_coll(vec)
			local coll = sq_trn_coll(entity.pos + vec, entity.rds)
			if not coll then
				entity.pos += vec
				return true
			end
			return false
		end
		for i=1, 8 do
			local test_vec = vec2_up * i --move by pixels
			if (test_coll(test_vec)) return true, true -- out now
			test_vec = vec2_down * i
			if (test_coll(test_vec)) return true, true
			test_vec = vec2_left * i
			if (test_coll(test_vec)) return true, true 
			test_vec = vec2_right * i
			if (test_coll(test_vec)) return true, true 
		end
		
		return true,false -- too deep idk what to do
	end
	
	return false, false
end

function get_out_e(entity)
	local coll, other, norm = check_coll_ntts(entity, nil, entity.rds)
	
	if coll then
		local diff = entity.pos - other.pos
		local diff_n = projection(diff, norm)
		
		entity.pos += vec2_normalized(diff_n) * ((entity.rds + other.rds) - vec2_len(diff_n) +0.5)
		return true
	end
	
	return false

end

function move_entity(entity)

	-- move
	local move_precoll, did_c, with_t, coll_e, surface_normal = move_until_collide(entity, entity.vel, true)
	if did_c then
	
		if with_t then
			entity.vel = recomp_mul(entity.vel, surface_normal, -trn_bnc, trn_slp)
		else
			transfer_momentum(entity, coll_e, 0.8, 1, true)
			
			-- todo trigger coll events for entities
		end
	end
	
	local clip_e = get_out_e(entity)
	if clip_e then
		printh("ayo -e")
	end
	
	local clip = get_out_t(entity)
	if clip then
		printh("ayo")
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
 else
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
	local tol = 0.3
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
			e1.pos += move_1
			e2.pos -= move_2

			-- equalize velocity components
			transfer_momentum(e1,e2, 0.2, 1)
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
	
	-- leg move parameters
	local stand_height,st_o,tol,leg_move_speed,solo_distance =
		 5.2, 1,	3, 1.5, 2	 
			
 -- preferred offset from center
	-- offset tolerance	

	if entity.walking then
		stand_height,st_o,tol,leg_move_speed =
		 4.2, 3, 6, 2.5
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
	local coll_land, closest_p, away_vector, with_t, other_ntt
	local function try_find()
		coll_land, closest_p, away_vector, with_t, other_ntt = coll_raycast(entity.pos, stand_vec, 0, 1, entity, true)
	end

	try_find()
	
	if not coll_land then
		stand_vec = vec2_normalized(entity.leg_facing+vec2_right*0.5)*p1_st_rng
		try_find()
	end
	if not coll_land then
		stand_vec = vec2_normalized(entity.leg_facing+vec2_left*0.5)*p1_st_rng
		try_find()
	end
	
	local stand_center=entity.pos + stand_vec*closest_p
	
	if coll_land and closest_p > -0.5 then

		if entity.jump_cooldown_t <= 0 then	
		
			-- so is not clipping
			stand_center += away_vector * 0.8
		
			local run_v = recomp_mul(player.vel, away_vector, 0, 1)
			stand_center += run_v*2
			
			-- try to stand
			entity.grounded_mode,entity.surface_away,entity.ground_is_entity,entity.ground_entity = 
			true,v2c(away_vector),not with_t, other_ntt

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
			
			-- if invalid standing point (in wall or not on ground )
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
					local move_vec_precoll = move_towards(leg, target.pos + vec2_up*0.3, leg_move_speed)
					move_until_collide(entity, -move_vec_precoll * leg.mass / entity.mass, true)
				end
			end

			-- move legs to targets
			move_leg(ntt_rl,ntt_rl_t)
			move_leg(ntt_ll,ntt_ll_t)
			
			-- transfer_v1
			local t_v1,t_v2 = 0.90,0.10


			-- now check legs
			if ntt_rl.is_stnd or ntt_ll.is_stnd then -- really is standing 
		
				-- player's stand will be updated later automatically
		
				-- todo figure out a solution for arms
				entity.ra.vel *= 0.98
				entity.la.vel *= 0.98
				
				if (vec2_len(entity.ra.vel) < 0.10) then
					entity.ra.vel *= 0
					--entity.ra.stand_info |= 0b1000
				end
				if (vec2_len(entity.la.vel) < 0.10) then
					entity.la.vel *= 0
					--entity.la.stand_info |= 0b1000
				end
				
				--custom friction
				entity.vel *= 0.75
				ntt_uh.vel *= 0.75
				if (ntt_rl.is_stnd) ntt_rl.vel *= 0.75
				if (ntt_ll.is_stnd) ntt_ll.vel *= 0.75

				player_col = 12
								
				t_v1,t_v2 = 0.80,0.20
				
				if ntt_rl.is_stnd and ntt_ll.is_stnd then -- and is standing on both legs	 		
					t_v1,t_v2 = 0.70,0.30		
				end
				
		-- wallstand
			elseif ntt_rl.is_tch or ntt_ll.is_tch then
			
				entity.vel *= 0.95
				entity.uh.vel *= 0.95		

			end -- of leg stand check
				
			
			-- stabilise pos
			local stand_p_lh = stand_center + away_vector*stand_height
			local stand_p_uh = stand_center + away_vector*(stand_height+2.4)
			
			-- todo unhardcode
			if btn(3) then
				stand_p_lh -= away_vector * 4
				stand_p_uh -= away_vector * 4
			end
			
			if away_vector.x != 0 then

			else
				entity.pos.y = entity.pos.y*t_v1 + stand_p_lh.y*t_v2
				ntt_uh.pos.y = ntt_uh.pos.y*t_v1 + stand_p_uh.y*t_v2
				
				ntt_uh.pos.x = ntt_uh.pos.x*t_v1 + (entity.pos.x + run_v.x*2)*t_v2
			end
			
		
		end -- of jump cooldown check
						
	end -- of if_coll

end

function move_towards(entity, target_pos, vel)
	
	local move_vec = target_pos - entity.pos
	
	if entity.is_stnd and vec2_len(target_pos - entity.pos) > 2 then
		move_vec.y -= 5
	end

	local move_vec_scaled = vec2_normalized(move_vec) * vel
	
	if (vec2_len(move_vec) < vec2_len(move_vec_scaled)) move_vec_scaled = move_vec * 0.97
	
	return move_until_collide(entity, move_vec_scaled, true)
	
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
	
	-- defaults
	player.walking = false	
	
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
	
	
	-- walking/air move -----------------------------------

	local vel_limit = p1_h_a_spd_lmt
	
	if player.grounded_mode and player.surface_away.y != 0 then 
		v_x += 2 -- movement
		vel_limit = p1_h_g_spd_lmt
	else -- air drift
		v_x += 0.04		
	end
	
	if player.grounded_mode then
		if b0 or b1 then
			player.walking = true
			player.is_right = false 
			if (b1) player.is_right = true
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
		foreach_in_do(player.m_l_legs, apply_vel, pv_add/2)
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
		local input_dir_j = player.surface_away * 0.3 + vec2_up*0.1 + input_dir
		input_dir_j.y *= 2
		
		local function do_jump()
			did_jump = true
		
			printh("jump'd")
			player.jump_cooldown_t = 10 -- 10 frames of jump cooldown
			player.jump_control_t = 10 -- 10 frames of jump control
			
			jump_vel = vec2_normalized(input_dir_j) * p1_jump
		end
	
		if player.grounded_mode then
			
			if vec2_len(player.vel * 0.3) < 1 then

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
		
		if did_jump then
		
			if player.ground_is_entity and 
				not (surface_normal.x == 0 and surface_normal.y < 0 and player.ground_entity.is_stnd) then
				-- simulate entity bounce
				local st_m = player.mass
				player.mass = player.total_mass
				transfer_momentum(player, player.ground_entity, 1, 1, true)
				player.mass = st_m
			
				printh("drop kick! technically at least..")	
				local ce_mass = player.ground_entity.mass
				
				-- split jump_vel in 2
				-- prevents troll physics and allows for proper drop kicks
				local j_v1,j_v2 = split_vector(jump_vel*1.25, player.total_mass, ce_mass)
				jump_vel = j_v1
				player.ground_entity.vel -= j_v2
				
			
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
	
	
	


	-- grabbing -----------------------------------
	
	if btn(5) then
		local input_dir_h = vec2_normalized(input_dir + vec2_right * tonum(player.is_right) * 0.2 + vec2_left * tonum(not player.is_right) * 0.2)
		
		local hold_pos = p_uh.pos + input_dir_h*5

		apply_counter_momentum(input_dir_h/16, p_ra, p_uh)
		
		if player.in_grab then
			apply_counter_momentum((hold_pos - p_la.pos)/16, p_la, p_uh)
		else		
			apply_counter_momentum(input_dir_h/24, p_la, p_uh)
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
				end
			end


			if player.in_grab then
				if arm.is_tch then
					arm.vel *=  1*0.3 + (trn_slp)*0.7
					p_uh.vel *= 1*0.3 + (trn_slp)*0.7
				end
			else
				if arm.is_tch then
					if arm.tch_trn then
						
						att_grab_tile(arm.tch)
						
					else
						if arm.tch.mass < 3 and arm.tch.rds < 10 and not player.in_grab then
							grab = true
						else
							arm.vel *=  1*0.3 + (trn_slp)*0.7
							p_uh.vel *= 1*0.3 + (trn_slp)*0.7	
						end
					end
				else
					att_grab_tile(arm.pos)
				end
			end
		
			if grab then -- take the thing
				sfx(15)
				player.in_grab = true
				grab_e = arm.tch
				player.grabbed_e = grab_e
				player.grabbed_coll_on = grab_e.coll_mask_on
				player.grabbed_coll_see = grab_e.coll_mask_see
				
				grab_e.coll_mask_on = player.coll_mask_on
				grab_e.coll_mask_see = player.coll_mask_see
			end
						
					
		
		end
		
		arm_grab(p_ra)
		arm_grab(p_la)
		
		local hold_str = 0.125
		
			-- rotate grabbed object
		local function arm_hold(arm, hold_grab)

			if player.in_grab and hold_grab then
			
				local grab_e = player.grabbed_e
				local diff = grab_e.pos - hold_pos
				apply_counter_momentum(diff * 0.1, p_uh, grab_e)
				
				grab_e.vel = grab_e.vel*0.8 + p_uh.vel*0.2

			elseif arm.is_tch then
				apply_momentum(p_uh,input_dir * hold_str)
				apply_momentum(arm,-input_dir * hold_str * 0.5)
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
					sfx(16)
				else
					sfx(17)
					
					move_until_collide(grab_e, vec2_normalized(input_dir) * 5)
					
					local throw_vel = throw_str
					throw_vel = min(throw_vel/grab_e.mass, 3)
					apply_counter_momentum(input_dir_n * throw_vel*grab_e.mass, grab_e, arm)
					
				end

				grab_e.coll_mask_on = player.grabbed_coll_on
				grab_e.coll_mask_see = player.grabbed_coll_see
				
				player.grabbed_e = nil

			end
		end
		
		arm_throw(p_ra)
		arm_throw(p_la)
	end

		
	-- rotation -----------------------------------

	-- alignment velocity
 local align_up   = vec2_up * 0.2
 local align_down = vec2_down * 0.2
	
	
	if player.grounded_mode and player.stand_type != 1 then -- on or close to ground
	
		--align_down.x += input_dir.x * 0.2
	elseif player.grounded_mode and player.stand_type == 1 then
		--align_down -= player.surface_away * 0.5
	else

		
		if btn(4) then -- can stay tilted
			align_up = player.facing * 0.99 + vec2_up * 0.01
			align_down = player.leg_facing * 0.98 + vec2_down * 0.01 + vec2_new(player.vel.x * 0.01,0)
		else
			align_up = player.facing * 0.25 + vec2_up * 0.45
			align_down = player.leg_facing * 0.10 + vec2_down * 0.90 + vec2_new(player.vel.x * 0.20,0)
		end

		local grab_link_r = entity_links[p_ra.id][p_ra.grabbed_id]
		local grab_link_l = entity_links[p_la.id][p_la.grabbed_id]

		if btn(4) then	
			align_down -= input_dir * 0.50
		else
			align_down.x += input_dir.x * 0.20
			align_down.y -= input_dir.y * 0.70
		end

	end
	
	align_up += input_dir * 0.2
	


	-- slight mixing to prevent weird bending (jump and hold down)
	align_up, align_down = align_up*0.7 - align_down*0.3, align_down*0.7 - align_up*0.3
	
	
	player.facing = vec2_normalized(align_up)
	player.leg_facing = vec2_normalized(align_down)
	
	local ll_link = entity_links[p_ll.id][player.id]
	local rl_link = entity_links[p_rl.id][player.id]
	ll_link.len = 5.5
	rl_link.len = 5.5
	
	if not player.grounded_mode then
	
		apply_counter_momentum(player.facing / 10, p_uh, player)
	
		local align_vec = player.leg_facing / 16
	
		apply_counter_momentum(align_vec, p_rl, player)
		apply_counter_momentum(align_vec * 0.75, p_ll, player)

		
		if not player.grounded_mode then
			ll_link.len = 4.8
			if btn(4) then
				ll_link.len = 3.0
				rl_link.len = 4.5
			end
		end
	end



 
end






__gfx__
00000000aaaaa99a9aaaaaaa89aa9998a98888990000000200000002222222221566665100000000000000000000000000000000000000000000000000000000
00000000a98888888888898898888882882112890000002222222222221111225d11d1dd00000000000000000000000000000000000000000000000000000000
00700700999899999988998998888882898882880000020202020202222222226551111d00000000000000000000000000111000000000000000000000000000
00077000988888888888888898888882921111282000002220202022211111126115d11600000000000000000000000000151000000000000000000000000000
00077000888888888888888998888882888888890200020202020202222222226d1d111d000000000000000000000000001dd000000000000000000000000000
00700700988888888888888998888882882112892222222222222222221111226111d51500000000000000000000000000100000000000000000000000000000
0000000098888882888888889888888298882888222222222222222222222222d551d1d100000000000000000000000000100000000000000000000000000000
0000000098888222882222888222222899888989222222222222222222222222d116511100000000000000000000000000000000000000000000000000000000
77777770899888888888888888888888888888981111111120000002000200005d6666d522222111000000000000000000000000000000000000000000000000
70000077a988888888888888888888888888888a111111112200002200020000d151111d21111212000000000000000000000000000000000000000000000000
70000707a999888888888988888888888998999a11111111202002020002020065111d5d21112112000000000000000000000000000000000000000000000000
70007007988988889889999888888888888888991111111120022002020202006111d55611111112000000000000000000070700000000000000000000000000
70070007a999998888898888888888888899999a111111112002200202020200651d511d11111112000000000000000000000000000000000000000000000000
70700007a988888888888999888888888888988a1111111120200202020202006155111511211112000000000000000000000000000000000000000000000000
7700000799998998888888888888888888889999111111112200002202022220511d515522222222000000000000000000000000000000000000000000000000
0777777798898888888888888888888888888899111111112000000202022200d5d6dd5111111111000000000000000000000000000000000000000000000000
11111111aaaaa99a9aaaaa99a9a9a9a9a2a2a2a21111111122222221020202000000000000000500000000000000000000000000000000000000000000000000
22222222a98888888888988898889888922222221222122222222211020202000000000000006dd0000000000000000000000000000000000000000000000000
1111111199989999998999898898889888988898111111112111111122220200000000000006d0d6000000000000000000000000000000000000000000000000
22222222888888888888888888888889888282892212221222222211022222205d6666d5006d0000000000000000000000070700000000000000000000000000
88222828988889989989988888888888888882881111111121111111020202006d555ddd06d00000000000000000000000070700000000000000000000000000
2222222288888888888888888888888888888888122212222222221102020200600000065d000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888881111111111111111022202006000000606d00000000000000000000000000000000000000000000000000000
8888888888888888888888888888888888888888222122212221111102020200d000000d00600000000000000000000000000000000000000000000000000000
888888880a0a0a0a0000000092022029999999990000000021111121222222222222211100000000000000000000000000000000000000000000000000000000
88288828292929290000000099022099292222920000000021111121222222222111121200000000000000000000000000000000000000000000000000000000
22222222aaaaaaaa0000000092922929009009000000000021111121222222222111211200000000000000000000000000000700000000000000000000000000
28882888002222000000000092099029222992220000000021111121222222225d6666d500000000000000000000000000070700000000000000000000000000
22222222000220000000000092099029222992220122200021222221222222226d555ddd00000000000000000000000000000000000000000000000000000000
11111111000220000000000092922929009009000211221021111111222222226121111600000000000000000000000000000000000000000000000000000000
21222222002222000000000099022099292222922122112011111111222222226222222600000000000000000000000000000000000000000000000000000000
1111111199999999000000009202202999999999121111122221222122222222d111111d00000000000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa999999999aaaaa99999999999999aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaa99999aaa999999999999999aaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999aaaa99999999999000000000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000111000011000000000000000000000000000000000000000000000000000000000000000000000000000
9999999999aaaaa99999999999999999000000000110111001111100000000000000000000000000000000000000000000000000000000000000000000000000
99999999aaaa99aa9999999999999999000000000110111001111101100000000000000000000000000000000000000000000000000000000000000000000000
9999999aaaaaa999aa99999999aa9999110001100110111001111101100000010000000000000000000000000000000000000000000000000000000000000000
999999aaa99999999aa99999aaa9a999110001110110111001111101100100010000000000000000000000000000000000000000000000000000000000000000
999999aaa999999999aa999aa99a9a99111011110110111001111101111110010000000000000000000000000000000000000000000000000000000000000000
99aaaaaa99aaaa999999a9aa99999999111111111111111101111101111111110000000000000000000000000000000000000000000000000000000000000000
9aaaaaa9aaa99aaa99999a999a999999111111111111111111111101111111110000000000000000000000000000000000000000000000000000000000000000
aaaa999aa999999aa999999aa99aa999111111111111111101111111111111110000000000000000000000000000000000000000000000000000000000000000
aa9999aa999aaa99999999999aaa9a9a111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
a99aaaaa99aaa9999999999999a9a9aa111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
99aaaaa99aa999999999999999aaaaa9111111111111111101111111111111110000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022211100000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002222211111000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222211212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000221212212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000122211212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000221212212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000122211212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000221212212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000122211212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000221212212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000122211212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000221212212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000122211212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000221212212111110000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000122211212111110000000000000000000000000
__gff__
0001010101000000030000000000000000010101010000000300000000000000000101010100000002000000000000000001000101000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525252515151500080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525252515152122020200000000000000000000000000000000000000000000000000000000000001222223222222222222280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000251919192519190326260313121400000000000000000000000000000000000000000000000000000000000011131313131313131313280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000253636362536360215151313131400000000000000000000000000000000000000000000000000000000000011131313131313131313280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525250215150113021400000000000000000000000000000000000000000000000000000000000011131313131313131313280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000251919192519190326260313131200000000000000252525150000000000000000000000000000000000000011131313131313131313280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000253636362536362515151113121425252525151500251925150000000000000000000000000000000000000011131313131313131313142626262603030326260303032626030000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525252515151113131425252525151908253625070738000000000000000000000000000000000011131313131313131314290000000003040300001600160000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000251919192619190326260112131425252525012322232223230202000000000000000000000000000000000011131313131313131314252626262603030326260303030000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000253636362536360115151113131225262625121330301330301214000000000000000000000000000000000011131313131313131314250000000000000000000304030000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525250415151113131425252525111337371315151214000000000300000000000000000000000011131313131313131314290000000000000000000303030000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000251919192519190115151213131425252525111320201320201314000000000300000000000000000000000011131313131313131313140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000263636362536360326261113121425252525121213131313131314000000001600000000000000000000000011131313131313131313140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000170000000000000000000000252525252525252515150313021225252525111330301230301314000000001600000000000000000000000011142323232323231113140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000270000000000000000000000251919192519192515151113131425262625111337371337371314000000001600000000000000000000000011142615151515151113140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000306030000000000000000000000253636362536030323030102010125252525111320201320201314000000001600000000000000000000000811141519001515191113140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001600270000000000000000000000250303252525252515153625252525252525121313131313131314000000001600000000000017000008081811143737151515361113140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001600270000000000000000000003251919192519192515151525252525252525032323232323232323000000001600002828380727001818081811131302252502020213140303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000300170000000000000000000016253636362536362515151525252525252525152526252525251515000000000301242323222202020202020202030303252503030303140303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818080000000000000000001600270000000000000000000016252525252525252515151818012104022525152525252525251515000000001603031313030303030319190703030303151515151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0121232204000000000000001608270000000000000000000102240225252525252515181818111312143625152525251925251515030303001619252515151516191915151515151515151515151515150000000000000003000300000300000300000003000005060606060000000000000000000000000000000000000000
1113131314000000000000000303030000000000000028381113130423232323232323232324030303030236032525253625251503030303031619192515151516151515151515151515150303151515151500030303000016001600001600001600000016000037030303030000000000000000000000000000000000000000
0313131314060606050706060303031800000017050601031213131313131313131313131313131313232322232222232121232103021213122302192515151516151515151515151515151515151515151503030303000016001600001600001600000016000001031313030000000000000000000000000000000000000000
1113131314210223230303033316331818080027073711131313131313131313131313131313131313131313131313131313131313131313131313232122232316151515150715151515151515151515150303030303232323020200001600001627000016001711031313030000000000000000000000000000000000000000
1112031314020212220134012202033434343434343411121313131313131313131313131313131313131313131313131313131313131313131313131313131302222225220202252503032525250102020203030303131313131302022222220202020016002703131313140000000000000000000000000000000000000000
1113131313131212030333033303160016000016000011131313131313131313131313131313131313131313131313131313131313131313131313131313131313131325252525252525252525251313131313131313131313131313131313131313131313131311131313140000000000000000000000000000000000000000
1113131313131313030333033303160016000016000011121313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313041313131313131313131313131313131313131313131313131313131311030303140000000000000000000000000000000000000000
__sfx__
0010000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c072300133202336043
001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002300021000210002005022050
000200003f7003f7003e7003e7003d7003b7003870035700327002d70027700227001c70017700107000b70008700057000270002700017000170001700017000170001700017000170002700007000070000700
011180001075010750107501d7501f750000002eb0730b1732b1734b3634b2730b2734b3736b673e3000201004020060300604008040080400201002010028762eb762eb662cb662ab762eb0730b2734b3736b47
011180001eb751eb751eb751eb751eb751eb751eb751a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a051
011080001eb751eb751eb751eb751a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a0511a051
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
520100003f6103f6103f6100e6100e6100e6100e6100e610356103561036610366103761037610376103761000000376003760037600376103761037610376103761037600376003760037600376003760037600
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53010000143100d31109311093112061020610206100d32020310253203d6103d610396103561510615066152a6050d6033b6033f6033f6053f6053f6053f6053f6053e6053f6053f6053f605006050060500000
52010000163100d3110a3112262022620093201932038610253103e6103d6102b6101c610166100f6100561003600006000060000600000000000000000000000000000000000000000000000000000000000000
52010000143410d331043210134100320366302531025320366203662036620366103661036610366103661036610366103661536615366153661536625366153661536615366103661000000000000000000000
54010000193400f340083400633003330033200962009620096200962009610096100961009610096100b60000000000000000000000000000000000000000000000000000000000000000000000000000000000
08020000120610b0610506301063000632866315653116450b6450b6450a635096300863007620066200562004620046150361502615006153760337603376033760337603376033760337603376033760300000
0a0100001375017750187501c740217402673028720287102c6002c6002c6302c6302c6202c6202c6202c6153b6303b6203b6203b6253b6103b6103b6103b6103b6003b600220002600026000260000000000000
0a0100003b6103b6103b6203b6303b6203b6203c6003c6002c6202c6202c6202c6202c6202c6202c60026715227301f7301b7301673513720117100f7100d7100d7103b600220002600026000260000000000000
0802000003650076510f621166100f05328740217401c73016730107300b720087200472004710047100471004710047150471504700037000370003700037000070000700000000000000000000000000000000
520100000d3230a3230832308313083110b3111231119311256102c6103161036611396113c6153e6153f6153f6153f6153f6053f6053f6053f6053f6053f6053f6053f6053e6053f6053f6053f6050000500005
02010000130501505017050180501a0501c05021050260502805028050240501e0501905015050110500f0500e0500d0500d0500d0500e0500f0500f050100501205014050190401d04022030260302602026020
501200000331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f3200331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f320
501200000131001310013100131001310013100131001310013100c3200c3200c32012320123200f3200f32001310013100131001310123200f3200131012320013100f320013100131016320153200131014320
4a1200002e6152e6052e6152e60037615396002e6152e6150000037615000000000037615000002e600376152e6152e6052e6152e60037615396002e6152e615376152e615000000000037615000002e61537615
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000215502100001000e155001000d10002155021550215002155021550e1500e100001000f100021000210002100001000010002100021000e1000e1000010000100001000010000100001000010000100
010800000245002430024200241002415004000e4500e4300e4200e4100e415004050040500405004050040500405004050040500405004050040500405004000240002400094000940015400154001540015400
001000000e15000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000005355073550a3550c35511355133551635518355000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001d75019750137500f7500f750107501075010750107201172011710117001870018700187001b700197001970019700197001970019700197001a7001e700217001a7000070000700007000070000700
001100001075010750107501d7501f750000001870000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000018430184300c4310c4301f430366031143211432114321123211232112321123211232112320000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000053550735505355073550a3550c3551635518355000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000018430184300c4310c4301f4301f4001d4321d4321d4321d2321d2221d2221d2121d2121d2020000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000053550735505355073550a3550c355073550c355073550a3550c3550f3551135513355163551835500000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003f7503f7503e7503e7503d7503b7503875035750327502d75027750227501c75017750107500b75008750057500275002740017400173001730017300172001720017100171002700007000070000700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0020000018c5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 43431614
02 4b591615
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344
00 63424344

