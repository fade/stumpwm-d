(uiop:define-package :stumpwm-init/volume
  (:use :cl)
  (:export #:show-volume #:adjust-volume #:set-volume #:toggle-mute #:mute #:unmute
           #:volume-10+ #:volume-10-
           #:show-microphone #:toggle-mic-mute
           #:*wpctl-program* #:*volume-sink* #:*microphone-source* #:*volume-limit*)
  (:import-from :stumpwm
                #:defcommand #:message))

(cl:in-package :stumpwm-init/volume)

;;; Sound control goes through wpctl, the WirePlumber command line tool,
;;; because this machine runs PipeWire and the PulseAudio mixers are not
;;; installed. wpctl ships with WirePlumber, so it is present wherever the
;;; session manager is.

(defparameter *wpctl-program* "wpctl"
  "Name or path of the wpctl executable used for every sound command.")

(defparameter *volume-sink* "@DEFAULT_AUDIO_SINK@"
  "The wpctl node the volume commands act on. The default names whichever
output WirePlumber currently treats as the default, so the commands follow
you when you switch headphones or speakers.")

(defparameter *microphone-source* "@DEFAULT_AUDIO_SOURCE@"
  "The wpctl node the microphone commands act on, by default the current
default input.")

(defparameter *volume-limit* 1.5
  "Highest volume the commands will set, as a fraction where 1.0 is 100%.
Values above 1.0 allow boosting past full scale, which matches the old
pamixer setup. Set it to 1.0 to never go past 100%.")

(define-condition wpctl-error (error)
  ((detail :initarg :detail :reader wpctl-error-detail))
  (:report (lambda (condition stream)
             (format stream "wpctl: ~a" (wpctl-error-detail condition))))
  (:documentation "Signalled when wpctl is missing, fails, or prints
something these commands cannot understand."))

(defun wpctl (&rest args)
  "Run wpctl with ARGS and return its standard output as a string.
Signals WPCTL-ERROR when the program cannot be started or reports a failure."
  (multiple-value-bind (output error-output status)
      (handler-case
          (uiop:run-program (cons *wpctl-program* args)
                            :output '(:string :stripped t)
                            :error-output '(:string :stripped t)
                            :ignore-error-status t)
        (error (e)
          (error 'wpctl-error
                 :detail (format nil "cannot run ~a (~a)" *wpctl-program* e))))
    ;; Some wpctl subcommands, get-volume among them, report a missing node
    ;; on standard error yet exit with status 0.
    (unless (and (eql status 0)
                 (or (zerop (length error-output))
                     (plusp (length output))))
      (error 'wpctl-error
             :detail (if (plusp (length error-output))
                         error-output
                         (format nil "~{~a~^ ~} exited with status ~a"
                                 args status))))
    output))

(defun parse-volume (text)
  "Parse wpctl get-volume output such as \"Volume: 0.41 [MUTED]\".
Returns the volume as a whole percentage and a second value that is true
when the node is muted."
  (let* ((prefix "Volume:")
         (start (search prefix text))
         (number-start (and start
                            (position #\Space text
                                      :start (+ start (length prefix))
                                      :test-not #'char=)))
         (number-end (and number-start
                          (or (position #\Space text :start number-start)
                              (length text))))
         (fraction (and number-end
                        (let ((*read-eval* nil)
                              (*read-default-float-format* 'double-float))
                          (ignore-errors
                           (read-from-string text t nil
                                             :start number-start
                                             :end number-end))))))
    (unless (realp fraction)
      (error 'wpctl-error
             :detail (format nil "unexpected volume output ~s" text)))
    (values (round (* 100 fraction))
            (and (search "[MUTED]" text) t))))

(defun node-volume (node)
  "Return NODE's volume as a whole percentage, and whether it is muted."
  (parse-volume (wpctl "get-volume" node)))

(defun set-node-volume (node volume)
  "Set NODE's volume with VOLUME in wpctl's syntax, such as \"40%\" or
\"10%+\", never going above *VOLUME-LIMIT*."
  (wpctl "set-volume" "-l" (format nil "~f" (float *volume-limit*))
         node volume))

(defun set-node-mute (node state)
  "Set NODE's mute state, where STATE is \"1\", \"0\" or \"toggle\"."
  (wpctl "set-mute" node state))

(defun describe-node (label node)
  "Return a one-line description of NODE such as \"Volume: 41% (muted)\"."
  (multiple-value-bind (percent mutedp) (node-volume node)
    (format nil "~a: ~d%~:[~; (muted)~]" label percent mutedp)))

(defmacro with-wpctl-errors (&body body)
  "Run BODY, turning a wpctl failure into a message on screen. The init file
sends errors to the debugger, and a missing sound tool should not do that."
  `(handler-case (progn ,@body)
     (wpctl-error (e)
       (message "~a" e))))

(defcommand show-volume () ()
  "Show the output volume and whether it is muted."
  (with-wpctl-errors
    (message "~a" (describe-node "Volume" *volume-sink*)))
  (values))

(defcommand adjust-volume (delta) ((:number "volume delta (%): "))
  "increase or decrease system volume by DELTA

DELTA should be an integer representing a positive or negative percentage."
  (with-wpctl-errors
    (set-node-volume *volume-sink*
                     (format nil "~d%~:[+~;-~]" (abs delta) (minusp delta))))
  (show-volume))

(defcommand set-volume (target) ((:number "absolute volume (%): "))
  "set system volume to TARGET

TARGET should be a non-negative integer representing a percentage."
  (with-wpctl-errors
    (set-node-volume *volume-sink* (format nil "~d%" (max 0 target))))
  (show-volume))

(defcommand toggle-mute () ()
  (with-wpctl-errors
    (set-node-mute *volume-sink* "toggle"))
  (show-volume))

(defcommand mute () ()
  (with-wpctl-errors
    (set-node-mute *volume-sink* "1"))
  (show-volume))

(defcommand unmute () ()
  (with-wpctl-errors
    (set-node-mute *volume-sink* "0"))
  (show-volume))

(defcommand volume-10+ () ()
  (adjust-volume 10))

(defcommand volume-10- () ()
  (adjust-volume -10))

(defcommand show-microphone () ()
  "Show the microphone level and whether it is muted."
  (with-wpctl-errors
    (message "~a" (describe-node "Microphone" *microphone-source*)))
  (values))

(defcommand toggle-mic-mute () ()
  "Mute or unmute the default microphone, then show its state."
  (with-wpctl-errors
    (set-node-mute *microphone-source* "toggle"))
  (show-microphone))
