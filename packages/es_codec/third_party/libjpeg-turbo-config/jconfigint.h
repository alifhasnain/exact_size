/* Hand-written equivalent of libjpeg-turbo 3.2.1 src/jconfigint.h.in (see jconfig.h). */

#define BUILD  "exactsize"

#if defined(_MSC_VER)
#define HIDDEN
#undef inline
#define INLINE  __forceinline
#define THREAD_LOCAL  __declspec(thread)
#else
#define HIDDEN  __attribute__((visibility("hidden")))
#undef inline
#define INLINE  __inline__ __attribute__((always_inline))
#define THREAD_LOCAL  __thread
#endif

#define PACKAGE_NAME  "libjpeg-turbo"
#define VERSION  "3.2.1"

#if defined(_WIN64) || defined(__LP64__) || defined(__x86_64__) || defined(__aarch64__)
#define SIZEOF_SIZE_T  8
#else
#define SIZEOF_SIZE_T  4
#endif

#if defined(__GNUC__) || defined(__clang__)
#if (SIZEOF_SIZE_T == 8 && defined(__LP64__)) || (SIZEOF_SIZE_T == 4)
#define HAVE_BUILTIN_CTZL
#endif
#endif

#if defined(_MSC_VER)
#define HAVE_INTRIN_H
#endif

#if defined(_MSC_VER) && defined(HAVE_INTRIN_H)
#if (SIZEOF_SIZE_T == 8)
#define HAVE_BITSCANFORWARD64
#elif (SIZEOF_SIZE_T == 4)
#define HAVE_BITSCANFORWARD
#endif
#endif

#if defined(__has_attribute)
#if __has_attribute(fallthrough)
#define FALLTHROUGH  __attribute__((fallthrough));
#else
#define FALLTHROUGH
#endif
#else
#define FALLTHROUGH
#endif

#ifndef BITS_IN_JSAMPLE
#define BITS_IN_JSAMPLE  8
#endif

#undef C_ARITH_CODING_SUPPORTED
#undef D_ARITH_CODING_SUPPORTED
#undef WITH_SIMD

#if BITS_IN_JSAMPLE == 8
#define C_ARITH_CODING_SUPPORTED 1
#define D_ARITH_CODING_SUPPORTED 1
/* #undef WITH_SIMD */
#define SIMD_ARCHITECTURE  NONE
#endif

/* #undef WITH_PROFILE */
