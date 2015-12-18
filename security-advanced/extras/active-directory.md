# Active Directory preparation
========================================

Below are the steps, including many PowerShell commands to prepare an AD environment

1. Deploy Windows Server 2012 R2
1. Set hostname to your liking
1. Install AD services
1. Configure AD
1. Add self-signed certificate for AD's LDAPS to work
1. Populate sample containers, users & groups
1. Delegate control to appropriate users

****************************************

## 1. Deploy Windows Server 2012 R2
----------------------------------------

- Most Cloud providers will have this option
- On Google Cloud, they have a "one-click" option to deploy AD

## 2. Set hostname


## Change hostname, if needed, and restart

   ```
## this will restart the server
$new_hostname = "ad01"
Rename-Computer -NewName $new_hostname -Restart
   ```
   
****************************************

## Install AD
----------------------------------------

1. Open Powershell (right click and "open as Administrator)

2. Prepare your environment. Update these to your liking.

   ```
$domainname = "lab.hortonworks.net"
$domainnetbiosname = "LAB"
$password = "BadPass#1"
   ```

3. Install AD features & Configure AD. You have 2 options:
   1. Deploy AD without DNS (relying on /etc/hosts or a separate DNS)

   ```
Install-WindowsFeature AD-Domain-Services –IncludeManagementTools
Import-Module ADDSDeployment
$secure_string_pwd = convertto-securestring ${password} -asplaintext -force
Install-ADDSForest `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "Win2012R2" `
-DomainName ${domainname} `
-DomainNetbiosName ${domainnetbiosname} `
-ForestMode "Win2012R2" `
-InstallDns:$false `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-SafeModeAdministratorPassword:$secure_string_pwd `
-Force:$true
   ```

   2. Deploy AD with DNS

    ```
Install-WindowsFeature AD-Domain-Services –IncludeManagementTools
Import-Module ADDSDeployment
$secure_string_pwd = convertto-securestring ${password} -asplaintext -force
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "Win2012R2" `
-DomainName ${domainname} `
-DomainNetbiosName ${domainnetbiosname} `
-ForestMode "Win2012R2" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-SafeModeAdministratorPassword:$secure_string_pwd `
-Force:$true
    ```

****************************************

## Add UPN suffixes
----------------------------------------

If the domain of your Hadoop nodes is different than your AD domain:
https://technet.microsoft.com/en-gb/library/cc772007.aspx


****************************************

## Create CA & self-signed certificate for LDAPS
----------------------------------------

- Full instructions: http://www.javaxt.com/Tutorials/Windows/How_to_Enable_LDAPS_in_Active_Directory
    - Alternatively you could install Certificate Services in AD and create the certificate from there

- I created on my local system with these commands.
    - Note: This method of managing a CA is not secure. Stricly for testing.

```
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
    -subj '/CN=lab.hortonworks.net/O=Hortonworks Testing/C=US'

openssl genrsa -out wildcard-lab-hortonworks-net.key 2048
openssl req -new -key wildcard-lab-hortonworks-net.key -out wildcard-lab-hortonworks-net.csr \
    -subj '/CN=*.lab.hortonworks.net/O=Hortonworks Testing/C=US'
openssl x509 -req -in wildcard-lab-hortonworks-net.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out wildcard-lab-hortonworks-net.crt -days 3650
```

****************************************

## Configure AD OUs, Groups, Users, ...
----------------------------------------

```
$my_base = "DC=lab,DC=hortonworks,DC=net"
$my_ous = "CorpUsers","HadoopNodes","HadoopServices","ServiceUsers"
$my_groups = "hadoop-users","ldap-users","legal","hr","sales","hadoop-admins"

$my_ous | ForEach-Object {
  NEW-ADOrganizationalUnit $_;
}

$my_groups | ForEach-Object {
    NEW-ADGroup –name $_ –groupscope Global –path "OU=CorpUsers,$my_base";
}

$UserCSV = @"
samAccountName,Name,ParentOU,Group
hadoopadmin,"hadoopadmin","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net","hadoop-admins"
rangeradmin,"rangeradmin","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net","hadoop-users"
ambari,"ambari","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net","hadoop-users"
keyadmin,"keyadmin","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net","hadoop-users"
ldap-reader,"ldap-reader","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net","ldap-users"
registersssd,"registersssd","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net","ldap-users"
legal1,"Legal1 Legal","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net","legal"
legal2,"Legal2 Legal","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net","legal"
legal3,"Legal3 Legal","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net","legal"
sales1,"Sales1 Sales","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net","sales"
sales2,"Sales2 Sales","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net","sales"
sales3,"Sales3 Sales","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net","sales"
hr1,"Hr1 HR","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net","hr"
hr2,"Hr2 HR","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net","hr"
hr3,"Hr3 HR","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net","hr"
"@

$UserCSV > Users.csv

$AccountPassword = "BadPass#1" | ConvertTo-SecureString -AsPlainText -Force
Import-Module ActiveDirectory
Import-Csv "Users.csv" | ForEach-Object {
    $userPrincinpal = $_."samAccountName" + "@lab.hortonworks.net"
    New-ADUser -Name $_.Name `
        -Path $_."ParentOU" `
        -SamAccountName  $_."samAccountName" `
        -UserPrincipalName  $userPrincinpal `
        -AccountPassword $AccountPassword `
        -ChangePasswordAtLogon $false  `
        -Enabled $true
    add-adgroupmember -identity $_."Group" -member (Get-ADUser $_."samAccountName")
    add-adgroupmember -identity "hadoop-users" -member (Get-ADUser $_."samAccountName")
}
```

1. Delegate OU permissions to `hadoopadmin` for `OU=HadoopServices` (right click HadoopServices > Delegate Control > Add > hadoopadmin > checknames > OK >  "Create, delete, and manage user accounts" > OK)


1. Give registersssd user permissions to join workstations to OU=HadoopNodes (needed to run 'adcli join' successfully)
  ```
# CorpUsers > Properties > Security > Advanced > 
#    Add > 'Select a principal' > registersssd > Check names > Ok > Select below checkboxes > OK
#           Create Computer Objects
#           Delete Computer Objects
#    Add > 'Select a principal' > registersssd > Check names > Ok > Set 'Applies to' to: 'Descendant Computer Objects' > select below checkboxes > Ok > Apply
#           Read All Properties
#           Write All Properties
#           Read Permissions
#           Modify Permissions
#           Change Password
#           Reset Password
#           Validated write to DNS host name
#           Validated write to service principle name
  ```

For more details see: https://jonconwayuk.wordpress.com/2011/10/20/minimum-permissions-required-for-account-to-join-workstations-to-the-domain-during-deployment/


1. create principal for Ambari. This will be used later to kerborize Ambari before setting up views
```
ktpass -out ambari.keytab -princ ambari@LAB.HORTONWORKS.NET -pass BadPAss#1 -mapuser ambari@LAB.HORTONWORKS.NET -mapop set -crypto All -ptype KRB5_NT_PRINCIPAL
```

1. To test the LDAP connection from a Linux node
  ```
  sudo yum install openldap-clients
  ldapsearch -h ad01.lab.hortonworks.net -p 389 -D "ldap-reader@lab.hortonworks.net" -w BadPass#1 -b "OU=CorpUsers,DC=lab,DC=hortonworks,DC=net" "(&(objectclass=person)(sAMAccountName=sales1))"
  ```

