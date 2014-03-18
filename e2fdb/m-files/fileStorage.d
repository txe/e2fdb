module files.fileStorage;
private import std.stdio;
private import helper.kompas;
private import core.thread;
private import utils;
private import std.string;


struct file_info
{
  wstring filePath;
  wstring digest;
  char*   data;
  int     dataLen;
  char*   icon;
  int     iconLen;
  char*   crc;
  int     crcLen;
  this(wstring _filePath, wstring _digest) { filePath = _filePath; digest = _digest; dataLen = 0; iconLen = 0; crcLen = 0; }
}

/++++++++++++++++++++++++++++++++++++++++/
class FileStorage
{
  kompasDll   _dll;
  int         _cacheId;
  FileThread  _thread;
  file_info[] _fileInfo;

  /++++++++++++++++++++++++++/
  // инициализируем работу стореджа
  void Init()
  {
    _dll.Load;
    write("\ninit cache ... " );
    stdout.flush();

    int kompas = _dll.kompas_cache_init("", 15, 0);
    if (kompas < 10)
      throw new Exception("FileStorage: не смогли запустить Компас");

    write("ok");
    stdout.flush();

  }
  /+++++++++++++++++++++++++++/
  // останавливает работу стореджа
  void Stop()
  {
    _dll.kompas_cache_stop(_cacheId);
  }
  /+++++++++++++++++++++++++++/
  // запускает обработку файлов
  void RunTask(int[wstring] modelPaths)
  {
    _thread = new FileThread(modelPaths, _dll, _cacheId);
    _thread.start();
  }
  /+++++++++++++++++++++++++++/
  void WaitTask()
  {
    _thread.join;
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
  wstring[wstring]   _modelHashByPath; // список хешей моделей по пути
  file_info[wstring] _fileInfoByHash;  // модели, которые запустили в работу

  int[wstring] _modelPaths;
  kompasDll    _dll;
  int          _cacheId;

public:

  this(int[wstring] modelPaths, kompasDll dll, int cacheId)
  {
    super(&run);
    _modelPaths = modelPaths;
    _dll = dll;
    _cacheId = cacheId;
  }

  file_info GetResult(wstring filePath)
  {
    wstring digest = _modelHashByPath[filePath.toLower];
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
          wstring digest = getMD5(modelPath);
          _modelHashByPath[modelPath] = digest;

          // добавим его в список на обработку если такого хэша еще там не было
          if (!(digest in _fileInfoByHash))
            _fileInfoByHash[digest] = file_info(modelPath, digest);
        }
      }

    // получим данные для файлов
    foreach (digest, fileInfo; _fileInfoByHash)
    {
      _dll.kompas_cache_file_info(_cacheId, toAnsii(fileInfo.digest, 1251).toStringz, toAnsii(fileInfo.filePath, 1251).toStringz, false, &fileInfo.data, &fileInfo.dataLen, &fileInfo.crc, &fileInfo.crcLen, &fileInfo.icon, &fileInfo.iconLen);
    }
  }
}