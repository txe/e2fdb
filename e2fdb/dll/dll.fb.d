module dll.fb;
import std.c.windows.windows;


alias extern(Windows) const(char*) function() fdb_error_fp;

alias extern(Windows) int  function(const char* serverName, const char* baseName, const char* user, const char* password) fdb_provider_open_fp;
alias extern(Windows) bool function(int provider) fdb_provider_close_fp;

alias extern(Windows) int  function(int provider, int am, int il, int lr) fdb_transaction_open_fp;
alias extern(Windows) int  function(int prov)  fdb_transaction_open2_fp;
alias extern(Windows) bool function(int trans) fdb_transaction_close_fp;
alias extern(Windows) bool function(int trans) fdb_transaction_start_fp;
alias extern(Windows) bool function(int trans) fdb_transaction_commit_fp;
alias extern(Windows) bool function(int trans) fdb_transaction_rollback_fp;

alias extern(Windows) int  function(int provider, int trans) fdb_statement_open_fp;
alias extern(Windows) bool function(int st) fdb_statement_close_fp;

alias extern(Windows) bool function(int st, const char* query) fdb_statement_prepare_fp;
alias extern(Windows) bool function(int st, const char* query) fdb_statement_execute_fp;
alias extern(Windows) bool function(int st, const char* query) fdb_statement_execute_immediate_fp;
alias extern(Windows) bool function(int st) fdb_statement_fetch_fp;

alias extern(Windows) bool function(int st, int index) fdb_statement_set_null_fp;
alias extern(Windows) bool function(int st, int index, int Value) fdb_statement_set_int_fp;
alias extern(Windows) bool function(int st, int index, const double* value) fdb_statement_set_double_fp;
alias extern(Windows) bool function(int st, int index, const char* value) fdb_statement_set_string_fp;
alias extern(Windows) bool function(int st, int index, const char* value) fdb_statement_set_blob_as_string_fp;
alias extern(Windows) bool function(int st, int index, const char* filePath) fdb_statement_set_blob_as_file_fp;
alias extern(Windows) bool function(int st, int index, char* data, int dataLen) fdb_statement_set_blob_as_data_fp;

alias extern(Windows) bool function(int st, int index) fdb_statement_get_is_null_fp;
alias extern(Windows) bool function(int st, int index, int* value) fdb_statement_get_int_fp;
alias extern(Windows) bool function(int st, int index, double* value) fdb_statement_get_double_fp;
alias extern(Windows) bool function(int st, int index, char* value) fdb_statement_get_string_fp;

struct fbDll
{
public:
  HMODULE _module;

  fdb_error_fp fdb_error;

  fdb_provider_open_fp fdb_provider_open;
  fdb_provider_close_fp fdb_provider_close;

  fdb_transaction_open_fp  fdb_transaction_open;
  fdb_transaction_open2_fp fdb_transaction_open2;
  fdb_transaction_close_fp fdb_transaction_close;
  fdb_transaction_start_fp fdb_transaction_start;
  fdb_transaction_commit_fp fdb_transaction_commit;
  fdb_transaction_rollback_fp fdb_transaction_rollback;

  fdb_statement_open_fp fdb_statement_open;
  fdb_statement_close_fp fdb_statement_close;

  fdb_statement_prepare_fp fdb_statement_prepare;
  fdb_statement_execute_fp fdb_statement_execute;
  fdb_statement_execute_immediate_fp fdb_statement_execute_immediate;
  fdb_statement_fetch_fp fdb_statement_fetch;

  fdb_statement_set_null_fp fdb_statement_set_null;
  fdb_statement_set_int_fp fdb_statement_set_int;
  fdb_statement_set_double_fp fdb_statement_set_double;
  fdb_statement_set_string_fp fdb_statement_set_string;
  fdb_statement_set_blob_as_string_fp fdb_statement_set_blob_as_string;
  fdb_statement_set_blob_as_file_fp fdb_statement_set_blob_as_file;
  fdb_statement_set_blob_as_data_fp fdb_statement_set_blob_as_data;

  fdb_statement_get_is_null_fp fdb_statement_get_is_null;
  fdb_statement_get_int_fp fdb_statement_get_int;
  fdb_statement_get_double_fp fdb_statement_get_double;
  fdb_statement_get_string_fp fdb_statement_get_string;

  void Load()
  {
    if (_module != null)
      return;

    _module = LoadLibraryA("e2fdb-helper.dll");
    if (_module == null)  throw new Exception("fbDll._module == null");

    fdb_error = cast(fdb_error_fp) GetProcAddress(_module, "fdb_error");
    if (fdb_error == null) throw new Exception("fdb_error == null");

    fdb_provider_open = cast(fdb_provider_open_fp) GetProcAddress(_module, "fdb_provider_open");
    if (fdb_provider_open == null) throw new Exception("fdb_provider_open == null");
    fdb_provider_close = cast(fdb_provider_close_fp) GetProcAddress(_module, "fdb_provider_close");
    if (fdb_provider_close == null) throw new Exception("fdb_provider_close == null");

    fdb_transaction_open = cast(fdb_transaction_open_fp) GetProcAddress(_module, "fdb_transaction_open");
    if (fdb_transaction_open == null) throw new Exception("fdb_transaction_open == null");
    fdb_transaction_open2 = cast(fdb_transaction_open2_fp) GetProcAddress(_module, "fdb_transaction_open2");
    if (fdb_transaction_open2 == null) throw new Exception("fdb_transaction_open2 == null");
    fdb_transaction_close = cast(fdb_transaction_close_fp) GetProcAddress(_module, "fdb_transaction_close");
    if (fdb_transaction_close == null) throw new Exception("fdb_transaction_close == null");
    fdb_transaction_start = cast(fdb_transaction_start_fp) GetProcAddress(_module, "fdb_transaction_start");
    if (fdb_transaction_start == null) throw new Exception("fdb_transaction_start == null");
    fdb_transaction_commit = cast(fdb_transaction_commit_fp) GetProcAddress(_module, "fdb_transaction_commit");
    if (fdb_transaction_commit == null) throw new Exception("fdb_transaction_commit == null");
    fdb_transaction_rollback = cast(fdb_transaction_rollback_fp) GetProcAddress(_module, "fdb_transaction_rollback");
    if (fdb_transaction_rollback == null) throw new Exception("fdb_transaction_rollback == null");

    fdb_statement_open = cast(fdb_statement_open_fp) GetProcAddress(_module, "fdb_statement_open");
    if (fdb_statement_open == null) throw new Exception("fdb_statement_open == null");
    fdb_statement_close = cast(fdb_statement_close_fp) GetProcAddress(_module, "fdb_statement_close");
    if (fdb_statement_close == null) throw new Exception("fdb_statement_close == null");

    fdb_statement_prepare = cast(fdb_statement_prepare_fp) GetProcAddress(_module, "fdb_statement_prepare");
    if (fdb_statement_prepare == null) throw new Exception("fdb_statement_prepare == null");
    fdb_statement_execute = cast(fdb_statement_execute_fp) GetProcAddress(_module, "fdb_statement_execute");
    if (fdb_statement_execute == null) throw new Exception("fdb_statement_execute == null");
    fdb_statement_execute_immediate = cast(fdb_statement_execute_immediate_fp) GetProcAddress(_module, "fdb_statement_execute_immediate");
    if (fdb_statement_execute_immediate == null) throw new Exception("fdb_statement_execute_immediate == null");
    fdb_statement_fetch = cast(fdb_statement_fetch_fp) GetProcAddress(_module, "fdb_statement_fetch");
    if (fdb_statement_fetch == null) throw new Exception("fdb_statement_fetch == null");

    fdb_statement_set_null = cast(fdb_statement_set_null_fp) GetProcAddress(_module, "fdb_statement_set_null");
    if (fdb_statement_set_null == null) throw new Exception("fdb_statement_set_null == null");
    fdb_statement_set_int = cast(fdb_statement_set_int_fp) GetProcAddress(_module, "fdb_statement_set_int");
    if (fdb_statement_set_int == null) throw new Exception("fdb_statement_set_int == null");
    fdb_statement_set_double = cast(fdb_statement_set_double_fp) GetProcAddress(_module, "fdb_statement_set_double");
    if (fdb_statement_set_double == null) throw new Exception("fdb_statement_set_double == null");
    fdb_statement_set_string = cast(fdb_statement_set_string_fp) GetProcAddress(_module, "fdb_statement_set_string");
    if (fdb_statement_set_string == null) throw new Exception("fdb_statement_set_string == null");
    fdb_statement_set_blob_as_string = cast(fdb_statement_set_blob_as_string_fp) GetProcAddress(_module, "fdb_statement_set_blob_as_string");
    if (fdb_statement_set_blob_as_string == null) throw new Exception("fdb_statement_set_blob_as_string == null");
    fdb_statement_set_blob_as_file = cast(fdb_statement_set_blob_as_file_fp) GetProcAddress(_module, "fdb_statement_set_blob_as_file");
    if (fdb_statement_set_blob_as_file == null) throw new Exception("fdb_statement_set_blob_as_file == null");
    fdb_statement_set_blob_as_data = cast(fdb_statement_set_blob_as_data_fp) GetProcAddress(_module, "fdb_statement_set_blob_as_data");
    if (fdb_statement_set_blob_as_data == null) throw new Exception("fdb_statement_set_blob_as_data == null");

    fdb_statement_get_is_null = cast(fdb_statement_get_is_null_fp) GetProcAddress(_module, "fdb_statement_get_is_null");
    if (fdb_statement_get_is_null == null) throw new Exception("fdb_statement_get_is_null == null");
    fdb_statement_get_int = cast(fdb_statement_get_int_fp) GetProcAddress(_module, "fdb_statement_get_int");
    if (fdb_statement_get_int == null) throw new Exception("fdb_statement_get_int == null");
    fdb_statement_get_double = cast(fdb_statement_get_double_fp) GetProcAddress(_module, "fdb_statement_get_double");
    if (fdb_statement_get_double == null) throw new Exception("fdb_statement_get_double == null");
    fdb_statement_get_string = cast(fdb_statement_get_string_fp) GetProcAddress(_module, "fdb_statement_get_string");
    if (fdb_statement_get_string == null) throw new Exception("fdb_statement_get_string == null");
  }

  void Free()
  {
    FreeLibrary(_module);
    _module = null;
  }

}