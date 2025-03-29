//
// MSX2 電脳学園II/III カッター
//

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define SECTOR_SIZE 512
#define TRACK_SIZE (9 * SECTOR_SIZE)
#define TOTAL_TRACKS 80
#define SIDES 2
#define DISK_SIZE (TOTAL_TRACKS * SIDES * 9 * SECTOR_SIZE)

uint8_t* get_sector_pointer(uint8_t* disk_image, int track, int side, int sector) {
    size_t offset = (((track * 2) + side) * 9 + sector) * SECTOR_SIZE;
    return &disk_image[offset];
}

void write_to_file(const char* output_filename, uint8_t* data, size_t size) {
    FILE *output_file = fopen(output_filename, "wb");
    if (output_file == NULL) {
        perror("Error opening output file");
        return;
    }

    fwrite(data, 1, size, output_file);
    fclose(output_file);
}

int trim(char* s) {
    int n;
    for (n = strlen(s) - 1; n >= 0; n--) {
        if (s[n] != ' ' && s[n] != '\t' && s[n] != '\n') {
            break;
        }
    }
    s[n + 1] = '\0';
    return n;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <disk_image_filename>\n", argv[0]);
        return 1;
    }

    const char* disk_image_filename = argv[1];
    FILE *disk_file = fopen(disk_image_filename, "rb");
    if (disk_file == NULL) {
        perror("Error opening disk image file");
        return 1;
    }

    uint8_t* disk_image = (uint8_t*)malloc(DISK_SIZE);
    if (disk_image == NULL) {
        perror("Error allocating memory for disk image");
        fclose(disk_file);
        return 1;
    }

    size_t read_size = fread(disk_image, 1, DISK_SIZE, disk_file);
    if (read_size != DISK_SIZE) {
        fprintf(stderr, "Error reading disk image file\n");
        free(disk_image);
        fclose(disk_file);
        return 1;
    }
    fclose(disk_file);

    uint8_t* file_table = get_sector_pointer(disk_image, 0, 0, 4);
    while (file_table[0] != 0xff) {
        char file_name[12+1] = {0};
        int size = file_table[0xc] * SECTOR_SIZE;
        int track = file_table[0xe];
        int side = (file_table[0xf] & 0x10) ? 1 : 0;
        int sector = (file_table[0xf] & 0x0f) - 1;
        memcpy(file_name, file_table, 8);
        int n = trim(file_name) + 1;
        memcpy(file_name+n, ".", 1);
        memcpy(file_name+n+1, file_table+8, 3);
        printf("%s\t%02d %d %d %d\n", file_name, track, side, sector, size);
        write_to_file(file_name, get_sector_pointer(disk_image, track, side, sector), size);
        file_table += 0x10;
    }

    free(disk_image);

    return 0;
}
