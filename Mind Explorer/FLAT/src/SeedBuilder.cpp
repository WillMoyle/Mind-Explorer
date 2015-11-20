#include "SeedBuilder.hpp"
#include "GlobalCommon.hpp"
#include <vector>


namespace FLAT
{
	nodeSkeleton::nodeSkeleton()
	{
		m_pIdentifier=NULL;
		m_ptrMBR=NULL;
		m_pDataLength=NULL;
		m_pData=NULL;
		level=0;
		children=0;
		nodeType=0;
		dataLength=0;
	}

	nodeSkeleton::~nodeSkeleton()
	{
		if (m_ptrMBR!=NULL)
		{
			for (uint32_t i=0;i<this->children;i++)
				if (m_ptrMBR[i]!=NULL)
					delete m_ptrMBR[i];
			delete[] m_ptrMBR;
		}

		if (m_pData != NULL)
		{
			for (uint32_t i=0;i<this->children;i++)
				if (m_pData[i]!=NULL)
					delete[] m_pData[i];
			delete[] m_pData;
		}
		if (m_pDataLength!=NULL)
			delete[] m_pDataLength;
		if (m_pIdentifier!=NULL)
			delete[] m_pIdentifier;
	}

	nodeSkeleton * SeedBuilder::readNode(SpatialIndex::id_type page,
			SpatialIndex::IStorageManager* m_pStorageManager)
	{
		byte* buffer;
		byte* ptr;

		ptr = buffer;
		nodeSkeleton * ns = new nodeSkeleton();

		try
		{
			m_pStorageManager->loadByteArray(page, ns->dataLength, &buffer);
		}
		catch (SpatialIndex::InvalidPageException& e)
		{
			std::cerr << e.what() << std::endl;
			throw;
		}

		int c = 0;

		try
		{
			memcpy(&ns->nodeType, buffer, sizeof(uint32_t));
			if (ns->nodeType != SpatialIndex::RTree::PersistentLeaf && ns->nodeType != SpatialIndex::RTree::PersistentIndex)
			{
				delete[] buffer;
				delete ns;
				return NULL;
			}

			// skip the node type information, it is not needed.
			c += sizeof(uint32_t);

			memcpy(&ns->level, buffer + c, sizeof(uint32_t));
			c += sizeof(uint32_t);

			memcpy(&ns->children, buffer + c, sizeof(uint32_t));
			c += sizeof(uint32_t);

			// Why +1???
			int count = ns->children;
			ns->m_ptrMBR = new SpatialIndex::Region*[count];
			for (int i=0;i<count;i++) ns->m_ptrMBR[i]=NULL;
			ns->m_pIdentifier = new SpatialIndex::id_type[count];
			ns->m_pDataLength = new uint32_t[count];
			ns->m_pData = new byte*[count];
			for (int i=0;i<count;i++) ns->m_pData[i]=NULL;

			for (uint32_t u32Child = 0; u32Child < ns->children; ++u32Child)
			{
				//cout << u32Child << "> ";
				ns->m_ptrMBR[u32Child] = new SpatialIndex::Region();
				ns->m_ptrMBR[u32Child]->m_pLow = new double[3];
				ns->m_ptrMBR[u32Child]->m_pHigh = new double[3];
				memcpy(ns->m_ptrMBR[u32Child]->m_pLow, buffer + c, DIMENSION * sizeof(double));
				c += DIMENSION * sizeof(double);
				memcpy(ns->m_ptrMBR[u32Child]->m_pHigh, buffer + c, DIMENSION * sizeof(double));
				c += DIMENSION * sizeof(double);
				memcpy(&(ns->m_pIdentifier[u32Child]), buffer + c, sizeof(SpatialIndex::id_type));
				c += sizeof(SpatialIndex::id_type);

				memcpy(&(ns->m_pDataLength[u32Child]), buffer + c, sizeof(uint32_t));
				c += sizeof(uint32_t);

				if (ns->m_pDataLength[u32Child] > 0)
				{
					ns->m_pData[u32Child] = new byte[ns->m_pDataLength[u32Child]];
					memcpy(ns->m_pData[u32Child], buffer + c, ns->m_pDataLength[u32Child]);
					c += ns->m_pDataLength[u32Child];
				}
				else
				{
					ns->m_pData[u32Child] = NULL;
				}
			}

			ns->m_nodeMBR.m_pLow = new double[3];
			ns->m_nodeMBR.m_pHigh = new double[3];
			memcpy(ns->m_nodeMBR.m_pLow, buffer + c, DIMENSION * sizeof(double));
			c += DIMENSION * sizeof(double);
			memcpy(ns->m_nodeMBR.m_pHigh, buffer + c, DIMENSION * sizeof(double));

			delete[] buffer;
		}
		catch (...)
		{
			delete[] buffer;
			throw;
		}
		return ns;
	}
}
