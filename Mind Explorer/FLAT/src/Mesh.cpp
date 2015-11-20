#include "Mesh.hpp"
#include <cassert>
#include <iostream>

namespace FLAT
{
	Box Mesh::getMBR()
		{
		Box box;
            box.low = vertex1;
            box.high = vertex1;
            
            for (int i=0;i<DIMENSION;i++)
            {
                if (vertex2.Vector[i]<box.low.Vector[i]) box.low.Vector[i] = vertex2.Vector[i];
                if (vertex3.Vector[i]<box.low.Vector[i]) box.low.Vector[i] = vertex3.Vector[i];
                
                if (vertex2.Vector[i]>box.high.Vector[i]) box.high.Vector[i] = vertex2.Vector[i];
                if (vertex3.Vector[i]>box.high.Vector[i]) box.high.Vector[i] = vertex3.Vector[i];
            }
		return box;
		}

	Vertex Mesh::getCenter()
		{
		Vertex center;
		for (int i=0;i<DIMENSION;i++)
			center.Vector[i] = (vertex1.Vector[i]+vertex2.Vector[i]+vertex3.Vector[i])/3;
		return center;
		}

	SpatialObjectType Mesh::getType()
	{
		return MESH;
	}

	void Mesh::unserialize(int8* buffer)
	{
		int8* ptr = buffer;
		memcpy(&(vertex1.Vector), ptr,DIMENSION * sizeof(spaceUnit));
		ptr += DIMENSION * sizeof(spaceUnit);
		memcpy(&(vertex2.Vector), ptr,DIMENSION * sizeof(spaceUnit));
		ptr += DIMENSION * sizeof(spaceUnit);
		memcpy(&(vertex3.Vector), ptr,DIMENSION * sizeof(spaceUnit));
		ptr += DIMENSION * sizeof(spaceUnit);

		memcpy(&neuronId, ptr,sizeof(uint32));
		ptr += sizeof(uint32);
		memcpy(&v1, ptr,sizeof(uint32));
		ptr += sizeof(uint32);
		memcpy(&v2, ptr,sizeof(uint32));
		ptr += sizeof(uint32);
		memcpy(&v3, ptr,sizeof(uint32));
	}

	uint32 Mesh::getSize()
	{
		return (DIMENSION*3*sizeof(spaceUnit))+(sizeof(uint32)*4);
	}
}
