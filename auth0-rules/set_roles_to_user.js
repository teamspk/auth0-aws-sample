function (user, context, callback) {
  if(context.clientID === 'Oz0q5DMFlYVi3kbnM76yqCrqSUErJQIN') {
    
  user.app_metadata = user.app_metadata || {};
  // You can add a Role based on what you want
  // In this case I check domain
  var addRolesToUser = function(user, cb) {
    if (typeof(user.email) !== 'undefined') {
      if (user.email.indexOf('@test.com') > -1) {
        cb(null, {roles: ['admin']});
      }
    } else {
      cb(null, {roles: ['user']});
    }
  };

  addRolesToUser(user, function(err, roles) {
    if (err) {
      callback(err);
    } else {
      user.app_metadata.Oz0q5DMFlYVi3kbnM76yqCrqSUErJQIN = roles;
      auth0.users.updateAppMetadata(user.user_id, user.app_metadata)
        .then(function(){
          callback(null, user, context);
        })
        .catch(function(err){
          callback(err);
        });
    }
  });
    
    
    
  } else {
    callback(null, user, context);
  }
}
