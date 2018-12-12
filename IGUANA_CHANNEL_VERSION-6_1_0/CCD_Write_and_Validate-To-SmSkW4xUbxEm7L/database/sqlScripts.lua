local sql = {
   ['SELECT_ACCOUNTS'] = [[SELECT * FROM Accounts WHERE Patient_ID=$(PatientIdValue)]],
   ['SELECT_ALLERGIES'] = [[SELECT * FROM Allergies WHERE Patient_ID=$(PatientIdValue)]],
   ['SELECT_MEDICATIONS'] = [[SELECT * FROM Medications WHERE Patient_ID=$(PatientIdValue)]],
   ['SELECT_PATIENT_INSURANCE'] = [[SELECT * FROM Patient_Insurance WHERE Patient_ID=$(PatientIdValue)]],
   ['SELECT_LABS'] = [[SELECT * FROM Labs WHERE Patient_ID=$(PatientIdValue)]],
   ['SELECT_VITALS'] = [[SELECT * FROM Vitals WHERE Patient_ID=$(PatientIdValue)]],
   ['SELECT_SOCIAL_HISTORY'] = [[SELECT * FROM Social_History WHERE Patient_ID=$(PatientIdValue)]],
   ['SELECT_PROBLEMS_LIST'] = [[SELECT * FROM Problems_List WHERE Patient_ID=$(PatientIdValue)]],
   ['SELECT_APPOINTMENTS'] = [[SELECT * FROM Appointments WHERE Patient_ID=$(PatientIdValue)]],
   ['SELECT_PROCEDURES'] = [[SELECT * FROM Procedures WHERE Patient_ID=$(PatientIdValue)]]
}

return sql