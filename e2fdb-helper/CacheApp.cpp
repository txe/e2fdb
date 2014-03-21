#include "CacheApp.h"
#import <ksConstants.tlb>   no_namespace named_guids
#import <ksConstants3D.tlb> no_namespace named_guids
#import <kAPI2D5COM.tlb>    no_namespace named_guids
#import <kAPI3D5COM.tlb>    no_namespace named_guids
#import <kAPI7.tlb>         rename_namespace("API7") named_guids
#import <kAPI5.tlb>         named_guids rename_namespace("API5") 
#include "ibpp/ibpp.h"
#include "ByteData.h"
#include "_io.h"
#include "aux_ext.h"
#include <list>


//-------------------------------------------------------------------------
struct FILE_INFO
{
  ByteData    data;
  ByteData    icon;
  std::string crc;
};
//-------------------------------------------------------------------------
struct CACHE_INFO
{
  API5::KompasObjectPtr kompas5;

  IBPP::Database    db;
  IBPP::Transaction trans;
  IBPP::Statement   findSt;
  IBPP::Statement   addSt;
  IBPP::Blob        dataBlob;
  IBPP::Blob        iconBlob;

  std::wstring      tempM3D;
  std::wstring      tempFrw;
 
  std::list<FILE_INFO*> infoList;
};
//-------------------------------------------------------------------------
void FillRef(FILE_INFO& fileInfo, char** data, int* dataLen, char** crc, int* crcLen, char** icon, int* iconLen);
bool FindFileInCache(CACHE_INFO* cache, const char* digest, FILE_INFO& fileInfo);
void WriteFileInCache(CACHE_INFO* cache, const std::string& digest, FILE_INFO& fileInfo);
bool PrepareFile(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo);
bool PrepareFrw(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo);
bool PrepareM3D(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo);


static std::string glb_error;
//-------------------------------------------------------------------------
const char* CacheApp::_ErrorMessage()
{
  return glb_error.c_str();
}
//-------------------------------------------------------------------------
int CacheApp::_NewInstance(const char* cacheDb, int majorVer, int minorVer)
{
  // проверим подсоединение базы
  IBPP::Database base = IBPP::DatabaseFactory("", cacheDb, "sysdba", "masterkey");
  base->Connect();
  if (!base->Connected())
  {
    glb_error = "не смогли подключится к файловому кэшу";
    return 0;
  }

  IBPP::Transaction trans = IBPP::TransactionFactory(base, IBPP::amWrite, IBPP::ilReadCommitted, IBPP::lrNoWait);
  trans->Start();

  // если версия прописана, то проверим совпадение
  IBPP::Statement st = StatementFactory(base, trans);
  st->Execute("SELECT param_value FROM params WHERE param_key='version'");
  std::string version = std::string((LPCSTR)aux::itoa(majorVer)) + "." + std::string((LPCSTR)aux::itoa(minorVer));
  if (st->Fetch())
  {
    std::string res;
    st->Get(1, res);
    if (res != version)
    {
      glb_error = "версия файлового кэша не совпадает с версией компаса";
      return 0;
    }
  }
  else // если там версии нет, то это пустышка, пропишем текущую версию
  {
    st->Prepare("INSERT INTO params (param_key, param_value) VALUES(?, ?)");
    st->Set(1, "version");
    st->Set(2, version);
    st->Execute();
  }


  IBPP::Blob dataBlob = IBPP::BlobFactory(base, trans);
  IBPP::Blob iconBlob = IBPP::BlobFactory(base, trans);
  // подготовим нужные запросы к базе
  IBPP::Statement findSt = StatementFactory(base, trans);
  findSt->Prepare("SELECT data, icon, crc FROM files WHERE digest = ?");
  IBPP::Statement addSt = StatementFactory(base, trans);
  addSt->Prepare("INSERT INTO files (digest, data, icon, crc) VALUES(?, ?, ?, ?)");
  

  // запустим компас
  CoInitializeEx(NULL, COINIT_MULTITHREADED);

  CLSID clsid = IID_NULL;
  CLSIDFromProgID(L"KOMPAS.Application.5", &clsid);

  IUnknownPtr kompasApp;
  HRESULT hRes = CoCreateInstance(clsid, NULL, CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER, IID_IUnknown, (void**)&kompasApp);
  if (!SUCCEEDED(hRes))
  {
    glb_error = "не смогли запустить компас";
    return 0;
  }


  CACHE_INFO* cache = new CACHE_INFO; 
  cache->kompas5 = kompasApp;
  cache->db        = base;
  cache->trans     = trans;
  cache->findSt    = findSt;
  cache->addSt     = addSt;
  cache->dataBlob  = dataBlob;
  cache->iconBlob  = iconBlob;

  std::wstring temp = io::dir::temp_dir(L"_fdb_converter");
  if (!io::dir::exist(temp))
    io::dir::create(temp);

  cache->tempM3D = io::file::temp_name(temp, L"_x_", L".m3d");

  return (int)cache;
}
//-------------------------------------------------------------------------
bool CacheApp::_DeleteInstance(int c)
{
  CACHE_INFO* cache = (CACHE_INFO*)c;
  if (cache && cache->kompas5)
    cache->kompas5->Quit();

  delete cache;
  return true;
}
//-------------------------------------------------------------------------
void CacheApp::_ClearCache(int c)
{
  CACHE_INFO* cache = (CACHE_INFO*)c;
}
//-------------------------------------------------------------------------
bool CacheApp::_CacheFile(int c, const char* digest, const char* fromFile, bool isEngSys, char** data, int* dataLen, char** crc, int* crcLen, char** icon, int* iconLen)
{
  CACHE_INFO* cache = (CACHE_INFO*)c;
  
  FILE_INFO* fileInfo = new FILE_INFO();
  if (FindFileInCache(cache, digest, *fileInfo))
  {
    cache->infoList.push_back(fileInfo);
    FillRef(*fileInfo, data, dataLen, crc, crcLen, icon, iconLen);
    return true;
  }

  if (PrepareFile(cache, fromFile, isEngSys, *fileInfo))
  {
    cache->infoList.push_back(fileInfo);
    WriteFileInCache(cache, digest, *fileInfo);
    FillRef(*fileInfo, data, dataLen, crc, crcLen, icon, iconLen);
    return true;
  }

  delete fileInfo;
  return false;
}
//-------------------------------------------------------------------------
void FillRef(FILE_INFO& fileInfo, char** data, int* dataLen, char** crc, int* crcLen, char** icon, int* iconLen)
{
  *data    = (char*)fileInfo.data.GetData();
  *dataLen = fileInfo.data.GetLength();
  *icon    = (char*)fileInfo.icon.GetData();
  *iconLen = fileInfo.icon.GetLength();
  *crc     = (char*)fileInfo.crc.c_str();
  *crcLen  = fileInfo.crc.size();
}
//-------------------------------------------------------------------------
bool FindFileInCache(CACHE_INFO* cache, const char* digest, FILE_INFO& fileInfo)
{
  cache->findSt->Set(1, digest);
  cache->findSt->Execute();
  if (!cache->findSt->Fetch())
    return false;

  cache->findSt->Get(1, cache->dataBlob);
  fileInfo.data.LoadFromBlob(cache->dataBlob);
  cache->findSt->Get(2, cache->iconBlob);
  fileInfo.icon.LoadFromBlob(cache->iconBlob);
  cache->findSt->Get(3, fileInfo.crc);

  return true;
}
//-------------------------------------------------------------------------
void WriteFileInCache(CACHE_INFO* cache, const std::string& digest, FILE_INFO& fileInfo)
{
  cache->addSt->Set(1, digest);
  fileInfo.data.SaveToBlob(cache->dataBlob);
  cache->addSt->Set(2, cache->dataBlob);
  fileInfo.icon.SaveToBlob(cache->iconBlob);
  cache->addSt->Set(3, cache->iconBlob);
  cache->addSt->Set(4, fileInfo.crc);

  cache->addSt->Execute();
}
//-------------------------------------------------------------------------
bool PrepareFile(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo)
{
  bool isFrw = fromFile.find("lfr", 0) != std::string::npos;
  if (isFrw)
    return PrepareFrw(cache, fromFile, isEngSys, fileInfo);
  else
    return PrepareM3D(cache, fromFile, isEngSys, fileInfo);
}
//-------------------------------------------------------------------------
bool PrepareFrw(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo)
{
  return false;
}
//-------------------------------------------------------------------------
bool PrepareM3D(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo)
{
  io::file::remove(cache->tempM3D);
  io::file::copy(aux::_a2w(fromFile), cache->tempM3D);

  API5::ksDocument3DPtr doc = cache->kompas5->Document3D();
  if (0 == doc->Open(cache->tempM3D.c_str(), VARIANT_TRUE))
    return false;

  // посчитаем crc
  //API7::ICheckSumPtr crc = cache->kompas5->CheckSum;
  //crc->AddReference(doc->Reference, doc->Reference, TRUE );
  //fileInfo.crc = aux::_w2a(std::wstring(crc->StrResult.GetBSTR()));

  // развернем модель
  if (!isEngSys)
    if (API5::ksViewProjectionCollectionPtr views = doc->GetViewProjectionCollection())
      if (API5::ksViewProjectionPtr view = views->GetByIndex(7 /*vp_IsoXYZ*/))
        view->SetCurrent();

  doc->Save();
  doc->close();

  fileInfo.data.LoadFromFile(cache->tempM3D);
  fileInfo.data.Compress();


  return true;
}
