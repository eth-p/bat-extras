# bat-extras: batman

Read system manual pages (`man`) using `bat` as the manual page formatter.

Gone are the days of losing your place while reading through monotone manual pages. With `bat` and `batman`, you can read `man ifconfig` with beautiful 24-bit color and syntax higlighting.



## Usage

    batman [SECTION] [ENTRY]



## Environment

| Variable   | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| `MANPAGER` | Changes the pager used for `batman`. This is treated like `BAT_PAGER`, but only affects this command. |




## Installation

This script is a part of the `bat-extras` suite of scripts. You can find install instructions [here](../README.md#installation).



## Acknowledgements

Thanks to [@sharkdp](https://github.com/sharkdp) and [@LunarLambda](https://github.com/LunarLambda) for debugging how to make this work properly in [certain environments](https://github.com/sharkdp/bat/issues/652).



## Issues?

If you find an issue or have a feature suggestion, make a pull request or issue through GitHub!
Contributions are always welcome.
