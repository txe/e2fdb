module fdb.writeManager;

private import edb.parser;
private import std.path;
private import files.fileStorage;
private import console.consoleWriter;
private import edb.structure;
private import fdb.fdbConvert;

struct WriteManager
{
private:
  ConsoleWriter _console;
  FileStorage   _fileStorage;

public:
  /++++++++++++++++++++++++++++/
  void Run(string[] edbFiles)
  {
    auto thisDir = std.file.thisExePath.dirName;
    std.file.copy(thisDir ~ "/blank.fdb", thisDir ~ "/breeze.fdb");

    _console.Init();
    _fileStorage.Init();

    foreach (index, file; edbFiles)
    {
      auto edbStruct = EdbParser().Parse(file);
      auto fdbStruct = FdbConvert().Convert(edbStruct);
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