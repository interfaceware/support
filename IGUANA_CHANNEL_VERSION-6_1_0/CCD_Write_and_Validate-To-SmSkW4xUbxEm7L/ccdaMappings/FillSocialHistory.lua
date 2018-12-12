local social = {}
-- Local Functions ---

--- Public Functions ---
function social.fillSocialHistory(sB, HistoryData)
   local History = {}

   for row = 1,#HistoryData do
      History[row] = {}
      for column = 1,#HistoryData[1] do
         History[row][column] = 1
      end
   end

   local rowLength = #HistoryData[1]
   local tableLength = #HistoryData

   for i=1,tableLength do
      for j=1,rowLength do

         History[i][j] = HistoryData[i][j]:nodeValue()

         if History[i][j] == "" then
            History[i][j] = '00000'
         end
      end
   end
   
   local HistorySection = {}

   --local status = History[1][11]:nodeValue()

   HistorySection.section = {}

   local HS = HistorySection.section

   HS.templateId = {root = "2.16.840.1.113883.10.20.22.2.17"}
   HS.code = {}
   HS.code = {code = "29762-2", codeSystem = "2.16.840.1.113883.6.1", displayName = "Social History", codeSystemName = "LOINC"}
   HS.title = {Text = "Social History"}
   HS.text = {Text = ""}

   if HistoryData[1]:isNull() then
      HistorySection.section.nullFlavor = 'NI'

   else

      HS.entry = {}

      for i=1,#History do

         local H = {}
         H.observation = {}
         local HSO = H.observation
         local date = History[i][7]

         HSO.templateId = {root = "2.16.840.1.113883.10.22.4.78"}
         HSO.classCode = "OBS"
         HSO.moodCode = "EVN"
         HSO.code = {}
         HSO.code = voc.ActCode.Assertion
         HSO.statusCode = {}
         HSO.statusCode = {code = 'completed'}
         HSO.effectiveTime = {value = date:gsub('(%d%d%d%d)-(%d%d)-(%d%d)','%1%2%3')}

         local status = ""
         local name = ""
         trace(History[i][12])
         if History[i][12] == "00000" then
            status = "266927001"
            name = "unknown"
         elseif History[i][12] == "Current" then
            status = "449868002"
            name = "current"
         elseif History[i][12] == "Former" then
            status = "8517006"
            name = "former"
         elseif History[i][12] == "Never" then
            status = "266919005"
            name = "never"
         end
         HSO.value = {}
         HSO.value = {['xsi:type'] = "CD", code = status, displayName = name, codeSystem = "2.16.840.1.113883.6.96", codeSystemName = "SNOMED CT"}

         table.insert(HS.entry,H)
      end
   end
   table.insert(sB.component, HistorySection)
end

return social