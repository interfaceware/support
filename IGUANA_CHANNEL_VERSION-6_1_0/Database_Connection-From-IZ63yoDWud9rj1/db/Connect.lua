-- $Revision: 1.0 $
-- $Date: 2017-10-19 $

--
-- The Database Connection module
-- Copyright (c) 2011-2017 iNTERFACEWARE Inc. ALL RIGHTS RESERVED
-- iNTERFACEWARE permits you to use, modify, and distribute this file in accordance
-- with the terms of the iNTERFACEWARE license agreement accompanying the software
-- in which it is used.
--

-- include retry function locally - code at end of file
local retry = {} 

local RETRY_COUNT = 5   -- default number of times to try reconnecting to database
local RETRY_PAUSE = 5   -- default number of seconds between trying to reconnect to database
local DB_TIMEOUT  = 300 -- default number of seconds before the DB connection times out
	                     -- NOTE: default for an ODBC connection is 300 seconds (5 minutes)

----- START: local functions -----
local function CopyTable(Table)
   local Copy = {}
   for k, v in pairs(Table) do
      Copy[k] = v
   end
   return Copy
end

local function GetDbCredentials(Credentials)
   local credentials = CopyTable(Credentials)
   -- remove unwanted fields from credentials
   credentials.retry_count  = nil
   credentials.retry_pause  = nil
   credentials.db_timeout   = nil
   credentials.odbc_timeout = nil
   -- change odbc_timeout to timeout to match db.connect param
   credentials.timeout      = credentials.odbc_timeout
   return credentials
end

local function SetScriptTimeout(Credentials)
   local retryCount = Credentials.retry_count
   local retryPause = Credentials.retry_pause
   local dbConnectTimeout = Credentials.db_timeout
   if not retryCount then retryCount = RETRY_COUNT end
   if not retryPause then retryPause = RETRY_PAUSE end
   if not dbTimeout  then dbTimeout  = DB_TIMEOUT end
   -- calculate total time for database retry timeout
   local dbRetryTimeout = retryCount*(retryPause + dbTimeout) + 300
   iguana.setTimeout(dbRetryTimeout) 
end

-- Initialize or reconnect to database
local function Init(Credentials, Conn)  
   if not Conn or not Conn:check() then 
      if Conn and not iguana.isTest() then Conn:close() end -- close stale connection
      SetScriptTimeout(Credentials) -- set IGUANA translator timeout
      local credentials = GetDbCredentials(Credentials)
      Conn = retry.call{func=db.connect, arg1 = credentials, 
         retry=Credentials.retry_count, pause=Credentials.retry_pause,
         funcname='Init'}
   end
   return Conn
end

local function ReConnect(CustomConn)
   -- retry connection and save new connection back to object
   local metaTable = getmetatable(CustomConn)
	metaTable.Conn = Init(metaTable._Config, metaTable.Conn)
   setmetatable(CustomConn, metaTable)
   
   return metaTable
end
----- END: local functions -----


----- START: methods for connection object -----
local Methods = {}

function Methods.query(Self, Sql)
   local metaTable = ReConnect(Self)
  
   local Success, Result = pcall(metaTable.Conn.query, metaTable.Conn, Sql)
   if not Success then
      error(Result, 2) -- bubble error to user code
   end
   return Result
end

function Methods.execute(Self, Sql)
   local metaTable = ReConnect(Self)
   
   local Success, Result = pcall(metaTable.Conn.execute, metaTable.Conn, Sql)
   if not Success then
      error(Result, 2) -- bubble error to user code
   end
   return Result
end

function Methods.quote(Self, String)
   local metaTable = ReConnect(Self)
   
   local Success, Result = pcall(metaTable.Conn.quote, metaTable.Conn, Sql)
   if not Success then
      error(Result, 2) -- bubble error to user code
   end
   return Result
end

function Methods.close(Self)
   -- close connection if it is already open
   local metaTable = getmetatable(Self)
   local conn = metaTable.Conn

   if conn then
      local Success, Result = pcall(conn.close, conn)
      if not Success then
         error(Result, 2) -- bubble error to user code
      end
   end
end

function Methods.merge(Self, String)
   local metaTable = ReConnect(Self)
   
   local Success, Result = pcall(metaTable.Conn.merge, metaTable.Conn, Sql)
   if not Success then
      error(Result, 2) -- bubble error to user code
   end
   return Result
end
----- END: methods for connection object -----


----- Interface = single Connect() function -----
local function Connect(Credentials)
   local metaTable = {}
   metaTable.__index = Methods
   metaTable._Config = Credentials
   local connection = {}
   return setmetatable(connection, metaTable)
end


-- Help for functions
local HelpInfo = [[{
      "SummaryLine": "Returns a database handle..",
      "Returns": [
         {
            "Desc": "A new database connection handle <u>custom database connection object</u>."
         }
      ],
      "Parameters": [         
         {
            "api": {
               "Desc": "set to the database type (e.g. db.MY_SQL or db.SQL_SERVER) <u>integer constant</u>."
            }
         }, 
         {
            "name": {
               "Desc": "database name/address. For db.SQLITE, this is the database file name <u>string</u>."
            }
         }, 
         {
            "user": {
               "Desc": "user name (neither required nor used for db.SQLITE) <u>string</u>."
            }
         }, 
         {
            "password": {
               "Desc": "password (neither required nor used for db.SQLITE) <u>string</u>."
            }
         },
         {
            "live": {
            "Desc": "if true, the statement will be executed in the editor (default = false) <u>boolean</u>.",
            "Opt": true
            }
         },
         {
            "use_unicode": {
            "Desc": "if true, Unicode will be used when communicating with the database (default = false) <u>boolean</u>.",
            "Opt": true
            }
         },
         {
            "odbc_timeout": {
            "Desc": "maximum time in seconds allowed for an ODBC query (default = 300, 0 for infinite) <u>integer</u>.",
            "Opt": true
            }
         },
         {
            "retry_count": {
               "Desc": "number of retries before connection fails (default = 5) <u>integer</u>.",
               "Opt": true
            }
         },
         {
            "retry_pause": {
               "Desc": "number of seconds pause between connection retries (default = 5) <u>integer</u>.",
               "Opt": true
            }
         },
         {
            "db_timeout": {
               "Desc": "number of seconds before the DB Server times out a connection (default = 300) <u>integer</u>.",
               "Opt": true
            }
         },
      ],
      "Title": "Connect",
      "Usage": "Connect{api=<value>, name=<value>, ...}",
      "Examples": [
         "local Conn = Connect{
            api=db.MY_SQL, name='test@localhost',
            user='fred', password='secret'}"
      ],
      "ParameterTable": true,
      "SeeAlso": [
         {
            "Title": "Tools Repository: Database Connection",
            "Link": "http://help.interfaceware.com/v6/database-connection"
         },
         {
            "Title": "Our Database Documentation",
            "Link": "http://help.interfaceware.com/category/building-interfaces/interfaces/database"
         },
         {
            "Title": "The db_connection module - new database methods",
            "Link": "http://wiki.interfaceware.com/1034.html?v=6.0.0"
         },
         {
            "Title": "The db module - old style database functions",
            "Link": "http://wiki.interfaceware.com/431.html?v=6.0.0"
         }
      ],
      "Desc": "Prepares a database connection and returns a <b>custom</b> database connection handle. By default the returned handle is configured to be live and allows database methods to run in the editor.
      <br><br>Connect does not create an actual database connection, as the connection will be created/recreated on demand, by query(), execute(), merge() etc.
      <ul><li>If Connect live = false then database operations do not execute in the editor.</li>
      <li>If live = true (the default) database operations will execute in the editor, based on the method default or specified live setting.</li>
      <li>The odbc_timeout parameter can only be used with ODBC connections (it will cause an error with other connections) -- it is quite useful for testing purposes as a quick way to set a short ODBC timeout.</li>
      <li>The db_timeout parameter is the (estimated) amount of time that your DB Server will take before timing out a connection -- the Connect module uses this to calulate how long the script needs to run to perform the maximum number of retries (instead of timing out before the retries are finished).<br><b>Note:</b> You may need to experiment with db_timeout to ensure the script timeout is long enough to perform the maximum number of retries.</li></ul>
      <b>Note:</b> The default retry values can be configured near the top of Connect.lua module (retry_pause = RETRY_PAUSE, retry_count = RETRY_COUNT)."
   }
]]

help.set{input_function=Connect, help_data=json.parse{data=HelpInfo}}

local HelpInfo = [[{
      "SummaryLine": "Executes an ad hoc SQL statement that can alter the database.",
      "Returns": [
         {
            "Desc": "<b>For queries:</b> the first result set <u>result_set node tree</u>."
         },
         {
            "Desc": "<b>For queries:</b> An array containing all the result sets <u>table</u>."
         }
      ],
      "Parameters": [         
         {
            "sql": {
               "Desc": "a string containing the SQL statement <u>string</u>."
            }
         },
         {
            "live": {
               "Desc": " if true, the statement will be executed in the editor (default = false) <u>boolean</u>.",
               "Opt": true
            }
         },
      ],
      "Title": "execute",
      "Usage": "DbConn:execute(sql)",
      "Examples": [
         "local Connect = require 'db.Connect'<br><br>local DbConn = Connect{api=db.SQL_SERVER, name='test',user='&lt;my user&gt;', password='&lt;secret&gt;',live=true, retry_count=50, retry_pause = 10, db_timeout = 50, timeout=30}<br><br>DbConn:execute('INSERT INTO Patient (FirstName, LastName) VALUES(\"Fred\", \"Smith\")')</pre>",
         "local Connect = require 'db.Connect'<br><br>local DbConn = Connect{api=db.SQL_SERVER, name='test',user='&lt;my user&gt;', password='&lt;secret&gt;',live=true, retry_count=25, retry_pause = 20, db_timeout = 50, timeout=30}<br><br>-- Return an array containing multiple results sets, one for each query<br>-- Note: Some DBs do not support multiple queries in a single \"sql\" string<br><br>local Result = DbConn:execute('SELECT * FROM Patient; SELECT * FROM Kin')",
         "local Connect = require 'db.Connect'<br><br>local DbConn = Connect{api=db.SQL_SERVER, name='test',user='&lt;my user&gt;', password='&lt;secret&gt;',live=true, retry_count=100, retry_pause = 15, db_timeout = 50, timeout=30}<br><br>-- trap the database error thrown by <code>DbConnect.DbExecute</code><br><br>-- try to insert a duplicate key = \"Primary Key Violation\" error<br>local TryDuplicateKey = \"INSERT INTO [dbo].[Patient] (Id,FirstName, LastName) VALUES (1, 'Fred', 'Smith')\"<br><br>local Success, Error = pcall(DbConn:execute, TryDuplicateKey)<br><br>trace(Success)                 -- false in this case<br>trace(Error)                   -- view the pcall Error return as a table<br>local DbError = Error.message  -- copy the DB error message string from Error<br>trace(DbError)                 -- view the DB error message"
      ],
      "ParameterTable": false,
      "SeeAlso": [
         {
            "Title": "Tools Repository: Database Connection",
            "Link": "http://help.interfaceware.com/v6/database-connection"
         },
         {
            "Title": "Our Database Documentation",
            "Link": "http://help.interfaceware.com/category/building-interfaces/interfaces/database"
         },
         {
            "Title": "The db_connection module - new database methods",
            "Link": "http://wiki.interfaceware.com/1034.html?v=6.0.0"
         },
         {
            "Title": "The db module - old style database functions",
            "Link": "http://wiki.interfaceware.com/431.html?v=6.0.0"
         }
      ],
      "Desc": "Executes an ad hoc SQL statement that can alter the database.<br><br>DbConn:execute() is designed to enhance the behaviour of the builtin conn:execute{} function. It automatically reconnects when a database connection is lost, it also improves performance by using a persistent database connection (that stays open as long as the channel is running).<br><br><b>Note:</b> The number of retries and the delay are set when using Connect to create the connection (retry_count and retry_pause parameters), if no values are set the default values (RETRY_COUNT and RETRY_PAUSE) near the top of the connect.lua module are used as defaults."
   }
]]

help.set{input_function=Methods.execute, help_data=json.parse{data=HelpInfo}}

local HelpInfo = [[{
      "SummaryLine": "Executes an ad hoc SQL query against a database.",
      "Returns": [
         {
            "Desc": "The first result set <u>result_set node tree</u>."
         },
         {
            "Desc": "An array containing all the result sets <u>table</u>."
         }
      ],
      "Parameters": [
         {
            "sql": {
               "Desc": "a string containing the SQL select statement\n"
            }
         },
         {
            "live": {
               "Desc": " if true, the statement will be executed in the editor (default = true) <u>boolean</u>.",
               "Opt": true
            }
         },
      ],
      "Title": "query",
      "Usage": "DbConn:query(sql)",
      "Examples": [
         "local Connect = require 'db.Connect'<br><br>local DbConn = Connect{api=db.SQL_SERVER, name='test',user='&lt;my user&gt;', password='&lt;secret&gt;',live=true, retry_count=50, retry_pause = 10, db_timeout = 50, timeout=30}<br><br>local Result = DbConn:query('SELECT * FROM Patient WHERE Flag = \"F\"')",
         "local Connect = require 'db.Connect'<br><br>local DbConn = Connect{api=db.SQL_SERVER, name='test',user='&lt;my user&gt;', password='&lt;secret&gt;',live=true, retry_count=50, retry_pause = 10, db_timeout = 50, timeout=30}<br><br>-- Return an array containing multiple results sets, one for each query<br>-- Note: Some DBs do not support multiple queries in a single \"sql\" string<br><br>local Result = DbConn:query('SELECT * FROM Patient; SELECT * FROM Kin')",
         "local Connect = require 'db.Connect'<br><br>local DbConn = Connect{api=db.SQL_SERVER, name='test',user='&lt;my user&gt;', password='&lt;secret&gt;',live=true, retry_count=50, retry_pause = 10, db_timeout = 50, timeout=30}<br><br>-- trap the database error thrown by <code>DbConn:query</code><br><br>local Success, Error = pcall(DbConn:query, 'Select * from Not_a_table')<br><br>trace(Success)                 -- false in this case<br>trace(Error)                   -- view the pcall Error return as a table<br>local DbError = Error.message  -- copy the DB error message string from Error<br>trace(DbError)                 -- view the DB error message"
      ],
      "ParameterTable": false,
      "SeeAlso": [
         {
            "Title": "Tools Repository: Database Connection",
            "Link": "http://help.interfaceware.com/v6/database-connection"
         },
         {
            "Title": "Our Database Documentation",
            "Link": "http://help.interfaceware.com/category/building-interfaces/interfaces/database"
         },
         {
            "Title": "The db_connection module - new database methods",
            "Link": "http://wiki.interfaceware.com/1034.html?v=6.0.0"
         },
         {
            "Title": "The db module - old style database functions",
            "Link": "http://wiki.interfaceware.com/431.html?v=6.0.0"
         }
      ],
      "Desc": "Executes an ad hoc SQL query against a database.<br><br>Insert or update statements are not allowed (for these, use the <code>DbConn:execute</code> method).<br><br>DbConn:query() is designed to enhance the behaviour of the builtin conn:query{} function. It automatically reconnects when a database connection is lost, it also improves performance by using a persistent database connection (that stays open as long as the channel is running).<br><br><b>Note:</b> The number of retries and the delay are set when using Connect to create the connection (retry_count and retry_pause parameters), if no values are set the default values (RETRY_COUNT and RETRY_PAUSE) near the top of the connect.lua module are used as defaults."
   }
]]


help.set{input_function=Methods.query, help_data=json.parse{data=HelpInfo}}

local HelpInfo = [[{
      "Examples": [
         "<pre>local Sql = 'SELECT * FROM MyTable WHERE Name = '..DbCconnect.DbQuote(MyString)</pre>"
      ],
      "Usage": "DbConn:quote(data)",
      "Title": "quote",
      "SummaryLine": "Returns an escaped string surrounded by single quotes.",
      "Desc": "Accepts a single string argument, and returns an escaped string surrounded by single quotes. Escaping is database specific, characters are escaped specifically to match each database API.<br><br>The quote function also automatically reconnects to ensure that it is equally as reliable as other database functions (like query and execute).",      
      "SeeAlso": [
         {
            "Title": "Tools Repository: Database Connection",
            "Link": "http://help.interfaceware.com/v6/database-connection"
         },
         {
            "Title": "Our Database Documentation",
            "Link": "http://help.interfaceware.com/category/building-interfaces/interfaces/database"
         },
         {
            "Title": "The db_connection module - new database methods",
            "Link": "http://wiki.interfaceware.com/1034.html?v=6.0.0"
         },
         {
            "Title": "The db module - old style database functions",
            "Link": "http://wiki.interfaceware.com/431.html?v=6.0.0"
         }
      ],
      "Returns": [
         {
            "Desc": "An escaped string surrounded by single quotes <u>string</u>."
         }
      ],
      "Parameters": [
         {
            "data": {
               "Desc": "The string to escape <u>string</u>."
            }
         }
      ]
   }
]]
	
help.set{input_function=Methods.quote, help_data=json.parse{data=HelpInfo}}


------------------------------------------
----- retry funtion included locally -----
------------------------------------------

-- customize the (generic) error messages used by retry() if desired
local RETRIES_FAILED_MESSAGE = 'Retries completed - was unable to recover from connection error.'
local FATAL_ERROR_MESSAGE    = 'Stopping channel - fatal error, function returned false. Function name: '
local RECOVERED_MESSAGE      = 'Recovered from error, connection is now working. Function name: '

local function sleep(S)
   if not iguana.isTest() then
      util.sleep(S*1000)
   end
end

-- hard-coded to allow "argN" params (e.g., arg1, arg2,...argN)
local function checkParam(T, List, Usage)
   if type(T) ~= 'table' then
      error(Usage,3)
   end
   for k,v in pairs(List) do
      for w,x in pairs(T) do
         if w:find('arg') then
            if w == 'arg' then error('Unknown parameter "'..w..'"', 3) end
         else
            if not List[w] then error('Unknown parameter "'..w..'"', 3) end
         end
      end
   end
end

-- hard-coded for "argN" params (e.g., arg1, arg2,...argN)
local function getArgs(P)
   local args = {}
   for k,v in pairs(P) do
      if k:find('arg')==1 then
         args[tonumber(k:sub(4))] = P[k]
      end
   end
   return args
end

-- This function will call with a retry sequence - default is 100 times with a pause of 10 seconds between retries
function retry.call(P)--F, A, RetryCount, Delay)
   checkParam(P, {func=0, retry=0, pause=0, funcname=0, errorfunc=0}, Usage)
   if type(P.func) ~= 'function' then
      error('The "func" argument is not a function type, or it is missing (nil).', 2)
   end 
     
   local RetryCount = P.retry or 100
   local Delay = P.pause or 10
   local Fname = P.funcname or 'not specified'
   local Func = P.func
   local ErrorFunc = P.errorfunc
   local Info = 'Will retry '..RetryCount..' times with pause of '..Delay..' seconds.'
   local Success, ErrMsgOrReturnCode
   local Args = getArgs(P)

   if iguana.isTest() then RetryCount = 2 end 
   for i =1, RetryCount do
      local R = {pcall(Func, unpack(Args))}
      Success = R[1]
      ErrMsgOrReturnCode = R[2]
      if ErrorFunc then
         Success = ErrorFunc(unpack(R))
      end
      if Success then
         -- Function call did not throw an error 
         -- but we still have to check for function returning false
         if ErrMsgOrReturnCode == false then
            error(FATAL_ERROR_MESSAGE..Fname..'()')
         end
         if (i > 1) then
            iguana.setChannelStatus{color='green', text=RECOVERED_MESSAGE..Fname..'()'}
            iguana.logInfo(RECOVERED_MESSAGE..Fname..'()')
         end
         -- add Info message as the last of (potentially) multiple returns
         R[#R+1] = Info
         return unpack(R,2)
      else
         if iguana.isTest() then 
            -- TEST ONLY: add Info message as the last of (potentially) multiple returns
            R[#R+1] = Info
            return "SIMULATING RETRY: "..tostring(unpack(R,2)) -- test return "PRETENDING TO RETRY"
         else -- LIVE
            -- keep retrying if Success ~= true
            local E = 'Error executing operation. Retrying ('
            ..i..' of '..RetryCount..')...\n'..tostring(ErrMsgOrReturnCode)
            iguana.setChannelStatus{color='yellow',
               text=E}
            sleep(Delay)
            iguana.logInfo(E)
         end 
      end
   end
   
   -- stop channel if retries are unsuccessful
   iguana.setChannelStatus{text=RETRIES_FAILED_MESSAGE}
   error(RETRIES_FAILED_MESSAGE..' Function: '..Fname..'(). Stopping channel.\n'..tostring(ErrMsgOrReturnCode)) 
end

return Connect