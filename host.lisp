(uiop:define-package :stumpwm-init/host
  (:use :cl)
  (:export #:*host* #:laptop-p #:load-host-configuration
           #:host-configuration-file)
  (:import-from :stumpwm
                #:message))

(cl:in-package :stumpwm-init/host)

;;; This config runs on more than one machine. Everything shared lives in
;;; the ordinary files; anything that only one machine needs goes in
;;; hosts/<name>.lisp, where <name> is that machine's host name. A machine
;;; without such a file simply gets the shared config.

(defun short-host-name (name)
  "Return NAME downcased and cut at its first dot, so a fully qualified
name such as \"bb8.example.org\" becomes \"bb8\"."
  (string-downcase (subseq name 0 (or (position #\. name) (length name)))))

(defparameter *host*
  (intern (string-upcase (short-host-name (or (machine-instance) "unknown")))
          :keyword)
  "A keyword naming the machine this config is running on, such as :BB8.
It comes from the host name, so a host file is named after that too.")

(defparameter *portable-chassis-types* '(8 9 10 14 30 31 32)
  "SMBIOS chassis type codes that describe something you carry around:
portable, laptop, notebook, sub notebook, tablet, convertible and
detachable.")

(defun chassis-type ()
  "Return the SMBIOS chassis type the firmware reports, or NIL when it
cannot be read."
  (ignore-errors
   (parse-integer (uiop:read-file-string "/sys/class/dmi/id/chassis_type")
                  :junk-allowed t)))

(defun battery-present-p ()
  "True when the kernel reports a system battery. Only entries named BAT
count, so a wireless mouse or keyboard battery does not make a desktop look
like a laptop."
  (some (lambda (dir)
          (uiop:string-prefix-p "BAT" (car (last (pathname-directory dir)))))
        (ignore-errors (uiop:subdirectories "/sys/class/power_supply/"))))

(defun laptop-p ()
  "True when this machine is a laptop or similar portable. The firmware's
chassis type decides it; a system battery also counts, because some
laptops report a chassis type that says otherwise."
  (or (and (member (chassis-type) *portable-chassis-types*) t)
      (battery-present-p)))

(defun host-configuration-file (&optional (host *host*))
  "Return the pathname of HOST's configuration file next to the system
definition, whether or not it exists."
  (merge-pathnames (make-pathname :directory '(:relative "hosts")
                                  :name (string-downcase (symbol-name host))
                                  :type "lisp")
                   (asdf:system-source-directory "stumpwm-init")))

(defun load-host-configuration (&optional (host *host*))
  "Load the configuration that only HOST needs, from hosts/<host>.lisp, and
say on screen which file loaded. A host without such a file is normal and
only gets a message. Returns true when a host file was loaded."
  (let ((file (host-configuration-file host))
        (name (string-downcase (symbol-name host))))
    (cond ((probe-file file)
           (asdf:load-system (format nil "stumpwm-init/hosts/~a" name))
           (message "Loaded host configuration ~a" (uiop:native-namestring file))
           t)
          (t
           (message "No host configuration for ~a" name)
           nil))))
