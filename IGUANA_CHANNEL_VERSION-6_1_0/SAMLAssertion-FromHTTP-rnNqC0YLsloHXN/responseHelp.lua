-- This module contains some useful utility functions for working with SAML

local store2        = require('ifw.store2')
local urlcode       = require('ifw.urlcode')
local globalConfigs = require('SAMLconfig')

local SAMLhelp = {}

-- (DEPRECATED) This function will clear the replay store if the response ID is outdated. 
function SAMLhelp.clearStore() 
   local replayStore = store2.connect(globalConfigs.replayStoreName)
   local storeT = replayStore:info()
   local currTime = os.time()
   for k = 1,storeT:childCount() do -- For each entry in the store
      -- If its maximum validity is earlier than current time, then delete it
      if os.difftime(currTime,dateparse.parse(storeT[k].CValue:nodeValue())) > 0 then
         replayStore:put(storeT[k].CKey:nodeValue(),nil)
      end
   end
end

-- This function extracts and returns all non-empty attributes from the assertion 
function SAMLhelp.getAttributes(xmlResponse) 
   local attributes = {}
   -- Loop through attributes and populate the attributes table with the available (non-nil) attribute values
   for k=1,xmlResponse["Assertion"]["AttributeStatement"]:childCount("Attribute") do
      if xmlResponse["Assertion"]["AttributeStatement"][k]["AttributeValue"] ~= nil then 
         local key = xmlResponse["Assertion"]["AttributeStatement"][k].Name:nodeValue()
         attributes[key] = xmlResponse["Assertion"]["AttributeStatement"]:child("Attribute", k)["AttributeValue"][1]:nodeValue()
      end
   end
   
   return attributes
end

-- Extract the response component of what is received from the IdP
function SAMLhelp.getResponse(Data) 
   local _,ind = Data:find('SAMLResponse')
   local responseStr = filter.base64.dec(urlcode.unescape((Data:sub(ind+2))))
   local responseTree = xml.parse(responseStr)
   return responseStr,responseTree
end

return SAMLhelp