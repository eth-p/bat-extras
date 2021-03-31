# bat-extras

Bash scripts that integrate [bat](https://github.com/sharkdp/bat) with various command line tools.

&nbsp;

## Scripts

### [`batgrep`](doc/batgrep.md)
Quickly search through and highlight files using [ripgrep](https://github.com/burntsushi/ripgrep).
<u>Requirements:</u> `ripgrep`



### [`batman`](doc/batman.md)

Read system manual pages (`man`) using `bat` as the manual page formatter.



### [`batpipe`](doc/batpipe.md)

A `less` (and soon `bat`) preprocessor for viewing more types of files in the terminal.



### [`batwatch`](doc/batwatch.md)

Watch for changes in one or more files, and print them with `bat`.
<u>Requirements:</u> `entr` (optional)



### [`batdiff`](doc/batdiff.md)
Diff a file against the current git index, or display the diff between two files.
<u>Requirements:</u> `bat`, `delta` (optional)



### [`prettybat`](doc/prettybat.md)

Pretty-print source code and highlight it with `bat`.
<u>Requirements:</u> (see doc/prettybat.md)

&nbsp;

## Installation via Package Manager

### Homebrew

All of the `bat-extras` scripts can be installed with `brew install eth-p/software/bat-extras`.

If you would only like to install one of the scripts, you can use `brew install eth-p/software/bat-extras-[SCRIPT]` to install it.


&nbsp;

## Installation (![CircleCI](https://circleci.com/gh/eth-p/bat-extras.svg?style=svg))

The scripts in this repository are designed to run as-is, provided that they aren't moved around.
This means that you're free to just symlink `src/[script].sh` to your local bin folder.

If you would rather have *faster*, self-contained scripts that you can place and run anywhere, you can use the `build.sh` script to create (and optionally install) them.

&nbsp;

**Building:**

```bash
./build.sh [OPTIONS...]
```

This will combine and preprocess each script under the `src` directory, and create corresponding self-contained scripts in the `bin` folder. Any library scripts that are sourced using `source "${LIB}/[NAME].sh"` will be embedded automatically.

&nbsp;

**Minification:**

There are three different options for minification:

| Option          | Description                                            |
| --------------- | ------------------------------------------------------ |
| `--minify=none` | Nothing will be minified.                              |
| `--minify=lib`  | Embedded library scripts will be minified. \[default\] |
| `--minify=all`  | Everything will be minified.                           |

This uses [shfmt](https://github.com/mvdan/sh) to perform minification.


&nbsp;

**Installation:**

You can also specify `--install` and `--prefix=PATH` to have the build script automatically install the scripts for all users on the system. You may need to run the build script as root.

If you only want to install a single script, you can run the build process and copy the script directly out of the newly-created `bin` folder.



**Manuals:** (EXPERIMENTAL)

You can specify `--manuals` to have the build script generate a `man` page for each of the markdown documentation files.
This is an experimental feature that uses a non-compliant Markdown "parser" written in Bash, and there is no guarantee
as for the quality of the generated manual pages.



**Alternate Executable:**

Depending on the distribution, bat may have been renamed to avoid package conflicts.
If you wish to use these scripts on a distribution where this is the case, there is an `--alternate-executable=NAME` option which will build the scripts to use an alternate executable name.



**Verification:**

The build script will attempt to verify the correctness of the "bin" scripts by comparing their output with their source counterparts. It is recommended to let it do this, but you can disable verification with the `--no-verify` option.

&nbsp;

## Contributing

If you would like to contribute to `bat-extras`, please feel free to [open an issue on GitHub](https://github.com/eth-p/bat-extras/issues), or make a pull request. If you do the latter, please keep our [contributing guidelines](./CONTRIBUTING.md) in mind.  
