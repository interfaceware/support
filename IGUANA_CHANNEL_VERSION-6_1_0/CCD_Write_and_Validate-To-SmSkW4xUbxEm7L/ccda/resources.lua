local utils = require 'ccda.utils'
local cfg = require 'ccda.configs'

local function parseSchema()
   local XSDdir = utils.ccdaRssDir..cfg.CCDAVersion..utils.pathSeparator..'Schema'..utils.pathSeparator..'infrastructure'..utils.pathSeparator..'cda'..utils.pathSeparator
   local FileXSD = XSDdir..'CDA_SDTC.xsd'

   local xsd = require('ccda.xsd')
   local ccda = xsd.parseXSD(FileXSD)
   trace(ccda)
   
   -- save parsed data to file
   local fx = io.open(cfg.CCDAdir..'ccda_xsd.json','w+')
   fx:write(json.serialize{data=ccda})
   fx:close()
   
   return ccda
end


local function parseVocab()
   -- The R2.1 voc.xml does not include R1.1 voc.xml so we need to process both
   local Files = {
      utils.ccdaRssDir..'R1_1'..utils.pathSeparator..'voc.xml',
      utils.ccdaRssDir..cfg.CCDAVersion..utils.pathSeparator..'voc.xml'
   }
   
   -- parse the voc file
   local parseVOC = require('ccda.voc')
   local LuaData, XmlData = parseVOC(Files)
   
   -- save the lua version for "slightly" faster load
   local fl = io.open(cfg.CCDAdir..'vocab.lua','w+')
   fl:write(tostring(LuaData))
   fl:close()
   
   -- save the combined voc file for schematron validation
   local fx = io.open(cfg.CCDAdir..'voc.xml','w+')
   fx:write(tostring(XmlData))
   fx:close()
end


local function parseSchematron()   
   local formatSCH = require 'ccda.sch'
   local SchData = formatSCH(utils.ccdaRssDir..cfg.CCDAVersion..utils.pathSeparator..'Consolidate.sch')
   -- save sch to file
   local fs = io.open(cfg.CCDAdir..'Consolidate.sch','w+')
   fs:write(tostring(SchData))
   fs:close()
   
   local SchDir = utils.ccdaRssDir..'iso-schematron-xslt1'..utils.pathSeparator
   -- generate XSL which will be used for real-time validation
   -- Command for msxsl
   --   'msxsl -o CCDA\Consolidation.xsl CCDA\Consolidate.sch edit\admin\other\iso_iso-schematron-xslt1\iso_svrl_for_xslt1.xsl'
   -- Command for xsltproc
   --   'xsltproc -o CCDA/Consolidation.xsl edit/admin/other/iso_iso-schematron-xslt1/iso_svrl_for_xslt1.xsl CCDA/Consolidate.sch'
   -- Command for saxon9he
   --   'java -jar saxon9he.jar -o:CCDA\Consolidation.xsl CCDA\Consolidate.sch edit\admin\other\iso_iso-schematron-xslt1\iso_svrl_for_xslt1.xsl'
   local OtherDir = iguana.project.root()..'other'..utils.pathSeparator
   local CommandsW = {
      OtherDir..'msxsl -o ',
      'Consolidation.xsl ',
      'Consolidate.sch '..SchDir..'iso_svrl_for_xslt1.xsl'
   }
   local CommandsP = {
      'xsltproc -o ',
      'Consolidation.xsl '..SchDir..'iso_svrl_for_xslt1.xsl ',
      'Consolidate.sch'
   }
   local Commands = utils.pathSeparator == '/' and CommandsP or CommandsW

   local XSLcommand = table.concat(Commands, cfg.CCDAdir)
   trace(XSLcommand)
   os.execute(XSLcommand)
end



-- load XSD and VOC database
-- XSD is used to create the XML file
-- VOC contains MOST (not all) of the HL7 code system / value set
-- 
-- If a file is not found, it will be regenerated. Note that it could
-- take up to 30 seconds to regenerate the 4MB VOC file
-- 
-- You may add additional code systems or values to the VOC database.
-- If the code system exists in voc.xml, you need to append the new value to the system
-- If the code system does NOT exist in voc.xml, you could either add the new code system 
-- to voc.xml, or you can add it in the generateLuaFile() function in voc.lua
local function loadResource()
   -- create cfg.CCDAdir if it does not exist.
   if not os.fs.access(cfg.CCDAdir) then
      trace('CCDA directory does not exist. Create it.')
      os.fs.mkdir(cfg.CCDAdirName)
   end
   
   -- load XSD table
   local ccda = {}
   local fxj = io.open(cfg.CCDAdir..'ccda_xsd.json','r')
   if fxj then
      local fxjData = fxj:read('*a')
      fxj:close()
      ccda.namespace = json.parse{data=fxjData}
   else
      ccda.namespace = parseSchema()
   end
   
   -- load vocab.lua
   if not os.fs.access(cfg.CCDAdir..'vocab.lua') then
      parseVocab()
   end
   local fvl = io.open(cfg.CCDAdir..'vocab.lua','r')
   if fvl == nil then
      error('Failed to convert voc.xml to Lua file.')
   end
   fvl:close()
   dofile(cfg.CCDAdir..'vocab.lua')

   -- make sure Consolidation.xsl exists
   local fsx = io.open(cfg.CCDAdir..'Consolidation.xsl','r')
   if fsx == nil then
      parseSchematron()
      fsx = io.open(cfg.CCDAdir..'Consolidation.xsl','r')
      if fsx == nil then
         error('Failed to convert schematron to XSL file.')
      end
   end
   fsx:close()

   return ccda
end

return loadResource