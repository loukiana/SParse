(function(){

    var app = angular.module('sparse', ['fileSystem']);
    var fs = require("fs");
    var appCfg= {
        CONFIG_DIR: "./config"
    };

    app.controller('NavCtrl', function($scope, $window, fileSystem) {
        $scope.terminal = [];
        $scope.log = [];

        this.init=function() {
            this.tab=0;

           /* var nw = require('nw.gui');
            var window = nw.Window;
            var newVar = window.get();
            newVar.showDevTools();
*/
            $scope.tabs = [
                {"name": "About"},
                {"name": "Config"},
                {"name": "Log"}
            ];

            $scope.formats= {};

            fs.readdir(appCfg.CONFIG_DIR, function(err, files) {
                for(var i in files) {
                    if (err) {
                        console.error(err);
                        $scope.log.push('ERROR! '+err.text);
                    } else {
                        if (files[i] == "db.json") continue;
                        $scope.log.push('Config Found: ' + files[i]);
                        var name = files[i].replace(/\.[^/.]+$/, "");
                        $scope.formats[name]= JSON.parse(fs.readFileSync(appCfg.CONFIG_DIR+'/'+files[i], 'utf8'));
                        $scope.log.push('Config Loaded: ' + name);
                        $scope.tabs.push({"name": name});
                    }
                }
            });
        };

        this.init();

    });

    app.controller('ConfigCtrl', function($scope, $window, fileSystem) {


        $scope.getFiles = function(dir) {
            $.when(fs.readdirSync(dir)).then(function(files) {
                for(var i in files) {
                    $scope.terminal.push('Config Found: ' + files[i]);
                    //var cfg = require(dir+'/'+files[i]);
                    //$scope.log.push('Config Loaded: ' + files[i]);
                }
            }, function(err) {
                console.error(err);
                $scope.log.push('ERROR! '+err.text);
                $window.alert(err.text);
            });

            /*$scope.log.push('Getting directory content '+dir);
            fileSystem.getFolderContents(dir).then(function(entries) {
                $scope.terminal.push('Getting folder content');
                $scope.log.push('Getting folder content');
                for(var i = 0; i<entries.length; i++) {
                    $scope.terminal.push(entries[i].fullPath);
                }
            }, function(err) {
                //console.log(err);
                $scope.log.push('ERROR! '+err.text);
                $window.alert(err.text);
            });*/
        };

        $scope.loadConfig = function (file) {
            if (fs.existsSync(file)) {
                var content = fs.readFileSync(file, "utf8");
                return JSON.parse(content);
            }
        };

        $scope.saveConfig = function (file, content) {
            fs.writeFileSync(file, JSON.stringify(content), "utf8");
            return true;
        };

    });
})();

var gui = require('nw.gui');
gui.Window.get().on('close', function() {
    // operations
    this.close(true); // don't forget this line, else you can't close it (I tried)
});
