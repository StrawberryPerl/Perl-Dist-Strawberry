#define RETURN_ON_ERROR(x,h,s) \
    if (ERROR_SUCCESS != x) { \
        SimpleLogString1(h,s); \
        return x; \
    }
 
#define RETURN_ON_ERROR_FREE(x,y,h,s) \
    if (ERROR_SUCCESS != x) { \
        SimpleLogString1(h,s); \
        free(y); \
        return x; \
    }
 
#define RETURN_ON_ERROR_FREE2(x,y,z,h,s) \
    if (ERROR_SUCCESS != x) { \
        SimpleLogString1(h,s); \
        free(y); \
        free(z); \
        return x; \
    }
 
#define RETURN_IF_NULL(x,h,s) \
    if (NULL == x) { \
        SimpleLogString1(h,s); \
        return ERROR_INSTALL_FAILURE; \
    }

#ifdef _DEBUG
#define LOG_DEBUG_DETAILS_IF_NULL(x,h) \
    if (NULL == x) { \
      PrintUINT(h,x); \
      PrintLastErrorDetails(h); \
    }
#define LOG_DEBUG_DETAILS_ON_ERROR(x,h) \
    if (ERROR_SUCCESS != x) { \
      PrintUINT(h,x); \
      PrintLastErrorDetails(h); \
    }
#else
#define LOG_DEBUG_DETAILS_IF_NULL(x,h)
#define LOG_DEBUG_DETAILS_ON_ERROR(x,h)
#endif


extern void SimpleLogString1(MSIHANDLE hModule, LPCTSTR s);
extern void SimpleLogString2(MSIHANDLE hModule, LPCTSTR s, LPCTSTR t);
extern void SimpleLogString3(MSIHANDLE hModule, LPCTSTR s, LPCTSTR t, LPCTSTR u);
extern void SimpleLogString4(MSIHANDLE hModule, LPCTSTR s, LPCTSTR t, LPCTSTR u, LPCTSTR v);
extern void PrintLastErrorDetails(MSIHANDLE hModule);
extern void PrintUINT(MSIHANDLE hModule, UINT i);