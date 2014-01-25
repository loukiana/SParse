SParse
======

Log (text) file parser.

Huge files
----------

Use parameter
```sh  
  --max-old-space-size=4000 
```

Configuration
-------------

To be described... see examples in `config` folder.
  
Example commands
----------------

Parse file (config json must correspond to it's format) and load into table in MySQL (table must exist, config db.json must point to correct database):

```
  node --max-old-space-size=4000 parser.js tests\4095\22_ro1_22017.log 22_ro1_22017
```