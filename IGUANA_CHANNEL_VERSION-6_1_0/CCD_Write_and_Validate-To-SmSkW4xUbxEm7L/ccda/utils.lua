local utils = {}

-- ==================== Lua path functions ====================

utils.pathSeparator = package.config:sub(1,1) == '\\' and '\\' or '/'
utils.otherDir = iguana.project.root()..'other'..utils.pathSeparator
utils.ccdaRssDir = utils.otherDir..'CCDA'..utils.pathSeparator


function utils.checkDependencies()
   if utils.pathSeparator == '/' then
      -- check if xsltproc is installed for POSIX hosts
      if os.execute('xsltproc --version') ~= 0 then
         error('xsltproc is not found on your POSIX system. Please install it.', 2)
         -- OR you could set up JRE and use saxon9he.
         -- You need to modify the Command variable in parseFiles() and validateCCDA() in ccda.validate.lua
      end

      -- check if xmllint is installed
      if os.execute('xmllint --version') ~= 0 then
         error('xmllint is not found on your system. Please install it.', 2)
      end
   end
end

-- ==================== XML node functions ====================

local nodeType = node.nodeType
local append = node.append

function node.text(X)
   for i=1,#X do
      if nodeType(X[i]) == 'text' then
         return X[i]
      end
   end
   return append(X, xml.TEXT, '')
end

function utils.setText(X, T)
   X:text():setInner(T)
end


function utils.setAttr(N, K, V)
   if nodeType(N) ~= 'element' then
      error('Must be an element')
   end
   if not N[K] or nodeType(N[K]) ~= 'attribute' then
      append(N, xml.ATTRIBUTE, K)
   end 
   N[K] = V
   return N
end

function utils.addElement(X, Name)
   return append(X, xml.ELEMENT, Name)
end

-- ==================== Lua table functions ====================

-- returns a copy the table obj
function utils.copyTable(obj, seen)
   if type(obj) ~= 'table' then return obj end
   if seen and seen[obj] then return seen[obj] end
   local s = seen or {}
   local res = setmetatable({}, getmetatable(obj))
   s[obj] = res
   for k, v in pairs(obj) do
      res[utils.copyTable(k, s)] = utils.copyTable(v, s)
   end

   return res
end

-- return the length (number of key-val pair) of a table
function utils.tableLength(I)
   local count = 0
   for _,Z in pairs(I) do
      count = count + 1
   end

   return count
end

-- ==================== XML 2 Lua table functions ====================

-- converts the XSD XML tree to a lua table
local function map2Table(I)
   local R = {}
   if I:isLeaf() then
      R[I:nodeName()] = I:nodeValue()
      return R
   end

   local Node = {}
   for J = 1,#I do
      local ChildNode = map2Table(I[J])
      -- add the child node to this node
      local ChildNodeName = I[J]:nodeName()
      -- Since it is important to preserve the order of child elements
      -- in xs:sequence, array is used insetad of table
      if I:nodeName() == 'xs:sequence' then
         table.insert(Node, ChildNode)
      else
         if I:childCount(ChildNodeName) < 2 then
            Node[ChildNodeName] = ChildNode[ChildNodeName]
         else
            if Node[ChildNodeName] == nil then
               Node[ChildNodeName] = {}
            end
            table.insert(Node[ChildNodeName], ChildNode[ChildNodeName])
         end
      end
   end
   R[I:nodeName()] = Node

   return R
end

-- converts XSD to a lua table
function utils.convertXMLtoTable(FileIn)
   -- open file
   local IO = io.input(FileIn)
   -- read the entire XML file and parse it into a tree
   local FileData = IO:read('*a')
   -- close file
   IO:close()

   -- NarritiveBlock.xsd uses ASCII encoding, which is not supported by
   -- xml, we will just treat it as UTF-8
   if table.remove(FileIn:split(utils.pathSeparator)) == 'NarrativeBlock.xsd' then
      FileData = FileData:gsub('encoding="ASCII"','encoding="UTF-8"')
   end

   -- convert XSD to lua table
   local XSD = xml.parse{data=FileData}
   local T = map2Table(XSD)

   return T.Document
end

return utils