local utils = require 'ccda.utils'
local cfg = require 'ccda.configs'

local social = {}
-- Local Functions ---

-- Public Functions ---
function social.fillSocialHistory(sB)
   -- Create Social History Section
   local SocialHistorySection = {}
   -- Note: the content of Results Section must be wrapped in a 'section' element
   SocialHistorySection.section = {}
   do
      local RS = SocialHistorySection.section
      RS.templateId = {root='2.16.840.1.113883.10.20.22.2.17', extension='2015-08-01'}
      RS.code = {code="29762-2", codeSystem="2.16.840.1.113883.6.1", codeSystemName="LOINC", displayName="Social History"}
      RS.title = {Text = 'SOCIAL HISTORY'}
      RS.text = {
         Text = [[
         <table border="1" width="100%">
         <thead>
         <tr>
         <th>Social History Observation</th>
         <th>Description</th>
         <th>Dates Observed</th>
         </tr>
         </thead>
         <tbody>
         <tr>
         <td>Current Smoking Status</td>
         <td>Former smoker</td>
         <td>September 10, 2012</td>
         </tr>
         <tr>
         <td>Tobacco Use</td>
         <td>Moderate cigarette smoker, 10-19/day</td>
         <td>February, 2009 - February, 2011</td>
         </tr>
         <tr>
         <td>Alcoholic drinks per day</td>
         <td>12</td>
         <td>Since February, 2012</td>
         </tr>
         </tbody>
         </table>
         ]]
      }
      RS.entry = {typeCode="DRIV"}
      RS.entry.observation = {classCode="OBS", moodCode="EVN"}
      do
         local RO = RS.entry.observation
         RO.templateId = {root='2.16.840.1.113883.10.20.22.4.78',extension='2014-06-09'}
         RO.id = {extension="123456789", root="2.16.840.1.113883.19"}
         RO.code = {code="72166-2", codeSystem="2.16.840.1.113883.6.1", codeSystemName="LOINC", displayName="Tobacco smoking status NHIS"}
         RO.statusCode = {code="completed"}
         -- TODO: to be removed
         if cfg.CCDAVersion == "R2_1" then
            RO.value = utils.copyTable(voc["Current Smoking Status"]["Former smoker"])
            RO.value['xsi:type']="CD"
         end
         RO.effectiveTime = {value="20120910"}
      end
   end
   -- Add SocialHistorySection Section to structureBody
   table.insert(sB.component, SocialHistorySection)
end

return social