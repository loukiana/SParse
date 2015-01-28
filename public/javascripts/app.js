(function(){

    var app = angular.module('sparse', []);
    var fs = require("fs");
    var JSZip = require("jszip");
    var appCfg= {
        CONFIG_DIR: "./config"
    };

    app.controller('NavCtrl', function($scope, $window) {
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
                {"name": "Main"},
                {"name": "Config"},
                {"name": "Log"},
                {"name": "New Format"}
            ];

            $scope.formats= {};

            fs.readdir(appCfg.CONFIG_DIR, function(err, files) {
                for(var i in files) {
                    if (err) {
                        console.error(err);
                        $scope.log.push('ERROR! '+err.text);
                    } else {
                        try {
                            if (files[i] == "db.json") continue;
                            $scope.log.push('Config Found: ' + files[i]);
                            var name = files[i].replace(/\.[^/.]+$/, "");
                            $scope.formats[name] = JSON.parse(fs.readFileSync(appCfg.CONFIG_DIR + '/' + files[i], 'utf8'));
                            $scope.log.push('Config Loaded: ' + name);
                            $scope.tabs.push({"name": name});
                        } catch (err2) {
                            console.error(err);
                            $scope.log.push('ERROR! '+err.text);
                        }
                    }
                }
            });
        };

        this.init();

    });

    app.controller('FormatCtrl', function($scope, $window) {
        this.name="To be implemented...";
    });

    app.controller('DialogueCtrl', function($scope, $window) {

        this.step=1;
        this.logFilesSourcePath = false; // xxx load from history
        this.dbName = "";

        this.loadLogFiles = function() {
            if (!fs.existsSync(logFilesSourcePath)) {
                alert("No such file or folder"); //todo balloon
            }
            // xxx if zip - unzip in temp folder and (*)
            // if folder - for each file in folder
            // (*) delete created work\temp files

            var zip = new JSZip();
            fs.readFile(logFilesSourcePath, function(err, data) {
                if (err) alert(err.text);

                var zip = new JSZip(data);
                zip.files
            });
            return true;
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
