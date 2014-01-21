// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the E2FDBHELPER_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// E2FDBHELPER_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef E2FDBHELPER_EXPORTS
#define E2FDBHELPER_API __declspec(dllexport)
#else
#define E2FDBHELPER_API __declspec(dllimport)
#endif


E2FDBHELPER_API const char* fdb_error();

E2FDBHELPER_API intptr_t fdb_provider_open(const char* serverName, const char* baseName, const char* user, const char* password);
E2FDBHELPER_API bool     fdb_provider_close(intptr_t provider);

E2FDBHELPER_API intptr_t fdb_transaction_open(intptr_t provider);
E2FDBHELPER_API bool     fdb_transaction_close(intptr_t trans);
E2FDBHELPER_API bool     fdb_transaction_start(intptr_t trans);
E2FDBHELPER_API bool     fdb_transaction_commit(intptr_t trans);
E2FDBHELPER_API bool     fdb_transaction_rollback(intptr_t trans);

E2FDBHELPER_API intptr_t fdb_statement_open(intptr_t provider, intptr_t trans);
E2FDBHELPER_API bool     fdb_statement_close(intptr_t st);

E2FDBHELPER_API bool     fdb_statement_prepare(intptr_t st, const char* query);
E2FDBHELPER_API bool     fdb_statement_execute(intptr_t st, const char* query);
E2FDBHELPER_API bool     fdb_statement_execute_immediate(intptr_t st, const char* query);
E2FDBHELPER_API bool     fdb_statement_fetch(intptr_t st);

E2FDBHELPER_API bool     fdb_statement_set_null(intptr_t st, int index);
E2FDBHELPER_API bool     fdb_statement_set_int(intptr_t st, int index, int Value);
E2FDBHELPER_API bool     fdb_statement_set_double(intptr_t st, int index, const double* value);
E2FDBHELPER_API bool     fdb_statement_set_string(intptr_t st, int index, const char* value);

E2FDBHELPER_API bool     fdb_statement_get_is_null(intptr_t st, int index);
E2FDBHELPER_API bool     fdb_statement_get_int(intptr_t st, int index, int* value);
E2FDBHELPER_API bool     fdb_statement_get_double(intptr_t st, int index, double* value);
E2FDBHELPER_API bool     fdb_statement_get_string(intptr_t st, int index, char* value);








