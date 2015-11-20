#ifndef MESH_TRIANGLE_HPP
#define MESH_TRIANGLE_HPP

#include "SpatialObject.hpp"
#include "Box.hpp"
#include "math.h"

#ifdef __cplusplus
namespace FLAT
{
    
    class Mesh: public SpatialObject
    {
    public:
        Vertex vertex1, vertex2, vertex3;
        uint32 neuronId;
        uint32 v1,v2,v3;
        
        Mesh()
        {
        }
        
        Mesh(Vertex vr1, Vertex vr2 ,Vertex vr3,uint32 nId, uint32 vtx1,uint32 vtx2 ,uint32 vtx3)
        {
            vertex1 = vr1;
            vertex2 = vr2;
            vertex3 = vr3;
            neuronId = nId;
            v1 = vtx1;
            v2 = vtx2;
            v3 = vtx3;
        }
        
        // Spatial Object virtual functions
        Box getMBR();
        Vertex getCenter();
        SpatialObjectType getType();
        void unserialize(int8* buffer);
        uint32 getSize();
    };
}

#endif
#endif
