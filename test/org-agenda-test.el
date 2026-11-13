;;; org-agenda-test.el --- Tests for the agenda helpers -*- lexical-binding: t -*-

;; Run: emacs -Q --batch -l test/org-agenda-test.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'org-agenda)

;; Load only the helper functions: the use-package forms need straight.el
(defmacro use-package (&rest _) nil)
(load (expand-file-name "../modules/init-org.el"
                        (file-name-directory (or load-file-name buffer-file-name)))
      nil 'nomessage)

(ert-deftest org-agenda-empty-blocks-are-hidden ()
  "A block without entries disappears, wherever it sits; filled blocks stay."
  (let* ((file (make-temp-file "agenda-" nil ".org" "* NEXT pick me\n* TODO later\n"))
         (org-agenda-files (list file))
         (org-todo-keywords '((sequence "TODO" "NEXT" "WAITING" "|" "DONE")))
         (org-agenda-block-separator ?─)
         (org-agenda-finalize-hook '(ss/org-agenda-hide-empty-blocks))
         (org-agenda-custom-commands
          '(("x" "test"
             ((todo "NEXT" ((org-agenda-overriding-header "Filled first")))
              (todo "WAITING" ((org-agenda-overriding-header "Empty middle")))
              (todo "TODO" ((org-agenda-overriding-header "Filled last")))
              (todo "WAITING" ((org-agenda-overriding-header "Empty end"))))))))
    (unwind-protect
        (progn
          (org-agenda nil "x")
          (let ((text (buffer-string)))
            (should (string-match-p "Filled first" text))
            (should (string-match-p "pick me" text))
            (should (string-match-p "Filled last" text))
            (should (string-match-p "later" text))
            (should-not (string-match-p "Empty" text))))
      (delete-file file))))

(provide 'org-agenda-test)
;;; org-agenda-test.el ends here
