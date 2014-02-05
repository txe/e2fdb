module fdb.fdbConnect;
private import helper.fb;
private import std.conv;
private import std.string;


struct FdbConnect
{
  private helper.fb.fbDll _dll;
  private int             _provider;

  bool Connect(string server, string basePath, string user, string password)
  {
    _dll.Load("e2fdb-helper.dll");
    _provider = _dll.fdb_provider_open(server.toStringz, basePath.toStringz, user.toStringz, password.toStringz);
    return _provider > 0;
  }

  void Disconnect()
  {
    _dll.fdb_provider_close(_provider);
    _provider = 0;
    _dll.Free();
  }

  FdbTransaction OpenTransaction(FdbTransaction.TAM am, FdbTransaction.TIL il, FdbTransaction.TLR lr)
  {
    int tran = _dll.fdb_transaction_open(_provider, am, il, lr);
    return new FdbTransaction(_dll, tran);
  }

  FdbStatement OpenStatement(FdbTransaction transaction)
  {
    int st = _dll.fdb_statement_open(_provider, transaction._tran);
    return new FdbStatement(_dll, st);
  }
}

class FdbTransaction
{
  private helper.fb.fbDll _dll;
  int _tran;

  enum TAM {amWrite, amRead};
  enum TIL {ilConcurrency, ilReadDirty, ilReadCommitted, ilConsistency};
  enum TLR {lrWait, lrNoWait};

  this(fbDll dll, int tran)
  {
    _dll = dll;
    _tran = tran;
  }

  bool Start()    { return _dll.fdb_transaction_start(_tran); }
  bool Close()    { return _dll.fdb_transaction_close(_tran); }
  bool Commit()   { return _dll.fdb_transaction_commit(_tran); }
  bool Rollback() { return _dll.fdb_transaction_rollback(_tran); }
}

class FdbStatement
{
  private helper.fb.fbDll _dll;
  private int _st;

  this(fbDll dll, int st)
  {
    _dll = dll;
    _st = st;
  }

  ~this() { _dll.fdb_statement_close(_st); }

  bool Prepare(string query)
  { 
    return _dll.fdb_statement_prepare(_st, query.ptr);
  }
  bool Execute(string query)
  {
    return _dll.fdb_statement_execute(_st, query.ptr);
  }
  bool ExecuteImmediate(string query)
  {
    return _dll.fdb_statement_execute_immediate(_st, query.ptr);
  }
  bool Fetch()
  {
    return _dll.fdb_statement_fetch(_st);
  }

  bool SetNull(int index)
  { 
    return _dll.fdb_statement_set_null(_st, index);
  }
  bool SetInt(int index, int val)
  { 
    return _dll.fdb_statement_set_int(_st, index, val);
  }
  bool SetDouble(int index, ref double val)
  { 
    return _dll.fdb_statement_set_double(_st, index, &val);
  }
  bool SetString(int index, string val)
  {
    return _dll.fdb_statement_set_string(_st, index, val.ptr); 
  }

  bool IsNull(int index)
  { 
    return _dll.fdb_statement_get_is_null(_st, index);
  }
  int GetInt(int index)
  {
    int val;
    _dll.fdb_statement_get_int(_st, index, &val);
    return val;
  }
  double GetDouble(int index)
  {
    double val;
    _dll.fdb_statement_get_double(_st, index, &val);
    return val;
  }
  string GetString(int index)
  {
    char[255] val;
    _dll.fdb_statement_get_string(_st, index, val.ptr);
    return to!string(val);
  }

}