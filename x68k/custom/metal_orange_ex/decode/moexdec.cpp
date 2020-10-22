#include <stdio.h>
#include <string.h>
#include <memory.h>

#define COPYRIGHT "METAL ORANGE EX decompress tool (" \
__DATE__ \
") (c)RuRuRu\n"

#define Uint8  unsigned char
#define Uint16 unsigned short
#define Uint32 unsigned int

/**
 * Get data (32bit big endian)
 *
 * @param _src [in] source data pointer
 * @return data
 *
 */
Uint32 get_dword_be(Uint8 *_src)
{
	Uint32 dst;
	dst = _src[0] << 24;
	dst+= _src[1] << 16;
	dst+= _src[2] <<  8;
	dst+= _src[3];
	return dst;
}

/**
 * Get data (16bit big endian)
 *
 * @param _src [in] source data pointer
 * @return data
 *
 */
Uint16 get_word_be(Uint8 *_src)
{
	Uint16 dst;
	dst = _src[0] << 8;
	dst+= _src[1];
	return dst;
}

/**
 * update compress flag
 *
 * @param _flag [in/out] flag data
 * @param _flag_remain [in/out] flag bit remain
 * @param _insize [in/out] source data remain
 * @param _src [in/out] source data pointer
 *
 */
void flag_update (int &_flag, int &_flag_remain, int &_insize, Uint8 *&_src)
{
	if (--_flag_remain <= 0) {
		_flag = *(_src++);
		_flag_remain = 8;
		_insize--;
	} else {
		_flag <<= 1;
	}
}

/**
 * decompress data
 *
 * @param _src [in] source data pointer
 * @param _src_size [in] source data size
 * @param _dst [in] dust data pointer
 * @param _dst_size [out] dust data size
 *
 */
void decompress (Uint8 *_src, size_t _src_size, Uint8 *_dst, size_t &_dst_size)
{
	int flag, insize = _src_size;
	int flag_remain = 1;
	int copylen;
	char offset[4] = {-1, -1, -1, -1};
	short *soffset = (short*)offset;
	long *loffset = (long*)offset;

	_dst_size = 0;

	flag_update(flag, flag_remain, insize, _src);

	while(0 < insize) {

		if (flag & 0x80) {
				// 1 pattern
			*(_dst++) = *(_src++);
			_dst_size++;
			insize--;
		} else {
			offset[0] = -1;
			copylen = 0;
			flag_update(flag, flag_remain, insize, _src);

			if (flag & 0x80) {
				// 01 pattern
				*soffset = (short)get_word_be(_src);
				_src += 2;

				copylen = *soffset & 0x7;
				*loffset >>= 3;
				if (copylen) {
					copylen += 2;
					insize -= 2;
				} else {
					copylen = *(_src++);
					copylen += 1;
					insize -= 3;
				}

				while(0 < copylen--) {
					*(_dst++) = *(_dst+*loffset);
					_dst_size++;
				}
			} else {
				// 00 pattern
				flag_update(flag, flag_remain, insize, _src);
				copylen = (copylen * 2) + ((flag & 0x80) ? 1 : 0);

				flag_update(flag, flag_remain, insize, _src);
				copylen = (copylen * 2) + ((flag & 0x80) ? 1 : 0);

				((Uint8*)&offset)[1] = 0xff;
				*(char*)&offset = *(char*)(_src++);
				insize --;
				copylen += 2;		// test

				while(0 < copylen--) {
					*(_dst++) = *(_dst+*soffset);
					_dst_size++;
				}
			}

		}
		flag_update(flag, flag_remain, insize, _src);
	}
}

/**
 * split & write zmd file.
 *
 * @param _src [in] source data pointer
 *
 */
void write(Uint8 *_src)
{
	FILE *fh;
	Uint32 offset;
	size_t size;
	Uint16 songno;
	char name[0x13];
	int count = 0;

	offset = get_dword_be(_src) + 4;

	do {
		size   = get_dword_be(_src + count*0x0a + 0x04);
		songno = get_word_be( _src + count*0x0a + 0x08);

		if (songno == 0xffff) {
			break;
		}

		sprintf(name, "MO%02d.ZMD", count);
		printf("ofs:%x size:%d no:%d\n", offset, size, songno);

		fh = fopen(name, "wb");
		fseek(fh, SEEK_SET, 0);
		fwrite("\x10ZmuSi", 1, 6, fh);							// add Zmusic Header
		fwrite(_src + offset, 1, size, fh);
		fclose(fh);

		offset += size;
		count++;
	} while (songno != 0xffff);
}

void usage()
{
	printf("usage: moexdec <filename>\n");
}

int main(int argc, char *argv[])
{
	Uint8 *src = NULL;
	size_t src_size, dst_size;

	printf(COPYRIGHT);

	if (argc == 1) {
		usage();
		return -1;
	}

	{
		FILE *fh = fopen(argv[1], "rb");
		if (fh == NULL) {
			printf("error: can't open %s\n", argv[1]);
			return -2;
		}
		fseek(fh, 0, SEEK_END);
		src_size = ftell(fh);
		fseek(fh, 0, SEEK_SET);
		src = new Uint8[src_size];
		fread(src, 1, src_size, fh);
		fclose(fh);
	}

	Uint8 *dst = new Uint8[src_size * 5];
	memset(dst, 0, src_size * 5);

	decompress(src, src_size, dst, dst_size);

	write(dst);

#if 0
	// for debug
	{
		FILE *fh = fopen("out.mus", "wb");
		fseek(fh, SEEK_SET, 0);
		fwrite(dst, 1, dst_size, fh);
		fclose(fh);
	}
#endif

	delete [] dst;
	delete [] src;
}

