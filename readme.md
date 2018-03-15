# wafers
Named file system wafer stack trees

## Why
I use this to compose bootable root filesystems for linux containers. I don't want all of Docker and `machinectl clone` is really only useful with btrfs (overlayfs feels like a better fit to me at the moment).

## How
[overlayfs](https://www.kernel.org/doc/Documentation/filesystems/overlayfs.txt) and a bit of bash.

## Usage
```
$ wafers stack name [parent]
$ wafers unstack stack1 [stack2] [..]
```

## Commands

#### `stack`
Create a new stack based on the wafer `name`.
* `name`  
 The uppermost of a stack of wafers you want to create at `${STACKS}/name`. The ancestry of this wafer is recursively traced automatically to produce the full stack.
* `[parent]`  
 If the wafer `name` does not yet exist, it can be created automatically as long as a `parent` is specified to base it on.

#### `unstack`
Assume each positional argument corresponds to a wafer stack in `$STACKS`, and unstack each one.

## Environment variables

#### `WAFERS`
Set this to override default value of `/var/lib/wafers`.

#### `STACKS`
Set this to override default value of `/var/lib/machines`.

## Example
``` bash
# create and cd to $WAFERS (/var/lib/wafers by default)
$ mkdir -p /var/lib/wafers
$ cd /var/lib/wafers

# create a directory tree to represent a base wafer
$ mkdir -p archbase/data

# get some bootable rootfs in there
$ pacstrap -cdi archbase/data base --ignore linux --ignore linux-firmware 

# create a new wafer on top of another wafer and recursively mount
# the resulting stack into $STACKS (/var/lib/machines by default)
$ wafers stack archbase2 archbase
2 wafers stacked at /var/lib/machines/archbase2

# have a look at the raw wafer
$ tree archbase2/data
archbase2/data

0 directories, 0 files

# and have a look at the mounted stack
$ ls /var/lib/machines/archbase2
bin  boot  dev  etc  home  lib  lib64  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var

# boot into the stack with your fav container tool, make a change, get back out
$ systemd-nspawn -bD /var/lib/machines/archbase2
Spawning container archbase2 on /var/lib/machines/archbase2.
Press ^] three times within 1s to kill container.
systemd 237 running in system mode. (+PAM -AUDIT -SELINUX -IMA -APPARMOR +SMACK -SYSVINIT +UTMP ..snip
Detected virtualization systemd-nspawn.
Detected architecture x86-64.

Welcome to Arch Linux!

[  OK  ] Started Dispatch Password Requests to Console Directory Watch.
[  OK  ] Reached target Remote File Systems.
..snip
[  OK  ] Reached target Multi-User System.
[  OK  ] Reached target Graphical Interface.

Arch Linux 4.15.3-300.fc27.x86_64 (console)

archbase2 login: root
Last login: Fri Feb 23 03:14:32 on pts/0
[root@archbase2 ~]$ useradd -s/bin/bash -m jesse
[root@archbase2 ~]$
Container archbase2 terminated by signal KILL.

# have another look at the raw wafer to see where useradd made changes to the stack
$ tree archbase2/data
archbase2/data
├── etc
│   ├── group
│   ├── group-
│   ├── gshadow
│   ├── gshadow-
│   ├── machine-id
│   ├── passwd
│   ├── passwd-
│   ├── resolv.conf
│   ├── shadow
│   └── shadow-
├── home
│   └── jesse
├── root
└── var
    └── log
        ├── btmp
        ├── faillog
        ├── journal
        │   └── 7ee3294689ca4a9394ad8a34cc44d1d8     
        │       ├── system@000565dde63c6d7b-87320e8b62aabc30.journal~
        │       └── system.journal
        ├── lastlog
        ├── tallylog
        └── wtmp

# unstack
wafers unstack archbase2

# restack (note parent wafer is only required the first time)
wafers stack archbase2

# you can also stack wafers that have no parent(s)
wafers stack archbase

# use with machinectl
machinectl start archbase
machinectl shell archbase
```

## License
MIT
