# bat-extras: batgrep

Quickly search through and highlight files using [ripgrep](https://github.com/burntsushi/ripgrep).

Search through files or directories looking for matching regular expressions (or fixed strings with `-F`), and print the output using `bat` for an easy and syntax-highlighted experience.



## Usage

    batgrep [OPTIONS] PATTERN [PATH...]



## Options

| Short | Long                         | Description                                                  |
| ----- | ---------------------------- | ------------------------------------------------------------ |
| `-i`  | `--ignore-case`              | Use case insensitive searching.                              |
| `-s`  | `--case-sensitive`           | Use case sensitive searching.                                |
| `-S`  | `--smart-case`               | Use smart case searching.                                    |
| `-A`  | `--after-context=[LINES]`    | Display the next *n* lines after a matched line.             |
| `-B`  | `--before-context=[LINES]`   | Display the previous `n` lines before a matched line.        |
| `-C`  | `--context=[LINES]`          | A combination of `--after-context` and `--before-context`.   |
| `-p`  | `--search-pattern`           | Tell pager to search for `PATTERN`. Currently supported pagers: `less`. |
|       | `--no-follow`                | Do not follow symlinks.                                      |
|       | `--no-snip`                  | Do not show the `snip` decoration.<br /><br />This is automatically enabled when `--context=0` or when `bat --version` is less than `0.12.x`. |
|       | `--no-highlight`             | Do not highlight matching lines.<br /><br />This is automatically enabled when `--context=0`. |
|       | `--color`                    | Force color output.                                          |
|       | `--no-color`                 | Force disable color output.                                  |
|       | `--paging=["never"/"always"]`| Enable/disable paging.                                     |
|       | `--pager=[PAGER]`            | Specify the pager to use.                                    |
|       | `--terminal-width=[COLS]`    | Generate output for the specified terminal width.            |

The following options are passed directly to ripgrep, and are not handled by this script.

| Short | Long                       | Notes                                                        |
| ----- | -------------------------- | ------------------------------------------------------------ |
| `-F`  | `--fixed-strings`          |                                                              |
| `-U`  | `--multiline`              |                                                              |
| `-P`  | `--pcre2`                  |                                                              |
| `-z`  | `--search-zip`             |                                                              |
| `-w`  | `--word-regexp`            |                                                              |
|       | `--one-file-system`        |                                                              |
|       | `--multiline-dotall`       |                                                              |
|       | `--ignore` / `--no-ignore` |                                                              |
|       | `--crlf` / `--no-crlf`     |                                                              |
|       | `--hidden` / `--no-hidden` |                                                              |
| `-E`  | `--encoding`               | This is unsupported by `bat`, and may cause issues when trying to display unsupported encodings. |
| `-g`  | `--glob`                   |                                                              |
| `-t`  | `--type`                   |                                                              |
| `-T`  | `--type-not`               |                                                              |
| `-m`  | `--max-count`              |                                                              |
|       | `--max-depth`              |                                                              |
|       | `--iglob`                  |                                                              |
|       | `--ignore-file`            |                                                              |



## Installation

This script is a part of the `bat-extras` suite of scripts. You can find install instructions [here](../README.md#installation).



## Caveats

**Differences from ripgrep:**

- `--follow` is enabled by default for `batgrep`.

- Not all the `ripgrep` options are supported.



## Issues?

If you find an issue or have a feature suggestion, make a pull request or issue through GitHub!
Contributions are always welcome.
