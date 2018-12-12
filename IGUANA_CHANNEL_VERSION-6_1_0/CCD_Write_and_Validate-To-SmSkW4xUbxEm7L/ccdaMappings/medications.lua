local meds = {}
-- Local Functions ---

-- Public Functions ---
function meds.fillMedications(sB)
   local MedicationsSection = {}
   -- Note: the content of Medications Section must be wrapped in a 'section' element
   MedicationsSection.section = {}
   do
      local MS = MedicationsSection.section
      MS.templateId = {root='2.16.840.1.113883.10.20.22.2.1.1', extension='2014-06-09'}
      MS.code = {}
      MS.code = voc.LOINC["History of Medication Use"]
      MS.title = {Text='Medications'}
      MS.text = {
         Text = [[
         <table border="1" width="100%">
         <thead>
         <tr>
         <th>Medication</th>
         <th>Directions</th>
         <th>Start Date</th>
         <th>End Date</th>
         <th>Status</th>
         <th>Indications</th>
         <th>Fill Instructions</th>
         </tr>
         </thead>
         <tbody>
         <tr>
         <td><content ID="Med1">Albuterol 0.09 MG/ACTUAT[Proventil]</content></td>
         <td>0.09 MG/ACTUAT inhalant solution, 2 puffs once</td>
         <td>Unknown</td>
         <td>20120806</td>
         <td>Completed</td>
         <td>Asthma (195967001 SNOMED CT)</td>
         <td><content ID="FillIns" />
         <list listType="unordered">
         <item>Generic Substitition Allowed</item>
         <item>Label In Spanish</item>
         </list>
         </td>
         </tr>
         </tbody>
         </table>
         ]]
      }
      MS.entry = {}
      MS.entry.substanceAdministration = {}
      do
         local MAE = MS.entry.substanceAdministration
         MAE.templateId = {root='2.16.840.1.113883.10.20.22.4.16',extension='2014-06-09'}
         MAE.classCode = 'SBADM'
         MAE.moodCode = 'EVN'
         MAE.id = {}
         MAE.id = {root="cdbd33f0-6cde-11db-9fe1-0800200c9a66"}
         MAE.text = {
            Text = '<reference value="#Med1"/>0.09 MG/ACTUAT inhalant solution, 2 puffs'
         }
         MAE.statusCode = {}
         MAE.statusCode = {code="completed"}

         -- We have multiple instances of effective time here, so we need to put them in a correctly ordered array
         MAE.effectiveTime = {}
         local eT = {}
         -- Note : In 2015 Errata, the effectiveTime is update to support single-administration, in which case
         -- the timestamp is assigned to the value attribute of effectiveTime.
         --         eT.value = '20120806'
         -- To represents a medication duration, the type of effectiveTime may be change to IVL_TS
         eT['xsi:type'] = 'IVL_TS'
         -- Note: the following line demonstartes how to deal with required input that is unknown
         eT.low = {nullFlavor='UNK'}
         eT.high = {value="20120806"}
         table.insert(MAE.effectiveTime, eT)
         eT = {}
         eT['xsi:type']='PIVL_TS'
         eT.operator = 'A'
         eT.period = {value = '12', unit='h'}
         table.insert(MAE.effectiveTime, eT)
         MAE.author = {}
         MAE.author.templateId = {root="2.16.840.1.113883.10.20.22.4.119"}
         MAE.author.time = {value="20120806"}
         MAE.author.assignedAuthor = {}
         MAE.author.assignedAuthor.id = {root='2.16.840.1.113883.4.6'}
         MAE.routeCode = {}
         MAE.routeCode = voc["Medication Route FDA Value Set"].EPIDURAL
         MAE.doseQuantity = {
            value = '0.09',
            unit = 'mg/actuat'
         }
         MAE.rateQuantity = {
            value = '90',
            unit = 'ml/min'
         }
         MAE.consumable = {}
         do
            local c = MAE.consumable

            c.manufacturedProduct = {}
            c.manufacturedProduct.templateId = {root = '2.16.840.1.113883.10.20.22.4.23',extension='2014-06-09'}
            c.manufacturedProduct.classCode = 'MANU'
            c.manufacturedProduct.manufacturedMaterial = {}
            -- The code value we want is not in voc, so we will manually type it in.
            c.manufacturedProduct.manufacturedMaterial.code = {
               code = "573621", codeSystem="2.16.840.1.113883.6.88",
               displayName="Albuterol 0.09 MG/ACTUAT [Proventil]",
               codeSystemName='Medication Clinical Drug Name Value Set'
            }
            c.manufacturedProduct.manufacturedMaterial.code.originalText = {
               Text = '<reference value="#Med1"/>'
            }
         end
      end
   end
   -- Add Medications Section to structureBody
   table.insert(sB.component, MedicationsSection)
end

return meds