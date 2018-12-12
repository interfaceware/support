local vitals = {}
-- Local Functions ---

-- Public Functions ---
function vitals.fillVitals(sB)
   local VitalSignSection = {}
   -- Note: the content of vitals Section must be wrapped in a 'section' element
   VitalSignSection.section = {}
   do
      local RS = VitalSignSection.section
      RS.templateId = {root='2.16.840.1.113883.10.20.22.2.4.1', extension='2015-08-01'}
      RS.code = {code="8716-3", codeSystem="2.16.840.1.113883.6.1", codeSystemName="LOINC", displayName="VITAL SIGNS"}
      RS.title = {Text = 'VITAL SIGNS'}
      RS.text = {
         Text = [[
            <table border="1" width="100%">
               <thead>
                  <tr>
                     <th align="right">Date / Time: </th>
                     <th>Sept 10, 2012</th>
                     <th>Sept 1, 2011</th>
                  </tr>
               </thead>
               <tbody>
                  <tr>
                     <th align="left">Height</th>
                     <td ID="vit1">177 cm</td>
                     <td ID="vit2">177 cm</td>
                  </tr>
                  <tr>
                     <th align="left">Weight</th>
                     <td ID="vit3">86 kg</td>
                     <td ID="vit4">88 kg</td>
                  </tr>
                  <tr>
                     <th align="left">Blood Pressure</th>
                     <td ID="vit5">132/88</td>
                     <td ID="vit6">128/80</td>
                  </tr>
               </tbody>
            </table>
         ]]
      }
      RS.entry = {typeCode="DRIV"}
      RS.entry.organizer = {classCode="CLUSTER", moodCode="EVN"}
      do
         local RO = RS.entry.organizer
         RO.templateId = {root='2.16.840.1.113883.10.20.22.4.26',extension='2015-08-01'}
         RO.id = {extension="123456789", root="2.16.840.1.113883.19"}
         RO.code = {code="46680005", codeSystem="2.16.840.1.113883.6.96", codeSystemName="SNOMED CT", displayName="Vital signs"}
         RO.statusCode = {code="completed"}
         RO.effectiveTime = {value="20120910"}
         RO.component = {}
         RO.component.observation = {classCode="OBS", moodCode="EVN"}
         do
            local RCO = RO.component.observation
            RCO.templateId = {
               [1] = {root="2.16.840.1.113883.10.20.22.4.27", extension="2014-06-09"},
               [2] = {root="2.16.840.1.113883.10.20.22.4.27"}
            }
            RCO.id = {root="ed9589fd-fda0-41f7-a3d0-dc537554f5c2"}
            RCO.code = voc["Vital Sign Result Value Set"].Height
            RCO.statusCode = {code="completed"}
            RCO.effectiveTime = {value="20120910"}
            RCO.value = {['xsi:type']="PQ", value="177", unit="cm"}
            RCO.interpretationCode = {code="N", codeSystem="2.16.840.1.113883.5.83"}
         end
      end
   end
   -- Add vitals Section Section to structureBody
   table.insert(sB.component, VitalSignSection)
   end

return vitals 