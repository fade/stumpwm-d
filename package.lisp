(uiop:define-package :stumpwm-init/package
  (nicknames :stumpwm-init)
  (:use-reexport
   :stumpwm-init/theme
   :stumpwm-init/modeline
   :stumpwm-init/keybindings
   :stumpwm-init/groups))
