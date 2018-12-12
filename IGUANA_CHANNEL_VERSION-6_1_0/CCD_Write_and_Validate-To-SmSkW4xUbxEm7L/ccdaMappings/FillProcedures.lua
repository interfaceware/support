local procedure = {}
-- Local Functions ---

function generateGUID()

   return util.guid(136):gsub("(%w%w%w%w%w%w%w%w)(%w%w%w%w)(%w%w%w%w)(%w%w%w%w)(%w%w%w%w%w%w%w%w%w%w%w%w)%w%w", "%1-%2-%3-%4-%5")

end


function fillNullFlavor(conf)

   table.insert(nonValidErr,conf)
   local nullF = {nullFlavor = 'NI'}

   return nullF
end

--- Public Functions ---
function procedure.fillProcedures(sB, ProceduresData)

   local Procedures = {}


   for row = 1,#ProceduresData do
      Procedures[row] = {}
      for column = 1,#ProceduresData[1] do
         Procedures[row][column] = 1
      end
   end


   local rowLength = #ProceduresData[1]
   local tableLength = #ProceduresData

   for i=1,tableLength do
      for j=1,rowLength do

         Procedures[i][j] = ProceduresData[i][j]

         if Procedures[i][j]:nodeValue() == '' then
            Procedures[i][j] = '00000'

         end
      end
   end


   -- Create Procedures Section
   local ProceduresSection = {}

   local uniqueID = generateGUID()

   -- Note: the content of Procedures Section must be wrapped in a 'section' element
   ProceduresSection.section = {}
   do
      local PS = ProceduresSection.section
      PS.templateId = {root='2.16.840.1.113883.10.20.22.2.7.1'}
      PS.code = {}
      PS.code = voc.LOINC["History of Procedures"]
      PS.title = {Text = 'History of Procedures'}
      PS.text = {Text = ''}

      -- PS.nullFlavor = 'NI'

      if ProceduresData[1]:isNull() then
         ProceduresSection.section.nullFlavor = 'NI'
         table.insert(nonValidErr,'6274')

      else


         PS.entry = {}

         for i=1,#Procedures do
            local Pr = {}
            Pr.procedure = {}

            do
               local P = Pr.procedure
               -- Again, Procedure is optional, so validation does not check clasCode and moodCode
               P.classCode = 'PROC'
               P.moodCode = 'EVN'
               P.templateId = {root='2.16.840.1.113883.10.20.22.4.14'}
               P.id = {}
               P.id = {extension="1111", root=uniqueID}
               P.code = {}
               P.code = {
                  code=Procedures[i][3]:nodeValue(), codeSystem="2.16.840.1.113883.6.12",
                  displayName="N/A", codeSystemName="CPT"
               }
               P.code.originalText = {
                  Text=''
               }
               P.statusCode = voc["ProcedureAct statusCode"].Completed
               P.effectiveTime = {}
               P.effectiveTime.value = Procedures[i][4]:nodeValue():gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%1%2")

               table.insert(PS.entry,Pr)
            end

         end
         trace(PS.entry)
         -- Add Procedures Section to structureBody
         table.insert(sB.component, ProceduresSection)

      end
      trace(sB.component)
   end
end

return procedure