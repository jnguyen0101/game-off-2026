"""Author the static town scene and an overview from the same layout data."""
from pathlib import Path
import base64, struct, random, re, json
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/kenmi'
TARGET = ROOT / 'scenes/levels/town.tscn'
old = TARGET.read_text(encoding='utf-8')
# Keep the player's customized house sprite, colliders, and entrance setup.
home_start = old.index('[node name="PlayerHouse"')
next_sibling = re.search(r'\n\[node name="[^"]+" (?:type="[^"]+" )?parent="World"(?: |\])', old[home_start + 1:])
home = old[home_start:home_start + 1 + next_sibling.start()] if next_sibling else old[home_start:]
home = home.replace('position = Vector2(146, 57)', 'position = Vector2(208, 200)')
shape_ids = re.findall(r'shape = SubResource\("([^\"]+)"\)', home)
kept_shapes = []
for sid in shape_ids:
 m=re.search(r'\[sub_resource type="[^"]+" id="'+re.escape(sid)+r'"\]\n.*?(?=\n\[|\Z)',old,re.S)
 if m: kept_shapes.append(m.group().strip())
parts=['[gd_scene format=3 uid="uid://c7y5la0exxt55"]']
def add(text): parts.append(text)
textures={
'grass':'tiles/Grass/Grass_1_Middle.png','road':'tiles/Cobble_Road/Cobble_Road_1.png',
'water':'tiles/Water/Water_Middle.png','home':'buildings/Buildings/Houses/Wood/House_3_Wood_Base_Red.png',
'inn':'buildings/Buildings/Houses/Wood/House_5_Wood_Base_Red.png',
'guild':'buildings/Buildings/Houses/Wood/House_5_Wood_Base_Blue.png',
'palace':'buildings/Buildings/Houses/Limestone/House_5_Limestone_Base_Blue.png',
'wing':'buildings/Buildings/Houses/Stone/House_1_Stone_Base_Black.png',
'cottage':'buildings/Buildings/Houses/Wood/House_1_Wood_Base_Red.png',
'stalls':'buildings/Buildings/Unique_Buildings/Stalls/Market_Stalls.png',
'fountain':'outdoor_decor/Fountain.png','tree':'trees/Big_Oak_Tree.png',
'wall':'outdoor_decor/Stone_Fence_Big.png','lamp':'outdoor_decor/Lanter_Posts.png',
'flowers':'outdoor_decor/Flowers.png','bridge':'tiles/Bridge/Bridge_Stone_Horizontal.png',
'signs':'outdoor_decor/Signs.png'}
for name,path in textures.items():
 rid='4_0x67q' if name=='home' else name
 add(f'[ext_resource type="Texture2D" path="res://assets/kenmi/{path}" id="{rid}"]')
for kind,path,name in [('Script','scripts/levels/town.gd','town'),('Script','scripts/objects/home_entrance.gd','home_entrance'),('PackedScene','scenes/player/player.tscn','player'),('PackedScene','scenes/objects/dialogue_interactable.tscn','dialogue'),('FontFile','assets/fonts/PixeloidSans-lxa3y.ttf','font')]:
 add(f'[ext_resource type="{kind}" path="res://{path}" id="{name}"]')
for s in kept_shapes:add(s)
for name,size in [('Building',(176,40)),('SmallBuilding',(64,40)),('Stall',(40,20)),('Tree',(14,10)),('Wall',(16,12)),('NorthBoundary',(976,16)),('SideBoundary',(16,768)),('Water',(64,768))]:
 add(f'[sub_resource type="RectangleShape2D" id="{name}Shape"]\nsize = Vector2{size}')
add('[sub_resource type="CircleShape2D" id="FountainShape"]\nradius = 12.0')
atlases={}
def atlas(name,tex,rect):
 rid='4_0x67q' if tex=='home' else tex
 add(f'[sub_resource type="AtlasTexture" id="{name}"]\natlas = ExtResource("{rid}")\nregion = Rect2{tuple(rect)}')
 atlases[name]=(tex,rect)
for n,tex,r in [('Oak','tree',(64,0,64,80)),('Fountain','fountain',(0,32,32,48)),('Wall','wall',(16,0,16,16)),('Post','wall',(0,0,16,16)),('Lamp','lamp',(0,0,16,48)),('Bridge','bridge',(0,0,128,48)),('Flowers','flowers',(0,0,16,16)),('Sign','signs',(0,0,32,16))]:atlas(n,tex,r)
for i in range(4):atlas(f'Stall{i}','stalls',(i*48,0,48,48))
for name in ['grass','road','water']:
 cells='\n'.join(f'{x}:{y}/0 = 0' for y in range(3 if name=='road' else 1) for x in range(3 if name=='road' else 1))
 add(f'[sub_resource type="TileSetAtlasSource" id="{name}Atlas"]\ntexture = ExtResource("{name}")\n{cells}')
add('[sub_resource type="TileSet" id="GroundTiles"]\nsources/0 = SubResource("grassAtlas")\nsources/1 = SubResource("roadAtlas")\nsources/2 = SubResource("waterAtlas")')
add('[node name="Town" type="Node2D"]\nscript = ExtResource("town")')
# Editor paintable tile layers. The data header is Godot's native format-0 header.
def tilelayer(name,cells,source,z,terrain=False):
 data=bytearray(struct.pack('<H',0))
 for x,y in sorted(cells):
  ax=0 if (x-1,y) not in cells else 2 if (x+1,y) not in cells else 1
  ay=0 if (x,y-1) not in cells else 2 if (x,y+1) not in cells else 1
  data.extend(struct.pack('<hhhhhh',x,y,source,ax if terrain else 0,ay if terrain else 0,0))
 add(f'[node name="{name}" type="TileMapLayer" parent="."]\nz_index = {z}\ntile_set = SubResource("GroundTiles")\ntile_map_data = PackedByteArray("{base64.b64encode(data).decode()}")')
grass={(x,y) for y in range(48) for x in range(60)}
water={(x,y) for y in range(48) for x in range(4)}
roads=set()
def road(x1,y1,x2,y2):roads.update((x,y) for x in range(x1,x2) for y in range(y1,y2))
# Uneven plaza and gently bending streets follow the terrain rather than a grid.
import math
for y in range(21, 40):
 for x in range(21, 44):
  edge = 1.0 + 0.045 * math.sin(x * 1.9 + y * 0.7)
  if ((x-31.5)/10.0)**2 + ((y-30.5)/8.0)**2 < edge: roads.add((x,y))
def lane(points, width=1):
 for (ax,ay),(bx,by) in zip(points,points[1:]):
  steps=max(abs(bx-ax),abs(by-ay))
  for step in range(steps+1):
   t=step/max(1,steps)
   cx,cy=round(ax+(bx-ax)*t),round(ay+(by-ay)*t)
   for dy in range(-width,width+1):
    for dx in range(-width,width+1): roads.add((cx+dx,cy+dy))
lane([(14,13),(14,17),(17,19),(22,20),(26,24)],1)
lane([(13,27),(19,28),(25,28),(31,27),(39,26),(49,25)],1)
lane([(32,14),(31,18),(32,23),(32,30),(31,36),(33,41),(32,47)],1)
lane([(12,37),(17,36),(22,38),(30,36)],1)
lane([(33,37),(40,39),(49,38)],1)
lane([(3,28),(7,28),(11,27),(14,27)],1)
lane([(49,25),(50,31),(48,35),(49,38)],1)
# The civic courtyard is smaller and offset from the avenue.
road(22,12,43,16)
tilelayer('Grass',grass,0,-4)
tilelayer('River',water,2,-3)
tilelayer('Paths',roads,1,-2,True)
add('[node name="World" type="Node2D" parent="."]\ny_sort_enabled = true')
# Collect a simple software overview with the same textures, crop regions, and sorting origins.
preview=Image.new('RGBA',(960,768))
images={n:Image.open(ASSETS/p).convert('RGBA') for n,p in textures.items()}
for y in range(48):
 for x in range(60):preview.alpha_composite(images['grass'].crop((0,0,16,16)),(x*16,y*16))
for x,y in water:preview.alpha_composite(images['water'].crop((0,0,16,16)),(x*16,y*16))
for x,y in roads:
 ax=0 if (x-1,y) not in roads else 2 if (x+1,y) not in roads else 1
 ay=0 if (x,y-1) not in roads else 2 if (x,y+1) not in roads else 1
 preview.alpha_composite(images['road'].crop((ax*16,ay*16,ax*16+16,ay*16+16)),(x*16,y*16))
draws=[]
def sprite(name,parent,pos,tex,offset=(0,0),crop=False):
 path=parent+'/'+name if parent!='.' else name
 ref=f'SubResource("{tex}")' if crop else f'ExtResource("{tex}")'
 add(f'[node name="{name}" type="Sprite2D" parent="{parent}"]\nposition = Vector2{pos}\ntexture = {ref}')
 return path
def preview_sprite(tex,x,y,ox=0,oy=0,sort=None):
 if tex in atlases:
  key,r=atlases[tex];im=images[key].crop((r[0],r[1],r[0]+r[2],r[1]+r[3]))
 else:im=images[tex]
 draws.append((y if sort is None else sort,im,(int(x+ox-im.width/2),int(y+oy-im.height/2))))
def body(name,x,y,tex,shape,offset=(0,-44),shapeoffset=(0,-16),crop=False):
 add(f'[node name="{name}" type="StaticBody2D" parent="World"]\nposition = Vector2({x}, {y})')
 sprite('Sprite2D','World/'+name,offset,tex,crop=crop)
 add(f'[node name="CollisionShape2D" type="CollisionShape2D" parent="World/{name}"]\nposition = Vector2{shapeoffset}\nshape = SubResource("{shape}Shape")')
 preview_sprite(tex,x,y,*offset)
 return 'World/'+name
def dialogue(name,parent,pos,prompt,lines):
 add(f'[node name="{name}" parent="{parent}" instance=ExtResource("dialogue")]\nposition = Vector2{pos}\ninteraction_prompt = {json.dumps(prompt)}\nlines = Array[String]([{", ".join(json.dumps(v) for v in lines)}])')
add(home.strip())
preview_sprite('home',208,200,0,-21)
# Large destinations follow the reference's compass positions.
body('Inn',218,402,'inn','Building')
dialogue('Entrance','World/Inn',(16,4),'Read inn sign',["The Wayward Pick Inn. A warm meal and a bed for travelers."])
body('Guild',790,382,'guild','Building')
dialogue('Entrance','World/Guild',(16,4),'Read guild sign',["Thieves' Guild. Applicants report to the guild head.","This is the place. I should have another look at my resume before going in."])
body('Palace',500,192,'palace','Building')
body('PalaceWestWing',380,208,'wing','SmallBuilding')
body('PalaceEastWing',632,178,'wing','SmallBuilding')
dialogue('Entrance','World/Palace',(16,8),'Read palace notice',["Royal grounds. Entry by appointment only."])
for name,x,y in [('WestCottage',180,586),('SouthwestCottage',356,650),('EastCottage',804,594),('SoutheastCottage',706,680)]:body(name,x,y,'cottage','SmallBuilding')
for i,(x,y) in enumerate([(404,430),(614,450),(432,568),(596,578)]):body(f'MarketStall{i+1}',x,y,f'Stall{i}','Stall',(0,-20),(0,-6),True)
body('MarketFountain',504,500,'Fountain','Fountain',(0,-16),(0,-4),True)
# Signs and lampposts are physical world objects rather than floating place labels.
for name,x,y,title in [('InnSign',286,430,'Inn'),('GuildSign',862,412,'Guild'),('MarketSign',492,380,'Market'),('PalaceSign',566,250,'Palace')]:
 p=body(name,x,y,'Sign','Tree',(0,-10),(0,0),True)
 add(f'[node name="Title" type="Label" parent="{p}"]\noffset_left = -30.0\noffset_top = -25.0\noffset_right = 30.0\ntext = "{title}"\nhorizontal_alignment = 1\ntheme_override_fonts/font = ExtResource("font")\ntheme_override_font_sizes/font_size = 8\ntheme_override_colors/font_shadow_color = Color(0, 0, 0, 1)\ntheme_override_constants/shadow_offset_x = 1\ntheme_override_constants/shadow_offset_y = 1')
for i,(x,y) in enumerate([(342,428),(680,470),(472,628),(570,650),(458,288),(572,322),(173,295),(858,534)]):body(f'StreetLamp{i+1}',x,y,'Lamp','Tree',(0,-20),(0,0),True)
# The town opens into the surrounding landscape; no enclosing stone walls.
dialogue('GateNotice','World',(512,716),'Read gate notice',["South Gate. The road beyond leads out of town."])
# River banks are blocked, with a clear crossing beside the inn.
add('[node name="RiverBanks" type="StaticBody2D" parent="."]')
for name,cy,h in [('North',212,424),('South',620,296)]:
 sid='River'+name
 # Separate shapes allow the bridge opening at y416..512.
 # Kept outside World so river collision does not participate in Y sorting.
 # Shape resources must precede scene nodes, so use polygons here.
 add(f'[node name="{name}" type="CollisionPolygon2D" parent="RiverBanks"]\npolygon = PackedVector2Array(0, {cy-h//2}, 64, {cy-h//2}, 64, {cy+h//2}, 0, {cy+h//2})')
sprite('Bridge','.',(48,448),'Bridge',crop=True)
preview_sprite('Bridge',48,448,sort=-100)
# Controlled tree placement keeps trunks off roads and major walking spaces.
rng=random.Random(2026)
positions=[]
# Irregular woodland clusters with varied spacing, rather than rows of trees.
for x in [78,134,196,257,318,389,451,524,593,661,738,802,868,941]:
 positions.append((x+rng.randint(-12,12),rng.randint(18,58)))
for x in [86,151,216,282,358,417,612,679,749,826,893,945]:
 positions.append((x+rng.randint(-14,14),rng.randint(733,778)))
for y in [112,173,251,313,381,503,558,642,704]:
 positions.append((rng.randint(70,100),y+rng.randint(-12,12)))
 positions.append((rng.randint(922,956),y+rng.randint(-17,17)))
positions += [(290,165),(314,234),(166,268),(724,190),(794,230),(860,288),(330,389),(711,335),(162,504),(284,524),(337,593),(742,530),(866,576),(627,660),(252,674),(305,152),(875,210),(142,670)]
for i,(x,y) in enumerate(positions):
 if y == 760 and 464 <= x <= 560: continue
 x+=rng.choice([-4,0,4])
 body(f'Oak{i:02}',x,y,'Oak','Tree',(0,-32),(0,0),True)
for i,(x,y) in enumerate([(176,224),(192,224),(256,224),(288,416),(272,416),(752,416),(832,416),(368,256),(384,256),(656,256),(672,256),(192,608),(224,608),(768,624),(800,624)]):
 sprite(f'Flowers{i}','.',(x,y),'Flowers',crop=True)
 preview_sprite('Flowers',x,y,sort=-101)
add('[node name="Player" parent="World" instance=ExtResource("player")]\nposition = Vector2(224, 229)')
add('[node name="Camera2D" parent="World/Player" index="2"]\nlimit_left = 0\nlimit_top = 0\nlimit_right = 960\nlimit_bottom = 768')
add('[node name="Boundaries" type="StaticBody2D" parent="."]')
for name,shape,pos in [('Top','NorthBoundary',(480,-8)),('Bottom','NorthBoundary',(480,776)),('Left','SideBoundary',(-8,384)),('Right','SideBoundary',(968,384))]:add(f'[node name="{name}" type="CollisionShape2D" parent="Boundaries"]\nposition = Vector2{pos}\nshape = SubResource("{shape}Shape")')
add('[node name="TownHUD" type="CanvasLayer" parent="."]\nlayer = 3')
add('[node name="Objective" type="Label" parent="TownHUD"]\nanchor_right = 1.0\noffset_top = 6.0\noffset_right = -8.0\nhorizontal_alignment = 2\ntheme_override_fonts/font = ExtResource("font")\ntheme_override_font_sizes/font_size = 8\ntheme_override_colors/font_color = Color(1, 0.85, 0.45, 1)\ntheme_override_colors/font_shadow_color = Color(0, 0, 0, 1)\ntheme_override_constants/shadow_offset_x = 1\ntheme_override_constants/shadow_offset_y = 1\nmouse_filter = 2')
TARGET.write_text('\n\n'.join(parts)+'\n',encoding='utf-8')
for _,im,pos in sorted(draws,key=lambda d:d[0]):preview.alpha_composite(im,pos)
out=ROOT/'design/town_layout_overview.png'
out.parent.mkdir(exist_ok=True)
preview.convert('RGB').save(out)
print(f'Built {TARGET.name}; preview: {out}')
