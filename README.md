### Edits for Aedificium
[Lua](https://lua.org) plugin for [Cuberite](https://cuberite.org) which provides large-scale block edits and figure drawing.
<br>
Based off the [enginehub/worldedit](https://github.com/EngineHub/WorldEdit) and the [tvpt/voxelsniper](https://github.com/TVPT/VoxelSniper) plugins, using code from the [cuberite/worldedit](https://github.com/cuberite/WorldEdit) plugin by [Mathias](https://github.com/mathiascode).

### Features
1. Works with the [worldeditcui](https://www.spigotmc.org/resources/worldedit-cui.25524) visualization plugin for Forge and LiteLoader.
2. Properly runs calculations in a container, evading problems with complex functions.
3. W/E API-compliant craftscripts and schematic formats.

### Visitor-level commands
By default server configuration, these commands are granted to visitors.
| Usage | Permission(s) | Description |
| ------- | ---------- | ----------- |
| `/ascend` | `edits.navigation.ascend` | Ascends you upward. |
| `/biomes` | `edits.biomes` | Lists configured biomes. |
| `/cui` | `edits.cui` | Completes the visualizer handshake. |
| `/descend` | `edits.navigation.descend` | Descends you downward. |
| `/formats` | `edits.schematic.list` | Lists supported schematic formats. |
| `/schematics` | `edits.schematic.list` | Lists operable schematics. |
| `/thru` | `edits.navigation.thru` | Takes you through walls and levels. |

### Architect-level commands
By default server configuration, these commands are granted to architects.
| Usage | Permission(s) | Description |
| ------- | ---------- | ----------- |
| `//addleaves` | `edits.region.addleaves` | Adds leaves to log blocks. |
| `//brush <cylinder [...] \| sphere [...]>` | `edits.brush` | Brushes shapes onto a target. |
| `//chunk` | `edits.selection.chunk` | Selects the chunk you're in. |
| `//count <block>` | `edits.selection.count` | Counts the amount of blocks in a region. |
| `//contract` | `edits.selection.contract` | Contracts the region. |
| `//copy` | `edits.clipboard.copy` | Copies the region to your clipboard. |
| `//cut` | `edits.clipboard.cut` | Cuts the selection to your clipboard. |
| `//cylinder <block> <radius>[,<radius>] [height]` | `edits.generation.cylinder` | Generates a cylinder. |
| `//deselect (or) //desel` | `edits.selection.deselect` | Deselects the current region. |
| `//distr` | `edits.selection.distr` | Inspects your region's block distribution. |
| `//drain <radius>` | `edits.drain` | Drains all the water around you by a radius. |
| `//ellipsoid [-h] <block>` | `edits.region.ellipsoid` | Generates an ellipsoid at your region. |
| `//expand <amount>` | `edits.selection.expand` | Expands the region. |
| `//extinguish <radius>` | `edits.extinguish` | Extinguishes fire around you by a radius. |
| `//faces <block>` | `edits.region.faces` | Builds the wall faces of a region. |
| `//fillr <block> <radius> [depth] [allowup]` | `edits.fill.recursive` | Recursively fills a hole. |
| `//fill <block> <radius> <depth>` | `edits.fill` | Fills a hole. |
| `//generate [flags] <block> <formula>` | `edits.generation.shape` | Generates a formulaic shape. |
| `//green <radius>` | `edits.green` | Greens any nearby dirt with grass. |
| `//getbiome` | `edits.biome.info` | Gets the biome makeup of a region. |
| `//hcylinder <block> <radius>[,<radius>] [height]` | `edits.selection.cylinder` | Generates a hollow cylinder. |
| `//hpos1 (or) //hpos2` | `edits.selection.pos` | Sets the first and second position at your crosshair. |
| `//hpyramid <block> <size>[,<size>,<size>]` | `edits.generation.pyramid` | Generates a hollow pyramid. |
| `//hsphere <block> <radius>[,<radius>,<radius>]` | `edits.generation.hsphere` | Generates a hollow sphere. |
| `//leafdecay` | `edits.region.leafdecay` | Withers away leaves in a region. |
| `//loadsel <name>` | `edits.selection.loadselection` | Loads a selection that has been saved. |
| `//mask [block]` | `edits.brush.options.mask` | Sets a restrictive brush mask. |
| `//mirror <xy \| xz \| yx \| yz \| zx \| zy>` | `edits.region.mirror` | Mirrors a region on a specified plane. |
| `//paste` | `edits.clipboard.paste` | Pastes the contents of your clipboard. |
| `//pickaxe` | `edits.superpickaxe` | Toggles the super pickaxe. |
| `//pos1 (or) //pos2` | `edits.selection.pos` | Sets the first and second position at your location. |
| `//pumpkins` | `edits.generation.pumpkins` | Adds pumpkins to the surface. |
| `//pyramid <block> <size>[,<size>,<size>]` | `edits.generation.pyramid` | Generates a solid pyramid. |
| `//redo` | `edits.history.redo` | Redoes the last undone action. |
| `//replace <src block> <dst block>` | `edits.region.replace` | Replaces the blocks in a region. |
| `//replacenear <radius> <src block> <dst block>` | `edits.region.replacenear` | Replaces the blocks around you by a radius. |
| `//rotate [90 \| 180 \| 270 \| -90 \| -180 \| -270]` | `edits.clipboard.rotate` | Rotates the contents of your clipboard. |
| `//savesel` | `edits.selection.saveselection` | Saves the current selection. |
| `//schem <load [...] \| save [...]>` | `edits.schematic` `edits.schematic.load` `edits.schematic.save` | Saves selections between schematic and clipboard. |
| `//set <block>` | `edits.region.set` | Sets the blocks in a region. |
| `//setbiome [-p] <biome>` | `edits.biome.set` | Sets the biome of a region. |
| `//shift <amount>` | `edits.selection.size` | Moves the area of a region. |
| `//shrink` | `edits.selection.shrink` | Shrinks a region to exclude air-only layers. |
| `//size` | `edits.selection.size` | Gets the size of a region. |
| `//snow <radius>` | `edits.snow` | Places snow on blocks which can frost. |
| `//sphere <block> <radius>[,<radius>,<radius>]` | `edits.generation.sphere` | Generates a solid sphere. |
| `//stack <amount>` | `edits.region.stack` | Duplicates a region directionally. |
| `//thaw <radius>` | `edits.thaw` | Thaws the snow around you by a radius. |
| `//undo` | `edits.history.undo` | Undoes the last action. |
| `//up <height>` | `edits.navigation.up` | Takes you upward by a distance. |
| `//vmirror` | `edits.region.vmirror` | Mirrors a region vertically. |
| `//walls <block>` | `edits.region.walls` | Builds the four walls of a region. |
| `//wand` | `edits.wand` | Gets the wand for you. |
| `//wandwork` | `edits.wand.toggle` | Changes if the edit wand works. |

### Moderator-level commands
By default server configuration, these commands are granted to moderators.
| Usage | Permission(s) | Description |
| ------- | ---------- | ----------- |
| `/execute <script>` | `edits.scripting.execute` | Executes a craftscript. |