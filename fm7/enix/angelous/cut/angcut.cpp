/**
 *
 * Angelous for FM-7 file cutter
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include "d88.h"

static void decrypt_sub( unsigned char *buf, unsigned char *c )
{
    unsigned char a;
    int i;

    for (i=0; i< 0x100; i++) {
        a = buf[i];
        a = a ^ *c;
        buf[i] = a;
        (*c)--;
        (*c)--;
    }
}

static void decrypt( unsigned char * buf, int loop )
{
    int i;
    unsigned char c = 0;
    for ( i=0; i< loop; i++ ) {
        decrypt_sub(buf, &c);
        buf += 0x100;
//        decrypt_sub(buf, &c);
//        buf += 0x100;
    }
}


static void fcut(D88 &disk, char *_fname, int _trk, int _C, int _H, int _R, int _N, int _offset, int _size)
{
	int read_size = ( ( ( _size + _offset ) / 0x100 ) + 1 ) * 0x100;
	unsigned char *buf = (unsigned char*)malloc( read_size );

	int load_size = disk.ReadDATA(_trk, _C, _H, _R, _N, buf, read_size);
	int trk = _trk+1;
	while(load_size < read_size) {
		int load_size2 = disk.ReadDATA(trk, trk/2, trk%2, _R, _N, buf+load_size, read_size-load_size);

		if (load_size2 == 0) {
			printf("ReadDATA error r2:%x l2:%x\n", read_size-load_size, load_size2);
			return;
		}
		load_size += load_size2;
		trk++;
	}

	for (int i=0; i < read_size; i+=0x100) {
		decrypt( buf + i, 1 );
	}

	FILE *fp = fopen(_fname, "wb");
	if (fp) {
		fwrite(buf + _offset, 1, _size, fp);
		fclose(fp);
	}

	free(buf);
}

static void filecut( unsigned char*disk, char *fname, unsigned int rofs, unsigned int rsize, unsigned int dofs)
{
    int i;
    FILE *fp;
    int read_size = ( ( ( rsize + dofs ) / 0x200 ) + 1 ) * 0x200;
    unsigned char *buf = (unsigned char*)malloc( read_size );

    memcpy( buf, disk + rofs, read_size );

    for (i=0; i < read_size; i+=0x200) {
        decrypt( buf + i, 1 );
    }

    fp = fopen( fname, "wb" );
    if ( fp ) {
	fwrite( buf + dofs, rsize, 1, fp );
	fclose( fp );
    }
}

int main( int argc, char *argv[] )
{
	D88 disk;
	unsigned char fat[0x0c00];


	if (argc != 2) {
		fprintf(stderr, "Usage: %s [dsk file]\n", argv[0]);
		return 1;
	}

	if (!disk.SetFile(argv[1])) {
		fprintf(stderr, "Can't open file.\n");
		return 1;
	}

	{
		disk.SelectDisk(0);
		disk.SetRecordRange( 0x01, 0x6 );

		// ディレクトリの読み込み
		memset( fat, 0, sizeof(fat) );
		disk.ReadDATA( 0x01, 0x00, 0x01, 0x01, D88::N_1024, fat, 0x0c00 );
	}

    // FAT decrypt
    decrypt( fat, 0x0c );

	// cut file
    unsigned char *tmp = fat;
    while( tmp[0] != 0x00 )
    {
        char fname[7];
        int copyadr = (tmp[0xb] << 8) + tmp[0x0a];
		int trk = tmp[0x7];
		int cyn = tmp[0x7] / 2;
		int head = tmp[0x7] % 2;
        int readofs = ( (tmp[0x7] * 9 ) + ((tmp[0x9] - 0x40) / 2) ) * 0x200;
        int readsiz = (tmp[0xd] << 8) + tmp[0xc];
        int copyofs = tmp[0x8] + ((tmp[0x9] - 0x40) * 0x100);
        memcpy( fname, tmp, 6 );

        if (((unsigned char)fname[0]) == 0xff) {
            fname[0] = '_';
        }
        fname[6] = '\0';
        tmp += 0x10;
        printf( "Name:%s Trk:%03d Cyn:%02d Hed:%02x Size:%04x Cofs:%04x\n", fname, trk, cyn, head, readsiz, copyofs );
//        filecut( disk, fname, readofs, readsiz, copyofs );
		fcut( disk, fname, trk, cyn, head, 1, D88::N_1024, copyofs, readsiz ); 
    }

    return 0;
}
