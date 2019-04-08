-- 1) Go to password.configs.lua share module to add/update configurations starting at line10 of configs.lua
local configUtil = require 'password.util'
local configs = configUtil.configs

-- 2) Initialize configuration value ONCE:
--  2.1) Edit 'username' and 'password' values starting line10 of main.lua
--  2.2) Then uncomment the lines and run script
--  2.3) Then re comment the lines out
--  2.4) Then the 'password' value has been updated
--configUtil.save(configs.APP_USERNAME, 'UserName')
--configUtil.save(configs.APP_PASSWORD, 'Password')

function main() 
   -- 3) Verify saved configuration value
   local userName = configUtil.load(configs.APP_USERNAME)
   local userPass = configUtil.load(configs.APP_PASSWORD)
end