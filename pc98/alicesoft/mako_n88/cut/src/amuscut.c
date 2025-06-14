// Alicesoft AMUS.DAT cutter

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define UNIT_SIZE 0x100
#define MAX_ENTRIES 1024

int split_archive(const char* filename) {
    FILE* fp = fopen(filename, "rb");
    if (!fp) {
        perror("Failed to open input file");
        return 1;
    }

    // ファイルサイズ取得
    fseek(fp, 0, SEEK_END);
    long filesize = ftell(fp);
    rewind(fp);

    if (filesize < 2) {
        fprintf(stderr, "File too small.\n");
        fclose(fp);
        return 1;
    }

    uint8_t* buffer = (uint8_t*)malloc(filesize);
    if (!buffer) {
        perror("Memory allocation failed");
        fclose(fp);
        return 1;
    }
    fread(buffer, 1, filesize, fp);
    fclose(fp);

    // Parse address table
    uint16_t* addr_table = (uint16_t*)buffer;
    size_t entry_count = 1;

    // i:0 Data -> Song No map
    for (size_t i = 1; i < MAX_ENTRIES; i++) {
        if (addr_table[i] == 0xff) {
            // End flag
            break;
        }

        size_t start_offset = ((size_t)addr_table[i] - 1) * UNIT_SIZE;
        if (start_offset >= (size_t)filesize) {
            fprintf(stderr, "Invalid address at entry %zu\n", i);
            continue;
        }

        size_t end_offset = 0;
        if (addr_table[i + 1] != 0) {
            end_offset = ((size_t)addr_table[i + 1] - 1) * UNIT_SIZE;
        } else {
            end_offset = filesize;
        }

        if (end_offset > filesize || end_offset <= start_offset) {
            fprintf(stderr, "Invalid length at entry %zu\n", i);
            continue;
        }

        // Genarate output name
        char outname[256];
        const char* dot = strrchr(filename, '.');
        size_t base_len = dot ? (size_t)(dot - filename) : strlen(filename);
        snprintf(outname, sizeof(outname), "%.*s_%02zu.DAT", (int)base_len, filename, entry_count);

        FILE* out = fopen(outname, "wb");
        if (!out) {
            perror("Failed to open output file");
            free(buffer);
            return 1;
        }
        fwrite(buffer + start_offset, 1, end_offset - start_offset, out);
        fclose(out);

        printf("Wrote %s (%zu bytes)\n", outname, end_offset - start_offset);
        entry_count++;
    }

    free(buffer);
    return 0;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s AMUS.DAT\n", argv[0]);
        return 1;
    }

    return split_archive(argv[1]);
}
