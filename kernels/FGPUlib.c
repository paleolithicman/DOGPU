#include "clctypes.h"

#define TYPE_CHECK(TYPE,X,MSG) ({ TYPE __dummy; __typeof__(X) __dummy2; (void)(&__dummy == &__dummy2); 1; })


#define __local __attribute__((address_space(1)))

typedef unsigned char uint8_t;
typedef signed char int8_t;
typedef unsigned int uint32_t;
typedef uint8_t uint8x128 __attribute__((ext_vector_type(128)));

float sqrtf(float);

inline int get_group_id(const int dim)
{
    int res;
    __asm__ __volatile__(
        "wgid %0, %1"
        : "=r"(res)
        : "I"(dim)
    );
    return res;
}

inline int get_local_size(const int dim)
{
    int res;
    __asm__ __volatile__(
        "wgsize %0, %1"
        : "=r"(res)
        : "I"(dim)
    );
    return res;
}

inline int get_global_size(const int dim)
{
    int res;
    __asm__ __volatile__(
        "size %0, %1"
        : "=r"(res)
        : "I"(dim)
    );
    return res;
}

inline int get_local_id(const int dim)
{
    int lid;
    __asm__ __volatile__(
        "lid %0, %1"
        : "=r"(lid)
        : "I"(dim)
    );
    return lid;
}

inline int get_global_id(const int dim)
{
    int index, lid;
    __asm__ __volatile__(
        "lid %0, %1"
        : "=r"(lid)
        : "I"(dim)
    );
    __asm__ __volatile__(
        "wgoff %0, %1"
        : "=r"(index)
        : "I"(dim)
    );
    return index + lid;
}


inline void local_sync()
{
    __asm__ __volatile__("lsync":::"memory");
}

inline void global_sync()
{
    __asm__ __volatile__("gsync":::"memory");
}


// FIXME: ahsu
// maybe the compiler should be able to infer these instructions?
#define store_uint8x128(val, base, disp, offset)                                      \
{                                                                                             \
    TYPE_CHECK(uint8x128,           val    , val_is_expected_to_be_uint8x128);                \
    TYPE_CHECK(__global uint8x128*, base   , base_is_expected_to_be_global_uint8x128_ptr);    \
    __asm__ __volatile__(                                                                     \
        "swc %0, [%1 + %2 + %3]"                                                              \
        :                                                                                     \
        : "f"(val), "r"(base), "r"(disp), "I"(offset)                                         \
    );                                                                                        \
}

#define store_uint8x128_local(val, base, disp, offset)                                      \
{                                                                                             \
    TYPE_CHECK(uint8x128,           val    , val_is_expected_to_be_uint8x128);                \
    TYPE_CHECK(__local uint8x128*, base   , base_is_expected_to_be_global_uint8x128_ptr);    \
    TYPE_CHECK(int,                 disp   , disp_is_expected_to_be_int);                     \
    TYPE_CHECK(int,                 offset , offset_is_expected_to_be_int);                   \
    __asm__ __volatile__(                                                                     \
        "sswc %0, [%1 + %2 + %3]"                                                              \
        :                                                                                     \
        : "f"(val), "r"(base), "r"(disp), "I"(offset)                                         \
    );                                                                                        \
}

inline uint8x128 load_uint8x128(__global uint8x128* base, int disp, int offset)
{
    uint8x128 val;
    __asm__ __volatile__(
        "lwc %0, [%1 + %2 + %3]" 
        : "=f"(val)
        : "r"(base), "r"(disp), "I"(offset)
    );
    return val;
}

inline uint8x128 load_uint8x128_local(__local uint8x128* base, int disp, int offset)
{
    uint8x128 val;
    __asm__ __volatile__(
        "slwc %0, [%1 + %2 + %3]" 
        : "=f"(val)
        : "r"(base), "r"(disp), "I"(offset)
    );
    return val;
}

inline uint8x128 load_if_zero_uint8x128(int cond, __global uint8x128* base, int offset)
{
    uint8x128 val;
    __asm__ __volatile__(
        "lwcz %0, %1, [%2 + %3]"
        : "=f"(val)
        : "r"(cond), "r"(base), "I"(offset)
    );
    return val;
}

#define store_if_zero_uint8x128(val, cond, base, offset)                                      \
{                                                                                             \
    TYPE_CHECK(uint8x128,           val    , val_is_expected_to_be_uint8x128);                \
    TYPE_CHECK(int,                 cond   , cond_is_expected_to_be_int);                     \
    TYPE_CHECK(__global uint8x128*, base   , base_is_expected_to_be_global_uint8x128_ptr);    \
    TYPE_CHECK(int,                 offset , offset_is_expected_to_be_int);                   \
    __asm__ __volatile__(                                                                     \
        "swcz %0, %1, [%2 + %3]"                                                              \
        :                                                                                     \
        : "f"(val), "r"(cond), "r"(base), "I"(offset)                                         \
    );                                                                                        \
}

inline uint8x128 load_local_if_zero(int cond, __local uint8x128* base, int offset)
{
    uint8x128 val;
    __asm__ __volatile__(
        "slwcz %0, %1, [%2 + %3]"
        : "=f"(val)
        : "r"(cond), "r"(base), "I"(offset)
    );
    return val;
}

#define store_local_if_zero(val, cond, base, offset)                                          \
{                                                                                             \
    TYPE_CHECK(uint8x128,           val    , val_is_expected_to_be_uint8x128);                \
    TYPE_CHECK(int,                 cond   , cond_is_expected_to_be_int);                     \
    TYPE_CHECK(__local uint8x128*,  base   , base_is_expected_to_be_global_uint8x128_ptr);    \
    TYPE_CHECK(int,                 offset , offset_is_expected_to_be_int);                   \
    __asm__ __volatile__(                                                                     \
        "sswcz %0, %1, [%2 + %3]"                                                             \
        :                                                                                     \
        : "f"(val), "r"(cond), "r"(base), "I"(offset)                                         \
    );                                                                                        \
}

inline float load_if_zero_fp32(int cond, __global float* base, int offset)
{
	float val;
    __asm__ __volatile__(
        "lwz %0, %1, [%2 + %3]"
        : "=r"(val)
        : "r"(cond), "r"(base), "I"(offset)
    );
    return val;
}

inline void store_if_zero_uint(int val, int cond, __global unsigned* base, int offset)
{
    __asm__ __volatile__(
        "swz %0, %1, [%2 + %3]"
        :
        : "r"(val), "r"(cond), "r"(base), "I"(offset)
    );
}

inline void store_if_zero_fp32(float val, int cond, __global float* base, int offset)
{
    __asm__ __volatile__(
        "swz %0, %1, [%2 + %3]"
        :
        : "r"(val), "r"(cond), "r"(base), "I"(offset)
    );
}

inline int8_t load_if_zero_int8(int8_t val, int cond, __global int8_t* base, int offset)
{
    __asm__ __volatile__(
        "lbz %0, %1, [%2 + %3]"
        : "+r"(val)
        : "r"(cond), "r"(base), "I"(offset)
    );
    return val;
}

inline void store_if_zero_int8(int8_t val, int cond, __global int8_t* base, int offset)
{
    __asm__ __volatile__(
        "sbz %0, %1, [%2 + %3]"
        :
        : "r"(val), "r"(cond), "r"(base), "I"(offset)
    );
}

//inline int median(uint8x128 in0, uint8x128 in1)
//{
//	int out;
//    __asm__("vvrv %0, %1, %2, %3"
//        : "=r"(out), "+f"(in0)
//        : "f"(in1), "I"(0)
//		: "memory");
//	return out;
//}

// FIXME: ahsu
// dot functions defined here as macros instead of the wrapper functions commented below
// when invoking the inline assembly via a function call, the vector types exhibit a weird type splitting issue that
// does not occur when using inline assembly directly
// just using macros with static type checks for now instead of fixing the compiler issue
#define _dot(acc, srcA, srcB_ptr, srcB_off)                                                         \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          srcA    , dot_srcA_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(__local uint8x128*, srcB_ptr, dot_srcB_ptr_is_expected_to_be_local_uint8x128_ptr);   \
    TYPE_CHECK(int,                srcB_off, dot_srcB_off_is_expected_to_be_int);                   \
    __asm__("vdot %0, %1, [%2 + %3]"                                                                \
        : "+r"(acc) : "f"(srcA), "r"(srcB_ptr), "I"(srcB_off) : "memory");                          \
}

#define dot_mask0(acc, srcA, srcB_ptr, srcB_off)                                                         \
{                                                                                                   \
    __asm__("vdotm0 %0, %1, [%2 + %3]"                                                                \
        : "+r"(acc) : "f"(srcA), "r"(srcB_ptr), "I"(srcB_off) : "memory");                          \
}

#define dot_mask1(acc, srcA, srcB_ptr, srcB_off)                                                         \
{                                                                                                   \
    __asm__("vdotm1 %0, %1, [%2 + %3]"                                                                \
        : "+r"(acc) : "f"(srcA), "r"(srcB_ptr), "I"(srcB_off) : "memory");                          \
}

#define dot_fp32(acc, srcA, srcB_ptr, srcB_off)                                                     \
{                                                                                                   \
    TYPE_CHECK(float,              acc,      dot_accumulator_is_expected_to_be_fp32);               \
    _dot(acc, srcA, srcB_ptr, srcB_off);                                                            \
}

#define dot_int32(acc, srcA, srcB_ptr, srcB_off)                                                    \
{                                                                                                   \
    TYPE_CHECK(int,                acc,      dot_accumulator_is_expected_to_be_int32);              \
    _dot(acc, srcA, srcB_ptr, srcB_off);                                                            \
}

#define nodot_fp32(acc, srcA, srcB_ptr, srcB_off)                                                   \
{                                                                                                   \
    TYPE_CHECK(float,              acc,      dot_accumulator_is_expected_to_be_fp32);               \
    TYPE_CHECK(uint8x128,          srcA    , dot_srcA_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(__local uint8x128*, srcB_ptr, dot_srcB_ptr_is_expected_to_be_local_uint8x128_ptr);   \
    TYPE_CHECK(int,                srcB_off, dot_srcB_off_is_expected_to_be_int);                   \
    for (int _i = 0; _i < 32; ++_i) {                                                               \
        int _off = srcB_off * 32 + _i;                                                              \
        float _a, _b;                                                                               \
        __asm__("addi %1, %3, 0\n\t" /* placeholder for a vreg move instr, i.e. vmov r, rf, imm */  \
                "slw  %2, [%3 + %4 + %5]\n\t"                                                       \
                "ffma %0, %1, %2"                                                                   \
            : "+r"(acc), "=r"(_a), "=r"(_b) : "r"(srcB_ptr), "r"(_off), "I"(0), "f"(srcA)           \
            : "memory");                                                                            \
    }                                                                                               \
}

#define nodotnosmem_fp32(acc, srcA, srcB_ptr, srcB_off)                                             \
{                                                                                                   \
    TYPE_CHECK(float,               acc,      dot_accumulator_is_expected_to_be_fp32);              \
    TYPE_CHECK(uint8x128,           srcA    , dot_srcA_is_expected_to_be_uint8x128);                \
    TYPE_CHECK(__global uint8x128*, srcB_ptr, dot_srcB_ptr_is_expected_to_be_global_uint8x128_ptr); \
    TYPE_CHECK(int,                 srcB_off, dot_srcB_off_is_expected_to_be_int);                  \
    for (int _i = 0; _i < 32; ++_i) {                                                               \
        int _off = srcB_off * 32 + _i;                                                              \
        float _a, _b;                                                                               \
        __asm__("addi %1, %3, 0\n\t" /* placeholder for a vreg move instr, i.e. vmov r, rf, imm */  \
                "lw   %2, [%3 + %4]\n\t"                                                            \
                "ffma %0, %1, %2"                                                                   \
            : "+r"(acc), "=r"(_a), "=r"(_b) : "r"(srcB_ptr), "r"(_off), "I"(0), "f"(srcA)           \
            : "memory");                                                                            \
    }                                                                                               \
}

#define movc(dst, src, offset, mode)                                                                \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          src    , movc_src_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(uint8x128,          dst    , movc_dst_is_expected_to_be_local_uint8x128_ptr);        \
    TYPE_CHECK(int,                offset , movc_mask_is_expected_to_be_int);                       \
    TYPE_CHECK(int,                mode   , off_is_expected_to_be_int);                             \
    __asm__("vrvi %0, %1, %2, %3"                                                                   \
        : "+f"(dst)                                                                                 \
        : "f"(src), "r"(offset), "I"(mode) : "memory");                                             \
}

#define bitonic_sort(va, vb, dir, imm)                                                                \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          va    , bitonic_sort_va_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(uint8x128,          vb    , bitonic_sort_vb_is_expected_to_be_local_uint8x128_ptr);        \
    __asm__("vrvi %0, %1, %2, %3"                                                                   \
        : "+f"(va)                                                                                 \
        : "f"(vb), "r"(dir), "I"(256+imm));                                             \
}

#define sort(vx, dir)                                                                \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          vx    , sort_vx_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(int,                dir , sort_dir_is_expected_to_be_int);                       \
    __asm__("vrvv %0, %1, %2, %3"                                                                   \
        : "+f"(vx)                                                                                 \
        : "f"(vx), "r"(dir), "I"(0));                                             \
}

#define vmrv(dst, srcA, srcB_ptr, srcB_off)                                                         \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          dst,      dst_is_expected_to_be_uint8x128);                      \
    TYPE_CHECK(uint8x128,          srcA    , srcA_is_expected_to_be_uint8x128);                     \
    TYPE_CHECK(__local uint8x128*, srcB_ptr, srcB_ptr_is_expected_to_be_local_uint8x128_ptr);       \
    TYPE_CHECK(int,                srcB_off, srcB_off_is_expected_to_be_int);                       \
    __asm__("vmrv %0, %1, [%2 + %3]"                                                                \
        : "+f"(dst) : "f"(srcA), "r"(srcB_ptr), "I"(srcB_off) : "memory");                          \
}

//inline float dot_fp32(float acc, uint8x128 srcA, __local uint8x128* srcB_ptr, int srcB_off)
//{
//    __asm__ __volatile__(
//        "vdot %0, %1, [%2 + %3]"
//        : "+r"(acc)
//        : "f"(srcA), "r"(srcB_ptr), "I"(srcB_off)
//    );
//    return acc;
//}

//inline int dot_int32(int acc, uint8x128 srcA, __local uint8x128* srcB_ptr, int srcB_off)
//{
//    __asm__ __volatile__(
//        "vdot %0, %1, [%2 + %3]"
//        : "+r"(acc)
//        : "f"(srcA), "r"(srcB_ptr), "I"(srcB_off)
//    );
//    return acc;
//}

// #define butterfly16(io0, io1, twid)                                                                 \
// {                                                                                                   \
//     TYPE_CHECK(uint8x128,          io0    , but16_io0_is_expected_to_be_uint8x128);                 \
//     TYPE_CHECK(uint8x128,          io1    , but16_io1_is_expected_to_be_uint8x128);                 \
//     TYPE_CHECK(uint8x128,          twid   , but16_twd_is_expected_to_be_uint8x128);                 \
//     __asm__("but16 %0, %1, %2"                                                                      \
//         : "+f"(io0), "+f"(io1)                                                                      \
//         : "f"(twid));                                                                               \
// }

#define butterfly(io0, twid, mode)                                                           \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          io0    , but0_io0_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(uint8x128,          twid   , but0_twd_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(int,                mode  , but0_stage_is_expected_to_be_int);                      \
    __asm__("vvvi %0, %1, %2, %3"                                                                   \
        : "=f"(io0)                                                                      \
        : "0"(io0), "f"(twid), "I"((mode<<6)+3));                                                                   \
}

#define butterfly0(io0, mode)                                                           \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          io0    , but0_io0_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(int,                mode  , but0_stage_is_expected_to_be_int);                      \
    __asm__("vvvi %0, %1, %2, %3"                                                                   \
        : "=f"(io0)                                                                      \
        : "0"(io0), "f"(io0), "I"(mode) : "memory");                                                                   \
}

#define butterfly16(o0, i0, i1, mode)                                                           \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          o0    , but0_o0_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(uint8x128,          i0    , but0_i0_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(uint8x128,          i1    , but0_i1_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(int,                mode  , but0_stage_is_expected_to_be_int);                      \
    __asm__("vvvi %0, %1, %2, %3"                                                                   \
        : "=f"(o0)                                                                      \
        : "f"(i0), "f"(i1), "I"(mode) : "memory");                                                                   \
}

#define get_elem(out, in, idx)                                                               \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          in     , get_elem_in_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(int,                idx    , get_elem_idx_is_expected_to_be_int);                      \
    __asm__("vrri %0, %1, %2, %3"                                                                   \
        : "+r"(out)                                                                      \
        : "f"(in), "r"(idx), "I"(0));                                                                   \
}

#define write_elem(out, val, idx) \
{ \
    TYPE_CHECK(uint8x128,          out    , write_elem_in_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(float,              val    , write_elem_in_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(int,                idx    , write_elem_idx_is_expected_to_be_int);                      \
    __asm__ __volatile__( \
        "rvi %0, %1, %2, 0" \
        : "+f"(out) \
        : "r"(val), "r"(idx)); \
}

#define get_vec(out, in)                                                               \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          out    , get_vec_out_is_expected_to_be_uint8x128);                      \
    TYPE_CHECK(uint8x128,          in     , get_vec_in_is_expected_to_be_uint8x128);                  \
    __asm__("vvi %0, %1, %2"                                                                   \
        : "=f"(out)                                                                      \
        : "f"(in), "I"(0) : "memory");                                                                   \
}

#define median(out, in0, in1, mode)                                                               \
{                                                                                                   \
    TYPE_CHECK(unsigned,                out    , median_length_is_expected_to_be_int);                      \
    TYPE_CHECK(uint8x128,          in0     , median_in_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(uint8x128,          in1     , median_in_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(int,                mode  , mode_is_expected_to_be_int);                      \
    __asm__("vvrv %0, %1, %2, %3"                                                                   \
        : "=r"(out), "+f"(in0) : "f"(in1), "I"(mode) : "memory");                                       \
}

#define sharpen(out, in, length)                                                               \
{                                                                                                   \
    TYPE_CHECK(int,                out    , median_length_is_expected_to_be_int);                      \
    TYPE_CHECK(uint8x128,          in     , median_in_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(int,                length , median_length_is_expected_to_be_int);                      \
    __asm__("vrri %0, %1, %2, %3"                                                                   \
        : "=r"(out)                                                                      \
        : "f"(in), "r"(length), "I"(1));                                                                   \
}

#define vadd(out, in0, in1, off)                                                                 \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          out    , vadd_out_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(uint8x128,          in0    , vadd_in0_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(uint8x128,          in1   , vadd_in1_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(int,           off   , nbody_off_is_expected_to_be_int);                 \
    __asm__("vvvi %0, %1, %2, %3"                                                                      \
        : "+f"(out)                                                                     \
        : "f"(in0), "f"(in1), "I"((off<<6)));                                                \
}

#define vmul(out, in0, in1, off)                                                                 \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          out    , vmul_out_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(uint8x128,          in0    , vmul_in0_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(uint8x128,          in1   , vmul_in1_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(int,           off   , nbody_off_is_expected_to_be_int);                 \
    __asm__("vvvi %0, %1, %2, %3"                                                                      \
        : "+f"(out)                                                                     \
        : "f"(in0), "f"(in1), "I"((off<<6)+1));                                                \
}

#define nbody(out, in0, in1, off)                                                                 \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          out    , nbody_out_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(uint8x128,          in0    , nbody_in0_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(uint8x128,          in1   , nbody_in1_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(int,           off   , nbody_off_is_expected_to_be_int);                 \
    __asm__("vvvi %0, %1, %2, %3"                                                                      \
        : "+f"(out)                                                                     \
        : "f"(in0), "f"(in1), "I"((off<<6)+2));                                                \
}

#define gen_twiddle(out, in, off)                                                                 \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          out    , in_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(uint8x128,          in    , in_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(int,           off   , off_is_expected_to_be_int);                 \
    __asm__("vvi %0, %1, %2"                                                                      \
        : "+f"(out)                                                                     \
        : "f"(in), "I"(off));                                                \
}

#define copy(out, in, off)                                                                 \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          out   , out_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(uint8x128,          in    , in_is_expected_to_be_uint8x128);                 \
    TYPE_CHECK(int,           off   , off_is_expected_to_be_int);                 \
    __asm__("vvi %0, %1, %2"                                                                      \
        : "=f"(out)                                                                     \
        : "f"(in), "I"(off) : "memory");                                                \
}

#define copy_swap(dst, src, mode, dir)                                                                \
{                                                                                                   \
    TYPE_CHECK(uint8x128,          src    , src_is_expected_to_be_uint8x128);                  \
    TYPE_CHECK(uint8x128,          dst    , dst_is_expected_to_be_local_uint8x128_ptr);        \
    __asm__("vrvi %0, %1, %2, %3"                                                                   \
        : "+f"(dst)                                                                                 \
        : "f"(src), "r"(mode), "I"(dir) : "memory");                                             \
}

    //TYPE_CHECK(uint32_t,                mode   , mode_is_expected_to_be_unsigned);                             \
    TYPE_CHECK(uint32_t,                dir   , dir_is_expected_to_be_unsigned);                             \


	
inline uint8x128 set_value(int val, uint32_t bm)
{
    uint8x128 res;
    __asm__ __volatile__(
        "rvi %0, %1, %2, 0"
        : "+f"(res)
        : "r"(val), "r"(bm));
    return res;
}

inline void cfg(int val)
{
    __asm__ __volatile__(
        "cfg %0, 0"
        :
        : "r"(val)
        );
}

inline void init_acc(int val)
{
    float out;
    __asm__ __volatile__(
        "act %0, %1, 3"
        : "=r"(out)
        : "r"(val)
        : "memory"
    );
}

inline float get_acc0(int idx)
{
    float out;
    __asm__ __volatile__(
        "act %0, %1, 7"
        : "=r"(out)
        : "r"(idx)
    );
    return out;
}

inline float get_acc1(int idx)
{
    float out;
    __asm__ __volatile__(
        "act %0, %1, 11"
        : "=r"(out)
        : "r"(idx)
    );
    return out;
}

inline float get_acc2(int idx)
{
    float out;
    __asm__ __volatile__(
        "act %0, %1, 15"
        : "=r"(out)
        : "r"(idx)
    );
    return out;
}

inline float relu_fp32(float in)
{
    float out;
    __asm__ __volatile__(
        "act %0, %1, 0"
        : "=r"(out)
        : "r"(in)
    );
    return out;
}

inline int relu_int32(int in)
{
    int out;
    __asm__ __volatile__(
        "act %0, %1, 0"
        : "=r"(out)
        : "r"(in)
    );
    return out;
}

inline float sigmoid_fp32(float in)
{
    float out;
    __asm__ __volatile__(
        "act %0, %1, 1"
        : "=r"(out)
        : "r"(in)
    );
    return out;
}

inline float tanh_fp32(float in)
{
    float out;
    __asm__ __volatile__(
        "act %0, %1, 2"
        : "=r"(out)
        : "r"(in)
    );
    return out;
}

inline int tanh_int32(int in)
{
    int out;
    __asm__ __volatile__(
        "act %0, %1, 2"
        : "=r"(out)
        : "r"(in)
    );
    return out;
}

inline int load_word(__global uint32_t* base, int disp)
{
    int out;
    __asm__ __volatile__(
        "lw %0, [%1 + %2]"
        : "=r"(out)
        : "r"(base), "r"(disp));
    return out;
}

inline void store_word(__global uint32_t* base, int disp, int val)
{
    __asm__ __volatile__(
        "sw %0, [%1 + %2]"
        : 
        : "r"(val), "r"(base), "r"(disp));
}

inline int load_word_local(__local uint32_t* base, int disp, int offset)
{
    int out;
    __asm__ __volatile__(
        "slw %0, [%1 + %2 + %3]"
        : "=r"(out)
        : "r"(base), "r"(disp), "I"(offset));
    return out;
}

inline void store_word_local(__local uint32_t* base, int disp, int offset, int val)
{
    __asm__ __volatile__(
        "ssw %0, [%1 + %2 + %3]"
        : 
        : "r"(val), "r"(base), "r"(disp), "I"(offset));
}
