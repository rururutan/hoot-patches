/**
 * KOEI386系サウンドデータ ヘッダ構造
 *
 * 00(W) : file total num
 * ---
 * 00(D) : start offset
 * 04(W) : length
 * --  total num分ループ
 * 
 * offsetはヘッダの終端が0
 * データは無圧縮
 *
 */
#include <stdio.h>
#include <stdlib.h>

#define UINT unsigned int
#define UINT32 unsigned int
#define UINT8 unsigned char

#if !defined(MAX_PATH)
#define MAX_PATH FILENAME_MAX
#endif

#define	LOADWORD(a)				(((UINT32)(a)[0]) |			\
								((UINT32)(a)[1] << 8))

#define	LOADDWORD(a)			(((UINT32)(a)[0]) |				\
								((UINT32)(a)[1] << 8) |			\
								((UINT32)(a)[2] << 16) |		\
								((UINT32)(a)[3] << 24))

static void type_cut(UINT number, FILE *fp, UINT8 *ptr, size_t size)
{
	UINT	hofs;
	UINT	fofs;
	UINT	fsize;
	const UINT8 *data;

	data = ptr + (LOADWORD(ptr) * 6) + 2;

	// header offset
	hofs = number * 6 + 2;
	fofs = LOADDWORD(ptr + hofs);
	fsize = LOADWORD(ptr + hofs + 4);
	fwrite(data+fofs, 1, fsize, fp);

	return;
}

int cutter(char *file)
{
	int totalnum;
	char wpath[MAX_PATH];
	size_t bufsize;
	UINT8 *buf = NULL;
	FILE *wfp = NULL, *rfp = NULL;
	int ret = 0, i,j;

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

	totalnum = LOADWORD(buf);

	printf("Total Num : %d\n", totalnum);

	for (j=0; j< totalnum; j++) {
		// make file name
		for(i=0; file[i]!='\0'; i++) {
			if (file[i]=='.') {
				break;
			}
		}
		file[i] = '\0' ;
		sprintf(wpath, "%s.%03d", file, j);

		wfp = fopen(wpath, "wb");
		if (!wfp) {
			ret = -4;
			goto cutter_err;
		}

		type_cut(j, wfp, buf, bufsize);
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

int main(int argc, char **argv) {

	int		r;
	int		num;

	if (argc < 2) {
		printf("usage: koei386cut [filename]\n");
		return(1);
	}

	r = cutter(argv[1]);

	return(r);
}

