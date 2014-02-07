#include "ByteData.h"
#include <fstream>

#include "lzo/lzo1y.h"
#include "lzo/lzo_asm.h"

//-------------------------------------------------------------------------
ByteData::ByteData(): m_pData(NULL), m_lSize(0), m_bAutoDelete(false)
{

}
//-------------------------------------------------------------------------
ByteData::ByteData(long lSize): m_pData(NULL), m_lSize(lSize), m_bAutoDelete(false)
{
  if (lSize > 0)
    Init(new char[lSize], lSize, true);
}
//-------------------------------------------------------------------------
ByteData::ByteData(const ByteData& data): m_pData(NULL), m_lSize(0), m_bAutoDelete(false)
{
  throw L"Попытка скопировать данные!";
}
//-------------------------------------------------------------------------
ByteData::~ByteData()
{
  Clear();
}
//-------------------------------------------------------------------------
void ByteData::Attach(char* pBuff, long nSize)
{
  Init(pBuff, nSize, false);
}
//-------------------------------------------------------------------------
char* ByteData::Detach()
{
  char* pBuff = m_pData;
  m_pData = NULL; 
  m_lSize = 0; 
  m_bAutoDelete = false;
  return pBuff;
}
//-------------------------------------------------------------------------
void ByteData::Init(char* pBuff, lzo_uint nSize, bool bAutoDelete)
{
  Clear();
  m_pData = pBuff;
  m_lSize = static_cast<__int32>(nSize);
  m_bAutoDelete = bAutoDelete;
}
//-------------------------------------------------------------------------
void ByteData::Clear()
{
  if (m_pData != NULL && m_bAutoDelete)
    delete[] m_pData;
  m_pData = NULL;
  m_lSize = NULL;
  m_bAutoDelete = false;
}
//-------------------------------------------------------------------------
int ByteData::LoadFromBlob(IBPP::Blob blob)
{
  int lLargest, lSegment, lSize = 0;
  blob->Open();
  blob->Info(&lSize, &lLargest, &lSegment);
  if (lSize > 0)
  {
    char* pData = new char[lSize];
    char *pBlockBegin = pData, *pBlockEnd = pBlockBegin + lSize;
    while (pBlockBegin < pBlockEnd)
      pBlockBegin += blob->Read( pBlockBegin, lLargest );
    
    Init(pData, lSize, true);
  }
  blob->Close();
  return lSize;
}
//-------------------------------------------------------------------------
int ByteData::SaveToBlob(IBPP::Blob blob)
{
  blob->Create();

  int lBlockCount = 0, lBlockSize;
  char* pBuffPointer = m_pData;
  do 
  {
    lBlockSize = std::min(gMaxBlobSegment, m_lSize - lBlockCount*gMaxBlobSegment);
    blob->Write(pBuffPointer, lBlockSize);
    pBuffPointer += lBlockSize;
    ++lBlockCount;
  } 
  while (lBlockCount * gMaxBlobSegment < m_lSize);

  blob->Close();
  return m_lSize;
}
//-------------------------------------------------------------------------
int ByteData::LoadFromFile(const std::wstring& sPath)
{
  long lSize = 0;
  std::fstream InputFile(sPath.c_str(), std::fstream::in | std::fstream::binary);

  if (!InputFile.fail())
  {
    InputFile.seekg (0, std::ios::end);
    lSize = (long)InputFile.tellg();
    InputFile.seekg (0, std::ios::beg);

    if (lSize > 0)
    {
      Init(new char[lSize], lSize, true);
      InputFile.read(m_pData, m_lSize);
    }
  }
  return lSize;	
}
//-------------------------------------------------------------------------
int ByteData::SaveToFile(const std::wstring& sPath)
{
  std::fstream OutputFile(sPath.c_str(), std::fstream::out | std::fstream::binary);
  if (!OutputFile.is_open())
    return 0;
  OutputFile.write(m_pData, m_lSize);
  OutputFile.close();
  return m_lSize;
}
//-------------------------------------------------------------------------
bool ByteData::EqualFile(const std::wstring& sPath)
{
  std::fstream InputFile(sPath.c_str(), std::fstream::in | std::fstream::binary);
  if (InputFile.fail())
    return false;

  InputFile.seekg (0, std::ios::end);
  long lSize = (long)InputFile.tellg();
  if ( lSize != m_lSize )
    return false;
  if( lSize == 0 )
    return true;

  char *buff = new char[lSize];
  InputFile.seekg(0, std::ios::beg);
  InputFile.read(buff, lSize);
  bool result = (0 == memcmp(buff, m_pData, lSize));
  delete[] buff;

  return result;
}
//-------------------------------------------------------------------------
void ByteData::Compress()
{
  // Компрессия с запоминанием размера файла. выделим помимо прочего память на запись размер.
  lzo_uint lNewSize;
  lzo_uint lSizeOfSize = sizeof( m_lSize ), lExtraSize;
  lExtraSize = (m_lSize / 1024 + 1) * 16;
  char *pNewData = new char[m_lSize + lExtraSize + lSizeOfSize];
  
  char pWrkData[LZO1Y_999_MEM_COMPRESS];
  // Запишем размер
  memcpy(pNewData, &m_lSize, lSizeOfSize);

  lzo1y_999_compress( 
    (unsigned char*)m_pData, 
    m_lSize, 
    (unsigned char*)(pNewData + lSizeOfSize), 
    &lNewSize, 
    pWrkData 
    );

  Init(pNewData, lNewSize + lSizeOfSize, true);
}
//-------------------------------------------------------------------------
void ByteData::Decompress()
{
  // Декомпрессия с предварительным получением размера
  __int32 realSize32;
  size_t  lSizeOfSize = sizeof(m_lSize);
  memcpy(&realSize32, m_pData, lSizeOfSize);

  // 	For reasons of speed this decompressor can write up to 3 bytes
  // 		past the end of the decompressed (output) block.
  // 		[ technical note: because data is transferred in 32-bit units ]
  //  LZO.FAQ
  char *pNewData = new char[realSize32 + 3];
  char pWrkData[LZO1Y_999_MEM_COMPRESS];

  lzo_uint realSizeLzo = realSize32;

 #if defined(_WIN64)  
   lzo1y_decompress( 
    (unsigned char*)(m_pData + lSizeOfSize), 
    m_lSize - lSizeOfSize, 
    (unsigned char*)pNewData, 
    &realSizeLzo, 
    pWrkData 
    );
#else
   lzo1y_decompress_asm_fast( 
    (unsigned char*)(m_pData + lSizeOfSize), 
    m_lSize - lSizeOfSize, 
    (unsigned char*)pNewData, 
    &realSizeLzo, 
    pWrkData 
    );
#endif



  Init(pNewData, realSize32, true);
}

/************************************************************************/
/*                                                                      */
/************************************************************************/
//-------------------------------------------------------------------------
ByteArhiver::ByteArhiver(char* buf, size_t size)
{
  m_pPos = m_pData = buf;
  m_lSize = size;
}
//-------------------------------------------------------------------------
void ByteArhiver::WriteType(ByteArhiver::DataType type)
{
  memcpy(m_pPos, &type, gnDataTypeSize);
  m_pPos += gnDataTypeSize;
}
//-------------------------------------------------------------------------
ByteArhiver::DataType ByteArhiver::ReadType()
{
  DataType CurrType;
  memcpy(&CurrType, m_pPos, gnDataTypeSize);
  return CurrType;
}
//-------------------------------------------------------------------------
bool ByteArhiver::Seek(long newPos)
{
  if (newPos > -1 && newPos < static_cast<int>(m_lSize))
  {
    m_pPos = m_pData + newPos;
    return true;
  }
  return false;
}
//-------------------------------------------------------------------------
size_t ByteArhiver::LeftoverSize() const 
{ 
  char *pEnd = m_pData + m_lSize; 
  return pEnd - m_pPos; 
}
//-------------------------------------------------------------------------
ByteArhiver& ByteArhiver::operator << (const int& nIntVal)
{
  if (LeftoverSize() >= gnDataTypeSize + gnIntSize)
  {
    WriteType(tmp_Int);
    memcpy(m_pPos, &nIntVal, gnIntSize);
    m_pPos += gnIntSize;
  }	
  return *this;
}
//-------------------------------------------------------------------------
ByteArhiver& ByteArhiver::operator << (const unsigned int& nIntVal)
{
  const int& refArg = (const int&)nIntVal; 
  return (*this) << refArg;
}
//-------------------------------------------------------------------------
ByteArhiver& ByteArhiver::operator << (const double& rDblVal)
{
  if (LeftoverSize() >= gnDataTypeSize + gnDblSize)
  {
    WriteType(tmp_Double);
    memcpy(m_pPos, &rDblVal, gnDblSize);
    m_pPos += gnDblSize;
  }	
  return *this;
}
//-------------------------------------------------------------------------
ByteArhiver& ByteArhiver::operator << (const std::wstring& sStrVal)
{
  size_t nStrSize = sStrVal.size() * sizeof(wchar_t), nStrSizeSize = sizeof(int);
  if (LeftoverSize() >= nStrSize + nStrSizeSize + gnDataTypeSize)
  {
    WriteType(tmp_String);
    memcpy(m_pPos, &nStrSize, nStrSizeSize);
    m_pPos += nStrSizeSize;
    memcpy(m_pPos, sStrVal.c_str(), nStrSize);
    m_pPos += nStrSize;
  }
  return *this;
}
//-------------------------------------------------------------------------
ByteArhiver& ByteArhiver::operator << (const wchar_t* pStrVal)
{
  std::wstring str = pStrVal;
  return (*this) << str;
}
//-------------------------------------------------------------------------
ByteArhiver& ByteArhiver::operator >> (int& nIntVal)
{
  if (LeftoverSize() >= gnDataTypeSize + gnIntSize)
    if (ReadType() == tmp_Int)
    {
      m_pPos += gnDataTypeSize;
      memcpy(&nIntVal, m_pPos, gnIntSize);
      m_pPos += gnIntSize;
    }
  return *this;
}
//-------------------------------------------------------------------------
ByteArhiver& ByteArhiver::operator >> (unsigned int& nIntVal)
{
  int& refArg = (int&)nIntVal; 
  return (*this) >> refArg;
}
//-------------------------------------------------------------------------
ByteArhiver& ByteArhiver::operator >> (double& rDblVal)
{
  if (LeftoverSize() >= gnDataTypeSize + gnDblSize)
    if (ReadType() == tmp_Double)
    {
      m_pPos += gnDataTypeSize;
      memcpy(&rDblVal, m_pPos, gnDblSize);
      m_pPos += gnDblSize;
    }
  return *this;
}
//-------------------------------------------------------------------------
ByteArhiver& ByteArhiver::operator >> (std::wstring& sStrVal)
{
  unsigned int nStrSizeSize = sizeof(int), nStrSize;
  if (LeftoverSize() >= gnDataTypeSize + nStrSizeSize)
    if (ReadType() == tmp_String)
    {
      m_pPos += gnDataTypeSize;
      memcpy(&nStrSize, m_pPos, nStrSizeSize);
      m_pPos += nStrSizeSize;
      if (LeftoverSize() >= nStrSize)
      {
        sStrVal.clear();
        sStrVal.insert(0, (wchar_t*)m_pPos, nStrSize / sizeof(wchar_t));
        m_pPos += nStrSize;
      }
    }
  return *this;
}