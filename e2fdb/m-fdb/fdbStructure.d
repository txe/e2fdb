module fdb.fdbStructure;

/++++++++++++++++++++++++++++/
class FdbPacket
{
  wstring     _id;
  wstring     _name;
  FdbVirtData _fdbVirtData;    
}
/++++++++++++++++++++++++++++/
class FdbVirtData
{
  FdbAttribute[]         _atrs;
  FdbTemplate[][wstring] _folders;  // folderPath -> FdbTemplates  
}
/++++++++++++++++++++++++++++/
class FdbTemplate
{
  wstring         _name;
  wstring         _type;
  FdbStdSize[]   _sizes;
  FdbModel       _model;
  FdbFrw[]       _frws;
}
/++++++++++++++++++++++++++++/
class FdbAttribute
{
  int    _num;
  int    _oldNum;
  wstring _type;
  wstring _name;
  wstring _desc;
  wstring _measure;
  wstring _variable;
  wstring _formula;
  wstring _value;
}
/++++++++++++++++++++++++++++/
class FdbStdSize
{
  wstring[] _values;
  wstring   _pdf;
  wstring   _jpg;
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

