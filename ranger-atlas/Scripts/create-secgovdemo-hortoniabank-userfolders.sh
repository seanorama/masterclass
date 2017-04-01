sudo sudo -u hdfs bash -c "
    # kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs-hortoniabank@FIELD.HORTONWORKS.COM
    hadoop fs -mkdir /user/admin
    hadoop fs -chown admin:hdfs /user/admin
    hadoop fs -mkdir /user/joe-analyst
    hadoop fs -chown joe-analyst:analyst /user/joe-analyst
    hadoop fs -mkdir /user/kate-hr
    hadoop fs -chown kate-hr:hr /user/kate-hr
    hadoop fs -mkdir /user/ivanna-eu-hr
    hadoop fs -chown ivanna-eu-hr:hr /user/ivanna-eu-hr
    hadoop fs -mkdir /user/compliance-admin
    hadoop fs -chown compliance-admin:compliance /user/compliance-admin
    hadoop fs -mkdir /user/hadoopadmin
    hadoop fs -chown hadoopadmin:hdfs /user/hadoopadmin
"

