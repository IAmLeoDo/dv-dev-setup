# shellcheck shell=bash
if has code; then log 'VS Code command available; use code . from your WSL project'; else log 'Install Windows VS Code and ms-vscode-remote.remote-wsl on Windows; reopen WSL.'; fi
log 'VS Code recommendations from config.ini; apply manually in the host/WSL UI:'
config_section vscode.extensions
config_section vscode.settings
