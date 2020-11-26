
/**
 *
 * File cutter for Birdy Soft X68000 series
 *
 * 2012/09/28 RuRuRu
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define Uint8  unsigned char
#define Uint32 unsigned int

#define COPYRIGHT "File cut tool for Birdy Software X68000 (" \
__DATE__ \
") (c)RuRuRu\n\n"

void usage()
{
	printf("usage: bdycut <filename>\n");
}

int main(int argc, char *argv[])
{
	if (argc == 1) {
		usage();
		return -1;
	}

	printf( COPYRIGHT );

	FILE	*in = NULL, *out = NULL;
    Uint8	*disk = NULL;
	int		ret = 0;

	in = fopen(argv[1], "rb");
	if (in == NULL) {
		printf("error: can't open %s\n", argv[1]);
		return -2;
	}
	printf( "filename: %s\n", argv[1] );

	//filesize
	fseek(in, 0, SEEK_SET);
	fseek(in, 0, SEEK_END);
	size_t file_size = ftell(in);
	fseek(in, 0, SEEK_SET);

	if (file_size != 0x134000) {
		printf("error: illegal size %s\n", argv[1]);
		ret = -3;
		goto error;
	}

	disk = new Uint8[0x134000];
	fread( disk, 0x134000, 1, in );
	Uint8 *fat = &disk[0x3800];

	// make basename
	fat[2] = 0;
	int i;
	for (i=4; i<12; i++) {
		if (fat[i] == 0x2e) {
			break;
		}
	}
	fat[i] = 0;

	printf( "title   : %s\ndisk    : %s\n\n", &fat[4], &fat[1] );

	char	wname[13];
	size_t	wsize = 0L;
	for (i=2; i < 0x100; i++) {
		int offs = 8 * i;
		if (fat[offs + 5] == 0) {
			continue;
		}
		sprintf(wname, "%s_%s%02X", &fat[4], &fat[1], i);
		out = fopen(wname, "wb+");
		if (!out) {
			printf("error: can't open file : %s\n", wname);
			fclose( out );
			continue;
		}
		fseek( out , 0x0, SEEK_SET );

		size_t wlen = fat[offs] + (fat[offs+1] << 8) + (fat[offs+2] << 16);
		size_t wpos = (fat[offs+3] + (fat[offs+4] << 8)) * 0x400;

		fwrite( &disk[wpos], wlen, 1, out );

		fclose( out );

		printf( "| %s | ofs:%06x | size:%06x | attr:%02x\n", wname, wpos, wlen );
	}

  error:
	delete [] disk;
    if (in) fclose(in);
	if (out) fclose(out);

	return ret;
}
