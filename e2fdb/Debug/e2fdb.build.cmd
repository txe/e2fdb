set PATH=C:\tools\D\dmd2\windows\\bin;C:\Program Files\Microsoft SDKs\Windows\v6.0A\\\bin;%PATH%
dmd -g -debug -X -Xf"Debug\e2fdb.json" -deps="Debug\e2fdb.dep" -c -of"Debug\e2fdb.obj" edb\edb.formula.d edb\edb.parser.d edb\edb.structure.d main.d utils.d
if errorlevel 1 goto reportError

set LIB="C:\tools\D\dmd2\windows\bin\..\lib"
echo. > Debug\e2fdb.build.lnkarg
echo "Debug\e2fdb.obj","Debug\e2fdb.exe_cv","Debug\e2fdb.map",user32.lib+ >> Debug\e2fdb.build.lnkarg
echo kernel32.lib/NOMAP/CO/NOI >> Debug\e2fdb.build.lnkarg

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps Debug\e2fdb.lnkdep C:\tools\D\dmd2\windows\bin\link.exe @Debug\e2fdb.build.lnkarg
if errorlevel 1 goto reportError
if not exist "Debug\e2fdb.exe_cv" (echo "Debug\e2fdb.exe_cv" not created! && goto reportError)
echo Converting debug information...
"C:\Program Files (x86)\VisualD\cv2pdb\cv2pdb.exe" "Debug\e2fdb.exe_cv" "Debug\e2fdb.exe"
if errorlevel 1 goto reportError
if not exist "Debug\e2fdb.exe" (echo "Debug\e2fdb.exe" not created! && goto reportError)

goto noError

:reportError
echo Building Debug\e2fdb.exe failed!

:noError
