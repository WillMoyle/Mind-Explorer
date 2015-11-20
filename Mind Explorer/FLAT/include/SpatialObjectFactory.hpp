#ifndef SPATIAL_OBJECT_FACTORY_HPP
#define SPATIAL_OBJECT_FACTORY_HPP

#include "GlobalCommon.hpp"

#ifdef __cplusplus

namespace FLAT
{
	class SpatialObject;
	enum SpatialObjectType
	{
		VERTEX,
		BOX,
		CONE,
		TRIANGLE,
		SPHERE,
		SEGMENT,
		MESH,
		SOMA,
		SYNAPSE,
		NONE
	};

	class SpatialObjectFactory
	{
	public:
		 static SpatialObject* create (SpatialObjectType objType);
		 static uint32 getSize(SpatialObjectType objType);
	};
}

#endif
#endif