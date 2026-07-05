# Fresh macOS setup — agent prompt

You are an agent on a fresh (or reset) Mac. Recreate my full environment from this
document. Work top to bottom, verify each block before moving on. Ask before anything
destructive; everything else — just do it.

## Vibe (applies to every choice you make)

- **Catppuccin Mocha** everywhere: terminal, bat, delta, fzf colors, LS_COLORS, lazygit.
- **JetBrainsMono Nerd Font** as the terminal font.
- Preference order: **good TUI > GUI > bare CLI** — lazygit, lazydocker, btop, bbrew,
  one-letter aliases.
- **fzf with rich previews** wired into everything (tab completion, ctrl-t, cd).
- Minimal, fast, informative prompt (starship). Shell startup must stay under ~0.5s
  (`time zsh -i -c exit`) — if a step slows it down, find a lazier way.
- Secrets never live in tracked files — `~/.zshrc.local` (chmod 600), sourced if present.
- No version pins in this doc: always install current stable. If a tool needs a specific
  version for a project, that's the project's concern (global.json, .nvmrc), not this setup.

## 1. Homebrew + packages

Install Homebrew, then:

**Formulae:**
`atuin bat btop direnv docker docker-completion eza fastfetch fd fzf fzf-tab gh git-delta jq lazydocker lazygit neovim nvm opencode ripgrep shfmt starship stylua tailscale tree-sitter-cli uv vivid zoxide zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting`

Tap + install: `valkyrie00/bbrew/bbrew` (TUI for brew itself).

**Casks:**
`anydesk audiorelay blackhole-2ch blackhole-16ch claude claude-code codex cyberduck dotnet-sdk font-jetbrains-mono-nerd-font ghostty google-chrome lm-studio logi-options+ middleclick obs openvpn-connect orbstack pearcleaner rider t3-code transmission visual-studio-code`

Notes:
- `orbstack` replaces Docker Desktop; the `docker` formula is just the CLI client.
- `dotnet-sdk` = current SDK; add LTS cask alongside only if a project demands it.
- After install run `chmod g-w /opt/homebrew/share` — otherwise zsh compaudit complains
  and full compinit aborts.

## 2. zsh (`~/.zshrc`)

Build it with these blocks, in this order:

1. **Env**: `EDITOR`/`VISUAL`=nvim, `PAGER`=less, `LESS="-FRX"`,
   `DOTNET_CLI_TELEMETRY_OPTOUT=1`, `PATH+=~/.dotnet/tools`.
2. **Colors + fzf**: `LS_COLORS="$(vivid generate catppuccin-mocha)"`,
   `BAT_THEME="Catppuccin Mocha"`. fzf default command = `fd --hidden --strip-cwd-prefix
   --exclude .git`; alt-c = dirs only. `FZF_DEFAULT_OPTS`: height 60%, reverse, border,
   right 60% preview window, full Catppuccin Mocha color set. ctrl-t preview: eza for
   dirs / bat with line numbers for files.
3. **Completions**: put `/opt/homebrew/share/zsh-completions` and brew `site-functions`
   on `fpath` *before* compinit. Then:
   ```zsh
   autoload -Uz compinit
   if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then compinit; else compinit -C; fi
   ```
   (full rebuild if dump older than 24h, cached fast path otherwise).
   zstyles: case-insensitive matcher, `list-colors` from LS_COLORS, group headers
   `[%d]`, `menu no` (fzf-tab owns selection).
4. **fzf-tab**: source after compinit; previews for cd and generic completions
   (eza for dirs, bat for files), height 60% reverse, `,`/`.` switch groups.
5. **Options/history**: auto_cd, auto_pushd, pushd_ignore_dups, hist_ignore_all_dups,
   hist_reduce_blanks, hist_save_no_dups, inc_append_history, share_history.
   HISTSIZE=SAVEHIST=100000.
6. **Keybinds**: emacs mode (`bindkey -e`), ctrl-a/e/u/k/w, alt-arrows + alt-b/f word
   jumps, alt-backspace kill word.
7. **Aliases**: `ll`/`la` = eza long with icons/git/group-dirs-first, `ls` = eza,
   `cat`=bat, `grep`=rg, `lg`=lazygit, `ld`=lazydocker, `tree`=`eza --tree --icons=auto`,
   `..`/`...`.
8. **Project jumps**: `cdpath` covering my source roots (ask me for the layout — pattern
   is `~/coding/src/work/...` and `~/coding/src/hobby/...`), plus one-word shell
   functions for the repos I'm currently living in.
9. **Tool inits**: nvm (brew-installed, sourced), `fzf --zsh` (guarded interactive-only),
   `zoxide init zsh`, `starship init zsh`, `direnv hook zsh`.
10. **Secrets**: `[ -f ~/.zshrc.local ] && source ~/.zshrc.local`; create that file
    chmod 600. Ask me which env vars to put there — never write values into ~/.zshrc.
11. **Plugins, order matters**: zsh-autosuggestions → zsh-syntax-highlighting (must be
    near-last) → `eval "$(atuin init zsh --disable-ai)"` (ctrl-r + up arrow; the
    `--disable-ai` flag matters — I don't want `?` hijacked). If there's existing shell
    history, run `atuin import auto`.

## 3. git (`~/.gitconfig`)

- `core.ignorecase=false`, `core.pager=delta`.
- **Identity guard**: global user = `No Name <none@local.invalid>` (deliberate — forces
  per-directory identity). `includeIf "gitdir:..."` blocks for the work and hobby source
  roots, each pointing at a `.gitconfig` inside that root with the real name/email.
  Ask me for the emails at setup time; don't invent them.
- Pretty one-line log format (yellow hash, dim green local date `%F %H:%M`, orange refs,
  cyan subject, gray author) via `format.pretty` + `log.date=format-local`.
- `pull.rebase=true`, `push.autoSetupRemote=true`, `init.defaultBranch=main`,
  `merge.conflictStyle=zdiff3`, `diff.colorMoved=default`.
- **delta**: navigate, line-numbers, `syntax-theme = Catppuccin Mocha`. Side-by-side goes
  in a *feature*, not the main section — main-section values override features, which
  breaks the lazygit opt-out:
  ```ini
  [delta]
      features = wide-view
  [delta "wide-view"]
      side-by-side = true
  [delta "lazygit"]
      side-by-side = false
  ```
- Aliases: `st`=status -sb, `co`, `sw`, `br`, `cm`, `amend`=commit --amend --no-edit,
  `lg`=log --graph --decorate --oneline --all.
- `interactive.diffFilter = delta --color-only`.

See .gitconfig file for details.

## 4. Ghostty (`~/.config/ghostty/config`)

JetBrainsMono Nerd Font Mono 14pt, theme Catppuccin Mocha, padding 10/8, opacity 0.96 +
blur 20 + `background-opacity-cells`, `macos-option-as-alt`, `copy-on-select=clipboard`,
no close confirmation, `window-save-state=always`, `mouse-hide-while-typing`.
Quick terminal: F12 global toggle, top, fullscreen, autohide, follows spaces.
Keybinds: cmd-t/w tabs, cmd-d / cmd-shift-d splits, cmd-arrows split navigation,
cmd-shift-left/right tabs, cmd-shift-enter zoom split, cmd-shift-e equalize.
Validate with `ghostty +validate-config`.

## 5. lazygit (`~/.config/lazygit/config.yml`)

`nerdFontsVersion: "3"`, Catppuccin Mocha border/selection colors, and:
```yaml
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never --features=lazygit
```
(the `--features=lazygit` picks up the single-column override from gitconfig).

## 6. starship (`~/.config/starship.toml`)

`add_newline = false`. Format: directory → git branch/status → dotnet → nodejs →
cmd_duration → newline → character. Directory bold cyan, truncation 4, full repo path.
Git branch `git:` prefix bold purple; status bold yellow. `.NET ` / `node ` version
segments. cmd_duration only above 1.5s. Prompt char `>` green/red.

## 7. Neovim

Clone the LazyVim starter into `~/.config/nvim`, remove its `.git`, run headless plugin
sync. Stock starter is fine — I customize in-repo per machine.

## 8. Verification

- new Ghostty window: font/theme/opacity right, F12 quick terminal works
- `time zsh -i -c exit` < 0.5s, no compinit warnings
- tab completion shows fzf-tab with previews; ctrl-r opens atuin; ctrl-t previews files
- `lg` in any repo: diff is single-column with line numbers; `git diff` in a wide
  terminal: side-by-side
- `git -C <work-repo> config user.email` returns the work identity; a repo outside the
  source roots returns `none@local.invalid`
- `btop`, `fastfetch`, `bbrew` launch; `dotnet --list-sdks` and `node -v` resolve
