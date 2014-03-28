#include "CacheApp.h"
#import <ksConstants.tlb>   no_namespace named_guids
#import <ksConstants3D.tlb> no_namespace named_guids
#import <kAPI2D5COM.tlb>    no_namespace named_guids
#import <kAPI3D5COM.tlb>    no_namespace named_guids
#import <kAPI7.tlb>         rename_namespace("API7") named_guids
#import <kAPI5.tlb>         named_guids rename_namespace("API5")
#include <ldefin2d.h>
#include "ibpp/ibpp.h"
#include "ByteData.h"
#include "_io.h"
#include "aux_ext.h"
#include "Thumb.h"
#include <list>


//-------------------------------------------------------------------------
struct FILE_INFO
{
  ByteData    data;
  ByteData    icon;
  std::string crc;
};
//-------------------------------------------------------------------------
struct CACHE_INFO
{
  API5::KompasObjectPtr kompas5;

  IBPP::Database    db;
  IBPP::Transaction trans;
  IBPP::Statement   findSt;
  IBPP::Statement   addSt;
  IBPP::Blob        dataBlob;
  IBPP::Blob        iconBlob;

  std::wstring      tempDir;
  std::wstring      tempFrw;
 
  std::list<FILE_INFO*> infoList;
};
//-------------------------------------------------------------------------
void FillRef(FILE_INFO& fileInfo, char** data, int* dataLen, char** crc, int* crcLen, char** icon, int* iconLen);
bool FindFileInCache(CACHE_INFO* cache, const char* digest, FILE_INFO& fileInfo);
void WriteFileInCache(CACHE_INFO* cache, const std::string& digest, FILE_INFO& fileInfo);
bool PrepareFile(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo);
bool FRW_Prepare(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo);
bool FRW_MoveDimension(API5::KompasObjectPtr kompas5, API5::ksDocument2DPtr doc);
bool FRW_CreatePng(std::wstring pngName, API5::KompasObjectPtr kompas5, API5::ksDocument2DPtr doc);
void FRW_PreparePng(API5::KompasObjectPtr kompas5, API5::ksDocument2DPtr doc, double& xSize, double& ySize, double& xBot, double& yBot, int& textCount);
bool M3D_Prepare(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo);


static std::string glb_error;
//-------------------------------------------------------------------------
const char* CacheApp::_ErrorMessage()
{
  return glb_error.c_str();
}
//-------------------------------------------------------------------------
int CacheApp::_NewInstance(const char* cacheDb, int majorVer, int minorVer)
{
  std::wstring tempDir = io::dir::temp_dir(L"_fdb_converter");
  if (!io::dir::exist(tempDir))
    io::dir::create(tempDir);

  auto remove = [](std::wstring file) -> bool
  {
    if (io::file::exist(file))
      return io::file::remove(file);
    return true;
  };
  if (!remove(tempDir + L"fragment.frw"))
  {
    glb_error = "не могу удалить временный файл фрагмента";
    return false;
  }
  if (!remove(tempDir + L"fragment.frw.png"))
  {
    glb_error = "не могу удалить временный файл иконки фрагмента";
    return false;
  }
  if (!remove(tempDir + L"model.m3d"))
  {
    glb_error = "не могу удалить временный файл модели";
    return false;
  }
  if (!remove(tempDir + L"model.m3d.png"))
  {
    glb_error = "не могу удалить временный файл иконки модели";
    return false;
  }

  // проверим подсоединение базы
  IBPP::Database base = IBPP::DatabaseFactory("", cacheDb, "sysdba", "masterkey");
  base->Connect();
  if (!base->Connected())
  {
    glb_error = "не смогли подключится к файловому кэшу";
    return 0;
  }

  IBPP::Transaction trans = IBPP::TransactionFactory(base, IBPP::amWrite, IBPP::ilReadCommitted, IBPP::lrNoWait);
  trans->Start();

  // если версия прописана, то проверим совпадение
  IBPP::Statement st = StatementFactory(base, trans);
  st->Execute("SELECT param_value FROM params WHERE param_key='version'");
  std::string version = std::string((LPCSTR)aux::itoa(majorVer)) + "." + std::string((LPCSTR)aux::itoa(minorVer));
  if (st->Fetch())
  {
    std::string res;
    st->Get(1, res);
    if (res != version)
    {
      glb_error = "версия файлового кэша не совпадает с версией компаса";
      return 0;
    }
  }
  else // если там версии нет, то это пустышка, пропишем текущую версию
  {
    st->Prepare("INSERT INTO params (param_key, param_value) VALUES(?, ?)");
    st->Set(1, "version");
    st->Set(2, version);
    st->Execute();
  }


  IBPP::Blob dataBlob = IBPP::BlobFactory(base, trans);
  IBPP::Blob iconBlob = IBPP::BlobFactory(base, trans);
  // подготовим нужные запросы к базе
  IBPP::Statement findSt = StatementFactory(base, trans);
  findSt->Prepare("SELECT data, icon, crc FROM files WHERE digest = ?");
  IBPP::Statement addSt = StatementFactory(base, trans);
  addSt->Prepare("INSERT INTO files (digest, data, icon, crc) VALUES(?, ?, ?, ?)");
  

  // запустим компас
  CoInitializeEx(NULL, COINIT_MULTITHREADED);

  CLSID clsid = IID_NULL;
  CLSIDFromProgID(L"KOMPAS.Application.5", &clsid);

  IUnknownPtr kompasApp;
  HRESULT hRes = CoCreateInstance(clsid, NULL, CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER, IID_IUnknown, (void**)&kompasApp);
  if (!SUCCEEDED(hRes))
  {
    glb_error = "не смогли запустить компас";
    return 0;
  }


  CACHE_INFO* cache = new CACHE_INFO; 
  cache->kompas5 = kompasApp;
  cache->db        = base;
  cache->trans     = trans;
  cache->findSt    = findSt;
  cache->addSt     = addSt;
  cache->dataBlob  = dataBlob;
  cache->iconBlob  = iconBlob;
  cache->tempDir   = tempDir;

  return (int)cache;
}
//-------------------------------------------------------------------------
bool CacheApp::_DeleteInstance(int c)
{
  CACHE_INFO* cache = (CACHE_INFO*)c;
  if (cache)
  {
    if (cache->kompas5)
      cache->kompas5->Quit();

    if (cache->db->Connected())
    {
      cache->trans->Commit();
      cache->db->Disconnect();
    }
  }

  delete cache;
  return true;
}
//-------------------------------------------------------------------------
void CacheApp::_ClearCache(int c)
{
  CACHE_INFO* cache = (CACHE_INFO*)c;
  for (auto it = cache->infoList.begin(); it != cache->infoList.end(); ++it)
    delete *it;
  cache->infoList.clear();
}
//-------------------------------------------------------------------------
bool CacheApp::_CacheFile(int c, const char* digest, const char* fromFile, bool isEngSys, char** data, int* dataLen, char** crc, int* crcLen, char** icon, int* iconLen, bool* isFromCache)
{
  CACHE_INFO* cache = (CACHE_INFO*)c;
  *isFromCache = false;

  FILE_INFO* fileInfo = new FILE_INFO();
  if (FindFileInCache(cache, digest, *fileInfo))
  {
    cache->infoList.push_back(fileInfo);
    FillRef(*fileInfo, data, dataLen, crc, crcLen, icon, iconLen);
    *isFromCache = true;
    return true;
  }

  if (PrepareFile(cache, fromFile, isEngSys, *fileInfo))
  {
    cache->infoList.push_back(fileInfo);
    WriteFileInCache(cache, digest, *fileInfo);
    FillRef(*fileInfo, data, dataLen, crc, crcLen, icon, iconLen);
    return true;
  }

  delete fileInfo;
  return false;
}
//-------------------------------------------------------------------------
void FillRef(FILE_INFO& fileInfo, char** data, int* dataLen, char** crc, int* crcLen, char** icon, int* iconLen)
{
  *data    = (char*)fileInfo.data.GetData();
  *dataLen = fileInfo.data.GetLength();
  *icon    = (char*)fileInfo.icon.GetData();
  *iconLen = fileInfo.icon.GetLength();
  *crc     = (char*)fileInfo.crc.c_str();
  *crcLen  = fileInfo.crc.size();
}
//-------------------------------------------------------------------------
bool FindFileInCache(CACHE_INFO* cache, const char* digest, FILE_INFO& fileInfo)
{
  cache->findSt->Set(1, digest);
  cache->findSt->Execute();
  if (!cache->findSt->Fetch())
    return false;

  cache->findSt->Get(1, cache->dataBlob);
  fileInfo.data.LoadFromBlob(cache->dataBlob);
  cache->findSt->Get(2, cache->iconBlob);
  fileInfo.icon.LoadFromBlob(cache->iconBlob);
  cache->findSt->Get(3, fileInfo.crc);

  return true;
}
//-------------------------------------------------------------------------
void WriteFileInCache(CACHE_INFO* cache, const std::string& digest, FILE_INFO& fileInfo)
{
  cache->addSt->Set(1, digest);
  fileInfo.data.SaveToBlob(cache->dataBlob);
  cache->addSt->Set(2, cache->dataBlob);
  fileInfo.icon.SaveToBlob(cache->iconBlob);
  cache->addSt->Set(3, cache->iconBlob);
  cache->addSt->Set(4, fileInfo.crc);

  cache->addSt->Execute();
}
//-------------------------------------------------------------------------
bool PrepareFile(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo)
{
  bool isFrw = fromFile.find("|", 0) != std::string::npos;
  if (isFrw)
    return FRW_Prepare(cache, fromFile, isEngSys, fileInfo);
  else
    return M3D_Prepare(cache, fromFile, isEngSys, fileInfo);
}
//-------------------------------------------------------------------------
bool FRW_Prepare(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo)
{
  std::wstring tempFrw = cache->tempDir + L"fragment.frw";
  if (io::file::exist(tempFrw))
    if (!io::file::remove(tempFrw))
    {
      glb_error = "не могу удалить временный файл фрагмента";
      return false;
    }

  API5::ksPlacementParamPtr place = cache->kompas5->GetParamStruct(ko_PlacementParam);
  place->Init();

  API5::ksDocumentParamPtr docParam(cache->kompas5->GetParamStruct(ko_DocumentParam));
  docParam->Init();
  docParam->type = lt_DocFragment;

  API5::ksDocument2DPtr doc = cache->kompas5->Document2D();
  doc->ksCreateDocument(docParam);

  // вставка фрагмента в документ
  API5::ksFragmentPtr frag = doc->GetFragment();
  long def = frag->ksFragmentDefinition(aux::_a2w(fromFile).c_str(), L"name", 0);
  if (def == 0)
  {
    glb_error = "frag->ksFragmentDefinition == 0 для " + fromFile;
    return false;
  }
  if (!frag->ksInsertFragment(def, FALSE, place))
  {
    glb_error = "frag->ksInsertFragment == 0 для " + fromFile;
    return false;
  }

  // перенесем РАЗМЕРЫ на отдельный слой
  if (FRW_MoveDimension(cache->kompas5, doc))
    fileInfo.crc = "dim=1";

  // создадим файл
  doc->ksSaveDocument(tempFrw.c_str());

  fileInfo.data.LoadFromFile(tempFrw);
  fileInfo.data.Compress();

  // создать иконку
  std::wstring pngName = tempFrw + L".png";
  io::file::remove(pngName);
  if (!FRW_CreatePng(pngName, cache->kompas5, doc))
  {
    doc->ksCloseDocument();
    glb_error = glb_error + ": " + fromFile;
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
bool FRW_CreatePng(std::wstring pngName, API5::KompasObjectPtr kompas5, API5::ksDocument2DPtr doc)
{
  //FRW_RemovePoints();
  //FRW_ChangeText();

  int textCount = 0;
  double xSize = 1., ySize = 1.;
  double xBot = 1., yBot = 1.;

  FRW_PreparePng(kompas5, doc, xSize, ySize, xBot, yBot, textCount);

  double maxSize = xSize > ySize ? xSize : ySize;
  double koef    = 128./maxSize; // все картинки по умолчанию 128х128, потом сжимаются для четкой картинки
  if (!textCount)
    koef = 64. /maxSize;

  //FRW_ModifyHatch(maxSize / 50.);

  doc->ksLayer(0);

  // определяем невидимый стиль линий
  API5::ksLibStylePtr style = kompas5->GetParamStruct(ko_LibStyle);
  style->styleNumber    = 100;
  style->typeAllocation = 1;
  style->fileName       = kompas5->ksGetFullPathFromSystemPath(L"spds.lcs", 0 /*sptSYSTEM_FILES*/);

  // создаём невидимый прямоугольник, чтобы избежать компасового глюка 
  // с потерей части изображения при сохранении в PNG
  API5::ksRectangleParamPtr rect = kompas5->GetParamStruct(ko_RectangleParam);
  rect->Init();
  rect->x      = xBot - maxSize/20.;
  rect->y      = yBot - maxSize/20.;
  rect->width  = xSize + maxSize/10.;
  rect->height = ySize + maxSize/10.;
  rect->style  = doc->ksAddStyle(1 /*CURVE_STYLE*/, style, 1);

  doc->ksRectangle(rect, 0);

  API5::ksRasterFormatParamPtr raster = doc->RasterFormatParam();
  raster->format       = 3;   /*FORMAT_PNG*/
  raster->colorBPP     = 32;  /*BPP_COLOR_32*/
  raster->extScale     = 0.236 * koef; // max(0.2633 * Koef,0.01); - защита // Масштаб сохранения 0.236 - коэффициент преобразования из мм в пиксели
  raster->onlyThinLine = 0;   // Все линии своей толщины (не всегда работает)
  raster->colorType    = 3    /*COLOROBJECT*/;   // Цвет линий - по цвету объекта

  if (!doc->SaveAsToRasterFormat(pngName.c_str(), raster))
  {
    glb_error = "не смогли сохранить в растер, " + aux::_w2a((LPCWSTR)kompas5->ksStrResult());
    return false;
  }

  if (!thumb::Strech(pngName))
  {
    glb_error = "не смогли преобразовать растр";
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
  }
}
//-------------------------------------------------------------------------
bool M3D_Prepare(CACHE_INFO* cache, const std::string& fromFile, bool isEngSys, FILE_INFO& fileInfo)
{
  std::wstring tempM3d = cache->tempDir + L"model.m3d";

  io::file::remove(tempM3d);
  io::file::copy(aux::_a2w(fromFile), tempM3d);

  API5::ksDocument3DPtr doc = cache->kompas5->Document3D();
  if (0 == doc->Open(tempM3d.c_str(), VARIANT_TRUE))
  {
    doc->close();
    glb_error = "не смогли открыть модель: " + fromFile;
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

  std::wstring pngFile = cache->tempDir + L"model.png";
  io::file::remove(pngFile);

  if (!thumb::ExtractThumbnail(cache->tempDir, L"model.m3d", L"model.png", pngSize))
  {
    glb_error = "не смогли создать иконку с модели: " + fromFile;
    return false;
  }

  fileInfo.icon.LoadFromFile(pngFile);
  fileInfo.icon.Compress();
  
  return true;
}
