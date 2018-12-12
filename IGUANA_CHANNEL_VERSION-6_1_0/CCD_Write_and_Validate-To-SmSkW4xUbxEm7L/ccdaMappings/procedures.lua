local procedures = {}
-- Local Functions ---

-- Public Functions ---
function procedures.fillProcedures(sB)
   -- Create Procedures Section
   local ProceduresSection = {}
   -- Note: the content of Procedures Section must be wrapped in a 'section' element
   ProceduresSection.section = {}
   do
      local PS = ProceduresSection.section
      PS.templateId = {root='2.16.840.1.113883.10.20.22.2.7.1'}
      PS.code = {}
      PS.code = voc.LOINC["History of Procedures"]
      PS.title = {Text = 'History of Procedures'}
      PS.text = {
         Text = [[
         <table border="1" width="100%">
         <thead>
         <tr>
         <th>Procedure</th>
         <th>Date</th>
         </tr>
         </thead>
         <tbody>
         <tr>
         <td>
         <content ID="Proc2">Chest X-Ray</content>
         </td>
         <td>2012</td>
         </tr>
         </tbody>
         </table>
         ]]
      }

      PS.entry = {}
      PS.entry.procedure = {}
      do
         local P = PS.entry.procedure
         -- Again, Procedure is optional, so validation does not check clasCode and moodCode
         P.classCode = 'PROC'
         P.moodCode = 'EVN'
         P.templateId = {root='2.16.840.1.113883.10.20.22.4.14'}
         P.id = {}
         P.id = {extension="123456789", root="2.16.840.1.113883.19"}
         P.code = {}
         P.code = {
            code="168731009", codeSystem="2.16.840.1.113883.6.96",
            displayName="Chest X-Ray", codeSystemName="SNOMED-CT"
         }
         P.code.originalText = {
            Text='<reference value="#Proc2"/>'
         }
         P.statusCode = voc["ProcedureAct statusCode"].Completed
         P.effectiveTime = {}
         P.effectiveTime.value = '20120806'
         P.priorityCode = {
            code="CR", codeSystem="2.16.840.1.113883.5.7",
            codeSystemName="ActPriority", displayName="Callback results"
         }
         P.targetSiteCode = {}
         P.targetSiteCode = {
            code="82094008", codeSystem="2.16.840.1.113883.6.96",
            codeSystemName="SNOMED CT", displayName="Lower Respiratory Tract Structure"
         }

         P.performer = {}
         P.performer.assignedEntity = {}
         do
            local AE = P.performer.assignedEntity
            AE.id = {}
            AE.id = {root="2.16.840.1.113883.19.5", extension="1234"}
            AE.addr = {}
            AE.addr = {
               ['streetAddressLine'] = {Text = '1002 Healthcare Drive'},
               ['city'] = {Text = 'Portland'},
               ['state'] = {Text = 'OR'},
               ['country'] = {Text = 'US'},
               ['postalCode'] = {Text = '97266'}
            }
            AE.telecom = {}
            AE.telecom = {use='WP', value='(314)159-265-3589'}
            AE.representedOrganization = {}
            AE.representedOrganization.id = {}
            AE.representedOrganization.id = {root="2.16.840.1.113883.19.5"}
            AE.representedOrganization.addr = {nullFlavor="UNK"}
            AE.representedOrganization.telecom = {}
            AE.representedOrganization.telecom = {nullFlavor="UNK"}
            -- The name element of organization has a text element
            AE.representedOrganization.name = {
               Text='Get Well Radiology'
            }
         end
      end
   end
   -- Add Procedures Section to structureBody
   table.insert(sB.component, ProceduresSection)
end

return procedures