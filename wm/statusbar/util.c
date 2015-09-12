#include <ctype.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "util.h"

static int str_realloc(struct str *str, size_t cap)
{
	void *buf;

	if (cap <= str->cap)
		return 0;

	buf = realloc(str->buf, cap);
	if (!buf) {
		perror("realloc");
		return -1;
	}

	str->buf = buf;
	str->cap = cap;
	return 0;
}

int str_append_buf(struct str *str, char *buf, size_t len)
{
	int ret;

	if (str->len + len > str->cap) {
		ret = str_realloc(str, str->len + len);
		if (ret)
			return ret;
	}
	memmove(str->buf + str->len, buf, len);
	str->len += len;
	return 0;
}

int str_appendf(struct str *str, char *format, ...)
{
	va_list ap;
	char *buf;
	int ret;

	va_start(ap, format);
	ret = vasprintf(&buf, format, ap);
	va_end(ap);

	if (ret == -1)
		return -1;

	ret = str_append_buf(str, buf, ret);
	free(buf);
	return ret;
}

int str_append_escaped(struct str *str, char *buf, size_t len)
{
	int ret;
	size_t i;

	for (i = 0; i < len; i++) {
		switch (buf[i]) {
		case '\0':
			ret = str_append(str, "\\0");
			break;
		case '\a':
			ret = str_append(str, "\\a");
			break;
		case '\b':
			ret = str_append(str, "\\b");
			break;
		case '\t':
			ret = str_append(str, "\\t");
			break;
		case '\n':
			ret = str_append(str, "\\n");
			break;
		case '\v':
			ret = str_append(str, "\\v");
			break;
		case '\f':
			ret = str_append(str, "\\f");
			break;
		case '\r':
			ret = str_append(str, "\\r");
			break;
		case '\\':
			ret = str_append(str, "\\\\");
			break;
		default:
			if (isprint(buf[i]))
				ret = str_append_buf(str, &buf[i], 1);
			else
				ret = str_appendf(str, "\\x%x", buf[i]);
			break;
		}
		if (ret)
			return -1;
	}
	return 0;
}

int str_append_icon(struct str *str, char *icon)
{
	char *home = getenv("HOME");

	if (!home) {
		fprintf(stderr, "HOME is not set\n");
		return -1;
	}

	return str_appendf(str, "\x1b]9;%s/.dotfiles/wm/icons/%s.xbm\a",
			   home, icon);
}

int parse_int(char *str, long long *ret)
{
	char *endptr;

	errno = 0;
	*ret = strtoll(str, &endptr, 10);
	if (errno)
		return -1;
	if (*endptr) {
		errno = EINVAL;
		return -1;
	}
	return 0;
}

int parse_int_file(char *path, long long *lret)
{
	FILE *file;
	int ret;

	file = fopen(path, "rb");
	if (!file)
		return -1;

	ret = fscanf(file, "%lld", lret);
	if (ret != 1) {
		fclose(file);
		errno = EINVAL;
		return -1;
	}

	fclose(file);
	return 0;
}
