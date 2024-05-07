#!/bin/bash

# Set variables
S3_BUCKET_NAME="deenstatic"
CLOUDFRONT_DIST_NAME="deen-static-cdn"
DOMAIN_NAME="s3cdn.mmuyideen.xyz"

echo "---------------------------"
echo "|   Creating S3 Bucket    |"
echo "---------------------------"

# Create S3 bucket
aws s3api create-bucket \
  --bucket $S3_BUCKET_NAME\
  --region us-east-1

# upload web files
aws s3 cp \
  web/ \
  s3://$S3_BUCKET_NAME/ \
  --recursive

# Configure static website hosting
aws s3 website \
  s3://$S3_BUCKET_NAME/ \
  --index-document index.html

# enable public access
aws s3api put-public-access-block \
  --bucket $S3_BUCKET_NAME \
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# attach bucket policy
aws s3api put-bucket-policy \
  --bucket $S3_BUCKET_NAME \
  --policy file://policy.json

echo "----------------------------------------------------------------------------------------------"
echo "|      S3 bucket created successfully with static web hosting enab;ed and public access      |"
echo "----------------------------------------------------------------------------------------------"



echo "-------------------------------------"
echo "|      Creating ACM Certificate      |"
echo "-------------------------------------"

# Run the aws acm request-certificate command and capture the output
ACM_CERT_ARN=$(aws acm request-certificate \
  --domain-name $DOMAIN_NAME \
  --validation-method DNS | jq -r '.CertificateArn')
  
echo "[ACM]"   Certificate ARN: $ACM_CERT_ARN

sleep 20 #tit takes some time to create and get the values

# get values for CNAME verification
VALIDATION_NAME="$(aws acm describe-certificate \
  --certificate-arn $ACM_CERT_ARN \
  --query "Certificate.DomainValidationOptions[?DomainName=='$DOMAIN_NAME'].ResourceRecord.Name" \
  --output text)"

VALIDATION_VALUE="$(aws acm describe-certificate \
  --certificate-arn "$ACM_CERT_ARN" \
  --query "Certificate.DomainValidationOptions[?DomainName=='$DOMAIN_NAME'].ResourceRecord.Value" \
  --output text)"

echo "[ACM]          Certificate validation record: $VALIDATION_NAME CNAME $VALIDATION_VALUE"

{
  echo "VALIDATION_NAME=$VALIDATION_NAME"
  echo "VALIDATION_VALUE=$VALIDATION_VALUE"
} > validation_data.txt


echo "-----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "|      Update the CNAME records with your domain provider or Route 53 records with the values shown above or from the validation_data.txt file      |"
echo "-----------------------------------------------------------------------------------------------------------------------------------------------------"

# Wait for ACM certificate validation, this step may take a few minutes
echo "Waiting for ACM certificate validation..."
aws acm wait certificate-validated --certificate-arn $ACM_CERT_ARN

ACM_CERTIFICATE_STATUS="$(aws acm describe-certificate \
  --certificate-arn "$ACM_CERT_ARN" \
  --query "Certificate.Status" \
  --output text)"



# Create CloudFront distribution
aws cloudfront create-distribution \
  --origin-domain-name $S3_BUCKET_NAME.s3-website-us-east-1.amazonaws.com \
  --default-root-object index.html \
  --region us-east-1 \
  --no-cli-pager

echo "-------------------------------------"
echo "|  Cloudfront created successfullly |"
echo "-------------------------------------"


