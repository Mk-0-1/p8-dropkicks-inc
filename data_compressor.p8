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


--2nd: ALL LEVEL PROPS

-- (1)map pos x, (2)map pos y, (3)x size, (4)y size
-- available map pos's:x:full range, y:12-39(inclusive)
-- 1 full stage should have about 600 tiles
-- max level dimensions are 32x28 (cause of extended map limits and sprite sheet, for y you'd have to start at top)
-- (5)mus index

-- (6)active music layers (4 bitfield)

-- (7)pal index, (8)bg col





-- bg info:
-- (1)image index
-- (2)pal index

-- (3)scale
-- (4)parallax
-- (5)offset x
-- (6)offset y
-- (7)wrap x
-- (8)wrap y
-- (9)timescroll x
-- (10)timescroll y



--3rd: entity spawns
-- type, xpos, ypos, extrainfo array (, and / separated, same as ntt info)

--(for signs: str,screen,x,y,xlen,ylen,c1,c2)

--4th: signs
-- x,y,text

-- NOTE: try to not have more than 6 legs active at once. More kinda lags

ntt_extrainfos=split([[/
procalert/true
next_e/11
rX,rY/14,0 -- 4
rX,rY/-14,0
rX,rY/0,-14
rX,rY/-12,-12
Btyp/5
gun/4
boss/true -- 10
rope,rX,rY/6,76,-20
break_func/load_next
is_left/t --13
is_up/t
is_left,is_up/t
rX,rY/-15,15
text_box/\-f\^h\fadanger!\n\nrogue\nmachinery\nahead ->⬇️false⬇️386⬇️4⬇️44⬇️42⬇️2⬇️1
text_box/\fae.m. wall\nusage manual\n\n❎-attach\n🅾️-release⬇️false⬇️22⬇️278⬇️58⬇️42⬇️2⬇️1
text_box/\fa\-dnotice to workers:\njumping directly\non the panels is\nstill considered\na workplace hazard\nregardless of how\n'sick' it may look⬇️false⬇️100⬇️196⬇️88⬇️50⬇️2⬇️1
text_box/\fato maintenance staff:\nplease only \fcgrab\nheat-seeking bolts\fa\nin emergencies⬇️false⬇️36⬇️40⬇️94⬇️32⬇️2⬇️1
]],"\n")


--1st array: title info
-- 1: title
-- 2: next lvl (1-indexed, -1 is finish, -2 is no transition (for custom ones))
-- 3,4: player spawnpos x & y
-- 5: extra global vars

-- 6,7: map pos x & y
-- 8,9: x & y size
-- 10: music index
-- 11: music layers
-- 12: main palette
-- 13: clear color

-- 14, 15: bg1 & 2 mem location
-- 16: enemy mem location
-- 17: num enemies

-- 10 altname wayy too much fresh air 
-- 18 altname the moat? also the ditch is funny
lvls_info = split([[   the construction site  ` 2` 28`58`/`0`23`23`4`7`1`2`1
1: roadblock` 3` 7`66`/`23`23`16`4`8`3`2`2
2: magnetizing yourself` 4` 6`322`/`58`19`15`11`8`3`2`2
3: don't look down` 5` 4`110`/`14`12`16`6`8`3`2`2
4: mayhem square` 6` 4`200`y_u_l,lvl_e_req/-64,4`0`12`14`11`8`7`3`2
5: the small issue in question` -1` 4`116`y_u_l,lvl_e_req/-32,1`29`12`12`6`8`7`3`2
  the hijacked transport  ` 8` 48`88`y_l_l/64`45`12`15`5`24`7`0`2
1: what a blast` 9` 10`88`/`0`26`12`4`28`5`1`1
2: hang in there` 10` 20`233`y_l_l/256`66`19`12`11`28`5`1`1
3: nice weather up here` 11` 10`150`/`14`17`15`6`28`13`4`12
4: broken access bridge` 12` 75`120`lvl_e_req,y_u_l/4,-96`28`18`18`5`28`13`4`12
5: annoyingly out of reach` 13` 8`128`y_u_l,lvl_e_req/-96,1`61`12`11`7`28`13`4`12
control cabin` -2` 6`42`x_l_l,y_l_l,y_u_l/192,96,-96`57`17`4`3`7`1`4`12
  the lowlands  `15` 240`56`/`103`12`10`9`-1`7`8`2
1: bouncy castle` 16` 4`315`/`78`19`10`11`38`3`8`4
2: the horrid sludge pits` 17` 8`124`sludg_l/186`113`12`15`7`38`3`8`4
3: hunted` 18` 4`154`y_u_l,sludg_l/-96,169`113`19`15`6`38`3`8`2
4: the gutter` 11` 4`154`y_u_l,sludg_l/-96,2000`113`25`15`7`38`7`9`1]],"\n")

redundancies = {
{
	[[2`7`3`2`48`8`1`0`1`0`1`0`4`8`64`2`0`0`0`0]],
	
--entities
[[
4`520`52`2`
7`542`-2`1`
5`658`34`1`
13`404`44`17
]],

--decals TODO
[[
115`61`\f2\^o0ff🅾️\-2\|9\f2\^o0dbj\|fum\|fp!`
258`78`\f2\^o150\^:00130e3a0a190800`
262`86`\f2\^o068\^:84ef565692df9249\|e\^o0d0\^:e058517575edeb91`
328`66`\f2\^o0ff🅾️\n\n\|c \-f+\n\n\|c\^:10387c1010100010
]]

},

-- 2
{
	[[23`23`16`4`8`3`2`2`2`6`3`2`48`12`1`0`1`0`1`3`5`10`-72`8`0`0`0`0]],
	
[[
5`104`50`2`
4`154`93`1`
4`276`38`7`
5`464`22`4`
6`498`94`1
]],

[[
302`29`\f2\^o0ff❎\|e\n\ng\|fr\|fa\|fb`
286`33`\f2\^o0ff\^:00008064320f0204		\|e\^:0000070c90a0c0f0
]]

},
-- 3
{
	[[2`6`3`2`48`16`1`0`1`0`1`3`5`10`-170`8`1`0`0`0]],
	
[[
13`51`331`18`
13`148`246`19`
5`78`154`6`
15`20`72`1`
7`80`90`1`
5`247`36`4`
4`323`62`2`
6`438`105`3`
7`350`16`3
]]

},
-- 4
{
	[[1`7`3`4`-102`36`1`0`0`0`0`10`4`8`-40`36`0`0`0`0]],
	
[[
5`79`76`6`
7`240`10`2`
6`274`44`3`
6`432`75`8`
7`390`6`3
]]

},
-- 5
{
	[[0`3`3`4`208`4`1`0`0`0`0`12`5`8`-140`-4`0`0`0`0]],
	
[[
16`112`239`4`
6`298`170`8`
6`161`37`8`
7`300`40`2`
7`346`26`1`
16`205`140`9
]]

},
-- 6
{
	[[1`7`5`4`-48`-10`1`0`0`0`0`10`5`12`-242`4`1`0`0`0]],

[[
11`108`48`1`
8`272`90`10
]]

},
-- 7
{
	[[1`4`2`2`-48`32`1`0`30`-3`1`6`5`4`32`-26`1`0`45`-6]],
	
[[
4`205`99`2`
7`230`57`1`
16`150`54`1`
16`315`20`4
]]
},
-- 8
{
	[[2`7`3`4`0`-26`1`0`30`0`2`7`4`4`32`68`1`0`60`0]],
	
[[
13`76`84`20`
18`200`68`3`
7`295`50`1`
18`360`72`1
]]
	
},
-- 9
{
	[[2`7`3`4`0`-26`1`1`30`-3`2`7`4`4`32`68`1`1`60`-6]],
	
[[
17`57`233`11`
16`213`238`4`
16`308`183`1`
16`309`66`4
]]

},
-- 10
{
	[[2`0`3`12`0`10`1`0`30`0`2`0`6`16`32`0`1`0`60`0]],
	
[[
18`100`88`3`
16`164`60`4`
17`232`119`1`
16`272`69`6`
17`380`108`11`
18`456`88`1`
15`403`44`1
]]

},
-- 11
{
	[[2`0`3`4`0`14`1`0`30`0`2`3`5`8`0`18`1`0`60`0]],
	
[[
18`216`104`3`
16`196`75`6`
6`308`108`8`
18`524`56`3`
6`458`12`8
]]
},
-- 12
{
	[[2`7`3`4`0`14`1`0`30`0`2`3`5`8`0`18`1`0`60`0]],
[[
22`304`72`10
]]
	
},
-- 13
{
	[[2`7`3`4`0`14`1`0`30`0`2`3`5`8`0`18`1`0`60`0]],
[[
30`77`44`12
]]
	
},
-- 14
{
	[[3`13`2`2`-48`32`1`0`0`0`3`14`3`4`32`40`1`0`0`0]],
	
[[
27`117`108`5`
25`63`169`13`
27`40`156`5`
27`72`215`1`
25`102`205`14`
25`282`260`13
]]
},
-- 15
{
	[[3`13`3`4`-48`17`1`0`0`0`3`14`-2`8`32`54`1`0`0`0]],

[[
27`276`206`1`
27`233`167`7`
27`144`103`16`
27`48`127`5`
31`145`200`1`
28`176`78`1`
32`202`94`2`
15`49`28`1`
27`49`43`1
]]
},
-- 16
{
	[[3`13`3`12`-48`17`1`0`0`0`3`14`-2`40`32`80`1`0`0`0]],
	
[[
27`112`176`15`
28`112`57`1`
28`274`70`1`
16`274`33`6
]]
},

-- 17
{
	[[3`6`2`24`75`64`1`0`0`0`3`14`2`40`0`86`1`0`0`0]],
	
[[
29`338`-4`1`
29`383`122`1`
30`288`148`1`
28`146`8`1
]]
},

{
	[[2`6`2`0`75`10`1`0`1`0`3`1`2`16`0`52`1`0`0`0]],
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
