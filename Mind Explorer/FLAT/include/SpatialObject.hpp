#ifndef SPATIAL_OBJECT_HPP
#define SPATIAL_OBJECT_HPP

#include "SpatialObjectFactory.hpp"

#ifdef __cplusplus

namespace FLAT
{
class Box;
class Vertex;

	class SpatialObject
	{
	public:
		SpatialObject();
		virtual ~SpatialObject();

		virtual Box getMBR()=0;
		virtual Vertex getCenter()=0;
		virtual void unserialize(int8* buffer)=0;
		virtual uint32 getSize()=0;
		virtual SpatialObjectType getType()=0;
	};

}

#endif
#endif