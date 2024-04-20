;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

(defconst my-emacs-d (file-name-as-directory "~/.doom.d/")
   "Directory of emacs.d.")
(defconst my-lisp-dir (concat my-emacs-d "lisp")
   "Directory of personal configuration.")
(add-to-list 'load-path (expand-file-name my-lisp-dir))
;; (add-to-list 'default-frame-alist '(fullscreen . fullboth)) 

(set-face-attribute 'default nil :height 140)

(add-hook 'MAJOR-MODE-local-vars-hook #'lsp!)

;;调节鼠标滚动
(setq mouse-wheel-scroll-amount '(2 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)

(global-set-key (kbd "C-c w") #'writeroom-mode)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c r") #'org-capture)
(global-set-key [f8] 'neotree-toggle)
(global-set-key (kbd "C-s") 'consult-line)

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com"
      )

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;     doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(after! org
     
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
(setq org-agenda-span 5)
(setq org-ellipsis " ▾ ")
(setq org-superstar-headline-bullets-list '(" " " " " " " " " " " "))
(setq
  ;; hide * before headings
  org-hide-leading-stars t
  ;; show actually italicized text instead of /italicized text/
  org-hide-emphasis-markers t)

(setq org-log-done 'time)

(setq org-capture-templates
      '(("t" "thought" entry (file+headline "~/Dropbox/Todo/inbox.org")
         "* %?\n  %i\n %U"
         :empty-lines 1)
         ("j" "Journal" entry (file+datetree "~/Dropbox/notes/journal.org")
         "* %?\nEntered on %U\n %i\n %a")))

(setq! org-todo-keywords '((sequence "TODO" "PROGRESS" "|" "DONE" "ABORT")))

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
;; (add-hook 'org-mode-hook #'writeroom-mode)
;; (add-hook 'org-mode-hook #'hide-mode-line-mode)
(add-hook 'org-mode-hook 'turn-on-auto-fill)


(setq org-roam-directory "~/roam")
(use-package! websocket
    :after org-roam)

(use-package! org-roam-ui
    :after org-roam ;; or :after org
;;         normally we'd recommend hooking orui after org-roam, but since org-roam does not have
;;         a hookable mode anymore, you're advised to pick something yourself
;;         if you don't care about startup time, use
;;  :hook (after-init . org-roam-ui-mode)
    :config
    (setq org-roam-ui-sync-theme t
          org-roam-ui-follow t
          org-roam-ui-update-on-save t
          org-roam-ui-open-on-start t))


;; automatic line wrapping
(add-hook 'org-mode-hook (lambda() (setq truncate-lines nil)))
)

;; neotree conf
(after! neotree
(setq-default neo-show-hidden-files nil)
(setq projectile-switch-project-action 'neotree-projectile-action)
(setq neo-smart-open t)
)

(after! elfeed
(elfeed-goodies/setup)
(setq elfeed-goodies/entry-pane-size 0.6)
(evil-define-key 'normal elfeed-show-mode-map
	(kbd "J") 'elfeed-goodies/split-show-next
	(kbd "K") 'elfeed-goodies/split-show-prev)
(evil-define-key 'normal elfeed-search-mode-map
	(kbd "J") 'elfeed-goodies/split-show-next
	(kbd "K") 'elfeed-goodies/split-show-prev)	
(setq-default elfeed-feeds (quote
			(("https://linux.cn/rss.xml" linux)
			("https://rsshub.app/cnki/journals/TSQB" 图书情报工作)
			("https://rsshub.app/cnki/journals/QBXB" 情报学报)
			)
			))
)

