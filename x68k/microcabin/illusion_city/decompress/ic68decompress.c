/* Expand Illusion City (X68000) table-based LZSS .DAT files. */
#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const uint8_t zmd_signature[] = {0x10, 'Z', 'm', 'u', 'S', 'i', 'C'};

static int read_file(const char *path, uint8_t **data, size_t *size)
{
    FILE *file;
    long length;

    file = fopen(path, "rb");
    if (file == NULL) {
        fprintf(stderr, "%s: %s\n", path, strerror(errno));
        return 0;
    }
    if (fseek(file, 0, SEEK_END) != 0 || (length = ftell(file)) < 0 ||
        fseek(file, 0, SEEK_SET) != 0) {
        fprintf(stderr, "%s: cannot determine file size\n", path);
        fclose(file);
        return 0;
    }
    *size = (size_t)length;
    *data = (uint8_t *)malloc(*size != 0 ? *size : 1);
    if (*data == NULL) {
        fprintf(stderr, "out of memory\n");
        fclose(file);
        return 0;
    }
    if (fread(*data, 1, *size, file) != *size) {
        fprintf(stderr, "%s: read error\n", path);
        free(*data);
        *data = NULL;
        fclose(file);
        return 0;
    }
    fclose(file);
    return 1;
}

static int decompress(const uint8_t *input, size_t input_size,
                      uint8_t **output, size_t *output_size)
{
    size_t input_pos;
    size_t output_pos = 0;
    unsigned int table_size;

    if (input_size < 5) {
        fprintf(stderr, "input is too short\n");
        return 0;
    }
    *output_size = (size_t)input[0] | ((size_t)input[1] << 8);
    table_size = input[4];
    input_pos = 5 + table_size;
    if (input_pos > input_size) {
        fprintf(stderr, "distance table extends past end of input\n");
        return 0;
    }
    *output = (uint8_t *)malloc(*output_size != 0 ? *output_size : 1);
    if (*output == NULL) {
        fprintf(stderr, "out of memory\n");
        return 0;
    }

    while (output_pos < *output_size) {
        unsigned int token;
        size_t length;

        if (input_pos >= input_size) {
            fprintf(stderr, "compressed stream ended at %zu of %zu bytes\n",
                    output_pos, *output_size);
            goto error;
        }
        token = input[input_pos++];
        if (token < table_size) {
            size_t distance;
            size_t i;

            if (input_pos >= input_size) {
                fprintf(stderr, "missing back-reference length\n");
                goto error;
            }
            length = input[input_pos++];
            if (length == 0)
                length = 256;
            distance = (size_t)input[5 + token] + 1;
            if (distance > output_pos) {
                fprintf(stderr, "invalid distance %zu at output offset %zu\n",
                        distance, output_pos);
                goto error;
            }
            if (length > *output_size - output_pos) {
                fprintf(stderr, "output exceeded declared size %zu\n", *output_size);
                goto error;
            }
            for (i = 0; i < length; ++i) {
                (*output)[output_pos] = (*output)[output_pos - distance];
                ++output_pos;
            }
        } else {
            if (token == 0xff) {
                if (input_pos >= input_size) {
                    fprintf(stderr, "missing extended literal length\n");
                    goto error;
                }
                length = input[input_pos++];
                if (length == 0)
                    length = 256;
            } else {
                length = (size_t)(token - table_size + 1);
            }
            if (length > input_size - input_pos) {
                fprintf(stderr, "literal extends past end of input\n");
                goto error;
            }
            if (length > *output_size - output_pos) {
                fprintf(stderr, "output exceeded declared size %zu\n", *output_size);
                goto error;
            }
            memcpy(*output + output_pos, input + input_pos, length);
            input_pos += length;
            output_pos += length;
        }
    }
    return 1;

error:
    free(*output);
    *output = NULL;
    return 0;
}

static size_t find_zmd(const uint8_t *data, size_t size)
{
    size_t i;
    for (i = 0; i + sizeof(zmd_signature) <= size; ++i) {
        if (memcmp(data + i, zmd_signature, sizeof(zmd_signature)) == 0)
            return i;
    }
    return size;
}

int main(int argc, char **argv)
{
    uint8_t *input = NULL;
    uint8_t *output = NULL;
    size_t input_size;
    size_t output_size;
    size_t offset = 0;
    FILE *file;

    if (argc < 3 || argc > 4 ||
        (argc == 4 && strcmp(argv[3], "--carve-zmd") != 0)) {
        fprintf(stderr, "usage: %s input.DAT output [--carve-zmd]\n", argv[0]);
        return 2;
    }
    if (!read_file(argv[1], &input, &input_size) ||
        !decompress(input, input_size, &output, &output_size)) {
        free(input);
        return 1;
    }
    free(input);

    if (argc == 4) {
        offset = find_zmd(output, output_size);
        if (offset == output_size) {
            fprintf(stderr, "%s: ZMD signature not found\n", argv[1]);
            free(output);
            return 1;
        }
    }
    file = fopen(argv[2], "wb");
    if (file == NULL) {
        fprintf(stderr, "%s: %s\n", argv[2], strerror(errno));
        free(output);
        return 1;
    }
    if (fwrite(output + offset, 1, output_size - offset, file) !=
        output_size - offset) {
        fprintf(stderr, "%s: write error\n", argv[2]);
        fclose(file);
        free(output);
        return 1;
    }
    fclose(file);
    printf("wrote %zu bytes to %s\n", output_size - offset, argv[2]);
    free(output);
    return 0;
}
