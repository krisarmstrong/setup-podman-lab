_setup_podman_lab()
{
  local cur prev opts profiles commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  commands="light teardown rebuild rerun lan-enable lan-disable lan-status"
  profiles="all dev net sec monitor infra"
  opts="--components --build-only --run-only --profile --lan-mode --lan-interface --no-progress --progress --quiet --verbose --help"

  case "$prev" in
    --profile)
      # shellcheck disable=SC2207
      COMPREPLY=( $(compgen -W "$profiles" -- "$cur") )
      return 0
      ;;
    --components|--lan-interface)
      return 0
      ;;
    rebuild|rerun)
      # shellcheck disable=SC2207
      COMPREPLY=( $(compgen -W "$profiles" -- "$cur") )
      return 0
      ;;
    lan-enable|lan-disable)
      # shellcheck disable=SC2207
      COMPREPLY=( $(compgen -W "all $(podman ps --format '{{.Names}}' 2>/dev/null)" -- "$cur") )
      return 0
      ;;
  esac

  if [[ "$cur" == -* ]]; then
    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
  else
    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
  fi
  return 0
}
complete -F _setup_podman_lab setup-podman-lab.sh
