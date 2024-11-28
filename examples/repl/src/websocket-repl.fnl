(local websockets (require :websockets))

(local welcome-message "Welcome to LoveJS!\n")
(var ws nil)
(var ss 0)
(var stdio nil)

(tset love.handlers
      :replwebsocketopen
       (fn [_data]
         (ws:send_utf8_text  (.. welcome-message ">> "))
         (tset _G :print (fn [x] (ws:send_utf8_text (.. x "\n"))))))

(tset love.handlers
      :replwebsocketmessage
       (fn [data]
         (set ss (stdio  (.. data "\n")))
         (ws:send_utf8_text  (if (> ss 0) ".." ">> "))))

(local opts {:onValues (fn [vals]
                         (ws:send_utf8_text (.. (table.concat vals "\t") "\n")))
             :onError (fn [_errtype err]
                        (ws:send_utf8_text (.. (table.concat [err] "\t") "\n")))
             :moduleName "fennel"
             :stepped-repl true})

;;(local address "ws://localhost:9000/ws")
(fn start [address]
  (set ws (websockets.new :repl address))
  (local repl (require :lib.step-repl))
  (set stdio (repl opts)))

{: start :get-ws (fn [] ws)}
