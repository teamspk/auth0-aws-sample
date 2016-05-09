function (user, context, callback) {
  if(context.clientID === 'Oz0q5DMFlYVi3kbnM76yqCrqSUErJQIN') {
    var socialRoleInfo = {
      role:"arn:aws:iam::951720451008:role/auth0-api-social-role",
      principal: "arn:aws:iam::951720451008:saml-provider/auth0-provider",
      isAdmin: false
    };

    var adminRoleInfo = {
      role:"arn:aws:iam::951720451008:role/auth0-api-role",
      principal: "arn:aws:iam::951720451008:saml-provider/auth0-provider",
      isAdmin: true
    };

    var requestRole = context.request.body.role;
    var requestPrincipal = context.request.body.principal;
    var allowedRole = null;

    if(user.identities[0].isSocial === false) {
      allowedRole = adminRoleInfo;
    } else {
      allowedRole = socialRoleInfo;
    }

    if((requestRole && requestRole !== allowedRole.role) ||
       (requestPrincipal && requestPrincipal !== allowedRole.principal)) {
        console.log('mismatch in requested role:',requestRole, ':', requestPrincipal);
        console.log('overridding');
    } else {
      console.log('valid or no role requested for delegation');
    }

    context.addonConfiguration = context.addonConfiguration || {};
    context.addonConfiguration.aws = context.addonConfiguration.aws || {};
    context.addonConfiguration.aws.role = allowedRole.role;
    context.addonConfiguration.aws.principal = allowedRole.principal;
    callback(null, user, context);
    
    
/*    
    user.app_metadata = user.app_metadata || {};
    
    var addRolesToUser = function(user, cb) {
    if (typeof(user.email) !== undefined) {
      if (user.email.indexOf('@gonto.com') > -1) {
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
*/  

    
    
  } else {
    callback(null, user, context);
  }
}
