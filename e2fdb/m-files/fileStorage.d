module files.fileStorage;
private import std.stdio;
private import helper.kompas;
private import std.concurrency;
private import utils;
private import std.string;

class MODEL_INFO {}

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
  kompasDll _dll;
  int       _cacheId;

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
  void RunJob(int[wstring] modelPaths)
  {
    JobThread(modelPaths, _dll, _cacheId);
  }
  /+++++++++++++++++++++++++++/
  void WaitJob()
  {

  }
  /+++++++++++++++++++++++++++/
  MODEL_INFO GetModel(wstring modelPath)
  {
    return null;
  }
private:
  /+++++++++++++++++++++++++++++++++++/
  static void JobThread(int[wstring] modelPaths, kompasDll dll, int cacheId)
  {
    wstring[wstring] modelHashByPath; // список хешей моделей по пути
    int[wstring]     hashInJob;       // int[MD5], которые запустим в работу
    file_info[]      fileInfos;        // модели, которые запустили в работу

    // разберем сколько моделей надо обработать
    foreach (modelPath, num; modelPaths)
      if (modelPath.length != 0)
      {
        modelPath = modelPath.toLower;
        if (!(modelPath in modelHashByPath)) // если такой путь не обрабатывали, то отметим его обработанным
        {
          wstring digest = getMD5(modelPath);
          modelHashByPath[modelPath] = digest;

          // добавим его в список на обработку если такого хэша еще там не было
          if (!(digest in hashInJob))
          {
            hashInJob[digest] = 1;
            fileInfos ~= file_info(modelPath, digest);
          }
        }
      }

    // получим данные для файлов
    foreach (fileInfo; fileInfos)
    {
      dll.kompas_cache_file_info(cacheId, toAnsii(fileInfo.digest, 1251).toStringz, toAnsii(fileInfo.filePath, 1251).toStringz, false, &fileInfo.data, &fileInfo.dataLen, &fileInfo.crc, &fileInfo.crcLen, &fileInfo.icon, &fileInfo.iconLen);
    }
  }
}