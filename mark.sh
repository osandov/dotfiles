MARKDIR="$HOME/.marks"

mkdir -p "$MARKDIR"

mark () {
    if [ $# -eq 1 ]; then
        ln -s "$(pwd)" "$MARKDIR/$1"
    else
        echo "Usage: mark MARK" >&2
        return 1
    fi
}

jump () {
    if [ $# -eq 1 ]; then
        cd "$MARKDIR/$1"
    else
        echo "Usage: jump MARK" >&2
        return 1
    fi
}

unmark () {
    if [ $# -eq 1 ]; then
        rm -i "$MARKDIR/$1"
    else
        echo "Usage: unmark MARK" >&2
        return 1
    fi
}

marks () {
    if [ $# -eq 0 ]; then
        ls "$MARKDIR" | while read -r MARK; do
            printf "%s -> %s\n" "$MARK" "$(readlink "$MARKDIR/$MARK")"
        done
    else
        echo "Usage: marks" >&2
        return 1
    fi
}
