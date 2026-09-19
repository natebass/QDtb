(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)

(add-to-list 'load-path (expand-file-name "user-lisp" user-emacs-directory))

(require 'my-editing)
(require 'my-project)
(require 'my-treesit)
(require 'my-test)

(require 'atomic-chrome)
(atomic-chrome-start-server)

(defun my/set-ghostty-title ()
  "Update Ghostty window title to show current buffer and relative path."
  (unless (display-graphic-p)
    (let* ((buf-name (buffer-name))
           (file-path (when (buffer-file-name)
                        (file-relative-name (buffer-file-name) default-directory))))
      (send-string-to-terminal
       (format "\e]2;%s - Emacs\a"
               (if file-path
                   (format "%s (%s)" buf-name file-path)
                 buf-name))))))

(add-hook 'buffer-list-update-hook #'my/set-ghostty-title)

;; Enable mouse support in terminal Emacs
(xterm-mouse-mode 1)

;; Enable pixel/line-based mouse wheel scrolling
(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))
