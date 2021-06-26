all:
	@echo "Run 'make install' to install knbnBrd"
	@echo "Run 'make update' to update knbnBrd"
	@echo "Run 'make migrate' to migrate old knbnBrd /opt dir to new /opt dir"

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
	@echo "Changes since last version:"
	@echo "Ability to add/remove notes\\nMoving tasks include notes\\nAbility to migrate to new opt dir\\nProper syntax to knbn command (run knbn help to see new syntax)"
	@cho "Ability to backup columns and the entire board (knbn help to see more info)"

migrate:
	@mv $(DESTDIR)/opt/knbn $(DESTDIR)/opt/knbnBrd
	@cp -p knbn.sh $(DESTDIR)/usr/bin/knbn
	@cp -p NOTICE $(DESTDIR)/opt/knbnBrd
	@chmod 755 $(DESTDIR)/usr/bin/knbn
	@echo "Changes since last version:"
	@echo "Ability to add/remove notes\\nMoving tasks include notes\\nAbility to migrate to new opt dir\\nProper syntax to knbn command (run knbn help to see new syntax)"
	@cho "Ability to backup columns and the entire board (knbn help to see more info)"

uninstall:
	@rm -rf $(DESTDIR)/opt/knbnBrd
	@rm $(DESTDIR)/usr/bin/knbn
