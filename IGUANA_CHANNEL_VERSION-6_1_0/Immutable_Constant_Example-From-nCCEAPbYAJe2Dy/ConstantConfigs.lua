local function readonlyConst(table)
   return setmetatable({}, {
         __index = table,
         __newindex = function(table, key, value)
            error("Attempt to modify read-only contants")
         end,
         __metatable = false
      });
end

return readonlyConst {
   LEFT   = 1,
   RIGHT  = 2,
   UP     = 3,
   DOWN   = 4,
   otherstuff = {} -- otherstuff is not contant table
}