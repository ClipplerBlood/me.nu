# Example of a me.nu configuration inspired by Telescope.nvim
# Requirements:
#   - ripgrep
#   - fzf
#   - bat
#   - vim / micro (* for micro edit fzf-code last two lines)

# Cd directories using fzf and fd
def-env fzf-dir [] {(
    (fd -d 4 -c always --type directory)
    | (fzf --preview "fd -d 1 -c always . {}" 
        --ansi --layout reverse --tiebreak length,chunk)
    | cd $in
)}


# Run ripgrep on the current folder, pipe it to fzf interactive
# and start the editor on the selected line
def fzf-code [
    query: string = "."        # Query
    --type(-t): string         # Filetype to search for
    --type-not(-T): string     # Filetype to exclude
    --max-depth(-d): int = 5   # Max depth
    --lines(-l): int = 20      # numer of lines to include in preview
] {
    # Check if we are in a danger dir (slow or useless grep)
    let pwd_len = $env.PWD | path split | length
    if ($env.PWD == ("~" | path expand) or $pwd_len < 4) {
        let v = (
            [no yes] 
            | input list "You are grepping in ~, are you sure you want to do that?"
        )
        if ($v != "yes") { return }
    }

    # Parse flags
    mut flags = []
    if not ($type | is-empty) {
        $flags ++= [-t $type]
    }
    if not ($type_not | is-empty) {
        $flags ++= [-T $type_not]
    }

    # Ripgrep
    ( rg ($flags) 
        --line-number --with-filename --color=always
        --field-match-separator ' ' --max-depth ($max_depth)
        ($query)
    )
    # Fzf + bat
    | ( fzf --ansi 
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
        --preview "bat --color always {1} --highlight-line {2}"
        --exact
    )
    # Parse fzf out
    | parse "{file} {line} {code}" | first 
    # Open editor
    | vim $"+($in.line)" $in.file
    # | micro -parsecursor true $"($in.file):($in.line)"
}

$env.nu_menu_commands = [
    {
        description: "Search Dir"
        keymap: "sd"
        command: { fzf-dir }
        group: "Search"
    }
    {
        description: "Search Code"
        keymap: "sc"
        command: { fzf-code }
        group: "Search"
    }
    {
        description: "Git Status"
        keymap: "gs"
        command: { git status }
        group: "Git"
    }
    {
        description: "Git Add Update"
        keymap: "gau"
        command: {git add --update}
        group: "Git"
    }
    {
        description: "Git Add All"
        keymap: "gaa"
        command: {git add --all}
        group: "Git"
    }
    {
        description: "Git Commit"
        keymap: "gc"
        command: {
            print (git status)
            input "Message: "
            | git commit -m $in
        }
        group: "Git"
    }
    {
        description: "Git Push"
        keymap: "gp"
        command: { git push }
        group: "Git"
    }
    {
        description: "Git pulL"
        keymap: "gl"
        command: { git pull }
        group: "Git"
    }
    {
        description: "Vim in Directory"
        keymap: "vd"
        command: { nvim . }
    }
    {
        description: "Refresh nu"
        keymap: "r"
        command: { nu }
    }
    {
        description: "Clear"
        keymap: "c"
        command: { clear }
    }
    {
        description: "Hello"
        keymap: "h"
        command: { print "Hello" }
    }
]
