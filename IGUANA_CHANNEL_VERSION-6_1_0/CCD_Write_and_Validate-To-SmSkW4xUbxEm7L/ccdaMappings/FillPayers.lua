local payer = {}
-- Local Functions ---

--- Public Functions ---
function payer.fillPayers(sB, PayersData)

   local uniqueID = generateGUID()
   local Pay = {}

   for row = 1,#PayersData do
      Pay[row] = {}
      for column = 1,#PayersData[1] do
         Pay[row][column] = 1
      end
   end

   local rowLength = #PayersData[1]
   local tableLength = #PayersData

   for i=1,tableLength do
      for j=1,rowLength do

         Pay[i][j] = PayersData[i][j]:nodeValue()

         if Pay[i][j] == "" then
            Pay[i][j] = '00000'
         end
      end
   end

   local PayersSection = {}

   PayersSection.section = {}

   do
      local PS = PayersSection.section
      PS.templateId = {root = '2.16.840.1.113883.10.20.22.2.18'}
      PS.code = {}
      PS.code = voc.LOINC["Payment Sources"]
      PS.title = {Text="Payment Sources"}
      PS.text = {Text = ""}

      if PayersData[1]:isNull() then
         PayersSection.section.nullFlavor = 'NI'

      else

         PS.entry = {}
         --COVERAGE ACTIVITY SECTION
         for i=1,#Pay do

            local P = {}
            P.act = {}

            do
               p = P.act
               p.templateId = {root = '2.16.840.1.113883.10.20.22.4.60'}
               p.classCode = 'ACT'
               p.moodCode = 'EVN'
               p.id = {}

               if Pay[i][5] == '00000' then
                  p.id = fillNullFlavor()
               else
                  --p.id = {root = generateGUID(), extension = Pay[i][5]} --SUBSCRIBER MEMBER ID
                  p.id.root = generateGUID()
                  p.id.extension = Pay[i][5]
               end
               p.code = {}
               p.code = voc.LOINC["Payment Sources"]
               p.statusCode = {}
               p.statusCode = {code = "completed"}

               p.entryRelationship = {}
               p.entryRelationship.typeCode = 'COMP'
               p.entryRelationship.act = {}

               --POLICY ACTIVITY SECTION
               do
                  local peRa = p.entryRelationship.act
                  peRa.templateId = {root= '2.16.840.1.113883.10.20.22.4.61'}
                  peRa.classCode = 'ACT'
                  peRa.moodCode = 'EVN'
                  peRa.id = {}

                  if Pay[i][7] == '00000' then
                     peRa.id = fillNullFlavor()
                  else
                     -- peRa.id = {root = generateGUID(), extension = Pay[i][7]} --GROUP NUMBER
                     peRa.id.root = generateGUID()
                     peRa.id.extension = Pay[i][7]
                  end
                  peRa.code = fillNullFlavor()
                  peRa.statusCode = {}
                  peRa.statusCode.code = 'completed'

                  peRa.performer = {}
                  peRa.performer.typeCode = 'PRF'
                  peRa.performer.templateId = {root = '2.16.840.1.113883.10.20.22.4.87'}

                  peRa.performer.assignedEntity = {}
                  local ppa = peRa.performer.assignedEntity
                  ppa.id = {root = '2.16.840.1.113883.19'}

                  peRa.participant = {}
                  local pp = peRa.participant

                  pp.typeCode = 'COV'
                  pp.templateId = {root = '2.16.840.1.113883.10.20.22.4.89'}
                  pp.participantRole = {}
                  pp.participantRole.id = {root = generateGUID()}

                  pp.value = {['xsi:type']='CE'}

                  peRa.entryRelationship = {}
                  peRa.entryRelationship.typeCode = 'REFR'
                  peRa.entryRelationship.act = {}

                  local PRA = peRa.entryRelationship.act
                  PRA.classCode = 'ACT'
                  PRA.moodCode = 'EVN'
                  PRA.id = {}

                  if Pay[i][7] == '00000' then
                     PRA.id = fillNullFlavor()
                  else
                     --PRA.id = {root = generateGUID(), extension = Pay[i][7]}
                     PRA.id.root = generateGUID()
                     PRA.id.extension = Pay[i][7]
                  end

                  PRA.code = fillNullFlavor()
                  PRA.templateId = {root = '2.16.840.1.113883.10.20.1.19'}
                  PRA.entryRelationship = fillNullFlavor()
                  PRA.entryRelationship.typeCode = 'SUBJ'
                  PRA.entryRelationship.procedure = {}

                  local PEP = PRA.entryRelationship.procedure
                  PEP.classCode = 'PROC'
                  PEP.moodCode = 'PRMS'
                  PEP.code = fillNullFlavor()


                  pp.participantRole.code = fillNullFlavor()
               end
               table.insert(PS.entry, P)
            end
         end
      end
      table.insert(sB.component, PayersSection)
   end
end

return payer