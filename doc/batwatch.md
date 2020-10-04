# bat-extras: batwatch

Watch for changes in one or more files, and print them with `bat`.

Please note this watches filesystem files, and not command output like `watch(1)`.



## Usage

    batwatch [OPTIONS] FILE...



## Options

| Short | Long                  | Description                                                  |
| ----- | --------------------- | ------------------------------------------------------------ |
|       | `--watcher=[watcher]` | Use a specific program to watch for file changes. See [below](#watchers) for more details. |
|       | `--clear`             | Clear the screen before printing the files.<br />This is enabled by default. |
|       | `--no-clear`          | Do not clear the screen before printing the files.           |
|       | `--color`             | Force color output.                                          |
|       | `--no-color`          | Force disable color output.                                  |

All remaining options are passed through to bat.



## Watchers

Batwatch uses external programs to watch for file changes.
Currently, the following programs are supported:

- [entr](http://entrproject.org/)

There is also a fallback `poll` watcher available.



## Installation

This script is a part of the `bat-extras` suite of scripts. You can find install instructions [here](../README.md#installation).




## Issues?

If you find an issue or have a feature suggestion, make a pull request or issue through GitHub!
Contributions are always welcome.
