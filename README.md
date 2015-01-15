SParse
======

Log (text) file parser.

Huge files
----------

Use parameter
```sh  
  --max-old-space-size=4000 
```

Installation
------------

Requires Node.js. Check-out files into a folder, e.g. `C:\SParse`, then `cd` to this folder and execute `npm install` to load dependencies. Configure database connection and log file formats, and run (see below).

Configuration
-------------

To be described... see examples in `config` folder.

* Database connection configured in `\config\db.json` file:

```json
{
    "db":
    {
        "host": "localhost",
        "user": "root",
        "password": "root",
        "database": "test"
    }
}
```

* Format of the file to be parsed is configured in other file:
```json
{
    "line": {
        "start" :    "(RO\\d+),(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})\\.(\\d{3}),",
        "matcher" :  "(RO\\d+),(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})\\.(\\d{3}),(\\d+),(\\D+),(\\d+),(In|Out),(\\d+),(\\d+),([\\s\\S]*)$",
        "elements" : [
            "node",
            "tstamp",
            "tstamp_ms",
            "someID" ,
            "object",
            "object_id",
            "direction",
            "request_id",
            "message_len",
            "message"
        ],

        "include" :   ".*GetAvailPrimPackages",

        "scramble": "<SessionGUID>([-\\S]{5,50})</SessionGUID>"
    },

    "message": {
        "in_matcher" : "GetAvailPrimPackages\\(.*='([\\s\\S]*)'\\)$",
        "in_elements": ["param1"],
        "out_matcher": "GetAvailPrimPackages Finished Result='([\\s\\S]*)'$",
        "out_elements": ["result"]
    }
}
```  
  
Example commands
----------------

Parse file (config json must correspond to it's format) and load into table in MySQL (table must exist, config `db.json` must point to correct database):

```
  node --max-old-space-size=4000 parser.js tests\4095\22_ro1_22017.log 22_ro1_22017
```
