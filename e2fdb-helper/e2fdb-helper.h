#pragma  once

// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the E2FDBHELPER_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// E2FDBHELPER_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef E2FDBHELPER_EXPORTS
#define E2FDBHELPER_API extern "C" __declspec(dllexport)
#else
#define E2FDBHELPER_API extern "C" __declspec(dllimport)
#endif


E2FDBHELPER_API const char* fdb_error();

E2FDBHELPER_API int  fdb_provider_open(const char* serverName, const char* baseName, const char* user, const char* password);
E2FDBHELPER_API bool fdb_provider_close(int provider);

E2FDBHELPER_API int  fdb_transaction_open(int provider, int am, int il, int lr);
E2FDBHELPER_API int  fdb_transaction_open2(int provider);
E2FDBHELPER_API bool fdb_transaction_close(int trans);
E2FDBHELPER_API bool fdb_transaction_start(int trans);
E2FDBHELPER_API bool fdb_transaction_commit(int trans);
E2FDBHELPER_API bool fdb_transaction_rollback(int trans);

E2FDBHELPER_API int  fdb_statement_open(int provider, int trans);
E2FDBHELPER_API bool fdb_statement_close(int st);

E2FDBHELPER_API bool fdb_statement_prepare(int st, const char* query);
E2FDBHELPER_API bool fdb_statement_execute(int st, const char* query);
E2FDBHELPER_API bool fdb_statement_execute_immediate(int st, const char* query);
E2FDBHELPER_API bool fdb_statement_fetch(int st);

E2FDBHELPER_API bool fdb_statement_set_null(int st, int index);
E2FDBHELPER_API bool fdb_statement_set_int(int st, int index, int value);
E2FDBHELPER_API bool fdb_statement_set_double(int st, int index, const double* value);
E2FDBHELPER_API bool fdb_statement_set_string(int st, int index, const char* value);
E2FDBHELPER_API bool fdb_statement_set_blob_as_string(int st, int index, const char* value);
E2FDBHELPER_API bool fdb_statement_set_blob_as_file(int st, int index, const char* filePath);
E2FDBHELPER_API bool fdb_statement_set_blob_as_data(int st, int index, char* data, int dataLen);


E2FDBHELPER_API bool fdb_statement_get_is_null(int st, int index);
E2FDBHELPER_API bool fdb_statement_get_int(int st, int index, int* value);
E2FDBHELPER_API bool fdb_statement_get_double(int st, int index, double* value);
E2FDBHELPER_API bool fdb_statement_get_string(int st, int index, char* value);

/************************************************************************/
/*                                                                      */
/************************************************************************/
struct CACHE_FILE_INFO
{
  const char*  fileDigest;
  const char*  dataDigest;
  const char*  param;

  const char*  data;
  int          dataLen;
  const char*  icon;
  int          iconLen;
};
/************************************************************************/
/*                         cache server                                 */
/************************************************************************/
E2FDBHELPER_API int         cache_server_init(const char* basePath, int majorVer, int minorVer);
E2FDBHELPER_API bool        cache_server_write(int cacheServer, const char* digest, CACHE_FILE_INFO* fileInfo);
E2FDBHELPER_API bool        cache_server_read(int cacheServer, const char* digest, CACHE_FILE_INFO* fileInfo);
E2FDBHELPER_API const char* cache_server_message(int cacheServer);
E2FDBHELPER_API bool        cache_server_clear(int cacheServer);
E2FDBHELPER_API bool        cache_server_quit(int cacheServer);
/************************************************************************/
/*                         kompas server                                */
/************************************************************************/
E2FDBHELPER_API int         kompas_server_init(int index, int majorVer, int minorVer);
E2FDBHELPER_API bool         kompas_server_file(int kompasServer, const char* fileName, bool isEngSys, CACHE_FILE_INFO* fileInfo);
E2FDBHELPER_API const char* kompas_server_message(int kompasServer);
E2FDBHELPER_API bool         kompas_server_clear(int kompasServer);
E2FDBHELPER_API bool         kompas_server_quit(int kompasServer);

