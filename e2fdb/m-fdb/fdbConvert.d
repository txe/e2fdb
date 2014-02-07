module fdb.fdbConvert;

import edb.structure;
import fdb.fdbStructure;
private import std.path;
private import std.file;
private import std.string;
private import std.conv;

struct FdbConvert
{
public:
  /++++++++++++++++++++++++++++/
  FdbPacket Convert(EdbStructure edbStruct)
  {
    auto packet = new FdbPacket;

    // имя
    foreach (section; edbStruct._sections)
      if (IdSection s = cast (IdSection) section)
      {
        packet._name = s._baseName;
        packet._id   = s._baseId;
        packet._type = s._baseType;
        if (packet._type == "")
          packet._type = "UNDEFINED";
        break;
      }

    // расположение lfr
    // предположим что лежит в той же папке что и edb
    auto lfrPath = edbStruct._path.stripExtension ~ ".lfr";
    if (!exists(to!string(lfrPath))) // иначе лежит на одну папку выше
      lfrPath = lfrPath.dirName.dirName ~ "\\" ~ lfrPath.baseName;
    if (!exists(to!string(lfrPath)))
      throw new EdbStructException("FdbConvert: не смогли найти lfr: " ~ to!string(packet._name));
    // папка где лежит edb
    auto edbFolder = edbStruct._path.dirName;

    // найдем расположение формул
    AliasSection aliasSection = null;
    foreach (section; edbStruct._sections)
      if (AliasSection s = cast (AliasSection) section)
      {
        aliasSection = s;
        break;
      }

    // обработаем каждую дату
    foreach (section; edbStruct._sections)
      if (DataSection s = cast (DataSection) section)
      {
        auto virtData = new FdbVirtData;
        virtData._num = s._num;
        CreateTableAttr(virtData, s);
        CreateFormulaAttr(virtData, aliasSection);
        CreateOtherAttr(virtData, s);

        foreach (elm; s._elements)
          CreateTemplate(virtData, elm, lfrPath, edbFolder);

        packet._fdbVirtData ~= virtData;
      }

    return packet;
  }

private:
  /++++++++++++++++++++++++++++/
  void CreateTableAttr(FdbVirtData virtData, DataSection sec)
  {
    foreach (int i, edbAtr; sec._atrs)
    {
      auto atr = new FdbAttribute;
      atr._num = i;
      atr._name = edbAtr.name;
      atr._desc = edbAtr.desc;

      if (sec._typeList[i] == 'S')       atr._type = FdbAttribute.Type.String;
      else if (sec._typeList[i] == 'I')  atr._type = FdbAttribute.Type.Int;
      else if (sec._typeList[i] == 'F')  atr._type = FdbAttribute.Type.Double;

      virtData._atrs ~= atr;
    }
  }
  /++++++++++++++++++++++++++++/
  void CreateFormulaAttr(FdbVirtData virtData, AliasSection sec)
  {
    if (sec is null)
      return;
  }
  /++++++++++++++++++++++++++++/
  void CreateOtherAttr(FdbVirtData virtData, DataSection sec)
  {

  }
  /++++++++++++++++++++++++++++/
  void CreateTemplate(FdbVirtData virtData, DataSectionElement elm, wstring lfrPath, wstring edbFolder)
  {
    auto temp = new FdbTemplate;
    temp._name   = elm._name[0..1].toUpper ~ elm._name[1..$];
    temp._folder = elm._folder;
    
    bool buildPath(ref wstring fileName, wstring path)
    {
      if (fileName == "")
        return true;
      fileName = to!wstring(buildNormalizedPath(to!string(path ~ fileName)));
      return exists(to!string(fileName));
    }

    // проверим что 3D у все одинаковое
    temp._model = elm._simples.byValue.front[2]._value;
    foreach (row, simple; elm._simples)
      if (temp._model != simple[2]._value)
        throw new EdbStructException("DATA_" ~ to!wstring(virtData._num) ~ ": m3d типоразмера (" ~ simple[2]._value ~") не совпадает с m3d темплейта (" ~ temp._model ~ ")", row);
    if (!buildPath(temp._model, edbFolder ~ "\\M3d\\"))
        throw new Exception("DATA_" ~ to!string(virtData._num) ~ ": не смогли найти m3d: " ~ to!string(temp._model));

    foreach (row, simple; elm._simples)
    {
      // вычислим ID для типоразмера
      // TODO: if (IsEngSys) id = simple(11);
      wstring id = simple[0]._value;
      wstring oldIndex = "";
      wstring oldName  = "";
      wstring[] words  = id.split("#");
      if (words.length > 1)
      {
        if (words.length != 3) // если и разделится, то только на три части
          throw new EdbStructException("DATA_" ~ to!wstring(virtData._num) ~ ": неверный формат id типоразмера", row);
        id = words[0];
        oldIndex = words[1];
        oldName = words[2];
      }

      wstring jpg = simple[3]._value;
      if (!buildPath(jpg, edbFolder ~ "\\Jpg\\"))
        throw new EdbStructException("DATA_" ~ to!wstring(virtData._num) ~ ": не смогли найти jpg: " ~ temp._model, row);
      wstring pdf = simple[4]._value;
      if (!buildPath(pdf, edbFolder ~ "\\Pdf\\"))
        throw new EdbStructException("DATA_" ~ to!wstring(virtData._num) ~ ": не смогли найти pdf: " ~ pdf, row);

      temp._sizes ~= new FdbStdSize(simple, id, oldIndex, oldName, jpg, pdf);
    }

    virtData._templates ~= temp;
  }
  /++++++++++++++++++++++++++++/



}