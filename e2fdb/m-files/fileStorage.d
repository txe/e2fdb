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
  bool    fromCache;

  char*  dataDigest;
  char*  param;

  char*   data;
  int     dataLen;
  char*   icon;
  int     iconLen;
  this(wstring _longPath, string _fileDigest) { longPath = _longPath; fileDigest = _fileDigest; dataLen = 0; iconLen = 0; fromCache = false;}
}

void cache_file_2_file_info(CACHE_FILE_INFO* cInfo, file_info fInfo)
{
  fInfo.dataDigest = cInfo.dataDigest;
  fInfo.param      = cInfo.param;
  fInfo.data       = cInfo.data;
  fInfo.dataLen    = cInfo.dataLen;
  fInfo.icon       = cInfo.icon;
  fInfo.iconLen    = cInfo.iconLen;
}
void file_info_2_cache_file(file_info fInfo, CACHE_FILE_INFO* cInfo)
{
  cInfo.dataDigest = fInfo.dataDigest;
  cInfo.param      = fInfo.param;
  cInfo.data       = fInfo.data;
  cInfo.dataLen    = fInfo.dataLen;
  cInfo.icon       = fInfo.icon;
  cInfo.iconLen    = fInfo.iconLen;
}
//------------------------------------------
private void throw_if_message(const(char*) message, void delegate() stop)
{
  string err = to!string(message);
  if (err.length != 0)
  {
    if (stop)
      stop();
    auto err2 = toUtf(to!(char[])(err), 1251);
    throw new Exception("FileStorage: " ~ to!string(err2));
  }
}
//-----------------------------------------
class FileStorage
{
  KompasServerDll _kompasDll;
  CacheServerDll  _cacheDll;
  int             _cacheId;
  int[]           _kompasIds;
  FileThread      _mainThread;
  
  enum THREAD_COUNT = 2;

  public int _unicFileCount = 0;
  public int _cacheHit = 0;

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
    throw_if_message(_cacheDll.cache_server_message(_cacheId), &Stop);
    write("ok");

    for (int i = 0; i < THREAD_COUNT; ++i)
    {
      write("\nconnect to kompas (", i,") ... ");
      stdout.flush();

      int kompasId = _kompasDll.kompas_server_init(i, 15, 0);
      _kompasIds ~= kompasId;
      throw_if_message(_kompasDll.kompas_server_message(kompasId), &Stop);
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
    foreach(kompasId; _kompasIds)
      _kompasDll.kompas_server_quit(kompasId);
    _kompasIds.clear;
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

  void run()
  {
    _storage._cacheDll.cache_server_clear(_storage._cacheId);
    foreach (kompasId; _storage._kompasIds)
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
      if (!res)
        throw_if_message(_storage._cacheDll.cache_server_message(_storage._cacheId), null);
      if (res)
      {
        cache_file_2_file_info(&cInfo, fileInfo);
        fileInfo.fromCache = true;
      }
    }
    
    // файлы, которые не были в кэше
    auto fileJob  = _fileInfoByHash.byValue.array.filter!(a => !a.fromCache).array;
    
    _storage._unicFileCount += _fileInfoByHash.length;
    _storage._cacheHit      += _fileInfoByHash.length - fileJob.length;

    // разобъем файлы на части
    int chunkSize = fileJob.length / _storage._kompasIds.length;
    int rest      = fileJob.length - chunkSize * _storage._kompasIds.length;
    KompasThread[] threads;
    int taken = 0;
    foreach (index, kompasId; _storage._kompasIds)
    {
      int count = chunkSize + (index < rest ? 1 : 0);
      try
      {
        threads ~= new KompasThread(fileJob[taken .. taken + count], kompasId, _storage._kompasDll);
        taken += count;
      }
      catch (Exception e)
      {
        writeln();
      }
    }
    int checkCount = 0;
    foreach (thread; threads)
      checkCount += thread._files.length;
    if (checkCount != fileJob.length)
      throw new Exception("???");
    foreach (thread; threads)
      thread.start;
    foreach (thread; threads)
      thread.join;

    // запишем в кэш
    foreach (fileInfo; fileJob)
    {
      CACHE_FILE_INFO cInfo;
      file_info_2_cache_file(fileInfo, &cInfo);
      bool res = _storage._cacheDll.cache_server_write(_storage._cacheId, fileInfo.fileDigest.toStringz, &cInfo);
      if (!res)
        throw_if_message(_storage._cacheDll.cache_server_message(_storage._cacheId), null);
    }
  }
}

//-----------------------------------------
class KompasThread : Thread
{
  file_info[]     _files;
  int             _kompasId;
  KompasServerDll _kompasDll;

  this(file_info[] files, int kompasId, KompasServerDll kompasDll)
  {
    super(&run);
    _files     = files;
    _kompasId  = kompasId;
    _kompasDll = kompasDll;
  }

  void run()
  {
    foreach (fileInfo; _files)
    {
      CACHE_FILE_INFO cInfo;
      bool res = _kompasDll.kompas_server_file(_kompasId, toAnsii(fileInfo.longPath, 1251).toStringz, false, &cInfo);
      if (!res)
        throw_if_message(_kompasDll.kompas_server_message(_kompasId), null);
      cache_file_2_file_info(&cInfo, fileInfo);
    }
  }
}