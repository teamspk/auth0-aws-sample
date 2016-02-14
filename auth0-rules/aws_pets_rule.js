function (user, context, callback) {
  if(context.clientID === 'iDC9GHTe9nM2w1L146zn2o7qxEgpoEZI') {
    var socialRoleInfo = {
      role:"arn:aws:iam::713403314913:role/auth0-api-social-role",
      principal: "arn:aws:iam::713403314913:saml-provider/auth0-provider"
    };

    var adminRoleInfo = {
      role:"arn:aws:iam::713403314913:role/auth0-api-role",
      principal: "arn:aws:iam::713403314913:saml-provider/auth0-provider"
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

  } else {
    callback(null, user, context);
  }
}
