#
# touch m3 deps
#

THISTREE:=$(shell cd ../../../..; pwd)
include $(THISTREE)/make.conf

LDFLAGS=-L$(THISTREE)/user/lib -L$(FULLTREE)/user/lib
vpath crt0.o    $(THISTREE)/user/lib:$(FULLTREE)/user/lib

all: extension #touch_domain
touch_domain: crt0.o touch.o extend_touch.o encap_touch.o
	$(LD) $(LDFLAGS) -o $@ $^ -ldomain -lc

extension: m3sources	# make.extension has the rule to build m3sources

install: extension #touch_domain

include $(THISTREE)/user/make.extension

