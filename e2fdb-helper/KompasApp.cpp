#include "KompasApp.h"
#import <ksConstants.tlb>   no_namespace named_guids
#import <ksConstants3D.tlb> no_namespace named_guids
#import <kAPI2D5COM.tlb>    no_namespace named_guids
#import <kAPI3D5COM.tlb>    no_namespace named_guids
#import <kAPI7.tlb>         rename_namespace("API7") named_guids
#import <kAPI5.tlb>         named_guids rename_namespace("API5") 

struct KOMPAS_INFO
{
  API7::IApplicationPtr kompasApp;
};

//-------------------------------------------------------------------------
int KompasApp::CreateNew(const char* cacheDb, int majorVer, int minorVer)
{
  CoInitializeEx(NULL, COINIT_MULTITHREADED);

  CLSID clsid = IID_NULL;
  CLSIDFromProgID(L"KOMPAS.Application.7", &clsid);

  IUnknownPtr stubApp;
  HRESULT hRes = CoCreateInstance(clsid, NULL, CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER, IID_IUnknown, (void**)&stubApp);
  if (!SUCCEEDED(hRes))
    return 0;

  KOMPAS_INFO* info = new KOMPAS_INFO;
  info->kompasApp = stubApp;

  return (int)info;
}
//-------------------------------------------------------------------------
bool KompasApp::Close(int kompas)
{
  KOMPAS_INFO* info = (KOMPAS_INFO*)kompas;
  if (info && info->kompasApp)
    info->kompasApp->Quit();

  delete info;
  return true;
}