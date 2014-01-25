module edb.parser;

private import std.stdio;
private import std.file;
private import std.string;
private import std.typecons;
private import std.algorithm : replace;
private import std.conv;
private import std.path;

private import edb.structure;
private import edb.formula;
private import utils;

/++++++++++++++++++++++++++++/
private alias Tuple!(wstring, "key", wstring, "value") KeyValue;

/++++++++++++++++++++++++++++/
class EdbFileParserException : Exception
{
  this(string msg)  { super(msg); }
  this(wstring msg) { super(to!string(msg)); }
}

/++++++++++++++++++++++++++++/
class EdbParserException : Exception
{
  this(string msg, int row = -1, wstring line = "")
  { 
    super(msg);
    _row   = row;
    _line  = line;
  }
  this(wstring msg, int row = -1, wstring line = "") 
  { 
    super(to!string(msg));
    _row = row;
    _line = line;
  }

  int      _row;
  wstring  _line;
}

/++++++++++++++++++++++++++++/
struct EdbParser
{
 private:
  EdbSection[] _sections;
  int          _curRow = -1;

private:
  void SetCurRow(int row) { _curRow = row; }
  int GetCurRow()
  {
    if (_curRow == -1)
      throw new EdbParserException("EdbParser: обратились к GetCurRow раньше времени");
    return _curRow;
  }

public:
  
  /+--------------------------+/
  EdbStructure Parse(string edbPath)
  {
    //writeln(edbPath);
    auto bytes = cast(char[]) read(edbPath);
    auto text  = utils.toUtf(bytes, 1251);
    auto lines = splitLines(text);

    EdbSection section = null;
    bool isComment = false;

    // построчно парсим файл
    foreach (index, line; lines) 
    {
      SetCurRow(index);

      //writeln(index);
      //if (baseName(edbPath) == "Заглушки до 500 мм ОСТ 36-47-81.edb" && index == 100)
      //  isComment = isComment;

      line = line.strip;
      try 
      {
        if (IsSkipLine(line))
          continue;

        if (isComment) 
        {
          if (IsCommentEnd(line))
            isComment = false;
          else
            InComment(section, line);
        }
        else if (IsCommentBegin(line))
          isComment = true;
        else if (section is null)
        {
          section = IsSectionBegin(line);
          // TODO: добавить проверку что таких секций нет больше
        }
        else if (IsSectionEnd(line))
          section = null;
        else if (auto s = cast(IdSection) section)    ParseIdSection(s,    line);
        else if (auto s = cast(TreeSection) section)  ParseTreeSection(s,  line);
        else if (auto s = cast(DataSection) section)  ParseDataSection(s,  line);
        else if (auto s = cast(PropSection) section)  ParsePropSection(s,  line);
        else if (auto s = cast(SpecSection) section)  ParseSpecSection(s,  line);
        else if (auto s = cast(AliasSection) section) ParseAliasSection(s, line);
      }
      catch (EdbParserException e)
      {
        throw new EdbParserException(e.msg, index, line);
      }
      catch (Exception e)
      {
        throw new EdbParserException(e.msg, index, line);
      }
    }

    // делаем дополнительные проверки
    try
    {
      foreach (s; _sections)
        if (auto dataSection = cast(DataSection) s)
        {
          ChechAttInComment(dataSection);
          CalculateTypeList(dataSection);
        }
    }
    catch (Exception e)
      throw e;


    auto edbFile = EdbStructure();
    edbFile._sections = _sections;
    return edbFile;
  }

private:
  /+--------------------------+/
  bool IsSkipLine(wstring line) 
  { 
    return line == "" || startsWith(line, "//"); 
  }
  /+--------------------------+/
  bool IsCommentBegin(wstring line) 
  { 
    return startsWith(line, "/*"); 
  }
  /+--------------------------+/
  void InComment(EdbSection section, wstring line) 
  { 
    if (auto s = cast(DataSection) section)
      ParseDataSectionComment(s, line);
  }
  /+--------------------------+/
  bool IsCommentEnd(wstring line) 
  { 
    return startsWith(line, "*/"); 
  }
  /+--------------------------+/
  EdbSection IsSectionBegin(wstring line) 
  { 
    if (!startsWith(line, "[") || !endsWith(line, "]"))
      return null;

    EdbSection section = null;
    auto pos = line.indexOf("_");
    if (pos != -1)
    {
      wstring name = line[1..pos];
      int num = to!int(line[pos+1 .. $-1]);
      switch (name)
      {
        case "DATA":          section = new DataSection(num); break;
        case "PROPERTIES":    section = new PropSection(num); break;
        case "SPECIFICATION": section = new SpecSection(num); break;
        default: break;
      }
    }
    if (section is null)
    {
      wstring name = line[1 .. $-1];
      switch (name)
      {
        case "TREE":  section = new TreeSection;  break;
        case "ALIAS": section = new AliasSection; break;
        case "ID":    section = new IdSection;    break;
        default: throw new EdbParserException("Неизвестная секция в файле: " ~ line);
       }
    }
    _sections ~= section;
    return section;
  }
  /+--------------------------+/
  bool IsSectionEnd(wstring line) 
  { 
    return line == "[END]"; 
  }
  /+--------------------------+/
  void ParseIdSection(IdSection section, wstring line) 
  {
    KeyValue* param = ParseKeyValue(line);
    if (param is null)
      throw new EdbParserException("Ошибка в описании параметра: " ~ line);
    switch (param.key)
    {
      case "BASE_ID":   section._baseId   = param.value; break;
      case "BASE_NAME": section._baseName = param.value; break;
      case "BASE_TYPE":  
       // if (param.value == "SEGMENT" || param.value == "ELEMENT" || param.value == "VENTBOX")
          section._baseType = param.value;
      //  else
      //    throw new EdbParserException("Ошибочная значение параметра BASE_TYPE: " ~ param.value);
        break;
      default: throw new EdbParserException("Неизвестный параметр: " ~ param.key);
    }
  };
  /+--------------------------+/
  void ParseTreeSection(TreeSection section, wstring line) 
  {
    auto params = split(line, "#");
    if (params.length >= 3)
      section._params ~= params;
  };
  /+--------------------------+/
  void ParseDataSection(DataSection section, wstring line) 
  {
    if (!ParseDataSectionParam(section, line))
      ParseDataSectionElement(section, line);
  };
  /+--------------------------+/
  void ParseDataSectionComment(DataSection section, wstring line)
  {
    wstring[] words = line.split(" ");
    if (words.length < 3)
      return;
    // первая часть должна быть числом
    static auto ints = "0123456789";
    foreach (ch; words[0])
      if (ints.indexOf(ch) == -1)
        return;
    // потом черта
    if (words[1] != "-")
      return;

    int num = to!int(words[0]);
   
    // возьмем данные послед черты
    line = line[line.indexOf("-") .. $];
    words = line.split("|");

    auto atr = new AtrInComment();
    if (words.length > 0) atr.name = words[0].strip;
    if (words.length > 1) atr.desc = words[1].strip;
    if (words.length > 2) atr.formula = words[2].strip;
    if (atr.name.length == 0)
      atr.name = "Безымянный атрибут";

    // проверка на повторяемость
    if (section._atrs.length == 0)
      if (num != 0)
        throw new EdbParserException("DATA_" ~ to!wstring(num) ~ ": номер первого атрибута в комментариях должно начинатся с нуля");

    if (num > 0)
      if (!((num - 1) in section._atrs))
        throw new EdbParserException("DATA_" ~ to!wstring(num) ~ ": номер атрибута в комментариях должно должно быть больше на 1, чем предыдущий атрибут");

    section._atrs[num] = atr;
  }
  /+--------------------------+/
  bool ParseDataSectionParam(DataSection section, wstring line)
  {
    KeyValue* param = ParseKeyValue(line);
    if (param is null || param.key.length == 0 || param.value.length == 0)
      return false;
    if (param.key[0] == '"')
      return false;

    wstring ParseEditValue(wstring value)
    {
      if (endsWith(value, "-"))
        return null;
      if (startsWith(value, "P"))
      {
        int i0 = value.indexOf("[");
        int i1 = value.lastIndexOf("]");
        if (i0 == -1 || i0 >= i1)
          throw new EdbParserException("DATA_" ~ to!wstring(section._num) ~ ": ошибка в описании параметра " ~ value);
        return value[i0+1 .. i1];
      }
      int i0 = value.indexOf("\"");
      int i1 = value.lastIndexOf("\"");
      if (i0 == -1 || i0 >= i1)
        throw new EdbParserException("DATA_" ~ to!wstring(section._num) ~ ": ошибка в описании параметра: " ~ value);
      return value[i0 + 1 .. i1];
    }

    switch (param.key)
    {
      case "NAME_EDIT_1":       section._lengthName = param.value; break;
      case "NAME_EDIT_2":       section._widthName  = param.value; break;
      case "NAME_EDIT_3":       section._heightName = param.value; break;
      case "EDIT_1", "EDIT_1-": section._paramEdit1 = ParseEditValue(param.value); break;
      case "EDIT_2", "EDIT_2-": section._paramEdit2 = ParseEditValue(param.value); break;
      case "EDIT_3", "EDIT_3-": section._paramEdit3 = ParseEditValue(param.value); break;
      case "CONTROL_PARAM":     section._paramControl = to!int(param.value[1 .. $]); break;
      case "TYPES":
        if (section._elements.length != 0)
          throw new EdbParserException("DATA_" ~ to!wstring(section._num) ~ ": параметр TYPES должен быть объявлен ранее типоразмеров");
        foreach (index, t; param.value)
          if (t != 'F' && t != 'I' && t != 'S')
            throw new EdbParserException("DATA_" ~ to!wstring(section._num) ~ ": параметр TYPES содержит неизвестный символ (" ~ t ~ ") в позиции " ~ to!wstring(index));
        section._typeList = param.value;
        break;
      case "FOLDER":
        if (section._elements.length > 0 && section._elements[$-1]._simples.length == 0)
          throw new EdbParserException("DATA_" ~ to!string(section._num) ~ ": между текущим и предыдущим FOLDERом не было типоразмеров");
        auto e = section.AddElement();
        int pos = param.value.lastIndexOf("|");
        if (pos == -1)
        {
          e._name = param.value;
          e._folder = "";
        }
        else
        {
          e._name = param.value[pos + 1 .. $];
          e._folder = param.value[0 .. pos];
        }
        break;
      case "PROJECTION":
        if (section._elements.length == 0 || section._elements[$-1]._folder is null)
          throw new EdbParserException("DATA_" ~ to!wstring(section._num) ~ ": перед параметром PROJECTION должен стоять параметр FOLDER");
        int pos0 = param.value.indexOf("|");
        int pos1 = param.value.indexOf("|", pos0+1);
        if (pos0 == -1 || pos1 == -1)
          throw new EdbParserException("DATA_" ~ to!wstring(section._num) ~ ": ошибка в описании параметра PROJECTION: " ~ param.value);
        int t = to!int(param.value[0 .. pos0]);
        wstring name = param.value[pos0 + 1 .. pos1];
        wstring path = param.value[pos1 + 1 .. $];
        auto prj = new DataSectionElement.Prj(t, name, path);
        section._elements[$-1]._prjs ~= prj;
        break;
      case "COMMENT_FIELD1": section._paramComment1 = param.value; break;
      case "COMMENT_FIELD2": section._paramComment2 = param.value; break;
      default:
        if (param.key.length < 30 && param.key.indexOf(" ") == -1)
          throw new EdbParserException("DATA_" ~ to!wstring(section._num) ~ ": неизвестный параметр " ~ param.key);
        return false;
    }
    return true;
  }
  /+--------------------------+/
  void ParseDataSectionElement(DataSection section, wstring line)
  {
    if (section._elements.length == 0)
      throw new EdbParserException("DATA_" ~ to!string(section._num) ~ ": отсутствует начальный FOLDER");

    wstring[] values = SmartSplit(line);
    if (values.length < 10)
      throw new EdbParserException("DATA_" ~ to!string(section._num) ~ ": слишком короткая строка типоразмера");

    if (section._typeList.length != 0)
      if (section._typeList.length != values.length)
        throw new EdbParserException("DATA_" ~ to!string(section._num) ~ ": кол-во атрибутов в типоразмере (" ~ to!string(values.length) ~") не совпадает c длиной строки типов (" ~ to!string(section._typeList.length) ~ ")");
    // не правильно работает из за simple
    //if (section._typeList.length == 0)
    //  if (section._elements.length > 0 && section.elements[0].simples.length > 0)
    //    if (section._elements[0]._simples.length != values.length)
    //      throw new EdbParserException("DATA_" ~ to!string(section._num) ~ ": кол-во атрибутов в типоразмере (" ~ to!string(values.length) ~") не совпадает c кол-вом атрибутов в предыдущего типоразмера (" ~ to!string(section.elements[0].simples.length) ~ ")");

    section._elements[$-1]._simples[GetCurRow()] = values;
  }
  /+--------------------------+/
  void ParsePropSection(PropSection section, wstring line) 
  {
    if (line == "END")
      return;

    wstring[] words = SmartSplit(line);
    if (words.length < 2)
      throw new EdbParserException("PROPERTIES_" ~ to!wstring(section._num) ~ ": неверный формат, не найден пробел");

    auto typeName = words[0];
    auto propType = PropSection.PropType.NONE;
    if (startsWith(typeName,      "GROUP")) propType = PropSection.PropType.GROUP;
    else if (startsWith(typeName, "EDIT"))  propType = PropSection.PropType.EDIT;
    else if (startsWith(typeName, "COMBO")) propType = PropSection.PropType.COMBO;
    else if (startsWith(typeName, "CHECK")) propType = PropSection.PropType.CHECK;
    else throw new EdbParserException("PROPERTIES_" ~ to!wstring(section._num) ~ ": неверный формат, неизвестный тип " ~ typeName);

    int enable  = endsWith(typeName, "-");
    int visible = endsWith(typeName, "#");

    wstring name = words[1];
    if (name.length < 3 || name[0] != '"' || name[$-1] != '"')
      throw new EdbParserException("PROPERTIES_" ~ to!wstring(section._num) ~ ": неверный формат, не найдено наименование");
    name = name[1 .. $-2];

    // обработаем остальное
    int atrNum = -1, menuNum = -1;
    wstring propParam, propAdd;
    for (int i = 2; i < words.length; ++i)
    {
      // атрибуты начинаются с 1 надо с 0
      wstring word = words[i];
      if (word[0] == 'A')
        atrNum = to!int(word[1..$]);
      else if (word[0] == 'G' && word.length > 1)
        menuNum = to!int(word[1..$]);
      else if (word[0] == 'L')
        propAdd = word[1..$];
      else if (word[0] == '"' && word[$-1] == '"')
        propAdd = word[1..$-2];
      else if (startsWith(word, "P[") && word[$-1] == ']')
        propParam = word[2 .. $-2];
      else 
        throw new EdbParserException("PROPERTIES_" ~ to!wstring(section._num) ~ ": неверный формат, неизвестный параметр " ~ word);

      // бла бла надо добавить в список
    }
  }
  /+--------------------------+/
  void ParseSpecSection(SpecSection section, wstring line) 
  {
    KeyValue* val = ParseKeyValue(line);
    if (val is null)
      throw new EdbParserException("SPECIFICATION_" ~ to!wstring(section._specNum) ~ ": неверный формат, неизвестный параметр " ~ line);

    switch (val.key)
    {
      case "LIB_NAME":    section._libName    = val.value; break;
      case "FIRST_PART":  section._firstPart  = to!int(val.value); break;
      case "SECOND_PART": section._secondPart = to!int(val.value); break;
      default: // например - COLUMN_10
        if (!startsWith(val.key, "COLUMN_"))
          throw new EdbParserException("SPECIFICATION_" ~ to!wstring(section._specNum) ~ ": неверный формат, неизвестный параметр " ~ val.key);
        
        int columnNum = to!int(val.key[7 .. $]);
        wstring[] words = split(val.value, "|");
        foreach (word; words)
        {
          int pos0 = word.lastIndexOf('[');
          int pos1 = word.lastIndexOf(']');
          if (pos0 < 1 || pos1 < 1 || pos0 > pos1)
            throw new EdbParserException("SPECIFICATION_" ~ to!wstring(section._specNum) ~ ": неверная структура " ~ word);
          int dataNum = to!int(word[pos0+1 .. pos1]);
          int index = dataNum * 10000 + columnNum;
          if (index in section._columns)
            throw new EdbParserException("SPECIFICATION_" ~ to!wstring(section._specNum) ~ ": уже есть значение колонки " ~ to!wstring(columnNum) ~ " для DATA_" ~ to!wstring(dataNum));
          section._columns[index] = word[0 .. pos0];
          (new EdbFormulaParser).Parse(word[0 ..  pos0]);
        }
    }
  }
  /+--------------------------+/
  void ParseAliasSection(AliasSection section, wstring line) 
  {
    section._params[GetCurRow] = line;
    KeyValue* param = ParseKeyValue(line);
    if (param is null)
      throw new EdbParserException("ALIAS: неверный формат, не найден = в " ~ line);

    // проверим наличие []|
    int beginPos = 0;
    for (;;)
    {
      int pos = param.value.indexOf("|", beginPos);
      if (pos == -1)
        break;

      // слева или [10], или что-то другое если разделитель внутри строки
      bool wasSpace = false;
      CHECK_FOR: for (int i = pos - 1; i >= beginPos; --i)
      {
        auto ch = param.value[i];
        if (ch == ']')
        {
          if (wasSpace)
            throw new EdbParserException("ALIAS: неверный формат, между скобкой и разделителем не должно быть пробела, в позиции " ~ to!wstring(pos));
          break;
        }
        if (ch == ' ')
        {
          wasSpace = true;
          continue;
        }
        static auto ints = "0123456789";
        if (ints.indexOf(ch) != -1)
        {
          for (int k = i - 1; k >= beginPos; --k)
            if (ints.indexOf(param.value[k]) != -1)
              continue;
            else if (param.value[k] == '[')
              throw new EdbParserException("ALIAS: неверный формат, возможно не закрыта скобка перед разделителем, в позиции " ~ to!wstring(pos));
            else break CHECK_FOR;
        }
        if (ch == '[')
          throw new EdbParserException("ALIAS: неверный формат, возможно не закрыта скобка перед разделителем, в позиции " ~ to!wstring(pos));
        if (ch == '{' || ch == '}')
          throw new EdbParserException("ALIAS: неверный формат, возможно используется неверный тип скобок перед разделителем, в позиции " ~ to!wstring(pos));
        break; // если другие символы, то дальше проверять не будем
      }
      beginPos = pos + 1;
    }

    if (line.indexOf("KOMPAS_PROPERTY") != -1)
    {
      // проверим частично формат "XX:YY|GG:VV"
      wstring[] words;
      bool comm = false;
      int beginWord = -1;
      for (int i = 0; i < param.value.length; ++i)
        if (param.value[i] == '"')
        {
          if (comm == false)
          {
            beginWord = i;
            comm = true;
          }
          else
          {
            comm = false;
            words ~= param.value[beginWord .. i];
          }
        }
      if (comm)
        throw new EdbParserException("ALIAS: неверный формат, возможно не закрыта строка");
      
      foreach (wstring word; words)
      {
        if (word.indexOf("||") != -1)
          throw new EdbParserException("ALIAS: неверный формат KOMPAS_PROPERTY, символы || в " ~ word);
        if (word.indexOf("::") != -1)
          throw new EdbParserException("ALIAS: неверный формат KOMPAS_PROPERTY, символы :: в " ~ word);
        if (word.indexOf(":|") != -1)
          throw new EdbParserException("ALIAS: неверный формат KOMPAS_PROPERTY, символы :| в " ~ word);
        if (word.indexOf("|:") != -1)
          throw new EdbParserException("ALIAS: неверный формат KOMPAS_PROPERTY, символы |: в " ~ word);
        int count1 = word.countchars("|");
        int count2 = word.countchars(":");
        if (count2 != count1 + 1)
          throw new EdbParserException("ALIAS: неверный формат KOMPAS_PROPERTY, неверное количество : и |, в строке " ~ word);
      }
    }
  };
  /+--------------------------+/
  KeyValue* ParseKeyValue(wstring line)
  {
    // key = value
    int pos = line.indexOf("=");
    if (pos == -1)
      return null;
    return new KeyValue(line[0 .. pos].strip, line[pos + 1 .. $].strip);
  }
  /+--------------------------+/
  wstring[] SmartSplit(wstring line)
  {
    wstring[] words;

    int  beginWord = -1;
    int  lastWhite = -1; // считаем что перед нулем пробел
    bool comma = false;

    // значение обрамляются или пробелами или кавычками
    for (int i = 0; i < line.length; ++i)
    {
      auto ch = line[i];
      if (ch == '"')
      {
        if (!comma)
        {
          if (lastWhite != i - 1)
            throw new EdbParserException("SPLIT PARSER: неверный формат строки, перед кавычкой (\") должен быть пробел. Позиция символа " ~ to!string(i));
          comma = true;
          beginWord = i;
        }
        else
        {
          comma = false;
          words ~= line[beginWord .. i+ 1];
          beginWord = -1;
          lastWhite = -1;
        }
      }
      else if (!comma)
      {
        if (ch == ' ' || ch == '\t')
        {
          if (lastWhite == i - 1 || beginWord == -1)
            lastWhite = i;
          else
          {
            words ~= line[beginWord .. i];
            beginWord = -1;
            lastWhite = i;
          }
        }
        else if (beginWord == -1)
        {
          if (lastWhite != i - 1)
            throw new EdbParserException("SPLIT PARSER: неверный формат строки, перед символом должен быть пробел. Позиция символа: " ~ to!string(i));
          beginWord = i;
        }
      }
    }

    if (comma)
      throw new EdbParserException("SPLIT PARSER: неверный формат строки, строка не закончилась \"");
    if (beginWord != -1)
      words ~= line[beginWord..$];

    return words;
  }
  /+--------------------------+/
  void ChechAttInComment(DataSection section)
  {
    foreach (DataSectionElement el; section._elements)
      foreach (int row, wstring[] simple; el._simples)
        if (section._atrs.length != simple.length)
          throw new EdbParserException("DATA_" ~ to!string(section._num) ~ ": совпадает кол-во атрибутов (" ~ to!string(section._atrs.length) ~ ") и значений в типоразмере (" ~ to!string(simple.length) ~ ") в строке " ~ to!string(row));
        else
          return;
  }
  /+--------------------------+/
  void CalculateTypeList(DataSection section)
  {
    if (section._typeList.length == 0)
    {
      return;
      //throw new EdbParserException("Нет TYPES");
    }
    // кол-во атрибутов в типеразмере уже проверили при чтении
    foreach (DataSectionElement el; section._elements)
      foreach (int row, wstring[] simple; el._simples)
        foreach (int col, wstring val; simple)
        {
          if (val == "\" \"" || val == "\"-\"")
            continue;
          // если тип S, то должны быть кавычки
          if (section._typeList[col] == 'S')
            if (!startsWith(val, '"'))
            {
              int five = section._typeList.length > (col + 5) ? 5 : section._typeList.length - col;
              wstring line = "... " ~ join(simple[col .. col + five], " ") ~ " ...";
              //throw new EdbParserException("DATA_" ~ to!wstring(section.num) ~ ": атрибут имеет тип 'S', но записан без кавычек, номер " ~ to!wstring(col) ~ " из " ~ to!wstring(section.typeList.length), row, line);
            }
          // если тип не S, то кавычки не должны быть
          if (section._typeList[col] != 'S')
            if (startsWith(val, '"'))
            {
              int five = section._typeList.length > (col + 5) ? 5 : section._typeList.length - col;
              wstring line = "... " ~ join(simple[col .. col + five], " ") ~ " ...";
              throw new EdbParserException("DATA_" ~ to!wstring(section._num) ~ ": атрибут имеет тип '"~ section._typeList[col] ~"', хотя записан с кавычками, номер " ~ to!wstring(col) ~ " из " ~ to!wstring(section._typeList.length), row, line);
            }
        }
  }
}
