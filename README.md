# bat-extras

Bash scripts that integrate [bat](https://github.com/sharkdp/bat) with various command line tools.

&nbsp;

## Scripts

- [`batgrep`](doc/batgrep.md) (ripgrep + bat)

&nbsp;

## Installation

The scripts in this repository are designed to run as-is, provided that they aren't moved around.
This means that you're free to just symlink `src/[script].sh` to your local bin folder.

If you would rather have self-contained scripts that you can place and run anywhere, you can use the `build.sh` script to create (and optionally install) them.

&nbsp;

**Building:**

```bash
./build.sh [OPTIONS...]
```

This will combine and preprocess each script under the `src` directory, and create corresponding self-contained scripts in the `bin` folder. Any library scripts that are sourced using `source "${LIB}/[NAME].sh"` will be embedded automatically.

&nbsp;

**Minification:**

There are three different options for minification:

| Option          | Description                                          |
| --------------- | ---------------------------------------------------- |
| `--minify=none` | Nothing will be minified.                            |
| `--minify=lib`  | Embedded library scripts will be minified. [default] |
| `--minify=all`  | Everything will be minified.                         |

This uses [bash_minifier](https://github.com/precious/bash_minifier) to perform minification, and requires Python 2 to be installed as either `python2` or `python`.

&nbsp;

**Installation:**

You can also specify `--install` and `--prefix=PATH` to have the build script automatically install the scripts for all users on the system. You may need to run the build script as root. 