module files.fileStorage;
private import std.stdio;
private import helper.kompas;
private import core.thread;
private import utils;
private import std.string;
private import std.file;
private import std.path;
private import std.conv;

class file_info
{
  wstring filePath;
  string  digest;
  char*   data;
  int     dataLen;
  char*   icon;
  int     iconLen;
  char*   crc;
  int     crcLen;
  this(wstring _filePath, string _digest) { filePath = _filePath; digest = _digest; dataLen = 0; iconLen = 0; crcLen = 0; }
}

/++++++++++++++++++++++++++++++++++++++++/
class FileStorage
{
  kompasDll   _dll;
  int         _cacheId;
  FileThread  _thread;
  file_info[] _fileInfo;

  public int _unicFileCount = 0;
  public int _cacheHit = 0;

  /++++++++++++++++++++++++++/
  // инициализируем работу стореджа
  void Init()
  {
    _dll.Load;
    write("\nconnect to cache/kompas ... " );
    stdout.flush();

    // если файла кэша нет то создадим новый
    string thisDir = std.file.thisExePath.dirName;
    if (!exists(thisDir ~ "/cache.fdb"))
      std.file.copy(thisDir ~ "/blank.cache.fdb", thisDir ~ "/cache.fdb");
    
    _cacheId = _dll.kompas_cache_init((thisDir ~ "/cache.fdb").toStringz, 15, 0);
    if (_cacheId == 0)
    {
      string err = to!string(_dll.kompas_cache_error());
      auto err2 = toUtf(to!(char[])(err), 1251);
      throw new Exception("FileStorage: " ~ to!string(err2));
    }

    write("ok");
    stdout.flush();

  }
  /+++++++++++++++++++++++++++/
  // останавливает работу стореджа
  void Stop()
  {
    _dll.kompas_cache_stop(_cacheId);
    _cacheId = 0;
  }
  /+++++++++++++++++++++++++++/
  // запускает обработку файлов
  void RunTask(wstring[] filePaths)
  {
    _thread = new FileThread(filePaths, _dll, _cacheId, &_unicFileCount, &_cacheHit);
    _thread.run();
    // TODO start
    //_thread.start();
  }
  /+++++++++++++++++++++++++++/
  void WaitTask()
  {
    // TODO join
    //_thread.join;
  }
  /+++++++++++++++++++++++++++/
  file_info GetModel(wstring modelPath)
  {
    return _thread.GetResult(modelPath);
  }
}

class FileThread : Thread
{
private:
  string[wstring]   _modelHashByPath; // список хешей моделей по пути
  file_info[string] _fileInfoByHash;  // модели, которые запустили в работу

  wstring[]    _filePaths;
  kompasDll    _dll;
  int          _cacheId;

  int*         _unicFileCount;
  int*         _cacheHit;

public:

  this(wstring[] filePaths, kompasDll dll, int cacheId, int* unicFileCount, int* cacheHit)
  {
    super(&run);
    _filePaths     = filePaths;
    _dll           = dll;
    _cacheId       = cacheId;
    _unicFileCount = unicFileCount;
    _cacheHit      = cacheHit;
  }

  file_info GetResult(wstring filePath)
  {
    string digest = _modelHashByPath[filePath.toLower];
    return _fileInfoByHash[digest];
  }

private:
  void run()
  {
    _dll.kompas_cache_clear_temp(_cacheId);
    
    // разберем сколько моделей надо обработать
    foreach (filePath; _filePaths)
      if (filePath.length != 0)
      {
        filePath = filePath.toLower;
        if (!(filePath in _modelHashByPath)) // если такой путь не обрабатывали, то отметим его обработанным
        {
          wstring realPath  = filePath;
          wstring digestSuf = "";
          
          int stickPos = filePath.indexOf("|");
          if (stickPos != -1)
          {
            realPath  = filePath[0 .. stickPos];
            digestSuf = filePath[stickPos .. $];
          }

          string digest = getMD5(realPath) ~ to!string(toAnsii(digestSuf, 1251));
          _modelHashByPath[filePath] = digest;

          // добавим его в список на обработку если такого хэша еще там не было
          if (!(digest in _fileInfoByHash))
            _fileInfoByHash[digest] = new file_info(filePath, digest);
        }
      }

    // получим данные для файлов
    foreach (fileInfo; _fileInfoByHash.byValue)
    {
      bool isFromCache = false;
      bool res = _dll.kompas_cache_file_info(_cacheId, fileInfo.digest.toStringz, toAnsii(fileInfo.filePath, 1251).toStringz, false, &fileInfo.data, &fileInfo.dataLen, &fileInfo.crc, &fileInfo.crcLen, &fileInfo.icon, &fileInfo.iconLen, &isFromCache);
      if (!res)
      {
        string err = to!string(_dll.kompas_cache_error());
        auto err2 = toUtf(to!(char[])(err), 1251);
        throw new Exception("FileStorage: " ~ to!string(err2));
      }

      *_unicFileCount += 1;
      if (isFromCache)
        *_cacheHit += 1;
    }
  }
}