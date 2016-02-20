var AWS = require('aws-sdk');
var DOC = require('dynamodb-doc');
var dynamo = new DOC.DynamoDB();
//var dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = function(event, context) {
   var cb = function(err, data) {
      if(err) {
         console.log('error on SparklGetAppointments: ',err);
         context.done('Unable to retrieve appointments', null);
      } else {
         if(data.Item && data.Item.appointment) {
             context.done(null, data.Item.appointment);
         } else {
              context.done(null, {});
         }
      }
   };
///var params = { }
//params.TableName = "sparkl-appointments";
//var key = { "ExampleHashKey": "default" };
//params.Key = key;
//dynamo.getItem(params, function(err, data) {
   dynamo.getItem({TableName:"sparkl-a", Key:{client_project:"default"}}, cb);
};
