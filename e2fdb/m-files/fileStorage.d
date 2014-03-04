module files.fileStorage;
private import std.stdio;
private import helper.kompas;
private import std.concurrency;

struct MES_MAIN_STOP {}
struct MES_KOMPAS_START {}
struct MES_KOMPAS_STOP {}
struct MES_KOMPAS_M3D {}
struct MES_KOMPAS_FRW {}

class FileStorage
{
  Tid       _mainThread;
  Tid[]     _kompasThread;
  kompasDll _dll;

  void Init()
  {
    _dll.Load;
    RunStorageThread();
    RunKompasThread();
    RunKompasThread();
  }
  void Stop()
  {

  }
private:
  void RunStorageThread()
  {
    write("\nrun storage thread ... ");
    _mainThread = spawn(&MainThread);
    write("ok");
  }
  void RunKompasThread()
  {
    int num = _kompasThread.length;
    write("\nrun kompas thread (", num, ") ... " );

    int major, minor;
    int kompas = _dll.kompas_start(&major, &minor);
    if (kompas == 0)
       throw new Exception("FileStorage: не смогли запустить Компас");
    if (major != 15)
      throw new Exception("FileStorage: неверная версия компаса");

    _kompasThread ~= spawn(&KompasThread, _mainThread, num, kompas);

    write("ok");
  }
  static void MainThread()
  {

  }
  static void KompasThread(Tid parent, int number, int kompas)
  {
    kompasDll dll;
    dll.Load;
  }
}