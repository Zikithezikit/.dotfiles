if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
alias audio_server="as-cmd --bind=10.100.102.20 --encoding=f32 --channels=2 --sample-rate=48000"
alias netflix_remote="export XAUTHORITY='$HOME/.Xauthority' && gtk-launch Netflix"

# Created by `pipx` on 2025-10-30 08:00:02
set PATH $PATH /home/server-yoav/.local/bin

# npm global binaries
fish_add_path /home/server-yoav/.npm-global/bin

# opencode
fish_add_path /home/server-yoav/.opencode/bin

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/server-yoav/.lmstudio/bin
# End of LM Studio CLI section

# Language support
setxkbmap -layout us,il -option grp:win_space_toggle 2>/dev/null

## Wallpaper
# exec --no-startup-id feh --bg-scale ~/Pictures/Wallpapers/wallpaper-1.jpg

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

alias copy="xclip -selection clipboard"
alias venv="source .venv/bin/activate.fish"

function nvm
    bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end

# OpenClaw Completion
# source "/home/server-yoav/.openclaw/completions/openclaw.fish"

# API for claude code
set ANTHROPIC_BASE_URL "http://10.100.102.20:20128/v1"
set ANTHROPIC_AUTH_TOKEN "$OPENROUTER_API_KEY"
set ANTHROPIC_API_KEY ""

####

alias idf="source '/home/server-yoav/.espressif/tools/activate_idf_v6.1.fish' && set -x ESP_IDF_VERSION 6.1.0"

set -gx PATH ~/.espressif/tools/tools/qemu-xtensa/esp_develop_9.2.2_20260417/qemu/bin $PATH

# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_eim_global_optspecs
    string join \n l/locale= v/verbose log-file= do-not-track= esp-idf-json-path= h/help V/version
end

function __fish_eim_needs_command
    # Figure out if the current invocation already has a command.
    set -l cmd (commandline -opc)
    set -e cmd[1]
    argparse -s (__fish_eim_global_optspecs) -- $cmd 2>/dev/null
    or return
    if set -q argv[1]
        # Also print the command, so this can be used to figure out what it is.
        echo $argv[1]
        return 1
    end
    return 0
end

function __fish_eim_using_subcommand
    set -l cmd (__fish_eim_needs_command)
    test -z "$cmd"
    and return 1
    contains -- $cmd[1] $argv
end

complete -c eim -n __fish_eim_needs_command -s l -l locale -d 'Set the language for the wizard (en, cn)' -r
complete -c eim -n __fish_eim_needs_command -l log-file -d 'file in which logs will be stored (default: eim.log)' -r
complete -c eim -n __fish_eim_needs_command -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n __fish_eim_needs_command -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n __fish_eim_needs_command -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n __fish_eim_needs_command -s h -l help -d 'Print help (see more with \'--help\')'
complete -c eim -n __fish_eim_needs_command -s V -l version -d 'Print version'
complete -c eim -n __fish_eim_needs_command -f -a install -d 'Install ESP-IDF versions'
complete -c eim -n __fish_eim_needs_command -f -a list -d 'List installed ESP-IDF versions'
complete -c eim -n __fish_eim_needs_command -f -a list-tools -d 'List tools declared in an installed ESP-IDF\'s tools.json, with on-disk status'
complete -c eim -n __fish_eim_needs_command -f -a list-features -d 'List features declared in an installed ESP-IDF\'s requirements.json, with install status'
complete -c eim -n __fish_eim_needs_command -f -a select -d 'Select an ESP-IDF version as active'
complete -c eim -n __fish_eim_needs_command -f -a discover -d 'Discover available ESP-IDF versions (not implemented yet)'
complete -c eim -n __fish_eim_needs_command -f -a remove -d 'Remove specific ESP-IDF version'
complete -c eim -n __fish_eim_needs_command -f -a rename -d 'Rename specific ESP-IDF version'
complete -c eim -n __fish_eim_needs_command -f -a run -d 'Run command in the context of a specific ESP-IDF version'
complete -c eim -n __fish_eim_needs_command -f -a import -d 'Import existing ESP-IDF installation using tools_set_config.json'
complete -c eim -n __fish_eim_needs_command -f -a purge -d 'Purge all ESP-IDF installations'
complete -c eim -n __fish_eim_needs_command -f -a wizard -d 'Run the ESP-IDF Installer Wizard'
complete -c eim -n __fish_eim_needs_command -f -a gui -d 'Run the ESP-IDF Installer GUI with arguments passed through command line'
complete -c eim -n __fish_eim_needs_command -f -a fix -d 'Fix the ESP-IDF installation by reinstalling the tools and dependencies'
complete -c eim -n __fish_eim_needs_command -f -a install-drivers -d 'Install drivers for ESP-IDF. This is only available on Windows platforms'
complete -c eim -n __fish_eim_needs_command -f -a completions -d 'Generate shell completion script to stdout'
complete -c eim -n __fish_eim_needs_command -f -a help-json -d 'Print help in JSON format for machine reading'
complete -c eim -n __fish_eim_needs_command -f -a help -d 'Print this message or the help of the given subcommand(s)'
complete -c eim -n "__fish_eim_using_subcommand install" -s p -l path -d 'Base Path to which all the files and folder will be installed. For the `fix` command, this is the path of the existing installation to fix.' -r
complete -c eim -n "__fish_eim_using_subcommand install" -s c -l config -r -F
complete -c eim -n "__fish_eim_using_subcommand install" -s t -l target -d 'You can provide multiple targets separated by comma' -r
complete -c eim -n "__fish_eim_using_subcommand install" -s i -l idf-versions -d 'you can provide multiple versions of ESP-IDF separated by comma, you can also specify exact commit hash' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l tool-download-folder-name -r
complete -c eim -n "__fish_eim_using_subcommand install" -l tool-install-folder-name -r
complete -c eim -n "__fish_eim_using_subcommand install" -l tools-json-file -d 'Path to tools.json file relative from ESP-IDF installation folder' -r
complete -c eim -n "__fish_eim_using_subcommand install" -s n -l non-interactive -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand install" -s m -l mirror -d 'URL for tools download mirror to be used instead of github.com' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l idf-mirror -d 'URL for ESP-IDF download mirror to be used instead of github.com' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l pypi-mirror -d 'URL for PyPI mirror to be used instead of https://pypi.org/simple' -r
complete -c eim -n "__fish_eim_using_subcommand install" -s l -l locale -d 'Set the language for the wizard (en, cn)' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l log-file -d 'file in which logs will be stored (default: eim.log)' -r
complete -c eim -n "__fish_eim_using_subcommand install" -s r -l recurse-submodules -d 'Should the installer recurse into submodules of the ESP-IDF repository (default true) ' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand install" -s a -l install-all-prerequisites -d 'Should the installer attempt to install all missing prerequisites (default false). This flag only affects Windows platforms as we do not offer prerequisites for other platforms. ' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand install" -l config-file-save-path -d 'if set, the installer will as it\'s very last move save the configuration to the specified file path. This file can than be used to repeat the installation with the same settings.' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l idf-features -d 'Comma separated list of additional IDF features (ci, docs, pytests, etc.) to be installed with ESP-IDF.' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l idf-tools -d 'Comma separated list of tools to be installed with ESP-IDF.' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l repo-stub -d 'Repo stub to be used in case you want to use a custom repository. This is the \'espressif/esp-idf\' part of the repository URL.' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l skip-prerequisites-check -d 'Skip prerequisites check. This is useful if you are sure that all prerequisites are already installed and you want to skip the check. This is not recommended unless you know what you are doing, as it can result in a non-functional installation. Use at your own risk.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand install" -l version-name -d 'Version name to be used for the installation. If not provided, the version will be derived from the ESP-IDF repository tag or commit hash.' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l cleanup -d 'If set to true, the installer will remove temporary files after installation. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand install" -l skip-components-download -d 'If set to true, the installer will skipp component managers components download. Default is false on install true on fix.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand install" -l python-env-folder-name -d 'Folder name to be used for the python environments. If not provided, it will default to `python`.' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l use-local-archive -d 'Path to a local archive for offline installation. This is useful if you have already downloaded the ESP-IDF zst archive and want to use it for installation without downloading it again.' -r -F
complete -c eim -n "__fish_eim_using_subcommand install" -l activation-script-path-override -d 'Optional override for activation script path. This allows specifying a custom path for the activation script to be saved to instead of the default one.' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l python-version-override -d 'Optional override for Python version to install when installing prerequisites. This allows specifying a custom Python version instead of the default one. the accepted format is without dots like \'python313\' for Python 3.13' -r
complete -c eim -n "__fish_eim_using_subcommand install" -l create-bat-activation-script -d 'Whether to create a .bat activation script on Windows. This is useful for users who want to activate the ESP-IDF environment using a batch file instead of PowerShell. Default is false. This is for legacy compatibility reasons as the default activation method on Windows is now PowerShell script.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand install" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand install" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand install" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand install" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand list" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand list" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand list" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand list" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand list-tools" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand list-tools" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand list-tools" -l outdated -d 'Show only tools whose installed version is older than the latest available in tools.json'
complete -c eim -n "__fish_eim_using_subcommand list-tools" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand list-tools" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand list-features" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand list-features" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand list-features" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand list-features" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand select" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand select" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand select" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand select" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand discover" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand discover" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand discover" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand discover" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand remove" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand remove" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand remove" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand remove" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand rename" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand rename" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand rename" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand rename" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand run" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand run" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand run" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand run" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand import" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand import" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand import" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand import" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand purge" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand purge" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand purge" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand purge" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand wizard" -s p -l path -d 'Base Path to which all the files and folder will be installed. For the `fix` command, this is the path of the existing installation to fix.' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -s c -l config -r -F
complete -c eim -n "__fish_eim_using_subcommand wizard" -s t -l target -d 'You can provide multiple targets separated by comma' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -s i -l idf-versions -d 'you can provide multiple versions of ESP-IDF separated by comma, you can also specify exact commit hash' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l tool-download-folder-name -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l tool-install-folder-name -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l tools-json-file -d 'Path to tools.json file relative from ESP-IDF installation folder' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -s n -l non-interactive -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand wizard" -s m -l mirror -d 'URL for tools download mirror to be used instead of github.com' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l idf-mirror -d 'URL for ESP-IDF download mirror to be used instead of github.com' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l pypi-mirror -d 'URL for PyPI mirror to be used instead of https://pypi.org/simple' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -s l -l locale -d 'Set the language for the wizard (en, cn)' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l log-file -d 'file in which logs will be stored (default: eim.log)' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -s r -l recurse-submodules -d 'Should the installer recurse into submodules of the ESP-IDF repository (default true) ' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand wizard" -s a -l install-all-prerequisites -d 'Should the installer attempt to install all missing prerequisites (default false). This flag only affects Windows platforms as we do not offer prerequisites for other platforms. ' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand wizard" -l config-file-save-path -d 'if set, the installer will as it\'s very last move save the configuration to the specified file path. This file can than be used to repeat the installation with the same settings.' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l idf-features -d 'Comma separated list of additional IDF features (ci, docs, pytests, etc.) to be installed with ESP-IDF.' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l idf-tools -d 'Comma separated list of tools to be installed with ESP-IDF.' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l repo-stub -d 'Repo stub to be used in case you want to use a custom repository. This is the \'espressif/esp-idf\' part of the repository URL.' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l skip-prerequisites-check -d 'Skip prerequisites check. This is useful if you are sure that all prerequisites are already installed and you want to skip the check. This is not recommended unless you know what you are doing, as it can result in a non-functional installation. Use at your own risk.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand wizard" -l version-name -d 'Version name to be used for the installation. If not provided, the version will be derived from the ESP-IDF repository tag or commit hash.' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l cleanup -d 'If set to true, the installer will remove temporary files after installation. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand wizard" -l skip-components-download -d 'If set to true, the installer will skipp component managers components download. Default is false on install true on fix.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand wizard" -l python-env-folder-name -d 'Folder name to be used for the python environments. If not provided, it will default to `python`.' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l use-local-archive -d 'Path to a local archive for offline installation. This is useful if you have already downloaded the ESP-IDF zst archive and want to use it for installation without downloading it again.' -r -F
complete -c eim -n "__fish_eim_using_subcommand wizard" -l activation-script-path-override -d 'Optional override for activation script path. This allows specifying a custom path for the activation script to be saved to instead of the default one.' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l python-version-override -d 'Optional override for Python version to install when installing prerequisites. This allows specifying a custom Python version instead of the default one. the accepted format is without dots like \'python313\' for Python 3.13' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -l create-bat-activation-script -d 'Whether to create a .bat activation script on Windows. This is useful for users who want to activate the ESP-IDF environment using a batch file instead of PowerShell. Default is false. This is for legacy compatibility reasons as the default activation method on Windows is now PowerShell script.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand wizard" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand wizard" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand wizard" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand wizard" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand gui" -s p -l path -d 'Base Path to which all the files and folder will be installed. For the `fix` command, this is the path of the existing installation to fix.' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -s c -l config -r -F
complete -c eim -n "__fish_eim_using_subcommand gui" -s t -l target -d 'You can provide multiple targets separated by comma' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -s i -l idf-versions -d 'you can provide multiple versions of ESP-IDF separated by comma, you can also specify exact commit hash' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l tool-download-folder-name -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l tool-install-folder-name -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l tools-json-file -d 'Path to tools.json file relative from ESP-IDF installation folder' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -s n -l non-interactive -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand gui" -s m -l mirror -d 'URL for tools download mirror to be used instead of github.com' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l idf-mirror -d 'URL for ESP-IDF download mirror to be used instead of github.com' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l pypi-mirror -d 'URL for PyPI mirror to be used instead of https://pypi.org/simple' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -s l -l locale -d 'Set the language for the wizard (en, cn)' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l log-file -d 'file in which logs will be stored (default: eim.log)' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -s r -l recurse-submodules -d 'Should the installer recurse into submodules of the ESP-IDF repository (default true) ' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand gui" -s a -l install-all-prerequisites -d 'Should the installer attempt to install all missing prerequisites (default false). This flag only affects Windows platforms as we do not offer prerequisites for other platforms. ' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand gui" -l config-file-save-path -d 'if set, the installer will as it\'s very last move save the configuration to the specified file path. This file can than be used to repeat the installation with the same settings.' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l idf-features -d 'Comma separated list of additional IDF features (ci, docs, pytests, etc.) to be installed with ESP-IDF.' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l idf-tools -d 'Comma separated list of tools to be installed with ESP-IDF.' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l repo-stub -d 'Repo stub to be used in case you want to use a custom repository. This is the \'espressif/esp-idf\' part of the repository URL.' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l skip-prerequisites-check -d 'Skip prerequisites check. This is useful if you are sure that all prerequisites are already installed and you want to skip the check. This is not recommended unless you know what you are doing, as it can result in a non-functional installation. Use at your own risk.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand gui" -l version-name -d 'Version name to be used for the installation. If not provided, the version will be derived from the ESP-IDF repository tag or commit hash.' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l cleanup -d 'If set to true, the installer will remove temporary files after installation. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand gui" -l skip-components-download -d 'If set to true, the installer will skipp component managers components download. Default is false on install true on fix.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand gui" -l python-env-folder-name -d 'Folder name to be used for the python environments. If not provided, it will default to `python`.' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l use-local-archive -d 'Path to a local archive for offline installation. This is useful if you have already downloaded the ESP-IDF zst archive and want to use it for installation without downloading it again.' -r -F
complete -c eim -n "__fish_eim_using_subcommand gui" -l activation-script-path-override -d 'Optional override for activation script path. This allows specifying a custom path for the activation script to be saved to instead of the default one.' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l python-version-override -d 'Optional override for Python version to install when installing prerequisites. This allows specifying a custom Python version instead of the default one. the accepted format is without dots like \'python313\' for Python 3.13' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -l create-bat-activation-script -d 'Whether to create a .bat activation script on Windows. This is useful for users who want to activate the ESP-IDF environment using a batch file instead of PowerShell. Default is false. This is for legacy compatibility reasons as the default activation method on Windows is now PowerShell script.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand gui" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand gui" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand gui" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand gui" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand fix" -s p -l path -d 'Base Path to which all the files and folder will be installed. For the `fix` command, this is the path of the existing installation to fix.' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -s c -l config -r -F
complete -c eim -n "__fish_eim_using_subcommand fix" -s t -l target -d 'You can provide multiple targets separated by comma' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -s i -l idf-versions -d 'you can provide multiple versions of ESP-IDF separated by comma, you can also specify exact commit hash' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l tool-download-folder-name -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l tool-install-folder-name -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l tools-json-file -d 'Path to tools.json file relative from ESP-IDF installation folder' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -s n -l non-interactive -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand fix" -s m -l mirror -d 'URL for tools download mirror to be used instead of github.com' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l idf-mirror -d 'URL for ESP-IDF download mirror to be used instead of github.com' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l pypi-mirror -d 'URL for PyPI mirror to be used instead of https://pypi.org/simple' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -s l -l locale -d 'Set the language for the wizard (en, cn)' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l log-file -d 'file in which logs will be stored (default: eim.log)' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -s r -l recurse-submodules -d 'Should the installer recurse into submodules of the ESP-IDF repository (default true) ' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand fix" -s a -l install-all-prerequisites -d 'Should the installer attempt to install all missing prerequisites (default false). This flag only affects Windows platforms as we do not offer prerequisites for other platforms. ' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand fix" -l config-file-save-path -d 'if set, the installer will as it\'s very last move save the configuration to the specified file path. This file can than be used to repeat the installation with the same settings.' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l idf-features -d 'Comma separated list of additional IDF features (ci, docs, pytests, etc.) to be installed with ESP-IDF.' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l idf-tools -d 'Comma separated list of tools to be installed with ESP-IDF.' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l repo-stub -d 'Repo stub to be used in case you want to use a custom repository. This is the \'espressif/esp-idf\' part of the repository URL.' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l skip-prerequisites-check -d 'Skip prerequisites check. This is useful if you are sure that all prerequisites are already installed and you want to skip the check. This is not recommended unless you know what you are doing, as it can result in a non-functional installation. Use at your own risk.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand fix" -l version-name -d 'Version name to be used for the installation. If not provided, the version will be derived from the ESP-IDF repository tag or commit hash.' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l cleanup -d 'If set to true, the installer will remove temporary files after installation. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand fix" -l skip-components-download -d 'If set to true, the installer will skipp component managers components download. Default is false on install true on fix.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand fix" -l python-env-folder-name -d 'Folder name to be used for the python environments. If not provided, it will default to `python`.' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l use-local-archive -d 'Path to a local archive for offline installation. This is useful if you have already downloaded the ESP-IDF zst archive and want to use it for installation without downloading it again.' -r -F
complete -c eim -n "__fish_eim_using_subcommand fix" -l activation-script-path-override -d 'Optional override for activation script path. This allows specifying a custom path for the activation script to be saved to instead of the default one.' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l python-version-override -d 'Optional override for Python version to install when installing prerequisites. This allows specifying a custom Python version instead of the default one. the accepted format is without dots like \'python313\' for Python 3.13' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -l create-bat-activation-script -d 'Whether to create a .bat activation script on Windows. This is useful for users who want to activate the ESP-IDF environment using a batch file instead of PowerShell. Default is false. This is for legacy compatibility reasons as the default activation method on Windows is now PowerShell script.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand fix" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand fix" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand fix" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand fix" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand install-drivers" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand install-drivers" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand install-drivers" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand install-drivers" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand completions" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand completions" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand completions" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand completions" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand help-json" -l do-not-track -d 'If set to true, the installer will not send any usage data. Default is false.' -r -f -a "true\t''
false\t''"
complete -c eim -n "__fish_eim_using_subcommand help-json" -l esp-idf-json-path -d 'Path to directory for eim_idf.json. During install, the configuration file is saved here. For version management commands (list, select, rename, remove, etc.), it specifies where to read the file. Defaults to ~/.espressif/tools on POSIX, C:\\Espressif\\tools on Windows.' -r
complete -c eim -n "__fish_eim_using_subcommand help-json" -s v -l verbose -d 'Increase verbosity level (can be used multiple times)'
complete -c eim -n "__fish_eim_using_subcommand help-json" -s h -l help -d 'Print help'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a install -d 'Install ESP-IDF versions'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a list -d 'List installed ESP-IDF versions'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a list-tools -d 'List tools declared in an installed ESP-IDF\'s tools.json, with on-disk status'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a list-features -d 'List features declared in an installed ESP-IDF\'s requirements.json, with install status'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a select -d 'Select an ESP-IDF version as active'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a discover -d 'Discover available ESP-IDF versions (not implemented yet)'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a remove -d 'Remove specific ESP-IDF version'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a rename -d 'Rename specific ESP-IDF version'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a run -d 'Run command in the context of a specific ESP-IDF version'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a import -d 'Import existing ESP-IDF installation using tools_set_config.json'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a purge -d 'Purge all ESP-IDF installations'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a wizard -d 'Run the ESP-IDF Installer Wizard'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a gui -d 'Run the ESP-IDF Installer GUI with arguments passed through command line'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a fix -d 'Fix the ESP-IDF installation by reinstalling the tools and dependencies'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a install-drivers -d 'Install drivers for ESP-IDF. This is only available on Windows platforms'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a completions -d 'Generate shell completion script to stdout'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a help-json -d 'Print help in JSON format for machine reading'
complete -c eim -n "__fish_eim_using_subcommand help; and not __fish_seen_subcommand_from install list list-tools list-features select discover remove rename run import purge wizard gui fix install-drivers completions help-json help" -f -a help -d 'Print this message or the help of the given subcommand(s)'

# >>> ESP-IDF EIM PATH >>>
# Added by ESP-IDF extension so the EIM CLI can be launched directly.
if not contains -- /usr/bin $PATH
    set -gx PATH /usr/bin $PATH
end
# <<< ESP-IDF EIM PATH <<<

function frg --description "Live interactive ripgrep + fzf preview"
    set -l initial_query (string escape -- $argv)

    set -l rg_command "rg --column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git/*'"

    # Clipboard fallback (supports Wayland, X11, macOS)
    set -l copy_cmd pbcopy
    if type -q wl-copy
        set copy_cmd wl-copy
    else if type -q xclip
        set copy_cmd "xclip -selection clipboard"
    end

    set -l result (
        FZF_DEFAULT_COMMAND="$rg_command ''" \
        fzf --disabled \
            --ansi \
            --query="$initial_query" \
            --delimiter ':' \
            --prompt '🔍 Search > ' \
            --header '⚡ [Ctrl-Y: Copy Preview] | Search file contents' \
            --border='rounded' \
            --border-label=' Live Ripgrep Search ' \
            --border-label-pos='2' \
            --color='border:#89b4fa,label:#f5e0dc,prompt:#cba6f7,pointer:#f5e0dc' \
            --preview 'test -n "{1}" && bat --style=numbers,changes --color=always --highlight-line {2} -- {1}' \
            --preview-window 'right:60%,border-rounded,+{2}+3/3' \
            --bind "start:reload:$rg_command {q}" \
            --bind "change:reload:$rg_command {q} || true" \
            --bind "ctrl-y:execute-silent(bat --plain --color=never -- {1} | $copy_cmd)+change-prompt(📋 Copied! > )"
    )

    if test -n "$result"
        set -l file (string split -f1 ":" -- $result)
        set -l line (string split -f2 ":" -- $result)

        set -l editor $EDITOR
        test -z "$editor"; and set editor nvim

        $editor +$line "$file"
    end
end
