pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- movement prototype



-- global vars

debug_visuals = true

terrain_bounciness = 0.4
terrain_slipperiness = 0.4

gravity = 0.14


min_bound_x = -400
max_bound_x = 2000
min_bound_y = -2000
max_bound_y = 400

-- global player vars

p1_jump = 3.0

p1_h_g_spd_lim = 1.5 -- ground speed limit
p1_h_a_spd_lim = 1 -- aerial


function _init()
printh("start------------")
 col = 7
 
	camera_x = 32
	camera_y = 128
	camera(camera_x, camera_y)
	init_entities()	
	
end

function init_entities()
	player = spawn_player(132,127 + 64)
	add(entities, player)
	
	
		local ball_1 = spawn_entity(45 + 10,127 + 30, 0.2, 1.7)
		add(entities, ball_1)

		local ball_2 = spawn_entity(45 + 15,127 + 30, 0.2, 2)
		add(entities, ball_2)
		
		local ball_3 = spawn_entity(45 + 10,127 + 24, 0.2, 2)

		add(entities, ball_3)
		

		make_link(ball_1, ball_2, 0, 8, false, 0)
		make_link(ball_2, ball_3, 0, 10, false, 0)		
		make_link(ball_1, ball_3, 0, 8, false, 0)
	
	
		local ball_4 = spawn_entity(130,127 + 14, 3, 11)
		ball_4.bounciness = 1
		ball_4.vel = vec2_new(1.1,0)
		add(entities, ball_4)
		
end

tugs_per_frame = 0
MAC_per_frame = 0
frame_c = 0

function _update()
	frame_c += 1
	
	if frame_c >= 30 then
		printh("tugs in second: " .. tugs_per_frame)
		tugs_per_frame = 0
		printh("MAC in second: " .. MAC_per_frame)
		MAC_per_frame = 0
		
		frame_c = 0
	end



	-- move enttites
	for i=1, #entities do
		local entity = entities[i]
		
		if not is_oob(entity.pos) then
			if entity.e_type == "humanoid" then
				move_humanoid(entity)
			else 
				foreach_in_do(entity.move_list, move_entity)
			end
		end
	end

	-- check entity links (this ordering is important. 
 -- if link checking happened during entity move then the first moved entity
	-- would pull the other much more)
	
	-- this can be iterative. run this for loop multiple times for slightly more accurate link physics
	for j=1, 1 do
		for i=1, #entities do
				foreach_in_do(entities[i].move_list, move_links)
		end
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
-- entity managment

entities={}
player={} -- reference to the controllable entity
player_col=12

entity_id_stack={}
max_entities = 256
for i=0,max_entities+0 do
	add(entity_id_stack,max_entities+1 - i)
end

function take_id()
	return deli(entity_id_stack)
end

function give_id_back(id)
	add(entity_id_stack,id)
end

entity_links={} --physical "ropes" connecting entities
-- works as a set where key is entity's id
-- and value is a list of links (also keyed by id other's id) (both ways are recorded) 
-- each pair can only have 1 link

function spawn_entity(px,py,m,r)
 local entity = {
  id = take_id(),
  
		pos = vec2_new(px, py),
  vel = vec2_new(0,0),
 	
		mass = m or 1,
		
		-- half of edge len if squares
 	radius=r or 1,

		stand_info = 0b00000000, -- what kinds of stand support this entity has. Lowest has highest priority
		-- from lowest: 0-terrain stand, 1-entity stand, 2-link stand, 3-leg stand
		supported_by=nil, -- point (0) or entity (1,2,3)
		
		is_touching = false,
		touching_terrain = false,
		touching = nil,
		
		e_type = "none",
		
		coll_mask_on =  0b00000001, -- those who see one of these layers will detect this entity 
		coll_mask_see = 0b00001111, -- detects those on these layers
		coll_mask_ignore = 0b00000000, -- ONLY temporary set by some functions like grabbing, has priority over see obv
	
 }
	
	-- point to self when asked who moves
	entity.move_list = {entity}
 
 return entity
end

function spawn_humanoid(px,py)
	local e = spawn_entity(px,py,0.3,1)
	
	e.e_type = "humanoid"
	
	
	e.rl_target = spawn_entity(px+2,py+6) --subentity: right leg's target
	e.ll_target = spawn_entity(px-2,py+6)
	
	e.leg_facing = vec2_copy(vec2_down)
	e.facing = vec2_copy(vec2_up)
	e.is_right = true
	
	e.grounded_mode = false
	e.ground_is_entity = false
	e.ground_entity = nil
 
	e.walking = false


	e.rl = spawn_entity(px+2,py+6,0.1,0.2)
	e.ll = spawn_entity(px-2,py+6,0.1,0.2)
	
	local rl = e.rl
	local ll = e.ll
	
	make_link(e, rl,1, 5.5,false,0)
 make_link(e, ll,1, 5.5,false,0)
	

	e.upper_half = spawn_entity(px,py-2,0.3)
	local upper_half = e.upper_half
	
	
	e.ra = spawn_entity(px+3,py-1,0.1,0.2)
	e.la = spawn_entity(px-3,py-1,0.1,0.2)
 local ra = e.ra
	local la = e.la
	
	
	make_link(e, upper_half,0, 2.7,false,0)
	
	make_link(upper_half, ra,1, 4.5,false,0)
	make_link(upper_half, la,1, 4.5,false,0)
	
	
	e.total_mass = 1 -- precalculated but all of these added

	-- subentity mappings. moving them in bulk is a lot easier

	-- maps self too, so don't go deeper than 1 in subentities
 e.move_list = {e, upper_half, rl, ll, ra, la}
 e.m_l_prim = {e, upper_half}
 e.m_l_walk = {e, upper_half, rl, ll}
 e.m_l_legs = {rl, ll}
 e.m_l_arms = {ra, la}
	-- targets are not mapped as their movement is much more custom

	local function set_coll(e)
		e.coll_mask_on = 0b00000010
		-- doesn't collide with other parts
		e.coll_mask_see = 0b00001101
	end

	foreach_in_do(e.move_list, set_coll)

 return e
end

function spawn_player(px,py)
	
 local player_l = spawn_humanoid(px,py)
	
	-- timers
	player_l.jump_cooldown_t = 0
	player_l.jump_control_t = 0
	player_l.stuck_timer = 0
	
	-- vars
	player_l.standing = false
	player_l.surface_away = vec2_copy(vec2_up)
	
	return player_l
end


function make_link(e1, e2, link_type, link_len, to_ground, link_strenght)

	local t_l_s = link_strenght or 0
	local t_t_g = to_ground or false

	local link = {
		to = e2,
		l_type = link_type, -- 0-keep at exact distance, 1-limit max distance, 2-limit min
	 len = link_len,
		to_ground = t_t_g,
		strenght = t_l_s -- 0 means unbreakable
	}
	if(entity_links[e1.id] == nil) entity_links[e1.id] = {}
	
	local e2_id
	if t_t_g then
		e2_id = -1
	else
		e2_id = e2.id
	end
	
	entity_links[e1.id][e2_id] = link
	
	if not t_t_g then -- no need for second link if it's to ground
	
		local link2 = {
			to = e1,
			l_type = link_type,
			to_ground = false,
			len = link_len,
			strenght = t_l_s
		}

		if(entity_links[e2.id] == nil) entity_links[e2.id] = {}
		entity_links[e2.id][e1.id] = link2
		
		return link, link2
		
	end
	return link
	
end

function delete_link(e1,e2)
	if (e2 == nil) then -- delete ground link
		entity_links[e1.id][-1] = nil
	else
		entity_links[e1.id][e2.id] = nil
		entity_links[e2.id][e1.id] = nil
		e2.stand_info &= 0b11111011
	end
	e1.stand_info &= 0b11111011


end

-->8
-- drawing

function draw_bg(bg_num, scroll_amount,timescroll, wrap)
	
	local tile_x = 0 + bg_num*32
	
	local scroll_x = 0 + camera_x * scroll_amount 
	scroll_x += time()*timescroll
	
	if(wrap) scroll_x %= 256
		
 --for i=0,127 do --draw scaled tiles over whole screen
 --	tline(camera_x,i,camera_x+127,i,
 --							124 + scroll_x ,tile_y + i*0x0.04, 0x0.04, 0)
 --end
	
	--
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
	print(vec2_len(player.vel))
end

function draw_entity(entity, col)
	--circfill(entity.pos.x, entity.pos.y, entity.radius, col)

	rectfill(entity.pos.x - entity.radius, entity.pos.y - entity.radius, entity.pos.x + entity.radius, entity.pos.y + entity.radius,col)
	
	if debug_visuals then
		if entity.stand_info != 0 then
			if entity.stand_info & 0b1 != 0 then
				circ(entity.pos.x + entity.vel.x, entity.pos.y + entity.vel.y, entity.radius/2,11)
			else
				circ(entity.pos.x + entity.vel.x, entity.pos.y + entity.vel.y, entity.radius/2,12)		
			end
		else
			circ(entity.pos.x + entity.vel.x, entity.pos.y + entity.vel.y, entity.radius/2,4)	
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

function draw_joint(p1, p2, radius, col, is_right)
	local k_1, k_2 = find_circle_intersections(p1, p2, radius)
	
	if is_right then
		line_vec(p1, k_1, col)
		line_vec(k_1, p2, col)
		--circ(rk_1.x, rk_1.y, 1, 3)
	else
		line_vec(p1, k_2, col)
		line_vec(k_2, p2, col)	
	end

end

function draw_humanoid(entity)
	
	-- locals
	-- all of these are read-only so it's fine
	local ntt_pos = entity.pos

	local ntt_uh_pos = entity.upper_half.pos

	
	local ntt_rl_pos = entity.rl.pos
	local ntt_ll_pos = entity.ll.pos

	local ntt_ra_pos = entity.ra.pos
	local ntt_la_pos = entity.la.pos


	line_entity(entity, entity.upper_half, player_col)
	
	local head_pos_center = ntt_uh_pos + (entity.facing*2)
	local head_pos_sprite = head_pos_center + vec2_new(-3.5,-4)
		
	local flip_r = true
	local flip_u = false
	if (entity.is_right) flip_r = false
	if entity.facing.y > 0.7 then
		flip_u = true
		flip_r = not flip_r
	end
	spr(12, head_pos_sprite.x, head_pos_sprite.y, 1, 1, flip_r, flip_u)
	
	local e_p_s = head_pos_sprite
	if (btn(3)) e_p_s.y += 1
	if (btn(0) and entity.is_right) e_p_s.x -= 1
	if (btn(1) and not entity.is_right) e_p_s.x += 1
	local e_s = 28
	if (vec2_len(player.vel) > 4) e_s = 44
	
 spr(e_s, e_p_s.x, e_p_s.y, 1, 1, flip_r, flip_u)

	
	if debug_visuals then

		
		if entity.grounded_mode then
			draw_entity(entity.rl_target, 7)
			draw_entity(entity.ll_target,14)
		end
		
		local did_coll, closest_hit = coll_raycast(ntt_pos, vec2_normalized(entity.leg_facing)*9, 1, 1, entity, true)
		if did_coll then
			local stand_point = ntt_pos + vec2_normalized(entity.leg_facing)*9*closest_hit
			circ(stand_point.x,stand_point.y,2,12)
		end

	end

	
	-- intersections of 2 cicles
	
	draw_joint(ntt_pos, ntt_rl_pos, 2.75, 7, entity.is_right)
	draw_joint(ntt_pos, ntt_ll_pos, 2.75, 11, entity.is_right)
	
	draw_entity(entity.rl, 13)
	draw_entity(entity.ll, 13)

	draw_joint(ntt_uh_pos, ntt_ra_pos, 2.25, 7,  not entity.is_right)
	draw_joint(ntt_uh_pos, ntt_la_pos, 2.25, 11, not entity.is_right)

	draw_entity(entity.ra, 13)
	draw_entity(entity.la, 13)
	

end

-->8
-- vector implementation

--2d vector operations
function vec2_new(vx,vy)
 a = {x=vx, y=vy}
 setmetatable(a,vec2)
	return a
end

vec2={
	
	--add/sub 2 vectors 	
	__add = function(a,b)
 	return vec2_new(a.x+b.x,a.y+b.y)
	end,
	
	__unm = function(a,b)
 	return vec2_new(-a.x,-a.y)
	end,
	
	__sub = function(a,b)
 	return a + (-b)
	end,
	
	--mul div vector by a scalar
	__mul = function(a,s)
 	return vec2_new(a.x*s,a.y*s)
	end,
	
	__div = function(a,s)
 	return a*(1/s)
	end,
	
	__idiv = function(a,s)
 	return vec2_new(a.x\s,a.y\s)
	end,
	

	__eq = function(a,b)
		return a.x == b.x and a.y == b.y
	end
	
}

-- some basic vectors
vec2_zero  = vec2_new(0,0)
vec2_right  = vec2_new(1,0)
vec2_down  = vec2_new(0,1)
vec2_left = -vec2_right
vec2_up   = -vec2_down

function vec2_copy(vec)
	return vec2_new(vec.x, vec.y)
end

function vec2_len(vec)

	-- alternate way of getting hypotenuse by trigonometry
	-- avoids squaring and rooting
	-- this way is A LOT more precise in nearly all cases 
	-- and does not break at very small or big values 
	-- (og broke when > 200, or > 2000 wih large precision loss)
	
	-- more accurate in almost all cases
	
	local v2 = vec2_copy(vec)
	
	-- take bigger side, otherwise can ultrasmall/ultrasmall and horrible accuracy
	local v2_c = v2.x
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
	if (vec2_len(vec) == 0) return vec2_copy(vec2_zero)
	return vec/vec2_len(vec)
end

function vec2_dot(v1,v2)
	return v1.x*v2.x + v1.y*v2.y
end

-- use atan2() for angle

function vec2_angle(v1,v2) -- gives shortest angle between two vectors
	local angle = atan2(v1.x,v1.y) - atan2(v2.x,v2.y)
	if (angle >  0.5) angle -= 1
	if (angle < -0.5) angle += 1
	return angle
end


function projection(a,b)
	local k = vec2_dot(a,b) / vec2_dot(b,b)
	
	return vec2_new(k * b.x, k * b.y)
end


-->8
-- helper functions

function apply_vel(e,v)
 e.vel += v
end

function apply_momentum(e, m)
	e.vel += m / e.mass
end

function split_vector(v, m1, m2)
	local v1 = v * m2 / (m1+m2)
	local v2 = v * m1 / (m1+m2)

	return v1, v2
end


-- multiply components separately
function recomp_mul(v,s,m1,m2)
	local vc = projection(v,s)
	return vc*m1 + (v-vc)*m2, vc*m1, (v-vc)*m2
end


function apply_counter_momentum(v, e1, e2)
	apply_momentum(e1,v)
	apply_momentum(e2,-v)
end


-- used in collisions and link pulling/pushing
function transfer_momentum(e1, e2, bounciness, slipperiness, square_coll) -- b is from 0 to 1
	local diff = e2.pos - e1.pos
	
	if square_coll then
		if (diff.x > diff.y) then
			diff.y = 0
		else
			diff.x = 0
		end
	
	end

	local e1m = e1.mass
	local e2m = e2.mass
	local total_m = e1m+e2m

	-- find components	
	local tmp, v1_c, v2_c
	-- decomponentizes and multiplies these
	tmp, v1_c, e1.vel = recomp_mul(e1.vel, diff, 1, slipperiness)
 tmp, v2_c, e2.vel = recomp_mul(e2.vel, diff, 1, slipperiness)

	-- for elastic bounce
	local v1_f = v1_c * (e1m - e2m) + v2_c *  2*e2m
	local v2_f = v1_c * 2*e1m       + v2_c *  (e2m - e1m)
	
	-- for sticky collision - equalize velocities
	local final_v = v1_c*e1m + v2_c*e2m
	
	-- readd modified components
	e1.vel += (final_v * (1 - bounciness) + v1_f * bounciness)/total_m
	e2.vel += (final_v * (1 - bounciness) + v2_f * bounciness)/total_m
	
end



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
		local s_normal = vec2_copy(vec2_up)
		
		if abs(p1.x-p2.x) > abs(p1.y-p2.y) then
			s_normal = vec2_left * sgn(p2.x - p1.x)
		else
			s_normal = vec2_up * sgn(p2.y - p1.y)
		end
		
		return true, s_normal
	end
	
	return false

end

function sq_trn_coll(point, radius, find_closest)
	point_max = point+vec2_new(radius,radius)
	point_min = point+vec2_new(-radius,-radius)
	local found = false
	local min_dist = 32000
	local closest = nil
	local closest_n

	-- go over all tiles in rectangle range
	for j=flr(point_min.y/8),flr(point_max.y/8) do
		for i=flr(point_min.x/8),flr(point_max.x/8) do
			local tile = mget(i,j)
			
			if (fget(tile,0)) then -- solid tile
			
				-- test coll
				local p2 = vec2_new(i*8+4,j*8+4)
				local did, normal = sq_sq_coll(point, radius, p2, 4)
				
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

function check_coll_ntts(ntt, pos, radius)
	local p_t = pos or ntt.pos
	local r_t = radius or ntt.radius

	-- ultra slow with lots of entities - limit is about 15
	-- todo maybe check subentities
	-- todo maybe do grid cell separation table
	for i=1, #entities do
		local other = entities[i]
		if other.id != ntt.id and (ntt.coll_mask_see & other.coll_mask_on != 0) then
			local did, normal = sq_sq_coll(p_t, r_t, other.pos, other.radius)
			
			if (did) return true, other, normal
		end
	end
	return false, nil	
end

function ray_sq(r_pos, r_dir, sq_pos, sq_rad)

	-- position ray in center
	
	local rx_1 = (sq_pos - r_pos).x - sq_rad
	-- figure out how much param
	local p1x_dist = rx_1 / r_dir.x

	local rx_2 = (sq_pos - r_pos).x + sq_rad
	local p2x_dist = rx_2 / r_dir.x
	
	
	local ry_1 = (sq_pos - r_pos).y - sq_rad
	-- figure out how much param
	local p1y_dist = ry_1 / r_dir.y

	local ry_2 = (sq_pos - r_pos).y + sq_rad
	local p2y_dist = ry_2 / r_dir.y
	
	local enter_x = min(p1x_dist, p2x_dist)
	local exit_x = max(p1x_dist, p2x_dist)
	
	local enter_y = min(p1y_dist, p2y_dist)
	local exit_y = max(p1y_dist, p2y_dist)
		
	if enter_x < enter_y then
		if enter_y < exit_x then
			return true, enter_y, min(exit_x,exit_y)
		end
	else
		if enter_x < exit_y then
			return true, enter_x, min(exit_x,exit_y)
		end
	end

	return false

end


function coll_raycast(start_point, move_vec, radius, substeps, who, with_entities)
	local t_r = radius or 0
	local t_steps = substeps or 1

	local max_steps = 5
	
	local did_coll = false
	local closest_hit = 1
	local norm = vec2_up*1
	local with_t
	local coll_entity
	


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
			
			if did_e then
				local did_r, enter_r, exit_r = ray_sq(start_point, move_vec, other_e.pos, t_r + other_e.radius)
				if did_r then 
					did_coll = true
					closest_hit = enter_r
					norm = norm_e
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
		local h_c = point_trn_coll(start_point+move_vec*closest_hit*1.2 + vec2_new(norm.x*4, 0))
		local v_c = point_trn_coll(start_point+move_vec*closest_hit*1.2 + vec2_new(0, norm.y*4))
		if h_c or v_c then
			norm.x *= tonum(v_c)
			norm.y *= tonum(h_c)
		end			
	
	end

	if (closest_hit <= 0) printh("uhoh" .. closest_hit)
	return did_coll, closest_hit*0.99, norm, with_t, coll_entity

end




-->8
-- movement

function is_oob(pos)

	if pos.x < min_bound_x or
	   pos.x > max_bound_x or
	   pos.y < min_bound_y or
	   pos.y > max_bound_y then
				return true
	end
	return false
	
end


function move_until_collide(entity, move_vec, do_entites)
	-- default results
	local move_precoll = vec2_copy(vec2_zero)
	local did_collide = false
	local with_terrain = false
	local coll_e
	local surface_normal
	
	-- prevent micromovements
	if vec2_len(move_vec) > 0.01 then
		
		MAC_per_frame += 1
		
		local closest_p
		did_collide, closest_p, surface_normal, with_terrain, coll_e = coll_raycast(entity.pos, move_vec, entity.radius, 1, entity, do_entites)

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



function update_touch(entity, radius)

	local r = radius or entity.radius+1
	
	local coll_t, t_point = sq_trn_coll(entity.pos, r)
	local coll_e, e = check_coll_ntts(entity, nil, r)
	
 if coll_t then
		entity.is_touching = true
		entity.touching_terrain  = true
		entity.touching = t_point
		return true, true, t_point
	elseif coll_e then
		entity.is_touching = true
		entity.touching_terrain  = false
		entity.touching = e
		return true, false, e
	else
		entity.is_touching = false
		entity.touching_terrain = false
		entity.touching = nil
		return false, false
	end

end

function update_stand(entity, do_entities)

 -- check airborne state
	
	
	-- clear ground
	entity.stand_info &= 0b11111110
	-- and entity stands
	if (do_entities) entity.stand_info &= 0b11111101
	
	entity.supported_by = nil -- 1 frame of false movement if it's supported by 2,3 or others but they'll set theirs on the next frame anyway so it's ok
	
	local down_pos = entity.pos + vec2_down*2
	
	-- if not in bounce
	if abs(entity.vel.y) < 0.5 then
	
		if do_entities then
			local touch_e, e = check_coll_ntts(entity, down_pos)
			
			if touch_e and e.stand_info != 0 then -- if standing on a stable entity
				entity.stand_info |= 0b00000010 -- entity stand
				entity.supported_by = e
			end
		end
	
	
	 local touch, point = sq_trn_coll(down_pos, entity.radius)
		if touch then -- and touching ground
		
			local surface_vec = entity.pos - point		
			if vec2_angle(surface_vec, vec2_up) < 0.3 then -- and directly above that ground
				entity.stand_info |= 0b00000001 -- ground stand
				entity.supported_by = point
			else
				entity.vel += vec2_normalized(surface_vec) / 4 -- slide off
			end
			
		end
		

			
	end
	

	
	if (entity.stand_info & 0b00000011 != 0) then -- maybe --if any
		entity.vel.y = 0
	end
	
end

-- NO TERRAIN CLIPPING (entity clipping is ez after ray_sphere implementation)
function get_out_t(entity)

	local coll = sq_trn_coll(entity.pos, entity.radius-0.5)
	if coll then
	
		local function test_coll(vec)
			local coll = sq_trn_coll(entity.pos + vec, entity.radius)
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

function move_entity(entity)

	-- move
	local move_precoll, did_c, with_t, pos_or_e, surface_normal = move_until_collide(entity, entity.vel, true)
	if did_c then
	
		if with_t then
			entity.vel = recomp_mul(entity.vel, surface_normal, -terrain_bounciness, terrain_slipperiness)
		else
			transfer_momentum(entity, pos_or_e, 0.8, 1, true)
			
			-- todo trigger coll events for entities
		end
	end
	
	local clip = get_out_t(entity)
	if clip then
		printh("ayo")
	end
	
	--fall
	local function cascade_fall(entity, rem_depth)
		if rem_depth <= 0 then -- give up, no one falls ig
			return
		end
	
	 -- WARNING: if(0) is true! false and nil are the only false vals
		if entity.stand_info & 0b00000001 != 0 then -- ground stand
			return false-- no fall
		elseif entity.stand_info != 0 then 
			if entity.supported_by != nil then
				return cascade_fall(entity.supported_by, rem_depth-1)
			end
			return false
		else
			entity.vel.y += gravity
			return true
		end
	end
	
	cascade_fall(entity, 4)
	
	
	if entity.stand_info & 0b00000011 == 0 then
  entity.vel *= 0.998 --air friction
 else
		local slip = terrain_slipperiness
		if entity.stand_info & 0b00000010 != 0 then
			--slip = entity.supported_by.slipperiness or 0.5
		end
		
	 entity.vel.x *= 1 * 0.8 + (slip) * 0.2 --ground friction
	end
 
	
	if vec2_len(entity.vel) < 0.09 then -- prevent micromovements
		entity.vel = vec2_copy(vec2_zero)
	end
	
	update_stand(entity, true)
	update_touch(entity)
	
	
end




function move_links(entity)

 -- check for links and pull/push them if needed
 local links = entity_links[entity.id]
 if links != nil then
 	for to_entity_id, link in pairs(links) do
			local distance
			
			if link.to_ground then
				distance = vec2_len(link.to - entity.pos)
			else
				distance = vec2_len(link.to.pos - entity.pos)
			end
 		
 		--if (entity.id==1) printh(distance)
 		
 		-- small tolerance so tug isn't constantly called
			-- todo lower velocity maybe??????
 		if  (distance > link.len+0.3 and link.l_type & 0b10 == 0) 
 		 or (distance < link.len-0.3 and link.l_type & 0b1  == 0)
 		  then
 			-- pull self and other entity
 			tug(entity, link)
 		end
 	end
 end

end



-- called when an entity is outside its link range
function tug(e1,link)
	--printh(e1.id .. " tugs " .. link.to.id)
	
	tugs_per_frame += 1
	
	e1m = e1.mass
	
	e2 = link.to
	local e2_pos = e2.pos
	if (link.to_ground) e2_pos = e2
	
	local diff = e2_pos - e1.pos
	local diff_norm = vec2_normalized(diff)
	local diff_len = vec2_len(diff)
	
	-- the amount that the entities need to move so they stay in proper link range
	local move_need = diff_norm * (diff_len - link.len)
	
	if link.strenght > 0 and vec2_len(move_need) > link.strenght then
		if link.to_ground then
			delete_link(e1)
		else
			delete_link(e1,e2)
		end
		return
	end
	

	

	if link.to_ground then
	
		--
		e1.pos += move_need
		-- remove vel component towards ground
		e1.vel = recomp_mul(e1.vel, e1.pos - e2_pos, 0, 1)
	else
		
		e2m = e2.mass

		-- move proportionally and equalize velocities

		-- the amount each entity needs to move (scalar, positive means move towards the other entity)
		-- i probably got these with an equation so don't question the 1
		local move_1 = move_need/(1 + e1m/e2m)
		local move_2 = move_1 * e1m / e2m -- == move_need/(e2m/e1m)
		
			
		-- move towards (or away)	
		-- used to be slide, outclip is now accurate enough and faster
		e1.pos += move_1
		e2.pos -= move_2

		
		-- equalize velocity components
		transfer_momentum(e1,e2, 0, 1)
		
		-- can add small bounce so they're not super strechable
		
		-- velocity - works as bounce - idk if this should work but it helps in reducing amount of tugs per frame
		e1.vel += move_1 / 4
		e2.vel -= move_2 / 4
		
		--e1.vel *= 0.98
		--e2.vel *= 0.98
		
		local function update_l_stand(e1,e2)
			-- todo fix this need of removing leg support
			e1.stand_info &= 0b11111011
			if (e2.stand_info & 0b1011 != 0 and vec2_len(e1.vel) < 0.15) then
				e1.stand_info |= 0b00000100
				if e1.stand_info & 0b11 == 0 then
					e1.supported_by = e2
				end
				--e1.vel = vec2_copy(vec2_zero)
			end
		end
		
		update_l_stand(e1,e2)
		update_l_stand(e2,e1)

	end
end



function move_humanoid(entity)
	

	-- local variables - help a lot in token reduction
	-- do NOT REASSIGN THESE, they cannot be at left side of an =
	-- ntt_rl = .. NOT OK
	-- ntt_rl.pos = .. is fine tho
	
	-- also do NOT TRY to do this with ntt_rl_pos and the like, it breaks
	
	local ntt_uh = entity.upper_half
	
	local ntt_rl = entity.rl
	local ntt_ll = entity.ll

	local ntt_rl_t = entity.rl_target
	local ntt_ll_t = entity.ll_target

	local ntt_ra = entity.ra
	local ntt_la = entity.la

	foreach_in_do(entity.move_list, move_entity) -- moves comps separately
	
	-- leg move parameters
	local tol = 3 -- offset tolerance		
	local stand_offset = vec2_new(1, 0) -- preferred offset from center
	local leg_move_speed = 1.4
	local stand_height = 5.2	
	local solo_distance = 2
	
	if entity.walking then
		stand_height = 4.9
		tol = 7
		stand_offset = vec2_new(3,0)
		leg_move_speed = 2.3
	end
	

	
	-- defaults - no leg support
	player_col = 13
	
	entity.stand_info &= 0b11110111
	ntt_uh.stand_info &= 0b11110111
	ntt_ra.stand_info &= 0b11110111
	ntt_la.stand_info &= 0b11110111
	
	entity.grounded_mode = false
	entity.ground_is_entity = false
	entity.ground_entity = nil
	entity.standing = false
	entity.stand_type = 0 -- floor
	
	ntt_ll.at_target = false
	ntt_rl.at_target = false

	local x_hitbox = 1.0
	local y_hitbox = 1.0
	

	
	
	-- where is landing point
	local coll_land, closest_p, away_vector, with_t, other_ntt = coll_raycast(entity.pos, vec2_normalized(entity.leg_facing)*9, 0, 1, entity, true)
	if (not coll_land) coll_land, closest_p, away_vector, with_t, other_ntt = coll_raycast(entity.pos, vec2_normalized(entity.leg_facing + vec2_right*0.3)*9, 0, 1, entity, true)
	if (not coll_land) coll_land, closest_p, away_vector, with_t, other_ntt = coll_raycast(entity.pos, vec2_normalized(entity.leg_facing + vec2_left*0.3)*9, 0, 1, entity, true)

	local stand_center = entity.pos + vec2_normalized(entity.leg_facing)*9*closest_p
	
	if coll_land then
	
		entity.ground_is_entity = not with_t
		entity.ground_entity = other_ntt

		if away_vector.x != 0 then
			entity.stand_type = 1 -- wall
		elseif away_vector.y > 0 then
			entity.stand_type = 2 -- ceiling
		end
	
		-- so is not clipping
		stand_center += away_vector * 1
		entity.surface_away = vec2_copy(away_vector)
		
		local run_v = recomp_mul(player.vel, away_vector, 0, 1)
		--stand_center += run_v
		
		if entity.jump_cooldown_t <= 0 then
	
			-- try to stand
			entity.grounded_mode = true

			
			-- xy flip stuff on wall
			if entity.stand_type == 1 then
				stand_offset.x, stand_offset.y = stand_offset.y, stand_offset.x
				x_hitbox, y_hitbox = y_hitbox, x_hitbox
			end

			-- find good standing positions
			local right_pos = stand_center + stand_offset -- default good standing positions for legs
			local left_pos = stand_center - stand_offset
			
			-- if invalid standing point (in wall or not on ground )
			local function correct(pos, leg) 
				if (point_trn_coll(pos + away_vector*2) or check_coll_ntts(leg, pos + away_vector*2, leg.radius)) or not (point_trn_coll(pos - away_vector*2) or check_coll_ntts(leg, pos - away_vector*2, leg.radius)) then
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
					leg.terrain_normal = vec2_copy(away_vector)
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
			



			-- now check legs
			if (ntt_rl.stand_info & 0b11) != 0 or (ntt_ll.stand_info & 0b11) != 0 then -- really is standing 
				
				entity.stand_info |= 0b1000 -- supported by legs
				ntt_uh.stand_info |= 0b1000
				
				
				-- todo figure out a solution for arms
				entity.ra.vel *= 0.98
				entity.la.vel *= 0.98
				if (vec2_len(entity.ra.vel) < 0.10) then
					entity.ra.vel *= 0
					entity.ra.stand_info |= 0b1000
				end
				if (vec2_len(entity.la.vel) < 0.10) then
					entity.la.vel *= 0
					entity.la.stand_info |= 0b1000
				end
				
				--custom friction
				entity.vel *= 0.5
				entity.upper_half.vel *= 0.5

				player_col = 12
				
				-- transfer_v1
				local t_v1 = 0.80
				local t_v2 = 0.20
				
				if ntt_rl.stand_info != 0 and ntt_ll.stand_info != 0 -- and is standing stabily	 
				then				
					t_v1 = 0.70
					t_v2 = 0.30
			
				else

				end
				-- stabilise pos
				
				entity.standing = true
				
				entity.pos.y = entity.pos.y*t_v1 + (stand_center.y - stand_height)*t_v2
				ntt_uh.pos.y = ntt_uh.pos.y*t_v1 + (stand_center.y - stand_height -2.8 )*t_v2
				ntt_uh.pos.x = ntt_uh.pos.x*t_v1 + (entity.pos.x + run_v.x*2)*t_v2
				
				--ntt_la.pos.y = ntt_la.pos.y*t_v1 + (stand_center.y - stand_height+1.2)*t_v2
				--ntt_ra.pos.y = ntt_ra.pos.y*t_v1 + (stand_center.y - stand_height+1.2)*t_v2
				
					-- wallstand
			elseif ntt_rl.at_target or ntt_ll.at_target then
			
				entity.standing = true
			

			end -- of stability at target check
				
		end -- of velocity angle check
						

	end -- of if_coll




end

function move_towards(entity, target_pos, vel)
	
	local move_vec = target_pos - entity.pos
	
	if entity.stand_info & 0b11 != 0 and vec2_len(target_pos - entity.pos) > 2 then
		move_vec.y -= 5
	end

	local move_vec_scaled = vec2_normalized(move_vec) * vel
	
	if (vec2_len(move_vec) < vec2_len(move_vec_scaled)) move_vec_scaled = move_vec * 0.97
	
	return move_until_collide(entity, move_vec_scaled, true)
	
end




function player_control(player, b0,b1,b2,b3,b4,b5) -- buttons are bools
	
	-- local refs
	local p_rl = player.rl
	local p_ll = player.ll
	local p_ra = player.ra
	local p_la = player.la
	local p_uh = player.upper_half
	
	local b0i = tonum(b0)
	local b1i = tonum(b1)
	local b2i = tonum(b2)
	local b3i = tonum(b3)
	local b4i = tonum(b4)
	local b5i = tonum(b5)
	
	-- controls
	
	local v_x = 0
	local v_y = 0
	
	local input_dir =	vec2_left  * b0i
																	+ vec2_right * b1i
																	+ vec2_up    * b2i
																	+ vec2_down  * b3i
																
	
	-- defaults
	player.walking = false	
	


	-- process timers
	
	if (player.jump_cooldown_t > 0) player.jump_cooldown_t -= 1
	if (player.jump_control_t > 0) player.jump_control_t -= 1
	if (player.stuck_timer > 0) player.stuck_timer -= 1

	
	local stand = (player.stand_info & 0b1000) != 0
	
	-- unstuck
	if player.grounded_mode and not stand then
		if player.stuck_timer <= 0 then		
			p_ll.pos = player.ll_target.pos
			p_rl.pos = player.rl_target.pos
			player.stand_info |= 0b1000
			printh("sike")
			player.stuck_timer = 15
		end
	else
		player.stuck_timer = 15
	end
	
	
	-- walking/air move -----------------------------------

	local vel_limit = p1_h_a_spd_lim
	
	if (player.grounded_mode and (b0 or b1)) player.walking = true

	if stand then 
		v_x += 1 -- movement
		vel_limit = p1_h_g_spd_lim
	else -- air drift
		v_x += 0.06		
	end
	
	
	
	if player.standing then
		if (b0) player.is_right = false
		if (b1) player.is_right = true
	end
	

	local v_p_x = v_x
	local v_n_x = v_x
	local v_p_y = v_y
	local v_n_y = v_y
	
	v_p_x = max(0, min(v_p_x, vel_limit - player.vel.x))
	v_n_x = max(0, min(v_n_x, vel_limit + player.vel.x))
	
	v_p_y = max(0, min(v_p_y, vel_limit - player.vel.y))
	v_n_y = max(0, min(v_n_y, vel_limit + player.vel.y))
	
	
	local pv_add = vec2_new(
	v_p_x * tonum(btn(1)) - v_n_x * tonum(btn(0)) ,
	v_p_y * tonum(btn(3)) - v_n_y * tonum(btn(2))
	)
	
	foreach_in_do(player.m_l_prim, apply_vel, pv_add)
	foreach_in_do(player.m_l_legs, apply_vel, pv_add/2)

	if (b0 or b1) and stand then 
		player.vel.y -= 0.03
		p_uh.vel.y -= 0.03
	end

	
	
	
	
	-- jumping -----------------------------------
	
	update_touch(p_ll)
	update_touch(p_rl)
	
	if btn(4) and player.jump_cooldown_t <= 0 then -- try to jump
	
		local jump_vel = vec2_copy(vec2_zero)
		local surface_normal = vec2_copy(vec2_up)
		
		-- jump control	
		local input_dir_j = player.surface_away * 0.3 + input_dir
		input_dir_j.y *= 2

		local function do_jump()
			printh("jump'd")
			player.jump_cooldown_t = 10 -- 10 frames of jump cooldown
			player.jump_control_t = 10 -- 6 frames of jump control
			
			jump_vel = vec2_normalized(input_dir_j) * p1_jump

		end
	
		if player.standing then
			
			if vec2_len(player.vel * 0.4) < 1 then

				--local t_terrain_normal = reference_leg.terrain_normal or (reference_leg.pos - reference_leg.touching)
				surface_normal = player.surface_away
				--surface_normal = surface_normal*0.8 + input_dir*0.2
				
				
				-- small bounce
				b_mul = -0.2
				
				-- not if surfaceboosting
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
		

		if player.ground_is_entity then
			-- simulate entity bounce
			transfer_momentum(player, player.ground_entity, 1, 1, true)

			printh("drop kick! technically at least..")	
			local ce_mass = player.ground_entity.mass
			
			local tot_player_mass = player.mass + p_uh.mass
			local total_mass = tot_player_mass + ce_mass
			
			-- split jump_vel in 2
			-- prevents troll physics and allows for proper drop kicks
			local jump_vel_total = jump_vel
			jump_vel = jump_vel_total * ce_mass / (total_mass)
			local ce_add = jump_vel_total * tot_player_mass / (total_mass)
			player.ground_entity.vel -= ce_add
		end

		foreach_in_do(player.m_l_prim, apply_vel, jump_vel)
		foreach_in_do(player.m_l_legs, apply_vel, jump_vel*0.5)
		foreach_in_do(player.m_l_arms, apply_vel, jump_vel*0.75)

	
	end

	-- jump control
	if (player.jump_control_t > 0 and not btn(4)) then
		player.vel *= 0.9
		p_uh.vel *= 0.9
	end
	
	
	




	-- grabbing -----------------------------------
	
	if btn(5) then
		local input_dir_h = vec2_normalized(input_dir + vec2_right * tonum(player.is_right) * 0.2 + vec2_left * tonum(not player.is_right) * 0.2)
		

		apply_counter_momentum(input_dir_h/22, p_ra, p_uh)
		apply_counter_momentum(input_dir_h/26, p_la, p_uh)
		
		-- make link if touching something
		local function arm_grab(arm)

			if arm.is_touching then
							local grab_link = entity_links[arm.id][arm.grabbed_id]
				
				if arm.touching_terrain then

					--arm.vel *= 1-terrain_slipperiness
					--arm.vel += (e_or_point - arm.pos)

					-- cool alternate way that grabs onto the terrain
					
				 -- check if already grabbing
					if grab_link == nil then -- dont have link or invalid, add this one
						printh("grabbed something!")
						arm.grabbed_id = -1
						make_link(arm, arm.touching, 0, vec2_len(arm.pos - arm.touching), true, 2.5)
					end
				else -- with entity
				 -- check if already grabbing
					if grab_link == nil then
						arm.grabbed_id = arm.touching.id
						make_link(arm, arm.touching, 0, vec2_len(arm.pos - arm.touching.pos), false, 10)
					end
				end
			end		
		end
			
		arm_grab(p_ra)
		arm_grab(p_la)
		
		local input_dir_a = vec2_normalized(input_dir + vec2_up * 0.8) * 0.1
		
		local hold_str = 0.2
		
			-- rotate grabbed object
		local function arm_hold(arm)
			local grab_link = entity_links[arm.id][arm.grabbed_id]
			
			if grab_link != nil then
				if arm.grabbed_id == -1 then -- terrain
					apply_counter_momentum(input_dir * hold_str, p_uh, arm)
					-- todo that but with check with surface norm
					--arm.vel *= 1-terrain_slipperiness
				else
				
					--apply_counter_momentum(input_dir_a * hold_str, grab_link.to, player)
				end
			end
		
		end
		
		arm_hold(p_ra)
		arm_hold(p_la)
			
	else
	
		-- throw
		local throw_str = 1
		
		local function arm_throw(arm)
			local grab_link = entity_links[arm.id][arm.grabbed_id]
			
			if grab_link != nil then
				if arm.grabbed_id == -1 then -- terrain
					delete_link(arm)
				else
					local other_e = grab_link.to
					apply_counter_momentum(input_dir * throw_str, other_e, p_uh)

					move_until_collide(other_e, other_e.vel, true)
					
					delete_link(arm, other_e)
				end
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
			align_down = player.leg_facing * 0.20 + vec2_down * 0.90 + vec2_new(player.vel.x * 0.55,0)
		end

		local grab_link_r = entity_links[p_ra.id][p_ra.grabbed_id]
		local grab_link_l = entity_links[p_la.id][p_la.grabbed_id]

		if grab_link_r != nil or grab_link_l != nil then
		
			align_down.x += input_dir.x * 0.70
			align_down.y -= input_dir.y * 0.70
			
		else
			align_down -= input_dir * 0.50
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
	
	if not player.standing then
	
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
00700700999899999988998998888882898882880000020202020202222222226111111d00000000000000000000000000111000000000000000000000000000
000770009888888888888888988888829211112820000022202020222111111261d1d11600000000000000000000000000151000000000000000000000000000
00077000888888888888888998888882888888890200020202020202222222226d1d111d000000000000000000000000001dd000000000000000000000000000
00700700988888888888888998888882882112892222222222222222221111226111d51500000000000000000000000000100000000000000000000000000000
0000000098888882888888889888888298882888222222222222222222222222d551d1d100000000000000000000000000100000000000000000000000000000
0000000098888222882222888222222899888989222222222222222222222222d116511100000000000000000000000000000000000000000000000000000000
77777770899888888888888888888888888888981111111120000002000200001d66665500000000000000000000000000000000000000000000000000000000
70000077a988888888888888888888888888888a111111112200002200020000d11151d500000000000000000000000000000000000000000000000000000000
70000707a999888888888988888888888998999a1111111120200202000202006dd5111d00000000000000000000000000000000000000000000000000000000
70007007988988889889999888888888888888991111111120022002020202006115115600000000000000000000000000070700000000000000000000000000
70070007a999998888898888888888888899999a1111111120022002020202006d5dd51d01222000000000000000000000000000000000000000000000000000
70700007a988888888888999888888888888988a1111111120200202020202006511111d02112210000000000000000000000000000000000000000000000000
7700000799998998888888888888888888889999111111112200002202022220551d515121221120000000000000000000000000000000000000000000000000
0777777798898888888888888888888888888899111111112000000202022200d1d6d11512111112000000000000000000000000000000000000000000000000
11111111aaaaa99a9aaaaa99a9a9a9a9a2a2a2a21111111122222221020202005d6666d522222111000000000000000000000000000000000000000000000000
22222222a9888888888898889888988892222222122212222222221102020200d151111d21111212000000000000000000000000000000000000000000000000
111111119998999999899989889888988898889811111111211111112222020065111d5d21112112000000000000000000070700000000000000000000000000
22222222888888888888888888888889888282892212221222222211022222206111d55611111112000000000000000000070700000000000000000000000000
8822282898888998998998888888888888888288111111112111111102020200651d511d11111112000000000000000000000000000000000000000000000000
22222222888888888888888888888888888888881222122222222211020202006155111511211112000000000000000000000000000000000000000000000000
8888888888888888888888888888888888888888111111111111111102220200511d515522222222000000000000000000000000000000000000000000000000
8888888888888888888888888888888888888888222122212221111102020200d5d6dd5111111111000000000000000000000000000000000000000000000000
888888880a0a0a0a0000000092022029999999990000000021111121222222220000000000000000000000000000000000000000000000000000000000000000
88288828292929290000000099022099292222920000000021111121222222220000000000000000000000000000000000000000000000000000000000000000
22222222aaaaaaaa0000000092922929009009000000000021111121222222220000000000000000000000000000000000000700000000000000000000000000
28882888002222000000000092099029222992220000000021111121222222220000000000000000000000000000000000070700000000000000000000000000
22222222000220000000000092099029222992220000000021222221222222220000000000000000000000000000000000000000000000000000000000000000
11111111000220000000000092922929009009000000000021111111222222220000000000000000000000000000000000000000000000000000000000000000
21222222002222000000000099022099292222920000000011111111222222220000000000000000000000000000000000000000000000000000000000000000
11111111999999990000000092022029999999990000000022212221222222220000000000000000000000000000000000000000000000000000000000000000
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
0001010101000000030000000000000000010101010000000300000000000000000101010100000003000000000000000001000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525252515151500080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525252515152122020200000000000000000000000000000000000000000000000000000000000001222223222222222222280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252929292529290326260313121400000000000000000000000000000000000000000000000000000000000011131313131313131313280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000253636362536360215151313131400000000000000000000000000000000000000000000000000000000000011131313131313131313280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525250215150113021400000000000000000000000000000000000000000000000000000000000011131313131313131313280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252929292529290326260313131200000000000000252525150000000000000000000000000000000000000011131313131313131313280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000253636362536362515151113121425252525151500252925150000000000000000000000000000000000000011131313131313131313142626262603030326260303032626030000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525252515151113131425252525152808253625070700000000000000000000000000000000000011131313131313131314290000000003040300001600160000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252929292629290326260112131425252525012322232223230202000000000000000000000000000000000011131313131313131314252626262603030326260303030000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000253636362536360115151113131225262625121330301330301214000000000000000000000000000000000011131313131313131314250000000000000000000304030000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252525252525250415151113131425252525111337371315151214000000000300000000000000000000000011131313131313131314290000000000000000000303030000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000252929292529290115151213131425252525111320201320201314000000000300000000000000000000000011131313131313131313140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000263636362536360326261113121425252525121213131313131314000000001600000000000000000000000011131313131313131313140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000170000000000000000000000252525252525252515150313021225252525111330301230301314000000001600000000000000000000000011142323232323231113140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000270000000000000000000000252929292529292515151113131425262625111337371337371314000000001600000000000000000000000011142615151515151113140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000306030000000000000000000000253636362536030323030102010125252525111320201320201314000000001600000000000000000000000811141529001515291113140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001600270000000000000000000000250303252525252515153625252525252525121313131313131314000000001600000000000017000008081811143737151515361113140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001600270000000000000000000003252929292529292515151525252525252525032323232323232323000000001600000000000727001818282811131302252502020213140303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0800000000000000000000000300170000000000000000000016253636362536362515151525252525252525152526252525251515000000000301242323222202020202020202030303252503030303140303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818080000000000000000001600270000000000000000000016252525252525252515152828012104022525152525252525251515000000001603031313030303030328280703030303151515151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0121232204000000000000001608270000000000000000000102240225252525252515282828111312143625152525252925251515030303001629252515151516282815151515151515151515151515150000000000000003000300000300000300000003000005060606060000000000000000000000000000000000000000
1113131314000000000000000303030000000000000000001113130423232323232323232324030303030236032525253625251503030303031629292515151516151515151515151515150303151515151500030303000016001600001600001600000016000037030303030000000000000000000000000000000000000000
0313131314060606050706060303031800000017050601031213131313131313131313131313131313232322232222232121232103021213122302292515151516151515151515151515151515151515151503030303000016001600001600001600000016000001031313030000000000000000000000000000000000000000
1113131314210223230303033316332818000027073711131313131313131313131313131313131313131313131313131313131313131313131313232122232316151515150715151515151515151515150303030303232323020200001600001627000016001711031313030000000000000000000000000000000000000000
1112031314020212220134012202033434343434343411121313131313131313131313131313131313131313131313131313131313131313131313131313131302222225220202252503032525250102020203030303131313131302022222220202020016002703131313140000000000000000000000000000000000000000
1113131313131212030333033303160016000016000011131313131313131313131313131313131313131313131313131313131313131313131313131313131313131325252525252525252525251313131313131313131313131313131313131313131313131311131313140000000000000000000000000000000000000000
1113131313131313030333033303160016000016000011121313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313131313041313131313131313131313131313131313131313131313131313131311030303140000000000000000000000000000000000000000
__sfx__
0010000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c072300133202336043
001000001d75019750137500f7500f750107501075010750107201172011710117001870018700187001b700197001970019700197001970019700197001a7001e700217001a7000070000700007000070000700
000200003f7003f7003e7003e7003d7003b7003870035700327002d70027700227001c70017700107000b70008700057000270002700017000170001700017000170001700017000170002700007000070000700
001000001075010750107501d7501f750000001870000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02010000130501505017050180501a0501c05021050260502805028050240501e0501905015050110500f0500e0500d0500d0500d0500e0500f0500f050100501205014050190501d05022050260502603026010
000200003f7503f7503e7503e7503d7503b7503875035750327502d75027750227501c75017750107500b75008750057500275002740017400173001730017300172001720017100171002700007000070000700
001000000215502100001000e155001000d10002155021550215002155021550e1500e100001000f100021000210002100001000010002100021000e1000e1000010000100001000010000100001000010000100
010800000245002430024200241002415004000e4500e4300e4200e4100e415004050040500405004050040500405004050040500405004050040500405004000240002400094000940015400154001540015400
020300002c6502c6302c6202c6153b6203b6103b6103b615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000e6300e6300e6200e6200e6200e6200e6100e6100e6100e6100e6001e6001e6001f600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000e15000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000005355073550a3550c35511355133551635518355000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
0010000018430184300c4310c4301f430366031143211432114321123211232112321123211232112320000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000053550735505355073550a3550c3551635518355000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000018430184300c4310c4301f4301f4001d4321d4321d4321d2321d2221d2221d2121d2121d2020000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000053550735505355073550a3550c355073550c355073550a3550c3550f3551135513355163551835500000000000000000000000000000000000000000000000000000000000000000000000000000000
501000000331003310033100331003310033100331003310033100d3500d3400d35012350123400f350033200331003310033100331003310033100331003310033100d3500d3400d35012350123400f3500f340
501000000131001310013100131001310013100131001310013100c3500c3400c34012350123400f3500f34001310013100131001310123500f3500131012350013100f350013100131016350013101535014350
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000001885000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 43434044
00 41434344

