/**
 * Sierra resource file decompress
 *  for SILPHEED(Ver.3) / SORCERIAN
 *
 * License : GPL
 */

#include <stdio.h>
#include <string.h>
#include <memory.h>

#include <scitypes.h>

#define COPYRIGHT "Sierra decompress tool (" \
__DATE__ \
") based FreeSCI version 0.6.4\n"


int decrypt1(guint8 *dest, guint8 *src, int length, int complength);

void usage()
{
    printf("usage: decrypt <filename>\n");
}

void rename_org(char *src)
{
    char file_org[FILENAME_MAX];
    strcpy(file_org, src);
    strcat(file_org, ".org");
    rename(src, file_org);
    printf("renamed   : %s -> %s\n", src, file_org);
}

int main(int argc, char *argv[])
{
    FILE *in = NULL, *out = NULL;
    size_t length , complength=(10818-4);
    unsigned char *dest, *src;

    printf(COPYRIGHT);

    if (argc == 1) {
        usage();
        return -1;
    }

    in = fopen(argv[1], "rb");
    if (in) {
        printf("filename  : %s\n", argv[1]);
        fseek(in, 0, SEEK_SET);
        fseek(in, 0, SEEK_END);
        complength = ftell(in);
        fseek(in, 0, SEEK_SET);
        src = malloc(complength);
        fread(src, 1, complength, in);
        fclose(in);
    } else {
        printf("open error! - src file\n");
        return -1;
    }

    length = src[0] + (src[1] << 8) + (src[2] << 16) + (src[3] << 24);
    dest = malloc(length);

    printf("src size  : %d\ndest size : %d\n", complength-4, length);
    decrypt1(dest, src+4, length, complength-4);

    rename_org(argv[1]);
    out = fopen(argv[1], "wb");
    if (out) {
        fwrite(dest, 1, length, out);
        fclose(out);
    } else {
        printf("open error! - dest file\n");
        return -2;
    }

    return 0;
}
