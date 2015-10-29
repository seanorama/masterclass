# SQL Masterclass: Instructor Notes
===================================

## Important
------------

- Provisioning can take up to an hour, so start in advance
- Some clusters may fail (due to AWS issues) so make a few extra
- TERMINATE clusters as soon as the session finishes!
  - Or prepare to pay ...


## Pre-reqs
-----------

### If not using our existing jump host:

- Choose where you will trigger these builds from
  - A Cloud machine is recommended such that you can trigger the build without needing to keep your laptop open
- Install the AWS CLI on that machine
  - http://docs.aws.amazon.com/cli/latest/userguide/installing.html
- Configure AWS CLI:
  - `aws configure`
  - Details on creating credentials for that: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html
  - Hortonworkers
    - Login to EC2 from Okta (file a helpdesk with your manager on cc if it is not present)
    - Choose "EU (Ireland)" as the region (top right of page)
    - Create a User for yourself from the "IAM" page

### If using our jump host:

- See internal documentation for the hostname & how to access
- Proceed as usual below.

## How this works
-----------------

There are several scripts used to make this work:

For AWS CloudFormation:

- cloudformation-generate-template.py: generates the AWS Cloudformation template
- cloudformation.json: the CloudFormation template which deploys a cluster

For managing multiple clusters (each takes variables for naming & the number of clusters):

- clusters-create.sh: calls cloudformation to create clusters
- clusters-report.sh: list cluster details
- clusters-terminate.sh: calls cloudformation to terminate clusters

If not using CloudFormation:

- setup.sh
  - preps the deployed instances, installs Ambari, installs HDP, ...
  - triggered directly by CloudFormation to setup each cluster
  - if not using CloudFormation, you can trigger this directly on any CentOS/RHEL7 instance

## Deploy, report & terminate clusters on AWS
-------------------------

1. Check the CloudFormation console
    - Open the AWS website
    - Ensure 'EU - Ireland' is the region
    - Open the CloudFormation paged
    - Ensure there are no conflicting stacks (those with same name of what you want to deploy)

2. Open a 'screen' so the commands continue if you lose connectivity:

    ```
screen

## Note: If you get disconnected, SSH back to the host and execute: `screen -x`
    ```


3. Set variables for the number of labs & their naming

    ```
export lab_count=1
export lab_first=1
export lab_prefix="mc-sql"
    ```

4. Provision your clusters

    ```
./clusters-create.sh
    ```

5. Get list of clusters for pasting into Etherpad
    - ensure the same variables are used from above

    ```
./clusters-report.sh
    ```

6. Terminate clusters
    - ensure the same variables are used from above

    ```
./clusters-terminate.sh
    ```

7. Verify that all clusters are terminated
    - From the AWS CloudFormation Web Console

## Running sessions

It's recommended to use an "etherpad" to share:

- the cluster details (from above)
- instructions to students

You can create your own, or use a hosted version such as TitanPad. You should create this account in advance.


## Debugging

#### Creation

- Some instances will fail their creation and time out, being rolled back, this is a nature of deploying large volumes of instances
- Those that fail should simply be manually deleted from the cloudformations web ui

#### Deleting cloudformations

- Occasionally cloudformations will fail to delete due to timing issues, in which case, it’s probably the VPC or InternetGateway, just switch to the VPC service window within the AWS site, delete the specific VPC that is being complained about in the cloudformation and then once the cloudformation delete has failed, retry the delete, deletion should complete this time.
- Once you’ve done the VPC deletion you can also do an AWS CLI call instead:
    - `aws cloudformation delete-stack --stack-name <cluster-name>`

##$$ AWS Website

If you suddenly notice that your instances/cloudformations/etc have vanished from the AWS control panel, you may have to re-login (from Okta if a Hortonworker)

