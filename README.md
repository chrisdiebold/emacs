# Emacs Config

A modern, minimal-dependency Emacs 31 config for **C++, Rust, Go, Python, and TypeScript**.
Standard Emacs keybindings, no evil-mode.

- **LSP:** eglot (built-in)
- **Syntax:** tree-sitter `*-ts-mode`s. Grammars download and compile the first time you open a file.
- **Format on save:** apheleia (runs async, so saves never block)
- **Lint:** flymake, fed by the language server plus ruff and eslint
- **Completion:** vertico + orderless + marginalia + consult + embark (minibuffer), corfu + cape (in-buffer)

## Files

| File            | Purpose                                                        |
|-----------------|----------------------------------------------------------------|
| `early-init.el` | Startup speed, hides UI chrome, macOS native-comp fix          |
| `init.el`       | Everything else, split into sections (`;;;;` headings)         |
| `custom.el`     | Written by `M-x customize`. Not tracked, created on demand     |

The config lives in `~/.config/emacs/`, the XDG location. If `~/.emacs`, `~/.emacs.el` or `~/.emacs.d/` exists, Emacs loads that instead and ignores this folder, so make sure none of them exist.

The first launch installs packages from GNU ELPA, NonGNU ELPA, and MELPA. This takes about a minute.

## External tools

| Language   | LSP server                                   | Formatter            | Linter                                        |
|------------|----------------------------------------------|----------------------|-----------------------------------------------|
| C/C++      | `clangd`                                     | `clang-format`       | clangd + clang-tidy (`--clang-tidy`)          |
| Rust       | `rust-analyzer`                              | `rustfmt`            | rust-analyzer running `cargo clippy`          |
| Go         | `gopls`                                      | `goimports`          | gopls + staticcheck + extra analyzers         |
| Python     | `basedpyright` (falls back to `pyright`)     | `ruff` (isort + fmt) | `ruff` (flymake-ruff) + basedpyright types    |
| TypeScript | `tsc --lsp` (TypeScript ≥ 7)                 | `prettier`           | `eslint` (flymake-eslint) + tsc               |

AI agents (optional, for agent-shell):

| Agent       | ACP adapter (required)                         | CLI (for signing in)  |
|-------------|------------------------------------------------|-----------------------|
| Claude Code | `claude-agent-acp`                             | `claude`              |
| Codex       | `codex-acp`                                    | `codex`               |

## Installing the tools

You need Emacs 31 or later, built with tree-sitter and (ideally) native compilation. You also need a C compiler, because Emacs compiles tree-sitter grammars the first time it needs them.

### macOS (Homebrew)

```sh
# Compiler + clangd (Apple's clangd includes clang-tidy)
xcode-select --install

# Search, C/C++ formatting
brew install ripgrep fd clang-format

# Rust: rustup, then the components the config uses
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup component add rust-analyzer clippy rustfmt

# Go
brew install go
go install golang.org/x/tools/gopls@latest
go install golang.org/x/tools/cmd/goimports@latest

# Python: ruff (lint + format) and basedpyright (LSP)
brew install uv
uv tool install ruff
uv tool install basedpyright        # or: npm i -g basedpyright

# TypeScript 7+ (built-in LSP), prettier, eslint
brew install node
npm i -g typescript prettier eslint

# Optional: debug adapters for dape
brew install llvm                                         # lldb-dap (C++/Rust)
go install github.com/go-delve/delve/cmd/dlv@latest       # Go
uv tool install debugpy                                   # Python

# Optional: AI agents for agent-shell (CLIs for signing in + ACP adapters)
npm i -g @anthropic-ai/claude-code @openai/codex
npm i -g @agentclientprotocol/claude-agent-acp @agentclientprotocol/codex-acp
```

### Ubuntu / Debian

```sh
# Compiler, clangd, clang-format, clang-tidy, search tools
sudo apt update
sudo apt install -y build-essential git curl clangd clang-format clang-tidy ripgrep fd-find

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup component add rust-analyzer clippy rustfmt

# Go: apt's golang is often old; use the official tarball or snap
sudo snap install go --classic
go install golang.org/x/tools/gopls@latest
go install golang.org/x/tools/cmd/goimports@latest

# Python
curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install ruff
uv tool install basedpyright

# Node (via nvm, so global npm installs don't need sudo), then TS 7+, prettier, eslint
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
nvm install --lts
npm i -g typescript prettier eslint

# Optional: debug adapters for dape
sudo apt install -y lldb                                  # lldb-dap (C++/Rust)
go install github.com/go-delve/delve/cmd/dlv@latest       # Go
uv tool install debugpy                                   # Python

# Optional: AI agents for agent-shell (CLIs for signing in + ACP adapters)
npm i -g @anthropic-ai/claude-code @openai/codex
npm i -g @agentclientprotocol/claude-agent-acp @agentclientprotocol/codex-acp
```

On Ubuntu, `fd` installs as `fdfind`; consult finds it automatically. Make sure `~/go/bin`, `~/.cargo/bin` and `~/.local/bin` are on your shell `PATH`.

Project-local tools take precedence when they exist: `node_modules/.bin/eslint`, and the local prettier that apheleia finds through npx. Formatters read the usual project config files: `.clang-format`, `rustfmt.toml`, `pyproject.toml` / `ruff.toml`, `.prettierrc`, `.editorconfig`.

GUI Emacs reads `PATH` from your login shell through `exec-path-from-shell`, so anything on your shell `PATH` is visible to Emacs.

### Per-project LSP settings

Default server settings live in `eglot-workspace-configuration` in `init.el`. To override them for one project, add a `.dir-locals.el` at the project root:

```elisp
((nil . ((eglot-workspace-configuration
          . (:basedpyright (:analysis (:typeCheckingMode "strict")))))))
```

## Building Emacs from source

This step is optional. Prebuilt Emacs 31 works with this config. Building it yourself gives you native compilation linked against a current libgccjit, plus tree-sitter, and both are built for your exact OS version.

Both platforms use these flags:

| Flag                               | Why                                                        |
|------------------------------------|------------------------------------------------------------|
| `--with-native-compilation=aot`    | Compiles all of Emacs's own Lisp to native code during the build |
| `--with-tree-sitter`               | Needed for the `*-ts-mode`s this config relies on          |
| `--with-ns` (macOS) / `--with-pgtk` (Linux) | Native GUI                                        |

### macOS

```sh
# Build dependencies
xcode-select --install
brew install autoconf texinfo pkgconf gnutls tree-sitter libgccjit gcc

# Get the source (emacs-31 release branch)
git clone --depth 1 -b emacs-31 https://git.savannah.gnu.org/git/emacs.git ~/src/emacs
cd ~/src/emacs

# Configure + build (configure finds Homebrew's libgccjit automatically)
./autogen.sh
./configure --with-native-compilation=aot --with-tree-sitter --with-ns
make -j"$(sysctl -n hw.ncpu)"
make install                       # creates nextstep/Emacs.app

# Install the app and the command-line launcher
rm -rf /Applications/Emacs.app     # removes the old build. Back it up first if you want to keep it
mv nextstep/Emacs.app /Applications/
ln -sf /Applications/Emacs.app/Contents/MacOS/Emacs /usr/local/bin/emacs
ln -sf /Applications/Emacs.app/Contents/MacOS/bin/emacsclient /usr/local/bin/emacsclient
```

If `configure` reports that libgccjit is missing, point it at Homebrew's copy and run `configure` again:

```sh
export CPPFLAGS="-I$(brew --prefix libgccjit)/include"
export LDFLAGS="-L$(brew --prefix libgccjit)/lib/gcc/current"
export LIBRARY_PATH="$(brew --prefix libgccjit)/lib/gcc/current"
```

### Ubuntu / Debian

```sh
# Build dependencies (libgccjit must match your gcc major version)
sudo apt update
sudo apt install -y build-essential git autoconf texinfo pkg-config \
  libgnutls28-dev libtree-sitter-dev "libgccjit-$(gcc -dumpversion | cut -d. -f1)-dev" \
  libgtk-3-dev libharfbuzz-dev libxml2-dev libsqlite3-dev libncurses-dev \
  libjpeg-dev libpng-dev libgif-dev libtiff-dev librsvg2-dev libwebp-dev

# Get the source (emacs-31 release branch)
git clone --depth 1 -b emacs-31 https://git.savannah.gnu.org/git/emacs.git ~/src/emacs
cd ~/src/emacs

# Configure + build (--with-pgtk for Wayland; use --with-x-toolkit=gtk3 for X11)
./autogen.sh
./configure --with-native-compilation=aot --with-tree-sitter --with-pgtk
make -j"$(nproc)"
sudo make install                  # installs to /usr/local
```

If `configure` says your tree-sitter is too old (older Ubuntu releases ship old versions), build it from source and run `configure` again:

```sh
git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git ~/src/tree-sitter
cd ~/src/tree-sitter && make && sudo make install && sudo ldconfig
```

### Verify the build

```sh
emacs --batch --eval '(message "native=%s treesit=%s" (native-comp-available-p) (treesit-available-p))'
# expect: native=t treesit=t
```

After switching to a new Emacs build, delete `~/.config/emacs/eln-cache/` so packages are recompiled against it.

## Key plugins

| Package                         | What it does                                                    |
|---------------------------------|-----------------------------------------------------------------|
| **eglot** (built-in)            | LSP client: completion, xref, rename, code actions, eldoc       |
| **treesit** (built-in)          | Tree-sitter major modes, grammars installed on demand            |
| **flymake** (built-in)          | On-the-fly diagnostics, shown inline at end of line             |
| **apheleia**                    | Format on save, async, keeps cursor position                    |
| **flymake-ruff / flymake-eslint** | Adds ruff/eslint diagnostics next to the LSP's own            |
| **vertico**                     | Vertical minibuffer completion UI                               |
| **orderless**                   | Space-separated, any-order fuzzy matching                       |
| **marginalia**                  | Annotations in the minibuffer (docstrings, file sizes…)         |
| **consult**                     | Search/navigation commands (ripgrep, buffers, imenu, lines)     |
| **embark**                      | Context actions on the thing at point or the current candidate  |
| **corfu + cape**                | In-buffer completion popup, plus file/dabbrev sources            |
| **magit**                       | Git porcelain                                                   |
| **diff-hl**                     | Git change markers in the fringe                                |
| **dape**                        | Debugger (DAP client)                                           |
| **agent-shell**                 | Claude Code and Codex agents in a buffer (ACP)                  |
| **avy / expreg / multiple-cursors** | Jump anywhere, expand region, multiple cursors              |
| **vundo**                       | Visual undo tree                                                |
| **helpful**                     | Better `C-h` help buffers                                       |
| **doom-modeline + nerd-icons**  | Modeline and icons (uses your installed Nerd Font)              |
| **which-key** (built-in)        | Pops up the available keys after a prefix                       |
| **modus-themes** (built-in)     | `modus-vivendi-tinted` (dark) / `modus-operandi-tinted` (light) |

## Keybindings

`C-` = Control, `M-` = Meta (Option on macOS). which-key shows what's available after any prefix. `C-h B` (embark-bindings) searches every binding.

### LSP (`C-c l` prefix, active in eglot buffers)

| Key        | Action                                 |
|------------|----------------------------------------|
| `M-.`      | Go to definition                       |
| `M-,`      | Jump back                              |
| `M-?`      | Find references                        |
| `C-c l r`  | Rename symbol                          |
| `C-c l a`  | Code actions                           |
| `C-c l q`  | Quick fix                              |
| `C-c l o`  | Organize imports                       |
| `C-c l f`  | Format buffer through LSP              |
| `C-c l i`  | Find implementation                    |
| `C-c l t`  | Find type definition                   |
| `C-c l d`  | Find declaration                       |
| `C-c l h`  | Show docs in a buffer (eldoc)          |
| `C-c l s`  | Search workspace symbols (consult)     |
| `C-c l R`  | Reconnect server                       |
| `C-c l S`  | Shut down server                       |
| `C-c t h`  | Toggle inlay hints                     |

### Diagnostics (flymake)

| Key        | Action                          |
|------------|---------------------------------|
| `M-n`      | Next diagnostic                 |
| `M-p`      | Previous diagnostic             |
| `M-g f`    | Search buffer diagnostics       |
| `C-c ! l`  | List buffer diagnostics         |
| `C-c ! p`  | List project diagnostics        |

### Formatting

Formatting runs on every save. Commands for controlling it:

| Key        | Action                                       |
|------------|----------------------------------------------|
| `C-c t f`  | Toggle format-on-save for this buffer        |
| `C-c l f`  | Format now through the LSP server            |
| `M-x apheleia-format-buffer` | Format now through apheleia |

### Search & navigation (consult)

| Key        | Action                                       |
|------------|----------------------------------------------|
| `C-x b`    | Switch buffer (also lists recent files and bookmarks) |
| `C-x p b`  | Switch buffer in the current project         |
| `C-c r`    | Recent files                                 |
| `M-s r`    | ripgrep in project                           |
| `M-s g`    | git grep                                     |
| `M-s f`    | Find file by name (fd)                       |
| `M-s l`    | Search lines in buffer                       |
| `M-s L`    | Search lines in all buffers                  |
| `M-g g`    | Go to line                                   |
| `M-g i`    | imenu (symbols in file)                      |
| `M-g I`    | imenu across project buffers                 |
| `M-g o`    | Outline headings                             |
| `M-g e`    | Compile errors                               |
| `M-y`      | Yank from kill ring                          |
| `<` (in consult) | Narrow by source (`b` buffers, `f` files…) |

### Embark

| Key        | Action                                                  |
|------------|---------------------------------------------------------|
| `C-.`      | Action menu for the thing at point or current candidate |
| `C-;`      | Run the default action                                  |
| `C-.` `E`  | Export candidates (e.g. ripgrep hits → editable grep buffer) |
| `C-c C-p`  | In an exported grep buffer: edit in place (wgrep); `C-c C-c` saves |

### Projects (project.el, built-in)

**Project root:** the nearest directory above the file that contains a `.git` folder or one of these markers:
`go.mod`, `Cargo.toml`, `package.json`, `tsconfig.json`, `pyproject.toml`, `compile_commands.json`, `.project`.
In a monorepo, each sub-project therefore gets its own root, its own eglot server, and its own scope for the commands below.
To make any other directory a project, create an empty `.project` file in it.

| Key        | Action                                   |
|------------|------------------------------------------|
| `C-x p p`  | Switch project (then choose an action)   |
| `C-x p f`  | Find file in project                     |
| `C-x p b`  | Switch to a project buffer (consult)     |
| `C-x p d`  | Find directory in project                |
| `C-x p D`  | Dired at project root                    |
| `C-x p g`  | Find regexp in project (xref)            |
| `C-x p r`  | Query-replace across project             |
| `C-x p s`  | Shell in project root                    |
| `C-x p e`  | Eshell in project root                   |
| `C-x p !`  | Run shell command in project root        |
| `C-x p k`  | Kill project buffers                     |
| `M-s r`    | ripgrep in project (consult)             |
| `M-s f`    | Find file by name with fd (consult)      |
| `C-c ! p`  | List project diagnostics (flymake)       |
| `C-c c`    | Compile in project root                  |
| `C-c C`    | Recompile                                |

### Editing

| Key        | Action                                    |
|------------|-------------------------------------------|
| `M-j`      | Jump to char (avy, type then pause)       |
| `M-g l`    | Jump to line (avy)                        |
| `C-=`      | Expand selection by syntax node           |
| `C--`      | Contract selection                        |
| `C->` / `C-<` | Add cursor at next/previous match       |
| `C-c m a`  | Cursors on all matches                    |
| `C-c m l`  | Cursor on each line of the region         |
| `C-x u`    | Visual undo tree (vundo)                  |
| `M-z`      | Zap up to char                            |
| `TAB`      | Indent, or complete if already indented   |

In the corfu popup: `TAB`/`RET` inserts, `M-n`/`M-p` or arrow keys move, `C-g` closes. The docs popup opens automatically after a short delay.

### Git

| Key        | Action                     |
|------------|----------------------------|
| `C-x g`    | Magit status               |
| `C-c g b`  | Blame                      |
| `C-c g l`  | Log for current file       |
| `C-x v [` / `C-x v ]` | Previous/next changed hunk (diff-hl) |

### Debugging (dape)

Start a session with `M-x dape` and pick a config (`codelldb`/`lldb-dap`, `dlv`, `debugpy`, `js-debug`). Use the `C-x C-a` prefix during the session:

| Key          | Action            |
|--------------|-------------------|
| `C-x C-a b`  | Toggle breakpoint |
| `C-x C-a c`  | Continue          |
| `C-x C-a n`  | Next              |
| `C-x C-a s`  | Step in           |
| `C-x C-a o`  | Step out          |
| `C-x C-a r`  | Restart           |
| `C-x C-a q`  | Quit              |

### AI agents (agent-shell)

| Key        | Action                                       |
|------------|----------------------------------------------|
| `C-c a a`  | Start an agent (pick from the list)          |
| `C-c a c`  | Start Claude Code                            |
| `C-c a x`  | Start Codex                                  |

### Windows, help & toggles

| Key        | Action                              |
|------------|-------------------------------------|
| `M-o`      | Other window                        |
| `C-c ←` / `C-c →` | Undo/redo window layout (winner) |
| `C-x k`    | Kill current buffer                 |
| `C-x C-b`  | ibuffer                             |
| `C-h f/v/k/x` | Help for function/variable/key/command (helpful) |
| `C-h B`    | Search all keybindings              |
| `C-c t t`  | Toggle dark/light theme             |
| `C-c t l`  | Toggle line numbers                 |
| `C-c t w`  | Toggle whitespace display           |
| `C-c t v`  | Toggle visual line mode             |

## Notes

- **Native compilation fix for macOS 26+:** older libgccjit builds (including the one bundled with emacsformacosx.com Emacs) compute the macOS version from the kernel as Darwin − 9. That broke when Apple jumped from macOS 15 to 26: Darwin 27 becomes `18.0`, which clang rejects. `early-init.el` reads the real version from `sw_vers` and passes `-mmacosx-version-min=<major>.0` to the compiler. The block does nothing on Linux, and it's harmless with a libgccjit that already computes the version correctly.
- **TypeScript 7+ is assumed.** Its native compiler has a built-in language server, which eglot runs with `tsc --lsp --stdio`. It uses the project's `node_modules/.bin/tsc` if there is one, otherwise the global `tsc`. Projects on TypeScript 6 or earlier won't get LSP support.
- **Tree-sitter grammars** go in `~/.config/emacs/tree-sitter/`. Emacs asks before installing one. To install without asking, set `treesit-auto-install-grammar` to `'always`.
- Emacs starts a server on launch, so `emacsclient -n file` opens files in the running instance.
