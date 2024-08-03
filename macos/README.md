# MacOS Setup

## Automated Steps

```sh
$ git clone git@github.com:hashhar/ansible-workstation.git
$ cd ansible-workstation/macos
$ bash bootstrap.sh
```

The `bootstrap.sh` script:

1. Installs [Homebrew](https://brew.sh).
1. Installs Python3 from Homebrew.
1. Installs [Ansible](https://www.ansible.com) using `pip3` as a user level
   package.
1. Installs required Ansible collections from `requirements.yml`.
1. Runs the playbook against the inventory defined in `inventory`.

## Manual Steps

### JetBrains

`open /Applications/JetBrains\ Toolbox.app` and install whatever apps are needed.

See [this issue](https://youtrack.jetbrains.com/issue/ALL-653) for ability to
script Toolbox.
