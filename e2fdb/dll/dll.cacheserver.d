module dll.cacheserver;
import std.c.windows.windows;

alias extern(Windows) int          function(const char* basePath, int majorVer, int minorVer) cache_server_init_fp;
alias extern(Windows) bool         function(int cacheServer, const char* digest, void* fileInfo) cache_server_write_fp;
alias extern(Windows) bool         function(int cacheServer, const char* digest, void* fileInfo) cache_server_read_fp;
alias extern(Windows) const(char*) function(int cacheServer) cache_server_message_fp;
alias extern(Windows) bool         function(int cacheServer) cache_server_clear_fp;
alias extern(Windows) bool         function(int cacheServer) cache_server_quit_fp;

struct CacheServerDll
{
public:
  HMODULE _module;

  cache_server_init_fp    cache_server_init;
  cache_server_write_fp   cache_server_write;
  cache_server_read_fp    cache_server_read;
  cache_server_message_fp cache_server_message;
  cache_server_clear_fp   cache_server_clear;
  cache_server_quit_fp    cache_server_quit;

  void Load()
  {
    if (_module != null)
      return;

    _module = LoadLibraryA("e2fdb-helper.dll");
    if (_module == null)  throw new Exception("fbDll._module == null");

    cache_server_init = cast(cache_server_init_fp) GetProcAddress(_module, "cache_server_init");
    if (cache_server_init == null)
      throw new Exception("cache_server_init == null");
    
    cache_server_write = cast(cache_server_write_fp) GetProcAddress(_module, "cache_server_write");
    if (cache_server_write == null)
      throw new Exception("cache_server_write == null");
    
    cache_server_read = cast(cache_server_read_fp) GetProcAddress(_module, "cache_server_read");
    if (cache_server_read == null)
      throw new Exception("cache_server_read == null");
    
    cache_server_message = cast(cache_server_message_fp) GetProcAddress(_module, "cache_server_message");
    if (cache_server_message == null)
      throw new Exception("cache_server_message == null");

    cache_server_clear = cast(cache_server_clear_fp) GetProcAddress(_module, "cache_server_clear");
    if (cache_server_clear == null)
      throw new Exception("cache_server_clear == null");

    cache_server_quit = cast(cache_server_quit_fp) GetProcAddress(_module, "cache_server_quit");
    if (cache_server_quit == null)
      throw new Exception("cache_server_quit == null");
  }

  void Free()
  {
    FreeLibrary(_module);
    _module = null;
  }
}