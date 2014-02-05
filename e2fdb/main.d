import std.stdio;
import std.path;
import std.file;
import std.conv;
import std.string;
import std.parallelism;
import edb.parser;
import helper.fb;
import fdb.writeManager;
import fdb.fdbConvert;

extern(Windows) int SetConsoleOutputCP(uint);

/++++++++++++++++++++++++++++/
string[] get_files(string path, string pattern)
{
  string[] files;
  foreach (file; dirEntries(path, pattern, SpanMode.breadth))
    if (file.isFile())
      files ~= file.name;
  return files;
}
/++++++++++++++++++++++++++++/
bool TestBase(string[] edbFiles)
{
  int count = 0;

  // сперва протестируем все базы
  string[] problems;
  foreach (index, edbFile; edbFiles) //foreach (index, edbFile; taskPool.parallel(edbFiles, 5))
    try
    {
      count += 1;
      write("\rtest: " ~ to!string(count) ~ " of " ~ to!string(edbFiles.length) ~ " file(s), problem(s): " ~ to!string(problems.length));
      stdout.flush();

      auto edbStruct = EdbParser().Parse(edbFile);
      auto fdbStruct = FdbConvert().Convert(edbStruct);
    }
    catch (EdbParserException e)
    { 
      auto txt = "\n*************************\n" ~ e.msg ~ "\nfile:\t" ~ edbFile ~ "\nrow:\t" ~ to!string(e._row == -1 ? -1 : e._row + 1) ~ "\nline:\t" ~ to!string(e._line) ~ "\n*************************";
      problems ~= txt;
    }
    catch (Exception e)
    {
      problems ~= e.msg;
    }

  if (edbFiles.length == 0)
    problems ~= "Отсутствуют файлы";

  if (problems)
    foreach (problem; problems)
      writeln(problem);
  return problems.length == 0;
}
/++++++++++++++++++++++++++++/
int main(string[] argv)
{
  // для генерации кода оберток
  // utils.h2d("c:\\e2fdb-helper.h", "c:\\txt.d", "fdb_", "dbDll");
  // return 0;

  try
  {
    SetConsoleOutputCP(65001);
    const path = "d:\\edb";

    writeln("Collecting files before ...");
    string[] edbFiles = get_files(path, "*.edb");

    if (TestBase(edbFiles))
      WriteManager().Run(edbFiles);
  }
  catch (Exception e)
  {
     writeln(e.msg);
  }

  write("\npress enter to exit:");
  readln();
  return 0;
}
