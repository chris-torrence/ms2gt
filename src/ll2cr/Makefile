#========================================================================
# makefile for ll2cr
#
# 23-Oct-2000 Terry Haran tharan@colorado.edu 303-492-1847
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /data/haran/ms2gth/src/ll2cr/Makefile,v 1.6 2001/02/20 17:43:44 haran Exp haran $

#------------------------------------------------------------------------
# configuration section
#
#	installation directories
#
TOPDIR = ../..
LIBDIR = $(TOPDIR)/lib
INCDIR = $(TOPDIR)/include
BINDIR = $(TOPDIR)/bin

#
#	commands
#
SHELL = /bin/sh
CC = cc
CO = co
MAKEDEPEND = makedepend
INSTALL = cp
RM = rm -f
TAR = tar
COMPRESS = gzip

#
#	archive file name
#
TARFILE = ll2cr.tar

#
#	debug or optimization settings
#
CONFIG_CFLAGS = -O
#CONFIG_CFLAGS = -DDEBUG -g
LOCAL_CFLAGS =

#
#	libraries
#
LOCAL_LIBS = -lmapx
SYSTEM_LIBS = -lm 

#
# end configuration section
#------------------------------------------------------------------------

CFLAGS = -I$(INCDIR) $(LOCAL_CFLAGS) $(CONFIG_CFLAGS)
LIBS = -L$(LIBDIR) $(LOCAL_LIBS) $(SYSTEM_LIBS)

SRCS = ll2cr.c
OBJS = ll2cr.o
HDRS = 

all: ll2cr install

ll2cr: $(OBJS)
	cc $(CFLAGS) -o ll2cr $(OBJS) $(LIBS)

install: ll2cr
	$(INSTALL) ll2cr $(BINDIR)

clean:
	- $(RM) $(OBJS) ll2cr

tar:
	- $(CO) Makefile $(SRCS) $(HDRS)
	$(TAR) cvf $(TARFILE) Makefile $(SRCS) $(HDRS)
	$(RM) $(TARFILE).gz
	$(COMPRESS) $(TARFILE)

depend:
	- $(CO) $(SRCS) $(HDRS)
	$(MAKEDEPEND) -I$(INCDIR) \
		-- $(CFLAGS) -- $(SRCS)

.SUFFIXES : .c,v .h,v .x .x,v

.c,v.o :
	$(CO) $<
	$(CC) $(CFLAGS) -c $*.c
	- $(RM) $*.c

.c,v.c :
	$(CO) $<

.h,v.h :
	$(CO) $<

