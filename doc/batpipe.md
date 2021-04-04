# bat-extras: batpipe

A `less` (and `bat`) preprocessor for viewing more types of files in the terminal.



## Usage
Like [lesspipe](https://github.com/wofr06/lesspipe), `batpipe` is designed to work with programs that support preprocessing with the `LESSOPEN` environment variable. Setting up `batpipe` will depend on your shell:

**Bash:**

    eval "$(batpipe)"

**Fish:**

    eval (batpipe)



## Built-in Viewers

| Files                | Program                     |
| -------------------- | --------------------------- |
| Directories          | `exa`, `ls`                 |
| `*.tar`, `*.tar.gz`  | `tar`                       |
| `*.zip`, `*.jar`     | `unzip`                     |
| `*.gz`               | `gunzip`                    |
| `*.xz`               | `xz`                        |


## External Viewers

For file formats that aren't supported by default, an external file viewer can be added to `batpipe` through the external viewer API.

External viewers are be added to batpipe by creating bash scripts inside the `~/.config/batpipe/viewers.d/` directory.

### Creating Viewers

Viewers must define two functions and append the viewer's name to the `$BATPIPE_VIEWERS` array.

 - `viewer_${viewer}_supports [file_basename] [file_path] [inner_file_path]`
 - `viewer_${viewer}_process [file_path] [inner_file_path]`

The `viewer_${viewer}_supports` function is called to determine if the external viewer is capable of viewing the provided file. If this function returns successfully, the corresponding `process` function will be called.  

### API

    $BATPIPE_VIEWERS      -- An array of loaded file viewers.
    $BATPIPE_ENABLE_COLOR -- Whether color is supported. (`true`|`false`)
    $BATPIPE_INSIDE_LESS  -- Whether batpipe is inside less. (`true`|`false`)
    
    batpipe_header [pattern] [...]    -- Print a viewer header line.
    batpipe_subheader [pattern] [...] -- Print a viewer subheader line.

    strip_trailing_slashes [path]     -- Strips trailing slashes from a path.




## Caveats

- By default, `batpipe` will not use colors when previewed inside `less`.
  Colors must be explicitly enabled with `BATPIPE=color`.


## Installation

This script is a part of the `bat-extras` suite of scripts. You can find install instructions [here](../README.md#installation).



## Issues?

If you find an issue or have a feature suggestion, make a pull request or issue through GitHub!
Contributions are always welcome.
