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

selected_lvl = 0

function print_level()
	cls()
	color(6)
	print("detected " .. #lvls_info .. " levels!")
	print("viewing lvl " .. selected_lvl+1)

	print("name: ".. lvl_title[1])

	print("title entries: ".. #lvl_title .. "/8")
	print("settings entries: ".. #lvl_settings .. "/33")

	
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
	output_str = ""
	
	local splitter = "A"
	local level_splitter = "B"
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
	
	printh(output_str)
	printh(output_str, "@clip")
	if (not err) color(11)
	print("all levels parsed and put\nto clipboard & terminal!")
	print("\^7\^6")
	print_level()
end


-->8
-- data


-- list of levels and all their data except the tiles

--1st array: title info
-- name/m_menu title
-- next lvl (1-indexed, -1 is finish, -2 is no transition (for custom ones))
-- player spawnpos x & y
-- camera pos in main menu
-- sub title
-- intro text


--2nd: ALL LEVEL PROPS

-- (1)map pos x, (2)map pos y, (3)x size, (4)y size
-- available map pos's:x:full range, y:12-39(inclusive)
-- 1 full stage should have about 600 tiles
-- max level dimensions are 32x28 (cause of extended map limits and sprite sheet, for y you'd have to start at top)
-- (5)mus index

-- (6)active music layers (4 bitfield)
-- (7) unused (up to 10)
-- (9)
-- (8)
-- (11)
-- (10)

-- (12)pal index, (13)bg col

-- bg 1:
-- (14)image index
-- (15)pal index

-- (16)scale
-- (17)parallax
-- (18)offset x
-- (19)offset y
-- (20)wrap x
-- (21)wrap y
-- (22)timescroll x
-- (23)timescroll y

-- same for bg 2
--(10 things, 24-33)


--3rd: entity spawns
-- type, xpos, ypos, extrainfo array (, and / separated, same as ntt info)

--(for signs: str,screen,x,y,xlen,ylen,c1,c2)

--4th: signs
-- x,y,text

-- NOTE: try to not have more than 6 legs active at once. More kinda lags

lvls_info = {
{[[mission 1` 2` 30`54` 464`0`construction\n site`]],
	[[0`23`24`4`4`1`0`0`0`0`0`2`1`2`7`3`0x0000.0800`48`8`1`0`1`0`1`0`4`0x0000.2000`64`2`0`0`0`0]],
	
--entities
[[
4`520`52`/`
5`630`56`rope_x,rope_y/12,12`
16`404`44`text_box/\-e\^h\fadanger!\n\nrogue\nmachinery\nahead ->:false:386:4:44:42:2:1
]],

--decals
[[
115`61`\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!`
258`78`\f2\^o150\^:00130e3a0a190800`
262`86`\f2\^o068\^:84ef565692df9249\|e\^o0d0\^:e058517575edeb91`
328`66`\f2\^o0ff🅾️\n\n\|c \-f+\n\n\|c\^:10387c1010100010
]]

},

{[[1-2` 3` 6`76` 0` 0`1: roadblock`]],
[[23`22`16`5`8`3`0`0`0`0`0`2`2`2`6`3`0x0000.0800`48`12`1`0`1`0`1`3`5`0x0000.2800`-72`8`0`0`0`0]],
	
--entities
[[
5`104`66`procalert/true`
4`154`109`/`
4`278`52`rope,rope_x,rope_y/4,-16,0`
5`464`34`rope_x,rope_y/16,0`
7`398`124`/
]],

--decals
[[
302`45`\f2\^o0ff❎\|e\n\ng\|fr\|fa\|fb`
286`49`\f2\^o0ff\^:00008064320f0204		\|e\^:0000070c90a0c0f0
]]

},

{[[1-3` 4` 6`290` 0` 0`2: magnetize yourself`]],
	[[0`12`14`10`8`3`0`0`0`0`0`2`2`2`6`3`0x0000.0800`48`16`1`0`1`0`1`3`5`0x0000.2800`-170`8`1`0`0`0]],
	
--entities
[[
16`52`292`text_box/\-e\^h\fae.m. wall\nusage manual\n\n❎-attach\n🅾️-release\n\ndetached jumping\nis not safety\ncompliant!:false:22:226:72:64:2:1`
4`78`154`rope_y/-16` 18`20`72`/`
7`80`90`/`
5`240`51`next_e,rope_x,rope_y/11,-16,8`
4`326`69`rope_x,rope_y/-12,12`
6`410`138`active_in,procalert/30,true`
7`408`96`procalert/true
]]

},

{[[1-4` 5` 4`110` 60`80`3: don't look down`]],
	[[14`12`16`6`8`3`0`0`0`0`0`2`2`1`7`3`0x0000.1000`-102`36`1`0`0`0`0`10`4`0x0000.2000`-40`36`0`0`0`0]],
	
--entities
[[
5`79`76`rope_y/-16`
7`240`10`procalert/true`
6`274`44`next_e,procalert/11,true`
6`432`75`b_type,procalert/7,true`
7`390`6`next_e/11
]]

},
{[[1-5` 6` 4`72` 60`80`4: mayhem square`]],
	[[30`12`16`7`8`7`0`0`0`0`0`3`2`0`3`3`0x0000.1000`208`-4`1`0`0`0`0`12`5`0x0000.2000`-140`-16`0`0`0`0]],
	
[[
11`108`60`/`
19`146`110`rope_x,rope_y/16,0`
7`272`110`range_in/25`
6`302`148`next_e,b_type,procalert/11,7,true`
5`396`132`rope_x,rope_y/-16,0`
7`436`80`/`
7`370`44`/`
19`232`40`rope_x,rope_y,gun,procalert/-12,-12,4,true
]]

},
{[[mission 1` -1` 4`116` 60`80`5: the small issue in question`]],
	[[57`12`12`6`8`7`0`0`0`0`0`3`2`1`7`5`0x0000.1000`-48`-10`1`0`0`0`0`10`5`0x0000.3000`-242`4`1`0`0`0]],

[[
11`108`48`/`
8`250`104`boss/true
]]

},
{[[mission 2` 8` 48`88` 48`0``]],
	[[39`19`15`5`25`1`0`0`0`0`0`0`2`1`4`2`0x0000.0800`-48`32`1`0`30`-3`1`6`5`0x0000.1000`32`-26`1`0`45`-6]],
	
[[
4`205`99`procalert/true`
7`230`57`range_in/16`
19`150`54`rope_x,rope_y/12,12`
19`315`20`rope_x,rope_y,active_out/12,12,80
]]
},
{[[2-8` 9` 10`88` 48`0`1: dust filter`]],
	[[0`26`12`4`25`5`0`0`0`0`0`1`1`2`7`3`0x0000.1000`0`-26`1`0`30`0`2`7`4`0x0000.1000`32`68`1`0`60`0]],
	
[[
21`200`68`b_type,next_e/6,11`
7`295`50`/`
21`360`75`b_type/6
]]
	
},
{[[2-9` 10` 20`233` 48`0`2: hang in there`]],
	[[47`19`12`11`25`5`0`0`0`0`0`1`1`2`7`3`0x0000.1000`0`-26`1`1`30`-3`2`7`4`0x0000.1000`32`68`1`1`60`-6]],
	
[[
20`57`233`rope,rope_x,rope_y/6,76,-20`
19`227`245`rope_x,rope_y/12,-12`
20`287`272`rope,rope_x,rope_y/8,0,-50`
20`306`153`rope,rope_x,rope_y/8,0,-40`
19`303`186`/`
19`309`66`rope_x,rope_y/14,0
]]

},
{[[2-10` 11` 10`150` 48`0`3:`]],
	[[14`17`15`6`25`13`0`0`0`0`0`4`12`2`0`3`0x0000.3000`0`10`1`0`30`0`2`0`6`0x0000.4000`32`0`1`0`60`0]],
	
[[
21`100`88`next_e/11`
19`164`60`rope_x,rope_y/12,-12`
20`232`119`rope,rope_x,rope_y/7,0,-120`
19`272`69`rope_x,rope_y/0,-14`
20`380`108`rope,rope_x,rope_y/6,76,-10`
21`456`88`/
]]

},
{[[2-11` 12` 76`72` 48`0`4:`]],
	[[28`19`18`4`25`13`0`0`0`0`0`4`12`2`0`3`0x0000.1000`0`14`1`0`30`0`2`3`5`0x0000.2000`0`18`1`0`60`0]],
	
[[
21`216`72`next_e,procalert/11,true`
19`172`20`rope_x,rope_y/-12,12`
6`330`44`gun,b_type,next_e,active_in/9,7,11,55`
21`534`98`b_type,next_e/6,11`
19`499`75`rope_x,rope_y,next_e,procalert/16,0,11,true
]]
},

{[[mission 2` -2` 8`128` 48`0`5:`]],
	[[46`12`11`7`25`13`0`0`0`0`0`4`12`2`7`3`0x0000.1000`0`14`1`0`30`0`2`3`5`0x0000.2000`0`18`1`0`60`0]],
[[
25`304`72`boss/true`
20`204`58`rope,rope_x,rope_y/8,0,-50
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
