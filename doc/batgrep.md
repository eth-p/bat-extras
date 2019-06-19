# bat-extras: batgrep

A script that combines [ripgrep](https://github.com/burntsushi/ripgrep) with bat's syntax highlighting and output formatting.



## Command Line

**Synopsis:**

- `batgrep [OPTIONS] PATTERN [PATH...] `



**Options:**

| Short | Long                       | Description                                                |
| ----- | -------------------------- | ---------------------------------------------------------- |
| `-i`  | `--ignore-case`            | Use case insensitive searching.                            |
| `-A`  | `--after-context=[LINES]`  | Display the next *n* lines after a matched line.           |
| `-B`  | `--before-context=[LINES]` | Display the previous `n` lines before a matched line.      |
| `-C`  | `--context=[LINES]`        | A combination of `--after-context` and `--before-context`. |
|       | `--no-follow`              | Do not follow symlinks.                                    |



**Options (Passthrough)**:
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



## Caveats

**Differences from ripgrep:**

- `--follow` is enabled by default for `batgrep`.

- Not all the `ripgrep` options are supported.



## Issues?

If you find an issue or have a feature suggestion, make a pull request or issue through GitHub!
Contributions are always welcome.