include ../folders.local.mk
include ../tools.mk
include ../dependencies.local.mk
include dependencies.local.mk

font_ext.prg: $(SRCS) $(ASSETS) $(COMMONS_MACROS) $(COMMONS_LIBS)
	$(AS) $(ASARGS) -o $@ _main.s
	cp $@ $(INSTALLDIR)


.PHONY: clean

clean:
	rm *.prg
	rm $(INSTALLDIR)/font_ext.prg
