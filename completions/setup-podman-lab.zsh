#compdef setup-podman-lab.sh

local -a _profiles _commands _options
_profiles=(all dev net sec monitor)
_commands=(light teardown rebuild rerun)
_options=(
  '--components'
  '--build-only'
  '--run-only'
  '--profile'
  '--no-progress'
  '--progress'
  '--quiet'
  '--verbose'
  '--help'
)

_setup_podman_lab() {
  local state
  cur=${words[CURRENT]}
  prev=${words[CURRENT-1]}

  case $prev in
    --profile)
      _describe 'profiles' _profiles
      return
      ;;
    --components)
      return
      ;;
    rebuild|rerun)
      _describe 'targets' _profiles
      return
      ;;
  esac

  if [[ $cur == -* ]]; then
    _describe 'options' _options
  else
    _describe 'commands' _commands
  fi
}

_setup_podman_lab "$@"
