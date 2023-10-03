
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
        print (
'# Example config. Place it in your `config.nu`
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
    | nu-highlight)
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

    # Define a boring function to print the menu
    def table_info [cmd = "", --dry: bool = false] {
        # Prepare the table output + customization
        $env.config.table.mode = 'rounded'
        $env.config.table.index_mode = 'never'
        $env.config.table.header_on_separator = true
        $env.config.table.padding = { left: 1, right: 1 }
        const col_w = 25
        let is_leading_spc = $cmd | str starts-with " "
        let prompt_left = if $is_leading_spc  {$"(ansi y)"} else {$"(ansi c)❯"}
        let key_color = if $is_leading_spc {(ansi yr)} else {(ansi cr)}
        let desc_color = if $is_leading_spc {(ansi yu)} else {(ansi cu)}

        # Build the menu
        let menu = $commands 
        | where ($it.keymap | str starts-with ($cmd | str trim))
        | group-by {$in.group? | default "Other"}
        | items {|group, commands| 
            # For each command group, build the submenu
            # which a string where each row contains multiple commands
            let submenu = $commands 
            | each {|c|
                # Each command is printed as <boxed keymap> <description with capital highlights>
                let k = $"($key_color)($c.keymap | fill -w ($max_len + 2) -a center -c ' ')(ansi reset) "
                let d = $c.description 
                | str replace -ra '([A-Z])' $'($desc_color)${1}(ansi reset)'
                | str trim
                
                [$k $d] | str join ' '
            }
            | group 2
            | each {|row|
                let row = if ($row | length) < 2 {$row | append ''} else {$row}
                $row | each {$in | fill -w ($col_w) -a left -c ' '} | str join ''
            }
            | str join "\n"

            {$group: $submenu}
        }
        | into record | flatten | into record
        | table -c
        
        let command_line = $"($prompt_left)(ansi reset) ($cmd | str replace ' ' '_' )"

        # Build the menu and the "command line"
        # CSIu resets the line to the saved pos; CSI0J clears from the cursor to end
        return $"(ansi csi)u(ansi csi)0J($menu)\n(ansi cursor_blink_on)($command_line)"
    }


    # Do a "pre-print". This gives some space in the console to print.
    # Needed if the console cursor is at the bottom of the terminal
    # <CSI>nA goes up n lines, <CSI>s saves the current line
    let pre_print = table_info ""
    let n_cmds = ($pre_print | lines | length) + 4
    print -n $"((1..$n_cmds) | each {"\n"} | str join '')(ansi csi)($n_cmds)A(ansi csi)s"

    # Start listening for user input
    mut cmd = ''
    print -n $"(ansi csi)s"  # Save cursor
    while (($cmd == '') or (not (($cmd | str trim) in $keys))) {
        # Print menu and wait input
        print -n (table_info $cmd)        
        let i = (input listen -t [key]).code


        # If Esc or Enter, clear and quit
        if ($i in ["esc" "enter"]) {
            print -n $"(ansi csi)u(ansi csi)0J"
            return 
        }

        # Ignore trailing spaces (a single leading space is allowed)
        if ($i == " ") and ($cmd | str length ) > 0 { 
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

    if ($cmd | str starts-with " ") {
        view source $command
        | str substring 1..-2 
        | str trim
        | commandline $in
    } else {
        do --env $command
    }
}