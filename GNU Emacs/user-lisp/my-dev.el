;;; my-dev.el --- Development helpers -*- lexical-binding: t; -*-

;;;###autoload
(defun my-dev-server ()
  "Run the project's development server."
  (interactive)
  (let ((default-directory
         (project-root (project-current t))))
    (compile "pnpm dev")))

(provide 'my-dev)
