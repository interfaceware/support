local ccda = {}
ccda.namespace = {}
ccda.namespace.map = {}
ccda.processed = {}
ccda.processing = {}

local xsd = {}
local utils = require 'ccda.utils'
-- ==================== XSD processing functions ====================

local function dereferenceName(I)
   local Target = I.target
   local Attr = I.output
   
   -- if ref is present, name and type should be absent, and vice versa
   assert(Attr.type == nil)
   trace('ref attribute is found. De-referencing ...')
   local Ref = Attr.ref:split(':')
   trace('Namespace = '..Ref[1]..', name = '..Ref[2])
   local RefNS = ccda.namespace.map[Ref[1]]
   trace(RefNS)
   local RemoteName = Ref[2]
   local RemoteType = ccda.namespace[RefNS][Target][Ref[2]].type
   trace('name = '..RemoteName..', type = '..RemoteType)
   -- detect the namespace of remove type
   local RemoteTypeData = RemoteType:split(':')
   -- Since the only remote namespace is sdtc, and the only namespace
   -- it could reference to is hl7, I will just hard code it here.
   if RemoteTypeData[1] == 'hl7' then
      RemoteType = RemoteTypeData[2]
   end
   Attr['name'] = Attr.ref
   Attr['type'] = RemoteType
   trace(Attr)
   assert(Attr.name ~= nil)
   assert(Attr.type ~= nil)

   -- remove the ref
   Attr.ref = nil
end

-- Convert a table that contains the name, type, and use attributes to 
-- one that maps the name attribute to a table that contains only the 
-- type and use attributes.
--
-- If the table contains a ref attribute instead, attempts will be made
-- to resolve the reference.
--
-- If parameter ordered is set, the extracted name will be appended to
-- the XSDseqOrder array as well.
local function XSDextractName(I)
   local Target = I.target
   local Source = I.source
   local Output = I.output
   local Order = I.ordered
   
   -- extract all attributes
   local Attr = {}
   
   -- an element appears exactly once by default
   if Target == 'element' then
      Attr['minOccurs'] = 1
      Attr['maxOccurs'] = 1
   end
   
   -- load all attributes
   for K,L in pairs(Source) do
      -- exclude child elements such as xs:annotation
      if type(L) ~= 'table' then
         Attr[K] = L
      end
   end
   
   -- Occasionally, the name and type of a xs:attribute / xs:element are not
   -- present. Instead, a ref (reference) is provided. We want to resolve
   -- the ref
   if Attr.name == nil then
      trace('name attribute is missing')
      local Ref = Attr.ref
      if Ref ~= nil then
         dereferenceName{target=Target, output=Attr}
      end
   end
         
   assert(Attr.ref == nil)
   
   -- reformat the extracted values
	local Key = Attr.name
   -- remove the key 'name'
   Attr.name = nil
   Output[Key] = Attr

   -- append Key to the sequence order array if ordered is set
   if Order then
      -- create the array if necessary
      if Output['XSDseqOrder'] == nil then
         Output['XSDseqOrder'] = {}
      end
      table.insert(Output['XSDseqOrder'], Key)
   end

   return Output
end


-- Extract /xs:attribute or /xs:element
-- If output is provided, it is updated. Otherwise Targets extracted from
-- source is returned
local function extractTarget(I)
   local Target = I.target
   local Source = I.source
   local Output = I.output

   -- determine the number of Target to extract
   local Count = #Source
   
   -- if Output is not provided, we are in extract mode
   if Output == nil then
      Output = {}
   end
   
	if Count == 0 then
      -- if there is only 1 instance of the Target, the Source is a table.
      -- This causes Count to be 0.
      XSDextractName{target=Target, source=Source, output=Output}
   else
      -- if there are multiple instaces, the Source is an array.
      for J = 1,Count do
         XSDextractName{target=Target, source=Source[J], output=Output}
      end
   end
   
   return Output
end


-- Extract /xs:choice
function XSDextractChoice(I)
   local Source = I.source
   local Output = I.output

   if Source["xs:element"] ~= nil then
      -- extract /xs:choice/xs:element
      extractTarget{target='element', source=Source["xs:element"], output=Output, ordered=true}
   end
   
   if Source["xs:sequence"] ~= nil then
      for I = 1,#Source["xs:sequence"] do
         -- generate a unique name to avoid collision
         local SeqName = generateNameExtension{base='XSDsequence-'}
         trace(SeqName)

         -- extract /xs:choice/xs:sequence
         local Sequence = {}
         extractSequence{source=Source["xs:sequence"][I], output=Sequence}
         trace(Output)

         -- add sequence to output
         Output[SeqName] = Sequence
      end
   end
   
   local ChoiceMeta = {}
   ChoiceMeta['minOccurs'] = Source.minOccurs or 1
   ChoiceMeta['maxOccurs'] = Source.maxOccurs or 1
   Output['XSDchoiceMeta'] = ChoiceMeta
   
   return Output
end


-- Generates a name for xs:choice to avoid key collisions in a xs:sequence.
-- TODO : This is a overkill, should use a counter instead.
-- Thankfully it is not called frequently
function generateNameExtension(I)
   local ChoiceName = I.base
   
   local GUID = util.guid(128)
   -- randomly select 5 chars from it
   for R = 1, 5 do
      local Index = math.random(33)
      ChoiceName = ChoiceName..GUID:sub(Index, Index)
   end

   return ChoiceName
end


-- Extract /xs:sequence
function extractSequence(I)
   local Source = I.source
   local Output = I.output

   for I = 1,#Source do
      if Source[I]["xs:element"] ~= nil then
         -- extract /xs:sequence/xs:element
         XSDextractName{target='element', source=Source[I]["xs:element"], output=Output, ordered=true}
      elseif Source[I]["xs:choice"] ~= nil then
         -- generate a unique name for choice
         local ChoiceName = generateNameExtension{base='XSDchoice-'}
         trace(ChoiceName)
         
         -- add xs:choice to the order array
         if Output['XSDseqOrder'] == nil then
            Output['XSDseqOrder'] = {}
         end
         table.insert(Output['XSDseqOrder'], ChoiceName)
         
         -- extract /xs:sequence/xs:choice
         local Choice = {}
         XSDextractChoice{source=Source[I]["xs:choice"], output=Choice}
         
         -- add choice to output
         Output[ChoiceName] = Choice
      end
   end
   
   return Output
end

-- extension component extraction functions
local extension = {}

extension["xs:attribute"] = function(I)
   local Output = I.output
   local CHKEXT = I.extension
   
   if Output['attribute'] == nil then
      Output['attribute'] = {}
   end
   extractTarget{target='attribute', source=CHKEXT["xs:attribute"], output=Output['attribute']}
end

extension["xs:element"] = function(I)
   local Output = I.output
   local CHKEXT = I.extension

   if Output['element'] == nil then
      Output['element'] = {}
   end
   extractTarget{target='element', source=CHKEXT["xs:element"], output=Output['element']}
end

extension["xs:sequence"] = function(I)
   local Output = I.output
   local CHKEXT = I.extension
   
   if Output['element'] == nil then
      Output['element'] = {}
      extractSequence{source=CHKEXT["xs:sequence"], output=Output['element']}
   else
      -- the base already has a sequence of elements, and we are extending it with more elements
      local ExtSeq = {}
      extractSequence{source=CHKEXT["xs:sequence"], output=ExtSeq}
      -- add the extension sequence to the base sequence
      for _,Z in pairs(ExtSeq['XSDseqOrder']) do
         table.insert(Output.element.XSDseqOrder, Z)
         Output.element[Z] = ExtSeq[Z]
      end
   end
end

extension["xs:choice"] = function(I)
   local Output = I.output
   local CHKEXT = I.extension

   if Output['element'] == nil then
      Output['element'] = {}
      XSDextractChoice{source=CHKEXT["xs:choice"], output=Output['element']}
   else
      -- generate a unique name to avoid collision
      local ChoiceName = generateNameExtension{base='XSDchoice-'}
      trace(ChoiceName)

      -- extract /xs:choice/xs:sequence
      local Choice = {}
      XSDextractChoice{source=CHKEXT["xs:choice"], output=Choice}

      -- add choice to the sequence order array
      table.insert(Output.element.XSDseqOrder, ChoiceName)

      -- add choice to output
      Output['element'][ChoiceName] = Choice
   end
end

-- Extract xs:extension
local function extractExtension(I)
   local CHKEXT = I.chkext
   local Namespace = I.namespace
   local Postponed = I.postponed
   local Index = I.index
   
   local Output
   
   local Base = CHKEXT.base
   trace('Extending complexType '..Base)
   
   local RemoteNS, Name = unpack(Base:split(':'))
   -- if Name is not nil, then Base has the form <namespace>:<name>
   if Name then
      -- sanity check: if within the same namespace, I don't think we should expect
      -- the namespace to be present in Base
      assert(Namespace ~= ccda.namespace.map[RemoteNS])
      -- update Namespace using namespace map
      Namespace = ccda.namespace.map[RemoteNS]
      Base = Name
   end
   trace(Namespace, Base)
   
   if ccda.namespace[Namespace][Base] == nil then
      trace('Base type '..Base..' not found. Postpone processing')
      -- add the complex type to the postponed list
      table.insert(Postponed, Index)
   else
      -- load the base complexType
      Output = utils.copyTable(ccda.namespace[Namespace][Base])
      
      -- extract extension components
      local ExtensionComponents = {"xs:attribute", "xs:element", "xs:sequence", "xs:choice"}
      for _,C in pairs(ExtensionComponents) do
         if CHKEXT[C] ~= nil then
            trace(C)
            extension[C]{extension=CHKEXT, output=Output}
         end
      end
   end
   
   return Output
end

-- restriction component extraction functions
local restriction = {}

restriction["xs:attribute"] = function(I)
   local Output = I.output
   local CHKRST = I.restriction
   
   if Output['attribute'] == nil then
      Output['attribute'] = {}
   end
   extractTarget{target='attribute', source=CHKRST["xs:attribute"], output=Output['attribute']}
end

restriction["xs:element"] = function(I)
   local Output = I.output
   local CHKRST = I.restriction

   if Output['element'] == nil then
      Output['element'] = {}
   end
   extractTarget{target='element', source=CHKRST["xs:element"], output=Output['element']}
end

restriction["xs:sequence"] = function(I)
   local Output = I.output
   local CHKRST = I.restriction

   if Output['element'] == nil then
      Output['element'] = {}
   end
   extractSequence{source=CHKRST["xs:sequence"], output=Output['element']}
end

restriction["xs:choice"] = function(I)
   local Output = I.output
   local CHKRST = I.restriction

   if Output['element'] == nil then
      Output['element'] = {}
   end
   XSDextractChoice{source=Source[I]["xs:choice"], output=Output['element']}
end

-- Extract xs:restriction
local function extractRestriction(I)
   local CHKRST = I.chkrst
   local Namespace = I.namespace
   local Postponed = I.postponed
   local Index = I.index
   
   local Output
   
   local Base = CHKRST.base
   trace('Restricting complexType '..Base)
   if ccda.namespace[Namespace][Base] == nil then
      trace('Base type '..Base..' not found. Postpone processing')
      -- add the complex type to the postponed list
      table.insert(Postponed, Index)
      trace(Postponed)
   else
      -- load the base complexType
      Output = utils.copyTable(ccda.namespace[Namespace][Base])
      -- Since all elements must be redefined, remove them from the copied base
      Output['element'] = nil
      Output['XSDseqOrder'] = nil
      trace(Output)

      -- extract restriction components
      local RestrictionComponents = {"xs:attribute", "xs:element", "xs:sequence", "xs:choice"}
      for _,C in pairs(RestrictionComponents) do
         if CHKRST[C] ~= nil then
            trace(C)
            restriction[C]{restriction=CHKRST, output=Output}
         end
      end
   end

   return Output
end

-- Extract /xs:complexContent
local function extractcomplexContent(I)
   local Index = I.index
   local Postponed = I.postpone
   local Namespace = I.namespace
   local Source = I.source

   local Output

   -- The derived complexType can either expand or restrict the base complexType
   local CHKEXT = Source["xs:extension"]
   local CHKRST = Source["xs:restriction"]
   
   -- the current complexType extends its base complexType
   if CHKEXT ~= nil then
      Output = extractExtension{chkext=CHKEXT, namespace=Namespace, postponed=Postponed, index=Index}
   elseif CHKRST ~= nil then
      Output = extractRestriction{chkrst=CHKRST, namespace=Namespace, postponed=Postponed, index=Index}
   else
      error('complexContent not supported')
   end

   return Output
end

-- parse complexType in XSD
local function parseComplexType(I)
   local J = I.input
   local Index = I.index
   local Postponed = I.postponeList
   local Namespace = I.namespace
   local ComplexTypes = I.output
   
   local TypeData = {}

   -- Extract /xs:schema/xs:complexType/xs:sequence
   if J["xs:sequence"] ~= nil then
      if TypeData['element'] == nil then
         TypeData['element'] = {}
      end
      extractSequence{source=J["xs:sequence"], output=TypeData['element']}
      trace(TypeData)
   end
   
   -- Extract /xs:schema/xs:complexType/xs:choice (seen in NarrativeBlock.xsd)
   if J["xs:choice"] ~= nil then
      if TypeData['element'] == nil then
         TypeData['element'] = {}
      end
      XSDextractChoice{source=J["xs:choice"], output=TypeData['element']}
   end

   -- Extract /xs:schema/xs:complexType/xs:annotation
   if J["xs:annotation"] ~= nil then
      trace('/xs:complexType/xs:annotation handling is skipped.')
   end

   -- Extract /xs:schema/xs:complexType/xs:attribute
   if J["xs:attribute"] ~= nil then
      TypeData['attribute'] = extractTarget{target='attribute', source=J["xs:attribute"]}
   end

   -- Extract /xs:schema/xs:complexType/xs:element - probably will never get called
   -- Note : /xs:sequence and /xs:element should not co-exist as children of /xs:complexType.
   -- So overwritting TypeData['element'] should not be a problem at the /xs:complexType
   -- level. However, /xs:sequence and /xs:element could co-exist as children of /xs:choice.
   if J["xs:element"] ~= nil then
      TypeData['element'] = extractTarget{target='element', source=J["xs:element"]}
      trace(TypeData)
   end
   
   -- Extract /xs:schema/xs:complexType/xs:complexContent
   -- This implies that the current complexType is based on another complexType
   if J["xs:complexContent"] ~= nil then
      TypeData = extractcomplexContent{index=Index, postpone=Postponed,
         namespace=Namespace, source=J["xs:complexContent"]}
      trace(TypeData)
   end

   -- If the base complexType is not processed yet, the derived complex can not be
   -- parsed, and an empty table is returned. Skip.
   if TypeData ~= nil then
      trace('Add complexType to namespace')
      ComplexTypes[J.name] = TypeData
   end

end

-- parse the namespace declarations in XSD
local function parseNamespaces(I)
   local Schema = I.schema
   local NamespaceIn = I.namespaceIn
   
   -- extract target namespace and namespace map from schema attributes
   local NamespaceTarget
   for J,K in pairs(Schema) do
      if type(K) ~= 'table' then
         -- extract target namespace
         if J == 'targetNamespace' then
            NamespaceTarget = K
         end
         -- extract namespace maps
         local Temp = J:split(':')
         if Temp[1] == 'xmlns' then
            if Temp[2] ~= nil then
               ccda.namespace.map[Temp[2]] = K
            end
         end
      end
   end
   
   -- determine the namespace of this XSD, it is either in the file or
   -- specified by NamespaceIn
   if NamespaceTarget == nil then
      if NamespaceIn == nil then
         error('Unable to determine the namespace of the XSD')
      end
      NamespaceTarget = NamespaceIn
   end
   
   return NamespaceTarget
end

-- process dependent XSD files
local function processDependencies(I)
   local Schema = I.schema
   local FileDir = I.dir
   local NamespaceTarget = I.nsTarget
   
   local Dummy = {'xs:import', 'xs:include'}
	for _,Q in pairs(Dummy) do
      trace(Q)
      if Schema[Q] ~= nil then
         local ImportCount = #Schema[Q]
         if ImportCount == 0 then
            Schema[Q] = {Schema[Q]}
            ImportCount = 1
         end
         for J = 1,ImportCount do
            local RelativePath = Schema[Q][J].schemaLocation
            -- convert path separator for Windows
            if utils.pathSeparator == '\\' then
               RelativePath = RelativePath:gsub('/', '\\')
            end
            trace(RelativePath)
            local Fname = table.remove(RelativePath:split(utils.pathSeparator))
            -- skip processing the file if it is being processed or it is processed
            if ccda.processed[Fname] == nil and ccda.processing[Fname] == nil then
               local FilePath = FileDir..RelativePath
               trace(FileDir)
               local NS = Schema[Q][J].namespace
               if NS == nil then
                  NS = NamespaceTarget
               end
               xsd.parseXSD(FilePath, NS)
            end
         end
      end
   end
end


-- Schema component extraction functions
local extract = {}

extract["xs:attribute"] = function(I)
   local Schema = I.schema
   local NamespaceTarget = I.namespace
   
   local Outputs = ccda.namespace[NamespaceTarget]
   Outputs['attribute'] = extractTarget{target='attribute', source=Schema["xs:attribute"]}
end

extract["xs:element"] = function(I)
   local Schema = I.schema
   local NamespaceTarget = I.namespace

   local Outputs = ccda.namespace[NamespaceTarget]
	Outputs['element'] = extractTarget{target='element', source=Schema["xs:element"]}
end

extract["xs:simpleType"] = function(I)
   -- simpleType restricts or extends basic XSD datatypes
   -- e.g. type 'bl' restricts 'xs:boolean' and its value can only be 'true' or 'false'
	trace('Not used in validation. Skip')
end

extract["xs:complexType"] = function(I)
   local Schema = I.schema
   local NamespaceTarget = I.namespace
   
   local Outputs = ccda.namespace[NamespaceTarget]
   -- create an array to hold complexTypes who need to be processed later because
   -- their base complexTypes are not yet processed
   local Postponed = {}

   for I = 1,#Schema["xs:complexType"] do
      local J = Schema["xs:complexType"][I]
      trace(I)
      trace(J.name)

      parseComplexType{input=J, index=I, postponeList=Postponed,
         namespace=NamespaceTarget, output=Outputs}
   end

   trace(Postponed)
   utils.tableLength(Postponed)
   trace(Outputs)
   utils.tableLength(Outputs)

   -- process complexType in the postponed array
   for Q = 1,#Postponed do
      local Itr = table.remove(Postponed, 1)
      local J = Schema["xs:complexType"][Itr]
      trace(J.name)

      parseComplexType{input=J, index=Q, postponeList=Postponed,
         namespace=NamespaceTarget, output=Outputs}
   end
   
   assert(next(Postponed) == nil)
   trace(Outputs)
end

extract["xs:group"] = function(I)
	trace('The only instance in infrastructureRoot.xsd is not referenced anywhere. Skip.')
end

extract["xs:attributeGroup"] = function(I)
	trace('The only instance in infrastructureRoot.xsd is empty. Skip')
end


-- ==================== schema main function ====================

-- Note: this function is designed to parse C-CDA xsd files only!
function xsd.parseXSD(File, NamespaceIn)
   -- convert the XSD file into a lua table
   local Schema = utils.convertXMLtoTable(File)["xs:schema"]
   
   -- parse the namespace map and get the namespace of the current XSD file
   local NamespaceTarget = parseNamespaces{schema=Schema, namespaceIn=NamespaceIn}

   -- create a local alias for ccda.namespace
   local NS = ccda.namespace
   
   -- create the namespace if it doesn't exist already
   if NS[NamespaceTarget] == nil then
      NS[NamespaceTarget] = {}
   end
   
   -- extract filename and directory
   -- Note the regex works for both Windows and POSIX paths
   local FileDir, FileName, ext = File:match("(.-)([^\\/]-%.?[^%.\\/]*)$")
   trace(FileDir)
   trace(FileName)
   
   -- add the current XSD file to the processing list to avoid 
   -- infinite import/include loop
   ccda.processing[FileName] = 1

   -- Pre-populate the QTY and RTO_QTY_QTY hl7 Types.
   --
   -- Note: this is for R2.1 schema becuase it introduced complex types
   -- in the sdtc namespace that are based on types in hl7 namespace.
   -- The proper solution is to update the XSD parsing logic so that it 
   -- can properly handle circular schema file dependencies.
   ccda.namespace["urn:hl7-org:v3"]["QTY"] = {
      ["attribute"] = {
         ["nullFlavor"] = {
            ["use"] = "optional",
            ["type"] = "NullFlavor"
         }
      }
   }
   ccda.namespace["urn:hl7-org:v3"]["RTO_QTY_QTY"] = {
      ["attribute"] = {
         ["nullFlavor"] = {
            ["type"] = "NullFlavor",
            ["use"] = "optional"
         }
      },
      ["element"] = {
         ["numerator"] = {
            ["type"] = "QTY",
            ["maxOccurs"] = 1,
            ["minOccurs"] = 1
         },
         ["XSDseqOrder"] = {
            "numerator",
            "denominator"
         },
         ["denominator"] = {
            ["type"] = "QTY",
            ["maxOccurs"] = 1,
            ["minOccurs"] = 1
         }
      }
   }
   
   -- process imports and includes
   processDependencies{schema=Schema, dir=FileDir, nsTarget=NamespaceTarget}

	-- process Schema components
   local SchemaComponents = {
      "xs:attribute",
      "xs:element",
      "xs:simpleType",
      "xs:complexType"
   }
   for _,C in pairs(SchemaComponents) do
      if Schema[C] ~= nil then
         trace(C)
         extract[C]{schema=Schema, namespace=NamespaceTarget}
      end
   end
   
   -- move file from processing list to processed list
   ccda.processed[FileName] = 1
   ccda.processing[FileName] = nil
   
   trace(NS)
   return NS
end

return xsd