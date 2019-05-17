-- The AWS S3 Adapter Module
--
-- Copyright (c) 2019 iNTERFACEWARE Inc. ALL RIGHTS RESERVED
-- iNTERFACEWARE permits you to use, modify, and distribute this file in accordance
-- with the terms of the iNTERFACEWARE license agreement accompanying the software
-- in which it is used.
--
-- This new version of the module enables Iguana to upload and download files from AWS S3.
--
-- Version:1.0

local s3API = require 'aws.s3API'

function main(Data)
   -- 1) Create an IAM user and assign the "AmazonS3FullAccess" permission
   -- https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_manage.html?icmpid=docs_iam_console
   
   -- 2) Create IAM user Access Key and update "Access Key" and "Access Key ID" in aws/configuration.lua
   
   -- 3) Create S3 bucket in AWS and update S3 bucket name and region in aws/configuration.lua
   -- https://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html
     
   -- 4) Define S3 bucket absolute file path
   local canonicalendpoint = '/JSON/patient-schema.json'
   
   -- 5) Put data in S3
   s3API.uploadFile(Data, canonicalendpoint)
   
   -- 6) Get data in S3
   local file = s3API.readFile(canonicalendpoint)
end