// Adapted from file by Farhan Tauheed

#ifndef BOX_HPP
#define BOX_HPP

#include "SpatialObject.hpp"
#include "Vertex.hpp"

#ifdef __cplusplus

namespace FLAT
{
	class Box : public SpatialObject
	{
	public:
		Vertex low;
		Vertex high;

		Box()
			{

			}

		Box(const Vertex &low, const Vertex &high)
			{
				this->low  = low;
				this->high = high;
			}

		~Box()
		{

		}
		static bigSpaceUnit volume(const Box &b);
		static bool overlap (const Box &b1,const Box &b2);

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