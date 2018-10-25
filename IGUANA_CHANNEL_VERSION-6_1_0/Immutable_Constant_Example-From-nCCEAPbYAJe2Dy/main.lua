-- get contant configurations
local configs = require 'ConstantConfigs'

-- The main function is the first function called from Iguana.
function main()
   trace(configs.LEFT)
   configs.otherstuff.abc = "Hello"
   trace(configs.otherstuff.abc)
   --configs.LEFT = 4 --throw error
end