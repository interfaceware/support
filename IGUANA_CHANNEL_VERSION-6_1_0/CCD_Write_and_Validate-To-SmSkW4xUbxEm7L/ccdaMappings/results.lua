local results = {}
-- Local Functions ---

-- Public Functions ---
function results.fillResults(sB)
   -- Create Results Section
   local ResultsSection = {}
   -- Note: the content of Results Section must be wrapped in a 'section' element
   ResultsSection.section = {}
   do
      local RS = ResultsSection.section
      RS.templateId = {root='2.16.840.1.113883.10.20.22.2.3.1', extension='2015-08-01'}
      RS.code = {}
      RS.code = voc.LOINC["Relevant Diagnostic Tests and/or Laboratory Data"]
      RS.title = {Text = 'RESULTS'}
      RS.text = {
         Text = [[
         <table border="1" width="100%">
         <thead>
         <tr>
         <th colspan="2">LABORATORY INFORMATION</th>
         </tr>
         <tr>
         <th colspan="2">Blood chemistry</th>
         </tr>
         </thead>
         <tbody>
         <tr>
         <td>
         <content ID="result1">HGB 12-16	g/dl</content>
         </td>
         <td>10.2 on 2012-08-10</td>
         </tr>
         </tbody>
         </table>
         ]]
      }
      RS.entry = {}
      RS.entry.organizer = {}
      do
         local RO = RS.entry.organizer
         RO.templateId = {root='2.16.840.1.113883.10.20.22.4.1',extension='2015-08-01'}
         -- classCode should be CLUSTER or BATTERY
         RO.classCode = 'BATTERY'
         RO.moodCode = 'EVN'
         RO.statusCode = {}
         RO.id = {}
         RO.id = {root="107c2dc0-67a5-11db-bd13-0800200c9a66"}
         RO.code = {}
         RO.statusCode = voc["Result Status"].completed
         RO.code = {
            code="43789009", codeSystem="2.16.840.1.113883.6.96",
            displayName="CBC WO DIFFERENTIAL", codeSystemName="SNOMED CT"
         }         
         RO.component = {}
         RO.component.observation = {}
         do
            local RO = RO.component.observation
            RO.templateId = {root='2.16.840.1.113883.10.20.22.4.2',extension='2015-08-01'}
            RO.classCode = 'OBS'
            RO.moodCode = 'EVN'
            RO.id = {}
            RO.id = {root="7d5a02b0-67a4-11db-bd13-0800200c9a66"}
            RO.code = {}
            RO.code = {
               code="30313-1", codeSystem="2.16.840.1.113883.6.1",
               displayName="HGB", codeSystemName="LOINC"
            }
            RO.text = {
               Text = '<reference value="#result1"/>'
            }
            RO.statusCode = {}
            -- Alternative : RO.statusCode = {code='completed'}
            trace(voc["Result Status"].completed)
            RO.statusCode = voc["Result Status"].completed
            RO.effectiveTime = {}
            RO.effectiveTime = {value="200003231430"}
            RO.value = {}
            RO.value = {
               ['xsi:type']="PQ", value="13.2", unit="g/dl"
            }
            RO.referenceRange = {}
            RO.referenceRange.observationRange = {}
            RO.referenceRange.observationRange.value = {
               ['xsi:type'] = "IVL_PQ",
               low = { value="12.0", unit="g/dL"},
               high = { value="15.5", unit="g/dL"}
            }
            RO.interpretationCode = {}
            RO.interpretationCode = {code="N", codeSystem="2.16.840.1.113883.5.83"}
         end
      end
   end
   -- Add ResultsSection Section to structureBody
   table.insert(sB.component, ResultsSection)
end

return results