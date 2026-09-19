;;; my-commands.el --- Personal command utilities -*- lexical-binding: t; -*-

;;;###autoload
(defun my-command-palette ()
  "Interactively select and execute an Emacs command."
  (interactive)
  (call-interactively
   (read-extended-command-prompt
    nil nil nil "Command: ")))

(provide 'my-commands)
