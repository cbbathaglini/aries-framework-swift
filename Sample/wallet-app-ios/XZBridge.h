#ifndef XZBridge_h
#define XZBridge_h

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

int xz_compress_buffer(
    const unsigned char *input,
    size_t input_len,
    unsigned char **output,
    size_t *output_len
);

int xz_decompress_buffer(
    const unsigned char *input,
    size_t input_len,
    unsigned char **output,
    size_t *output_len
);

void xz_free_buffer(unsigned char *buffer);

#ifdef __cplusplus
}
#endif

#endif
