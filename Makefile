all:
	@echo Run \'make install\' to install knbnBrd

install:
	@mkdir -p $(DESTDIR)/usr/bin
	@mkdir -p $(DESTDIR)/opt/knbn
	@mkdir board
	@cp -p board $(DESTDIR)/opt/knbn/board
	@cp -p knbn.sh $(DESTDIR)/usr/bin/knbn
	@cp -p LICENSE $(DESTDIR)/opt/knbn
	@cp -p NOTICE $(DESTDIR)/opt/knbn
	@chmod 755 $(DESTDIR)/usr/bin/knbn

uninstall:
	@rm -rf $(DESTDIR)/opt/knbn
	@rm $(DESTDIR)/usr/bin/knbn
