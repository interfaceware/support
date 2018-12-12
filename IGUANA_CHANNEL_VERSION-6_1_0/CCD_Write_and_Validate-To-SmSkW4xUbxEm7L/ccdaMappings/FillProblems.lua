local problem = {}
-- Local Functions ---

--- Public Functions ---
function problem.fillProblems(sB, ProblemsData)
   local Problems = {}

   for row = 1,#ProblemsData do
      Problems[row] = {}
      for column = 1,#ProblemsData[1] do
         Problems[row][column] = 1
      end
   end

   local rowLength = #ProblemsData[1]
   local tableLength = #ProblemsData

   for i=1,tableLength do
      for j=1,rowLength do

         Problems[i][j] = ProblemsData[i][j]
         Problems[i][j] = iconv.iso8859_1.dec(Problems[i][j]) --Should correct for accented characters. INSERT INTO OTHER SECTIONS
         

         if Problems[i][j] == "" then
            Problems[i][j] = '00000'
         end
      end
   end
   
   local ProblemSection = {}
   ProblemSection.section = {}
   do
      local PS = ProblemSection.section
      PS.templateId = {root = '2.16.840.1.113883.10.20.22.2.5.1'}
      PS.code = {}
      PS.code = voc.LOINC["Problem List"]
      PS.title = {Text = 'PROBLEMS'}
      PS.text = {
         Text = ''
      }

      if ProblemsData[1]:isNull() then
         ProblemSection.section.nullFlavor = 'NI'
      else
         PS.entry = {}
         for i=1,#Problems do
            local P = {}
            P.act = {}
            do
               local PCA = P.act
               PCA.templateId = {root='2.16.840.1.113883.10.20.22.4.3'}
               PCA.classCode = 'ACT'
               PCA.moodCode = 'EVN'
               PCA.id = {}
               PCA.id = {root=generateGUID()}
               PCA.code = {}
               PCA.code = {
                  code="CONC", codeSystem="2.16.840.1.113883.5.6",
                  displayName="Concern", codeSystemName='HL7ActClass'
               }
               PCA.statusCode = voc["ProblemAct statusCode"].Active
               PCA.effectiveTime = {}
               PCA.effectiveTime.low = {value = Problems[i][6]:gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%1%2")}
               PCA.effectiveTime.high = {value = '00000000'}

               PCA.entryRelationship = {}
               PCA.entryRelationship.typeCode = 'SUBJ'
               PCA.entryRelationship.observation = {}
               do
                  local PO = PCA.entryRelationship.observation

                  PO.templateId = {root='2.16.840.1.113883.10.20.22.4.4'}
                  PO.classCode = 'OBS'
                  PO.moodCode = 'EVN'
                  PO.id = {}
                  PO.id = {root=generateGUID()}
                  PO.code = voc["Problem Type"].Complaint
                  PO.text = {
                     Text = ''
                  }
                  PO.statusCode = {}
                  PO.statusCode = {code = 'completed'}
                  PO.effectiveTime = {}
                  PO.effectiveTime.low = {value='00000000'}
                  PO.effectiveTime.high = {value='00000000'}
                  -- Special xsi:type element! Method 3 used
                  PO.value = {} -- INSERT SNOMED CODE HERE
                  PO.value = {['xsi:type'] = 'CD', code = Problems[i][11], displayName = Problems[i][9], codeSystemName = "SNOMEDCT"}
               end
            end
            table.insert(PS.entry,P)           
         end
         -- Add Problem Section to structureBody
      end
   end
    table.insert(sB.component, ProblemSection)
end

return problem