#========================================================================
# Makefile for ms2gt
#
# 12-Apr-2001 T.Haran 303-492-1847  tharan@colorado.edu
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /data/haran/ms2gth/Makefile,v 1.29 2006/06/08 22:49:45 tharan Exp tharan $

#------------------------------------------------------------------------
# configuration section

#
#       define current version and release
#
VERSION = 0
RELEASE = 16

#
#	installation directories
#
TOPDIR = .
BINDIR = $(TOPDIR)/bin
DOCDIR = $(TOPDIR)/doc
GRDDIR = $(TOPDIR)/grids
INCDIR = $(TOPDIR)/include
LIBDIR = $(TOPDIR)/lib
SRCDIR = $(TOPDIR)/src
TU1DIR = $(TOPDIR)/tutorial_1
TU2DIR = $(TOPDIR)/tutorial_2
TU3DIR = $(TOPDIR)/tutorial_3
TU4DIR = $(TOPDIR)/tutorial_4

NAVDIR = $(SRCDIR)/fornav
GCNDIR = $(SRCDIR)/grid_convert
GSZDIR = $(SRCDIR)/gridsize
IDLDIR = $(SRCDIR)/idl
LL2DIR = $(SRCDIR)/ll2cr
LE2DIR = $(SRCDIR)/lle2cre
MAPDIR = $(SRCDIR)/mapx
SCTDIR = $(SRCDIR)/scripts
UTSDIR = $(SRCDIR)/utils

L1BDIR = $(IDLDIR)/level1b_read
UTLDIR = $(IDLDIR)/modis_utils

#
#	installation target directories
#
TARDIR = $(TOPDIR)/ms2gt$(VERSION).$(RELEASE)
TBINDIR = $(TARDIR)/bin
TDOCDIR = $(TARDIR)/doc
TGRDDIR = $(TARDIR)/grids
TINCDIR = $(TARDIR)/include
TLIBDIR = $(TARDIR)/lib
TSRCDIR = $(TARDIR)/src
TTU1DIR = $(TARDIR)/tutorial_1
TTU2DIR = $(TARDIR)/tutorial_2
TTU3DIR = $(TARDIR)/tutorial_3
TTU4DIR = $(TARDIR)/tutorial_4

TNAVDIR = $(TSRCDIR)/fornav
TGCNDIR = $(TSRCDIR)/grid_convert
TGSZDIR = $(TSRCDIR)/gridsize
TIDLDIR = $(TSRCDIR)/idl
TLL2DIR = $(TSRCDIR)/ll2cr
TLE2DIR = $(TSRCDIR)/lle2cre
TMAPDIR = $(TSRCDIR)/mapx
TSCTDIR = $(TSRCDIR)/scripts
TUTSDIR = $(TSRCDIR)/utils

TL1BDIR = $(TIDLDIR)/level1b_read
TUTLDIR = $(TIDLDIR)/modis_utils

#
#	commands
#
SHELL = /bin/sh
CC = cc
AR = ar
RANLIB = touch
CO = co
MAKE = make
MAKEDEPEND = makedepend
INSTALL = cp
CP = cp
CD = cd
RM = rm -f
RMDIR = rm -fr
MKDIR = mkdir -p
TAR = tar
COMPRESS = gzip

#
#	archive file name
#
TARFILE = $(TOPDIR)/ms2gt$(VERSION).$(RELEASE).tar

#
#	debug or optimization settings
#
#	on least significant byte first machines (Intel, Vax)
#	add -DLSB1ST option to enable byteswapping of cdb files
#
CONFIG_CFLAGS = -O
#CONFIG_CFLAGS = -DDEBUG -g

#
# end configuration section
#------------------------------------------------------------------------

#
#	makefiles
#
SRCMAKE	= $(SRCDIR)/Makefile
NAVMAKE = $(NAVDIR)/Makefile
GCNMAKE = $(GCNDIR)/Makefile
GSZMAKE = $(GSZDIR)/Makefile
LL2MAKE = $(LL2DIR)/Makefile
LE2MAKE = $(LE2DIR)/Makefile
MAPMAKE = $(MAPDIR)/Makefile
UTSMAKE = $(UTSDIR)/Makefile

GPDSRCS = $(GRDDIR)/*.gpd
MPPSRCS = $(GRDDIR)/*.mpp

L1BSRCS = $(L1BDIR)/*.pro $(L1BDIR)/*.txt
UTLSRCS = $(UTLDIR)/*.pro

NAVSRCS = $(NAVMAKE) $(NAVDIR)/*.c
GCNSRCS = $(GCNMAKE) $(GSZDIR)/*.c
GSZSRCS = $(GSZMAKE) $(GSZDIR)/*.c
IDLSRCS = $(L1BSRCS) $(UTLSRCS)
LL2SRCS = $(LL2MAKE) $(LL2DIR)/*.c
LE2SRCS = $(LE2MAKE) $(LE2DIR)/*.c
MAPSRCS = $(MAPMAKE) $(MAPDIR)/*.c $(MAPDIR)/*.h $(MAPDIR)/*.mpp
SCTSRCS = $(SCTDIR)/*.pl
UTSSRCS = $(UTSMAKE) $(UTSDIR)/*.c

TOPS = $(TOPDIR)/*.txt $(TOPDIR)/Makefile $(TOPDIR)/ms2gt_env.csh
DOCS = $(DOCDIR)/*.html $(DOCDIR)/*usage $(DOCDIR)/*.gif
HDRS = $(INCDIR)/*.h
GRDS = $(GPDSRCS) $(MPPSRCS)
SRCS = $(SRCMAKE) $(NAVSRCS) $(IDLSRCS) $(LL2SRCS) $(LE2SRCS) $(MAPSRCS) \
       $(SCTSRCS) $(UTSSRCS)
TU1S = $(TU1DIR)/*.txt $(TU1DIR)/*.gpd $(TU1DIR)/*.csh
TU2S = $(TU2DIR)/*.txt $(TU2DIR)/*.gpd $(TU2DIR)/*.csh
TU3S = $(TU3DIR)/*.txt $(TU3DIR)/*.gpd $(TU3DIR)/*.mpp $(TU3DIR)/*.csh
TU4S = $(TU4DIR)/*.txt $(TU4DIR)/*.gpd $(TU4DIR)/*.mpp $(TU4DIR)/*.csh

all:	srcs

srcs:
	$(CD) $(SRCDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all

clean:
	$(CD) $(SRCDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(RM) $(LIBDIR)/libmaps.a

tar:
	- $(CO) $(TOPS) $(DOCS) $(HDRS) $(SRCS) $(TU1S) $(TU2S) $(TU3S) $(TU4S)
	- $(RMDIR) $(TARDIR)
	$(MKDIR) $(TARDIR)
	$(MKDIR) $(TBINDIR) $(TDOCDIR) $(TGRDDIR) $(TINCDIR) $(TLIBDIR)
	$(MKDIR) $(TSRCDIR)
	$(MKDIR) $(TNAVDIR) $(TGCNDIR) $(TGSZDIR) $(TLL2DIR) $(TLE2DIR) \
                 $(TMAPDIR) \
                 $(TSCTDIR) $(TUTSDIR)
	$(MKDIR) $(TIDLDIR) $(TL1BDIR) $(TUTLDIR)
	$(MKDIR) $(TTU1DIR) $(TTU2DIR) $(TTU3DIR) $(TTU4DIR)
	$(CP) $(TOPS) $(TARDIR)
	$(CP) $(DOCS) $(TDOCDIR)
	$(CP) $(HDRS) $(TINCDIR)
	$(CP) $(GRDS) $(TGRDDIR)
	$(CP) $(SRCMAKE) $(TSRCDIR)
	$(CP) $(NAVSRCS) $(TNAVDIR)
	$(CP) $(GCNSRCS) $(TGCNDIR)
	$(CP) $(GSZSRCS) $(TGSZDIR)
	$(CP) $(L1BSRCS) $(TL1BDIR)
	$(CP) $(UTLSRCS) $(TUTLDIR)
	$(CP) $(LL2SRCS) $(TLL2DIR)
	$(CP) $(LE2SRCS) $(TLE2DIR)
	$(CP) $(MAPSRCS) $(TMAPDIR)
	$(CP) $(SCTSRCS) $(TSCTDIR)
	$(CP) $(UTSSRCS) $(TUTSDIR)
	$(CP) $(TU1S) $(TTU1DIR)
	$(CP) $(TU2S) $(TTU2DIR)
	$(CP) $(TU3S) $(TTU3DIR)
	$(CP) $(TU4S) $(TTU4DIR)
	$(TAR) cvf $(TARFILE) $(TARDIR)
	$(RM) $(TARFILE).gz
	$(COMPRESS) $(TARFILE)

depend:
	- $(CO) $(SRCS) $(HDRS)
	$(MAKEDEPEND) -I$(INCDIR) \
		-- $(CFLAGS) -- $(SRCS)

.SUFFIXES : .c,v .h,v

.c,v.o :
	$(CO) $<
	$(CC) $(CFLAGS) -c $*.c
	- $(RM) $*.c

.c,v.c :
	$(CO) $<

.h,v.h :
	$(CO) $<

# DO NOT DELETE THIS LINE -- make depend depends on it.

