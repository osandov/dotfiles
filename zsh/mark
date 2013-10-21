MARKDIR="$HOME/.marks"

mkdir -p "$MARKDIR"

mark () {
    TARGET="$(pwd)"
    if [ $# -eq 2 ]; then
        pushd "$1" > /dev/null
        TARGET="$(pwd)"
        popd > /dev/null
        shift
    fi

    if [ $# -eq 1 ]; then
        ln -s "$TARGET" "$MARKDIR/$1"
    else
        echo "Usage: mark [TARGET] MARK" >&2
        return 1
    fi
}

jump () {
    if [ $# -eq 1 ]; then
        cd "$(readlink -v "$MARKDIR/$1")"
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

readmark () {
    if [ $# -eq 1 ]; then
        TARGET="$(readlink -v "$MARKDIR/$1")"
        if [ $? -eq 0 ]; then
            echo "$TARGET"
        fi
    else
        echo "Usage: readmark MARK" >&2
        return 1
    fi
}
