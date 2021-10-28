unit amqp.table;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses AMQP.Types, amqp.privt, amqp.mem;


function amqp_decode_table(encoded : Tamqp_bytes; pool : Pamqp_pool; out output : Tamqp_table; offset : Psize_t):integer;
function amqp_encode_table(encoded : Tamqp_bytes; input : Pamqp_table; offset : Psize_t):integer;

function amqp_encode_field_value(encoded : Tamqp_bytes;const entry : Pamqp_field_value; offset : Psize_t):integer;
function amqp_decode_field_value(encoded : Tamqp_bytes; pool : Pamqp_pool; out entry : Tamqp_field_value; offset : Psize_t):integer;
//function amqp_table_get_entry_by_key(const table : Pamqp_table;const key : Tamqp_bytes):Pamqp_table_entry;
function amqp_decode_array(encoded : Tamqp_bytes; pool : Pamqp_pool; out output : Tamqp_array; offset : Psize_t):integer;
//function amqp_table_clone(const original: Tamqp_table;out clone : Tamqp_table; pool : Pamqp_pool):integer;
//function amqp_table_entry_clone(const original: Pamqp_table_entry; clone : Pamqp_table_entry; pool : Pamqp_pool):integer;
//function amqp_field_value_clone(const original: Pamqp_field_value; clone : Pamqp_field_value; pool : Pamqp_pool):integer;

const
  INITIAL_ARRAY_SIZE =16;
  INITIAL_TABLE_SIZE =16;

implementation


function amqp_decode_array(encoded : Tamqp_bytes; pool : Pamqp_pool;
                           out output : Tamqp_array; offset : Psize_t):integer;
var
    arraysize         : uint32;
  num_entries,
  allocated_entries : integer;
  entries           : Pamqp_field_value;
  limit             : size_t;
  res               : integer;
  newentries        : Pointer;
  label _out;
begin
{$POINTERMATH ON}
  num_entries := 0;
  allocated_entries := INITIAL_ARRAY_SIZE;
  if  0= amqp_decode_32(encoded, offset, &arraysize ) then
  begin
    Exit(Int(AMQP_STATUS_BAD_AMQP_DATA));
  end;
  if arraysize + offset^ > encoded.len then
  begin
    Exit(Int(AMQP_STATUS_BAD_AMQP_DATA));
  end;
  entries := allocMem(allocated_entries * sizeof(Tamqp_field_value));
  if entries = nil then
    Exit(Int(AMQP_STATUS_NO_MEMORY));

  limit := offset^ + arraysize;
  while offset^ < limit do
  begin
    if num_entries >= allocated_entries then
    begin
      allocated_entries := allocated_entries * 2;
      reallocMem(entries, allocated_entries * sizeof(Tamqp_field_value));
      res := Int(AMQP_STATUS_NO_MEMORY);
      if entries = nil then
         goto _out;
    end;
    res := amqp_decode_field_value(encoded, pool, entries[num_entries], offset);
    if res < 0 then
       goto _out;
    Inc(num_entries);
  end;
  output.num_entries := num_entries;
  output.entries := pool.alloc( num_entries * sizeof(Tamqp_field_value));
  { nil is legitimate if we requested a zero-length block. }
  if output.entries = nil then
  begin
    if num_entries = 0 then
      res := Int(AMQP_STATUS_OK)
    else
      res := Int(AMQP_STATUS_NO_MEMORY);

  end;
  memcpy(output.entries, entries, num_entries * sizeof(Tamqp_field_value));
  res := Int(AMQP_STATUS_OK);
_out:
  freeMem(entries);
  Result := res;
  {$POINTERMATH OFF}
end;

function amqp_decode_field_value(encoded : Tamqp_bytes;pool : Pamqp_pool;
                                 out entry : Tamqp_field_value; offset : Psize_t):integer;
var
  res : integer;
  len : uint32;
  label _out;

  procedure SIMPLE_FIELD_DECODER(bits: Byte; dest: string);
  var
    Lval8: uint8_t;
    Lval16: uint16_t;
    Lval32: uint32_t;
    Lval64: uint64_t;
    label _out;
  begin
    case bits of
      8:
      begin
        if (0=amqp_decode_8(encoded, offset, Lval8)) then
           goto _out;
        if dest = 'i8' then
         entry.value.i8 := Lval8
        else
        if dest = 'boolean' then
        begin
           if Lval8 > 0 then
             entry.value.boolean := 1
           else
             entry.value.boolean := 0;
        end;
      end;
      16:
      begin

        if (0=amqp_decode_16(encoded, offset, Lval16)) then
           goto _out;
        if dest = 'i16' then
           entry.value.i16 := Lval16;
      end;
      32:
      begin

        if (0=amqp_decode_32(encoded, offset, Lval32)) then
           goto _out;
        if dest = 'i32' then
          entry.value.i32 := Lval32;
      end;
      64:
      begin

        if (0=amqp_decode_64(encoded, offset, Lval64)) then
           goto _out;
        if dest = 'i64' then
          entry.value.i64 := Lval64
      end;

    end;

   _out:
      Result := res;
  end;

  procedure TRIVIAL_FIELD_DECODER(bits: byte);
  label _out;
  begin
     case bits of
        8:
        if 0=amqp_decode_8(encoded, offset, entry.value.u8) then
           goto _out;
        16:
        if 0=amqp_decode_16(encoded, offset, entry.value.u16) then
           goto _out;
        32:
        if 0=amqp_decode_32(encoded, offset, entry.value.u32) then
           goto _out;
     end;

     _out:
      Result := res;
  end;

begin
  res := Int(AMQP_STATUS_BAD_AMQP_DATA);
  if  0= amqp_decode_8(encoded, offset, entry.kind ) then
     goto _out;
  case entry.kind of
    Int(AMQP_FIELD_KIND_BOOLEAN):
      SIMPLE_FIELD_DECODER(8, 'boolean');
    Int(AMQP_FIELD_KIND_I8):
      SIMPLE_FIELD_DECODER(8, 'i8');
    Int(AMQP_FIELD_KIND_U8):
      TRIVIAL_FIELD_DECODER(8);
    Int(AMQP_FIELD_KIND_I16):
      SIMPLE_FIELD_DECODER(16, 'i16');
    Int(AMQP_FIELD_KIND_U16):
      TRIVIAL_FIELD_DECODER(16);
    Int(AMQP_FIELD_KIND_I32):
      SIMPLE_FIELD_DECODER(32, 'i32');
    Int(AMQP_FIELD_KIND_U32):
      TRIVIAL_FIELD_DECODER(32);
    Int(AMQP_FIELD_KIND_I64):
      SIMPLE_FIELD_DECODER(64, 'i64');
    Int(AMQP_FIELD_KIND_U64):
      TRIVIAL_FIELD_DECODER(64);
    Int(AMQP_FIELD_KIND_F32):
      TRIVIAL_FIELD_DECODER(32);
      { and by punning, f32 magically gets the right value...! }
    Int(AMQP_FIELD_KIND_F64):
      TRIVIAL_FIELD_DECODER(64);
      { and by punning, f64 magically gets the right value...! }
    Int(AMQP_FIELD_KIND_DECIMAL):
      if  (0= amqp_decode_8(encoded, offset, entry.value.decimal.decimals))  or
          (0= amqp_decode_32(encoded, offset, entry.value.decimal.value))then
          goto _out;

    Int(AMQP_FIELD_KIND_UTF8),
    { AMQP_FIELD_KIND_UTF8 and AMQP_FIELD_KIND_BYTES have the
       same implementation, but different interpretations. }
    { fall through }
    Int(AMQP_FIELD_KIND_BYTES):
    begin
      if  (0= amqp_decode_32(encoded, offset, &len))  or
          (0= amqp_decode_bytes(encoded, offset, entry.value.bytes, len))  then
        goto _out;

    end;
    Int(AMQP_FIELD_KIND_ARRAY):
      res := amqp_decode_array(encoded, pool, entry.value.&array, offset);
    Int(AMQP_FIELD_KIND_TIMESTAMP):
      TRIVIAL_FIELD_DECODER(64);
    Int(AMQP_FIELD_KIND_TABLE):
      res := amqp_decode_table(encoded, pool, entry.value.table, offset);
    Int(AMQP_FIELD_KIND_VOID):

    else  goto _out;
  end;
  res := Int(AMQP_STATUS_OK);
_out:
  Result := res;
end;

function amqp_decode_table(encoded : Tamqp_bytes; pool : Pamqp_pool;
                           out output : Tamqp_table; offset : Psize_t):integer;
var
    tablesize         : uint32;
    num_entries       : integer;
    entries           : Pamqp_table_entry;
    allocated_entries : integer;
    limit             : size_t;
    res               : integer;
    keylen            : byte;

    newentries        : Pointer;
    label _out;
begin
{$POINTERMATH ON}
  num_entries := 0;
  allocated_entries := INITIAL_TABLE_SIZE;
  if  0= amqp_decode_32(encoded, offset, &tablesize )then
  begin
    Exit(Int(AMQP_STATUS_BAD_AMQP_DATA));
  end;
  if tablesize + offset^ > encoded.len then
  begin
    Exit(Int(AMQP_STATUS_BAD_AMQP_DATA));
  end;
  entries := allocMem(allocated_entries * sizeof(Tamqp_table_entry));
  if entries = nil then
    Exit(Int(AMQP_STATUS_NO_MEMORY));

  limit := offset^ + tablesize;
  while offset^ < limit do
  begin
    res := Int(AMQP_STATUS_BAD_AMQP_DATA);
    if  0= amqp_decode_8(encoded, offset, &keylen )then
       goto _out;
    if num_entries >= allocated_entries then
    begin
      allocated_entries := allocated_entries * 2;
      reallocMem(entries, allocated_entries * sizeof(Tamqp_table_entry));
      res := Int(AMQP_STATUS_NO_MEMORY);
      if entries = nil then
        goto _out;

    end;
    res := Int(AMQP_STATUS_BAD_AMQP_DATA);
    if  0= amqp_decode_bytes(encoded, offset, entries[num_entries].key, keylen) then
        goto _out;
    res := amqp_decode_field_value(encoded, pool, entries[num_entries].value,offset);
    if res < 0 then
      goto _out;
    Inc(num_entries);
  end;

  output.num_entries := num_entries;
  output.entries := pool.alloc( num_entries * sizeof(Tamqp_table_entry));
  { nil is legitimate if we requested a zero-length block. }
  if output.entries = nil then
  begin
    if num_entries = 0 then
      res := Int(AMQP_STATUS_OK)
    else
      res := Int(AMQP_STATUS_NO_MEMORY);

  end;
  memcpy(output.entries, entries, num_entries * sizeof(Tamqp_table_entry));
  res := Int(AMQP_STATUS_OK);

_out:
  freemem(entries);
  Result := res;
  {$POINTERMATH OFF}
end;

function amqp_encode_array(encoded : Tamqp_bytes; input : Pamqp_array; offset : Psize_t):integer;
var
  start : size_t;
  i, res : integer;
  label _out;
begin
{$POINTERMATH ON}
  start := offset^;
  offset^ := offset^ + 4;
  for i := 0 to input.num_entries-1 do
  begin
    res := amqp_encode_field_value(encoded, @input.entries[i], offset);
    if res < 0 then
      goto _out;
  end;

  if  0= amqp_encode_n(32, encoded, @start, uint32_t( offset^ - start - 4)) then
  begin
    res := Integer(AMQP_STATUS_TABLE_TOO_BIG);
    goto _out;
  end;
  res := Integer(AMQP_STATUS_OK);
_out:
  Result := res;
  {$POINTERMATH OFF}
end;

function amqp_encode_field_value(encoded : Tamqp_bytes;const entry : Pamqp_field_value; offset : Psize_t):integer;
var
  res, value : integer;
  label _out;
  procedure FIELD_ENCODER(bits, val: Byte);
  begin
    if 0= amqp_encode_n(bits, encoded, offset, val) then
      res := Integer(AMQP_STATUS_TABLE_TOO_BIG);
  end;

begin
  res := Integer(AMQP_STATUS_BAD_AMQP_DATA);
  if  0= amqp_encode_n(8, encoded, offset, entry.kind)  then
    goto _out;

  case entry.kind of
    uint8(AMQP_FIELD_KIND_BOOLEAN):
    begin
      if entry.value.boolean > 0  then
         value := 1
      else
         value := 0;
      FIELD_ENCODER(8, value);
    end;
    uint8(AMQP_FIELD_KIND_I8):
      FIELD_ENCODER(8, entry.value.i8);
    uint8(AMQP_FIELD_KIND_U8):
      FIELD_ENCODER(8, entry.value.u8);
    uint8(AMQP_FIELD_KIND_I16):
      FIELD_ENCODER(16, entry.value.i16);
    uint8(AMQP_FIELD_KIND_U16):
      FIELD_ENCODER(16, entry.value.u16);
    uint8(AMQP_FIELD_KIND_I32):
      FIELD_ENCODER(32, entry.value.i32);
    uint8(AMQP_FIELD_KIND_U32):
      FIELD_ENCODER(32, entry.value.u32);
    uint8(AMQP_FIELD_KIND_I64):
      FIELD_ENCODER(64, entry.value.i64);
    uint8(AMQP_FIELD_KIND_U64):
      FIELD_ENCODER(64, entry.value.u64);
    uint8(AMQP_FIELD_KIND_F32):
      { by punning, u32 magically gets the right value...! }
      FIELD_ENCODER(32, entry.value.u32);
    uint8(AMQP_FIELD_KIND_F64):
      { by punning, u64 magically gets the right value...! }
      FIELD_ENCODER(64, entry.value.u64);
    uint8(AMQP_FIELD_KIND_DECIMAL):
    begin
      if  (0= amqp_encode_n(8, encoded, offset, entry.value.decimal.decimals))   or
          (0= amqp_encode_n(32, encoded, offset, entry.value.decimal.value)) then
      begin
         res := Integer(AMQP_STATUS_TABLE_TOO_BIG);
         goto _out;
      end;
    end;

    uint8(AMQP_FIELD_KIND_UTF8),
    { AMQP_FIELD_KIND_UTF8 and AMQP_FIELD_KIND_BYTES have the
       same implementation, but different interpretations. }
    { fall through }
    uint8(AMQP_FIELD_KIND_BYTES):
    begin
      if  (0= amqp_encode_n(32, encoded, offset, uint32_t (entry.value.bytes.len)))  or
          (0= amqp_encode_bytes(encoded, offset, entry.value.bytes))  then
      begin
        res := Integer(AMQP_STATUS_TABLE_TOO_BIG);
        goto _out;
      end;
    end;
    uint8(AMQP_FIELD_KIND_ARRAY):
    begin
      res := amqp_encode_array(encoded, @entry.value.&array, offset);
      goto _out;
    end;
    uint8(AMQP_FIELD_KIND_TIMESTAMP):
      FIELD_ENCODER(64, entry.value.u64);
    uint8(AMQP_FIELD_KIND_TABLE):
    begin
      res := amqp_encode_table(encoded, @entry.value.table, offset);
      goto _out;
    end;
    uint8(AMQP_FIELD_KIND_VOID):
      begin
         //
      end;
    else
      res := Integer(AMQP_STATUS_INVALID_PARAMETER);
  end;
  res := Integer(AMQP_STATUS_OK);
_out:
  Result := res;
end;

function amqp_encode_table(encoded : Tamqp_bytes; input : Pamqp_table; offset : Psize_t):integer;
var
  start : size_t;
  i, res : integer;
  label _out;
begin
{$POINTERMATH ON}
  start := offset^;
  offset^  := offset^ + 4;
  for i := 0 to input.num_entries-1 do
  begin
    if  0= amqp_encode_n(8, encoded, offset, uint8_t(input.entries[i].key.len))  then
    begin
      res := Integer(AMQP_STATUS_TABLE_TOO_BIG);
      goto _out;
    end;
    if  0= amqp_encode_bytes(encoded, offset, input.entries[i].key ) then
    begin
      res := Integer(AMQP_STATUS_TABLE_TOO_BIG);
      goto _out;
    end;
    res := amqp_encode_field_value(encoded, @input.entries[i].value, offset);
    if res < 0 then
       goto _out;

  end;

  if 0= amqp_encode_n(32, encoded, @start, uint32_t( offset^ - start - 4)) then
  begin
    res := Integer(AMQP_STATUS_TABLE_TOO_BIG);
    goto _out;
  end;
  res := Integer(AMQP_STATUS_OK);
_out:
  Result := res;
  {$POINTERMATH OFF}
end;

initialization

end.
