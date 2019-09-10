-- This module contains functions that validate the response coming back from the Identity
-- Provider

-- The list of checks can be found in function isValid() at the bottom of the file. 
-- The checks are a subset of those found in the OneLogin Python SAML 2.0 
-- library: https://github.com/onelogin/python-saml
-- Relevant file in the Python library:
-- https://github.com/onelogin/python-saml/blob/master/src/onelogin/saml2/response.py


local store2        = require('ifw.store2')
local dateparse     = require('ifw.dateparse')
local globalConfigs = require('SAMLconfig')
local respPyScript  = require('responsePyScript')
local SAMLhelp      = require('responseHelp')

-- Function extracts Id from SAML Response
local function getId(xmlResponse) 
   local Id = xmlResponse["samlp:Response"].ID:nodeValue()
   return Id
end

-- Function checks the response statuscode
local function checkStatus(response,logMsg)
   
   -- Extract the status
   local status = response["samlp:Response"]["samlp:Status"]["samlp:StatusCode"].Value:nodeValue():split(':')
   local respStatus = status[#status]
   local valid = true
   
   if respStatus ~= 'Success' then -- Verify that its a 'Success'
      logMsg = logMsg..'<br/>Fail: Status of Response is not Success, is '..respStatus..'.'
      valid = false
   else
      logMsg = logMsg..'<br/>Pass: Status of Response is Success.'
   end
   
   return valid,logMsg
end

-- Function checks NotOnOrAfter and NotBefore conditions
local function validateTimeStamps(xmlAssertion,logMsg)
   
   local valid = true
   
   -- Obtain the notBefore,NotOnOrAfter, and current times
   local notBefore = xmlAssertion["Assertion"]["Conditions"].NotBefore:nodeValue():split('.')[1] 
   local notAfter = xmlAssertion["Assertion"]["Conditions"].NotOnOrAfter:nodeValue():split('.')[1]
   local currTime = os.time() 
  
   -- Checking the NotBefore condition:
   local timeDif = os.difftime(currTime,dateparse.parse(notBefore))
   if timeDif < 0 then 
      logMsg = logMsg..'<br/>Fail: NotBefore condition NOT met!'
      status = false
   else 
      logMsg = logMsg..'<br/>Pass: NotBefore condition met.'
      trace(logMsg)
   end
   
   -- Checking NotOnOrAfter condition:
   local timeDif = os.difftime(dateparse.parse(notAfter),currTime)
   if timeDif <= 0 then 
      logMsg = logMsg..'<br/>Fail: NotOnOrAfter condition NOT met!'
      valid = false
   else
      logMsg = logMsg..'<br/>Pass: NotOnOrAfter condition met.'
   end 
   
   return valid,logMsg
end

-- Function creates python script to verify signature
local function createPyScript(xmlResponse)
   local responseStr = [[responseStr = """]]..xmlResponse..[["""]]
   local flContents = responseStr..'\n\n'..respPyScript
   trace(respPyScript)
   
   -- open, write, and close python script file
   local pythonFlNme = globalConfigs.pyScrLocation..'checkSignature.py'
   local pythonFH = io.open(pythonFlNme,'w')
   pythonFH:write(flContents)
   pythonFH:close()
   return pythonFlNme
end

-- Function calls python script to verify SAML signature
local function checkSign(xmlResponse,logMsg) 
   
   local valid = true
   
   -- (1) Create the python script
   local pythonFlNme = createPyScript(xmlResponse) -- create the py script
 
   -- (2) Run the script and read the results
   local cmd = globalConfigs.pythonLocation..' "'..pythonFlNme..'"'
   local outp = io.popen(cmd)              
   local signedAssertion = outp:read('*a') 
   outp:close()
   
   -- (3) Check that the assertion was actually validated. If it is, the assertion 
   -- will be returned
   if not signedAssertion:sub(1,16):find('Assertion') then 
      valid = false
      logMsg = logMsg..'<br/>Fail: Could not verify signature. Error: '..signedAssertion
   else
      logMsg = logMsg..'<br/>Pass: Signature verified!'
   end 
   
   -- Return the assignedAssertion to follow 'See what is signed' xmldsig best practice
   return valid,logMsg,xml.parse{data=signedAssertion} 
end

-- Function checks that response and assertions contain the required SAML components
local function isComplete(responseTree,logMsg)
  
   local valid = true
   
   --------- These may need to be modified during the initial testing --------------
   local respMustContain = {'Version','ID','IssueInstant','xmlns:samlp','Destination',
                        'InResponseTo','Issuer','samlp:Status','Assertion'}
   
   local assertMustContain = {'Version','ID','IssueInstant','xmlns','Issuer',
   'Signature','Subject','Conditions','AuthnStatement','AttributeStatement'}
  -----------------------------------------------------------------------------------
   
   -- Check the completion of the response
   for k = 1,#respMustContain do 
      if (responseTree["samlp:Response"][respMustContain[k]] == nil) then 
         valid = false
         logMsg = logMsg..'<br/>Fail: Response missing '..respMustContain[k]..'.'
         trace(logMsg)
         return valid,logMsg
      end
   end
   
   -- Check the completion of the assertion
   for k = 1,#assertMustContain do 
      trace(responseTree["samlp:Response"].Assertion)
      trace(responseTree["samlp:Response"].Assertion[assertMustContain[k]] == nil)
      if (responseTree["samlp:Response"].Assertion[assertMustContain[k]] == nil) then 
         valid = false
         trace(responseTree["samlp:Response"].Assertion[assertMustContain[k]])
         logMsg = logMsg..'<br/>Fail: Assertion missing '..assertMustContain[k]..'.'
         return valid,logMsg
      end
   end
   
   return valid,logMsg
end

-- Function verfies that the request is a response to a request from us
local function matchRequest(xmlResponse,logMsg) 
   
   local valid = true
   
   -- Connects to the request store name (which is populated in SAMLUser channel)
   local requestStore = store2.connect(globalConfigs.requestStoreName)
   local inRespId = xmlResponse["samlp:Response"].InResponseTo:nodeValue()
   local matchId = requestStore:get(inRespId)
   
   -- Check if the response ID is in response to a request that we made
   if matchId ~= 'true' then 
      logMsg = logMsg..[[<br/>Fail: Does not correspond to a request from us
                               OR replay attack!]]
      valid = false
   else 
      logMsg = logMsg..[[<br/>Pass: Response matches request.
                         <br/>Pass: No replay. This is the first time.]]
      requestStore:put(inRespId,nil)
   end
   
   return valid, logMsg
end

-- Check for replay attacks by Id of the Response (DEPRECATED)
local function checkReplay(xmlResponse,logMsg) 
   SAMLhelp.clearStore() -- Clears all old (no longer time-valid) entries, as validateTimeStamp will invalidate them
   local valid = true
   local respId = getId(xmlResponse)
   local replayStore = store2.connect(globalConfigs.replayStoreName)
   local validUntil = replayStore:get(respId)
   local maxTime = xmlResponse["samlp:Response"]["saml:Assertion"]["saml:Conditions"].NotOnOrAfter:nodeValue()
   
   if validUntil == nil then 
   -- ie. not in replay store. This is the first time we see it, so no replay.
      logMsg = logMsg..'<br/>Pass: No replay. This is the first time.'
      replayStore:put(respId,maxTime) -- Now add the ID and maximum valid time
   else 
      logMsg = logMsg..'<br/>Fail: Replay Detected!'
      valid = false
   end
   
   return valid,logMsg
end

-- Checks that the destination of the response is correct. Should match ACS_URL in SAMLconfigs
local function checkDestination(responseTree,logMsg) 
   local valid = true
   if responseTree["samlp:Response"].Destination:nodeValue() ~= globalConfigs.ACS_URL then 
      valid = false 
      logMsg = logMsg..'<br/>Fail: Destination is wrong.'
   else 
      logMsg = logMsg..'<br/>Pass: Destination is correct.'
   end
   return valid,logMsg
end

-- Checks that the response issuer is correct.
local function checkRespIssuer(responseTree,logMsg) 
   local valid = true  
   local respIssuer = responseTree["samlp:Response"].Issuer:nodeText()
   if respIssuer ~= globalConfigs.ISSUER then 
      valid = false 
      logMsg = logMsg..'<br/>Fail: Response Issuer is wrong.'
   else 
      logMsg = logMsg..'<br/>Pass: Response Issuer is correct.'
   end
   return valid,logMsg
end

-- Checks that the assertion issuer is correct
local function checkAssertIssuer(assertTree,logMsg) 
   local valid = true 
   local assertIssuer = assertTree["Assertion"]["Issuer"]:nodeText()
   if assertIssuer ~= globalConfigs.ISSUER then 
      valid = false 
      logMsg = logMsg..'<br/>Fail: Assertion Issuer is wrong.'
   else 
      logMsg = logMsg..'<br/>Pass: Assertion Issuer is correct.'
   end
   return valid,logMsg
end

-- Checks that the assertion audience is correct
local function checkAssertAudience(assertTree,logMsg) 
   local valid = true   
   local assertAud = assertTree["Assertion"]["Conditions"]["AudienceRestriction"]["Audience"][1]:nodeValue()
   if assertAud ~= globalConfigs.AUDIENCE then 
      valid = false 
      logMsg = logMsg..'<br/>Fail: Assertion audience is wrong.'
   else 
      logMsg = logMsg..'<br/>Pass: Assertion audience is correct.'
   end
   return valid,logMsg
end

-- Runs through all validity tests 
local function isValid(responseStr,responseTree) 
   
   local logMsg = '<br/>Validation Results for Response with ID '..getId(responseTree)..':'
   
   -- Check for completeness
   local valid,logMsg = isComplete(responseTree,logMsg)
   if valid == false then return valid,logMsg end

   -- Check the status
   local valid,logMsg = checkStatus(responseTree,logMsg)
   if valid == false then return valid,logMsg end
   
   -- Check that response matches request
   local valid,logMsg = matchRequest(responseTree,logMsg)
   if valid == false then return valid,logMsg end
   
   -- Check for replay (DEPRECATED as not needed. Replays will be caught by matchRequest)
   --local valid,logMsg = checkReplay(responseTree,logMsg)
   --if valid == false then return valid,logMsg end
  
   -- Check the destination
   local valid,logMsg = checkDestination(responseTree,logMsg)
   if valid == false then return valid,logMsg end
   
   -- Check the Response issuer
   local valid,logMsg = checkRespIssuer(responseTree,logMsg)
   if valid == false then return valid,logMsg end
   
   -- Check the signature
   local valid,logMsg,signedAssertion = checkSign(responseStr,logMsg) 
   if valid == false then return valid,logMsg end
   
   -- Check the Assertion Issuer
   local valid,logMsg = checkAssertIssuer(signedAssertion,logMsg)
   if valid == false then return valid,logMsg end
   
   -- Check the Assertion Audience
   local valid,logMsg = checkAssertAudience(signedAssertion,logMsg)
   if valid == false then return valid,logMsg end
   
   -- Validate the timestamps
   local valid,logMsg = validateTimeStamps(signedAssertion,logMsg)
   if valid == false then return valid,logMsg end

   return valid,logMsg,signedAssertion
end

return isValid