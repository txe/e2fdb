module fdb.writeManager;

private import edb.parser;
private import std.path;
private import files.fileStorage;
private import console.consoleWriter;
private import edb.structure;
private import fdb.fdbConvert;
private import fdb.fdbStructure;
private import fdb.fdbConnect;
private import std.conv;

class WriteManager
{
private:
  ConsoleWriter  _console;
  FileStorage    _fileStorage;
  FdbConnect     _provider = new FdbConnect;
  FdbTransaction _trans;

public:
  ~this()
  {
    _trans.Close();
    _provider.Disconnect();
  }
  /++++++++++++++++++++++++++++/
  void Run(string[] edbFiles)
  {
    auto thisDir = std.file.thisExePath.dirName;
    std.file.copy(thisDir ~ "/blank.fdb", thisDir ~ "/breeze.fdb");

    _provider.Connect("", to!string(thisDir ~ "\\breeze.fdb"), "sysdba", "masterkey");
    _trans = _provider.OpenTransaction(FdbTransaction.TAM.amWrite, FdbTransaction.TIL.ilReadCommitted, FdbTransaction.TLR.lrNoWait);
    
    _console.Init();
    _fileStorage.Init();

    foreach (index, file; edbFiles)
    {
      auto edbStruct = EdbParser().Parse(file);
      auto fdbStruct = FdbConvert().Convert(edbStruct);
      PrepareData(fdbStruct);
      RunFileJobs(fdbStruct);
      WritePacket(fdbStruct);
      WriteFiles();
    }
  }

private:
  /++++++++++++++++++++++++++++/
  FdbStatement GetStatement()
  {
    return _provider.OpenStatement(_trans);
  }
  /++++++++++++++++++++++++++++/
  void PrepareData(FdbPacket fdbPacket)
  {
  
  }
  /++++++++++++++++++++++++++++/
  void RunFileJobs(FdbPacket fdbPacket)
  {

  }
  /++++++++++++++++++++++++++++/
  void WritePacket(FdbPacket fdbPacket)
  {
    auto st = GetStatement();
    

  }
  /++++++++++++++++++++++++++++/
  void WriteFiles()
  {
    
  }
}