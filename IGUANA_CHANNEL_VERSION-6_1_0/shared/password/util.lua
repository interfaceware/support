local encryptConfig = require 'encrypt.password'
local configs = require 'password.configs'

-- Define password files path (e.g. IGUANA/configs/)
local SEPARATOR = package.config:sub(1,1) == '\\' and '\\' or '/'
local PATH = configs.folderName..SEPARATOR

local util = {}

function util.save(config, password)
   -- create configuration directory if it does not exist.
   if not os.fs.access(PATH) then os.fs.mkdir(PATH) end
   return encryptConfig.save{config=PATH..config, password=password, key=configs.key}
end

local SaveHelp=[[{
"Returns": [],
"Title": "configUtil.save",
"Parameters": [
{ "config": {"Desc": "Name of the configuration file to save to <u>string</u>."}},     
{ "password": { "Desc": "The password to save in the file <u>string</u>."}}],
"ParameterTable": false,
"Usage": "configUtil.save(config, password)",
"Examples": [
"--Save the config file - but do not leave this line in the script
configUtil.save('acmeapp','my password')"],
"Desc": "This function encrypts and saves a password to the specified file located in the configuration directory of Iguana."
}]]

help.set{input_function=util.save, help_data=json.parse{data=SaveHelp}}


function util.load(config)
   return encryptConfig.load{config=PATH..config,key=configs.key}
end

local LoadHelp=[[{
"Returns": [{"Desc": "The decrypted password <u>string</u>."}],
"Title": "configUtil.load",
"Parameters": [{ "config": {"Desc": "Name of the configuration file to load <u>string</u>."}}],
"ParameterTable": false,
"Usage": "configUtil.load(config)",
"Examples": [
"--Save the config file - but do not leave this line in the script
configUtil.save('acmeapp', 'my password')<br>
-- Load the password previously saved to the configuration file
local Password = configUtil.load('acmeapp')"
],
"Desc": "This function loads an encrypted password from the specified file in the configuration directory of Iguana that was saved using the configUtil.save{} function"
}]]

help.set{input_function=util.load, help_data=json.parse{data=LoadHelp}}

util.configs = configs.fileNames

return util