PREFIX = ~/.local
CFLAGS = -std=gnu99 -pedantic -Wall -Werror -D_GNU_SOURCE -O2 -I/usr/include/libnl3
LDFLAGS = -lnetlink -lnl-3 -lnl-genl-3 -lpulse
