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
  SetConsoleOutputCP(65001);

  const path = "d:\\edb";
  const edbFiles = get_files(path, "*.edb");
  int count = 0;

  foreach (index, edbFile; edbFiles)
    //foreach (index, edbFile; taskPool.parallel(edbFiles, 5))
    try
    {
      count += 1;
      write("\r" ~ to!string((1+count) * 100 /edbFiles.length) ~ " %");
      stdout.flush();

      EdbParser().Parse(edbFile);
    }
  catch (EdbParserException e)
  { 
    auto txt = "\n*************************\n" ~ e.msg ~ "\nfile:\t" ~ edbFile ~ "\nrow:\t" ~ to!string(e._row == -1 ? -1 : e._row + 1) ~ "\nline:\t" ~ to!string(e._line) ~ "\n*************************";
    writeln(txt);
    /+      writeln("\n",      e.msg);
    writeln("file:\t", edbFile);
    writeln("row:\t",  e.row);
    writeln("line:\t", e.line);
    writeln();
    +/      stdout.flush();
  }
  catch (Exception e)
  {
    writeln("\n", e.msg);
    writeln();
    stdout.flush();
  }


  write("\npress enter");
  readln();
  return 0;
}