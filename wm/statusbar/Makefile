include config.mk

OBJS := main.o \
	util.o \
	cpu.o \
	dropbox.o \
	mem.o \
	net.o \
	nics.o \
	power.o \
	volume.o \
	pa_watcher.o

statusbar: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: install
install: statusbar
	install -d $(PREFIX)/bin
	install -m755 statusbar $(PREFIX)/bin/

.PHONY: clean
clean:
	rm -f $(OBJS)
	rm -f statusbar
