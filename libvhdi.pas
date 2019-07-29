//VHD (version1) read only operations

unit LibVHDI;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{/*
  * Module providing Delphi bindings for the Library libvhdi
  *
  * Copyright (c) 2014, Erwan LABALEC <erwan2212@gmail.com>,
  *
  * This software is free software: you can redistribute it and/or modify
  * it under the terms of the GNU Lesser General Public License as published by
  * the Free Software Foundation, either version 3 of the License, or
  * (at your option) any later version.
  *
  * This software is distributed in the hope that it will be useful,
  * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  * GNU General Public License for more details.
  *
  * You should have received a copy of the GNU Lesser General Public License
  * along with this software.  If not, see <http://www.gnu.org/licenses/>.
  */}


interface

uses
  windows,
  sysutils ;

type
  TINT16 = short;
  TUINT16 = word;
  TUINT8 = byte;
  PlibHDL = pointer;
  TSIZE = longword;
  TSIZE64 = int64;
  PSIZE64 = ^int64;

 Tlibvhdihandleinitialize=function(handle : PLIBHDL;error:pointer) : integer; cdecl; //pointer to PLIBHDL
 Tlibvhdihandlefree=function(handle : PLIBHDL;error:pointer) : integer; cdecl;  //pointer to PLIBHDL
 Tlibvhdihandleopen=function(handle : PLIBHDL;filename : pansichar; flags : integer;error:pointer) : integer; cdecl;
 Tlibvhdihandleopenwide=function(handle : PLIBHDL;filename : pwidechar; flags : integer;error:pointer) : integer; cdecl;
 Tlibvhdihandleclose=function(handle : PLIBHDL;error:pointer) : integer; cdecl;
 Tlibvhdihandlegetmediasize = function(handle : PLIBHDL; media_size : PSIZE64;error:pointer) : integer; cdecl;
 Tlibvhdihandlewritebuffer = function(handle : PLIBHDL; buffer : pointer; size : TSIZE; offset : TSIZE64;error:pointer) : integer; cdecl;
 Tlibvhdihandlereadbufferatoffset = function(handle : PLIBHDL; buffer : pointer; size : TSIZE; offset : TSIZE64;error:pointer) : integer; cdecl;
 Tlibvhdihandleseekoffset= function(handle : PLIBHDL; offset : TSIZE64;whence:integer;error:pointer) : TSIZE64; cdecl;
 Tlibvhdihandlereadbuffer=function(handle : PLIBHDL; buffer : pointer; size : TSIZE; error:pointer) : integer; cdecl;

  TLibvhdi = class(TObject)
  private
        fLibHandle : THandle;
        fCurHandle : PlibHDL;

        flibvhdihandleopen:Tlibvhdihandleopen ;
        flibvhdihandleopenwide:Tlibvhdihandleopenwide ;
        flibvhdihandleclose:Tlibvhdihandleclose ;
        flibvhdihandleinitialize:Tlibvhdihandleinitialize ;
        flibvhdihandlefree:Tlibvhdihandlefree ;
        flibvhdihandlereadbufferatoffset:Tlibvhdihandlereadbufferatoffset;
        flibvhdihandlewritebuffer:Tlibvhdihandlewritebuffer;
        flibvhdihandlegetmediasize:Tlibvhdihandlegetmediasize;
        flibvhdihandleseekoffset:Tlibvhdihandleseekoffset;
        flibvhdihandlereadbuffer:Tlibvhdihandlereadbuffer;

  public
        constructor create();
        destructor destroy(); override;
        function libvhdi_open(const filename : ansistring;flag:byte=$1) : integer;
        function libvhdi_open_wide(const filename : widestring;flag:byte=$1) : integer;
        function libvhdi_read_buffer_at_offset(buffer : pointer; size : longword; offset : int64) : integer;
        function libvhdi_write_buffer(buffer : pointer; size : longword; offset : int64) : integer;
        function libvhdi_get_media_size() : int64;
        function libvhdi_close() : integer;
  end;

const
        libvhdi_OPEN_READ = $01;
        libvhdi_OPEN_WRITE = $02;

        SEEK_CUR =   1;
        SEEK_END =   2;
        SEEK_SET  =  0;

implementation

constructor TLibvhdi.create();
var
        libFileName : ansistring;
begin
        fLibHandle:=0;
        fCurHandle:=nil;

        //libFileName:=ExtractFilePath(Application.ExeName)+'libvhdi.dll';
        //libFileName:=GetCurrentDir  +'\libvhdi.dll';
        libFileName:=ExtractFilePath(ParamStr(0))+'\libvhdi.dll';
        if fileExists(libFileName) then
        begin
                fLibHandle:=LoadLibraryA(PAnsiChar(libFileName));
                if fLibHandle<>0 then
                begin
                        @flibvhdihandleinitialize:=GetProcAddress(fLibHandle,'libvhdi_file_initialize');
                        @flibvhdihandlefree:=GetProcAddress(fLibHandle,'libvhdi_file_free');
                        @flibvhdihandleopen:=GetProcAddress(fLibHandle,'libvhdi_file_open');
                        @flibvhdihandleopenwide:=GetProcAddress(fLibHandle,'libvhdi_file_open_wide');
                        @flibvhdihandleclose:=GetProcAddress(fLibHandle,'libvhdi_file_close');
                        @flibvhdihandlereadbufferatoffset:=GetProcAddress(fLibHandle,'libvhdi_file_read_buffer_at_offset');
                        @flibvhdihandlewritebuffer:=GetProcAddress(fLibHandle,'libvhdi_file_write_buffer');
                        @flibvhdihandlegetmediasize:=GetProcAddress(fLibHandle,'libvhdi_file_get_media_size');
                        @flibvhdihandleseekoffset:=GetProcAddress(fLibHandle,'libvhdi_file_seek_offset');
                        @flibvhdihandlereadbuffer:=GetProcAddress(fLibHandle,'libvhdi_file_read_buffer');
                 end;
        end
        else raise exception.Create ('could not find libvhdi.dll');
end;

destructor Tlibvhdi.destroy();
begin
        if (fCurHandle<>nil) then
        begin
                libvhdi_close();
                FreeLibrary(fLibHandle);
        end;
        inherited;
end;


{/*
  * Open an entire (even multipart)  file.
  * @param filename - the first (.e01) file name.
  * @return 0 if successful and valid, -1 otherwise.
  */}
function Tlibvhdi.libvhdi_open(const filename : ansistring;flag:byte=$1) : integer;
var
        err:pointer;
        ret:integer;
begin
        err:=nil;
        Result:=-1;
        ret:=flibvhdihandleinitialize (@fCurHandle,@err); //pointer to pointer = ** in c
        if ret=1
           then if flibvhdihandleopen (fCurHandle,pchar(fileName), flag,@err)<>1
                then {raise exception.Create('flibvhdihandleopen failed')};
        if fCurHandle<>nil then  Result:=0;
end;

function Tlibvhdi.libvhdi_open_wide(const filename : widestring;flag:byte=$1) : integer;
var
        err:pointer;
        ret:integer;
begin
        err:=nil;
        Result:=-1;
        ret:=flibvhdihandleinitialize (@fCurHandle,@err); //pointer to pointer = ** in c
        if ret=1
           then if flibvhdihandleopenwide (fCurHandle,pwidechar(fileName), flag,@err)<>1
                then {raise exception.Create('flibvhdihandleopen failed')};
        if fCurHandle<>nil then  Result:=0;
end;


{/*
  * Read an arbitrary part of the  file.
  * @param buffer : pointer - pointer to a preallocated buffer (byte array) to read into.
  * @param size - The number of bytes to read
  * @param offset - The position within the  file.
  * @return The number of bytes successfully read, -1 if unsuccessful.
  */}
function Tlibvhdi.libvhdi_read_buffer_at_offset(buffer : pointer; size : longword; offset : int64) : integer;
var
err:pointer;
begin
        err:=nil;
        Result:=-1;
        if fLibHandle<>0 then
        begin
        {if flibvhdihandleseekoffset (fCurHandle ,offset,seek_set,@err)<>-1
          then result:=flibvhdihandlereadbuffer(fCurHandle ,buffer,size,@err);}
        Result:=flibvhdihandlereadbufferatoffset(fCurHandle, buffer, size, offset,@err);
        end;
end;

{/*
  * write an arbitrary part of the  file.
  * @param buffer : pointer - pointer to a preallocated buffer (byte array) to write from.
  * @param size - The number of bytes to write
  * @param offset - The position within the  file.
  * @return The number of bytes successfully written, -1 if unsuccessful.
  */}
function Tlibvhdi.libvhdi_write_buffer(buffer : pointer; size : longword; offset : int64) : integer;
var
err:pointer;
begin
        err:=nil;
        Result:=-1;
        if fLibHandle<>0 then
        begin
        Result:=flibvhdihandlewritebuffer (fCurHandle, buffer, size, offset,@err);
        end;
end;



{/*
  * Get the total true size of the  file.
  * @return The size of the  file in bytes, -1 if unsuccessful.
  */}
function Tlibvhdi.libvhdi_get_media_size() : int64;
var
        resInt64 :Int64;
        err:pointer;
begin
        err:=nil;
        Result:=-1;
        resInt64:=-1;
        if (fLibHandle<>0) and (fCurHandle<>nil) then
        begin
          flibvhdihandlegetmediasize (fCurHandle,@resInt64,@err);
          Result:=resInt64;
        end;
end;


{/*
  * Close the  file.
  * @return 0 if successful, -1 otherwise.
  */}
function Tlibvhdi.libvhdi_close() : integer;
var
err:pointer;
begin
        err:=nil;
        if fLibHandle<>0 then
        begin
        Result:=flibvhdihandleclose (fCurHandle,@err);
        if result=0 then result:=flibvhdihandlefree (@fCurHandle,@err);
        fCurHandle:=0;
        end;
end;

end.

