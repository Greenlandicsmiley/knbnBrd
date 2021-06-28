all:
	@echo "Run 'make install' to install knbnBrd"
	@echo "Run 'make update' to update knbnBrd"

install:
	@mkdir -p $(DESTDIR)/usr/bin
	@mkdir -p $(DESTDIR)/opt/knbnBrd
	@cp -r -p board $(DESTDIR)/opt/knbnBrd/board
	@cp -p knbn.sh $(DESTDIR)/usr/bin/knbn
	@cp -p LICENSE $(DESTDIR)/opt/knbnBrd
	@cp -p NOTICE $(DESTDIR)/opt/knbnBrd
	@chmod 755 $(DESTDIR)/usr/bin/knbn

update:
	@cp -p knbn.sh $(DESTDIR)/usr/bin/knbn
	@cp -p NOTICE $(DESTDIR)/opt/knbnBrd
	@chmod 755 $(DESTDIR)/usr/bin/knbn
	@echo "View the changes on my github page"

uninstall:
	@rm -rf $(DESTDIR)/opt/knbnBrd
	@rm $(DESTDIR)/usr/bin/knbn
