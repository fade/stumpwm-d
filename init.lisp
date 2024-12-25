(cl:in-package :stumpwm)

;;; to debug this init system, uncomment the following two lines.
;; (setf *debug-level* 3)
;; (redirect-all-output (data-dir-file "debug-output" "txt"))

;;; ======================================================================
;;; if quicklisp isn't loaded, load it.
;;; ======================================================================

#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (message "Loading/Using quicklisp, slynk etc....")
    (load quicklisp-init)))

;; (use-package :ql)

;; common lisp string processing lib.
(asdf:load-system "str")
(asdf:load-system "cl-mount-info")

;;; ======================================================================
;;; Start a slynk server so we can modify stump as it runs, from emacs
;;; ======================================================================

;; when loading slynk, we must be absolutely sure that the lisp image
;; that stump was built with matches the lisp image we are using in
;; general for development, or you will get gnarly tracebacks.

(asdf:load-system 'slynk)

(setf stumpwm:*top-level-error-action* :break)

;;; ======================================================================
;;  idempotentate! a slynk server in our WM process.
;;; ======================================================================

(defvar *slynk-p* nil)

(if *slynk-p*
    (message "Slynk server is already running.")
  (progn
    (slynk:create-server :port 4007
			 :style slynk:*communication-style*
			 :dont-close t)
    (setf *slynk-p* t)
    (message "Slynk server started.")))

;;; ======================================================================
;;  init the lisp listener.
;;; ======================================================================

(in-package :stumpwm)
(setf *default-package* :stumpwm)


;;; ======================================================================
;;; too many things use notifications for core functionality to ignore
;;; them. This almost always works at least 80% of the time.
;;; ======================================================================

(load-module "notify")

(defvar *notifications* nil)

(if (and (find-package :notify) (not *notifications*))
    (progn
      (notify:notify-server-toggle)
      (setf *notifications* t))
    (message "The notify package was not loaded. It is already present."))

;;; ======================================================================
;;; Let's see if we can solve the screenshotting issue for once and all.
;;; ======================================================================

(load-module "screenshot")

;;; ======================================================================
;;;  group definitions
;;; ======================================================================

;; ;; set the name of the initial group, which otherwise defaults to "Default"
;; (setf (group-name (first (screen-groups (current-screen)))) "Terminal")

;; (dolist (space (list "Emacs" "Music" "Mail" "Boomer" "StumpConfig" "Nish" "Kleevo"))
;;   (gnewbg space))

;; ;; what to do with the mouse?
(setf *mouse-focus-policy* :sloppy)

(asdf:load-system :stumpwm-init)
