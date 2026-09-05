;;; literate/config.el -*- lexical-binding: t; -*-

(defconst my-lisp-dir (expand-file-name "lisp" doom-user-dir)
  "Directory of personal configuration.")
(add-to-list 'load-path my-lisp-dir)

(when (memq window-system '(mac ns x))
  (require 'exec-path-from-shell)
  (setq exec-path-from-shell-variables '("PATH"))
  (exec-path-from-shell-initialize))

(set-face-attribute 'default nil :height 140)

(add-hook 'MAJOR-MODE-local-vars-hook #'lsp!)

;; 调节鼠标滚动
(setq mouse-wheel-scroll-amount '(2 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)

(global-set-key (kbd "C-c w") #'writeroom-mode)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c r") #'org-capture)
(global-set-key [f8] 'neotree-toggle)
(global-set-key (kbd "C-s") 'consult-line)

(setq user-full-name "John Doe"
      user-mail-address "john@doe.com"
      )

(setq doom-theme 'doom-gruvbox-light)

(setq display-line-numbers-type t)

(setq org-directory "~/Dropbox/org-literate/")

;; 先清空可能存在的错误缓存
(setq-default org-agenda-files nil)

(with-eval-after-load 'flyspell
  (setq ispell-dictionary "en_US")) ;; 或者 "american"

(after! org
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
  ;; 终止番茄时把已经计时的部分记为 clock-out 而不是整段作废，
  ;; 这样 Mac app 的"暂停=终止"才不会把这段专注时间统计丢了。
  (setq org-pomodoro-keep-killed-pomodoro-time t))

(after! org
  (require 'json)

  (defun my/pomodoro-bridge--todo-p ()
    (let ((state (org-get-todo-state)))
      (and state (member state org-not-done-keywords))))

  (defun my/pomodoro-bridge-list-todos ()
    "JSON 数组：org-agenda-files 里所有未完成 TODO 的 file/pos/heading/path。"
    (let (entries)
      (dolist (file (org-agenda-files))
        (when (file-exists-p file)
          (with-current-buffer (find-file-noselect file)
            (org-with-wide-buffer
             (org-map-entries
              (lambda ()
                (when (my/pomodoro-bridge--todo-p)
                  (push (list (cons "file" file)
                              (cons "pos" (point))
                              (cons "heading" (org-get-heading t t t t))
                              (cons "path" (mapconcat #'identity
                                                       (org-get-outline-path)
                                                       " > ")))
                        entries)))
              nil 'file)))))
      (json-encode (nreverse entries))))

  (defun my/pomodoro-bridge-clock-in (file pos heading)
    "在 FILE:POS（校验标题文本等于 HEADING）处 clock-in。只记账，不涉及
org-pomodoro 自己的计时器——Mac app 才是计时权威。"
    (condition-case err
        (progn
          (with-current-buffer (find-file-noselect file)
            (widen)
            (goto-char (min (max pos (point-min)) (point-max)))
            (beginning-of-line)
            (unless (and (looking-at org-complex-heading-regexp)
                         (equal (org-get-heading t t t t) heading))
              (goto-char (point-min))
              (unless (re-search-forward
                       (concat "^\\*+[ \t]+.*" (regexp-quote heading)) nil t)
                (error "找不到标题：%s" heading))
              (beginning-of-line))
            (when (org-clocking-p) (org-clock-out))
            (org-clock-in)
            (save-buffer))
          (json-encode (list (cons "ok" t))))
      (error (json-encode (list (cons "ok" :json-false)
                                 (cons "error" (error-message-string err)))))))

  (defun my/pomodoro-bridge-clock-out ()
    "结束当前 clock（Mac app 那边的专注段走完，或用户点了终止）。"
    (condition-case err
        (let ((buf (and (org-clocking-p) (marker-buffer org-clock-marker))))
          (when (org-clocking-p) (org-clock-out))
          (when buf (with-current-buffer buf (save-buffer)))
          (json-encode (list (cons "ok" t))))
      (error (json-encode (list (cons "ok" :json-false)
                                 (cons "error" (error-message-string err)))))))

  (defun my/pomodoro-bridge-stats ()
    "按标题统计今天/近 7 天的 clock 分钟数，JSON 数组。"
    (let* ((today-start (apply #'encode-time 0 0 0 (nthcdr 3 (decode-time))))
           (week-start (time-subtract today-start (* 6 86400)))
           (now (current-time))
           results)
      (dolist (file (org-agenda-files))
        (when (file-exists-p file)
          (with-current-buffer (find-file-noselect file)
            (org-with-wide-buffer
             (org-clock-sum today-start now nil :clock-today)
             (org-clock-sum week-start now nil :clock-week)
             (org-map-entries
              (lambda ()
                (when (my/pomodoro-bridge--todo-p)
                  (push (list (cons "heading" (org-get-heading t t t t))
                              (cons "path" (mapconcat #'identity
                                                       (org-get-outline-path)
                                                       " > "))
                              (cons "todayMinutes"
                                    (or (get-text-property (point) :clock-today) 0))
                              (cons "weekMinutes"
                                    (or (get-text-property (point) :clock-week) 0)))
                        results)))
              nil 'file)))))
      (json-encode (nreverse results)))))

(after! org
  (setq org-refile-use-outline-path 'file)
  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-targets '((org-agenda-files :level . 0)
                             ("~/Dropbox/GTD/someday.org" :level . 0)
                             ("~/Dropbox/GTD/archive.org" :maxlevel . 4)))
  (setq org-agenda-files
        (list (expand-file-name "~/Dropbox/GTD/project.org"))))

(after! org
  (setq org-agenda-span 5)
  (setq org-startup-indented t              ; 标题按层级缩进
        org-ellipsis " ▾ "                  ; 折叠符号
        org-pretty-entities t               ; \alpha → α
        org-hide-emphasis-markers t         ; /斜体/ 直接显示为斜体
        org-agenda-block-separator ""       ; agenda 分块之间去掉分隔线
        org-fontify-whole-heading-line t
        org-fontify-done-headline t
        org-fontify-quote-and-verse-blocks t)
  ;; 顶部留白：空白 header-line（改 header-line face 高度可调留白大小）
  (setq header-line-format " ")
  ;; 全框留白：连 mode-line 一起留出内边距（像素，可调）
  (add-to-list 'default-frame-alist '(internal-border-width . 2))
  (when (frame-live-p (selected-frame))
    (set-frame-parameter (selected-frame) 'internal-border-width 2))
  (setq org-log-done 'time))

(after! org
  (setq org-modern-star nil
        org-modern-hide-stars nil   ; org-modern 自己的隐藏星号开关，一起关掉
        org-hide-leading-stars t
        org-modern-todo nil))      ; TODO 关键字不要色块徽章，用已有的纯文字变色

(after! org
  (setq org-capture-templates
        '(("t" "thought" entry (file "~/Dropbox/GTD/inbox.org")
           "* To Do %?\n  %i\n %U"
           :empty-lines 1)
          ("j" "Journal" entry (file+datetree "~/Dropbox/notes/journal.org")
           "* %?\nEntered on %U\n %i\n %a"))))

(after! org
  (setq! org-todo-keywords '((sequence "To Do" "In Progress" "Delegate" "|" "Completed" "Abort")))

  (setq org-todo-keyword-faces
        '(("To Do" . "#ab5183")
          ("In Progress" . "#4d96c6")
          ("Delegate" . "#8a6dc9")
          ("Completed" . "#f78c2c")
          ("Abort" . "#d92947")))

  (setq hl-todo-keyword-faces
        '(("To Do" . "#ab5183")
          ("In Progress" . "#4d96c6")
          ("Delegate" . "#8a6dc9")
          ("Completed" . "#f78c2c")
          ("Abort" . "#d92947"))))

(after! org
  ;; modify the image size
  (setq org-image-actual-width (/ (display-pixel-width) 3)))

(require 'cl-lib)

;; 字体选择：优先教程字体，未安装则回退 macOS 自带字体
(defun my/first-available-font (candidates fallback)
  "Return the first installed font family in CANDIDATES, else FALLBACK."
  (or (cl-loop for family in candidates
               if (member family (font-family-list))
               return family)
      fallback))

(defconst my/org-serif-font
  (my/first-available-font '("ETBookOT" "EtBembo" "Iowan Old Style" "Charter" "Georgia")
                           "Georgia"))

(defconst my/org-mono-font
  (my/first-available-font '("Source Code Pro" "Menlo")
                           "Menlo"))

(defconst my/org-serif-mono-font
  (my/first-available-font '("Verily Serif Mono")
                           my/org-mono-font))

;; 中文字体：配合 ETBook 用霞鹜文楷（楷体，跟 ETBook 的人文衬线气质更搭，
;; 比宋体/黑体更合适）。ETBook 本身没有中文字形，靠 set-fontset-font
;; 把中日韩范围单独指过去，不影响西文走 my/org-serif-font。
(defconst my/org-cjk-font
  (my/first-available-font '("LXGW WenKai" "PingFang SC" "STKaiti")
                           "PingFang SC"))

;; 全局生效：所有 buffer 里的中日韩字符都走这个字体，不止 org
(set-fontset-font t 'han (font-spec :family my/org-cjk-font) nil 'prepend)

(defun my/apply-org-rices ()
  "Apply Tufte-style Org faces (lepisma's Ricing up Org Mode)."
  (when (featurep 'org)
    (require 'org-faces)
    (require 'org-indent)
    (let ((ink "#1c1e1f")    ; 墨色：正文
          (muted "#8a8a8a")  ; 弱化：日期、特殊行、block 首尾
          (code "#525254"))  ; 代码前景
    ;; 基础字体
    (set-face-attribute 'variable-pitch nil
                        :family my/org-serif-font :height 1.3 :foreground ink)
    (set-face-attribute 'fixed-pitch nil
                        :family my/org-mono-font :height 1.0)
    ;; 文档标题与信息
    (set-face-attribute 'org-document-title nil
                        :inherit nil :family my/org-serif-font
                        :height 1.8 :weight 'normal :foreground muted
                        :underline nil)
    (set-face-attribute 'org-document-info nil
                        :family my/org-serif-font :height 1.2 :slant 'italic)
    ;; 标题：每级一个颜色（星号跟标题正文共用同一个 face，一起上色），
    ;; 层级缩放/斜体照旧保留
    (set-face-attribute 'org-level-1 nil :inherit nil :family my/org-serif-font
                        :height 1.6 :foreground "#1c1e1f")
    (set-face-attribute 'org-level-2 nil :inherit nil :family my/org-serif-font
                        :height 1.4 :slant 'italic :foreground "#ab5183")
    (set-face-attribute 'org-level-3 nil :inherit nil :family my/org-serif-font
                        :height 1.25 :slant 'italic :foreground "#4d96c6")
    (set-face-attribute 'org-level-4 nil :inherit nil :family my/org-serif-font
                        :height 1.1 :slant 'italic :foreground "#8a6dc9")
    (set-face-attribute 'org-level-5 nil :inherit nil :family my/org-serif-font
                        :height 1.0 :weight 'bold :foreground "#f78c2c")
    (set-face-attribute 'org-level-6 nil :inherit nil :family my/org-serif-font
                        :height 1.0 :weight 'bold :foreground "#3a6b35")
    (set-face-attribute 'org-level-7 nil :inherit nil :family my/org-serif-font
                        :height 1.0 :weight 'bold :foreground "#6f4e37")
    (set-face-attribute 'org-level-8 nil :inherit nil :family my/org-serif-font
                        :height 1.0 :weight 'bold :foreground "#45707a")
    ;; 完成标题加删除线
    (set-face-attribute 'org-headline-done nil :strike-through t)
    ;; 链接与弱化文字
    (set-face-attribute 'org-link nil :underline nil :foreground "#458588")
    (set-face-attribute 'org-special-keyword nil :height 0.9 :foreground muted)
    (set-face-attribute 'org-meta-line nil :height 0.9 :foreground muted)
    (set-face-attribute 'org-date nil :family my/org-mono-font :height 0.8)
    (set-face-attribute 'org-tag nil :foreground "#727280")
    ;; 表格 / 代码 / 引用块
    (set-face-attribute 'org-table nil :family my/org-serif-mono-font :height 0.9)
    (set-face-attribute 'org-code nil :family my/org-serif-mono-font
                        :foreground code :height 0.9)
    (set-face-attribute 'org-verbatim nil :family my/org-serif-mono-font
                        :foreground code :height 0.9)
    (set-face-attribute 'org-block nil :family my/org-mono-font)
    (set-face-attribute 'org-block-begin-line nil :family my/org-mono-font
                        :height 0.8 :foreground muted)
    (set-face-attribute 'org-block-end-line nil :family my/org-mono-font
                        :height 0.8 :foreground muted)
    ;; 关键：缩进（星号）用等宽，保证变宽正文下标题内容对齐
    (set-face-attribute 'org-indent nil :inherit '(org-hide fixed-pitch))
    (set-face-attribute 'org-ellipsis nil :underline nil :foreground muted))))

;; 在 org 加载后再应用；主题切换时若 org 已加载则重新应用
(after! org (my/apply-org-rices))
(add-hook 'doom-load-theme-hook #'my/apply-org-rices)

;; 左右留白（Tufte 风格需要一点边距）
(defun my/org-side-padding ()
  "给当前 org buffer 左右各加 2 个字符宽的留白。"
  (setq left-margin-width 2
        right-margin-width 2)
  (set-window-buffer nil (current-buffer)))

(after! org
  (add-hook 'org-mode-hook #'variable-pitch-mode) ; 正文衬线
  (add-hook 'org-mode-hook #'org-modern-mode)     ; 标题星号（已设为空格）
  (add-hook 'org-mode-hook #'turn-on-auto-fill)   ; 自动 fill 换行
  (add-hook 'org-mode-hook #'my/org-side-padding) ; 左右留白
  (add-hook 'org-mode-hook #'org-pretty-table-mode) ; 漂亮表格边框
  ;; 行距：让衬线正文更有呼吸感
  (add-hook 'org-mode-hook (lambda () (setq-local line-spacing 0.1)))
  ;; 自动软换行而非截断
  (add-hook 'org-mode-hook (lambda () (setq-local truncate-lines nil)))
  ;; 行高不同时高亮当前行会很丑，按需启用：
  ;; (add-hook 'org-mode-hook (lambda () (hl-line-mode -1)))
  ;; 更彻底的无打扰模式（可选）：
  ;; (add-hook 'org-mode-hook #'writeroom-mode)
  )

(after! org
  (setq org-roam-directory "~/Dropbox/roam")
  (use-package! websocket
      :after org-roam)

  (use-package! org-roam-ui
      :after org-roam
      ;; normally we'd recommend hooking orui after org-roam, but since
      ;; org-roam does not have a hookable mode anymore, you're advised to
      ;; pick something yourself.  if you don't care about startup time, use
      ;; :hook (after-init . org-roam-ui-mode)
      :config
      (setq org-roam-ui-sync-theme t
            org-roam-ui-follow t
            org-roam-ui-update-on-save t
            org-roam-ui-open-on-start t)))

(after! neotree
  (setq-default neo-show-hidden-files nil)
  (setq projectile-switch-project-action 'neotree-projectile-action)
  (setq neo-smart-open t))

(use-package! claude-code
  :init
  (setq claude-code-terminal-backend 'vterm)
  :bind-keymap ("C-c c" . claude-code-command-map)
  :config (claude-code-mode))

(load! "dsh" (expand-file-name "lisp" doom-user-dir))

(load! "cch" (expand-file-name "lisp" doom-user-dir))

(use-package! gptel
  :commands (gptel gptel-send gptel-menu gptel-rewrite)
  :init
  (setq gptel-default-mode 'org-mode)
  :config
  (setq gptel-backend
        (gptel-make-anthropic "Claude"
          :stream t
          :key (lambda ()
                 (auth-source-pick-first-password
                  :host "api.anthropic.com" :user "gptel"))
          :models '(claude-sonnet-5 claude-opus-5 claude-haiku-4-5-20251001)))
  (setq gptel-model 'claude-sonnet-5)

  (gptel-make-openai "DeepSeek"
    :host "api.deepseek.com"
    :endpoint "/chat/completions"
    :stream t
    :key (lambda ()
           (auth-source-pick-first-password
            :host "api.deepseek.com" :user "gptel"))
    :models '(deepseek-chat deepseek-reasoner))
  :bind (("C-c g g" . gptel)
         ("C-c g s" . gptel-send)
         ("C-c g m" . gptel-menu)
         ("C-c g r" . gptel-rewrite)))

(when (fboundp 'map!)
  (map! :leader
        :desc "gptel: 打开聊天窗口" "g g" #'gptel
        :desc "gptel: 发送/续聊"    "g s" #'gptel-send
        :desc "gptel: 命令菜单"     "g m" #'gptel-menu
        :desc "gptel: 改写选区"     "g r" #'gptel-rewrite))

(after! elfeed
  (defun +rss-cnki-stabilize-id (type _item entry)
    "稳定知网 RSS 条目的 id，避免链接里的随机追踪 token 导致刷新出重复文章。"
    (when (and (eq type :rss)
               (string-match-p "rss\\.cnki\\.net" (elfeed-entry-feed-id entry)))
      (setf (elfeed-entry-id entry)
            (cons (car (elfeed-entry-id entry))
                  (elfeed-entry-title entry)))))
  (add-hook 'elfeed-new-entry-parse-hook #'+rss-cnki-stabilize-id))

(when (fboundp 'map!)
  (map! :leader
        :desc "elfeed: 打开期刊订阅阅读器" "o r" #'=rss))
