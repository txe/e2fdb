#pragma once
#include <string>
#include <vector>
#include <Shlobj.h>
#include <memory>

namespace io
{
namespace file
{
  //-------------------------------------------------------------------------
  inline bool exist(const std::wstring& filePath)
  {
    return _waccess(filePath.c_str(), 0) == 0;
  }
  //-------------------------------------------------------------------------
  inline bool remove(const std::wstring& filePath)
  {
    return _wremove(filePath.c_str()) == 0;
  }
  //-------------------------------------------------------------------------
  inline std::wstring temp_name(const std::wstring& folder, const std::wstring& pre, const std::wstring& ext)
  {
    wchar_t fileName[MAX_PATH];

    if (0 != GetTempFileNameW(folder.c_str(), pre.c_str(), 0, fileName)) // pre - не более 3 символов
    {
      std::wstring path = fileName;
      if (!ext.empty() && ext[0] != L'.')
        path += L".";
      path += ext;
      return path;
    }

    return L"";
  }
  //-------------------------------------------------------------------------
  inline bool write(const std::wstring& filePath, const void* buf, size_t size)
  {
    HANDLE hFile = CreateFile(filePath.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE)
      return false;

    DWORD written = 0;
    BOOL res = WriteFile(hFile, buf, (DWORD)size, &written, NULL);
    CloseHandle(hFile);

    return !!res;
  }
  //-------------------------------------------------------------------------
  inline bool read(const std::wstring& filePath, std::vector<char>& buf)
  {
    HANDLE hFile = CreateFile(filePath.c_str(), GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE)
      return false;

    DWORD dwFileSize = GetFileSize(hFile,  NULL);
    buf.resize(dwFileSize);
    DWORD readed = 0;
    BOOL res = ReadFile(hFile, &buf.front(), dwFileSize, &readed, NULL);
    CloseHandle(hFile);

    return !!res;
  }
  //-------------------------------------------------------------------------
  inline bool copy(const std::wstring& from, const std::wstring& to)
  {
    return !!CopyFile(from.c_str(), to.c_str(), TRUE);
  }
} // namespace file 

namespace dir
{
  //-------------------------------------------------------------------------
  inline bool exist(const std::wstring& dirPath)
  {
    return false;
  }
  //-------------------------------------------------------------------------
  inline bool create(const std::wstring& path)
  {
    wchar_t drive[_MAX_DRIVE], dir[_MAX_DIR], fname[_MAX_FNAME], ext[_MAX_EXT];
    _wsplitpath(path.c_str(), drive, dir, fname, ext ); 

    std::wstring new_path = std::wstring(drive) + std::wstring(dir);
    SHCreateDirectoryExW(NULL, new_path.c_str(), NULL);
    return true;
  }
  //-------------------------------------------------------------------------
  inline bool remove(const std::wstring& dirPath)
  {
    wchar_t szFrom[MAX_PATH] = {0};
    lstrcpy(szFrom, dirPath.c_str());

    SHFILEOPSTRUCTW sh;
    sh.hwnd   = NULL;
    sh.wFunc  = FO_DELETE;
    sh.pFrom  = szFrom;
    sh.pTo    = NULL;
    sh.fFlags = FOF_NOCONFIRMATION | FOF_SILENT;
    sh.hNameMappings = NULL;
    sh.lpszProgressTitle = NULL;

    return !!SHFileOperationW(&sh);
  }
  //-------------------------------------------------------------------------
  inline std::wstring special_folder(int nFolder)
  {
    std::wstring path;

    IMalloc* shellMalloc = NULL;
    HRESULT hres = SHGetMalloc(&shellMalloc);
    if (FAILED(hres))
      L"";

    LPITEMIDLIST pidl = NULL;
    wchar_t wstrPath[MAX_PATH];
    hres = SHGetSpecialFolderLocation(NULL, nFolder, &pidl);
    if (SUCCEEDED(hres))
      if (SHGetPathFromIDList(pidl, wstrPath))
        path = wstrPath;

    if (pidl)
      shellMalloc->Free(pidl);
    shellMalloc->Release();

    return path;
  }
  //-------------------------------------------------------------------------
  inline std::wstring temp_dir(std::wstring includeFolder = L"")
  {
    if (!includeFolder.empty())
    {
      wchar_t ch = includeFolder[includeFolder.size() - 1];
      if (ch != L'\\' && ch != L'/')
        includeFolder += L"\\";
    }

    wchar_t tempPath[MAX_PATH];
    if (0 != ::GetTempPathW(MAX_PATH, tempPath))
      return std::wstring(tempPath) + includeFolder;
    return L"";
  }

} // namespace dir

} // namespace io


class XTempFile
{
private:
  struct file_prop
  {
  public:
    file_prop()
    {
      std::wstring tempDir = io::dir::temp_dir();
      fileName = io::file::temp_name(tempDir, L"aek", L"");
      io::file::write(fileName, 0, 0); // создадим его пустым
    }

    ~file_prop()
    {
      io::file::remove(fileName);
    }

  public:
    std::wstring fileName;
  };

public:
  XTempFile()
  {
    data = std::tr1::shared_ptr<file_prop>(new file_prop());
  }

  std::wstring fileName() { return data->fileName; }

private:
  std::tr1::shared_ptr<file_prop> data;
};