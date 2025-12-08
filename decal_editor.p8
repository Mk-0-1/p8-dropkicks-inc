pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--
--


decal = {}

outline = {0,0,0,0,0,0,0,0}

function mouse_in_rect(x1,y1,x2,y2)
	return (mouse_x>=x1 and mouse_x<=x2) and (mouse_y>=y1 and mouse_y<=y2)
end

pals={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143}

pal_main=15 -- indexes into the array (0-based)
pal_bg=30
pal_outl=31

function _init()
-- enable mouse buttons
	poke(0x5f2d, 0b1)
-- enable extended palette
	poke(0x5f2e, 0b1)
	
	for i=1,8*8 do
		add(decal,0)
	end

	pal(4,pals[pal_main+1],1)
	pal(5,pals[pal_bg+1],1)
	pal(6,pals[pal_outl+1],1)
	

end


function decode_mousepos(x,y)
		local cx,cy = (mouse_x-10)\8,(mouse_y-10)\8
		return cx%8+cy*8
end

function compress_decal()
	local str = ""
 for j=7,0,-1 do
		local h=0
		for i=0,7 do
			h+=decal[i+j*8 +1] << i
		end
		local hexstr = split(tostr(h,0x1),".",false)[1]
		local hexstr2 = hexstr[#hexstr-1] .. hexstr[#hexstr]
		str = hexstr2 .. str
	end
	
	return str
end

function print_outline()
	local h=0
	for i=0,7 do
		h+=outline[i+1] << i
	end
	
	local hexstr = split(tostr(h,0x1),".",false)[1]
	local hexstr2 = hexstr[#hexstr-1] .. hexstr[#hexstr]
	
	return hexstr2
end


p_cldwn,s_cldwn=1,1

function _update()
	mouse_x, mouse_y = stat(32),stat(33)
	mous_gridx,mous_gridy = (mouse_x-2)\8,(mouse_y-2)\8
	
	if (p_cldwn > 0) p_cldwn-=1
	if (s_cldwn > 0) s_cldwn-=1
	
	local mouse_p = stat(34)
	
	mouse_prim_now = (mouse_p&0b1!=0) and (not mouse_prim or p_cldwn<=0)
	if (mouse_prim_now) p_cldwn = 2
	if (mouse_prim_now and not mouse_prim) p_cldwn = 8
	mouse_prim = mouse_p&0b1!=0
	
	mouse_scnd_now = (mouse_p&0b10!=0) and (not mouse_scnd or s_cldwn<=0)
	if (mouse_scnd_now) s_cldwn = 2
	if (mouse_scnd_now and not mouse_scnd) s_cldwn = 8
	mouse_scnd = mouse_p&0b10!=0
	
	
	if mouse_in_rect(10,10,73,73) then
		if mouse_prim then
			decal[decode_mousepos(mouse_x,mouse_y)+1] = 1
		end
		if mouse_scnd then
			decal[decode_mousepos(mouse_x,mouse_y)+1] = 0
		end
	end
	
	if mouse_in_rect(2,110+2,42,120+2) and mouse_prim_now then
		printh("decal:"..compress_decal())
		printh(compress_decal(),"@clip")
	end

	if mouse_in_rect(84,4,92,12) and mouse_prim_now then
		pal_main+=1
		pal_main%=32
		pal(4,pals[pal_main+1],1)
	end
	if mouse_in_rect(84,4,92,12) and mouse_scnd_now then
		pal_main-=1
		pal_main%=32
		pal(4,pals[pal_main+1],1)
	end
	
	if mouse_in_rect(84,16,92,24) and mouse_prim_now then
		pal_bg+=1
		pal_bg%=32
		pal(5,pals[pal_bg+1],1)
	end
	if mouse_in_rect(84,16,92,24) and mouse_scnd_now then
		pal_bg-=1
		pal_bg%=32
		pal(5,pals[pal_bg+1],1)
	end
	
	if mouse_in_rect(84,28,92,36) and mouse_prim_now then
		pal_outl+=1
		pal_outl%=32
		pal(6,pals[pal_outl+1],1)
	end
	if mouse_in_rect(84,28,92,36) and mouse_scnd_now then
		pal_outl-=1
		pal_outl%=32
		pal(6,pals[pal_outl+1],1)
	end
 
	
	local counter=1
	
	for j=0,2 do
		for i=0,2 do
		
			if not (i==1 and j==1) then
				if mouse_in_rect(58+i*8,90+j*8,58+i*8+6,90+j*8+6) then
					if mouse_prim then
						outline[counter]=1
					elseif mouse_scnd then
						outline[counter]=0
					end
				end
				counter+=1
			end
			
		end
	end
	
	
end

function draw_decal(x,y,col)

	for j=0,7 do
		for i=0,7 do
			if (decal[i+j*8+1]) == 1 then
				rectfill(i*8+x,j*8+y,(i+1)*8+x-1,(j+1)*8+y-1,col)
			end
		end
	end
	
end

function _draw()
	cls()
	
	rectfill(2,2,80+1,80+1,5)
	
	rcol=5
	if (mouse_in_rect(2,110+2,42,120+2)) rcol = 4
	rectfill(2,110+2,42,120+2,rcol)
	print("output hex", 3, 115, 7)
	
	
	rectfill(84,4,92,12,4)
	print("main:".. pals[pal_main+1], 95, 6,7)
	
	
	rectfill(84,16,92,24,5)
	print("bg:".. pals[pal_bg+1], 95, 18,7)
	
	rectfill(84,28,92,36,6)
	print("outl:".. pals[pal_outl+1], 95, 30,7)



	print("outline:",26,90,7)
	
	local counter=1
	for j=0,2 do
		for i=0,2 do
		
			if not (i==1 and j==1) then
				if outline[counter] == 1 then
					rectfill(58+i*8,90+j*8,58+i*8+6,90+j*8+6,7)
					draw_decal(2+i*8,2+j*8,6)
				else
					rect(58+i*8,90+j*8,58+i*8+6,90+j*8+6,7)
				end
				counter+=1
			else
				print(print_outline(),58+8,99,7)
			end
			
			
			
		end
	end


	

	draw_decal(10,10,4)
	
	if mouse_in_rect(10,10,73,73) then
		rect(9,9,72+2,72+2,2)
	
		local cx,cy = mous_gridx,mous_gridy
		
		if decal[decode_mousepos(mouse_x,mouse_y)+1] == 0 then
			rect(cx*8+2,cy*8+2,(cx+1)*8+1,(cy+1)*8+1,4)
		else
			rect(cx*8+2,cy*8+2,(cx+1)*8+1,(cy+1)*8+1,5)
		end
	end
	
	
	spr(1,mouse_x-1,mouse_y-1)
	--pset(mouse_x,mouse_y,5)
	
	
	
	
end

__gfx__
00000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
