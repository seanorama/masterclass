drop database if exists hortoniabank cascade;
Create database hortoniabank;

drop database if exists finance cascade;
Create database finance;

drop database if exists claim cascade;
create database claim;

drop database if exists cost_savings cascade;
Create database cost_savings;

---------

use hortoniabank;

DROP TABLE IF EXISTS hortoniabank.us_customers_temp;

CREATE TEMPORARY EXTERNAL TABLE hortoniabank.us_customers_temp(
 number string,
 gender string,
 title string,
 givenname string,
 middleinitial string,
 surname string,
 streetaddress string, 
 city string,
 state string,
 statefull string,
 zipcode string,
 country string,
 countryfull string,
 emailaddress string,
 username string,
 password string,
 telephonenumber string,
 telephonecountrycode string,
 mothersmaiden string,
 birthday string,
 age int,
 tropicalzodiac string,
 cctype string,
 ccnumber string,
 cvv2 string,
 ccexpires string,
 nationalid string,
 mrn string,
 insuranceid string,
 eyecolor string,
 occupation string,
 company string,
 vehicle string,
 domain string,
 bloodtype string,
 weight double,
 height int,
 latitude double,
 longitude double)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/admin/hortoniabank_data/us_customers'
tblproperties("skip.header.line.count"="1");


DROP TABLE IF EXISTS hortoniabank.us_customers;

CREATE TABLE hortoniabank.us_customers(
  number string,
  gender string,
  title string,
  givenname string,
  middleinitial string,
  surname string,
  streetaddress string,
  city string,
  state string,
  statefull string,
  zipcode string,
  country string,
  countryfull string,
  emailaddress string,
  username string,
  password string,
  telephonenumber string,
  telephonecountrycode string,
  mothersmaiden string,
  birthday string,
  age int,
  tropicalzodiac string,
  cctype string,
  ccnumber string,
  cvv2 string,
  ccexpires string,
  nationalid string,
  mrn string,
  insuranceid string,
  eyecolor string,
  occupation string,
  company string,
  vehicle string,
  domain string,
  bloodtype string,
  weight double,
  height int,
  latitude double,
  longitude double)
STORED AS ORC;

INSERT INTO hortoniabank.us_customers SELECT * FROM hortoniabank.us_customers_temp;

DROP TABLE hortoniabank.us_customers_temp;
------


DROP TABLE IF EXISTS hortoniabank.ww_customers_temp;

CREATE EXTERNAL TABLE hortoniabank.ww_customers_temp(
  gender string,
  title string,
  givenname string,
  middleinitial string,
  surname string,
  number int,
  nameset string,
  streetaddress string,
  city string,
  state string,
  statefull string,
  zipcode string,
  country string,
  countryfull string,
  emailaddress string,
  username string,
  password string,
  browser string,
  telephonenumber string,
  telephonecountrycode int,
  mothersmaiden string,
  birthday string,
  age int,
  tropicalzodiac string,
  cctype string,
  ccnumber bigint,
  cvv2 int,
  ccexpires string,
  nationalid string,
  ups string,
  mrn bigint,
  insuranceid int,
  eyecolor string,
  occupation string,
  company string,
  vehicle string,
  domain string,
  bloodtype string,
  weight double,
  kilograms double,
  feetinches string,
  height int,
  guid string,
  latitude double,
  longitude double)
ROW FORMAT DELIMITED 
FIELDS TERMINATED BY ',' ESCAPED BY '"'
-- LINES TERMINATED BY '\n' 
STORED AS TEXTFILE
LOCATION '/user/admin/hortoniabank_data/ww_customers'
tblproperties("skip.header.line.count"="1");


-- ALTER TABLE hortoniabank.ww_customers_temp SET SERDEPROPERTIES ('serialization.encoding'='SJIS');

-- INSERT OVERWRITE LOCAL DIRECTORY '/home/hive/ww_customers' 
-- ROW FORMAT DELIMITED 
-- FIELDS TERMINATED BY ',' 
-- select * from hortoniabank.ww_customers;
-- */

DROP TABLE IF EXISTS hortoniabank.ww_customers;

CREATE TABLE hortoniabank.ww_customers(
  gender string,
  title string,
  givenname string,
  middleinitial string,
  surname string,
  number int,
  nameset string,
  streetaddress string,
  city string,
  state string,
  statefull string,
  zipcode string,
  country string,
  countryfull string,
  emailaddress string,
  username string,
  password string,
  telephonenumber string,
  telephonecountrycode int,
  mothersmaiden string,
  birthday string,
  age int,
  tropicalzodiac string,
  cctype string,
  ccnumber bigint,
  cvv2 int,
  ccexpires string,
  nationalid string,
  mrn bigint,
  insuranceid int,
  eyecolor string,
  occupation string,
  company string,
  vehicle string,
  domain string,
  bloodtype string,
  weight double,
  height int,
  latitude double,
  longitude double)
STORED AS ORC;

INSERT OVERWRITE Table hortoniabank.ww_customers 
SELECT 
gender
  ,title 
  ,givenname
  ,middleinitial
  ,surname
  ,number
  ,nameset
  ,streetaddress
  ,city
  ,state
  ,statefull
  ,zipcode
  ,country
  ,countryfull
  ,emailaddress
  ,username
  ,password
  ,telephonenumber
  ,telephonecountrycode
  ,mothersmaiden
  ,birthday
  ,age
  ,tropicalzodiac
  ,cctype
  ,ccnumber
  ,cvv2
  ,ccexpires
  ,nationalid
  ,mrn
  ,insuranceid
  ,eyecolor
  ,occupation
  ,company
  ,vehicle
  ,domain
  ,bloodtype
  ,weight
  ,height
  ,latitude
  ,longitude
FROM hortoniabank.ww_customers_temp;

DROP TABLE hortoniabank.ww_customers_temp;

-----

DROP TABLE IF EXISTS hortoniabank.eu_countries_temp;

CREATE TEMPORARY EXTERNAL TABLE hortoniabank.eu_countries_temp(
  countryname string,
  countrycode string,
  region string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/admin/hortoniabank_data/eu_countries';

DROP TABLE IF EXISTS hortoniabank.eu_countries;

CREATE TABLE hortoniabank.eu_countries(
  countryname string,
  countrycode string,
  region string)
STORED AS ORC;

INSERT INTO hortoniabank.eu_countries SELECT * FROM hortoniabank.eu_countries_temp;

DROP TABLE hortoniabank.eu_countries_temp;

-----

use finance;

DROP TABLE IF EXISTS finance.tax_2015_temp;

CREATE TEMPORARY EXTERNAL TABLE  finance.tax_2015_temp(
  ssn string,
  fed_tax double,
  state_tax double,
  local_tax double)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/admin/hortoniabank_data/tax_2015';


DROP TABLE IF EXISTS finance.tax_2015;

CREATE TABLE finance.tax_2015(
  ssn string,
  fed_tax double,
  state_tax double,
  local_tax double)
STORED AS ORC;

INSERT INTO finance.tax_2015 SELECT * FROM finance.tax_2015_temp;

DROP TABLE finance.tax_2015_temp;

---
use cost_savings;

-- INSERT OVERWRITE LOCAL DIRECTORY '~/claim-savings.csv' 
-- ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
-- SELECT * FROM claim_savings;

DROP TABLE IF EXISTS cost_savings.claim_savings_temp;

CREATE TEMPORARY EXTERNAL TABLE cost_savings.claim_savings_temp(
`reportdate` date,
`name` string,
`sequenceid` int,
`claimid` int,
`costsavings` int,
`eligibilitycode` int,
`latitude` double,
`longitude` double)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/admin/hortoniabank_data/claim_savings';



DROP TABLE IF EXISTS cost_savings.claim_savings;

CREATE TABLE cost_savings.claim_savings(
`reportdate` date,
`name` string,
`sequenceid` int,
`claimid` int,
`costsavings` int,
`eligibilitycode` int,
`latitude` double,
`longitude` double)
COMMENT 'Claims Savings'
STORED AS ORC;


INSERT INTO cost_savings.claim_savings SELECT * FROM cost_savings.claim_savings_temp;

DROP TABLE cost_savings.claim_savings_temp;


-----

use claim;

-- INSERT OVERWRITE LOCAL DIRECTORY '~/provider_summary.csv' 
-- ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
-- SELECT * FROM provider_summary;

DROP TABLE IF EXISTS claim.provider_summary_temp;

CREATE TEMPORARY EXTERNAL TABLE claim.provider_summary_temp(
`providerid` string,
`providername` string,
`providerstreetaddress` string,
`providercity` string,
`providerstate` string,
`providerzip` string,
`providerreferralregion` string,
`totaldischarges` int,
`averagecoveredcharges` decimal(10,2),
`averagetotalpayments` decimal(10,2),
`averagemedicarepayments` decimal(10,2))
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/admin/hortoniabank_data/provider_summary';

DROP TABLE IF EXISTS claim.provider_summary;

CREATE EXTERNAL TABLE claim.provider_summary(
`providerid` string,
`providername` string,
`providerstreetaddress` string,
`providercity` string,
`providerstate` string,
`providerzip` string,
`providerreferralregion` string,
`totaldischarges` int,
`averagecoveredcharges` decimal(10,2),
`averagetotalpayments` decimal(10,2),
`averagemedicarepayments` decimal(10,2))
COMMENT 'Provider Summary'
STORED AS ORC;


INSERT INTO claim.provider_summary SELECT * FROM claim.provider_summary_temp;

DROP TABLE claim.provider_summary_temp;


DROP VIEW IF EXISTS claim.claims_view;


CREATE VIEW claim.claims_view AS 
select `claim_savings`.`reportdate`, 
`claim_savings`.`name`, 
`claim_savings`.`sequenceid`, 
`claim_savings`.`claimid`, 
`claim_savings`.`costsavings`, 
`claim_savings`.`eligibilitycode`, 
`claim_savings`.`latitude`, 
`claim_savings`.`longitude` 
from `cost_savings`.`claim_savings`;


DROP TABLE IF EXISTS claim.prov_view ;

CREATE VIEW claim.prov_view AS 
select `provider_summary`.`providerid`, 
`provider_summary`.`providername`, 
`provider_summary`.`providerstreetaddress`, 
`provider_summary`.`providercity`, 
`provider_summary`.`providerstate`, 
`provider_summary`.`providerzip`, 
`provider_summary`.`providerreferralregion`, 
`provider_summary`.`totaldischarges`, 
`provider_summary`.`averagecoveredcharges`, 
`provider_summary`.`averagetotalpayments`, 
`provider_summary`.`averagemedicarepayments` 
from `claim`.`provider_summary`;









