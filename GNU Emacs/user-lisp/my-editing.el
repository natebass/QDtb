
;;; my-editing.el --- Personal editing commands -*- lexical-binding: t; -*-

;;;###autoload
(defun my-duplicate-line ()
  "Duplicate the current line."
  (interactive)
  (let ((column (- (point) (line-beginning-position))))
    (save-excursion
      (end-of-line)
      (newline)
      (yank))
    (forward-line 1)
    (move-to-column column)))

;;;###autoload
(defun my-open-init-file ()
  "Open the user's Emacs configuration."
  (interactive)
  (find-file user-init-file))

(provide 'my-editing)
