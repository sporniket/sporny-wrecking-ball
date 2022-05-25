SUBDIRS := 10_wrecking_ball 20_sheet_extractor

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

# aliases for the CLI
swb: 10_wrecking_ball

sheetext: 20_sheet_extractor

# end of aliases
.PHONY: all clean $(SUBDIRS)

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) clean -C $$dir; \
	done
