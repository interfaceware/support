-- This module has utility functions required for the building of the 
-- SAML request. 

local urlcode       = require('ifw.urlcode')
local templates     = require('requestPyTemplates')
local store         = require('ifw.store2')
local globalConfigs = require('SAMLconfig')

local reqgen = {}

-- This function stores the ID of the request so that the response can be traced back to it
local function storeId(ID) 
   local requestStore = store.connect(globalConfigs.requestStoreName)
   requestStore:put(ID,true)
end

-- This function creates a python file (see templates) to deflate & b64-encode the request
local function createPython(rqst) 
   local fl = io.open(globalConfigs.pyScrLocation..'compress.py','w')
   local wr = [[saml = """]]..rqst..'"""\n\n'..templates.reqPyScript
   fl:write(wr)
   fl:close()
end

-- This function creates a request using the template in 'templates' and populates it
function reqgen.reqCreate() 
   
   -- (1) Parse the template
   local rqst = xml.parse{data = templates.reqTemplate} 
   
   -- (2) Populate the SAML request with the correct information
   local uuid = '_'..util.guid(152) 
   rqst["samlp:AuthnRequest"].ID                          = uuid
   rqst["samlp:AuthnRequest"].IssueInstant                = os.ts.gmdate('%Y-%m-%dT%XZ')
   rqst["samlp:AuthnRequest"].Destination                 = globalConfigs.idpURL
   rqst["samlp:AuthnRequest"].AssertionConsumerServiceURL = globalConfigs.ACS_URL
   rqst["samlp:AuthnRequest"]["saml:Issuer"]:setInner(globalConfigs.AUDIENCE)
   
   -- (3) Store the ID so that it can be traced once response is received
   if not iguana.isTest() then
      storeId(uuid)  
   end
   
   return tostring(rqst)
end

-- This function runs the Python script and returns the deflated,b64-encoded,url-encoded request
function reqgen.reqPrepPython(rqst) 
   
   -- (1) Create the python script to generate the deflated,b64-encoded,url-encoded request
   createPython(rqst)
   
   -- (2) Execute the python script 
   local cmd = globalConfigs.pythonLocation..' "'..globalConfigs.pyScrLocation..'compress.py"'
   local outp = io.popen(cmd)
   local bs64enc = outp:read('*a')
   outp:close()
   
   -- (3) URL encode the request
   if bs64enc ~= '' then
      local urlenc = {}
      urlenc[1] = bs64enc
      local rqstComp = urlcode.encodeTable(urlenc):sub(3)
      return rqstComp 
   else
      error('Could not create SAML request!')
   end
   
end

return reqgen
