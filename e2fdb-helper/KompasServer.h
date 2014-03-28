#pragma once
#include "e2fdb-helper.h"
#include <string>

namespace KompasServer
{
  int         _NewInstance(int index, int majorVer, int minorVer);
  bool        _File(int kompasServer, std::string fileName, bool isEngSys, CACHE_FILE_INFO* fileInfo);
  const char* _Message(int kompasServer);
  bool        _Clear(int kompasServer);
  bool        _Quit(int kompasServer);
};

