#ifndef SHDR_HELPER
#define SHDR_HELPER 1

#include <dispatch/dispatch.h>
#include <objc/objc.h>

void shdr_helper_rpd_fill(void *restrict render_pipeline_descriptor, void *
		restrict name, id vertex_function, id fragment_function);

void shdr_helper_pipe_make(id *restrict pipeline, void *restrict
		render_pipeline_descriptor, id device, dispatch_group_t);

#endif /* SHDR_HELPER */
