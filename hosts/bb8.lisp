(uiop:define-package :stumpwm-init/hosts/bb8
  (:use :cl)
  (:import-from :stumpwm-init/brightness)
  (:import-from :stumpwm-init/keybinding-macros
   #:bind))

(cl:in-package :stumpwm-init/hosts/bb8)

;;; Things only bb8, the HP laptop, needs. The shared config never loads
;;; this file; load-host-configuration does, when it runs on bb8.

;;; brightness keys: 5% steps, or 1% steps with shift held
(bind "XF86MonBrightnessUp" "brightness-up 5")
(bind "XF86MonBrightnessDown" "brightness-down 5")
(bind "S-XF86MonBrightnessUp" "brightness-up 1")
(bind "S-XF86MonBrightnessDown" "brightness-down 1")
