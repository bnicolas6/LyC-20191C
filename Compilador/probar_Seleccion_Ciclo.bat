del ts.txt
del intermedia.txt
c:\GnuWin32\bin\flex Lexico.l
pause
c:\GnuWin32\bin\bison -dyv Sintactico.y
pause
c:\MinGW\bin\gcc.exe lex.yy.c y.tab.c -o GCI.exe
pause
pause
GCI.exe ./pruebas/prueba_seleccion_ciclo.txt
del lex.yy.c
del y.tab.c
del y.output
del y.tab.h
del GCI.exe
pause