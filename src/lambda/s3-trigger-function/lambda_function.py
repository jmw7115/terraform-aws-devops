# s3-trigger-function
import json
import urllib.parse
import boto3
import datetime

print('Loading function')

s3 = boto3.client('s3')
s3resource = boto3.resource('s3')
x = datetime.datetime.now()
date_time = x.strftime("%Y-%m-%d-%H-%M-%S")

def lambda_handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))

    # Get the object from the event and show its content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    new_file_key = "Archive-Data/{}-{}".format(key,date_time)
    print(new_file_key)

    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        print("CONTENT TYPE: " + response['ContentType'])
        #s3jw = boto3.resource('s3')
        #s3.copy_object(bucket,new_file_key).copy_from(CopySource="{}/{}".format(bucket,key))
        copy_source = {
            'Bucket': bucket,
            'Key': key
        }
        new_bucket = s3resource.Bucket(bucket)
        obj = new_bucket.Object(new_file_key)
        obj.copy(copy_source)
        return response['ContentType']
    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
        raise e