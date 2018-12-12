local utils = require 'ccda.utils'

local sch = {}
-- attributes of the schematron root element
sch.meta = {}
-- namespace database
sch.namespace = {}
-- phase database
sch.phase = {}
-- pattern database
sch.pattern = {}
-- rule database
sch.rule = {}
-- abstract rule database
sch.rule.abstract = {}
-- assert database
sch.assert = {}

local setAttr = utils.setAttr
local setText = utils.setText
local addElement = utils.addElement

-- ==================== schematron extraction functions ====================

-- extract schematron assert
local function SCHextractAssert(I)
   local J = I.rule
   local Temp = I.output
   
   if Temp['assert'] == nil then
      Temp['assert'] = {}
   end
   trace(Temp)
   if J["sch:assert"] ~= nil then
      if #J["sch:assert"] == 0 then
         J["sch:assert"] = {J["sch:assert"]}
      end
      for _,K in pairs(J["sch:assert"]) do
         trace(K)
         -- add to assert database
         if K.id ~= nil then
            --[[
            local ConfId = tonumber(K.id:match('%d+'))
            trace(ConfId)
            if ConfId == nil then
               ConfId = K.id
            end
            ]]
            local ConfId = K.id
            sch.assert[ConfId] = K
            -- add to parent rule
            table.insert(Temp['assert'], ConfId)
         end
      end
   end
end


-- extract a schematron rule
local function SCHextractRule(I)
   local Source = I.source
   local Output = I.output

   for _,J in pairs(Source) do
      trace(J)
      local RuleId = J.id
      trace(RuleId)
      local Temp = {}

      if J['sch:extends'] ~= nil then
         local BaseRuleId = J['sch:extends'].rule
         local BaseRuleDB = sch.rule.abstract
         trace(BaseRuleId)
         trace(sch.rule)
         trace(BaseRuleDB[BaseRuleId]['assert'])
         Temp['assert'] = utils.copyTable(BaseRuleDB[BaseRuleId]['assert'])
         trace(Temp)
      end
      
      -- extract rule context
      Temp['context'] = J.context
      
      -- extract rule asserts
      SCHextractAssert{rule=J, output=Temp}
      
      -- abstract rules have not context
      if J.context == nil then
         -- save abstract rules to sch.rule.abstract
         sch.rule.abstract[RuleId] = Temp
      else
         -- save rule to sch.rule
         sch.rule[RuleId] = Temp
         -- add rule id to pattern's rule list
         table.insert(Output, RuleId)
      end
   end
   trace(sch.rule)
   return Output
end


-- parse a schematron file and save it in a Lua table
-- Note: this function is designed to parse C-CDA sch file only!
local function parseSCH(File, NamespaceIn)   
   local Schematron = utils.convertXMLtoTable(File)["sch:schema"]
   trace(Schematron)
   
   -- extract meta data
   for J,K in pairs(Schematron) do
      if type(K) ~= 'table' then
         sch.meta[J] = K
      end
   end
   trace(sch.meta)

   -- extract namespace map
   local NamespaceTarget
   for _,J in pairs(Schematron['sch:ns']) do
      sch.namespace[J.prefix] = J.uri
   end
   trace(sch.namespace)

   -- extract phase
   local NamespaceTarget
   for _,J in pairs(Schematron['sch:phase']) do
      local PhaseId = J.id
      trace(PhaseId)
      local Actives = {}
      for _,M in pairs(J["sch:active"]) do
         table.insert(Actives, M.pattern)
      end
      sch.phase[PhaseId] = Actives
   end
   trace(sch.phase)
   
   -- extract pattern
   -- It turns out that the rule ID is exactly the same as the pattern ID
   -- except the first char 'p' is replaced by 'r'
   for _,J in pairs(Schematron['sch:pattern']) do
      local PatternId = J.id
      trace(PatternId)
      sch.pattern[PatternId] = {}
      SCHextractRule{source=J["sch:rule"], output=sch.pattern[PatternId]}
   end
   
end



-- ==================== schematron generation functions ====================

-- set the content of a schematron element
local function setAttrAndText(I)
   local Target = I.target
   local ChildAttr = I.attr
   
   local OtherDir = iguana.workingDir()..iguana.project.root()..'other'..utils.pathSeparator
   for I,J in pairs(ChildAttr) do
      if I == 'Text' then
         setText(Target, J)
      elseif I == 'test' then
         -- Important: the schematron refers voc.xml and checks agasinst it.
         -- Since we will not save the generated sch file in the same directory,
         -- document(voc.xml) in test strings need to be updated to
         -- document(edit/admin/other/CCDA/R2_1(R2)/voc.xml).
         -- The generate sch file will be save in CCDA\
         --if J:find('voc.xml', 1, true) then
         --   J = J:gsub('voc.xml', utils.ccdaRssDir..'voc.xml')
         --end
         setAttr(Target, I, J)
      else
         setAttr(Target, I, J)
      end
   end

end


-- insert schemtaron elements to a parent node
local function insertElement(I)
   local Target = I.target
   local ChildName = I.name
   local ChildAttr = I.attr

   local Child = addElement(Target, ChildName)
   setAttrAndText{target=Child, attr=ChildAttr}
end


-- genereate the namespaces of a schematron
local function addNamespaces(I)
   local Target = I.target
   
   local NSattr = {prefix=1, uri=1}
   assert(next(sch.namespace) ~= nil)
   for J,K in pairs(sch.namespace) do
      NSattr.prefix, NSattr.uri = J, K
      insertElement{target=Target, name='sch:ns', attr=NSattr}
   end
   
end


-- add branch rules to a schematron pattern
local function appendBranchWarningRule(I)
   local Target = I.target
   local wPatternId = I.wPid
   local Out = I.output
	trace(wPatternId)
   
   local wPattern = sch.pattern[wPatternId]
   trace(wPattern)
   for _,J in pairs(wPattern) do
      if J:find('branch') then
         trace(J)
         local Rule = sch.rule[J]
         trace(Rule)
         local RuleNode = addElement(Target, 'sch:rule')
         setAttr(RuleNode, 'id', J)
         setAttr(RuleNode, 'context', Rule.context)
         for _,K in pairs(Rule.assert) do
            trace(K)
            insertElement{target=RuleNode, name='sch:assert', attr=sch.assert[K]}
         end
      end
   end
end

local function addPatternRule(ErrRuleId, Target, ProcessedWarns)
   
   trace(ErrRuleId)
   
   -- add merged error and warning rules to the Target
   local RuleNode = addElement(Target, 'sch:rule')
   setAttr(RuleNode, 'id', ErrRuleId)
   setAttr(RuleNode, 'context', sch.rule[ErrRuleId].context)

   --   sch.rule["r-urn-hl7ii-2.16.840.1.113883.10.20.22.1.1-2015-08-01-errors"].asserts
   
   -- add shall asserts - patterns in error phase
   local Asserts = sch.rule[ErrRuleId].assert
   for I = 1,#Asserts do
      local E = sch.assert[Asserts[I]]
      trace(E.id)
      insertElement{target=RuleNode, name='sch:assert', attr=E}
   end

   -- add should asserts - patterns in warning phase
   local WarnRuleId = ErrRuleId:gsub('errors', 'warnings')
   if sch.rule[WarnRuleId] then
      ProcessedWarns[WarnRuleId] = true
      local Asserts = sch.rule[WarnRuleId].assert
      for I = 1,#Asserts do
         local W = sch.assert[Asserts[I]]
         trace(W.id)
         -- add shall asserts - patterns in error phase
         insertElement{target=RuleNode, name='sch:assert', attr=W}
      end
   end
end

-- generate the schematron rules that are associated with a schematron pattern ID
-- @Param id : the error Pattern ID
local function addPatternRules(I)
   local Target = I.target
   local PatternId = I.id
	trace(PatternId)
   
   -- add all error rules and their corresponding warning rules
   local Rules = sch.pattern[PatternId]
   trace(Rules)
   local ProcessedWarns = {}
   for I = 1, #Rules do
      local RuleId = Rules[I]
      trace(RuleId)
      
      addPatternRule(RuleId, Target, ProcessedWarns)
   end
   
   -- NOTE: it is possible for a branch to only contain warnings.
   
   -- get the "leftover" warning rules
   local WarnPatternId, Count = PatternId:gsub('errors', 'warnings')
   if Count > 0 then
      trace(WarnPatternId)
      local WarnRules = sch.pattern[WarnPatternId]
      for I = 1, #WarnRules do
         local RuleId = WarnRules[I]
         trace(RuleId)
         if not ProcessedWarns[RuleId] then
            addPatternRule(RuleId, Target, ProcessedWarns)
         end
      end
   end
   
end


-- generate a new schematron XML tree whose assertions are re-ordered.
local function generateSCHtree()
   -- create root
   local SCH = xml.parse{data='<sch:schema/>'}["sch:schema"]
   -- set root attributes 
   setAttrAndText{target=SCH, attr=sch.meta}
   -- add namespaces
   addNamespaces{target=SCH}
   -- add phase
   local Phase = addElement(SCH, 'sch:phase')
   setAttr(Phase, 'id', 'errors')
   for _,J in pairs(sch.phase.errors) do
      setAttr(addElement(Phase, 'sch:active'), 'pattern', J)
   end
   trace(sch)
   -- add patterns
   -- the warning patterns will be merged with corresponding error patterns.
   -- if a warning pattern contains branch warning rules, the rules will be
   -- appended to the corresponding error pattern
   for _,P in pairs(sch.phase.errors) do
      trace(P)
      local ePattern = addElement(SCH, 'sch:pattern')
      setAttr(ePattern, 'id', P)
      addPatternRules{target=ePattern, id=P}
   end
   
   return SCH
end



-- ==================== schematron main function ====================

-- The purpose of formatSCH() is to reorder the schematron assertions
-- so that validation errors are presented in the natural order, the
-- order the rules are presented in the Implementation Guide PDF file
local function formatSCH(FileSCH)

   -- load sch file into a lua table
   parseSCH(FileSCH)
   
   -- generate schematron
   return generateSCHtree()
end

return formatSCH