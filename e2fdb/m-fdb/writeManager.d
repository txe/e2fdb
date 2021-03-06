module fdb.writeManager;

private import edb.parser;
private import std.path;
private import files.fileStorage;
private import edb.structure;
private import fdb.fdbConvert;
private import fdb.fdbStructure;
private import fdb.fdbConnect;
private import std.conv;
private import std.string;
private import std.stdio;
private import std.datetime;
private import std.digest.md;
private import std.file;

class WriteManager
{
private:
  FileStorage    _fileStorage = new FileStorage;
  FdbConnect     _provider = new FdbConnect;
  FdbTransaction _trans;

  int[wstring] _cache_packet_types;
  int[wstring] _cache_atr_name;
  int[wstring] _cache_atr_desc;
  int          _repId;
  int[string]  _cache_modelId_byHash;

public:
  ~this()
  {
    _trans.Commit();
    _trans.Close();
    _provider.Disconnect();

    _fileStorage.Stop;
  }
  /++++++++++++++++++++++++++++/
  void Run(string[] edbFiles)
  {
    writeln;

    write("\ncreate breeze.fdb ... ");
    string thisDir = std.file.thisExePath.dirName;
    std.file.copy(thisDir ~ "/blank.breeze.fdb", thisDir ~ "/breeze.fdb");
    write("ok");

    write("\nconnect to breeze.fdb ... ");
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
    _trans.Start;
    write("ok");
    
    _fileStorage.Init();

    StopWatch sw;
    sw.start;
    writeln;
    string[] problems;
    foreach (index, file; edbFiles)
    {
      write("\rwriting: " ~ to!string(index + 1) ~ " of " ~ to!string(edbFiles.length) ~ " packet(s), problem(s): ", problems.length);
      stdout.flush();
      
      try
      {
        auto edbStruct = EdbParser().Parse(file);
        auto fdbStruct = FdbConvert().Convert(edbStruct);
        PrepareData(fdbStruct);
        RunFileJobs(fdbStruct);
        WritePacketAndFolderTree(fdbStruct);
        WriteTempletes(fdbStruct);
        WriteFiles(fdbStruct);
      }
      catch (Exception e) 
      {
        problems ~= "! " ~ e.msg ~ "\n  file: " ~ file;
      }
    }
    sw.stop;
    writeln;

    foreach (p; problems)
      writeln(p);

    writeln("\nlap time: ", sw.peek.seconds, " sec.");
    writeln("cache hit: ", _fileStorage._cacheHit, "/", _fileStorage._unicFileCount);
    
    write("\ncommiting base ... ");
    stdout.flush();
    _trans.Commit();
    write("ok\n");
    

    write("commiting cache/closing kompas ... ");
    stdout.flush();
    _fileStorage.Stop;
    write("ok\n");
    stdout.flush();
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
    if (int* val = fdbPacket._type in _cache_packet_types)
      fdbPacket._rType = *val;
    else
    {
      fdbPacket._rType = st.Prepare("INSERT INTO OBJECTTYPE (SVAL) VALUES ( ? ) RETURNING ID").Set(1, fdbPacket._type).Execute().GetInt(1);
      _cache_packet_types[fdbPacket._type] = fdbPacket._rType;
    }
    // ненастоящий репрезинтейшн
    _repId = st.Prepare("INSERT INTO REPRESENTATION (DATA, DIGEST) VALUES( ?, ? ) RETURNING ID").SetBlobAsString(1, "20").Set(2, "20").Execute().GetInt(1);
    // заполним id для имен атрибутов
    foreach (data; fdbPacket._fdbVirtData)
      foreach (atr; data._atrs)
      {
        if (int* val = atr._name in _cache_atr_name)
          atr._rNameId = *val;
        else
        {
          atr._rNameId = st.Prepare("INSERT INTO ATTRIBUTENAME (NAME) VALUES( ? ) RETURNING ID").Set(1, atr._name).Execute().GetInt(1);
         _cache_atr_name[atr._name] = atr._rNameId;
        }
        if (int* val = atr._desc in _cache_atr_desc)
          atr._rDescId = *val;
        else
        {
          atr._rDescId = st.Prepare("INSERT INTO ATTRIBUTEDESCRIPTION (DESCRIPTION) VALUES( ? ) RETURNING ID").Set(1, atr._desc).Execute().GetInt(1);
          _cache_atr_desc[atr._desc] = atr._rDescId;
        }
      }

  }
  /++++++++++++++++++++++++++++/
  void RunFileJobs(FdbPacket fdbPacket)
  {
    wstring[] files;

    foreach (data; fdbPacket._fdbVirtData)
      foreach (FdbTemplate temp; data._templates)
      {
        //if (temp._model.length != 0)
        //  files ~= temp._model;
        foreach (FdbFrw frw; temp._frws)
          files ~= frw.path;
      }

    _fileStorage.RunTask(files);
  }
  /++++++++++++++++++++++++++++/
  void WritePacketAndFolderTree(FdbPacket fdbPacket)
  {
    FdbStatement stPacket = GetStatement();
    stPacket.Prepare("INSERT INTO PACKET (PACKETID, FOLDERID) VALUES (?, ?) RETURNING ID");
    FdbStatement stFolder = GetStatement();
    stFolder.Prepare("INSERT INTO FOLDER (NAME, ID_PARENT) VALUES (?, ?) RETURNING ID");

    // создать рутовый фолдер
    fdbPacket._rRootId = stFolder.Set(1, fdbPacket._name).SetNull(2).Execute().GetInt(1);
    // создать пакет
    fdbPacket._rId = stPacket.Set(1, fdbPacket._id).Set(2, fdbPacket._rRootId).Execute().GetInt(1);
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
          int folderId = stFolder.Set(1, folder).Set(2, prevFolderId).Execute().GetInt(1);
          fdbPacket._rFolderIdMap[folderPath] = folderId;
        }
      }
  }
  /++++++++++++++++++++++++++++/
  void WriteTempletes(FdbPacket fdbPacket)
  {
    FdbStatement stTemp = GetStatement();
    stTemp.Prepare("INSERT INTO OBJECT (NAME, MODELID, OBJECTTYPEID, PACKETID, FOLDERID, REPRESENTATIONID) VALUES ( ?, ?, ?, ?, ?, ? ) RETURNING ID");
    FdbStatement stAtr = GetStatement();
    stAtr.Prepare("INSERT INTO OBJECTATTRIBUTE (OBJECTID, NUMBER, OLD_NUMBER, ATTRTYPE, ATTRIBUTENAMEID, ATTRIBUTEDESCRIPTIONID, MEASURE, VARNAME, FORMULA, CONCRETEVALUEID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING ID");
    FdbStatement stSize = GetStatement();
    stSize.Prepare("INSERT INTO STANDARDSIZE (OBJECTID, IDENTIFIER, OLD_INDEX, OLD_NAME) VALUES (?, ?, ?, ?) RETURNING ID");
    FdbStatement stVal = GetStatement();
    stVal.Prepare("EXECUTE PROCEDURE WRITE_STD_SIZE_VAL(?,?,?,?,?)");


    foreach (data; fdbPacket._fdbVirtData)
      foreach (FdbTemplate temp; data._templates)
      {
        // создадим темплейт
        int folderId = fdbPacket._rFolderIdMap[temp._folder];
        stTemp.Set(1, temp._name).SetNull(2).Set(3, fdbPacket._rType).Set(4, fdbPacket._rId).Set(5, folderId).Set(6, _repId);
        temp._rId = stTemp.Execute().GetInt(1);

        // создадим атрибуты для темплейта
        int[] atrIdList;
        foreach (atr; data._atrs)
        {
          stAtr.Set(1, temp._rId).Set(2, atr._num).Set(3, atr._oldNum).Set(4, atr._type).Set(5, atr._rNameId).Set(6, atr._rDescId);
          stAtr.Set(7, "" /+measure+/).Set(8, ""/+var+/).Set(9, "" /+formula+/).SetNull(10);
          int atrId = stAtr.Execute().GetInt(1);
          atrIdList ~= atrId;
        }

        // создадим типоразмеры
        foreach (stdSize; temp._sizes)
        {
          int stdSizeId = stSize.Set(1, temp._rId).Set(2, stdSize._id).Set(3, stdSize._oldIndex).Set(4, stdSize._oldName).Execute().GetInt(1);
          foreach (col, val; stdSize._values)
          {
            if (val._type == SimpleValue.ValueType.Null)
              continue;
            stVal.Set(1, atrIdList[col]);
            stVal.Set(2, stdSizeId);
            val._type == SimpleValue.ValueType.Int ? stVal.Set(3, to!int(val._value)) : stVal.SetNull(3);
            val._type == SimpleValue.ValueType.Double ? stVal.Set(4, to!double(val._value)) : stVal.SetNull(4);
            val._type == SimpleValue.ValueType.String ? stVal.Set(5, val._value) : stVal.SetNull(5);
            stVal.Execute();
          }
        }
      }
  }
  /++++++++++++++++++++++++++++/
  void WriteFiles(FdbPacket fdbPacket)
  {
    _fileStorage.WaitTask;

    return;
    FdbStatement stAddModel = GetStatement();
    stAddModel.Prepare("INSERT INTO MODEL (MODEL, THUMBNAIL, DIGEST, MODEL_VERSION) VALUES( ?, ?, ?, ? ) RETURNING ID");
    FdbStatement stSetModel = GetStatement();
    stSetModel.Prepare("UPDATE OBJECT set MODELID = ? WHERE ID = ?");
    foreach (data; fdbPacket._fdbVirtData)
      foreach (FdbTemplate temp; data._templates)
      {
        if (temp._model.length == 0)
          continue;
        
        file_info model;// = _fileStorage.GetModel(temp._model);
    /+    if (int* findModelId = model.digest in _cache_modelId_byHash)
        {
          stSetModel.Set(1, *findModelId).Set(2, temp._rId).Execute();
        }
        else
        {
          stAddModel.SetBlobAsData(1, model.data, model.dataLen).SetBlobAsData(2, model.icon, model.iconLen).Set(3, model.digest).Set(4, 2);
          int modelId = stAddModel.Execute.GetInt(1);
          _cache_modelId_byHash[model.digest] = modelId;

          stSetModel.Set(1, modelId).Set(2, temp._rId).Execute();
        }+/
      }
  }
}