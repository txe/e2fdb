module utils;
private import core.sys.windows.windows;
private import std.conv;
private import std.string;

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
      throw new Exception("");
  }
  
  return to!wstring(result);
}
/++++++++++++++++++++++++++++/