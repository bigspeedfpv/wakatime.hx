(require-builtin steel/io as io::)
(require-builtin steel/process)
(require-builtin steel/time)
(require "steel/result")

(require "helix/static.scm")

; TODO: fallback to wakatime
(define (wakatime-cli)
  "wakatime-cli")

(define (get-ini-value content key)
  (letrec ([loop (lambda (lines)
                   (if (null? lines)
                       'not-found
                       (let* ([line (trim (car lines))]
                              [rest (cdr lines)])
                         (match (split-once line "=")
                           [(list k v)
                            (let ([k* (trim k)]
                                  [v* (trim v)])
                              (if (string=? k* key)
                                  v*
                                  (loop rest)))]
                           [else (loop rest)]))))])
    (~> content (split-many "\n") (loop))))

(define (with-stdout-piped c)
  (set-piped-stdout! c)
  c)

(define *last-heartbeat-time* None)
(define *last-heartbeat-file* "")

; 2 minute interval between sending heartbeats of the same file
(define same-file-interval 120)

; per the wakatime plugin guide, only send a new heartbeat if:
; - it has been 2 minutes since last heartbeat
; - we have a different file open, or
; - the file has been saved
(define (should-send-file? filename is-file-saved?)
  (or is-file-saved?
      (if (Some? *last-heartbeat-time*)
          [~>
           (instant/now) ;
           (duration-since (Some->value *last-heartbeat-time*))
           (duration->seconds)
           (> same-file-interval)]
          (begin
            (log::info! "wakatime heartbeat hasn't been sent since startup")
            #true))
      [not (string=? filename *last-heartbeat-file*)]))

(define (send-heartbeat is-file-saved?)
  (if (should-send-file? (cx->current-file) is-file-saved?)
      (begin
        (log::info! "sending wakatime heartbeat...")
        (let* ([file (cx->current-file)]
               [time (instant/now)]
               [entity (string-join (list "--entity=\"" file "\""))]
               [plugin-name "--plugin=\"helix/25.07.1 helix-wakatime/0.1.0\""])
          (~> (command wakatime-cli [list entity plugin-name])
              with-stdout-piped
              spawn-process
              Ok->value
              wait->stdout
              Ok->value)
          (set! *last-heartbeat-file* file)
          (set! *last-heartbeat-time* (Some time))))))

; per Wakatime docs https://wakatime.com/help/creating-plugin#handling-editor-events
; updates should be sent when the file is modified, changed, or saved.

(provide register-wakatime)
(define (register-wakatime)
  (begin
    ; FIXME: slow?
    ; This is called literally EVERY time the selection (cursor?) is changed.
    ; I don't think this is the right event to hook but it seems to be the most
    ; suitable one from the 6 or so that I can find
    (register-hook! 'selection-did-change (lambda (view-id) (send-heartbeat #false)))
    (register-hook! 'post-insert-char (lambda (event) (send-heartbeat #false)))
    (register-hook! 'document-saved (lambda (doc-id) (send-heartbeat #true)))))
