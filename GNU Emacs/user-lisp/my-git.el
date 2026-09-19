;;; my-git.el --- Personal Git commands -*- lexical-binding: t; -*-

;;;###autoload
(defun my-git-status ()
  "Open Git status for the current project."
  (interactive)
  (require 'vc)
  (vc-dir default-directory))

(provide 'my-git)
