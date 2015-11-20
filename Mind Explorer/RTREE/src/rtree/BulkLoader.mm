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

#include <cstring>
#include <stdio.h>
#include <cmath>
#include <algorithm>
#include <set>

#include <time.h>

#ifndef _MSC_VER
#include <unistd.h>
#endif

#include "../spatialindex/SpatialIndexImpl.h"
#include "RTree.h"
#include "Leaf.h"
#include "Index.h"
#include "BulkLoader.h"


#define PAGE_SIZE 4096 // 4096
#define OBJECT_SIZE 48
#define NODE_FANOUT PAGE_SIZE/(OBJECT_SIZE+8)
#define LEAF_FANOUT PAGE_SIZE/OBJECT_SIZE

using namespace SpatialIndex::RTree;

//
// ExternalSorter::Record
//
ExternalSorter::Record::Record()
: m_pData(0)
{
}

ExternalSorter::Record::Record(const Region& r, id_type id, uint32_t len, byte* pData, uint32_t s)
: m_r(r), m_id(id), m_len(len), m_pData(pData), m_s(s)
{
}

ExternalSorter::Record::Record(const Region& r, id_type id, uint32_t len, byte* pData, uint32_t s, unsigned long long h)
: m_r(r), m_id(id), m_len(len), m_pData(pData), m_s(s), hilbert_value(h)
{
}

ExternalSorter::Record::~Record()
{
	//if(m_len > 0)
		delete[] m_pData;
}

bool ExternalSorter::Record::operator<(const Record& r) const
{
	if (m_s != r.m_s)
		throw Tools::IllegalStateException("ExternalSorter::Record::operator<: Incompatible sorting dimensions.");

	if (m_r.m_pHigh[m_s] + m_r.m_pLow[m_s] < r.m_r.m_pHigh[m_s] + r.m_r.m_pLow[m_s])
		return true;
	else
		return false;
}

void ExternalSorter::Record::storeToFile(Tools::TemporaryFile& f)
{
	f.write(static_cast<uint64_t>(m_id));
	f.write(m_r.m_dimension);
	f.write(m_s);
	f.write((uint64_t)hilbert_value);

	for (uint32_t i = 0; i < m_r.m_dimension; ++i)
	{
		f.write(m_r.m_pLow[i]);
		f.write(m_r.m_pHigh[i]);
	}

	f.write(m_len);
	if (m_len > 0) f.write(m_len, m_pData);
}

void ExternalSorter::Record::loadFromFile(Tools::TemporaryFile& f)
{
	m_id = static_cast<id_type>(f.readUInt64());
	uint32_t dim = f.readUInt32();
	m_s = f.readUInt32();
	hilbert_value = f.readUInt64();

	if (dim != m_r.m_dimension)
	{
		delete[] m_r.m_pLow;
		delete[] m_r.m_pHigh;
		m_r.m_dimension = dim;
		m_r.m_pLow = new double[dim];
		m_r.m_pHigh = new double[dim];
	}

	for (uint32_t i = 0; i < m_r.m_dimension; ++i)
	{
		m_r.m_pLow[i] = f.readDouble();
		m_r.m_pHigh[i] = f.readDouble();
	}

	m_len = f.readUInt32();
	delete[] m_pData; m_pData = 0;
	if (m_len > 0) f.readBytes(m_len, &m_pData);
}

//
// ExternalSorter
//
ExternalSorter::ExternalSorter(uint32_t u32PageSize, uint32_t u32BufferPages)
: m_bInsertionPhase(true), m_u32PageSize(u32PageSize),
  m_u32BufferPages(u32BufferPages), m_u64TotalEntries(0), m_stI(0)
{
}

ExternalSorter::~ExternalSorter()
{
	for (m_stI = 0; m_stI < m_buffer.size(); ++m_stI) delete m_buffer[m_stI];
}

void ExternalSorter::iinsert(Record* r)
{
	if (m_bInsertionPhase == false)
		throw Tools::IllegalStateException("ExternalSorter::insert: Input has already been sorted.");

	m_buffer.push_back(r);
	++m_u64TotalEntries;

	// this will create the initial, sorted buckets before the
	// external merge sort.
	if (m_buffer.size() >= m_u32PageSize * m_u32BufferPages)
	{
		std::sort(m_buffer.begin(), m_buffer.end(), Record::IDAsc());
		Tools::TemporaryFile* tf = new Tools::TemporaryFile();
		for (size_t j = 0; j < m_buffer.size(); ++j)
		{
			m_buffer[j]->storeToFile(*tf);
			delete m_buffer[j];
		}
		m_buffer.clear();
		tf->rewindForReading();
		m_runs.push_back(Tools::SmartPointer<Tools::TemporaryFile>(tf));
	}
}

void ExternalSorter::hinsert(Record* r)
{
	if (m_bInsertionPhase == false)
		throw Tools::IllegalStateException("ExternalSorter::insert: Input has already been sorted.");

	m_buffer.push_back(r);
	++m_u64TotalEntries;

	// this will create the initial, sorted buckets before the
	// external merge sort.
	if (m_buffer.size() >= m_u32PageSize * m_u32BufferPages)
	{
		std::sort(m_buffer.begin(), m_buffer.end(), Record::hilbertAsc());
		Tools::TemporaryFile* tf = new Tools::TemporaryFile();
		for (size_t j = 0; j <= m_buffer.size(); ++j)
		{
			m_buffer[j]->storeToFile(*tf);
		}
		m_buffer.clear();
		tf->rewindForReading();
		m_runs.push_back(Tools::SmartPointer<Tools::TemporaryFile>(tf));
	}

	m_bInsertionPhase = true;
}

void ExternalSorter::insert(Record* r)
{
	if (m_bInsertionPhase == false)
		throw Tools::IllegalStateException("ExternalSorter::insert: Input has already been sorted.");

	m_buffer.push_back(r);
	++m_u64TotalEntries;

	// this will create the initial, sorted buckets before the
	// external merge sort.
	if (m_buffer.size() >= m_u32PageSize * m_u32BufferPages)
	{
		std::sort(m_buffer.begin(), m_buffer.end(), Record::SortAscending());
		Tools::TemporaryFile* tf = new Tools::TemporaryFile();
		for (size_t j = 0; j < m_buffer.size(); ++j)
		{
			m_buffer[j]->storeToFile(*tf);
			delete m_buffer[j];
		}
		m_buffer.clear();
		tf->rewindForReading();
		m_runs.push_back(Tools::SmartPointer<Tools::TemporaryFile>(tf));
	}
}

void ExternalSorter::pinsert(Record* r, int sortOrder)
{
	if (m_bInsertionPhase == false)
		throw Tools::IllegalStateException("ExternalSorter::insert: Input has already been sorted.");

	m_buffer.push_back(r);
	++m_u64TotalEntries;

	// this will create the initial, sorted buckets before the
	// external merge sort.
	if (m_buffer.size() > m_u32PageSize * m_u32BufferPages)
	{
		std::sort(m_buffer.begin(), m_buffer.end(), Comparator(sortOrder));
		Tools::TemporaryFile* tf = new Tools::TemporaryFile();
		for (size_t j = 0; j <= m_buffer.size(); ++j)
		{
			m_buffer[j]->storeToFile(*tf);
		}
		m_buffer.clear();
		tf->rewindForReading();
		m_runs.push_back(Tools::SmartPointer<Tools::TemporaryFile>(tf));
	}
}
void ExternalSorter::sort()
{
	if (m_bInsertionPhase == false)
		throw Tools::IllegalStateException("ExternalSorter::sort: Input has already been sorted.");

	if (m_runs.empty())
	{
		// The data fits in main memory. No need to store to disk.
		std::sort(m_buffer.begin(), m_buffer.end(), Record::SortAscending());
		m_bInsertionPhase = false;
		return;
	}

	if (m_buffer.size() > 0)
	{
		// Whatever remained in the buffer (if not filled) needs to be stored
		// as the final bucket.
		std::sort(m_buffer.begin(), m_buffer.end(), Record::SortAscending());
		Tools::TemporaryFile* tf = new Tools::TemporaryFile();
		for (size_t j = 0; j < m_buffer.size(); ++j)
		{
			m_buffer[j]->storeToFile(*tf);
			delete m_buffer[j];
		}
		m_buffer.clear();
		tf->rewindForReading();
		m_runs.push_back(Tools::SmartPointer<Tools::TemporaryFile>(tf));
	}

	if (m_runs.size() == 1)
	{
		m_sortedFile = m_runs.front();
	}
	else
	{
		Record* r = NULL;

		while (m_runs.size() > 1)
		{
			Tools::SmartPointer<Tools::TemporaryFile> tf(new Tools::TemporaryFile());
			std::vector<Tools::SmartPointer<Tools::TemporaryFile> > buckets;
			std::vector<std::queue<Record*> > buffers;
			std::priority_queue<PQEntry, std::vector<PQEntry>, PQEntry::SortAscending> pq;

			// initialize buffers and priority queue.
			std::list<Tools::SmartPointer<Tools::TemporaryFile> >::iterator it = m_runs.begin();
			for (uint32_t i = 0; i < (std::min)(static_cast<uint32_t>(m_runs.size()), m_u32BufferPages); ++i)
			{
				buckets.push_back(*it);
				buffers.push_back(std::queue<Record*>());

				r = new Record();
				r->loadFromFile(**it);
					// a run cannot be empty initially, so this should never fail.
				pq.push(PQEntry(r, i));

				for (uint32_t j = 0; j < m_u32PageSize - 1; ++j)
				{
					// fill the buffer with the rest of the page of records.
					try
					{
						r = new Record();
						r->loadFromFile(**it);
						buffers.back().push(r);
					}
					catch (Tools::EndOfStreamException)
					{
						delete r;
						break;
					}
				}
				++it;
			}

			// exhaust buckets, buffers, and priority queue.
			while (! pq.empty())
			{
				PQEntry e = pq.top(); pq.pop();
				e.m_r->storeToFile(*tf);
				delete e.m_r;

				if (! buckets[e.m_u32Index]->eof() && buffers[e.m_u32Index].empty())
				{
					for (uint32_t j = 0; j < m_u32PageSize; ++j)
					{
						try
						{
							r = new Record();
							r->loadFromFile(*buckets[e.m_u32Index]);
							buffers[e.m_u32Index].push(r);
						}
						catch (Tools::EndOfStreamException)
						{
							delete r;
							break;
						}
					}
				}

				if (! buffers[e.m_u32Index].empty())
				{
					e.m_r = buffers[e.m_u32Index].front();
					buffers[e.m_u32Index].pop();
					pq.push(e);
				}
			}

			tf->rewindForReading();

			// check if another pass is needed.
			uint32_t u32Count = std::min(static_cast<uint32_t>(m_runs.size()), m_u32BufferPages);
			for (uint32_t i = 0; i < u32Count; ++i)
			{
				m_runs.pop_front();
			}

			if (m_runs.size() == 0)
			{
				m_sortedFile = tf;
				break;
			}
			else
			{
				m_runs.push_back(tf);
			}
		}
	}

	m_bInsertionPhase = false;
}

void ExternalSorter::bucketMerge()
{
	//basically merge all temporary files without sorting
	if (m_bInsertionPhase == false)
		throw Tools::IllegalStateException("ExternalSorter::sort: Input has already been sorted.");

	if (m_buffer.size() > 0)
	{
		// Whatever remained in the buffer (if not filled) needs to be stored
		// as the final bucket.
		Tools::TemporaryFile* tf = new Tools::TemporaryFile();
		for (size_t j = 0; j < m_buffer.size(); ++j)
		{
			m_buffer[j]->storeToFile(*tf);
			delete m_buffer[j];
		}
		m_buffer.clear();
		tf->rewindForReading();
		m_runs.push_back(Tools::SmartPointer<Tools::TemporaryFile>(tf));
	}

	if (m_runs.size() >= 1)
	{
		m_sortedFile = m_runs.front();
	}
	else
	{
		Record* r = NULL;

		//I am taking a couple of shortcuts here
		Tools::SmartPointer<Tools::TemporaryFile> tf(new Tools::TemporaryFile());

		// initialize buffers and priority queue.
		std::list<Tools::SmartPointer<Tools::TemporaryFile> >::iterator it = m_runs.begin();
		for (uint32_t i = 0; i < (std::min)(static_cast<uint32_t>(m_runs.size()), m_u32BufferPages); ++i)
		{
			r = new Record();
			r->loadFromFile(**it);

			r->storeToFile(*tf);

			++it;
		}

		tf->rewindForReading();

		m_sortedFile = tf;
	}

	m_bInsertionPhase = false;
}

/*
 * the following three methods are used to directly insert elements in the "sorted" file. avoids buffering & sorting the content. can only be used if input does not need to be sorted
 */
void ExternalSorter::setupFile() {
	Tools::SmartPointer<Tools::TemporaryFile> tf(new Tools::TemporaryFile());
	m_sortedFile = tf;
}

void ExternalSorter::dinsert(Record* r)
{
	++m_u64TotalEntries;
	r->storeToFile(*m_sortedFile);
	delete r;
}

void ExternalSorter::wrapUp() {
	m_bInsertionPhase = false;
	m_sortedFile->rewindForReading();
}


void ExternalSorter::psort(int sortOrder)
{
	if (m_bInsertionPhase == false)
		throw Tools::IllegalStateException("ExternalSorter::sort: Input has already been sorted.");

	if (m_runs.empty())
	{
		// The data fits in main memory. No need to store to disk.
		std::sort(m_buffer.begin(), m_buffer.end(), Comparator(sortOrder));
		m_bInsertionPhase = false;
		return;
	}

	if (m_buffer.size() > 0)
	{
		// Whatever remained in the buffer (if not filled) needs to be stored
		// as the final bucket.
		std::sort(m_buffer.begin(), m_buffer.end(), Comparator(sortOrder));
		Tools::TemporaryFile* tf = new Tools::TemporaryFile();

		for (size_t j = 0; j < m_buffer.size(); ++j)
		{
			m_buffer[j]->storeToFile(*tf);
			delete m_buffer[j];
		}
		m_buffer.clear();
		tf->rewindForReading();
		m_runs.push_back(Tools::SmartPointer<Tools::TemporaryFile>(tf));
	}

	if (m_runs.size() == 1)
	{
		m_sortedFile = m_runs.front();
	}
	else
	{
		Record* r = NULL;

		while (m_runs.size() > 1)
		{
			Tools::SmartPointer<Tools::TemporaryFile> tf(new Tools::TemporaryFile());

			std::vector<Tools::SmartPointer<Tools::TemporaryFile> > buckets;
			std::vector<std::queue<Record*> > buffers;
			//std::priority_queue<PQEntry, std::vector<PQEntry>, PQEntry::SortAscending> pq;
			std::vector<PQEntry> pq;

			// initialize buffers and priority queue.
			std::list<Tools::SmartPointer<Tools::TemporaryFile> >::iterator it = m_runs.begin();
			for (uint32_t i = 0; i < (std::min)(static_cast<uint32_t>(m_runs.size()), m_u32BufferPages); ++i)
			{
				buckets.push_back(*it);
				buffers.push_back(std::queue<Record*>());

				r = new Record();
				r->loadFromFile(**it);
					// a run cannot be empty initially, so this should never fail.
				pq.push_back(PQEntry(r, i));

				for (uint32_t j = 0; j < m_u32PageSize - 1; ++j)
				{
					// fill the buffer with the rest of the page of records.
					try
					{
						r = new Record();
						r->loadFromFile(**it);
						buffers.back().push(r);
					}
					catch (Tools::EndOfStreamException)
					{
						delete r;
						break;
					}
				}
				++it;
			}

			std::sort(pq.begin(), pq.end(), PQEntry::PQComparator(sortOrder));

			// exhaust buckets, buffers, and priority queue.
			while (! pq.empty())
			{
				PQEntry e = pq.front(); pq.erase(pq.begin());
				e.m_r->storeToFile(*tf);
				delete e.m_r;

				if (! buckets[e.m_u32Index]->eof() && buffers[e.m_u32Index].empty())
				{
					for (uint32_t j = 0; j < m_u32PageSize; ++j)
					{
						try
						{
							r = new Record();
							r->loadFromFile(*buckets[e.m_u32Index]);
							buffers[e.m_u32Index].push(r);
						}
						catch (Tools::EndOfStreamException)
						{
							delete r;
							break;
						}
					}
				}

				if (! buffers[e.m_u32Index].empty())
				{
					e.m_r = buffers[e.m_u32Index].front();
					buffers[e.m_u32Index].pop();
					pq.push_back(e);
				}

				std::sort(pq.begin(), pq.end(), PQEntry::PQComparator(sortOrder));
			}

			tf->rewindForReading();

			// check if another pass is needed.
			uint32_t u32Count = std::min(static_cast<uint32_t>(m_runs.size()), m_u32BufferPages);
			for (uint32_t i = 0; i < u32Count; ++i)
			{
				m_runs.pop_front();
			}

			if (m_runs.size() == 0)
			{
				m_sortedFile = tf;
				break;
			}
			else
			{
				m_runs.push_back(tf);
			}
		}
	}
}


void ExternalSorter::hsort()
{
	if (m_bInsertionPhase == false)
		throw Tools::IllegalStateException("ExternalSorter::sort: Input has already been sorted.");

	if (m_runs.empty())
	{
		// The data fits in main memory. No need to store to disk.
		std::sort(m_buffer.begin(), m_buffer.end(), Record::hilbertAsc());
		m_bInsertionPhase = false;
		return;
	}

	if (m_buffer.size() > 0)
	{
		// Whatever remained in the buffer (if not filled) needs to be stored
		// as the final bucket.
		std::sort(m_buffer.begin(), m_buffer.end(), Record::hilbertAsc());
		Tools::TemporaryFile* tf = new Tools::TemporaryFile();
		for (size_t j = 0; j <= m_buffer.size(); ++j)
		{
			m_buffer[j]->storeToFile(*tf);
			delete m_buffer[j];
		}
		m_buffer.clear();
		tf->rewindForReading();
		m_runs.push_back(Tools::SmartPointer<Tools::TemporaryFile>(tf));
	}

	if (m_runs.size() == 1)
	{
		m_sortedFile = m_runs.front();
	}
	else
	{
		Record* r = NULL;

		while (m_runs.size() > 0)
		{
			Tools::SmartPointer<Tools::TemporaryFile> tf(new Tools::TemporaryFile());
			std::vector<Tools::SmartPointer<Tools::TemporaryFile> > buckets;
			std::vector<std::queue<Record*> > buffers;
			std::priority_queue<PQEntry, std::vector<PQEntry>, PQEntry::hilbertAsc> pq;

			// initialize buffers and priority queue.
			std::list<Tools::SmartPointer<Tools::TemporaryFile> >::iterator it = m_runs.begin();
			for (uint32_t i = 0; i < (std::min)(static_cast<uint32_t>(m_runs.size()), m_u32BufferPages); ++i)
			{
				buckets.push_back(*it);
				buffers.push_back(std::queue<Record*>());

				r = new Record();
				r->loadFromFile(**it);
					// a run cannot be empty initially, so this should never fail.
				pq.push(PQEntry(r, i));

				for (uint32_t j = 0; j <= m_u32PageSize - 1; ++j)
				{
					// fill the buffer with the rest of the page of records.
					try
					{
						r = new Record();
						r->loadFromFile(**it);
						buffers.back().push(r);
					}
					catch (Tools::EndOfStreamException)
					{
						delete r;
						break;
					}
				}
				++it;
			}

			// exhaust buckets, buffers, and priority queue.
			while (! pq.empty())
			{
				PQEntry e = pq.top(); pq.pop();
				e.m_r->storeToFile(*tf);
				delete e.m_r;

				if (! buckets[e.m_u32Index]->eof() && buffers[e.m_u32Index].empty())
				{
					for (uint32_t j = 0; j < m_u32PageSize; ++j)
					{
						try
						{
							r = new Record();
							r->loadFromFile(*buckets[e.m_u32Index]);
							buffers[e.m_u32Index].push(r);
						}
						catch (Tools::EndOfStreamException)
						{
							delete r;
							break;
						}
					}
				}

				if (! buffers[e.m_u32Index].empty())
				{
					e.m_r = buffers[e.m_u32Index].front();
					buffers[e.m_u32Index].pop();
					pq.push(e);
				}
			}

			tf->rewindForReading();

			// check if another pass is needed.
			uint32_t u32Count = std::min(static_cast<uint32_t>(m_runs.size()), m_u32BufferPages);
			for (uint32_t i = 0; i < u32Count; ++i)
			{
				m_runs.pop_front();
			}

			if (m_runs.size() == 0)
			{
				m_sortedFile = tf;
				break;
			}
			else
			{
				m_runs.push_back(tf);
			}
		}
	}

}

void ExternalSorter::isort()
{
	if (m_bInsertionPhase == false)
		throw Tools::IllegalStateException("ExternalSorter::sort: Input has already been sorted.");

	if (m_runs.empty())
	{
		// The data fits in main memory. No need to store to disk.
		std::sort(m_buffer.begin(), m_buffer.end(), Record::IDAsc());
		m_bInsertionPhase = false;
		return;
	}

	if (m_buffer.size() > 0)
	{
		// Whatever remained in the buffer (if not filled) needs to be stored
		// as the final bucket.
		std::sort(m_buffer.begin(), m_buffer.end(), Record::IDAsc());
		Tools::TemporaryFile* tf = new Tools::TemporaryFile();
		for (size_t j = 0; j < m_buffer.size(); ++j)
		{
			m_buffer[j]->storeToFile(*tf);
			delete m_buffer[j];
		}
		m_buffer.clear();
		tf->rewindForReading();
		m_runs.push_back(Tools::SmartPointer<Tools::TemporaryFile>(tf));
	}

	if (m_runs.size() == 1)
	{
		m_sortedFile = m_runs.front();
	}
	else
	{
		Record* r = NULL;

		while (m_runs.size() > 1)
		{
			Tools::SmartPointer<Tools::TemporaryFile> tf(new Tools::TemporaryFile());
			std::vector<Tools::SmartPointer<Tools::TemporaryFile> > buckets;
			std::vector<std::queue<Record*> > buffers;
			std::priority_queue<PQEntry, std::vector<PQEntry>, PQEntry::IDAsc> pq;

			// initialize buffers and priority queue.
			std::list<Tools::SmartPointer<Tools::TemporaryFile> >::iterator it = m_runs.begin();
			for (uint32_t i = 0; i < (std::min)(static_cast<uint32_t>(m_runs.size()), m_u32BufferPages); ++i)
			{
				buckets.push_back(*it);
				buffers.push_back(std::queue<Record*>());

				r = new Record();
				r->loadFromFile(**it);
					// a run cannot be empty initially, so this should never fail.
				pq.push(PQEntry(r, i));

				for (uint32_t j = 0; j < m_u32PageSize - 1; ++j)
				{
					// fill the buffer with the rest of the page of records.
					try
					{
						r = new Record();
						r->loadFromFile(**it);
						buffers.back().push(r);
					}
					catch (Tools::EndOfStreamException)
					{
						delete r;
						break;
					}
				}
				++it;
			}

			// exhaust buckets, buffers, and priority queue.
			while (! pq.empty())
			{
				PQEntry e = pq.top(); pq.pop();
				e.m_r->storeToFile(*tf);
				delete e.m_r;

				if (! buckets[e.m_u32Index]->eof() && buffers[e.m_u32Index].empty())
				{
					for (uint32_t j = 0; j < m_u32PageSize; ++j)
					{
						try
						{
							r = new Record();
							r->loadFromFile(*buckets[e.m_u32Index]);
							buffers[e.m_u32Index].push(r);
						}
						catch (Tools::EndOfStreamException)
						{
							delete r;
							break;
						}
					}
				}

				if (! buffers[e.m_u32Index].empty())
				{
					e.m_r = buffers[e.m_u32Index].front();
					buffers[e.m_u32Index].pop();
					pq.push(e);
				}
			}

			tf->rewindForReading();

			// check if another pass is needed.
			uint32_t u32Count = std::min(static_cast<uint32_t>(m_runs.size()), m_u32BufferPages);
			for (uint32_t i = 0; i < u32Count; ++i)
			{
				m_runs.pop_front();
			}

			if (m_runs.size() == 0)
			{
				m_sortedFile = tf;
				break;
			}
			else
			{
				m_runs.push_back(tf);
			}
		}
	}


}

void ExternalSorter::finishedInserting() {
	m_bInsertionPhase = false;
}

void ExternalSorter::rewindFile() {
	m_sortedFile->rewindForReading();
}


ExternalSorter::Record* ExternalSorter::getNextRecord()
{
	if (m_bInsertionPhase == true)
		throw Tools::IllegalStateException("ExternalSorter::getNextRecord: Input has not been sorted yet.");

	Record* ret;

	if (m_sortedFile.get() == 0)
	{
		if (m_stI < m_buffer.size())
		{
			ret = m_buffer[m_stI];
			m_buffer[m_stI] = 0;
			++m_stI;
		}
		else
			throw Tools::EndOfStreamException("");
	}
	else
	{
		ret = new Record();
		ret->loadFromFile(*m_sortedFile);
	}

	return ret;
}

inline uint64_t ExternalSorter::getTotalEntries() const
{
	return m_u64TotalEntries;
}

void BulkLoader::writeNode(SpatialIndex::RTree::RTree* pTree, std::list<ExternalSorter::RecordP*> objlist, ExternalSorter *nextLevel, int Level)
{
	std::vector<ExternalSorter::Record*> node;

	for (std::list<ExternalSorter::RecordP*>::iterator it = objlist.begin(); it != objlist.end(); it++) {
		node.push_back((*it)->rec);
	}

	Node* n = createNode(pTree, node, Level);
	pTree->writeNode(n);
	//maybe this should be pinsert sorted on 0
	nextLevel->dinsert(new ExternalSorter::Record(n->m_nodeMBR, n->m_identifier, 0, 0, 0));
	pTree->m_rootID = n->m_identifier;

	node.clear();

	delete n;
}

void BulkLoader::processExtremeNode(SpatialIndex::RTree::RTree* pTree, ExternalSorter *es, ExternalSorter *nextLevel, int sortOrder, int Level, bool *deleted)
{
	if (es->getTotalEntries() == 0) return;
	unsigned int nodeSize;
	if (Level==0) nodeSize = pTree->m_leafCapacity;
	else nodeSize = pTree->m_indexCapacity;
	ExternalSorter::Comparator functor(sortOrder);
	std::list<ExternalSorter::RecordP*> entries;

	ExternalSorter::Record* r;

	int c = 0;

	for(unsigned int idx=0; idx<es->getTotalEntries(); idx++) {
		if (!deleted[idx])c++;
	}

	if(c == 0) return;

	for(unsigned int idx=0; idx<es->getTotalEntries(); idx++) {

		r = es->getNextRecord();

		if(deleted[idx]) {
			delete r;
			continue;
		}

		std::list<ExternalSorter::RecordP*>::iterator nd=entries.begin();
		for (;nd!=entries.end();++nd) {
			if ( functor(r, ((*nd)->rec)) ) {
				ExternalSorter::RecordP *rp = new ExternalSorter::RecordP(new ExternalSorter::Record(r->m_r, r->m_id, r->m_len, r->m_pData, 0), idx);
				entries.insert(nd, rp);
				deleted[idx] = true;
				break;
			}
		}

		if (entries.size()<nodeSize && nd==entries.end()) {
			ExternalSorter::RecordP *rp = new ExternalSorter::RecordP(new ExternalSorter::Record(r->m_r, r->m_id, r->m_len, r->m_pData, 0), idx);
			entries.insert(nd, rp);
			deleted[idx] = true;
		}

		if (entries.size()>nodeSize) {
			std::list<ExternalSorter::RecordP*>::iterator aa =entries.end();
			aa--;
			deleted[(*aa)->idx] = false;
			delete (*aa)->rec;
			delete (*aa);
			entries.erase(aa);
		}
	}

	writeNode(pTree, entries, nextLevel, Level);

	entries.clear();

	es->rewindFile();
}

void BulkLoader::makePseudoPRTree(SpatialIndex::RTree::RTree* pTree, ExternalSorter *es, ExternalSorter *es2, int sortDimension, int Level, int pageSize, int numberOfPages) {

	bool * deleted = new bool[es->getTotalEntries()];

	for(unsigned int i=0; i<es->getTotalEntries(); i++) {
		deleted[i] = false;
	}

	// identify extreme(priority) nodes, write them in prtree and remove from input
	for (int a = 0; a < 6; a++) {
		processExtremeNode(pTree, es, es2, a, Level, deleted);
	}

	if (es->getTotalEntries() > 0) {
		// sort remaining elements on sort dimension
		ExternalSorter *eso = new ExternalSorter(pageSize, numberOfPages);

		ExternalSorter::Record* r;

		for(unsigned int idx=0; idx<es->getTotalEntries(); idx++) {

			r = es->getNextRecord();

			if (!deleted[idx]) {
				eso->pinsert(new ExternalSorter::Record(r->m_r, r->m_id, r->m_len, r->m_pData, 0), sortDimension);
			}

			delete r;
		}

		delete[] deleted;

		eso->psort(sortDimension);

		ExternalSorter *li = new ExternalSorter(pageSize, numberOfPages);
		ExternalSorter *ri = new ExternalSorter(pageSize, numberOfPages);

		li->setupFile();
		ri->setupFile();

		// find median and break input list into leftList (li) , rightList (ri)
		for(unsigned int i=0; i<eso->getTotalEntries()/2; i++) {
			r = eso->getNextRecord();
			li->dinsert(new ExternalSorter::Record(r->m_r, r->m_id, r->m_len, r->m_pData, 0));
			delete r;
		}

		for (unsigned int i = uint32_t(eso->getTotalEntries()) / 2; i < eso->getTotalEntries(); i++) {
			r = eso->getNextRecord();
			ri->dinsert(new ExternalSorter::Record(r->m_r, r->m_id, r->m_len, r->m_pData, 0));
			delete r;
		}

		li->wrapUp();
		ri->wrapUp();

		delete eso;

		//recursive calls
		makePseudoPRTree(pTree, li, es2, (sortDimension + 1) % 6, Level, pageSize, numberOfPages);
		makePseudoPRTree(pTree, ri, es2, (sortDimension + 1) % 6, Level, pageSize, numberOfPages);

		delete li;
		delete ri;
	} else {
		delete[] deleted;
	}
}

//
// BulkLoader
//
void BulkLoader::bulkLoadUsingPR(
	SpatialIndex::RTree::RTree* pTree,
	IDataStream& stream,
	uint32_t bindex,
	uint32_t bleaf,
	uint32_t pageSize,
	uint32_t numberOfPages
) {
	if (! stream.hasNext())
		throw Tools::IllegalArgumentException(
			"RTree::BulkLoader::bulkLoadUsingSTR: Empty data stream given."
		);

	NodePtr n = pTree->readNode(pTree->m_rootID);
	pTree->deleteNode(n.get());

	#ifndef NDEBUG
	std::cerr << "RTree::BulkLoader: Sorting data." << std::endl;
	#endif

//	ExternalSorter *es = new ExternalSorter
//
//
	ExternalSorter *es = new ExternalSorter(pageSize, numberOfPages);

	es->setupFile();

	while (stream.hasNext())
	{
		Data* d = reinterpret_cast<Data*>(stream.getNext());
		if (d == 0)
			throw Tools::IllegalArgumentException(
				"bulkLoadUsingSTR: RTree bulk load expects SpatialIndex::RTree::Data entries."
			);

		es->dinsert(new ExternalSorter::Record(d->m_region, d->m_id, d->m_dataLength, d->m_pData, 0));
		d->m_pData = 0;
		delete d;
	}

	es->wrapUp();

	uint32_t level = 0;

	while(es->getTotalEntries() > 1) {
		//don't think this is necessary
		//es->sort();
//		std::cout << level << std::endl;

		pTree->m_stats.m_nodesInLevel.push_back(0);

		ExternalSorter *es2 = new ExternalSorter(pageSize, numberOfPages);
		es2->setupFile();
		makePseudoPRTree(pTree, es, es2, 0, level++, pageSize, numberOfPages);
		es2->wrapUp();
		delete es;
		es = es2;
	}

	delete es;

	pTree->m_stats.m_u32TreeHeight = level;
	pTree->storeHeader();
}

//
// BulkLoader
//
void BulkLoader::bulkLoadUsingSTR(
	SpatialIndex::RTree::RTree* pTree,
	IDataStream& stream,
	uint32_t bindex,
	uint32_t bleaf,
	uint32_t pageSize,
	uint32_t numberOfPages
) {
	if (! stream.hasNext())
		throw Tools::IllegalArgumentException(
			"RTree::BulkLoader::bulkLoadUsingSTR: Empty data stream given."
		);

	NodePtr n = pTree->readNode(pTree->m_rootID);
	pTree->deleteNode(n.get());

	#ifndef NDEBUG
	std::cerr << "RTree::BulkLoader: Sorting data." << std::endl;
	#endif

	Tools::SmartPointer<ExternalSorter> es = Tools::SmartPointer<ExternalSorter>(new ExternalSorter(pageSize, numberOfPages));

	while (stream.hasNext())
	{
		Data* d = reinterpret_cast<Data*>(stream.getNext());
		if (d == 0)
			throw Tools::IllegalArgumentException(
				"bulkLoadUsingSTR: RTree bulk load expects SpatialIndex::RTree::Data entries."
			);

		es->insert(new ExternalSorter::Record(d->m_region, d->m_id, d->m_dataLength, d->m_pData, 0));
		d->m_pData = 0;
		delete d;
	}
	es->sort();
	
	pTree->m_stats.m_u64Data = es->getTotalEntries();

	// create index levels.
	uint32_t level = 0;

	while (true)
	{
		#ifndef NDEBUG
		std::cerr << "RTree::BulkLoader: Building level " << level << std::endl;
		#endif

		pTree->m_stats.m_nodesInLevel.push_back(0);

		Tools::SmartPointer<ExternalSorter> es2 = Tools::SmartPointer<ExternalSorter>(new ExternalSorter(pageSize, numberOfPages));
		createLevel(pTree, es, 0, bleaf, bindex, level++, es2, pageSize, numberOfPages);
		es = es2;

		if (es->getTotalEntries() == 1) break;
		es->sort();
	}

	pTree->m_stats.m_u32TreeHeight = level;
	pTree->storeHeader();
}

void BulkLoader::bulkLoadUsingHilbert(
	SpatialIndex::RTree::RTree* pTree,
	IDataStream& stream,
	uint32_t bindex,
	uint32_t bleaf,
	uint32_t pageSize,
	uint32_t numberOfPages
) {
	if (! stream.hasNext())
		throw Tools::IllegalArgumentException(
			"RTree::BulkLoader::bulkLoadUsingSTR: Empty data stream given."
		);

	NodePtr n = pTree->readNode(pTree->m_rootID);
	pTree->deleteNode(n.get());

	#ifndef NDEBUG
	std::cerr << "RTree::BulkLoader: Sorting data." << std::endl;
	#endif

	Tools::SmartPointer<ExternalSorter> es = Tools::SmartPointer<ExternalSorter>(new ExternalSorter(pageSize, numberOfPages));

	int count  = 0;

	while (stream.hasNext())
	{
		Data* d = reinterpret_cast<Data*>(stream.getNext());
		if (d == 0)
			throw Tools::IllegalArgumentException(
				"bulkLoadUsingSTR: RTree bulk load expects SpatialIndex::RTree::Data entries."
			);

		d->m_id = count++;

		bitmask_t center[3];

		center[0] = (d->m_region.m_pHigh[0] + d->m_region.m_pLow[0]) / 2;
		center[1] = (d->m_region.m_pHigh[1] + d->m_region.m_pLow[1]) / 2;
		center[2] = (d->m_region.m_pHigh[2] + d->m_region.m_pLow[2]) / 2;

		unsigned long long hilbert = (unsigned long long)hilbert_c2i (3, 11, center);

		es->hinsert(new ExternalSorter::Record(d->m_region, d->m_id, d->m_dataLength, d->m_pData, 0, hilbert));
		d->m_pData = 0;
		delete d;
	}

	es->hsort();

	pTree->m_stats.m_u64Data = es->getTotalEntries();

	// create index levels.
	uint32_t level = 0;

	while (true)
	{
		#ifndef NDEBUG
		std::cerr << "RTree::BulkLoader: Building level " << level << std::endl;
		#endif

		pTree->m_stats.m_nodesInLevel.push_back(0);

		Tools::SmartPointer<ExternalSorter> es2 = Tools::SmartPointer<ExternalSorter>(new ExternalSorter(pageSize, numberOfPages));
		createHilbertLevel(pTree, es, 0, bleaf, bindex, level++, es2, pageSize, numberOfPages);
		es = es2;

		if (es->getTotalEntries() == 1) break;
		es->hsort();
	}

	pTree->m_stats.m_u32TreeHeight = level;
	pTree->storeHeader();
}

void BulkLoader::createHilbertLevel(
	SpatialIndex::RTree::RTree* pTree,
	Tools::SmartPointer<ExternalSorter> es,
	uint32_t dimension,
	uint32_t bleaf,
	uint32_t bindex,
	uint32_t level,
	Tools::SmartPointer<ExternalSorter> es2,
	uint32_t pageSize,
	uint32_t numberOfPages
) {
	uint64_t b = (level == 0) ? bleaf : bindex;

	std::vector<ExternalSorter::Record*> node;
	ExternalSorter::Record* r;

	while (true)
	{
		try { r = es->getNextRecord(); } catch (Tools::EndOfStreamException) { break; }
		node.push_back(r);

		if (node.size() == b)
		{
			Node* n = createNode(pTree, node, level);

			unsigned long long mh = 0;

			for (size_t cChild = 0; cChild < node.size(); ++cChild)
			{
				if(node[cChild]->hilbert_value > mh) mh = node[cChild]->hilbert_value;
			}


			node.clear();
			pTree->writeNode(n);

			es2->hinsert(new ExternalSorter::Record(n->m_nodeMBR, n->m_identifier, 0, 0, 0, mh));
			pTree->m_rootID = n->m_identifier;

			delete n;
		}
	}

	if (! node.empty())
	{
		Node* n = createNode(pTree, node, level);

		unsigned long long mh = 0;

		for (size_t cChild = 0; cChild < node.size(); ++cChild)
		{
			if(node[cChild]->hilbert_value > mh) mh = node[cChild]->hilbert_value;
		}


		pTree->writeNode(n);

		es2->hinsert(new ExternalSorter::Record(n->m_nodeMBR, n->m_identifier, 0, 0, 0, mh));
		pTree->m_rootID = n->m_identifier;
		delete n;
	}
}


void BulkLoader::createLevel(
	SpatialIndex::RTree::RTree* pTree,
	Tools::SmartPointer<ExternalSorter> es,
	uint32_t dimension,
	uint32_t bleaf,
	uint32_t bindex,
	uint32_t level,
	Tools::SmartPointer<ExternalSorter> es2,
	uint32_t pageSize,
	uint32_t numberOfPages
) {
	uint64_t b = (level == 0) ? bleaf : bindex;
	uint64_t P = static_cast<uint64_t>(std::ceil(static_cast<double>(es->getTotalEntries()) / static_cast<double>(b)));
	uint64_t S = static_cast<uint64_t>(std::ceil(std::sqrt(static_cast<double>(P))));

	if (S == 1 || dimension == pTree->m_dimension - 1 || S * b == es->getTotalEntries())
	{
		std::vector<ExternalSorter::Record*> node;
		ExternalSorter::Record* r;

		while (true)
		{
			try { r = es->getNextRecord(); } catch (Tools::EndOfStreamException) { break; }
			node.push_back(r);

			if (node.size() == b)
			{
				Node* n = createNode(pTree, node, level);
				node.clear();
				pTree->writeNode(n);
				es2->insert(new ExternalSorter::Record(n->m_nodeMBR, n->m_identifier, 0, 0, 0));
				pTree->m_rootID = n->m_identifier;
					// special case when the root has exactly bindex entries.
				delete n;
			}
		}

		if (! node.empty())
		{
			Node* n = createNode(pTree, node, level);
			pTree->writeNode(n);
			es2->insert(new ExternalSorter::Record(n->m_nodeMBR, n->m_identifier, 0, 0, 0));
			pTree->m_rootID = n->m_identifier;
			delete n;
		}
	}
	else
	{
		bool bMore = true;

		while (bMore)
		{
			ExternalSorter::Record* pR;
			Tools::SmartPointer<ExternalSorter> es3 = Tools::SmartPointer<ExternalSorter>(new ExternalSorter(pageSize, numberOfPages));
			
			for (uint64_t i = 0; i < S * b; ++i)
			{
				try { pR = es->getNextRecord(); }
				catch (Tools::EndOfStreamException) { bMore = false; break; }
				pR->m_s = dimension + 1;
				es3->insert(pR);
			}
			es3->sort();
			createLevel(pTree, es3, dimension + 1, bleaf, bindex, level, es2, pageSize, numberOfPages);
		}
	}
}

Node* BulkLoader::createNode(SpatialIndex::RTree::RTree* pTree, std::vector<ExternalSorter::Record*>& e, uint32_t level)
{
	Node* n;

	if (level == 0) n = new Leaf(pTree, -1);
	else n = new Index(pTree, -1, level);

	for (size_t cChild = 0; cChild < e.size(); ++cChild)
	{
		n->insertEntry(e[cChild]->m_len, e[cChild]->m_pData, e[cChild]->m_r, e[cChild]->m_id);
		e[cChild]->m_pData = 0;
		delete e[cChild];
	}

	return n;
}
