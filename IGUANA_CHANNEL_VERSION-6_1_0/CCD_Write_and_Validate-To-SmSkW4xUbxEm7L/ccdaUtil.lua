require 'ccda.xsd'
require 'ccda.voc'
require 'ccda.sch'
require 'ccda.generate'
require 'ccda.validate'

local ccdaUtil = {}

---- Local Functions ----

---- Public Functions ---
function ccdaUtil.InitialLoad()
   -- Load CCDA grammar
   -- Note : The generation of CCDA\voc.lua could take up to 30 seconds because of the 4MB voc.xml file.
   loadDB()
end   

function ccdaUtil.GererateCcdaXML(CD)
   local Doc = xml.parse{data=[[
      <ClinicalDocument xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:cda="urn:hl7-org:v3" xmlns:sdtc="urn:hl7-org:sdtc"/>
      ]]}

   --The above functions fill out the header and structured body of the CCD document.
   generateXML{parent=Doc.ClinicalDocument, data=CD}
   return Doc
end

function ccdaUtil.WriteCcdaXML(Doc, Data)
   local DB_ID = 'Screen_CDA'
   local P_ID = Data
   local filename = DB_ID..'_'..P_ID
   
   -- save the XML file to disk for validation
   local filePath = CCDAdir..filename..'.xml'
   local f = io.open(filePath,'w+')
   f:write(tostring(Doc))
   f:close()
   
   return filePath
end

function ccdaUtil.ValidateCCDA(filePath)
   ValidateCCDA(filePath)
end

function ccdaUtil.GetCCDAValidationResult(filePath)
   local Success, Err = pcall(function() ParseValidationResults{file=CCDAdir..'cda_err.svrl', xml=filePath, mode=2} end)
   return Success, Err
end

return ccdaUtil