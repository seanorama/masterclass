### Authorization

* `hadoop fs -chown myuser /user/myuser`


### Ranger

#### Managing Authorization before Ranger

```
## HDFS
hadoop fs -mkdir /tmp/example-dir
hadoop fs -chown sean /tmp/testdir
hadoop fs -chmod 755 /tmp/testdir

## Hive

```

#### Deploy Ranger

https://github.com/abajwa-hw/security-workshops/blob/master/Setup-ranger-23.md

#### Managing Authorization with Ranger