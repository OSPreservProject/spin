#
# Makefile for the SPIN version of m3core
# This program runs under Digital Unix on the local host.
#

#
# HISTORY
# 11-Nov-97  David Becker (becker) at the University of Washington
#	Changed M3SHIP definition to search explicity rather than
#	through a PATH variable set somewhere in the makefiles.
#	Removed a bunch of unused targets.
#
# 28-Feb-97  Wilson Hsieh (whsieh) at the University of Washington
#	fix platforms
#
# 29-Jan-97  Wilson Hsieh (whsieh) at the University of Washington
#	refcount platform
#
# 11-Feb-97  Przemek Pardyak (pardy) at the University of Washington
#	Better clean-up and multiple platforms.
#

THISTREE:=$(shell cd ../..; pwd)
include $(THISTREE)/make.conf	# sets FULLTREE and DECSRCM3BUILD

BUILD_DIR:=$(LOCALTARGET)

#  Look for m3ship first in THISTREE, then in FULLTREE.
M3SHIP:=$(firstword $(wildcard $(patsubst %, %/local/$(LOCALTARGET)/bin/m3ship, $(THISTREE) $(FULLTREE))))

all:	m3sources
	$(M3SHIP) -DINSTALL_ROOT=$(THISTREE)/local/$(BUILD_DIR)/ $(M3FLAGS)



include $(THISTREE)/local/make.local


