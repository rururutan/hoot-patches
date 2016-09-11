#include <stdio.h>

#define rol2_size 24272
#define fuku2_size 37114

const unsigned int rol2[] = {
	518,  459,  677, 633, 458, 978, 374, 978,  476, 365,
	401,  182, 1019, 747, 420, 611, 468, 591,  525, 470,
	731,  933,  569, 702, 671, 283, 753, 703, 1184, 371,
	370,  359,  595, 436, 298, 163, 356, 673,  178, 800,
	131,  579,  401, 683,   0
};

const unsigned int fuku2[] = {
	518,  459,  677, 633, 458, 978,  374,  978,  476,  365,
	401,  182, 1019, 747, 420, 611,  468,  591,  525,  470,
	731,  933,  569, 702, 671, 283,  753,  703, 1184,  371,
	370,  359,  595, 436, 298, 163,  356,  673,  178,  800,
	131,  579,  401, 683, 386, 578, 1225,  399,  641, 1076,
	194,  583, 1205, 492, 620, 666,  660,  635,  778,  489,
	798, 1417,    0
};


int main () {
	const unsigned int* size_tbl;
	FILE *rfp = fopen("MUSIC.DAT", "rb");
	if (rfp == NULL) {
		return -1;
	}

	fseek(rfp, 0, SEEK_END);
	long rsize = ftell(rfp);
	if (rsize == -1L) {
		return -1;
	}

	if (rsize == rol2_size) {
		size_tbl = rol2;
	} else if (rsize == fuku2_size) {
		size_tbl = fuku2;
	} else {
		return -1;
	}

	unsigned char *buf = new unsigned char[rsize];
	fseek(rfp, 0, SEEK_SET);
	fread(buf, 1, rsize, rfp);
	printf("rsize = %d\n", rsize);

	int name_count = 0;
	char name_buf[16];
	unsigned char *work = buf;
	FILE *wfp;
	while (rsize && name_count < 99) {
		if (size_tbl[name_count] == 0) {
			break;
		}
		sprintf(name_buf, "MUSIC%02d.MLD", name_count);
		wfp = fopen(name_buf, "wb");
		if (wfp == NULL) {
			printf("error\n");
			break;
		}

		fwrite(work, 1, size_tbl[name_count], wfp);
		fclose(wfp);
		work += size_tbl[name_count];
		name_count++;
	}

	delete [] buf;
	return 0;
}
