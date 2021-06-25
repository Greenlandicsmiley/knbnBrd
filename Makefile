all:
	@echo Run \'make install\' to install knbnBrd

install:
	@mkdir -p $(DESTDIR)/usr/bin
	@mkdir -p $(DESTDIR)/opt/knbn
	@cp -r -p board $(DESTDIR)/opt/knbn/board
	@cp -p knbn.sh $(DESTDIR)/usr/bin/knbn
	@cp -p LICENSE $(DESTDIR)/opt/knbn
	@cp -p NOTICE $(DESTDIR)/opt/knbn
	@chmod 755 $(DESTDIR)/usr/bin/knbn

update:
	@cp -p knbn.sh $(DESTDIR)/usr/bin/knbn
	@cp -p NOTICE $(DESTDIR)/opt/knbn
	@chmod 755 $(DESTDIR)/usr/bin/knbn
	@echo "Changes since last version: Ability to update without doing manual work through this makefile"

uninstall:
	@rm -rf $(DESTDIR)/opt/knbn
	@rm $(DESTDIR)/usr/bin/knbn
