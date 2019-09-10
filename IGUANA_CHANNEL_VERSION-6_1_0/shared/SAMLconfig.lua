-------------------------------------------------
--------- All configurable values go here -------
-------------------------------------------------

-- Ensure that the https ports AND the Iguana web server ports both use certificates. 
-- All access must be done through https 
-- Self-Signed Certicates is okay

local globalConfigs = {}

globalConfigs.IGUANA_URL       = ''                                                           -- Iguana base URL
globalConfigs.IGUANA_PORT      = iguana.webInfo().web_config.port
globalConfigs.IGUANA_HTTP_PORT = iguana.webInfo().https_channel_server.port
globalConfigs.AUDIENCE         = globalConfigs.IGUANA_URL..':'..globalConfigs.IGUANA_HTTP_PORT..'/SAMLUser'         -- SP Identifier (Entity ID)
globalConfigs.ACS_URL          = globalConfigs.IGUANA_URL..':'..globalConfigs.IGUANA_HTTP_PORT..'/SAMLAssertion/'   -- Reply URL (Assertion Consumer Service URL)
globalConfigs.ISSUER           = ''                    -- IdP Identifier (get from IdP)
globalConfigs.IDP_URL          = ''     -- Login URL (get from IdP)

globalConfigs.replayStoreName  = ''                          -- DEPRECATED (No longer needed)
globalConfigs.requestStoreName = ''       -- Path to the request store 
globalConfigs.certLocation     = ''   -- Place the x509 certificate provided by IdP
globalConfigs.signxmlLocation  = ''     -- Location of teh signxml library. Can leave as is if on Linux. 
globalConfigs.pythonLocation   = ''                               -- Location of the python executable. Can leave as is if on Linux.   
globalConfigs.pyScrLocation    = ''         -- Location of the python scripts that will be generated
globalConfigs.pwDirectory      = ''            -- Location of the password directory. 

return globalConfigs