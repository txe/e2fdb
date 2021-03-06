module fdb.fdbStructure;
private import edb.structure;

/++++++++++++++++++++++++++++/
class FdbPacket
{
  wstring       _id = null;
  wstring       _name = null;
  wstring       _type = null;
  FdbVirtData[] _fdbVirtData;

  int           _rId;
  int           _rRootId;
  int[wstring]  _rFolderIdMap; // все создаваемые фолдеры будут здесь прописаны, что бы уменьшить кол-во проверок
  int           _rType;
}
/++++++++++++++++++++++++++++/
class FdbVirtData
{
  int            _num; // номер соответсвует номеру DATA
  FdbAttribute[] _atrs;
  FdbTemplate[]  _templates;
}
/++++++++++++++++++++++++++++/
class FdbTemplate
{
  wstring      _folder = null;
  wstring      _name = null;
  FdbStdSize[] _sizes;
  wstring      _model;
  FdbFrw[]     _frws;

  int          _rId;
}
/++++++++++++++++++++++++++++/
class FdbAttribute
{
  enum Type {Int = 1, Double = 2, String = 3}

  int     _num;
  int     _oldNum = 0;
  Type    _type;
  wstring _name = null;
  wstring _desc = null;
  wstring _measure = null;
  wstring _variable = null;
  wstring _formula = null;
  SimpleValue _value;

  int _rNameId;
  int _rDescId;
}
/++++++++++++++++++++++++++++/
class FdbStdSize
{
  SimpleValue[] _values;
  wstring       _id;
  wstring       _oldIndex;
  wstring       _oldName;
  wstring       _pdf;
  wstring       _jpg;

  this(SimpleValue[] values, wstring id, wstring oldIndex, wstring oldName, wstring jpg, wstring pdf)
  {
    _values = values;
    _id = id;
    _oldIndex = oldIndex;
    _oldName = oldName;
    _pdf = pdf;
    _jpg = jpg;
  }
}

/++++++++++++++++++++++++++++/
class FdbFrw
{
  wstring path;
  wstring name;
  int     view;

  this(wstring _path, wstring _name, int _view)
  {
    path = _path;
    name = _name;
    view = _view;
  }
}
/++++++++++++++++++++++++++++/
/++++++++++++++++++++++++++++/
/++++++++++++++++++++++++++++/

