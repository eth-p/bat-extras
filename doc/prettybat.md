# bat-extras: prettybat

Pretty-print source code and highlight it with `bat`.

The only thing better than syntax highlighting? Syntax highlighting *and* code formatting. This script combines the best of both worlds by using [various formatters](#Languages) to format source files before using `bat` to highlight them.



## Usage

    prettybat [OPTIONS] [PATH...]



## Options

Every option is passed through to `bat`.
See `man bat` for more information.



## Languages

| Language             | Formatter                                                   |
| -------------------- | ----------------------------------------------------------- |
| JavaScript (JS, JSX) | [prettier](https://prettier.io/)                            |
| TypeScript (TS, TSX) | [prettier](https://prettier.io/)                            |
| CSS, SCSS, SASS      | [prettier](https://prettier.io/)                            |
| Markdown             | [prettier](https://prettier.io/)                            |
| JSON                 | [prettier](https://prettier.io/)                            |
| YAML                 | [prettier](https://prettier.io/)                            |
| HTML                 | [prettier](https://prettier.io/)                            |
| Rust                 | [rustfmt](https://github.com/rust-lang/rustfmt)             |
| Bash                 | [shfmt](https://github.com/mvdan/sh)                        |
| C                    | [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html) |
| C++                  | [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html) |
| Objective-C          | [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html) |





## Caveats

- The header displayed by bat will show `STDIN` instead of the filename (`bat 0.13` or older).
- The git changes sidebar will not work with files that have been formatted.


## Installation

This script is a part of the `bat-extras` suite of scripts. You can find install instructions [here](../README.md#installation).



## Issues?

If you find an issue or have a feature suggestion, make a pull request or issue through GitHub!
Contributions are always welcome.
