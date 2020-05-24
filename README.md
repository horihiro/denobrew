# dvm.sh
Version management script for Deno🦕

# How to use
## ls-remote
Retrieving releases from GitHub.

```bash
$ dvm.sh ls-remote
v1.0.2
v1.0.1
v1.0.0
v1.0.0-rc3
v1.0.0-rc2
v1.0.0-rc1
  :
```

## install
Installing specified version.

```bash
$ dvm.sh install v1.0.2
######################################################################## 100.0%
Archive:  /home/<USER_NAME>/.dvm.sh/releases/v1.0.2/bin/deno.zip
  inflating: deno
Deno was installed successfully to /home/<USER_NAME>/.dvm.sh/releases/v1.0.2/bin/deno
Please execute `dvm.sh use v1.0.2` for activating the version.

```

## ls
Retriving installed version.

```bash
$ dvm.sh ls
v1.0.2

```

## use
Activating specified version.

```bash
$ dvm.sh use v1.0.2
deno 1.0.2
v8 8.4.300
typescript 3.9.2
```


```bash
$ dvm.sh use v1.0.1
Deno `v1.0.1` is not found in your machine.
Please retry after executing following command.

  `dvm.sh install v1.0.1`
```