#include <limits>
#include "SpatialObjectFactory.hpp"
#include "Vertex.hpp"
#include "Box.hpp"
#include <cassert>
#include <iostream>
#include "math.h"
namespace FLAT
{
    spaceUnit & Vertex::operator [](int subscript)
    {
        assert (subscript >= 0 && subscript < DIMENSION);
        return Vector[subscript];
    }
    
    const spaceUnit & Vertex::operator [](int subscript) const
    {
        assert (subscript >= 0 && subscript < DIMENSION);
        return Vector[subscript];
    }

    // The Absolute difference in each dimension of the vector
	void Vertex::differenceVector(const Vertex &v1,const Vertex &v2, Vertex &difference)
	{
		for (int i=0;i<DIMENSION;i++)
		{
			if (v1.Vector[i]>=v2.Vector[i])
				difference.Vector[i] = v1.Vector[i]-v2.Vector[i];
			else
				difference.Vector[i] = v2.Vector[i]-v1.Vector[i];
		}
	}

	// Midpoint of 2 Vertices
	void Vertex::midPoint (const Vertex &v1,const Vertex &v2,Vertex &mid)
	{
		for (int i=0;i<DIMENSION;i++)
			mid.Vector[i] = (v1.Vector[i]+v2.Vector[i]) /2;
	}

	// for SpatialObject Base Class
	Box Vertex::getMBR()
	{
		return Box(*this,*this);
	}

	void Vertex::unserialize(int8* buffer)
	{
		memcpy(&Vector, buffer,DIMENSION * sizeof(spaceUnit));
	}

	uint32 Vertex::getSize()
	{
		return DIMENSION * sizeof(spaceUnit);
	}

	// for SpatialObject Base Class
	Vertex Vertex::getCenter()
	{
		return *this;
	}

	SpatialObjectType Vertex::getType()
	{
		return VERTEX;
	}
}
