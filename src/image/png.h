#ifndef IMG_PNG_H
#define IMG_PNG_H 1

#include <stdio.h>

unsigned char *img_readpng(FILE *, size_t *width, size_t *height, int *channels,
		int closefile);

unsigned char *img_readpngpath(const char *path, size_t *width, size_t *height,
		int *channels);

#endif /* IMG_PNG_H */
