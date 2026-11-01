;;; init.el --- Modern Emacs config for C++, Rust, Go, Python, TypeScript -*- lexical-binding: t; -*-

;;; Commentary:
;; Built for Emacs 31.  Standard Emacs keybindings (no evil).
;;
;;   LSP          eglot (built-in)
;;   Syntax       tree-sitter *-ts-modes, grammars auto-installed on demand
;;   Formatting   apheleia (async, runs on save)
;;   Linting      flymake fed by eglot + flymake-ruff / flymake-eslint
;;   Completion   vertico/orderless/marginalia/consult/embark + corfu/cape
;;
;; See README.md for keybindings.

;;; Code:

;;;; Packages --------------------------------------------------------------

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))
      package-archive-priorities '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1)))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t
      use-package-expand-minimally t)

;; Keep Customize output out of this file.
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file 'noerror 'nomessage)

;;;; macOS / environment ----------------------------------------------------

;; GUI Emacs on macOS does not inherit the shell PATH; needed to find
;; clangd, rust-analyzer, gopls, ruff, prettier, etc.
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (setq exec-path-from-shell-variables
        '("PATH" "MANPATH" "GOPATH" "GOROOT" "CARGO_HOME" "RUSTUP_HOME"
          "VIRTUAL_ENV" "NVM_DIR"))
  (exec-path-from-shell-initialize))

;;;; Sane defaults -----------------------------------------------------------

(use-package emacs
  :ensure nil
  :custom
  (use-short-answers t)
  (ring-bell-function #'ignore)
  (indent-tabs-mode nil)
  (tab-width 4)
  (fill-column 100)
  (require-final-newline t)
  (sentence-end-double-space nil)
  (create-lockfiles nil)
  (make-backup-files nil)
  (auto-save-default t)
  (auto-save-file-name-transforms
   `((".*" ,(locate-user-emacs-file "auto-save/") t)))
  (scroll-conservatively 101)
  (scroll-margin 3)
  (mouse-wheel-progressive-speed nil)
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (tab-always-indent 'complete)
  (text-mode-ispell-word-completion nil)
  (kill-do-not-save-duplicates t)
  (save-interprogram-paste-before-kill t)
  (column-number-mode t)
  (help-window-select t)
  (switch-to-buffer-obey-display-actions t)
  :config
  (make-directory (locate-user-emacs-file "auto-save/") t)
  (delete-selection-mode 1)
  (global-auto-revert-mode 1)
  (savehist-mode 1)
  (save-place-mode 1)
  (recentf-mode 1)
  (winner-mode 1)
  (pixel-scroll-precision-mode 1)
  (electric-pair-mode 1)
  (show-paren-mode 1)
  (repeat-mode 1)
  (which-key-mode 1)
  (editorconfig-mode 1)
  :hook
  (prog-mode . display-line-numbers-mode)
  (prog-mode . hl-line-mode)
  :bind
  (("M-o"     . other-window)
   ("C-x k"   . kill-current-buffer)
   ("C-x C-b" . ibuffer)
   ("M-z"     . zap-up-to-char)
   ("C-c t l" . display-line-numbers-mode)
   ("C-c t w" . whitespace-mode)
   ("C-c t v" . visual-line-mode)))

(setq recentf-max-saved-items 300)

;;;; Appearance --------------------------------------------------------------

(setq modus-themes-italic-constructs t
      modus-themes-bold-constructs t
      modus-themes-to-toggle '(modus-vivendi-tinted modus-operandi-tinted))
(load-theme 'modus-vivendi-tinted t)
(keymap-global-set "C-c t t" #'modus-themes-toggle)

(defun my/set-fonts (&optional _frame)
  "Pick the first installed font from a preferred list."
  (when (display-graphic-p)
    (when-let* ((font (seq-find (lambda (f) (member f (font-family-list)))
                                '("FiraCode Nerd Font Mono" "JetBrains Mono"
                                  "SF Mono" "Menlo"))))
      (set-face-attribute 'default nil :family font :height 140)
      (set-face-attribute 'fixed-pitch nil :family font))))
(add-hook 'window-setup-hook #'my/set-fonts)
(add-hook 'server-after-make-frame-hook #'my/set-fonts)

(use-package nerd-icons)

(use-package doom-modeline
  :custom
  (doom-modeline-height 26)
  (doom-modeline-buffer-file-name-style 'relative-from-project)
  :init (doom-modeline-mode 1))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;;; Minibuffer completion -----------------------------------------------------

(use-package vertico
  :custom
  (vertico-cycle t)
  (vertico-count 15)
  :init (vertico-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion))
                                   (eglot (styles orderless))
                                   (eglot-capf (styles orderless)))))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package consult
  :bind
  (("C-x b"   . consult-buffer)
   ("C-x 4 b" . consult-buffer-other-window)
   ("C-x p b" . consult-project-buffer)
   ("C-x r b" . consult-bookmark)
   ("M-y"     . consult-yank-pop)
   ("M-g g"   . consult-goto-line)
   ("M-g M-g" . consult-goto-line)
   ("M-g i"   . consult-imenu)
   ("M-g I"   . consult-imenu-multi)
   ("M-g o"   . consult-outline)
   ("M-g m"   . consult-mark)
   ("M-g e"   . consult-compile-error)
   ("M-g f"   . consult-flymake)
   ("M-s r"   . consult-ripgrep)
   ("M-s g"   . consult-git-grep)
   ("M-s f"   . consult-fd)
   ("M-s l"   . consult-line)
   ("M-s L"   . consult-line-multi)
   ("C-c r"   . consult-recent-file)
   :map isearch-mode-map
   ("M-s l"   . consult-line))
  :custom
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  (consult-narrow-key "<"))

(use-package embark
  :bind
  (("C-."   . embark-act)
   ("C-;"   . embark-dwim)
   ("C-h B" . embark-bindings))
  :custom
  (prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; Edit grep/ripgrep results in place: C-c C-p in an embark-export buffer.
(use-package wgrep
  :custom (wgrep-auto-save-buffer t))

;;;; In-buffer completion ------------------------------------------------------

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.15)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  :init
  (global-corfu-mode 1)
  (corfu-history-mode 1)
  (corfu-popupinfo-mode 1))

(use-package nerd-icons-corfu
  :after corfu
  :config (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev 90))

;;;; Editing helpers -----------------------------------------------------------

(use-package avy
  :bind (("M-j"   . avy-goto-char-timer)
         ("M-g l" . avy-goto-line)))

(use-package expreg
  :bind (("C-=" . expreg-expand)
         ("C--" . expreg-contract)))

(use-package multiple-cursors
  :bind (("C->"         . mc/mark-next-like-this)
         ("C-<"         . mc/mark-previous-like-this)
         ("C-c m a"     . mc/mark-all-like-this)
         ("C-c m l"     . mc/edit-lines)))

(use-package vundo
  :bind ("C-x u" . vundo))

(use-package helpful
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)))

;;;; Git -------------------------------------------------------------------------

(use-package magit
  :bind (("C-x g"   . magit-status)
         ("C-c g b" . magit-blame-addition)
         ("C-c g l" . magit-log-buffer-file))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package diff-hl
  :hook ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :init
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1))

;;;; Tree-sitter -------------------------------------------------------------------

;; Emacs 31: use the *-ts-mode for every language that has one, and
;; offer to download + compile a grammar the first time it is needed.
(use-package treesit
  :ensure nil
  :custom
  (treesit-enabled-modes t)
  (treesit-auto-install-grammar 'ask)
  (treesit-font-lock-level 4))

(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode))

;;;; Projects ----------------------------------------------------------------------

;; project.el treats the git root as the project by default.  In a monorepo,
;; also treat any directory containing one of these markers as its own
;; project, so eglot starts a server per sub-project and C-x p commands
;; scope to it.  The nearest marker wins.
(use-package project
  :ensure nil
  :custom
  (project-vc-extra-root-markers
   '("go.mod" "Cargo.toml" "package.json" "tsconfig.json" "pyproject.toml"
     "compile_commands.json" ".project")))

;;;; Compilation -------------------------------------------------------------------

(use-package compile
  :ensure nil
  :custom
  (compilation-scroll-output 'first-error)
  (compilation-ask-about-save nil)
  (compilation-max-output-line-length nil)
  :hook (compilation-filter . ansi-color-compilation-filter)
  :bind (("C-c c" . project-compile)
         ("C-c C" . recompile)))

;;;; LSP: eglot ------------------------------------------------------------------

(use-package eglot
  :ensure nil
  :hook
  ((c-ts-mode c++-ts-mode c-mode c++-mode
    rust-ts-mode
    go-ts-mode go-mod-ts-mode
    python-ts-mode python-mode
    typescript-ts-mode tsx-ts-mode js-ts-mode js-mode)
   . eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-extend-to-xref t)
  (eglot-events-buffer-config '(:size 0 :format full)) ; no event log = faster
  (eglot-send-changes-idle-time 0.3)
  (eglot-report-progress nil)
  :config
  ;; C/C++: clangd with clang-tidy diagnostics.
  (add-to-list 'eglot-server-programs
               '((c-ts-mode c++-ts-mode c-mode c++-mode)
                 . ("clangd" "--background-index" "--clang-tidy"
                    "--header-insertion=iwyu" "--completion-style=detailed"
                    "--function-arg-placeholders=0")))
  ;; Python: prefer basedpyright, fall back to pyright. Ruff lints/formats.
  (add-to-list 'eglot-server-programs
               `((python-ts-mode python-mode)
                 . ,(eglot-alternatives
                     '(("basedpyright-langserver" "--stdio")
                       ("pyright-langserver" "--stdio")))))

  ;; TypeScript: TS >= 7 (native Go compiler) has a built-in LSP server.
  ;; Prefer the project's own tsc, then the global one.
  (defun my/ts-server-contact (&rest _)
    (let ((root (locate-dominating-file default-directory "node_modules/.bin/tsc")))
      (list (if root (expand-file-name "node_modules/.bin/tsc" root) "tsc")
            "--lsp" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((typescript-ts-mode tsx-ts-mode js-ts-mode js-mode)
                 . my/ts-server-contact))

  ;; Per-server settings (sent via workspace/configuration).
  ;; Override per project with a .dir-locals.el if needed.
  (setq-default
   eglot-workspace-configuration
   '(:rust-analyzer
     (:check (:command "clippy")
      :cargo (:features "all")
      :procMacro (:enable t))
     :gopls
     (:staticcheck t
      :usePlaceholders t
      :gofumpt :json-false
      :analyses (:unusedparams t :unusedwrite t :nilness t :shadow t))
     :basedpyright
     (:disableOrganizeImports t           ; ruff owns imports
      :analysis (:typeCheckingMode "standard"
                 :autoImportCompletions t))
     :python
     (:analysis (:typeCheckingMode "standard"))))

  :bind
  (:map eglot-mode-map
        ("C-c l r" . eglot-rename)
        ("C-c l a" . eglot-code-actions)
        ("C-c l q" . eglot-code-action-quickfix)
        ("C-c l o" . eglot-code-action-organize-imports)
        ("C-c l f" . eglot-format-buffer)
        ("C-c l i" . eglot-find-implementation)
        ("C-c l t" . eglot-find-typeDefinition)
        ("C-c l d" . eglot-find-declaration)
        ("C-c l h" . eldoc-doc-buffer)
        ("C-c l s" . consult-eglot-symbols)
        ("C-c l R" . eglot-reconnect)
        ("C-c l S" . eglot-shutdown)
        ("C-c t h" . eglot-inlay-hints-mode)))

(use-package consult-eglot
  :after (consult eglot))

(use-package eldoc
  :ensure nil
  :custom
  (eldoc-echo-area-use-multiline-p nil)
  (eldoc-echo-area-prefer-doc-buffer t))

;;;; Linting: flymake ------------------------------------------------------------

(use-package flymake
  :ensure nil
  :custom
  (flymake-start-on-save-buffer t)
  (flymake-no-changes-timeout 0.5)
  (flymake-show-diagnostics-at-end-of-line 'short)
  (flymake-fringe-indicator-position 'right-fringe)
  :bind
  (:map flymake-mode-map
        ("M-n"     . flymake-goto-next-error)
        ("M-p"     . flymake-goto-prev-error)
        ("C-c ! l" . flymake-show-buffer-diagnostics)
        ("C-c ! p" . flymake-show-project-diagnostics)))

;; Eglot replaces flymake's backends with its own, so extra linters must
;; be added after eglot takes over the buffer.

;; Python: ruff diagnostics alongside (based)pyright type checking.
(use-package flymake-ruff
  :hook ((python-base-mode eglot-managed-mode) . my/python-enable-ruff)
  :preface
  (defun my/python-enable-ruff ()
    (when (and (derived-mode-p 'python-base-mode) (executable-find "ruff"))
      (flymake-ruff-load)
      (flymake-mode 1))))

;; TypeScript/JavaScript: eslint alongside the TS language server.
;; Uses the project's local node_modules/.bin/eslint when present.
(use-package flymake-eslint
  :hook ((typescript-ts-mode tsx-ts-mode js-ts-mode js-mode eglot-managed-mode)
         . my/ts-enable-eslint)
  :preface
  (defun my/ts-enable-eslint ()
    (when (derived-mode-p 'typescript-ts-mode 'tsx-ts-mode 'js-ts-mode 'js-mode)
      (require 'flymake-eslint)
      (when-let* ((root (locate-dominating-file default-directory "node_modules"))
                  (local (expand-file-name "node_modules/.bin/eslint" root))
                  ((file-executable-p local)))
        (setq-local flymake-eslint-executable-name local))
      (when (executable-find flymake-eslint-executable-name)
        (flymake-eslint-enable)
        (flymake-mode 1)))))
;; Note: leave `flymake-eslint-prefer-json-diagnostics' off; its JSON parser
;; crashes on eslint messages with no line number (e.g. "File ignored").

;;;; Formatting: apheleia (format on save) --------------------------------------

(use-package apheleia
  :init (apheleia-global-mode 1)
  :bind ("C-c t f" . apheleia-mode)    ; toggle format-on-save per buffer
  :config
  ;; Python: ruff fixes imports, then formats.
  (setf (alist-get 'python-mode    apheleia-mode-alist) '(ruff-isort ruff))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff-isort ruff))
  ;; Go: goimports = gofmt + import management.
  (setf (alist-get 'go-ts-mode     apheleia-mode-alist) 'goimports)
  ;; C/C++: clang-format (honours .clang-format).
  (dolist (m '(c-mode c++-mode c-ts-mode c++-ts-mode))
    (setf (alist-get m apheleia-mode-alist) 'clang-format))
  ;; Rust: rustfmt (honours rustfmt.toml).
  (setf (alist-get 'rust-ts-mode   apheleia-mode-alist) 'rustfmt)
  ;; TS/JS: prettier (apheleia prefers the project-local prettier via npx).
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'prettier-typescript)
  (setf (alist-get 'tsx-ts-mode        apheleia-mode-alist) 'prettier-typescript)
  (setf (alist-get 'js-ts-mode         apheleia-mode-alist) 'prettier-javascript))

;;;; Debugging: dape (DAP) -------------------------------------------------------

;; Debug adapters: codelldb (C++/Rust), dlv (Go), debugpy (Python),
;; js-debug (TypeScript).  Start with M-x dape; prefix key C-x C-a.
(use-package dape
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t)
  :config
  (add-hook 'dape-compile-hook #'kill-buffer))

;;;; Language tweaks ---------------------------------------------------------------

(use-package c-ts-mode
  :ensure nil
  :custom
  (c-ts-mode-indent-offset 4)
  (c-ts-mode-indent-style 'linux))

(use-package go-ts-mode
  :ensure nil
  :custom (go-ts-mode-indent-offset 4)
  :hook (go-ts-mode . (lambda () (setq-local indent-tabs-mode t
                                             tab-width 4))))

(use-package rust-ts-mode
  :ensure nil
  :mode "\\.rs\\'")

(use-package typescript-ts-mode
  :ensure nil
  :mode (("\\.ts\\'"  . typescript-ts-mode)
         ("\\.tsx\\'" . tsx-ts-mode))
  :custom (typescript-ts-mode-indent-offset 2))

(use-package python
  :ensure nil
  :custom (python-indent-guess-indent-offset-verbose nil))

;;;; AI agents: agent-shell (ACP) ----------------------------------------------------

;; Claude Code and Codex in an Emacs buffer via the Agent Client Protocol.
;; Needs the ACP adapters on PATH:
;;   npm install -g @agentclientprotocol/claude-agent-acp @agentclientprotocol/codex-acp
(use-package agent-shell
  :bind (("C-c a a" . agent-shell)
         ("C-c a c" . agent-shell-anthropic-start-claude-code)
         ("C-c a x" . agent-shell-openai-start-codex)))

;;;; Server ------------------------------------------------------------------------

(use-package server
  :ensure nil
  :config
  (unless (server-running-p) (server-start)))

;;; init.el ends here
