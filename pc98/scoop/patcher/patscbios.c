/**
 * hootでSCBIOSのマウス初期化でループするのをパッチ当て
 *
 */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define UINT unsigned int
#define UINT32 unsigned int
#define UINT8 unsigned char

// 汎用
static const UINT8 search_data[] = {
	0x1e, 0x06, 0x60, 0x8c, 0xc8, 0x8e, 0xd8, 0x8e,
	0xc0, 0xb4, 0x42, 0xb5, 0xc0, 0xcd, 0x18
};

// SCBIOS 3.00
static const UINT8 search_data2[] = {
	0x1e, 0x06, 0x9c, 0x60, 0xfa, 0xe6, 0x5f, 0x8c,
	0xc8, 0x8e, 0xd8
};

static size_t search_bin( UINT8* _data, size_t _size )
{
	size_t ret = search_bin2( _data, _size, search_data, sizeof(search_data) );

	if ( ret != 0 ) {
		return ret;
	}

	return search_bin2( _data, _size, search_data2, sizeof(search_data2) );
}

static size_t search_bin2( UINT8* _data, size_t _data_size, UINT8* _search_data, size_t _search_size )
{
	size_t pos = 0, found = 0;

	for (pos = 0; pos < _data_size; pos++) {
		if (!memcmp(&_data[pos], _search_data, _search_size)) {
			printf("found.\nposition = 0x%x\n", pos);
			found = pos;
			break;
		}
	}

	if (found) {
		return found;
	} else {
		return 0;
	}
}

static void usage()
{
	printf("usage: srchcut scbios.com\n");
}

int main(int argc, char **argv) 
{

	UINT8 *bin_data = NULL;
	size_t bin_size = 0;
	size_t locate = 0;

	// Read file.
	{
		FILE *fp = fopen("SCBIOS.COM", "r+b");
		if (fp) {

			fseek( fp, 0, SEEK_END );
			bin_size = ftell( fp );
			fseek( fp, 0, SEEK_SET );

			bin_data = malloc(bin_size);

			if (bin_data) {
				fread( bin_data, bin_size, 1, fp );
			}
			fclose(fp);
		} else {
			printf("SCBIOS not found.\n");
			return -1;
		}
	}

	if (bin_data == NULL) {
		printf( "file open error.");
		return -2;
	}

	// Search binary
	locate = search_bin( bin_data, bin_size );

	// Patch write
	if (locate != 0 ) {
		rename("SCBIOS.COM", "SCBIOS.ORG");

		bin_data[locate] = 0xc3;
		{
			FILE *fp = fopen("SCBIOS.COM", "wb");
			fwrite( bin_data, bin_size, 1, fp );
			fclose(fp);
		}
	} else {
		printf("No need patch.");
	}

	free(bin_data);

	return 0;
}
