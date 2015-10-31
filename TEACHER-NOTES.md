## Debugging Master Classes

______________________________________

## Notes only valid for pdsh deployed labs


## Various notes & commands for whoever is running the class

#### Set the list of hosts:
```
hosts=hostname1,hostname2,hostname3,
## or programatically
```

#### Set environment for pdsh
```
export PDSH_SSH_ARGS_APPEND="-l student -i ${HOME}/.ssh/student.pri.key -o ConnectTimeout=5 -o CheckHostIP=no -o StrictHostKeyChecking=no -o RequestTTY=force"
```

#### Update ambari-bootstrap
```
command="cd /opt/ambari-bootstrap; git pull"
pdsh -w ${hosts_all} "${command}"
```

#### Check hosts
```
command="uptime"
pdsh -w ${hosts_all} "${command}"
```

