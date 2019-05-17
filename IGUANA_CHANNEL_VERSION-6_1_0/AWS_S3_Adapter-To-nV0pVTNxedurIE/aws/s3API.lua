-- S3 Bucket API functions
local awsConfigs = require 'aws.configurations'
local headerUtil = require 'aws.apiHeaderUtil'
local retry = require 'retry'

local s3API = {}

-- Local functions
local function WebServiceError(Success, ErrMsgOrReturnCode, Code, Headers)
   local funcSuccess
   if Success then
      -- successfully call the web service
      funcSuccess = true -- don't retry
      -- we still need to check the Code (HTTP return code)
      if Code == 503 then
         iguana.logInfo('WebService connection: 503 - Service Unavailable: unavailable probably temporarily overloaded')
         -- wait longer before retrying (in this case an extra 30 seconds)
         -- this is an example and can be customized to your requirements
         -- NOTE: Some WebServices may include a retry-after field in the Headers
         --       if so you can use this to customize the delay (sleep) period
         if not iguana.isTest() then
            util.sleep(30000)
         end
         funcSuccess = false -- retry
      elseif Code == 404 then
         iguana.logInfo('WebService connection: 404 - Not Found: the resource was not found but may be available in the future')
         -- wait longer before retrying (in this case an extra 120 seconds)
         -- this is an example and can be customized to your requirements
         -- NOTE: Some WebServices may include a retry-after field in the Headers
         --       if so you can use this to customize the delay (sleep) period
         if not iguana.isTest() then
            util.sleep(120000)
         end
      elseif Code == 408 then
         iguana.logInfo('WebService connection: 408 - Request Timeout: the server timed out probably temporarily overloaded')
         -- wait longer before retrying (in this case an extra 30 seconds)
         -- this is an example and can be customized to your requirements
         -- NOTE: Some WebServices may include a retry-after field in the Headers
         --       if so you can use this to customize the delay (sleep) period
         if not iguana.isTest() then
            util.sleep(30000)
         end
      elseif Code == 429 then
         iguana.logInfo('WebService connection: 429 - Too Many Requests: too many requests or concurrent connections')         
         -- wait longer before retrying (in this case an extra 60 seconds)
         -- this is an example and can be customized to your requirements
         -- NOTE: Some WebServices may include a retry-after field in the Headers
         --       if so you can use this to customize the delay (sleep) period
         if not iguana.isTest() then
            util.sleep(60000)
         end
         funcSuccess = false -- retry
      elseif Code == 401 then
         iguana.logError('WebService connection: 401 - Unauthorized: usually indicates Login failure')
         -- you could/should also email the administrator here
         -- https://help.interfaceware.com/code/details/send-an-email-from-lua?v=6.0.0
         
         -- in this case we don't want to retry 
         -- so we don't set funcSuccess = false
      elseif Code == 403 then
         iguana.logError('WebService connection: 403 - Forbidden: you do not have permission to access this resource')
         -- you could/should also email the administrator here
         -- https://help.interfaceware.com/code/details/send-an-email-from-lua?v=6.0.0
         
         -- in this case we don't want to retry 
         -- so we don't set funcSuccess = false
      elseif Code == 413 then
         iguana.logError('WebService connection: 413 - Payload Too Large: the requested result is too large to process')
         -- you could/should also email the administrator here
         -- https://help.interfaceware.com/code/details/send-an-email-from-lua?v=6.0.0
         
         -- in this case we don't want to retry 
         -- so we don't set funcSuccess = false
      end
   else
      -- anything else should be a genuine error that we don't want to retry
      -- you can customize the logic here to retry specific errors if needed
      iguana.logError('WebService connection: ERROR '..tostring(Code)..' - '..tostring(ErrMsgOrReturnCode))
      funcSuccess = true -- we don't want to retry
   end
   return funcSuccess
end

local function ReadS3(canonicalendpoint)
   local myheaders = headerUtil.getAwsViaAuthorizationHeader(canonicalendpoint)
   local url = awsConfigs.ENDPOINT..canonicalendpoint
   local r, e, h = net.http.get{url = url, headers= myheaders, live = awsConfigs.READLIVE}
   return r, e, h
end

local function UploadS3(content, canonicalendpoint)
   local myputheaders = headerUtil.putAwsViaAuthorizationHeader(canonicalendpoint, content)
   local url = awsConfigs.ENDPOINT..canonicalendpoint
   local r, e, h = net.http.post{url = url, headers = myputheaders, method='PUT', body = content, live = awsConfigs.UPLOADLIVE, timeout= awsConfigs.POSTTIMEOUT}
   return r,e, h
end

-- Public functions
function s3API.readFile(canonicalendpoint)
   local r, e, h, re = retry.call{func=ReadS3, arg1=canonicalendpoint, retry=awsConfigs.RETRY, pause=awsConfigs.RETRYPAUSE, funcname='ReadS3', errorfunc=WebServiceError}
   return r
end

function s3API.uploadFile(content, canonicalendpoint)
   local r, e, h, re = retry.call{func=UploadS3, arg1=content, arg2=canonicalendpoint, retry=awsConfigs.RETRY, pause=awsConfigs.RETRYPAUSE, funcname='UploadS3', errorfunc=WebServiceError}
   if tonumber(e) == 200 then
      return true
   else
      return false
   end
end


local ReadHelp=[[{
"Returns": [{"Desc": "The file contents from the configured AWS S3 bucket."}],
"Title": "s3API.readFile",
"Parameters": [{ "canonicalendpoint": {"Desc": "S3 bucket absolute file path."}}],
"ParameterTable": false,
"Usage": "s3API.readFile(canonicalendpoint)",
"Examples": [
"-- Define S3 bucket absolute file path
 local canonicalendpoint = '/JSON/patient-schema.json'<br />
 -- Put data in S3
 s3API.uploadFile(content, canonicalendpoint)<br/>
 -- Get data in S3
 local file = s3API.readFile(canonicalendpoint)"
],
"Desc": "This function loads a file from the configured AWS S3 bucket."
}]]

help.set{input_function=s3API.readFile, help_data=json.parse{data=ReadHelp}}

local UploadHelp=[[{
"Returns": [{"Desc": "Boolean true for a successful upload."}],
"Title": "s3API.uploadFile",
"Parameters": [
{ "content": {"Desc": "The upload file."}},     
{ "canonicalendpoint": { "Desc": "The S3 bucket absolute file path."}}],
"ParameterTable": false,
"Usage": "s3API.uploadFile",
"Examples": [
"-- Define S3 bucket absolute file path
 local canonicalendpoint = '/JSON/patient-schema.json'<br />
 -- Put data in S3
 s3API.uploadFile(content, canonicalendpoint)<br/>
 -- Get data in S3
 local file = s3API.readFile(canonicalendpoint)"],
"Desc": "This function uploads a file to the configured AWS S3 bucket."
}]]

help.set{input_function=s3API.uploadFile, help_data=json.parse{data=UploadHelp}}

return s3API