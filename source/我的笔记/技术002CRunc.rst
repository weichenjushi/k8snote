技术002CRunc

技术002CRunc
============

-  `技术002CRunc <>`__

   -  `Creating an OCI Bundle <>`__
   -  `Running Containers <>`__
   -  `通过Supervisor运行runc <>`__

Creating an OCI Bundle
----------------------

-  create the top most bundle directory

``mkdir /mycontainer cd /mycontainer``

-  create the rootfs directory

``mkdir rootfs``

-  export busybox via Docker into the rootfs directory

``docker export $(docker create busybox) | tar -C rootfs -xvf -``
命令\ ``runc spec``\ 会生成基本的模版文件config.json

Running Containers
------------------

1. 以root用户运行

-  run as root

``cd /mycontainer runc run mycontainerid``

If you used the unmodified runc spec template this should give you a sh
session inside the container.

The second way to start a container is using the specs lifecycle
operations. This gives you more power over how the container is created
and managed while it is running. This will also launch the container in
the background so you will have to edit the config.json to remove the
terminal setting for the simple examples here. Your process field in the
config.json should look like this below with “terminal”: false and
\`“args”: [“sleep”, “5”].

“process”: { “terminal”: false, “user”: { “uid”: 0, “gid”: 0 }, “args”:
[ “sleep”, “5”], “env”: [
“PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin”,
“TERM=xterm”], “cwd”: “/”, “capabilities”: { “bounding”: [
“CAP_AUDIT_WRITE”, “CAP_KILL”, “CAP_NET_BIND_SERVICE”], “effective”: [
“CAP_AUDIT_WRITE”, “CAP_KILL”, “CAP_NET_BIND_SERVICE”], “inheritable”: [
“CAP_AUDIT_WRITE”, “CAP_KILL”, “CAP_NET_BIND_SERVICE”], “permitted”: [
“CAP_AUDIT_WRITE”, “CAP_KILL”, “CAP_NET_BIND_SERVICE”], “ambient”: [
“CAP_AUDIT_WRITE”, “CAP_KILL”, “CAP_NET_BIND_SERVICE”] }, “rlimits”: [ {
“type”: “RLIMIT_NOFILE”, “hard”: 1024, “soft”: 1024 }],
“noNewPrivileges”: true },\`

-  run as root

cd /mycontainer runc create mycontainerid

-  view the container is created and in the “created” state

runc list

-  start the process inside the container

runc start mycontainerid

-  after 5 seconds view that the container has exited and is now in the
   stopped state

runc list

-  now delete the container

runc delete mycontainerid 1. 以普通用户运行

-  Same as the first example

   mkdir ~/mycontainer cd ~/mycontainer mkdir rootfs docker export
   $(docker create busybox) \| tar -C rootfs -xvf -

-  The –rootless parameter instructs runc spec to generate a
   configuration for a rootless container, which will allow you to run
   the container as a non-root user.

``runc spec --rootless``

-  The –root parameter tells runc where to store the container state. It
   must be writable by the user.

``runc --root /tmp/runc run mycontainerid``

通过Supervisor运行runc
----------------------

Supervisors \`[Unit] Description=Start My Container [Service]
Type=forking

ExecStart=/usr/local/sbin/runc run -d –pid-file /run/mycontainerid.pid
mycontainerid

ExecStopPost=/usr/local/sbin/runc delete mycontainerid
WorkingDirectory=/mycontainer PIDFile=/run/mycontainerid.pid [Install]
WantedBy=multi-user.target\`
