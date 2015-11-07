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
$new_hostname = ad01
Rename-Computer -NewName $new_hostname -Restart
   ```
   
****************************************

## Install AD
----------------------------------------

1. Install AD software features

   ```
Install-WindowsFeature AD-Domain-Services –IncludeManagementTools
   ```

2. Open Powershell (right click and "open as Administrator)

3. Prepare your environment. Update these to your liking.

   ```
$domainname = "lab.hortonworks.net"
$domainnetbiosname = "LAB"
$password = "BadPass#1"
   ```

4. Configure AD. You have 2 options:
   1. Deploy AD without DNS (relying on /etc/hosts or a separate DNS)

   ```
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

****************************************

## Add UPN suffixes
----------------------------------------

If the domain of your Hadoop nodes is different than your AD domain:
https://technet.microsoft.com/en-gb/library/cc772007.aspx


****************************************

## Create CA & self-signed certificate for LDAPS
----------------------------------------

- TODO. 1 example here:
http://www.javaxt.com/Tutorials/Windows/How_to_Enable_LDAPS_in_Active_Directory

****************************************

## Configure AD OUs, Groups, Users, ...
----------------------------------------

1. Set these before running scripts:

   ```powershell
$my_base = "DC=lab,DC=hortonworks,DC=net"
$my_ous = "CorpUsers","HadoopNodes","ServiceUsers"
$my_groups = "hadoop-users","ldap-users","legal","hr","sales"
$my_users = "hr1","hr2","hr3","legal1","legal2","legal3","sales1","sales2","sales3"
$my_admin = "hadoopadmin"
   ```
   
1. Create OUs

   ```powershell
## create OUs
$my_ous | ForEach-Object {
  NEW-ADOrganizationalUnit $_;
}
   ```
   

1. Create groups

   ```powershell
$my_groups | ForEach-Object {
    NEW-ADGroup –name $_ –groupscope Global –path "OU=CorpUsers,$my_base";
}
   ```

1. Create users including
   - admin user (hadoopadmin)
   - business users (legal1, legal2, ...)
   - service users (rangeradmin, keyadmin, ambari)
   - user who can register computers for SSSD (registersssd)
   - ldapconnect user for LDAP lookups (ambari, ranger, knox, ...)

   a. Create NewUsers.csv file under C:\Users\Administrator\Downloads (*TODO:* automate creation of this csv based on above users)
   ```
samAccountName,Name,ParentOU
hadoopadmin,"hadoopadmin hadoopadmin","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net"
rangeradmin,"rangeradmin rangeradmin","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net"
keyadmin,"keyadmin keyadmin","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net"
ambari,"ambari ambari","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net"
ldapconnect,"ldapconnect ldapconnect","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net"
registersssd,"registersssd registersssd","OU=ServiceUsers,DC=lab,DC=hortonworks,DC=net"
legal1,"Legal1 Legal","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net"
legal2,"Legal2 Legal","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net"
legal3,"Legal3 Legal","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net"
sales1,"Sales1 Sales","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net"
sales2,"Sales2 Sales","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net"
sales3,"Sales3 Sales","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net"
hr1,"Hr1 HR","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net"
hr2,"Hr2 HR","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net"
hr3,"Hr3 HR","OU=CorpUsers,DC=lab,DC=hortonworks,DC=net"   
   ```
  b. Create Create-BulkADUsers-CSV.ps1 file under C:\Users\Administrator\Downloads  (*TODO:* stop hardcoding domain and password)
  ```
Import-Module ActiveDirectory
Import-Csv "C:\Users\Administrator\Downloads\NewUsers.csv" | ForEach-Object {
 $userPrincinpal = $_."samAccountName" + "@lab.hortonworks.net"
New-ADUser -Name $_.Name `
 -Path $_."ParentOU" `
 -SamAccountName  $_."samAccountName" `
 -UserPrincipalName  $userPrincinpal `
 -AccountPassword (ConvertTo-SecureString "BadPass#1" -AsPlainText -Force) `
 -ChangePasswordAtLogon $true  `
 -Enabled $true
}  
  ```
  c. Run script to create users
  ```
powershell.exe -executionpolicy ByPass
.\Create-BulkADUsers-CSV.ps1 .\NewUsers.csv  
  ```
1. Add users to groups
   - TODO

