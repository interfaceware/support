-- This channel plays the second part of SP-initiated SAML SSO.
-- It is responsible for validating and processing the response / assertion 
-- coming back from the identity provider. 
-- It will log-in and redirect the user in the case of successful login at the IdP
-- Tested with Azure AD SAML SSO for non-gallery applications:
-- https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/configure-single-sign-on-non-gallery-applications

-- To use, please read the accompanying guide on Basecamp

local isSAMLValid  = require('isSAMLValid')
local SAMLhelp     = require('responseHelp')
local grantAccess  = require('grantAccess')

function main(Data)
   
   -- (1) Extract the response
   local respStatus,responseStr,responseTree = pcall(SAMLhelp.getResponse,Data)
   if respStatus == false then
      net.http.respond{body='Could not extract response!'}
      return
   end

   -- (2) Verify the response
   local Status,valid,logMsg,assertion = pcall(isSAMLValid,responseStr,responseTree)
   
   -- (3) If successful validation, get all non-empty attributes and grant access
   local attributes = {}

   if (Status and valid) == true then 
      attributes = SAMLhelp.getAttributes(assertion) 
      grantAccess(attributes)                    
   else
      if Status == false then                    
         logMsg = 'Problem processing response.' 
      end
      net.http.respond{body='Unable to authenticate user.'..logMsg}
   end

end





