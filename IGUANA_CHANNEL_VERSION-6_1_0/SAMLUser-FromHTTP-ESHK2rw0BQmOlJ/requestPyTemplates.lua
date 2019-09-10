local templates = {}

-- This is the template for the request 
templates.reqTemplate = [[<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                    ID="_d7b0612b30486a59c1720be3506f6aba1be47da2e5"
                    Version="2.0"
                    IssueInstant="2017-02-03T03:22:17Z"
                    Destination="https://login.microsoftonline.com/964a28cf-ddc8-4c22-a8ee-5aa77c233b81/saml2/"
                    AssertionConsumerServiceURL="https://sp.example.com/saml/sp/saml2-acs/default"
                    ProtocolBinding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                    >
    <saml:Issuer>https://sp.example.com/</saml:Issuer>
    <samlp:NameIDPolicy Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
                        AllowCreate="true"
                        />
</samlp:AuthnRequest>]]

-- This is part of the python script required for deflating and base64 encoding
-- the request
templates.reqPyScript = 
[[import zlib
from base64 import b64encode
compressed = zlib.compress(saml)[2:-4]
encoded = b64encode(compressed)
print encoded]]

return templates