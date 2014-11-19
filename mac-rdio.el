;;https://github.com/Bruce-Connor/names/
;;https://raw.githubusercontent.com/krisajenkins/helm-spotify/master/helm-spotify.el

(defun current-track-info()
  (s-split-up-to ", " (run-command-and-return-string "to get the {key, artist, album, name} of the current track") 3))


(defun run-command-and-return-string(cmd)
  (s-trim-right (shell-command-to-string (command cmd))))
  

(defun command(cmd)
  (concat "osascript -e 'tell application \"Rdio\" " cmd "'"))

(defvar song-list '())

(defun track-id(track)
  (car track))

(defun track-artist(track)
  (car (cdr track)))

(defun track-album(track)
  (car (nthcdr 2 track)))

(defun track-name(track)
  (car (nthcdr 3 track)))

(defun get-all-x(func)
  (delete-dups (map 'list func song-list)))

(defun get-all-names()
  (get-all-x 'track-name))

(defun get-all-albums()
  (get-all-x 'track-album))

(defun get-all-artists()
  (get-all-x 'track-artist))

(defun get-tracks-for-artist(tracks artist)
  (cond ((not tracks) '())
        ((string= artist (track-artist (car tracks))) (cons (car tracks) (get-tracks-for-artist (cdr tracks) artist)))
        (t (get-tracks-for-artist (cdr tracks) artist))))


(defvar queue '())

(defun add-to-queue (tracks)
  (setq queue (append tracks queue)))
  
(add-to-queue (get-tracks-for-artist song-list "The Slits"))



(defun play-track(track)
  (play-track-id (track-id track)))

(defun play-artist(artist)
  (play-track-id))

;(play-track (car song-list))
;(play-artist "The Slits")

(defun play-track-id(track-id)
  (run-command-and-return-string (concat "to play source \"" track-id "\"")))

(defun add-current-to-song-list()
  (let ((ct (current-track-info)))
    (if (and (not (member ct song-list))
             (not (string= (track-id ct) "")))
        (setq song-list (cons (current-track-info) song-list)))))

(setq my-timer (run-with-timer 0 10 'add-current-to-song-list))
(cancel-timer my-timer)

(defun is-ready-for-next-song()
  (and
   (string= "0" (run-command-and-return-string "to get player position"))
   (string= "paused" (run-command-and-return-string "to get player state"))))


(defun play-next-in-queue()
  (if (and (is-ready-for-next-song)
           (car queue))
      (progn
        (play-track (car queue))
        (setq queue (cdr queue)))))


(setq my-timer2 (run-with-timer 0 2 'play-next-in-queue))
(cancel-timer my-timer2)


(defun format-track-for-display (track)
  (concat (track-artist track)
          " - "
          (track-album track)
          " - "
          (track-name track)))

(defun helm-rdio-search()
  (mapcar (lambda (track)
            (cons (format-track-for-display track)
                  track))
          song-list))

(defun helm-rdio-actions-for-track (actions track)
  "Return a list of helm ACTIONS available for this TRACK."
  `((,(format "Play Track - %s" (track-id track)) . play-track)
    ("Show Track Metadata" . pp)))

(defvar helm-source-rdio-track-search
  '((name . "Rdio")
    (volatile)
    ;(delayed)
    ;(multiline)
    ;(requires-pattern . 0)
    (candidates . helm-rdio-search)
    (action-transformer . helm-rdio-actions-for-track)))


(require 'helm)
(defun helm-rdio ()
  "Bring up a Rdio search interface in helm."
  (interactive)
  (helm :sources '(helm-source-rdio-track-search)
	:buffer "*helm-rdio*"))
