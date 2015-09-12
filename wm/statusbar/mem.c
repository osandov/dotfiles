#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sections.h"
#include "util.h"

enum status mem_init(struct mem_section *section)
{
	memset(section, 0, sizeof(*section));
	section->n = 100;
	section->buf = malloc(section->n);
	if (!section->buf) {
		perror("malloc");
		return SECTION_FATAL;
	}

	return mem_update(section);
}

void mem_free(struct mem_section *section)
{
	free(section->buf);
}

enum status mem_update(struct mem_section *section)
{
	FILE *file;
	ssize_t ssret;
	enum status status = SECTION_SUCCESS;
	long long memtotal = -1;
	long long memfree = -1;
	long long buffers = -1;
	long long cached = -1;
	long long slab = -1;

	file = fopen("/proc/meminfo", "rb");
	if (!file) {
		if (errno == ENOENT) {
			fprintf(stderr, "/proc/meminfo does not exist\n");
			return SECTION_ERROR;
		}
		perror("fopen(\"/proc/meminfo\")");
		return SECTION_FATAL;
	}

	while (errno = 0, (ssret = getline(&section->buf, &section->n, file)) != -1) {
		if (sscanf(section->buf, "MemTotal: %lld", &memtotal) == 1 ||
		    sscanf(section->buf, "MemFree: %lld", &memfree) == 1 ||
		    sscanf(section->buf, "Buffers: %lld", &buffers) == 1 ||
		    sscanf(section->buf, "Cached: %lld", &cached) == 1 ||
		    sscanf(section->buf, "Slab: %lld", &slab) == 1)
			continue;
	}
	if (ferror(file)) {
		perror("getline(\"/proc/meminfo\")");
		status = SECTION_FATAL;
		goto out;
	}
	if (memtotal < 0) {
		fprintf(stderr, "Missing MemTotal in /proc/meminfo\n");
		status = SECTION_ERROR;
	}
	if (memfree < 0) {
		fprintf(stderr, "Missing MemFree in /proc/meminfo\n");
		status = SECTION_ERROR;
	}
	if (buffers < 0) {
		fprintf(stderr, "Missing Buffers in /proc/meminfo\n");
		status = SECTION_ERROR;
	}
	if (cached < 0) {
		fprintf(stderr, "Missing Cached in /proc/meminfo\n");
		status = SECTION_ERROR;
	}
	if (slab < 0) {
		fprintf(stderr, "Missing Slab in /proc/meminfo\n");
		status = SECTION_ERROR;
	}
	if (status == SECTION_ERROR)
		goto out;

	section->mem_usage = 100.0 * ((double)(memtotal - memfree - buffers -
					       cached - slab) / memtotal);

out:
	fclose(file);
	return status;
}

int append_mem(const struct mem_section *section, struct str *str)
{
	if (str_append_icon(str, "mem"))
		return -1;
	if (str_appendf(str, "%3.0f%%", section->mem_usage))
		return -1;
	return str_separator(str);
}
