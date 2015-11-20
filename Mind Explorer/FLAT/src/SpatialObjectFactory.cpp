#include "SpatialObjectFactory.hpp"
#include "Box.hpp"
#include "Vertex.hpp"
#include "Mesh.hpp"
#include <cstdlib>

namespace FLAT
{
    SpatialObject* SpatialObjectFactory::create (SpatialObjectType objType)
    {
        if (objType == VERTEX)
            return new Vertex();
        else if (objType == BOX)
            return new Box();
        else if (objType == MESH)
            return new Mesh();
        exit(1);
        return NULL;
    }
    
    uint32 SpatialObjectFactory::getSize (SpatialObjectType objType)
    {
        switch (objType)
        {
            case VERTEX:
                return DIMENSION*sizeof(spaceUnit);
            case BOX:
                return DIMENSION*2*sizeof(spaceUnit);
            case CONE:
                return ((DIMENSION*2)+2)*sizeof(spaceUnit);
            case TRIANGLE:
                return DIMENSION*3*sizeof(spaceUnit);
            case SPHERE:
                return (DIMENSION+1)*sizeof(spaceUnit);
            case SEGMENT:
                return (((DIMENSION*2)+2)*sizeof(spaceUnit))+(sizeof(uint32)*3);
            case MESH:
                return (DIMENSION*3*sizeof(spaceUnit))+(sizeof(uint32)*4);
            case SOMA:
                return ((DIMENSION+1)*sizeof(spaceUnit))+sizeof(uint32);
            case SYNAPSE:
                return (DIMENSION*sizeof(spaceUnit)*2) + (sizeof(uint32)*4) + sizeof(spaceUnit);
            case NONE:
                exit(1);
        }
        exit(1);
        return 0;
    }
}
