-- This channel plays the first part of SP-initiated SAML SSO.
-- It is responsible for generating the request and redirecting the user to the IdP 
-- login page. It creates the xml request, deflates it, base64-encodes it, and 
-- appends it to the IdP URL

-- Tested with Azure AD SAML SSO for non-gallery applications:
-- https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/configure-single-sign-on-non-gallery-applications

-- To use, please read the accompanying guide on help documentation site

local reqgen      = require('requestHelp')
local globConfigs = require('SAMLconfig')

function main(Data)
   
   -- (1) Generate the xml request
   local request = reqgen.reqCreate()
 
   -- (2) Deflate, base64 encode, and url encode it 
   local Status,reqReady = pcall(reqgen.reqPrepPython,request)
  
   -- (3) If successful in creating request
   if Status == true then
      -- (3a) Create the URL
      local locat = globConfigs.IDP_URL..reqReady
     
      -- (3b) Redirect user to IdP
      net.http.respond{
         body    = reqReady,
         code    = 302,  
         headers = {Location = globConfigs.IDP_URL..'?SAMLRequest='..reqReady}}
   else 
      iguana.logWarning("Could not generate SAML request!")
      net.http.respond{body="Problem generating SAML request."}
   end
end
