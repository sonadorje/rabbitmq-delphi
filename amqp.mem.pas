unit amqp.mem;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$INCLUDE config.inc}
interface
uses  {$IFDEF FPC}SysUtils,{$Else} System.SysUtils, {$ENDIF} AMQP.Types;

 
 function amqp_cstring_bytes( const cstr: PAnsiChar):Tamqp_bytes;

 procedure amqp_dump( const buffer:Pointer; len : size_t);

implementation


function isprint( c : byte):byte;
begin
    if (c >= $20 ) and  (c <= $7e)  then
       Exit(1);
    Result := 0;
end;

procedure dump_row(count : longint; numinrow : integer;chs : Pinteger);
var
  i : integer;
begin
{$PointerMath on}
  write(format('%.8x:',[count - numinrow]));
  if numinrow > 0 then
  begin
    for i := 0 to numinrow-1 do
    begin
      if i = 8 then
        Write(':');

      write(format(' %.2x',[chs[i]]));
    end;
    for i := numinrow to 15 do
    begin
      if i = 8 then
        Write(':');

      Write('');
    end;
    Write('');

    for i := 0 to numinrow-1 do
    begin
      if isprint(chs[i])>0  then
        write(format('%s',[Chr(chs[i])]))
      else
        Write('.');

    end;
  end;
  Writeln;
 {$PointerMath off}
end;

function rows_eq(a, b : Pinteger):Boolean;
var
  i : integer;
begin
{$PointerMath on}
  for i := 0 to 15 do
    if a[i] <> b[i] then
      Exit(False);

  Result := True;
{$PointerMath off}
end;

procedure amqp_dump( const buffer:Pointer; len : size_t);
var
    buf         : Pbyte;
    count       : longint;
    numinrow    : integer;
    chs,
    oldchs      : array[0..15] of integer;
    showed_dots : integer;
    i           : size_t;
    ch,
    j           : integer;
begin
  buf := PByte(buffer);
  count := 0;
  numinrow := 0;

  showed_dots := 0;
  for i := 0 to len-1 do
  begin
    ch := buf[i];
    if numinrow = 16 then
    begin
      if rows_eq(@oldchs, @chs) then
      begin
        if  0>= showed_dots then
        begin
          showed_dots := 1;
          Writeln(
              '          .. .. .. .. .. .. .. .. : .. .. .. .. .. .. .. ..\n');
        end;
      end
      else
      begin
        showed_dots := 0;
        dump_row(count, numinrow, @chs);
      end;
      for j := 0 to 15 do
        oldchs[j] := chs[j];

      numinrow := 0;
    end;
    Inc(count);
    chs[numinrow] := ch;
    Inc(numinrow);
  end;
  dump_row(count, numinrow, @chs);
  if numinrow <> 0 then begin
    writeln(format('%.8x:',[count]));
  end;
end;

{ replaced by Tamqp_bytes.Implicit
function amqp_bytes_malloc_dup( src : Tamqp_bytes): Tamqp_bytes;
begin
  result.len := src.len;
  result.bytes := malloc(src.len);
  if result.bytes <> nil then begin
    memcpy(result.bytes, src.bytes, src.len);
  end;

end;  }

function amqp_cstring_bytes( const cstr: PAnsiChar):Tamqp_bytes;
begin
  result.len := Length(cstr);
  result.bytes := PAMQPChar(cstr);
end;

initialization

end.
