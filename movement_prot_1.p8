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
	mod_tabl(_ENV,"p1_jump,p1_h_g_spd_lmt,p1_h_a_spd_lmt,p1_st_rng/3.1,2,1,8")
 --jump, ground/air speed limit, stand range

 -- timers & counters
 mod_tabl(_ENV,"anim_c,max_anim_len/0,2048")
	
	-- use extended map by default
	poke(0x5f56,0x80)


	camera_x,camera_y=32,128
	camera(camera_x,camera_y)
	
	
	load_lvl(0)
	
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

tick_timers = {}

function make_timer(ticks, func, args)
	add(tick_timers, {t=ticks,f=func,a=args})
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
	
	for num,timer in pairs(tick_timers) do
		timer.t -= 1
		if timer.t <= 0 then
			timer.f()
			del(tick_timers,timer)
		end
	end

	update_mus()

	-- update entities
	for num, ntt in pairs(entities) do
		
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
	
	draw_loaded_bg()

	draw_fall_zone(255)

 draw_map()
	draw_entities()
	draw_links()
	draw_ui()
end


--get from starting map
function mget0x20(x,y)
	if (x >= 128 or y >= 64 or x < 0 or y < 0) return 0
	if y < 32 then
		return @(0x2000 + x + y*128)
	else
		return @(0x1000 + x + y*128)
	end
end

function mset0x20(x,y,v)
	if (x >= 128 or y >= 64 or x < 0 or y < 0) return false
	if y < 32 then
		poke(0x2000 + x + y*128, v)
		return true
	else
	 poke(0x1000 + x + y*128)
		return true
	end
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

-->8
-- entity managment

mod_tabl(_ENV, "entities,max_entities,entity_id_stack/{},256,{}")

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
	ntt.update_func = move_entity
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

	e.rl=spawn_entity(px+2,py+6,0.1,0)--right leg
	e.ll=spawn_entity(px-2,py+6,0.1,0)--left
	e.uh=spawn_entity(px  ,py-2,0.3,1)--upper half of body
	e.ra=spawn_entity(px+3,py-1,0.1,0)--right arm
	e.la=spawn_entity(px-3,py-1,0.1,0)

	e.total_mass = 1 -- precalculated but all of these added
	
	local rl,ll,uh,ra,la = e.rl,e.ll,e.uh,e.ra,e.la
	
	make_link(e ,rl,1,5.4,false,0,0,7)
	make_link(e ,ll,1,5.4,false,0,0,11)	
	make_link(e ,uh,1,3.3,false,0,0,5)
	make_link(uh,ra,1,4.5,false,0,0,7)
	make_link(uh,la,1,4.5,false,0,0,11)

	--subentity mappings. moving them in bulk is a lot easier
 e.move_list = {e,uh,rl,ll,ra,la}
	--targets are only mapped here
 e.all_ntts = {e,uh,rl,ll,ra,la,rl_target,ll_target}
 e.m_l_prim = {e,uh}
 e.m_l_walk = {e,uh,rl,ll}
	
 e.m_l_legs = {rl,ll}
 e.l_targets = {e.rl_target,e.ll_target}
 e.l_target_groups = {{e.rl_target,e.ll_target}}
 e.l_t_g_angles = {{0.025,-0.025}}
 e.l_t_g_cooldowns = {0}
 e.m_l_arms = {ra,la}

	local function set_coll(e)
		--doesn't collide with other parts
		mod_tabl(e, "coll_mask_on,coll_mask_see/0b00000010,0b00001101")
	end
	
	foreach(e.move_list, set_coll)

	mod_tabl(e,"in_grab,grabbed_e,grabbed_coll_on,grabbed_coll_see/false,nil,0b00000000,0b00000000")
	e.update_func = move_humanoid

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
	pal(palettes[loaded_level[1][5]+1], 0)
	
	
	local scroll_x = (-offset_x or 0) + camera_x*scroll_a_x
	scroll_x += time()*(timescroll_x or 0)
	local scroll_y = (-offset_y or 0) + camera_y*scroll_a_y
	scroll_y += time()*(timescroll_y or 0)
	
	if(wrap_x) scroll_x %= len_x*8*scale
	if(wrap_y) scroll_y %= len_y*8*scale

	local function map_scaled(ox,oy)
		for	i=0,len_x-1 do
			for	j=0,len_y-1 do
			 local n = mget0x20(m_st_x+i,m_st_y+j)
				sspr((n&0b1111)*8,(n\16)*8,8,8, camera_x-scroll_x+i*8*scale+ox, camera_y-scroll_y+j*8*scale+oy, scale*8,scale*8)
			end
		end
	end
	
	map_scaled(0,0)
	if (wrap_x) map_scaled(len_x*8*scale,0)
	if (wrap_y) map_scaled(0,len_y*8*scale)
	if (wrap_x and wrap_y) map_scaled(len_x*8*scale,len_y*8*scale)


	pal(0)
end


l_bg_scales = {1,2,3,4,5,6,8,12}
l_bg_scrolls_x = {0, 0x.02, 0x.02, 0x.04, 0x0.1, 0x0.1, 0x0.2, 0x0.4, 0x0.8, 1, 1, 0x1.2, 0x1.2, 0x1.4, 0x1.4, 0x1.8}
l_bg_scrolls_y = {0, 0x.02, 0x.00, 0x.04, 0x0.1, 0x0.0, 0x0.2, 0x0.4, 0x0.8, 1, 0, 0x1.2, 0x0, 0x1.4, 0x1.0, 0x1.8}


l_bg_timescrolls = {0,    1, 2, 6, 15, 30, 60, 90,
																				150, -1,-2,-6,-15,-30,-60,-90}

l_bg_angles_x = {0,0.5,0.5,  1,1,   1,  0.5, 0.5}
l_bg_angles_y = {1,  1,0.5,0.5,0,-0.5, -0.5,  -1}


function draw_loaded_bg()

	bg1_index = loaded_level[1][6]*8
 bg2_index = loaded_level[1][6+9]*8

	bg1_scrl_x = l_bg_scrolls_x[loaded_level[1][7] + 1]
	bg1_scrl_y = l_bg_scrolls_y[loaded_level[1][7] + 1]
	bg2_scrl_x = l_bg_scrolls_x[loaded_level[1][7+9] + 1]
	bg2_scrl_y = l_bg_scrolls_y[loaded_level[1][7+9] + 1]

	bg1_scale = l_bg_scales[loaded_level[1][8]   +1]
	bg2_scale = l_bg_scales[loaded_level[1][8+9] +1]
	
	bg1_wrap_x = false or (loaded_level[1][9]   != 0)
	bg1_wrap_y = false or (loaded_level[1][10]   != 0)
	bg2_wrap_x = false or (loaded_level[1][9+9] != 0)
	bg2_wrap_y = false or (loaded_level[1][10+9] != 0)
	
	bg1_offset_x = ((loaded_level[1][11] &0b0111) - (loaded_level[1][11]&0b1000)) * 16
	bg1_offset_y = ((loaded_level[1][12] &0b0111) - (loaded_level[1][12]&0b1000)) * 16

	bg2_offset_x = ((loaded_level[1][11+9]&0b0111) - (loaded_level[1][11+9]&0b1000)) * 16
	bg2_offset_y = ((loaded_level[1][12+9]&0b0111) - (loaded_level[1][12+9]&0b1000)) * 16 
	

	bg1_timescroll = l_bg_timescrolls[loaded_level[1][13]   +1]
	bg2_timescroll = l_bg_timescrolls[loaded_level[1][13+9] +1]
	
	bg1_timescroll_x = l_bg_angles_x[loaded_level[1][14]   +1]
	bg1_timescroll_y = l_bg_angles_y[loaded_level[1][14]   +1]
	bg2_timescroll_x = l_bg_angles_x[loaded_level[1][14+9] +1]
	bg2_timescroll_y = l_bg_angles_y[loaded_level[1][14+9] +1]
	

	draw_bg(bg1_index, 0, 8, 4, bg1_scale, bg1_scrl_x,  bg1_scrl_y,   bg1_timescroll_x * bg1_timescroll, bg1_timescroll_y * bg1_timescroll, bg1_wrap_x,bg1_wrap_y, bg1_offset_x, bg1_offset_y)
	draw_bg(bg2_index, 0, 8, 4, bg2_scale, bg2_scrl_x,  bg2_scrl_y,   bg2_timescroll_x * bg2_timescroll, bg2_timescroll_y * bg2_timescroll, bg2_wrap_x,bg2_wrap_y, bg2_offset_x, bg2_offset_y)

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

	

 -- left side
	-- intersections of 2 cicles
	
	draw_joint(ntt_pos, ll_pos, 5.4/2, 7,is_r)
	draw_joint(ntt_pos, ll_pos+vec2_left*0.5, 5.4/2, 7,is_r)

	pset(ntt.ll.pos.x,ntt.ll.pos.y, 7)
	
	draw_joint(uh_pos, la_pos, 2.25, 15, not is_r)
	pset(ntt.la.pos.x,ntt.la.pos.y, 15)


	


	-- body
	line_vec(ntt_pos, uh_pos, 13)
	
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
	spr(128, head_pos_sprite.x, head_pos_sprite.y, 1, 1, flip_r, flip_u)
	
	--eyes
	local e_p_s = head_pos_center+vec2_new(1-2*tonum(flip_r),-1)
	if (btn(3)) e_p_s.y += 1
	
	if anim_c%(55 + ntt.id) > 3 or vec2_len(ntt.vel) > 0.5 then
		pset(e_p_s.x+1, e_p_s.y, 12)
		pset(e_p_s.x-1, e_p_s.y, 12)
		if vec2_len(player.vel) > 4 then
			pset(e_p_s.x+1, e_p_s.y+1, 12)
			pset(e_p_s.x-1, e_p_s.y+1, 12)
		end
	end


	-- right side
	draw_joint(ntt_pos, rl_pos, 5.4/2, 12, is_r)
	draw_joint(ntt_pos, rl_pos+vec2_right*0.5, 5.4/2, 12, is_r)
	pset(ntt.rl.pos.x,ntt.rl.pos.y, 12)
	
	draw_joint(uh_pos, ra_pos, 2.25, 13,  not is_r)
	pset(ntt.ra.pos.x,ntt.ra.pos.y, 15)
	
	
	if debug_visuals then
		if ntt.grounded_mode then
			draw_entity(ntt.rl_target, 7)
			draw_entity(ntt.ll_target,14)
			
			--local st_point = (ntt.rl_target.pos+ntt.ll_target.pos)/2
			--circ(st_point.x,st_point.y,2,12)
		end
	end

	

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

		for i=1, 10 do
			for j=1, #vec_rep do 
			
				local m_v = vec_rep[j] * i*0.98
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

	local down_pos = entity.pos + vec2_down*1
	
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
		
		-- legs give special stand property

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
	
	if not did_m then
		entity.vel *= 0
	end
	
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
			--printh(e1.id .. " tugs " .. e2.id)

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
	
	-- local references - help a lot in token reduction
	-- do NOT REASSIGN THESE, they cannot be at left side of an =
	-- ntt_rl = .. NOT OK
	-- ntt_rl.pos = .. is fine tho
	-- also do NOT TRY to do this with ntt_rl_pos and the like, it breaks for same reason
	local ntt_uh,ntt_rl,ntt_ll,ntt_rl_t,ntt_ll_t,ntt_ra,ntt_la = entity.uh,entity.rl,entity.ll,entity.rl_target,entity.ll_target,entity.ra,entity.la

	foreach_in_do(entity.move_list, move_entity) -- moves comps separately
	
	entity.special_stand = false
	ntt_uh.special_stand = false
	ntt_ra.special_stand = false
	ntt_la.special_stand = false
	
	-- leg move parameters
	local stnd_height,stnd_angl,tol,leg_speed =
		 unstr"4.0, 0.05,	3, 2"
			
 -- preferred offset from center, in pico8 degrees
	-- offset tolerance	
	
	if entity.walking and not entity.crouch then
		stnd_height,stnd_angl,tol,leg_speed =
		 unstr"3.5, 0.10, 6, 5"
	end

	-- defaults - no leg support
	
	mod_tabl(entity, "grounded_mode,ground_is_entity,ground_pos_entity/false,false,nil")

	if entity.jump_cooldown_t <= 0 then
	
		-- where is landing point
		local stand_vec = vec2_normalized(entity.leg_facing + vec2_limit(entity.vel*0.5))*p1_st_rng	
		local side = false
		local down = false
		local stand_center, coll_land, away_vector, with_t, other_t_ntt
		
		local function try_find(vec, rds)
			local out
			local vec_rep = {vec,vec2_rotate(vec,stnd_angl), vec2_rotate(vec,-stnd_angl)}
			for i=1, #vec_rep do
				for j=1, 4 do 
					local t_vec = vec_rep[i] * (j/4)
					coll_land,with_t,out,away_vector,other_t_ntt = unclip(entity, entity.pos + t_vec, rds)
					if (coll_land and out) return true, t_vec
				end
			end
			return false
		end
		
		
		
		for i=1, #entity.l_target_groups do
		
			if entity.l_t_g_cooldowns[i] <= 0 then					
				local max_dist = -1
				local max_index = 0
				for j=1, #entity.l_target_groups[i] do
				
					local did, t_vec = try_find(vec2_rotate(stand_vec,entity.l_t_g_angles[i][j]), entity.m_l_legs[i].rds)
					
					if did then
						stand_center = entity.pos + t_vec + away_vector
						entity.grounded_mode,entity.surface_away,entity.ground_is_entity,entity.ground_pos_entity = 
						true,vec2_normalized(away_vector),not with_t, other_t_ntt
			
						local dist = vec2_len(entity.l_target_groups[i][j].pos - stand_center)
						if dist > max_dist then
							max_dist = dist
							max_index = j
						end
						if dist > tol then
							entity.l_target_groups[i][j].active = false
						else
							entity.l_target_groups[i][j].active = true
						end
					end
					
					if max_dist > tol then
						entity.l_target_groups[i][max_index].pos = stand_center
						entity.l_target_groups[i][max_index].active = true
						entity.l_t_g_cooldowns[i] = 2
					end
				end
			else 
				entity.l_t_g_cooldowns[i] -= 1
			end
			
		end
		
		if entity.grounded_mode then
			-- try to stand

			-- targets are ok now
			local function move_leg(leg, target)
				local dist = target.pos - leg.pos
				if vec2_len(dist) > 4 then
					if (leg.is_stnd) leg.pos.y -= 2
					move_and_unclip(leg, vec2_limit(dist/leg_speed)*leg_speed)
				else
					leg.pos = target.pos
					leg.vel *= 0
				end
			end
			
			-- move legs to targets
			for i=1, #entity.m_l_legs do
				if (entity.l_targets[i].active)	move_leg(entity.m_l_legs[i],entity.l_targets[i])
			end
			
			
			-- transfer_v1
			local t_v1,t_v2 = 0.93,0.07
			
			if ntt_rl.is_stnd or ntt_ll.is_stnd then -- really is standing 
				-- player's stand info will be updated later automatically
				
				--custom friction
				entity.vel *= 0.96
				ntt_uh.vel *= 0.96
				ntt_ra.vel *= 0.96
				ntt_la.vel *= 0.96
				if (ntt_rl.is_stnd) ntt_rl.vel *= 0.95
				if (ntt_ll.is_stnd) ntt_ll.vel *= 0.95

				if (entity.walking == false) then
					entity.vel *= 0.70
					ntt_uh.vel *= 0.70
					ntt_ra.vel *= 0.70
					ntt_la.vel *= 0.70
				end

				entity.special_stand = true
				ntt_uh.special_stand = true
				t_v1,t_v2 = 0.80,0.20
				
		-- wallstand
			elseif ntt_rl.is_tch or ntt_ll.is_tch then
			
				entity.vel *= 0.95
				entity.uh.vel *= 0.95
				
				if ntt_rl.is_tch and ntt_ll.is_tch then
					entity.vel *= 0.90
					entity.uh.vel *= 0.90
				end
			end -- of leg stand check

			-- stabilise pos
			local stand_p_lh = vec2_center(stand_center\1 + entity.surface_away*(stnd_height + 1*tonum(not player.crouch) * (anim_c\48)%2))
			local stand_p_uh = vec2_center(stand_p_lh + vec2_normalized(entity.surface_away)*(2.6))
			
			if entity.crouch then
				stand_p_lh -= entity.surface_away * 4
				stand_p_uh -= entity.surface_away * 4
			end
			
			if entity.surface_away.x != 0 then

			else
				--entity.pos.x = entity.pos.x*t_v1 + stand_p_lh.x*t_v2
				entity.pos.y = entity.pos.y*t_v1 + stand_p_lh.y*t_v2
				
				ntt_uh.pos.y = ntt_uh.pos.y*t_v1 + stand_p_uh.y*t_v2
				
				ntt_uh.pos.x = ntt_uh.pos.x*t_v1 + entity.pos.x*t_v2
				
				local function stabl_arm(arm,offst)
					if vec2_len(arm.vel) < 0.3 and ntt_uh.pos.y - arm.pos.y < -3 then
						arm.vel *= 0
						arm.pos = (ntt_uh.pos+vec2_new(offst,4.25))
						arm.special_stand = true
					end
				end
				
				stabl_arm(ntt_la, 1)
				stabl_arm(ntt_ra,-1)

			end
				
		end -- of grounded mode check
		
	end -- of jump cooldown check
	
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
	--if player.grounded_mode and not stand then
	--	if player.stuck_timer <= 0 then		
	--		p_ll.pos = player.ll_target.pos
	--		p_rl.pos = player.rl_target.pos
	--		printh("sike")
	--		player.stuck_timer = 15
	--	end
	--else
	--	player.stuck_timer = 15
	--end
	
	
	
	-- regen stamina
	if (player.stmn < player.stmn_l_t) player.stmn += 0x0.008
	
	local jump_s = false
	local j_scale = 1
	
	-- grabbing -----------------------------------
	
	if b5 then
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
						jump_s = true
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
				slowdown(p_uh,0.9)
				
				apply_momentum(arm,-input_dir * hold_str * 0.5)
				slowdown(arm,0.8)
				if arm.is_stnd then
					arm.vel *= 0
					apply_momentum(p_uh,input_dir * hold_str * 0.5)	
				end
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
	
	local jump_g = player.grounded_mode 
		and (vec2_len(p_rl.pos - player.rl_target.pos) < 5 or vec2_len(p_ll.pos - player.ll_target.pos) < 5)
		and player.jump_cooldown_t <= 0 

	
	if b4 and (jump_g or jump_s) then -- jump
	
		local surface_normal = player.surface_away
		
		-- jump control	
		local input_dir_j = vec2_normalized(vec2_up*0.3 + input_dir)
		if (player.surface_away.x != 0) input_dir_j += player.surface_away * 0.3
		input_dir_j.y *= 2
		
		local jump_vel = vec2_normalized(input_dir_j) * p1_jump * j_scale
		jump_vel = jump_vel * 0.90 + vec2_normalized(jump_vel) * vec2_len(projection(jump_vel, surface_normal)) * 0.10

		local surf_mod = (vec2_normalized(jump_vel)+surface_normal)/2
		if vec2_len(projection(player.vel,surf_mod)*0.8) < 1 or vec2_dot(player.vel, jump_vel) >= 0 then

			player.stmn -= 0x0.05

			--surface_normal = surface_normal*0.8 + input_dir*0.2
			
			-- small speed reduction if slamming
			b_mul = 0.3
			
			-- small boost if surfaceboosting
			if (vec2_dot(player.vel, jump_vel) > 0) b_mul = 0.1
			
			-- decomponentize
			player.vel = recomp_mul(player.vel, surf_mod, b_mul, 0.1)
			p_uh.vel = recomp_mul(p_uh.vel, surf_mod, b_mul, 0.1)
			p_rl.vel = recomp_mul(p_rl.vel, surf_mod, b_mul, 0.1)
			p_ll.vel = recomp_mul(p_ll.vel, surf_mod, b_mul, 0.1)

			-- jump start
			printh("jump'd")
			player.jump_cooldown_t=9 -- 10 frames of jump cooldown
			player.jump_control_t=10 -- 10 frames of jump control
			
			
			printh("surface: " .. surface_normal.x .. "  " .. surface_normal.y)

		-- CAREFUL WHEN JUMPING AFTER LADDER GRAB

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
	
	if not player.grounded_mode and not (player.is_stnd and input_dir.x == 0) then
	
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

-->8
-- level managment


l_size_x = 16
l_size_y = 8
l_head_size_x = 10
l_head_size_y = 1

l_start = 12
l_end = 32 

palettes = {
	split"1,2,3,128,132,142,15, 8,9,10,138,7,12,14,13,0",
	split"1,2,9,1,5,13,6, 8,9,10,10,7,12,14,13, 0",
	split"1,131,4,2,8,9,10,3,138,135,143,7,12,14,13,0",
	split"3,2,3,130,5,6,7,8,9,10,11,12,13,14,15,3",
	split"129,2,3,4,5,6,7,8,9,10,11,12,13,14,15,5",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0",
	split"5,7,3,4,5,6,7,8,5,4,3,2,7,14,15,0",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,9",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,6",
	split"11,4,3,4,5,6,7,8,9,10,11,12,13,14,15,4",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,10",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,10",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,15",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,7",
	split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,12"
}

function load_lvl_header(index)
	local header = {}
	
	local map_pos_x =  (index%8) * l_size_x
	local map_pos_y =  (index\8) *(l_size_y + l_head_size_y) + l_start

	local o = 0
	local function add_h(i,n,s)
		add(header,(mget0x20(map_pos_x+i+o,map_pos_y)&n)>>s)
	end 

	-- shape
	add_h(0,0b00000011,0)
	-- extend
	add_h(0,0b00001100,2)
	
	-- mus
	add_h(0,0b11110000,4)
	
	-- pals
	add_h(1,0b00001111,0)
	add_h(1,0b11110000,4)
	
	local function add_bg()
		add_h(2,0b00001111,0)
		add_h(2,0b11110000,4)
		
		add_h(3,0b00000111,0)
		add_h(3,0b00001000,3)
		add_h(3,0b00010000,4)
		
		add_h(4,0b00001111,0)
		add_h(4,0b11110000,4)
		
		add_h(5,0b00001111,0)
		add_h(5,0b01110000,4)
	end
	
 add_bg()
	o = 4
 add_bg()

	return header
	
end
function load_lvl(index)
	loaded_level = {load_lvl_header(index),{}}

	local map_pos_x =  (index%8) * l_size_x
	local map_pos_y =  (index\8) *(l_size_y + l_head_size_y) + l_start

	for j=0, l_size_y-1 do
		for i=0, l_size_x-1 do
		 add(loaded_level[2], mget0x20(map_pos_x+i,map_pos_y+l_head_size_y+j))
		end
	end

	for t_c=0, #loaded_level[2]-1 do
		draw_tile(loaded_level[2][t_c+1], t_c%l_size_x, t_c\l_size_x)
	end


	pal(palettes[loaded_level[1][4]+1], 1)
end


function get_texture(index)
	return (index%32)*4 ,(index\32)*4 +4
end

function tile_spr(s, alt_l, alt_t, random, rs)
	extra_b = (s & 0b11000000) >> 6
	s1 = s & 0b00111111
	
	
	if random and (s1 & 0b100000 != 0) and (s1 & 0b001000 == 0) then -- in bottom left part of spr page
		srand(rs)
		local r = rnd(100)
		-- flip 1st bit
		if (r > 85) s1 ^^= 0b1 
	end
	
	
	if alt_t and not fget(s1,7) then
	 -- alt texture
		s1 += 0b01000000
	end
	
	if alt_l then
		if (extra_b & 0b1) == 0b1 then
			-- flip 3rd bit
			s1 ^^= 0b100
		end
		if (extra_b & 0b10) == 0b10 then
			-- flip 4th bit
			s1 ^^= 0b1000
		end
	end
	


	return s1
end

function draw_tile(t,x,y)
	
	local tiles = {}
	
	local t2 = t & 0b00111111
	local extra_t = (t & 0b11000000) >> 6
	
	local alt_l = (extra_t & 0b1 == 0b1)
	local alt_t = (extra_t & 0b10 == 0b10)
	
	 
	local t_x,t_y = get_texture(t2)
	
	for j=0,3 do
		for i=0,3 do
			add(tiles, mget0x20(t_x+i,t_y+j))
		end
	end
	
	
	for j=0,3 do
		for i=0,3 do
			local mod_tile = tile_spr(tiles[i + j*4 +1], alt_l, alt_t, true, (x*4+i) + (y*4+j)*l_size_x)
		
			mset(x*4+i,y*4+j, mod_tile)
		end
	end		

end


__gfx__
0000000022222221111111112222222289aa9998a9888899aaaaa99aa999aaaa11111111798a7987000000002b2b2b2b05020500167777610000000000000000
000000002222221111111111222222229888888288211289a98888888888888a22222222998aa98a000000003333333355557575611111150000000000000000
000000002111111111111111222222229888888289888288999899999988999911111111a98aa98a00000000bbbbbbbb05020700711111150000000000000000
000000002222221111111111222222229888888292111128988888888888888922222222a98aa98a000000003b3223b325222520711111170000000000000000
000000002111111111111111222222229888888288888889888888888888889988222828a98aa98a0000000023b33b3205020500711111150000000000000000
000000002222221111111111222222229888888288211289988888888888888822222222a98aa98a00000000232bb23275755555711111160000000000000000
000000001111111111111111222222229888888298882888988888888998888288888888a98aa98a0000000033b33b3307020500511111160000000000000000
000000002221111111111111222222228222222899888989888882228888882288888888a98aa98a000000003b2222b305000500666666610000000000000000
00000000111111112001100222222222899888888888889a888888888888888888888888998aa98ab2022023bbbbb3bb65777756167777610000000000000000
00000000222222212201102202000020a988888888888888888888888888888888288828a98aa98ab30220332322223251611115651151550000000000000000
00000000211111112021120200200200a99988888998999a998888888888888822222222a98a998ab23223230030030076111565766111150000000000000000
00000000211121212002200211122111988988888888889a888888888889988828882888a98aa98ab20330232223322271115667711651170000000000000000
00000000211211212002200211122111a999998888999999988888999888889922222222a98aa98ab20330232223322276156115751511150000000000000000
00000000211111212021120200200200a98888888888988aa99998888888888811111111a98aa98ab23223230030030071661116711156160000000000000000
00000000211111212201102202000020999889988888999a889888888888899821222222a9889988330220332322223261156166566151510000000000000000
00000000112222212001100222222222988888888888889aa99aaa9888aaa99a1111111188228822320220233333333356575561511761110000000000000000
00000000000000000000000200000002aaaaa99a9aaaaa9900000000000000000000000028228828a2a2a2a20b0b0b0b00000000000006000000000000000000
00000000000000002222222200000022a98888888888988800000000000000000000000012888888922222222323232300000000000075500000000000000000
0000000000000000020202020000020299989999998999890000000000000000000000001128822288988898bbbbbbbb00000000000750570000000000000000
00000000000000002020202220000022888888888888888800000000000000000000000011128888888282890022220065777756007500000000000000000000
00000000000000000202020202000202988889989989988800000000000000000000000011112888888882880002200075666555075000000000000000000000
00000000000000002222222222222222888888888888888800000000000000000000000022111288888888880002200070000007650000000000000000000000
00000000000000002222222222222222888888888888888800000000000000000000000011111128888888880022220070000007075000000000000000000000
00000000000000002222222222222222888888888888888800000000000000000000000012221112888888883333333350000005007000000000000000000000
02020200000200001111111111111111888888888888888888828882888888820000000022122212b3bbbbb3bbb3bbb322222221222221211111111100000000
02020200000200002222122212221122888888888888888822222222882288880000000022122212b1333313b333b33321111111221212121211717200000000
22220200000202001111111111111111888888888888888882888288888888880000000022122212b3b33b33b331333122222111212121111111171100000000
02222220020202002212221221122112888888888888888822222222282222820000000022122212333333333111311165777756657777562112211200000000
02020200020202001111111111111111888888888888898888828882888288880000000022122212b3333331bbb1bbb375666555756665551121111100000000
0202020002020200122212221211122288888888988999982222222282222222000000002212221233b33b31b333b33172211117721111177172112200000000
02220200020222201111111111111111888888888889888882888288888882880000000022122212313333113331b33171111117712111171711111100000000
02020200020222002221222122212221888888888888899922222222228222220000000022122112331113113311331152111115511111152221222100000000
0000000000000000000000000000000000000000000000008aaa9988888888210000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000a9988888899888820000000000000000000000000000000055766555555555555555555555555555
000000000000000000000000000000000000000000000000a9889888888888820000000000000000000000000000000000006660000000000000000000000000
000000000000000000000000000000000000000000000000a8888888888888880000000000000000000000000000000015766511111111111000000000000000
00000000000000000000000000000000000000000000000098988888888888880000000000000000000000000000000077776777777777777110000000000000
00000000000000000000000000000000000000000000000098888888888888880000000000000000000000000000000066666666666666666667100000000000
00000000000000000000000000000000000000000000000088888888888828880000000000000000000000000000000077777777777777777777771000000000
00000000000000000000000000000000000000000000000088888888888888880000000000000000000000000000000066666666666666666666666700000000
00000000000000000000000000000000000000000000000088888888888888888828888800000000000000000000000066666666666666666666666666600000
00000000000000000000000000000000000000000000000088888888888888828228288800000000000000000000000066666666657111111111115611170000
00000000000000000000000000000000000000000000000088888888888822822812282800000000000000000000000065111156671111111111111611111000
00000000000000000000000000000000000000000000000088888888888888822812282200000000000000000000000061111116611111111111111611111100
00000000000000000000000000000000000000000000000088888888882888822212112800000000000000000000000061177116611111111111111611111110
00000000000000000000000000000000000000000000000088228888888888221211121800000000000000000000000061711716611111111111111611111111
00000000000000000000000000000000000000000000000028888888888882212121212100000000000000000000000061111116651111111111117611111115
00000000000000000000000000000000000000000000000012882222222222112111211100000000000000000000000061177116666677777777776677777777
000000020021002100001001010012002a2aa2a22a22aa2a00000000000000000000000000000000bb233322bbb2232261711716666666666000000000000000
10000021022110121021001011012010aaaaaaaaaaaaaaaa00000000000000000000000000000000b332222bb333322b61111116666666666000000000000000
102012120121100201020021120221029aaa99a9aa9a9aaa000000000000000000000000000000003322bb22333332b361177116666666666600000000000000
121012200210112102120201200201219a9a99899a99a99a00000000000000000000000000000000222b33323333222261711716666666666600000000000000
11211200121010121212121221202122898998989998a98900000000000000000000000000000000bb22332b22222bbb61111116666666666660000000000000
12212101202110222102221221212212988a89989898898900000000000000000000000000000000333222bb332bbb3351111115555555555550000000000000
22012102212112212221222221222121989a89899889889800000000000000000000000000000000332bbb23322b333366555566666666666660000000000000
1221211211212121122221222222212288988889888888980000000000000000000000000000000032bb33322222333355555555555555555550000000000000
22112212212122112122221222122121888888888898888800000000000000000000000000000000bbb22b222222b23300000000000000000000000000000000
21212122122121212122212212121121888888988988988800000000000000000000000000000000bb33b33bbb2bb32200000000000000000000000000000000
221112122122112121222122121212228888889888888988000000000000000000000000000000003332333bb332322b00000000000000000000000000000000
1212211212212122222222122112121288988888888898980000000000000000000000000000000033322322232b222200000000000000000000000000000000
21212111212212212212221121222212898888888988989900000000000000000000000000000000b23322bbb2b332bb00000000000000000000000000000000
12121112121211222212212122221222898888889888889800000000000000000000000000000000332b2bb333232bbb00000000000000000000000000000000
1211212112121121222121221222121288888888888988890000000000000000000000000000000032b33b333332bb3300000000000000000000000000000000
12112121221221222221222222222212888888888888888800000000000000000000000000000000222322333322233300000000000000000000000000000000
0000000000000000056666505d6666dd000000000000000000666600000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000561e11655181e115000000dd7700000006666660000000000000000000000000000000000000000000000000000000000000000000000000
0044400000000000611e11166181e11600006dd77ddd00006d66666d000550000000000000000000000000000000000000000000000000000000000000000000
004f40000000000061e11116618111160006dd755dddd00066d6666d005885000000000000000000000000000000000000000000000000000000000000000000
004ff000000000006e55eee6d1811116006dd566665ddd00666d66dd005885000000000000000000000000000000000000000000000000000000000000000000
0040000000000000688511166dddddd600dd56118165dd00666d6dd5000550000000000000000000000000000000000000000000000000000000000000000000
0040000000000000d88511155555555506dd611e8116ddd0066ddd50000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000055555555151515150dd561e181165dd000dd5500000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006d766dd666dd76660dd56e558ee65dd006066d00006d06d00000000000000000000000000000000000000000000000000000000000000000
000000000000000000055000000550000dd768858116ddd007d6d0dd607ddd000000000000000000000000000000000000000000000000000000000000000000
00000000000000000566665005666650007d68858115dd00706dddd06dd6dddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000056e1116556e1116500ddd555555ddd006dd55ddd07d55ddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000061e1555661e15556000dddd55dddd0006dd55ddd6dd55dd00000000000000000000000000000000000000000000000000000000000000000
000000000000000068e15d8668e15d860000dddddddd000006dddd0d66dddddd0000000000000000000000000000000000000000000000000000000000000000
0000000000000000d8e158d5d8e158d5000000dddd0000006d06ddd0006ddd0d0000000000000000000000000000000000000000000000000000000000000000
000000000000000005666650056666500000000000000000006dd0d00660dd000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000006dd7000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000006dd77d00000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000006dd77ddd0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000dd755ddd0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000d7755ddd0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000077dddddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000dddddd00000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000dddd000000000000000000000000000000000000000000000000000000000000000000
0056650011175111111117778888888911dd111198dd988988889899000000000000000000000000000000000000000000000000000000000000000000000000
0d7666d0117517111117775798a98a981ddd11118ad7a8988d89aa98000000000000000000000000000000000000000000000000000000000000000000000000
5776ddd5157571711575651789a97a981dd5d11187a97aa8869aa989000000000000000000000000000000000000000000000000000000000000000000000000
666ddd555576171557565171add7a9881d577771aa777778567777aa000000000000000000000000000000000000000000000000000000000000000000000000
66dddd5157655557517511718ddd99981177aa998977aa99d677aa99000000000000000000000000000000000000000000000000000000000000000000000000
56ddd5511751777117571711d5ddaaa817a7791197a77998d6aaa988000000000000000000000000000000000000000000000000000000000000000000000000
0dd5551075771551757175118d5d98881a1a97118a8a9789889a9898000000000000000000000000000000000000000000000000000000000000000000000000
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
9aaa99999999999999990900aaa99999000000000000000000000000000000000000000000000000000000000880000000000000000000000000000081110000
aaa9999999999aaaaaaa9090a00aaaa9000000000000000000000000000000000000000000000000002100088888800000000000008100000000000811111000
a9999aa9999aaaa999aaa9090aa99999000000000000000000000000000000000000000000880000002110028881100000000000881110000000008211111000
99999999999999999a99aa00aa9aa999000000000000000000000000000000000000000000288000002110022211100000000088811110000000082221111100
aaaaaaa999999999909999a0a9aa9990000000000000000000000000000000000000000000211000002100022211000000000888111111000008222222111100
aaaa999009099999090900009a999909000000000000000000000000000000000000211002211000021100222211000000008882211111100082222222111110
a99090099099999990900aa900909090000000000000000000000000000000000000211112210000021000222211000000088222211111100222222222211110
9909090009aa99990000aa9000000000000000000000000000000000000000000002211102200000020000222110000000822222221111002222222222211100
00000000000000000000000000000000000000000000000000000000000000000002211102010000001000222100000002222222221111002222222222221100
00000000000000000000000000000000000000000000000000000000000000000002211100288000210000221000000002222222222110000222222222221100
00000000000000000000000000000000000000000000000000000000000000000002111000028880000002020100880000222222222110000222222222222100
00000000000000000000000000000000000000000000000000000000000000000002111000022110000000201028810000222222222210000022222222222000
00000000000000000000000000000000000000000000000000000000000000000002111000222110000000000022110000022222222200000022222222220000
00000000000000000000000000000000000000000000000000000000000000000022110000221100008880000022110000022222220000000002222222000000
00000000000000000000000000000000000000000000000000000000000000000021110000221100008888000022110000002222000000000002222200000000
00000000000000000000000000000000000000000000000000000000000000000021110000221100002888800022110000002200000000000000220000000000
__gff__
8000808001010101010000018483008000000000010100000100010183830000000000000101000000000101828080800000000081010101000000008282848000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
000000cbcc00cdce000000000000000000c3c000000000c26061616000616063000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9ca00dbdc00dd020000000000c80000c00000c300c1c2c37170717060707172000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9dac5dbdccfdd02c4d6d8c6c502c4c7c2c1d0d3d0d1d2e27270737371717372000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9da02dbdcdfdd02d402020202020202e3e1d3d0e0e1d1d06465646565646565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003434343404062507242425242425250424252524323232320607060700000000090909093a1b1b1b000000010c00000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003434343414343415343534341435341518181818331133321617161700000000191919191a000012000000120c00000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003434353435343405343434341434341532323232242524250607060700000000350537361a1313010b2b2b2b0c00000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003434343416353435343434341818181802020202181818181617161700000000373736371a0000121a0000120c00000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020203030303013232320132323202020202020202020000000001323301293534353939393901131301011313010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020202030303033332323232323332020202023232323300000000d90303d9022934343939393912000012300000111301131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020202030303033232323333323232020202023332323200000000d90303d902022935333232331200001230000030c012c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020203030303323232320202020202020202030303030000000001d9d901323232293232333201222201012222011301131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0081121612424104000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
022d000000150000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
022d150c6c6c6c6c6c6c6c6c6c6c6c0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222d150c292d0000140000002a00000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03020c04040400000c0b00002a000b0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020606060600000c0a000b0703030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010122220202000a0c0a000a0701010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0010000012b1512b1512b1514b2514b2514b3516b451ab551cb7520b0622b2624b3628b562cb7632330200622c0622c0622c0622c0622c0622c0622c0622c0622c0622c062280522a0622c072300133202336043
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
4801000014300105000c6000a30007400056000460006600064000640006600046000060000600006000960009600000000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
511200000331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f3200331003310033100331003310033100331003310033100d3200d3200d32012320123200f3200f320
511200000131001310013100131001310013100131001310013100c3200c3200c32012320123200f3200f32001310013100131001310123200f3200131012320013100f320013110131016320153241532514320
4b1200002e625029002e6252e60037625396002e6252e6250000037625000000a6252e6252560537625376053a6103a6253a6103a62537625396002e6252e6251362537625000000000037625000001362537625
0412000027c251bc201b3261bc00273261bc351bc051bc351bc001bc351b3161bc3519c20193151ac201ac100fc251bc201b3261b400273261bc351b4001bc351b4101bc351b4161bc351ec201b3151bc201bc10
041200001bc251bc201b3260f325273261bc201bc120d3251bc251bc351b3161bc351ec201931520c2020c101bc251ec201b3261b4002732620c2220c1222c351b41020c351b4161bc001ec201b31519c201ac20
0112000027c251bc201b3260f323273261bc351b3131bc350f3231bc351b3261bc351b326193151ac201ac101b3261bc101b3261b32222c2222c221631220c2220c2220c221ec221ec22183121ec1219c201ac10
4d1200001bd201bd201bd201bd201bd101bd101bd101bd101bd101bd101bd1019d2020d2022d2020d201bd201ed201bd201bd201bd201bd101bd101bd101bd103361533614336153361019d2019d201ed201ed20
4d1200001bd201bd201bd201bd201bd101bd101bd101bd101bd101bd101bd101bd101bd101bd101bd101bd1022d3519d2022d3519d2021d3519d2021d3519d2020d351ad2020d351ad201ed301bd2019d301ad20
0b1200000f33303c002e62503c003e63503c002e6252e62503c043e62503c000a6253e62503c00376253e6250f33300c003e6250f32300c003e6150f3232e6252e6003e615376252e6003a6253a6253a6253a625
0b12000003c2003c2003c2503c2003c3503c2003c2003c2203c1403c2503c2003c2003c2503c2003c2503c2001c2001c2001c3501c2001c2001c2501c2001c2001c2301c2001c2101c2303c2003c2006c2006c30
0b12000000c3000c2000c2500c3000c2000c2000c2300c2200c1000c2000c2000c2506c2006c2003c2003c200ac200ac200ac250ac200ac2516c200ac200ac250dc200dc2001c2001c250fc2008c2008c2506c20
4d12000020d2020d2020d2020d2020d1020c1020c1020c10204102041022420224202242022d102241022410224350b420224350b42027d350b42027d350b42022c350d42022c350d42022c351e43020c301a420
0010000018430184300c4310c4301f4301f4001d4321d4321d4321d2321d2221d2221d2121d2121d2020000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000018430184300c4310c4301f4303660311432114321143211232112221122211222112221122211212053550735505355073550a3550c355073550c35505355073550a3550c35511355133551635518355
001000000215502100001000e155001000d10002155021550215002155021550e1500e100001000f100021000210002100001000010002100021000e1000e1000010000100001000010000100001000010000100
010900201bc2620c1627c2620c161bc2624c161bc2620c161bc2623c161bc2620c1627c2624c161bc2620c161bc2627c161bc2620c1627c2628c161bc2617c261bc2627c2623c2627c261bc2627c2623c2627c26
0109002017c2620c1623c2620c1617c2624c161bc2623c1623c2623c1617c2620c1623c2624c1617c2620c1623c2627c1617c2620c1623c2628c1617c261bc2617c2627c2623c2627c2617c2627c2623c2627c26
01100000022500730002250073000a3000c3001630018300052500000005250000000000000000000000000004250000000425000000000000000000000000000325000000022500000000000000000000000000
311000000a2300a2300323003230032100323003410034100d2300d23003230034200331003230034100341006230062300343003430032100323003210032100a2300a220084300843003230032100343003420
01100000143361b3160f3301b336143101b3100f3301b3160f3301b3100f3361b3260f3300d31012330113300f3350f3201633016326163300f3160f320143300f3361402014336143200f3101b3301233011330
011000000f336123160f330123360f3101b3100f3300f3100f336143100f330143361b3100f3200f330113301d3260f3201d3260f3201d3260f3201d3260f3201e3260f4201e3260f4201e3260f4201e3260f420
011000002c3263331627310333362c3163331627316273162733633316273363332627312273142a3202933027335273352e3202e3262e33027316273102c330273262c0102c3362c31027330333302a33029330
1110000020336273161b3302733620316273101b330273161b336273161b33627326193101b3101e330193301b3351b3352232022326223301b3161b320203301b3362003020336203201b310273301e3301d330
311000000a1100a1200a1300a1300a1300a1300a1300a1200393003130039300312003933039330392003920069300313006930031300c1200c1200c1200c1200493003130049300392003923039230392303923
311000000b1100b1200b1300b1300b1200b1200b1220b1220493004130049300422203923039230392203922069300313006930031300d1220d1220d1220d1220793003130121320693206932069331212212922
3110000003350034400335003220032200323003410034100335003440033500322003210032300393003930064500f4400645003230032200323003210032100435012d40043500622006220063100631006310
31100000049500b450049500322003220032300341003410043500b440043500322003220032100340003400064500f9400645003220032200323003210032100735012d400735006d400622012d300631006310
111000001b3361e3161b3301e3361b310273101b3301b3101b336203101b33020336273101b3201b3301d330293261b320293261b320293261b320293261b3202a3261b3202a3261b3202a3261b3202a3261b420
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
01 323c3944
00 323c3944
00 3d3c3944
02 3e3c3a44
00 373c3344
02 383c3444
00 393c3644
02 3a3c3b44
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

