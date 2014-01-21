import std.stdio;
import std.path;
import std.file;
import std.conv;
import std.string;
import std.parallelism;
import edb.parser;

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
int main(string[] argv)
{
  // для генерации кода оберток
  // utils.h2d("c:\\e2fdb-helper.h", "c:\\txt.d", "fdb_", "dbDll");
  // return 0;

  SetConsoleOutputCP(65001);

  writeln("Collecting files before read ...");

  const path = "d:\\edb";
  const edbFiles = get_files(path, "*.edb");
  int count = 0;

  string[] problems;
  foreach (index, edbFile; edbFiles) 
  //foreach (index, edbFile; taskPool.parallel(edbFiles, 5))
    try
    {
      count += 1;
      write("\rnow:" ~ to!string((1+count) * 100 /edbFiles.length) ~ " %, problem(s): " ~ to!string(problems.length));
      stdout.flush();

      EdbParser().Parse(edbFile);
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

  foreach (problem; problems)
    writeln(problem);

  write("\npress enter to exit:");
  readln();
  return 0;
}