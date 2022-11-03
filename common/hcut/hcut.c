/**
 *
 * てきとーにヘッダを除去するプログラム
 *
 */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

static int cutter(uint32_t headSize, char *infile, char *outfile)
{
	uint8_t *buf = NULL;
	FILE *wfp = NULL;
	int ret = 0;

	FILE *rfp = fopen(infile, "rb");
	if (!rfp) {
		return -1;
	}

	fseek(rfp, 0, SEEK_END);
	size_t inSize = ftell(rfp);

	if (headSize >= inSize) {
		ret = -2;
		goto cutter_err;
	}

	const size_t readSize = 1024 * 1024;
	buf = (uint8_t*)malloc( readSize );	// 1MB
	if (buf == NULL) {
		ret = -3;
		goto cutter_err;
	}
	fseek(rfp, 0, SEEK_SET);
	fseek(rfp, headSize, SEEK_CUR);

	wfp = fopen(outfile, "wb+");
	if (!wfp) {
		ret = -4;
		goto cutter_err;
	}

	while(1) {
		size_t remainSize = fread(buf, 1, readSize, rfp);
		if (remainSize <= 0) {
			printf("read end");
			break;
		}
		size_t writeSize = fwrite(buf, 1, remainSize, wfp);
		if (writeSize == remainSize) {
			printf("write size = %d byte\n", remainSize);
		} else {
			printf("write error! %d\n", writeSize);
			break;
		}
	}

cutter_err:
	if (rfp) {
		fclose(rfp);
	}
	if (wfp) {
		fclose(wfp);
	}
	if (buf) {
		free(buf);
	}
    return ret;
}

int main(int argc, char **argv) 
{
	size_t		size;

	if (argc < 3) {
		printf("usage: hcut [size] [infile] [outfile]\n");
		return(1);
	}

	unsigned long cutSize = strtoul(argv[1], NULL, 16);
	if (cutSize <= 0) {
		printf("number error.\n");
		return -1;
	} else {
		printf("cut size:%xbytes\n", cutSize);
	}

	int result = cutter(cutSize, argv[2], argv[3]);

	return result;
}
