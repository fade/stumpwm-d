(uiop:define-package :stumpwm-init/personal-keys
  (:import-from :stumpwm-init/keybinding-macros
                #:super-key-maps
                #:windowed-app-launcher
                #:s-
                #:s-l
                #:bind))


(in-package :stumpwm-init/personal-keys)

;;;----------------------------------------------------------------------
;;; keybinds
;;;----------------------------------------------------------------------

;; Nyxt is a keyboard driven web browser written in common lisp.

;; (defcommand nyxt () ()
;;   "run or raise the nyxt key-driven webbrowser."
;;   (run-or-raise "nyxt" '(:class "nyxt")))

;; b for browser
(windowed-app-launcher nyxt b)
;; f for real browser
(windowed-app-launcher firefox f)

;; m for music
;; (windowed-app-launcher clementine m)


;; c for light/fast terminal
(windowed-app-launcher alacritty c)
;; C for reliable URL recog (konsole)
(windowed-app-launcher konsole o)
