//
//  XZBridge.c
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 11/03/26.
//

#include "XZBridge.h"
#include <lzma.h>
#include <stdlib.h>
#include <stdint.h>

#define XZ_OK 0
#define XZ_ERR_INIT 1
#define XZ_ERR_PROCESS 2
#define XZ_ERR_MEMORY 3

static int process_xz(
    const unsigned char *input,
    size_t input_len,
    unsigned char **output,
    size_t *output_len,
    int compress
) {
    if (!input || !output || !output_len) return XZ_ERR_PROCESS;

    *output = NULL;
    *output_len = 0;

    lzma_stream strm = LZMA_STREAM_INIT;
    lzma_ret ret;

    if (compress) {
        ret = lzma_easy_encoder(&strm, LZMA_PRESET_DEFAULT, LZMA_CHECK_CRC64);
    } else {
        ret = lzma_stream_decoder(&strm, UINT64_MAX, LZMA_CONCATENATED);
    }

    if (ret != LZMA_OK) {
        return XZ_ERR_INIT;
    }

    size_t out_capacity = input_len > 0 ? input_len * 2 : 1024;
    if (!compress) {
        out_capacity = input_len * 8;
        if (out_capacity < 4096) out_capacity = 4096;
    }

    unsigned char *out_buf = (unsigned char *)malloc(out_capacity);
    if (!out_buf) {
        lzma_end(&strm);
        return XZ_ERR_MEMORY;
    }

    strm.next_in = input;
    strm.avail_in = input_len;
    strm.next_out = out_buf;
    strm.avail_out = out_capacity;

    while (1) {
        lzma_action action = (strm.avail_in == 0) ? LZMA_FINISH : LZMA_RUN;
        ret = lzma_code(&strm, action);

        if (ret == LZMA_STREAM_END) {
            break;
        }

        if (ret != LZMA_OK) {
            free(out_buf);
            lzma_end(&strm);
            return XZ_ERR_PROCESS;
        }

        if (strm.avail_out == 0) {
            size_t used = strm.total_out;
            out_capacity *= 2;
            unsigned char *tmp = (unsigned char *)realloc(out_buf, out_capacity);
            if (!tmp) {
                free(out_buf);
                lzma_end(&strm);
                return XZ_ERR_MEMORY;
            }
            out_buf = tmp;
            strm.next_out = out_buf + used;
            strm.avail_out = out_capacity - used;
        }
    }

    *output_len = strm.total_out;
    *output = out_buf;

    lzma_end(&strm);
    return XZ_OK;
}

int xz_compress_buffer(
    const unsigned char *input,
    size_t input_len,
    unsigned char **output,
    size_t *output_len
) {
    return process_xz(input, input_len, output, output_len, 1);
}

int xz_decompress_buffer(
    const unsigned char *input,
    size_t input_len,
    unsigned char **output,
    size_t *output_len
) {
    return process_xz(input, input_len, output, output_len, 0);
}

void xz_free_buffer(unsigned char *buffer) {
    if (buffer) free(buffer);
}
