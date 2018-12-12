local script = require 'database.sqlScripts'

local sqlAPI = {}

-- Local functions
local function InterpSQL(s, tab)
   return (s:gsub('($%b())', function(w) return tab[w:sub(3, -2)] or w end))
end

-- Public functions
function sqlAPI.getAccounts(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_ACCOUNTS, {PatientIdValue=patientId})
   local accounts = conn:query{sql=selectScript}
   return accounts
end

function sqlAPI.getAllergies(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_ALLERGIES, {PatientIdValue=patientId})
   local allergies = conn:query{sql=selectScript}
   return allergies
end

function sqlAPI.getMedications(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_MEDICATIONS, {PatientIdValue=patientId})
   local medications = conn:query{sql=selectScript}
   return medications
end

function sqlAPI.getInsurance(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_PATIENT_INSURANCE, {PatientIdValue=patientId})
   local insurance = conn:query{sql=selectScript}
   return insurance
end

function sqlAPI.getLabs(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_LABS, {PatientIdValue=patientId})
   local labs = conn:query{sql=selectScript}
   return labs
end

function sqlAPI.getVitals(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_VITALS, {PatientIdValue=patientId})
   local vitals = conn:query{sql=selectScript}
   return vitals
end

function sqlAPI.getSocialHistory(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_SOCIAL_HISTORY, {PatientIdValue=patientId})
   local socials = conn:query{sql=selectScript}
   return socials
end

function sqlAPI.getProblems(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_PROBLEMS_LIST, {PatientIdValue=patientId})
   local problems = conn:query{sql=selectScript}
   return problems
end

function sqlAPI.getAppointments(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_APPOINTMENTS, {PatientIdValue=patientId})
   local appointments = conn:query{sql=selectScript}
   return appointments
end

function sqlAPI.getProcedures(conn, patientId)
   local selectScript = InterpSQL(script.SELECT_PROCEDURES, {PatientIdValue=patientId})
   local procedures = conn:query{sql=selectScript}
   return procedures
end

return sqlAPI