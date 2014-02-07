#pragma once
#include <windows.h>

namespace aux
{
  // изменение точки в строке на запятую
  inline std::wstring dot_to_com(std::wstring real)
  {
    for (size_t pos = real.find(L'.'); pos != std::wstring::npos; pos = real.find(L'.', pos))
      real[pos] = L',';
//     size_t dot_pos  = real.find(L'.');
//     if (dot_pos != std::wstring::npos)
//       real[dot_pos] = L',';				
    return real;
  }
  inline std::wstring com_to_dot(std::wstring real)
  {
    for (size_t pos = real.find(L','); pos != std::wstring::npos; pos = real.find(L',', pos))
      real[pos] = L'.';
  
//     size_t dot_pos  = real.find(L',');
//     if (dot_pos != std::wstring::npos)
//       real[dot_pos] = L'.';				
    return real;
  }

//------------------------------------------------------------------------------
	/** const char* to float parser.
	**/
	// возвращает double из строки
  inline double atof(const std::string& str, double default_value = 0.0) 
	{ 
		if (str.empty()) return default_value;
    char*       lastptr;
    const char* s = str.c_str();
		double d = ::strtod(s, &lastptr);
		return (lastptr != s)? d : default_value;
	}
  //------------------------------------------------------------------------------
  /** const wchar_t* to float parser.
  **/
  // возвращает double из строки
  inline double wtof(const std::wstring& str, double default_value = 0.0) 
  { 
    if (str.empty()) return default_value;
    wchar_t*        lastptr;
    const wchar_t*  s = str.c_str();
    double d = ::wcstod(s, &lastptr);
    return (lastptr != s)? d : default_value;
  }
  //------------------------------------------------------------------------------
  /** wstring to integer parser.
  **/
  inline int wtoi(const std::wstring& str, int default_value = 0, int default_radix = 10) 
  { 
    if (str.empty()) return default_value;
    wchar_t* lastptr;
    const wchar_t*  s = str.c_str();
    long i = wcstol(s, &lastptr, default_radix);
    return (lastptr != s)? (int)i : default_value;
  }
  //------------------------------------------------------------------------------
  /** string to integer parser.
  **/
  inline int atoi(const std::string& str, int default_value = 0, int default_radix = 10) 
  { 
    if (str.empty()) return default_value;
    char* lastptr;
    const char* s = str.c_str(); 
    long i = strtol(s, &lastptr, default_radix);
    return (lastptr != s)? (int)i : default_value;
  }
//------------------------------------------------------------------------------
	/** Integer to string converter.
	Use it as ostream << itoa(234) 
	**/
	class itoa 
	{
		char buffer[38];
	public:
		itoa(int n, int radix = 10)
		{ 
			_itoa(n,buffer,radix);
		}
		operator const char*() { return buffer; }
	};
//------------------------------------------------------------------------------
	/** Integer to wstring converter.
	Use it as wostream << itow(234) 
	**/

	class itow 
	{
		wchar_t buffer[38];
	public:
		itow(int n, int radix = 10)
		{ 
			_itow(n,buffer,radix);
		}
		operator const wchar_t*() { return buffer; }
	};
//------------------------------------------------------------------------------
	/** Float to string converter.
	Use it as ostream << ftoa(234.1); or
	Use it as ostream << ftoa(234.1,"pt"); or
	**/
	class ftoa 
	{
		char buffer[64];
	public:
		ftoa(double d, const char* units = "", int fractional_digits = 1)
		{ 
			_snprintf(buffer, 64, "%.*f%s", fractional_digits, d, units );
			buffer[63] = 0;
		}
		operator const char*() { return buffer; }
	};
//------------------------------------------------------------------------------
	/** Float to wstring converter.
	Use it as wostream << ftow(234.1); or
	Use it as wostream << ftow(234.1,"pt"); or
	**/
	class ftow
	{
		wchar_t buffer[64];
	public:
		ftow(double d, const wchar_t* units = L"", int fractional_digits = 1)
		{ 
			_snwprintf(buffer, 64, L"%.*f%s", fractional_digits, d, units );
			buffer[63] = 0;
		}
		operator const wchar_t*() { return buffer; }
	};
//-------------------------------------------------------------------------------
  // helper convertor objects wchar_t to ACP and vice versa
  class w2a 
  {
    char* buffer;

  public:
    explicit w2a(const wchar_t* wstr):buffer(0)     { convert(wstr); } 
    explicit w2a(const std::wstring& wstr):buffer(0) { convert(wstr.c_str()); }
    ~w2a()                                          { delete[] buffer; }
    operator const char*()                          { return buffer; }

  private:
    void convert(const wchar_t* wstr)
    {
      if(wstr)
      {
        int nu  = (int)wcslen(wstr);
        int n   = WideCharToMultiByte(CP_ACP, 0, wstr, nu, 0, 0, 0, 0);
        buffer  = new char[n+1];
        WideCharToMultiByte(CP_ACP, 0, wstr, nu, buffer, n, 0, 0);
        buffer[n] = 0;
      }
    }

  };

//-----------------------------------------------------------------------------------------
  class a2w 
  {
    wchar_t* buffer;
  public:
    explicit a2w(const char* str):buffer(0)         { convert(str); }
    explicit a2w(const std::string& str):buffer(0)  { convert(str.c_str()); }
    ~a2w()                                          { delete[] buffer; }
    operator const wchar_t*()                       { return buffer; }
  private:
    void convert(const char* str)
    {
      if(str)
      {
        int n   = (int)strlen(str);
        int nu  = MultiByteToWideChar(CP_THREAD_ACP, 0, str, n, 0, 0);
        buffer  = new wchar_t[n+1];
        MultiByteToWideChar(CP_ACP, 0, str, n, buffer, nu);
        buffer[nu] = 0;
      }
    }
  };


  template<class TYPE1, class TYPE2>
  bool has_item(const TYPE1& vect, const TYPE2& val)
  {
    TYPE1::const_iterator it = std::find(vect.begin(), vect.end(), val);
    return it != vect.end();
  }

  inline std::wstring _a2w(const std::string& str) { return std::wstring(a2w(str.c_str())); }
  inline std::string _w2a(const std::wstring& str) { return std::string(w2a(str.c_str())); }
}