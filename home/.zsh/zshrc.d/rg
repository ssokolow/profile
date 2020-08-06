function rg() {
    declare -a OUTPUT
    local USE_PAGER

    # -- Implement `-G ...` as an alternative to `-g !...` --
    # Work around a footgun in zsh's handling of ! characters
    for ARG in "$@"; do
        if [[ "$ARG" = "-p" ]]; then
            USE_PAGER=1
        fi

        if [[ "$ARG" == "-G"* ]]; then
            OUTPUT+=( "-g" )
            if [[ "$ARG" == "-G" ]]; then
                take_next=1
            else
                OUTPUT+=( "!${ARG:2}" )
            fi
        elif [[ "$take_next" == 1 ]]; then
            OUTPUT+=( "!$ARG" )
            unset take_next
        else
            OUTPUT+=( "$ARG" )
        fi
    done

    if [[ "$USE_PAGER" == 1 ]]; then
        command rg "${OUTPUT[@]}" | less -RFX
    else
        command rg "${OUTPUT[@]}"
    fi
}
