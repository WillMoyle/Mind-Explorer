#include <vector>
#include "Box.hpp"

using namespace std;
namespace FLAT
{
	bigSpaceUnit Box::volume(const Box &b)
	{
		bigSpaceUnit v=1;
		Vertex distance;
		Vertex::differenceVector(b.low,b.high,distance);

		for (int i=0;i<DIMENSION;i++)
			v *= distance.Vector[i];
		return v;
	}
    
    
    // Do 2 Boxes overlap Any Volume?
    bool Box::overlap (const Box &b1,const Box &b2)
    {
        for (int i=0;i<DIMENSION;i++)
        {
            bool overlap=false;
            if (b1.low.Vector[i]  >= b2.low.Vector[i] && b1.low.Vector[i]  <= b2.high.Vector[i]) overlap=true;
            if (b1.high.Vector[i] >= b2.low.Vector[i] && b1.high.Vector[i] <= b2.high.Vector[i]) overlap=true;
            if (b2.low.Vector[i]  >= b1.low.Vector[i] && b2.low.Vector[i]  <= b1.high.Vector[i]) overlap=true;
            if (b2.high.Vector[i] >= b1.low.Vector[i] && b2.high.Vector[i] <= b1.high.Vector[i]) overlap=true;
            if (!overlap) return false;
        }
        return true;
    }

	Box Box::getMBR()
	{
		return *this;
	}

	Vertex Box::getCenter()
	{
		Vertex v;
        Vertex::midPoint (low,high,v);
		return v;
	}

    SpatialObjectType Box::getType()
	{
		return BOX;
	}

	void Box::unserialize(int8* buffer)
	{
		int8* ptr = buffer;
		memcpy(&(low.Vector), ptr,DIMENSION * sizeof(spaceUnit));
		ptr += DIMENSION * sizeof(spaceUnit);
		memcpy(&(high.Vector), ptr,DIMENSION * sizeof(spaceUnit));
	}

	uint32 Box::getSize()
	{
		return 2* DIMENSION * sizeof(spaceUnit);
	}
}

