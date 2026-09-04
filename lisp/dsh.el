;;; dsh.el --- DeepSeek Harness (dsh) integration for Doom Emacs -*- lexical-binding: t; -*-

;; Commands for talking to the dsh CLI's single-shot "headless" profile from
;; Emacs. Every call runs `dsh --profile headless "<prompt>"` and returns the
;; model's final answer.
;;
;; Requirements:
;;   - the `dsh' CLI on PATH (Homebrew: /opt/homebrew/bin/dsh); the executable
;;     is auto-detected, or set `dsh-executable' explicitly.
;;   - a configured ~/.dsh with DeepSeek credentials (dsh finds them itself).
;;
;; Keybindings installed when this file is loaded:
;;   C-c d a  /  SPC d a  — ask a question asynchronously (answer into *dsh*)
;;   C-c d r  /  SPC d r  — use the selected region as the question
;;   C-c d i  /  SPC d i  — ask synchronously and insert the answer at point
;;   C-c d I  /  SPC d I  — region variant of the above
;;
;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defgroup dsh nil "DeepSeek Harness (dsh) integration."
  :group 'external
  :prefix "dsh-")

(defcustom dsh-executable nil
  "Path to the `dsh' CLI. When nil it is searched on `exec-path', then in the
usual Homebrew locations."
  :type '(choice (const :tag "auto-detect" nil) string)
  :group 'dsh)

(defcustom dsh-profile "headless"
  "dsh profile used for single-shot questions."
  :type 'string
  :group 'dsh)

(defun dsh--exe ()
  "Return the dsh executable path; signal a helpful error when missing."
  (or dsh-executable
      (executable-find "dsh")
      (cl-find-if #'file-executable-p
                  '("/opt/homebrew/bin/dsh"
                    "/usr/local/bin/dsh"
                    "/opt/local/bin/dsh"))
      (user-error "找不到 dsh：请安装 dsh CLI，或在 dsh-executable 里设置路径")))

(defun dsh--command (prompt)
  "Build the process command vector for PROMPT."
  (list (dsh--exe) "--profile" dsh-profile prompt))

(defun dsh--ask-sync (prompt)
  "Run one headless dsh question synchronously and return its answer text."
  (let ((default-directory (if (buffer-file-name)
                               (file-name-directory (buffer-file-name))
                             default-directory)))
    (string-trim
     (shell-command-to-string
      (mapconcat #'shell-quote-argument (dsh--command prompt) " ")))))

(defun dsh--ask-async (prompt)
  "Run one headless dsh question asynchronously into the *dsh* buffer."
  (let ((buf (get-buffer-create "*dsh*"))
        (cmd (dsh--command prompt)))
    (with-current-buffer buf
      (special-mode)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format ";; dsh> %s\n\n" prompt))
        (goto-char (point-max))))
    (display-buffer buf)
    (make-process
     :name "dsh"
     :buffer buf
     :stderr buf
     :command cmd
     :sentinel (lambda (proc _event)
                 (when (memq (process-status proc) '(exit signal))
                   (when (buffer-live-p (process-buffer proc))
                     (with-current-buffer (process-buffer proc)
                       (let ((inhibit-read-only t))
                         (goto-char (point-max))
                         (insert (format "\n;; [dsh 完成 · exit %s]\n"
                                         (process-exit-status proc)))))))))))

;;;###autoload
(defun dsh-ask (prompt)
  "Ask PROMPT asynchronously; the answer lands in the *dsh* buffer."
  (interactive "s[dsh] 问题: ")
  (dsh--ask-async prompt))

;;;###autoload
(defun dsh-ask-region (beg end)
  "Ask dsh about the selected region (asynchronously, answer to *dsh*)."
  (interactive "r")
  (let ((text (string-trim (buffer-substring-no-properties beg end))))
    (if (string-empty-p text)
        (user-error "选中区域是空的")
      (dsh--ask-async text))))

;;;###autoload
(defun dsh-ask-insert (prompt)
  "Ask PROMPT synchronously and insert the answer at point."
  (interactive "s[dsh] 问题: ")
  (let ((answer (dsh--ask-sync prompt)))
    (unless (string-empty-p answer)
      (insert answer)
      (unless (string-suffix-p "\n" answer) (insert "\n")))))

;;;###autoload
(defun dsh-ask-region-insert (beg end)
  "Ask dsh about the selected region and insert the answer at point."
  (interactive "r")
  (let ((text (string-trim (buffer-substring-no-properties beg end))))
    (if (string-empty-p text)
        (user-error "选中区域是空的")
      (dsh-ask-insert text))))

;; ── keybindings ─────────────────────────────────────────────────────────────

;; Global (works everywhere, including non-evil sessions)
(global-set-key (kbd "C-c d a") #'dsh-ask)
(global-set-key (kbd "C-c d r") #'dsh-ask-region)
(global-set-key (kbd "C-c d i") #'dsh-ask-insert)
(global-set-key (kbd "C-c d I") #'dsh-ask-region-insert)

;; Evil leader (SPC d a / SPC d r / SPC d i / SPC d I)
(when (fboundp 'map!)
  (map! :leader
        :desc "dsh: 异步提问"      "d a" #'dsh-ask
        :desc "dsh: 提问选中区域"  "d r" #'dsh-ask-region
        :desc "dsh: 提问并插入"    "d i" #'dsh-ask-insert
        :desc "dsh: 区域并插入"    "d I" #'dsh-ask-region-insert))

(provide 'dsh)
;;; dsh.el ends here
