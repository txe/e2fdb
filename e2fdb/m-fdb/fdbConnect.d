module fdb.fdbConnect;
private import helper.fb;
private import std.conv;
private import std.string;
private import std.c.windows.windows;
private import utils;


class FdbConnect
{
  public  fbDll _dll;
  private int   _provider;

  ~this()
  {
    _dll.Free();
  }

  bool Connect(string basePath, string user, string password)
  {
    _dll.Load("e2fdb-helper.dll");
    _provider = _dll.fdb_provider_open("".toStringz, basePath.toStringz, user.toStringz, password.toStringz);
    return _provider > 0;
  }

  void Disconnect()
  {
    _dll.fdb_provider_close(_provider);
    _provider = 0;
  }

  FdbTransaction OpenTransaction(FdbTransaction.TAM am, FdbTransaction.TIL il, FdbTransaction.TLR lr)
  {
    int tran = _dll.fdb_transaction_open(_provider, am, il, lr);
    if (tran == 0)
      return null;
    return new FdbTransaction(this, tran);
  }

  FdbStatementRef OpenStatement(FdbTransaction transaction)
  {
    int st = _dll.fdb_statement_open(_provider, transaction._tran);
    return FdbStatementRef(this, st);
  }
}

class FdbTransaction
{
  private FdbConnect _connect;
  int _tran;

  enum TAM {amWrite, amRead};
  enum TIL {ilConcurrency, ilReadDirty, ilReadCommitted, ilConsistency};
  enum TLR {lrWait, lrNoWait};

  this(FdbConnect connect, int tran)
  {
    _connect = connect;
    _tran = tran;
  }

  bool Start()    { return _connect._dll.fdb_transaction_start(_tran); }
  bool Close()    { return _connect._dll.fdb_transaction_close(_tran); }
  bool Commit()   { return _connect._dll.fdb_transaction_commit(_tran); }
  bool Rollback() { return _connect._dll.fdb_transaction_rollback(_tran); }
}

struct FdbStatementRef
{
  FdbConnect _connect;
  int _st;

  this(FdbConnect connect, int st)
  {
    _st = st;
    _connect = connect;
  }
}

struct FdbStatement
{
  private FdbConnect _connect;
  private int _st;

  this(FdbStatementRef r)
  {
    _st = r._st;
    _connect = r._connect;
  }

  ~this() { _connect._dll.fdb_statement_close(_st); }

  ref FdbStatement Prepare(string query)
  { 
    if (!_connect._dll.fdb_statement_prepare(_st, query.toStringz))
      throw new Exception("CONNECT: failed fdb_statement_prepare");
    return this;
  }
  ref FdbStatement Execute(string query = "")
  {
    if (!_connect._dll.fdb_statement_execute(_st, query.toStringz))
      throw new Exception("CONNECT: failed fdb_statement_execute");
    return this;
  }
  ref FdbStatement ExecuteImmediate(string query)
  {
    _connect._dll.fdb_statement_execute_immediate(_st, query.toStringz);
    return this;
  }
  bool Fetch()
  {
    return _connect._dll.fdb_statement_fetch(_st);
  }

  ref FdbStatement SetNull(int index)
  { 
    _connect._dll.fdb_statement_set_null(_st, index);
    return this;
  }
  ref FdbStatement Set(int index, int val)
  { 
    _connect._dll.fdb_statement_set_int(_st, index, val);
    return this;
  }
  ref FdbStatement Set(int index, double val)
  { 
    _connect._dll.fdb_statement_set_double(_st, index, &val);
    return this;
  }
  ref FdbStatement Set(int index, string val)
  {
    _connect._dll.fdb_statement_set_string(_st, index, val.toStringz);
    return this;
  }
  ref FdbStatement Set(int index, wstring val)
  {
    auto val2 = toAnsii(val, 1251);
    _connect._dll.fdb_statement_set_string(_st, index, val2.toStringz);
    return this;
  }
  ref FdbStatement SetBlobAsString(int index, string val)
  {
    _connect._dll.fdb_statement_set_blob_as_string(_st, index, val.toStringz);
    return this;
  }
  ref FdbStatement SetBlobAsFile(int index, wstring fileName)
  {
    auto val2 = toAnsii(fileName, 1251);
    _connect._dll.fdb_statement_set_blob_as_string(_st, index, val2.toStringz);
    return this;
  }

  bool IsNull(int index)
  { 
    return _connect._dll.fdb_statement_get_is_null(_st, index);
  }
  int GetInt(int index)
  {
    int val;
    _connect._dll.fdb_statement_get_int(_st, index, &val);
    return val;
  }
  double GetDouble(int index)
  {
    double val;
    _connect._dll.fdb_statement_get_double(_st, index, &val);
    return val;
  }
  string GetString(int index)
  {
    char[255] val;
    _connect._dll.fdb_statement_get_string(_st, index, val.ptr);
    return to!string(val);
  }

}