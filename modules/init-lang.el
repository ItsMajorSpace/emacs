;;; init-lang.el --- Per-language setup -*- lexical-binding: t -*-

;;; Commentary:
;; One section per language: major mode, language server, debugger and
;; keys.  Generic tooling (tree-sitter, eglot, dape) is in init-prog.el.
;; Jump between sections with M-s M-o.

;;; Code:

;;; ------------------------------------------------------------
;;; C, CSS, JSON, JavaScript
;;; ------------------------------------------------------------
;; Eglot's default servers: clangd, vscode-langservers-extracted,
;; typescript-language-server.

(dolist (hook '(c-ts-mode-hook css-ts-mode-hook json-ts-mode-hook
                js-ts-mode-hook tsx-ts-mode-hook))
  (add-hook hook #'eglot-ensure))

;;; ------------------------------------------------------------
;;; TypeScript, Angular, Razor (web-mode)
;;; ------------------------------------------------------------
;; Requires: npm i -g typescript-language-server @angular/language-server typescript
;; Razor: rzls on PATH.

(add-hook 'typescript-ts-mode-hook #'eglot-ensure)
(add-hook 'web-mode-hook #'eglot-ensure)

(defun ss/eglot-angular-or (fallback)
  "Return an eglot contact: ngserver if the project has angular.json, else FALLBACK.
FALLBACK is a contact list, or a function returning one."
  (lambda (_interactive)
    (let ((root (when-let* ((pr (project-current))) (project-root pr)))
          (probe (if-let* ((appdata (getenv "APPDATA")))
                     (concat ".," (expand-file-name "npm/node_modules" appdata))
                   ".")))
      (if (and root (file-exists-p (expand-file-name "angular.json" root)))
          (list "ngserver" "--stdio" "--tsProbeLocations" probe "--ngProbeLocations" probe)
        (if (functionp fallback) (funcall fallback) fallback)))))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `(typescript-ts-mode
                 . ,(ss/eglot-angular-or '("typescript-language-server" "--stdio"))))
  (add-to-list 'eglot-server-programs
               `(web-mode
                 . ,(ss/eglot-angular-or
                     (lambda ()
                       (if (string-match-p "\\.html\\'" (or buffer-file-name ""))
                           '("vscode-html-language-server" "--stdio")
                         '("rzls" "--logLevel" "Information")))))))

(use-package web-mode
  :mode ("\\.cshtml\\'" "\\.razor\\'" "\\.html\\'")
  :custom
  (web-mode-engines-alist '(("angular" . "\\.html\\'")))
  (web-mode-markup-indent-offset 2)
  (web-mode-code-indent-offset 4)
  (web-mode-css-indent-offset 2)
  (web-mode-enable-auto-pairing t)
  (web-mode-enable-css-colorization t)
  (web-mode-enable-current-element-highlight t))

;; Debugging: js-debug, unpacked from js-debug-dap-*.tar.gz into debug-adapters/.
;; Next.js dev server, reusing the adapter setup of the built-in js-debug-node.
(with-eval-after-load 'dape
  (let ((js (alist-get 'js-debug-node dape-configs)))
    (add-to-list 'dape-configs
                 `(nextjs-dev
                   modes (typescript-ts-mode tsx-ts-mode js-ts-mode)
                   ensure ,(plist-get js 'ensure)
                   command ,(plist-get js 'command)
                   command-args ,(plist-get js 'command-args)
                   port :autoport
                   :type "pwa-node"
                   :request "launch"
                   :cwd dape-cwd
                   :runtimeExecutable "npm"
                   :runtimeArgs ["run" "dev"]
                   :console "internalConsole"
                   :skipFiles ["<node_internals>/**"]))))

;;; ------------------------------------------------------------
;;; Astro
;;; ------------------------------------------------------------
;; Requires: npm i -g @astrojs/language-server

(add-to-list 'treesit-language-source-alist
             '(astro "https://github.com/virchau13/tree-sitter-astro"))

(use-package astro-ts-mode
  :straight (astro-ts-mode :type git :host github :repo "Sorixelle/astro-ts-mode" :branch "master")
  :mode "\\.astro\\'"
  :hook (astro-ts-mode . eglot-ensure))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(astro-ts-mode . ("astro-ls" "--stdio"
                                  :initializationOptions
                                  (:typescript (:tsdk "node_modules/typescript/lib"))))))

;;; ------------------------------------------------------------
;;; C# / .NET
;;; ------------------------------------------------------------
;; LSP: csharp-ls (dotnet tool install -g csharp-ls)
;; Debugger: netcoredbg (https://github.com/Samsung/netcoredbg/releases)

(add-hook 'csharp-mode-hook #'eglot-ensure)
(add-to-list 'auto-mode-alist '("\\.xaml\\'" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.csproj\\'" . nxml-mode))

(use-package sharper
  :commands sharper-main-transient
  :init
  (with-eval-after-load 'csharp-mode
    (keymap-set csharp-mode-map "C-c d" #'sharper-main-transient)
    (keymap-set csharp-ts-mode-map "C-c d" #'sharper-main-transient)))

(with-eval-after-load 'dape
  (add-to-list 'dape-configs
               '(netcoredbg-attach
                 modes (csharp-mode csharp-ts-mode)
                 ensure dape-ensure-command
                 command "netcoredbg"
                 command-args ["--interpreter=vscode"]
                 :type "coreclr"
                 :request "attach"
                 :processId (lambda () (read-number "Process ID: ")))))

;;; ------------------------------------------------------------
;;; Go
;;; ------------------------------------------------------------
;; LSP: gopls (go install golang.org/x/tools/gopls@latest)
;; Debugger: dlv (go install github.com/go-delve/delve/cmd/dlv@latest)
;; Formatting on save: apheleia (gofmt).

(defun ss/go-mode-setup ()
  "Configure buffer-local settings for Go source files."
  (setq-local tab-width 4
              indent-tabs-mode t
              compile-command "go build ./... 2>&1")
  (eglot-ensure))

(add-hook 'go-ts-mode-hook #'ss/go-mode-setup)

(with-eval-after-load 'eglot
  (setq-default eglot-workspace-configuration
                (plist-put (default-value 'eglot-workspace-configuration) :gopls
                           '(:usePlaceholders t
                             :staticcheck t
                             :analyses (:unusedparams t :shadow t :fieldalignment t)))))

(use-package gotest
  :bind (:map go-ts-mode-map
              ("C-c t t" . go-test-current-test)
              ("C-c t f" . go-test-current-file)
              ("C-c t p" . go-test-current-project)
              ("C-c t b" . go-test-current-benchmark)
              ("C-c t r" . go-run)))

;;; ------------------------------------------------------------
;;; Java
;;; ------------------------------------------------------------
;; LSP: jdtls on PATH (needs JDK 21+; on Windows the bin/ dir with jdtls.bat).
;; Debugger: com.microsoft.java.debug.plugin-*.jar (microsoft/java-debug)
;; in debug-adapters/java-debug/, loaded into jdtls as a bundle so dape's
;; built-in `jdtls' config works.

(add-hook 'java-ts-mode-hook #'eglot-ensure)

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               ;; Function contact: the jar is looked up on each server start.
               `(java-ts-mode
                 . ,(lambda (_interactive)
                      `("jdtls" :initializationOptions
                        (:bundles ,(vconcat
                                    (file-expand-wildcards
                                     (locate-user-emacs-file
                                      "debug-adapters/java-debug/com.microsoft.java.debug.plugin-*.jar")))))))))

;;; ------------------------------------------------------------
;;; YAML, Docker, Compose, .env
;;; ------------------------------------------------------------
;; Requires: npm i -g yaml-language-server dockerfile-language-server-nodejs
;;           @microsoft/compose-language-service

(define-derived-mode docker-compose-ts-mode yaml-ts-mode "Compose"
  "YAML mode for docker-compose files.")
(add-to-list 'auto-mode-alist
             '("\\(?:docker-\\)?compose[^/]*\\.ya?ml\\'" . docker-compose-ts-mode))
(add-to-list 'auto-mode-alist '("\\.dockerfile\\'" . dockerfile-ts-mode))
(add-to-list 'auto-mode-alist '("\\(?:Container\\|Docker\\)file\\.[^/]*\\'" . dockerfile-ts-mode))

(dolist (hook '(yaml-ts-mode-hook dockerfile-ts-mode-hook docker-compose-ts-mode-hook))
  (add-hook hook #'eglot-ensure))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(docker-compose-ts-mode . ("docker-compose-langserver" "--stdio")))
  (setq-default eglot-workspace-configuration
                (plist-put (default-value 'eglot-workspace-configuration) :yaml
                           '(:validate t
                             :hover t
                             :completion t
                             :format (:enable t)
                             :schemas
                             (:https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.31.0-standalone-strict/all.json
                              ["/*.k8s.yaml" "/*.k8s.yml" "/kubernetes/**/*.yaml" "/k8s/**/*.yaml" "/manifests/**/*.yaml"]
                              :https://json.schemastore.org/github-workflow.json
                              [".github/workflows/*.yaml" ".github/workflows/*.yml"]
                              :https://json.schemastore.org/github-action.json
                              ["action.yaml" "action.yml"]
                              :https://json.schemastore.org/chart.json
                              ["Chart.yaml" "Chart.yml"]
                              :https://json.schemastore.org/pre-commit-config.json
                              [".pre-commit-config.yaml"]
                              :https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json
                              [".gitlab-ci.yml" ".gitlab-ci.yaml"])))))

(use-package dotenv-mode
  :mode ("\\.env\\'" "\\.env\\..*\\'"))

;;; ------------------------------------------------------------
;;; Markdown, Mermaid
;;; ------------------------------------------------------------

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :custom
  (markdown-command "pandoc")
  (markdown-fontify-code-blocks-natively t))

(use-package mermaid-mode
  :mode ("\\.mmd\\'" . mermaid-mode)
  :custom
  (mermaid-mmdc-location "mmdc"))

;;; ------------------------------------------------------------
;;; Common Lisp
;;; ------------------------------------------------------------
;; SLY + SBCL (`sbcl' on PATH).  Completion via Corfu, navigation via
;; xref (M-. / M-,), structural editing via smartparens strict mode.

(use-package sly
  :mode ("\\.asd\\'" . lisp-mode)
  :custom
  (inferior-lisp-program "sbcl")
  (sly-net-coding-system 'utf-8-unix)
  :config
  ;; Show the REPL in a short window at the bottom of the frame
  (add-to-list 'display-buffer-alist
               '("\\*sly-mrepl for .*\\*"
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (window-height . 0.3))))

(defun ss/lisp-mode-setup ()
  "Configure buffer-local settings for Common Lisp source files."
  (setq-local indent-tabs-mode nil)
  (aggressive-indent-mode 1)
  (smartparens-strict-mode 1))

(add-hook 'lisp-mode-hook #'ss/lisp-mode-setup)
(add-hook 'sly-mrepl-mode-hook #'smartparens-strict-mode)
(add-hook 'sly-mrepl-mode-hook #'rainbow-delimiters-mode)

(with-eval-after-load 'smartparens
  (define-key smartparens-mode-map (kbd "C-)") #'sp-forward-slurp-sexp)
  (define-key smartparens-mode-map (kbd "C-}") #'sp-forward-barf-sexp)
  (define-key smartparens-mode-map (kbd "C-(") #'sp-backward-slurp-sexp)
  (define-key smartparens-mode-map (kbd "C-{") #'sp-backward-barf-sexp)
  (define-key smartparens-mode-map (kbd "C-c s") #'sp-splice-sexp)
  (define-key smartparens-mode-map (kbd "C-c r") #'sp-raise-sexp))

;;; ------------------------------------------------------------
;;; PowerShell
;;; ------------------------------------------------------------

(use-package powershell)

(provide 'init-lang)
;;; init-lang.el ends here
