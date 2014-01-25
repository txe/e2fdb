module fdb.writeManager;

private import edb.parser;
private import files.fileStorage;
private import console.consoleWriter;
private import edb.structure;

struct WriteManager
{
private:
  ConsoleWriter _console;
  FileStorage   _fileStorage;

public:
  /++++++++++++++++++++++++++++/
  void Run(string[] edbFiles)
  {
    _console.Init();
    _fileStorage.Init();

    foreach (index, file; edbFiles)
    {
      auto edbStruct = EdbParser().Parse(file);
      PrepareData(edbStruct);
      RunFileJobs(edbStruct);
      WritePacket(edbStruct);
      WriteFiles();
    }
  }

private:
  /++++++++++++++++++++++++++++/
  void PrepareData(EdbStructure edbStruct)
  {
  
  }
  /++++++++++++++++++++++++++++/
  void RunFileJobs(EdbStructure edbStruct)
  {

  }
  /++++++++++++++++++++++++++++/
  void WritePacket(EdbStructure edbStruct)
  {

  }
  /++++++++++++++++++++++++++++/
  void WriteFiles()
  {

  }
}