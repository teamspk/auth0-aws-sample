var AWS = require('aws-sdk');
var DOC = require('dynamodb-doc');
var dynamo = new DOC.DynamoDB();

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var item = { client_project:"default",
                 appointment: event.appointment || {}
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
    dynamo.putItem({TableName:"sparkl-a", Item:item}, cb);
};
