#ifndef SEED_BUILDER_HPP_
#define SEED_BUILDER_HPP_

#include "SpatialIndex.h"

#ifdef __cplusplus

namespace FLAT
{
	class nodeSkeleton
	{
	public:
		SpatialIndex::id_type *m_pIdentifier;

		SpatialIndex::Region **m_ptrMBR;

		uint32_t *m_pDataLength;

		byte **m_pData;

		SpatialIndex::Region m_nodeMBR;

		uint32_t level;

		uint32_t children;

		uint32_t nodeType;

		uint32_t dataLength;

		nodeSkeleton();

		~nodeSkeleton();
	};

	class SeedBuilder
	{
	public:
		static nodeSkeleton * readNode(SpatialIndex::id_type page,SpatialIndex::IStorageManager* m_pStorageManager);
	};

}
#endif
#endif
