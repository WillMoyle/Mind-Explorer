#ifndef VERTEX_HPP
#define VERTEX_HPP

#include "SpatialObject.hpp"

#ifdef __cplusplus

namespace FLAT
{
    class Vertex: public SpatialObject
    {
    public:
        spaceUnit Vector[DIMENSION];
        
        Vertex()
        {
            for (int i=0;i<DIMENSION;i++)
                Vector[i]=0;
        }
        
        Vertex(spaceUnit x, spaceUnit y ,spaceUnit z)
        {
            Vector[0]=x;
            Vector[1]=y;
            Vector[2]=z;
        }
        
        spaceUnit       & operator[](int subscript);
        const spaceUnit & operator[](int subscript) const;
        static void differenceVector(const Vertex &v1,const Vertex &v2, Vertex &difference);
        static void midPoint (const Vertex &v1,const Vertex &v2, Vertex &mid);
        
        
        // Spatial Object virtual functions
        Box getMBR();
        Vertex getCenter();
        void unserialize(int8* buffer);
        SpatialObjectType getType();
        uint32 getSize();
    };
}

#endif
#endif
