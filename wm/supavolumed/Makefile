include config.mk

supavolumed: supavolumed.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

.PHONY: install
install: supavolumed
	install -d $(PREFIX)/bin
	install -m755 supavolumed $(PREFIX)/bin/

.PHONY: clean
clean:
	rm -f supavolumed
