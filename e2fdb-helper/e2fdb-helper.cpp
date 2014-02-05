// e2fdb-helper.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "e2fdb-helper.h"
#include <list>
#include "ibpp/ibpp.h"

std::list<IBPP::Database>    glb_database;
std::list<IBPP::Transaction> glb_transaction;
std::list<IBPP::Statement>   glb_statement;
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
  try
  {
    IBPP::Database base = IBPP::DatabaseFactory(serverName, baseName, user, password);
    base->Connect();
    if (!base->Connected())
      return 0;
    glb_database.push_back(base);
    return (int)base.intf();
  }
  catch (...)
  {
  }
  return 0;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_provider_close(int provider)
{
  if (!provider)
    return false;

  IBPP::Database base = (IBPP::IDatabase*)provider;
  glb_database.remove(base);
  return true;
}
/************************************************************************/
/*                             Transaction                              */
/************************************************************************/
E2FDBHELPER_API int fdb_transaction_open(int provider, int am, int il, int lr)
{
  if (!provider)
    return false;

  IBPP::Transaction trans = TransactionFactory((IBPP::IDatabase*)provider, (IBPP::TAM)am, (IBPP::TIL)il, (IBPP::TLR)lr);
  glb_transaction.push_back(trans);
  return (int)trans.intf();
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_close(int trans)
{
  if (!trans)
    return false;

  IBPP::Transaction _trans = (IBPP::ITransaction*)trans;
  glb_transaction.remove(_trans);
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_start(int trans)
{
  if (!trans)
    return false;

  ((IBPP::ITransaction*)trans)->Start();
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_commit(int trans)
{
  if (!trans)
    return false;

  ((IBPP::ITransaction*)trans)->Commit();
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_transaction_rollback(int trans)
{
  if (!trans)
    return false;

  ((IBPP::ITransaction*)trans)->Rollback();
  return true;
}
/************************************************************************/
/*                        Statement                                     */
/************************************************************************/
E2FDBHELPER_API int fdb_statement_open(int provider, int trans)
{
  if (!provider || !trans)
    return false;

  IBPP::Database _prov = (IBPP::IDatabase*) provider;
  IBPP::Transaction _trans = (IBPP::ITransaction*)trans;

  IBPP::Statement st = StatementFactory(_prov, _trans);
  glb_statement.push_back(st);
  return (int)st.intf();
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_close(int st)
{
  if (!st)
    return false;

  glb_statement.remove((IBPP::IStatement*)st);
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_prepare(int st, const char* query)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Prepare(query);
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_execute(int st, const char* query)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Execute(query);
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_execute_immediate(int st, const char* query)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->ExecuteImmediate(query);
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_fetch(int st)
{
  if (!st)
    return false;

  return ((IBPP::IStatement*)st)->Fetch();
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_null(int st, int index)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->SetNull(index);
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_set_int(int st, int index, int value)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Set(index, value);
  return true;
}
E2FDBHELPER_API bool fdb_statement_set_double(int st, int index, const double* value)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Set(index, *value);
  return true;
}
E2FDBHELPER_API bool fdb_statement_set_string(int st, int index, const char* value)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Set(index, value);
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_is_null(int st, int index)
{
  if (!st)
    return false;

  return ((IBPP::IStatement*)st)->IsNull(index);
}
E2FDBHELPER_API bool fdb_statement_get_int(int st, int index, int* value)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Get(index, value);
  return true;
}
E2FDBHELPER_API bool fdb_statement_get_double(int st, int index, double* value)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Get(index, value);
  return true;
}
//-------------------------------------------------------------------------
E2FDBHELPER_API bool fdb_statement_get_string(int st, int index, char* value)
{
  if (!st)
    return false;

  ((IBPP::IStatement*)st)->Get(index, value);
  return true;
}