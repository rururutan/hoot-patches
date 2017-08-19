/**
 * Hydefos & Lenam cutter
 *
 * @year 2017
 * @auther RuRuRu
 */

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <malloc.h>

static const int sector_size = 0x200;

static uint16_t get_wordbe(const uint8_t *_src)
{
	return static_cast<uint16_t>(_src[0]) + (static_cast<uint16_t>(_src[1]) << 8);
}

/**
 * search & cut files.
 *
 * @param _src [in] source data pointer.
 * @param _size [in] source data size.
 *
 */
static void cut_file(const uint8_t *_src, size_t _size)
{
	const uint8_t *fat = &_src[0x800];
	uint32_t offset = 0;

	do {
		if (fat[offset] == 0x00) {
			break;
		}

		char out_name[0x20] = {};
		const uint8_t *ent = &fat[offset];
		int fnp = 0;
		for (int i=0; i < 8; i++) {
			char c = ent[i];				// ファイル名を１文字ずつ取り出す
			if (c==' ') break;
			out_name[fnp++] = c;			// ファイル名を構成する
		}
		if (ent[8] != ' ') {				// 拡張子が必要なら付ける
			out_name[fnp++] = '.';
		}
		for (int i=8; i<0xc; i++) {			// 同じように拡張子を取り出す
			char c=ent[i];
			if (c==' ') break;
			out_name[fnp++] = c;
		}
		out_name[fnp++] = '\0';				// 文字列の最後

		uint32_t sector  = get_wordbe(&ent[0x0c]);	// 開始総セクタ
		uint32_t out_size = (*(ent+0x0e) + (*(ent+0x0f) << 8)) * 0x200;	// サイズ

		printf("%-12s  offset:%02x size:%04x\n", out_name, sector * 0x200, out_size);

		if (out_size > 0) {
			FILE *fh = fopen(out_name, "wb");
			fseek(fh, SEEK_SET, 0);
			fwrite(_src + sector * 0x200, 1, out_size, fh);
			fclose(fh);
		}

		offset += 0x10;
	} while (offset < _size);
}

void usage()
{
	printf("usage: hyzcut <filename> <prefix>\n");
}

int main(int argc, char *argv[])
{
	if (argc <= 1) {
		usage();
		return -1;
	}

	// read image
	uint8_t *src = NULL;
	size_t src_size = 0u;
	{
		FILE *fh = fopen(argv[1], "rb");
		if (fh == NULL) {
			printf("error: can't open %s\n", argv[1]);
			return -2;
		}
		fseek(fh, 0, SEEK_END);
		src_size = ftell(fh);
		fseek(fh, 0, SEEK_SET);
		src = (uint8_t*)malloc(src_size);
		if (src != NULL) {
			fread(src, 1, src_size, fh);
		}
		fclose(fh);
	}

	if (src == NULL) {
		return -3;
	}

	cut_file(src, src_size);
	free(src);
}

