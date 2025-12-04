#include <err.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include <png.h> /* confusing */

#include "png.h"
#include "../resources.h"

static int typepng2chan(int bit_depth, int color_type);

unsigned char *img_readpng(FILE *file, uint32_t *width, uint32_t *height, int *
		channels) {
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

	png_set_palette_to_rgb(png_reader);

	png_init_io(png_reader, file);
	png_set_sig_bytes(png_reader, 8);

	png_infop png_info = png_create_info_struct(png_reader);
	if (png_info == NULL) {
		warnx("libpng: Can't create info");
		png_destroy_read_struct(&png_reader, NULL, NULL);
		return NULL;
	}

	png_read_info(png_reader, png_info);

	if (setjmp(png_jmpbuf(png_reader))) {
		warnx("libpng: Failed to read png");
		png_read_end(png_reader, png_info);
		png_destroy_read_struct(&png_reader, &png_info, NULL);
		return NULL;
	}

	int bit_depth, color_type;
	png_uint_32 w, h;
	png_get_IHDR(png_reader, png_info, &w, &h, &bit_depth,
			&color_type, NULL, NULL, NULL);
	*width = w;
	*height = h;

	*channels = typepng2chan(bit_depth, color_type);

	size_t rowbytes = png_get_rowbytes(png_reader, png_info);

	/* hack to support paletted PNGs with alpha channel */
	if (color_type == PNG_COLOR_TYPE_PALETTE) {
		png_bytep trans = NULL;
		int num_trans = 0;
		png_color_16p trans_values = NULL;

		/* not sure if these need to be freed somewhere */
		png_get_tRNS(png_reader, png_info, &trans, &num_trans,
				&trans_values);
		if (trans != NULL) {
			rowbytes *= 4;
			*channels = 4;
		} else
			rowbytes *= 3;
	}

	unsigned char *image = (unsigned char *)malloc((*height) *
			sizeof(png_bytep) * rowbytes);
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
		rows[i] = &(image[i * rowbytes]);

	png_read_image(png_reader, rows);

	free(rows);

	png_destroy_read_struct(&png_reader, &png_info, NULL);

	return image;
}

unsigned char *img_readpngpath(const char *path, uint32_t *width, uint32_t *
		height, int *channels) {
	int fd = openatres(path, O_RDONLY);
	if (fd < 0) {
		warn("openatres: %s", path);
		return NULL;
	}

	FILE *file = fdopen(fd, "rb");
	if (file == NULL) {
		warn("fdopen: %i", fd);
		close(fd);
		return NULL;
	}

	unsigned char *data = img_readpng(file, width, height, channels);

	fclose(file);

	return data;
}

static int typepng2chan(int bit_depth, int color_type) {
	int channels;
	switch(bit_depth) {
		case 4:
			switch(color_type) {
				case PNG_COLOR_TYPE_GRAY:
					channels = 1;
					break;
				default:
					warnx("pngreader: bad color type: %i",
							color_type);
					channels = -1;
			}
			break;
		case 8:
			switch(color_type) {
				case PNG_COLOR_TYPE_GRAY:
					channels = 1;
					break;
				case PNG_COLOR_TYPE_GRAY_ALPHA:
					channels = 2;
					break;
				case PNG_COLOR_TYPE_PALETTE:
				case PNG_COLOR_TYPE_RGB:
					channels = 3;
					break;
				case PNG_COLOR_TYPE_RGB_ALPHA:
					channels = 4;
					break;
				default:
					warnx("pngreader: bad color type: %i",
							color_type);
					channels = -1;
			}
			break;
		default:
			warnx("pngreader: bad bit depth: %i", bit_depth);
			channels = -1;
	}

	return channels;
}
