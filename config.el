;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; ---------------------------------------------------------------------------
;; 文学化配置引导（literate config）
;;
;; 自 2026-09-02 起，私人配置的唯一真源改为 literate/config.org（Org babel
;; 文学化配置）。Emacs 启动时：
;;   - 若 config.org 比已生成的 literate/config.el 新，自动重新 tangle 并加载；
;;   - 否则直接加载现有 .el，启动开销极小。
;;
;; 修改配置的正确姿势：编辑 literate/config.org，保存后重启 Emacs（或
;; 执行 M-x org-babel-load-file 立即生效），无需 doom sync。
;; 备份：config.el.bak-20260902
;; ---------------------------------------------------------------------------

(org-babel-load-file (expand-file-name "literate/config.org" doom-user-dir))
