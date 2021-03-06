;;; glistup.el --- list up files in `gtags'

;; Copyright (C) 2014 SEONGBAEK KANG

;; Author: SEONGBAEK KANG
;; Maintainer:
;; Created: 26 Feb 2014
;; Keywords: c, `gtags'
;; Package-Version:
;; Package-Requires:

;; This file is not part of GNU Emacs.

;; see <http://www.gnu.org/licenses/>

;;; Commentary:

;; To use glistup-mode, .emacs file as below
;; 
;; (add-to-list 'load-path "/path-to/")
;; (require 'glistup)
;; 
;; To use glistup-mode,
;; make tag file using gtags and
;; 
;; M-x glistup-mode

;;; History

;;; Code:

(defconst glistup-mode-buffer-name "*glistup-buffer*"
  "Buffer Name")
(defvar glistup-mode-map nil
  "Keymap used in glistup mode")
(unless glistup-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'glistup-mode-open-file)
    (define-key map (kbd "\e") 'glistup-kill-buffer)
    (define-key map [remap self-insert-command] 'glistup-mode-self-insert-command)
    (define-key map [remap delete-backward-char] 'glistup-mode-self-insert-command)
    (setq glistup-mode-map map)
    ))
(defvar glistup-mode-pattern nil
  "Search pattern")
(defconst glistup-search-pattern1 "/%s[^/]*$"
  "Search pattern for filename")
(defconst glistup-search-pattern2 "%s[^/]*$"
  "Search pattern for filepath")
(defconst glistup-search-pattern3 "%s"
  "")
(defvar glistup-search-pattern glistup-search-pattern1
  "Search pattern in using currently")

(defvar glistup-files nil
  "Files which is listup")

(defvar glistup-debug-elapse nil
  "delay time of listup")

(defun glistup-listup (&optional pattern)
  "list files using GNU Global
return result buffer which name is `glistup-mode-buffer-name'"
  (let ((shell-param)
	(patterni)
	(gpath-sha1)
	(time-start (current-time))
	)
    
    (if (null pattern)
	(setq patterni (concat ""))
      (setq patterni (concat pattern)))
    (if (get-buffer glistup-mode-buffer-name)
	(erase-buffer))

    (call-process "global" nil (get-buffer-create glistup-mode-buffer-name) nil "--path" (format glistup-search-pattern patterni))
    ;; (get-buffer glistup-mode-buffer-name)
    (setq glistup-debug-elapse (format-time-string "%3N " (time-since time-start)))

    glistup-mode-buffer-name)
  )

(defun glistup-kill-buffer ()
  (interactive)
  (if (or (null glistup-mode-pattern) (equal "" glistup-mode-pattern))
      (kill-buffer glistup-mode-buffer-name)
    (progn
      (setq glistup-mode-pattern (concat ""))
      ;; todo list up & print status
      )
    )
  )

(defun glistup-change-pattern (arg)
  (cond
   ((= 2 arg) (setq glistup-search-pattern glistup-search-pattern2))
   ((= 3 arg) (setq glistup-search-pattern glistup-search-pattern3))
   (t (setq glistup-search-pattern glistup-search-pattern1))
   )
  )

(defun glistup-mode (&optional pattern)
  "glistup-mode Major Moode
listup files in gtags-mode"
  (interactive)
  (require 'gtags)
  (if (null (gtags-get-rootpath))
      (error "no tag files!!!")
    (setq glistup-mode-pattern nil)
    ;; (setq glistup-files nil)

    (if (get-buffer glistup-mode-buffer-name)
	(glistup-kill-buffer))

    (let ((time-start (current-time)))

      (switch-to-buffer (glistup-listup pattern))

      (setq glistup-debug-elapse (format-time-string "%3N" (time-since time-start)))
      (message "delay ... %s" glistup-debug-elapse)
      )
    (setq buffer-read-only t)

    (goto-char (point-min))
    (beginning-of-line)

    (kill-all-local-variables)
    (use-local-map glistup-mode-map)

    (setq
     major-mode 'glistup-mode
     mode-name "glistup-mode")
    (run-hooks 'glistup-mode-hook)
    )
  )

(defun glistup-mode-self-insert-command ()
  "remap 'self-insert-command"
  (interactive)
  (let ((glistup-mode-this-key (this-command-keys))
	(skip-search nil)
	)
    (cond
     ;; del-key
     ((equal "\^?" glistup-mode-this-key)
      (if (> (length glistup-mode-pattern) 0)
	(cond
	 ((equal "." (substring glistup-mode-pattern -1)) (setq glistup-mode-pattern (substring glistup-mode-pattern 0 -2)))
	 (t                                               (setq glistup-mode-pattern (substring glistup-mode-pattern 0 -1)))
	 )
	(setq skip-search t)
	)
      )
     ;; '.' character to '\.' in pattern
     ((equal "." glistup-mode-this-key)   (setq glistup-mode-pattern (concat glistup-mode-pattern "\\.")))
     (t                                   (setq glistup-mode-pattern (concat glistup-mode-pattern glistup-mode-this-key)))
     )
    
    (setq buffer-read-only nil)
    (if (null skip-search)
	(glistup-listup glistup-mode-pattern))
    (setq buffer-read-only t)
    (goto-char (point-min))
    (message 
     "delay(%s) matched(%s), Searching %s ..."
     glistup-debug-elapse
     (save-excursion
       (let ((start)
    	     (end)
    	     )
    	 (goto-char (point-min))
    	 (setq start (point))
    	 (goto-char (point-max))
    	 (setq end (point))
    	 (count-lines start end)
    	 )
       )
     (replace-regexp-in-string "\\\\" "" glistup-mode-pattern))
    )
  )

(defun glistup-mode-open-file ()
  ""
  (interactive)
  (save-excursion
    (let ((start)
	  (end)
	  (filename))
      (beginning-of-line)
      (setq start (point))
      (end-of-line)
      (setq end (point))
      (setq filename (buffer-substring start end))
      (find-file (expand-file-name filename))
      )
    (kill-buffer glistup-mode-buffer-name)
    )
  )

(provide 'glistup)

;;; glistup.el ends here
