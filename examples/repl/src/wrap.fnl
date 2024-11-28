(local state (require :src.state))

(fn update-html-window-size []
  (when (= :Web (love.system.getOS))
    (local js (require :js))
    (js.call "love_send_event(\"window-resize\",JSON.stringify({\"w\": window.innerWidth, \"h\": window.innerHeight}))")))

(fn love.load []
  (when (= :Web (love.system.getOS))
    (local websocket-repl (require :src.websocket-repl))
    (websocket-repl.start "ws://192.168.0.18:9000/ws")
    ;; (websocket-repl.start "ws://localhost:9000/ws")
    (update-html-window-size))
  (set state.x 0)
  (set state.y 0)
  (set state.dx 1)
  (set state.dy 1))

(set love.handlers.fileupload
     (fn [filename]
       (pp filename)))


(set love.handlers.log
     (fn [str]
       (pp str)))

(set love.handlers.window-resize
     (fn [jsondata]
       (local json (require :lib.json))
       (local {: w : h &as data} (json.decode jsondata))
       (local (_ _ flags) (love.window.getMode))
       ;; (love.window.setMode w h flags)
;;        (local js (require :js))
;;        (js.call (: "
;; Module[\"canvas\"].width=%d; 
;; Module[\"canvas\"].height=%d;
;; " :format w h))
       ))

;; (fn love.userevent [name data code]
;;   (fn safe-push [handle ...]
;;     (let [args [...]]
;;       (pcall (fn []
;;                (when (. love.handlers handle)
;;                  (love.event.push handle (unpack args)))))))
;;   (when (not (safe-push name data code))
;;     (pp [name data code])))

(local font (love.graphics.newFont :fallingsky.otf 80))
(love.graphics.setFont font)

(fn love.touchpressed [id x y dx dy pressure]
  (pp [:touchpressed id x y dx dy pressure]))

(fn love.touchreleased [id x y dx dy pressure]
  (pp [:touchreleased id x y dx dy pressure]))

(fn love.touchmoved [id x y dx dy pressure]
  (pp [:touchmoved id x y dx dy pressure]))

(fn love.update [dt]
  (local speed 1)
  (local {: x : dx &as state} (require :src.state))
  (tset state :x (+ x dx))
  (if (> (+ x 300) 600)
      (tset state :dx (* speed -1))
      (< x 0)
      (tset state :dx (* speed 1))))

(fn love.draw []
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
  (love.graphics.setColor (. pallets.indecision 10))
  (love.graphics.rectangle :fill 0 0 300 100)
  (love.graphics.setColor (. pallets.indecision 17))
  (love.graphics.print "Update" 20 -10))



(fn love.resize [w h] )

;; env --chdir=/home/alexjgriffith/Github/lovejs-update/fennellovejs/ -S fennel -e '(local {: build-project} (require :buildtools.build-project)) (build-project :examples/repl/ :resources/)'

;; Local Variables:
;; love2d-fennel-program: "env --chdir=/home/alexjgriffith/Github/lovejs-update/fennellovejs/ -S fennel -e '(local {: build-project} (require :buildtools.build-project)) (build-project :examples/repl/ :resources/)' && env --chdir=/home/alexjgriffith/Github/lovejs-update/fennellovejs/ -S ./scripts/websocket-stdio -i resources/websocket-repl.html -d ./examples/repl,resources -p 9000 -l log~ -t \"0.0.0.0\""
;; fennel-repl--buffer-name:"*LOVEJS REPL*"
;; End:

