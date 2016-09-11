#include <stdio.h>
#include <stdlib.h>

#define UINT unsigned int
#define UINT32 unsigned int
#define UINT8 unsigned char

#if !defined(MAX_PATH)
#define MAX_PATH FILENAME_MAX
#endif

#define	LOADDWORD(a)			(((UINT32)(a)[3]) |				\
								((UINT32)(a)[2] << 8) |			\
								((UINT32)(a)[1] << 16) |		\
								((UINT32)(a)[0] << 24))

/**
 * decode for KOEI's lzw archive.
 *
 * @param number
 *        [in] file number (0 origin)
 * @param fp
 *        [in] output file handle
 * @param src
 *        [in] input buffer pointer
 * @param size
 *        [in] input buffer size
 */
static void type_lzw(UINT number, FILE *fp, UINT8 *ptr, size_t size)
{
const UINT8 *src;
	UINT	srcsize;
	UINT	pos;
	UINT	arcsize;
	UINT	dstsize;
	UINT	arcpos;
const UINT8	*arc;
	UINT	apos;
	UINT	dpos;
	UINT	bitcnt;
	UINT	bitdat;
	UINT	datum;
	UINT8	*dst;
	UINT	leng;

	src = ptr;
	srcsize = size;
	pos = 0x110 + ((number + 1) * 32);
	if (pos > srcsize) {
		goto lzhsolve_err1;
	}

	arcsize = LOADDWORD(src + pos - 16);
	dstsize = LOADDWORD(src + pos - 12);
	arcpos = LOADDWORD(src + pos - 8);

	if ((arcsize + arcpos) > srcsize) {
		goto lzhsolve_err1;
	}

	arc = src + arcpos;
	dst = (UINT8*)malloc(dstsize);
	if (dst == NULL) {
		goto lzhsolve_err1;
	}

	printf("* number  : %.x\n", number);
	printf("* arcsize : %.x\n", arcsize);
	printf("* datasize: %.x\n", dstsize);
	printf("* postion : %.x\n", arcpos);

	apos = 0;
	dpos = 0;
	while(dpos < dstsize) {
		// get data
		bitcnt = 0;
		do {
			bitcnt++;
			if ((apos >> 3) >= arcsize) {
				goto lzhsolve_err2;
			}
			bitdat = (arc[apos >> 3] >> ((~apos) & 7)) & 1;
			apos++;
		} while(bitdat);
		datum = (1 << bitcnt) - 2;
		do {
			bitcnt--;
			if ((apos >> 3) >= arcsize) {
				goto lzhsolve_err2;
			}
			bitdat = (arc[apos >> 3] >> ((~apos) & 7)) & 1;
			apos++;
			datum += bitdat << bitcnt;
		} while(bitcnt);
		if (datum < 0x100) {
			dst[dpos++] = src[datum + 0x10];
		}
		else {
			// get data
			bitcnt = 0;
			do {
				bitcnt++;
				if ((apos >> 3) >= arcsize) {
					goto lzhsolve_err2;
				}
				bitdat = (arc[apos >> 3] >> ((~apos) & 7)) & 1;
				apos++;
			} while(bitdat);
			leng = (1 << bitcnt) - 2;
			do {
				bitcnt--;
				if ((apos >> 3) >= arcsize) {
					goto lzhsolve_err2;
				}
				bitdat = (arc[apos >> 3] >> ((~apos) & 7)) & 1;
				apos++;
				leng += bitdat << bitcnt;
			} while(bitcnt);

			datum -= 0x100;
			if (dpos < datum) {
				goto lzhsolve_err2;
			}
			leng = min(leng + 3, dstsize - dpos);
			do {
				dst[dpos] = dst[dpos - datum];
				dpos++;
			} while(--leng);
		}
	}

	printf("* solve succeed.\n");
	fwrite(dst, 1, dstsize, fp);

lzhsolve_err2:
	free(dst);

lzhsolve_err1:
	return;
}

static char* get_filename(int num, UINT8 *buf)
{
	return (char*)(buf +(0x110 + num * 32));
}

int cutter(int num, char *file)
{
	char wpath[MAX_PATH];
	size_t bufsize;
	UINT8 *buf = NULL;
	FILE *wfp = NULL, *rfp = NULL;
	int ret = 0, i;

	rfp = fopen(file, "rb");
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

	wfp = fopen(get_filename(num, buf), "wb");
	if (!wfp) {
		ret = -4;
		goto cutter_err;
	}

	type_lzw(num, wfp, buf, bufsize);

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

int main(int argc, char **argv) {

	int		r;
	int		num;

	if (argc < 3) {
		printf("usage: ls10dec [number] [filename]\n");
		return(1);
	}

	num = atoi(argv[1]);
	if (num < 0) {
		printf("number error.\n");
		return -1;
	}

	r = cutter(num, argv[2]);

	return(r);
}

