#include "CacheServer.h"
#include "ibpp/ibpp.h"
#include "ByteData.h"
#include "aux_ext.h"
#include <list>

using namespace IBPP;
//-------------------------------------------------------------------------
struct cache_server_file
{
  std::string fileDigest;
  std::string dataDigest;
  std::string param;

  ByteData    data;
  ByteData    icon;
};
//-------------------------------------------------------------------------
struct cache_server_info
{
  std::string message;

  IBPP::Database    base;
  IBPP::Transaction trans;
  IBPP::Statement   stRead;
  IBPP::Statement   stWrite;
  IBPP::Blob        dataBlob;
  IBPP::Blob        iconBlob;
  std::list<cache_server_file*> files;
};
//-------------------------------------------------------------------------
int CacheServer::_NewInstance(const char* basePath, int majorVer, int minorVer)
{
  cache_server_info* info = new cache_server_info;

  // проверим подсоединение базы
  info->base = IBPP::DatabaseFactory("", basePath, "sysdba", "masterkey");
  info->base->Connect();
  if (!info->base->Connected())
  {
    info->message = "не смогли подключится к файловому кэшу";
    return (int)info;
  }

  info->trans = IBPP::TransactionFactory(info->base, IBPP::amWrite, IBPP::ilReadCommitted, IBPP::lrNoWait);
  info->trans->Start();
  if (!info->trans->Started())
  {
    info->message = "не смогли запустить транзакцию файлогого кэша";
    return (int)info;
  }

  // если версия прописана, то проверим совпадение
  IBPP::Statement st = StatementFactory(info->base, info->trans);
  st->Execute("SELECT param_value FROM params WHERE param_key='version'");
  std::string version = std::string((LPCSTR)aux::itoa(majorVer)) + "." + std::string((LPCSTR)aux::itoa(minorVer));
  if (st->Fetch())
  {
    std::string res;
    st->Get(1, res);
    if (res != version)
    {
      info->message = "версия файлового кэша не совпадает с версией компаса";
      return (int)info;
    }
  }
  else // если там версии нет, то это пустышка, пропишем текущую версию
  {
    st->Prepare("INSERT INTO params (param_key, param_value) VALUES(?, ?)");
    st->Set(1, "version");
    st->Set(2, version);
    st->Execute();
  }

  info->dataBlob = IBPP::BlobFactory(info->base, info->trans);
  info->iconBlob = IBPP::BlobFactory(info->base, info->trans);

  info->stRead = StatementFactory(info->base, info->trans);
  info->stRead->Prepare("SELECT dataDigest, data, icon, param FROM files WHERE fileDigest = ?");

  info->stWrite = StatementFactory(info->base, info->trans);
  info->stWrite->Prepare("INSERT INTO files (fileDigest, dataDigest, data, icon,  param) VALUES(?, ?, ?, ?, ?)");

  return (int)info;
}
//-------------------------------------------------------------------------
bool CacheServer::_Write(int cacheServer, const char* fileDigest, CACHE_FILE_INFO* fileInfo)
{
  cache_server_info* info = (cache_server_info*)cacheServer;

  info->stWrite->Set(1, fileDigest);
  info->stWrite->Set(2, fileInfo->dataDigest);

  ByteData data;
  data.Attach((char*)fileInfo->data, fileInfo->dataLen);
  data.SaveToBlob(info->dataBlob);
  info->stWrite->Set(3, info->dataBlob);

  ByteData icon;
  icon.Attach((char*)fileInfo->icon, fileInfo->iconLen);
  icon.SaveToBlob(info->iconBlob);
  info->stWrite->Set(4, info->iconBlob);
  
  info->stWrite->Set(5, fileInfo->param);

  info->stWrite->Execute();
  return true;
}
//-------------------------------------------------------------------------
bool CacheServer::_Read(int cacheServer, const char* fileDigest, CACHE_FILE_INFO* fileInfo)
{
  cache_server_info* info = (cache_server_info*)cacheServer;

  info->stRead->Set(1, fileDigest);
  info->stRead->Execute();
  if (!info->stRead->Fetch())
    return false;

  cache_server_file* file = new cache_server_file;
  file->fileDigest = fileDigest;

  info->stRead->Get(1, file->dataDigest);

  info->stRead->Get(2, info->dataBlob);
  file->data.LoadFromBlob(info->dataBlob);

  info->stRead->Get(3, info->iconBlob);
  file->icon.LoadFromBlob(info->iconBlob);

  info->stRead->Get(4, file->param);
  info->files.push_back(file);

  fileInfo->fileDigest = file->fileDigest.c_str();
  fileInfo->dataDigest = file->dataDigest.c_str();
  fileInfo->data       = file->data.GetData();
  fileInfo->dataLen    = file->data.GetLength();
  fileInfo->icon       = file->icon.GetData();
  fileInfo->iconLen    = file->icon.GetLength();
  fileInfo->param      = file->param.c_str();

  return true;
}
//-------------------------------------------------------------------------
bool CacheServer::_Clear(int cacheServer)
{
  if (cache_server_info* info = (cache_server_info*)cacheServer)
  {
    for (auto it = info->files.begin(); it != info->files.end(); ++it)
      delete *it;
    info->files.clear();
    return true;
  }
  return false;
}
//-------------------------------------------------------------------------
bool CacheServer::_Quit(int cacheServer)
{
  _Clear(cacheServer);

  if (cache_server_info* info = (cache_server_info*)cacheServer)
  {
    if (info->base->Connected())
    {
      info->trans->Commit();
      info->base->Disconnect();
    }
    delete info;
    return true;
  }
  return false;
}
//-------------------------------------------------------------------------
const char* CacheServer::_Message(int cacheServer)
{
  if (cache_server_info* info = (cache_server_info*)cacheServer)
    return info->message.c_str();
  return "передан нулевой указатель на кэш";
}
