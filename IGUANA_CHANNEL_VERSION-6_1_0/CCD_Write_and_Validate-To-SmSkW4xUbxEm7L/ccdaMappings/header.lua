local header = {}

-- Local Functions ---


-- Public Functions ---
function header.FillHeader(CD)
   -- Since a CCDA document must have two templateId elements in its header,
   -- one for US Realm Heaer and one for the Type of the CCDA document, data
   -- must be passed in as an array, and the order matters.
   -- In fact, the CCDA generator wraps an input table in an array before
   -- processing it.
   CD.templateId = {}
   table.insert(CD.templateId, {root='2.16.840.1.113883.10.20.22.1.2', extension='2015-08-01'})
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
   CD.setId = {extension='111199021', root='2.16.840.1.113883.19.5.99999.19'}
   CD.versionNumber = {value=1}
end


function header.FillrecordTarget(rT)
   rT.patientRole = {}
   do
      -- Create an alias so that we can do pR.id = {} instead of rT.patientRole.id = {}
      local pR = rT.patientRole
      pR.id = {}
      pR.id = {extension="12345", root="2.16.840.1.113883.19"}
      pR.addr = {}
      pR.addr = {
         ['streetAddressLine'] = {Text = '1111 BadPassword St.'},
         ['city'] = {Text = 'Silver Spring'},
         ['state'] = {Text = 'CA'},
         ['country'] = {Text = 'US'},
         ['postalCode'] = {Text = '20001'}
      }
      pR.addr.use = voc.PostalAddressUse["primary home"]
      pR.telecom = {}
      -- Note: although selecting a value for use here is not the exactly the same as for code,
      -- logic was added in ccda.generates to allow us to assign a use value in a similar way.
      pR.telecom.use = voc["Telecom Use (US Realm Header)"]["Work place"]
      pR.telecom.value = 'tel:(781)555-1212'
      
      pR.patient = {}
      do
         local p = pR.patient
         p.name = {}
         -- text nodes
         p.name.given = {Text = 'Health'}
         p.name.family = {qualifier='SP', Text = 'Level'}
         p.name.use = 'L'
         -- OR
--         p.name.use = voc.EntityNameUse.Legal
         p.administrativeGenderCode = voc["Administrative Gender (HL7 V3)"].Male
         p.birthTime = {value = '20000229'}
         p.maritalStatusCode = voc["Marital Status Value Set"].Married
         p.religiousAffiliationCode = voc["Religious Affiliation Value Set"]["Christian (non-Catholic, non-specific)"]
         p.raceCode = voc["Race Value Set"].White
         p['sdtc:raceCode'] = voc["Race Value Set"]["Native Hawaiian or Other Pacific Islander"]
         p.ethnicGroupCode = voc.EthnicityGroup["Not Hispanic or Latino"]
         
         p.guardian = {}
         -- ResponsibleParty value set not in voc, so we goining to hardcode here.
         -- If this value set is frequently used, consider adding it to CCDA/vocab.lua
         p.guardian.code = {
            code="POWATT", displayName="Power of Attorney", codeSystem="2.16.840.1.113883.1.11.19830", codeSystemName="ResponsibleParty"
         }
         p.guardian.addr = {
            ['streetAddressLine'] = {Text = '1111 BadPassword St.'},
            ['city'] = {Text = 'Silver Spring'},
            ['state'] = {Text = 'CA'},
            ['country'] = {Text = 'US'},
            ['postalCode'] = {Text = '20001'}
         }
         p.guardian.addr.use = voc.PostalAddressUse["primary home"]
         p.guardian.telecom = {}
         -- Note: although selecting a value for use here is not the exactly the same as for code,
         -- logic was added in ccda.generates to allow us to assign a use value in a similar way.
         p.guardian.telecom.use = voc["Telecom Use (US Realm Header)"]["Mobile contact"]
         p.guardian.telecom.value = 'tel:(781)555-2008'
         p.guardian.guardianPerson = {
            name = {
               given = {Text = 'Boris'},
               family = {Text = 'Level'}
            }
         }
         
         p.birthplace  = {}
         p.birthplace.place = {}
         p.birthplace.place.addr = {
            ['streetAddressLine'] = {Text = '1234 BadPassword St.'},
            ['city'] = {Text = 'Silver Spring'},
            ['state'] = {Text = 'CA'},
            ['country'] = {Text = 'US'},
            ['postalCode'] = {Text = '20001'}
         }
         p.languageCommunication = {}
         p.languageCommunication.languageCode = voc.Language.English
         p.languageCommunication.modeCode = voc["LanguageAbilityMode Value Set"]["Expressed spoken"]
         p.languageCommunication.proficiencyLevelCode = voc.LanguageAbilityProficiency.Excellent
         p.languageCommunication.preferenceInd = {value = 'true'}
      end
      
      pR.providerOrganization = {}
      do
         local PO = pR.providerOrganization
         PO.id = {root='2.16.840.1.113883.4.6'}
         -- The name element of organization has a text element
         PO.name = {Text='Get Well Clinic'}
         PO.telecom = {
            use = 'WP',
            value = 'tel: 555-555-5000'
         }
         PO.addr = {
            ['streetAddressLine'] = {Text = '0000 BadPassword St.'},
            ['city'] = {Text = 'Silver Spring'},
            ['state'] = {Text = 'CA'},
            ['country'] = {Text = 'US'},
            ['postalCode'] = {Text = '20001'}
         }
      end
   end
end


function header.FillAuthor(a)
   a.time = {value='20050806'}
   a.assignedAuthor = {}
   do
      local aA = a.assignedAuthor
      aA.id = {root=''}
      aA.code = {}
      aA.code = voc["Healthcare Provider Taxonomy (HIPAA)"]["Adult Health"]
      aA.addr = {}
      aA.addr = {
         ['streetAddressLine'] = {Text = '1002 Healthcare Drive'},
         ['city'] = {Text = 'Portland'},
         ['state'] = {Text = 'OR'},
         ['country'] = {Text = 'US'},
         ['postalCode'] = {Text = '97266'}
      }
      aA.telecom = {value='tel:555-555-1002'}
      aA.telecom.use = voc["Telecom Use (US Realm Header)"]["Work place"]
      aA.assignedPerson = {}
      aA.id.root = '2.16.840.1.113883.4.6'
      aA.assignedPerson.name = {}
      aA.assignedPerson.name.family = {Text='Seven'}
      aA.assignedPerson.name.given = {Text='Henry'}
   end
end


function header.FillDataEnterer(de)
   de.assignedEntity = {
      id = {extension="333777777", root="2.16.840.1.113883.4.6"},
      addr = {
         streetAddressLine = {Text="1007 Healthcare Drive"},
         city = {Text="Portland"},
         state = {Text="OR"},
         postalCode = {Text="99123"},
         country = {Text="US"}
      },
      telecom = {use="WP", value="tel:+1(555)555-1050"},
      assignedPerson = {
         name = {
            given = {Text="Ellen"},
            family = {Text="Enter"}
         }
      }
   }
end


function header.FillInformant(i)
   i.assignedEntity = {
      id = {extension="888888888", root="2.16.840.1.113883.4.6"},
      addr = {
         streetAddressLine = {Text="1007 Healthcare Drive"},
         city = {Text="Portland"},
         state = {Text="OR"},
         postalCode = {Text="99123"},
         country = {Text="US"}
      },
      telecom = {use="WP", value="tel:+1(555)555-1005"},
      assignedPerson = {
         name = {
            given = {Text="Harold"},
            family = {Text="Hippocrates"},
            suffix = {qualifier="AC", Text="M.D."}
         }
      },
      representedOrganization = {
         name = {Text="The DoctorsApart Physician Group"}
      }
   }
end


function header.FillCustodian(c)
   c.assignedCustodian = {}
   c.assignedCustodian.representedCustodianOrganization = {}
   do
      local rCO = c.assignedCustodian.representedCustodianOrganization
      rCO.id = {}
      rCO.id = {root='2.16.840.1.113883.4.6'}
      rCO.name = {}
      -- The name element of organization has a text element
      rCO.name = {Text='Good Health Clinic'}
      rCO.telecom = {}
      rCO.telecom = {
         value = 'tel: 555-555-1002',
         use = voc["Telecom Use (US Realm Header)"]["Work place"]
      }
      rCO.addr = {}
      rCO.addr = {
         ['streetAddressLine'] = {Text = '1002 Healthcare Drive'},
         ['city'] = {Text = 'Portland'},
         ['state'] = {Text = 'OR'},
         ['country'] = {Text = 'US'},
         ['postalCode'] = {Text = '97266'}
      }
   end
end


function header.FillInformationRecipient(IR)
	IR.intendedRecipient = {}
   IR.intendedRecipient.informationRecipient = {}
   IR.intendedRecipient.informationRecipient.name = {}
   IR.intendedRecipient.informationRecipient.name = {
      given = {Text='Henry'},
      family = {Text='Seven'}
   }
   IR.intendedRecipient.receivedOrganization = {}
   -- The name element of organization has a text element
   IR.intendedRecipient.receivedOrganization.name = {Text='Get Well Clinic'}
end


function header.FillLegalAuthenticator(lA)
   lA.time = {}
   lA.time = {value='20120806'}
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
      aE.code = voc["Healthcare Provider Taxonomy (HIPAA)"]["Adult Medicine"]
      aE.addr = {}
      aE.addr = {
         ['streetAddressLine'] = {Text = '1002 Healthcare Drive'},
         ['city'] = {Text = 'Portland'},
         ['state'] = {Text = 'OR'},
         ['country'] = {Text = 'US'},
         ['postalCode'] = {Text = '97266'}
      }
      
      aE.telecom = {}
      aE.telecom.use = voc["Telecom Use (US Realm Header)"]["Work place"]
      aE.telecom.value = 'tel:555-555-1007'
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
      aE.prefix = {Text='Dr.'}
      aE.assignedPerson.name.family = {Text='Seven'}
      aE.assignedPerson.name.given = {Text='Henry'}
   end
end


function header.FillAuthenticator(A)
   A.time = {}
   A.time.value = '20050329224411+0500'
   A.signatureCode = {}
   A.signatureCode.code = 'S'
   A.assignedEntity = {}
   A.assignedEntity.id = {root="2.16.840.1.113883.4.6"}
   A.assignedEntity.code = voc["Healthcare Provider Taxonomy (HIPAA)"]["Adult Medicine"]
   A.assignedEntity.addr = {
      ['streetAddressLine'] = {Text = '1002 Healthcare Drive'},
      ['city'] = {Text = 'Portland'},
      ['state'] = {Text = 'OR'},
      ['country'] = {Text = 'US'},
      ['postalCode'] = {Text = '97266'}
   }
   A.assignedEntity.telecom = {}
   A.assignedEntity.telecom.use = 'WP'
   A.assignedEntity.telecom.value = 'tel:(555)555-1003'
   A.assignedEntity.assignedPerson = {
      name = {
         given = {Text='Henry'},
         family = {Text='Seven'}
      }
   }
end


function header.FillDocumentationOf(docOf)
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
         p.assignedEntity.code = {}
         p.assignedEntity.code = {
            code="200000000X",
            codeSystem="2.16.840.1.113883.6.101",
            displayName="Allopathic and Osteopathic Physicians",
            codeSystemName="Provider Codes"
         }
         p.typeCode = 'PRF'
         p.functionCode = {
            code='PP', codeSystem='2.16.840.1.113883.5.88',
            displayName="Primary Care Provider", codeSystemName='ParticipationFunction'
         }
         p.time = {
            low = {value='20020716'},
            high = {value='20020915'}
         }
      end
      -- Note this value is not selected from a value set
      sE.classCode = 'PCPR'
      sE.effectiveTime.high = {value='201208060058+0500'}
   end
end


return header