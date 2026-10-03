(uiop:define-package :stumpwm-init/deepsky
  (:use :cl)
  (:import-from :stumpwm-init/deftheme
                #:deftheme))

(cl:in-package :stumpwm-init/deepsky)


(deftheme deepsky
  (background "#29264D") ;; azurite | heroku dark blue
  (foreground  "#C9C3E6") ;; etched glass | heroku light blue
  (selection "#44475a")
  (current-line  "#1D1D1D") ;; silhouette | heroku charcoal/black
  (comment "#6272a4")
  (cyan "#8be9fd")
  (green "#50fa7b")
  (orange "#ffb86c")
  (pink "#ff79c6")
  (purple "#bd93f9")
  (red "#ff5555")
  (yellow "#f1fa8c")
  (cloudless-day  "#64B4FB") ;; cloudless day | heroku medium blue
  (bluebird  "#7565C7") ;; bluebird | heroku 2/3 blue
  (snow  "#fffafa") ;; snow
  (white  "#e5e5e5") ;; white
  (peachpuff  "#ffdab9") ;; peachpuff
  (lemonchiffon  "#fffacd")) ;;lemonchiffon
