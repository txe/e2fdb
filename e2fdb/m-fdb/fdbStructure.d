module fdb.fdbStructure;
private import edb.structure;

/++++++++++++++++++++++++++++/
class FdbPacket
{
  wstring       _id = null;
  wstring       _name = null;
  FdbVirtData[] _fdbVirtData;    
}
/++++++++++++++++++++++++++++/
class FdbVirtData
{
  FdbAttribute[] _atrs;
  FdbTemplate[]  _templates;
}
/++++++++++++++++++++++++++++/
class FdbTemplate
{
  wstring      _folder = null;
  wstring      _name = null;
  wstring      _type = null;
  FdbStdSize[] _sizes;
  FdbModel     _model;
  FdbFrw[]     _frws;
}
/++++++++++++++++++++++++++++/
class FdbAttribute
{
  enum Type {Int = 1, Double = 2, String = 3}

  int     _num;
  int     _oldNum;
  Type    _type;
  wstring _name = null;
  wstring _desc = null;
  wstring _measure = null;
  wstring _variable = null;
  wstring _formula = null;
  SimpleValue _value;
}
/++++++++++++++++++++++++++++/
class FdbStdSize
{
  SimpleValue[] _values;
  wstring       _pdf;
  wstring       _jpg;

  this(SimpleValue[] values, wstring pdf, wstring jpg)
  {
    _values = values;
    _pdf = pdf;
    _jpg = jpg;
  }
}
/++++++++++++++++++++++++++++/
class FdbModel
{
  
}
/++++++++++++++++++++++++++++/
class FdbFrw
{

}
/++++++++++++++++++++++++++++/
/++++++++++++++++++++++++++++/
/++++++++++++++++++++++++++++/

