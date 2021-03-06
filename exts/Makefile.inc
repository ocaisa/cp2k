ifeq ("","$(wildcard $(EXTSHOME)/dbcsr/Makefile)")
$(error "No DBCSR submodule available, please run 'git submodule update --init --recursive'")
endif

LIBS     := -L$(LIBEXTSDIR)/dbcsr -ldbcsr $(LIBS)
EXTSDEPS_LIB  = $(LIBEXTSDIR)/dbcsr/libdbcsr.a
EXTSDEPS_MOD = $(OBJEXTSDIR)/dbcsr/dbcsr_api.mod $(OBJEXTSDIR)/dbcsr/dbcsr_tensor_api.mod
$(EXTSDEPS_MOD) : ; # override builtin .mod rule to prevent circular dependency

extversions: dbcsrversion

extclean: dbcsrclean
	@echo "Clean EXT"

dbcsr:
	$(MAKE) -C $(EXTSHOME)/$@ \
	   INCLUDEMAKE=$(ARCHDIR)/$(ARCH).$(ONEVERSION) \
	   LIBDIR=$(LIBEXTSDIR)/$@ \
	   OBJDIR=$(OBJEXTSDIR)/$@ \
	   FYPPEXE=$(TOOLSRC)/build_utils/fypp

dbcsrversion:
	@$(MAKE) -C $(EXTSHOME)/dbcsr \
	   FYPPEXE=$(TOOLSRC)/build_utils/fypp \
	   version

dbcsrclean:
	@echo "Clean DBCSR"
	@$(MAKE) -C $(EXTSHOME)/dbcsr \
	   FYPPEXE=$(TOOLSRC)/build_utils/fypp \
	   clean
