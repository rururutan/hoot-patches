/**
 *
 * Dragon Buster fro FM77AV decode (Test)
 *
 */

#include <stdio.h>
#include <stdlib.h>

int main( int argc, char *argv[] )
{
	FILE *wfp=0;
	signed char *tmp;
	unsigned char *buf = 0;
	size_t bufsize;

	if (argc != 3) {
		fprintf(stderr, "Usage: %s [in file] [out file]\n", argv[0]);
		return 1;
	}

	{
		size_t i;
		FILE *rfp = fopen( argv[1], "rb" );
		if ( rfp ) {
			fseek(rfp, 0, SEEK_END);
			bufsize = ftell(rfp);
			fseek(rfp, 0, SEEK_END);

			buf = (unsigned char*)malloc(bufsize);
			fseek(rfp, 0, SEEK_SET);
			{ size_t rsize = fread( buf, 1, bufsize, rfp );
			if ( rsize != bufsize) {
				printf("read error fs:%d rs:%d\n", bufsize, rsize);
			}
			}
			fclose( rfp );
			tmp = buf;

			// NEG‚·‚é‚¾‚¯...
			for (i=0; i<bufsize; i++) {
				tmp[i] = -1 * tmp[i];
			}
		}
	}

	if (buf == 0) {
		return -1;
	}

	{
		FILE *wfp = fopen( argv[2], "wb" );
		if ( wfp ) {
			fwrite( buf, 1, bufsize, wfp );
			fclose( wfp );
		}
	}

	free(buf);
	return 0;
}
