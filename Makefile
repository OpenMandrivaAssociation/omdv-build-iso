# 2014 Author: tpgxyz@gmail.com

NAME = omdv-build-iso
VERSION = 0.0.6
DATAFILE ?= $(DESTDIR)/usr/share/$(NAME)
BINFILE ?= $(DESTDIR)/usr/bin

all:
install:
	-install -d $(BINFILE)
	-install -d $(DATAFILE)
	-install -d $(DATAFILE)/EFI
	-install -d $(DATAFILE)/data
	-install -d $(DATAFILE)/dracut
	-install -d $(DATAFILE)/dracut/90liveiso
	-install -d $(DATAFILE)/extraconfig
	-install -d $(DATAFILE)/tools
	-install -d $(DATAFILE)/iso-pkg-lists-cooker
	-install -d $(DATAFILE)/iso-pkg-lists-openmandriva2014.0
	install -m 755 omdv-build-iso.sh $(BINFILE)
	cp -fr EFI/* $(DATAFILE)/EFI/
	cp -fr data/* $(DATAFILE)/data/
	cp -fr dracut/* $(DATAFILE)/dracut/
	cp -fr iso-pkg-lists-cooker/* $(DATAFILE)/iso-pkg-lists-cooker/
	cp -fr iso-pkg-lists-openmandriva2014.0/* $(DATAFILE)/iso-pkg-lists-openmandriva2014.0/
	cp -fr extraconfig/* $(DATAFILE)/extraconfig/
	install -m 644 tools/* $(DATAFILE)/tools/

dist:
	git archive --format=tar --prefix=$(NAME)-$(VERSION)/ HEAD | xz -2vec -T0 > $(NAME)-$(VERSION).tar.xz;
	$(info $(NAME)-$(VERSION).tar.xz is ready)

PHONY: ChangeLog log changelog

log: ChangeLog

changelog: ChangeLog


ChangeLog:
	@if test -d "$$PWD/.git"; then \
	    git --no-pager log --format="%ai %aN %n%n%x09* %s%d%n" > $@.tmp \
	    && mv -f $@.tmp $@ \
	    && git commit ChangeLog -m 'generated changelog' \
	    || (rm -f  $@.tmp; \
	    echo Failed to generate ChangeLog, your ChangeLog may be outdated >&2; \
	    (test -f $@ || echo git-log is required to generate this file >> $@)); \
	fi;