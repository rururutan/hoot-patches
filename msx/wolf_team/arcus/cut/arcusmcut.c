#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <malloc.h>

/**
 * Arcus(MSX) music data cutter
 */

#define COPYRIGHT "Arcus 0B data cut tool (" \
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
	int size, fsize, remain;
	char name[0x20];
	int count = 0;

	songno = 0;
	offset = 0;
	remain = _size;
	size = 512;			// minimum size : 512byte

	do {
		while ( remain > 0 ) {

			// '00 42' or '01 42'
			if ( ((_src[offset] == 0x00 || _src[offset] == 0x01) && _src[offset+1] == 0x42) ) {
				break;
			}

			offset += 512;
			remain -= 512;
			continue;
		}

		if (remain <= 0) return;

		fsize = (_src[offset+3] << 8) + _src[offset+2];
		size = ((fsize / 512) + 1 ) * 512;

		sprintf(name, "%s%02d.BIN", _prefix, count);
		printf("%s | ofs:0x%05x size:0x%04x no:%02d\n", name, offset, fsize, count);

		fh = fopen(name, "wb");
		fseek(fh, SEEK_SET, 0);
		fwrite(_src + offset, 1, fsize, fh);
		fclose(fh);

		offset += size;
		remain -= size;
		count++;
	} while (offset < _size);
}

void usage()
{
	printf("usage: wolfmcut <filename> <prefix>\n");
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

