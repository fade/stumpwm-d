(uiop:define-package :stumpwm-init/brightness
  (:use :cl)
  (:export #:brightness-up #:brightness-down #:show-brightness
           #:*backlight-device* #:*busctl-program*)
  (:import-from :stumpwm
                #:defcommand #:message))

(cl:in-package :stumpwm-init/brightness)

;;; Screen brightness is read from the kernel's backlight files and set
;;; through systemd-logind. Writing the brightness file directly needs root,
;;; but logind lets the user who owns the active session set it, so these
;;; commands work without a setuid helper or a udev rule.

(defparameter *backlight-device* nil
  "Name of the backlight under /sys/class/backlight to control, such as
\"intel_backlight\". Leave it NIL to use the first one the kernel lists,
which is right on a machine with a single panel. Set it when a machine has
more than one and the first is the wrong one.")

(defparameter *busctl-program* "busctl"
  "Name or path of the busctl executable used to ask logind for a change.")

(define-condition brightness-error (error)
  ((detail :initarg :detail :reader brightness-error-detail))
  (:report (lambda (condition stream)
             (format stream "brightness: ~a" (brightness-error-detail condition))))
  (:documentation "Signalled when there is no backlight, its files cannot be
read, or logind refuses the change."))

(defun backlight-device ()
  "Return the name of the backlight to control."
  (or *backlight-device*
      (let ((dir (first (ignore-errors
                         (uiop:subdirectories "/sys/class/backlight/")))))
        (if dir
            (car (last (pathname-directory dir)))
            (error 'brightness-error :detail "no backlight on this machine")))))

(defun read-backlight-value (device file)
  "Read the integer in FILE under DEVICE's backlight directory."
  (let* ((path (format nil "/sys/class/backlight/~a/~a" device file))
         (value (ignore-errors
                 (parse-integer (uiop:read-file-string path) :junk-allowed t))))
    (or value
        (error 'brightness-error :detail (format nil "cannot read ~a" path)))))

(defun backlight-state (device)
  "Return DEVICE's current raw brightness and its maximum."
  (values (read-backlight-value device "brightness")
          (read-backlight-value device "max_brightness")))

(defun set-backlight-raw (device value)
  "Ask logind to set DEVICE to the raw brightness VALUE."
  (multiple-value-bind (output error-output status)
      (handler-case
          (uiop:run-program (list *busctl-program* "call"
                                  "org.freedesktop.login1"
                                  "/org/freedesktop/login1/session/auto"
                                  "org.freedesktop.login1.Session"
                                  "SetBrightness" "ssu"
                                  "backlight" device (princ-to-string value))
                            :output '(:string :stripped t)
                            :error-output '(:string :stripped t)
                            :ignore-error-status t)
        (error (e)
          (error 'brightness-error
                 :detail (format nil "cannot run ~a (~a)" *busctl-program* e))))
    (declare (ignore output))
    (unless (eql status 0)
      (error 'brightness-error
             :detail (if (plusp (length error-output))
                         error-output
                         (format nil "~a exited with status ~a"
                                 *busctl-program* status))))
    value))

(defun brightness-percent (value maximum)
  "Return VALUE as a whole percentage of MAXIMUM."
  (round (* 100 value) maximum))

(defun step-brightness (delta)
  "Change the brightness by DELTA percent of the maximum. The result never
drops below 1, so the panel is never switched fully dark by accident."
  (let ((device (backlight-device)))
    (multiple-value-bind (value maximum) (backlight-state device)
      (set-backlight-raw device
                         (max 1 (min maximum
                                     (+ value (round (* delta maximum) 100))))))))

(defmacro with-brightness-errors (&body body)
  "Run BODY, turning a brightness failure into a message on screen. The init
file sends errors to the debugger, and a missing backlight should not do
that."
  `(handler-case (progn ,@body)
     (brightness-error (e)
       (message "~a" e))))

(defcommand show-brightness () ()
  "Show the screen brightness as a percentage."
  (with-brightness-errors
    (multiple-value-bind (value maximum) (backlight-state (backlight-device))
      (message "Brightness: ~d%" (brightness-percent value maximum))))
  (values))

(defcommand brightness-up (step) ((:number "brightness step (%): "))
  "Raise the screen brightness by STEP percent, then show it."
  (with-brightness-errors
    (step-brightness (abs step))
    (show-brightness)))

(defcommand brightness-down (step) ((:number "brightness step (%): "))
  "Lower the screen brightness by STEP percent, then show it."
  (with-brightness-errors
    (step-brightness (- (abs step)))
    (show-brightness)))
