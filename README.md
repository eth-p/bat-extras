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

All of the `bat-extras` scripts can be installed with `brew install bat-extras`.

If you would prefer to only install the specific scripts you need, you can use the `eth-p/software` tap to install individual scripts: `brew install eth-p/software/bat-extras-[SCRIPT]`


### Pacman 

`bat-extras` is [officially available](https://archlinux.org/packages/extra/any/bat-extras/) on the Arch extra repository!

If you have the extra repository enabled, you can install `bat-extras` by running:

```bash
pacman -S bat-extras
```

### Gentoo
`bat-extras` is available on **Gentoo's Guru Overlay** as `sys-apps/bat-extras`.

To install, first make sure you've added the [Gentoo Guru Overlay](https://wiki.gentoo.org/wiki/Project:GURU) to your local repositories, then emerge accordingly...

```bash
emerge sys-apps/bat-extras
```

### Fedora (Unofficial)
`bat-extras` is available in an unofficial Fedora Copr
[repository](https://copr.fedorainfracloud.org/coprs/awood/bat-extras/).
**Note**: this package does not contain `prettybat` since `prettier` is not yet
packaged for Fedora.

Install the Copr plugin, enable the repository, and then install the package
by running:

```bash
dnf install dnf-plugins-core 
dnf copr enable awood/bat-extras
dnf install bat-extras
```

&nbsp;

## Installation

[![Test](https://github.com/eth-p/bat-extras/actions/workflows/test.yaml/badge.svg)](https://github.com/eth-p/bat-extras/actions/workflows/test.yaml)

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



**Manuals:**

The build script will automatically generate a `man` page for each of the markdown documentation files.
This is a beta feature that uses a non-compliant Markdown "parser" written in Bash, and there is no guarantee towards the quality of the generated manual pages. If you do not want to generate manual files, you can provide the `--no-manuals` option to disable manual file generation.



**Alternate Executable:**

Depending on the distribution, bat may have been renamed to avoid package conflicts.
If you wish to use these scripts on a distribution where this is the case, there is an `--alternate-executable=NAME` option which will build the scripts to use an alternate executable name.

You may also specify alternate executables for `ripgrep`, `delta`, `fzf`, or `git` with `--alternate-executable:PROGRAM NAME` where `PROGRAM` is one the aforementioned programs. Note that doing so may cause verification to fail.


**Verification:**

The build script will attempt to verify the correctness of the "bin" scripts by comparing their output with their source counterparts. It is recommended to let it do this, but you can disable verification with the `--no-verify` option.

&nbsp;

## Contributing

If you would like to contribute to `bat-extras`, please feel free to [open an issue on GitHub](https://github.com/eth-p/bat-extras/issues), or make a pull request. If you do the latter, please keep our [contributing guidelines](./CONTRIBUTING.md) in mind.  
