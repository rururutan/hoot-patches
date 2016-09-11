
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const char* const tmp_name = "@@TMP@@.DAT";

#define DICT_SIZE 4096

#define Uint8  unsigned char
#define Uint32 unsigned int

#define COPYRIGHT "Last breaker decompress tool (" \
__DATE__ \
") (c)Fac.KUROHANE/UME-3/RuRuRu\n"

/**
 * decode of lz data
 *
 * @param in
 *        [in] input file handle
 * @param in_size
 *        [in] input data size
 * @param out
 *        [in] output file handle
 * @param out_size
 *        [in] output data size
 */
Uint32 decodeLZ(FILE *in, Uint32 in_size,
				FILE *out, Uint32 out_size)
{
	Uint32	i, j;
	Uint8	read_buf[4];
	Uint8	*dic;
	Uint32	dic_pos = 0x0000;
	Uint8	flag;
	Uint32	decode_startaddr;
	Uint32	decode_length;
	Uint32	decode_byte = 0L;
	Uint32	readed_byte = 0L;

	// initial dictionary
	dic = (Uint8*)calloc(1, DICT_SIZE);
	memset(dic, 0, DICT_SIZE);

	// main
	while(readed_byte <= in_size) {

		if (decode_byte >= out_size) {
			break;
		}

		//compress flag
		fread(read_buf, 1, 1, in);
		flag = read_buf[0];
		readed_byte++;

		for(i = 0; i != 8; i++) {
			if (flag & 1) {
				fread(read_buf, 1, 1, in);
				dic[dic_pos] = read_buf[0];
//				printf("dic put pos:%2x data:%x\n", dic_pos, read_buf[0]);
				fprintf(out, "%c", read_buf[0]);
				dic_pos++;
				dic_pos &= 0x0FFF;
				readed_byte++;
				decode_byte++;
			} else {
				fread(read_buf, 2, 1, in);
				decode_length = (read_buf[1] & 0x0F) + 0x03;
				decode_startaddr  = (read_buf[1] & 0xF0) << 4;
				decode_startaddr += read_buf[0];
				readed_byte += 2;

				//decode
				for(j = 0; j != decode_length; j++) {
					Uint32	addr = (decode_startaddr + 1) & 0x0FFF;
					dic[dic_pos] = dic[(dic_pos - addr) & 0xfff];
//					printf("decode len:%2x adr:0x%2x dic_pos:0x%2x dic_pos2:0x%2x data:0x%2x\n", decode_length, decode_startaddr, dic_pos, (dic_pos-addr)&0xfff, dic[(dic_pos - addr) & 0xfff]);
					fprintf(out, "%c", dic[(dic_pos - addr) & 0xfff]);
					dic_pos++;
					dic_pos &= 0x0FFF;
					decode_byte++;
				}
			}
			flag >>= 1;
			if (readed_byte >= in_size) {
				break;
			}
		}
	}
	free(dic);
	return decode_byte;
}

void usage()
{
	printf("usage: lbext <filename>\n");
}

int main(int argc, char *argv[])
{
	FILE	*in = NULL, *out = NULL;
	Uint8	tmp[4];
	Uint32	filesize_compress = 0L;
	Uint32	filesize_original = 0L;
	int		ret = 0;

	printf(COPYRIGHT);

	if (argc == 1) {
		usage();
		return -1;
	}

	in = fopen(argv[1], "rb");
	if (in == NULL) {
		printf("error: can't open %s\n", argv[1]);
		return -2;
	}
	printf( "filename: %s\n", argv[1] );

	//filesize
	fseek(in, 0, SEEK_SET);
	fseek(in, 0, SEEK_END);
	filesize_compress = ftell(in);
	filesize_compress -= 4;							// -4 : header size
	fseek(in, 0, SEEK_SET);

	printf( "compress size: %lu(0x%04lX)\n",
			filesize_compress, filesize_compress);

	out = fopen(tmp_name, "wb+");
	if (out == NULL) {
		printf("error: can't open tempfile\n");
		fclose(in);
		ret = -3;
		goto error;
	}

	// extract
	fseek(in , 0x0, SEEK_SET);
	fread(tmp, 4, 1, in);
	filesize_original = tmp[0] + (tmp[1] << 8) + (tmp[2] << 16) + (tmp[3] << 24);
	printf("original size: %lu(0x%04lX)\n",
		   filesize_original, filesize_original);

	filesize_original = decodeLZ(in, filesize_compress, out, filesize_original);

	printf("\ncomplete.\n");

  error:
	fclose(in);
	fclose(out);

	remove(argv[1]);
	rename(tmp_name, argv[1]);

	return ret;
}
