import datetime
import json
import urllib2
import base64
import gzip
from StringIO import StringIO

print('Loading function')

class SlackWrapper:
    #slack
    __hook = 'T02M3K4PZ/B051H1SD4/tCnPNlI2YhJInc1C0TZfgJ11' #mr-frank
    #__hook = 'T02MT19RP/B0S3A88LC/R9hsZ8PDTw2vjHmh8vyTKssZ' #teamspk
    __channel = '#test'
   # __channel = '#cloudwatch_logs'
    __icon_url = 'https://raw.githubusercontent.com/donnemartin/dev-setup-resources/master/res/aws_lambda.png'
    __username = 'lambda'

    #def __init__(self, hook, channel, icon_url, username):
    #    pass
    def __init__(self, username = __username):
        self.username = username

    def post(self, posttext):
        params = json.dumps({ 
                  'channel': self.__channel , 
                  'text':posttext,
                  'icon_url': self.__icon_url,
                  'username':self.username
                  })
        url = 'https://hooks.slack.com/services/' + self.__hook
        req = urllib2.Request(url, params)
        response = urllib2.urlopen(req)
        code, res =  response.getcode(), response.read()
        if (code == 200):
            msg = "Successfully posted to Slack"
            print msg
            return msg
        else:
            msg = "Failed to post to Slack"
            print code, res
            raise Exception(msg + res)

class JST(datetime.tzinfo):
    def utcoffset(self, dt):
        return datetime.timedelta(hours=9)
    def dst(self, dt):
        return datetime.timedelta(0)
    def tzname(self, dt):
        return "JST"    

def get_events(record):
    decoded_data = record.decode('base64')
    unzipped_data = gzip.GzipFile(fileobj=StringIO(decoded_data)).read()
    json_data = json.loads(unzipped_data)
    first_time = json_data['logEvents'][0]['timestamp']/1000.0
    events= "`" + datetime.datetime.fromtimestamp(first_time, tz=JST()).strftime('%Y-%m-%d %H:%M:%S%z') + "`\n"
    for data in json_data['logEvents']:
        events += data['message']
    return events, json_data['logGroup']

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))
    
    if ("awslogs" in event):
        message, log_group = get_events(event['awslogs']['data'])
        slack = SlackWrapper(log_group)
        return slack.post(message)
    elif ("Records" in event):
        #for record in event['Records']:
        #print(record['eventID'])
        #print(record['eventName'])
        #print("DynamoDB Record: " + json.dumps(record['dynamodb'], indent=2))
        print('Successfully processed {} records.'.format(len(event['Records'])))
        r = json.dumps(event['Records'][0])
        print(r)
        ddb = json.loads(r)['dynamodb']
        key = ddb['Keys']
        if not ('NewImage' in ddb):
            message = "Deleted appointment for " + key['client_project']['S']
        elif 'confirmed_at' in ddb['NewImage']:
            message = "Client has confirmed project " + key['client_project']['S'] + " at: " + ddb['NewImage']['confirmed_at']['S']
        else:
            message = "Created appointment for project project " + key['client_project']['S']
        slack = SlackWrapper('DynamoDB')
        return slack.post(message)    
    else:
        raise Exception('ERROR: not a cloudwatch logs event')

    #return event['key1']  # Echo back the first key value
    #raise Exception('Something went wrong')
