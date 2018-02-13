/**
 * Twilight Zone III for MSX cutter
 */

#include <stdio.h>

#define TZ3 "TZ3.3"
#define BGM "BGM.DAT"

int main ( int argc, char *argv[] )
{
	int i = 0;
	short flen=0;
	char fname[12];
	FILE *rfp = NULL, *wfp = NULL;
	unsigned char table[0x40], *buf;

	memset( table, 0, sizeof(table) );
	printf("Twilight Zone 3 (MSX) cutter\n");

	{
		rfp = fopen( TZ3, "rb" );
		if ( rfp == NULL ) {
			printf("Can't open %s\n", TZ3);
			return -1;
		}
		fseek( rfp, 0x218, SEEK_SET );
		fread( table, 1, 0x3a, rfp );
		fclose( rfp );
	}

	rfp = fopen( BGM, "rb" );
	if ( rfp == NULL ) {
		printf("Can't open %s\n", BGM);
		return -1;
	}
	fseek( rfp, SEEK_SET, 0 );

	do {
		flen = table[i* 2 + 2] + (table[i* 2 + 3] * 0x100);

		if (flen == 0) {
			break;
		}

		buf = (unsigned char*)malloc(flen);
		fread( buf, 1, flen, rfp );
		{
			sprintf( fname, "BGM.%03d", i );
			printf( "%s size : 0x%04x\n", fname, flen );
			wfp = fopen( fname, "wb" );
			fwrite( buf, 1, flen, wfp );
		}
		free(buf);
		i++;
	} while (flen != 0);

	return 0;
}
