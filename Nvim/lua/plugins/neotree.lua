return	{ 
	
	"nvim-neo-tree/neo-tree.nvim", 	
	branch = "v3.x",

        
	dependencies = {
        
	"nvim-lua/plenary.nvim",
	"nvim-tree/nvim-web-devicons",
	"MunifTanjim/nui.nvim",
	
	},


	config = function()
	    require('neo-tree').setup({
		window = {
   	  	position = "left", -- Set the position of Neotree to the top
        	height = 20,      -- Define the height of the Neotree window
    		
			},
    	    default_component_configs = {
        

		icon = {

-- 			folder_closed = "+",
--		        folder_open = "-",
--			folder_empty = f07b

            },


	},   
        
    })

end


}
