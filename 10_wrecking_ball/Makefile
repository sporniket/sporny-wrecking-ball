include ../folders.local.mk
include ../tools.mk
include ../dependencies.local.mk
include dependencies.local.mk

swb.prg: $(SRCS) $(INCLUDES) $(ASSETS) $(COMMONS_MACROS) $(COMMONS_LIBS)
	$(AS) $(ASARGS) -o $@ _main.s
	cp $@ $(INSTALLDIR)


.PHONY: clean

clean:
	rm *.prg
	rm $(INSTALLDIR)/swb.prg
