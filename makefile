serve:
	$(shell fennel -e "(local {: build-project} (require :buildtools.build-project)) (build-project :examples/repl/ :resources/)")
	$(shell cd resources && ../scripts/websocket-stdio -i websocket-repl.html -d ../,./ -p 9000)

setup:
	$(shell ./scripts/download-lovejs.sh)

clean:
	rm resources/game.data resources/game.metadata

lovefile:
	$(shell cd game && find -type f | LC_ALL=C sort | env TZ=UTC zip -r -q -9 -X ../${LOVEFILE} -@)
