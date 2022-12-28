(cl:in-package :stumpwm-user)
(require :quicklisp)

(ql:quickload :stumpwm-init)

;;; ======================================================================
;;; Start a slynk server so we can modify stump as it runs, from emacs
;;; ======================================================================

;; when loading slynk, we must be absolutely sure that the lisp image
;; that stump was built with matches the lisp image we are using in
;; general for development, or you will get gnarly tracebacks.

(quickload 'slynk)

(setf stumpwm:*top-level-error-action* :break)

;;; ======================================================================
;;  idempotentate! a slynk server in our WM process.
;;; ======================================================================

(defvar *slynk-p* nil)
(if *slynk-p*
      (message "Slynk server is already running.")
      (progn
	(slynk:create-server :port 4006
			     :style slynk:*communication-style*
			     :dont-close t)
	(setf *slynk-p* t)
	(message "Slynk server started.")))

;;; ======================================================================
;;  init the lisp listener.
;;; ======================================================================

(in-package :stumpwm)
(setf *default-package* :stumpwm)
