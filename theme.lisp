(uiop:define-package :stumpwm-init/theme
  (:use :cl)
  (:import-from :stumpwm-init/deepsky)
  (:import-from :stumpwm
                #:*colors*
                #:set-fg-color
                #:set-bg-color
                #:set-border-color
                #:set-focus-color
                #:set-unfocus-color
                #:update-color-map
                #:current-screen
                #:*mode-line-foreground-color*
                #:*mode-line-background-color*
                #:*mode-line-border-color*
                #:run-shell-command))

;; ensure this file is loaded before modeline.lisp because otherwise
;; the modeline may not respect the colors bound below.

(cl:in-package :stumpwm-init/theme)

;; the working colour palette.

;;; As per commentary in color.lisp
(defparameter *colors* `(deepsky:background        ; ^0
                         deepsky:foreground        ; ^1
                         deepsky:current-line      ; ^2
                         deepsky:cloudless-day     ; ^3
                         deepsky:bluebird          ; ^4
                         deepsky:snow              ; ^5
                         deepsky:white             ; ^6
                         deepsky:peachpuff         ; ^7
                         deepsky:lemonchiffon      ; ^8
                         deepsky:comment
                         deepsky:cyan
                         deepsky:green
                         deepsky:orange
                         deepsky:pink
                         deepsky:purple
                         deepsky:red
                         deepsky:yellow))

(when *initializing*
  (update-color-map (current-screen)))

(set-fg-color deepsky:foreground)
(set-bg-color deepsky:background)
(set-border-color deepsky:current-line)

(defparameter *mode-line-foreground-color* deepsky:foreground)
(defparameter *mode-line-background-color* deepsky:background)
(defparameter *mode-line-border-color* deepsky:current-line)

(defun set-theme ()
    ;;; message and input bar colors
  ;; `stumppwm:set-fg-color' controls the text in the message and input bar
  (set-fg-color deepsky:foreground)
  ;; `stumpwm:set-bg-color' controls the background in the message and input bar
  (set-bg-color deepsky:background)
  ;; `stumpwm:set-border-color' controls the border of the message and input bar
  (set-border-color deepsky:comment)

  ;;; window borders
  ;; `stumpwm:set-focus-color applies to the border of the focused window
  (set-focus-color deepsky:comment)
  ;; `wtumpwm:set-unfocus-color applies to the border of non-fucused windows
  (set-unfocus-color deepsky:background)

  (dolist (screen stumpwm:*screen-list*)
    (update-color-map screen))

  ;; potential place to put xresource changes by running a shell command. ie:
  ;; (run-shell-command "xrdb -load ~/.Xresources")
  ;; (run-shell-command (format nil "xsetroot -solid ~s" deepsky:background))
  )

(stumpwm:add-hook stumpwm:*start-hook* 'set-theme)
