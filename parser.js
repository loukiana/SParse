var fs = require('fs'),
    readline = require('readline'),
    stream = require('stream');

var logConfig = require('./config/corbatrace.json');
var dbConfig = require('./config/db.json');


if (!process.argv[2] /*|| !fs.exists(process.argv[2])*/
    || !process.argv[3]) {
    console.log("Invalid arguments.");
    process.exit(1);
}

console.log('Hello!');
console.log('I am starting to process file '+process.argv[2]+'.');

var instream = fs.createReadStream(process.argv[2]);

var lineAssemble = readline.createInterface({
    input: instream,
    output: process.stdout,
    terminal: false
});

var regexp = require('node-regexp');
var assembledLine = false;

//********* ASSEMBLE MULTIPLE LINE LOG MESSAGES *********************

function shouldSkipLine(line) {

    if (logConfig.line.include) {
        if (new RegExp(logConfig.line.include, 'm').test(line) == false) {
            return true;
        }
    }
    if (logConfig.line.exclude) {
        if (new RegExp(logConfig.line.exclude, 'm').test(line) == true) {
            return true;
        }
    }
    return false;
}


function scrambleLine(line) {
    if (logConfig.line.scramble) {
        for (var scr in logConfig.line.scramble) {
            if (scr) {
                var reScramble = new RegExp(scr, 'm');

                var toReplace = line.match(reScramble);
                if (toReplace && toReplace.length > 1) {
                    return line.replace(toReplace[1], 'XXX');
                }
            }
        }
    }
    return line;
}

lineAssemble.on('line', function(line) {
    var re = new RegExp(logConfig.line.start);
    if (re.test(line)) {
        // starting new line, finish assembling old line
        if (! shouldSkipLine(assembledLine)) {
            assembledLine = scrambleLine(assembledLine);
            parseLine(assembledLine+"\r\n");
        }
        assembledLine = false;
    }

    // continuing assembling the line
    assembledLine = (assembledLine ? (assembledLine + "\r\n") : "")
        + line;
});


lineAssemble.on('close', function() {
    if (assembledLine) {
        // finish assembling old line
        if (! shouldSkipLine(assembledLine)) {
            assembledLine = scrambleLine(assembledLine);
            parseLine(assembledLine+"\r\n");
        }
        assembledLine = false;
        console.log('Processing ended.');
    }
});

//********* PARSE ASSEMBLED LOG MESSAGES AND PUT INTO DB *************


function parseLine(line) {
    var rep = new RegExp(logConfig.line.matcher, 'm');
    var values = false;

    if (values = line.match(rep)) {
        var msgValues = false;
        var dbLine = {};

        for (var i=0;i<logConfig.line.elements.length;i++) {

            dbLine[logConfig.line.elements[i]] = values[i+1].trim();

            msgValues = true;
            if (logConfig.line.elements[i] == 'message') {
                msgValues = parseMessage(values[i+1]);

                if (msgValues) {
                    merge(dbLine, msgValues);
                }
            }
        }

        upload(dbLine);
        //process.stdout.write(JSON.stringify(dbLine)+"\n");
    }
}

function merge(set1, set2){
    for (var key in set2){
        if (set2.hasOwnProperty(key))
            set1[key] = set2[key]
    }
    return set1
}

function parseMessage(message) {
    var msgValues = false;
    var result = {};

    var remi = new RegExp(logConfig.message.in_matcher, 'm');
    if (msgValues = message.match(remi)) {
        for (var j=0;j<logConfig.message.in_elements.length;j++) {
            result[logConfig.message.in_elements[j]] = msgValues[j+1].trim();
        }
        return result;
    }

    var remo = new RegExp(logConfig.message.out_matcher, 'm');
    if (msgValues = message.match(remo)) {
        for (var j=0;j<logConfig.message.out_elements.length;j++) {
            result[logConfig.message.out_elements[j]] = msgValues[j+1].trim();
        }
    }
    return result;
}

//********** Database upload ***********************************************

var mysql = require('mysql');
var connection;

function upload(json) {

    var query = connection.query('INSERT INTO '+process.argv[3]+' SET ?', json, function(err, result) {
        //console.log(query.sql);
        console.log('.');
    });
}

function handleDisconnect() {
    connection = mysql.createConnection(dbConfig.db); // Recreate the connection, since
    // the old one cannot be reused.

    connection.connect(function(err) {              // The server is either down
        if(err) {                                     // or restarting (takes a while sometimes).
            console.log('error when connecting to db:', err);
            setTimeout(handleDisconnect, 2000); // We introduce a delay before attempting to reconnect,
        }                                     // to avoid a hot loop, and to allow our node script to
    });                                     // process asynchronous requests in the meantime.
    // If you're also serving http, display a 503 error.
    connection.on('error', function(err) {
        console.log('db error', err);
        if(err.code === 'PROTOCOL_CONNECTION_LOST') { // Connection to the MySQL server is usually
            handleDisconnect();                         // lost due to either server restart, or a
        } else {                                      // connnection idle timeout (the wait_timeout
            throw err;                                  // server variable configures this)
        }
    });
}

handleDisconnect();



