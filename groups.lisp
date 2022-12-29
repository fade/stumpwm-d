(uiop:define-package :stumpwm-init/groups
                     (:use :cl :stumpwm))

;;; ======================================================================
;;;  group definitions
;;; ======================================================================

;; set the name of the initial group, which otherwise defaults to "Default"
(setf (group-name (first (screen-groups (stumpwm:current-screen)))) "Terminal")

(dolist (space (list "Emacs" "Music" "Mail" "Boomer" "StumpConfig" "Nish" "Kleevo"))
  (gnewbg space))
