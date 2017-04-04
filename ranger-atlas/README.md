# Ranger Atlas (Hortonia Bank)

## Lab 01: Access services

Ensure you can access the following.

- [ ] Ambari: Login to Ambari web UI by opening http://AMBARI_PUBLIC_IP:8080
- Open each of the following from Ambari:
  - [ ] Ranger
  - [ ] Atlas
  - [ ] Zeppelin

Credentials will be provided by the instructor.

## Lab 02: Ranger: Review & Enable HortoniaBank Policies

- Open Ranger
- View the Hive policies.
  - Note that the demo policies are disabled.
- [ ] Enable them while reviewing what they do.
  - Make sure to do this for each type (Access, Masking, Row Level Filter)

## Lab 03: Ranger: Enable Tag based Policies

- [ ] Create Tag Service
  - Open Ranger
  - Click Access Manager -> Tag Based Policies
  - Click the + icon and create a service named 'tags'
    - ![[][]](/images/2017/04/screenshot-ranger-add-tag-service.png)

- [ ] Configure Hive for Tag based Policies
  - Open Ranger
  - Click Access Manager -> Resources Based Policies
  - Click ‘edit/pen’ icon next to the service’
  - [ ] Set ‘Select Tag Service’ to ‘tags’
    - ![](/images/2017/04/screenshot-ranger-configure-hive-tag-service.png)

## Lab 04: Ranger: Allow 'compliance' group to see expired data

- [ ] Update 'EXPIRES_ON' tag based policy
  - Open Ranger
  - Click Access Manager -> Tag Based Policies
  - Open the 'tags' service
  - Edit the 'EXPIRES_ON' policy
  - Notice the condition which denies access to 'public'
  - Add these conditions:
    - 1. 'Allow Conditions': Give the group 'compliance' access to component 'hive'
      - ![](media/screenshot-ranger-add-tag-condition1.png)
    - 2. 'Exclude from Deny Conditions': Give the group 'compliance' access to component 'hive'
      - ![](media/screenshot-ranger-add-tag-condition1.png)

## Lab 05: Atlas: Create 'EXPIRES_ON' tag in Atlas

- [ ] Create tag in Atlas
  - Open Atlas
  - Click ‘Tags’ -> ‘Create Tag’
  - Name: "EXPIRES_ON"
    - Attributes: "expiry_date" as type "date"
    - ![](media/screenshot-atlas-create-tag-expireson.png)

## Lab 06: Atlas: Add 'EXPIRES_ON' tag to table 'tax_2015'

1. [ ] Find the 'tax_2015' table
  - Open Atlas
  - Click ‘Search’:
    - Type: hive_table
    - Query: tax_2015
      - ![](media/screenshot-atlas-tax2015-search.png)
2. [ ] Add tag to table
  - Click blue "+" sign next to 'tax_2015'
    - Tag: EXPIRES_ON
    - expiry_date: 2016-12-31T00:00:00.000Z
      - ![](media/screenshot-atlas-tax2015-tag.png)

## Lab 07: Test EXPIRES_ON policy

- [ ] Test EXPIRES_ON Tag from Ambari View:
  - Login to Ambari as 'joe-analyst'
    - Open the Hive view
      - Notice that while you can see the 'finance' database, you cannot see the 'tax_2015' table.
    - Log out of Ambari
  - Login to Ambari as compliance-admin.
    - Open the Hive view
      - You can now see the tax_2015 table

- [ ] Check Ranger audits
  - Open Ranger
  - Click Audit
    - Notice, in the far right column, the '[EXPIRES_ON]' tag policy being used

## Lab 08: Confirm policies from Ambari

From Ambari:

1. [ ]	Login joe-analyst
  - Go to the Hive View and execute the following:
    ```
select givenname, age, birthday, ccnumber, streetaddress, nationalid, password, mrn from hortoniabank.us_customers;
    ```
  - You should see masked data

2. [ ] Login kate-hr
  - Go to the Hive View and execute the following:
    ```
select givenname, age, birthday, ccnumber, streetaddress, nationalid, password, mrn from hortoniabank.us_customers;
    ```
  - You should see all the data


3. [ ] Login as kate-hr.
  - Go to the Hive View and execute the following:
    ```
select gender, title, givenname, country from hortoniabank.ww_customers;
    ```
  - You should only see US country data

4. [ ] Login as ivana-eu-hr
  - Go to the Hive View and execute the following:
    ```
select gender, title, givenname, country from hortoniabank.ww_customers;
    ```
  - You should see EU country data


## Lab 09: Import Zeppelin Notebooks

- [ ] Import Notebooks
  - Login to Zeppelin as 'compliance-admin'
  - Import each of these notebooks using URL
    - [ ] [HortoniaBank - compliance-admin Notebook](https://raw.githubusercontent.com/seanorama/masterclass/master/ranger-atlas/Notebooks/HortoniaBank%20-%20Compliance%20Admin%20View.json)
    - [ ] [HortoniaBank - ivana-eu-ur Notebook](https://raw.githubusercontent.com/seanorama/masterclass/master/ranger-atlas/Notebooks/HortoniaBank%20-%20Ivana%20EU%20HR.json)
    - [ ] [HortoniaBank - joe-analyst Notebook](https://raw.githubusercontent.com/seanorama/masterclass/master/ranger-atlas/Notebooks/HortoniaBank%20-%20Joe%20Analyst.json)
