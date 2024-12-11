;; Title: Websocket stdio
;; Description: Pass stdio through a websocket
;; Author: AlexJGriffith
;; URL: https://codeberg.org/alexjgriffith/websocket-stdio
;; Version: 1.0 2024-11-24
;; Licence: GPL3+
;; Dependencies: lua-http, fennel
;; Extended Dependencies: getopt, lustache

;;;;; * Dependencies
(local fennel (require :lib.fennel))

(local _loader (require :luarocks.loader))
(local server (require :http.server))
(local headers (require :http.headers))
(local websocket (require :http.websocket))

;;;;; * Utilities
(local log
       (setmetatable
        {:file-handle nil
         :file-name "log~"
         :enabled true}
        {:__index
         {:open (fn [self file-name?]
                  (when file-name?
                    (set self.file-name file-name?))
                  (let [(ok handle) (pcall io.open self.file-name :w)]
                    (when ok (set self.file-handle handle))))
          :close (fn [self]
                   (when self.file-handle
                     (let [(ok) (pcall io.close self.file-handle)]
                       (when ok
                         (set self.file-handle nil)))))
          :log (fn [self message|handle? message?]
                 (local message (or message? message|handle?))
                 (local handle (when message? message|handle?))
                 (when (not self.file-handle)
                   (self:open))
                 (when self.file-handle
                   (when handle
                     (self.file-handle:write handle)
                     (self.file-handle:write " "))
                   (self.file-handle:write message)
                   (self.file-handle:write "\n")
                   (self.file-handle:flush)))
          :disable (fn [self] (set self.enabled false))
          :enable (fn [self] (set self.enabled true))}
         :__call (fn [self ...] (when self.enabled (self:log ...)))}))

(fn load-html [file-name internal-server-error?]
  (local internal-server-error
         (or internal-server-error?
             "<html>
<head><title>Page Load Error</title</head>
<body>
<p>The server failed to load the page requested</p>
</body
</html"))
  (let [(ok html)
        (pcall
         #(with-open [fin (io.open file-name)]
            (fin:read "*all")))]
    (if ok
        (values html 200)
        (values internal-server-error 500))))

(fn make-static-response [msg status content-type?]
  (fn [_s stream req-headers]
    (let [req-method (req-headers:get ::method)
          res-headers (headers.new)]
      (each [key value (pairs {::status (tostring status)
                               :content-type (or content-type? "text/html; charset=utf-8")
                               :Cross-Origin-Opener-Policy :same-origin
                               :Cross-Origin-Embedder-Policy :require-corp})]
        (res-headers:append key value))
      (assert (stream:write_headers res-headers (= req-method :HEAD)))
      (when (~= req-method :HEAD)
        (assert (stream:write_chunk msg true))))))

(fn make-static-page [page]
  (fn [_s stream req-headers]
    (local (msg status) (load-html page))
    (let [req-method (req-headers:get ::method)
          res-headers (headers.new)]
      (each [key value (pairs {::status (tostring status)
                               :content-type "text/html; charset=utf-8"
                               :Cross-Origin-Opener-Policy :same-origin
                               :Cross-Origin-Embedder-Policy :require-corp})]
        (res-headers:append key value))
      (assert (stream:write_headers res-headers (= req-method :HEAD)))
      (when (~= req-method :HEAD)
        (assert (stream:write_chunk msg true))))))

;;;;; * File Watcher
(local watcher
       (setmetatable
        {:dir "./"
         :check-period 0.1
         :last-modified 0}
        {:__index
         {:set-directory
          (fn [self dir]
            (set self.dir
                 (if (= "/" (dir:sub (# dir) (# dir))) dir (.. dir "/"))))

          :check-modified
          (fn [self callback dir?]
            (fn append-/ [dir] (if (= "/" (dir:sub (# dir) (# dir))) dir (.. dir "/")))
            (local lfs (require :lfs))
            (local dir (append-/ (or dir? self.dir)))            
            (each [file (lfs.dir dir)]
              (when (and (~= file ".") (~= file ".."))
                (local dfile (.. dir file))
                (local atts (lfs.attributes dfile))                
                (when atts
                  (match atts.mode
                    :file (when (> atts.modification self.last-modified)
                            (set self.last-modified atts.modification)
                            (callback self dfile atts))
                    :directory (self:check-modified callback dfile))))))
          
          :get-last-modified
          (fn [self]
            (self:check-modified (fn [self _file {: modification}]
                                   (set self.last-modified modification)))
            self.last-modified)
          
          :step
          (fn [self callback]
            (self:check-modified (fn [self file {: modification}]
                                   (set self.last-modified modification)
                                   (callback file))))
          
          :loop
          (fn [self callback]
            (local cqueues (require :cqueues))
            (self:get-last-modified)
            ;; there is an issue where it wont reset properly
            ;; for the first 2 file changes
            (while true
              (self:step callback)
              (cqueues.sleep self.check-period)))
          }}))

;;;;; * Server
(local r404 (make-static-response "404 - Page not found\n" 404))

(fn ws [ws-server stream req-headers]
  (log :*opening-new-websocket)
  (fn loop [ws]
    (match ws.got_close_code
      1000  (ws:close 1000 "Connection Closed")
      _ (match (ws:receive)
          msg (do
                (io.stdout:write msg)
                (log :*msg msg)
                (io.stdout:flush)
                (loop ws)))))
  ;; need to kill this when ws disconnects
  (fn stdin [handle ws]
    (fn loop []
      (local input (handle:read))
      (log :*stdin input)
      (log :*ws (-> ws (fennel.view {:one-line? true})))
      (ws:send input)
      (loop)))
  (let [res-headers (headers.new)]
    (match (req-headers:get :connection)
      :Upgrade (let [new-ws (websocket.new_from_stream stream req-headers)
                     (success? err err-no)  (new-ws:accept {:headers res-headers})]
                 (when err (log :*con-failed (-> [err err-no new-ws] (fennel.view {:one-line? true}))))
                 (when success?
                   (log :*con-success (-> new-ws (fennel.view {:one-line? true})))
                   (local cs (require "cqueues.socket"))
                   (ws-server.cq:wrap (stdin (cs.fdopen 0) new-ws))
                   (loop new-ws))))))

(fn file-change-events [_server stream _req-headers serve-directories]
  (let [res-headers (headers.new)]
    (if serve-directories
        (do
          (local serve-directory (. serve-directories 1))
          ;; only watch the first directory, we can get this to work with multiple
          ;; directories in the future
          (log :*file-change-events :Success!)
          (res-headers:append ::status :200)
          (res-headers:append :content-type :text/event-stream)
          (assert (stream:write_headers res-headers false))
          (set watcher.dir serve-directory)
          (set watcher.check-period 0.1)
          (assert (stream:write_chunk (.. ": comment"  "\n\n") false))
          ;; Seems to work better if I send one data chunk right away
          ;; a better solution would be valued.
          (assert (stream:write_chunk (.. "data: #connected"  "\n\n") false))
          (watcher:loop
           (fn [file]
             (log :*watcher file)
             (assert (stream:write_chunk (.. ": comment"  "\n\n") false))
             (assert (stream:write_chunk (.. "data: " (file:gsub serve-directory "") "\n\n") false)))
           serve-directory))
        (do
          (log :*file-change-events :Failed!)
          (res-headers:append ::status :500)
          (res-headers:append :content-type :text/text)
          (assert (stream:write_headers res-headers false))
          (assert (stream:write_chunk "Error 500: The server is not configured to host static pages." false))
          ))))

(fn make-paths [opts builtin]
       (let [path (if (and opts.b builtin)
                      ((. builtin opts.b :path) {:port opts.p})
                      opts.i
                      {:/ (make-static-page opts.i)})]
         (tset path :/ws ws)
         (tset path :/file-change-events file-change-events)
         path))

(fn err [ws-server ctx op err errno]
  (log :*err
       (string.format
        "%s on %s failed%s" op (tostring ctx)
        (if err (.. ": " (tostring err)) ""))))

(fn get-static-file [file-/ serve-directories]  
  (local lfs (require :lfs))
  (local file (file-/:sub 2 (# file-/)))
  (when serve-directories
    (each  [_ serve-directory  (ipairs serve-directories)]
      (local dfile (.. (or serve-directory "./") file))
      (local attrs (lfs.attributes dfile))
      (log :*serve-directory (or serve-directory "Not Defined!"))
      (log :*file  dfile)
      (log :*attrs  (-> attrs (fennel.view {:one-line? true})))
      (when (and serve-directory attrs (= attrs.mode :file))
        ;; return the first match you see
        (local fin (io.open dfile :r))
        (local str (and fin (fin:read :*all)))
        (when fin (fin:close))
        (when str
          (local content-type
                 (if
                  (dfile:find "%.wasm$") "application/wasm"
                  (dfile:find "%.js$") "text/javascript"
                  (dfile:find "%.html$") "text/html"
                  ))
          (local fun (make-static-response str 200 content-type))
          (lua "return fun"))))))

(fn new-server [opts builtin]
  (local port (or opts.p 9000))
  (local paths (make-paths opts builtin))
  (log:disable)
  (when opts.l
      (log:enable)
      (when (= :string (type opts.l))
        (set log.file-name opts.l)))
  (local serve-directories
         (when opts.d
         (do
         (fn process-directory [dir]
           (-> dir
               ((fn [dir]
                  (if (~= "./" (dir:sub 1 2))
                      (.. "./" dir)
                      dir)))
               ((fn [dir]
                  (if (~= "/" (dir:sub (# dir) (# dir)))
                      (.. dir "/")
                      dir)))))
         (icollect [dir (opts.d:gmatch "([^,]*)")]
           (when (~= dir "")
             (process-directory dir))))))
  (fn reply [s stream]
    (let [req-headers (assert (stream:get_headers))
          path-fun (or (. paths (req-headers:get ::path))
                       (get-static-file (req-headers:get ::path) serve-directories)
                       r404)]
      (log :*path  (req-headers:get ::path))
      (log :*headers (-> req-headers (fennel.view {:one-line? true})))
      (path-fun s stream req-headers serve-directories)))
  (local ws-server
         (assert (server.listen
                  {:host :localhost
                   :port port
                   :onstream reply
                   :onerror err})))
  ws-server)

{: new-server : watcher}
