;;; init-editor.el --- Editing, formatting, projects and workspaces -*- lexical-binding: t -*-

;; Built-in equivalents of undo-fu-only-undo / undo-fu-only-redo
(keymap-global-set "C-/" #'undo-only)
(keymap-global-set "C-S-/" #'undo-redo)

(use-package undo-fu-session
  :config
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'" "\\.env\\'" "\\.env\\."))
  (undo-fu-session-global-mode))

(use-package vundo
  :bind ("C-x u" . vundo))

(use-package dtrt-indent
  :hook (prog-mode . dtrt-indent-mode)
  :custom
  (dtrt-indent-verbosity 0))

(use-package aggressive-indent
  :hook (emacs-lisp-mode . aggressive-indent-mode))

(use-package dumb-jump
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate)
  :custom
  (dumb-jump-prefer-searcher 'rg)
  (dumb-jump-selector 'completing-read))

(use-package wgrep
  :bind ( :map grep-mode-map
          ("e" . wgrep-change-to-wgrep-mode)
          ("C-x C-q" . wgrep-change-to-wgrep-mode)
          ("C-c C-c" . wgrep-finish-edit)))

(use-package ace-window
  :bind (("M-o" . ace-window))
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package avy
  :bind (("C-:" . avy-goto-char-2)      
         ("C-'" . avy-goto-line)
         ("M-g w" . avy-goto-word-1)))   

(use-package multiple-cursors
  :bind (("C->" .           mc/mark-next-like-this)
         ("C-<" .           mc/mark-previous-like-this)
         ("C-c m" .         mc/mark-all-like-this)
         ("C-S-c C-S-c" .   mc/edit-lines)
         ("C-S-<mouse-1>" . mc/add-cursor-on-click)))

(use-package expreg
  :bind (("C-=" . expreg-expand)
         ("C-+" . expreg-contract)))

(use-package smartparens
  :hook (prog-mode text-mode)
  :config
  (require 'smartparens-config)
  (show-smartparens-global-mode 1)
  :bind (:map smartparens-mode-map
              ("C-M-f" . sp-forward-sexp)
              ("C-M-b" . sp-backward-sexp)
              ("C-M-n" . sp-next-sexp)
              ("C-M-p" . sp-previous-sexp)
              ("C-M-k" . sp-kill-sexp)
              ("C-M-w" . sp-copy-sexp)))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package pulsar
  :bind
  (:map global-map
        ("C-x l" . pulsar-pulse-line) 
        ("C-x L" . pulsar-highlight-permanently-dwim)) 
  :init
  (pulsar-global-mode 1)
  :config
  (setq pulsar-delay 0.055)
  (setq pulsar-iterations 5)
  (setq pulsar-face 'pulsar-green)
  (setq pulsar-region-face 'pulsar-yellow)
  (setq pulsar-highlight-face 'pulsar-magenta))

(use-package editorconfig
  :straight (:type built-in)
  :config
  (editorconfig-mode t))

(use-package apheleia
  :config
  (apheleia-global-mode +1))

;;; ------------------------------------------------------------
;;; Projects and workspaces
;;; ------------------------------------------------------------

;; Built-in project.el, also reachable under the old projectile prefix
(keymap-global-set "C-c p" project-prefix-map)
(setq project-switch-commands #'project-find-file)
(let ((inhibit-message t))
  (dolist (dir '("~/source/work" "~/source/personal"))
    (when (file-directory-p dir)
      (project-remember-projects-under dir))))

(provide 'init-editor)
;;; init-editor.el ends here
