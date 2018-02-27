#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <malloc.h>

/**
 * MicroCabin MSX music data cutter
 *  for Xak / XakII / Fray / PricessMaker ...
 */

#define COPYRIGHT "MicroCabin (MSX) data cut tool (" \
__DATE__ \
") (c)RuRuRu\n"

#define Uint8  unsigned char
#define Uint16 unsigned short
#define Uint32 unsigned int

/**
 * split & write file.
 *
 * @param _src [in] source data pointer.
 * @param _size [in] source data size.
 * @param _prefix [in] prefix of output file.
 *
 */
void write(Uint8 *_src, int _size, char *_prefix)
{
	FILE *fh;
	Uint32 offset;
	Uint16 songno;
	int size, remain;
	char name[0x20];
	int count = 0;

	songno = 0;
	offset = 0;
	remain = _size;

	do {
		if (!(_src[offset] == 0x0c || _src[offset] == 0xfe) ||
			_src[offset+1] != 0x00) {
			break;
		}

		size = 512;			// minimum size : 512byte
		remain -= 512;

		while ( remain > 0 ) {

			// '0C 00'(OPLL) or 'FE 00'(PSG)
			if ( (_src[offset+size+1] == 0x00 && _src[offset+size] == 0x0c) ||
				 (_src[offset+size+1] == 0x00 && _src[offset+size] == 0xfe) ) {
				break;
			}

			remain -= 512;
			size += 512;
			continue;
		}

		sprintf(name, "%s%02X.BGM", _prefix, count);
		printf("%s ofs:0x%04x size:0x%04x no:%02x\n", name, offset, size, count);

		fh = fopen(name, "wb");
		fseek(fh, SEEK_SET, 0);
		fwrite(_src + offset, 1, size, fh);
		fclose(fh);

		offset += size;
		count++;
	} while (offset < _size);
}

void usage()
{
	printf("usage: fraycut <filename> <prefix>\n");
}

int main(int argc, char *argv[])
{
	Uint8 *src = NULL;
	size_t src_size;

	printf(COPYRIGHT);

	if (argc < 3) {
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
		src = (Uint8*)malloc(src_size);
		fread(src, 1, src_size, fh);
		fclose(fh);
	}

	write(src, src_size, argv[2]);
	free(src);
}

