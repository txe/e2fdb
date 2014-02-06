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
private import std.stdio;
private import std.datetime;

class WriteManager
{
private:
  ConsoleWriter  _console;
  FileStorage    _fileStorage;
  FdbConnect     _provider = new FdbConnect;
  FdbTransaction _trans;

  int[wstring]    _cache_packet_types;
  int             _repId;

public:
  ~this()
  {
    _trans.Close();
    _provider.Disconnect();
  }
  /++++++++++++++++++++++++++++/
  void Run(string[] edbFiles)
  {
    writeln;

    write("\nprepare fdb ... ");
    string thisDir = std.file.thisExePath.dirName;
    std.file.copy(thisDir ~ "/blank.fdb", thisDir ~ "/breeze.fdb");
    write("ok");

    write("\nconnect to fdb ... ");
    if (!_provider.Connect(thisDir ~ "\\breeze.fdb", "sysdba", "masterkey"))
    {
      write("error, can't create connect");
      return;
    }
    _trans = _provider.OpenTransaction(FdbTransaction.TAM.amWrite, FdbTransaction.TIL.ilReadCommitted, FdbTransaction.TLR.lrNoWait);
    if (_trans is null)
    {
      write("error, can't open transaction");
      return;
    }
    write("ok");
    _trans.Start;
    
    _console.Init();
    _fileStorage.Init();

    StopWatch sw;
    sw.start;
    writeln;
    foreach (index, file; edbFiles)
    {
      write("\rwrite: " ~ to!string(index + 1) ~ " of " ~ to!string(edbFiles.length) ~ " packet(s), problem(s): 0");
      stdout.flush();
      
      try
      {
        auto edbStruct = EdbParser().Parse(file);
        auto fdbStruct = FdbConvert().Convert(edbStruct);
        PrepareData(fdbStruct);
        RunFileJobs(fdbStruct);
        WritePacketAndFolderTree(fdbStruct);
        WriteTempletes(fdbStruct);
        WriteFiles();
      }
      catch (Exception e) {}
    }
    sw.stop;
    writeln;
    writeln("lap time: ", sw.peek.seconds, " sec.");

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
    FdbStatement st = GetStatement();
    // подготовим кэш для типов пакетов
    if (fdbPacket._type in _cache_packet_types)
      fdbPacket._rType = _cache_packet_types[fdbPacket._type];
    else
    {
      fdbPacket._rType = st.Prepare("INSERT INTO OBJECTTYPE (SVAL) VALUES ( ? ) RETURNING ID").Set(1, fdbPacket._type).Execute().GetInt(1);
      _cache_packet_types[fdbPacket._type] = fdbPacket._rType;
    }

    _repId = st.Prepare("INSERT INTO REPRESENTATION (DATA, DIGEST) VALUES( ?, ? ) RETURNING ID").SetBlob(1, "20").Set(2, "20").Execute().GetInt(1);
  }
  /++++++++++++++++++++++++++++/
  void RunFileJobs(FdbPacket fdbPacket)
  {

  }
  /++++++++++++++++++++++++++++/
  void WritePacketAndFolderTree(FdbPacket fdbPacket)
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
  void WriteTempletes(FdbPacket fdbPacket)
  {
    FdbStatement st = GetStatement();
    foreach (data; fdbPacket._fdbVirtData)
      foreach (FdbTemplate temp; data._templates)
      {
        int folderId = fdbPacket._rFolderIdMap[temp._folder];
        st.Prepare("INSERT INTO OBJECT (NAME, MODELID, OBJECTTYPEID, PACKETID, FOLDERID, REPRESENTATIONID) VALUES ( ?, ?, ?, ?, ?, ? ) RETURNING ID");
        st.Set(1, temp._name).SetNull(2).Set(3, fdbPacket._rType).Set(4, fdbPacket._rId).Set(5, folderId).Set(6, _repId);
        temp._rId = st.Execute().GetInt(1);
      }
  }
  /++++++++++++++++++++++++++++/
  void WriteFiles()
  {
    
  }
}