/**
 * ガイアの紋章 for MSX デコード
 *
 *  @year 2011/08/16
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>
#include <malloc.h>

#define COPYRIGHT "Gaia decode tool (" \
__DATE__ \
") (c)RuRuRu\n"

#define Uint8  unsigned char

void usage()
{
	printf("usage: gaia_dec <filename> <num>\n");
}

int main(int argc, char *argv[])
{
	Uint8 *src = NULL;
	size_t src_size = 0;

	printf(COPYRIGHT);

	if (argc < 3) {
		usage();
		return -1;
	}

	// read
	{
		FILE *fh = fopen(argv[1], "rb");
		if (!fh) {
			printf("File open error.\n");
			return -1;
		} else {
			fseek(fh, 0, SEEK_END);
			src_size = ftell(fh);
			fseek(fh, 0, SEEK_SET);
			src = (Uint8*)malloc(src_size);
			fread(src, 1, src_size, fh);
			fclose(fh);
		}
	}

	// decode
	{
		size_t i;
		Uint8 dec, dec_val;

		int num = atoi( argv[2] );
		switch( num ) {
		  case 1:	// BOOT.COM  / MSXG3.DAT
			dec_val = 0x55;
			break;
		  case 2:	// MSXG1.DAT / MSXG4.DAT
			dec_val = 0xaa;
			break;
		  case 3:	// MSXG2.DAT
			dec_val = 0x5f;
			break;
		  case 0:	// MSXG5.DAT
		  default:
			dec_val = 0xff;
			break;
		}

		for (i=0; i<src_size; i++) {
			dec = src[i] ^ dec_val;
			src[i] = dec;
		}
	}

	// write
	{
		FILE *fh = fopen(argv[1], "wb");
		if (!fh) {
			printf("File open error. (write)\n");
			return -2;
		} else {
			fseek(fh, 0, SEEK_SET);
			fwrite(src, src_size, 1, fh);
			fclose(fh);
		}
	}
	free(src);
	return 0;
}
