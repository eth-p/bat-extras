# bat-extras: batdiff

Diff a file against the current git index, or display the diff between two files.

This script supports using [delta](https://github.com/dandavison/delta) as an alternative highlighter for diffs.




## Usage

    batdiff [OPTIONS] FILE
    batdiff [OPTIONS] FILE OTHER_FILE



## Options

| Short | Long                          | Description                                                  |
| ----- | ----------------------------- | ------------------------------------------------------------ |
| `-C`  | `--context=[LINES]`           | The number of lines to show before and after the differing lines. |
|       | `--delta`                     | Display diffs using `delta`.                                 |
|       | `--color`                     | Force color output.                                          |
|       | `--no-color`                  | Force disable color output.                                  |
|       | `--paging=["never"/"always"]` | Enable/disable paging.                                       |
|       | `--pager=[PAGER]`             | Specify the pager to use.                                    |
|       | `--terminal-width=[COLS]`     | Generate output for the specified terminal width.            |



## Installation

This script is a part of the `bat-extras` suite of scripts. You can find install instructions [here](../README.md#installation).



## Caveats

**When using `bat` as the printer:**

- Syntax highlighting in diffs between two files is not supported.
- Syntax highlighting in a single-file diff requires `bat` >= 0.15.

**When using `delta` as the printer:**

- The `--no-color` option does not remove all color output.



## Issues?

If you find an issue or have a feature suggestion, make a pull request or issue through GitHub!
Contributions are always welcome.
