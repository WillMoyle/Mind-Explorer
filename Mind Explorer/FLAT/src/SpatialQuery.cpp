#include "SpatialQuery.hpp"

#include <fstream>
#include <iostream>

namespace FLAT
{

	SpatialQuery::SpatialQuery()
	{

	}

	QueryStatistics::QueryStatistics()
	{
		FLAT_seedIOs=0;
		FLAT_metaDataIOs=0;
		FLAT_payLoadIOs=0;
		FLAT_metaDataEntryLookup=0;
		FLAT_seedId=-1;

		FLAT_prefetchMetaHits=0;
		FLAT_prefetchPayLoadHit=0;
		FLAT_prefetchBuildingComparison=0;
		FLAT_prefetchVertices=0;
		FLAT_prefetchEdges=0;
		FLAT_prefetchPredictionComparison=0;
		FLAT_prefetchEntryCandidates=0;

		UselessPoints=0;
		ResultPoints=0;
		ObjectsPerPage=0;
		ObjectSize=0;

		RTREE_nodeIOs=0;
		RTREE_leafIOs=0;
	}

	void QueryStatistics::add(QueryStatistics& qs)
	{
		 FLAT_seedIOs     += qs.FLAT_seedIOs;
		 FLAT_metaDataIOs += qs.FLAT_metaDataIOs;
		 FLAT_payLoadIOs  +=qs.FLAT_payLoadIOs;
		 FLAT_metaDataEntryLookup +=FLAT_metaDataEntryLookup;

		 UselessPoints +=qs.UselessPoints;
		 ResultPoints +=qs.ResultPoints;

		 RTREE_nodeIOs +=qs.RTREE_nodeIOs;
		 RTREE_leafIOs +=qs.RTREE_leafIOs;

		 FLAT_prefetchMetaHits+= qs.FLAT_prefetchMetaHits;
		 FLAT_prefetchPayLoadHit+= qs.FLAT_prefetchPayLoadHit;
		 FLAT_prefetchBuildingComparison+=qs.FLAT_prefetchBuildingComparison;

		 FLAT_prefetchVertices+=qs.FLAT_prefetchVertices;
		 FLAT_prefetchEdges+=qs.FLAT_prefetchEdges;

		 FLAT_prefetchPredictionComparison+=qs.FLAT_prefetchPredictionComparison;
		 FLAT_prefetchEntryCandidates+=qs.FLAT_prefetchEntryCandidates;
	}

	void QueryStatistics::printFLATstats()
	{
		uint64 FLAT_TotalIO  = FLAT_seedIOs + FLAT_metaDataIOs + FLAT_payLoadIOs;
		double FLAT_TotalMB  = ((FLAT_TotalIO+0.0)*(PAGE_SIZE+0.0))/1024.0/1024.0;

		double FLAT_SeedMB    = ((FLAT_seedIOs+0.0)*(PAGE_SIZE+0.0))/1024.0/1024.0;
		double FLAT_MetadataMB= ((FLAT_metaDataIOs+0.0)*(PAGE_SIZE+0.0))/1024.0/1024.0;
		double FLAT_ResultMB = ((ResultPoints+0.0)*(ObjectSize+0.0))/1024.0/1024.0;
		double FLAT_UselessMB= ((UselessPoints+0.0)*(ObjectSize+0.0))/1024.0/1024.0;
		double FLAT_EmptyMB  = FLAT_TotalMB - (FLAT_SeedMB+FLAT_MetadataMB+FLAT_ResultMB+FLAT_UselessMB);

		double FLAT_IOperResult = (FLAT_TotalIO+0.0)/(ResultPoints+0.0);
		
        std::cout  << "TotalIO" << "\t\t\t" << FLAT_TotalIO << "\n";
        std::cout  << "SeedIO" << "\t\t\t" << FLAT_seedIOs << "\n";
        std::cout  << "MetaDataIO" << "\t\t" << FLAT_metaDataIOs << "\n";
        std::cout  << "PayLoadIO" << "\t\t" << FLAT_payLoadIOs << "\n";
        std::cout  << "Results" << "\t\t\t" << ResultPoints << "\n";
        std::cout  << "Useless" << "\t\t\t" << UselessPoints << "\n";
        std::cout  << "Total MB" << "\t\t" << FLAT_TotalMB << "\n";
        std::cout  << "Seed MB" << "\t\t\t" << FLAT_SeedMB << "\n";
        std::cout  << "Metadata MB" << "\t\t" << FLAT_MetadataMB << "\n";
        std::cout  << "Result MB" << "\t\t" << FLAT_ResultMB << "\n";
        std::cout  << "Useless MB" << "\t\t" << FLAT_UselessMB << "\n";
        std::cout  << "Empty MB" << "\t\t" << FLAT_EmptyMB << "\n";
        std::cout  << "IO per Result" << "\t" << FLAT_IOperResult << "\n";
	}

}
