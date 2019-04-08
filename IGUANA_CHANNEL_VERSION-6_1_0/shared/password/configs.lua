local configs = {}

-- 1) Define the key that uses for all password encryption
configs.key = "C59p7A2EfePNVVME"

-- 2) Define the directory that all encrypted files are stored
configs.folderName = "passwords"

-- 3) Define the individual encrypted file names
configs.fileNames = {
   APP_USERNAME = "APP_USERNAME",
   APP_PASSWORD = "APP_PASSWORD"
}

return configs