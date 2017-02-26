#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <malloc.h>
#include <cstdint>

static const int sector_size = 0x200;

/**
 * MSXtR Ranma 1/2 file cutter
 */

uint16_t static get_wordbe(uint8_t *_src)
{
	return static_cast<uint16_t>(_src[0]) + (static_cast<uint16_t>(_src[1]) << 8);
}

/**
 * split & write file.
 *
 * @param _src [in] source data pointer.
 * @param _size [in] source data size.
 * @param _prefix [in] prefix of output file.
 *
 */
static void write(uint8_t *_src, int _size, char *_prefix)
{
	FILE *fh = nullptr;
	char name[0x20] = {0};

	uint32_t offset = 0;
	uint32_t sector = 0;
	uint32_t file_size = 0;
	uint32_t file_ofs = 0;
	uint32_t file_lofs = 0;

	uint8_t *fat = &_src[0x1c11];

	do {
		if (fat[offset] == 0x00) {
			break;
		}

		sector = get_wordbe(&fat[offset + 0x0b]);
		file_size = get_wordbe(&fat[offset + 0x0d]);
		file_ofs = get_wordbe(&fat[offset + 0x0f]);
		file_lofs = get_wordbe(&fat[offset + 0x11]);
		int i;
		for (i=0 ; i<8; i++) {
			if (fat[offset + i] != 0x20) {
				name[i] = fat[offset + i];
			} else {
				break;
			}
		}
		name[i++] = '.';
		for (int j=0; j<3; j++) {
			name[i++] = fat[offset + 8 + j];
		}
		name[i] = 0;
		printf("%s\tsec:0x%04x size:0x%04x ofs:%04x ofs2:%04x\n", name, sector, file_size, file_ofs, file_lofs);

		int file_size_byte = (file_size - 1) * sector_size + file_lofs;
		fh = fopen(name, "wb");
		fseek(fh, SEEK_SET, 0);
		fwrite(_src + (sector * sector_size) + file_ofs, 1, file_size_byte, fh);
		fclose(fh);

		offset += 0x14;
	} while (offset < _size);
}

void usage()
{
	printf("usage: ranmacut <filename> <prefix>\n");
}

int main(int argc, char *argv[])
{
	uint8_t *src = NULL;
	size_t src_size;

	if (argc < 1) {
		usage();
		return -1;
	}

	{
		FILE *fh = fopen(argv[1], "rb");
		if (fh == NULL) {
			printf("error: can't open %s\n", argv[1]);
			return -2;
		}
		fseek(fh, 0, SEEK_END);
		src_size = ftell(fh);
		fseek(fh, 0, SEEK_SET);
		src = (uint8_t*)malloc(src_size);
		fread(src, 1, src_size, fh);
		fclose(fh);
	}

	// check disk
	if (memcmp(&src[0x1c06], "Ranma", 5) != 0) {
		printf("illegal disk\n");
		return -3;
	}

	write(src, src_size, argv[2]);
	free(src);
}

