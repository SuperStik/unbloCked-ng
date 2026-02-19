#ifndef SHDR_BACKGROUND
#define SHDR_BACKGROUND 1

#include <dispatch/dispatch.h>
#include <objc/objc.h>

void shdr_background_new(id *pipeline, id library, dispatch_group_t);

#endif /* SHDR_BACKGROUND */
