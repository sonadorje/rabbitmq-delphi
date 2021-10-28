unit amqp.privt;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses AMQP.Types;

type
  Tbint = record
      case integer of
        0: (i: uint32_t);
        1: (c: array[0..3] of Byte);

  end;


function is_bigendian: bool;
function amqp_offset(data: PByte; offset : size_t): PByte;
function amqp_rpc_reply_error( status : Tamqp_status_enum):Tamqp_rpc_reply;

procedure amqp_e8(Aval : uint8_t; Adata: Pointer);
procedure amqp_e16(Aval : uint16_t;Adata: Pointer);
procedure amqp_e32(val : uint32_t;data: Pointer);
procedure amqp_e64(val : uint64_t; data: Pointer);

function amqp_encode_n(bits: Byte; encoded : Tamqp_bytes;offset : Psize_t; input : uint64_t):integer;
function amqp_encode_bytes(encoded : Tamqp_bytes;offset : Psize_t; input : Tamqp_bytes):integer;

function amqp_d8(data: Pointer):uint8_t;
function amqp_d16(data: Pointer):uint16_t;
function amqp_d32(data: Pointer):uint32_t;
function amqp_d64(data: Pointer):uint64_t;

function amqp_decode_8(encoded: Tamqp_bytes; offset: Psize_t; out output: uint8_t): int;
function amqp_decode_16(encoded: Tamqp_bytes; offset: Psize_t; out output: uint16_t): int;
function amqp_decode_32(encoded: Tamqp_bytes; offset: Psize_t; out output: uint32_t): int;
function amqp_decode_64(encoded: Tamqp_bytes; offset: Psize_t; out output: uint64_t): int;
function amqp_decode_bytes(encoded : Tamqp_bytes;offset : Psize_t; out output : Tamqp_bytes; len : size_t):integer;



implementation

function amqp_offset(data: PByte; offset : size_t): PByte;
begin
  Inc(data , offset);
  Result := data;
end;

function amqp_rpc_reply_error( status : Tamqp_status_enum):Tamqp_rpc_reply;
var
  reply : Tamqp_rpc_reply;
begin
  reply.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
  reply.library_error := Int(status);
  Result := reply;
end;

function amqp_decode_bytes(encoded : Tamqp_bytes;offset : Psize_t; out output : Tamqp_bytes; len : size_t):integer;
var
  o : size_t;
begin
  o := offset^;
  offset^ := o + len;
  if offset^ <= encoded.len then
  begin
    output.bytes := amqp_offset(encoded.bytes, o);
    output.len := len;
    Exit(1);
  end
  else
    Exit(0);

end;

function amqp_d32(data: Pointer):uint32_t;
var
  val : uint32_t;
begin
  memcpy(@val, data, sizeof(val));
  if  not is_bigendian then
  begin
    val := ((val and $FF000000)  shr  24) or ((val and $00FF0000)  shr  8) or
           ((val and $0000FF00)  shl  8)  or ((val and $000000FF)  shl  24);
  end;
  Result := val;
end;

procedure amqp_e64(val : uint64; data: Pointer);
begin
  if  not is_bigendian then
  begin
    val :=  ((val and 18374686479671623680)  shr  56) or
            ((val and 71776119061217280)     shr  40) or
            ((val and 280375465082880)       shr  24) or
            ((val and 1095216660480)         shr  8 ) or
            ((val and 4278190080)            shl  8 ) or
            ((val and 16711680)              shl  24) or
            ((val and 65280)                 shl  40) or
            ((val and 255)                   shl  56);
  end;
  memcpy(data, @val, sizeof(val));
end;

function amqp_d64(data: Pointer):uint64_t;
var
  val : uint64_t;
begin
    memcpy(@val, data, sizeof(val));
    if not is_bigendian then
    begin
      val :=  ((val and 18374686479671623680)  shr  56) or
              ((val and 71776119061217280)     shr  40) or
              ((val and 280375465082880)       shr  24) or
              ((val and 1095216660480)         shr  8 ) or
              ((val and 4278190080)            shl  8 ) or
              ((val and 16711680)              shl  24) or
              ((val and 65280)                 shl  40) or
              ((val and 255)                   shl  56);
    end;
    Result := val;
end;


function amqp_d16(data: Pointer):uint16_t;
var
  val : uint16_t;
begin
  memcpy(@val, data, sizeof(val));
  if not is_bigendian  then
     val := ((val and $FF00)  shr  8) or ((val and $00FF)  shl  8);

  Result := val;
end;


function amqp_d8(data: Pointer):uint8_t;
var
  val : uint8_t;
begin
  memcpy(@val, data, sizeof(val));
  Result := val;
end;


function amqp_encode_bytes(encoded : Tamqp_bytes;offset : Psize_t; input : Tamqp_bytes):integer;
var
  o : size_t;
begin
  o := offset^;
  { The memcpy below has undefined behavior if the input is nil. It is valid
   * for a 0-length amqp_bytes_t to have .bytes = nil. Thus we should check
   * before encoding.
   }
  if input.len = 0 then
    Exit(1);


  offset^ := o + input.len;
  if offset^ <= encoded.len then
  begin
    memcpy(amqp_offset(encoded.bytes, o), input.bytes, input.len);
    Exit(1);
  end
  else
     Exit(0);

end;

function amqp_decode_8(encoded: Tamqp_bytes; offset: Psize_t; out output: uint8_t): int;
var
  o : size_t;
begin
    o := offset^;
    offset^ := o + 1;//Round(8 / 8);
    if offset^ <= encoded.len then
    begin
      output := amqp_d8(amqp_offset(encoded.bytes, o));
      Exit(1);
    end;
    Result := 0;
end;

function amqp_decode_16(encoded: Tamqp_bytes; offset: Psize_t; out output: uint16_t): int;
var
  o : size_t;
begin
    o := offset^;
    offset^ := o + 2;//Round(16 / 8);
    if offset^ <= encoded.len then
    begin
      output := amqp_d16(amqp_offset(encoded.bytes, o));
      Exit(1);
    end;
    Result := 0;
end;

function amqp_decode_32(encoded: Tamqp_bytes; offset: Psize_t; out output: uint32_t): int;
var
  o : size_t;
begin
    o := offset^;
    offset^ := o + 32 DIV 8;
    if offset^ <= encoded.len then
    begin
      output := amqp_d32(amqp_offset(encoded.bytes, o));
      Exit(1);
    end;
    Result := 0;
end;

function amqp_decode_64(encoded: Tamqp_bytes; offset: Psize_t; out output: uint64_t): int;
var
  o : size_t;
begin
    o := offset^;
    offset^ := o + 8;//Round(64 / 8);
    if offset^ <= encoded.len then
    begin
      output := amqp_d64(amqp_offset(encoded.bytes, o));
      Exit(1);
    end;
    Result := 0;
end;

function amqp_encode_n(bits: Byte; encoded : Tamqp_bytes;offset : Psize_t; input : uint64_t):integer;
var
  o : size_t;
begin

    o := offset^;
    offset^ := o + bits div 8;
    if offset^ <= encoded.len then
    begin
      case bits of
         8:
           amqp_e8(input, amqp_offset(encoded.bytes, o));
         16:
           amqp_e16(input, amqp_offset(encoded.bytes, o));
         32:
           amqp_e32(input, amqp_offset(encoded.bytes, o));
         64:
           amqp_e64(input, amqp_offset(encoded.bytes, o));
      end;
      Exit( 1);
    end;

    Exit( 0);
end;

procedure amqp_e8(Aval : uint8_t; Adata: Pointer);
begin
  memcpy(Adata, @Aval, sizeof(Aval));
end;

procedure amqp_e16(Aval : uint16;Adata: Pointer);
begin
  if  not is_bigendian()  then
  begin
    Aval := ((Aval and uint32_t($FF00))  shr  uint32_t(8)) or ((Aval and uint32_t($00FF))  shl  uint32_t(8));
  end;
  memcpy(Adata, @Aval, sizeof(Aval));
end;

procedure amqp_e32(val : uint32;data: Pointer);
begin
  if  not is_bigendian then
  begin
    val := ((val and UInt32($FF000000))  shr  UInt32(24)) or ((val and UInt32($00FF0000))  shr  UInt32(8)) or
           ((val and UInt32($0000FF00))  shl  UInt32(8)) or ((val and UInt32($000000FF))  shl  UInt32(24));
  end;
  memcpy(data, @val, sizeof(val));
end;



function is_bigendian: bool;
var
  bint: Tbint;
begin
  bint.i := $01020304;
  Result := Ord(bint.c[0]) = 1;
end;


initialization

end.
