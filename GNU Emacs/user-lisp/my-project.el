;;; my-project.el --- Project commands -*- lexical-binding: t; -*-

;;;###autoload
(defun my-project-find-config ()
  "Open the project configuration file."
  (interactive)
  (let* ((project (project-current t))
         (root (project-root project))
         (file (expand-file-name "README.md" root)))
    (find-file file)))

;;;###autoload
(defun my-project-shell ()
  "Open a shell at the current project root."
  (interactive)
  (project-shell))

(provide 'my-project)
