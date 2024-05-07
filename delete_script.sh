#!/bin/bash

# empty bucket
aws s3 rb s3://deenstatic \
    --force

#disable cloudfront

#delete distribution
CLOUDFRONT_DIST_ID="$(aws cloudfront list-distributions \
  --query "DistributionList.Items[*].Id" \
  --output text)"

aws cloudfront delete-distribution \
    --id $CLOUDFRONT_DIST_ID \
    --if-match E1HI5RE7W8YT3D


#delete certificate
aws acm delete-certificate \
 --certificate-arn "arn:aws:acm:us-east-1:413677591682:certificate/adc156fe-ef95-42ac-ad38-698830d7b44f"
