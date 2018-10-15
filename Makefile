NAME=rfid-reader
BUILDDIR=/dev/shm/$(NAME)
TARGET=$(BUILDDIR)/$(NAME).elf
DATE=$(shell git log -n 1 --date=short --pretty=format:%cd)
COMMIT=$(shell git log -n 1 --pretty=format:%h)

BUILDSRC:=$(BUILDDIR)/Makefile
CONSOLESRC:=$(BUILDDIR)/console.c
CORESRC:=$(BUILDDIR)/rfid-reader.c
DRIVERSRC:=$(BUILDDIR)/uart.c
EPIGYNYSRC:=$(BUILDDIR)/epigyny.c
PAYLOADSRC:=$(BUILDDIR)/rfid_payload.c
PROTOSRC:=$(BUILDDIR)/packet.c $(BUILDDIR)/protocol.tr
UTILITYSRC:=$(BUILDDIR)/utility.c $(BUILDDIR)/ring.c $(BUILDDIR)/sbtree.c $(BUILDDIR)/stack.c $(BUILDDIR)/defination.h $(BUILDDIR)/hash.c $(BUILDDIR)/base64.c
RFIDSRC:=$(BUILDDIR)/rfid.c $(BUILDDIR)/rfid.h
RFIDFSMSRC:=$(BUILDDIR)/rfid-fsm.c
COREFSMSRC:=$(BUILDDIR)/core-fsm.c
TASKFSMSRC:=$(BUILDDIR)/task-fsm.c
PROTOFSMSRC:=$(BUILDDIR)/proto-fsm.c

LIBRARY:=$(BUILDDIR)/libopencm3
CONFIG:=$(BUILDDIR)/config
CONFIGSRC:=$(BUILDDIR)/config.orig

include .config

all: $(TARGET)


DEPENDS=$(BUILDSRC) $(CONSOLESRC) $(CORESRC) $(COREFSMSRC) $(DRIVERSRC) $(EPIGYNYSRC) $(PAYLOADSRC) $(PROTOSRC) $(PROTOFSMSRC) $(RFIDFSMSRC) $(RFIDSRC) $(TASKFSMSRC) $(UTILITYSRC) $(LIBRARY) $(CONFIGSRC)

$(TARGET): $(DEPENDS)
	cp $(CONFIGSRC) $(CONFIG)
	sed 'a \RFID_READER_ID=1' $(CONFIGSRC) > $(CONFIG)
	cd $(BUILDDIR); make; cd -

$(BUILDSRC): build.org | prebuild
	org-tangle $<
	sed -i 's/        /\t/g' $@
	sed -i 's/        /\t/g' $(BUILDDIR)/libopencm3.rules.mk
	sed -i 's/        /\t/g' $(BUILDDIR)/libopencm3.target.mk
$(CONSOLESRC): console.org | prebuild
	org-tangle $<
$(CORESRC): core.org | prebuild
	org-tangle $<
$(DRIVERSRC): driver.org | prebuild
	org-tangle $<
$(EPIGYNYSRC): epigyny.org | prebuild
	org-tangle $<
$(PROTOSRC): protocol.org | prebuild
	org-tangle $<
$(RFIDSRC): rfid.org | prebuild
	org-tangle $<
$(UTILITYSRC): utility.org | prebuild
	org-tangle $<

$(RFIDFSMSRC): rfid-fsm.csv | prebuild
	fsm-generator.py $< -d $(BUILDDIR) --prefix rfid --style table
#	fsm-generator.py $< -d $(BUILDDIR) --prefix rfid --style table --debug
#	sed -i '1a#include "console.h"' $@
#	sed -i '1d' $@
#	sed -i 's/printf(\"(\");/console_log(\"(\");/g' $@
#	sed -i 's/printf/console_string/g' $@
#	sed -i 's/\\n/\\r\\n/g' $@

$(TASKFSMSRC): task-fsm.csv | prebuild
	fsm-generator.py $< -d $(BUILDDIR) --prefix task --style table
#	fsm-generator.py $< -d $(BUILDDIR) --prefix task --style table --debug
#	sed -i '1a#include "console.h"' $@
#	sed -i '1d' $@
#	sed -i 's/printf(\"(\");/console_log(\"(\");/g' $@
#	sed -i 's/printf/console_string/g' $@
#	sed -i 's/\\n/\\r\\n/g' $@

$(COREFSMSRC): core-fsm.csv | prebuild
	fsm-generator.py $< -d $(BUILDDIR) --prefix core --style table
#	fsm-generator.py $< -d $(BUILDDIR) --prefix core --style table --debug
#	sed -i '1a#include "console.h"' $@
#	sed -i '1d' $@
#	sed -i 's/printf(\"(\");/console_log(\"(\");/g' $@
#	sed -i 's/printf/console_string/g' $@
#	sed -i 's/\\n/\\r\\n/g' $@

$(PROTOFSMSRC): proto-fsm.csv | prebuild
	fsm-generator.py $< -d $(BUILDDIR) --prefix proto --style table
#	fsm-generator.py $< -d $(BUILDDIR) --prefix proto --style table --debug
#	sed -i '1a#include "console.h"' $@
#	sed -i '1d' $@
#	sed -i 's/printf(\"(\");/console_log(\"(\");/g' $@
#	sed -i 's/printf/console_string/g' $@
#	sed -i 's/\\n/\\r\\n/g' $@

$(PAYLOADSRC): $(BUILDDIR)/protocol.tr | prebuild
	tightrope -entity -serial -clang -d $(BUILDDIR) $<

$(LIBRARY):
	ln -sf $(LIBOPENCM3) $(BUILDDIR)

flash: $(TARGET)
	cd $(BUILDDIR); make flash V=1; cd -

prebuild:
ifeq "$(wildcard $(BUILDDIR))" ""
	@mkdir -p $(BUILDDIR)
endif

clean:
	rm -rf $(BUILDDIR)

.PHONY: all clean flash prebuild
