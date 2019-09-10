local globalConfigs = require('SAMLconfig')

local respPyScript = [[import sys
sys.path.append(']]..globalConfigs.signxmlLocation..[[')
from lxml import etree
from signxml import XMLVerifier

with open("]]..globalConfigs.certLocation..[[", "r") as fh:
    cert = fh.read()
responseTree = etree.fromstring(responseStr)
assertion_data = XMLVerifier().verify(responseStr, x509_cert=cert).signed_data
print assertion_data]]

return respPyScript
