local vital = {}
-- Local Functions ---

--- Public Functions ---
function vital.fillVitals(sB, VitalsData)

   local Vitals = {}

   for row = 1,#VitalsData do
      Vitals[row] = {}
      for column = 1,#VitalsData[1] do
         Vitals[row][column] = 1
      end
   end

   local rowLength = #VitalsData[1]
   local tableLength = #VitalsData

   for i=1,tableLength do
      for j=1,rowLength do

         Vitals[i][j] = VitalsData[i][j]:nodeValue()

         if Vitals[i][j] == "" then
            Vitals[i][j] = '00000'
         end

      end
   end

   local VitalsSection = {}

   VitalsSection.section = {}

   do
      local VS = VitalsSection.section
      VS.templateId = {root = "2.16.840.1.113883.10.20.22.4.1"}
      VS.code = {}
      VS.code = voc.LOINC["VITAL SIGNS"]
      VS.title = {Text = "VITAL SIGNS"}
      VS.text = {Text=""}

      if VitalsData[1]:isNull() then
         VitalsSection.section.nullFlavor = 'NI'

      else

         VS.entry = {}

         for i=1,#Vitals do

            local V = {}
            V.organizer = {}

            do
               local VO = V.organizer
               VO.templateId = {root = "2.16.840.1.113883.10.20.22.4.26"}
               VO.classCode = "CLUSTER"
               VO.moodCode = "EVN"
               VO.id = {}
               VO.id = {root = generateGUID()}
               VO.code = {}
               VO.code = {code="46680005", codeSystem="2.16.840.1.113883.6.96", displayName="Vital Signs", codeSystemName="SNOMED CT"}
               VO.statusCode = {}
               VO.statusCode = {code = "completed"}
               VO.effectiveTime = fillNullFlavor()

               VO.component = {}

               componentTemplate = {}
               componentTemplate.observation = {}
               local CTO = componentTemplate.observation
               CTO.templateId = {root = "2.16.840.1.113883.10.20.22.4.27"}
               CTO.classCode = 'OBS'
               CTO.moodCode = "EVN"
               CTO.id = {}
               CTO.id = {root = generateGUID()}
               CTO.code = fillNullFlavor()
               CTO.statusCode = {}
               CTO.statusCode = {code = "completed"}
               CTO.value = {['xsi:type'] = 'PQ', nullFlavor = 'NI'}
               CTO.effectiveTime = {value = Vitals[i][7]:gsub("(%d%d%d%d)-(%d%d)-(%d%d)", "%1%2%3")}

               for j=8,14 do
                  do

                     local temp = copyTable(componentTemplate)

                     local VitalSignType = ""
                     local VitalSignName = ""

                     if j==8 then

                        local Systolic = ''
                        local Diastolic = ''
                        local BP = Vitals[i][j]
                        BP = BP:split('/')

                        temp.observation.code = {code = '8480-6' , codeSystem = "2.16.840.1.113883.3.88.12.80.62", displayName = 'BP Systolic', codeSystemName = "LOINC"}

                        if Vitals[i][j] ~= '' then
                           temp.observation.value = {['xsi:type'] = 'PQ', value = BP[1]}
                        end

                        table.insert(VO.component, temp)
                        local temp = copyTable(componentTemplate)
                        temp.observation.code = {code = '8462-4' , codeSystem = "2.16.840.1.113883.3.88.12.80.62", displayName = 'BP Diastolic', codeSystemName = "LOINC"}

                        if Vitals[i][j] ~= '' then
                           temp.observation.value = {['xsi:type'] = 'PQ', value = BP[2]}
                        end
                        table.insert(VO.component,temp)
                        trace(VO.component)

                     elseif j==9 then                        

                        local val = Vitals[i][j]

                        if val:match(",") ~= nil then
                           val = val:gsub(",",".")
                        end

                        VitalSignType = "8310-5" -- Body Temperature
                        VitalSignName = "Temp"
                        temp.observation.code = {code = VitalSignType, codeSystem = "2.16.840.1.113883.3.88.12.80.62", displayName = VitalSignName, codeSystemName = "LOINC"}
                        if Vitals[i][j] ~= '' then
                           temp.observation.value = {['xsi:type'] = 'PQ', value = val}
                        end
                        table.insert(VO.component,temp)
                        trace(VO.component)

                     elseif j==10 then
                        VitalSignType = "9279-1" -- Respiratory Rate
                        VitalSignName = "RR"
                        temp.observation.code = {code = VitalSignType, codeSystem = "2.16.840.1.113883.3.88.12.80.62", displayName = VitalSignName, codeSystemName = "LOINC"}
                        if Vitals[i][j] ~= '' then
                           temp.observation.value = {['xsi:type'] = 'PQ', value = Vitals[i][j]}
                        end

                        table.insert(VO.component,temp)
                     elseif j==11 then
                        VitalSignType = "8867-4" -- Pulse
                        VitalSignName = "Pulse"
                        temp.observation.code = {code = VitalSignType, codeSystem = "2.16.840.1.113883.3.88.12.80.62", displayName = VitalSignName, codeSystemName = "LOINC"}
                        if Vitals[i][j] ~= '' then
                           temp.observation.value = {['xsi:type'] = 'PQ', value = Vitals[i][j]}
                        end
                        table.insert(VO.component,temp)
                     elseif j==12 then
                        VitalSignType = "3141-9" -- Weight
                        VitalSignName = "Weight"
                        temp.observation.code = {code = VitalSignType, codeSystem = "2.16.840.1.113883.3.88.12.80.62", displayName = VitalSignName, codeSystemName = "LOINC"}
                        if Vitals[i][j] ~= '' then
                           temp.observation.value = {['xsi:type'] = 'PQ', value = Vitals[i][j]}
                        end
                        table.insert(VO.component, temp)
                     elseif j==13 then
                        VitalSignType = "8302-2" -- Height
                        VitalSignName = "Height"
                        temp.observation.code = {code = VitalSignType, codeSystem = "2.16.840.1.113883.3.88.12.80.62", displayName = VitalSignName, codeSystemName = "LOINC"}
                        if Vitals[i][j] ~= '' then
                           temp.observation.value = {['xsi:type'] = 'PQ', value = Vitals[i][j]}
                        end                          
                        table.insert(VO.component,temp)
                     elseif j==14 then
                        VitalSignType = "39156-5" -- BMI
                        VitalSignName = "BMI"
                        temp.observation.code = {code = VitalSignType, codeSystem = "2.16.840.1.113883.3.88.12.80.62", displayName = VitalSignName, codeSystemName = "LOINC"}
                        if Vitals[i][j] ~= '' then
                           temp.observation.value = {['xsi:type'] = 'PQ', value = Vitals[i][j]}
                        end                           
                        table.insert(VO.component,temp)
                     end
                  end
               end
               table.insert(VS.entry, V)
            end
         end
      end
      table.insert(sB.component, VitalsSection)
   end
end

return vital