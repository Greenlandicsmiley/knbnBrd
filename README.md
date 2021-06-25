# knbnBrd

knbnBrd is a kanban board manager command written in Bash

<a href="./LICENSE"><img src="https://img.shields.io/github/license/Greenlandicsmiley/knbnBrd?color=Green&style=flat-square"></a>
<a href="https://github.com/Greenlandicsmiley/knbnBrd/releases/latest"><img src="https://img.shields.io/github/v/tag/Greenlandicsmiley/knbnBrd?color=Green&label=version&style=flat-square"></a>
<img src="https://img.shields.io/github/languages/top/Greenlandicsmiley/knbnBrd?color=Green&label=bash&style=flat-square">
<img src="https://i.imgur.com/QEqKQ3N.png" height="240px" align="right">

### Requirements

Coreutils, Bash

### Description
In an effort to further understand and learn bash scripting within Linux, 
I have created this kanban board manager to both track my tasks and learn more about scripting

Using the command `knbn`, you can:
- Add tasks to columns
- Lists tasks
- Remove tasks
- Move tasks from one column to another
- And wipe columns of all tasks.

Run `knbn help` to learn the syntax

GPLv3 notice can be printed by simply running `knbn`

Track feature progress at:
- https://github.com/Greenlandicsmiley/knbnBrd/projects/1

### Installation
Download the latest release
- https://github.com/Greenlandicsmiley/knbnBrd/releases/latest

Install the script
- Make `configure` executable, idk how to not require this elp
- Run `./configure` inside the script directory
- Run `make install` inside the script directory

**NOTE:** You may have to run this as root.

### Uninstall
- Run `make uninstall` or `knbn uninstall` to uninstall the script

**NOTE:** You may have to run either as root.
