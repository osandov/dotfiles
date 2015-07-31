PREFIX = ~/.local
CFLAGS = -std=c99 -pedantic -Wall -Werror -D_DEFAULT_SOURCE -O2 `pkg-config --cflags gtk+-3.0`
LDFLAGS = -lX11 -lpulse -lnotify `pkg-config --libs gtk+-3.0`
