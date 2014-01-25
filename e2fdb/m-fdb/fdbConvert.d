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
        packet._name = s._baseName; // добавить проверку
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

}