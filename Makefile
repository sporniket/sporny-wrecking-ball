SUBDIRS := 10_wrecking_ball  20_font_extractor  20_font_generator  20_level_generator  20_sheet_extractor  30_check_hardware

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

# aliases for the CLI
swb: 10_wrecking_ball

fontext: 20_font_extractor

fontgen: 20_font_generator

lvlgen: 20_level_generator

sheetext: 20_sheet_extractor

checkhw: 30_check_hardware

# end of aliases
.PHONY: all clean $(SUBDIRS)

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) clean -C $$dir; \
	done
