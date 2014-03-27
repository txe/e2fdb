#pragma once
#include <string>

namespace thumb
{
  bool    ExtractThumbnail(const std::wstring & strDirectory, const std::wstring& strFileNameOnly, const std::wstring& strPNGNameOnly, int nSize);
  HBITMAP GetThumbnailHBitmap(std::wstring strFolder, std::wstring strFileName, int nSize); // strFileName - файл, из которого получаем иконку ("1.frw")
                                                                                            // strFolder - папка с этим файлом
};
