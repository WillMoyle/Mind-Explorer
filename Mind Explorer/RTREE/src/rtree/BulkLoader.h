// Spatial Index Library
//
// Copyright (C) 2002 Navel Ltd.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//  Email:
//    mhadji@gmail.com

#include "hilbert.hpp"

#pragma once

namespace SpatialIndex
{
	namespace RTree
	{
		class ExternalSorter
		{
		public:
			class Record
			{
			public:
				Record();
				Record(const Region& r, id_type id, uint32_t len, byte* pData, uint32_t s, unsigned long long h);
				Record(const Region& r, id_type id, uint32_t len, byte* pData, uint32_t s);
				~Record();

				bool operator<(const Record& r) const;

				void storeToFile(Tools::TemporaryFile& f);
				void loadFromFile(Tools::TemporaryFile& f);

				struct SortAscending : public std::binary_function<Record* const, Record* const, bool>
				{
					bool operator()(Record* const r1, Record* const r2)
					{
						if (*r1 < *r2) return true;
						else return false;
					}
				};

				struct hilbertAsc : public std::binary_function<Record* const, Record* const, bool>
				{
					bool operator()(Record* const r1, Record* const r2)
					{
						return r1->hilbert_value > r2->hilbert_value;
					}
				};

				struct IDAsc : public std::binary_function<Record* const, Record* const, bool>
				{
					bool operator()(Record* const r1, Record* const r2)
					{
						if(r1->m_id > r2->m_id) return true;
						else return false;
					}
				};

			public:
				Region m_r;
				id_type m_id;
				byte* m_pData;
				uint32_t m_len;
				uint32_t m_s;
				unsigned long long hilbert_value;
			};


			class RecordP
			{
			public:
				Record *rec;
				int idx;

				// make a Leaf node
				RecordP(Record *r, int i) {
					rec = r;
					idx = i;
				}

				~RecordP() {
//					delete rec;
				}
			};

			struct Comparator : public std::binary_function<Record* const, Record* const, bool>
			{
				int sortDimension;
			public:
				Comparator(int sort)
				{
					sortDimension = sort;
				}
				bool operator()(Record* const r1, Record* const r2)
				{
					switch(sortDimension)
					{
					case 0:
						{
						if (r1->m_r.m_pLow[0] < r2->m_r.m_pLow[0]) return true;
						else return false;
						}
						break;
					case 1:
						{
						if (r1->m_r.m_pLow[1] < r2->m_r.m_pLow[1]) return true;
						else return false;
						}
						break;
					case 2:
						{
						if (r1->m_r.m_pLow[2] < r2->m_r.m_pLow[2]) return true;
						else return false;
						}
						break;
					case 3:
						{
						if (r1->m_r.m_pHigh[0] > r2->m_r.m_pHigh[0]) return true;
						else return false;
						}
						break;
					case 4:
						{
						if (r1->m_r.m_pHigh[1] > r2->m_r.m_pHigh[1]) return true;
						else return false;
						}
						break;
					case 5:
						{
						if (r1->m_r.m_pHigh[2] > r2->m_r.m_pHigh[2]) return true;
						else return false;
						}
						break;
					default:
						std::cout << "Error: bad sortDimension: " << sortDimension << std::endl;
						break;
					}
                    return true;
				}
			};


		public:
			ExternalSorter(uint32_t u32PageSize, uint32_t u32BufferPages);
			virtual ~ExternalSorter();

			class PQEntry
			{
			public:
				PQEntry(Record* r, uint32_t u32Index) : m_r(r), m_u32Index(u32Index) {}

				struct PQComparator : public std::binary_function<const PQEntry&, const PQEntry&, bool>
				{
					int sortDimension;
				public:
					PQComparator(int sort)
					{
						sortDimension = sort;
					}
					bool operator()(const PQEntry& r1, const PQEntry& r2)
					{
						switch(sortDimension)
						{
						case 0:
							{
								return (r1.m_r->m_r.m_pLow[0] < r2.m_r->m_r.m_pLow[0]);
							}
							break;
						case 1:
							{
								return (r1.m_r->m_r.m_pLow[1] < r2.m_r->m_r.m_pLow[1]);
							}
							break;
						case 2:
							{
								return (r1.m_r->m_r.m_pLow[2] < r2.m_r->m_r.m_pLow[2]);
							}
							break;
						case 3:
							{
								return (r1.m_r->m_r.m_pHigh[0] > r2.m_r->m_r.m_pHigh[0]);
							}
							break;
						case 4:
							{
								return (r1.m_r->m_r.m_pHigh[1] > r2.m_r->m_r.m_pHigh[1]);
							}
							break;
						case 5:
							{
								return (r1.m_r->m_r.m_pHigh[2] > r2.m_r->m_r.m_pHigh[2]);
							}
							break;
						default:
							std::cout << "Error: bad sortDimension: " << sortDimension << std::endl;
							break;
						}
                        return true;
					}
				};

				struct SortAscending : public std::binary_function<const PQEntry&, const PQEntry&, bool>
				{
					bool operator()(const PQEntry& e1, const PQEntry& e2)
					{
						if (*(e1.m_r) < *(e2.m_r)) return true;
						else return false;
					}
				};

				struct hilbertAsc : public std::binary_function<Record* const, Record* const, bool>
				{
					bool operator()(const PQEntry& e1, const PQEntry& e2)
					{
						return (*(e2.m_r)).hilbert_value > (*(e1.m_r)).hilbert_value;
					}
				};

				struct IDAsc : public std::binary_function<Record* const, Record* const, bool>
				{
					bool operator()(const PQEntry& e1, const PQEntry& e2)
					{
						if(e1.m_r->m_id > e2.m_r->m_id) return true;
						else return false;
					}
				};

				Record* m_r;
				uint32_t m_u32Index;
			};

			void insert(Record* r);
			void pinsert(Record* r, int sortOrder);
			void hinsert(Record* r);
			void iinsert(Record* r);
			void sort();
			void psort(int sortOrder);
			void isort();
			void hsort();
			void finishedInserting();
			void bucketMerge();
			void rewindFile();
			void setupFile();
			void dinsert(Record* r);
			void wrapUp();
			Record* getNextRecord();
			uint64_t getTotalEntries() const;


		private:
			bool m_bInsertionPhase;
			uint32_t m_u32PageSize;
			uint32_t m_u32BufferPages;
			Tools::SmartPointer<Tools::TemporaryFile> m_sortedFile;
			std::list<Tools::SmartPointer<Tools::TemporaryFile> > m_runs;
			std::vector<Record*> m_buffer;
			uint64_t m_u64TotalEntries;
			uint32_t m_stI;
		};

		class BulkLoader
		{
		public:
			void bulkLoadUsingSTR(
				RTree* pTree,
				IDataStream& stream,
				uint32_t bindex,
				uint32_t bleaf,
				uint32_t pageSize, // The number of node entries per page.
				uint32_t numberOfPages // The total number of pages to use.
			);
			void bulkLoadUsingHilbert(
				RTree* pTree,
				IDataStream& stream,
				uint32_t bindex,
				uint32_t bleaf,
				uint32_t pageSize, // The number of node entries per page.
				uint32_t numberOfPages // The total number of pages to use.
			);

			void bulkLoadUsingPR(
				SpatialIndex::RTree::RTree* pTree,
				IDataStream& stream,
				uint32_t bindex,
				uint32_t bleaf,
				uint32_t pageSize,
				uint32_t numberOfPages
			);

		protected:
			void createLevel(
				RTree* pTree,
				Tools::SmartPointer<ExternalSorter> es,
				uint32_t dimension,
				uint32_t indexSize,
				uint32_t leafSize,
				uint32_t level,
				Tools::SmartPointer<ExternalSorter> es2,
				uint32_t pageSize,
				uint32_t numberOfPages
			);

			void createHilbertLevel(
				RTree* pTree,
				Tools::SmartPointer<ExternalSorter> es,
				uint32_t dimension,
				uint32_t indexSize,
				uint32_t leafSize,
				uint32_t level,
				Tools::SmartPointer<ExternalSorter> es2,
				uint32_t pageSize,
				uint32_t numberOfPages
			);

			Node* createNode(
				RTree* pTree,
				std::vector<ExternalSorter::Record*>& e,
				uint32_t level
			);

			void writeNode(
				SpatialIndex::RTree::RTree* pTree,
				std::list<ExternalSorter::RecordP*> objlist,
				ExternalSorter *nextLevel,
				int Level
			);

			void processExtremeNode(
				SpatialIndex::RTree::RTree* pTree,
				ExternalSorter *es,
				ExternalSorter *nextLevel,
				int type,
				int Level,
				bool *deleted
			);

			void makePseudoPRTree(
				SpatialIndex::RTree::RTree* pTree,
				ExternalSorter *es,
				ExternalSorter *es2,
				int sortDimension,
				int Level,
				int pageSize,
				int numberOfPages
			);
		};
	}
}
