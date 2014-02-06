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
      throw new Exception("FdbConvert: не смогли найти lfr для " ~ to!string(packet._name));
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
    foreach (row, simple; elm._simples)
    {
      // if (IsEngSys) id = simple(11);
      wstring id = simple[0]._value;
      wstring oldIndex = "";
      wstring oldName = "";
      wstring[] words = id.split("#");
      if (words.length > 1)
      {
        if (words.length != 3) // если и разделится, то только на три части
          throw new Exception("fdbConvert: ошибка определения id типоразмера");
        id = words[0];
        oldIndex = words[1];
        oldName = words[2];
      }
      temp._sizes ~= new FdbStdSize(simple, id, oldIndex, oldName, "", ""); // не забыть проверить что бы все 3d было у всех одинаковым ))
    }

    virtData._templates ~= temp;
  }
  /++++++++++++++++++++++++++++/



}