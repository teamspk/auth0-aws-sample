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

  function getAppointments() {
//    window.alert('getAppointments not implemented');
    // this is unauthenticated
    var apigClient = apigClientFactory.newClient({
        region: 'ap-northeast-1' // The region where the API is deployed
    });

    console.log("getting appointments");
    apigClient.appointmentsGet({},{})
      .then(function(response) {
        console.log("got appointments");
        console.log(response);
        console.log(response.data);
        var url = response.data[8].appointment.documents
        for (var i=0; i < response.data.length; i++) {
            response.data[i].appointment.documents = $sce.trustAsResourceUrl(response.data[i].appointment.documents);
        }
        $scope.appointments = response.data;
        $scope.$apply();
      }).catch(function (response) {
        alert('getting appointments failed');
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

  function putAppointment(client_pj, newAppointment) {
      //window.alert('putAppointment not implemented');
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
  function confirmAppointment(user, params) {
      //window.alert('confirmAppointment not implemented');
    var apigClient = getSecureApiClient();
    var body = {
      client_project: params[0],
      created_at : params[1],
      authToken: store.get('token')
    };
    console.log('confirmAppointment with params', body);

    apigClient.appointmentsConfirmPost({}, body)
      .then(function(response) {
        console.log(response);
        console.log('appointments before assign in confirmAppointment:');
        console.log($scope.appointments);
        //$scope.appointments = [response.data]; //[{}] one data MAYBE this should be another table
        //$scope.appointments.forEach( function(e, i, arr) {
            //if (e.client_project == body.client_project && e.created_at = body.created_at) {
        for (k in $scope.appointments) {
            if ($scope.appointments[k].client_project == body.client_project && $scope.appointments[k].created_at == body.created_at) {
                console.log('Replaeing ' + JSON.stringify($scope.appointments[k]) + ' with ' + JSON.stringify(response.data))
                $scope.appointments[k] = response.data;
                break;
            }
        }
        //$scope.appointments.push(response.data); //[{}] one data MAYBE this should be another table
        console.log('after assining appointments in confirmAppointment');
        console.log($scope.appointments);
        //$scope.appointments = [response.data]; //[{}] one data MAYBE this should be another table
        console.log('before apply in confirmAppointment');
        //console.log(response.data); {}
        $scope.$apply();
        console.log('applied');
      }).catch(function (response) {
        alert('confirm appointment failed');
        showError(response);
    });
  }
  
  $scope.addAppointment = function() {
    $scope.adding = true;
  }

  $scope.cancelAddAppointment = function() {
    $scope.adding = false;
  }

  $scope.removeAppointment = function(id) {
    var index = -1;

     angular.forEach($scope.appointments, function(p, i) {
       if(p.id === id) index = i;
     });   
    
     if(index >= 0) {
        $scope.appointments.splice(index, 1);
        putAppointment($scope.appointments);
     }
  }

  $scope.confirmAppointment = function(id) {
    var profile = store.get('profile');
    var user = profile.name || profile.email;
    confirmAppointment(user, id);
  }

  $scope.saveAppointment = function() {
    //var maxid = 0;

    //angular.forEach($scope.appointments, function(p) {
    //  if(p.id > maxid) maxid = p.id;
    //});
    
    var newAppointment = {};
    var client_pj = "";
    client_pj = $scope.client_project;
    newAppointment.attendees= $scope.appointment.attendees;
    newAppointment.summary = $scope.appointment.summary;
    newAppointment.documents = $scope.appointment.documents;
    $scope.appointment.attendees = "";
    $scope.appointment.summary = "";
    $scope.appointment.documents = "";
    $scope.appointments.push({client_project: client_pj, appointment: newAppointment, created_at: 'now'});
    console.log('going to save new appointment: ');
    console.log(newAppointment);
    console.log(client_pj);
    putAppointment(client_pj, newAppointment);
    $scope.adding = false;
  }

  $scope.logout = function() {
    auth.signout();
    store.remove('profile');
    store.remove('token');
    $location.path('/login');
  }

  getAppointments();

});
