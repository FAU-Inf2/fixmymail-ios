#ifndef MAILCORE_MCUTILS_H

#define MAILCORE_MCUTILS_H

#ifdef __cplusplus

#define MC_SAFE_RETAIN(o) ((o) != NULL ? (o)->retain() : NULL)
#define MC_SAFE_COPY(o) ((o) != NULL ? (o)->copy() : NULL)

#define MC_SAFE_RELEASE(o) \
    do { \
        if ((o) != NULL) { \
            (o)->release(); \
            (o) = NULL; \
        } \
    } while (0)

#define MC_SAFE_REPLACE_RETAIN(type, mField, value) \
    do { \
        MC_SAFE_RELEASE(mField); \
        mField = (type *) MC_SAFE_RETAIN(value); \
    } while (0)

#define MC_SAFE_REPLACE_COPY(type, mField, value) \
    do { \
        MC_SAFE_RELEASE(mField); \
        mField = (type *) MC_SAFE_COPY(value); \
    } while (0)

#define MCSTR(str) mailcore::String::uniquedStringWithUTF8Characters("" str "")

#define MCUTF8(str) MCUTF8DESC(str)
#define MCUTF8DESC(obj) ((obj) != NULL ? (obj)->description()->UTF8Characters() : NULL )

#define MCLOCALIZEDSTRING(key) key

#define MCISKINDOFCLASS(instance, class) (dynamic_cast<class *>(instance) != NULL)

#endif

#ifdef _MSC_VER
#	ifdef MAILCORE_DLL
#		define MAILCORE_EXPORT __declspec(dllexport)
#	else
#		define MAILCORE_EXPORT __declspec(dllimport)
#   endif
#else
#	define MAILCORE_EXPORT
#endif

#ifdef __clang__

#if __has_feature(attribute_analyzer_noreturn)
#define CLANG_ANALYZER_NORETURN __attribute__((analyzer_noreturn))
#else
#define CLANG_ANALYZER_NORETURN
#endif

#define ATTRIBUTE_RETURNS_NONNULL __attribute__((returns_nonnull))

#else

#define CLANG_ANALYZER_NORETURN
#define ATTRIBUTE_RETURNS_NONNULL

#endif

#endif
