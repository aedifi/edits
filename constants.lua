-- constants.lua
-- Global variables used by the plugin.

-- Some blocks won't render with a meta value of zero.
g_DefaultMetas = {
	[E_BLOCK_CHEST]              = 2,
	[E_BLOCK_ENDER_CHEST]        = 2,
	[E_BLOCK_FURNACE]            = 2,
	[E_BLOCK_LADDER]             = 2,
	[E_BLOCK_LIT_FURNACE]        = 2,
	[E_BLOCK_NETHER_PORTAL]      = 1,
	[E_BLOCK_TORCH]              = 1,
	[E_BLOCK_TRAPPED_CHEST]      = 2,
	[E_BLOCK_REDSTONE_TORCH_ON]  = 1,
	[E_BLOCK_REDSTONE_TORCH_OFF] = 1,
	[E_BLOCK_WALLSIGN]           = 2,
	[E_BLOCK_WALL_BANNER]        = 2
}

E_DIRECTION_NORTH1 = 0
E_DIRECTION_NORTH2 = 4
E_DIRECTION_EAST = 1
E_DIRECTION_SOUTH = 2
E_DIRECTION_WEST = 3
