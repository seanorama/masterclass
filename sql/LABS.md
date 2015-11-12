# Labs
These notes are meant to accompany our Hadoop SQL Masterclass which covers:

- SQL on Hadoop
- SQL using Hive
- Tools for Hive
- Data on Hive
- Extensibility of Hive
- Hive performance
- Phoenix
- Spark SQL

## Requirements

Tested with:

- Ambari 2.1.2
- HDP 2.3.2
- OpenJDK 8

More details on the deployment process at the end of this document.


---
---


## Lab preparation at cluster setup time


- Lab 1: Set up student clusters with HDFS, MapReduce2, YARN, Tez, Hive, HBase, Zookeeper, Spark and Hive-, Tez- and File-View
- Lab 2: Create customer database folder: `Lab2/lab2-prepare.sh`
- Lab 3: Create tweets folder: `Lab3/lab3-prepare.sh`
- Lab 4: Copy twitter sample data: `Lab4/lab4-prepare.sh` and Insert 

    HIVE_AUX_JARS_PATH=$HIVE_AUX_JARS_PATH:/var/lib/hive/json-serde-1.1.9.9-Hive13-jar-with-dependencies.jar

  into _Advanced hive-env_ -> _hive-env template_ to allow access to it from hive SQL
- Lab 5: Create employees database in hbase: `Lab5/lab5-prepare.sh`
- Lab 6: Import employees database into hive: `Lab6/lab6-prepare.sh`


---
---


## Labs


### Lab 1: Handover cluster

__Goal:__ Get access to the system

1. Console via SSH or Web
    - User: student
    - Pass: we will share separately
    - If you do not have an SSH client, there is a web console:
      - http://hostname:4200

2. Ambari: http://yourhost:8080

    - User: admin
    - Pass: 

3. Check dashboard. At least the following components should run and have a green status:

    - HDFS
    - MapReduce2
    - YARN
    - Tez
    - Hive
    - HBase
    - Zookeeper
    - Spark

4. Check that File View, Tez view and Hive view are available



### Lab 2: The Ambari Views

__Goal:__ Use of Hive View and File View to issue SQL statements and understand link between files and tables

- Use File view to navigate to e.g. `/masterclass/lab2/customers`
- Use Hive view to query a table

  ```sql
SELECT * 
FROM customers 
WHERE length(last_name) > 7
ORDER BY last_name;
  ```

- Save the query

  __Note: Explain that they need to save before switching views !__

- Use Hive view to create a table and fill it
  
  ```sql
CREATE EXTERNAL TABLE IF NOT EXISTS cust2 (
    last_name STRING,
    first_name STRING,
    house STRING,
    street STRING,
    post_code STRING
)
LOCATION "/tmp/cust2";
  ```

  ```sql
INSERT into cust2
SELECT last_name, first_name, address[0], address[1], address[3] 
FROM customers 
ORDER BY last_name;
  ```

- Refresh the Database Explorer and examine `cust2`.

- Look at the visual explanation of the last SQL statement

- Again, use File View to navigate to `/tmp/cust2`




### Lab 3: Examine a data set and load it into hive

__Goal__: Convert raw data to a table and then to an ORC table including some Hive SQL functions

- Use File View to navigate to `/masterclass/lab3/tweets`

- Use Hive View to create Schema (with data)

  ```sql
CREATE EXTERNAL TABLE IF NOT EXISTS tweets_text_partition(
    tweet_id bigint,
    created_unixtime bigint,
    created_time string,
    displayname string,
    msg string,
    fulltext string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY "|"
LOCATION "/masterclass/lab3/tweets";
  ```

  Use Database Explorer to look at schema and data 

- Prepare the data as ORC

  ```sql
CREATE EXTERNAL TABLE IF NOT EXISTS tweets_orc_msg_hashtags(
    tweet_id bigint,
    created_unixtime string,
    displayname string,
    msg string,
    hashtag string
)
STORED AS orc;
  ```

  __Note__: This is implemented via a SerDe. You could add 

  `ROW FORMAT SERDE "org.apache.hadoop.hive.ql.io.orc.OrcSerde"`

  ```sql  
INSERT OVERWRITE TABLE tweets_orc_msg_hashtags
SELECT
    tweet_id,
    from_unixtime(floor(created_unixtime/1000)),
    displayname,
    msg,
    get_json_object(fulltext,'$.entities.hashtags[0].text')
FROM tweets_text_partition;
  ```

- Create a simple query

  ```sql
SELECT hashtag, count(*) AS cnt
FROM tweets_orc_msg_hashtags
WHERE hashtag IS NOT null 
GROUP BY hashtag
HAVING cnt>10
LIMIT 10;
  ```



### Lab 4: Building a table on top of json

__Goal:__ Understand the Serialization/Deserialization feature

- Download the file `sample_twitter_data.txt` and examine the structure

  ```sql
CREATE TABLE IF NOT EXISTS twitter_json (
    geolocation STRUCT<lat: DOUBLE, long: DOUBLE>,
    tweetmessage STRING,
    createddate STRING,
    `user` STRUCT<screenname: STRING,
                  name: STRING,
                  id: BIGINT,
                  geoenabled: BOOLEAN,
                  userlocation: STRING>
) 
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe';
  
LOAD DATA INPATH '/masterclass/lab4/twitter/sample_twitter_data.txt' 
INTO TABLE twitter_json;
  ```

- Query the file

  ```sql
SELECT * 
FROM twitter_json;

SELECT createddate, `user`.screenname 
FROM twitter_json WHERE `user`.name LIKE 'Sarah%';
  ```

__Note__: If you cannot add a SerDe jar to the overall Hive Path, then prefix the three commands above with

  ```sql
ADD JAR /the/path/to/json-serde-1.1.9.9-Hive13-jar-with-dependencies.jar;
  ```

### Lab 5: Use HBase table from Hive

__Goal__: Understand external data sources using HBase as an example


##### Query HBase using Phoenix and Hive

- Query from Phoenix `phoenix-sqlline localhost:2181:/hbase-unsecure`:

  ```sql
CREATE VIEW "employees" ( 
    pk VARCHAR PRIMARY KEY, 
    "f"."birth_date" VARCHAR, 
    "f"."first_name" VARCHAR, 
    "f"."last_name" VARCHAR, 
    "f"."gender" VARCHAR, 
    "f"."hire_date" VARCHAR
);

SELECT * from "employees" limit 10;
  ```

- Link with Hive

  ```sql
CREATE EXTERNAL TABLE employees_hbase(
    key BIGINT, 
    birth_date STRING, 
    first_name STRING, 
    last_name STRING, 
    gender STRING, 
    hire_date STRING
)
STORED BY "org.apache.hadoop.hive.hbase.HBaseStorageHandler"
WITH SERDEPROPERTIES ("hbase.columns.mapping" = ":key,f:birth_date,f:first_name,f:last_name,f:gender,f:hire_date")
TBLPROPERTIES("hbase.table.name" = "employees");
  ```

- Query new external table in Hive

  ```sql
SELECT * from employees_hbase limit 10;
  ```



##### Create HBase table in Hive

- Use Hive view to create a table in HBase

  ```sql
CREATE TABLE tweets_hbase(
    tweet_id BIGINT, 
    created_unixtime BIGINT, 
    created_time STRING, 
    displayname STRING, 
    msg STRING, 
    fulltext STRING  
)
STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES ("hbase.columns.mapping" = ":key,f:c1,f:c2,f:c3,f:c4,f:c5")
TBLPROPERTIES ("hbase.table.name" = "tweets");
  ```

- Goto Ambari Dashboard - HBase - Quick Links - HBase Master UI to check whether tweets table exists
- Insert data into HBase table

  ```sql
INSERT INTO tweets_hbase
SELECT * from tweets_text_partition;
  ```

- Query from Hive

  ```sql
SELECT * from tweets_hbase;
  ```


### Lab 6: SQL explain 

__Goal:__ Understand the SQL explain

- Use Hive view to execute a join SQL statement and press _"Explain"_ instead of _"Execute_"

  ```sql
SELECT d.dept_name, count(*) as cnt
FROM departments d, employees e, dept_emp x
WHERE d.dept_no = x.dept_no and e.emp_no = x.emp_no
GROUP BY d.dept_name ORDER BY cnt DESC limit 5;  
  ```

  ```sql
SELECT e.first_name, e.last_name, e.hire_date, d.dept_name, x.from_date, x.to_date
FROM departments d, employees e, dept_emp x
WHERE d.dept_no = x.dept_no and e.emp_no = x.emp_no
ORDER BY d.dept_name, e.last_name, e.first_name, x.from_date;
  ```

  ```sql
ANALYZE TABLE departments COMPUTE STATISTICS for COLUMNS;
ANALYZE TABLE dept_emp COMPUTE STATISTICS for COLUMNS;
ANALYZE TABLE employees COMPUTE STATISTICS for COLUMNS;
  ```

  ```sql
ANALYZE TABLE departments COMPUTE STATISTICS;
ANALYZE TABLE dept_emp COMPUTE STATISTICS;
ANALYZE TABLE employees COMPUTE STATISTICS;
  ```
