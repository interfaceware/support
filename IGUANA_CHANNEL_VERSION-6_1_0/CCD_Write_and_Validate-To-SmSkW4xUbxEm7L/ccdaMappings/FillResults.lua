local result = {}
-- Local Functions ---

--- Public Functions ---
function result.fillResults(sB, LabsData)
   local Labs = {}

   for row = 1,#LabsData do
      Labs[row] = {}
      for column = 1,#LabsData[1] do
         Labs[row][column] = 1
      end
   end

   local rowLength = #LabsData[1]
   local tableLength = #LabsData

   for i=1,tableLength do
      for j=1,rowLength do

         Labs[i][j] = LabsData[i][j]

         if Labs[i][j] == "" then
            Labs[i][j] = '00000'
         end

      end
   end
   
   -- Create Results Section
   local ResultsSection = {}

      -- Note: the content of Results Section must be wrapped in a 'section' element
      ResultsSection.section = {}
      do
         local RS = ResultsSection.section
         RS.templateId = {root='2.16.840.1.113883.10.20.22.2.3.1'}
         RS.code = {}
         RS.code = voc.LOINC["Relevant Diagnostic Tests and/or Laboratory Data"]
         RS.title = {Text = 'RESULTS'}
         RS.text = {
            Text = ""
         }

      if LabsData[1]:isNull() then 
         ResultsSection.section.nullFlavor = 'NI'
         table.insert(nonValidErr,'7112')
   
      else

         RS.entry = {} --NEED TO HAVE ONE ENTRY FOR EACH TEST       
         
         for i=1,#Labs do

            local R = {}
            R.organizer = {}

            do
               local RO = R.organizer
               RO.templateId = {root='2.16.840.1.113883.10.20.22.4.1'}
               -- classCode should be CLUSTER or BATTERY
               RO.classCode = 'BATTERY'
               RO.moodCode = 'EVN'
               RO.statusCode = {}
               RO.id = {}
               RO.id = {root=generateGUID()}
               RO.code = {}
               RO.statusCode = voc["Result Status"].completed              
               
               RO.code = {
                  code=Labs[i][15], codeSystem="2.16.840.1.113883.6.1",
                  displayName=Labs[i][14], codeSystemName="LOINC"
               }
               
               if Labs[i][15]:nodeValue() == '' then
                  RO.code = fillNullFlavor()
               end
               
               RO.component = {}
               RO.component.observation = {}
               do
                  local RO = RO.component.observation
                  RO.templateId = {root='2.16.840.1.113883.10.20.22.4.2'}
                  RO.classCode = 'OBS'
                  RO.moodCode = 'EVN'
                  RO.id = {}
                  RO.id = {root=generateGUID()}
                  RO.code = {}
                  RO.code = {
                     code=Labs[i][15], codeSystem="2.16.840.1.113883.6.1",
                     displayName=Labs[i][14], codeSystemName="LOINC"
                  }
                  
                  if Labs[i][15]:nodeValue() == '' then
                     RO.code = fillNullFlavor()
                  end
                  
                  RO.text = {
                     Text = ''
                  }
                  RO.statusCode = {}
                  -- Alternative : RO.statusCode = {code='completed'}
                  trace(voc["Result Status"].completed)
                  RO.statusCode = voc["Result Status"].completed
                  RO.effectiveTime = {}
                  RO.effectiveTime.low = {value = Labs[i][5]:nodeValue():gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%1%2")}
                  RO.effectiveTime.high = {value = Labs[i][6]:nodeValue():gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%1%2")}
                  --RO.effectiveTime = fillNullFlavor()
                  RO.value = {}

                  local val = Labs[i][16]:nodeValue()
                  local uni = Labs[i][17]:nodeValue()
                  
                  if uni == '' then
                     uni = 'NO_UNIT'
                  end               
                  
                  RO.value = {
                     ['xsi:type']="PQ", value=val, unit=uni
                  }
                  
                  if uni:match('%%') ~= nil then
                     RO.value = {['xsi:type']="ST", Text=val..' '..uni}
                     end
                  
                  if val == '' then
                     RO.value = {['xsi:type']="ST", Text='NO VALUE'}
                     end
                  
                  if val:match("%a+") ~= nil then
                     RO.value = {['xsi:type']="ST", Text=val}
                     end
                  
                  if val:match(" ") ~= nil then
                     RO.value = {['xsi:type']="ST", Text=val}
                     end
                  
                  if val:match("-") ~= nil then
                     RO.value = {['xsi:type']="ST", Text=val}
                     end 
                  
                   if val:match("+") ~= nil then
                     RO.value = {['xsi:type']="ST", Text=val}
                     end 
                  
                  if val:match("<") ~= nil 
                     or val:match(">") ~= nil 
                     or val:match("=") ~= nil 
                     or val:match("@") ~= nil  then
                     
                     if val:match("<") ~= nil then val = val:gsub('<','less than ')
                        elseif val:match(">") ~= nil then val = val:gsub('>','greater than ')
                     end
                     
                     RO.value = {['xsi:type']="ST", Text=val..' '..uni}
                  end
                  
                  --[[
                  Some Lab Results were listed as "<1.00" but the Value element
                  for type PQ only accepts decimal or double type entries, "<" is not
                  allowed. To account for the "<" character, the type was changed to ST
                  and the value and unit were concatenated into one string.
                  --]]                
                  
                  RO.referenceRange = {}
                  RO.referenceRange.observationRange = {}
                  
                  local range = Labs[i][18]:nodeValue()
                  
                  if range:match('<') == '<' then
                     range = range:gsub('<','less than ')
                  elseif range:match('>') == '>' then
                     range = range:gsub('>','greater than ')
                  end
                  
                  RO.referenceRange.observationRange.text = {
                     Text = range
                  }
                
                  RO.interpretationCode = {}
                  RO.interpretationCode = {code="N", codeSystem="2.16.840.1.113883.5.83"}
               end
               table.insert(RS.entry, R)
            end
         end
         -- Add ResultsSection Section to structureBody        
      end
   end
   table.insert(sB.component, ResultsSection)
end
return result