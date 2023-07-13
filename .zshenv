
printf -v __CF_USER_TEXT_ENCODING '%#x:0.0' "$(id -u)"
export __CF_USER_TEXT_ENCODING

SHELL_SESSIONS_DISABLE=1
export LESS=FRSX
export LESSHISTFILE=-
export PYTHONSTARTUP=~/.pythonrc
export GRADLE_OPTS='-Dorg.gradle.daemon=false -Dgradle.cache.remote.enabled=false'
export ANDROID_{HOME,SDK_ROOT}="$HOME/Library/Android/sdk"
