import std.stdio;
import std.path;
import std.file;
import std.conv;
import std.string;
import std.parallelism;
import edb.parser;
import edb.structure;
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
    catch (EdbStructException e)
    { 
      auto txt = "\n+++++++++++++++++++++++++++++++++++++++++++++\n" ~ e.msg ~ "\nfile: " ~ edbFile ~ "\nrow: " ~ to!string(e._row == -1 ? -1 : e._row + 1) ~ "\nline: " ~ to!string(e._line);
      problems ~= txt;
    }
    catch (Exception e)
    {
      problems ~= "\n+++++++++++++++++++++++++++++++++++++++++++++\n" ~ e.msg ~ "\nfile: " ~ edbFile;
    }

  if (edbFiles.length == 0)
    problems ~= "Отсутствуют файлы";

  writeln;
  if (problems)
    foreach (problem; problems)
    {
      write(problem);
      stdout.flush(); // требуется, т.к. если слишком много сообщений будет падать
    }

  auto f = File(std.file.thisExePath.dirName ~ "\\+log.txt", "w");
  f.write(problems.join("\n"));

  return problems.length == 0;
}
/++++++++++++++++++++++++++++/
int main(string[] argv)
{
  try
  {
    SetConsoleOutputCP(65001);
    const path = "d:\\+edb";

    writeln("collecting files before ...");
    string[] edbFiles = get_files(path, "*.edb");

    auto writer = new WriteManager;
    if (TestBase(edbFiles))
    {}
      writer.Run(edbFiles);
    
  }
  catch (Exception e)
  {
    writeln;
    writeln(e.msg);
  }

  write("\n\npress enter to exit");
  readln();
  return 0;
}
