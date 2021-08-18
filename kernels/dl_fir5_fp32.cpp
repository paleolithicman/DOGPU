#include "FGPUlib.c"

/*
support up to 480 coefficients
thread 32a+0: 0-31, 32-63, ..., 448-479
thread 32a+1: 479-0-30, 31-62, ..., 447-478
thread 32a+2: 478-479-0-29, 30-61, ..., 446-477
.
.
.
*/
#define N_SIZE              32768
#define FILTER_LEN          480
#define NUM_CU              8
#define WG_SIZE             512
#define LENGTH              N_SIZE / NUM_CU

__kernel void dl_fir5_fp32(__global float* in, __global float* coeff, __global float* out, int length)
{
    __local float* h_shr_ptr   = 0;                     // N_SIZE

    int gid = get_global_id(0);
    int lid = get_local_id(0);

    int bid = lid & (~31);
    __global float* A_ptr = coeff;
    __global float* x_ptr = in + ((gid >> 9) * LENGTH);
	__global float* out_ptr = out + ((gid >> 9) * LENGTH);
    int offset = (lid & 31) >> 3;
    int mode1 = offset;
    int mode2 = 4+offset;

    /* bring coefficients into registers */
    __global uint8x128* A_vec_ptr = (__global uint8x128*) A_ptr;
    __global uint8x128* in_vec_ptr = (__global uint8x128*) x_ptr;

    uint8x128 A_vreg_0;
    uint8x128 A_vreg_1;
    uint8x128 A_vreg_2;
    uint8x128 A_vreg_3;
    uint8x128 A_vreg_4;
    uint8x128 A_vreg_5;
    uint8x128 A_vreg_6;
    uint8x128 A_vreg_7;
    uint8x128 A_vreg_8;
    uint8x128 A_vreg_9;
    uint8x128 A_vreg_10;
    uint8x128 A_vreg_11;
    uint8x128 A_vreg_12;
    uint8x128 A_vreg_13;
    uint8x128 A_vreg_14;
    uint8x128 A_vreg_tmp = A_vec_ptr[0];
    movc(A_vreg_0, A_vreg_tmp, mode1, 1);
    movc(A_vreg_1, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[1];
    movc(A_vreg_1, A_vreg_tmp, mode1, 1);
    movc(A_vreg_2, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[2];
    movc(A_vreg_2, A_vreg_tmp, mode1, 1);
    movc(A_vreg_3, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[3];
    movc(A_vreg_3, A_vreg_tmp, mode1, 1);
    movc(A_vreg_4, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[4];
    movc(A_vreg_4, A_vreg_tmp, mode1, 1);
    movc(A_vreg_5, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[5];
    movc(A_vreg_5, A_vreg_tmp, mode1, 1);
    movc(A_vreg_6, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[6];
    movc(A_vreg_6, A_vreg_tmp, mode1, 1);
    movc(A_vreg_7, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[7];
    movc(A_vreg_7, A_vreg_tmp, mode1, 1);
    movc(A_vreg_8, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[8];
    movc(A_vreg_8, A_vreg_tmp, mode1, 1);
    movc(A_vreg_9, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[9];
    movc(A_vreg_9, A_vreg_tmp, mode1, 1);
    movc(A_vreg_10, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[10];
    movc(A_vreg_10, A_vreg_tmp, mode1, 1);
    movc(A_vreg_11, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[11];
    movc(A_vreg_11, A_vreg_tmp, mode1, 1);
    movc(A_vreg_12, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[12];
    movc(A_vreg_12, A_vreg_tmp, mode1, 1);
    movc(A_vreg_13, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[13];
    movc(A_vreg_13, A_vreg_tmp, mode1, 1);
    movc(A_vreg_14, A_vreg_tmp, mode2, 1);
    A_vreg_tmp = A_vec_ptr[14];
    movc(A_vreg_14, A_vreg_tmp, mode1, 1);
    movc(A_vreg_0, A_vreg_tmp, mode2, 1);
    
    global_sync();

    // load inputs to shared memory
    int idx = lid >> 3;
    __local uint8x128* h_shr_vec_ptr0 = (__local uint8x128*) (h_shr_ptr);
    A_vreg_tmp = in_vec_ptr[idx];
    store_uint8x128_local(A_vreg_tmp, h_shr_vec_ptr0, idx, 0);
    local_sync();
    __local uint8x128* h_shr_vec_ptr = (__local uint8x128*) (h_shr_ptr + bid);
    float res = 0.f;

    #pragma unroll
    for (int i = 0; i < 4; i++) {
        dot_mask0(res, A_vreg_0, h_shr_vec_ptr, 0);
        dot_fp32(res, A_vreg_1, h_shr_vec_ptr, 1);
        dot_fp32(res, A_vreg_2, h_shr_vec_ptr, 2);
        dot_fp32(res, A_vreg_3, h_shr_vec_ptr, 3);
        dot_fp32(res, A_vreg_4, h_shr_vec_ptr, 4);
        dot_fp32(res, A_vreg_5, h_shr_vec_ptr, 5);
        dot_fp32(res, A_vreg_6, h_shr_vec_ptr, 6);
        dot_fp32(res, A_vreg_7, h_shr_vec_ptr, 7);
        dot_fp32(res, A_vreg_8, h_shr_vec_ptr, 8);
        dot_fp32(res, A_vreg_9, h_shr_vec_ptr, 9);
        dot_fp32(res, A_vreg_10, h_shr_vec_ptr, 10);
        dot_fp32(res, A_vreg_11, h_shr_vec_ptr, 11);
        dot_fp32(res, A_vreg_12, h_shr_vec_ptr, 12);
        dot_fp32(res, A_vreg_13, h_shr_vec_ptr, 13);
        dot_fp32(res, A_vreg_14, h_shr_vec_ptr, 14);
        dot_mask1(res, A_vreg_0, h_shr_vec_ptr, 15);

        h_shr_vec_ptr += 16;
        out_ptr[lid] = res;
        out_ptr += WG_SIZE;
    }
}
