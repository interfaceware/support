-- If you see the following error, it usually means an externally referenced file is not found.
-- The Consolidate.sch file depends on the voc.xml to check if the assigned code value is
-- selected from the correct value set.
-- e.g. count(cda:confidentialityCode[@code=document("..\edit\admin\other\voc.xml")/voc:systems/voc:system[@valueSetOid="2.16.840.1.113883.1.11.16926"]/voc:code/@value])=1
-- As a result, if voc.xml is not found, MSXSL throws the error below. Therefore, it is crucial
-- to ensure voc.xml can be found in the specified directory.
-- Consolidated.sch is in CCDA\
-- voc.xml is in edit\admin\other\
--[[
Error occurred while executing stylesheet 'CCDA\Consolidation.xsl'.

Code:   0x800c0006
The system cannot locate the object specified.
--]]
local utils = require 'ccda.utils'
local cfg = require 'ccda.configs'

local validate = {}

function validate.ValidateCCDA()
   local OtherDir = iguana.project.root()..'other'..utils.pathSeparator
   --
   -- msxsl.exe in bundled in the other\ directory
   local CommandsW = {
      OtherDir..'msxsl.exe -o ',
      'cda_err.svrl ',
      cfg.CCDAoutput..' ',
      'Consolidation.xsl'
   }
   local CommandsP = {
      'xsltproc -o ',
      'cda_err.svrl ',
      'Consolidation.xsl ',
      cfg.CCDAoutput
   }
   local Commands = utils.pathSeparator == '\\' and CommandsW or CommandsP
   -- Command for msxsl
   --    'msxsl -o CCDA\cda_err.svrl CCDA\cda_xml.xml CCDA\Consolidation.xsl'
   -- Command for xsltproc
   --    'xsltproc -o CCDA/cda_err.svrl CCDA/Consolidation.xsl CCDA/cda_xml.xml'
   -- Command for saxon9he
   --    'java -jar saxon9he.jar -o:CCDA\cda_err.svrl CCDA\cda_xml.xml CCDA\Consolidation.xsl'
   local Command
   Command = table.concat(Commands, cfg.CCDAdir)
   trace(Command)
   if os.execute(Command) ~= 0 then
      -- present the error message if command returns with an error
      local Prog = io.popen(Command..' 2>&1')
      local Output = Prog:read("*a")
      Prog:close()
      error(Output)
   end
   
   -- validate simple types using the XSD files
   local XsdCmd = {
      ' --schema '..OtherDir..'CCDA',
      cfg.CCDAVersion,
      'Schema',
      'infrastructure',
      'cda',
      'CDA_SDTC.xsd '..cfg.CCDAdir..cfg.CCDAoutput..' 2> '..cfg.CCDAdir..'xsd_err'
   }
   XsdCmd = table.concat(XsdCmd, utils.pathSeparator)
	if utils.pathSeparator == '\\' then
      XsdCmd = OtherDir..'xmllint\\xmllint.exe'..XsdCmd
   else
      XsdCmd = 'xmllint'..XsdCmd
	end
   trace(XsdCmd)
   os.execute(XsdCmd)
end



-- Definition:
--    SHALL test : the error message of the test contains the keyword SHALL
--    SHOULD test : the error message of the test contains the keyword SHOULD
-- Note:
--    Error is thrown only when a SHALL test fails, and all SHOULD test fails are appended 
-- afterthe SHALL test failure. If no SHALL fails found, SHOULD fails are displayed.
--    If the XML file fails any SHALL test, it is invalid. If it fails a SHOULD test,
-- it is still valid but missing infomation that's recommended to include.
function ParseSVRL(I)
   local File = I.file
   local Mode = I.mode

   local Verror = utils.convertXMLtoTable(File)["svrl:schematron-output"]
   local Fails = Verror["svrl:failed-assert"]
   trace(Fails)

   if Fails == nil then
      trace("SCH validation passed.")
      return nil, 0, 0, true
   end

   -- if there is only 1 fail, Fails is a table. Wrap it in an array
   if #Fails == 0 then
      Fails = {Fails}
   end

   local SHALLcount, SHOULDcount = 0,0
   local ShallErrMsg, ShouldErrMsg, ErrMsg = '', '', ''

   for _,I in pairs(Fails) do
      -- grab error location
      local Err = 'Location :  '..I.location..'\n'
      -- grab error test
      Err = Err..'Test\t :  '..I.test..'\n'
      -- grab error message
      local RawMessage = I["svrl:text"].Text
      Err = Err..'Message\t :  '..RawMessage..'\n'

      -- determine error type
      local LocShould = RawMessage:find('SHOULD') or 100
      local LocShall = RawMessage:find('SHALL') or 100
      if LocShould == LocShall then
         error("Unable to determine the type of the error.")
      end
      
      if LocShould < LocShall then
         SHOULDcount = SHOULDcount + 1
         ShouldErrMsg = ShouldErrMsg..'\n'..Err
      else
         SHALLcount = SHALLcount + 1
         ShallErrMsg = ShallErrMsg..'\n'..Err
      end
   end
   
   if Mode == 1 then
      ErrMsg = ErrMsg..ShallErrMsg..'\n\n\n'
      SHOULDcount = 0
   elseif Mode == 2 then
      ErrMsg = ErrMsg..ShallErrMsg..'\n\n\n'..ShouldErrMsg
   else
      ErrMsg = ""
      SHOULDcount = 0
      SHALLcount = 0
   end

   return ErrMsg, SHALLcount, SHOULDcount
end



local function ParseXsdErr()
   local LineCount = 0
   for Line in io.lines(cfg.CCDAdir..'xsd_err') do
      if Line == cfg.CCDAdir..cfg.CCDAoutput..' validates' then
         trace('XSD validation passed.')
         return nil, 0
      end
      LineCount = LineCount + 1
   end   

   local X = io.open(cfg.CCDAdir..'xsd_err', 'r')
   local XsdErr = X:read('*a')
   X:close()

   return XsdErr, LineCount-1
end



function validate.ParseValidationResults(I)
   local SchErr, Shall, Should = ParseSVRL(I)
   local XsdErr, Count = ParseXsdErr()

   if Shall == 0 
      and Should == 0
      and Count == 0 
   then
      trace("XML validation passed.")
      return true
   end

   -- build error message.
   local Errors = 'XML validation failed.\n\nSummary : \n'
   Errors = Errors..'\tSchematron Validation : '
   if SchErr then
      Errors = Errors..Shall..' SHALL error(s) and '
      Errors = Errors..Should..' SHOULD error(s)\n'
   else
      Errors = Errors..'Passed\n'
   end
   Errors = Errors..'\tSchema Validation : '
   if XsdErr then
      Errors = Errors..Count..' error(s)\n\n\n'
   else
      Errors = Errors..'Passed\n\n\n'
   end
   
   if SchErr then
      Errors = Errors..SchErr..'\n\n\n'
   end
   if XsdErr then
      Errors = Errors..XsdErr
   end 
   
   if Errors ~= nil then
      error(Errors)
   end
end

return validate