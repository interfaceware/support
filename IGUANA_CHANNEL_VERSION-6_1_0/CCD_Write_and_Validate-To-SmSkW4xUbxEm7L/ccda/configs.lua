local utils = require 'ccda.utils'

local cfg ={}

-- Define CCDA directory and files
cfg.CCDAdirName = 'CCDA'
cfg.CCDAoutput = 'ccda.xml'
cfg.CCDAdir = cfg.CCDAdirName..utils.pathSeparator
cfg.CCDAerrName = 'cda_err.svrl'

-- Define CCDA version (R2 or R2.1)
-- R2: 2012 July Edition
-- R2_1: 2015 Aug Edition
cfg.CCDAVersion = 'R2_1'

return cfg