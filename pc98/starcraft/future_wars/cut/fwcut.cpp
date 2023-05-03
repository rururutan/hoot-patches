/**
 * File cutter for Future Wars(PC-98)
 *
 * [データ形式]
 * 0-1  : file num(big endian)
 * 2-3  : ???(big endian)
 * 0x1e * file num分ループ
 * 00-0d : file name
 * 0e-11 : file offset(big endian)
 * 12-15 : encoded size(big endian)
 * 16-19 : decoded size(big endian)
 * 1a-1d : ????
 *
 */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// Big endian
uint32_t get_u32(uint8_t *ptr)
{
	return ptr[3] | (ptr[2] << 8) | (ptr[1] << 16) | (ptr[0] << 24);
}


void usage()
{
	printf("usage: fwcut <filename>\n");
}

int cutter(char *file_name)
{
	FILE *rfh = fopen(file_name, "rb");
	if (rfh == NULL) {
		printf("error: can't open %s\n", file_name);
		return -2;
	}

	//filesize
	fseek(rfh, 0, SEEK_SET);
	fseek(rfh, 0, SEEK_END);
	size_t file_size = ftell(rfh);
	fseek(rfh, 0, SEEK_SET);

	uint8_t *file_buf = (uint8_t*)malloc(file_size);
	if (file_buf == NULL) {
		fclose(rfh);
		return -3;
	}
	fread(file_buf, 1, file_size, rfh);
	fclose(rfh);

	int file_num = file_buf[1];
	uint8_t *info_ptr = file_buf + 4;
	for(int i=0; i<file_num; i++) {
		char* out_name = (char*)info_ptr;
		uint32_t offset = get_u32(info_ptr + 0x0e);
		uint32_t out_size = get_u32(info_ptr + 0x12);
		uint32_t decode_size = get_u32(info_ptr + 0x16);
		printf("%s ofs:%08x csize:%08x dsize:%08x\n",
			   out_name, offset, out_size, decode_size);
		info_ptr += 30;

		FILE *wfh = fopen(out_name, "wb");
		if (wfh == NULL) {
			continue;
		}

		fwrite(file_buf + offset, 1, out_size, wfh);
		fclose(wfh);
	}

	return 0;
}

int main(int argc, char *argv[])
{
	//printf( COPYRIGHT );

	if (argc < 2) {
		usage();
		return -1;
	}

	return cutter(argv[1]);
}

