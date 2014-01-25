module edb.structure;

private import std.stdio;
private import std.conv;

/++++++++++++++++++++++++++++/
class EdbSection 
{
}
/++++++++++++++++++++++++++++/
class IdSection : EdbSection 
{
  wstring _baseId   = null;
  wstring _baseName = null;
  wstring _baseType = null;
}
/++++++++++++++++++++++++++++/
class TreeSection : EdbSection 
{
  wstring[][] _params;
}
/++++++++++++++++++++++++++++/
class DataSectionElement
{
  static class Prj 
  { 
    this(int typeNum, wstring name, wstring path) 
    { 
      _typeNum = typeNum; 
      _name = name; 
      _path = path; 
    }
  
    int     _typeNum; 
    wstring _name; 
    wstring _path; 
  }

  wstring _name;
  wstring _folder = null;
  Prj[]   _prjs;
  wstring[][int] _simples;
}
/++++++++++++++++++++++++++++/
class DataSection : EdbSection 
{
  int     _num;
  wstring _lengthName = "Длина, мм";
  wstring _widthName  = "Ширина, мм";
  wstring _heightName = "Высота, мм";
  wstring _paramEdit1;
  wstring _paramEdit2;
  wstring _paramEdit3;
  int     _paramControl;
  wstring _paramComment1;
  wstring _paramComment2;
  wstring[] _comments;
  wstring _typeList;
  DataSectionElement[] _elements;

  DataSectionElement AddElement()
  {
    auto e = new DataSectionElement;
    _elements ~= e;
    return e;
  }

  this(int num) { _num = num; }
}
/++++++++++++++++++++++++++++/
class PropSection : EdbSection 
{
  enum PropType {NONE, GROUP, EDIT, COMBO, CHECK};
  
  int _num;
  this(int num) { _num = num; }
}
/++++++++++++++++++++++++++++/
class SpecSection : EdbSection 
{
  int          _specNum;
  wstring      _libName;
  int          _firstPart;
  int          _secondPart;
  wstring[int] _columns; // ключ: номер-даты * 10000 + номер колонки

  this(int num) { _specNum = num; }
}
/++++++++++++++++++++++++++++/
class AliasSection :EdbSection 
{
  wstring[int] _params;
}
/++++++++++++++++++++++++++++/
struct EdbStructure
{
  EdbSection[] _sections;
}

