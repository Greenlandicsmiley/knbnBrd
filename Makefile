all:
	@echo "Run 'make install' to install knbnBrd"
	@echo "Run 'make update' to update knbnBrd"
	@echo "Run 'make migrate' to copy board from old knbnBrd directory to new directory and delete old knbnBrd directory"

install:
	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/share/doc/knbnBrd
	cp -p knbn.sh $(DESTDIR)/usr/bin/knbn
	cp -p LICENSE $(DESTDIR)/usr/share/doc/knbnBrd
	cp -p NOTICE $(DESTDIR)/usr/share/doc/knbnBrd
	cp -p EXAMPLES $(DESTDIR)/usr/share/doc/knbnBrd
	chmod 755 $(DESTDIR)/usr/bin/knbn

update:
	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/share/doc/knbnBrd
	cp -p knbn.sh $(DESTDIR)/usr/bin/knbn
	cp -p LICENSE $(DESTDIR)/usr/share/doc/knbnBrd
	cp -p NOTICE $(DESTDIR)/usr/share/doc/knbnBrd
	cp -p EXAMPLES $(DESTDIR)/usr/share/doc/knbnBrd
	chmod 755 $(DESTDIR)/usr/bin/knbn
	@echo "View the changes on my github page"

migrate:
	cp -r -p /opt/knbnBrd/board $${HOME}/.local/share/knbnBrd
	rm -rf /opt/knbnBrd

uninstall:
	rm -rf $${HOME}/.local/share/knbnBrd
	rm -rf $(DESTDIR)/usr/share/doc/knbnBrd
	rm $(DESTDIR)/usr/bin/knbn