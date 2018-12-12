require 'FillAllergies'
require 'FillMeds'
require 'FillPayers'
require 'FillProblems'
require 'FillProcedures'
require 'FillResults'
require 'FillVitals'
require 'FillSocialHistory'
require 'FillEncounters'



-- Copies key-value pairs in t1 to t2
-- No key collision checks!
function CCDAmergeTable(t1, t2)
   for K,V in pairs(t1) do
      t2[K] = V
   end
end

function FillHeader(CD)


   -- Since a CCDA document must have two templateId elements in its header,
   -- one for US Realm Heaer and one for the Type of the CCDA document, data
   -- must be passed in as an array, and the order matters.
   -- In fact, the CCDA generator wraps an input table in an array before
   -- processing it.
   CD.templateId = {}
   table.insert(CD.templateId, {root='2.16.840.1.113883.10.20.22.1.1'})
   -- In this example, we will create a CCD document whose templateId is
   -- 2.16.840.1.113883.10.20.22.1.2
   table.insert(CD.templateId, {root='2.16.840.1.113883.10.20.22.1.2'})

   CD.realmCode = {code='US'}
   CD.typeId = { root='2.16.840.1.113883.1.3', extension='POCD_HD000040' }

   CD.id = {}
   CD.id = {extension="7a5312a7-3578-4b5f-af5b-a7d411f3208c", root="2.16.840.1.113883.3.72"}

   -- The line below is absolutely unnecessary. The only reason it is here is because I coded
   -- this CCDA document using nothing but the validation errors present in main.lua.
   -- It happens that validation first checks if the code element exists, then the correctness
   -- of its assigned values.
   CD.code = {}

   -- The next line presents an easy way to assign code elements.
   -- Most (but not all) code systems are stored in the 'voc' Lua table. However, 
   -- the table can be slow to index at times since it contains 4MB of data.
   CD.code = voc.LOINC["Summarization of Episode Note"]
   -- Alternatively, you could assign the values yourself
   --[[
   CD.code = {
   code='34133-9', codeSystem='2.16.840.1.113883.6.1',
   displayName='Summarization of Episode Note', codeSystemName='LOINC'
}
   --]]

   -- title has a text node so we need to map it to Text
   CD.title = {Text = 'HL7 CCD'}
   CD.effectiveTime = {['value'] = '20130607000000-0000'}

   -- For confidentialityCode, the assigned value is also checked, so you
   -- will get an error if you assign an illegal value
   --CD.confidentialityCode = voc["Act Priority Value Set"]["As needed"]
   CD.confidentialityCode = voc["HL7 BasicConfidentialityKind"].normal

   -- Unfortunately, the schematron provided by HL7 does not check the 
   -- assigned values in most cases, and languageCode being one of them.
   CD.languageCode = voc.Language.English

   -- Absolutely optional elements are not checked by the validator
   CD.setId = {extension='111199021', root='2.16.840.1.113883.19'}
   CD.versionNumber = {value=1}
end


function FillrecordTarget(rT, AccountsData) --PATIENTS TABLE

   local Accounts = {}

   for row = 1,#AccountsData do
      Accounts[row] = {}
      for column = 1,#AccountsData[1] do
         Accounts[row][column] = 1
      end
   end

   local rowLength = #AccountsData[1]
   local tableLength = #AccountsData

   for i=1,tableLength do
      for j=1,rowLength do

         Accounts[i][j] = AccountsData[i][j]

         if Accounts[i][j] == "" then
            Accounts[i][j] = "00000"
         end

      end
   end

   --[[The above loop blocks create an empty table and then fill the table with data from AccountsData which
   is the query result from the database. We need the data to be in a Lua table so that we can alter the data
   in case it doesn't work.
   --]]

   local zip = Accounts[1][13]:nodeValue()

   rT.patientRole = {}
   do
      -- Create an alias so that we can do pR.id = {} instead of rT.patientRole.id = {}
      local pR = rT.patientRole
      pR.id = {}
      pR.id = {extension=Accounts[1][1]:nodeValue(), root="2.16.840.1.113883.19"}
      pR.addr = {}
      pR.addr = {
         ['streetAddressLine'] = {Text = Accounts[1][9]:nodeValue()..Accounts[1][10]:nodeValue()},
         ['city'] = {Text = Accounts[1][11]:nodeValue()},
         ['state'] = {Text = Accounts[1][12]:nodeValue()},
         ['country'] = {Text = 'US'},

         ['postalCode'] = {Text = zip}
      }
      pR.addr.use = voc.PostalAddressUse["primary home"]
      pR.telecom = {}
      -- Note: although selecting a value for use here is not the exactly the same as for code,
      -- logic was added in ccda.generates to allow us to assign a use value in a similar way.
      pR.telecom.use = voc["Telecom Use (US Realm Header)"]["Work place"]
      --trace(Accounts)
      pR.telecom.value = Accounts[1][15]:nodeValue()

      pR.patient = {}
      do
         local p = pR.patient
         p.name = {}
         -- text nodes
         p.name.given = {Text = Accounts[1][2]:nodeValue()}

         local test = Accounts[1][4]:nodeValue()
         test =  test:gsub("\145","'")

         p.name.family = {Text = test}
         -- p.name.use = {Text = Accounts[1][4]}
         -- OR
         --         p.name.use = voc.EntityNameUse.Legal

         local gCode = {}
         if Accounts[1][7]:nodeValue() == 'M' then
            gCode = {code = 'M', codeSystem = '2.16.840.1.113883.5.1', codeSystemName='HL7AdministrativeGender',displayName='Male'}
         elseif Accounts[1][7]:nodeValue() == 'F' then
            gCode = {code = 'F', codeSystem = '2.16.840.1.113883.5.1', codeSystemName='HL7AdministrativeGender',displayName='Female'}
         else
            gCode = fillNullFlavor()
         end

         p.administrativeGenderCode = gCode
         --local DateOfBirth = Accounts[1][6]:nodeValue();
         --trace(DateOfBirth:gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%2%1"))
         if Accounts[1][6]:isNull() then
            p.birthTime = {fillNullFlavor('5299')}
            else
            p.birthTime = {value = Accounts[1][6]:nodeValue():gsub("(%d%d)/(%d%d)/(%d%d%d%d)", "%3%1%2")}
         end
            
         p.languageCommunication = {}
         p.languageCommunication.languageCode = voc.Language.English
         p.languageCommunication.proficiencyLevelCode = voc.LanguageAbilityProficiency.Excellent
      end
      
      --trace(pR.patient)

      pR.providerOrganization = {} --DO NOT HAVE ADDR, HAVE OID
      do
         local PO = pR.providerOrganization
         PO.id = {root='2.16.840.1.113883.3.5416.1.3214'}
         -- The name element of organization has a text element
         PO.name = {Text='YourHealth Family Medicine'}
         PO.telecom = {
            fillNullFlavor()
         }
         PO.addr = {fillNullFlavor('10415')}
      end
   end
end


function FillAuthor(a) --INQUIRE ABOUT INFO FROM NPO
   a.time = {value='00000000'}
   a.assignedAuthor = {}
   do
      local aA = a.assignedAuthor
      aA.id = {root=''}
      aA.code = {}
      aA.code = fillNullFlavor('16788')
      aA.addr = {}
      aA.addr = {
         ['streetAddressLine'] = {Text = '300 E Front St. Suite 240'},
         ['city'] = {Text = 'Traverse City'},
         ['state'] = {Text = 'MI'},
         ['country'] = {Text = 'US'},
         ['postalCode'] = {Text = '49684'}
      }
      aA.telecom = {value='1-231-421-8505'}
      aA.telecom.use = voc["Telecom Use (US Realm Header)"]["Work place"]
      aA.assignedPerson = {}
      aA.id.root = '2.16.840.1.113883.4.6'
      aA.assignedPerson.name = {}
      aA.assignedPerson.name.family = {Text='Organization'}
      aA.assignedPerson.name.given = {Text='Northern Physicians'}
   end
end


function FillCustodian(c)
   c.assignedCustodian = {}
   c.assignedCustodian.representedCustodianOrganization = {}
   do
      local rCO = c.assignedCustodian.representedCustodianOrganization
      rCO.id = {}
      rCO.id = {root='2.16.840.1.113883.4.6'}
      rCO.name = {}
      -- The name element of organization has a text element
      rCO.name = {Text='Northern Physicians Organization'}
      rCO.telecom = {}
      rCO.telecom = {
         value = 'tel: 1-231-421-8505',
         use = voc["Telecom Use (US Realm Header)"]["Work place"]
      }
      rCO.addr = {}
      rCO.addr = {
         ['streetAddressLine'] = {Text = '300 E Front St. Suite 240'},
         ['city'] = {Text = 'Traverse City'},
         ['state'] = {Text = 'MI'},
         ['country'] = {Text = 'US'},
         ['postalCode'] = {Text = '49684'}
      }
   end
end


function FillInformationRecipient(IR)
   IR.intendedRecipient = {}
   IR.intendedRecipient.informationRecipient = {}
   IR.intendedRecipient.informationRecipient.name = {}
   IR.intendedRecipient.informationRecipient.name = fillNullFlavor('10427')
   IR.intendedRecipient.receivedOrganization = {}
   -- The name element of organization has a text element
   IR.intendedRecipient.receivedOrganization.name = {Text='eClinicalworks'}
end


function FillLegalAuthenticator(lA)
   lA.time = {}
   lA.time = {value='000000000'}
   lA.signatureCode = {}
   -- Note this code is not selected from a value set like other codes
   lA.signatureCode.code = 'S'
   lA.assignedEntity = {}
   do
      local aE = lA.assignedEntity
      aE.id = {}
      aE.id = {
         extension="999999999",
         root="2.16.840.1.113883.4.6"  
      }
      aE.addr = {}
      aE.addr = {
         ['streetAddressLine'] = {Text = '300 E Front St. Suite 240'},
         ['city'] = {Text = 'Traverse City'},
         ['state'] = {Text = 'MI'},
         ['country'] = {Text = 'US'},
         ['postalCode'] = {Text = '49684'}
      }

      aE.telecom = {}
      aE.telecom.use = voc["Telecom Use (US Realm Header)"]["Work place"]
      aE.telecom.value = 'tel:1-231-421-8505'
      -- OR
      --[[
      aE.telecom = {
      value = 'tel:555-555-1047',
      use = voc["Telecom Use (US Realm Header)"]["Work place"]
   }
      --]]

      aE.assignedPerson = {}
      aE.assignedPerson.name = {}
      -- text nodes
      aE.prefix = {Text='Mr.'}
      aE.assignedPerson.name.family = {Text='Organization'}
      aE.assignedPerson.name.given = {Text='Northern Physicians'}
   end
end


function FillAuthenticator(A)
   A.time = fillNullFlavor('16874')
   A.signatureCode = {}
   A.signatureCode.code = 'S'
   A.assignedEntity = {}
   A.assignedEntity.id = {root="2.16.840.1.113883.4.6"}
   A.assignedEntity.addr = {
      ['streetAddressLine'] = {Text = '300 E Front St. Suite 240'},
      ['city'] = {Text = 'Traverse City'},
      ['state'] = {Text = 'MI'},
      ['country'] = {Text = 'US'},
      ['postalCode'] = {Text = '49684'}
   }
   A.assignedEntity.telecom = {}
   A.assignedEntity.telecom.use = 'WP'
   A.assignedEntity.telecom.value = 'tel:1-231-421-8505'
   A.assignedEntity.assignedPerson = {
      name = {
         given = {Text='Northern Physicians'},
         family = {Text='Organization'}
      }
   }
end


function FillDocumentationOf(docOf)
   docOf.serviceEvent = {}
   do
      local sE = docOf.serviceEvent
      sE.effectiveTime = {}
      sE.effectiveTime.low = {value='201208060028+0500'}
      sE.performer = {}
      do
         local p = sE.performer
         -- Note: IG forces typeCode to be binded to'PRF', but 2012 errata removed
         -- this constraint because the header constraint for Operative Note and
         -- other document types require different typeCode (e.g.PPRF).
         p.typeCode = ''
         p.assignedEntity = {}
         p.assignedEntity.id = {}
         p.assignedEntity.id = {root = '2.16.840.1.113883.4.6'}
         p.assignedEntity.code = fillNullFlavor('14843')
         -- p.assignedEntity.code = {
         --  code="200000000X",
         --codeSystem="2.16.840.1.113883.6.101",
         --displayName="Allopathic and Osteopathic Physicians",
         --codeSystemName="Provider Codes"
         --}
         p.typeCode = 'PRF'
         p.functionCode = fillNullFlavor()
         --p.functionCode = {
         -- code='PP', codeSystem='2.16.840.1.113883.5.88',
         --displayName="Primary Care Provider", codeSystemName='ParticipationFunction'
         --}
         p.time = {
            low = {value='00000000'},
            high = {value='00000000'}
         }
      end
      -- Note this value is not selected from a value set
      sE.classCode = 'PCPR'
      --sE.effectiveTime.high = {value='201208060058+0500'}
      sE.effectiveTime.low = fillNullFlavor()
      sE.effectiveTime.high = fillNullFlavor()
   end
end


function FillStructuredBody(sB, AllergyData, MedsData, PayersData, LabsData, VitalsData, HistoryData, EncountersData, ProblemsData, ProceduresData)
   -- structuredBody contains a list of component sections in a specific order
   sB.component = {}
   fillAllergies(sB, AllergyData)
   fillMedications(sB, MedsData)
   fillPayers(sB,PayersData)
   fillProblems(sB, ProblemsData)
   fillProcedures(sB, ProceduresData)
   fillResults(sB, LabsData)
   fillVitals(sB, VitalsData)
   fillSocialHistory(sB, HistoryData)
   fillEncounters(sB, EncountersData)

end

