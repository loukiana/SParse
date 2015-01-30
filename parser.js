var fs = require('fs'),
    readline = require('readline'),
    stream = require('stream'),
    es = require("event-stream"),
    regexp = require('node-regexp');
var mysql = require('mysql');

var logConfig = require(process.argv[5] || './config/corba trace.json');
var dbConfig = require('./config/db.json');

var file = process.argv[2];

if (!file || !fs.existsSync(process.argv[2])
    || !process.argv[3]) {
    console.log("Invalid arguments.");
    process.exit(1);
}

var table = process.argv[3].replace(/[^\w\d]/g,'_');

console.log('Hello!');
console.log('I am starting to process file `'+file+'` into table `'+table+'`');

var stats = fs.statSync(file);
var fileSizeInBytes = stats["size"];
var fileSizeRead = 0;
var linesRead = 0;
var linesLoaded = 0;
var linesScanned = 0;
var assembledLine = false;
var connection;
var schema = false;
const MAX_THREADS=500; //todo move to config
handleDisconnect();
var debug_traceLines = false;
var GC_PERIOD = 1000;  // when read this amount of lines - forse garbage collect (if not 0)

var debug_Queries_Started = 0;
var debug_Queries_Ended = 0;

/*
reading file using Line By Line

var LineByLineReader = require('line-by-line'),
 instream = new LineByLineReader(file);

 instream.on('error', function (err) {
    console.log(err);
});

 instream.on('line', _line);

 instream.on('end', _close);*/

/* reading file using pipes */

var instream = fs.createReadStream(file, {flags: 'r'}).pipe(es.split())
    .pipe(es.mapSync(function(line){

        // pause the readstream
        //instream.pause();

        (function(){

            _line(line);


            //instream.resume();

        })();
    })
        .on('error', function(){
            console.log('Error while reading file.');
        })
        .on('end', function(){
            _close();
        })
);

/* reading file using ReadLine

var instream = fs.createReadStream(file, {flags: 'r'});
var lineAssemble = readline.createInterface({
    input: instream,
    output: process.stdout,
    terminal: false
});
 lineAssemble.on('line', _line);
 lineAssemble.on('close', _close);
*/

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
    if (logConfig.line.scramble && logConfig.line.scramble.length) {
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

function logStatus() {
    console.log('file read:\t'+Math.round(100 * fileSizeRead / fileSizeInBytes) + '%'+
        '\tlines loaded/read:\t'+linesLoaded+'\t\t/'+linesRead
        +'\t\t\t[db queue\t'+(debug_Queries_Started - debug_Queries_Ended)+'\t]');
}

function _line(line) {
    linesScanned++;
    if (linesScanned % GC_PERIOD == 0) {
        console.log('gc...');
        //global.gc();
        connection.end();
        handleDisconnect();
        console.log('finished gc?');
    }
    fileSizeRead += Buffer.byteLength(line, 'utf8');
    if (debug_traceLines) {
        console.log('\t\t\t\t\t\t\t'+line);
    }
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
}

function _close() {
    if (assembledLine) {
        // finish assembling old line
        if (! shouldSkipLine(assembledLine)) {
            assembledLine = scrambleLine(assembledLine);
            parseLine(assembledLine+"\r\n");
        }
        assembledLine = false;
        fileSizeRead = fileSizeInBytes;
        connection.end(function(err) {
            if (err) console.log(err);
            console.log('Uploading ended.');
        });
        console.log('Reading ended.');
    }
}

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

        linesRead ++;
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

function createDB(schemaName) {

    var query = connection.query('CREATE DATABASE IF NOT EXISTS '+mysql.escapeId(schemaName), function(err, result) {
        if (err) console.log(err);
    });
}

function createTable(tableName, tableColumns) {

    var query = connection.query('CREATE TABLE '+mysql.escapeId(tableName) + ' (' + tableColumns.join(', ') + ')', function(err, result) {
        if (err) console.log(err);
    });
}

function upload(json) {

    debug_Queries_Started++;
    //if (linesRead-linesLoaded > MAX_THREADS) {
        instream.pause();
    //}
    logStatus();
    var query = connection.query('INSERT INTO '+mysql.escapeId(table)+' SET ?', json, function(err, result) {
        //if (instream.paused) {
            instream.resume();
        //}
        if (err) {
            console.log(err);
        }
        else {
            debug_Queries_Ended++;
            linesLoaded++;
        }
        logStatus();
    });
}

function handleDisconnect() {
    console.log('connecting to database');
    if (!schema) {
        schema = dbConfig.db.database;

        if (process.argv[4]) {
            schema = process.argv[4];
        }

        dbConfig.db.database = null;

        connection = mysql.createConnection(dbConfig.db); // Recreate the connection, since
        // the old one cannot be reused.

        connection.connect(function(err) {              // The server is either down
            if(err) {                                     // or restarting (takes a while sometimes).
                console.log('error when connecting to db:', err);
                setTimeout(handleDisconnect, 2000); // We introduce a delay before attempting to reconnect,
            }                                     // to avoid a hot loop, and to allow our node script to
        });                                     // process asynchronous requests in the meantime.
        // If you're also serving http, display a 503 error.

        dbConfig.db.database = schema;
        createDB(dbConfig.db.database);
        connection.query('USE ' + mysql.escapeId(schema));
        createTable(table, logConfig.createTable);
    } else {
        connection = mysql.createConnection(dbConfig.db); // Recreate the connection, since
        // the old one cannot be reused.

        connection.connect(function(err) {              // The server is either down
            if(err) {                                     // or restarting (takes a while sometimes).
                console.log('error when connecting to db:', err);
                setTimeout(handleDisconnect, 2000); // We introduce a delay before attempting to reconnect,
            }                                     // to avoid a hot loop, and to allow our node script to
        });                                     // process asynchronous requests in the meantime.
        // If you're also serving http, display a 503 error.
    }

    connection.on('error', function(err) {
        console.log('db error', err);
        if(err.code === 'PROTOCOL_CONNECTION_LOST') { // Connection to the MySQL server is usually
            handleDisconnect();                         // lost due to either server restart, or a
        } else {                                      // connnection idle timeout (the wait_timeout
            throw err;                                  // server variable configures this)
        }
    });
}



