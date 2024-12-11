serve:
	fennel -e "(local {: build-project} (require :src.build-project)) (build-project :examples/repl/ :resources/)"
	env --chdir=/home/alexjgriffith/Github/fennellovejs/ -S ./scripts/websocket-stdio -i resources/shell.html -d ./examples/repl,resources -p 9000 -l log~ -t "0.0.0.0"

setup:
	$(shell ./scripts/download-lovejs.sh)

clean:
	rm resources/game.data resources/game.metadata

lovefile:
	$(shell cd game && find -type f | LC_ALL=C sort | env TZ=UTC zip -r -q -9 -X ../${LOVEFILE} -@)
