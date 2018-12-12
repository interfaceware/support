local utils = require 'ccda.utils'
local addElement = utils.addElement
local setAttr = utils.setAttr
local ccda = {}

-- IMPORTANT : Be EXTREMELY careful when you modify a code input data entry.
-- If this code element entry has a reference to the voc code system table,
-- modifying the code entry would modify the voc table as well.
-- 
-- For example, assume we assigned component.observation.statusCode like this
--    component.observation.statusCode = voc["Result Status"].completed
-- and some where in this lua file statusCode is modified like this
--    component.observation.statusCode.code = nil
-- Then voc["Result Status"].completed is changed forever (until the next time
-- you run the channel).


-- fills the attributes of the parent element
local function fillAttributes(I)
   local Parent = I.parent
   local T = I.template
   local Data = I.data
   
   -- populate attributes
   for J,K in pairs(T) do
      trace(J)
      trace(K)
      -- check if the attribute is prohibited
      if K.use ~= 'prohibited' then
         -- check if input is provided
         local Val = Data[J]
         if Val ~= nil then
            -- check if the attribute is fixed
            if K.fixed ~= nil then
               Val = K.fixed
            end
            setAttr(Parent, J, Val)
         end
      end
   end

end

-- cardinality extraction helper function
-- -1 is returned if the maxOccurs = 'unbounded'
local function extractCardinality(I)
   -- extract minOccurs
	local min = tonumber(I.minOccurs)
   -- extract maxOccurs
   local max = -1
   if I.maxOccurs ~= 'unbounded' then
      max = tonumber(I.maxOccurs)
   end
   
   return min, max   
end


-- helper function of handleChoiceFiniteOccurance()
local function matchInputToChoice(I)
   local Data = I.data
   local T = I.choice
   local Result = I.result

   local minCard, maxCard = extractCardinality(T.XSDchoiceMeta)
   
   if maxCard == 0 then
      assert(minCard == 0)
      -- maxOccurs is 0 which disables the xs:choice
      error('The current xs:choice has an unusual cardinality of 0..0')
   elseif maxCard < 0 then
      -- maxOccurs of the xs:choice is 'unbounded'
      -- sanity check. This never happens. If it does in the future,
      -- the code in handleSequenceChoice() should do the trick.
      error('The future is here.')
   else
      -- maxOccurs of the xs:choice is a positive integer
      for J,K in pairs(T) do
         if J ~= 'XSDchoiceMeta' then
            trace(J)
            if J:split('-')[1] == 'XSDsequence' then
               -- handle xs:sequence
               if matchInputToSequence{data=Data, sequence=T[J]} then
                  trace('right option')
                  return true
               else
                  trace('wrong option')
               end
            else
               -- handle xs:element
               if Data[J] ~= nil then
                  -- the xs:element matches an input in input data
                  if utils.tableLength(Data) > 1 then
                     trace('not this option')
                     return false
                  else
                     trace('this is the right option')
                     Result[J] = T[J]
                     if Result['XSDseqOrder'] ~= nil then
                        table.insert(Result['XSDseqOrder'], J)
                     end
                     -- Note the Data is a copy of the orginal data (copied in 
                     -- handleChoiceFiniteOccurance) so we don't need to worry about
                     -- modifying the voc table here.
                     Data[J] = nil
                     return true
                  end
               end
            end
         end
      end
   end
   
   return false
end


-- helper function of handleChoiceFiniteOccurance()
local function matchInputToSequence(I)
	local Data = I.data
   local Sequence = I.sequence
   local Result = I.result
   
   for _,J in pairs(Sequence.XSDseqOrder) do
      trace(J)
      if J:split('-')[1] == 'XSDchoice' then
         trace('xs:choice')
         if matchInputToChoice{data=Data, choice=Sequence[J], result=Result} then            
            -- add the returned data to Result and XSDseqOrder
            trace(Result)
         end
      else
         trace('xs:element')
         -- check cardinality
         local min, max = extractCardinality(Sequence[J])
         if min == 1 and max == 1 and Data[J] == nil then
            trace('required element is absent')
            return false
         end

         if Data[J] ~= nil then
            -- add it to result
            if Result['XSDseqOrder'] == nil then 
               Result['XSDseqOrder'] = {}
            end
            Result[J] = Sequence[J]
            table.insert(Result.XSDseqOrder, J)
            -- Note the Data is a copy of the orginal data (copied in 
            -- handleChoiceFiniteOccurance) so we don't need to worry about
            -- modifying the voc table here.
            Data[J] = nil
         end
      end
   end
   trace(Result)
   if next(Data) == nil then
      trace('all inputs are matched.')
      return true
   else
      trace('some inputs are not matched.')
      return false
   end
end


-- extract the intended list of child elements out of all possible combinations
-- allowed by the implementation guide
local function handleChoiceFiniteOccurance(I)
   local T = I.template
   local Data = I.data
   
   local Result = {}
   for J,K in pairs(T) do
      local DataCopy = utils.copyTable(Data)
      if J ~= 'XSDchoiceMeta' then
         trace(J)
         trace(K)
         if J:split('-')[1] == 'XSDsequence' then
            -- handle xs:sequence
            if matchInputToSequence{data=DataCopy, sequence=T[J], result=Result} then
               trace('right option')
               break
            else
               trace('wrong option')
               -- reset Result
               Result = {}
            end
            trace(Result)
         else
            -- handle xs:element
            if DataCopy[J] ~= nil then
               -- the xs:element matches an input in input data
               if utils.tableLength(DataCopy) > 1 then
                  trace('wrong option')
                  -- reset Result
                  Result = {}
               else
                  if Result['XSDseqOrder'] == nil then 
                     Result['XSDseqOrder'] = {}
                  end
                  trace('right option')
                  Result[J] = T[J]
                  table.insert(Result.XSDseqOrder, J)
                  break
               end
            end
         end
      end
   end
   
   return Result
end


-- forwared declare the fileElement function
local fillElement


-- handles xs:choice
local function handleChoice(I)
   local Parent = I.parent
   local T = I.template
   local Data = I.data
   
   -- we know we are currently in a xs:choice, the next step is to
   -- determine its ardinality
   local minCard, maxCard = extractCardinality(T.XSDchoiceMeta)
   local Result = {}
   
   if maxCard == 0 then
      assert(minCard == 0)
      -- maxOccurs is 0 which disables the xs:choice
      error('The current xs:choice has an unusual cardinality of 0..0')
   elseif maxCard < 0 then
      -- maxOccurs of the xs:choice is 'unbounded'
      -- sanity check. This never happens. If it does in the future,
      -- the code in handleSequenceChoice() should do the trick.
      error('The future is here.')
   else
      -- maxOccurs of the xs:choice is a positive integer
      Result = handleChoiceFiniteOccurance{template=T, data=Data}
   end
   trace(Result)
   
   if next(Result) ~= nil then
      for _,Z in pairs(Result.XSDseqOrder) do
         local aE = addElement(Parent, Z)
         fillElement{parent=aE, data=Data[Z], type=Result[Z].type}
      end
   else
--      error('Invalid input for '..Parent:nodeName())
   end
   
end


-- handles xs:choice in xs:sequence
local function handleSequenceChoice(I)
   local Parent = I.parent
   local T = I.template
   local Data = I.data
   local J = I.choice
   
   local Choice = J
   trace(Choice)
   for L,_ in pairs(T[J]) do
      trace(L)
      trace(Data[L])
      if Data[L] ~= nil then
         local K = T[Choice][L]
         J = L
         local aE = addElement(Parent, J)
         fillElement{parent=aE, data=Data[J], type=K.type}
      end
   end
end


-- handles xs:element in xs:sequence
local function handleSequenceElement(I)
   local Parent = I.parent
   local K = I.template
   local Data = I.data
   local J = I.element
   
   local minOccurs, maxOccurs = extractCardinality(K)
   trace(minOccurs)
   trace(Data[J])
   if minOccurs > 0 then
      trace('required')
      if Data[J] == nil then
         -- change trace to error to enforce required element check
         trace('Missing input for required child element: '..J)
      end
   end

   if Data[J] ~= nil then
      if #Data[J] == 0 then
         Data[J] = {Data[J]}
      end
      trace(Data[J])

      local OccursIn = #Data[J]
      if OccursIn < minOccurs then
         local Err = 'Element '..J..' must appear at least'..minOccurs
         Err = Err..' times, only '..OccursIn..' sets of data provided.'
         error(Err)
      end
      if maxOccurs > 0 and OccursIn > maxOccurs then
         if type(Data[J]) == 'string' then
            local Err = 'Invalid string assignement.\n'
            Err = Err..'e.g. title="HL7" should be title = {Text = "HL7"}\n'
            Err = Err..'statusCode="completed" should be statusCode = {code="completed"}\n'
            Err = Err..'telecom="(314)159-265-3589" should be telecom = {value="(314)159-265-3589"}\n'
            Err = Err..'effectiveTime.low="20120806" should be effectiveTime.low = {value="20120806"}\n'
            error(Err)
         end
         local Err = 'Element '..J..' is allowed to appear '..maxOccurs
         Err = Err..' times, '..OccursIn..' sets of data provided.'
         error(Err)
      end

      -- if Data[J] is a string, such as the code string,
      -- wrap it in a table
      if type(Data[J]) == 'string' then
         Data[J] = {{Data[J]}}
      end

      for L = 1,#Data[J] do
         local aE = addElement(Parent, J)
         fillElement{parent=aE, data=Data[J][L], type=K.type}
      end
   end
end


-- handles xs:sequence
local function handleSequence(I)
   local Parent = I.parent
   local T = I.template
   local Data = I.data
   
   for _,J in pairs(T.XSDseqOrder) do
      local K = T[J]
      trace(J)

      -- handle xs:choice in xs:sequence
      if J:split('-')[1] == 'XSDchoice' then
         trace('xs:choice in xs:sequence')
         handleSequenceChoice{parent=Parent, template=T, data=Data, choice=J}
      elseif J:split('-')[1] == 'XSDsequence' then
         error('xs:sequence in xs:sequence?')
      else
         trace('xs:element in xs:sequence')
         handleSequenceElement{parent=Parent, template=K, data=Data, element=J}
      end
   end
end


-- handle Text node data if current element contains Text nodes
-- returns true if the current node is a text node
local function handleTextNode(I)
   local Parent = I.parent
   local Etype = I.type
   local T = I.template
   local Data = I.data
   
   -- special handling for type 'ON', which is a text node for organization names
   -- unlike other text element types, it has no mediatype attribute.
   if Etype == 'ON' then
      Parent:setInner(Data.Text)
      -- Text node has nothing to do with code system , so no need to worry about
      -- modifying voc table here. We can use nil to skip part of fillElement()
      -- to speed up the code
      Data.Text = nil
      return true
   end
   
   -- check for text elements
   local attr = T['attribute']
   if attr ~= nil then
      trace(attr)
      if attr['mediaType'] ~= nil then
         if attr['mediaType']['fixed'] == 'text/plain' or
            attr['mediaType']['default'] == 'text/plain' or
            attr['mediaType']['fixed'] == 'text/x-hl7-text+xml' or
            attr['mediaType']['fixed'] == 'text/x-hl7-title+xml' then
            Parent:setInner(Data.Text)
         end
         -- Text node has nothing to do with code system , so no need to worry
         -- about modifying voc table here
         Data.Text = nil
         return true
      end
   end
   
	return false
end


-- fill the attributes and child elements of an element
fillElement = function(I)
   local Parent = I.parent
   local Data = I.data
   local Etype = I.type
   local Required = I.required
   trace(Parent)
   trace(Etype)
   -- skip if input invalid
	if Parent == nil then
      error('Invalid Parent')
   end
   type(Data)
   if not Required and next(Data) == nil then
      trace('No input provided for optional element. Skip')
      return
   end
   
   -- Check if the input includes xsi:type. xsi:type allows the type of an
   -- element to be redefined. Therefore, if xsi:type is present, then we
   -- will ignore the input type parameter 'Etype = I.type'
   if Data['xsi:type'] ~= nil then
      setAttr(Parent, 'xsi:type', Data["xsi:type"])
      Etype = Data['xsi:type']
      -- xsi:type always contain a type string, don't need to worry about
      -- modifying voc table
      Data['xsi:type'] = nil
   end

   -- grab the XSD template
   local T = ccda.namespace["urn:hl7-org:v3"][Etype]
   trace(T)
   
   -- handle Text nodes
   if handleTextNode{parent=Parent, type=Etype, template=T, data=Data} then
      -- fill the attributes of the text node element if exists
      fillAttributes{parent=Parent, template=T.attribute, data=Data}
      -- Text nodes should only contain Text data, so we can return here.
      return
   end

   trace(Data)
   -- special handling for telecom/@use and addr/@use
   -- @use could be selected from a Value Set but only the code SHALL be present.
   -- the codeSystem, displayName, and codeSystemName are all omitted.
   if Data['use'] ~= nil then
      -- if use is chosen from a voc value set, unwrap it.
      if Data['use'].code then
         Data['use'] = Data['use'].code
      end
      trace(Data)
   end

   -- fill the attributes of the current element
   fillAttributes{parent=Parent, template=T.attribute, data=Data}
   
   -- populate child elements
   if T.element ~= nil then
      trace('Fill child elemnts for '..Etype)
      if T.element.XSDchoiceMeta ~= nil then
         trace('xs:choice detected')
         handleChoice{parent=Parent, template=T.element, data=Data}
      elseif T.element.XSDseqOrder ~= nil then
         trace('xs:sequence detected')
         trace(Data)
         handleSequence{parent=Parent, template=T.element, data=Data}
      else
         -- sanity check, in case I missed something
         error()
      end
   end
   
end



-- ==================== generate main function ====================

-- this function uses XSD database and user input data table to generate
-- a CCDA XML file
local function generateXML(I)
   local Parent = I.parent
   local Data = I.data
   ccda = I.ccda
   
   local DB = ccda.namespace["urn:hl7-org:v3"]
   local T = DB.element.ClinicalDocument.type
   trace(T)
   
   -- fill the root element ClinicalDocument
   fillElement{parent=Parent, data=Data, type=T, required=true}

end

return generateXML