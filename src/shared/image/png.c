#include <err.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include <png.h> /* confusing */

#include "png.h"

unsigned char *img_readpng(FILE *file, uint32_t *width, uint32_t *height, int *
		channels, int *bit_depth, size_t *rowbytes) {
	unsigned char sig[8];
	fread(sig, 1, 8, file);

	if (png_sig_cmp(sig, 0, 8)) {
		warnx("libpng: Bad signature");
		return NULL;
	}

	png_structp png_reader = png_create_read_struct(PNG_LIBPNG_VER_STRING,
			NULL, NULL, NULL);
	if (png_reader == NULL) {
		warnx("libpng: Can't create reader");
		return NULL;
	}

	png_infop png_info = png_create_info_struct(png_reader);
	if (png_info == NULL) {
		warnx("libpng: Can't create info");
		png_destroy_read_struct(&png_reader, NULL, NULL);
		return NULL;
	}

	if (setjmp(png_jmpbuf(png_reader))) {
		warnx("libpng: Failed to read png");
		png_read_end(png_reader, png_info);
		png_destroy_read_struct(&png_reader, &png_info, NULL);
		return NULL;
	}

	png_init_io(png_reader, file);
	png_set_sig_bytes(png_reader, 8);

	png_set_expand(png_reader);

	png_read_info(png_reader, png_info);

#if __BYTE_ORDER__ != __ORDER_BIG_ENDIAN__
	png_set_swap(png_reader);
#endif /* __BYTE_ORDER__ != __ORDER_BIG_ENDIAN__ */

	png_read_update_info(png_reader, png_info);

	int color_type;
	png_uint_32 w, h;
	png_get_IHDR(png_reader, png_info, &w, &h, bit_depth,
			&color_type, NULL, NULL, NULL);
	*width = w;
	*height = h;

	*channels = png_get_channels(png_reader, png_info);

	*rowbytes = png_get_rowbytes(png_reader, png_info);

	unsigned char *image = (unsigned char *)malloc((*height) *
			sizeof(png_byte) * *rowbytes);
	if (image == NULL) {
		warn("malloc", NULL);
		png_read_end(png_reader, png_info);
		png_destroy_read_struct(&png_reader, &png_info, NULL);
		return NULL;
	}

	png_bytep *rows = malloc((*height) * sizeof(png_bytep));
	if (rows == NULL) {
		free(image);
		png_read_end(png_reader, png_info);
		png_destroy_read_struct(&png_reader, &png_info, NULL);
		return NULL;
	}

	for (long i = 0; i < *height; ++i)
		rows[i] = &(image[i * *rowbytes]);

	png_read_image(png_reader, rows);

	free(rows);

	png_read_end(png_reader, png_info);
	png_destroy_read_struct(&png_reader, &png_info, NULL);

	return image;
}
