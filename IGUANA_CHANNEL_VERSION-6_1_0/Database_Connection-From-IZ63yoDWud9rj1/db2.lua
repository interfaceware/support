local retry = require "retry"

local db2 = {}
local method = {}

-- Configuration settings for database retry (Default 16 minutes)
local RETRY_COUNT = 100          -- number of times to try reconnecting to database
local RETRY_PAUSE = 10          -- number of seconds between trying to reconnect to database

-- Configuration settings for iguana timeout (Default 38 minutes)
local DB_CONNECT_TIMEOUT = 10  -- number of seconds before the DB connection times out (ODBC default = 300 seconds)
local IGUANA_TIMEOUT = RETRY_COUNT*(RETRY_PAUSE + DB_CONNECT_TIMEOUT) + 300

-- Local functions -- START --
local function CopyDBConfigs(T)
   local C = {}
   for K, V in pairs(T) do C[K] = V end
   return C
end

local function Init(Credentials, Conn)
   if not Conn or not Conn:check() then
      if Conn then Conn:close() end -- close stale connection
      iguana.setTimeout(IGUANA_TIMEOUT) -- prevents timing out before completing retries
      Conn = retry.call{func=db.connect, arg1 = Credentials, 
         retry=RETRY_COUNT, pause=RETRY_PAUSE,
         funcname='Init'}
   end
   return Conn
end

local function ReConnect(Self)
   local metaTable = getmetatable(Self)
   metaTable.Conn = Init(metaTable._Config, metaTable.Conn)
   setmetatable(Self, metaTable)
   return metaTable
end
-- Local functions -- END --

-- Connect to database
function db2.connect(T)
   local metaTable = {}
   metaTable.__index = method
   metaTable._Config = CopyDBConfigs(T)
   local connection = {}
   return setmetatable(connection, metaTable)
end

-- Method Functions --START--
function method.query(Self, T)
   local metaTable = ReConnect(Self)
   local Success, Result = pcall(metaTable.Conn.query, metaTable.Conn, T)
   if not Success then error(Result, 2) end
   return Result
end

function method.execute(Self, T)
   local metaTable = ReConnect(Self)
   local Success, Result = pcall(metaTable.Conn.execute, metaTable.Conn, T)
   if not Success then error(Result, 2) end
   return Result
end

function method.quote(Self, T)
   local metaTable = ReConnect(Self)
   local Success, Result = pcall(metaTable.Conn.quote, metaTable.Conn, T)
   if not Success then error(Result, 2) end
   return Result
end

function method.close(Self)
   local metaTable = getmetatable(Self)
   local Conn = metaTable.Conn
   if Conn then 
      local Success, Result = pcall(Conn.close, Conn)
      if not Success then error(Result, 2) end
      return Result
   else 
      return nil
   end
end

function method.merge(Self, T)
   local metaTable = ReConnect(Self)
   local Success, Result = pcall(metaTable.Conn.merge, metaTable.Conn, T)
   if not Success then error(Result, 2) end
   return Result
end
-- Method Functions -- END --

-- Help -- START--
if help then
   ------------------------
   -- db2:connect()
   ------------------------
   help.set{input_function=db2.connect, help_data=help.get(db.connect)}
   
   ------------------------
   -- db2:query()
   ------------------------
   help.set{input_function=method.query, help_data=help.get(db.query)}
   
   ------------------------
   -- db2:execute()
   ------------------------
   help.set{input_function=method.execute, help_data=help.get(db.execute)}
   
   ------------------------
   -- db2:merge()
   ------------------------
   help.set{input_function=method.merge, help_data=help.get(db.merge)}
   
   ------------------------
   -- db2:close()
   ------------------------
   help.set{input_function=method.close, help_data=help.get(db.close)}
   
    ------------------------
   -- db2:quote()
   ------------------------
   local d = [==[{"Parameters":[{"data":{"Desc":"The string to escape <u>string</u>."}}],"Returns":[{"Desc":"An escaped string surrounded by single quotes <u>string</u>."}],"Title":"quote","SummaryLine":"Returns an escaped string surrounded by single quotes.","SeeAlso":[{"Title":"The db_connection module - new database methods","Link":"http://wiki.interfaceware.com/1034.html?v=6.0.0"},{"Title":"The db module - old style database functions","Link":"http://wiki.interfaceware.com/431.html?v=6.0.0"},{"Title":"Mapping To/From Databases","Link":"http://wiki.interfaceware.com/311.html?v=6.0.0"},{"Title":"Understanding Lua OO syntax: what the colon operator means","Link":"http://wiki.interfaceware.com/224.html?v=6.0.0"}],"Usage":"conn:quote(data)","Examples":["<pre>local Sql = 'SELECT * FROM MyTable WHERE Name = '..conn:quote(MyString)</pre>"],"Desc":"Accepts a single string argument, and returns an escaped string surrounded by single quotes. Escaping is database specific, characters are escaped specifically to match each database API."}]==]
	local h = json.parse{data=d}
   help.set{input_function=method.quote, help_data=h}
end
-- Help -- END --

return db2