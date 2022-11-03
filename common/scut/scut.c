/**
 *
 * てきとーにバイナリサーチして切り出すプログラム
 *
 */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define UINT unsigned int
#define UINT32 unsigned int
#define UINT8 unsigned char

#define LOADDWORD(b, a)		{(b)[0] = (a)[3];	\
							 (b)[1] = (a)[2];	\
							 (b)[2] = (a)[1];	\
							 (b)[3] = (a)[0];}

static void search_bin(UINT32 sbin, UINT32 sbin2, size_t size, FILE *fp, UINT8 *buf, size_t bufsize)
{
	size_t pos = 0, found = 0;
	UINT8 searchbin[8];
	UINT8 *bin = (UINT8*)&sbin;
	UINT8 *bin2 = (UINT8*)&sbin2;

	LOADDWORD(searchbin, bin);
	LOADDWORD((searchbin+4), bin2);

	printf("search binary %02x:%02x:%02x:%02x:%02x:%02x:%02x:%02x....",
		   searchbin[0], searchbin[1], searchbin[2], searchbin[3],
		   searchbin[4], searchbin[5], searchbin[6], searchbin[7]
		   );

	for (pos = 0; pos < bufsize; pos++) {
		if (!memcmp(&buf[pos], searchbin, 8)) {
			if ((bufsize - pos) < 3 ||
				(bufsize - pos) < size) {
				printf("too small!!\n");
				break;
			}

			printf("found.\nposition = 0x%x\n", pos);
			found = pos;
			break;
		}
	}

	if (found) {
		if (fwrite(&buf[pos], 1, size, fp) == size) {
			printf("write size = %d byte\n", size);
		} else {
			printf("write error!\n");
		}
	} else {
		printf("not found.\n");
	}
}

static int cutter(UINT32 sbin, UINT32 sbin2, size_t size, char *infile, char *outfile)
{
	size_t bufsize;
	UINT8 *buf = NULL;
	FILE *wfp = NULL, *rfp = NULL;
	int ret = 0;

	rfp = fopen(infile, "rb");
	if (!rfp) {
		return -2;
	}

	fseek(rfp, 0, SEEK_END);
	bufsize = ftell(rfp);

	buf = (UINT8*)malloc(bufsize);
	if (buf == NULL) {
		ret = -3;
		goto cutter_err;
	}
	fseek(rfp, 0, SEEK_SET);
	fread(buf, 1, bufsize, rfp);
	fclose(rfp);

	wfp = fopen(outfile, "wb");
	if (!wfp) {
		ret = -4;
		goto cutter_err;
	}

	search_bin(sbin, sbin2, size, wfp, buf, bufsize);

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
	int		r;
	size_t		size;
	unsigned long sbin, sbin2;

	if (argc < 6) {
		printf("usage: srchcut [binary] [binary2] [size] [infile] [outfile]\n");
		return(1);
	}

	sbin = strtoul(argv[1], NULL, 16);
	if (sbin <= 0) {
		printf("number error.\n");
		return -1;
	} else {
	    printf("sbin=%x\n", sbin);
	}

	sbin2 = strtoul(argv[2], NULL, 16);
	if (sbin2 <= 0) {
		printf("number error.\n");
		return -1;
	}

	size = atoi(argv[3]);
	if (size <= 0) {
		printf("size error.\n");
		return -1;
	}

	r = cutter(sbin, sbin2, size, argv[4], argv[5]);

	return(r);
}
