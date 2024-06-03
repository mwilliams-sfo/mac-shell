
unset HISTFILE
setopt IGNORE_EOF

lambda0() {
	local str
	while read -rd $'\0' str || [ -n "$str" ]; do
		sh -c "$1" -- "$str"
		str=
	done
}

is_empty_dir() {
	local list
	[ -d "$1" ] && list="$(ls -A -- "$1")" && [ -z "$list" ]
}

sort_revs() {
	# Prefer close names over distant
	git-rev-distance | sort -gsk 1 | cut -d ' ' -f 2-
}

git_rev_name() {
	local rev="$1"
	# Prefer heads over tags over remotes.
	{
		timeout 1 git name-rev --name-only --no-undefined --refs="refs/heads/*" -- "$rev"
		timeout 1 git name-rev --name-only --no-undefined --refs="refs/tags/*" -- "$rev"
		timeout 1 git name-rev --name-only --no-undefined -- "$rev"
	} 2>/dev/null | sort_revs | sed -e 's/\^0$//' | head -n 1
}

git_action() {
	local git_dir
	git_dir="$(git rev-parse --git-dir)" || return
	if [ -f "$git_dir/MERGE_HEAD" ]; then
		echo merge
	elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
		echo cherry-pick
	elif [ -f "$git_dir/REVERT_HEAD" ]; then
		echo revert
	elif [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
		echo rebase
	elif [ -f "$git_dir/BISECT_START" ]; then
		echo bisect
	else
		false
	fi
}

dquote() {
	local c
	for c in \\ \" \` \$; do
		set -- "${@//"$c"/\\"$c"}" 
	done
	[ $# = 0 ] || printf '"%s"' "$1"
	(( $# < 2 )) || printf ' "%s"' "${@[2,-1]}"
	echo
}

pquote()
	dquote "${@//\%/%%}"

prompt_status() {
	(( $1 <= 128 )) || set -- "$1 ${signals[$1 - 127]}"
	[ 0 = "$1" ] || printf 'exit=%s\n' "$1"
}

prompt_git_head() {
	local branch revision name name_color
	echo -n Head:

	if ! git rev-parse --verify -q HEAD > /dev/null; then
		printf none
		return
	fi

	branch="$(git branch --show-current)"
	revision="$(git rev-parse --short HEAD)"
	if [ -n "$branch" ]; then
		eval printf "'%%B%%F{green}%s%%f%%b (%%F{yellow}%s%%f)'" $(pquote "$branch" "$revision")
		return
	fi

	eval printf "'%%F{yellow}%s%%f'" $(pquote "$revision")
	name="$(git_rev_name HEAD)" && [ -z "$name" ] && return
	case "$name" in
	tags/*)
		name_color=yellow
		name="${name#tags/}"
		;;
	remotes/*)
		name_color=red
		name="${name#remotes/}"
		;;
	*)
		name_color=green
		name="${name#heads/}"
		;;
	esac
	eval printf "' (%%B%%F{%s}%s%%f%%b)'" $(pquote "$name_color" "$name")
}

prompt_git() {
	local root subdir branch action
	root="$(git rev-parse --show-toplevel)"
	subdir="${PWD#"$root"}"
	subdir="${subdir:-/}"
	if [[ "$root" == "$HOME"/code/* ]]; then
		root="${root#"$HOME"/code/}"
	else
		root="$(basename "$root")"
	fi
	eval printf "'%%F{blue}[%s]%%f%s\\n'" $(pquote "$root" "$subdir")

	prompt_git_head
	action="$(git_action)"
	[ -z "$action" ] || eval printf "' (%s)'" $(pquote "$action")
	echo
}

prompt() {
	local stat=$?
	if [ 1 != "$INTELLIJ_TERMINAL" ] && [ -n "$TERM" ]; then
		printf '%%{'
		tput init
		printf '%%}'
	fi
	prompt_status "$stat"
	echo
	if [ true = "$(git rev-parse --is-inside-work-tree 2> /dev/null)" ]; then
		prompt_git
	else
		echo '%~'
	fi
	eval printf "'%%B%%(!.%%Sroot%%s .)%s%%#%%b '" $(pquote "$ZSH_NAME")
}
set -o PROMPT_SUBST
PS1='$(prompt)'

forget() {
	local HISTSIZE=0
	if ! infocmp -1 2>/dev/null | grep -q '^	ed=\\E\[J,\{0,1\}$'; then
		echo Terminal capability unavailable >&2
		return 1
	fi
	printf '\e[3J'
}

xterm_title() {
	[ $# = 1 ] && printf '\e]2;%s\a' "$1"
}

cf() {
	clear
	forget
}

uuid() {
	command uuidgen | tr A-F a-f
}

squashvid() {
	[[ "$1" = *.mov ]] &&
	ffmpeg -i "$1" -vf 'fps=15,scale=250:-1' "${1%.mov}.webm"
}

alias pip3='python3 -m pip'
alias gw=./gradlew
