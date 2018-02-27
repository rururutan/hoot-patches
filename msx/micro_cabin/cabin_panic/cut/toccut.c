#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <malloc.h>

/**
 * Tower of Cabin (MSX) music data cutter
 */

#define COPYRIGHT "Tower of Cabin (MSX) music data cut tool (" \
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
	size_t size, fsize, remain;
	char name[0x20];
	int bgmno = 0, tonno = 0;
	Uint8 found = 0;

	offset = 0;
	remain = _size;

	do {
		// 'BGM' or 'ONS'
		if ( memcmp( &_src[offset], "BGM", 3) == 0 ||
			 memcmp( &_src[offset], "bgm", 3) == 0 ) {
			found = 1;
		}

		if ( memcmp( &_src[offset], "ONS", 3) == 0 ||
			 memcmp( &_src[offset], "ons", 3) == 0 ) {
			found = 2;
		}

		if (found == 0) {
			break;
		}

		size = 512;			// minimum size : 512byte
		remain -= 512;

		// Next file or EOF
		while ( remain > 0 ) {

			// 'BGM' or 'ONS'
			if ( memcmp( &_src[offset+size], "BGM", 3) == 0 ||
				 memcmp( &_src[offset+size], "bgm", 3) == 0 ||
				 memcmp( &_src[offset+size], "ONS", 3) == 0 ||
				 memcmp( &_src[offset+size], "ons", 3) == 0 ) {
				break;
			}

			remain -= 512;
			size += 512;
			continue;
		}

		if ( found == 1 ) {
			sprintf(name, "%s%02X.BGM", _prefix, bgmno++);
		} else {
			sprintf(name, "%s%02X.TON", _prefix, tonno++);
		}
		fsize = _src[offset+4] + ((size_t)_src[offset+5] <<8);
		printf("%s ofs:0x%04x size:0x%04x\n", name, offset, fsize);

		fh = fopen(name, "wb");
		fseek(fh, SEEK_SET, 0);
		fwrite(_src + offset + 0x10, 1, size - 0x10, fh);	// +0x10‚µ‚Äƒwƒbƒ_íœ
		fclose(fh);

		offset += size;
		found = 0;
	} while (offset < _size);
}

void usage()
{
	printf("usage: toccut <filename> <prefix>\n");
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

