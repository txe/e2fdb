#include "StdAfx.h"
#include "Thumb.h"

#include <shlobj.h>
#include <atlimage.h>

//-------------------------------------------------------------------------
bool CThumb::ExtractThumbnail(const std::wstring & strDirectory, const std::wstring& strFileNameOnly, const std::wstring& strThumbnailFileNameOnly, int nSize)
{
  HBITMAP Thumbnail = GetThumbnailHBitmap(strDirectory, strFileNameOnly, nSize);
  if (Thumbnail == 0)
    return false;

  CImage image;
  image.Attach(Thumbnail);
  image.Save((strDirectory + strThumbnailFileNameOnly).c_str(), Gdiplus::ImageFormatPNG);
  image.Destroy();
  return true;
}
//-------------------------------------------------------------------------
HBITMAP CThumb::GetThumbnailHBitmap(std::wstring strFolder, std::wstring strFileName, int nSize)
{
  HBITMAP result(0);

  LPITEMIDLIST pidList = NULL;
  DWORD   dwPriority = 0;
  DWORD   dwFlags    = IEIFLAG_ASPECT | IEIFLAG_QUALITY;
  HRESULT hr         = E_NOINTERFACE;
  WCHAR   szBuffer[MAX_PATH];
  IExtractImage *peiURL = NULL;
  IShellFolder  *psfWorkDir = NULL;
  IShellFolder  *psfDesktop = NULL;

  CoInitialize(NULL);
  hr = SHGetDesktopFolder(&psfDesktop);
  if(SUCCEEDED(hr)) 
  {
    hr = psfDesktop->ParseDisplayName(NULL, NULL, (LPWSTR)strFolder.c_str(), NULL, &pidList, NULL);
    if(SUCCEEDED(hr)) 
    {
      hr = psfDesktop->BindToObject(pidList, NULL, IID_IShellFolder, (void **)&psfWorkDir);
      if(SUCCEEDED(hr)) 
      {
        hr = psfWorkDir->ParseDisplayName(NULL, NULL, (LPWSTR)strFileName.c_str(), NULL, &pidList, NULL);
        if(SUCCEEDED(hr)) 
        {
          LPCITEMIDLIST pidl = pidList;
          hr = psfWorkDir->GetUIObjectOf(NULL, 1, &pidl, IID_IExtractImage, NULL,
            (void **)&peiURL);
          if(SUCCEEDED(hr)) 
          {
            SIZE cSize;
            cSize.cx = nSize;
            cSize.cy = nSize;
            hr = peiURL->GetLocation(szBuffer, MAX_PATH, &dwPriority, &cSize, 16, &dwFlags);
            if(SUCCEEDED(hr) || hr == E_PENDING)
            {
              hr = peiURL->Extract(&result);
            }
          }
        }
      }
    }

    ILFree(pidList);
    if(peiURL != NULL)
      peiURL->Release();
    if(psfDesktop != NULL)
      psfDesktop->Release();
    if(psfWorkDir != NULL)
      psfWorkDir->Release();
    //CoUninitialize();
  }
  return result;
}