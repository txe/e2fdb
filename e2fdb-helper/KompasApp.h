#pragma once

class KompasApp
{
public:
  static int  CreateNew(const char* cacheDb, int majorVer, int minorVer);
  static bool Close(int cache);
};

