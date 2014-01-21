// e2fdb-helper.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "e2fdb-helper.h"

//-------------------------------------------------------------------------
E2FDBHELPER_API const char* fdb_error()
{
  return "";
}
/************************************************************************/
/*                               Provider                               */
/************************************************************************/
E2FDBHELPER_API int fdb_provider_open(const char* serverName, const char* baseName, const char* user, const char* password)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_provider_close(int provider)
{
  return false;
}
/************************************************************************/
/*                             Transaction                              */
/************************************************************************/
E2FDBHELPER_API int fdb_transaction_open(int provider)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_close(int trans)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_start(int trans)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_commit(int trans)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_rollback(int trans)
{
  return 0;
}
/************************************************************************/
/*                        Statement                                     */
/************************************************************************/
E2FDBHELPER_API int fdb_statement_open(int provider, int trans)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_close(int st)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_prepare(int st, const char* query)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_execute(int st, const char* query)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_execute_immediate(int st, const char* query)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_fetch(int st)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_null(int st, int index)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_int(int st, int index, int Value)
{
  return 0;
}
E2FDBHELPER_API bool fdb_statement_set_double(int st, int index, const double* value)
{
  return 0;
}
E2FDBHELPER_API bool fdb_statement_set_string(int st, int index, const char* value)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_is_null(int st, int index)
{
  return 0;
}
E2FDBHELPER_API bool fdb_statement_get_int(int st, int index, int* value)
{
  return 0;
}
E2FDBHELPER_API bool fdb_statement_get_double(int st, int index, double* value)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_string(int st, int index, char* value)
{
  return 0;
}