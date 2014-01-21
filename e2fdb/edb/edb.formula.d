module edb.formula;

private import std.variant;
private import std.string;
private import std.conv;

/++++++++++++++++++++++++++++/
class ASTree
{
private:
  Variant  _data;
  ASTree[] _childs;

public:
  ASTree find(Variant data)
  {
    foreach (child; _childs)
      if (child._data == data)
        return child;
    return null;
  }
  ASTree add(Variant data)
  {
    auto child = new ASTree();
    child._data = data;
    _childs ~= child;
    return child;
  }
}

/++++++++++++++++++++++++++++/
class EdbFormulaParser
{
  private wstring _strFormula;

  public ASTree Parse(wstring formula)
  {
    if (formula == "")
      return null;
    _strFormula = formula;

    ASTree ast = new ASTree;
    if (RecParse(formula, ast))
      return ast;
    return null;
  }

  private bool RecParse(wstring formula, ASTree ast)
  {
    if (formula == "")
      return false;

    wstring str;
    for (int i = 0; i < formula.length; ++i)
    {
      wchar ch = formula[i];
      if (ch == '"')
      {
        int pos = formula.indexOf('"', i + 1);
        if (pos == -1)
          throw new Exception("PARSE-FORMULA: не найдена закрывающая кавычка после открывающей, позиция " ~ to!string(i) ~ " формула: " ~ to!string(_strFormula));
        str = formula[i+1 .. pos];
        i = pos; // не увеличивать
      }
      else if (ch == '+' || ch == '-' || ch == '*' || ch == '/')
      {
        ast._data = ch;
        // возможно левую ветвь уже загрузили - скобки
        // если еще нет, то туда поместим накопленное
        if (ast._childs.length == 0)
          ast.add(Variant(str));
        return RecParse(formula[i + 1 .. $], ast.add(Variant("")));
      }
      else if (ch == '(')
      {
        if (ast._childs.length)
          throw new Exception("PARSE-FORMULA: повторно встретилась открывающая скобка после открывающей, позиция " ~ to!string(i) ~ " формула: " ~ to!string(_strFormula));
        // найдем закрывающую скобку
        int bracket = 1;
        int j = i + 1;
        for (; j < formula.length; ++j)
          if (formula[j] == '(')
            ++bracket;
          else if (formula[j] == ')')
          {
            --bracket;
            if (bracket <= 0)
              break;
          }
        if (bracket > 0)
          throw new Exception("PARSE-FORMULA: не встретилась закрывающая скобка после открывающей, позиция " ~ to!string(i) ~ " формула: " ~ to!string(_strFormula));
        // если скобки вокруг ВСЕГО выражения, то их не учитываем
        if (i == 0 && j == formula.length - 1 && formula.length > 2)
          return RecParse(formula[1 .. $ - 1], ast);
        // иначе загрузим в левую часть дерева
        if (!RecParse(formula[i + 1 ..  j], ast.add(Variant(""))))
          return false;
        i = j;
      }
      else
        str ~= ch;
    }

    if (str != "")
      ast._data = str.strip;

    return true;
  }
}