pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- story of the mirror
-- by elias mote (roc studios)

-- spawn enemy function
function spawn_enemy(x,y,spr,spd, w, h, is_boss)
  local e = {}
  e.x = x or 0
  e.y = y or 0
  e.dx = 0
  e.dy = 0
  e.w = w or 8
  e.h = h or 8
  e.spr = spr or 1
  e.spd = spd or 0.4
  e.is_boss = is_boss or false
  add(enemies,e)
end

-- check if a map cell is solid
function solid(x,y)
	local obj = blocks[cur_room][flr(x/8)+16*flr(y/8)+1]
	if(obj ~= nil) then
		if(eversion == 0) then
			if(obj >= 128) then
				eversion = 1
				blocks = map_mirror
				music(4)
				refresh_room()
				return true
			end
		elseif(eversion == 1) then
			if(obj == 78 or obj == 79 or obj == 94 or obj == 95) then
				eversion = 2
				music(6)
				refresh_room()
				return false
			end
		elseif(eversion == 2) then
			if(obj >= 160) then
				music(-1)
				music(5)
				eversion = 3
				blocks = map_shadow
				world.x = 0
				world.y = 0
				cur_room = 1
				refresh_room()
				return true
			end
		end
		
		if(obj == 3 or obj == 6 or obj == 7 or (obj == 8 and eversion == 0)
			or obj >= 128) then
			return true
		end
	end
	return false
end

-- check if the area is solid
function solid_area(x,y,w,h)
	return solid(x+w,y) or solid(x+w,y+h) or solid(x,y) or solid(x,y+h)
end

-- check if something has collided with the player
function char_collision(e)
 if(p1.x<e.x+e.w and p1.x+p1.w>e.x and p1.y<e.y+e.h and p1.y+p1.h>e.y) return true
 return false
end

-- player keyboard commands
function player_controls()
	local spd = 1

	-- move around
	if(not is_reading) then
		-- horizontal movement
		if(btn(0)) then
			p1.dx = -spd
			p1.dir = "left"
		end
		if(btn(1)) then
			p1.dx = spd 
			p1.dir = "right"
		end
		if not btn(0) and not btn(1) then
			p1.dx = 0
		end
		
		-- vertical movement
		if(btn(2)) then
			p1.dy = -spd
			p1.ydir = "up"
		end
		if(btn(3)) then
			p1.dy = spd
			p1.ydir = "down"
		end
		if not btn(2) and not btn(3) then
			p1.dy = 0
		end
	end

	-- read slab or talk to brother
	if(btnp(4) and (eversion < 2 or (world.x == 0 and world.y == 2))) then
		if(not is_reading) then
			-- checks nearby object to see if it is interactable
			local objs = {}
			add(objs, blocks[cur_room][flr(p1.x/8)+16*flr(p1.y/8)+1])
			add(objs, blocks[cur_room][flr(p1.x/8)+16*flr(p1.y/8)+2])
			add(objs, blocks[cur_room][flr(p1.x/8)+16*flr(p1.y/8)+1+16])
			add(objs, blocks[cur_room][flr(p1.x/8+1)+16*flr(p1.y/8+1)+1])
			for k,v in pairs(objs) do
				if(v == 1 or v == 2 or v == 12) then
					is_reading = true
					p1.dx = 0
					p1.dy = 0
				end
			end
		else
			is_reading = false
		end
	end
end

-- move the player, an npc or an enemy
function move_actor(act, is_solid)
	
	if(is_solid) then
		if not solid_area(act.x+act.dx,act.y,act.w,act.h) then
			act.x += act.dx
		else
			act.dx = 0
		end

		if not solid_area(act.x,act.y+act.dy,act.w,act.h) then
			act.y += act.dy
		else
			act.dy = 0
		end
	else
		act.x += act.dx
		act.y += act.dy
	end
end

-- ai for the enemy
function enemy_ai(e)
 if e.x < p1.x - 1 then
  e.dx = e.spd
 elseif e.x > p1.x + 1 then
  e.dx = -e.spd
 else
  e.dx = 0
 end

 if e.y < p1.y - 1 then
  e.dy = e.spd
 elseif e.y > p1.y + 1 then
  e.dy = -e.spd
 else
  e.dy = 0
 end
end

-- refresh game timer, enemies
function refresh_room()
	timer = 0
	enemies = {}
	spawn_time = flr(rnd(2*30)) + 1*30
	if(eversion == 2) then
		if(world.x == 0 and world.y == 0 and orbs_acquired[1] == false) spawn_enemy(40,48,49,0)
		if(world.x == 2 and world.y == 1 and orbs_acquired[3] == false) spawn_enemy(64,40,53,0)
		if(world.x == 1 and world.y == 2 and orbs_acquired[2] == false) spawn_enemy(96,16,51,0)
	end
end

-- update the room when the player exits the screen
function update_room()

	-- go to left room
	if(p1.x <= 0 - p1.dx) then
		world.x -= 1
		if(world.x < 0) world.x = 2
		p1.x = 128 - 2 * p1.w
		refresh_room()
	end

	-- go to right room
	if(p1.x >= 128 - p1.w - p1.dx) then
		world.x += 1
		if(world.x > 2) world.x = 0
		p1.x = p1.w
		refresh_room()
	end

	-- go to room above
	if(p1.y <= 0 - p1.dy) then
		world.y += 1
		if(world.y > 2) world.y = 0
		p1.y = 128 - 2 * p1.h
		refresh_room()
	end

	-- go to room below
	if(p1.y >= 128 - p1.h - p1.dy) then
		world.y -= 1
		if(world.y < 0) world.y = 2
		p1.y = p1.h
		refresh_room()
	end

	-- update current room
	cur_room = world.x+world.y*3+1
end

function setup_game()
	-- set game state
	game_state = "game"
			
	-- setup game music and reserve channel 1
	music(-1)
	music(0, 0, 1)

	-- initialize the game timer
	timer = 0

	-- initialize the player
	p1 = {x=32, y=32, dx=0, dy=0, w=7, h=7, dir="right", ydir="down"}

	-- initialize enemy table
	enemies = {}

	-- initialize the eversion level
	eversion = 0

	-- initialize the starting room
	world = {x=2,y=0,width=3,height=3}

	-- setup the blocks for each room
	blocks = map_normal

	-- initialize the current room value
	cur_room = world.x+world.y*3+1

	-- player does not have any light orbs initially
	orbs_acquired = {false, false, false}
end

function _init()
	timer = 0

	-- initialize the game state
	game_state = "title"

	-- initialize game version
	game_version = "v1.0"

	-- initialize is_reading to false
	is_reading = false

	-- read stone slabs to learn more about the world
	cur_text =
	{
		{
			-- (0,0)
			"",

			-- (1,0)
			"",

			-- (2,0)
			"hey bro! are you going up to\n"
			.. "look at the mirror today? it's\n"
			.. "really awesome looking. robbie\n"
			.. "said he checked out the place\n"
			.. "yesterday, and it looks like\n"
			.. "its abandoned. we should be\n"
			.. "able to look at it and be back\n"
			.. "home in time for supper. it's\n"
			.. "not far from here. i'll be there\n"
			.. "shortly.",

			-- (0,1)
			"after father milked the cows\n"
		  	.. "this morning, he went out back\n"
			.. "to the grotto to pray at the\n"
			.. "shrine that he found for the\n"
			.. "old mirror. he says the mirror\n"
			.. "brings our harvest good luck.\n"
			.. "i think he's looking for some\n"
			.. "hope from the holy one ever\n"
			.. "since mother walked off one\n"
			.. "night in her sleep. it's odd,\n"
			.. "but sometimes it feels like i\n"
			.. "can hear mother calling out at\n"
			.. "night from the cave. father put\n"
			.. "candles out in front of the\n"
			.. "mirror in hopes that it would\n"
			.. "help guide mother home. i hope\n"
			.. "mother comes back someday.",

			-- (1,1)
			"",

			-- (2,1)
			"one night i decided to visit\n"
			.. "the grotto alone when i was\n"
			.. "feeling depressed, i lit a few\n"
			.. "of the candles for light and\n"
			.. "gazed upon the mirror intently,\n"
			.. "as if hoping it would offer\n"
			.. "some kind of answer. after a\n"
			.. "short time, my reflection seemed\n"
			.. "to morph into a horrid ugly\n"
			.. "creature. in fear i backed away,\n"
			.. "and only then did i notice a\n"
			.. "tall figure in rust-colored\n"
			.. "robes. a long, bony and sickly,\n"
			.. "hand reached for the mirror's\n"
			.. "polished surface, but before it\n"
			.. "touched it, i ran out of the\n"
			.. "shrine in terror. i never did\n"
			.. "tell my parents what i saw that\n"
			.. "night.",

			-- (0,2)
			"",

			-- (1,2)
		  	"mother told me once that the\n"
			.. "holy light that lit the world\n"
			.. "each day was contained in a\n"
			.. "magic artifact. she said that\n"
			.. "one day, the prince in red was\n"
			.. "jealous of the light and came\n"
			.. "to steal it away. our holy\n"
			.. "queen fought the red prince,\n"
			.. "but it shattered in the\n"
			.. "conflict, giving rise to the\n"
			.. "three major colors of our world:\n"
			.. "red, green and blue. she also\n"
			.. "mentioned that her knights\n"
			.. "placed the shattered remains of\n"
			.. "the light into orbs of the\n"
			.. "three colors and hid them\n"
			.. "throughout the land.",

			-- (2,2)
			"",
		},
		{
			-- (0,0)
			"we are many. we are the image\n"
			.. "of your soul. we are the\n"
			.. "reflections of your being. we\n"
			.. "are born in your gaze, and we\n"
			.. "will become your life.\n",

			-- (1,0)
			"a strange red symbol of a\n"
			.. "triangle with an oblong eye\n"
			.. "suddenly appeared while i looked\n"
			.. "for father. unfathomable dark\n"
			.. "words seemed to hang about it\n"
			.. "it in whispers. i felt an\n"
			.. "ominous chill run down my spine\n"
			.. "just being near it. the eye\n"
			.. "seemed to stare into my soul.\n"
			.. "amidst the mad babbling of\n"
			.. "voices, i thought i could hear\n"
			.. "mother's voice. who left this\n"
			.. "cursed symbol here?\n",

			-- (2,0)
			"a space between spaces. no god\n"
			.. "may enter the dark lands. one\n"
			.. "cannot return to the world of\n"
			.. "light from the mirror plane",

			-- (0,1)
			"what is this strange place? i\n"
			.. "saw father gazing at the shrine\n"
			.. "mirror one night when mother\n"
			.. "suddenly appeared in the dark\n"
			.. "glass. father reached out to\n"
			.. "touch her, but the mirror\n"
			.. "rippled like water, and he\n"
			.. "suddenly fell through. i chased\n"
			.. "after him and somehow ended up\n"
			.. "in this strange world where\n"
			.. "color is bleached from the land.\n"
			.. "i have to hurry and locate\n"
			.. "father or i'll be left alone. i\n"
			.. "can hear mother's voice echoing\n"
			.. "about, but it sounds ancient\n"
			.. "and distored. i'm scared father.\n"
			.. "please come back home.\n",

			-- (1,1)
			"the mirror is an affront to holy\n"
			.. "light. ebony encroaching night\n"
			.. "shall visit you.\n",

			-- (2,1)
			"the crimson eye is awake. the\n"
			.. "shadow road awaits. do not\n"
			.. "be afraid. the red prince's\n"
			.. "cool embrace awaits",

			-- (0,2)
			"when the world becomes dark,\n"
			.. "place the three orbs of light\n"
			.. "and touch the destroyed mirror\n"
			.. "to meet the red prince.",
			-- (1,2)
			"",
			-- (2,2)
			"?#$?^?^#$?%^#$%$#^!???",
		},
		{
			"",
			"",
			"",
			"",
			"",
			"",
			"when the world becomes dark,\n"
			.. "place the three orbs of light\n"
			.. "and touch the destroyed mirror\n"
			.. "to meet the red prince.",
			"",
			"",
		}
	}

	-- initialize the normal world tile map
	map_normal =
	{
		-- (0,0)
		{
			7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 4,
			4, 4, 4, 5, 7, 4, 4, 5, 4, 4, 4, 4, 7, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6, 5, 4, 4, 4,
			4, 4, 4, 4, 7, 4, 4, 5, 6, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 5, 4, 4, 4, 4, 4, 4, 5, 7, 4, 4, 4, 4,
			5, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 7, 4, 4, 4, 5, 7, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 6, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 7, 4, 4, 5, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 7, 4, 7, 7, 7, 4, 4, 6, 4, 4, 4, 4,
			4, 4, 4, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 4, 4,
			4, 4, 4, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 4, 4, 4,
			7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
		},

		-- (1,0)
		{
			7, 4, 4, 4, 4, 4, 4, 4, 5, 4, 4, 4, 5, 4, 4, 7,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 7, 4, 4, 4, 6, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4,
			4, 5, 4, 4, 4, 6, 5, 4, 4, 6, 4, 4, 5, 4, 4, 5,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			5, 4, 5, 4, 4, 4, 5, 6, 4, 4, 4, 4, 4, 4, 4, 5,
			5, 4, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4, 5, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4,
			4, 4, 4, 6, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 5, 4, 4, 4, 4, 4, 5, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 5, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7,
		},

		-- (2,0)
		{
			7, 4, 4, 4, 4, 4, 4, 5,  4,  4,  5,  4, 4, 4, 4, 7,
			4, 4, 4, 4, 4, 4, 4, 4,  4,  4,  4,  4, 4, 4, 4, 4,
			4, 4, 5, 4, 7, 4, 4, 4,  4,  4,  4,  4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4,  4,  4,  4,  4, 4, 7, 4, 4,
			4, 4, 7, 4, 4, 4, 4, 4,  8,  8,  8,  8, 8, 4, 4, 4,
			4, 4, 4, 7, 4, 4, 4, 4,  8,  8,  8,  8, 8, 4, 4, 5,
			4, 4, 5, 4, 4, 4, 4, 4,  8, 14,  8, 14, 8, 4, 4, 4,
			4, 4, 4, 4, 4, 7, 4, 4,  8,  8,  8,  8, 8, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4,  8,  8,  8,  8, 8, 5, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 5,  4,  4,  4,  4, 4, 4, 4, 4,
			4, 4, 4, 4, 5, 4, 4, 4,  4,  4,  4,  4, 4, 4, 4, 4,
			4, 5, 7, 4, 4, 4, 4, 4,  2,  4,  4,  4, 4, 4, 4, 4,
			4, 4, 4, 5, 4, 4, 4, 4,  4,  4,  7,  4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4,  4,  4,  4,  4, 4, 4, 5, 4,
			4, 4, 4, 4, 4, 4, 4, 4,  4,  4,  4,  4, 4, 7, 4, 4,
			7, 4, 4, 4, 4, 4, 5, 4,  4,  4,  4,  4, 4, 5, 4, 7,
		},
		

		-- (0,1)
		{
			7, 7, 7,  7, 7, 4, 4, 4, 4, 4, 4, 7, 7, 7, 7, 7,
			4, 4, 4,  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 5, 4,  5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4,  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5,
			4, 4, 4,  4, 4, 4, 4, 7, 4, 5, 4, 4, 4, 4, 5, 5,
			4, 4, 5,  5, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 5, 12, 5, 4, 4, 5, 4, 7, 7, 4, 4, 4, 4, 4,
			5, 5, 5,  5, 5, 4, 4, 4, 4, 7, 7, 4, 4, 4, 4, 4,
			4, 4, 4,  4, 4, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4,  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			5, 5, 4,  4, 4, 4, 4, 4, 4, 4, 4, 5, 4, 4, 4, 5,
			4, 5, 4,  7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 4,
			4, 4, 4,  4, 5, 4, 4, 4, 4, 4, 4, 4, 4, 7, 4, 5,
			4, 4, 4,  4, 4, 4, 5, 4, 4, 7, 4, 4, 4, 4, 4, 4,
			4, 4, 4,  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			7, 4, 4,  4, 4, 4, 5, 4, 4, 5, 4, 5, 4, 4, 4, 7,
		},

		-- (1,1)
		{
			7, 4, 4, 4, 4, 5, 4, 4, 4, 5, 4, 4, 4, 4, 4, 7,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 5, 4, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5,
			4, 4, 4, 4, 5, 4, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 6, 4, 4, 6, 4, 5, 4, 4, 4, 4,
			5, 4, 4, 4, 6, 5, 6, 4, 5, 4, 6, 4, 5, 4, 4, 5,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6, 4,
			5, 4, 4, 6, 4, 4, 5, 4, 5, 5, 4, 5, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 6, 4, 4, 4, 4, 6, 4, 4, 5,
			4, 4, 5, 4, 5, 6, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 5, 4, 5, 4, 4, 5, 4, 4,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
			7, 4, 4, 4, 4, 4, 5, 4, 5, 4, 4, 4, 4, 4, 4, 7,
		},

		-- (2,1)
		{
			7, 4,  5, 4,  5, 4, 4,  4, 5, 4, 4,  4,  4, 4, 4, 7,
			4, 4,  4, 4,  4, 4, 4,  4, 4, 4, 4,  4,  4, 4, 4, 4,
			4, 4,  4, 4,  4, 4, 4,  4, 4, 4, 4,  4,  4, 4, 4, 4,
			4, 4, 11, 4,  4, 4, 4,  4, 4, 4, 4,  4, 11, 4, 4, 4,
			4, 4,  4, 4,  4, 4, 5,  7, 4, 7, 4,  4,  4, 4, 4, 4,
			4, 4,  4, 4,  5, 4, 4,  4, 4, 4, 5,  4,  4, 5, 4, 4,
			4, 4,  4, 4,  4, 4, 4,  5, 4, 4, 5,  4,  4, 4, 4, 4,
			4, 4,  5, 5,  5, 7, 4, 12, 5, 5, 4,  5,  4, 4, 4, 4,
			4, 4,  4, 4,  4, 7, 4,  4, 4, 4, 4,  4,  4, 5, 4, 5,
			4, 4,  4, 4,  4, 7, 4,  5, 4, 4, 7,  5,  4, 4, 4, 5,
			4, 4,  4, 4,  5, 5, 5,  4, 4, 4, 4, 11,  4, 4, 4, 4,
			4, 4,  4, 4,  4, 4, 4,  4, 5, 4, 7,  4,  5, 4, 4, 4,
			4, 4,  4, 4,  4, 4, 4,  5, 5, 4, 5,  4,  4, 4, 4, 4,
			4, 4,  4, 4, 11, 4, 4,  4, 4, 4, 5,  4,  4, 4, 4, 4,
			4, 4,  4, 4,  4, 4, 4,  4, 4, 4, 4,  4,  4, 4, 4, 4,
			7, 4,  4, 5,  4, 5, 5,  4, 4, 4, 5,  5,  4, 4, 4, 7,
		},

		-- (0,2)
		{
			3,  3,  3,  3, 3, 3,   3,   3,   3,   3, 3, 3,  3,  3, 3, 3,
			3,  0,  0,  0, 0, 0, 128, 129, 130, 131, 0, 0,  0,  0, 0, 3,
			3,  0,  0,  0, 0, 0, 144, 145, 146, 147, 0, 0,  0,  0, 0, 3,
			3,  0,  0,  0, 0, 0, 160, 161, 162, 163, 0, 0,  0,  0, 0, 3,
			3,  0, 10,  0, 0, 0, 176, 177, 178, 179, 0, 0,  0, 10, 0, 3,
			3,  0,  0,  0, 0, 0,   0,   0,   0,   0, 0, 0,  0,  0, 0, 3,
			3,  0,  0,  0, 0, 0,   0,   0,   0,   0, 0, 0,  0,  0, 0, 3,
			3, 10,  0,  0, 0, 0,   0,   0,   0,   0, 0, 0,  0,  0, 0, 3,
			3,  0,  0, 10, 0, 0,   0,   0,   0,   0, 0, 0,  0,  0, 0, 3,
			3,  0,  0,  0, 0, 0,   0,   0,   0,   0, 0, 0, 10,  0, 0, 3,
			3,  0,  0,  0, 0, 0,   0,   0,   0,   0, 0, 0, 10,  0, 0, 3,
			3,  3,  3,  3, 3, 0,   0,   0,   0,   0, 0, 3,  3,  3, 3, 3,
			0,  0,  0,  0, 3, 0,   0,   0,   0,   0, 0, 3,  0,  0, 0, 0,
			0,  0,  0,  0, 3, 0,   0,   0,   0,   0, 0, 3,  0,  0, 0, 0,
			0,  0,  0,  0, 3, 0,   0,   0,   0,   0, 0, 3,  0,  0, 0, 0,
			0,  0,  0,  0, 3, 0,   0,   0,   0,   0, 0, 3,  0,  0, 0, 0,
		},

		-- (1,2)
		{
			7, 4, 4, 4,  4, 4, 4,  4,  4, 4, 4, 4,  4,  4, 4, 7,
			7, 4, 4, 4,  4, 4, 4,  4,  4, 4, 4, 4,  4,  4, 4, 4,
			7, 7, 4, 4,  4, 4, 4,  4,  4, 4, 4, 4,  4, 11, 4, 4,
			7, 7, 4, 4,  4, 4, 4,  4,  4, 4, 4, 4,  4,  4, 4, 4,
			7, 7, 4, 4, 11, 4, 4,  4,  4, 5, 4, 4,  4,  4, 4, 4,
			7, 7, 7, 4,  4, 4, 4,  4,  7, 4, 4, 4,  4,  5, 4, 4,
			7, 7, 4, 5,  4, 4, 4, 11,  4, 4, 4, 5,  4,  4, 4, 4,
			7, 7, 7, 5,  5, 5, 4,  4,  4, 5, 4, 4,  5,  4, 4, 4,
			7, 7, 5, 7,  4, 7, 4, 12,  5, 4, 4, 4,  4,  4, 4, 4,
			7, 4, 5, 5,  4, 4, 4,  4,  4, 4, 4, 4, 11,  4, 4, 4,
			7, 7, 4, 4,  4, 4, 4,  4,  4, 4, 5, 4,  4,  4, 4, 4,
			7, 7, 4, 4, 11, 4, 4,  4,  4, 4, 5, 4,  4,  5, 4, 4,
			7, 7, 4, 4,  4, 4, 4,  4,  4, 7, 4, 4,  4,  4, 4, 4,
			7, 7, 7, 4,  4, 4, 4,  4, 11, 4, 4, 4,  4,  4, 4, 4,
			7, 4, 4, 4,  4, 4, 4,  4,  4, 4, 4, 4,  4,  4, 4, 4,
			7, 4, 4, 4,  4, 4, 4,  4,  4, 4, 4, 4,  4,  4, 4, 7,
		},

		-- (2,2)
		{
			7, 4,  4,  4, 4, 4,  4, 5,  5, 4, 4, 4, 4, 4, 4, 3,
			4, 4,  4,  4, 4, 4,  4, 4,  4, 4, 4, 4, 4, 4, 4, 3,
			4, 4,  4,  4, 4, 4,  4, 4,  4, 4, 4, 4, 4, 4, 4, 3,
			4, 4,  4,  4, 4, 4,  4, 4,  4, 4, 4, 4, 4, 7, 4, 3,
			4, 4,  4,  4, 7, 4,  4, 4,  4, 4, 4, 4, 4, 4, 4, 3,
			4, 5,  4,  4, 4, 4, 11, 4,  4, 4, 4, 4, 4, 4, 4, 3,
			4, 4,  4,  4, 4, 4,  4, 4,  4, 4, 4, 7, 4, 4, 4, 3,
			5, 4, 11,  4, 4, 7,  4, 4,  4, 4, 5, 4, 4, 4, 4, 3,
			5, 4,  4,  4, 4, 4,  4, 4,  4, 7, 4, 5, 4, 4, 4, 3,
			5, 4,  4, 11, 4, 5,  4, 4,  4, 4, 5, 4, 4, 4, 4, 3,
			4, 4,  4,  4, 4, 4,  4, 4,  4, 4, 4, 4, 4, 5, 4, 3,
			4, 4,  4,  4, 4, 4,  4, 4, 11, 4, 4, 7, 4, 4, 4, 3,
			4, 4,  4,  4, 4, 4,  4, 4,  4, 4, 4, 4, 4, 4, 4, 3,
			4, 4,  4,  4, 4, 4,  4, 4,  4, 4, 4, 4, 4, 4, 4, 3,
			4, 4,  4,  4, 4, 4,  4, 4,  4, 4, 4, 4, 4, 4, 4, 3,
			7, 4,  4,  4, 4, 4,  4, 4,  4, 4, 4, 4, 4, 4, 4, 3,
		},
	}

	-- initialize the mirror world tile map
	map_mirror = 
	{
		-- (0,0)
		{
			3,  3, 3,  4, 4, 4, 4, 4, 4, 4, 4, 4,  4, 4, 3, 3,
			3,  4, 4,  4, 4, 4, 4, 4, 4, 4, 4, 4,  4, 4, 4, 4,
			3,  4, 4,  4, 4, 4, 4, 4, 4, 5, 4, 4,  4, 4, 4, 4,
			3,  4, 11, 4, 4, 4, 4, 1, 4, 5, 5, 4,  4, 4, 9, 4,
			3,  4, 8,  4, 5, 4, 4, 4, 4, 4, 4, 4,  4, 5, 9, 4,
			3,  4, 9,  4, 1, 4, 4, 4, 4, 4, 4, 7,  4, 4, 9, 4,
			3,  4, 8,  4, 4, 9, 4, 4, 4, 4, 4, 4,  4, 4, 9, 4,
			3,  4, 9,  7, 4, 4, 7, 3, 4, 4, 1, 4,  4, 1, 4, 4,
			3,  4, 4,  4, 4, 4, 4, 4, 3, 4, 7, 4,  4, 4, 4, 4,
			3, 11, 4,  7, 7, 4, 4, 4, 1, 4, 4, 4,  4, 4, 4, 4,
			3,  4, 4,  7, 3, 4, 5, 4, 4, 4, 3, 4,  4, 4, 4, 4,
			3,  4, 4,  7, 4, 5, 5, 4, 4, 4, 4, 4, 11, 4, 4, 4,
			3,  4, 4, 11, 4, 4, 4, 7, 4, 4, 4, 4,  4, 4, 4, 4,
			3,  4, 4,  4, 4, 1, 4, 4, 4, 4, 4, 4,  4, 4, 4, 4,
			3,  4, 4,  4, 4, 4, 4, 4, 4, 5, 4, 4,  4, 4, 4, 4,
			3,  3, 3,  3, 3, 3, 3, 3, 3, 3, 3, 3,  3, 3, 3, 3,
		},

		-- (1,0)
		{
			7, 4, 4, 4, 4, 4,  4,  4, 4, 4, 4,  4, 4, 4, 7, 7,
			4, 4, 4, 4, 4, 4,  4,  4, 4, 4, 4,  4, 4, 4, 7, 7,
			4, 4, 4, 4, 4, 4,  4,  4, 4, 4, 4,  4, 4, 4, 7, 7,
			4, 4, 4, 5, 4, 4,  4,  4, 4, 7, 4, 12, 4, 4, 4, 4,
			5, 4, 9, 4, 4, 6,  6,  6, 6, 4, 4,  4, 4, 4, 4, 4,
			4, 4, 9, 4, 6, 4, 78, 79, 4, 6, 7,  4, 4, 8, 5, 4,
			4, 4, 9, 4, 6, 4, 94, 95, 4, 6, 7,  4, 4, 8, 4, 4,
			4, 4, 7, 4, 6, 5,  4,  4, 4, 6, 4,  4, 7, 8, 4, 4,
			5, 5, 9, 4, 6, 4,  5,  4, 4, 6, 4,  4, 4, 4, 4, 4,
			4, 4, 4, 4, 6, 5,  4,  4, 4, 6, 4,  4, 4, 4, 5, 4,
			4, 4, 4, 4, 6, 4,  5,  4, 4, 6, 4,  4, 4, 4, 4, 4,
			4, 4, 4, 5, 6, 4,  4,  4, 4, 6, 5,  4, 4, 4, 4, 4,
			4, 4, 4, 4, 6, 4,  4,  4, 4, 6, 4,  4, 9, 4, 4, 5,
			4, 4, 4, 4, 6, 4,  5,  4, 4, 6, 4,  4, 8, 4, 7, 7,
			4, 4, 4, 4, 6, 5,  5,  4, 4, 6, 4,  4, 4, 4, 7, 7,
			7, 7, 7, 7, 6, 4,  5,  4, 4, 6, 7,  7, 7, 7, 7, 7,
		},

		-- (2,0)
		{
			7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7,
			7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6,
			7, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6,
			4, 4, 4, 1, 5, 5, 4, 4, 7, 4, 4, 4, 4, 4, 4, 6,
			4, 4, 4, 4, 4, 4, 4, 4, 6, 4, 4, 4, 4, 4, 4, 6,
			4, 4, 4, 4, 6, 5, 4, 4, 5, 4, 6, 5, 4, 6, 4, 6,
			4, 4, 4, 4, 4, 1, 9, 4, 4, 4, 4, 4, 4, 4, 4, 6,
			4, 4, 6, 1, 4, 4, 9, 5, 5, 7, 9, 4, 4, 4, 4, 6,
			5, 5, 4, 4, 4, 6, 9, 4, 4, 4, 8, 4, 4, 4, 4, 6,
			5, 5, 5, 4, 4, 4, 7, 4, 4, 4, 9, 4, 6, 4, 4, 6,
			5, 4, 4, 6, 4, 6, 4, 4, 1, 6, 8, 4, 4, 4, 4, 6,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 6, 6, 4, 4, 6,
			4, 4, 4, 4, 4, 4, 4, 6, 4, 4, 4, 4, 4, 4, 4, 6,
			7, 4, 4, 4, 6, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6,
			7, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6,
			7, 7, 7, 4, 4, 4, 4, 4, 5, 4, 5, 4, 4, 4, 4, 7,
		},

		-- (0,1)
		{
			7, 7, 7, 7,  7, 4, 4, 4,  4,  4, 4, 7, 7,  7, 7, 7,
			5, 4, 7, 4,  4, 4, 4, 4,  4,  4, 4, 4, 7,  7, 5, 7,
			5, 5, 4, 4,  4, 4, 4, 4,  4,  4, 4, 4, 4,  4, 7, 7,
			5, 4, 4, 4,  4, 4, 4, 4,  6,  4, 4, 4, 4,  4, 4, 7,
			4, 4, 6, 4,  4, 4, 4, 4,  4,  4, 4, 6, 4,  6, 4, 7,
			4, 4, 4, 4,  4, 6, 4, 4,  5,  5, 4, 4, 4,  4, 4, 7,
			4, 4, 4, 4,  4, 6, 4, 4,  5, 12, 4, 4, 4,  4, 4, 7,
			4, 4, 4, 7, 11, 4, 4, 4,  5,  5, 4, 5, 4,  9, 7, 7,
			4, 4, 4, 4,  8, 4, 4, 4,  4,  4, 4, 4, 4, 11, 7, 7,
			4, 4, 6, 4,  9, 6, 4, 6,  4,  6, 4, 4, 4,  8, 7, 7,
			4, 4, 4, 4,  8, 4, 4, 9,  4,  4, 4, 4, 6,  9, 7, 7,
			7, 4, 4, 4,  9, 6, 6, 4,  4,  4, 4, 4, 4,  4, 7, 7,
			7, 7, 4, 4,  5, 6, 4, 4,  6,  4, 4, 6, 4,  4, 7, 7,
			7, 7, 7, 4,  4, 4, 4, 4,  4,  4, 4, 4, 4,  4, 7, 7,
			7, 7, 7, 4,  4, 4, 4, 4,  4,  4, 4, 4, 4,  4, 7, 7,
			7, 7, 7, 5,  4, 4, 4, 4,  4,  4, 4, 4, 4,  4, 7, 7,
		},

		-- (1,1)
		{
			7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7, 7, 7,
			6, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7, 7, 7,
			6, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7,
			6, 4, 4, 6, 4, 4, 1, 4, 4, 5, 9, 5, 4, 4, 4, 7,
			6, 4, 1, 4, 4, 4, 4, 4, 4, 4, 8, 4, 4, 4, 4, 7,
			6, 6, 4, 4, 7, 6, 4, 4, 4, 4, 9, 4, 5, 4, 4, 4,
			6, 6, 4, 4, 7, 7, 4, 4, 5, 4, 9, 4, 4, 4, 4, 4,
			6, 6, 5, 4, 1, 3, 3, 4, 4, 5, 8, 4, 4, 4, 4, 4,
			6, 6, 6, 6, 4, 3, 5, 6, 6, 4, 4, 4, 4, 4, 4, 5,
			6, 4, 6, 4, 9, 4, 4, 7, 7, 4, 1, 5, 4, 5, 4, 4,
			6, 4, 6, 4, 8, 5, 4, 4, 5, 7, 4, 4, 4, 4, 4, 4,
			6, 4, 4, 4, 8, 4, 4, 4, 4, 4, 5, 4, 7, 4, 4, 4,
			6, 4, 4, 4, 9, 4, 4, 4, 4, 4, 6, 4, 4, 4, 4, 4,
			6, 4, 4, 4, 4, 4, 4, 4, 9, 4, 4, 6, 4, 4, 4, 4,
			6, 4, 4, 4, 1, 4, 4, 4, 8, 4, 4, 4, 4, 4, 7, 7,
			6, 4, 4, 4, 4, 5, 5, 5, 4, 5, 4, 4, 4, 4, 7, 7,
		},

		-- (2,1)
		{
			7, 7, 7, 7, 4, 4, 4, 4, 5, 5, 4,  4, 4, 4, 4, 7,
			7, 7, 7, 4, 4, 4, 4, 4, 4, 5, 4,  4, 4, 4, 4, 4,
			7, 7, 7, 4, 4, 1, 4, 4, 4, 4, 4,  4, 4, 1, 4, 4,
			7, 4, 4, 5, 4, 4, 4, 4, 4, 4, 4,  4, 1, 4, 4, 4,
			7, 4, 4, 4, 4, 5, 6, 4, 4, 4, 4,  6, 4, 4, 4, 4,
			5, 4, 4, 1, 4, 4, 4, 4, 4, 4, 4,  4, 4, 4, 4, 4,
			5, 4, 4, 4, 4, 4, 4, 4, 6, 5, 4,  4, 4, 1, 4, 4,
			4, 4, 4, 4, 1, 4, 6, 4, 4, 3, 4,  4, 4, 4, 4, 4,
			4, 8, 5, 7, 9, 4, 4, 1, 3, 1, 3, 11, 4, 4, 4, 4,
			4, 9, 4, 4, 5, 4, 4, 4, 3, 1, 3, 11, 4, 4, 4, 4,
			4, 8, 4, 4, 4, 5, 4, 4, 4, 3, 4, 11, 4, 4, 4, 4,
			4, 9, 4, 4, 4, 6, 4, 6, 4, 4, 4,  7, 7, 7, 7, 7,
			4, 4, 4, 6, 4, 4, 4, 6, 4, 4, 4,  4, 7, 7, 7, 7,
			4, 4, 4, 4, 4, 6, 4, 6, 4, 4, 4,  4, 4, 4, 4, 7,
			4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,  4, 4, 4, 4, 7,
			7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,  4, 4, 4, 4, 7,
		},

		-- (0,2)
		{
			3, 3, 3,  3, 3, 3,   3,   3,   3,   3, 3, 3, 3, 3 ,3, 3,
			3, 0, 0,  0, 0, 0, 128, 129, 130, 131, 0, 0, 0, 0 ,0, 3,
			3, 0, 0,  0, 0, 0, 144, 145, 146, 147, 0, 0, 2, 0 ,0, 3,
			3, 2, 0,  0, 0, 0, 160, 161, 162, 163, 0, 0, 0, 0 ,0, 3,
			3, 0, 0,  0, 0, 0, 176, 177, 178, 179, 0, 0, 0, 0 ,0, 3,
			3, 0, 0,  0, 0, 0,   0,   0,   0,   0, 0, 0, 0, 2 ,0, 3,
			3, 0, 0,  2, 0, 0,   0,   0,   0,   0, 0, 0, 0, 0 ,0, 3,
			3, 0, 0,  0, 0, 0,   0,   0,   0,   0, 0, 0, 0, 0 ,0, 3,
			3, 0, 0,  0, 0, 0,   0,   0,   0,   0, 0, 0, 0, 0 ,0, 3,
			3, 0, 0,  0, 0, 0,   0,   0,   0,   0, 0, 2, 0, 0 ,0, 3,
			3, 0, 0,  0, 0, 0,   0,   0,   0,   0, 0, 0, 0, 0 ,0, 3,
			3, 3, 3,  3, 3, 0,   0,   0,   0,   0, 0, 3, 3, 3 ,3, 3,
			0, 0, 0,  0, 3, 0,   0,   0,   0,   0, 0, 3, 0, 0 ,0, 0,
			0, 0, 0,  0, 3, 0,   0,   0,   0,   0, 0, 3, 0, 0 ,0, 0,
			0, 0, 0,  0, 3, 0,   0,   0,   0,   0, 0, 3, 0, 0 ,0, 0,
			0, 0, 0,  0, 3, 0,   0,   0,   0,   0, 0, 3, 0, 0 ,0, 0,
		},

		-- (1,2)
		{
			3, 6, 6, 6, 7, 4, 4, 4, 4, 7, 6, 6, 6, 6, 6, 3,
			3, 4, 4, 4, 7, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 3,
			3, 4, 4, 4, 9, 7, 4, 4, 7, 4, 4, 4, 4, 4, 4, 3,
			3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3,
			3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 3,
			3, 3, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 3,
			3, 4, 4, 4, 9, 3, 4, 4, 4, 4, 4, 9, 4, 5, 5, 3,
			3, 4, 4, 4, 4, 4, 4, 4, 4, 5, 4, 4, 4, 4, 4, 3,
			3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 4, 4, 5, 4, 3,
			3, 4, 4, 7, 7, 9, 9, 4, 4, 5, 4, 4, 4, 4, 4, 3,
			3, 4, 4, 4, 7, 9, 4, 4, 4, 4, 4, 4, 3, 4, 4, 3,
			3, 4, 4, 4, 4, 9, 4, 4, 3, 4, 7, 4, 4, 4, 4, 3,
			3, 4, 4, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3,
			3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3,
			3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3,
			3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3,
		},

		-- (2,2)
		{
			3, 3, 3, 4,  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3,
			3, 3, 4, 4,  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3,
			3, 4, 5, 4,  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3,
			3, 4, 5, 4,  9, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3,
			3, 4, 4, 4,  8, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3,
			3, 4, 4, 4, 11, 4, 4, 4, 7, 4, 4, 4, 5, 5, 5, 3,
			3, 4, 4, 5,  9, 1, 4, 1, 4, 4, 5, 4, 4, 5, 3, 3,
			3, 3, 3, 4,  4, 4, 4, 5, 4, 4, 4, 4, 7, 4, 4, 3,
			3, 4, 3, 4,  4, 4, 4, 4, 4, 5, 4, 4, 4, 4, 4, 3,
			3, 7, 7, 8,  8, 4, 7, 1, 4, 4, 3, 7, 4, 4, 4, 3,
			3, 7, 7, 4,  2, 4, 4, 4, 4, 4, 4, 4, 4, 7, 4, 3,
			3, 4, 4, 4,  2, 4, 4, 5, 4, 4, 2, 4, 7, 4, 4, 3,
			3, 4, 4, 4,  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3,
			3, 3, 3, 4,  4, 8, 4, 4, 4, 4, 4, 4, 8, 4, 4, 3,
			3, 3, 3, 3,  4, 4, 4, 4, 4, 4, 4, 4, 4, 9, 9, 3,
			3, 3, 3, 3,  4, 4, 4, 5, 4, 4, 5, 4, 4, 9, 9, 3,
		},
	}

	-- initialize the shadow world tile map
	map_shadow = 
	{
		{
			7, 7, 7, 7, 7, 7, 7,  7,  7, 7, 7, 7, 7, 7, 7, 7,
			7, 7, 7, 7, 7, 7, 7,  7,  7, 7, 7, 7, 7, 7, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 0, 0, 0, 0, 0,  0,  0, 0, 0, 0, 0, 0, 7, 7,
			7, 7, 7, 7, 7, 7, 7,  7,  7, 7, 7, 7, 7, 7, 7, 7,
			7, 7, 7, 7, 7, 7, 7,  7,  7, 7, 7, 7, 7, 7, 7, 7,
		}
	}
end

function _update()

	-- title screen controls
	if(game_state == "title") then
		if(btnp(4)) game_state = "warning"

	-- warning screen controls
	elseif(game_state == "warning") then
		if(btnp(4)) game_state = "tutorial"

	elseif(game_state == "tutorial") then
		if(btnp(4)) game_state = "quote"

	-- quote screen controls
	elseif(game_state == "quote") then
		if(btnp(4)) then
			setup_game()
		end

	-- update game
	elseif(game_state == "game") then
		-- update the timer when not reading
		if(not is_reading) timer = (timer + 1) % 32000
		
		-- player controls
		player_controls()

		-- update player
		move_actor(p1, true)
		
		-- update room when player is at edge
		update_room()

		-- spawn enemies in the dark world
		if(eversion == 2 and not (world.x == 0 and world.y == 2)) then
			-- check how many orbs have been collected
			local num_collected = 0
			for k,v in pairs(orbs_acquired) do
				if(v == true) num_collected += 1
			end

			-- spawn more enemies if more orbs have been collected
			for i=1,num_collected+1 do
				if(timer == spawn_time * i) then
					local x = flr(rnd(2))
					local y = flr(rnd(2))
					local spd = 0.3 + rnd(0.3)
					local spr = 33
					if(x == 0 and y == 0) spawn_enemy(0,0,spr,spd)
					if(x == 1 and y == 0) spawn_enemy(128,0,spr,spd)
					if(x == 0 and y == 1) spawn_enemy(0,128,spr,spd)
					if(x == 1 and y == 1) spawn_enemy(128,128,spr,spd)
				end
			end
		end

		-- shadow map updates (player win condition)
		if(eversion == 3) then

			-- after 20 seconds in the shadow map, stop music
			if(timer == 30 * 20) music(-1, 1000)

			-- after twenty one seconds, spawn the red prince
			if(timer == 30 * 27) then
				spawn_enemy(128, 64, 201, 4, 16, 32, true)
				music(7)
			end
		end
			

		-- for each enemy, update when not reading
		if(not is_reading) then
			for k,v in pairs(enemies) do
				-- enemy movement
				move_actor(v)

				-- enemy ai (slow movement towards player)
				enemy_ai(v)

				-- check collisions of the light orbs
				if(orbs_acquired[1] == false) then
					if(char_collision(v) and v.spr == 49) then
						orbs_acquired[1] = true
						del(enemies, v)
						sfx(9)
					end
				end
				if(orbs_acquired[2] == false) then
					if(char_collision(v) and v.spr == 51) then
						orbs_acquired[2] = true
						del(enemies, v)
						sfx(9)
					end
				end
				if(orbs_acquired[3] == false) then
					if(char_collision(v) and v.spr == 53) then
						orbs_acquired[3] = true
						del(enemies, v)
						sfx(9)
					end
				end

				-- kill the player if an enemy collides
				if(char_collision(v) and (v.spr == 33 or v.spr == 201)) then
					if(v.is_boss == true) then
						refresh_room()
						game_state = "ending"
						music(-1)
					else
						refresh_room()
						game_state = "dying"
						music(-1)
					end
				end
			end
		end
	
	elseif(game_state == "dying") then
		music(-1)
		timer = (timer + 1) % 32000
		if(timer >= 30 * 5) game_state = "title"
	elseif(game_state == "ending") then
		timer = (timer + 1) % 32000
		if(timer < 30 * 13) then
			music(-1)
		
		elseif(timer == 30 * 14) then
			music(7)

		elseif(timer >= 30 * 15) then
			music(-1)
			game_state = "title"
		end
	end
end

function _draw()
	cls()
	color(7)
	-- draw title screen objects
	if(game_state == "title") then
		print("story of the mirror", 26, 0)
		spr(128, 48, 24, 4, 4)
		spr(1, 60, 44)
		print("press 'z' to play", 32, 72)

		print("developed by elias mote", 0, 88)
		print("tested by ryan keefe", 0, 96)
		print("made for darktober 2018 jam", 0, 104)
		print("(c) roc studios 2018", 0, 112)
		print(game_version, 0, 120)

	-- draw warning screen (comes after title)
	elseif(game_state == "warning") then
		local x = 4
		local y = 54
		print("this game is not suitable for", x, y)
		print("children or those easily", x, y+8)
		print("disturbed.", x, y+16)

	-- draw controls screen
	elseif(game_state == "tutorial") then
		print("how to play:", 0, 0)
		print("touch objects to activate them.", 0, 8)
		spr(144, 16, 16, 4, 3)
		spr(142, 56, 16, 2, 2)
		spr(49, 88, 16)

		print("press z on slabs or characters", 0, 40)
		print("to interact with them.", 0, 48)
		spr(61, 88, 48)
		spr(18, 104, 48)

		print("use direction keys to move.", 0, 64)

		print("avoid touching enemies that", 0, 72)
		print("hunt you down.", 0, 80)
		spr(33,64,80)

		print("traverse the mirror world and", 0, 96)
		print("walk the dark path.", 0, 104)
		print("press z to play.", 0, 120)

	elseif(game_state == "quote") then
		local x = 12
		local y = 48
		print("what say of it? what say", x, y)
		print("conscience grim", x, y+8)
		print("that spectre in my path?", x, y+16)
		print("- chamberlain's pharronida", x, y+32)

	-- draw game objects
 	elseif(game_state == "game") then
 		-- draw blocks
	 	for i=1,(16*16) do
	 		local b = blocks[cur_room][i]
	 		if(b ~= 0) then
	 			if(b < 64) then
	 				spr(b+16*eversion,((i-1)*8)%128, 8*flr((i-1)/16))
	 			elseif(b < 128) then
	 				spr(b+32*(eversion-1),((i-1)*8)%128, 8*flr((i-1)/16))
	 			elseif(b < 192) then
	 				spr(b+4*eversion,((i-1)*8)%128, 8*flr((i-1)/16))
	 			end
	 		end
	 	end
	 	
	 	-- draw the crimson eye based on timer
	 	if(eversion == 3) then
	 		local x = 56
	 		local y = 32
	 		local w = 2
	 		local h = 2
	 		if(timer < 30 * 21) then
	 			spr(142, x, y, w, h)
	 		elseif(timer < 30 * 22) then
	 			spr(192, x, y, w, h)
	 		elseif(timer < 30 * 23) then
	 			spr(194, x, y, w, h)
	 		elseif(timer < 30 * 24) then
	 			spr(192, x, y, w, h)
	 		elseif(timer < 30 * 25) then
	 			spr(196, x, y, w, h)
	 		else
	 			spr(198, x, y, w, h)
	 		end
	 	end

	 	-- draw player
	 	if(p1.dir == "left") then
	 		local s = 57
	 		if(p1.ydir == "up") s = 59
	 		spr(s, p1.x, p1.y, 1, 1, true)
	 	else
	 		local s = 57
	 		if(p1.ydir == "up") s = 59
	 		spr(s, p1.x, p1.y)
	 	end

	 	-- draw enemies
		for k,v in pairs(enemies) do
			if(v.spr == 33) then
				if(timer % 2 == 0) then
					if(v.dx < 0) then
						spr(v.spr, v.x, v.y, 1, 1, true)
					else
						spr(v.spr, v.x, v.y, 1, 1)
					end
				end
			elseif(v.spr >= 49 and v.spr <= 54) then
				spr(v.spr + timer % 2, v.x, v.y)
			elseif(v.spr == 201) then
				spr(v.spr, v.x, v.y, v.w/8, v.h/8, true)
			else
				spr(v.spr, v.x, v.y, v.w/8, v.h/8)
			end
		end

	 	-- if eversion is at between 1 and 2, draw random horizontal bars
	 	if(eversion >= 1 and eversion <= 2) then
		 	if(timer % (60/eversion) <= 20) then
		 		local y1 = flr(rnd(112)) + 8
		 		local y2 = y1 + flr(rnd(3))
		 		rectfill(0, y1, 128, y2, 0)
		 	end
		end

		-- draw the orbs in the eversion 2 shrine
	 	if((eversion == 2 and world.x == 0 and world.y == 2)
	 	or eversion == 3) then
	 		if(orbs_acquired[1]) spr(49+timer%2,60,64)
	 		if(orbs_acquired[2]) spr(51+timer%2,40,80)
	 		if(orbs_acquired[3]) spr(53+timer%2,80,80)
	 	end

		-- draw reading text if player is reading something
	 	if(is_reading) then
	 		local y = 0
	 		color(0)
	 		rectfill(0,y,128,128,0)
	 		color(7)
	 		print(cur_text[eversion+1][cur_room], 0, y, 7)
	 	end

	elseif(game_state == "ending") then
		if(timer < 30 * 12) then
			print("congratulations, you have\n"
				.. "completed story of the mirror.\n"
				.. "you have traversed the mirror\n"
				.. "realm and stepped through the\n"
				.. "shadows to meet the red prince.\n"
				.. "however, when one walks through\n"
				.. "a mirror, their reflection must\n"
				.. "take their place...", 0, 40
				)
		elseif(timer >= 30 * 14) then
			local dt = (timer - (30 * 14))*3.2
			sspr(88, 96, 32, 32, 48 - dt/2, 48 - dt/2, 32 + dt, 32 + dt)
		end

	elseif(game_state == "dying") then
		print("game over", 48, 56, 7)
	end	
end
__gfx__
000000000008880033344433400044443333333333333333333443333333333300000000333b33338008000833bbbb3333555533000666004444444400000000
0000000000888880334444434400044433333333333b333333444ff33bbbbb3388088888b33b3333900900093b3333b335555553006666604004000444044444
0070070008f1f1f034fcfcf3004400043333333333b333333454544f3bb3bbb300000000b33b333390090009bb3333bb55555555067070704004000400000000
0007700008fffff034fffff3044440003333333333b33333444455443b3bb3b388888088b33b333390090009b3b33b3b50050055067777704004000444444044
000770000111111035555553444400403333333333333b33444544543bbbbbb3000000003b3b33b390090009b33bb33b55555555066666604444444400000000
007007000f1111f03f5555f30444044433333333333333b3544444443334f3338888888033bb33b399999999b33bb33b55005505076666704004000444444440
0000000000cccc0033cccc3300444044333333333b333333355445433334433300000000333bbb33000900003b3bb3b355555555007777004004000400000000
0000000000c00c0033c33c33000000003333333333333333333543333344433388808888333bb3330009000033bbbb3355555555007007004444444444404444
00000000555666550006660050005555555555555555555555665555555555555550055555500555000000005500005555777755000000000000000000000000
0000000055666665006666605500055555555555555655555666ff55566666555550055505500555000000005055550557777775000000000000000000000000
0000000056707075067070700055000555555555556555556d6d66f5566566655550055505500555000000000055550077777777000000000000000000000000
000000005677777506777770055550005555555555655555666dd666565665655550055505500555000000000505505070070077000000000000000000000000
00000000566666650666666055550050555555555555565566d66d66566666655550055550500505000000000550055077777777000000000000000000000000
0000000057666675076666700555055555555555555555656666666d555df5555550055555000505000000000550055077007707000000000000000000000000
000000005577775500777700005550555555555556555555dd66d655555dd5555550055555500055000000005050050577777777000000000000000000000000
00000000557557550070070000000000555555555555555555d6555555ddd5555550055555500555000000005500005577777777000000000000000000000000
00000000000660000005550078887777000000000088000066000060000000000000000000000000000000000080000000000000000000000000000000000000
00000000066600600050005077888777000000000080888006666600007770000000000000000000000000000807777000000000000000000000000000000000
00000000667808700508085088778887000000000000008806566560007877000000000000000000000000008800008700000000000000000000000000000000
00000000067877800500005087777888000000008800000066666660078878700000000000000000000000007070070700007000000000000000000000000000
00000000555555500500005077778878000000000880080066556666087877700000000000000000000000007008800800707700000000000000000000000000
000000000755557005000050877787770000000008000080665556667800d0770000000000000000000000007008700707077070000000000000000000000000
000000000766660750000550887778770000000000008880065556067000d0700000000000000000000000000808777077007770000000000000000000000000
0000000000060660555555008888888800000000000000080065600000dd80000000000000000000000000000077700077777707000000000000000000000000
00000000008888000088880000333300003333000011110000111100000000000006600000088800000000000008880000000000005555000000000000000000
00000000088878800888888003337330033333300111711001111110000000000666006000888880000888000088888000088800055555500000000000000000
000000008887f7888888f8883337b7333333b3331117c7111111c111000000006678087008f1f1f0008888800888888000888880555555550000000000000000
00000000888878888888888833337333333333331111711111111111000000000678778008fffff008f1f1f00888888008888880500500550000000000000000
0000000088888888888888883333333333333333111111111111111100000000660066660111111008fffff00111111008888880555555550000000000000000
0000000088888888888888883333333333333333111111111111111100000000660006660f1111f0011111100f1111f001111110550055050000000000000000
00000000088888800888888003333330033333300111111001111110000000000600060600cccc000f1111f000cccc000f1111f0555555550000000000000000
00000000008888000088880000333300003333000011110000111100000000000060600000c00c0000c00c0000c00c0000c00c00555555550000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555555885555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555558008555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555580000855555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555580000855555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555800880085555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555808008085555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005558008008008555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005558080800808555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005580080800800855
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005580080800800855
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005580080800800855
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005800080800800085
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005800008008000085
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000008008000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000880000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008888888888888888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555555550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055000555555550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000550005505555550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555000005550555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005550000505500050
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005500000555000050
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005008805555008055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005500800555508055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500005555508055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005555055505508855
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000550055005500855
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555550000550555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555500000550550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055500000550500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005550005555000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055055550000
00055500005055555500005500555500000555000050555555000055005555000000000000000000000000000000000000000000000000000000000880000000
00055555000555550000005550500000000555550005555500000055505000000000000000000000000000000000000000000000000000000000008008000000
50000555500555000000555550550005500005555005550000005555505500050000000000000000000000000000000000000000000000000000080000800000
55000555555555555555555550055555550005555555555555555555500555550000000000000000000000000000000000000000000000000000080000800000
55055555555555555555555555555555550555555555555555555555555555550000000000000000000000000000000000000000000000000000800880080000
55555556657666566656666665555555555555588578885888588888855555550000000000000000000000000000000000000000000000000000808008080000
05555566656665566656666656555055055555888588855888588888585550550000000000000000000000000000000000000000000000000008008008008000
00505566765666666566665566655055005055887858888885888855888550550000000000000000000000000000000000000000000000000008080800808000
00505657666666666666666666655005005058578888888888888888888550050000000000000000000000000000000000000000000000000080080800800800
05505675666666666666666666655005055058758888888888888888888550050000000000000000000000000000000000000000000000000080080800800800
05005766666666666666666666655500050057888888888888888888888555000000000000000000000000000000000000000000000000000080080800800800
00005666666666666666666666755500000058888888888888888888887555000000000000000000000000000000000000000000000000000800080800800080
05555666666666666666666667755555055558888888888888888888877555550000000000000000000000000000000000000000000000000800008008000080
00505666666666666666666677655555005058888888888888888888778555550000000000000000000000000000000000000000000000008000008008000008
00005666666666666666666776650055000058888888888888888887788500550000000000000000000000000000000000000000000000008000000880000008
05555666666666666666667766650055055558888888888888888877888500550000000000000000000000000000000000000000000000008888888888888888
05055666666666666666677666650055050558888888888888888778888500550000000000000000000000000000000000000000000000000000000000000000
00005666666666666666776666650055000058888888888888887788888500550000000000000000000000000000000000000000000000000000000000000000
00005666666666666667766666655005000058888888888888877888888550050000000500000000000000000000000000000000000000000000000000000000
00055666666666666677666666655005000558888888888888778888888550050000555500000000000000000000000000000000000000000000000000000000
00055666666666666776666666655505000558888888888887788888888555050000050500555000050555500000000000000000000000000000000000000000
00055666666666667766666666755500000558888888888877888888887555000000000500555550005555500000000000000000000000000000000000000000
05055666666666677666666667655555050558888888888778888888878555550500555500005500005500550055000000000000000000000000000000000000
05055666666666776666666676655555050558888888887788888888788555550500505555005000005550555555000000000000000000000000000000000000
05055666666667766666666766655555050558888888877888888887888555550505500550555000555550555555550000000000000000000000000000000000
05555666666677666666667666655555055558888888778888888878888555550555000555555555555550555555000000000000000000000000000000000000
55555666666776666666676666655505555558888887788888888788888555055550005555555555555550555550550500000000000000000000000000000000
55555666667766666666766666655005555558888877888888887888888550055550005505055055500000505555500500000000000000000000000000000000
50555566677666666667666666555005505555888778888888878888885550055050005505055555555050505550500500000000000000000000000000000000
50555556776666666676666665555055505555587788888888788888855550555055555055055555555500505550005500000000000000000000000000000000
00550055766666666766666655550050005500557888888887888888555500500055005050055055055000505550005000000000000000000000000000000000
00505005555555555555555555550000005050055555555555555555555500000050500555555555555550500550000000000000000000000000000000000000
00000008800000000000000880000000000000088000000000000008800000000000000000000008888880000000000000008888888800000000000000000000
00000080080000000000008008000000000000800800000000000080080000000000000000000888888880000000000000888888888888800000000000000000
00000800008000000000080000800000000008000080000000000808808000000000000000000888880088000000000088880000000000880000000000000000
00000800008000000000080000800000000008088080000000000880088000000000000000008888880008000000000088000000000000008000000000000000
00008000000800000000800000080000000080800808000000008080080800000000000000008888800008000000000880000000000000088000000000000000
00008008800800000000800000080000000080800808000000008080080800000000000000008888800008000000000800000000000000088000000000000000
00080080080080000008000880008000000808000080800000080808808080000000000000008888800008000000000800000000000000088000000000000000
00080080080080000008008008008000000808088080800000080808808080000000000000088888800008800000000800000000000000088000000000000000
00800808008008000080088008800800008008088080080000800808808008000000000000088888880008800000008800000000000000088000000000000000
00800808008008000080080880800800008008088080080000800808808008000000000000088888880088800000008800000000000000088000000000000000
00800808008008000080088008800800008008088080080000800808808008000000000000088888888888000000008000000000000000088000000000000000
08000080080000800800008008000080080008088080008008000808808000800000000000088888888888800000008000000000000000088000000000000000
08000080080000800800000880000080080008000080008008000808808000800000000000088888888888800000008800000000000000088000000000000000
80000008800000088000000000000008800000800800000880000080080000080000000000088888888888880000008800000000000000088000000000000000
80000000000000088000000000000008800000800800000880000080080000080000000000088888888880080000008800000000000000088000000000000000
88888888888888888888888888888888888888888888888888888888888888880000000000088888888888000000000880000000000000880000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000088888888888800000000888800000008008880000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000888888888888880000000888888888888888000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000888888888888880000000008888888888880000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000008888888888800080000000008888888888888000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000008888888888888000000008888888888888800880000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000008888888888888800000008888888888088888000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000088888888888888000000088880888880808888888000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000088888888888888880000088888888888088888888800000000000000
00000000000000000000000000000000000000000000000000000000000000000000000008888888888800800008080888800888888888008880000000000000
00000000000000000000000000000000000000000000000000000000000000000000000088888888888000000008888888008888888888808888000000000000
00000000000000000000000000000000000000000000000000000000000000000000000008888888888800000008888888088888888888888880800000000000
00000000000000000000000000000000000000000000000000000000000000000000000008888888888888000880808880080888888888888888000000000000
00000000000000000000000000000000000000000000000000000000000000000000000008888888888888880888888888888888888888888008880000000000
00000000000000000000000000000000000000000000000000000000000000000000000088888888888888888088888888888880888888888808800000000000
00000000000000000000000000000000000000000000000000000000000000000000000008888888888888800888888888888888888888888800888800000000
00000000000000000000000000000000000000000000000000000000000000000000000088888888888888888888888888888888888888888888888000000000
__label__
00000000000000000000000000077077700770777070700000077077700000777070707770000077707770777077700770777000000000000000000000000000
00000000000000000000000000700007007070707070700000707070000000070070707000000077700700707070707070707000000000000000000000000000
00000000000000000000000000777007007070770077700000707077000000070077707700000070700700770077007070770000000000000000000000000000
00000000000000000000000000007007007070707000700000707070000000070070707000000070700700707070707070707000000000000000000000000000
00000000000000000000000000770007007700707077700000770070000000070070707770000070707770707070707700707000000000000000000000000000
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
00000000000000000000000000000000000000000000000000055500005055555500005500555500000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055555000555550000005550500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000050000555500555000000555550550005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055000555555555555555555550055555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055055555555555555555555555555555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055555556657666566656666665555555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005555566656665566656666656555055000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000505566765666666566665566655055000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000505657666666666666666666655005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005505675666666666666666666655005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005005766666666666666666666655500000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000005666666666666666666666755500000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005555666666666666666666667755555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000505666666666666666666677655555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000005666666666666666666776650055000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005555666666666666666667766650055000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005055666666666666666677666650055000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000005666666666666666776666650055000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000005666666666666667766666655005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055666666666666677666666655005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055666666666688876666666655505000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000055666666666888886666666755500000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005055666666668f1f1f6666667655555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005055666666668fffff6666676655555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005055666666661111116666766655555000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000555566666667f1111f6667666655555000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055555666666776cccc66676666655505000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055555666667766c66c66766666655005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000050555566677666666667666666555005000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000050555556776666666676666665555055000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000550055766666666766666655550050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000505005555555555555555555550000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000777077707770077007700000070077700700000077700770000077707000777070700000000000000000000000000000
00000000000000000000000000000000707070707000700070000000700000707000000007007070000070707000707070700000000000000000000000000000
00000000000000000000000000000000777077007700777077700000000007000000000007007070000077707000777077700000000000000000000000000000
00000000000000000000000000000000700070707000007000700000000070000000000007007070000070007000707000700000000000000000000000000000
00000000000000000000000000000000700070707770770077000000000077700000000007007700000070007770707077700000000000000000000000000000
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
77007770707077707000077077707770770000007770707000007770700077707770077000007770077077707770000000000000000000000000000000000000
70707000707070007000707070707000707000007070707000007000700007007070700000007770707007007000000000000000000000000000000000000000
70707700707077007000707077707700707000007700777000007700700007007770777000007070707007007700000000000000000000000000000000000000
70707000777070007000707070007000707000007070007000007000700007007070007000007070707007007000000000000000000000000000000000000000
77707770070077707770770070007770777000007770777000007770777077707070770000007070770007007770000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77707770077077707770770000007770707000007770707077707700000070707770777077707770000000000000000000000000000000000000000000000000
07007000700007007000707000007070707000007070707070707070000070707000700070007000000000000000000000000000000000000000000000000000
07007700777007007700707000007700777000007700777077707070000077007700770077007700000000000000000000000000000000000000000000000000
07007000007007007000707000007070007000007070007070707070000070707000700070007000000000000000000000000000000000000000000000000000
07007770770007007770777000007770777000007070777070707070000070707770777070007770000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77707770770077700000777007707770000077007770777070707770077077707770777000007770777077007770000077707770777000000000000000000000
77707070707070000000700070707070000070707070707070700700707070707000707000000070707007007070000007007070777000000000000000000000
70707770707077000000770070707700000070707770770077000700707077007700770000007770707007007770000007007770707000000000000000000000
70707070707070000000700070707070000070707070707070700700707070707000707000007000707007007070000007007070707000000000000000000000
70707070777077700000700077007070000077707070707070700700770077707770707000007770777077707770000077007070707000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000770070000007770077007700000077077707070770077700770077000007770777077007770000000000000000000000000000000000000000000000000
70007000007000007070707070000000700007007070707007007070700000000070707007007070000000000000000000000000000000000000000000000000
70007000007000007700707070000000777007007070707007007070777000007770707007007770000000000000000000000000000000000000000000000000
70007000007000007070707070000000007007007070707007007070007000007000707007007070000000000000000000000000000000000000000000000000
07000770070000007070770007700000770007000770777077707700770000007770777077707770000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707700000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700700000070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700700000070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700700000070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07007770070077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
002000202361032610126102861019610346101361007610246102f610116103861020610056103e6101b61033610206100d6102c610116103661023610166103b610186102a6100d61035610036103361019610
001400001307013060130501304013030130201301013010300703006030050300403003030020300103001026070260602605026040260302602026010260101d0701d0601d0501d0401d0301d0201d0101d010
00140000130701306013050130401303013020130101301030070300603005030040300303002030010300100e0700e0600e0500e0400e0300e0200e0100e0101d0701d0601d0501d0401d0301d0201d0101d010
00140000130701306013050130401303013020130101301030070300603005030040300303002030010300103e0703e0603e0503e0403e0303e0203e0103e0101d0701d0601d0501d0401d0301d0201d0101d010
001400001307013060130501304013030130201301013010300703006030050300403003030020300103001032070320603205032040320303202032010320101d0701d0601d0501d0401d0301d0201d0101d010
003000201531015310183101b3201e33022330013602a33030330333303434001360223401d330193301632013320103101031014310193201d3202033001360233302a3302f340323400136028330223201a320
003c0018210002171020720207201f7201f7201e7301e7301d7301d7301c7401c7401b7401b7401a7501a75019750197501876018760177601776016770167701570015700157001570015700157000000000000
003c00181577015770147601476013760137601275012750117501175010740107400f7400f7400e7300e7300d7300d7300c7200c7200b7200b7200a7100a0000900009000000000000000000000000000000000
00010004366703d6702a7703f67031600292003a60031600000000100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000070100702008020090200a0200b0200d0200e0300f0301003011030120301303014030150401504017040190401a0401c0401e04020040220502505027050290502c0602f06034060370603b0703d070
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344
00 02424344
00 03424344
02 04424344
03 00424344
03 0f060744
03 05474344
03 08484344

