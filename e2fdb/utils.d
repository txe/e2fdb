module utils;
private import core.sys.windows.windows;
private import std.conv;
private import std.string;
private import std.stdio;
private import std.file;
private import std.array;
private import std.string;
private import std.digest.md;

private extern(Windows) int MultiByteToWideChar(uint, int, char*, int, wchar*, int);
private extern(Windows) int WideCharToMultiByte(uint, int, immutable(wchar)*, int, char*, int, int, int); 

/++++++++++++++++++++++++++++/
string getMD5(wstring filePath)
{
  MD5 md5;
  md5.start();
  auto bytes = cast(ubyte[]) read(to!string(filePath));
  md5.put(bytes);
  ubyte[16] digest = md5.finish;
  char[] str = digest.toHexString;
  return to!string(str);
}
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
char[] toAnsii(wstring s, uint codePage)
{
  char[] result;

  result.length = WideCharToMultiByte(codePage, 0, s.ptr, s.length, null, 0, 0, 0);
  if (result.length)
  {
    int readLen = WideCharToMultiByte(codePage, 0, s.ptr, s.length, result.ptr, result.length, 0, 0);
    if (readLen != result.length)
      throw new Exception("toAnsii: не смогли сконвертировать текст");
  }

  return result;
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