unit amqp.consumer;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$INCLUDE config.inc}
interface

uses {$IFNDEF FPC}
       {$IFDEF _WIN32}
          Net.Winsock2,
       {$ELSE}
          Net.SocketAPI,
       {$ENDIF}
     {$ELSE}
        Winsock2,
     {$ENDIF}
        amqp.mem, amqp.table, amqp.socket, AMQP.Types;

  function amqp_consume_message(Astate : Pamqp_connection_state;
                                out Aenvelope : Tamqp_envelope;
                                const Atimeout: Ptimeval;
                                Aflags: int ):Tamqp_rpc_reply;
  
  function amqp_read_message(state : Pamqp_connection_state;
                             channel : amqp_channel_t;
                             out Amessage : Tamqp_message;
                             flags: int):Tamqp_rpc_reply;
  function amqp_basic_consume( state : Pamqp_connection_state;
                             channel : amqp_channel_t;
                             queue, consumer_tag : Tamqp_bytes;
                             no_local, no_ack, exclusive : amqp_boolean_t;
                             arguments : Tamqp_table): Pamqp_basic_consume_ok;
implementation

function amqp_basic_consume( state : Pamqp_connection_state;
                             channel : amqp_channel_t;
                             queue, consumer_tag : Tamqp_bytes;
                             no_local, no_ack, exclusive : amqp_boolean_t;
                             arguments : Tamqp_table): Pamqp_basic_consume_ok;
var
  req : Tamqp_basic_consume;
begin
  req.ticket := 0;
  req.queue := queue;
  req.consumer_tag := consumer_tag;
  req.no_local := no_local;
  req.no_ack := no_ack;
  req.exclusive := exclusive;
  req.nowait := 0;
  req.arguments := arguments;
  Result := amqp_simple_rpc_decoded(state, channel, AMQP_BASIC_CONSUME_METHOD,
                                    AMQP_BASIC_CONSUME_OK_METHOD, @req);
end;

function amqp_consume_message(Astate : Pamqp_connection_state;
                              out Aenvelope : Tamqp_envelope;
                              const Atimeout: Ptimeval; Aflags: int):Tamqp_rpc_reply;
var
    res             : integer;
    Lframe          : Tamqp_frame;
    delivery_method : Pamqp_basic_deliver;
    ret             : Tamqp_rpc_reply;
    label error_out1;
    label error_out2;
begin
  memset(ret, 0, sizeof(ret));
  memset(Aenvelope, 0, sizeof(Tamqp_envelope));
  res := amqp_simple_wait_frame_noblock(Astate, Lframe, Atimeout);
  if Int(AMQP_STATUS_OK) <> res then
  begin
    ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
    ret.library_error := res;
    goto error_out1;
  end;

  if (AMQP_FRAME_METHOD <> Lframe.frame_type)  or
     (AMQP_BASIC_DELIVER_METHOD <> Lframe.payload.method.id) then
  begin
    amqp_put_back_frame(Astate, @Lframe);
    ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
    ret.library_error := Int(AMQP_STATUS_UNEXPECTED_STATE);
    goto error_out1;
  end;

  delivery_method := Pamqp_basic_deliver(Lframe.payload.method.decoded);
  Aenvelope.channel      := Lframe.channel;
  Aenvelope.consumer_tag := (@delivery_method.consumer_tag);
  Aenvelope.exchange     := (@delivery_method.exchange);
  Aenvelope.routing_key  := (@delivery_method.routing_key);

  Aenvelope.delivery_tag := delivery_method.delivery_tag;
  Aenvelope.redelivered  := delivery_method.redelivered;
  if (Aenvelope.consumer_tag.malloc_dup_failed > 0)   or
     (Aenvelope.exchange.malloc_dup_failed > 0)  or
     (Aenvelope.routing_key.malloc_dup_failed > 0) then
  begin
    ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
    ret.library_error := Int(AMQP_STATUS_NO_MEMORY);
    goto error_out2;
  end;

  ret := amqp_read_message(Astate, Aenvelope.channel, Aenvelope.message, 0);
  if AMQP_RESPONSE_NORMAL <> ret.reply_type then
  begin
    goto error_out2;
  end;

  ret.reply_type := AMQP_RESPONSE_NORMAL;
  Exit(ret);

error_out2:
  Aenvelope.routing_key.Destroy;
  Aenvelope.exchange.Destroy;
  Aenvelope.consumer_tag.Destroy;
error_out1:
  Result := ret;
end;


function amqp_read_message(state : Pamqp_connection_state;
                           channel : amqp_channel_t;
                           out Amessage : Tamqp_message; flags: int):Tamqp_rpc_reply;
var
    frame         : Tamqp_frame;
    ret           : Tamqp_rpc_reply;
    body_read     : size_t;
    body_read_ptr : PAMQPChar;
    res           : integer;
    label error_out1;
    label error_out2;
    label error_out3;
begin
  memset(ret, 0, sizeof(ret));
  memset(Amessage, 0, sizeof( Tamqp_message));
  res := amqp_simple_wait_frame_on_channel(state, channel, frame);
  if Int(AMQP_STATUS_OK) <> res then
  begin
    ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
    ret.library_error := res;
    goto error_out1;
  end;

  if frame.frame_type <> AMQP_FRAME_HEADER then
  begin
    if (AMQP_FRAME_METHOD = frame.frame_type)  and
       ( (AMQP_CHANNEL_CLOSE_METHOD = frame.payload.method.id)  or
         (AMQP_CONNECTION_CLOSE_METHOD = frame.payload.method.id) ) then
    begin
      ret.reply_type := AMQP_RESPONSE_SERVER_EXCEPTION;
      ret.reply := frame.payload.method;
    end
    else
    begin
      ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
      ret.library_error := Int(AMQP_STATUS_UNEXPECTED_STATE);
      amqp_put_back_frame(state, @frame);
    end;
    goto error_out1;
  end;

  //init_amqp_pool(@Amessage.pool, 4096);
  Amessage.pool.Create(4096);
  res := Pamqp_basic_properties(frame.payload.properties.decoded)^.clone(
                                     Amessage.properties, @Amessage.pool);
  if Int(AMQP_STATUS_OK) <> res then
  begin
    ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
    ret.library_error := res;
    goto error_out3;
  end;

  if 0 = frame.payload.properties.body_size then
  begin
    Amessage.body := amqp_empty_bytes;
  end
  else
  begin
    if SIZE_MAX < frame.payload.properties.body_size then
    begin
      ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
      ret.library_error := Int(AMQP_STATUS_NO_MEMORY);
      goto error_out1;
    end;
    Amessage.body := Tamqp_bytes.Create(size_t(frame.payload.properties.body_size));
    if nil = Amessage.body.bytes then
    begin
      ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
      ret.library_error := Int(AMQP_STATUS_NO_MEMORY);
      goto error_out1;
    end;
  end;

  body_read := 0;
  body_read_ptr := Amessage.body.bytes;
  while body_read < Amessage.body.len do
  begin
    res := amqp_simple_wait_frame_on_channel(state, channel, &frame);
    if Int(AMQP_STATUS_OK) <> res then
    begin
      ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
      ret.library_error := res;
      goto error_out2;
    end;

    if AMQP_FRAME_BODY <> frame.frame_type then
    begin
      if (AMQP_FRAME_METHOD = frame.frame_type ) and
         ( (AMQP_CHANNEL_CLOSE_METHOD = frame.payload.method.id)  or
           (AMQP_CONNECTION_CLOSE_METHOD = frame.payload.method.id)) then
      begin
        ret.reply_type := AMQP_RESPONSE_SERVER_EXCEPTION;
        ret.reply := frame.payload.method;
      end
      else
      begin
        ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
        ret.library_error := Int(AMQP_STATUS_BAD_AMQP_DATA);
      end;
      goto error_out2;
    end;

    if body_read + frame.payload.body_fragment.len > Amessage.body.len then
    begin
      ret.reply_type := AMQP_RESPONSE_LIBRARY_EXCEPTION;
      ret.library_error := Int(AMQP_STATUS_BAD_AMQP_DATA);
      goto error_out2;
    end;
    memcpy(body_read_ptr, frame.payload.body_fragment.bytes,
           frame.payload.body_fragment.len);
    body_read  := body_read + frame.payload.body_fragment.len;
    body_read_ptr  := body_read_ptr + frame.payload.body_fragment.len;
  end;
  ret.reply_type := AMQP_RESPONSE_NORMAL;
  Exit(ret);

error_out2:
  Amessage.body.Destroy;

error_out3:
  Amessage.pool.empty;

error_out1:
  Result := ret;
end;

end.


