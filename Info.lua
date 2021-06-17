-- info.lua
-- Implements the g_PluginInfo standard plugin description.

g_PluginInfo = 
{
	Name = "Edits",
	Version = "1",
	Date = "2020-11-27",
	SourceLocation = "https://github.com/aedifi/edits",
	Description = [[Efficient large-scale block edits.]],
	
	Commands =
	{
		["//addleaves"] = 
		{
			Permission = "edits.region.addleaves",
			Handler = HandleAddLeavesCommand,
			HelpString = "Adds leaves to log blocks.",
		},
		["//brush"] =
		{
			Permission = "edits.brush",
			Handler = HandleBrushMainCommand,
			HelpString = "Brushes shapes onto a target.",
			Subcommands =
			{
				sphere =
				{
					HelpString = "Brushes spheres onto a target.",
					Permission = "edits.brush.sphere",
					Handler = HandleSphereBrush,
				},
				cylinder =
				{
					HelpString = "Brushes cylinders onto a target.",
					Permission = "edits.brush.cylinder",
					Handler = HandleCylinderBrush,
				},
			},
		},
		["//chunk"] =
		{
			Permission = "edits.selection.chunk",
			Handler = HandleChunkCommand,
			HelpString = "Selects the chunk you're in.",
        },
		["//count"] =
		{
			Permission = "edits.selection.count",
			Handler = HandleCountCommand,
			HelpString = "Counts the amount of blocks in a region.",
		},
		["//contract"] =
		{
			Permission = "edits.selection.contract",
			Handler = HandleExpandContractCommand,
			HelpString = "Contracts the region.",
        },
		["//copy"] =
		{
			Permission = "edits.clipboard.copy",
			Handler = HandleCopyCommand,
			HelpString = "Copies the region to your clipboard.",
        },
		["//cut"] =
		{
			Permission = "edits.clipboard.cut",
			Handler = HandleCutCommand,
			HelpString = "Cuts the selection to your clipboard.",
        },
		["//cylinder"] =
		{
			Permission = "edits.generation.cylinder",
			Handler = HandleCylinderCommand,
			HelpString = "Generates a cylinder.",
        },
		["//deselect"] =
		{
			Alias = "//desel",
			Permission = "edits.selection.deselect",
			Handler = HandleDeselectCommand,
			HelpString = "Deselects the current region.",
        },
		["//distr"] =
		{
			Permission = "edits.selection.distr",
			Handler = HandleDistrCommand,
			HelpString = "Inspects your region's block distribution.",
        },
		["//drain"] =
		{
			Permission = "edits.drain",
			Handler = HandleDrainCommand,
			HelpString = "Drains all the water around you by a radius.",
        },
		["//ellipsoid"] =
		{
			Permission = "edits.region.ellipsoid",
			Handler = HandleEllipsoidCommand,
			HelpString = "Generates an ellipsoid at your region.",
        },
		["//expand"] =
		{
			Permission = "edits.selection.expand",
			Handler = HandleExpandContractCommand,
			HelpString = "Expands the region.",
        },
		["//extinguish"] =
		{
			Permission = "edits.extinguish",
			Handler = HandleExtinguishCommand,
			HelpString = "Extinguishes fire around you by a radius.",
        },
		["//faces"] =
		{
			Alias = "//outline",
			Permission = "edits.region.faces",
			Handler = HandleFacesCommand,
			HelpString = "Builds the wall faces of a region.",
        },
		["//fillr"] =
		{
			Permission = "edits.fill.recursive",
			Handler = HandleFillrCommand,
			HelpString = "Recursively fills a hole.",
        },
		["//fill"] =
		{
			Permission = "edits.fill",
			Handler = HandleFillCommand,
			HelpString = "Fills a hole.",
        },
		["//generate"] =
		{
			Alias = "//gen",
			Permission = "edits.generation.shape",
			Handler = HandleGenerationShapeCommand,
			HelpString = "Generates a formulaic shape.",
        },
		["//green"] =
		{
			Permission = "edits.green",
			Handler = HandleGreenCommand,
			HelpString = "Greens any nearby dirt with grass.",
		},
		["//getbiome"] =
		{
			Permission = "edits.biome.info",
			Handler = HandleReadBiomeCommand,
			HelpString = "Gets the biome makeup of a region.",
		},
		["//hcylinder"] =
		{
			Permission = "edits.selection.cylinder",
			Handler = HandleCylinderCommand,
			HelpString = "Generates a hollow cylinder.",
        },
		["//hpos1"] =
		{
			Permission = "edits.selection.pos",
			Handler = HandleHPosCommand,
			HelpString = "Sets the first position at your crosshair.",
        },
		["//hpos2"] =
		{
			Permission = "edits.selection.pos",
			Handler = HandleHPosCommand,
			HelpString = "Sets the second position at your crosshair.",
        },
		["//hpyramid"] =
		{
			Permission = "edits.generation.pyramid",
			Handler = HandlePyramidCommand,
			HelpString = "Generates a hollow pyramid.",
        },
		["//hsphere"] =
		{
			Permission = "edits.generation.hsphere",
			Handler = HandleSphereCommand,
			HelpString = "Generates a hollow sphere.",
        },
		["//leafdecay"] =
		{
			Permission = "edits.region.leafdecay",
			Handler = HandleLeafDecayCommand,
			HelpString = "Withers away leaves in a region.",
		},
		["//loadsel"] =
		{
			Permission = "edits.selection.loadselection",
			Handler = HandleSaveLoadSelectionCommand,
			HelpString = "Loads a selection that has been saved.",
		},
		["//mask"] =
		{
			Permission = "edits.brush.options.mask",
			Handler = HandleMaskCommand,
            HelpString = "Sets a restrictive brush mask.",
        },
		["//mirror"] =
		{
			Permission = "edits.region.mirror",
			Handler = HandleMirrorCommand,
            HelpString = "Mirrors a region on a specified plane.",
        },
		["//paste"] =
		{
			Permission = "edits.clipboard.paste",
			Handler = HandlePasteCommand,
			HelpString = "Pastes the contents of your clipboard.",
		},
		["//pickaxe"] = 
		{
			Permission = "edits.superpickaxe",
			Handler = HandlePickaxeCommand,
			HelpString = "Toggles the super pickaxe.",
		},
		["//pos1"] =
		{
			Permission = "edits.selection.pos",
			Handler = HandlePosCommand,
			HelpString = "Sets the first position at your location.",
        },
		["//pos2"] =
		{
			Permission = "edits.selection.pos",
			Handler = HandlePosCommand,
			HelpString = "Sets the second position at your location.",
		},
		["//pumpkins"] =
		{
			Permission = "edits.generation.pumpkins",
			Handler = HandlePumpkinsCommand,
			HelpString = "Adds pumpkins to the surface.",
		},
		["//pyramid"] =
		{
			Permission = "edits.generation.pyramid",
			Handler = HandlePyramidCommand,
			HelpString = "Generates a solid pyramid.",
        },
		["//redo"] =
		{
			Permission = "edits.history.redo",
			Handler = HandleRedoCommand,
			HelpString = "Redoes the last undone action.",
        },
		["//replace"] =
		{
			Permission = "edits.region.replace",
			Handler = HandleReplaceCommand,
			HelpString = "Replaces the blocks in a region.",
		},
		["//replacenear"] =
		{
			Permission = "edits.region.replacenear",
			Handler = HandleReplaceNearCommand,
			HelpString = "Replaces the blocks around you by a radius.",
        },
		["//rotate"] =
		{
			Permission = "edits.clipboard.rotate",
			Handler = HandleRotateCommand,
			HelpString = "Rotates the contents of your clipboard.",
        },
		["//savesel"] =
		{
			Permission = "edits.selection.saveselection",
			Handler = HandleSaveLoadSelectionCommand,
			HelpString = "Saves the current selection.",
		},
		["//schem"] =
		{
			Permission = "edits.schematic",
			Handler = HandleSchematicMainCommand,
			HelpString = "Saves selections between schematic and clipboard.",
			Subcommands =
			{
				import =
				{
					HelpString = "Imports a schematic to the server.",
					Permission = "edits.schematic.import",
					Handler = HandleSchematicImportCommand,
				},
				load =
				{
					HelpString = "Saves a schematic to your clipboard.",
					Permission = "edits.schematic.load",
					Handler = HandleSchematicLoadCommand,
				},
				save =
				{
					HelpString = "Saves your clipboard as a schematic.",
					Permission = "edits.schematic.save",
					Handler = HandleSchematicSaveCommand,
				},
			},
		},
		["//set"] =
		{
			Permission = "edits.region.set",
			Handler = HandleSetCommand,
			HelpString = "Sets the blocks in a region.",
		},
		["//setbiome"] =
		{
			Permission = "edits.biome.set",
			Handler = HandleSetBiomeCommand,
			HelpString = "Sets the biome of a region.",
        },
		["//shift"] =
		{
			Permission = "edits.selection.size",
			Handler = HandleShiftCommand,
			HelpString = "Moves the area of a region.",
        },
		["//shrink"] =
		{
			Permission = "edits.selection.shrink",
			Handler = HandleShrinkCommand,
			HelpString = "Shrinks a region to exclude air-only layers.",
		},
		["//size"] =
		{
			Permission = "edits.selection.size",
			Handler = HandleSizeCommand,
			HelpString = "Gets the size of a region.",
		},
		["//snow"] =
		{
			Permission = "edits.snow",
			Handler = HandleSnowCommand,
			HelpString = "Places snow on blocks which can frost.",
		},
		["//sphere"] =
		{
			Permission = "edits.generation.sphere",
			Handler = HandleSphereCommand,
			HelpString = "Generates a solid sphere.",
		},
		["//stack"] =
		{
			Permission = "edits.region.stack",
			Handler = HandleStackCommand,
			HelpString = "Duplicates a region directionally.",
		},
		["//thaw"] =
		{
			Permission = "edits.thaw",
			Handler = HandleThawCommand,
			HelpString = "Thaws the snow around you by a radius.",
		},
		["//undo"] =
		{
			Permission = "edits.history.undo",
			Handler = HandleUndoCommand,
			HelpString = "Undoes the last action.",
		},
		["//unbind"] =
		{
			Permission = "edits.unbind",
			Handler = HandleUnbindCommand,
			HelpString = "Strips your selected item of any bindings.",
		},
		["//up"] =
		{
			Permission = "edits.navigation.up",
			Handler = HandleUpCommand,
			HelpString = "Takes you upward by a distance.",
		},
		["//vmirror"] =
		{
			Permission = "edits.region.vmirror",
			Handler = HandleVMirrorCommand,
			HelpString = "Mirrors a region vertically.",
		},
		["//walls"] =
		{
			Permission = "edits.region.walls",
			Handler = HandleWallsCommand,
			HelpString = "Builds the four walls of a region.",
		},
		["//wand"] =
		{
			Permission = "edits.wand",
			Handler = HandleWandCommand,
			HelpString = "Gets the wand for you.",
		},
		["//wandwork"] =
		{
			Permission = "edits.wand.toggle",
			Handler = HandleToggleEditWandCommand,
			HelpString = "Changes if the edit wand works.",
        },
		-- Commands that aren't double-slashed.
		["/ascend"] =
		{
			Permission = "edits.navigation.ascend",
			Handler = HandleAscendCommand,
			HelpString = "Ascends you upward.",
		},
		["/biomes"] =
		{
			Permission = "edits.biomes",
			Handler = HandleBiomeListCommand,
			HelpString = "Lists configured biomes.",
		},
		["/cui"] =
		{
			Permission = "edits.cui",
			Handler = HandleWorldEditCuiCommand,
			HelpString = "Completes the visualizer handshake.",
		},
		["/descend"] =
		{
			Permission = "edits.navigation.descend",
			Handler = HandleDescendCommand,
			HelpString = "Descends you downward.",
		},
		["/execute"] =
		{
			Permission = "edits.scripting.execute",
			Handler = HandleCraftScriptCommand,
			HelpString = "Executes a craftscript.",
        },
		["/formats"] =
		{
			Permission = "edits.schematic.list",
			Handler = HandleSchematicFormatsCommand,
			HelpString = "Lists supported schematic formats.",
		},
		["/schematics"] =
		{
			Permission = "edits.schematic.list",
			Handler = HandleSchematicListCommand,
			HelpString = "Lists operable schematics.",
		},
		["/thru"] =
		{
			Permission = "edits.navigation.thru",
			Handler = HandleThruCommand,
			HelpString = "Takes you through walls and levels.",
		},
	}, -- Commands
} -- g_PluginInfo