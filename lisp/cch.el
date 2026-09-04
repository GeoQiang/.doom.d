;;; cch.el --- Claude Code Headless (cch) integration for Doom Emacs -*- lexical-binding: t; -*-

;; Commands for talking to the `claude' CLI's single-shot "print" mode
;; (`claude -p') from Emacs, the same way dsh.el talks to the `dsh' CLI.
;; Every call runs `claude -p "<prompt>"' and returns the model's final
;; answer as plain text.
;;
;; Requirements:
;;   - the `claude' CLI on PATH (Homebrew: /opt/homebrew/bin/claude); the
;;     executable is auto-detected, or set `cch-executable' explicitly.
;;   - `claude' already logged in (run `claude' interactively once).
;;
;; Keybindings installed when this file is loaded:
;;   C-c q a  — ask a question asynchronously (answer into *cch*)
;;   C-c q r  — use the selected region as the question
;;   C-c q i  — ask synchronously and insert the answer at point
;;   C-c q I  — region variant of the above
;;
;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defgroup cch nil "Claude Code Headless (cch) integration."
  :group 'external
  :prefix "cch-")

(defcustom cch-executable nil
  "Path to the `claude' CLI. When nil it is searched on `exec-path', then in
the usual Homebrew locations."
  :type '(choice (const :tag "auto-detect" nil) string)
  :group 'cch)

(defun cch--exe ()
  "Return the claude executable path; signal a helpful error when missing."
  (or cch-executable
      (executable-find "claude")
      (cl-find-if #'file-executable-p
                  '("/opt/homebrew/bin/claude"
                    "/usr/local/bin/claude"
                    "/opt/local/bin/claude"))
      (user-error "找不到 claude：请安装 Claude Code CLI，或在 cch-executable 里设置路径")))

(defun cch--command (prompt)
  "Build the process command vector for PROMPT."
  (list (cch--exe) "-p" prompt))

(defun cch--ask-sync (prompt)
  "Run one headless claude question synchronously and return its answer text."
  (let ((default-directory (if (buffer-file-name)
                               (file-name-directory (buffer-file-name))
                             default-directory)))
    (string-trim
     (shell-command-to-string
      (mapconcat #'shell-quote-argument (cch--command prompt) " ")))))

(defun cch--ask-async (prompt)
  "Run one headless claude question asynchronously into the *cch* buffer."
  (let ((buf (get-buffer-create "*cch*"))
        (cmd (cch--command prompt)))
    (with-current-buffer buf
      (special-mode)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format ";; claude> %s\n\n" prompt))
        (goto-char (point-max))))
    (display-buffer buf)
    (make-process
     :name "cch"
     :buffer buf
     :stderr buf
     :command cmd
     :sentinel (lambda (proc _event)
                 (when (memq (process-status proc) '(exit signal))
                   (when (buffer-live-p (process-buffer proc))
                     (with-current-buffer (process-buffer proc)
                       (let ((inhibit-read-only t))
                         (goto-char (point-max))
                         (insert (format "\n;; [claude 完成 · exit %s]\n"
                                         (process-exit-status proc)))))))))))

;;;###autoload
(defun cch-ask (prompt)
  "Ask PROMPT asynchronously; the answer lands in the *cch* buffer."
  (interactive "s[claude] 问题: ")
  (cch--ask-async prompt))

;;;###autoload
(defun cch-ask-region (beg end)
  "Ask claude about the selected region (asynchronously, answer to *cch*)."
  (interactive "r")
  (let ((text (string-trim (buffer-substring-no-properties beg end))))
    (if (string-empty-p text)
        (user-error "选中区域是空的")
      (cch--ask-async text))))

;;;###autoload
(defun cch-ask-insert (prompt)
  "Ask PROMPT synchronously and insert the answer at point."
  (interactive "s[claude] 问题: ")
  (insert (cch--ask-sync prompt)))

;;;###autoload
(defun cch-ask-region-insert (beg end)
  "Ask claude about the selected region synchronously, insert answer after it."
  (interactive "r")
  (let ((text (string-trim (buffer-substring-no-properties beg end))))
    (if (string-empty-p text)
        (user-error "选中区域是空的")
      (goto-char end)
      (insert "\n" (cch--ask-sync text)))))

(global-set-key (kbd "C-c q a") #'cch-ask)
(global-set-key (kbd "C-c q r") #'cch-ask-region)
(global-set-key (kbd "C-c q i") #'cch-ask-insert)
(global-set-key (kbd "C-c q I") #'cch-ask-region-insert)

(provide 'cch)
;;; cch.el ends here
