#pragma once

#include "lzo/lzoconf.h"
#include "ibpp/ibpp.h"

/************************************************************************/
/*                                                                      */
/************************************************************************/
class ByteData
{
public:
  ByteData();
  ByteData(long size);
  ByteData(const ByteData& data); 
  ~ByteData();

public:
  void	Attach(char* buff, long size);
  char*	Detach();
  void	Clear();

  long	GetLength() const { return m_lSize; } 
  const char* GetData() const { return m_pData; }

  int		LoadFromBlob(IBPP::Blob blob);
  int		SaveToBlob(IBPP::Blob blob);

  int		LoadFromFile(const std::wstring& sPath);
  int		SaveToFile(const std::wstring& sPath);
  bool	EqualFile(const std::wstring& sPath);

  void	Compress();
  void	Decompress();

private:
  void		Init(char* pBuff, lzo_uint nSize, bool bAutoDelete);

private:
  char*    m_pData;
  __int32  m_lSize;
  bool     m_bAutoDelete;

  const static __int32 gMaxBlobSegment = 32767;
};

/************************************************************************/
/*                                                                      */
/************************************************************************/
class ByteArhiver
{
private:
  typedef char DataType;
  static const DataType tmp_Int    = 1;
  static const DataType tmp_Double = 2;
  static const DataType tmp_String = 3;

  static const int gnDataTypeSize = sizeof(DataType);
  static const int gnIntSize      = sizeof(__int32);
  static const int gnDblSize      = sizeof(double);

public:
  ByteArhiver(char* buf, size_t size);
  
  ByteArhiver& operator << (const int& nIntVal);
  ByteArhiver& operator << (const unsigned int& nIntVal);
  ByteArhiver& operator << (const double& rDblVal);
  ByteArhiver& operator << (const std::wstring& sStrVal);
  ByteArhiver& operator << (const wchar_t* pStrVal);
  
  ByteArhiver& operator >> (int& nIntVal);
  ByteArhiver& operator >> (unsigned int& nIntVal);
  ByteArhiver& operator >> (double& rDblVal);
  ByteArhiver& operator >> (std::wstring& sStrVal);

  int GetLength() const { return (int)(m_pPos - m_pData); }

private:
  void     WriteType(DataType type);
  DataType ReadType();
  bool     Seek(long newPos);
  size_t   LeftoverSize() const;

private:
  char*   m_pData;
  size_t  m_lSize;
  char*   m_pPos;
};
