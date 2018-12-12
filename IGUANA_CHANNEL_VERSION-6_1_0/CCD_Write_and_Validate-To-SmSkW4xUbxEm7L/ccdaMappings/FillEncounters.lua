local encounter = {}
-- Local Functions ---

--- Public Functions ---
function encounter.fillEncounters(sB, EncountersData)
   local Encounters = {}
   for row = 1,#EncountersData do
      Encounters[row] = {}
      for column = 1,#EncountersData[1] do
         Encounters[row][column] = 1
      end
   end

   local rowLength = #EncountersData[1]
   local tableLength = #EncountersData

   for i=1,tableLength do
      for j=1,rowLength do

         Encounters[i][j] = EncountersData[i][j]

         if Encounters[i][j]:nodeValue() == "" then
            Encounters[i][j] = '00000'
         end

      end
   end

   local EncountersSection = {}

   EncountersSection.section = {}

   local ES = EncountersSection.section

   ES.templateID = {root = '2.16.840.1.113883.10.20.22.2.22.1'}
   ES.code = {code = '46240-8', codeSystem = '2.16.840.1.113883.6.1', displayName = 'History of Encounters', codeSystemName = 'LOINC'}
   ES.title = {Text = "Encounters"}
   ES.text = {Text = ""}

   if EncountersData[1]:isNull() then
      EncountersSection.section.nullFlavor = 'NI'

   else
      ES.entry = {}

      for i=1,#Encounters do

         local E = {}
         E.encounter = {}

         do
            local e = E.encounter
            e.classCode = 'ENC'
            e.moodCode = 'EVN'
            e.id = {}
            e.id = {root = generateGUID()}
            local date = Encounters[i][4]:nodeValue()

            e.effectiveTime = {value = date:gsub('(%d%d)/(%d%d)/(%d%d%d%d)','%3%1%2') }

         end
         table.insert(ES.entry, E)
      end
   end
   table.insert(sB.component, EncountersSection)
end

return encounter