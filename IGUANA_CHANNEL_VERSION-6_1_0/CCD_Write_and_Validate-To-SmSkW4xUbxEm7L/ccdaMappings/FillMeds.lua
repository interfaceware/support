local med = {}
-- Local Functions ---

--- Public Functions ---
function med.fillMedications(sB, MedsData)
   local Meds = {}

   for row = 1,#MedsData do
      Meds[row] = {}
      for column = 1,#MedsData[1] do
         Meds[row][column] = 1
      end
   end

   local rowLength = #MedsData[1]
   local tableLength = #MedsData

   for i=1,tableLength do
      for j=1,rowLength do

         Meds[i][j] = MedsData[i][j]

         if Meds[i][j]:nodeValue() == "" then
            Meds[i][j] = '00000'
         end

      end
   end

   trace(Meds)

   -- Create Medications Section
   local MedicationsSection = {}

   -- Note: the content of Medications Section must be wrapped in a 'section' element
   MedicationsSection.section = {}
   do
      local MS = MedicationsSection.section
      MS.templateId = {root='2.16.840.1.113883.10.20.22.2.1.1'}
      MS.code = {}
      MS.code = voc.LOINC["History of Medication Use"]
      MS.title = {Text='Medications'}
      MS.text = {         Text = [[         ]]      }

      if MedsData[1]:isNull() then
         MedicationsSection.section.nullFlavor = 'NI'
         table.insert(nonValidErr,'6274')

      else
         MS.entry = {}
         for i=1,#Meds do
            local M = {}
            M.substanceAdministration = {}
            do
               local MAE = M.substanceAdministration
               MAE.templateId = {root='2.16.840.1.113883.10.20.22.4.16'}
               MAE.classCode = 'SBADM'
               MAE.moodCode = 'EVN'
               MAE.id = {}
               MAE.id = {root=generateGUID()}
               MAE.text = {
                  Text = ''
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
               eT.low = {value = Meds[i][11]:nodeValue():gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%1%2")}
               eT.high = {nullFlavor='UNK'}
               table.insert(MAE.effectiveTime, eT)
               eT = {}
               eT['xsi:type']='PIVL_TS'
               eT.operator = 'A'
               eT.period = {value = '12', unit='h'}
               table.insert(MAE.effectiveTime, eT)

               MAE.consumable = {}
               do
                  local c = MAE.consumable

                  c.manufacturedProduct = {}
                  c.manufacturedProduct.templateId = {root = '2.16.840.1.113883.10.20.22.4.23'}
                  c.manufacturedProduct.classCode = 'MANU'
                  c.manufacturedProduct.manufacturedMaterial = {}
                  -- The code value we want is not in voc, so we will manually type it in.
                  c.manufacturedProduct.manufacturedMaterial.code = {
                     code = "573621", codeSystem="2.16.840.1.113883.6.88",
                     displayName=Meds[i][6],
                     codeSystemName='Medication Clinical Drug Name Value Set'
                  }
                  c.manufacturedProduct.manufacturedMaterial.code.originalText = {
                     Text = ''
                  }
               end
            end

            table.insert(MS.entry, M)
         end
      end
      -- Add Medications Section to structureBody
      table.insert(sB.component, MedicationsSection)
   end
end

return med