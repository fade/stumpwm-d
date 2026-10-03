(uiop:define-package :stumpwm-init/emacs
  (:use :cl)
  (:import-from :stumpwm
                #:defcommand #:message)
  (:import-from :slynk)
  (:export #:emacsclient-create-window
           #:emacsclient-eval
           #:emacsclient-debug
           #:emacs-status
           #:kill-emacs
           #:*emacsclient-program* #:*emacsclient-timeout* #:*slynk-port*))

(cl:in-package :stumpwm-init/emacs)

;;; Commands that talk to a running Emacs server through emacsclient. They
;;; run emacsclient directly rather than through a shell, so an Emacs Lisp
;;; form reaches Emacs exactly as typed, quotes and all.

(defparameter *emacsclient-program* "emacsclient"
  "Name or path of the emacsclient executable.")

(defparameter *emacsclient-timeout* 10
  "Seconds to wait for Emacs to answer an evaluation. The window manager
waits for the answer, so a busy or wedged Emacs must not hold it forever.")

(defvar *slynk-port* 49152
  "The last port handed to a Slynk server started by EMACSCLIENT-DEBUG.
Each debug session takes the next port up, so it never collides with the
server the init file starts on 4007 or with an earlier debug session.")

(define-condition emacsclient-error (error)
  ((detail :initarg :detail :reader emacsclient-error-detail))
  (:report (lambda (condition stream)
             (format stream "emacsclient: ~a"
                     (emacsclient-error-detail condition))))
  (:documentation "Signalled when emacsclient is missing, cannot reach a
server, or Emacs reports an error evaluating a form."))

(define-condition emacs-server-unreachable (emacsclient-error)
  ()
  (:documentation "Signalled when emacsclient runs but finds no Emacs
server to talk to."))

(defun first-line (text)
  "Return the first non-empty line of TEXT, so a failure fits in one message."
  (let ((line (or (find-if (lambda (line) (plusp (length line)))
                           (uiop:split-string text :separator '(#\Newline)))
                  ""))
        (prefix "emacsclient: "))
    ;; The condition report already names emacsclient.
    (if (uiop:string-prefix-p prefix line)
        (subseq line (length prefix))
        line)))

(defun emacsclient (&rest args)
  "Run emacsclient with ARGS and return its standard output as a string.
Signals EMACSCLIENT-ERROR when the program cannot be started or reports a
failure, and EMACS-SERVER-UNREACHABLE when no server answers."
  ;; ALTERNATE_EDITOR is removed from the environment because, when it is
  ;; set, emacsclient runs that editor instead of failing, and an
  ;; evaluation with no server would open a stray Emacs on the screen.
  (multiple-value-bind (output error-output status)
      (handler-case
          (uiop:run-program (list* "env" "-u" "ALTERNATE_EDITOR"
                                   *emacsclient-program* args)
                            :output '(:string :stripped t)
                            :error-output '(:string :stripped t)
                            :ignore-error-status t)
        (error (e)
          (error 'emacsclient-error
                 :detail (format nil "cannot run ~a (~a)"
                                 *emacsclient-program* e))))
    (unless (eql status 0)
      (let ((detail (if (plusp (length error-output))
                        (first-line error-output)
                        (format nil "exited with status ~a" status))))
        (error (if (or (search "can't find socket" error-output)
                       (search "can't connect" error-output)
                       (search "No socket" error-output))
                   'emacs-server-unreachable
                   'emacsclient-error)
               :detail detail)))
    output))

(defun emacs-eval (form)
  "Evaluate FORM, a string of Emacs Lisp, in the running Emacs server and
return the printed result."
  (emacsclient (format nil "--timeout=~d" *emacsclient-timeout*)
               "--eval" form))

(defmacro with-emacsclient-errors (&body body)
  "Run BODY, turning an emacsclient failure into a message on screen. The
init file sends errors to the debugger, and an absent Emacs should not."
  `(handler-case (progn ,@body)
     (emacsclient-error (e)
       (message "~a" e))))

(defcommand emacsclient-create-window (&optional extra-args) ((:rest))
  "Open a new Emacs frame without waiting for it to close, starting an Emacs
server first if none is running. Run it from the command prompt with
arguments, such as a file name, and they are passed on to emacsclient."
  ;; The frame lives as long as you keep it, so the client is launched in
  ;; the background rather than waited on.
  (with-emacsclient-errors
    (handler-case
        (uiop:launch-program
         (list* *emacsclient-program* "-c" "-n" "-a" ""
                (when extra-args
                  (remove "" (uiop:split-string extra-args) :test #'string=)))
         :output nil :error-output nil)
      (error (e)
        (error 'emacsclient-error
               :detail (format nil "cannot run ~a (~a)"
                               *emacsclient-program* e)))))
  (values))

(defcommand emacsclient-eval (form) ((:string "an emacs-lisp form: "))
  "Evaluate FORM in the running Emacs and show the result."
  (with-emacsclient-errors
    (message "~a" (emacs-eval form)))
  (values))

(defcommand kill-emacs () ()
  "Ask the running Emacs server to exit."
  (emacsclient-eval "(kill-emacs)"))

(defparameter *emacs-status-form*
  "(format \"Emacs %s, up %s, %d frames, %d buffers\"
           emacs-version (emacs-uptime)
           (length (delq terminal-frame (frame-list)))
           (length (buffer-list)))"
  "Emacs Lisp form whose value is the one-line status EMACS-STATUS shows.
The daemon's own initial frame is left out of the count because you never
see it.")

(defun read-elisp-string (printed)
  "Return the string Emacs printed as PRINTED, or PRINTED itself when it is
not a printed string."
  (or (and (plusp (length printed))
           (char= (char printed 0) #\")
           (let ((*read-eval* nil))
             (ignore-errors (read-from-string printed))))
      printed))

(defcommand emacs-status () ()
  "Show the running Emacs version, uptime, and how many frames and buffers
it holds."
  (with-emacsclient-errors
    (handler-case
        (message "~a" (read-elisp-string (emacs-eval *emacs-status-form*)))
      (emacs-server-unreachable ()
        (message "No Emacs server running."))))
  (values))

(defun next-slynk-port ()
  "Return a port no earlier debug session has used."
  (incf *slynk-port*))

(defun elisp-sly-connect-form (port &optional (host "localhost"))
  "Return the Emacs Lisp form that connects Sly to HOST on PORT."
  (format nil "(sly-connect ~s ~d)" host port))

(defcommand emacsclient-debug (&optional (port (next-slynk-port))) ()
  "Start a Slynk server in the window manager and have Emacs connect Sly to
it, giving you a REPL inside the running StumpWM."
  (with-emacsclient-errors
    (handler-case
        (slynk:create-server :port port
                             :style slynk:*communication-style*
                             :dont-close t)
      (error (e)
        (error 'emacsclient-error
               :detail (format nil "cannot start Slynk on port ~d (~a)"
                               port e))))
    (emacs-eval (elisp-sly-connect-form port))
    (message "Sly connecting to StumpWM on port ~d." port))
  (values))
