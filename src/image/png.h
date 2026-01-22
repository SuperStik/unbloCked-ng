#ifndef IMG_PNG_H
#define IMG_PNG_H 1

#include <stdint.h>
#include <stdio.h>

unsigned char *img_readpng(FILE *, uint32_t *width, uint32_t *height, int *
		channels, size_t *bytesperrow);

#endif /* IMG_PNG_H */
