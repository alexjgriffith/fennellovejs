linux only .. for now

1. Download release or compat into cache
   linux: ~/.cache/love-release/lovejs/
   windows: %APPDATA%/love-release/lovejs/
2. symlink into resources/release or resources/compat 
   (not sure how to symlink on windows)
3. Replace information in preload.js, and index.html
   set global value lOVE2D_GAME to the name of the love file or leave it nil if you want to load a whole folder?
   


rm resources/game.data resources/game.metadata && fennel -e "(local {: build-project} (require :buildtools.build-project)) (build-project :examples/repl/ :resources/)" && cd resources && ../scripts/websocket-stdio -i websocket-repl.html -d ../,./ -p 9000 && cd ../
