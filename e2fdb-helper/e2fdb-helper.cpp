// e2fdb-helper.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "e2fdb-helper.h"
#include <list>
#include "ibpp/ibpp.h"
#include "ByteData.h"
#include "aux_ext.h"
#include "CacheServer.h"
#include "KompasServer.h"


#define BEGIN_FUN try {
#define END_FUN } \
  catch (IBPP::Exception& ex) \
  { \
    OutputDebugStringA(ex.what()); \
    return false; \
  }

std::list<IBPP::Database>    glb_database;
std::list<IBPP::Transaction> glb_transaction;
std::list<IBPP::Statement>   glb_statement;
std::string                  glb_error;
//-------------------------------------------------------------------------
E2FDBHELPER_API const char* fdb_error()
{
  static std::string str;
  str = glb_error;
  glb_error.clear();
  return str.c_str();
}
/************************************************************************/
/*                               Provider                               */
/************************************************************************/
E2FDBHELPER_API int fdb_provider_open(const char* serverName, const char* baseName, const char* user, const char* password)
{
BEGIN_FUN
  IBPP::Database base = IBPP::DatabaseFactory(serverName, baseName, user, password);
  base->Connect();
  if (!base->Connected())
    return 0;
  glb_database.push_back(base);
  return (int)base.intf();
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_provider_close(int provider)
{
BEGIN_FUN
  if (!provider)
    return false;

  IBPP::Database base = (IBPP::IDatabase*)provider;
  if (base->Connected())
    base->Disconnect();
  glb_database.remove(base);
  return true;
END_FUN
}
/************************************************************************/
/*                             Transaction                              */
/************************************************************************/
E2FDBHELPER_API int fdb_transaction_open(int provider, int am, int il, int lr)
{
BEGIN_FUN
  if (!provider)
    return false;

  IBPP::Transaction trans = TransactionFactory((IBPP::IDatabase*)provider, (IBPP::TAM)am, (IBPP::TIL)il, (IBPP::TLR)lr);
  glb_transaction.push_back(trans);
  return (int)trans.intf();
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API int fdb_transaction_open2(int provider)
{
BEGIN_FUN
  return fdb_transaction_open(provider, 1, 2, 1);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_close(int trans)
{
BEGIN_FUN
  if (!trans)
    return false;

  IBPP::Transaction _trans = ((IBPP::ITransaction*)trans);
  glb_transaction.remove(_trans);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_start(int trans)
{
BEGIN_FUN
  if (!trans)
    return false;

  ((IBPP::ITransaction*)trans)->Start();
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_commit(int trans)
{
BEGIN_FUN
  if (!trans)
    return false;

  ((IBPP::ITransaction*)trans)->Commit();
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_rollback(int trans)
{
BEGIN_FUN
  if (!trans)
    return false;

  ((IBPP::ITransaction*)trans)->Rollback();
  return true;
END_FUN
}
/************************************************************************/
/*                        Statement                                     */
/************************************************************************/
E2FDBHELPER_API int fdb_statement_open(int provider, int trans)
{
BEGIN_FUN
  if (!provider || !trans)
    return false;

  IBPP::Database _prov = (IBPP::IDatabase*) provider;
  IBPP::Transaction _trans = (IBPP::ITransaction*)trans;

  IBPP::Statement st = StatementFactory(_prov, _trans);
  glb_statement.push_back(st);
  return (int)st.intf();
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_close(int st)
{
BEGIN_FUN
  if (!st)
    return false;

  glb_statement.remove((IBPP::IStatement*)st);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_prepare(int st, const char* query)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Prepare(query);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_execute(int st, const char* query)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Execute(query);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_execute_immediate(int st, const char* query)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->ExecuteImmediate(query);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_fetch(int st)
{
BEGIN_FUN
  if (!st)
    return false;

  return ((IBPP::IStatement*)st)->Fetch();
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_null(int st, int index)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->SetNull(index);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_int(int st, int index, int value)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Set(index, value);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_double(int st, int index, const double* value)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Set(index, *value);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_string(int st, int index, const char* value)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Set(index, value);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_blob_as_string(int st, int index, const char* value)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Set(index, std::string(value));
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_blob_as_file(int st, int index, const char* filePath)
{
BEGIN_FUN
  if (!st)
    return false;

  IBPP::Statement _st = (IBPP::IStatement*)st;
  IBPP::Blob blob = IBPP::BlobFactory(_st->DatabasePtr(), _st->TransactionPtr());

  ByteData data;
  data.LoadFromFile((LPCWSTR)aux::a2w(filePath));
  data.Compress();
  data.SaveToBlob(blob);
  _st->Set(index, blob);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_blob_as_data(int st, int index, char* data, int dataLen)
{
BEGIN_FUN
  if (!st)
    return false;

  IBPP::Statement _st = (IBPP::IStatement*)st;
  IBPP::Blob blob = IBPP::BlobFactory(_st->DatabasePtr(), _st->TransactionPtr());

  ByteData byteData;
  byteData.Attach(data, dataLen);
  byteData.SaveToBlob(blob);
  _st->Set(index, blob);

  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_is_null(int st, int index)
{
BEGIN_FUN
  if (!st)
    return false;

  return ((IBPP::IStatement*)st)->IsNull(index);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_int(int st, int index, int* value)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Get(index, value);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_double(int st, int index, double* value)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Get(index, value);
  return true;
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_string(int st, int index, char* value)
{
BEGIN_FUN
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Get(index, value);
  return true;
END_FUN
}

/************************************************************************/
/*                         cache server                                 */
/************************************************************************/
E2FDBHELPER_API int cache_server_init(const char* basePath, int majorVer, int minorVer)
{
BEGIN_FUN
  return CacheServer::_NewInstance(basePath, majorVer, minorVer);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool cache_server_write(int cacheServer, const char* digest, CACHE_FILE_INFO* fileInfo)
{
BEGIN_FUN
    return CacheServer::_Write(cacheServer, digest, fileInfo);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool cache_server_read(int cacheServer, const char* digest, CACHE_FILE_INFO* fileInfo)
{
BEGIN_FUN
    return CacheServer::_Read(cacheServer, digest, fileInfo);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API const char* cache_server_message(int cacheServer)
{
BEGIN_FUN
  return CacheServer::_Message(cacheServer);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool cache_server_clear(int cacheServer)
{
BEGIN_FUN
  return CacheServer::_Clear(cacheServer);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool cache_server_quit(int cacheServer)
{
BEGIN_FUN
  return CacheServer::_Quit(cacheServer);
END_FUN
}
/************************************************************************/
/*                         kompas server                                */
/************************************************************************/
E2FDBHELPER_API int kompas_server_init(int index, int majorVer, int minorVer)
{
BEGIN_FUN
  return KompasServer::_NewInstance(index, majorVer, minorVer);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API int kompas_server_file(int kompasServer, const char* fileName, bool isEngSys, CACHE_FILE_INFO* fileInfo)
{
BEGIN_FUN
  return KompasServer::_File(kompasServer, fileName, isEngSys, fileInfo);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API const char* kompas_server_message(int kompasServer)
{
BEGIN_FUN
  return KompasServer::_Message(kompasServer);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API int kompas_server_clear(int kompasServer)
{
BEGIN_FUN
  return KompasServer::_Clear(kompasServer);
END_FUN
}
//-------------------------------------------------------------------------
E2FDBHELPER_API int kompas_server_quit(int kompasServer)
{
BEGIN_FUN
  return KompasServer::_Quit(kompasServer);
END_FUN
}
