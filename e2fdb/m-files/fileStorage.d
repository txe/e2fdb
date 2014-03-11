module files.fileStorage;
private import std.stdio;
private import helper.kompas;
private import std.concurrency;
private import utils;
private import std.string;

class MODEL_INFO {}

struct model_md5
{
  wstring modelPath;
  wstring md5;
  bool    isCache;
  char*   data;
  int     dataLen;
  char*   icon;
  int     iconLen;
  char*   crc;
  int     crcLen;
  this(wstring _modelPath, wstring _md5) { modelPath = _modelPath; md5 = _md5; isCache = false; dataLen = 0; iconLen = 0; crcLen = 0; }
}

/++++++++++++++++++++++++++++++++++++++++/
class FileStorage
{
  kompasDll _dll;
  int       _kompasId;

  /++++++++++++++++++++++++++/
  // инициализируем работу стореджа
  void Init()
  {
    _dll.Load;
    InitKompas();
    InitCache();
  }
  /+++++++++++++++++++++++++++/
  // останавливает работу стореджа
  void Stop()
  {
    
  }
  /+++++++++++++++++++++++++++/
  // запускает обработку файлов
  void RunJob(int[wstring] modelPaths)
  {
    JobThread(modelPaths, _dll, _kompasId);
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
  /+++++++++++++++++++++++++++++++++/
  void InitKompas()
  {
    write("\ninit kompas ... " );
    stdout.flush();

    int major, minor;
    int kompas = _dll.kompas_start(&major, &minor);
    if (kompas == 0)
       throw new Exception("FileStorage: не смогли запустить Компас");
    if (major != 15)
    {
      _dll.kompas_stop(kompas);
      throw new Exception("FileStorage: неверная версия Компаса");
    }

    write("ok");
    stdout.flush();
  }
  /++++++++++++++++++++++++++++++/
  void InitCache()
  {

  }
  /+++++++++++++++++++++++++++++++++++/
  static void JobThread(int[wstring] modelPaths, kompasDll dll, int kompasId)
  {
    wstring[wstring] modelHashByPath; // список хешей моделей по пути
    int[wstring]     hashInJob;       // int[MD5], которые запустим в работу
    model_md5[]      jobModels;       // модели, которые запустили в работу

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
            jobModels ~= model_md5(modelPath, digest);
          }
        }
      }

    // получим готовые файлы из кеша
    FileFromCache(jobModels);
    // обработаем файлы в компасе
    FileFromKompas(jobModels, dll, kompasId);
  }
  /+++++++++++++++++++++++++++/
  static void FileFromCache(model_md5[] jobModels)
  {

  }
  /++++++++++++++++++++++++++/
  static bool FileFromKompas(model_md5[] jobModels, kompasDll dll, int kompasId)
  {
    foreach (jobModel; jobModels)
    {
      if (!dll.kompas_m3d(kompasId, toAnsii(jobModel.modelPath, 1251).toStringz, "", false, &jobModel.data, &jobModel.dataLen, &jobModel.crc, &jobModel.crcLen, &jobModel.icon, &jobModel.iconLen))
        return false;
    }

    return true;
  }
}