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
private import std.string;

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
    string thisDir = std.file.thisExePath.dirName;
    std.file.copy(thisDir ~ "/blank.fdb", thisDir ~ "/breeze.fdb");

    _provider.Connect(thisDir ~ "\\breeze.fdb", "sysdba", "masterkey");
    _trans = _provider.OpenTransaction(FdbTransaction.TAM.amWrite, FdbTransaction.TIL.ilReadCommitted, FdbTransaction.TLR.lrNoWait);
    _trans.Start;
    
    _console.Init();
    _fileStorage.Init();

    foreach (index, file; edbFiles)
    {
      auto edbStruct = EdbParser().Parse(file);
      auto fdbStruct = FdbConvert().Convert(edbStruct);
      PrepareData(fdbStruct);
      RunFileJobs(fdbStruct);
      WritePacketNameAndFolder(fdbStruct);
      WriteFiles();
    }
  }

private:
  /++++++++++++++++++++++++++++/
  FdbStatementRef GetStatement()
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
  void WritePacketNameAndFolder(FdbPacket fdbPacket)
  {
    FdbStatement st = GetStatement();
    // создать рутовый фолдер
    fdbPacket._rRootId = st.Prepare("INSERT INTO FOLDER (NAME, ID_PARENT) VALUES (?, ?) RETURNING ID").Set(1, fdbPacket._name).SetNull(2).Execute().GetInt(1);
    // создать пакет
    fdbPacket._rId = st.Prepare("INSERT INTO PACKET (PACKETID, FOLDERID) VALUES (?, ?) RETURNING ID").Set(1, fdbPacket._id).Set(2, fdbPacket._rRootId).Execute().GetInt(1);
    // создадим ветвление фолдеров
    foreach (data; fdbPacket._fdbVirtData)
      foreach (FdbTemplate temp; data._templates)
      {
        int prevFolderId = fdbPacket._rRootId;
        wstring[] childFolders = temp._folder.split("|");
        foreach (i, folder; childFolders)
        {
          wstring folderPath = (childFolders[0 .. i] ~ folder).join("|");
          if (folderPath in fdbPacket._rFolderIdMap)
          {
            prevFolderId = fdbPacket._rFolderIdMap[folderPath];
            continue;
          }
          int folderId = st.Prepare("INSERT INTO FOLDER (NAME, ID_PARENT) VALUES (?, ?) RETURNING ID").Set(1, folder).Set(2, prevFolderId).Execute().GetInt(1);
          fdbPacket._rFolderIdMap[folderPath] = folderId;
        }
      }
  }
  /++++++++++++++++++++++++++++/
  void WriteFiles()
  {
    
  }
}