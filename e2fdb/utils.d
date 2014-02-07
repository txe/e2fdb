module utils;
private import core.sys.windows.windows;
private import std.conv;
private import std.string;
private import std.stdio;
private import std.array;

private extern(Windows) int MultiByteToWideChar(uint, int, char*, int, wchar*, int); 

/++++++++++++++++++++++++++++/
wstring toUtf(char[] s, uint codePage)
{
  wchar[] result;

  result.length = MultiByteToWideChar(codePage, 0, s.ptr, s.length, null, 0);
  if (result.length)
  {
    int readLen = MultiByteToWideChar(codePage, 0, s.ptr, s.length, result.ptr, result.length);
    if (readLen != result.length)
      throw new Exception("toUtf: не смогли сконвертировать текст");
  }
  
  return to!wstring(result);
}
/++++++++++++++++++++++++++++/
// генерирует подключение 
void h2d(string headerFile, string dFile, string key, string className)
{
  auto file = File(headerFile);

  string[] aliass;
  string[] vars;
  string[] constr;

  foreach (buf; file.byLine())
  {
    string line = to!string(buf);
    if (line.strip == "")
    {
      aliass ~= "";
      vars   ~= "";
      constr ~= "";
      continue;
    }
    if (line.indexOf(key) == -1)
      continue;
    line = line[15..$].strip;
    int firstSpace = line.indexOf(key);
    int firstQ     = line.indexOf("(");
    int firstC     = line.indexOf(";");

    string fn_begin = line[0..firstSpace-1];
    string fn_name  = line[firstSpace..firstQ].strip;
    string fn_body  = line[firstQ..firstC];

    aliass ~= "alias " ~ fn_begin ~ " function" ~ fn_body ~ " " ~ fn_name ~ "_fp;";
    vars   ~= "  " ~ fn_name ~ "_fp " ~ fn_name ~ ";";
    constr ~= "    " ~ fn_name ~ " = cast(" ~ fn_name ~ "_fp) GetProcAddress(_module, \"" ~ fn_name ~ "\");";
    constr ~= "    if (" ~ fn_name ~ " == null) throw new Exception(\"" ~ fn_name ~" == null\");";
  }
  
  string text;
  text ~= aliass.join("\n");
  text ~= "\nclass " ~ className ~
          "\n{"~
          "\n";
  text ~= vars.join("\n") ~
          "\n  this(string name)" ~
          "\n  {" ~
          "\n    _modele = LoadLibraryA(" ~ "name" ~");" ~
          "\n    ";
  text ~= constr.join("\n");
  text ~= "\n  }" ~
          "\n}";
  File(dFile, "w").write(text);
}