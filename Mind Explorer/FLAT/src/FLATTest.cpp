//
//  FLAT.cpp
//  FLAT Tester
//
//  Created by William Moyle on 31/07/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

#include "FLATTest.hpp"
#include <vector>
#include <iostream>
#include <fstream>
#include <set>
#include <CoreFoundation/CFBundle.h>
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/CFUrl.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string>

using namespace std;

namespace FLAT
{
    class BufferedFile
    {
    public:
        BufferedFile() {
            eof = true;
            temporary = false;
            buffer = NULL;
        };
        
        ~BufferedFile() {
            close();
            if (temporary)
            {
                if (remove(filename.c_str())!=0)
                {
#ifdef FATAL
                    cout << "Cannot Delete Temporary File: " << filename << "\n";
#endif
                }
            }
        };
        
        void open(string filename) {
            try
            {
                this->filename = filename;
                close();
                eof=false;
                temporary=false;
                buffer = new char[FILE_BUFFER_SIZE];
                
                file.open(filename.c_str(), ios_base::in | ios_base::binary);
                file.rdbuf()->pubsetbuf(buffer, FILE_BUFFER_SIZE);
                
                if (!file.good()) throw 1;
            }
            catch(...)
            {
                eof = true;
#ifdef FATAL
                cout << "Cannot Open file: " << filename << "\n";
#endif
            };
        };
        
        void close() {
            eof=true;
            file.clear();
            if (file.is_open())
                file.close();
            delete[] buffer;
            buffer  = NULL;
        };
        
        void seek(uint64 offset) {
            try
            {
                eof = false;
                file.clear();
#ifdef WIN32
                file.seekg(0, std::ios_base::beg);
                uint32 n4GBSeeks = offset / 0xFFFFFFFF;
                for(uint32 i = 0; i < n4GBSeeks; i++)
                    file.seekg(0xFFFFFFFF, ios_base::cur);
                file.seekg(offset % 0xFFFFFFFF, ios_base::cur);
#else
                file.seekg(offset, ios_base::beg);
#endif
                if (!file.good()) throw 1;
            }
            catch(...)
            {
                eof = true;
#ifdef FATAL
                cout << "Cannot Seek file" << filename << " to:" << offset << "\n";
#endif
            }
        };
        
        void read(uint32 size, int8* buffer) {
#ifdef FATAL
            if (eof)
                cout << "Reading file after eof : " << filename << "\n";
#endif
            try
            {
                file.read(buffer,size);
                if (!file.good()) throw 1;
                eof = file.eof();
            }
            catch(...)
            {
                eof= true;
            }
        };
        
        uint32 readUInt32() {
            uint32 ret;
            try
            {
                file.read(reinterpret_cast<char*>(&ret), sizeof(uint32));
                if (!file.good()) throw 1;
            }
            catch(...)
            {
                eof = true;
#ifdef FATAL
                
                cout << "Cannot Read uint32 from file: " << filename << "\n";
#endif
            }
            return ret;
        };
        
        uint64 readUInt64() {
            uint64 ret;
            try
            {
                file.read(reinterpret_cast<char*>(&ret), sizeof(uint64));
                if (!file.good()) throw 1;
            }
            catch(...)
            {
                eof = true;
#ifdef FATAL
                cout << "Cannot Read uint64 from file: " << filename << "\n";
#endif
            }
            return ret;
        };
        
        fstream file;
        string filename;
        char* buffer;
        bool eof;
        bool temporary;
    };
    
    class PayLoad
    {
    public:
        BufferedFile* file;
        string filename;
        uint32 pageSize;
        uint64 objectsPerPage;
        uint32 objectSize;
        bool isCreated;
        SpatialObjectType objType;
        
        PayLoad() {};
        ~PayLoad() {
            delete file;
        };
        void load(string indexFileStem) {
            try
            {
                this->filename = indexFileStem + "_payload.dat";
                file  = new BufferedFile();
                file->open(this->filename);
                
                this->pageSize = file->readUInt32();
                this->objType  =  (SpatialObjectType)file->readUInt32();
                this->objectsPerPage = file->readUInt64();
                this->objectSize = file->readUInt32();
                
                this->isCreated= false;
            }
            catch(...)
            {
#ifdef FATAL
                cout << "Cannot load Payload File: " << this->filename << endl;
#endif
                exit(0);
            }
        };
    };
}

using namespace std;
namespace FLAT
{
    
    typedef uint32_t id;
    
    class MetadataEntry
    {
    public:
        Box pageMbr;
        Box partitionMbr;
        id pageId;
        set<id> pageLinks;
        
#ifdef DEBUG
        int i,j,k;
        
#endif
        
        MetadataEntry();
        
        MetadataEntry(byte * buffer, int length);
        
        ~MetadataEntry();
        
        void write(spaceUnit f, int pos, byte* buf);
        
        void writeId(int i, int pos, byte* buf);
        
        int readId(int pos, byte* buf);
        
        spaceUnit read(int pos, byte* buf);
    };
    
    class MetaVisitor : public SpatialIndex::IVisitor
    {
    public:
        vector<MetadataEntry*>* metadataStructure;
        int i;
        MetaVisitor(vector<MetadataEntry*>* metadataStructure,int i);
        ~MetaVisitor();
        virtual void visitNode(const SpatialIndex::INode& in);
        //virtual void visitData(const SpatialIndex::IData& in);
        virtual void visitUseless();
        virtual void visitData(const SpatialIndex::IData& in, SpatialIndex::id_type);
        virtual void visitData(std::vector<const SpatialIndex::IData*>& v);
        virtual bool doneVisiting();
    };
    
    class MetaDataStream : public SpatialIndex::IDataStream
    {
    public:
        unsigned i;
        uint32_t pages;
        bool dolinking;
        SpatialIndex::ISpatialIndex *linkerTree;
        
#ifdef DEBUG
        uint32_t links;
        int frequency[100];
        bigSpaceUnit sumVolume;
#endif
        vector<MetadataEntry*>* metadataStructure;
        
        MetaDataStream (vector<MetadataEntry*>* metadataStructure,SpatialIndex::ISpatialIndex *linkerTree);
        MetaDataStream (vector<MetadataEntry*>* metadataStructure);
        
        virtual ~MetaDataStream();
        
        virtual bool hasNext();
        
        virtual uint32_t size();
        
        virtual void rewind();
        
        void GenerateLinks(MetadataEntry* me,uint32_t i);
    };
    
}


using namespace FLAT;

class rtreeVisitor : public SpatialIndex::IVisitor
{
public:
    SpatialQuery* query;
    bool done;
    PayLoad* payload;
    
    rtreeVisitor(SpatialQuery* query, string indexFileStem) {
        this->query = query;
        done = false;
        payload   = new PayLoad();
        payload->load(indexFileStem);
    };
    
    ~rtreeVisitor() {
        delete payload;
    };
    
    virtual void visitNode(const SpatialIndex::INode& in) {
        if (in.isLeaf())
        {
            query->stats.FLAT_metaDataIOs++;
        }
        else
        {
            query->stats.FLAT_seedIOs++;
        }
    };
    
    virtual void visitData(const SpatialIndex::IData& in) {};
    
    virtual void visitUseless() {};
    
    virtual bool doneVisiting() {return done;};
    
    virtual void visitData(const SpatialIndex::IData& in, SpatialIndex::id_type id) {
        query->stats.FLAT_metaDataEntryLookup++;
        FLAT::uint8 *b;
        uint32 l;
        in.getData(l, &b);
        
        MetadataEntry m = MetadataEntry(b, l);
        delete[] b;
        
        vector<SpatialObject*> so;
        
        if (!payload->isCreated) {
            
            int8 page[payload->pageSize];
            int8* ptr = page;
            
            uint64_t offset = (uint64_t)(m.pageId+1)*(uint64_t)payload->pageSize; // +1 cause first page is Header
            
            payload->file->seek(offset);
            payload->file->read(payload->pageSize,page);
            
            uint32 counter=0;
            uint32 objectByteSize = SpatialObjectFactory::getSize(payload->objType);
            
            memcpy(&counter,ptr,sizeof(uint32));
            ptr += sizeof(uint32);
            
            for (uint32 i=0;i<counter;i++)
            {
                SpatialObject* sobj = SpatialObjectFactory::create(payload->objType);
                sobj->unserialize(ptr);
                ptr+=objectByteSize;
                so.push_back(sobj);
            }
        }
        
        for (vector<SpatialObject*>::iterator it = so.begin(); it != so.end(); ++it)
            if (Box::overlap(query->Region, (*it)->getMBR()))
            {
                done = true;
                query->stats.FLAT_seedId = int(id);
                break;
            }
        
        for (vector<SpatialObject*>::iterator it = so.begin(); it != so.end(); ++it)
            delete (*it);
    };
    
    virtual void visitData(std::vector<const SpatialIndex::IData *>& v
                           __attribute__((__unused__))) {};
};



using namespace std;

namespace FLAT {
    
    MetadataEntry::MetadataEntry()
    {
    }
    
    MetadataEntry::MetadataEntry(byte * buffer, int length)
    {
        pageMbr.low[0]  = read(0*sizeof(spaceUnit), buffer);
        pageMbr.low[1]  = read(1*sizeof(spaceUnit), buffer);
        pageMbr.low[2]  = read(2*sizeof(spaceUnit), buffer);
        pageMbr.high[0] = read(3*sizeof(spaceUnit), buffer);
        pageMbr.high[1] = read(4*sizeof(spaceUnit), buffer);
        pageMbr.high[2] = read(5*sizeof(spaceUnit), buffer);
        
        pageId = readId(6*sizeof(spaceUnit), buffer);
        
        int count = readId(6*sizeof(spaceUnit) + sizeof(id), buffer);
        for (int i=0; i<count; i++)
        {
            pageLinks.insert(readId(6*sizeof(spaceUnit) + 2*sizeof(id) + i*sizeof(id), buffer));
        }
    }
    
    MetadataEntry::~MetadataEntry()
    {
        pageLinks.clear();
    }
    
    void MetadataEntry::write(spaceUnit f, int pos, byte* buf)
    {
        byte* tmp = (byte*)&f;
        
        for(unsigned i=0; i<sizeof(spaceUnit); i++)
        {
            buf[i+pos] = tmp[i];
        }
    }
    
    void MetadataEntry::writeId(int i, int pos, byte* buf)
    {
        byte* tmp = (byte*)&i;
        
        for(unsigned j=0; j<sizeof(id); j++)
        {
            buf[j+pos] = tmp[j];
        }
    }
    
    int MetadataEntry::readId(int pos, byte* buf)
    {
        byte tmp[sizeof(id)];
        
        for(unsigned i=0; i<sizeof(id); i++) {
            tmp[i] = buf[i+pos];
        }
        
        int val = *reinterpret_cast<int *>(tmp);
        
        return val;
    }
    
    spaceUnit MetadataEntry::read(int pos, byte* buf)
    {
        byte tmp[sizeof(spaceUnit)];
        
        for(unsigned i=0; i<sizeof(spaceUnit); i++)
        {
            tmp[i] = buf[i+pos];
        }
        
        spaceUnit val = *reinterpret_cast<spaceUnit *>(tmp);
        
        return val;
    }
    
    
    
    MetaVisitor::MetaVisitor(vector<MetadataEntry*>* metadataStructure,int i)
    {
        this->metadataStructure = metadataStructure;
        this->i=i;
    }
    MetaVisitor::~MetaVisitor()
    {
    }
    void MetaVisitor::visitNode(const SpatialIndex::INode& in)
    {
    }
    
    void MetaVisitor::visitUseless()
    {
        
    }
    void MetaVisitor::visitData(const SpatialIndex::IData& in, SpatialIndex::id_type)
    {
        
    }
    void MetaVisitor::visitData(std::vector<const SpatialIndex::IData*>& v)
    {
        
    }
    bool MetaVisitor::doneVisiting()
    {
        return false;
    }
    
    
    
    
    MetaDataStream::MetaDataStream (vector<MetadataEntry*>* metadataStructure,SpatialIndex::ISpatialIndex *linkerTree)
    {
        i=0;
        this->linkerTree = linkerTree;
        this->metadataStructure = metadataStructure;
        pages = uint32_t(metadataStructure->size());
#ifdef DEBUG
        links=0;
        sumVolume=0;
        for (int i=0;i<100;i++)
        {
            //			volumeDistributon[i]=0;
            //			volumeLink[i]=0;
            frequency[i]=0;
        }
        //		overflow=0;
        
#endif
        dolinking=true;
    }
    
    MetaDataStream::MetaDataStream (vector<MetadataEntry*>* metadataStructure)
    {
        i=0;
        this->metadataStructure = metadataStructure;
        pages = uint32_t(metadataStructure->size());
#ifdef DEBUG
        links=0;
        sumVolume=0;
        for (int i=0;i<100;i++)
            frequency[i]=0;
#endif
        dolinking=false;
    }
    
    MetaDataStream::~MetaDataStream()
    {
    }
    
    bool MetaDataStream::hasNext()
    {
        return (i < pages);
    }
    
    uint32_t MetaDataStream::size()
    {
        return pages;
    }
    
    void MetaDataStream::rewind()
    {
        i=0;
    }
}


/*FLATTest::FLATTest() {
    numCoords = 123987;
    results = new spaceUnit[0];
}

FLATTest::FLATTest(string _in, string _query) {
    inputStem = _in;
    queryFile = _query;
    performTest();
    stats.printFLATstats();
}*/

//FLATTest::FLATTest(std::string* filename) {
FLATTest::FLATTest(char* filename, int len) {
    char * filename2 = new char[len];
    strcpy(filename2, filename);
    char * newInputStem = strcat(filename, "FLAT168_index.dat");
    //cout << newInputStem << endl;
    
    //char * newQueryFile = strcat(filename2, "SampleQuery.txt");
    //cout << newQueryFile << endl;
    
    //queryFile = *filename + "SampleQuery.txt";
    
    
    CFStringEncoding encodingMethod = CFStringGetSystemEncoding();
    
    CFStringRef datStringRef = CFStringCreateWithCString(kCFAllocatorDefault, newInputStem, encodingMethod);
    CFURLRef datURL  = CFURLCreateWithString(kCFAllocatorDefault, datStringRef, NULL);
    CFStringRef datPath = CFURLCopyFileSystemPath(datURL, kCFURLPOSIXPathStyle);
    inputStem = CFStringGetCStringPtr(datPath, encodingMethod);

    //cout << "Inputstem: " << inputStem << endl;
    
    /*fstream input;
    input.open(inputStem.c_str(), std::ios::in | std::ios::out | std::ios::binary);
    if (input.fail())
        cout << "Failure\n";
    else
        cout << "Success\n";
    input.close();*/
    
    inputStem = inputStem.substr(0, inputStem.size()-10);
    
    //CFBundleRef mainBundle = CFBundleGetMainBundle();
    //CFURLRef imageURL = CFBundleCopyResourceURL(mainBundle, CFSTR("SampleQuery"), CFSTR("txt"), NULL);
    //CFStringRef imagePath = CFURLCopyFileSystemPath(imageURL, kCFURLPOSIXPathStyle);
    //const char *path = CFStringGetCStringPtr(imagePath, encodingMethod);
    //queryFile = path;
    
    //cout << "Queryfile: " << queryFile << endl;

    //performTest();
    numCoords = 0;
    //stats.printFLATstats();
    
}

FLATTest::~FLATTest() {
    results.clear();
}

void FLATTest::performTest(float p0, float p1, float p2, float p3, float p4, float p5) {
    /******************** LOADING INDEX *********************/
    PayLoad* payload = new PayLoad();
    payload->load(inputStem);
    string seedfile = inputStem + "_index";
    SpatialIndex::IStorageManager* rtreeStorageManager = SpatialIndex::StorageManager::loadDiskStorageManager(seedfile);
    SpatialIndex::id_type indexIdentifier = 1;
    SpatialIndex::ISpatialIndex* seedtree = SpatialIndex::RTree::loadRTree(*rtreeStorageManager, indexIdentifier);
    
    /********************** DO QUERIES **********************/
    /*vector<SpatialQuery> queries;
    
    std::ifstream readFile;
    readFile.open(queryFile.c_str(),std::ios::in);
    std::string line;
    getline (readFile,line);
    SpatialQueryType type = (SpatialQueryType)atoi(line.c_str());
    
    
    if (readFile.is_open())
    {
        while (!readFile.eof())
        {
            std::vector<std::string> tokens;
            getline (readFile,line);
            if (readFile.eof()) break;
            //tokenize(line, tokens);
            
            // Skip delimiters at beginning.
            std::string::size_type lastPos = line.find_first_not_of(" ", 0);
            // Find first "non-delimiter".
            std::string::size_type pos     = line.find_first_of(" ", lastPos);
            
            while (std::string::npos != pos || std::string::npos != lastPos) {
                // Found a token, add it to the vector.
                tokens.push_back(line.substr(lastPos, pos - lastPos));
                // Skip delimiters.  Note the "not_of"
                lastPos = line.find_first_not_of(" ", pos);
                // Find next "non-delimiter"
                pos = line.find_first_of(" ", lastPos);
            }
            
            SpatialQuery temp;
            temp.type = (SpatialQueryType)type;
            temp.Region.low[0]   = atof(tokens.at(0).c_str());
            temp.Region.low[1]   = atof(tokens.at(1).c_str());
            temp.Region.low[2]   = atof(tokens.at(2).c_str());
            temp.Region.high[0]  = atof(tokens.at(3).c_str());
            temp.Region.high[1]  = atof(tokens.at(4).c_str());
            temp.Region.high[2]  = atof(tokens.at(5).c_str());
            queries.push_back(temp);
        }
        readFile.close();
    }*/
    
    SpatialQuery query;
    query.type = RANGE_QUERY;
    query.Region.low[0] = p0;
    query.Region.low[1] = p1;
    query.Region.low[2] = p2;
    query.Region.high[0] = p3;
    query.Region.high[1] = p4;
    query.Region.high[2] = p5;
    
    //QueryStatistics totalStats;
    //totalStats.ObjectSize = SpatialObjectFactory::getSize(BOX);
    //totalStats.ObjectsPerPage = (uint64)floor((PAGE_SIZE-4.0) / (totalStats.ObjectSize+0.0));
    int queueLength=0;
    long intersects = 0;
    
    //for (vector<SpatialQuery>::iterator query = queries.begin(); query != queries.end();query++)
    //{
        query.stats.ObjectSize = SpatialObjectFactory::getSize(BOX);
        query.stats.ObjectsPerPage = (uint64)floor((PAGE_SIZE-4.0) / (query.stats.ObjectSize+0.0));
        queue<int> metapageQueue;
        set<int> visitedMetaPages;
        /*=================== SEEDING ======================*/
        double lo[DIMENSION],hi[DIMENSION];
        for (int i=0;i<DIMENSION;i++)
        {
            lo[i] = (double)query.Region.low[i];
            hi[i] = (double)query.Region.high[i];
        }
        SpatialIndex::Region query_region = SpatialIndex::Region(lo,hi,DIMENSION);
        rtreeVisitor visitor(&query,inputStem);
        seedtree->seedQuery(query_region, visitor);
        
        if (query.stats.FLAT_seedId>=0)
        {
            metapageQueue.push(query.stats.FLAT_seedId);
        }
        
        unsigned int maxQueueLength=0;
        /*=================== CRAWLING ======================*/
        while (!metapageQueue.empty())
        {
            /*--------------  VISIT ---------------*/
            int visitPage = metapageQueue.front();
            metapageQueue.pop();
            
            bool b1 = visitedMetaPages.find(visitPage) != visitedMetaPages.end();
            
            if(b1) continue;
            
            nodeSkeleton * nss = SeedBuilder::readNode(visitPage, rtreeStorageManager);
            visitedMetaPages.insert(visitPage);
            query.stats.FLAT_metaDataIOs++;
            
            if (nss->nodeType == SpatialIndex::RTree::PersistentLeaf)
            {
                for (unsigned i = 0; i < nss->children; i++)
                {
                    MetadataEntry m = MetadataEntry(nss->m_pData[i], nss->m_pDataLength[i]);
                    
                    /*int count = m.readId(6*sizeof(spaceUnit) + sizeof(id), nss->m_pData[i]);
                    set<id> pageLinks;
                    for (int i=0; i<count; i++)
                    {
                        pageLinks.insert(m.readId(6*sizeof(spaceUnit) + 2*sizeof(id) + i*sizeof(id), nss->m_pData[i]));
                    }*/
                    
                    for (int a=0;a<DIMENSION;a++)
                    {
                        m.partitionMbr.low[a]  = nss->m_ptrMBR[i]->m_pLow[a];
                        m.partitionMbr.high[a] = nss->m_ptrMBR[i]->m_pHigh[a];
                    }
                    query.stats.FLAT_metaDataEntryLookup++;
                    
                    intersects++;
                    bool b2 = Box::overlap(m.partitionMbr,query.Region);
                    
                    if (b2)
                    {
                        for (set<id>::iterator links = m.pageLinks.begin(); links != m.pageLinks.end(); links++)
                            metapageQueue.push(*links);
                        
                        intersects++;
                        bool b3 = Box::overlap(m.pageMbr,query.Region);
                        
                        if (b3)
                        {
                            vector<SpatialObject*> objects;
                            
                            if (!payload->isCreated) {
                                
                                int8 page[payload->pageSize];
                                int8* ptr = page;
                                
                                uint64_t offset = (uint64_t)(m.pageId+1)*(uint64_t)payload->pageSize; // +1 cause first page is Header
                                
                                payload->file->seek(offset);
                                payload->file->read(payload->pageSize,page);
                                
                                uint32 counter=0;
                                uint32 objectByteSize = SpatialObjectFactory::getSize(payload->objType);
                                
                                memcpy(&counter,ptr,sizeof(uint32));
                                ptr += sizeof(uint32);
                                
                                for (uint32 i=0;i<counter;i++)
                                {
                                    SpatialObject* sobj = SpatialObjectFactory::create(payload->objType);
                                    sobj->unserialize(ptr);
                                    ptr+=objectByteSize;
                                    objects.push_back(sobj);
                                }
                            }
                            
                            query.stats.FLAT_payLoadIOs++;
                            for (vector<SpatialObject*>::iterator it = objects.begin(); it != objects.end(); ++it)
                            {
                                intersects++;
                                bool b3 = Box::overlap(query.Region, (*it)->getMBR());
                                if (b3) {
                                    query.stats.ResultPoints++;
                                    Mesh* newMesh = dynamic_cast<Mesh*>(*it);
                                    MeshData newMeshData(*newMesh);
                                    for (int i = 0; i < 9; i++)
                                        results.push_back(newMeshData.vertexData[i]);
                                }
                                else
                                    query.stats.UselessPoints++;
                                delete (*it);
                            }
                        }
                    }
                }
            }
            delete nss;
            if (metapageQueue.size()>maxQueueLength) maxQueueLength=uint32_t(metapageQueue.size());
        }
        //query->stats.printFLATstats();
        //totalStats.add(query->stats);
        queueLength += visitedMetaPages.size()+maxQueueLength;
    //}
    //stats.add(totalStats);
    numCoords = int(results.size());

    //stats.printFLATstats();
}

void FLATTest::printMeshCoords() {
    cout << "\nPRINTING RESULTS:\n";
    for (int i = 0; i < numCoords; i++) {
        cout << results[i] << " ";
    }
    cout << endl;
}