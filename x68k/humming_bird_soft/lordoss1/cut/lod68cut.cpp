/**
 * Record of lodoss war(X68K) file cutter
 *
 * MDTファイルの分割ヘッダはmain.xの中に内蔵されている
 *
 */
#include <stdio.h>

/* ロードス1 MDTテーブル */
const unsigned int rolw_tbl[] = {
	0x0000027c,
	0x000002fb,
	0x00000272,
	0x000002c2,
	0x000003ad,
	0x000002d3,
	0x000003a1,
	0x000001f8,
	0x000007e0,
	0x00000313,
	0x00000488,
	0x00000a3b,
	0x00000ac4,
	0x00000376,
	0x0000047b,
	0x0000025d,
	0x000004dd,
	0x0000027b,
	0x000001f0,
	0x00000487,
	0x00000290,
	0
};

/* 福神漬 MDT.DATテーブル */
const unsigned int fuku_tbl[] = {
    0x00001ac7,
    0x000004dd,
    0x00000487,
    0x0000025d,
    0x00000290,
    0x0000027b,
    0x000001f0,
    0x000003a1,
    0x000001f8,
    0x0000027c,
    0x000002fb,
    0x00000272,
    0x000003ad,
    0x000002d3,
    0x000002c2,
    0x00000313,
    0x00000ac4,
    0x00000a3b,
    0x00000488,
    0x000007e0,
    0x0000047b,
    0x00000376,
    0x000002af,
    0x0000088b,
    0x00000c7f,
    0x000005f6,
    0x000006e3,
    0x0000034b,
    0x00002038,
    0x0000014f,
    0
};

int main () {
	const unsigned int *size_tbl = rolw_tbl;
	FILE *rfp = fopen("MDT", "rb");
	if (rfp == NULL) {
		rfp = fopen("MDT.DAT", "rb");
		if (rfp == NULL) {
			return -1;
		}
		size_tbl = fuku_tbl;
	}

	fseek(rfp, 0, SEEK_END);
	long rsize = ftell(rfp);
	if (rsize == -1L) {
		return -1;
	}

	unsigned char *buf = new unsigned char[rsize];
	fseek(rfp, 0, SEEK_SET);
	fread(buf, 1, rsize, rfp);
	printf("file size = %ld\n", rsize);

	int name_count = 0;
	char name_buf[16];
	unsigned char *work = buf;
	FILE *wfp;
	while (rsize && name_count < 99) {
		if (size_tbl[name_count] == 0) {
			break;
		}
		sprintf(name_buf, "mdt.%03d", name_count);
		wfp = fopen(name_buf, "wb");
		if (wfp == NULL) {
			printf("error\n");
			break;
		}
		fwrite(work, 1, size_tbl[name_count], wfp);
		fclose(wfp);
		printf("%s size=%4d\n",name_buf, size_tbl[name_count]);
		work += size_tbl[name_count];
		name_count++;
	}

	delete [] buf;
	return 0;
}
