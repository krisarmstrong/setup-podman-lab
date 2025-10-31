_setup_podman_lab()
{
  local cur prev opts profiles commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  commands="light teardown rebuild rerun"
  profiles="all dev net sec monitor"
  opts="--components --build-only --run-only --profile --no-progress --progress --quiet --verbose --help"

  case "$prev" in
    --profile)
      COMPREPLY=( $(compgen -W "$profiles" -- "$cur") )
      return 0
      ;;
    --components)
      return 0
      ;;
    rebuild|rerun)
      COMPREPLY=( $(compgen -W "$profiles" -- "$cur") )
      return 0
      ;;
  esac

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
  else
    COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
  fi
  return 0
}
complete -F _setup_podman_lab setup-podman-lab.sh
