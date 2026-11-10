;;; init-ui.el --- Appearance and UI configuration -*- lexical-binding: t -*-

;;; Code:
(defun ss--monitor-width (frame)
  (nth 2 (frame-monitor-attribute 'geometry frame)))

(defun ss/apply-font (&optional frame)
  "Set FRAME's font height from the width of the monitor it is on."
  (let ((width (ss--monitor-width frame)))
    (set-frame-parameter frame 'ss-monitor-width width)
    (set-face-attribute 'default frame :family "Iosevka NFM"
                        :height (alist-get width ss/font-height-by-monitor
                                           ss/font-height))))

(defun ss--apply-font-on-monitor-change (frame)
  ;; Only on a monitor change: setting the font can move the frame and re-run this
  (unless (equal (frame-parameter frame 'ss-monitor-width)
                 (ss--monitor-width frame))
    (ss/apply-font frame)))

(defun ss--set-font-option (sym val)
  (set-default sym val)
  ;; Skip until both options exist; runs again when custom-file loads
  (when (boundp 'ss/font-height-by-monitor)
    (mapc #'ss/apply-font (frame-list))))

(defcustom ss/font-height 110
  "Default font height in 1/10 pt.
Set per machine with `M-x customize-variable'; it is saved to the
git-ignored `custom-file'."
  :type 'integer
  :group 'faces
  :set #'ss--set-font-option)

(defcustom ss/font-height-by-monitor nil
  "Alist of (MONITOR-PIXEL-WIDTH . FONT-HEIGHT).
Overrides `ss/font-height' on a monitor of that width, e.g.
\((1920 . 110) (3840 . 150)).  Set per machine like `ss/font-height'."
  :type '(alist :key-type integer :value-type integer)
  :group 'faces
  :set #'ss--set-font-option)

(add-hook 'after-make-frame-functions #'ss/apply-font)
(add-hook 'move-frame-functions #'ss--apply-font-on-monitor-change)
;; load-theme resets per-frame face attributes
(add-hook 'enable-theme-functions (lambda (_) (mapc #'ss/apply-font (frame-list))))

;; Start frames maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(column-number-mode)

(setq display-line-numbers-type t)
(dolist (hook '(prog-mode-hook conf-mode-hook yaml-ts-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

(winner-mode +1)
(defun toggle-delete-other-windows ()
  "Delete other windows in frame if any, or restore previous window config."
  (interactive)
  (if (and winner-mode
           (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))

(global-set-key (kbd "C-x 1") 'toggle-delete-other-windows)
(global-set-key (kbd "C-x <up>") 'windmove-up)
(global-set-key (kbd "C-x <down>") 'windmove-down)
(global-set-key (kbd "C-x <left>") 'windmove-left)
(global-set-key (kbd "C-x <right>") 'windmove-right)
(global-set-key (kbd "C-x C-<up>") 'enlarge-window)
(global-set-key (kbd "C-x C-<down>") 'shrink-window)
(global-set-key (kbd "C-x C-<left>") 'shrink-window-horizontally)
(global-set-key (kbd "C-x C-<right>") 'enlarge-window-horizontally)
(global-set-key (kbd "C-x w t") 'window-layout-transpose)
(global-set-key (kbd "C-x w r") 'window-layout-rotate-clockwise)
(global-set-key (kbd "C-x w f h") 'window-layout-flip-leftright)
(global-set-key (kbd "C-x w f v") 'window-layout-flip-topdown)

(use-package spacious-padding
  :hook (after-init . spacious-padding-mode)
  :custom
  (spacious-padding-widths
   '( :internal-border-width 15
      :header-line-width 4
      :mode-line-width 6
      :tab-width 4
      :right-divider-width 30
      :scroll-bar-width 8
      :fringe-width 8)))

;; Zen mode, after Doom's :ui zen: buffer-local, no fullscreen or maximizing
(use-package writeroom-mode
  :bind ("C-c z" . writeroom-mode)
  :custom
  (writeroom-width 0.5)
  (writeroom-global-effects nil)
  (writeroom-maximize-window nil)
  :config
  (add-hook 'writeroom-local-effects
            (lambda (arg) (text-scale-set (if (= arg 1) 1 0)))
            t)
  ;; Re-center when text size changes
  (add-hook 'text-scale-mode-hook #'visual-fill-column-adjust))

;; Proportional font for prose while in zen mode
(use-package mixed-pitch
  :defer t
  :init
  (add-hook 'writeroom-local-effects
            (lambda (arg)
              (when (derived-mode-p 'adoc-mode 'rst-mode 'markdown-mode 'org-mode)
                (mixed-pitch-mode arg))))
  :config
  (dolist (face '(org-date org-footnote org-special-keyword org-property-value
                  org-tag org-todo org-done font-lock-comment-face))
    (add-to-list 'mixed-pitch-fixed-pitch-faces face)))

;; Dim everything but the current defun/paragraph while in zen mode
(use-package focus
  :defer t
  :init (add-hook 'writeroom-local-effects #'focus-mode t))

;; Install and configure doom-themes
(use-package doom-themes
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ;; if nil, bold is universally disabled
        doom-themes-enable-italic t) ;; if nil, italics is universally disabled
  (doom-themes-visual-bell-config))

(load-theme 'doom-dracula t)
;; Load the theme

(use-package indent-bars
  :straight (indent-bars :type git :host github :repo "jdtsmith/indent-bars")
  :hook ((prog-mode yaml-ts-mode) . indent-bars-mode)
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-no-descend-string t)
  (indent-bars-width-frac 0.2)
  (indent-bars-pad-frac 0.1))

;; Modeline
(use-package nerd-icons
  :custom
  (nerd-icons-font-family "Symbols Nerd Font Mono"))

(use-package doom-modeline
  :init (doom-modeline-mode 1))

(use-package which-key :straight (:type built-in) :config (which-key-mode))

(provide 'init-ui)
;;; init-ui.el ends here
