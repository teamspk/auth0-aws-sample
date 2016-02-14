var AWS = require('aws-sdk');
var DOC = require('dynamodb-doc');
var dynamo = new DOC.DynamoDB();

exports.handler = function(event, context) {
   var petId = event.petId;
   var user = event.userName;
   var pets = {};
   console.log('start PetsPurchase, petId', petId, ' userName', user);

   var writecb = function(err, data) {
      if(!err) {
          context.done(null, pets);
      } else {
          console.log('error on GetPetsInfo: ',err);
          context.done('failed on update', null);
      }
   };

   var readcb = function(err, data) {
      if(err) {
          console.log('error on GetPetsInfo: ',err);
          context.done('failed to retrieve pet information', null);
      } else {
          // make sure we have pets
          if(data.Item && data.Item.pets) {
              pets = data.Item.pets;
              var found = false;

              for(var i = 0; i < pets.length && !found; i++) {
                  if(pets[i].id === petId) {
                     if(!pets[i].isSold) {
                        pets[i].isSold = true;
                        pets[i].soldTo = user;
                        var item = { username:"default",pets: pets};
                        dynamo.putItem({TableName:"Pets", Item:item}, writecb);
                        found = true;
                     }
                  }
               }
               if(!found) {
                 console.log('pet not found');
                 context.done('That pet is not available.', null);
               }
           } else {
              console.log('pet already sold');
              context.done('That pet is not available.', null);
           }
       }
   };

   dynamo.getItem({TableName:"Pets", Key:{username:"default"}}, readcb);
};
