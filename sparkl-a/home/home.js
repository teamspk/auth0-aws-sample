angular.module( 'sample.home', ['auth0'])
.controller( 'HomeCtrl', function HomeController( $scope, auth, $http, $location, store, $sce ) {
  $scope.appointments = [];
  $scope.isAdmin = store.get('profile').isAdmin;
  $scope.profile = store.get('profile');
  $scope.adding = false;
  $scope.iframeUrl = '';

  function showError(response) {
    if (response instanceof Error) {
       console.log('Error', response.message);
    } else {
      console.log(response.data);
      console.log(response.status);
      console.log(response.headers);
      console.log(response.config);
    }
  }

  function getBearerToken() {
    var token = store.get('token');
    return "bearer " + token;
  }

  function getPets() {
//    window.alert('getPets not implemented');
    // this is unauthenticated
    var apigClient = apigClientFactory.newClient({
        region: 'ap-northeast-1' // The region where the API is deployed
    });

    console.log("getting pets");
    apigClient.appointmentsGet({},{})
      .then(function(response) {
        console.log("got pets");
        console.log(response);
        console.log(response.data);
        //response.data[8].appointment.documents = $sce.trustAsHtml('http://google.com');
        var url = response.data[8].appointment.documents
        //response.data[8].appointment.documents = $sce.trustAsHtml('<iframe src="' + url + '?direction=ASC&theme=dark" width="330" height="400" frameborder="0" allowfullscreen webkitallowfullscreen msallowfullscreen></iframe>');
        for (var i=0; i < response.data.length; i++) {
            response.data[i].appointment.documents = $sce.trustAsResourceUrl(response.data[i].appointment.documents);
//            response.data[i].appointment.summary = $sce.trustAsResourceUrl(response.data[i].appointment.summary);
        }
        $scope.appointments = response.data;
        $scope.$apply();
      }).catch(function (response) {
        alert('pets get failed');
        showError(response);
    });
  }

  // --- Add for updating --- 
  function getSecureApiClient() {
    var awstoken = store.get('awstoken');

    return apigClientFactory.newClient({
        accessKey: awstoken.AccessKeyId,
        secretKey: awstoken.SecretAccessKey,
        sessionToken: awstoken.SessionToken,
        region: 'ap-northeast-1' // Set to your region
    });
  }

  function putPets(client_pj, newAppointment) {
      //window.alert('putPets not implemented');
    var body = {client_project: client_pj, appointment: newAppointment};

    //var apigClient = apigClientFactory.newClient({
    //    region: 'ap-northeast-1' // set this to the region you are running in.
    //});
    var apigClient = getSecureApiClient();

    apigClient.appointmentsPost({},body)
      .then(function(response) {
        console.log('saved appointment: ');
        console.log(response);
       }).catch(function (response) {
        alert('appointment update failed');
        showError(response);
      });
  }

  // TODO: change to dicsussion_id
  function buyPet(user, params) {
      //window.alert('buyPet not implemented');
    var apigClient = getSecureApiClient();
    var body = {
      client_project: params[0],
      created_at : params[1],
      authToken: store.get('token')
    };
    console.log('buyPet with params', body);

    apigClient.appointmentsConfirmPost({}, body)
      .then(function(response) {
        console.log(response);
        console.log('appointments before assign in buyPet:');
        console.log($scope.appointments);
        //$scope.appointments = [response.data]; //[{}] one data MAYBE this should be another table
        //$scope.appointments.forEach( function(e, i, arr) {
            //if (e.client_project == body.client_project && e.created_at = body.created_at) {
        for (k in $scope.appointments) {
            if ($scope.appointments[k].client_project == body.client_project && $scope.appointments[k].created_at == body.created_at) {
                console.log('Replaceing ' + JSON.stringify($scope.appointments[k]) + ' with ' + JSON.stringify(response.data))
                $scope.appointments[k] = response.data;
                break;
            }
        }
        //$scope.appointments.push(response.data); //[{}] one data MAYBE this should be another table
        console.log('after assining appointments in buyPet');
        console.log($scope.appointments);
        //$scope.appointments = [response.data]; //[{}] one data MAYBE this should be another table
        console.log('before apply in buyPet');
        //console.log(response.data); {}
        $scope.$apply();
        console.log('applied');
      }).catch(function (response) {
        alert('confirm appointment failed');
        showError(response);
    });
  }
  
  $scope.addPets = function() {
    $scope.adding = true;
  }

  $scope.cancelAddPet = function() {
    $scope.adding = false;
  }

  $scope.removePet = function(id) {
    var index = -1;

     angular.forEach($scope.appointments, function(p, i) {
       if(p.id === id) index = i;
     });   
    
     if(index >= 0) {
        $scope.appointments.splice(index, 1);
        putPets($scope.appointments);
     }
  }

  $scope.buyPet = function(id) {
    var profile = store.get('profile');
    var user = profile.name || profile.email;
    buyPet(user, id);
  }

  $scope.savePet = function() {
    //var maxid = 0;

    //angular.forEach($scope.appointments, function(p) {
    //  if(p.id > maxid) maxid = p.id;
    //});
    
    var newAppointment = {};
    var client_pj = "";
    //newPet.id = maxid + 1;
    client_pj = $scope.client_project;
    newAppointment.attendees= $scope.appointment.attendees;
    newAppointment.summary = $scope.appointment.summary;
    newAppointment.documents = $scope.appointment.documents;
    $scope.appointment.attendees = "";
    $scope.appointment.summary = "";
    $scope.appointment.documents = "";
    $scope.appointments.push({client_project: client_pj, appointment: newAppointment, created_at: 'now'});
    //putPets($scope.appointments);
    console.log('going to save new appointment: ');
    console.log(newAppointment);
    console.log(client_pj);
    putPets(client_pj, newAppointment);
    $scope.adding = false;
  }

  $scope.logout = function() {
    auth.signout();
    store.remove('profile');
    store.remove('token');
    $location.path('/login');
  }

  getPets();

});
