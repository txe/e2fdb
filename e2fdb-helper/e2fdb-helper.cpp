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
E2FDBHELPER_API intptr_t fdb_provider_open(const char* serverName, const char* baseName, const char* user, const char* password)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_provider_close(intptr_t provider)
{
  return false;
}
/************************************************************************/
/*                             Transaction                              */
/************************************************************************/
E2FDBHELPER_API intptr_t fdb_transaction_open(intptr_t provider)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_close(intptr_t trans)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_start(intptr_t trans)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_commit(intptr_t trans)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_rollback(intptr_t trans)
{
  return 0;
}
/************************************************************************/
/*                        Statement                                     */
/************************************************************************/
E2FDBHELPER_API intptr_t fdb_statement_open(intptr_t provider, intptr_t trans)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_close(intptr_t st)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_prepare(intptr_t st, const char* query)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_execute(intptr_t st, const char* query)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_execute_immediate(intptr_t st, const char* query)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_fetch(intptr_t st)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_null(intptr_t st, int index)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_int(intptr_t st, int index, int Value)
{
  return 0;
}
E2FDBHELPER_API bool fdb_statement_set_double(intptr_t st, int index, const double* value)
{
  return 0;
}
E2FDBHELPER_API bool fdb_statement_set_string(intptr_t st, int index, const char* value)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_is_null(intptr_t st, int index)
{
  return 0;
}
E2FDBHELPER_API bool fdb_statement_get_int(intptr_t st, int index, int* value)
{
  return 0;
}
E2FDBHELPER_API bool fdb_statement_get_double(intptr_t st, int index, double* value)
{
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_string(intptr_t st, int index, char* value)
{
  return 0;
}