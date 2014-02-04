module fdb.fdbConvert;

import edb.structure;
import fdb.fdbStructure;

struct FdbConvert
{
public:
  /++++++++++++++++++++++++++++/
  FdbPacket Convert(EdbStructure edbStruct)
  {
    FdbPacket packet;

    // имя
    foreach (section; edbStruct._sections)
      if (IdSection s = cast (IdSection) section)
      {
        packet._id = s._baseId;     // добавить проверку
        packet._name = s._baseName; // добавить проверку
        if (packet._id.length == 0)
          packet._id = packet._name;
        break;
      }

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
        FdbVirtData virtData;
        CreateTableAttr(virtData, s);
        CreateFormulaAttr(virtData, aliasSection);
        CreateOtherAttr(virtData, s);

        foreach (elm; s._elements)
          CreateTemplate(virtData, elm);
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
  void CreateTemplate(FdbVirtData virtData, DataSectionElement elm)
  {

  }
  /++++++++++++++++++++++++++++/



}