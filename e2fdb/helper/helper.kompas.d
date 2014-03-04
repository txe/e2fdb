module helper.kompas;
import std.c.windows.windows;

alias extern(Windows) int function(int* major, int* minor) kompas_start_fp;
alias extern(Windows) bool function(int kompas) kompas_stop_fp;
alias extern(Windows) bool function(int kompas, const char* m3dFile, bool isEngSys, char** crc, char** icon) kompas_m3d_fp;
alias extern(Windows) bool function(int kompas, const char* fromLfr, const char* toFrw, bool isEngSys, char** crc, char** icon) kompas_frw_fp;

struct kompasDll
{
public:
  HMODULE _module;

  kompas_start_fp kompas_start;
  kompas_stop_fp  kompas_stop;
  kompas_m3d_fp   kompas_m3d;
  kompas_frw_fp   kompas_frw;

  void Load()
  {
    if (_module != null)
      return;

    _module = LoadLibraryA("e2fdb-helper.dll");
    if (_module == null)  throw new Exception("fbDll._module == null");

    kompas_start = cast(kompas_start_fp) GetProcAddress(_module, "kompas_start");
    if (kompas_start == null) throw new Exception("kompas_start == null");
    kompas_stop = cast(kompas_stop_fp) GetProcAddress(_module, "kompas_stop");
    if (kompas_stop == null) throw new Exception("kompas_stop == null");
    kompas_m3d = cast(kompas_m3d_fp) GetProcAddress(_module, "kompas_m3d");
    if (kompas_m3d == null) throw new Exception("kompas_m3d == null");
    kompas_frw = cast(kompas_frw_fp) GetProcAddress(_module, "kompas_frw");
    if (kompas_frw == null) throw new Exception("kompas_frw == null");
  }

  void Free()
  {
    FreeLibrary(_module);
    _module = null;
  }
}