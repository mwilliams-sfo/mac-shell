
typeset -U PATH
eval `/usr/libexec/path_helper -s`
PATH="$(
	delim=
	for alt in ; do
		printf %s%s "$delim" "$HOME/.local/alternatives/$alt"
		delim=:
	done
	printf %s%s "$delim" "$PATH"
)"
PATH+=":$HOME/.brew/bin"
if [ -v ANDROID_HOME ]; then
	PATH+=":$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"
fi
PATH+=":$HOME/.local/bin"

typeset -U MANPATH
MANPATH+=":/Library/Developer/CommandLineTools/usr/share/man"

eval "$(ssh-agent -s)" >/dev/null 
