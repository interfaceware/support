local utils = require 'ccda.utils'

-- template used by addSystem to generate lua file
local Code = {
   '      [',
   1,
   '] = { code="',
   2,
   ', codeSystem="',
   3,
   ', displayName="',
   4,
   ', codeSystemName="',
   5,
   ' },'
}


-- helper function used to build a large string
local function newStack()
   -- starts with an empty string
   return {""}
end

-- helper function used to build a large string
local function addString(stack, s)
   -- push 's' into the stack
   table.insert(stack, s)
   for i=table.getn(stack)-1, 1, -1 do
      if string.len(stack[i]) > string.len(stack[i+1]) then
         break
      end
      stack[i] = stack[i].. table.remove(stack)
   end
end

-- add code system to output string
local function addSystem(I)
   local System = I.system
   local LuaFile = I.to
   
   trace(System)
   local SysName = System.valueSetName
	local Oid = System.valueSetOid
   trace(SysName..' = '..Oid)
   
   addString(LuaFile, 'voc["'..SysName..'"] = {\n')
   
   local Codes = System.code
   if Codes ~= nil then
      for _,C in pairs(System.code) do
         trace(C)
         Code = { '      [',
            C.displayName,
            '] = { code=',
            C.value,
            ', codeSystem=',
            C.codeSystem,
            ', displayName=',
            C.displayName,
            ', codeSystemName=',
            C.codeSystemName,
            ' },\n'
         }
         addString(LuaFile, table.concat(Code, '"'))
      end
   end
   addString(LuaFile, '}\n\n')

end

-- generate voc Lua file string
local function generateLuaFile(I)
   local LuaFile = newStack()
   -- add the top-level voc table, and some custom value set tables
   addString(LuaFile, [[
voc = {}

voc["LOINC"] = {
   ["History of Medication Use"] = {code="10160-0", codeSystem="2.16.840.1.113883.6.1", displayName="History of Medication Use", codeSystemName="LOINC"},
   ["Problem List"] = {code="11450-4", codeSystem="2.16.840.1.113883.6.1", displayName="Problem List", codeSystemName="LOINC"},
   ["Relevant Diagnostic Tests and/or Laboratory Data"] = {code="30954-2", codeSystem="2.16.840.1.113883.6.1", displayName="Relevant Diagnostic Tests and/or Laboratory Data", codeSystemName="LOINC"},
   ["Status"] = { code="33999-4", codeSystem="2.16.840.1.113883.6.1", displayName="Status",  codeSystemName="LOINC" },
   ["Summarization of Episode Note"] = { code="34133-9", codeSystem="2.16.840.1.113883.6.1", displayName="Summarization of Episode Note",  codeSystemName="LOINC" },
   ["History of Procedures"] = {code="47519-4", codeSystem="2.16.840.1.113883.6.1", displayName="History of Procedures", codeSystemName="LOINC"},						
   ["Allergies, Adverse Reactions, Alerts"] = { code="48765-2", codeSystem="2.16.840.1.113883.6.1", displayName="Allergies, adverse reactions, alerts",  codeSystemName="LOINC" }
}

voc["ActCode"] = {
   ["Assertion"] = { code="ASSERTION", codeSystem="2.16.840.1.113883.5.4", displayName="Assertion",  codeSystemName="ActCode" },
   ["Severity Observation"] = { code="SEV", codeSystem="2.16.840.1.113883.5.4", displayName="Severity Observation",  codeSystemName="ActCode" },
   ["Ambulatory"] = { code="AMB", codeSystem="2.16.840.1.113883.5.4", displayName="Ambulatory",  codeSystemName="ActCode" }
}

]])
   
   -- append parsed code systems to the file string
   for _,S in pairs(I.systems.system) do
      addSystem{system=S, to=LuaFile}
   end

   return table.concat(LuaFile)
end

-- Copies key-value pairs in t1 to t2
-- No key collision checks!
local function mergeTable(t1, t2)
   for K,V in pairs(t1) do
      t2[K] = V
   end
end


local setAttr = utils.setAttr
local addElement = utils.addElement
local function serializeToXML(Data)
   local VOC = xml.parse{data='<systems/>'}
   local SYS = VOC.systems
   -- add namespace attributes
	setAttr(SYS, 'xmlns:xsd', Data.systems["xmlns:xsd"]) 
	setAttr(SYS, 'xmlns:xsi', Data.systems["xmlns:xsi"]) 
	setAttr(SYS, 'xmlns', Data.systems["xmlns"])
   -- add system
   for I = 1,#Data.systems.system do
      local S = addElement(SYS, 'system')
      local Sys = Data.systems.system[I]
      trace(Sys)
      setAttr(S, 'valueSetOid', Sys.valueSetOid) 
      setAttr(S, 'valueSetName', Sys.valueSetName)
      -- add code if exists
      if Sys.code then
         for I = 1,#Sys.code do
            local C = addElement(S, 'code')
            local Code = Sys.code[I]
            trace(Sys)
            setAttr(C, 'value', Code.value) 
            setAttr(C, 'displayName', Code.displayName)
            setAttr(C, 'codeSystemName', Code.codeSystemName)
            setAttr(C, 'codeSystem', Code.codeSystem)
         end
      end
   end
   
   return VOC:S()
end

-- This function parses the 4MB voc.xml file and converts the parsed data into a string that
-- represents a Lua file.
-- The string should be save to a Lua file and the file should be loaded in the main function
local function parseVOC(Files)
   
   -- parse first voc.xml file
   local MasterVoc = utils.convertXMLtoTable(Files[1])
   trace(MasterVoc)
	
   -- create a map so we can merge other voc.xml files
   local Systems = MasterVoc.systems.system
   local OidMap = {}
   for J = 1,#Systems do
      local System = Systems[J]
      OidMap[System.valueSetOid] = J
   end
   trace(OidMap)

	-- parse other voc.xml files and merge with first
   for I = 2,#Files do
      local Voc = utils.convertXMLtoTable(Files[I])
      trace(Voc)

      local S = Voc.systems.system
      for K = 1, #S do
         local System = S[K] 
         trace(System)
         local match = OidMap[System.valueSetOid]
         trace(match)
         if match then
            Systems[match] = System
         else
            Systems[#Systems+1] = System
         end
      end
   end
   trace(MasterVoc)
   
   return generateLuaFile(MasterVoc), serializeToXML(MasterVoc)
end

return parseVOC