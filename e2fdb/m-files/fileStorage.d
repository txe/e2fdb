module files.fileStorage;
private import std.stdio;
private import helper.kompas;
private import core.thread;
private import utils;
private import std.string;
private import std.file;
private import std.path;
private import std.conv;


struct file_info
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
      auto err = to!string(_dll.kompas_cache_error());
      throw new Exception("FileStorage: " ~ err);
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
  void RunTask(int[wstring] modelPaths)
  {
    _thread = new FileThread(modelPaths, _dll, _cacheId, &_unicFileCount, &_cacheHit);
    _thread.run();
    //_thread.start();
  }
  /+++++++++++++++++++++++++++/
  void WaitTask()
  {
   // _thread.join;
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

  int[wstring] _modelPaths;
  kompasDll    _dll;
  int          _cacheId;

  int*         _unicFileCount;
  int*         _cacheHit;

public:

  this(int[wstring] modelPaths, kompasDll dll, int cacheId, int* unicFileCount, int* cacheHit)
  {
    super(&run);
    _modelPaths = modelPaths;
    _dll = dll;
    _cacheId = cacheId;
    _unicFileCount = unicFileCount;
    _cacheHit = cacheHit;
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
    foreach (modelPath, num; _modelPaths)
      if (modelPath.length != 0)
      {
        modelPath = modelPath.toLower;
        if (!(modelPath in _modelHashByPath)) // если такой путь не обрабатывали, то отметим его обработанным
        {
          string digest = getMD5(modelPath);
          _modelHashByPath[modelPath] = digest;

          // добавим его в список на обработку если такого хэша еще там не было
          if (!(digest in _fileInfoByHash))
            _fileInfoByHash[digest] = file_info(modelPath, digest);
        }
      }

    // получим данные для файлов
    foreach (fileInfo; _fileInfoByHash.byValue)
    {
      bool isFromCache = false;
      _dll.kompas_cache_file_info(_cacheId, fileInfo.digest.toStringz, toAnsii(fileInfo.filePath, 1251).toStringz, false, &fileInfo.data, &fileInfo.dataLen, &fileInfo.crc, &fileInfo.crcLen, &fileInfo.icon, &fileInfo.iconLen, &isFromCache);
      
      *_unicFileCount += 1;
      if (isFromCache)
        *_cacheHit += 1;
    }
  }
}