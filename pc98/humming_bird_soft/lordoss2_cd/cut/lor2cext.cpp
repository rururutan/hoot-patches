/**
 * Recoed of Lodoss War 2CD
 *  decode & cutter
 *
 * [データ形式]
 * 0-4 : decode size(little-e)
 * 5-  : compressed data(lz)
 *
 * 以上を連結しているだけ。圧縮サイズが記録されていない為
 * 頭からデコードするしか無い。
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DICT_SIZE 4096

#define Uint8  unsigned char
#define Uint32 unsigned int

#define COPYRIGHT "Lodoss2CD decompress tool (" \
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
 * @paran read_size
 *        [out] readed data size
 */
Uint32 decodeLZ(FILE *in, Uint32 in_size,
				FILE *out, Uint32 out_size, Uint32 &read_size)
{
	Uint32	i, j;
	Uint8	read_buf[4];
	Uint8	*dic;
	Uint32	dic_pos = 0x0FEE;
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
				fprintf(out, "%c", read_buf[0]);
				dic_pos++;
				dic_pos &= 0x0FFF;
				readed_byte++;
				decode_byte++;
				if (decode_byte >= out_size) {
					break;
				}
			} else {
				fread(read_buf, 1, 2, in);
				decode_length = (read_buf[1] & 0x0F) + 0x03;
				decode_startaddr  = (read_buf[1] & 0xF0) << 4;
				decode_startaddr += read_buf[0];
				readed_byte += 2;

				//decode
				for(j = 0; j != decode_length; j++) {
					Uint32	addr = (decode_startaddr + j) & 0x0FFF;
					dic[dic_pos] = dic[addr];
					fprintf(out, "%c", dic[addr]);
					dic_pos++;
					dic_pos &= 0x0FFF;
					decode_byte++;
					if (decode_byte >= out_size) {
						break;
					}
				}
			}
			flag >>= 1;
			if (readed_byte >= in_size) {
				break;
			}
		}
	}
	free(dic);
	read_size = readed_byte;
	return decode_byte;
}

void usage()
{
	printf("usage: lor2cext <filename>\n");
}

int main(int argc, char *argv[])
{
	FILE	*in = NULL, *out = NULL;
	Uint8	tmp[4];
	Uint32	filesize = 0L;
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
	filesize = ftell(in);
	fseek(in, 0, SEEK_SET);

	printf( "file size: %lu(0x%04lX)\n",
			filesize, filesize);

	fseek(in , 0x0, SEEK_SET);
	char tmp_name[255];
	for (int i = 0; ; i++) {
		if (filesize < 4) {
			break;
		}
		sprintf(tmp_name, "MUSIC%02d.MLD", i);
		out = fopen(tmp_name, "wb+");
		if (out == NULL) {
			printf("error: can't open tempfile\n");
			fclose(in);
			ret = -3;
			goto error;
		}

		// extract
		size_t len;
		if (fread(tmp, 1, 4, in) != 4) {
			goto error;
		}
		filesize -= 4;
		filesize_original = tmp[0] + (tmp[1] << 8) + (tmp[2] << 16) + (tmp[3] << 24);
		printf("original size: %lu(0x%04lX)\n",
			   filesize_original, filesize_original);

		Uint32 read_size = 0;
		filesize_original = decodeLZ(in, filesize, out, filesize_original, read_size);
		filesize -= read_size;

		fclose(out); out = NULL;
	}

  error:
	fclose(in);
	if (out) {
		fclose(out);
	}

	printf("\ncomplete.\n");
	remove(argv[1]);
	rename(tmp_name, argv[1]);

	return ret;
}
