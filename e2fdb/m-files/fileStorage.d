module files.fileStorage;
private import std.stdio;
private import dll.kompasserver;
private import dll.cacheserver;
private import core.thread;
private import utils;
private import std.string;
private import std.file;
private import std.path;
private import std.conv;
private import std.algorithm;
private import std.array;

//-----------------------------------------
struct CACHE_FILE_INFO
{
  char*  fileDigest;
  char*  dataDigest;
  char*  param;

  char*  data;
  int    dataLen;
  char*  icon;
  int    iconLen;
}
//-----------------------------------------
class file_info
{
  wstring longPath;
  string  fileDigest;
  string  dataDigest;
  string  param;
  bool    fromCache;

  char*   data;
  int     dataLen;
  char*   icon;
  int     iconLen;
  this(wstring _longPath, string _fileDigest) { longPath = _longPath; fileDigest = _fileDigest; dataLen = 0; iconLen = 0; fromCache = false;}
}

//-----------------------------------------
class FileStorage
{
  KompasServerDll _kompasDll;
  CacheServerDll  _cacheDll;
  int             _cacheId;
  int[]           _kompasId;
  FileThread      _mainThread;
  
  enum THREAD_COUNT = 4;

  public int _unicFileCount = 0;
  public int _cacheHit = 0;

  private void throw_if_message(const(char*) message)
  {
    string err = to!string(message);
    if (err.length != 0)
    {
      Stop;
      auto err2 = toUtf(to!(char[])(err), 1251);
      throw new Exception("FileStorage: " ~ to!string(err2));
    }
  }


  /++++++++++++++++++++++++++/
  // инициализируем работу стореджа
  void Init()
  {
    _kompasDll.Load;
    _cacheDll.Load;

    write("\nconnect to cache ... " );
    stdout.flush();

    // если файла кэша нет то создадим новый
    string thisDir = std.file.thisExePath.dirName;
    if (!exists(thisDir ~ "/cache.fdb"))
      std.file.copy(thisDir ~ "/blank.cache.fdb", thisDir ~ "/cache.fdb");
    _cacheId = _cacheDll.cache_server_init((thisDir ~ "/cache.fdb").toStringz, 15, 0);
    throw_if_message(_cacheDll.cache_server_message(_cacheId));
    write("ok");

    for (int i = 0; i < THREAD_COUNT; ++i)
    {
      write("\nconnect to kompas (", i,") ... ");
      stdout.flush();

      int kompasId = _kompasDll.kompas_server_init(i, 15, 0);
      _kompasId ~= kompasId;
      throw_if_message(_kompasDll.kompas_server_message(kompasId));
      write("ok");
    }

    stdout.flush();
  }
  /+++++++++++++++++++++++++++/
  // останавливает работу стореджа
  void Stop()
  {
    _cacheDll.cache_server_quit(_cacheId);
    _cacheId = 0;
    foreach(kompasId; _kompasId)
      _kompasDll.kompas_server_quit(kompasId);
    _kompasId.clear;
  }
  /+++++++++++++++++++++++++++/
  // запускает обработку файлов
  void RunTask(wstring[] filePaths)
  {
    _mainThread = new FileThread(this, filePaths);
    //_mainThread.run();
    // TODO start
    _mainThread.start();
  }
  /+++++++++++++++++++++++++++/
  void WaitTask()
  {
    // TODO join
    _mainThread.join;
  }
  /+++++++++++++++++++++++++++/
  file_info GetModel(wstring modelPath)
  {
    return null;// _thread.GetResult(modelPath);
  }
}

//-----------------------------------------
class FileThread : Thread
{
private:
  FileStorage       _storage;
  wstring[]         _filePaths;
  string[wstring]   _fileHashByLongPath;  // список хешей файлов по длинному пути
  file_info[string] _fileInfoByHash;      // обработанный файлы по хешу
  string[wstring]   _fileHashByShortPath; // список хешуй файлов по короткому пути

public:

  this(FileStorage storage, wstring[] filePaths)
  {
    super(&run);
    _storage   = storage;
    _filePaths = filePaths;
  }

  file_info GetResult(wstring longPath)
  {
    string fileDigest = _fileHashByLongPath[longPath.toLower];
    return _fileInfoByHash[fileDigest];
  }

private:
  string getHash(wstring shortPath)
  {
    if (string* hash = shortPath in _fileHashByShortPath)
      return *hash;
    string hash = getMD5(shortPath);
    _fileHashByShortPath[shortPath] = hash;
    return hash;
  }

  void cache_file_2_file_info(CACHE_FILE_INFO* cInfo, file_info fInfo)
  {
    fInfo.dataDigest = to!string(cInfo.dataDigest);
    fInfo.param      = to!string(cInfo.param);
    fInfo.data       = cInfo.data;
    fInfo.dataLen    = cInfo.dataLen;
    fInfo.icon       = cInfo.icon;
    fInfo.iconLen    = cInfo.iconLen;
  }

  void run()
  {
    _storage._cacheDll.cache_server_clear(_storage._cacheId);
    foreach (kompasId; _storage._kompasId)
      _storage._kompasDll.kompas_server_clear(kompasId);
    
    // разберем сколько моделей надо обработать
    foreach (longPath; _filePaths)
      if (longPath.length != 0)
      {
        longPath = longPath.toLower;
        if (!(longPath in _fileHashByLongPath)) // если такой путь не обрабатывали, то отметим его обработанным
        {
          wstring shortPath = longPath;
          wstring digestSuf = "";
          
          int stickPos = longPath.indexOf("|");
          if (stickPos != -1)
          {
            shortPath = longPath[0 .. stickPos];
            digestSuf = longPath[stickPos .. $];
          }

          string fileDigest = getHash(shortPath) ~ to!string(toAnsii(digestSuf, 1251));
          _fileHashByLongPath[longPath] = fileDigest;

          // добавим его в список на обработку если такого хэша еще там не было
          if (!(fileDigest in _fileInfoByHash))
            _fileInfoByHash[fileDigest] = new file_info(longPath, fileDigest);
        }
      }

    // сперва считываем из кэша
    foreach (fileInfo; _fileInfoByHash.byValue)
    {
      CACHE_FILE_INFO cInfo;
      bool res = _storage._cacheDll.cache_server_read(_storage._cacheId, fileInfo.fileDigest.toStringz, &cInfo);
      if (res)
      {
        cache_file_2_file_info(&cInfo, fileInfo);
        fileInfo.fromCache = true;
      }
    }

    // получим данные для файлов
    auto fileJob = array(_fileInfoByHash.byValue).filter!(a => !a.fromCache);
    foreach (fileInfo; fileJob)
    {
      CACHE_FILE_INFO cInfo;
      bool res = _storage._kompasDll.kompas_server_file(_storage._kompasId[0], toAnsii(fileInfo.longPath, 1251).toStringz, false, &cInfo);
      if (!res)
      {
//        string err = to!string(_dll.kompas_cache_error());
//        auto err2 = toUtf(to!(char[])(err), 1251);
//        throw new Exception("FileStorage: " ~ to!string(err2));
      }
    }
  }
}