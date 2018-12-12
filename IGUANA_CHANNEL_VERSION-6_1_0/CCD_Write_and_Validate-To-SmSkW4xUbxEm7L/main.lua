-- The C-CDA Implementation Guide can be downloaded from
-- http://www.hl7.org/implement/standards/product_brief.cfm?product_id=408
--
-- NOTE : it will take ~30s to process all resource files when you run the
-- channel for the first time.

-- Import CCDA Modules
local loadResource = require 'ccda.resources'
local generateXML = require 'ccda.generate'
local validate = require 'ccda.validate'
local utils = require 'ccda.utils'
local cfg = require 'ccda.configs'

-- Import CCDA mappings
local header = require 'ccdaMappings.header'
local allergies = require 'ccdaMappings.allergies'
local meds = require 'ccdaMappings.medications'
local problems = require 'ccdaMappings.problems'
local procedures = require 'ccdaMappings.procedures'
local results = require 'ccdaMappings.results'
local social = require 'ccdaMappings.socialHistory'
local vitals = require 'ccdaMappings.vitals'

-- ========================== main funciton ==========================
function main(Data)
   -- 1) MacOS or Linux ONLY: check if xsltproc and xmllint softwares has been installed. 
   -- Note: for Windows, the "other" folder has included msxsl.exe and xmllint libraries
   -- Use this function below only on MacOS or Linux Iguana
   -- utils.checkDependencies()

   -- 2) load CCDA voc resources
   -- Note : The generation of CCDA\voc.lua could take up to 30 seconds because of the 4MB voc.xml file.
	local Definition = loadResource()
   
   -- 3) Generate CCDA xml root
   -- It is VERY important to inlucde the urn:hl7-org:v3 namespace. Otherwise the XML
   -- validation will not work. The xsi namespace is used by some elements to redefine their types
   local Doc = xml.parse{data=[[
      <ClinicalDocument xmlns="urn:hl7-org:v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:cda="urn:hl7-org:v3" xmlns:sdtc="urn:hl7-org:sdtc"/>
   ]]}
   
   -- 4) Map CCDA Header
   local CD = {}   
   header.FillHeader(CD)
   CD.recordTarget = {}
   header.FillrecordTarget(CD.recordTarget)
	CD.author = {}
	header.FillAuthor(CD.author)
   CD.dataEnterer = {}
   header.FillDataEnterer(CD.dataEnterer)
   CD.informant = {}
   header.FillInformant(CD.informant)
   CD.custodian = {}
   header.FillCustodian(CD.custodian)
   CD.informationRecipient = {}
   header.FillInformationRecipient(CD.informationRecipient)
   CD.legalAuthenticator = {}
   header.FillLegalAuthenticator(CD.legalAuthenticator)
   CD.authenticator = {}
   header.FillAuthenticator(CD.authenticator)
   CD.documentationOf = {}
   header.FillDocumentationOf(CD.documentationOf)

   -- 5) Map CCDA Structure Body
   CD.component = {}
   CD.component.structuredBody = {}
   CD.component.structuredBody.component = {}
   local sB = CD.component.structuredBody
   allergies.fillAllergies(sB)
   meds.fillMedications(sB)
   problems.fillProblems(sB)
   procedures.fillProcedures(sB)
   results.fillResults(sB)
   vitals.fillVitals(sB)
   social.fillSocialHistory(sB)
   
   -- 6) generate the CCDA document and save it in CCDA\cda_xml.xml for validation
   generateXML{parent=Doc.ClinicalDocument, data=CD, ccda = Definition}
   local f = io.open(cfg.CCDAdir..cfg.CCDAoutput,'w+')
   f:write(tostring(Doc))
   f:close()

	
	-- 7) validate the XML file 
   validate.ValidateCCDA()
	
   -- 8) parse validation report
   --
   -- IMPORTANT: the validation system is intended as an aid to the creation of a bare minimum
   -- CCDA document from scratch and to help you understand the Implementation Guide. The
   -- schematron file it depends on is a "work-in-progress" at best.
	-- ========================================================================
   --    YOU SHOULD ALWAYS TEST YOUR CCDA DOCUMENT USING ONLINE VALIDATORS!
   -- ========================================================================
   -- https://sitenv.org/sandbox-ccda/ccda-validator
   --
   -- catch the error thrown in ccda.validate.lua and display it here
   -- ParseSVRL has 3 different output modes:
   -- 1 : outputs all Schema errors and Shall errors
   -- 2 : outputs all Schema errors, Shall errors, and Should errors
   -- Default : outputs all Schema errors
   local Success, Err = pcall(function() validate.ParseValidationResults{file=cfg.CCDAdir..cfg.CCDAerrName, mode=1} end)
   if not Success then
      -- It is highly recommended to click the error message in the Annotation panel ---------------------->
      -- and "dock" the pop-up window to the bottom of the browser.
      iguana.logError(Err) --or error(Err)
   end
	
end
