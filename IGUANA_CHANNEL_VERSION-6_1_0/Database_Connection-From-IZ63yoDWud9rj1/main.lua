local db2 = require "db2"

-- Option1: Define persisted database connection that does not require connection close
local dbConnect = db2.connect{api=db.SQLITE, name='sampleDB.sqlite',user='', password=''}

function main()
   -- The code uses a single database connection that is managed automatically
   -- by the db.Connect module - the connection is automatically created if it 
   -- does not exist and kept open between queries (for improved performance).  
   -- If the database connection is lost for any reason then it automatically
   -- reconnects - the reconnection is retried s specified number of times, 
   -- with a specified interval between the retries. If the reconnection is 
   -- not succesful then the channel is stopped. All connections, retries 
   -- and associated errors are logged.

   -- create a sample patient table if needed
   dbConnect:execute{sql=[[CREATE TABLE patient_test(
      Id INT,
      FirstName VARCHAR(45),
      LastName VARCHAR(45)
   )]], 
      live =false}


   -- insert a row into patient_test table if needed
   dbConnect:execute{sql=[[INSERT INTO patient_test (Id, LastName, FirstName) 
      VALUES (1,'Adams', 'Richard')]], 
      live =false}


   -- select all rows from patient_test table
   local result = dbConnect:query{sql="SELECT * FROM patient_test"}

   -- delete the patient_test table if needed
   dbConnect:execute{sql='DROP TABLE patient_test', live=false}

   -- Option2: define local database connection that requires to close connection in the end
   --local dbConnect = db2.connect{api=db.SQLITE, name='sampleDB.sqlite',user='', password=''}
   --dbConnect:close{} -- close is needed if dbConnect defines inside Main
end