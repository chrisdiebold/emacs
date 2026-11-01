;;; early-init.el --- Loaded before the package system and GUI -*- lexical-binding: t; -*-

;;; Commentary:
;; Startup performance tweaks and UI chrome removal.  Runs before init.el.

;;; Code:

;; Defer GC during startup; restored to a sane value in init.el.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Skip regexp file-handler checks while loading init files.
(defvar my--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1
                  file-name-handler-alist my--file-name-handler-alist)))

;; LSP servers send large JSON payloads.
(setq read-process-output-max (* 4 1024 1024))

;; Prefer newer .el over stale .elc.
(setq load-prefer-newer t)

;; Native-comp: keep warnings out of the way.
(setq native-comp-async-report-warnings-errors 'silent)

;; macOS: older libgccjit (e.g. the one bundled in emacsformacosx.com builds)
;; derives the deployment target as Darwin-kernel-version - 9, which broke
;; when Apple jumped from macOS 15 to 26 (Darwin 27 -> "18.0", rejected by
;; clang).  Pass the real macOS version explicitly.  Set before comp.el loads
;; so the defcustom keeps it; async compile workers inherit it.
(when (and (eq system-type 'darwin) (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  (let ((ver (string-trim (shell-command-to-string "sw_vers -productVersion"))))
    (when (string-match "\\`\\([0-9]+\\)" ver)
      (setq native-comp-driver-options
            (list "-Wl,-w"
                  (format "-mmacosx-version-min=%s.0" (match-string 1 ver)))))))

;; Remove UI chrome before the first frame is drawn.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(ns-transparent-titlebar . t) default-frame-alist)
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

;;; early-init.el ends here
