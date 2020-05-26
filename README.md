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
This is tested on Ubuntu 16 on WSL only.<br>
To Mac users, Please try this and give me feedback.

# How to use/Sub-commands
## `ls-remote`
Retrieving releases from GitHub.

```bash
$ dvm.sh ls-remote
v1.0.2          v1.0.0-rc3      v0.42.0         v0.39.0         v0.37.0         v0.34.0         v0.31.0         v0.28.1         v0.26.0         v0.23.0
v1.0.1          v1.0.0-rc2      v0.41.0         v0.38.0         v0.36.0         v0.33.0         v0.30.0         v0.28.0         v0.25.0         v0.22.0
v1.0.0          v1.0.0-rc1      v0.40.0         v0.37.1         v0.35.0         v0.32.0         v0.29.0         v0.27.0         v0.24.0         v0.21.0
```

Note:<br>
This sub-command uses GitHub API.
If API rate limit exceeded, Setting `$DVMSH_GITHUBAPI_CREDENTIAL`  as following helps you to access it.

```
$ DVMSH_GITHUBAPI_CREDENTIAL=<GITHUB_ACCOUNT> dvm ls-remote
```

## `install`
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

## `ls`
Retriving installed version.

```bash
$ dvm.sh ls
v1.0.2
```

## `use`
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

## `uninstall`
Uninstalling specified version from your computer.

```bash
$ dvm.sh uninstall v1.0.2
```
## `ls-all`
Retriving releases and installed

```bash
$ dvm.sh ls-all
Remote:
v1.0.2          v1.0.0-rc3      v0.42.0         v0.39.0         v0.37.0         v0.34.0         v0.31.0         v0.28.1         v0.26.0         v0.23.0
v1.0.1          v1.0.0-rc2      v0.41.0         v0.38.0         v0.36.0         v0.33.0         v0.30.0         v0.28.0         v0.25.0         v0.22.0
v1.0.0          v1.0.0-rc1      v0.40.0         v0.37.1         v0.35.0         v0.32.0         v0.29.0         v0.27.0         v0.24.0         v0.21.0

Local:
v1.0.2
```