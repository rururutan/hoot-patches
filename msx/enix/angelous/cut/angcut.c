/**
 *
 * Angelous for MSX file cutter
 *
 */

#include <stdio.h>

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
        decrypt_sub(buf, &c);
        buf += 0x100;
    }
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
    FILE *fp=0, *fp2=0;
    int i;
    unsigned char fat[0x1000];
    unsigned char disk[0xb4000];
    unsigned char *tmp;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s [dsk file]\n", argv[0]);
        return 1;
    }

    fp = fopen( argv[1], "rb" );
    if ( fp ) {
        fread( disk, sizeof(disk), 1, fp );
        fclose( fp );
        memcpy( fat, disk + 0x1200, sizeof(fat) );
    } else {
        return -1;
    }

    // FAT decrypt
    decrypt( fat, 8 );

    // cut file
    tmp = fat;
    while( tmp[0] != 0x00 )
    {
        char fname[7];
        int copyadr = (tmp[0xb] << 8) + tmp[0x0a];
        int readofs = ( (tmp[0x7] * 9 ) + ((tmp[0x9] - 0x40) / 2) ) * 0x200;
        int readsiz = (tmp[0xd] << 8) + tmp[0xc];
        int copyofs = tmp[0x8] + (((tmp[0x9] - 0x40) % 2) * 0x100);
        memcpy( fname, tmp, 6 );

        if (((unsigned char)fname[0]) == 0xff) {
            fname[0] = '_';
        }
        fname[6] = '\0';
        tmp += 0x10;
        printf( "Name:%s Cadr:%04x Rofs:%x Size:%04x Cofs:%04x\n", fname, copyadr, readofs, readsiz, copyofs );
        filecut( disk, fname, readofs, readsiz, copyofs );
    }

    return 0;
}
