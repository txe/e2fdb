module dll.kompasserver;
import std.c.windows.windows;

alias extern(Windows) int          function(int index, int majorVer, int minorVer) kompas_server_init_fp;
alias extern(Windows) bool         function(int kompasServer, const char* fileName, bool isEngSys, void* fileInfo) kompas_server_file_fp;
alias extern(Windows) const(char*) function(int kompasServer) kompas_server_message_fp;
alias extern(Windows) bool         function(int kompasServer) kompas_server_clear_fp;
alias extern(Windows) bool         function(int kompasServer) kompas_server_quit_fp;

struct KompasServerDll
{
public:
  HMODULE _module;

  kompas_server_init_fp    kompas_server_init;
  kompas_server_file_fp    kompas_server_file;
  kompas_server_message_fp kompas_server_message;
  kompas_server_clear_fp   kompas_server_clear;
  kompas_server_quit_fp    kompas_server_quit;

  void Load()
  {
    if (_module != null)
      return;

    _module = LoadLibraryA("e2fdb-helper.dll");
    if (_module == null)  throw new Exception("fbDll._module == null");

    kompas_server_init = cast(kompas_server_init_fp) GetProcAddress(_module, "kompas_server_init");
    if (kompas_server_init == null)
      throw new Exception("kompas_server_init == null");
    
    kompas_server_file = cast(kompas_server_file_fp) GetProcAddress(_module, "kompas_server_file");
    if (kompas_server_file == null)
      throw new Exception("kompas_server_file == null");
    
    kompas_server_message = cast(kompas_server_message_fp) GetProcAddress(_module, "kompas_server_message");
    if (kompas_server_message == null)
      throw new Exception("kompas_server_message == null");
    
    kompas_server_clear = cast(kompas_server_clear_fp) GetProcAddress(_module, "kompas_server_clear");
    if (kompas_server_clear == null)
      throw new Exception("kompas_server_clear == null");

    kompas_server_quit = cast(kompas_server_quit_fp) GetProcAddress(_module, "kompas_server_quit");
    if (kompas_server_quit == null)
      throw new Exception("kompas_server_quit == null");
  }

  void Free()
  {
    FreeLibrary(_module);
    _module = null;
  }
}