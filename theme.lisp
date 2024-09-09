(uiop:define-package :stumpwm-init/theme
  (:use :cl)
  (:import-from :stumpwm-init/deepsky)
  (:import-from :stumpwm
                #:kbd
                #:define-key
                #:defcommand
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
                #:run-shell-command)
  (:export #:*desktop-background-command*
           #:*background-images*
           #:backgrounds))

;; ensure this file is loaded before modeline.lisp because otherwise
;; the modeline may not respect the colors bound below.

(cl:in-package :stumpwm-init/theme)

;; the working colour palette.

;;; As per commentary in color.lisp
(setf stumpwm:*colors* `(,deepsky:background        ; ^0
                         ,deepsky:foreground        ; ^1
                         ,deepsky:current-line      ; ^2
                         ,deepsky:cloudless-day     ; ^3
                         ,deepsky:bluebird          ; ^4
                         ,deepsky:snow              ; ^5
                         ,deepsky:white             ; ^6
                         ,deepsky:peachpuff         ; ^7
                         ,deepsky:lemonchiffon      ; ^8
                         ,deepsky:comment
                         ,deepsky:cyan
                         ,deepsky:green
                         ,deepsky:orange
                         ,deepsky:pink
                         ,deepsky:purple
                         ,deepsky:red
                         ,deepsky:yellow))

(update-color-map (current-screen))
;; (when *initializing*
;;   (update-color-map (current-screen)))

(set-fg-color deepsky:foreground)
(set-bg-color deepsky:background)
;; (set-border-color deepsky:current-line)
(set-border-color deepsky:orange)

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
  (set-focus-color deepsky:cloudless-day)
  ;; `wtumpwm:set-unfocus-color applies to the border of non-focused windows
  (set-unfocus-color deepsky:background)

  (dolist (screen stumpwm:*screen-list*)
    (update-color-map screen))

  ;; potential place to put xresource changes by running a shell command. ie:
  ;; (run-shell-command "xrdb -load ~/.Xresources")
  ;; (run-shell-command (format nil "xsetroot -solid ~s" deepsky:background))
  )

(stumpwm:add-hook stumpwm:*start-hook* 'set-theme)

;;; ======================================================================
;;; stumpwm aesthetic configuration.
;;; ======================================================================

(defparameter *background-images* (list "$HOME/Desktop_pics/Sinead/" "$HOME/Desktop_pics/dpool/" "$HOME/Desktop_pics/Cityscapes/*") ;; "$HOME/Desktop_pics/Desktop_Images_Night_City/"
  "Directory containing desktop wallpapers.")

(defparameter *desktop-background-command* (format nil "feh --randomize --bg-scale ~{~A~^ ~}" *background-images*)
  "command to set the desktop wallpaper, as a string.")

;; set the background image when this init file is loaded. Obviously,
;; this assumes that the image directory path exists. If your image
;; files are stored on an external drive connected to USB, this will
;; likely cause a delay at this point loading the initfile.
(run-shell-command *desktop-background-command*)

;; command to set the desktop background at will.
(defcommand backgrounds () ()
  "set the root window backgrounds for the attached heads."
  (run-shell-command *desktop-background-command*))

;; bind the backgrounds command to a key in the root map.
(define-key stumpwm:*root-map* (kbd "F9") "backgrounds")

;;; ======================================================================
;;; notification colours.
;;; ======================================================================

(setq notify:*notify-server-title-color* "^3")
(setq notify:*notify-server-body-color* "^8")
