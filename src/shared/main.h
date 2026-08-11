#ifndef GL_MAIN_H
#define GL_MAIN_H 1

#include <SDL3/SDL_events.h>

/* take a wild guess what this does */
extern char done;

/* for locking the render thread when not visible */
extern char occluded;
extern pthread_mutex_t occlusionlock;

/* main event loop */
void ev_loop(void);

/* graphics backend init */
void gl_main(void);

#endif /* GL_MAIN_H */
