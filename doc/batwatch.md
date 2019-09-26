# bat-extras: batwatch

Watch for changes in one or more files, and print them when updated.



## Command Line

**Synopsis:**

- `batwatch [OPTIONS] FILE... `



**Options:**

| Short | Long                  | Description                                                  |
| ----- | --------------------- | ------------------------------------------------------------ |
|       | `--watcher=[watcher]` | Use a specific program to watch for file changes. See [below](#watchers) for more details. |
|       | `--clear`             | Clear the screen before printing the files.<br />This is enabled by default. |
|       | `--color`             | Force color output.                                          |
|       | `--no-color`          | Force disable color output.                                  |



**Options (Passthrough)**:
All remaining options are passed through to bat.



## Watchers

Batwatch uses external programs to watch for file changes.
Currently, the following programs are supported:

- [entr](http://entrproject.org/)



## Installation

This script is a part of the `bat-extras` suite of scripts. You can find install instructions [here](../README.md#installation).



## Caveats

None so far.



## Issues?

If you find an issue or have a feature suggestion, make a pull request or issue through GitHub!
Contributions are always welcome.