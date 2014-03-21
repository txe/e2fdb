module helper.kompas;
import std.c.windows.windows;

alias extern(Windows) int  function(const char* cacheDb, int majorVer, int minorVer) kompas_cache_init_fp;
alias extern(Windows) void function(int cache) kompas_cache_stop_fp;
alias extern(Windows) void function(int cache) kompas_cache_clear_temp_fp;
alias extern(Windows) bool function(int cache, const char* digest, const char* fromFile, bool isEngSys, char** data, int* dataLen, char** crc, int* crcLen, char** icon, int* iconLen) kompas_cache_file_info_fp;
alias extern(Windows) const(char*) function() kompas_cache_error_fp;

struct kompasDll
{
public:
  HMODULE _module;

  kompas_cache_init_fp       kompas_cache_init;
  kompas_cache_stop_fp       kompas_cache_stop;
  kompas_cache_clear_temp_fp kompas_cache_clear_temp;
  kompas_cache_file_info_fp  kompas_cache_file_info;
  kompas_cache_error_fp      kompas_cache_error;

  void Load()
  {
    if (_module != null)
      return;

    _module = LoadLibraryA("e2fdb-helper.dll");
    if (_module == null)  throw new Exception("fbDll._module == null");

    kompas_cache_init = cast(kompas_cache_init_fp) GetProcAddress(_module, "kompas_cache_init");
    if (kompas_cache_init == null)
      throw new Exception("kompas_cache_init == null");
    
    kompas_cache_stop = cast(kompas_cache_stop_fp) GetProcAddress(_module, "kompas_cache_stop");
    if (kompas_cache_stop == null)
      throw new Exception("kompas_cache_stop == null");
    
    kompas_cache_clear_temp = cast(kompas_cache_clear_temp_fp) GetProcAddress(_module, "kompas_cache_clear_temp");
    if (kompas_cache_clear_temp == null)
      throw new Exception("kompas_cache_clear_temp == null");
    
    kompas_cache_file_info = cast(kompas_cache_file_info_fp) GetProcAddress(_module, "kompas_cache_file_info");
    if (kompas_cache_file_info == null)
      throw new Exception("kompas_cache_file_info == null");

    kompas_cache_error = cast(kompas_cache_error_fp) GetProcAddress(_module, "kompas_cache_error");
    if (kompas_cache_error == null)
      throw new Exception("kompas_cache_error == null");
  }

  void Free()
  {
    FreeLibrary(_module);
    _module = null;
  }
}