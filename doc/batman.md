# bat-extras: batman

Read system manual pages (`man`) using `bat` as the manual page formatter.

Gone are the days of losing your place while reading through monotone manual pages. With `bat` and `batman`, you can read `man ifconfig` with beautiful 24-bit color and syntax higlighting.

If you have `fzf` installed, you can even use `batman` to search through manual pages!


## Usage

    batman [SECTION] [ENTRY]

### As a Replacement for Man

With bash:

```bash
eval "$(batman --export-env)"
```

With fish:

```fish
batman --export-env | source
```

## Environment

| Variable   | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| `MANPAGER` | Changes the pager used for `batman`. This is treated like `BAT_PAGER`, but only affects this command. |



## Customization

### Changing the Theme

You can change the syntax highlighting theme for `batman` by setting the `BAT_THEME` environment variable before calling `batman`. The following wrapper function will change the theme to `Solarized (dark)` without affecting any other `bat` command.

```bash
batman() {
    BAT_THEME="Solarized (dark)" batman "$@"
    return $?
}
```




## Installation

This script is a part of the `bat-extras` suite of scripts. You can find install instructions [here](../README.md#installation).



## Caveats

**Flags aren't highlighted:**

- This happens when you change `bat`'s theme through `bat`'s config file or the `BAT_THEME` environment variable. Not all themes provide colours for flags, and [it's a known issue](https://github.com/sharkdp/bat/issues/2115).
- You can overriding the theme for `batman` by wrapping it in a function that sets `BAT_THEME`.
- The following themes support manpage highlighting:
  - `Monokai Extended` / ``Monokai Extended Light`
  - `Solarized (dark)` / `Solarized (light)`



## Acknowledgements

Thanks to [@sharkdp](https://github.com/sharkdp) and [@LunarLambda](https://github.com/LunarLambda) for debugging how to make this work properly in [certain environments](https://github.com/sharkdp/bat/issues/652).



## Issues?

If you find an issue or have a feature suggestion, make a pull request or issue through GitHub!
Contributions are always welcome.
