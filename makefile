MEGASOURCE=$(CURDIR)/../megasource
EMSDK=$(CURDIR)/../emsdk

## need to fix websocket-stdio to use the inital pwd as the root rather than the
## or serve multiple directories, seperated by a "," with deterministic prioritization?
serve:
	$(shell fennel -e "(local {: build-project} (require :buildtools.build-project)) (build-project :examples/repl/ :resources/)" && cd resources && ../scripts/websocket-stdio -i websocket-repl.html -d ../,./ -p 9000)

clean:
	rm resources/game.data resources/game.metadata

compile:
	./scripts/build.sh $(MEGASOURCE) $(EMSDK)

pack-template:
	./scripts/template-preload.sh $(EMSDK) $(CURDIR)/examples/repl game.data

lovefile:
	$(shell cd game && find -type f | LC_ALL=C sort | env TZ=UTC zip -r -q -9 -X ../${LOVEFILE} -@)
