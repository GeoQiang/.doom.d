;;; org-pomodoro conf
(global-set-key (kbd "C-c o") 'org-pomodoro)

(add-hook 'org-pomodoro-started-hook
  (lambda ()
    (org-notify "A new pomodoro has started, stay focused !!!")))
(add-hook 'org-pomodoro-finished-hook
  (lambda ()
    (org-notify "A pomodoro is finished, take a break !!!")))
(add-hook 'org-pomodoro-short-break-finished-hook
  (lambda ()
    (org-notify "A short break done, ready a new pomodoro !!!")))
(add-hook 'org-pomodoro-long-break-finished-hook
  (lambda ()
    (org-notify "A long break done, ready a new pomodoro !!!")))
(setq org-pomodoro-length 52)
(setq org-pomodoro-short-break-length 17)
(setq org-pomodoro-long-break-length 17)

;;; org-refile conf

(setq org-refile-use-outline-path 'file)
(setq org-outline-path-complete-in-steps nil)
(setq org-refile-targets '((org-agenda-files :level . 0)
                           ("~/Dropbox/Todo/someday.org" :level . 0)
                           ("~/Dropbox/Todo/trash.org" :level . 0)
                           ("~/Dropbox/Todo/archive.org" :maxlevel . 4)))

;;; beautifying

(setq org-agenda-span 1)
(setq org-ellipsis " ▾ ")
(setq org-superstar-headline-bullets-list '(" " " " " " " " " " " "))
(setq
  ;; hide * before headings
  org-hide-leading-stars t
  ;; show actually italicized text instead of /italicized text/
  org-hide-emphasis-markers t)

(setq org-log-done 'time)

(setq org-todo-keywords '((sequence "TODO" "PROGRESS" "|" "DONE" "ABORT")))

(setq org-todo-keyword-faces
  '(("TODO" . "#ab5183")
    ("PROGRESS" . "#4d96c6")
    ("ABORT" . "#f78c2c")
    ("DONE" . "#d92947")))

(setq hl-todo-keyword-faces
  '(("TODO" . "#ab5183")
    ("PROGRESS" . "#4d96c6")
    ("ABORT" . "#f78c2c")
    ("DONE" . "#d92947")))

;; modify the image size
(setq org-image-actual-width (/ (display-pixel-width) 3))

;; style of font and headline

(custom-set-faces
  '(fixed-pitch ((t ( :family "Fira Code Retina" :height 110))))
  '(variable-pitch ((t (:family "ETBembo" :height 180))))
  '(org-table ((t (:inherit fixed-pitch :foreground "#83a598"))))
  '(org-level-1 ((t (:inherit outline-1 :height 1.2  :foreground "#black"))))
  '(org-level-2 ((t (:inherit outline-2 :height 1.2  :foreground "#black"))))
  '(org-level-3 ((t (:inherit outline-3 :height 1.2  :foreground "#black"))))
  '(org-level-4 ((t (:inherit outline-4 :height 1.2  :foreground "#black"))))
  '(org-level-5 ((t (:inherit outline-5 :height 1.2  :foreground "#black"))))
  '(org-level-6 ((t (:inherit outline-6 :height 1.2  :foreground "#black"))))
  '(org-level-7 ((t (:inherit outline-7 :height 1.2  :foreground "#black"))))
  '(org-level-8 ((t (:inherit outline-8 :height 1.2  :foreground "#black")))))

;;; hook conf

(add-hook 'org-mode-hook #'variable-pitch-mode)
(add-hook 'org-mode-hook #'writeroom-mode)
(add-hook 'org-mode-hook #'hide-mode-line-mode)
(add-hook 'org-mode-hook 'turn-on-auto-fill)

;; automatic line wrapping
(add-hook 'org-mode-hook (lambda() (setq truncate-lines nil)))

(provide 'init-org)
