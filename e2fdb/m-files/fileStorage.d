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
  this(wstring _modelPath, wstring _md5) { modelPath = _modelPath; md5 = _md5; }
}
struct MES_JOB_THREAD_RUN
{
  model_md5[] models;
}
struct MES_JOB_THREAD_EXIT
{

}
struct MES_JOB_THREAD_GET_RESULT
{
  MODEL_INFO[] models;
  this(immutable(MODEL_INFO[]) _models) immutable { models = _models; }
}
struct MES_JOB_THREAD_PREV_CHUNK
{
  Tid        workerTid;
  MODEL_INFO modelInfo;
}
struct MES_JOB_THREAD_ADD_WAITER
{
  Tid workerTid;
}
struct MES_WORKER_THREAD_M3D_CHUNK
{
  model_md5 chunk;
  this(model_md5 _chunk) { chunk = _chunk; }
}
struct MES_KOMPAS_FRW {}

/++++++++++++++++++++++++++++++++++++++++/
/++++++++++++++++++++++++++++++++++++++++/
class FileStorage
{
  Tid       _mainThread;
  Tid[]     _workerThreads;
  kompasDll _dll;

  wstring[wstring]    _modelHashByPath; // список хешей моделей по пути
  MODEL_INFO[wstring] _modelByMD5;      // список моделей по хешу модели

  // инициализируем работу стореджа
  void Init()
  {
    _dll.Load;
    RunStorageThread();
    //RunKompasThread();
    //RunKompasThread();
  }
  // останавливает работу стореджа
  void Stop()
  {
    
  }
  // запускает обработку файлов
  void RunJob(int[wstring] modelPaths)
  {
    // очистим, т.к. маловероятно что пригодятся для текущего пакета
    _modelHashByPath.clear; 
    _modelByMD5.clear;

    model_md5[]      jobModels;
    wstring[wstring] modelByDigest; // модели, которые запустим в работу

    // проверим лежат ли эти модели в кэше
    foreach (modelPath, num; modelPaths)
      if (modelPath.length != 0)
      {
        modelPath = modelPath.toLower;
        if (!(modelPath in _modelHashByPath)) // если такой путь не обрабатывали, то отметим его обработанным
        {
          wstring digest = getMD5(modelPath);
          _modelHashByPath[modelPath] = digest;

          // TODO: здесь надо найти в файловом кэше
          // добавим его в список на обработку если такого хэша еще там не было
          if (!(digest in modelByDigest))
          {
            modelByDigest[digest] = modelPath;
            jobModels ~= model_md5(modelPath, digest);
          }
        }
      }

    // запускаем обработку
    //send(Tid(_mainThread), MES_JOB_THREAD_RUN(jobModels));
  }
  // получаем результаты работы
  void WaitJob()
  {
    //send(_mainThread, MES_JOB_THREAD_GET_RESULT());
    auto msg = receiveOnly!(MES_JOB_THREAD_GET_RESULT)();
  }
  // получаем информацию о модели
  MODEL_INFO GetModel(wstring modelPath)
  {
    modelPath = modelPath.toLower;
    return _modelByMD5[_modelHashByPath[modelPath]];
  }
private:
  void RunStorageThread()
  {
    write("\nrun storage thread ... ");
    stdout.flush();
    _mainThread = spawn(&MainThread, thisTid);
    write("ok");
    stdout.flush();
  }
  void RunKompasThread()
  {
    int num = _workerThreads.length;
    write("\nrun kompas thread (", num, ") ... " );
    stdout.flush();

    int major, minor;
    int kompas = _dll.kompas_start(&major, &minor);
    if (kompas == 0)
       throw new Exception("FileStorage: не смогли запустить Компас");
    if (major != 15)
    {
      _dll.kompas_stop(kompas);
      throw new Exception("FileStorage: неверная версия компаса");
    }

    _workerThreads ~= spawn(&KompasThread, _mainThread, num, kompas);
    write("ok");
    stdout.flush();
  }

  /+++++++++++++++++++++++++++++++/
  /+++++++++++++++++++++++++++++++/
  static void MainThread(Tid parent)
  {
    MES_JOB_THREAD_RUN currentJob;  // текущая работа
    
    bool runChunk(Tid worker)
    {
      if (currentJob.models.length)
      {
        send(worker, MES_WORKER_THREAD_M3D_CHUNK(currentJob.models[0]));
        currentJob.models = currentJob.models[1 .. $];
        return true;
      }
      return false;
    }

    Tid[]        waiters;                 // ожидающие рабочие
    MODEL_INFO[] modelResult;             // обработанные модели
    bool         needSendResult = false;  // надо ли отсылать результат
    bool         running = true;          // крутим бесконечно цикл
    while (running)
      receive
      (
        (MES_JOB_THREAD_RUN newJob) // программа задает новую работу
        {
          currentJob = newJob;
          needSendResult = false;
          modelResult.clear;
          
          // пробуем запусить сколько сможем
          Tid[] w;
          foreach (waiter; waiters)
            if (!runChunk(waiter))
              w ~= waiter;
          waiters = w;
        },
        (MES_JOB_THREAD_EXIT exit) // программа говорит, что завершаем работу
        {
          running = false;
        },
        (MES_JOB_THREAD_GET_RESULT getResult) // программа требует результат
        {
          bool done = currentJob.models.length == 0;
          auto m = new immutable MODEL_INFO;
          auto l = immutable(MODEL_INFO[])();
      //    auto z = shared(MES_JOB_THREAD_GET_RESULT)(modelResult);
          int i = 0;
          if (done)
            send(parent, 9);
          else
            needSendResult = true;
        },
        (MES_JOB_THREAD_PREV_CHUNK prevChunk) // рабочий выполнил работу, если нет задания, добавим его в ожидающих
        {
          modelResult ~= prevChunk.modelInfo;
          
          bool done = currentJob.models.length == 0;
          if (done && needSendResult)
            send(parent, MES_JOB_THREAD_GET_RESULT(modelResult));
          else if (!runChunk(prevChunk.workerTid))
            waiters ~= prevChunk.workerTid;
        },
        (MES_JOB_THREAD_ADD_WAITER waiter) // рабочий говорит, что он готов
        {
          if (!runChunk(waiter.workerTid))
            waiters ~= waiter.workerTid;
        }
      );
  }
  static void KompasThread(Tid parent, int number, int kompas)
  {
    kompasDll dll;
    dll.Load;
  }
}