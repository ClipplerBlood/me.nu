# Me.nu
A quick launch menu for Nushell.
<p align="center">
  <img src=".github/assets/example_1.gif" width=720 />
</p>

## 💡 Prerequisites
Just [Nushell](https://github.com/nushell/nushell)

> **Warning**  
> This requires nushell ^0.86.0
> 
> Using it with previous version is possible but requires editing the very last line of `me.nu`
> Simply remove the `--env` flag in after the `do` command.  
> The only downside is that commands that modify the env, such as those that navigate the filesystem like `cd`, won't work.

## ⬇️ Installation

1. Download the `me.nu` script in a folder, such as `~/.config/me.nu`
2. In your config in `$nu.config-path` source the script by adding 
```bash
source '~/.config/me.nu`  # Or another path
```
3. Define your commands. You can follow the example [here](https://github.com/ClipplerBlood/me.nu/blob/main/menu_config.nu) for some inspiration.

## 🔧 Defining commands
The menu searches for the variable `$env.nu_menu_commands`, which should be defined as a `List<Record>` with the following structure:
```bash
$env.nu_menu_commands = [
  {
    description: "Hello World"  # Description to be displayed. Capital letters will be underlined
    keymap: "hw"  # Keys to invoke the command
    command: { print "Hello World" }  # **Closure** that will be invoked
    group: "Examples"  # [Optional] group of the command
  }
]
```


> **Note**  
> Commands must have unique keymaps!

### Example config
Check out [menu_config.nu](https://github.com/ClipplerBlood/me.nu/blob/main/menu_config.nu) for some Telescope.nvim inspired commands!

## 🚀 Usage
By default the menu launches with `Ctrl + Space`.

### Executing commands
After launching the command you can enter your sequence of characters to execute the command.
In our example, we can press `h` followed by `h` to print "Hello World".

### Sharing roots
In case of commands with the same prefix, for example a command `hn` that prints "Hello Nu", when pressing the first `h` key 
the table output would display the commands that have the `h` root.


### Edit mode
By pressing `<Space>` the menu will toggle the **Edit Mode**. In this mode, after typing the key sequence, the command will be inserted in your command line instead of being executed directly.

For example by pressing `<space>hh` the command line will be set to `> print "Hello World"`. This can be useful for passing flags to your own commands when required.


### Other keys
- Enter and Esc will close the menu
- Backspace will delete the last character
- Uppercase characters are allowed


## ❤️ Contributing
Feel free to contribute! PRs are welcome!

## 🚚 Roadmap
- [ ] Install script
- [ ] Nupm compatibility




