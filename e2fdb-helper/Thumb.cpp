#include "StdAfx.h"
#include "Thumb.h"

#include <shlobj.h>
#include <atlimage.h>

//-------------------------------------------------------------------------
bool thumb::ExtractThumbnail(const std::wstring & strDirectory, const std::wstring& strFileNameOnly, const std::wstring& strThumbnailFileNameOnly, int nSize)
{
  HBITMAP Thumbnail = thumb::GetThumbnailHBitmap(strDirectory, strFileNameOnly, nSize);
  if (Thumbnail == 0)
    return false;

  CImage image;
  image.Attach(Thumbnail);
  image.Save((strDirectory + strThumbnailFileNameOnly).c_str(), Gdiplus::ImageFormatPNG);
  image.Destroy();
  return true;
}
//-------------------------------------------------------------------------
HBITMAP thumb::GetThumbnailHBitmap(std::wstring strFolder, std::wstring strFileName, int nSize)
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
//-------------------------------------------------------------------------
bool thumb::Strech(const std::wstring& fileName)
{
  CImage oldImage, newImage;
  oldImage.Load(fileName.c_str());
  if (!oldImage)
    return false;

  int Himg = oldImage.GetHeight();
  int Wimg = oldImage.GetWidth();
  double coH = (double)Himg/Wimg;
  double coW = (double)Wimg/Himg;
  int H = 64*min(coH,1); if(H<=0) H=1;
  int W = 64*min(coW,1); if(W<=0) W=1;

  // Пересохряняем рисунок в формате 64х64
  int bpp = oldImage.GetBPP();
  newImage.Create(64,64,bpp);
  
  // Белый фон рисунка - оптимизировать!
  for(int x=0; x<64; ++x)
    for(int y=0; y<64; ++y)
      newImage.SetPixel(x,y,RGB(255,255,255));

  HDC dch = newImage.GetDC();
  SelectObject(dch,newImage);
  SetStretchBltMode(dch,HALFTONE);
  // Основая функция модификации
  oldImage.StretchBlt(dch,(64-W)/2,(64-H)/2,W,H,0,0,Wimg,Himg,SRCCOPY);
  newImage.Save(fileName.c_str(), Gdiplus::ImageFormatPNG);
  newImage.ReleaseDC();

  return true;
}