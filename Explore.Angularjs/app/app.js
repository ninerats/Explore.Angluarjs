var app = angular.module("exploreApp", ["ui.router"]);


var configFn = function ($stateProvider, $urlRouterProvider) {

    $urlRouterProvider.otherwise('/home');
    $stateProvider
        .state('home', {
            url: '/home',
            controller: "homeCtrl",
            template: "some text"
        });
};


app.config(configFn);