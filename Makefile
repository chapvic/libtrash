LIBNAME=libtrash

LIBFILE=$(LIBNAME).so
CONFIG=.$(LIBNAME)

MAJOR=3
VERSION=3.3

PREFIX=/usr/local

INSTALL_LIB=$(PREFIX)/lib
INSTALL_BIN=$(PREFIX)/bin

CC=gcc
CFLAGS=-O2 -Wmissing-prototypes -D_REENTRANT

SRC=src/main.c src/helpers.c src/unlink.c src/rename.c src/open-funs.c

STRASH=utils/strash-0.9/strash
TCLEAN=utils/tclean

all: $(LIBFILE)

$(LIBFILE): $(SRC)
	@echo -n "Checking for a working proc filesystem... "
	@ls -d /proc/self/fd
	@$(CC) -o link-helper link-helper.c
	@./makeconfig
	@rm -f link-helper
	$(CC) $(CFLAGS) $(SRC) -nostartfiles -shared -fPIC -Wl,-soname,$@ -o $@ -ldl

config:
	TRASH_OFF=YES install -m 644 $(CONFIG) $(HOME)

install:
	TRASH_OFF=YES install $(LIBFILE) $(INSTALL_LIB)
	TRASH_OFF=YES ln -sf $(LIBFILE) $(INSTALL_LIB)/$(LIBFILE).$(MAJOR)
	TRASH_OFF=YES ln -sf $(LIBFILE) $(INSTALL_LIB)/$(LIBFILE).$(VERSION)
	TRASH_OFF=YES install $(STRASH) $(INSTALL_BIN)
	TRASH_OFF=YES install $(TCLEAN) $(INSTALL_BIN)
	ldconfig

uninstall:
	TRASH_OFF=YES rm -f $(INSTALL_LIB)/$(LIBFILE).$(VERSION)
	TRASH_OFF=YES rm -f $(INSTALL_LIB)/$(LIBFILE).$(MAJOR)
	TRASH_OFF=YES rm -f $(INSTALL_LIB)/$(LIBFILE)
	TRASH_OFF=YES rm -f $(INSTALL_BIN)/tclean
	TRASH_OFF=YES rm -f $(INSTALL_BIN)/strash
	TRASH_OFF=YES rm -f $(HOME)/$(CONFIG)
	ldconfig

clean:
	@rm -f *~
	@rm -f *.o
	@rm -f src/config.h
	@rm -f $(LIBFILE)

.PHONY: all install uninstall clean
