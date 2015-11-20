#ifndef SPATIAL_QUERY_
#define SPATIAL_QUERY_

#include "Box.hpp"

#ifdef __cplusplus

namespace FLAT
{
	enum SpatialQueryType
	{
		RANGE_QUERY,
		SEED_QUERY,
		POINT_QUERY,
		KNN_QUERY,
		MOVING_QUERY
	};


	class QueryStatistics
	{
	public:
		uint64 FLAT_seedIOs;
		uint64 FLAT_metaDataIOs;
		uint64 FLAT_payLoadIOs;
		uint64 FLAT_metaDataEntryLookup;
		int32 FLAT_seedId;
		uint64 FLAT_prefetchMetaHits;
		uint64 FLAT_prefetchPayLoadHit;
		uint64 FLAT_prefetchBuildingComparison;
		uint64 FLAT_prefetchVertices;
		uint64 FLAT_prefetchEdges;
		uint64 FLAT_prefetchPredictionComparison;
		uint64 FLAT_prefetchEntryCandidates;

		uint64 UselessPoints;
		uint64 ResultPoints;
		uint64 ObjectsPerPage;
		uint32 ObjectSize;

		uint64 RTREE_nodeIOs;
		uint64 RTREE_leafIOs;

		QueryStatistics();
		void add(QueryStatistics& qs);
		void printFLATstats();
	};


	class SpatialQuery
	{
	public:
		QueryStatistics stats;
		SpatialQueryType type;
		Box Region;
		Vertex Point;

		SpatialQuery();
	};


}
#endif
#endif
