#!/usr/bin/env bash
set -euo pipefail

workspace_dir="${WORKSPACE_DIR:-/workspaces/arckit}"
bashrc="$HOME/.bashrc"
env_file="$workspace_dir/.env"

export PATH="$HOME/.local/bin:$HOME/.claude/local:$PATH"
cd "$workspace_dir"

echo "Setting up ArcKit dev environment..."

append_to_bashrc_once() {
  local marker="$1"
  local block="$2"

  if ! grep -qF "$marker" "$bashrc" 2>/dev/null; then
    printf '%s\n' "$block" >> "$bashrc"
  fi
}

configure_git() {
  git config --global credential.helper store
  git config --global core.eol lf
  git config --global core.autocrlf input
  git config --global --bool push.autoSetupRemote true
  git config --global alias.wip '!f() { git add -A && git commit -m "${1:-WIP}" && git push; }; f'
  git config --global alias.aliases "config --get-regexp '^alias.'"
  git config --global credential.useHttpPath true

  if [[ -n "${GIT_USERNAME:-}" ]]; then
    git config --global user.name "$GIT_USERNAME"
  fi

  if [[ -n "${GIT_EMAIL:-}" ]]; then
    git config --global user.email "$GIT_EMAIL"
  fi
}

add_git_aliases_to_bashrc() {
  if ! grep -qF "# Oh My Zsh git plugin aliases" "$bashrc" 2>/dev/null; then
    cat >> "$bashrc" <<'ALIASES'

# Oh My Zsh git plugin aliases
git_current_branch() { git symbolic-ref --short HEAD 2>/dev/null; }
git_main_branch() {
  local branch
  branch=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
  echo "${branch:-main}"
}
git_develop_branch() {
  git branch --list develop dev | head -1 | tr -d ' *' || echo develop
}

alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gbl='git blame -b -w'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gcam='git commit -a -m'
alias gcb='git checkout -b'
alias gcf='git config --list'
alias gcl='git clone --recurse-submodules'
alias gclean='git clean -id'
alias gcm='git checkout $(git_main_branch)'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gd='git diff'
alias gdca='git diff --cached'
alias gdct='git describe --tags $(git rev-list --tags --max-count=1)'
alias gds='git diff --staged'
alias gdup='git diff @{upstream}'
alias gf='git fetch'
alias gfa='git fetch --all --prune --jobs=10'
alias gfo='git fetch origin'
alias ggl='git pull origin $(git_current_branch)'
alias ggp='git push origin $(git_current_branch)'
alias ggpull='git pull origin "$(git_current_branch)"'
alias ggpush='git push origin "$(git_current_branch)"'
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias ggu='git pull --rebase origin $(git_current_branch)'
alias gignore='git update-index --assume-unchanged'
alias gl='git pull'
alias glg='git log --stat'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glo='git log --oneline --decorate'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias gm='git merge'
alias gma='git merge --abort'
alias gmom='git merge origin/$(git_main_branch)'
alias gms='git merge --squash'
alias gp='git push'
alias gpd='git push --dry-run'
alias gpf='git push --force-with-lease'
alias gpr='git pull --rebase'
alias gpra='git pull --rebase --autostash'
alias gprom='git pull --rebase origin $(git_main_branch)'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gr='git remote'
alias gra='git remote add'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'
alias grbm='git rebase $(git_main_branch)'
alias grbs='git rebase --skip'
alias grev='git revert'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias grm='git rm'
alias grmc='git rm --cached'
alias grmv='git remote rename'
alias grrm='git remote remove'
alias grset='git remote set-url'
alias grss='git restore --staged'
alias grst='git restore'
alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias grup='git remote update'
alias grv='git remote -v'
alias gsb='git status -sb'
alias gsh='git show'
alias gsi='git submodule init'
alias gss='git status -s'
alias gst='git status'
alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --patch'
alias gstu='git stash push --include-untracked'
alias gsu='git submodule update'
alias gsw='git switch'
alias gswc='git switch -c'
alias gswm='git switch $(git_main_branch)'
alias gunignore='git update-index --assume-unchanged'
alias gup='git pull --rebase'
alias gupa='git pull --rebase --autostash'
alias gupom='git pull --rebase origin $(git_main_branch)'
alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias gwip='git add -v && git commit -m "--wip-- [skip ci]"'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'
ALIASES
  fi
}

add_env_loader_to_bashrc() {
  if ! grep -qF "Source project .env" "$bashrc" 2>/dev/null; then
    cat >> "$bashrc" <<'ENVLOAD'

# Source project .env if it exists
if [ -f "$env_file" ]; then
  set -a
  source "$env_file"
  set +a
fi
ENVLOAD
  fi
}

source_project_env() {
  if [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$env_file"
    set +a
  fi
}

install_claude_cli() {
  if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh
    bash /tmp/claude-install.sh
  fi

  command -v claude >/dev/null 2>&1 || {
    echo "ERROR: claude not found after install"
    exit 1
  }

  claude install latest || echo "Warning: claude install latest failed — continuing."
}

install_arckit_plugins() {
  echo "Installing ArcKit Claude plugins..."

  claude plugin marketplace add https://github.com/tractorjuice/arc-kit.git || \
    echo "Warning: arckit plugin marketplace add failed — continuing."

  claude plugin install arckit || \
    echo "Warning: arckit plugin install failed — continuing without it."

  claude plugin install arckit-au && claude plugin enable arckit-au@arc-kit || \
    echo "Warning: arckit-au plugin install/enable failed — continuing without it."
}

configure_git
add_git_aliases_to_bashrc
add_env_loader_to_bashrc
source_project_env

echo "Installing Claude CLI..."
install_claude_cli
install_arckit_plugins

echo "Dev environment ready."
