# Build StumpWM from its source checkout and wire this configuration
# into the X session.
#
#   make            build the stumpwm image in the source checkout
#   make install    install the image, link the config, install the session
#   make check      report whether everything is wired up
#
# Every path below can be overridden on the command line, e.g.
#   make install PREFIX=$HOME/.local SUDO=

LISP_WORKSPACE ?= $(HOME)/SourceCode/lisp
WORKSPACE      := $(patsubst %/,%,$(LISP_WORKSPACE))
STUMPWM_SRC    ?= $(WORKSPACE)/stumpwm
CONTRIB_DIR    ?= $(WORKSPACE)/stumpwm-contrib

PREFIX         ?= /usr/local
BINDIR         ?= $(PREFIX)/bin
SBCL           ?= $(BINDIR)/sbcl
XSESSIONS_DIR  ?= /usr/share/xsessions
STUMPWM_D      ?= $(HOME)/.stumpwm.d
SUDO           ?= sudo

CONFIG_DIR     := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: all build install install-stumpwm link install-session check clean

all: build

# configure bakes the lisp path and the module directory into the
# generated Makefile, so rerun it whenever its inputs change.
$(STUMPWM_SRC)/configure: $(STUMPWM_SRC)/configure.ac
	cd $(STUMPWM_SRC) && ./autogen.sh

$(STUMPWM_SRC)/Makefile: $(STUMPWM_SRC)/configure $(STUMPWM_SRC)/Makefile.in $(CONFIG_DIR)/Makefile
	cd $(STUMPWM_SRC) && ./configure --prefix=$(PREFIX) \
		--with-lisp=sbcl \
		--with-module-dir=$(STUMPWM_D)/modules \
		LISP=$(SBCL)

build: $(STUMPWM_SRC)/Makefile
	$(MAKE) -C $(STUMPWM_SRC)

install: install-stumpwm link install-session

install-stumpwm: build
	$(SUDO) $(MAKE) -C $(STUMPWM_SRC) install

# Link the config into ~/.stumpwm.d, but never replace a real file or
# directory that is already sitting there.
link:
	@mkdir -p $(STUMPWM_D)
	@for pair in "init.lisp:$(CONFIG_DIR)/init.lisp" "modules:$(CONTRIB_DIR)"; do \
		name=$${pair%%:*}; target=$${pair#*:}; dest="$(STUMPWM_D)/$$name"; \
		if [ -e "$$dest" ] && [ ! -L "$$dest" ]; then \
			echo "refusing to replace $$dest: it is not a symlink" >&2; exit 1; \
		fi; \
		ln -sfn "$$target" "$$dest" && echo "$$dest -> $$target"; \
	done

# The session file runs start-stumpwm. It is installed as a copy so the
# login manager never depends on a home directory; after editing
# start_stumpwm.sh, run make install-session again to update it.
install-session:
	$(SUDO) rm -f $(BINDIR)/start-stumpwm
	$(SUDO) install -D -m 755 $(CONFIG_DIR)/start_stumpwm.sh $(BINDIR)/start-stumpwm
	$(SUDO) install -D -m 644 $(CONFIG_DIR)/stumpwm.desktop $(XSESSIONS_DIR)/stumpwm.desktop

check:
	@status=0; \
	ok()   { echo "  ok    $$1"; }; \
	fail() { echo "  FAIL  $$1"; status=1; }; \
	[ -x $(BINDIR)/stumpwm ] && ok "$(BINDIR)/stumpwm" || fail "$(BINDIR)/stumpwm is missing"; \
	if [ -x $(STUMPWM_SRC)/stumpwm ] && [ -x $(BINDIR)/stumpwm ]; then \
		cmp -s $(STUMPWM_SRC)/stumpwm $(BINDIR)/stumpwm \
			&& ok "installed image matches the build" \
			|| fail "installed image differs from the build (run make install)"; \
	fi; \
	if [ ! -x $(BINDIR)/start-stumpwm ]; then fail "$(BINDIR)/start-stumpwm is missing"; \
	elif [ -L $(BINDIR)/start-stumpwm ]; then fail "$(BINDIR)/start-stumpwm is a symlink (run make install-session)"; \
	elif cmp -s $(CONFIG_DIR)/start_stumpwm.sh $(BINDIR)/start-stumpwm; then ok "$(BINDIR)/start-stumpwm"; \
	else fail "$(BINDIR)/start-stumpwm differs from start_stumpwm.sh (run make install-session)"; fi; \
	[ -f $(XSESSIONS_DIR)/stumpwm.desktop ] && ok "$(XSESSIONS_DIR)/stumpwm.desktop" || fail "session file is missing"; \
	[ "$$(readlink -f $(STUMPWM_D)/init.lisp)" = "$(CONFIG_DIR)/init.lisp" ] \
		&& ok "$(STUMPWM_D)/init.lisp" || fail "$(STUMPWM_D)/init.lisp does not point at this config"; \
	[ "$$(readlink -f $(STUMPWM_D)/modules)" = "$$(readlink -f $(CONTRIB_DIR))" ] \
		&& ok "$(STUMPWM_D)/modules" || fail "$(STUMPWM_D)/modules does not point at $(CONTRIB_DIR)"; \
	exit $$status

clean:
	$(MAKE) -C $(STUMPWM_SRC) clean
