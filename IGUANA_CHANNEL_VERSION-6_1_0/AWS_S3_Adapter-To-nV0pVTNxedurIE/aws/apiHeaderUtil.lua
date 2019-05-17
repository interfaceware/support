-- AWS API utility that creates get/put authorization API header
local awsConfigs = require 'aws.configurations'

local headerUtil = {}

-- Local functions --
local function sign(key, msg)
   return crypto.hmac{data=iconv.ascii.dec(msg), key=key, algorithm="sha256"}   
end

local function getSignatureKey(key, dateStamp, regionName, serviceName)
   local kDate = sign(iconv.ascii.dec("AWS4"..key), dateStamp) 
   local kRegion = sign(kDate, regionName)
   local kService = sign(kRegion, serviceName)
   local kSigning = sign(kService, 'aws4_request')
   return kSigning         
end

local function getAuthorizationHeader(method, amzdate, datestamp, payload_hash, canonical_uri)
   --TASK 1: Create a Canonical Request for bucket
   -- https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
   local canonical_querystring = ""  -- empty in this case
   local canonical_headers = "host:" .. awsConfigs.HOST .. "\n" .."x-amz-content-sha256:" .. payload_hash.."\n".. "x-amz-date:" .. amzdate .. "\n"
   local signed_headers = "host;x-amz-content-sha256;x-amz-date"   
   local canonical_request = method .. "\n" .. canonical_uri .. "\n".. canonical_querystring 
   .. "\n" .. canonical_headers .. "\n" .. signed_headers .. "\n" .. payload_hash
   
   --TASK 2: Create a string to sign
   --https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
   --https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html#canonical-request
   local algorithm = "AWS4-HMAC-SHA256"   
   local credential_scope = datestamp .. "/" .. awsConfigs.REGION .. "/" .. awsConfigs.SERVICE .. "/" .. "aws4_request" 
   local string_to_sign = algorithm .. "\n" ..  amzdate .. "\n" ..  credential_scope .. "\n" 
   .. string.lower(filter.hex.enc(crypto.digest{data=canonical_request, algorithm="sha256"}))

   --TASK 3: Create a Signing key
   local signing_key = getSignatureKey(awsConfigs.SECRETKEY, datestamp, awsConfigs.REGION, awsConfigs.SERVICE)   
   local signature = string.lower(filter.hex.enc(crypto.hmac{data=iconv.ascii.dec(string_to_sign), key=signing_key, algorithm="sha256"}))   

   --TASK 4: Add signature to authorization request
   local authorization_header = algorithm .. " " .. "Credential=" .. awsConfigs.ACCESSKEY .. "/" .. credential_scope .. ", " 
   ..  "SignedHeaders=" .. signed_headers .. ", " .. "Signature=" .. signature 
   
   return authorization_header
end

-- Public functions --
function headerUtil.getAwsViaAuthorizationHeader(canonical_uri) 
   -- Prepare Authorization Tasks
   local method = "GET"
   local t = os.ts.time()
   local amzdate = os.ts.date("!%Y%m%dT%H%M%SZ", t)
   local datestamp = os.ts.date("!%Y%m%d", t)  
   local payload_hash = string.lower(filter.hex.enc(crypto.digest{data = '', algorithm="sha256"}))

	-- return Authorization Header
   local headers = {}
   headers["host"] = awsConfigs.HOST
   headers["x-amz-date"] = amzdate
   -- headers["range"]= "bytes=0-9" -- only return 9 bytes data
   headers["x-amz-content-sha256"] = payload_hash
   headers["authorization"] = getAuthorizationHeader(method, amzdate, datestamp, payload_hash, canonical_uri)
   return headers
end

function headerUtil.putAwsViaAuthorizationHeader(canonical_uri, content) 
   -- Prepare Authorization Tasks
   local method = "PUT"
   local t = os.ts.time()
   local amzdate = os.ts.date("!%Y%m%dT%H%M%SZ", t)
   local datestamp = os.ts.date("!%Y%m%d", t)  
   local payload_hash = string.lower(filter.hex.enc(crypto.digest{data = content, algorithm="sha256"})) 

   -- return Authorization header
   local hearders = {}
   hearders["host"] = awsConfigs.HOST
   hearders["x-amz-date"] = amzdate
   hearders["authorization"] = getAuthorizationHeader(method, amzdate, datestamp, payload_hash, canonical_uri)
   hearders["content-type"] = "application/json"
   hearders["content-length"] = #content
   hearders["Expect"] = '100-continue'
   hearders["x-amz-content-sha256"] = payload_hash
   hearders["Connection"]= 'Keep-Alive'
   return hearders
end

return headerUtil