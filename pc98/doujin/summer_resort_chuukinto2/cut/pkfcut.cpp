/**
 * Summer Resort Chuukinto2
 *  PKF cutter
 *
 */
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <new>

static uint32_t read_dword(uint8_t *src)
{
    return (src[1] << 24) + (src[0] << 16) + (src[3] << 8) + src[2];
}


int main (int argc, char *argv[])
{
	if (argc <  2) {
		printf("error\n");
		return -2;
	}

	uint8_t *src = nullptr;
	try {
		FILE *rfp = fopen(argv[1], "rb");
		if (rfp == nullptr) {
			return -1;
		}
		fseek(rfp, 0, SEEK_END);
		auto rsize = ftell(rfp);
		if (rsize == -1L) {
			return -2;
		}
		src = new uint8_t[rsize];
		fseek(rfp, 0, SEEK_SET);
		fread(src, 1, rsize, rfp);
		fclose(rfp);
	} catch(std::exception) {
		return -2;
	}

	uint16_t num = src[0] + (src[1] << 8);
	uint8_t *work = src + 0x10;

	char outname[12+1];
	for (int i=0; i<num; i++) {
		strncpy(outname, (char*)work, 12);
		uint32_t length = read_dword(work + 12);
		uint32_t offset = read_dword(work + 16);

		printf("file: %s %x %x\n", outname, length, offset);

		FILE *wfp = fopen(outname, "wb");
		fwrite(&src[offset], 1, length, wfp);
		fclose(wfp);

		work += 0x20;
	}

	return 0;
}
