local allergy = {}
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
function allergy.fillAllergies(sB, AllergyData)

   local uniqueID = generateGUID()


   local Allergies = {}


   for row = 1,#AllergyData do
      Allergies[row] = {}
      for column = 1,#AllergyData[1] do
         Allergies[row][column] = 1
      end
   end

   local rowLength = #AllergyData[1]
   local tableLength = #AllergyData

   for i=1,tableLength do
      for j=1,rowLength do

         Allergies[i][j] = AllergyData[i][j]

         if Allergies[i][j]:nodeValue() == '' then
            Allergies[i][j] = '00000'

         end
      end
   end

   trace(Allergies)

   -- Create Allergies Section
   local AllergiesSection = {}

   -- Note: the content of Allergies Section must be wrapped in a 'section' element
   AllergiesSection.section = {}
   do
      local AS = AllergiesSection.section
      AS.templateId = { root = '2.16.840.1.113883.10.20.22.2.6.1' }
      AS.code = {}
      AS.code = voc.LOINC["Allergies, Adverse Reactions, Alerts"]
      AS.title = { Text = 'ALLERGIES, ADVERSE REACTIONS, ALERTS' }
      -- The text element below is for human readability (a HTML table)
      -- ccda.generation simply sets the innerHTML of the text elemment to the string value
      -- you assigned to the Text key.
      -- Note : If your data is in a XML tree (tableNode), you could use tableNode:S() to 
      -- convert it into a string.
      AS.text = {Text =''}
      -- The entry element below is for machine readability

      if AllergyData[1]:isNull() then
         AllergiesSection.section.nullFlavor = 'NI'
         table.insert(nonValidErr,'7531')
      else

         AS.entry = {}

         for i=1,#Allergies do
            local A = {}
            A.act = {}

            do
               local a = A.act
               a.templateId = { root = '2.16.840.1.113883.10.20.22.4.30' }
               a.classCode = "ACT"
               a.moodCode = "EVN"
               a.id = {}
               a.id = {
                  root=uniqueID,
                  extension="1000"
               }
               a.code = {}
               a.code = voc.LOINC["Allergies, Adverse Reactions, Alerts"]
               a.statusCode = {}
               a.statusCode = voc["ProblemAct statusCode"].Completed
               a.effectiveTime = {}
               a.effectiveTime.high = { value = '00000000' }
               a.effectiveTime.low = { value = tostring(Allergies[i][10]):gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%1%2") }
               a.entryRelationship = {}
               a.entryRelationship.typeCode = 'SUBJ'
               a.entryRelationship.observation = {}

               do
                  local o = a.entryRelationship.observation

                  o.templateId = {root='2.16.840.1.113883.10.20.22.4.7'}
                  o.classCode = 'OBS'
                  o.moodCode = 'EVN'
                  o.id = {}
                  o.id = {
                     root=uniqueID,
                     extension="1001"
                  }
                  o.code = {}
                  o.code = voc.ActCode.Assertion
                  o.statusCode = {}
                  o.statusCode.code = 'completed'
                  o.effectiveTime = {}
                  o.effectiveTime.low = {value='00000000'}
                  o.effectiveTime.high = {value=tostring(Allergies[i][10]):gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%1%2")}

                  -- Special xsi:type element!
                  -- If you recall, we could either directly assign a voc value set to o.value or we need to individually
                  -- assign each child element. However, we also have an additional attribute xsi:type="CD" in this case.
                  -- What this attribute does is to redefine the type of the value element. In other words, we now have a
                  -- type CD value element here (FYI, value's default type is ANY).
                  --
                  -- There are three ways to assign o.value
                  -- 1. add type definition then merge the voc code table into the o.value table
                  o.value = {['xsi:type']="CD"}
                  local Code = voc["Allergy/Adverse Event Type Value Set"]["Propensity to adverse reactions to drug (disorder)"]
                  --    Note: the order matters as we want to copy the key-value pairs of Code into o.value, not vice versa
                  CCDAmergeTable(Code, o.value)
                  -- 2. handcraft the entire table
                  --            o.value = {
                  --               ['xsi:type']='CD', code='419511003', codeSystem='2.16.840.1.113883.6.96', codeSystemName='SNOMED-CT',
                  --               displayName='Propensity to adverse reactions to drug (disorder)'
                  --            }
                  -- 3. assign a copy of the voc table to o.value then add ['xsi:type']="CD"
                  --    IMPORTANT : When modifying data in a voc table, one MUST operate on a copy of the table. 
                  --    Otherwise, the voc table will be forever changed.
                  --            o.value = copyTable(voc["Allergy/Adverse Event Type Value Set"]["Propensity to adverse reactions to drug (disorder)"])
                  --            o.value['xsi:type'] = "CD"

                  -- Note: that originalText is treated the same way as text: whatever is assigned to Text will be set as the
                  -- innerHTML of orginalText.
                  o.value.originalText = {
                     Text = ''
                  }

                  -- Add the machine readable code corresponding to the Substance entry of the HTML table
                  o.participant = {}
                  do
                     local p = o.participant
                     p.typeCode = 'CSM'
                     p.participantRole = {}
                     p.participantRole.classCode = 'MANU'
                     p.participantRole.playingEntity = {}
                     p.participantRole.playingEntity.classCode = 'MMAT'
                     p.participantRole.playingEntity.code = {}                

                     p.participantRole.playingEntity.code = {
                        code=Allergies[i][5], codeSystem="2.16.840.1.113883.6.88",
                        displayName=Allergies[i][6], codeSystemName="RxNorm"
                     }
                     -- Note: that original text is treated the same as text: whatever is assigned to Text will be used as
                     -- the innerHTML of orginalText.
                     p.participantRole.playingEntity.code.originalText = {
                        Text = ''
                     }
                  end

                  -- Note: we need to have an array of entryRelationships corresponding to the human readable text elements above
                  o.entryRelationship = {}

                  -- Add the machine readable code corresponding to the Status entry of the HTML table
                  -- This section is completely optional, so the validator does not care if it's absent
                  local StatusObservation = {}

                  do
                     local sO = StatusObservation

                     -- Schematron does not check for the typeCode and inversionInd because this this template is optional.
                     sO.typeCode = 'SUBJ'
                     sO.inversionInd = 'true'
                     -- end of schematron does not check
                     sO.observation = {}
                     sO.observation.templateId = {root='2.16.840.1.113883.10.20.22.4.28'}
                     sO.observation.classCode = 'OBS'
                     sO.observation.moodCode = 'EVN'
                     sO.observation.code = {}
                     sO.observation.code = voc.LOINC["Status"]
                     sO.observation.statusCode = {}
                     sO.observation.statusCode = {code='completed'}
                     -- Special xsi:type element! We will use the first method here
                     sO.observation.value = {['xsi:type'] = 'CE'}
                     local Code = voc["Problem Status Value Set"]["Iinactive"]
                     CCDAmergeTable(Code, sO.observation.value)
                  end
                  table.insert(o.entryRelationship, StatusObservation)

                  -- Add the machine readable code corresponding to the Reaction entry of the HTML table
                  local ReactionObservation = {}

                  do
                     local eR = ReactionObservation

                     eR.typeCode = 'MFST'
                     eR.inversionInd = 'true'
                     eR.observation = {}
                     eR.observation.templateId = { root = '2.16.840.1.113883.10.20.22.4.9' }
                     eR.observation.classCode = 'OBS'
                     eR.observation.moodCode = 'EVN'
                     eR.observation.id = {}
                     eR.observation.id = {
                        root=uniqueID,
                        extension="1002"  
                     }
                     eR.observation.code = {}
                     eR.observation.code = {nullFlavor="NA"}
                     -- Note : this (machine) text points to its corresponding narrative in the human
                     -- readable text element. #reaction1 in this case.
                     eR.observation.text = {
                        Text = ''
                     }
                     eR.observation.statusCode = {}
                     eR.observation.statusCode = { code = 'completed' }
                     eR.observation.effectiveTime = {}
                     eR.observation.effectiveTime.low = {value = tostring(Allergies[i][10]):gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%1%2")}
                     eR.observation.effectiveTime.high = {value = '00000000'}
                     -- Special xsi:type element! Method 2
                     eR.observation.value = {
                        ['xsi:type']='CD', code='247472004', codeSystem='2.16.840.1.113883.6.96',
                        displayName=Allergies[i][8], codeSystemName='Problem Value Set'
                     }

                     -- Add the recommended Severity Observation element
                     do
                        eR.observation.entryRelationship = {}
                        eR.observation.entryRelationship.typeCode = 'SUBJ'
                        eR.observation.entryRelationship.inversionInd = 'true'
                        eR.observation.entryRelationship.observation = {}
                        local o = eR.observation.entryRelationship.observation
                        o.templateId = {root='2.16.840.1.113883.10.20.22.4.8'}
                        o.classCode = 'OBS'
                        o.moodCode = 'EVN'
                        o.code = {}
                        o.code = {code='SEV', codeSystem='2.16.840.1.113883.5.4'}
                        o.text = {
                           Text = ''
                        }
                        o.statusCode = {}
                        o.statusCode = 'completed'
                        o.statusCode = {code = 'completed'}
                        -- Special xsi:type element! Method 3
                        o.value = copyTable(voc["Problem Severity"]["Moderate to severe (qualifier value)"])
                        o.value['xsi:type'] = 'CD'
                        o.interpretationCode = {}
                        o.interpretationCode = voc["Observation Interpretation (HL7)"]["moderately susceptible"]
                     end

                  end
                  table.insert(o.entryRelationship, ReactionObservation)

                  -- Add the machine readable code corresponding to the Severity entry of the HTML table
                  local SeverityObservation = {}

                  do
                     local eR = SeverityObservation
                     eR.typeCode = 'SUBJ'
                     eR.inversionInd = 'true'
                     eR.observation = {}
                     eR.observation.templateId = {root='2.16.840.1.113883.10.20.22.4.8'}
                     eR.observation.classCode = 'OBS'
                     eR.observation.moodCode = 'EVN'
                     eR.observation.code = {}
                     -- You could also assign code = { code = 'SEV'} if you prefer
                     eR.observation.code = voc['ActCode']['Severity Observation']
                     -- Note : this (machine) text points to its corresponding narrative in the human
                     -- readable text element. #severity1 in this case.
                     eR.observation.text = {
                        Text = ''
                     }
                     eR.observation.statusCode = {}
                     eR.observation.statusCode = {code='completed'}
                     -- Special xsi:type element! We will use method 3 here 
                     eR.observation.value = copyTable(voc["Problem Severity"]["Moderate to severe (qualifier value)"])
                     eR.observation.value['xsi:type'] = 'CD'
                     eR.observation.interpretationCode = {}
                     eR.observation.interpretationCode = voc["Observation Interpretation (HL7)"]["moderately susceptible"]
                  end
                  table.insert(o.entryRelationship, SeverityObservation)            
               end
            end
            table.insert(AS.entry, A)
            trace(AS.entry)
            trace(Allergies)
            --table.insert(AllergiesSection,AS.entry)
            trace(AllergiesSection)

         end
      end

      -- Add Allergies Section to structureBody
      table.insert(sB.component, AllergiesSection)
   end
end

return allergy