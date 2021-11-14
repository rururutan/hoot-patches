
/**
 * GAINAX LB4 cutter
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define Uint8  unsigned char
#define Uint32 unsigned int

#define COPYRIGHT "GAINAX LB4 cut tool (" \
__DATE__ \
") (c)RuRuRu\n\n"

Uint32 GetDwordLe(Uint8 *_ptr)
{
	return
	  _ptr[0] + ((Uint32)_ptr[1] << 8)
	  + ((Uint32)_ptr[2] <<16) + ((Uint32)_ptr[3] << 24);
}

Uint32 GetWordLe(Uint8 *_ptr)
{
	return _ptr[0] + ((Uint32)_ptr[1] << 8);
}

void usage()
{
	printf("usage: lb4cut <filename>\n");
}

int main(int argc, char *argv[])
{
	if (argc == 1) {
		usage();
		return -1;
	}

	printf( COPYRIGHT );

	FILE	*in = NULL, *out = NULL;
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

	Uint8 *lb4file = new Uint8[file_size];
	fread(lb4file, file_size, 1, in);
	Uint8 *table = &lb4file[6];

	Uint32 hdrlen = GetDwordLe( lb4file );
	Uint32 filenum = GetWordLe( lb4file + 4 );

	char fname[255] = {0};
	Uint32 ofs = 6 + hdrlen;
	Uint32 ptr = 0;
	for (int i=0; i<filenum; i++) {
		Uint8  namelen = table[ptr++];
		memcpy(fname, table+ptr, namelen);
		fname[namelen] = 0;
		ptr += namelen;
		Uint32 len = GetWordLe(&table[ptr]);
		printf("ofs:%x len:%05d name:%s\n", ofs, len, fname);

		out = fopen(fname, "wb+");
		if (out) {
			fseek(out, 0, SEEK_SET);
			fwrite(&lb4file[ofs], len, 1, out);
			fclose(out);
		}

		ptr += 2;
		ofs += len;
	}

	delete [] lb4file;
	return 0;
}
