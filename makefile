MEGASOURCE=$(CURDIR)/../megasource
EMSDK=$(CURDIR)/../emsdk

serve:
	$(shell cd resources && ../scripts/serve.py)


compile:
	./scripts/build.sh $(MEGASOURCE) $(EMSDK)


pack-template:
	./scripts/template-preload.sh $(EMSDK) $(CURDIR)/examples/repl game.data

