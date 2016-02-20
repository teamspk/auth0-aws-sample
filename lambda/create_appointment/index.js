var AWS = require('aws-sdk');
//var DOC = require('dynamodb-doc');
//var dynamo = new DOC.DynamoDB();
var dynamo = new AWS.DynamoDB.DocumentClient();

// TODO: documents should be array
// TODO: auth/unauth
// { client_project: 'aaa', 
//   appointment: { attendees: 'aa, bb', summary: 'xxxxxxx', documents: 'http://box.com/abc', duration: '2h'}
// }
// test:
// {
//   "client_project": "test",
//     "appointment": {"key":"value"}
//  }
exports.handler = function(event, context) {
  console.log('Received event:', JSON.stringify(event, null, 2));
  if (event.client_project && event.appointment) {
    var item = { client_project: event.client_project,
                 created_at: new Date().toISOString(),
                 appointment: event.appointment
            };

    var cb = function(err, data) {
        if(err) {
            console.log(err);
            context.fail('unable to update appointments at this time');
        } else {
            console.log(data);
                context.succeed(null, data);
        }
    };
    dynamo.put({TableName:"sparkl-appointments2", Item:item}, cb);
  } else {
    context.fail('invalid params');
  }
};
