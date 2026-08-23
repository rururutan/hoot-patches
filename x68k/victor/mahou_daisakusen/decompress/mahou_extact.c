#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

static int read_file(const char *path, uint8_t **data, size_t *size)
{
	FILE *file = fopen(path, "rb");
	long length;

	if (file == NULL) return 0;
	if (fseek(file, 0, SEEK_END) != 0 || (length = ftell(file)) < 0 ||
		fseek(file, 0, SEEK_SET) != 0) {
		fclose(file);
		return 0;
	}

	*data = (uint8_t *)malloc((size_t)length);
	if (*data == NULL || fread(*data, 1, (size_t)length, file) != (size_t)length) {
		free(*data);
		*data = NULL;
		fclose(file);
		return 0;
	}

	fclose(file);
	*size = (size_t)length;
	return 1;
}

static int write_file(const char *path, const uint8_t *data, size_t size)
{
	FILE *file = fopen(path, "wb");
	int result;

	if (file == NULL) return 0;
	result = fwrite(data, 1, size, file) == size && fclose(file) == 0;
	return result;
}

int main(int argc, char **argv)
{
	uint8_t *source = NULL;
	uint8_t *output = NULL;
	size_t source_size = 0;
	size_t source_position = 4;
	size_t output_position = 0;
	size_t output_size;

	if (argc != 3) {
		fprintf(stderr, "Usage: %s input.DTC output.DTC\n", argv[0]);
		return 1;
	}

	if (!read_file(argv[1], &source, &source_size) || source_size < 5) {
		fprintf(stderr, "Cannot read input file: %s\n", argv[1]);
		free(source);
		return 1;
	}

	output_size = ((size_t)source[0] << 24) | ((size_t)source[1] << 16) |
		((size_t)source[2] << 8) | source[3];
	output = (uint8_t *)calloc(output_size, 1);
	if (output_size == 0 || output == NULL) {
		fprintf(stderr, "Invalid expanded size or out of memory.\n");
		free(source);
		return 1;
	}

	while (output_position < output_size) {
		unsigned int flags;
		int bit;

		if (source_position >= source_size) goto broken_stream;
		flags = source[source_position++];

		for (bit = 7; bit >= 0 && output_position < output_size; --bit) {
			if (flags & (1U << bit)) {
				if (source_position >= source_size) goto broken_stream;
				output[output_position++] = source[source_position++];
			} else {
				unsigned int word;
				unsigned int length;
				int offset;
				unsigned int i;

				if (source_position + 1 >= source_size) goto broken_stream;
				word = ((unsigned int)source[source_position] << 8) |
					source[source_position + 1];
				source_position += 2;
				length = (word & 0x1f) + 3;
				offset = (int)(word >> 5) - 0x800;

				for (i = 0; i < length && output_position < output_size; ++i) {
					ptrdiff_t copy_position = (ptrdiff_t)output_position + offset;
					/* The original loader expands into zero-filled BSS. */
					if (copy_position >= 0)
						output[output_position] = output[copy_position];
					++output_position;
				}
			}
		}
	}

	if (source_position != source_size) {
		fprintf(stderr, "Compressed stream size mismatch (%zu/%zu bytes used).\n",
			source_position, source_size);
		free(output);
		free(source);
		return 1;
	}

	if (!write_file(argv[2], output, output_size)) {
		fprintf(stderr, "Cannot write output file: %s\n", argv[2]);
		free(output);
		free(source);
		return 1;
	}

	printf("Expanded %zu bytes to %zu bytes.\n", source_size, output_size);
	free(output);
	free(source);
	return 0;

broken_stream:
	fprintf(stderr, "The compressed stream ended before expansion completed.\n");
	free(output);
	free(source);
	return 1;
}
