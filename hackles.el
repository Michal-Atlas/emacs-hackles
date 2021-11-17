;;; hackles.el --- View hackles from Emacs

;;; Copyright (C) 2014 Vibhav Pant <vibhavp@gmail.com>

;; Version: 1.0
;; Package-Requires: ((json "1.3"))
;; Keywords: hackles webcomic

;; ORIGINAL Xkcd Module:
;; Url: https://github.com/vibhavp/emacs-xkcd
;; Author: Vibhav Pant <vibhavp@gmail.com>

;;; Commentary:

;; This is my first ever elisp script, Forked from vibhavp's
;; wonderful Xkcd viewer, hacked at it until it read hackles.org instead
;; Comics can be viewed offline as they are stored by default in
;; ~/.emacs.d/hackles/
;; This file is not a part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Code:
(require 'json)
(require 'url)
(require 'image)
(require 'browse-url)

;;;###autoload
(define-derived-mode hackles-mode special-mode "hackles"
  "Major mode for viewing hackles (http://hackles.org/) comics."
  :group 'hackles)

(define-key hackles-mode-map (kbd "<right>") 'hackles-next)
(define-key hackles-mode-map (kbd "<left>") 'hackles-prev)
(define-key hackles-mode-map (kbd "q") 'hackles-kill-buffer)
(define-key hackles-mode-map (kbd "o") 'hackles-open-browser)

(defvar hackles-alt nil)
(defvar hackles-cur nil)
(defvar hackles-last 364)

(defgroup hackles nil
  "A hackles reader for Emacs"
  :group 'multimedia)

(defcustom hackles-cache-dir (let ((dir (concat user-emacs-directory "hackles/")))
                               (make-directory dir :parents)
                               dir)
  "Directory to cache images and json files to."
  :group 'hackles
  :type 'directory)

(defun hackles-download (url num)
  "Download the image linked by URL to NUM.  If NUM arleady exists, do nothing."
  (let ((name (format "%s%s.%s" hackles-cache-dir (number-to-string num)
		      (substring url (- (length url) 3)))))
    (if (file-exists-p name)
	name
      (url-copy-file url name))
    name))

(defun hackles-insert-image (file num)
  "Insert image described by FILE and NUM in buffer with the title-text.
If the image is a gif, animate it."
  (let ((image (create-image (format "%s%d.%s" hackles-cache-dir
				     num
				     (substring file (- (length file) 3)))
			     'png))
	(start (point)))
    (insert-image image)
    (add-text-properties start (point) '(help-echo hackles-alt))))

;;;###autoload
(defun hackles-get (num)
  "Get the hackles number NUM."
  (interactive "nEnter comic number: ")
  (get-buffer-create "*hackles*")
  (switch-to-buffer "*hackles*")
  (hackles-mode)
  (let (buffer-read-only)
    (erase-buffer)
    (setq hackles-cur num)
    (message "Getting comic...")
    (setq file (hackles-download (format "http://hackles.org/strips/cartoon%s.png" (number-to-string num)) num))
    (setq title (format "%d" num))
    (insert (propertize title
			'face '(:weight bold :height 110)))
    (center-line)
    (insert "\n")
    (hackles-insert-image file num)
    (if (eq hackles-cur 0)
	(setq hackles-cur num))
    (message "%s" title)))

(defun hackles-next (arg)
  "Get next hackles."
  (interactive "p")
  (let ((num (+ hackles-cur arg)))
    (when (> num 364)
      (setq num 364))
    (hackles-get num)))

(defun hackles-prev (arg)
  "Get previous hackles."
  (interactive "p")
  (let ((num (- hackles-cur arg)))
    (when (< num 1)
      (setq num 1))
    (hackles-get num)))

;;;###autoload
(defun hackles-get-last ()
  "Get the last hackles."
  (interactive)
  (hackles-get 364))

;;;###autoload
(defalias 'hackles 'hackles-get-last)

;; Not applicable until I find a way to parse it from HTML
;;(defun hackles-alt-text ()
;;  "View the alt text in the buffer."
;;  (interactive)
;;  (message "%s" hackles-alt))

(defun hackles-kill-buffer ()
  "Kill the hackles buffer."
  (interactive)
  (kill-buffer "*hackles*"))

(defun hackles-open-browser ()
  "Open current hackles in default browser"
  (interactive)
  (browse-url-default-browser (concat "http://hackles.org/cgi-bin/archives.pl?request="
				      (number-to-string hackles-cur))))

(defun hackles-copy-link ()
  "Save the link to the current comic to the kill-ring."
  (interactive)
  (let ((link (concat "http://hackles.org/strips/cartoon"
		      (number-to-string hackles-cur) ".png")))
    (kill-new link)
    (message link)))

(provide 'hackles)
;;; hackles.el ends here
