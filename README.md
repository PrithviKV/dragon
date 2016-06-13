# Dragon
Version controlled key-value store with a HTTP API we can query that from.

### Introduction

* This is a simple key-value store with a HTTP API which we can query. 
* Accepts a key(string) and value(string) and store them
* If an existing key is sent, the value is updated
* Accepts a key and return the corresponding latest value
* When given a key AND a timestamp, return whatever the value of the key at the time was.

### How to install

* These programs are assumed to be installed:
    * Core Ruby program was tested with Ruby: `2.0.0p451`
    * Postgresql Database with 2 tables
      * Tablename: Objects
        - fieldname and type: key (VARCHAR)
        - fieldname and type: value (VARCHAR)
      * Tablename: Timedobjects
        - fieldname and type: key_id (INT)
        - fieldname and type: key_value (VARCHAR)
        - filedname and type: timestamp (datetime)
      
* To install this program
```
$ git clone https://github.com/PrithviKV/dragon.git
$ bundle install
```
### How to run 
```
$ ruby key_value_store.rb
```
### Demo
   Demp app is deployed on HEROKU at http://secret-forest-70025.herokuapp.com/object/key1
   
### Request & Response Examples
###  GET /object/mykey
  ```
  http://secret-forest-70025.herokuapp.com/object/key1
  Response: abc
  ```
###  POST /object/mykey
  ```
  http://secret-forest-70025.herokuapp.com/object
  Body: {"key1": "xyz"}
  ```
### GET /object/mykey?timestamp=
  ```
  http://secret-forest-70025.herokuapp.com/object/key1?timestamp=1465783110
  Response: xyz
  
  http://secret-forest-70025.herokuapp.com/object/key1?timestamp=1465783032
  Response: abc
  ```
  
