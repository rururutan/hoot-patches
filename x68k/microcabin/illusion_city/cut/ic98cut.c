/* Cut Zmusic files from Illusion City IC98.BEM / IC98.BGE archives. */
#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint16_t get_u16_be(const uint8_t *p)
{
    return (uint16_t)(((uint16_t)p[0] << 8) | p[1]);
}

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

static int make_output_name(char **name, const char *input, unsigned int index)
{
    size_t length = strlen(input) + 32;
    *name = (char *)malloc(length);
    if (*name == NULL) {
        fprintf(stderr, "out of memory\n");
        return 0;
    }
    if (snprintf(*name, length, "%s%02u.ZMD", input, index) < 0) {
        fprintf(stderr, "cannot construct output filename\n");
        free(*name);
        *name = NULL;
        return 0;
    }
    return 1;
}

static int cut_archive(const char *path)
{
    uint8_t *data = NULL;
    size_t size;
    size_t header_size;
    unsigned int count;
    unsigned int i;
    int result = 0;

    if (!read_file(path, &data, &size))
        return 0;
    if (size < 2) {
        fprintf(stderr, "%s: input is too short\n", path);
        goto done;
    }

    count = get_u16_be(data);
    header_size = 2 + (size_t)count * 2;
    if (count == 0 || header_size > size) {
        fprintf(stderr, "%s: invalid file count %u\n", path, count);
        goto done;
    }

    for (i = 0; i < count; ++i) {
        size_t start = get_u16_be(data + 2 + (size_t)i * 2);
        size_t end = i + 1 < count
                         ? get_u16_be(data + 2 + (size_t)(i + 1) * 2)
                         : size;
        char *output_name = NULL;
        FILE *output;

        if (start < header_size || start > size || end < start || end > size) {
            fprintf(stderr,
                    "%s: invalid range for file %u: 0x%zx-0x%zx\n",
                    path, i, start, end);
            goto done;
        }
        if (!make_output_name(&output_name, path, i))
            goto done;
        output = fopen(output_name, "wb");
        if (output == NULL) {
            fprintf(stderr, "%s: %s\n", output_name, strerror(errno));
            free(output_name);
            goto done;
        }
        if (fwrite(data + start, 1, end - start, output) != end - start) {
            fprintf(stderr, "%s: write error\n", output_name);
            fclose(output);
            free(output_name);
            goto done;
        }
        fclose(output);
        printf("%s: offset 0x%04zx, size %zu\n",
               output_name, start, end - start);
        free(output_name);
    }
    result = 1;

done:
    free(data);
    return result;
}

int main(int argc, char **argv)
{
    int failures = 0;
    int i;

    if (argc < 2) {
        fprintf(stderr, "usage: %s IC98.BEM [IC98.BGE ...]\n", argv[0]);
        return 2;
    }
    for (i = 1; i < argc; ++i) {
        if (!cut_archive(argv[i]))
            ++failures;
    }
    return failures != 0 ? 1 : 0;
}
