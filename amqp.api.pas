unit amqp.api;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses {$IFDEF FPC}SysUtils,{$Else} System.SysUtils, {$ENDIF} amqp.framing, AMQP.Types;

function amqp_basic_publish( state : Pamqp_connection_state; channel : amqp_channel_t;
                             exchange, routing_key : Tamqp_bytes;
                             mandatory, immediate : amqp_boolean_t;
                             properties: Pamqp_basic_properties;
                             body : Tamqp_bytes):integer;
function amqp_channel_close( state : Pamqp_connection_state; channel : amqp_channel_t; code : integer): Tamqp_rpc_reply;
function amqp_connection_close( state : Pamqp_connection_state; code : integer):Tamqp_rpc_reply;

implementation

uses amqp.socket, amqp.connection, amqp.privt, amqp.time;



function amqp_connection_close( state : Pamqp_connection_state; code : integer):Tamqp_rpc_reply;
var
  codestr : array[0..12] of AMQPChar;
  replies : Tamqp_methods;
  req : Tamqp_channel_close;
  s: Ansistring;
  i, Size: Integer;
begin
  SetLength(replies,2);
  replies[0] := AMQP_CONNECTION_CLOSE_OK_METHOD;
  replies[1] := 0;

  if (code < 0)  or  (code > UINT16_MAX) then
    Exit(amqp_rpc_reply_error(AMQP_STATUS_INVALID_PARAMETER));

  req.reply_code := uint16_t(code);
  req.reply_text.bytes := @codestr;
  s := Format('%d', [code]);
  size:=Length(S);
  For i:=1 To size Do
  Begin
     codestr[i-1]:=S[i];
     If (i = size) Then Break;
  End;
  req.reply_text.len := size;
  req.class_id := 0;
  req.method_id := 0;
  Result := amqp_simple_rpc(state, 0, AMQP_CONNECTION_CLOSE_METHOD, replies, @req);
  SetLength(replies,0);
end;

function amqp_channel_close( state : Pamqp_connection_state; channel : amqp_channel_t; code : integer): Tamqp_rpc_reply;
var
  codestr : array[0..12] of AMQPChar;
  replies : Tamqp_methods;
  req : Tamqp_channel_close;
  s: Ansistring;
  i, Size: Integer;
begin
  SetLength(replies,2);
  replies[0] := AMQP_CHANNEL_CLOSE_OK_METHOD;
  replies[1] := 0;

  if (code < 0)  or  (code > UINT16_MAX) then
    Exit(amqp_rpc_reply_error(AMQP_STATUS_INVALID_PARAMETER));

  req.reply_code := uint16_t(code);
  req.reply_text.bytes := @codestr;
  s := Format('%d', [code]);
  size:=Length(S);
  For i:=1 To size Do
  Begin
     codestr[i-1]:=S[i];
     If (i = size) Then Break;
  End;
  req.reply_text.len := size;
  req.class_id := 0;
  req.method_id := 0;
  Result := amqp_simple_rpc(state, channel, AMQP_CHANNEL_CLOSE_METHOD, replies, @req);
  SetLength(replies,0);
end;

function amqp_basic_publish( state : Pamqp_connection_state; channel : amqp_channel_t;
                             exchange, routing_key : Tamqp_bytes;
                             mandatory, immediate : amqp_boolean_t;
                             properties: Pamqp_basic_properties;
                             body : Tamqp_bytes):integer;
var
  f                        : Tamqp_frame;
  body_offset,
  usable_body_payload_size : size_t;
  res,
  flagz                    : integer;
  m                        : Tamqp_basic_publish;
  default_properties       : Tamqp_basic_properties;
  remaining                : size_t;
begin
  usable_body_payload_size := state.frame_max - (HEADER_SIZE + FOOTER_SIZE);
  m.exchange := exchange;
  m.routing_key := routing_key;
  m.mandatory := mandatory;
  m.immediate := immediate;
  m.ticket := 0;
  { TODO(alanxz): this heartbeat check is happening in the wrong place, it
   * should really be done in amqp_try_send/writev }
  res := amqp_time_has_past(state.next_recv_heartbeat);
  if Int(AMQP_STATUS_TIMER_FAILURE) = res then
    Exit(res)

  else
  if (Int(AMQP_STATUS_TIMEOUT) = res) then
  begin
    res := amqp_try_recv(state);
    if Int(AMQP_STATUS_TIMEOUT) = res then
      Exit(Int(AMQP_STATUS_HEARTBEAT_TIMEOUT))
    else if int(AMQP_STATUS_OK) <> res then
      Exit(res);

  end;
  res := amqp_send_method_inner(state, channel, AMQP_BASIC_PUBLISH_METHOD, @m,
                               Int(AMQP_SF_MORE), Tamqp_time.infinite());
  if res < 0 then
    Exit(res);

  if properties = nil then
  begin
    memset(default_properties, 0, sizeof(default_properties));
    properties := @default_properties;
  end;
  f.frame_type := AMQP_FRAME_HEADER;
  f.channel := channel;
  f.payload.properties.class_id := AMQP_BASIC_CLASS;
  f.payload.properties.body_size := body.len;
  f.payload.properties.decoded := Pointer(properties);
  if body.len > 0 then
    flagz := Int(AMQP_SF_MORE)
  else
    flagz := Int(AMQP_SF_NONE);

  res := amqp_send_frame_inner(state, f, flagz, Tamqp_time.infinite);
  if res < 0 then
    Exit(res);

  body_offset := 0;
  while body_offset < body.len do
  begin
    remaining := body.len - body_offset;
    if remaining = 0 then
      break;

    f.frame_type := AMQP_FRAME_BODY;
    f.channel := channel;
    f.payload.body_fragment.bytes := amqp_offset(body.bytes, body_offset);
    if remaining >= usable_body_payload_size then
    begin
      f.payload.body_fragment.len := usable_body_payload_size;
      flagz := Int(AMQP_SF_MORE);
    end
    else
    begin
      f.payload.body_fragment.len := remaining;
      flagz := Int(AMQP_SF_NONE);
    end;
    body_offset  := body_offset + f.payload.body_fragment.len;
    res := amqp_send_frame_inner(state, f, flagz, Tamqp_time.infinite());
    if res < 0 then
      Exit(res);

  end;
  Result := Int(AMQP_STATUS_OK);
end;

initialization

end.
