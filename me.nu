
# Keybinding config
$env.config.keybindings ++= [{
    name: start_something
    modifier: CONTROL
    keycode: Space
    mode: emacs
    event: {
        send: executehostcommand
        cmd: "show_quick_menu"
    }
}]

const example_config = '
# Example config. Place it in your `config.nu`
$env.nu_menu_commands = {
    {
        description: "Refresh nu"
        keymap: "r"
        command: { nu }
    }
    {
        description: "Git Status"
        keymap: "gs"
        command: { git status }
        group: "Git"
    }
}
'

# Display me.nu
#
# Usage:
# - Invoke it with the keymap (default: Ctrl+Space)
# - Input your keymap, sequentially to invoke a command
# - If no match is found, the selection is reset
# - If the match starts with a Space, the command is not executed 
#   but sent to the command line for further editing
def-env show_quick_menu [] {
    # Sanity check + error message
    if not ("nu_menu_commands" in $env) {
        print $"\n(ansi red)Error: env.nu_menu_commands is not set!(ansi reset)\n"
        print ($example_config | nu-highlight)
        return
    }

    # Grab the keymap keys and the maximum length of a keymap
    let commands = $env.nu_menu_commands
    let keys = $commands | get keymap
    let max_len = $keys | str length | math max

    # Check unique keys
    if ($keys | length) > ($keys | uniq | length) {
        let non_unique_cmds = $commands 
        | group-by keymap | items {|keymap, commands| 
            if ($commands | length) > 1 {$commands}
        } | where (not ($it | is-empty))

        error make -u {msg: $"Some keymaps in your me.nu config are not unique!
            \n($non_unique_cmds | table -c)", }
    }

    # Render a command block
    def "render command" [
        command: record     # Command to render
        key_color: string   # Highlight color for the keymap
        desc_color: string  # Highlight color for description's Capital letters
    ] -> string {
        let keymap_box = $command.keymap 
        | fill -w ($max_len + 2) -a center -c ' '

        let description = $command.description 
        | str replace -ra '([A-Z])' $'($desc_color)${1}(ansi reset)'
        | str trim
        
        $"($key_color)($keymap_box)(ansi reset) ($description)"
    }

    # Render a group of commands in a "grid"
    def "render group" [
        commands: list<record>  # Command to render
        key_color: string       # Highlight color for the keymap
        desc_color: string      # Highlight color for description's Capital letters
        col_w: int = 25         # Commands' fill width
        n_cols: int = 2         # Number of columns per row
    ] -> string {
        $commands 
        | each { render command $in $key_color $desc_color }
        | group $n_cols
        | each {|row|
            mut row = $row
            while ($row | length) < $n_cols {
                $row ++= ''
            }

            $row
            | each {$in | fill -w ($col_w) -a left -c ' '} 
            | str join ''
        }
        | str join "\n"
    }

    # Render the full commands table with highlighting
    def "render full" [
        cmd:string = "",            # Command to filter
        edit_mode: bool = false     # Edit mode toggle
    ] {
        # Prepare the table output + customization
        $env.config.table.mode = 'rounded'
        $env.config.table.index_mode = 'never'
        $env.config.table.header_on_separator = true
        $env.config.table.padding = { left: 1, right: 1 }
        let prompt_left = if $edit_mode {$"(ansi y)"} else {$"(ansi c)❯"}
        let key_color = if $edit_mode {(ansi yr)} else {(ansi cr)}
        let desc_color = if $edit_mode {(ansi yu)} else {(ansi cu)}

        # Build the menu
        let cmd = ($cmd | str trim)
        let menu = $commands 
        | where ($it.keymap | str starts-with $cmd)
        | group-by {$in.group? | default "Other"}
        | items {|group, commands|
            {$group: (render group $commands $key_color $desc_color)}
        }
        | into record | flatten | into record
        | table -c
        
        let command_line = $"($prompt_left)(ansi reset) ($cmd)"

        # Build the menu and the "command line"
        # CSIu resets the line to the saved pos; CSI0J clears from the cursor to end
        return $"(ansi csi)u(ansi csi)0J($menu)\n(ansi cursor_blink_on)($command_line)"
    }


    # Do a "pre-print". This gives some space in the console to print.
    # Needed if the console cursor is at the bottom of the terminal
    # <CSI>nA goes up n lines, <CSI>s saves the current line
    let pre_print = render full ""
    let n_cmds = ($pre_print | lines | length) + 4
    print -n $"((1..$n_cmds) | each {"\n"} | str join '')(ansi csi)($n_cmds)A(ansi csi)s"

    # Start listening for user input
    mut cmd = ''
    mut edit_mode = false
    print -n $"(ansi csi)s"  # Save cursor
    while (($cmd == '') or (not (($cmd | str trim) in $keys))) {
        # Print menu and wait input
        print -n (render full $cmd $edit_mode)         
        let i = (input listen -t [key]).code


        # If Esc or Enter, clear and quit
        if ($i in ["esc" "enter"]) {
            print -n $"(ansi csi)u(ansi csi)0J"
            return 
        }

        # Space toggles edit mode
        if ($i == " ") { 
            $edit_mode = (not $edit_mode )
            continue
        }

        # Backspace => remove last char
        if ($i == "backspace") {
            $cmd = ($cmd | str substring 0..-2)
            continue
        }

        # Add the command
        $cmd += $i

        # If no command is matched with the input, reset the input
        if ($keys | where ($it | str starts-with ($cmd | str trim)) | is-empty) {
            $cmd = ''
            continue
        }

    }

    # Clear
    print -n $"(ansi csi)u(ansi csi)0J"

    # Execute the command closure,
    # or set the command line if starts with space
    let command = $commands 
    | where keymap == ($cmd | str trim) 
    | first 
    | get command

    if $edit_mode {
        view source $command
        | str trim 
        | str replace -rma '^{|}$' ''
        | str trim
        | commandline $in
    } else {
        do --env $command
    }
}