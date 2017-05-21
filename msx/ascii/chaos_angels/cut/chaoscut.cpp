#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <malloc.h>

/**
 * ChaosAngeles data cutter
 */

#define COPYRIGHT "ChaosAngeles (MSX) data cut tool (" \
__DATE__ \
") (c)RuRuRu\n"

#define Uint8  unsigned char
#define Uint16 unsigned short
#define Uint32 unsigned int

int get_3word_be( Uint8 *_src) {
	return (_src[0] + ((int)_src[1] << 8) + ((int)_src[2] << 16));
}


/**
 * split & write file.
 *
 * @param _src [in] source data pointer.
 * @param _size [in] source data size.
 * @param _prefix [in] prefix of output file.
 *
 */
void write( Uint8 *_srca, Uint8 *_srcb, Uint8 *_map )
{
	FILE *fh;
	Uint32 offset = 0;
	int size;
	int start, end;
	char name[0x20];
	int count = 0;
	int diskanum = _map[0] + ((int)_map[1] << 8);

	offset = get_3word_be(&_map[count * 3 + 2]);

	// DISK-A
	do {
		size = get_3word_be(&_map[(count+1) * 3 + 2]);
		if (size == 0) return;
		size -= offset;

		sprintf(name, "%s%03X.BIN", "DATA", count);
		printf("%s ofs:0x%04x size:0x%04x no:%02x\n", name, offset, size, count);

		fh = fopen(name, "wb");
		fseek(fh, SEEK_SET, 0);
		fwrite(_srca + offset, 1, size, fh);
		fclose(fh);

		offset += size;
		count++;

	} while (diskanum > count);

	// DISK-B
	count ++;
	offset = 0;
	int bno = count;
	int diskbnum = 0x1ff + bno;
	do {
		size = get_3word_be(&_map[(count+1) * 3 + 2]);
		if (size == 0) return;
		size -= offset;

		printf("1 : %d %d\n", offset, size);

		sprintf(name, "%s%03X.BIN", "DATB", count - bno);
		printf("%s ofs:0x%04x size:0x%04x no:%02x\n", name, offset, size, count-bno);

		fh = fopen(name, "wb");
		fseek(fh, SEEK_SET, 0);
		fwrite(_srcb + offset, 1, size, fh);
		fclose(fh);

		offset += size;
		count++;

	} while (diskbnum > count);
}

bool file_load( char *_fname, Uint8 *&_src, size_t &_size )
{
	Uint8 *src = NULL;
	size_t src_size;

	FILE *fh = fopen( _fname, "rb" );
	if ( fh == NULL ) {
		printf( "error: can't open %s\n", _fname );
		return NULL;
	}
	fseek( fh, 0, SEEK_END );
	src_size = ftell( fh );
	fseek( fh, 0, SEEK_SET );
	src = (Uint8*)malloc( src_size );
	fread( src, 1, src_size, fh );
	fclose( fh );

	_size = src_size;
	_src = src;

	return src ? true : false;
}

int main(int argc, char *argv[])
{
	Uint8 *srca = NULL, *srcb = NULL, *map = NULL;
	size_t srca_size, srcb_size, map_size;

	printf(COPYRIGHT);

	if ( file_load( "DISKMAP", map, map_size ) == false ) {
		return -1;
	}

	if ( file_load( "DISK-A", srca, srca_size ) == false ) {
		return -1;
	}

	if ( file_load( "DISK-B", srcb, srcb_size ) == false ) {
		return -1;
	}

	write( srca, srcb, map );

	free(srca);
	free(srcb);
	free(map);
}

