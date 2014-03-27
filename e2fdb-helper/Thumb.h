#pragma once
#include <string>

class CThumb
{
public:
  bool ExtractThumbnail(const std::wstring & strDirectory, const std::wstring& strFileNameOnly, const std::wstring& strPNGNameOnly, int nSize);

private:
  HBITMAP	GetThumbnailHBitmap(std::wstring strFolder, std::wstring strFileName, int nSize); // strFileName - ����, �� �������� �������� ������ ("1.frw")
                                                                                            // strFolder - ����� � ���� ������
};
