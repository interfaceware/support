local utils = require 'ccda.utils'
local cfg = require 'ccda.configs'

local problems = {}
-- Local Functions ---

-- Public Functions ---
function problems.fillProblems(sB)
   -- Create Problem Section
   local ProblemSection = {}
   -- Note: the content of Problem Section must be wrapped in a 'section' element
   ProblemSection.section = {}
   do
      local PS = ProblemSection.section
      PS.templateId = {root = '2.16.840.1.113883.10.20.22.2.5.1', extension='2015-08-01'}
      PS.code = {}
      PS.code = voc.LOINC["Problem List"]
      PS.title = {Text = 'PROBLEMS'}
      PS.text = {
         Text = [[
         <content ID="problems"/>
         <list listType="ordered">
         <item>
         <content ID="problem1">Pneumonia (age at onset 65): Status - Active
         <br />
         Health status: Moribund
         </content>
         </item>
         <item>
         <content ID="problem2">Asthma (age at onset 60): Status - Active
         <br />
         Health status: Severly Ill</content>
         </item>
         </list>
         ]]
      }
      PS.entry = {}
      PS.entry.act = {}
      do
         local PCA = PS.entry.act
         PCA.templateId = {root='2.16.840.1.113883.10.20.22.4.3', extension='2015-08-01'}
         PCA.classCode = 'ACT'
         PCA.moodCode = 'EVN'
         PCA.id = {}
         PCA.id = {root="ab1791b0-5c71-11db-b0de-0800200c9a66"}
         PCA.code = {}
         PCA.code = {
            code="CONC", codeSystem="2.16.840.1.113883.5.6",
            displayName="Concern", codeSystemName='HL7ActClass'
         }
         PCA.statusCode = voc["ProblemAct statusCode"].Active
         PCA.effectiveTime = {}
         PCA.effectiveTime.low = {value = '20120806'}
         PCA.effectiveTime.high = {value = '20120808'}

         PCA.entryRelationship = {}
         PCA.entryRelationship.typeCode = 'SUBJ'
         PCA.entryRelationship.observation = {}
         do
            local PO = PCA.entryRelationship.observation

            PO.templateId = {root='2.16.840.1.113883.10.20.22.4.4', extension='2015-08-01'}
            PO.classCode = 'OBS'
            PO.moodCode = 'EVN'
            PO.id = {root="ec8a6ff8-ed4b-4f7e-82c3-e98e58b45de7"}
            -- make a copy before adding the translation to avoid modifying voc table
            PO.code = utils.copyTable(voc["Problem Type"]["Complaint HL7.CCDAR2"])
            -- TODO: to be removed
            if cfg.CCDAVersion == "R2_1" then
               PO.code.translation = voc["Problem Type"]["Complaint HL7.CCDAR2"]
            end
            --PO.code.translation = voc["Problem Type"]["Complaint HL7.CCDAR2"]
            --PO.text = {
            --   Text = '<reference value="#problem1"/>'
            --}
            PO.statusCode = {}
            PO.statusCode = {code = 'completed'}
            PO.effectiveTime = {}
            PO.effectiveTime.low = {value='20120806'}
            PO.effectiveTime.high = {value='20120808'}
            -- Special xsi:type element! Method 3 used
            PO.value = utils.copyTable(voc["Problem Value Set"]["Pneumonia (disorder)"])
            PO.value['xsi:type'] = 'CD'
         end
      end
   end
   -- Add Problem Section to structureBody
   table.insert(sB.component, ProblemSection)
end

return problems