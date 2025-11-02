function __fish_setup_podman_lab_using_command
    set cmd (commandline -opc)
    if test (count $cmd) -gt 1
        if test $cmd[2] = rebuild -o $cmd[2] = rerun
            return 0
        end
    end
    return 1
end

function __fish_setup_podman_lab_needs_command
    set cmd (commandline -opc)
    if test (count $cmd) -le 1
        return 0
    end
    return 1
end

set -l profiles all dev net sec monitor infra
set -l options --components --build-only --run-only --profile --lan-mode --lan-interface --no-progress --progress --quiet --verbose --help

complete -c setup-podman-lab.sh -n '__fish_setup_podman_lab_needs_command' -f -a 'light teardown rebuild rerun lan-enable lan-disable lan-status'
complete -c setup-podman-lab.sh -s h -l help -d 'Show help'
complete -c setup-podman-lab.sh -l profile -a "$profiles" -d 'Select component profile'
complete -c setup-podman-lab.sh -l components -d 'Comma-separated component list'
complete -c setup-podman-lab.sh -l build-only -d 'Build images only'
complete -c setup-podman-lab.sh -l run-only -d 'Run containers only'
complete -c setup-podman-lab.sh -l lan-mode -d 'Enable LAN networking'
complete -c setup-podman-lab.sh -l lan-interface -d 'Physical network interface for LAN'
complete -c setup-podman-lab.sh -l no-progress -d 'Disable progress bar'
complete -c setup-podman-lab.sh -l progress -d 'Enable progress bar'
complete -c setup-podman-lab.sh -l quiet -d 'Suppress info logs'
complete -c setup-podman-lab.sh -l verbose -d 'Verbose logging'

complete -c setup-podman-lab.sh -n '__fish_setup_podman_lab_using_command' -a "$profiles"
