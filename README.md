# [dvm.sh](https://raw.githubusercontent.com/horihiro/dvm.sh/master/dvm.sh)
Version management script for Deno🦕

# Install
Download and set [this](https://raw.githubusercontent.com/horihiro/dvm.sh/master/dvm.sh) as executable.

or 

Add following function definition to your .bashrc/.bash_profile etc.

```bashrc
function dvm () {
  bash <(curl -fsSL "https://raw.githubusercontent.com/horihiro/dvm.sh/master/dvm.sh") $@
}
```
# Requirements
This script can be executable under following environment.

  - use bash as shell
  - curl and jq are installed

Note:<br>
This is tested on Ubuntu 16 on WSL only.

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

Note:<br>
This sub-command uses GitHub API.
If API rate limit exceeded, Setting `$DVMSH_GIHHUBAPI_CREDENTIAL`  as following helps you to access it.

```
$ DVMSH_GIHHUBAPI_CREDENTIAL=horihiro dvm ls-remote
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

Note:<br>
This sub-command uses `ls-remote` sub-command in order to validate specified version string.

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