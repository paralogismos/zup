#! /usr/bin/env sh
# zup.sh
# A simple script for updating Zig toolchains.
# Toolchains should be manually extracted into the ~/.zup directory.
# Zup will update the soft link to the Zig compiler in ~/bin, or create one
# if none exists.
set -e

zup_version=0.2.0
zup_dir=$HOME/.zup
bin_dir=$HOME/bin
cur_ver=$(zig version)

if ! [ -d "$zup_dir" ] ; then mkdir "$zup_dir" ; fi
reset_dir="$PWD"
cd "$zup_dir"

match_version='[[:digit:]]+.[[:digit:]]+.[[:digit:]]+'

usage() {
    printf "zup version %s\n" $zup_version
    printf "\n"
    printf "Usage:\n"
    printf "zup [command]\n"
    printf "\n"
    printf "Commands:\n"
    printf "<version> ... Set active Zig toolchain\n"
    printf "list      ... Show available Zig toolchains\n"
    printf "help      ... Show this help screen\n"
    printf "\n"
}

script_fail() {
    printf "*** %s : %s ***\n" "$1" "$2" >&2
    usage
    cd "$reset_dir"
    exit 2
}

check_version_num() {
    if ! $(echo "$1" | grep -E ^$match_version > /dev/null) ;
    then
        script_fail "Not a version number" "$1"
    elif ! $(echo "$zig_available_tc" | grep "$1" > /dev/null) ;
    then
        script_fail "Toolchain version not available" "$1"
    fi
}

# Find available toolchains.
zig_available_tc=$(find "$zup_dir" -maxdepth 1 -type d | grep "zig")
if [ -z "$zig_available_tc" ] ;
then
    script_fail "No Zig toolchains available" ""
fi
zig_available=$(echo "$zig_available_tc" |
                    grep -Eo $match_version.* |
                    sort -t. -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr)

# Parse script commands.
command=
modifier=

if ! [ -z ${1%%-*} ] ; then
    command="$1"
    shift
fi
if ! [ -z ${1%%-*} ] ; then
    modifier="$1"
    shift
fi

# Handle commands.
case "$command" in
    help | "" )
        usage
        ;;
    list )
        printf "available Zig toolchains:\n"
        for tc in $zig_available ; do
            if [ "$tc" = "$cur_ver" ] ; then printf "> %s <\n" "$tc"
            else printf "  %s\n" "$tc"
            fi
        done
        ;;
    * )
        check_version_num $command
        select_tc=$(echo "$zig_available_tc" | grep "$command")
        if [ -f "$bin_dir/zig" ] ; then rm "$bin_dir/zig" ; fi
        ln -s "$select_tc/zig" "$bin_dir/zig"
        ;;
esac

cd "$reset_dir"
