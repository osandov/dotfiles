# Add a directory to the PATH or move it to the front if it's already there
add_to_path () {
    export PATH="$(echo "$PATH" | sed -e "s!^$1:!!g" -e "s!:$1:!:!g" -e "s!^!$1:!")"
}

if [ -d "$HOME/.dotfiles/bin" ]; then
    add_to_path "$HOME/.dotfiles/bin"
fi

if [ -d "$HOME/bin" ]; then
    add_to_path "$HOME/bin"
fi

if [ -d "$HOME/.cabal/bin" ]; then
    add_to_path "$HOME/.cabal/bin"
fi

if [ -r "$HOME/.zshenv.local" ]; then
    source "$HOME/.zshenv.local" 
fi
