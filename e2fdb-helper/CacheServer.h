#pragma once
#include "e2fdb-helper.h"

namespace CacheServer
{
  int  _NewInstance(const char* basePath, int majorVer, int minorVer);
  bool _Write(int cacheServer, const char* digest, CACHE_FILE_INFO* fileInfo);
  bool _Read(int cacheServer, const char* digest, CACHE_FILE_INFO* fileInfo);
  bool _Clear(int cacheServer);
  bool _Quit(int cacheServer);

  const char* _Message(int cacheServer);
};
