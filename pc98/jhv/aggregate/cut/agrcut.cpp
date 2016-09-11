/**
 * aggregate file cutter
 *
 *
 */
#include <stdio.h>
#include <string.h>

inline int read_dword_le(unsigned char *src)
{
    return (src[3] << 24) + (src[2] << 16) + (src[1] << 8) + src[0];
}


int main (int argc, char *argv[]) {

	FILE *rfp = NULL, *wfp = NULL, *tfp = NULL;
	unsigned char *buf = NULL;

	if (argc <  2) {
		return -2;
	}

	try {

		size_t len = strlen(argv[1]);

		{
			char *datname = new char[len + 4];
			strcpy(datname, argv[1]);
			strcat(datname, ".dat");

			rfp = fopen(datname, "rb");
			delete [] datname;
			if (rfp == NULL) {
				throw -1;
			}
			fseek(rfp, 0, SEEK_END);
			long rsize = ftell(rfp);
			if (rsize == -1L) {
				throw -1;
			}
			buf = new unsigned char[rsize];
			fseek(rfp, 0, SEEK_SET);
			fread(buf, 1, rsize, rfp);
			printf("file size = %ld\n", rsize);
			fclose(rfp);
		}
		{
			char *lenname = new char[len + 4];
			strcpy(lenname, argv[1]);
			strcat(lenname, ".len");

			tfp = fopen(lenname, "rb");
			delete [] lenname;
			if (tfp == NULL) {
				throw -1;
			}
			fseek(tfp, 8, SEEK_SET);
		}

		int name_count = 0;
		char outname[16];
		unsigned char len_buf[4];
		size_t start= 0, end = 0;
		while (1) {
			if (fread(len_buf, 1, 4, tfp) != 4) {
				throw 0;
			}
			start = end;
			end = read_dword_le(len_buf);
			sprintf(outname, "%s.%03d", argv[1], name_count);
			wfp = fopen(outname, "wb");
			if (wfp == NULL) {
				printf("open error\n");
				throw -1;
			}
			fwrite(&buf[start], 1, end - start, wfp);
			fclose(wfp);
			printf("%s size=%4d\n",outname, end-start);
			name_count++;
		}
		throw 0;
	} catch(int ret) {
		delete [] buf;
		fclose(tfp);
		fclose(rfp);
		fclose(wfp);
		return ret;
	}

	return 0;
}
