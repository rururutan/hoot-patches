#include	"compiler.h"
#include	"strres.h"
#include	"dosio.h"
#include	"fddfile.h"
#include	"fddfunc.h"


static const OEMCHAR dstdir[] = OEMTEXT("file2zip");
static const OEMCHAR dstname[] = OEMTEXT("file_%.2x.bin");


static void cutfile(FDDFILE fdd, const OEMCHAR *basepath,
												const UINT8 *fat, UINT num) {

	UINT		s_p;
	UINT		size;
	UINT8		*ptr;
	OEMCHAR		fname[32];

	s_p = LOADINTELWORD(fat + num*4);
	if (s_p) {
		size = ((fat[num*4+2] - 1) & 0xff) + 1;
		ptr = fddseq(fdd, s_p >> 5, ((s_p >> 2) & 7) + 1, 3,
											(s_p & 3) << 8, size << 8);
		if (ptr) {
			wsprintf(fname, dstname, num);
			writedata(basepath, fname, ptr, size << 8);
			_MFREE(ptr);
		}
	}
}

static int cutter(const OEMCHAR *diskname) {

	OEMCHAR		basepath[MAX_PATH];
	FDDFILE		fdd;
	UINT8		fat[0x400];
	UINT		i;

	file_cpyname(basepath, file_getcd(dstdir), NELEMENTS(basepath));
	file_dircreate(basepath);

	fdd = fddfile_open(diskname, FTYPE_NONE);
	if (fdd == NULL) {
		printf("%s couldn't open.\n", diskname);
		goto cutter_err1;
	}

	if (fdd->read(fdd, 0, 8, fat, 0x400) != 0x400) {
		goto cutter_err2;
	}

	for (i=0x01; i<0x03; i++) {
		cutfile(fdd, basepath, fat, i);
	}
	for (i=0x0a; i<0x24; i++) {
		cutfile(fdd, basepath, fat, i);
	}
	for (i=0xbe; i<0xc3; i++) {
		cutfile(fdd, basepath, fat, i);
	}

	fdd->close(fdd);
	return(0);

cutter_err2:
	fdd->close(fdd);

cutter_err1:
	return(1);
}


int main(int argc, char **argv) {

	OEMCHAR	modulefile[MAX_PATH];
	int		r;

	dosio_init();
	GetModuleFileName(NULL, modulefile, NELEMENTS(modulefile));

	if (argc < 2) {
		printf("usage: %s [program disk image]\n", file_getname(modulefile));
		dosio_term();
		return(1);
	}

	_MEM_INIT();

	file_setcd(modulefile);
	TRACEINIT();

	r = cutter(argv[1]);

	TRACETERM();
	_MEM_USED("report.txt");
	dosio_term();
	return(r);
}

