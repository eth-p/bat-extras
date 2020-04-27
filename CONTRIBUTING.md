# Contributing
Are you interested in contributing to `bat-extras`? That's great!  
All we ask is that you keep a few things in mind:


## DOs:

- Use Bashisms whenever possible (unless it would make the code unclear). These are scripts written specifically for the `bash` shell, and they should take advantage of built-in functionality instead of spawning external processes.
- Use `awk` or `sed` when it would be faster or less verbose than only using `bash` builtins.

## DON'Ts:

- Include crude or offensive language inside issues or scripts.
- Use GNU/BSD-only features in external programs like `sed` or `awk`.
- Use `bash` features that require a Bash version newer than 3.2. 
- Use `head` in a pipe. See [Issue #19](https://github.com/eth-p/bat-extras/issues/19) for more details.
- Use any external program that isn't likely to come installed by default (e.g. avoid `perl` and `python`).
- Automatically reformat scripts unless it's a pull request specifically intended for reformatting. The formatting style that we use differs from what `shfmt` and other shell script formatters will emit.
