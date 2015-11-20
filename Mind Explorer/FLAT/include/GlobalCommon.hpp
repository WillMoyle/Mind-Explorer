#ifndef GLOBAL_COMMON_HPP_
#define GLOBAL_COMMON_HPP_

#ifdef __cplusplus

namespace FLAT
{
    typedef float  spaceUnit;
    typedef float bigSpaceUnit;
#define PAGE_SIZE 4096
    
#define DIMENSION 3
#define FILE_BUFFER_SIZE 4*PAGE_SIZE
#define RAW_DATA_HEADER_SIZE 16+(2*DIMENSION*sizeof(spaceUnit))
    
    typedef char int8;
    typedef int  int32;
    typedef unsigned char uint8;
    typedef unsigned short uint16;
    typedef unsigned int  uint32;
    typedef unsigned long long uint64;
    typedef long long int64;
}

#endif
#endif
