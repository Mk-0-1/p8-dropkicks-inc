pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

function _init()
	-- input delay
	poke(0x5f5c, 0)
	poke(0x5f5d, 2)
	parse_selected_lvl()
	print_level()
end

function _update()
	if btnp(3) then
		selected_lvl += 1
	end
	if btnp(2) then
		selected_lvl -= 1
	end
	if btnp(3) or btnp(2) then
		selected_lvl %= #lvls_info

		parse_selected_lvl()
		print_level()
	end
	
	
	if btnp(5) then
		compress_data()
	end
end

-->8
-- interface

function parse_lvl_string(in_string, delimiter)

 -- remove newlines from multistrings
	local str_spl = split(in_string, "\n") or {}
	
	local string_2 = ""
	for i=1, #str_spl do
		string_2 ..= str_spl[i]
	end

 local arr = split(string_2,delimiter) or {}
 if (string_2 == "") arr = {}
 
 return arr, string_2
end

function parse_selected_lvl()
		lvl = lvls_info[selected_lvl+1]
		
		lvl_title, lvl_title_string = parse_lvl_string(lvl[1],"`")
		lvl_settings, lvl_settings_string = parse_lvl_string(lvl[2],"`")
		lvl_ntts, lvl_ntts_string = parse_lvl_string(lvl[3],"`")
		lvl_decals, lvl_decals_string = parse_lvl_string(lvl[4],"`")
end



selected_lvl = 0

function print_level()
	cls()
	color(6)
	print("detected " .. #lvls_info .. " levels!")
	print("viewing lvl " .. selected_lvl+1)

	print("name: ".. lvl_title[1])

	print("title entries: ".. #lvl_title .. "/8")
	print("settings entries: ".. #lvl_settings .. "/28")

	
	print("num entities: ".. #lvl_ntts/4)
	if #lvl_ntts%4 != 0 then
		print("entity config error!",8)
		color(6)
	end
	
	print("num decals: ".. #lvl_decals/3)
	if #lvl_decals%3 != 0 then
		print("decal config error!",8)
		color(6)
	end

	print("press ❎ to output all levels!", 0, 110, 13)
end


function compress_data()
	cls()
	print("parsing levels...")
	output_str = 'lvls_info_2 = split("'
	
	local splitter = "⬅️"
	local level_splitter = "➡️"
	color(6)
	local err = false
	for i=1, #lvls_info do
		selected_lvl=i-1
		parse_selected_lvl()
		output_str ..= lvl_title_string .. splitter
		output_str ..= lvl_settings_string .. splitter
		output_str ..= lvl_ntts_string .. splitter
		output_str ..= lvl_decals_string
		
		if (i != #lvls_info) output_str ..= level_splitter
		
		
		if #lvl_ntts%4 != 0 then
			color(8)
			err = true
			print("\^3entity error in level " .. i .. " !")
		end
		if #lvl_decals%3 != 0 then
			color(8)
			err = true
			print("\^3decal error in level " .. i .. "!")
		end
		
		
		print("\^1parsed level " .. i)
	end
	output_str ..= '","➡️")\n'
	printh(output_str)
	printh(output_str, "@clip")
	if (not err) color(11)
	print("all levels parsed and put\nto clipboard & terminal!")
	for i=0, 60 do
		flip()
		if (btn() != 0) break
	end
	print_level()
end


-->8
-- data


-- list of levels and all their data except the tiles

--1st array: title info
-- 1: main menu title
-- 2: next lvl (1-indexed, -1 is finish, -2 is no transition (for custom ones))
-- 3,4: player spawnpos x & y
-- 5: real title
-- 6: intro text
-- 7: extra global vars
-- 8: main menu info


--2nd: ALL LEVEL PROPS

-- (1)map pos x, (2)map pos y, (3)x size, (4)y size
-- available map pos's:x:full range, y:12-39(inclusive)
-- 1 full stage should have about 600 tiles
-- max level dimensions are 32x28 (cause of extended map limits and sprite sheet, for y you'd have to start at top)
-- (5)mus index

-- (6)active music layers (4 bitfield)

-- (7)pal index, (8)bg col

-- bg 1:
-- (9)image index
-- (10)pal index

-- (11)scale
-- (12)parallax
-- (13)offset x
-- (14)offset y
-- (15)wrap x
-- (16)wrap y
-- (17)timescroll x
-- (18)timescroll y

-- same for bg 2
--(10 things, 19-28)




--3rd: entity spawns
-- type, xpos, ypos, extrainfo array (, and / separated, same as ntt info)

--(for signs: str,screen,x,y,xlen,ylen,c1,c2)

--4th: signs
-- x,y,text

-- NOTE: try to not have more than 6 legs active at once. More kinda lags

-- NEW WAY
--


lvls_info = {
{[[task 01` 2` 28`58`   the construction site  `finally, a day where our\n  name matches our service`/`from: hq\n\nsome construction company's\nbots went haywire -\nthey're hoping we could\n'clean' up the situation\nbefore the public notices\nand it turns into a mess\nof paperwork.\nPERFECT OPPORTUNITY FOR \nYOUR 'SKILLS' :] ]],
	[[0`23`23`4`7`1`2`1`2`7`3`2`48`8`1`0`1`0`1`0`4`8`64`2`0`0`0`0]],
	
--entities
[[
4`520`52`rY,procalert/12,true`
7`542`-2`/`
5`658`34`/`
13`404`44`text_box/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️4⬇️44⬇️42⬇️2⬇️1
]],

--decals
[[
115`61`\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!`
258`78`\f2\^o150\^:00130e3a0a190800`
262`86`\f2\^o068\^:84ef565692df9249\|e\^o0d0\^:e058517575edeb91`
328`66`\f2\^o0ff🅾️\n\n\|c \-f+\n\n\|c\^:10387c1010100010
]]

},

{[[1-2` 3` 7`66`1: roadblock``/`]],
	[[23`23`16`4`8`3`2`2`2`6`3`2`48`12`1`0`1`0`1`3`5`10`-72`8`0`0`0`0]],
	
[[
5`104`50`procalert/true`
4`154`93`/`
4`276`38`rope,rX,rY/4,-13,-8`
5`464`22`rX,rY/16,0`
6`498`94`/
]],

[[
302`29`\f2\^o0ff❎\|e\n\ng\|fr\|fa\|fb`
286`33`\f2\^o0ff\^:00008064320f0204		\|e\^:0000070c90a0c0f0
]]

},

{[[1-3` 4` 6`322`2: magnetizing yourself``/`]],
	[[58`19`15`11`8`3`2`2`2`6`3`2`48`16`1`0`1`0`1`3`5`10`-170`8`1`0`0`0]],
	
[[
13`51`331`text_box/\fae.m. wall\nusage manual\n\n❎-attach\n🅾️-release⬇️false⬇️22⬇️278⬇️58⬇️42⬇️2⬇️1`
13`148`246`text_box/\fa\-dnotice to workers:\njumping directly\non the panels is\nstill considered\na workplace hazard\nregardless of how\n'sick' it may look⬇️false⬇️100⬇️196⬇️88⬇️50⬇️2⬇️1`
5`78`154`rY/-16`
15`20`72`/`
7`80`90`/`
5`247`36`next_e,rX,rY/11,16,4`
4`323`62`rX,rY,procalert/-4,18,true`
6`438`105`/`
7`350`16`actN/40
]]

},

{[[1-4` 5` 4`110`3: don't look down``/`]],
	[[14`12`16`6`8`3`2`2`1`7`3`4`-102`36`1`0`0`0`0`10`4`8`-40`36`0`0`0`0]],
	
[[
5`79`76`rY/-16`
7`240`10`procalert/true`
6`274`44`next_e,procalert/11,true`
6`432`75`Btyp,procalert/5,true`
7`390`6`next_e/11
]]

},
{[[1-5` 6` 4`200`4: mayhem square``y_u_l,lvl_e_req/-64,4`]],
	[[0`12`14`11`8`7`3`2`0`3`3`4`208`4`1`0`0`0`0`12`5`8`-140`-4`0`0`0`0]],
	
[[
16`112`239`rX,rY/16,0`
6`298`170`next_e,Btyp/11,5`
6`161`37`/`
7`300`40`procalert/true`
7`346`26`/`
16`205`140`rX,rY,gun/-12,-12,4
]]

},
{[[task 01` -1` 4`116`5: the small issue in question``y_u_l,lvl_e_req/-32,1`]],
	[[29`12`12`6`8`7`3`2`1`7`5`4`-48`-10`1`0`0`0`0`10`5`12`-242`4`1`0`0`0]],

[[
11`108`48`/`
8`272`90`boss/true
]]

},
{[[task 02` 8` 48`88`  the hijacked transport  `you did bring a\n  parachute, right?`y_l_l/64`from: hq\n \nsame guys as yesterday,\nthis time it's one of their\nautomated cargo transports.\nmakes you wonder what\nthey're doing to get rogues\ntwice in a row, but hey as\nlong as they're paying i'm\nnot complaining. ]],
	[[45`12`15`5`24`7`0`2`1`4`2`2`-48`32`1`0`30`-3`1`6`5`4`32`-26`1`0`45`-6]],
	
[[
4`205`99`procalert/true`
7`230`57`rngN/16`
16`150`54`rX,rY/12,12`
16`315`20`rX,rY,actF/12,12,80
]]
},
{[[2-8` 9` 10`88`1: what a blast``/`]],
	[[0`26`12`4`28`5`1`1`2`7`3`4`0`-26`1`0`30`0`2`7`4`4`32`68`1`0`60`0]],
	
[[
13`76`84`text_box/\fato maintenance staff:\nplease only \fcgrab\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1`
18`200`68`rope,rX,rY,next_e/1,0,16,11`
7`295`50`/`
18`360`72`rope,rX,rY/1,0,16
]]
	
},
{[[2-9` 10` 20`233`2: hang in there``y_l_l/256`]],
	[[66`19`12`11`28`5`1`1`2`7`3`4`0`-26`1`1`30`-3`2`7`4`4`32`68`1`1`60`-6]],
	
[[
17`57`233`rope,rX,rY/6,76,-20`
16`213`238`rX,rY/12,-12`
16`308`183`/`
16`309`66`rX,rY/14,0
]]

},
{[[2-10` 11` 10`150`3: nice weather up here``/`]],
	[[14`17`15`6`28`13`4`12`2`0`3`12`0`10`1`0`30`0`2`0`6`16`32`0`1`0`60`0]],
	
[[
18`100`88`next_e/11`
16`164`60`rX,rY,next_e/12,-12,11`
17`232`119`rope,rX,rY/7,0,-120`
16`272`69`rX,rY,next_e/0,-14,11`
17`380`108`rope,rX,rY/6,79,-10`
18`456`88`/`
15`403`44`/
]]

},
{[[2-11` 12` 75`120`4: broken access bridge``lvl_e_req,y_u_l/4,-96`]],
	[[28`18`18`5`28`13`4`12`2`0`3`4`0`14`1`0`30`0`2`3`5`8`0`18`1`0`60`0]],
	
[[
18`216`104`next_e/11`
16`196`75`rY/-12`
6`308`108`Btyp/5`
18`524`56`next_e/11`
6`458`12`Btyp,next_e/5,11
]]
},

{[[2-12` 13` 8`128`5: annoyingly out of reach``y_u_l,lvl_e_req/-96,1`]],
	[[61`12`11`7`28`13`4`12`2`7`3`4`0`14`1`0`30`0`2`3`5`8`0`18`1`0`60`0]],
[[
22`304`72`boss/true`
17`130`58`rope,rX,rY/8,0,-50
]]
	
},

{[[task 02` -2` 6`42`control cabin``x_l_l,y_l_l,y_u_l/192,96,-96`]],
	[[57`17`4`3`7`1`4`12`2`7`3`4`0`14`1`0`30`0`2`3`5`8`0`18`1`0`60`0]],
[[
30`77`44`mass,gun,break_func/0.2,18,d_load_next
]]
	
},

{[[task 03` 15` 240`56`  the lowlands  ``/`from: hq\n ]],
	[[103`12`10`9`-1`7`8`2`3`13`2`2`-48`32`1`0`0`0`3`14`3`4`32`40`1`0`0`0]],
	
[[
27`117`108`rX/-22`
25`63`169`is_left/t`
27`40`156`rX/-22`
27`72`215`/`
25`102`205`is_up/t`
25`282`260`is_left/t
]]
},

{[[3-15` 16` 4`315`1: bouncy castle ``/`]],
	[[78`19`10`11`38`3`8`4`3`13`3`4`-48`17`1`0`0`0`3`14`-2`8`32`54`1`0`0`0]],

[[
27`276`206`/`
27`233`167`rX,rY/-14,-20`
27`144`103`rX,rY/-17,17`
27`48`127`rX/-22`
31`145`200`/`
28`176`78`/`
32`202`94`procalert/true`
15`49`28`/`
27`49`43`/
]]
},

{[[3-16` 17` 8`124`2: the horrid sludge pits ``sludg_l/186`]],
	[[113`12`15`7`38`3`8`4`3`13`3`12`-48`17`1`0`0`0`3`14`-2`40`32`80`1`0`0`0]],
	
[[
27`112`176`rX,rY/-15,17`
28`112`57`/`
28`274`70`/`
16`274`33`rX,rY/0,-12
]]
},


{[[3-17` 11` 4`154`3: hunted``y_u_l,sludg_l/-96,169`]],
	[[113`19`15`6`38`3`8`2`3`6`2`24`75`64`1`0`0`0`3`14`2`40`0`86`1`0`0`0]],
	
[[
29`338`-4`/`
29`383`122`/`
30`288`148`/`
28`146`8`actF/150
]]
},

{[[3-18` 11` 4`154`4: the gutter``y_u_l,sludg_l/-96,2000`]],
	[[113`25`15`8`38`7`9`1`2`6`2`0`75`10`1`0`1`0`3`1`2`16`0`52`1`0`0`0]],
	
[[

]]
}


}

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
