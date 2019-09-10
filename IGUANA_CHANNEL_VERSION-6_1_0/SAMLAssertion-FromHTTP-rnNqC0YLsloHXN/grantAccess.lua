-- This module is used to grant access to the user
-- This can be access to APIs, iguana resources, or iguana login

-- Below is an implementation of Iguana login that redirects the user
-- to the dashboard depending on their department. Each department 
-- has a single Iguana log in user. Example, if the user is in the 
-- Support department, then they would log in to Iguana as a Support-user. 

local globalConfigs = require('SAMLconfig')
local encr          = require('encrypt.password')

-- You must first encrypt the passwords of all department users in a secure location:
-- encr.save{config=conf.pwDirectory..'<department>', password='<password>', key='KJHASkj233j3d'}

local function loginUser(userInfo)
   
   -- (1) Extract the user department and load the corresponding password
   local user = userInfo.UserDepartment
   local pass = encr.load{config=globalConfigs.pwDirectory..'master',key='KJHASkj233j3d'}
   
   -- (2) Log the user in and obtain the session cookie
   local R,C,H = net.http.post{
      url  = 'https://127.0.0.1:'..globalConfigs.IGUANA_PORT..'/login.html',
      auth = {username = user..'-user', password = pass},
      live = true}    
   local cookie = H["Set-Cookie"]
   
   -- (3) Redirect the user to the Iguana dashboard
   net.http.respond{
      body    = 'Login successful',
      code    = 302,  
      headers = { Location       = globalConfigs.IGUANA_URL..':'..globalConfigs.IGUANA_PORT..'/dashboard.html',
                  ["Set-Cookie"] = cookie} }
   
end

return loginUser