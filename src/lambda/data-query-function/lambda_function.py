import json
import boto3
import os
import datetime

def lambda_handler(event, context):
    #try:
        #print("passed in event: {}".format(event))
        #print(event['query'])
        
        x = datetime.datetime.now()
        today = x.strftime("%G-%m-%d")
        #print(today)
        htmlTableData = ""
        selectType = ""
        # Establish select statement
        if 'query' in event:
            #print("YES")
            selectType = event['query']
            #print(type(selectType))
            # Select * from s3object where selectFormat like <something>
            #selectFormat = str(event['selectFormat'])
        
        
        # if selectType == "all":
        #     select_statement = "Select * from s3object"
        #     htmlTableStart = "<table class=\"center\"><tr><th>Type</th><th>Rate</th><th>Date</th></tr>"
        # else: 
        #     #select_statement = "Select Type,Rate from s3object where Date='{}'".format(today)
        #     select_statement = "Select Type,Rate from s3object"
        #     print(select_statement)
            
        htmlTableStart = "<table class=\"center\"><tr><th>Type</th><th>Rate</th><th>Date</th></tr>"

        ## This block queries the file using s3 select
        BUCKET_NAME = 'jmw7115-devops-challenge-bucket'
        KEY = 'data.csv'  
        s3 = boto3.client('s3','us-east-2')
        selectField = "Date"
        selectFieldValue = "2021-04-21"
        response = s3.select_object_content(
            Bucket = 'jmw7115-devops-challenge-bucket',
            Key = 'Active-data/data.csv',
            ExpressionType = 'SQL',
            Expression = "SELECT * FROM s3object s where s.\"Type\" = 'car'",
            #Expression = "SELECT * FROM s3object s where s.\"{}\" = '{}'".format(selectField,selectFieldValue),
            # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html?highlight=delete#S3.Client.select_object_content
            #InputSerialization = {'CSV': {"FileHeaderInfo": "Use"}},
            InputSerialization = {'CSV': {"RecordDelimiter": "\n", "FieldDelimiter": ",","FileHeaderInfo":"USE"}},
            #InputSerialization={'JSON': {'Type': 'DOCUMENT'}},
            OutputSerialization = {'JSON': {'RecordDelimiter': "\n"}},
        )

        ##
        # reference: https://www.linkedin.com/pulse/aws-s3-select-using-boto3-pyspark-mehul-thakkar
        data_dict = {}
        htmlTableData = ""
        for e in response['Payload']:
            if 'Records' in e:
                json_record = e['Records']['Payload'].decode('utf-8')
                recs = json_record.split('\n')
                for r in recs:
                        if r != "":
                            json_data = json.loads(r)
                            # start table row
                            htmlTableData = htmlTableData + "<tr>"
                            for k in json_data.keys():
                                #print(json_data[k])
                                #print("<td>{}</td>".format(json_data[k]))
                                s = "<td>{}</td>".format(json_data[k])
                                htmlTableData = htmlTableData + s
                                #print(htmlTableData)
                            # end table row
                            htmlTableData = htmlTableData + "</tr>"
                                
            elif 'Stats' in event:
                statsDetails = event['Stats']['Details']
                #print("Bytes scanned: ")
                #print(statsDetails['BytesScanned'])
                #print("Bytes processed: ")
                #print(statsDetails['BytesProcessed'])
                
        #print(type(json_data))
        #print(json_data)
        #print(htmlTableData)
        theInputForm = """
<tr>
<td colspan="3">        
<form action="">
  <p><b>Please make a selection: </b></p>
  <input type="radio" id="all" name="queryaction" value="all">
  <label for="allrates">All Rates</label><br>
  <input type="radio" id="female" name="queryaction" value="todaysrate">
  <label for="todaysrate">Today's Rates</label><br>
  <input type="radio" id="other" name="queryaction" value="other">
  <label for="other">Other</label><br><br><br>
  <input type="submit" value="Submit">
</form>
</td>
</tr>        
        """


        htmlTablEend = "</table>"

    
        theMessage = htmlTableStart + htmlTableData + theInputForm + htmlTablEend
        theTitle = "All Rates"
        #print(theMessage)

    #finally:
        return { "StatusCode": 200,"title": theTitle, "message": theMessage }