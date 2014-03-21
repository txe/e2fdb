#pragma once

class CacheApp
{
public:
  static const char* _ErrorMessage();
  static int  _NewInstance(const char* cacheDb, int majorVer, int minorVer);
  static bool _DeleteInstance(int cache);
  static void _ClearCache(int cache);
  static bool _CacheFile(int cache, const char* digest, const char* fromFile, bool isEngSys, char** data, int* dataLen, char** crc, int* crcLen, char** icon, int* iconLen);
};

