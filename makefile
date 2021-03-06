BINDIR = /usr/bin
BINNAME = clight
SYSTEMDDIR = /usr/lib/systemd/user/
SYSTEMDUNIT = clight.service
SYSTEMDTIMER = clight.timer
EXTRADIR = Extra
CONFDIR = /etc/default
CONFNAME = clight.conf
ICONSDIR = /usr/share/icons/hicolor/scalable/apps
ICONNAME = clight.svg
DESKTOPDIR = /usr/share/applications
LICENSEDIR = /usr/share/licenses/clight
COMPLNAME = clight
COMPLDIR = $(shell pkg-config --variable=completionsdir bash-completion)
BUSSERVICEDIR = /usr/share/dbus-1/services/
BUSSERVICENAME = org.clight.clight.service

RM = rm -f
RMDIR = rm -rf
INSTALL = install -p
INSTALL_PROGRAM = $(INSTALL) -m755
INSTALL_DATA = $(INSTALL) -m644
INSTALL_DIR = $(INSTALL) -d
SRCDIR = src/
LIBS = -lm $(shell pkg-config --libs popt gsl libconfig)
CFLAGS = $(shell pkg-config --cflags popt gsl libconfig) -DCONFDIR=\"$(CONFDIR)\" -D_GNU_SOURCE -std=c99

FOLDERS = $(subst src,.,$(sort $(dir $(wildcard $(SRCDIR)*/))))
SRCS = $(addsuffix *.c, $(FOLDERS))
INCS = $(addprefix -I, $(FOLDERS))

ifeq (,$(findstring $(MAKECMDGOALS),"clean install uninstall"))

ifeq ("$(shell pkg-config --exists libelogind && echo yes)", "yes")
ELOGIND_VERSION = $(shell pkg-config --modversion libelogind | head -c 3)
LIBS+=$(shell pkg-config --libs libelogind)
CFLAGS+=$(shell pkg-config --cflags libelogind) -DLIBSYSTEMD_VERSION=$(ELOGIND_VERSION)
else
ifeq ("$(shell pkg-config --atleast-version=221 systemd && echo yes)", "yes")
SYSTEMD_VERSION = $(shell pkg-config --modversion systemd)
LIBS+=$(shell pkg-config --libs libsystemd)
CFLAGS+=$(shell pkg-config --cflags libsystemd) -DLIBSYSTEMD_VERSION=$(SYSTEMD_VERSION)
else
$(error systemd minimum required version 221.)
endif
endif

endif

CLIGHT_VERSION = $(shell git describe --abbrev=0 --always --tags)
CFLAGS+=-DVERSION=\"$(CLIGHT_VERSION)\"

all: clight clean

debug: clight-debug clean

objects:
	@cd $(SRCDIR); $(CC) -c $(SRCS) $(CFLAGS) $(INCS) -Ofast

objects-debug:
	@cd $(SRCDIR); $(CC) -c *.c -Wall $(SRCS) $(CFLAGS) $(INCS) -Wshadow -Wstrict-overflow -Wtype-limits -fno-strict-aliasing -Wformat -Wformat-security -g

clight: objects
	@cd $(SRCDIR); $(CC) -o ../$(BINNAME) *.o $(LIBS) 

clight-debug: objects-debug
	@cd $(SRCDIR); $(CC) -o ../$(BINNAME) *.o $(LIBS)

clean:
	@cd $(SRCDIR); $(RM) *.o

install:
	$(info installing bin.)
	@$(INSTALL_DIR) "$(DESTDIR)$(BINDIR)"
	@$(INSTALL_PROGRAM) $(BINNAME) "$(DESTDIR)$(BINDIR)"
	
	$(info installing conf file.)
	@$(INSTALL_DIR) "$(DESTDIR)$(CONFDIR)"
	@$(INSTALL_DATA) $(EXTRADIR)/$(CONFNAME) "$(DESTDIR)$(CONFDIR)"

	$(info installing systemd unit and timer.)
	@$(INSTALL_DIR) "$(DESTDIR)$(SYSTEMDDIR)"
	@$(INSTALL_DATA) $(EXTRADIR)/systemd/$(SYSTEMDUNIT) "$(DESTDIR)$(SYSTEMDDIR)"
	@$(INSTALL_DATA) $(EXTRADIR)/systemd/$(SYSTEMDTIMER) "$(DESTDIR)$(SYSTEMDDIR)"
	
	$(info installing icon.)
	@$(INSTALL_DIR) "$(DESTDIR)$(ICONSDIR)"
	@$(INSTALL_DATA) $(EXTRADIR)/icons/$(ICONNAME) "$(DESTDIR)$(ICONSDIR)"
	
	$(info installing desktop file.)
	@$(INSTALL_DIR) "$(DESTDIR)$(DESKTOPDIR)"
	@$(INSTALL_DATA) $(EXTRADIR)/desktop/clightc.desktop "$(DESTDIR)$(DESKTOPDIR)"
	
	$(info installing license file.)
	@$(INSTALL_DIR) "$(DESTDIR)$(LICENSEDIR)"
	@$(INSTALL_DATA) COPYING "$(DESTDIR)$(LICENSEDIR)"
	
	$(info installing bash autocompletion.)
	@$(INSTALL_DIR) "$(DESTDIR)$(COMPLDIR)"
	@$(INSTALL_DATA) $(EXTRADIR)/$(COMPLNAME) "$(DESTDIR)$(COMPLDIR)/$(COMPLNAME)"
	
	$(info installing dbus service file.)
	@$(INSTALL_DIR) "$(DESTDIR)$(BUSSERVICEDIR)"
	@$(INSTALL_DATA) $(EXTRADIR)/$(BUSSERVICENAME) "$(DESTDIR)$(BUSSERVICEDIR)"

uninstall:
	$(info uninstalling bin.)
	@$(RM) "$(DESTDIR)$(BINDIR)/$(BINNAME)"
	
	$(info uninstalling conf file.)
	@$(RM) "$(DESTDIR)$(CONFDIR)/$(CONFNAME)"

	$(info uninstalling systemd unit and timer.)
	@$(RM) "$(DESTDIR)$(SYSTEMDDIR)/$(SYSTEMDUNIT)"
	@$(RM) "$(DESTDIR)$(SYSTEMDDIR)/$(SYSTEMDTIMER)"
	
	$(info uninstalling icon.)
	@$(RM) "$(DESTDIR)$(ICONSDIR)/$(ICONNAME)"
	
	$(info uninstalling desktop file.)
	@$(RM) "$(DESTDIR)$(DESKTOPDIR)/clightc.desktop"
	
	$(info uninstalling license file.)
	@$(RMDIR) "$(DESTDIR)$(LICENSEDIR)"
	
	$(info uninstalling bash autocompletion.)
	@$(RM) "$(DESTDIR)$(COMPLDIR)/$(COMPLNAME)"
	
	$(info uninstalling dbus service file.)
	@$(RM) "$(DESTDIR)$(BUSSERVICEDIR)/$(BUSSERVICENAME)"
