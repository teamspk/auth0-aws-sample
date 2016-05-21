var AWS = require('aws-sdk');
//var DOC = require('dynamodb-doc');
//var dynamo = new DOC.DynamoDB();
var dynamo = new AWS.DynamoDB.DocumentClient();
var jwt = require('jsonwebtoken');
var env = require('auth0-variables');
var fs = require('fs');

//var secret = env.AUTH0_SECRET;
    
exports.handler = function(event, context) {
    console.log('event:', event);
    console.log('context:', context);
    var client_project = event.client_project;
    var created_at = event.created_at;
    var userEmail = '';
    var appointment = {};

    // callback for reading appointment info from dynamodb
    var readcb = function(err, data) {
        if(err) {
            console.log('error on GetAppointmentInfo: ',err);
            context.done('failed to retrieve appointment information', null);
        } else {
            // make sure we have appointments
            console.log('reading::::');
            console.log(data);
            appointment = data.Items[0];
            if(appointment) {
                if (!appointment.confirmed_at) {
                    appointment.confirmed_at = new Date().toISOString();
                    console.log('confirming appointment at: ', appointment.confirmed_at);
                    //TODO: use update
                    dynamo.put({TableName:"sparkl-appointments", Item:appointment}, writecb);
                }else  {
                    console.log('appointment already confirmed');
                    context.done('That appointment is already confirmed.', null);
                }
            } else {
               console.log('appointment not found');
               context.done('That appointment is not available.', null);           
            }
        }
    };

    // callback for writing appointment info back to dynamddb.
    var writecb = function(err, data) {
        if(!err) {
            context.done(null, appointment);
        } else {
            console.log('error on GetAppointmentInfo: ',err);
            context.done('failed on update', null);
        }
    };

   // confirmation execution logic.
    if(event.authToken) {
        //var secretBuf = new Buffer(secret, 'base64');
        var secretBuf = fs.readFileSync('public.pem');
        jwt.verify(event.authToken, secretBuf, {algorithms: ['RS256', 'HS256']}, function(err, decoded) {
            if(err) {
                console.log('failed jwt verify: ', err, 'auth: ', event.authToken);
                context.done('authorization failure', null);
            //} else if(!decoded.email)
            //{
            //    console.log('err, email missing in jwt', 'jwt: ', decoded);
            //    context.done('authorization failure', null);
            } else {
                userEmail = decoded.email || 'noemail@example.com';
                roles = decoded.Oz0q5DMFlYVi3kbnM76yqCrqSUErJQIN.roles;
                console.log(roles);
                console.log('-----');
                //if ('admin' in roles) {
                //if ('user' in roles) {
                if (roles.indexOf('user') > -1) {
                    console.log('authorized for roles:', roles);
                    //console.log('authorized, petId', petId, 'userEmail:', userEmail);
                    //dynamo.getItem({TableName:"Pets", Key:{username:"default"}}, readcb);
                    var params = {
                        TableName: 'sparkl-appointments',
                          KeyConditionExpression: 'client_project = :hkey and created_at = :rkey',
                          ExpressionAttributeValues: {
                              ':hkey': client_project,
                              ':rkey': created_at
                          }
                    };
                    dynamo.query(params, readcb);
                } else {
                    console.log('not authorized for roles: ', roles)
                    context.done('authorization failure', null);
                }
            }
        });
    } else {
        console.log('invalid authorization token', event.authToken);
        context.done('authorization failure', null);
        // create custom error w/ code+msg. ref: http://www.jayway.com/2015/11/07/error-handling-in-api-gateway-and-aws-lambda
    }
};
