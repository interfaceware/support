local configs = {}

-- AWS Authentication
configs.ACCESSKEY = '' -- Your AWS IAM user's Access Key ID
configs.SECRETKEY = '' -- Your AWS IAM user's Access Key

-- AWS S3 bucket service
configs.BUCKETNAME = 'ifw-docs-test' -- The name you gave your S3 bucket
configs.REGION     = 'us-east-2' -- Region reference https://docs.aws.amazon.com/general/latest/gr/rande.html
configs.SERVICE    = 's3'
configs.HOST       = configs.BUCKETNAME .. '.s3.' .. configs.REGION .. '.amazonaws.com'
configs.ENDPOINT   = 'https://' .. configs.BUCKETNAME .. '.s3.' .. configs.REGION .. '.amazonaws.com'

-- AWS API configurations
configs.READLIVE    = true
configs.UPLOADLIVE  = true
configs.POSTTIMEOUT = 120 -- in seconds
configs.RETRY       = 2
configs.RETRYPAUSE  = 10 -- in seconds

return configs