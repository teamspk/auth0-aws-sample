var AWS = require('aws-sdk');
//var DOC = require('dynamodb-doc');
//var dynamo = new DOC.DynamoDB();
var dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = function(event, context) {
   var cb = function(err, data) {
      if(err) {
         console.log('error on SparklGetAppointments: ',err);
         context.done('Unable to retrieve appointments', null);
      } else {
         console.log(data.Items);
         if(data.Items && data.Items[0]) {
             context.done(null, data.Items);
         } else {
             context.done(null, {});
         }
      }
   };
//   dynamo.getItem({TableName:"sparkl-appointments", Key:{client_project:"default"}}, cb);
    var params = {
      TableName: 'sparkl-appointments',
      FilterExpression: 'created_at > :rkey',
      ExpressionAttributeValues: {
        ':rkey': '2016-02'
      }
    };
   dynamo.scan(params, cb);
};
