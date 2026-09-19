;;; my-treesit.el --- Tree-sitter configuration -*- lexical-binding: t; -*-

;;;###autoload
(defun my-enable-treesit ()
  "Prefer Tree-sitter major modes when available."
  (when (treesit-available-p)
    (dolist (mapping
             '((js-mode . js-ts-mode)
               (typescript-mode . typescript-ts-mode)
               (json-mode . json-ts-mode)
               (css-mode . css-ts-mode)
               (html-mode . html-ts-mode)))
      (when (fboundp (cdr mapping))
        (add-to-list 'major-mode-remap-alist mapping)))))

(my-enable-treesit)

(provide 'my-treesit)
