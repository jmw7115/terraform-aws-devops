# upload-file-function
import json
import boto3
import os
import sys
import uuid
from urllib.parse import unquote_plus

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    some_text = "test"
    lambda_path = event['srcPath'] + event['fileName']
    bucket_name = event['bucketName']
    dest_file_name = event['s3Path'] + event['fileName']
    os.system('echo testing... >'+lambda_path)
    s3 = boto3.resource("s3")
    s3.meta.client.upload_file(lambda_path, bucket_name, dest_file_name)

    return {
        'statusCode': 200,
        'body': json.dumps('file is created in:'+dest_file_name)
    }