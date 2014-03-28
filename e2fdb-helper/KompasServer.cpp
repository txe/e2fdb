#include "KompasServer.h"
#include "ByteData.h"
#include "_io.h"
#include "aux_ext.h"
#include "Thumb.h"

#import <ksConstants.tlb>   no_namespace named_guids
#import <ksConstants3D.tlb> no_namespace named_guids
#import <kAPI2D5COM.tlb>    no_namespace named_guids
#import <kAPI3D5COM.tlb>    no_namespace named_guids
#import <kAPI7.tlb>         rename_namespace("API7") named_guids
#import <kAPI5.tlb>         named_guids rename_namespace("API5")
#include <ldefin2d.h>

#include <list>

//-------------------------------------------------------------------------
struct kom_file
{
  ByteData    data;
  ByteData    icon;
  std::string param;
};
//-------------------------------------------------------------------------
struct kompas_server_info
{
  API5::KompasObjectPtr kompas5;
  std::wstring          tempDir;
  std::string           message;
  std::list<kom_file*>  files;
};

bool FRW_Prepare(kompas_server_info* info, const std::string& fromFile, bool isEngSys, kom_file& fileInfo);
bool FRW_MoveDimension(API5::KompasObjectPtr kompas5, API5::ksDocument2DPtr doc);
bool FRW_CreatePng(kompas_server_info* info, const std::wstring& pngName, API5::ksDocument2DPtr doc);
void FRW_PreparePng(API5::KompasObjectPtr kompas5, API5::ksDocument2DPtr doc, double& xSize, double& ySize, double& xBot, double& yBot, int& textCount);
bool M3D_Prepare(kompas_server_info* info, const std::string& fromFile, bool isEngSys, kom_file& fileInfo);


//-------------------------------------------------------------------------
int KompasServer::_NewInstance(int index, int majorVer, int minorVer)
{
  std::wstring tempDir = io::dir::temp_dir(L"_fdb_converter");
  if (!io::dir::exist(tempDir))
    io::dir::create(tempDir);

  std::wstring nextDir;
  std::wstring checkFiles[] = {L"model.m3d", L"mmodel.m3d.png", L"fragment.frw", L"fragment.frw.png"};
  for (int i = 0;;)
  {
    nextDir = tempDir + std::wstring(aux::itow(index)) + L"_" + std::wstring(aux::itow(i)) + L"_";
    bool exist = false;
    for (int k = 0; k < 4; ++k)
      if (exist = io::file::exist(nextDir + checkFiles[k]))
        break;
    if (!exist)
      break;
  }

  kompas_server_info* info = new kompas_server_info;
  info->kompas5 = NULL;

  // запустим компас
  CoInitializeEx(NULL, COINIT_MULTITHREADED);

  CLSID clsid = IID_NULL;
  CLSIDFromProgID(L"KOMPAS.Application.5", &clsid);

  IUnknownPtr kompasApp;
  HRESULT hRes = CoCreateInstance(clsid, NULL, CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER, IID_IUnknown, (void**)&kompasApp);
  if (!SUCCEEDED(hRes))
  {
    info->message = "не смогли запустить компас";
    return 0;
  }

  info->kompas5 = kompasApp;
  info->tempDir = nextDir;

  return (int)info;
}
//-------------------------------------------------------------------------
int KompasServer::_File(int kompasServer, std::string fileName, bool isEngSys, CACHE_FILE_INFO* fileInfo)
{
  kompas_server_info* info = (kompas_server_info*)kompasServer;
  kom_file* file = new kom_file;

  bool isFrw = fileName.find("|", 0) != std::string::npos;
  bool isOk = false;
  if (isFrw)
    isOk = FRW_Prepare(info, fileName, isEngSys, *file);
  else
    isOk = M3D_Prepare(info, fileName, isEngSys, *file);
  if (!isOk)
    return false;

  fileInfo->data    = file->data.GetData();
  fileInfo->dataLen = file->data.GetLength();
  fileInfo->icon    = file->icon.GetData();
  fileInfo->iconLen = file->icon.GetLength();
  fileInfo->param   = file->param.c_str();
  info->files.push_back(file);

  return true;
}
//-------------------------------------------------------------------------
const char*KompasServer::_Message(int kompasServer)
{
  if (kompas_server_info* info = (kompas_server_info*)kompasServer)
    return info->message.c_str();
  return "kompasServer нулевой указатель";
}
//-------------------------------------------------------------------------
int KompasServer::_Clear(int kompasServer)
{
  if (kompas_server_info* info = (kompas_server_info*)kompasServer)
  {
    for (auto it = info->files.begin(); it != info->files.end(); ++it)
      delete *it;
    info->files.clear();
    return true;
  }
  return false;
}
//-------------------------------------------------------------------------
int KompasServer::_Quit(int kompasServer)
{
  if (kompas_server_info* info = (kompas_server_info*)kompasServer)
  {
    if (info->kompas5)
      info->kompas5->Quit();
    delete info;
  }
  return true;
}
//-------------------------------------------------------------------------
bool FRW_Prepare(kompas_server_info* info, const std::string& fromFile, bool isEngSys, kom_file& fileInfo)
{
  std::wstring tempFrw = info->tempDir + L"fragment.frw";
  if (io::file::exist(tempFrw))
    if (!io::file::remove(tempFrw))
    {
      info->message = "не могу удалить временный файл фрагмента";
      return false;
    }

  API5::ksPlacementParamPtr place = info->kompas5->GetParamStruct(ko_PlacementParam);
  place->Init();

  API5::ksDocumentParamPtr docParam(info->kompas5->GetParamStruct(ko_DocumentParam));
  docParam->Init();
  docParam->type = lt_DocFragment;
  docParam->fileName = tempFrw.c_str();

  API5::ksDocument2DPtr doc = info->kompas5->Document2D();
  doc->ksCreateDocument(docParam);
  doc->ksSetObjParam(doc->reference, 0, 1);

  // вставка фрагмента в документ
  API5::ksFragmentPtr frag = doc->GetFragment();
  long def = frag->ksFragmentDefinition(aux::_a2w(fromFile).c_str(), L"name", 0);
  if (def == 0)
  {
    info->message = "frag->ksFragmentDefinition == 0 для " + fromFile;
    return false;
  }
  if (!frag->ksInsertFragment(def, FALSE, place))
  {
    info->message = "frag->ksInsertFragment == 0 для " + fromFile;
    return false;
  }

  // перенесем РАЗМЕРЫ на отдельный слой
  if (FRW_MoveDimension(info->kompas5, doc))
    fileInfo.param = "dim=1";

  // создадим файл
  doc->ksSaveDocument(tempFrw.c_str());

  fileInfo.data.LoadFromFile(tempFrw);
  fileInfo.data.Compress();

  // создать иконку
  std::wstring pngName = tempFrw + L".png";
  io::file::remove(pngName);
  if (!FRW_CreatePng(info, pngName, doc))
  {
    doc->ksCloseDocument();
    info->message = info->message + ": " + fromFile;
    return false;
  }
  fileInfo.icon.LoadFromFile(pngName);
  fileInfo.icon.Compress();

  doc->ksCloseDocument();

  return true;
}
//-------------------------------------------------------------------------
// перенесем РАЗМЕРЫ на отдельный слой
bool FRW_MoveDimension(API5::KompasObjectPtr kompas5, API5::ksDocument2DPtr doc)
{
  long layerRef = doc->ksLayer(990);
  if (!layerRef)
  {
    // TODO сообщение
    return false;
  }
  API5::ksLayerParamPtr layerParam = kompas5->GetParamStruct(ko_LayerParam);
  layerParam->Init();
  layerParam->color = RGB(50, 150, 255);
  layerParam->name = L"Размеры";
  layerParam->state = 0; // stACTIVE
  doc->ksSetObjParam(layerRef, layerParam, 9);

  bool isDim = false;

  API5::ksIteratorPtr iter = kompas5->GetIterator();
  iter->ksCreateIterator(0 /*ALL_OBJ */, 0);
  for (long moved = iter->ksMoveIterator(L"F"); moved; moved = iter->ksMoveIterator(L"N"))
  {
    long ref  = iter->Getreference();
    long type = doc->ksGetObjParam(ref, 0, 0);
    switch (type)
    {
      case ksDrLDimension:
      case ksDrADimension:
      case ksDrDDimension:
      case ksDrRDimension:
      case ksDrRBreakDimension:
      case ksDrLBreakDimension:
      case ksDrABreakDimension:
      case ksDrOrdinateDimension:
      case ksDrArcDimension:
        doc->ksChangeObjectLayer(ref, 990);
        isDim = true;
    }
  }
  iter->ksDeleteIterator();

  return isDim;
}
//-------------------------------------------------------------------------
bool FRW_CreatePng(kompas_server_info* info, const std::wstring& pngName, API5::ksDocument2DPtr doc)
{
  //FRW_RemovePoints();
  //FRW_ChangeText();

  int textCount = 0;
  double xSize = 1., ySize = 1.;
  double xBot = 1., yBot = 1.;

  //FRW_PreparePng(kompas5, doc, xSize, ySize, xBot, yBot, textCount);

  double maxSize = xSize > ySize ? xSize : ySize;
  double koef    = 128./maxSize; // все картинки по умолчанию 128х128, потом сжимаются для четкой картинки
  if (!textCount)
    koef = 64. /maxSize;

  //FRW_ModifyHatch(maxSize / 50.);

  //doc->ksLayer(0);

//   // определяем невидимый стиль линий
//   API5::ksLibStylePtr style = kompas5->GetParamStruct(ko_LibStyle);
//   style->styleNumber    = 100;
//   style->typeAllocation = 1;
//   style->fileName       = kompas5->ksGetFullPathFromSystemPath(L"spds.lcs", 0 /*sptSYSTEM_FILES*/);
// 
//   // создаём невидимый прямоугольник, чтобы избежать компасового глюка 
//   // с потерей части изображения при сохранении в PNG
//   API5::ksRectangleParamPtr rect = kompas5->GetParamStruct(ko_RectangleParam);
//   rect->Init();
//   rect->x      = xBot - maxSize/20.;
//   rect->y      = yBot - maxSize/20.;
//   rect->width  = xSize + maxSize/10.;
//   rect->height = ySize + maxSize/10.;
//   rect->style  = doc->ksAddStyle(1 /*CURVE_STYLE*/, style, 1);

//  doc->ksRectangle(rect, 0);

  API5::ksRasterFormatParamPtr raster = doc->RasterFormatParam();
  raster->Init();
  raster->format       = FORMAT_PNG;
  raster->extResolution = 96;
  raster->colorBPP     = BPP_COLOR_32;
  raster->extScale     = 0.01;//0.236 * koef; // max(0.2633 * Koef,0.01); - защита // Масштаб сохранения 0.236 - коэффициент преобразования из мм в пиксели
  raster->onlyThinLine = 0;   // Все линии своей толщины (не всегда работает)
  raster->colorType    = COLOROBJECT;   // Цвет линий - по цвету объекта

  if (!doc->SaveAsToRasterFormat(pngName.c_str(), raster))
  {
    info->message = "не смогли сохранить в растер, " + aux::_w2a((LPCWSTR)info->kompas5->ksStrResult());
    return false;
  }

  if (!thumb::Strech(pngName))
  {
    info->message = "не смогли преобразовать растр";
    return false;
  }

  return true;
}
//-------------------------------------------------------------------------
void FRW_PreparePng(API5::KompasObjectPtr kompas5, API5::ksDocument2DPtr doc, double& xSize, double& ySize, double& xBot, double& yBot, int& textCount)
{
  long group = doc->ksNewGroup(1);
  doc->ksEndGroup();

  std::vector<long> removedObj;
  int objCount = 0;

  API5::ksIteratorPtr iter = kompas5->GetIterator();
  iter->ksCreateIterator(0 /*ALL_OBJ*/, 0);
  for (long moved = iter->ksMoveIterator(L"F"); moved; moved = iter->ksMoveIterator("'N"))
  {
    long obj = iter->Getreference();
    int type = doc->ksGetObjParam(obj, 0, 0);
    switch (type)
    {
      case POINT_OBJ:
      case LDIMENSION_OBJ:
      case ADIMENSION_OBJ:
      case DDIMENSION_OBJ:
      case RDIMENSION_OBJ:
      case LBREAKDIMENSION_OBJ:
      case ABREAKDIMENSION_OBJ:
      case ORDINATEDIMENSION_OBJ:
      case ARCDIMENSION_OBJ:
      case AXISLINE_OBJ:
        removedObj.push_back(obj);
        break;
      default:
        doc->ksAddObjGroup(group, obj);
        ++objCount;
    }
  }
  iter->ksDeleteIterator();

  if (objCount)
  {
    API5::ksRectParamPtr rect = kompas5->GetParamStruct(ko_RectParam);
    doc->ksGetObjGabaritRect(group, rect);
    API5::ksMathPointParamPtr top = rect->GetpTop();
    API5::ksMathPointParamPtr bot = rect->GetpBot();
    xSize = top->x - bot->x;
    xSize = top->y - bot->y;
    xBot  = bot->x;
    yBot  = bot->y;
    if (xSize < 0.0001)
      xSize = 1.;
    if (ySize < 0.001)
      ySize = 1.;
  }
}
//-------------------------------------------------------------------------
bool M3D_Prepare(kompas_server_info* info, const std::string& fromFile, bool isEngSys, kom_file& fileInfo)
{
  std::wstring tempM3d = info->tempDir + L"model.m3d";

  io::file::remove(tempM3d);
  io::file::copy(aux::_a2w(fromFile), tempM3d);

  API5::ksDocument3DPtr doc = info->kompas5->Document3D();
  if (0 == doc->Open(tempM3d.c_str(), VARIANT_TRUE))
  {
    doc->close();
    info->message = "не смогли открыть модель: " + fromFile;
    return false;
  }

  // посчитаем crc
  //API7::ICheckSumPtr crc = cache->kompas5->CheckSum;
  //crc->AddReference(doc->Reference, doc->Reference, TRUE );
  //fileInfo.crc = aux::_w2a(std::wstring(crc->StrResult.GetBSTR()));

  // развернем модель
  if (!isEngSys)
    if (API5::ksViewProjectionCollectionPtr views = doc->GetViewProjectionCollection())
      if (API5::ksViewProjectionPtr view = views->GetByIndex(7 /*vp_IsoXYZ*/))
        view->SetCurrent();

  doc->Save();
  doc->close();

  fileInfo.data.LoadFromFile(tempM3d);
  fileInfo.data.Compress();

  // создадим icon
  int pngSize = isEngSys ? 128 : 64;

  std::wstring pngFile = info->tempDir + L"model.png";
  io::file::remove(pngFile);

  if (!thumb::ExtractThumbnail(info->tempDir, L"model.m3d", L"model.png", pngSize))
  {
    info->message = "не смогли создать иконку с модели: " + fromFile;
    return false;
  }

  fileInfo.icon.LoadFromFile(pngFile);
  fileInfo.icon.Compress();
  
  return true;
}
