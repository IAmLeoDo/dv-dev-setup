dv-dev-setup

Review config.ini and copy the ENTIRE directory, including internal/.
Do not store secrets in config.ini. Use DV_CONFIG for an external private override.

Preview and apply:
  Mutating commands default to a summary only. Add --apply to execute, or use
  --dry-run to explicitly preview. Do not combine both flags. This covers setup,
  install, cleanup, Docker changes/tests, workspace create/open and worktree
  clone/add/open/remove. Read-only help, versions, doctor, status/show/list need
  no apply flag. Existing confirmation and backup steps remain in effect.
  Aliases forward flags: dvds previews; dvds --apply starts Docker.
  Windows menu steps preview; run dev.bat setup NUMBER --apply to execute.

Installed Linux tools:
  Start from the extracted bundle inside Ubuntu/WSL. Setup with --apply copies
  the Linux runtime to a stable user-owned tools directory:
    ~/.local/share/dv-dev-setup/app/    Active runtime
    ~/.local/share/dv-dev-setup/backups/ Previous runtime copies, on changes only
    ~/.local/bin/dv                    CLI symlink into the installed runtime
    ~/.config/dv/config.ini            Persistent user settings
    ~/.config/dv/aliases.bash          Generated Bash shortcuts
  DV_TOOLS_ROOT in [setup] selects a different tools storage root; app/ lives
  beneath it. Use an absolute Linux path outside /mnt/. No sudo is needed.
  To copy/register only tools: bash dev.sh setup --only tools --apply (or install --apply).
  Setup --dry-run and install --dry-run do not copy or write files.
  Installation uses only the Linux runtime allowlist. It never copies private
  overrides, keys or project data. Existing user config is preserved on updates.
  Changed runtime trees are backed up; identical installs do not make backups.
  Run setup --only aliases --apply once to migrate shortcuts from older source-based
  versions. install --apply / setup --only tools --apply copies the CLI without regenerating
  aliases. After alias setup succeeds, the original bundle can be moved/removed.
  dvc begins with TOOL PATHS before System and shows the actual installed runtime,
  CLI and config locations. A check run directly from source reports that source
  path and remains read-only. Installed runtime defaults can be overridden by
  ~/.config/dv/config.ini, or by an explicit DV_CONFIG environment variable.
  Export DV_CONFIG if later commands should use that external private override.
  Keep a complete Windows bundle in an accessible Windows directory for dev.bat;
  tool copying runs inside Ubuntu/WSL. Project checkouts still belong under:
    ~/workspace/devimony/my-project/sources/my-project-dev/

Ubuntu (Bash, from this directory):
  bash dev.sh setup --dry-run
  bash dev.sh setup --apply
  bash dev.sh check
  bash dev.sh help
  bash dev.sh --version
  bash dev.sh versions
Run as your regular development user, not root. Open a new Bash shell after setup.

Alias scenarios (Ubuntu Bash, including WSL and Ubuntu VMs):
  These shortcuts run inside Ubuntu Bash. Windows CMD, PowerShell, Zsh and native
  macOS shells do not load them. All setup commands below run from this copied
  bundle directory, as your regular Linux user.

  1. Set up aliases without installing other tools
     Extract the complete bundle inside Ubuntu/WSL and review config.ini for the
     first installation. Later settings belong in ~/.config/dv/config.ini.
     In [setup], keep DV_INSTALL_ALIASES=true; review names in [aliases].

       bash dev.sh setup --only aliases --dry-run
       bash dev.sh setup --only aliases --apply

     Setup runs in a child process; the terminal that launched it does not gain
     aliases automatically. Activate them in that SAME interactive Bash terminal:

       source "$HOME/.config/dv/aliases.bash"
       type dvh            # Should report an alias, with the default config
       dvh                 # Show help

     Alternatively, open a new interactive Bash shell. Full Ubuntu setup includes
     this module unless disabled. Alias setup creates ~/.config/dv/aliases.bash
     and adds its source line once to ~/.bashrc. It does not install Git, Docker
     or VS Code. The aliases that need those tools require them to be available.
     Alias setup copies/registers the CLI runtime first. The generated aliases
     point to the installed app, so they keep working if this bundle is moved.

  2. Inspect the environment and open your workspace
     From the new Bash shell, these defaults work from any directory:

       dvh                 # Show command help
       dvc                 # Inspect tools and environment
       dvv                 # Show installed tool versions
       dvw                 # Print configured workspace/project roots
       dvwo --apply # Open the project root in VS Code

     dvc groups results into System, Development tools, Git & SSH, Docker,
     Workspace, and Aliases. [OK] means available/configured, [WARN] needs review, and [INFO]
     gives context or marks an untested check. Missing optional tools may be
     intentional. dvc does not install tools, start services or change config.
     GitHub authentication is opt-in: dvc --github. The report returns success
     when complete even if it contains warnings.

     Development tools are grouped as Python / pyenv, Node.js / nvm, and Other
     tools. pyenv and nvm are the main version-manager checks. python3, node and
     npm are listed beneath their manager as optional installed/selected versions;
     a missing runtime in PATH is informational. Available runtime versions are
     resolved from PATH and may come from outside the manager. Git and VS Code
     are listed under Other tools.

     The final Aliases section starts each shortcut with its command mapping.
     Help aliases show only their mapping; other aliases include Usage,
     Actions/Options and Examples in separate groups, separated by short --- lines;
     alternatives and flags are listed one per line with short explanations.
     dvclean separates summary-only examples from its --apply example.
     All examples use the actual configured alias name.
     Example: dvwo [--apply] [--add] [--] [DIR ...], dvwo --apply ./frontend ./backend,
     dvwo --apply --add ./shared ./docs. dvc shows --github; dvclean lists cleanup actions,
     --keep and --apply. Git aliases show common options and native --help.
     It also checks the alias file's syntax/source line and shows activation.
     Examples are printed as hints only and are never executed. It does not execute the alias file or inspect the calling shell.

     dvwo --apply requires code in PATH. Without paths it opens the
     configured project root; you can also choose one or more existing folders:

       dvwo . --apply # Current directory
       dvwo "$HOME/workspace/personal" --apply # A specified folder
       dvwo ./frontend ./backend --apply # Multi-root workspace with both folders
       dvwo --add ./shared ./docs --apply # Add to the last active VS Code window
       dvwo --help

     Relative paths use your current directory. Quote paths containing spaces.
     All requested folders must exist; explicit paths do not require the default
     project root to exist. --add requires at least one folder. This command does
     not create directories or save a .code-workspace file. Without the alias, use
     bash dev.sh workspace open ... from this bundle directory. Keep the alias
     mapping dvwo=dv workspace open; pass extra paths at the command line.
     To inspect the loaded definitions: alias dvh dvc dvv dvw dvwo

  3. Review changes in a Git project
     Change into your actual Git checkout first. Example using the default layout:

       cd "$HOME/workspace/devimony/my-project/sources/my-project-dev"
       gs                  # git status
       gs --short          # Compact status; extra arguments are forwarded
       gd                  # git diff (unstaged changes)
       gd --stat           # Summary of changed files
       gd --cached         # Review staged changes
       gl -5               # Last five commits, one line per commit

     Replace my-project and the workspace path with your own project location.

  4. Start Docker when needed and stop it when finished
     With Docker Engine installed and systemd available:

       dvds --apply # dv docker start; may prompt for sudo
       dvd                 # dv docker status
       sudo docker ps      # Inspect running containers
       dvdt --apply # dv docker stop

     Save container work before dvdt: it stops the Docker service and socket.
     dvd may return a nonzero status when Docker is stopped.

     Optional: grant the current setup user Docker access without sudo:
       DV_DOCKER_ADD_USER_TO_GROUP=true bash dev.sh setup --only docker
       DV_DOCKER_ADD_USER_TO_GROUP=true bash dev.sh setup --only docker --apply
     This grants root-equivalent access. Existing groups are preserved, and
     membership is unchanged by default. After applying, log out/in or run
     newgrp docker in your own Bash terminal. Setup never changes socket modes
     or launches a new group-enabled shell. Service control still needs sudo.

  5. Add or rename shortcuts
     Edit [aliases] in ~/.config/dv/config.ini after installation. For example:

       my_status=git status
       wt=dv worktree list
       dvr=dv docker restart

     Names must start with a letter and contain only ASCII letters, digits or _.
     Names must be unique. Use exact supported targets; no quotes, inline comments,
     arbitrary shell commands or command substitutions. Supported targets:
       dv help, dv doctor, dv versions, dv cleanup, dv workspace, dv workspace open
       dv docker start, dv docker stop, dv docker restart, dv docker status
       dv git status, dv worktree list, git status, git diff, git log --oneline

     Use the installed runtime to preview and apply changes (default tools path):

       bash "$HOME/.local/share/dv-dev-setup/app/dev.sh" setup --only aliases --dry-run
       bash "$HOME/.local/share/dv-dev-setup/app/dev.sh" setup --only aliases --apply

     If DV_TOOLS_ROOT is customized, use Active runtime from dvc instead.

     Open a new Bash shell, then use my_status --short, wt, or dvr as needed.
     wt requires a repository in the supported worktree layout. dvr --apply restarts Docker; dvr alone previews.
     Edit the persistent config.ini rather than generated aliases.bash, which setup replaces.
     A [aliases] section in an external DV_CONFIG replaces the entire alias list;
     include every shortcut you want to keep. Example with a private override:

       DV_CONFIG="$HOME/config.local.ini" bash dev.sh setup --only aliases --dry-run
       DV_CONFIG="$HOME/config.local.ini" bash dev.sh setup --only aliases --apply

  6. An alias is missing, or the bundle has moved
     Confirm you are in Ubuntu Bash, DV_INSTALL_ALIASES is true, and the name is
     present in the selected [aliases] section. Check the definition, for example:

       alias gs

     If dvh says "command not found", load the generated file in the current shell:

       source "$HOME/.config/dv/aliases.bash"
       type dvh
       dvh

     If source reports "No such file or directory", run alias setup from the
     installed runtime or an extracted bundle, with --apply and without sudo.
     Default installed command:
       bash "$HOME/.local/share/dv-dev-setup/app/dev.sh" setup --only aliases --apply
     Then run the source command above in your interactive Bash terminal. Windows
     setup alone does not create Linux aliases. Setup must complete successfully;
     inspect earlier failures if full setup stopped before reaching aliases.
     If the file exists but type still cannot find dvh, check that [aliases] in
     ~/.config/dv/config.ini (or DV_CONFIG) includes dvh=dv help, rerun alias setup and reload.
     Opening a new interactive Bash shell also loads aliases through ~/.bashrc;
     custom startup files must load ~/.bashrc for this to work.
     Removing or renaming an alias in config.ini does not unload it from already
     open shells; open a fresh Bash shell to discard removed definitions.
     An unmanaged file or symlink at ~/.config/dv/aliases.bash must be moved aside
     manually before setup can write there; preserve any user configuration.
     Moving the extracted bundle does not break aliases: they use the installed
     runtime. If DV_TOOLS_ROOT/app was moved manually, rerun setup from a bundle
     and reload aliases; normally leave the installed tools directory in place.
     DV_INSTALL_ALIASES=false skips future setup; it does not remove existing aliases.

Cleanup scenarios (Ubuntu/WSL):
  Default shortcut: dvclean = dv cleanup. Existing installs: add
  dvclean=dv cleanup to [aliases] in ~/.config/dv/config.ini, rerun alias setup
  and source ~/.config/dv/aliases.bash. User settings are preserved on upgrades.
    dvclean all --keep dv             Summary only
    dvclean all --keep dv --apply     Execute after confirmation
  Without --apply, commands print a SUMMARY ONLY: directories/tools to delete,
  installed packages to uninstall, and tools to keep. No APT simulation, manager
  initialization/uninstall, sudo, file deletion or shell edits run in summary mode.
  Add --apply and confirm the printed plan to remove selected items. For explicitly reviewed automation: --apply --yes.
  Do not run the whole command with sudo. Only APT package removal uses sudo.
  From a bundle without the installed CLI, use bash dev.sh cleanup ... instead.

  1. Reset the managed environment while keeping chosen tools
       dv cleanup all
       dv cleanup all --keep dv,pyenv,nvm
       dv cleanup all --keep dv,pyenv,nvm --apply

     --keep names: dv, pyenv, nvm, docker, git, ssh, packages (comma-separated).
     python/node also mean pyenv/nvm. Kept managers retain all installed versions
     and known recorded prerequisites. Cache cleanup may still run for kept tools.
     To remove all selected managed tools, use dv cleanup all --apply.

  2. Remove only specific tools or packages
       dv cleanup tools nvm
       dv cleanup tools pyenv --apply
       dv cleanup tools dv --apply
       dv cleanup packages docker-ce docker-ce-cli
       dv cleanup tools docker --include-existing

     Removing pyenv/nvm removes ALL their versions and installed libraries/global
     packages. Removing dv removes its installed runtime, CLI link and managed
     aliases; use a downloaded bundle/source to install it again. Exact generated
     shell initialization lines are removed after backing up ~/.bashrc. Custom
     lines are kept. Open a new Bash shell after removal.

     New setup runs record only missing packages they successfully install.
     Packages that already existed are kept by automatic cleanup. Old installations
     have no ownership record: select exact packages, or explicitly preview with
     --include-existing to include preexisting allowlisted dev packages.
       dv cleanup all --include-existing --keep dv,git
     Only --apply runs APT simulation before confirmation. Unselected dependency
     removals cause an error.
     No purge or autoremove is performed. Baseline system Python, SSH client,
     certificates and OS tools are kept. Save container work and stop running
     Docker/containerd services manually before applying their package removal.

  3. Clean caches or a project's dependencies without removing managers
       dv cleanup cache
       dv cleanup cache --apply
       dv cleanup project ./my-project
       dv cleanup project ./my-project --only node --apply
       dv cleanup project ./my-project --only python --apply

     Cache cleanup uses default pip/npm cache directories and manager download
     caches; custom pip/npm cache paths are not discovered. Project cleanup only
     selects .venv and/or node_modules in the named directory, not all projects.
     Source code, .git, package manifests and lockfiles are kept. Reinstall the
     selected dependencies normally afterward. Active/tracked/symlinked targets
     are refused; deactivate selected runtimes before applying removal.

  4. Remove one old runtime version, keeping its manager
       dv cleanup python 3.13.12
       dv cleanup node 22.14.0
       dv cleanup node 22.14.0 --apply

     Full version numbers only; no latest/lts/system aliases. Selected versions
     must be inactive. Other versions and the manager remain installed.

  Always preserved: project sources, SSH keys, persistent user configuration,
  tool update backups, system Python, Docker images/volumes and container data.
  all does not recursively remove project dependencies or unrelated user packages.
  Preview does not create state/backups or initialize nvm. Cleanup failures stop
  subsequent removals; review remaining state before retrying. Deletions across
  package managers and files are not transactional. Shell backups are kept at:
    ~/.local/state/dv-dev-setup/cleanup-backups/

Windows CMD (from this directory):
  dev.bat              (interactive menu)
  dev.bat setup
  dev.bat check
  dev.bat help
  dev.bat --version

Windows PowerShell (from this directory):
  .\dev.bat            (interactive menu)
  .\dev.bat setup
  .\dev.bat check
  .\dev.bat help
  .\dev.bat --version
Both Windows shells use native batch; no .ps1 or policy bypass is required.
Enable WSL features as administrator; install/configure Ubuntu as your development user.
Windows setup prepares WSL. Run Ubuntu setup separately inside Ubuntu.

macOS:
  Prepare an Ubuntu VM separately and follow the Ubuntu instructions inside it.
  Native macOS setup and automatic VM provisioning are not implemented.

Windows terminal behavior:
  No arguments, or menu: open the numbered interactive main menu.
  Setup, Check environment, Version and Help are available; Q quits.
  Setup submenu: select a step; B returns. Results wait before returning to menu.
  Direct commands still wait for a key before finishing; exit codes are preserved.
  The menu returns the last action's exit code when closed with Q or B.
  For automation in CMD: set "DV_NO_PAUSE=true"
  For automation in PowerShell: $env:DV_NO_PAUSE = 'true'
  In automation mode, no arguments shows help; use setup with a numbered step.
