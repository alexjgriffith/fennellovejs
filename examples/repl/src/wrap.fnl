(local websockets (require :websockets))

(local repl (require :lib.step-repl))

(local state (require :src.state))
(set state.x 0)
(set state.y 0)
(set state.dx 1)
(set state.dy 1)
(set state.ws nil)

(local opts {:onValues (fn [vals]
                         (local {: ws} (require :src.state))
                         (ws:send_utf8_text (.. (table.concat vals "\t") "\n")))
             :onError (fn [_errtype err]
                        (local {: ws} (require :src.state))
                        (ws:send_utf8_text (.. (table.concat [err] "\t") "\n")))
             :moduleName "fennel"
             :stepped-repl true})

(tset state :stdio (repl opts))

;; (local address "wss://live.alexjgriffith.com/ws")

(fn update-html-window-size []
  (local js (require :js))
  (js.call "love_send_event(\"window-size\",JSON.stringify({\"w\": window.innerWidth, \"h\": window.innerHeight}))"))

(local address "ws://localhost:9000/ws")
(fn love.load []
  (pp websockets)
  (local state (require :src.state))
  (tset state :ws (websockets.new address))
  (local ws state.ws)
  (pp (getmetatable ws))
  (update-html-window-size)
  ;; (ws:send_utf8_text "Hello Server!")
  )

(fn love.userevent [name data code]
  (local state (require :src.state))
  (local ws state.ws)
  (local stdio state.stdio)
  (local welcome-message "Welcome to LoveJS!\n")
  (fn websocket-open []
    (ws:send_utf8_text  (.. welcome-message ">> "))
    (tset _G :print (fn [x] (ws:send_utf8_text (.. x "\n")))))

  (var ss 0)
  (fn websocket-message [data]
    (set ss (stdio  (.. data "\n")))
    (ws:send_utf8_text  (if (> ss 0) ".." ">> ")))

  (set love.handlers.window-size
       (fn [{: w : h &as data}]
         (pp data)
         (local (_ _ flags) (love.window.getMode))
         (love.window.setMode w h flags)
         (local js (require :js))
         (js.call (: "
Module[\"canvas\"].width=%d;
Module[\"canvas\"].height=%d;
" :format w h))
         ))
  (fn window-size [data]
    (local json (require :lib.json))
    (love.event.push :window-size (json.decode data)))
  
  (match name
    :websocketopen (websocket-open)
    :websocketmessage (websocket-message data)
    :window-size (window-size data)
    _ (pp [name data code])))

(local font (love.graphics.newFont :fallingsky.otf 80))
(love.graphics.setFont font)

(fn love.touchpressed [id x y dx dy pressure]
  (pp [:touchpressed id x y dx dy pressure]))

(fn love.mousepressed [id x y dx dy]
  (pp [:mousepressed id x y dx dy]))

(fn love.update [dt]
  (local {: x : dx &as state} (require :src.state))
  (tset state :x (+ x dx))
  (if (> (+ x 300) 600)
      (tset state :dx -1)
      (< x 0)
      (tset state :dx 1)))

(fn love.draw []
  ;; (print :test)
  (local pallets (require :src.pallets))
  (love.graphics.clear (unpack (. pallets.indecision 1)))
  (love.graphics.setColor (. pallets.indecision 17))
  (local (w h) (love.window.getMode))
  (love.graphics.printf "Testing StdIO over Websockets" 0 10 w  :center))

(fn love.draw []
  (local {: x : y} (require :src.state))
  (local pallets (require :src.pallets))
  (love.graphics.clear (unpack (. pallets.indecision 1)))
  (love.graphics.translate x y)
  (love.graphics.setColor (. pallets.indecision 12))
  (love.graphics.rectangle :fill 0 0 300 100)
  (love.graphics.setColor 0 0 0 1)
  (love.graphics.print "Update" 20 -10)
  )

(fn love.resize [w h]
  (pp [w h]))

;; env --chdir=/home/alexjgriffith/Github/lovejs-update/fennellovejs/ -S fennel -e '(local {: build-project} (require :buildtools.build-project)) (build-project :examples/repl/ :resources/)'

;; Local Variables:
;; love2d-fennel-program: "env --chdir=/home/alexjgriffith/Github/lovejs-update/fennellovejs/ -S fennel -e '(local {: build-project} (require :buildtools.build-project)) (build-project :examples/repl/ :resources/)' && env --chdir=/home/alexjgriffith/Github/lovejs-update/fennellovejs/ -S ./scripts/websocket-stdio -i resources/websocket-repl.html -d ./,resources/ -p 9000"
;; fennel-repl--buffer-name:"*LOVEJS REPL*"
;; End:

