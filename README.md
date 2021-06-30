# knbnBrd

knbnBrd is a kanban board manager command written in Bash

<a href="./LICENSE"><img src="https://img.shields.io/github/license/Greenlandicsmiley/knbnBrd?color=Green&style=flat-square"></a>
<a href="https://github.com/Greenlandicsmiley/knbnBrd/releases/latest"><img src="https://img.shields.io/github/v/tag/Greenlandicsmiley/knbnBrd?color=Green&label=version&style=flat-square"></a>
<img src="https://img.shields.io/github/languages/top/Greenlandicsmiley/knbnBrd?color=Green&label=bash&style=flat-square">
<img src="https://i.imgur.com/KTpI8gj.png" height="360px" align="right">

### Requirements

Coreutils, Bash

### Description
In an effort to further understand and learn bash scripting within Linux, 
I have created this kanban board manager

Using the command `knbn`, you can:
- Add tasks to columns
- Add notes to tasks
- List tasks
- Remove tasks
- Remove notes from tasks
- Move tasks from one column to another
- Wipe columns of all tasks.

Run `knbn help` to learn the syntax

GPLv3 notice can be printed by running `knbn notice`

Track feature progress at:
- https://github.com/Greenlandicsmiley/knbnBrd/projects/1

### Installation
Download the latest release
- https://github.com/Greenlandicsmiley/knbnBrd/releases/latest

Install the script
- Run `./configure` inside the script directory
- Run `make install` inside the script directory

**NOTE:** You may have to run this as root.

### Updating the script
Download latest release
- https://github.com/Greenlandicsmiley/knbnBrd/releases/latest

Run `make update` in the script directory

**NOTE:** You may have to run this as root.

### Migrating from /opt to home
After you have updated, you can run `make migrate` to copy board from /opt/knbnBrd to ~/.local/share/knbnBrd

This will delete the /opt/knbnBrd directory

### Uninstall
- Run `make uninstall` or `knbn uninstall` to uninstall the script

**NOTE:** You may have to run either as root.
