unit amqp.framing;

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
         winsock2,
     {$ENDIF}
      AMQP.Types;


function amqp_encode_method(methodNumber : amqp_method_number_t;decoded: Pointer; encoded : Tamqp_bytes):integer;
function amqp_decode_method(methodNumber : amqp_method_number_t;pool : Pamqp_pool; encoded : Tamqp_bytes; out decoded: Pointer):integer;

function amqp_encode_properties(class_id : uint16;decoded: Pointer; encoded : Tamqp_bytes):integer;
function amqp_decode_properties(class_id : uint16; pool : Pamqp_pool; encoded : Tamqp_bytes; decoded: PPointer):integer;
function amqp_channel_open( state : Pamqp_connection_state; channel : amqp_channel_t): Pamqp_channel_open_ok;
function amqp_queue_bind( state : Pamqp_connection_state;
                          channel : amqp_channel_t; queue, exchange,
                          routing_key : Tamqp_bytes;
                          arguments : Tamqp_table): Pamqp_queue_bind_ok;
function amqp_exchange_declare( Astate : Pamqp_connection_state;
                                Achannel : amqp_channel_t;
                                Aexchange, Atype : Tamqp_bytes;
                                Apassive, Adurable, Aauto_delete, Ainternal : amqp_boolean_t;
                                Aarguments : Tamqp_table):Pamqp_exchange_declare_ok;

function amqp_queue_unbind( state : Pamqp_connection_state;
                            channel : amqp_channel_t;
                            queue, exchange, routing_key : Tamqp_bytes;
                            arguments : Tamqp_table): Pamqp_queue_unbind_ok;
function amqp_queue_declare( state : Pamqp_connection_state;
                             channel : amqp_channel_t; queue : Tamqp_bytes;
                             passive, durable, exclusive, auto_delete : amqp_boolean_t;
                             arguments : Tamqp_table): Pamqp_queue_declare_ok;

function amqp_method_name( methodNumber : amqp_method_number_t): PAnsiChar;

implementation

uses
   amqp.privt, amqp.table, amqp.mem, amqp.socket;

function amqp_method_name( methodNumber : amqp_method_number_t): PAnsiChar;
begin
  case methodNumber of
    AMQP_CONNECTION_START_METHOD:
      Exit('AMQP_CONNECTION_START_METHOD');
    AMQP_CONNECTION_START_OK_METHOD:
      Exit('AMQP_CONNECTION_START_OK_METHOD');
    AMQP_CONNECTION_SECURE_METHOD:
      Exit('AMQP_CONNECTION_SECURE_METHOD');
    AMQP_CONNECTION_SECURE_OK_METHOD:
      Exit('AMQP_CONNECTION_SECURE_OK_METHOD');
    AMQP_CONNECTION_TUNE_METHOD:
      Exit('AMQP_CONNECTION_TUNE_METHOD');
    AMQP_CONNECTION_TUNE_OK_METHOD:
      Exit('AMQP_CONNECTION_TUNE_OK_METHOD');
    AMQP_CONNECTION_OPEN_METHOD:
      Exit('AMQP_CONNECTION_OPEN_METHOD');
    AMQP_CONNECTION_OPEN_OK_METHOD:
      Exit('AMQP_CONNECTION_OPEN_OK_METHOD');
    AMQP_CONNECTION_CLOSE_METHOD:
      Exit('AMQP_CONNECTION_CLOSE_METHOD');
    AMQP_CONNECTION_CLOSE_OK_METHOD:
      Exit('AMQP_CONNECTION_CLOSE_OK_METHOD');
    AMQP_CONNECTION_BLOCKED_METHOD:
      Exit('AMQP_CONNECTION_BLOCKED_METHOD');
    AMQP_CONNECTION_UNBLOCKED_METHOD:
      Exit('AMQP_CONNECTION_UNBLOCKED_METHOD');
    AMQP_CONNECTION_UPDATE_SECRET_METHOD:
      Exit('AMQP_CONNECTION_UPDATE_SECRET_METHOD');
    AMQP_CONNECTION_UPDATE_SECRET_OK_METHOD:
      Exit('AMQP_CONNECTION_UPDATE_SECRET_OK_METHOD');
    AMQP_CHANNEL_OPEN_METHOD:
      Exit('AMQP_CHANNEL_OPEN_METHOD');
    AMQP_CHANNEL_OPEN_OK_METHOD:
      Exit('AMQP_CHANNEL_OPEN_OK_METHOD');
    AMQP_CHANNEL_FLOW_METHOD:
      Exit('AMQP_CHANNEL_FLOW_METHOD');
    AMQP_CHANNEL_FLOW_OK_METHOD:
      Exit('AMQP_CHANNEL_FLOW_OK_METHOD');
    AMQP_CHANNEL_CLOSE_METHOD:
      Exit('AMQP_CHANNEL_CLOSE_METHOD');
    AMQP_CHANNEL_CLOSE_OK_METHOD:
      Exit('AMQP_CHANNEL_CLOSE_OK_METHOD');
    AMQP_ACCESS_REQUEST_METHOD:
      Exit('AMQP_ACCESS_REQUEST_METHOD');
    AMQP_ACCESS_REQUEST_OK_METHOD:
      Exit('AMQP_ACCESS_REQUEST_OK_METHOD');
    AMQP_EXCHANGE_DECLARE_METHOD:
      Exit('AMQP_EXCHANGE_DECLARE_METHOD');
    AMQP_EXCHANGE_DECLARE_OK_METHOD:
      Exit('AMQP_EXCHANGE_DECLARE_OK_METHOD');
    AMQP_EXCHANGE_DELETE_METHOD:
      Exit('AMQP_EXCHANGE_DELETE_METHOD');
    AMQP_EXCHANGE_DELETE_OK_METHOD:
      Exit('AMQP_EXCHANGE_DELETE_OK_METHOD');
    AMQP_EXCHANGE_BIND_METHOD:
      Exit('AMQP_EXCHANGE_BIND_METHOD');
    AMQP_EXCHANGE_BIND_OK_METHOD:
      Exit('AMQP_EXCHANGE_BIND_OK_METHOD');
    AMQP_EXCHANGE_UNBIND_METHOD:
      Exit('AMQP_EXCHANGE_UNBIND_METHOD');
    AMQP_EXCHANGE_UNBIND_OK_METHOD:
      Exit('AMQP_EXCHANGE_UNBIND_OK_METHOD');
    AMQP_QUEUE_DECLARE_METHOD:
      Exit('AMQP_QUEUE_DECLARE_METHOD');
    AMQP_QUEUE_DECLARE_OK_METHOD:
      Exit('AMQP_QUEUE_DECLARE_OK_METHOD');
    AMQP_QUEUE_BIND_METHOD:
      Exit('AMQP_QUEUE_BIND_METHOD');
    AMQP_QUEUE_BIND_OK_METHOD:
      Exit('AMQP_QUEUE_BIND_OK_METHOD');
    AMQP_QUEUE_PURGE_METHOD:
      Exit('AMQP_QUEUE_PURGE_METHOD');
    AMQP_QUEUE_PURGE_OK_METHOD:
      Exit('AMQP_QUEUE_PURGE_OK_METHOD');
    AMQP_QUEUE_DELETE_METHOD:
      Exit('AMQP_QUEUE_DELETE_METHOD');
    AMQP_QUEUE_DELETE_OK_METHOD:
      Exit('AMQP_QUEUE_DELETE_OK_METHOD');
    AMQP_QUEUE_UNBIND_METHOD:
      Exit('AMQP_QUEUE_UNBIND_METHOD');
    AMQP_QUEUE_UNBIND_OK_METHOD:
      Exit('AMQP_QUEUE_UNBIND_OK_METHOD');
    AMQP_BASIC_QOS_METHOD:
      Exit('AMQP_BASIC_QOS_METHOD');
    AMQP_BASIC_QOS_OK_METHOD:
      Exit('AMQP_BASIC_QOS_OK_METHOD');
    AMQP_BASIC_CONSUME_METHOD:
      Exit('AMQP_BASIC_CONSUME_METHOD');
    AMQP_BASIC_CONSUME_OK_METHOD:
      Exit('AMQP_BASIC_CONSUME_OK_METHOD');
    AMQP_BASIC_CANCEL_METHOD:
      Exit('AMQP_BASIC_CANCEL_METHOD');
    AMQP_BASIC_CANCEL_OK_METHOD:
      Exit('AMQP_BASIC_CANCEL_OK_METHOD');
    AMQP_BASIC_PUBLISH_METHOD:
      Exit('AMQP_BASIC_PUBLISH_METHOD');
    AMQP_BASIC_RETURN_METHOD:
      Exit('AMQP_BASIC_RETURN_METHOD');
    AMQP_BASIC_DELIVER_METHOD:
      Exit('AMQP_BASIC_DELIVER_METHOD');
    AMQP_BASIC_GET_METHOD:
      Exit('AMQP_BASIC_GET_METHOD');
    AMQP_BASIC_GET_OK_METHOD:
      Exit('AMQP_BASIC_GET_OK_METHOD');
    AMQP_BASIC_GET_EMPTY_METHOD:
      Exit('AMQP_BASIC_GET_EMPTY_METHOD');
    AMQP_BASIC_ACK_METHOD:
      Exit('AMQP_BASIC_ACK_METHOD');
    AMQP_BASIC_REJECT_METHOD:
      Exit('AMQP_BASIC_REJECT_METHOD');
    AMQP_BASIC_RECOVER_ASYNC_METHOD:
      Exit('AMQP_BASIC_RECOVER_ASYNC_METHOD');
    AMQP_BASIC_RECOVER_METHOD:
      Exit('AMQP_BASIC_RECOVER_METHOD');
    AMQP_BASIC_RECOVER_OK_METHOD:
      Exit('AMQP_BASIC_RECOVER_OK_METHOD');
    AMQP_BASIC_NACK_METHOD:
      Exit('AMQP_BASIC_NACK_METHOD');
    AMQP_TX_SELECT_METHOD:
      Exit('AMQP_TX_SELECT_METHOD');
    AMQP_TX_SELECT_OK_METHOD:
      Exit('AMQP_TX_SELECT_OK_METHOD');
    AMQP_TX_COMMIT_METHOD:
      Exit('AMQP_TX_COMMIT_METHOD');
    AMQP_TX_COMMIT_OK_METHOD:
      Exit('AMQP_TX_COMMIT_OK_METHOD');
    AMQP_TX_ROLLBACK_METHOD:
      Exit('AMQP_TX_ROLLBACK_METHOD');
    AMQP_TX_ROLLBACK_OK_METHOD:
      Exit('AMQP_TX_ROLLBACK_OK_METHOD');
    AMQP_CONFIRM_SELECT_METHOD:
      Exit('AMQP_CONFIRM_SELECT_METHOD');
    AMQP_CONFIRM_SELECT_OK_METHOD:
      Exit('AMQP_CONFIRM_SELECT_OK_METHOD');
    else
      Exit(nil);
  end;
end;



function amqp_queue_declare( state : Pamqp_connection_state;
                             channel : amqp_channel_t; queue : Tamqp_bytes;
                             passive, durable, exclusive, auto_delete : amqp_boolean_t;
                             arguments : Tamqp_table): Pamqp_queue_declare_ok;
var
  req : Tamqp_queue_declare;
begin
  req.ticket := 0;
  req.queue := queue;
  req.passive := passive;
  req.durable := durable;
  req.exclusive := exclusive;
  req.auto_delete := auto_delete;
  req.nowait := 0;
  req.arguments := arguments;
  Result := amqp_simple_rpc_decoded(state, channel, AMQP_QUEUE_DECLARE_METHOD,
                                    AMQP_QUEUE_DECLARE_OK_METHOD, @req);
end;

(**
 * amqp_queue_unbind
 *
 * @param [in] state connection state
 * @param [in] channel the channel to do the RPC on
 * @param [in] queue queue
 * @param [in] exchange exchange
 * @param [in] routing_key routing_key
 * @param [in] arguments arguments
 * @returns amqp_queue_unbind_ok_t
 *)
function amqp_queue_unbind( state : Pamqp_connection_state;
                            channel : amqp_channel_t;
                            queue, exchange, routing_key : Tamqp_bytes;
                            arguments : Tamqp_table): Pamqp_queue_unbind_ok;
var
  req : Tamqp_queue_unbind;
begin
  req.ticket := 0;
  req.queue := queue;
  req.exchange := exchange;
  req.routing_key := routing_key;
  req.arguments := arguments;
  Result := amqp_simple_rpc_decoded(state, channel, AMQP_QUEUE_UNBIND_METHOD,
                                 AMQP_QUEUE_UNBIND_OK_METHOD, @req);
end;

(**
 * amqp_exchange_declare
 *
 * @param [in] state connection state
 * @param [in] channel the channel to do the RPC on
 * @param [in] exchange exchange
 * @param [in] type type
 * @param [in] passive passive
 * @param [in] durable durable
 * @param [in] auto_delete auto_delete
 * @param [in] internal internal
 * @param [in] arguments arguments
 * @returns amqp_exchange_declare_ok_t
 *)
function amqp_exchange_declare( Astate : Pamqp_connection_state;
                                Achannel : amqp_channel_t;
                                Aexchange, Atype : Tamqp_bytes;
                                Apassive, Adurable, Aauto_delete, Ainternal : amqp_boolean_t;
                                Aarguments : Tamqp_table):Pamqp_exchange_declare_ok;
var
  req : Tamqp_exchange_declare;
begin
  req.ticket := 0;
  req.exchange := Aexchange;
  req.&type := Atype;
  req.passive := Apassive;
  req.durable := Adurable;
  req.auto_delete := Aauto_delete;
  req.internal := Ainternal;
  req.nowait := 0;
  req.arguments := Aarguments;
  Result := amqp_simple_rpc_decoded(Astate, Achannel, AMQP_EXCHANGE_DECLARE_METHOD,
                                 AMQP_EXCHANGE_DECLARE_OK_METHOD, @req);
end;

(**
 * amqp_queue_bind
 *
 * @param [in] state connection state
 * @param [in] channel the channel to do the RPC on
 * @param [in] queue queue
 * @param [in] exchange exchange
 * @param [in] routing_key routing_key
 * @param [in] arguments arguments
 * @returns amqp_queue_bind_ok_t
 *)
function amqp_queue_bind( state : Pamqp_connection_state;
                          channel : amqp_channel_t; queue, exchange,
                          routing_key : Tamqp_bytes;
                          arguments : Tamqp_table): Pamqp_queue_bind_ok;
var
  req : Tamqp_queue_bind;
begin
  req.ticket := 0;
  req.queue := queue;
  req.exchange := exchange;
  req.routing_key := routing_key;
  req.nowait := 0;
  req.arguments := arguments;
  Result := amqp_simple_rpc_decoded(state, channel, AMQP_QUEUE_BIND_METHOD,
                                    AMQP_QUEUE_BIND_OK_METHOD, @req);
end;

function amqp_channel_open( state : Pamqp_connection_state; channel : amqp_channel_t):Pamqp_channel_open_ok;
var
  req : Tamqp_channel_open;
begin
  req.out_of_band := amqp_empty_bytes;
  Result := amqp_simple_rpc_decoded(state, channel, AMQP_CHANNEL_OPEN_METHOD,
                                 AMQP_CHANNEL_OPEN_OK_METHOD, @req);
end;

function amqp_decode_properties(class_id : uint16; pool : Pamqp_pool;
                                encoded : Tamqp_bytes; decoded: PPointer):integer;
var
    offset         : size_t;
    flags          : amqp_flags_t;
    flagword_index : integer;
    partial_flags  : uint16;
    connection_p   : Pamqp_connection_properties;
    channel_p      : Pamqp_channel_properties;
    access_p       : Pamqp_access_properties;
    exchange_p     : Pamqp_exchange_properties;
    queue_p        : Pamqp_queue_properties;
    basic_p        : Pamqp_basic_properties;
    tx_p           : Pamqp_tx_properties ;
    confirm_p      : Pamqp_confirm_properties;
    res            : integer;
    len: uint8_t;

begin
  offset := 0;
  flags := 0;
  flagword_index := 0;
  while (partial_flags and 1) > 0 do
  begin
    if  0= amqp_decode_16(encoded, @offset, &partial_flags  ) then
      Exit(Int(AMQP_STATUS_BAD_AMQP_DATA));
    flags  := flags  or ((partial_flags  shl  (flagword_index * 16)));
    Inc(flagword_index);
  end;

  case class_id of
    10:
    begin
      connection_p :=  Pamqp_connection_properties(pool.alloc( sizeof(Tamqp_connection_properties)));
      if connection_p = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      connection_p._flags := flags;
      decoded^ := connection_p;
      Exit(0);
    end;
    20:
    begin
      channel_p := Pamqp_channel_properties(pool.alloc( sizeof(Tamqp_channel_properties)));
      if channel_p = nil then
        Exit(int(AMQP_STATUS_NO_MEMORY));

      channel_p._flags := flags;
      decoded^ := channel_p;
      Exit(0);
    end;
    30:
    begin
      access_p := Pamqp_access_properties(pool.alloc( sizeof(Tamqp_access_properties)));
      if access_p = nil then
        Exit(int(AMQP_STATUS_NO_MEMORY));

      access_p._flags := flags;
      decoded^ := access_p;
      Exit(0);
    end;
    40:
    begin
      exchange_p := Pamqp_exchange_properties(pool.alloc(sizeof(Tamqp_exchange_properties)));
      if exchange_p = nil then
        Exit(int(AMQP_STATUS_NO_MEMORY));

      exchange_p._flags := flags;
      decoded^ := exchange_p;
      Exit(0);
    end;
    50:
    begin
      queue_p := Pamqp_queue_properties(pool.alloc(sizeof(Tamqp_queue_properties)));
      if queue_p = nil then
        Exit(int(AMQP_STATUS_NO_MEMORY));

      queue_p._flags := flags;
      decoded^ := queue_p;
      Exit(0);
    end;
    60:
    begin
      basic_p := Pamqp_basic_properties(pool.alloc( sizeof(Tamqp_basic_properties)));
      if basic_p = nil then
        Exit(int(AMQP_STATUS_NO_MEMORY));

      basic_p._flags := flags;
      if (flags and AMQP_BASIC_CONTENT_TYPE_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))    or
               (0= amqp_decode_bytes(encoded, @offset, basic_p.content_type, len)) then
            Exit(Int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      if (flags and AMQP_BASIC_CONTENT_ENCODING_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))   or
               (0= amqp_decode_bytes(encoded, @offset, basic_p.content_encoding, len)) then
            Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      if (flags and AMQP_BASIC_HEADERS_FLAG)>0 then
      begin
        begin
          res := amqp_decode_table(encoded, pool, basic_p.headers, @offset);
          if res < 0 then Exit(res);
        end;
      end;
      if (flags and AMQP_BASIC_DELIVERY_MODE_FLAG)>0 then
      begin
        if  (0= amqp_decode_8(encoded, @offset, basic_p.delivery_mode)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_PRIORITY_FLAG)>0 then
      begin
        if  (0= amqp_decode_8(encoded, @offset, basic_p.priority)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_CORRELATION_ID_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))   or
               (0= amqp_decode_bytes(encoded, @offset, basic_p.correlation_id, len)) then
            Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      if (flags and AMQP_BASIC_REPLY_TO_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))   or
               (0= amqp_decode_bytes(encoded, @offset, basic_p.reply_to, len))  then
            Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      if (flags and AMQP_BASIC_EXPIRATION_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))    or
               (0= amqp_decode_bytes(encoded, @offset, basic_p.expiration, len))then
            Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      if (flags and AMQP_BASIC_MESSAGE_ID_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))    or
               (0= amqp_decode_bytes(encoded, @offset, basic_p.message_id, len)) then
            Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      if (flags and AMQP_BASIC_TIMESTAMP_FLAG)>0 then
      begin
        if  0= amqp_decode_64(encoded, @offset, basic_p.timestamp) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_TYPE_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))  or
              (0= amqp_decode_bytes(encoded, @offset, basic_p.&type, len))  then
            Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      if (flags and AMQP_BASIC_USER_ID_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))   or
               (0= amqp_decode_bytes(encoded, @offset, basic_p.user_id, len)) then
            Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      if (flags and AMQP_BASIC_APP_ID_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))   or
               (0= amqp_decode_bytes(encoded, @offset, basic_p.app_id, len)) then
            Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      if (flags and AMQP_BASIC_CLUSTER_ID_FLAG)>0 then
      begin
        begin
          //var len: uint8_t;
          if  (0= amqp_decode_8(encoded, @offset, &len))   or
               (0= amqp_decode_bytes(encoded, @offset, basic_p.cluster_id, len)) then
            Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
        end;
      end;
      decoded^ := basic_p;
      Exit(0);
    end;
    90:
    begin
      tx_p := Pamqp_tx_properties(pool.alloc( sizeof(Tamqp_tx_properties)));
      if tx_p = nil then
        Exit(int(AMQP_STATUS_NO_MEMORY));

      tx_p._flags := flags;
      decoded^ := tx_p;
      Exit(0);
    end;
    85:
    begin
      confirm_p := Pamqp_confirm_properties(pool.alloc(sizeof(Tamqp_confirm_properties)));
      if confirm_p = nil then
        Exit(int(AMQP_STATUS_NO_MEMORY));

      confirm_p._flags := flags;
      decoded^ := confirm_p;
      Exit(0);
    end;
    else
      Exit(Int(AMQP_STATUS_UNKNOWN_CLASS));
  end;
end;


function ReturnVal(bits: Byte;IsTrue, IsFalse: Int): Integer;
begin
  if bits > 0 then
     Exit(IsTrue)
  else
     Exit(IsFalse);
end;

function amqp_decode_method(methodNumber : amqp_method_number_t;pool : Pamqp_pool; encoded : Tamqp_bytes; out decoded: Pointer):integer;
var
    offset     : size_t;
    bit_buffer : byte;
    res        : integer;
    len: uint32;
    len8: uint8;
    START : Pamqp_connection_start;
    START_OK : Pamqp_connection_start_ok;
    SECURE : Pamqp_connection_secure;
    SECURE_OK : Pamqp_connection_secure_ok;
    TUNE : Pamqp_connection_tune;
    TUNE_OK : Pamqp_connection_tune_ok;
    OPEN : Pamqp_connection_open;
    OPEN_OK : Pamqp_connection_open_ok;
    CLOSE : Pamqp_connection_close;
    CLOSE_OK : Pamqp_connection_close_ok;
    BLOCKED : Pamqp_connection_blocked;
    UNBLOCKED : Pamqp_connection_unblocked;
    UPDATE_SECRET : Pamqp_connection_update_secret;
    UPDATE_SECRET_OK : Pamqp_connection_update_secret_ok;
    CHANNEL_OPEN : Pamqp_channel_open;
    CHANNEL_OPEN_OK : Pamqp_channel_open_ok;
    CHANNEL_FLOW : Pamqp_channel_flow;
    CHANNEL_FLOW_OK : Pamqp_channel_flow_ok;
    CHANNEL_CLOSE : Pamqp_channel_close;
    CHANNEL_CLOSE_OK : Pamqp_channel_close_ok;

    REQUEST : Pamqp_access_request;
    REQUEST_OK : Pamqp_access_request_ok;
    EXCHANGE_DECLARE : Pamqp_exchange_declare;
    EXCHANGE_DECLARE_OK : Pamqp_exchange_declare_ok;
    EXCHANGE_DELETE : Pamqp_exchange_delete;
    EXCHANGE_BIND_OK  : Pamqp_exchange_bind_ok;
    EXCHANGE_UNBIND : Pamqp_exchange_unbind;
    EXCHANGE_DELETE_OK : Pamqp_exchange_delete_ok;
    EXCHANGE_BIND : Pamqp_exchange_bind;
    EXCHANGE_UNBIND_OK : Pamqp_exchange_unbind_ok;
    QUEUE_DECLARE:Pamqp_queue_declare;
    QUEUE_DECLARE_OK :Pamqp_queue_declare_ok;
    QUEUE_BIND :Pamqp_queue_bind;
    QUEUE_BIND_OK :Pamqp_queue_bind_ok;
    QUEUE_PURGE :Pamqp_queue_purge;
    QUEUE_PURGE_OK:Pamqp_queue_purge_ok;
    QUEUE_DELETE :Pamqp_queue_delete;
    QUEUE_DELETE_OK :Pamqp_queue_delete_ok;
    QUEUE_UNBIND :Pamqp_queue_unbind;
    QUEUE_UNBIND_OK :Pamqp_queue_unbind_ok;
    BASIC_QOS : Pamqp_basic_qos;
    BASIC_QOS_OK :Pamqp_basic_qos_ok;
    BASIC_CONSUME : Pamqp_basic_consume;
    BASIC_CONSUME_OK :Pamqp_basic_consume_ok;
    BASIC_CANCEL :Pamqp_basic_cancel;
    BASIC_CANCEL_OK :Pamqp_basic_cancel_ok;
    BASIC_PUBLISH : Pamqp_basic_publish;
    BASIC_RETURN :Pamqp_basic_return;
    BASIC_DELIVER :Pamqp_basic_deliver;
    BASIC_GET : Pamqp_basic_get;
    BASIC_GET_OK :Pamqp_basic_get_ok;
    BASIC_GET_EMPTY : Pamqp_basic_get_empty;
    BASIC_ACK :Pamqp_basic_ack;
    BASIC_REJECT : Pamqp_basic_reject;
    BASIC_RECOVER_ASYNC :Pamqp_basic_recover_async;
    BASIC_RECOVER : Pamqp_basic_recover;
    BASIC_RECOVER_OK : Pamqp_basic_recover_ok;
    BASIC_NACK:Pamqp_basic_nack;
    TX_SELECT :Pamqp_tx_select;
    TX_SELECT_OK : Pamqp_tx_select_ok;
    TX_COMMIT :Pamqp_tx_commit;
    TX_COMMIT_OK : Pamqp_tx_commit_ok;
    TX_ROLLBACK : Pamqp_tx_rollback;
    TX_ROLLBACK_OK : Pamqp_tx_rollback_ok;
    CONFIRM_SELECT : Pamqp_confirm_select;
    CONFIRM_SELECT_OK : Pamqp_confirm_select_ok;

begin
  offset := 0;
  case methodNumber of
    AMQP_CONNECTION_START_METHOD:
    begin
      START := Pamqp_connection_start(pool.alloc( sizeof(Tamqp_connection_start)));
      if START = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      if  0= amqp_decode_8(encoded, @offset, START.version_major ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_decode_8(encoded, @offset, START.version_minor ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        res := amqp_decode_table(encoded, pool, START.server_properties, @offset);
        if res < 0 then Exit(res);
      end;

      begin
        //var len: uint32;
        if  (0= amqp_decode_32(encoded, @offset, len)) or
            (0= amqp_decode_bytes(encoded, @offset, START.mechanisms, len))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;

      begin
        //var len: uint32;
        if  (0= amqp_decode_32(encoded, @offset, len))  or
            (0= amqp_decode_bytes(encoded, @offset, START.locales, len)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := START;
      Exit(0);
    end;

    AMQP_CONNECTION_START_OK_METHOD:
    begin
      START_OK := Pamqp_connection_start_ok(pool.alloc( sizeof(Tamqp_connection_start_ok)));
      if START_OK = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      begin
        res := amqp_decode_table(encoded, pool, START_OK.client_properties, @offset);
        if res < 0 then Exit(res);
      end;
      begin
        //var len8: uint8;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
            (0=amqp_decode_bytes(encoded, @offset, START_OK.mechanism, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint32;
        if  (0= amqp_decode_32(encoded, @offset, len))   or
            (0= amqp_decode_bytes(encoded, @offset, START_OK.response, len)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
            (0= amqp_decode_bytes(encoded, @offset, START_OK.locale, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := START_OK;
      Exit(0);
    end;

    AMQP_CONNECTION_SECURE_METHOD:
    begin
      SECURE := Pamqp_connection_secure(pool.alloc( sizeof(Tamqp_connection_secure)));
      if SECURE = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      begin
        //var len: uint32;
        if  (0= amqp_decode_32(encoded, @offset, len))  or
            (0= amqp_decode_bytes(encoded, @offset, SECURE.challenge, len)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := SECURE;
      Exit(0);
    end;

    AMQP_CONNECTION_SECURE_OK_METHOD:
    begin
      SECURE_OK := Pamqp_connection_secure_ok(pool.alloc( sizeof(Tamqp_connection_secure_ok)));
      if SECURE_OK = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      begin
        //var len: uint32;
        if  (0= amqp_decode_32(encoded, @offset, len))   or
            (0= amqp_decode_bytes(encoded, @offset, SECURE_OK.response, len)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := SECURE_OK;
      Exit(0);
    end;

    AMQP_CONNECTION_TUNE_METHOD:
    begin
      TUNE := Pamqp_connection_tune(pool.alloc( sizeof(Tamqp_connection_tune)));
      if  TUNE= nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      if  (0= amqp_decode_16(encoded, @offset, TUNE.channel_max )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0= amqp_decode_32(encoded, @offset, TUNE.frame_max )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0= amqp_decode_16(encoded, @offset, TUNE.heartbeat )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      decoded := TUNE;
      Exit(0);
    end;

    AMQP_CONNECTION_TUNE_OK_METHOD:
    begin
      TUNE_OK := Pamqp_connection_tune_ok(pool.alloc( sizeof(Tamqp_connection_tune_ok)));
      if TUNE_OK = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      if  (0= amqp_decode_16(encoded, @offset, TUNE_OK.channel_max)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0= amqp_decode_32(encoded, @offset, TUNE_OK.frame_max )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0= amqp_decode_16(encoded, @offset, TUNE_OK.heartbeat ))   then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      decoded := TUNE_OK;
      Exit(0);
    end;

    AMQP_CONNECTION_OPEN_METHOD:
    begin
      OPEN := Pamqp_connection_open(pool.alloc( sizeof(Tamqp_connection_open)));
      if OPEN = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      begin
        //var len: uint8;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
            (0= amqp_decode_bytes(encoded, @offset, OPEN.virtual_host, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, OPEN.capabilities, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  (0= amqp_decode_8(encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (bit_buffer and (1  shl  0)) > 0 then
         OPEN.insist :=  1
      else
         OPEN.insist := 0;
      decoded := OPEN;
      Exit(0);
    end;

    AMQP_CONNECTION_OPEN_OK_METHOD:
    begin
      OPEN_OK := Pamqp_connection_open_ok(pool.alloc( sizeof(Tamqp_connection_open_ok)));
      if OPEN_OK = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      begin
        //var len: uint8;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
            (0= amqp_decode_bytes(encoded, @offset, OPEN_OK.known_hosts, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := OPEN_OK;
      Exit(0);
    end;

    AMQP_CONNECTION_CLOSE_METHOD:
    begin
      CLOSE := Pamqp_connection_close(pool.alloc( sizeof(Tamqp_connection_close)));
      if CLOSE = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      if  (0= amqp_decode_16(encoded, @offset, CLOSE.reply_code )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
            (0= amqp_decode_bytes(encoded, @offset, CLOSE.reply_text, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  (0= amqp_decode_16(encoded, @offset, CLOSE.class_id )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0= amqp_decode_16(encoded, @offset, CLOSE.method_id ) ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      decoded := CLOSE;
      Exit(0);
    end;

    AMQP_CONNECTION_CLOSE_OK_METHOD:
    begin
      CLOSE_OK := Pamqp_connection_close_ok(pool.alloc( sizeof(Tamqp_connection_close_ok)));
      if CLOSE_OK = nil then begin
        Exit(Int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := CLOSE_OK;
      Exit(0);
    end;

    AMQP_CONNECTION_BLOCKED_METHOD:
    begin
      BLOCKED := Pamqp_connection_blocked(pool.alloc( sizeof(Tamqp_connection_blocked)));
      if BLOCKED = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      begin
        //var len: uint8;
        if  (0= amqp_decode_8(encoded, @offset, len8 ))  or
             (0= amqp_decode_bytes(encoded, @offset, BLOCKED.reason, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := BLOCKED;
      Exit(0);
    end;

    AMQP_CONNECTION_UNBLOCKED_METHOD:
    begin
      UNBLOCKED := Pamqp_connection_unblocked(pool.alloc( sizeof(Tamqp_connection_unblocked)));
      if UNBLOCKED = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      decoded := UNBLOCKED;
      Exit(0);
    end;

    AMQP_CONNECTION_UPDATE_SECRET_METHOD:
    begin
      UPDATE_SECRET := Pamqp_connection_update_secret(pool.alloc( sizeof(Tamqp_connection_update_secret)));
      if UPDATE_SECRET = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      begin
        //var len: uint32;
        if  (0= amqp_decode_32(encoded, @offset, len))   or
             (0= amqp_decode_bytes(encoded, @offset, UPDATE_SECRET.new_secret, len))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8;
        if  (0= amqp_decode_8(encoded, @offset, len8 ))  or
             (0= amqp_decode_bytes(encoded, @offset, UPDATE_SECRET.reason, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := UPDATE_SECRET;
      Exit(0);
    end;

    AMQP_CONNECTION_UPDATE_SECRET_OK_METHOD:
    begin
      UPDATE_SECRET_OK := Pamqp_connection_update_secret_ok(pool.alloc(  sizeof(Tamqp_connection_update_secret_ok)));
      if UPDATE_SECRET_OK = nil then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      decoded := UPDATE_SECRET_OK;
      Exit(0);
    end;

    AMQP_CHANNEL_OPEN_METHOD:
    begin
      CHANNEL_OPEN := Pamqp_channel_open(pool.alloc(  sizeof(Tamqp_channel_open)));
      if CHANNEL_OPEN = nil then begin
        Exit(Int(AMQP_STATUS_NO_MEMORY));
      end;
      begin
        //var len: uint8;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, CHANNEL_OPEN.out_of_band, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := CHANNEL_OPEN;
      Exit(0);
    end;

    AMQP_CHANNEL_OPEN_OK_METHOD:
    begin
      CHANNEL_OPEN_OK := Pamqp_channel_open_ok(pool.alloc(  sizeof(Tamqp_channel_open_ok)));
      if CHANNEL_OPEN_OK = nil then begin
        Exit(Int(AMQP_STATUS_NO_MEMORY));
      end;
      begin
        //var len: uint32;
        if  (0= amqp_decode_32(encoded, @offset, len))  or
             (0= amqp_decode_bytes(encoded, @offset, CHANNEL_OPEN_OK.channel_id, len))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := CHANNEL_OPEN_OK;
      Exit(0);
    end;

    AMQP_CHANNEL_FLOW_METHOD:
    begin
      CHANNEL_FLOW := Pamqp_channel_flow(pool.alloc(  sizeof(Tamqp_channel_flow)));
      if CHANNEL_FLOW = nil then begin
        Exit(Int(AMQP_STATUS_NO_MEMORY));
      end;
      if  (0= amqp_decode_8(encoded, @offset, bit_buffer))  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (bit_buffer and (1  shl  0)) > 0 then
          CHANNEL_FLOW.active := 1
      else CHANNEL_FLOW.active := 0;
      decoded := CHANNEL_FLOW;
      Exit(0);
    end;

    AMQP_CHANNEL_FLOW_OK_METHOD:
    begin
      CHANNEL_FLOW_OK := Pamqp_channel_flow_ok(pool.alloc(  sizeof(Tamqp_channel_flow_ok)));
      if CHANNEL_FLOW_OK = nil then begin
        Exit(Int(AMQP_STATUS_NO_MEMORY));
      end;
      if  (0= amqp_decode_8(encoded, @offset, bit_buffer))   then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (bit_buffer and (1  shl  0))>0  then
          CHANNEL_FLOW_OK.active := 1
       else CHANNEL_FLOW_OK.active := 0;
      decoded := CHANNEL_FLOW_OK;
      Exit(0);
    end;

    AMQP_CHANNEL_CLOSE_METHOD:
    begin
      CHANNEL_CLOSE := Pamqp_channel_close(pool.alloc(  sizeof(Tamqp_channel_close)));
      if CHANNEL_CLOSE = nil then begin
        Exit(Int(AMQP_STATUS_NO_MEMORY));
      end;
      if  (0= amqp_decode_16(encoded, @offset, CHANNEL_CLOSE.reply_code )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, CHANNEL_CLOSE.reply_text, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  (0= amqp_decode_16(encoded, @offset, CHANNEL_CLOSE.class_id )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0= amqp_decode_16(encoded, @offset, CHANNEL_CLOSE.method_id ))  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      decoded := CHANNEL_CLOSE;
      Exit(0);
    end;

    AMQP_CHANNEL_CLOSE_OK_METHOD:
    begin
      CHANNEL_CLOSE_OK := Pamqp_channel_close_ok(pool.alloc(  sizeof(Tamqp_channel_close_ok)));
      if CHANNEL_CLOSE_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := CHANNEL_CLOSE_OK;
      Exit(0);
    end;

    AMQP_ACCESS_REQUEST_METHOD:
    begin
      REQUEST := Pamqp_access_request(pool.alloc(  sizeof(Tamqp_access_request)));
      if REQUEST = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, REQUEST.realm, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  (0= amqp_decode_8(encoded, @offset, &bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      REQUEST.exclusive := ReturnVal((bit_buffer and (1  shl  0)) , 1 , 0);
      REQUEST.passive := ReturnVal((bit_buffer and (1  shl  1)) , 1 , 0);
      REQUEST.active := ReturnVal((bit_buffer and (1  shl  2)) , 1 , 0);
      REQUEST.write := ReturnVal((bit_buffer and (1  shl  3)) , 1 , 0);
      REQUEST.read := ReturnVal((bit_buffer and (1  shl  4)) , 1 , 0);
      decoded := REQUEST;
      Exit(0);
    end;

    AMQP_ACCESS_REQUEST_OK_METHOD:
    begin
      REQUEST_OK := Pamqp_access_request_ok(pool.alloc( sizeof(Tamqp_access_request_ok)));
      if REQUEST_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  (0= amqp_decode_16(encoded, @offset, REQUEST_OK.ticket )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      decoded := REQUEST_OK;
      Exit(0);
    end;

    AMQP_EXCHANGE_DECLARE_METHOD:
    begin
      EXCHANGE_DECLARE := Pamqp_exchange_declare(pool.alloc(  sizeof(Tamqp_exchange_declare)));
      if EXCHANGE_DECLARE = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  (0= amqp_decode_16(encoded, @offset, EXCHANGE_DECLARE.ticket) )  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, EXCHANGE_DECLARE.exchange, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
             (0= amqp_decode_bytes(encoded, @offset, EXCHANGE_DECLARE.&type, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  (0= amqp_decode_8(encoded, @offset, bit_buffer))  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      EXCHANGE_DECLARE.passive := ReturnVal((bit_buffer and (1  shl  0)) , 1 ,0);
      EXCHANGE_DECLARE.durable := ReturnVal((bit_buffer and (1  shl  1)) , 1 , 0);
      EXCHANGE_DECLARE.auto_delete := ReturnVal((bit_buffer and (1  shl  2)) , 1 , 0);
      EXCHANGE_DECLARE.internal := ReturnVal((bit_buffer and (1  shl  3)), 1 , 0);
      EXCHANGE_DECLARE.nowait := ReturnVal((bit_buffer and (1  shl  4)) , 1 , 0);
      begin
        res := amqp_decode_table(encoded, pool, EXCHANGE_DECLARE.arguments, @offset);
        if res < 0 then Exit(res);
      end;
      decoded := EXCHANGE_DECLARE;
      Exit(0);
    end;

    AMQP_EXCHANGE_DECLARE_OK_METHOD:
    begin
      EXCHANGE_DECLARE_OK := Pamqp_exchange_declare_ok(pool.alloc(  sizeof(Tamqp_exchange_declare_ok)));
      if EXCHANGE_DECLARE_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := EXCHANGE_DECLARE_OK;
      Exit(0);
    end;

    AMQP_EXCHANGE_DELETE_METHOD:
    begin
      EXCHANGE_DELETE := Pamqp_exchange_delete(pool.alloc(  sizeof(Tamqp_exchange_delete)));
      if EXCHANGE_DELETE = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, EXCHANGE_DELETE.ticket) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
             (0= amqp_decode_bytes(encoded, @offset, EXCHANGE_DELETE.exchange, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, bit_buffer) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      EXCHANGE_DELETE.if_unused := ReturnVal((bit_buffer and (1  shl  0)) , 1 , 0);
      EXCHANGE_DELETE.nowait := ReturnVal((bit_buffer and (1  shl  1)) , 1 , 0);
      decoded := EXCHANGE_DELETE;
      Exit(0);
    end;

    AMQP_EXCHANGE_DELETE_OK_METHOD:
    begin
      EXCHANGE_DELETE_OK := Pamqp_exchange_delete_ok(pool.alloc(  sizeof(Tamqp_exchange_delete_ok)));
      if EXCHANGE_DELETE_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := EXCHANGE_DELETE_OK;
      Exit(0);
    end;

    AMQP_EXCHANGE_BIND_METHOD:
    begin
      EXCHANGE_BIND := Pamqp_exchange_bind(pool.alloc(  sizeof(Tamqp_exchange_bind)));
      if EXCHANGE_BIND = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  (0= amqp_decode_16(encoded, @offset, EXCHANGE_BIND.ticket )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //r len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
            (0= amqp_decode_bytes(encoded, @offset, EXCHANGE_BIND.destination, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //r len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
             (0= amqp_decode_bytes(encoded, @offset, EXCHANGE_BIND.source, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //r len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, EXCHANGE_BIND.routing_key, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, bit_buffer)  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      EXCHANGE_BIND.nowait := ReturnVal((bit_buffer and (1  shl  0)) , 1 , 0);
      begin
        res := amqp_decode_table(encoded, pool, EXCHANGE_BIND.arguments, @offset);
        if res < 0 then Exit(res);
      end;
      decoded := EXCHANGE_BIND;
      Exit(0);
    end;

    AMQP_EXCHANGE_BIND_OK_METHOD:
    begin
      EXCHANGE_BIND_OK := Pamqp_exchange_bind_ok(pool.alloc(  sizeof(Tamqp_exchange_bind_ok)));
      if EXCHANGE_BIND_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := EXCHANGE_BIND_OK;
      Exit(0);
    end;

    AMQP_EXCHANGE_UNBIND_METHOD:
    begin
      EXCHANGE_UNBIND := Pamqp_exchange_unbind(pool.alloc(  sizeof(Tamqp_exchange_unbind)));
      if EXCHANGE_UNBIND = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  (0= amqp_decode_16(encoded, @offset, EXCHANGE_UNBIND.ticket ))  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, EXCHANGE_UNBIND.destination, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
             (0= amqp_decode_bytes(encoded, @offset, EXCHANGE_UNBIND.source, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
             (0= amqp_decode_bytes(encoded, @offset, EXCHANGE_UNBIND.routing_key, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer)   then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      EXCHANGE_UNBIND.nowait := ReturnVal((bit_buffer and (1  shl  0)) , 1 , 0);
      begin
        res := amqp_decode_table(encoded, pool, EXCHANGE_UNBIND.arguments, @offset);
        if res < 0 then Exit(res);
      end;
      decoded := EXCHANGE_UNBIND;
      Exit(0);
    end;

    AMQP_EXCHANGE_UNBIND_OK_METHOD:
    begin
      EXCHANGE_UNBIND_OK := Pamqp_exchange_unbind_ok(pool.alloc(  sizeof(Tamqp_exchange_unbind_ok)));
      if EXCHANGE_UNBIND_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := EXCHANGE_UNBIND_OK;
      Exit(0);
    end;

    AMQP_QUEUE_DECLARE_METHOD:
    begin
      QUEUE_DECLARE:=Pamqp_queue_declare(pool.alloc(  sizeof(Tamqp_queue_declare)));
      if QUEUE_DECLARE = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, QUEUE_DECLARE.ticket )then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_DECLARE.queue, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      QUEUE_DECLARE.passive := ReturnVal((bit_buffer and (1  shl  0)) , 1 , 0);
      QUEUE_DECLARE.durable := ReturnVal((bit_buffer and (1  shl  1)) , 1 , 0);
      QUEUE_DECLARE.exclusive := ReturnVal((bit_buffer and (1  shl  2)) , 1 , 0);
      QUEUE_DECLARE.auto_delete := ReturnVal((bit_buffer and (1  shl  3)) , 1 , 0);
      QUEUE_DECLARE.nowait := ReturnVal((bit_buffer and (1  shl  4)) , 1, 0);
      begin
        res := amqp_decode_table(encoded, pool, QUEUE_DECLARE.arguments, @offset);
        if res < 0 then Exit(res);
      end;
      decoded := QUEUE_DECLARE;
      Exit(0);
    end;

    AMQP_QUEUE_DECLARE_OK_METHOD:
    begin
      QUEUE_DECLARE_OK :=Pamqp_queue_declare_ok(pool.alloc(  sizeof(Tamqp_queue_declare_ok)));
      if QUEUE_DECLARE_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8 )) or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_DECLARE_OK.queue, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_32(encoded, @offset, QUEUE_DECLARE_OK.message_count) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_decode_32(encoded, @offset, QUEUE_DECLARE_OK.consumer_count) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      decoded := QUEUE_DECLARE_OK;
      Exit(0);
    end;

    AMQP_QUEUE_BIND_METHOD:
    begin
      QUEUE_BIND :=Pamqp_queue_bind(pool.alloc( sizeof(Tamqp_queue_bind)));
      if QUEUE_BIND = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, QUEUE_BIND.ticket) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
       // var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_BIND.queue, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_BIND.exchange, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_BIND.routing_key, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      QUEUE_BIND.nowait := ReturnVal((bit_buffer and (1  shl  0)) , 1 , 0);
      begin
        res := amqp_decode_table(encoded, pool, QUEUE_BIND.arguments, @offset);
        if res < 0 then Exit(res);
      end;
      decoded := QUEUE_BIND;
      Exit(0);
    end;

    AMQP_QUEUE_BIND_OK_METHOD:
    begin
      QUEUE_BIND_OK :=Pamqp_queue_bind_ok(pool.alloc(  sizeof(Tamqp_queue_bind_ok)));
      if QUEUE_BIND_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := QUEUE_BIND_OK;
      Exit(0);
    end;

    AMQP_QUEUE_PURGE_METHOD:
    begin
      QUEUE_PURGE :=Pamqp_queue_purge(pool.alloc(  sizeof(Tamqp_queue_purge)));
      if QUEUE_PURGE = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, QUEUE_PURGE.ticket) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_PURGE.queue, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, bit_buffer) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      QUEUE_PURGE.nowait := ReturnVal((bit_buffer and (1  shl  0)) , 1 , 0);
      decoded := QUEUE_PURGE;
      Exit(0);
    end;

    AMQP_QUEUE_PURGE_OK_METHOD:
    begin
      QUEUE_PURGE_OK:=Pamqp_queue_purge_ok(pool.alloc(  sizeof(Tamqp_queue_purge_ok)));
      if QUEUE_PURGE_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_32(encoded, @offset, QUEUE_PURGE_OK.message_count) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      decoded := QUEUE_PURGE_OK;
      Exit(0);
    end;

    AMQP_QUEUE_DELETE_METHOD:
    begin
      QUEUE_DELETE :=Pamqp_queue_delete(pool.alloc(  sizeof(Tamqp_queue_delete)));
      if QUEUE_DELETE = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, QUEUE_DELETE.ticket)  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_DELETE.queue, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, bit_buffer )  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      QUEUE_DELETE.if_unused := ReturnVal((bit_buffer and (1  shl  0)) , 1 , 0);
      QUEUE_DELETE.if_empty := ReturnVal((bit_buffer and (1  shl  1)) , 1 , 0);
      QUEUE_DELETE.nowait := ReturnVal((bit_buffer and (1  shl  2)) , 1 , 0);
      decoded := QUEUE_DELETE;
      Exit(0);
    end;

    AMQP_QUEUE_DELETE_OK_METHOD:
    begin
      QUEUE_DELETE_OK :=Pamqp_queue_delete_ok(pool.alloc(  sizeof(Tamqp_queue_delete_ok)));
      if QUEUE_DELETE_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if 0= amqp_decode_32(encoded, @offset, QUEUE_DELETE_OK.message_count) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      decoded := QUEUE_DELETE_OK;
      Exit(0);
    end;

    AMQP_QUEUE_UNBIND_METHOD:
    begin
      QUEUE_UNBIND :=Pamqp_queue_unbind(pool.alloc(  sizeof(Tamqp_queue_unbind)));
      if QUEUE_UNBIND = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, QUEUE_UNBIND.ticket )  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_UNBIND.queue, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_UNBIND.exchange, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8 ))  or
             (0= amqp_decode_bytes(encoded, @offset, QUEUE_UNBIND.routing_key, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        res := amqp_decode_table(encoded, pool, QUEUE_UNBIND.arguments, @offset);
        if res < 0 then Exit(res);
      end;
      decoded := QUEUE_UNBIND;
      Exit(0);
    end;

    AMQP_QUEUE_UNBIND_OK_METHOD:
    begin
      QUEUE_UNBIND_OK :=Pamqp_queue_unbind_ok(pool.alloc(  sizeof(Tamqp_queue_unbind_ok)));
      if QUEUE_UNBIND_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := QUEUE_UNBIND_OK;
      Exit(0);
    end;

    AMQP_BASIC_QOS_METHOD:
    begin
      BASIC_QOS := Pamqp_basic_qos(pool.alloc( sizeof(Tamqp_basic_qos)));
      if BASIC_QOS = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_32(encoded, @offset, BASIC_QOS.prefetch_size)  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_decode_16(encoded, @offset, BASIC_QOS.prefetch_count) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_decode_8(encoded, @offset, bit_buffer)  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_QOS.global := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      decoded := BASIC_QOS;
      Exit(0);
    end;

    AMQP_BASIC_QOS_OK_METHOD:
    begin
      BASIC_QOS_OK :=Pamqp_basic_qos_ok(pool.alloc(  sizeof(Tamqp_basic_qos_ok)));
      if BASIC_QOS_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := BASIC_QOS_OK;
      Exit(0);
    end;

    AMQP_BASIC_CONSUME_METHOD:
    begin
      BASIC_CONSUME := Pamqp_basic_consume(pool.alloc(  sizeof(Tamqp_basic_consume)));
      if BASIC_CONSUME = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, BASIC_CONSUME.ticket)  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
       //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_CONSUME.queue, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_CONSUME.consumer_tag, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_CONSUME.no_local := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      BASIC_CONSUME.no_ack := ReturnVal((bit_buffer and (1  shl  1)) , 1,0);
      BASIC_CONSUME.exclusive := ReturnVal((bit_buffer and (1  shl  2)) , 1,0);
      BASIC_CONSUME.nowait := ReturnVal((bit_buffer and (1  shl  3)) , 1,0);
      begin
        res := amqp_decode_table(encoded, pool, BASIC_CONSUME.arguments, @offset);
        if res < 0 then Exit(res);
      end;
      decoded := BASIC_CONSUME;
      Exit(0);
    end;

    AMQP_BASIC_CONSUME_OK_METHOD:
    begin
      BASIC_CONSUME_OK :=Pamqp_basic_consume_ok(pool.alloc(  sizeof(Tamqp_basic_consume_ok)));
      if BASIC_CONSUME_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_CONSUME_OK.consumer_tag, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := BASIC_CONSUME_OK;
      Exit(0);
    end;

    AMQP_BASIC_CANCEL_METHOD:
    begin
      BASIC_CANCEL :=Pamqp_basic_cancel(pool.alloc(  sizeof(Tamqp_basic_cancel)));
      if BASIC_CANCEL = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_CANCEL.consumer_tag, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, bit_buffer) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_CANCEL.nowait := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      decoded := BASIC_CANCEL;
      Exit(0);
    end;

    AMQP_BASIC_CANCEL_OK_METHOD:
    begin
      BASIC_CANCEL_OK :=Pamqp_basic_cancel_ok(pool.alloc(  sizeof(Tamqp_basic_cancel_ok)));
      if BASIC_CANCEL_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_CANCEL_OK.consumer_tag, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := BASIC_CANCEL_OK;
      Exit(0);
    end;

    AMQP_BASIC_PUBLISH_METHOD:
    begin
      BASIC_PUBLISH := Pamqp_basic_publish(pool.alloc(  sizeof(Tamqp_basic_publish)));
      if BASIC_PUBLISH = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, BASIC_PUBLISH.ticket)  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_PUBLISH.exchange, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_PUBLISH.routing_key, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer)   then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_PUBLISH.mandatory := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      BASIC_PUBLISH.immediate := ReturnVal((bit_buffer and (1  shl  1)) , 1,0);
      decoded := BASIC_PUBLISH;
      Exit(0);
    end;

    AMQP_BASIC_RETURN_METHOD:
    begin
       BASIC_RETURN :=Pamqp_basic_return(pool.alloc(  sizeof(Tamqp_basic_return)));
      if BASIC_RETURN = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, BASIC_RETURN.reply_code )  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_RETURN.reply_text, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_RETURN.exchange, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_RETURN.routing_key, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := BASIC_RETURN;
      Exit(0);
    end;

    AMQP_BASIC_DELIVER_METHOD:
    begin
      BASIC_DELIVER :=Pamqp_basic_deliver(pool.alloc(  sizeof(Tamqp_basic_deliver)));
      if BASIC_DELIVER = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_DELIVER.consumer_tag, len8))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  0= amqp_decode_64(encoded, @offset, BASIC_DELIVER.delivery_tag )  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_decode_8(encoded, @offset, bit_buffer )   then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));

      BASIC_DELIVER.redelivered := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);

      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_DELIVER.exchange, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))  or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_DELIVER.routing_key, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := BASIC_DELIVER;
      Exit(0);
    end;

    AMQP_BASIC_GET_METHOD:
    begin
      BASIC_GET := Pamqp_basic_get(pool.alloc( sizeof(Tamqp_basic_get)));
      if BASIC_GET = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_16(encoded, @offset, BASIC_GET.ticket)  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8))   or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_GET.queue, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  (0= amqp_decode_8(encoded, @offset, bit_buffer ))   then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_GET.no_ack := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      decoded := BASIC_GET;
      Exit(0);
    end;

    AMQP_BASIC_GET_OK_METHOD:
    begin
      BASIC_GET_OK :=Pamqp_basic_get_ok(pool.alloc(  sizeof(Tamqp_basic_get_ok)));
      if BASIC_GET_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  (0= amqp_decode_64(encoded, @offset, BASIC_GET_OK.delivery_tag ))  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0= amqp_decode_8(encoded, @offset, bit_buffer  )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));

      BASIC_GET_OK.redelivered := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);

      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_GET_OK.exchange, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
             (0= amqp_decode_bytes(encoded, @offset, BASIC_GET_OK.routing_key, len8)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if  (0= amqp_decode_32(encoded, @offset, BASIC_GET_OK.message_count ))  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      decoded := BASIC_GET_OK;
      Exit(0);
    end;

    AMQP_BASIC_GET_EMPTY_METHOD:
    begin
      BASIC_GET_EMPTY := Pamqp_basic_get_empty(pool.alloc(  sizeof(Tamqp_basic_get_empty)));
      if BASIC_GET_EMPTY = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      begin
        //var len: uint8_t;
        if  (0= amqp_decode_8(encoded, @offset, len8)) or
            (0= amqp_decode_bytes(encoded, @offset, BASIC_GET_EMPTY.cluster_id, len8))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      decoded := BASIC_GET_EMPTY;
      Exit(0);
    end;

    AMQP_BASIC_ACK_METHOD:
    begin
      BASIC_ACK :=Pamqp_basic_ack(pool.alloc( sizeof(Tamqp_basic_ack)));
      if BASIC_ACK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_64(encoded, @offset, BASIC_ACK.delivery_tag ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_ACK.multiple := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      decoded := BASIC_ACK;
      Exit(0);
    end;

    AMQP_BASIC_REJECT_METHOD:
    begin
      BASIC_REJECT := Pamqp_basic_reject(pool.alloc(  sizeof(Tamqp_basic_reject)));
      if BASIC_REJECT = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_64(encoded, @offset, BASIC_REJECT.delivery_tag ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_REJECT.requeue := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      decoded := BASIC_REJECT;
      Exit(0);
    end;

    AMQP_BASIC_RECOVER_ASYNC_METHOD:
    begin
      BASIC_RECOVER_ASYNC :=Pamqp_basic_recover_async(pool.alloc(  sizeof(Tamqp_basic_recover_async)));
      if BASIC_RECOVER_ASYNC = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_RECOVER_ASYNC.requeue := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      decoded := BASIC_RECOVER_ASYNC;
      Exit(0);
    end;

    AMQP_BASIC_RECOVER_METHOD:
    begin
      BASIC_RECOVER := Pamqp_basic_recover(pool.alloc( sizeof(Tamqp_basic_recover)));
      if BASIC_RECOVER = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_RECOVER.requeue := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      decoded := BASIC_RECOVER;
      Exit(0);
    end;

    AMQP_BASIC_RECOVER_OK_METHOD:  begin
      BASIC_RECOVER_OK := Pamqp_basic_recover_ok(pool.alloc(  sizeof(Tamqp_basic_recover_ok)));
      if BASIC_RECOVER_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := BASIC_RECOVER_OK;
      Exit(0);
    end;

    AMQP_BASIC_NACK_METHOD:
    begin
      BASIC_NACK:=Pamqp_basic_nack(pool.alloc( sizeof(Tamqp_basic_nack)));
      if BASIC_NACK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if  0= amqp_decode_64(encoded, @offset, BASIC_NACK.delivery_tag ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_decode_8(encoded, @offset, &bit_buffer ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      BASIC_NACK.multiple := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      BASIC_NACK.requeue := ReturnVal((bit_buffer and (1  shl  1)) , 1,0);
      decoded := BASIC_NACK;
      Exit(0);
    end;

    AMQP_TX_SELECT_METHOD:
    begin
      TX_SELECT :=Pamqp_tx_select(pool.alloc( sizeof(Tamqp_tx_select)));
      if TX_SELECT = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := TX_SELECT;
      Exit(0);
    end;

    AMQP_TX_SELECT_OK_METHOD:
    begin
      TX_SELECT_OK := Pamqp_tx_select_ok(pool.alloc(  sizeof(Tamqp_tx_select_ok)));
      if TX_SELECT_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := TX_SELECT_OK;
      Exit(0);
    end;

    AMQP_TX_COMMIT_METHOD:
    begin
      TX_COMMIT :=Pamqp_tx_commit(pool.alloc( sizeof(Tamqp_tx_commit)));
      if TX_COMMIT = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := TX_COMMIT;
      Exit(0);
    end;

    AMQP_TX_COMMIT_OK_METHOD:
    begin
      TX_COMMIT_OK := Pamqp_tx_commit_ok(pool.alloc(  sizeof(Tamqp_tx_commit_ok)));
      if TX_COMMIT_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := TX_COMMIT_OK;
      Exit(0);
    end;

    AMQP_TX_ROLLBACK_METHOD:
    begin
      TX_ROLLBACK := Pamqp_tx_rollback(pool.alloc(  sizeof(Tamqp_tx_rollback)));
      if TX_ROLLBACK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := TX_ROLLBACK;
      Exit(0);
    end;

    AMQP_TX_ROLLBACK_OK_METHOD:
    begin
      TX_ROLLBACK_OK := Pamqp_tx_rollback_ok(pool.alloc(  sizeof(Tamqp_tx_rollback_ok)));
      if TX_ROLLBACK_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := TX_ROLLBACK_OK;
      Exit(0);
    end;

    AMQP_CONFIRM_SELECT_METHOD:
    begin
      CONFIRM_SELECT := Pamqp_confirm_select(pool.alloc(  sizeof(Tamqp_confirm_select)));
      if CONFIRM_SELECT = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      if 0= amqp_decode_8(encoded, @offset, &bit_buffer ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      CONFIRM_SELECT.nowait := ReturnVal((bit_buffer and (1  shl  0)) , 1,0);
      decoded := CONFIRM_SELECT;
      Exit(0);
    end;

    AMQP_CONFIRM_SELECT_OK_METHOD:
    begin
      CONFIRM_SELECT_OK := Pamqp_confirm_select_ok(pool.alloc( sizeof(Tamqp_confirm_select_ok)));
      if CONFIRM_SELECT_OK = nil then begin
        Exit(int(AMQP_STATUS_NO_MEMORY));
      end;
      decoded := CONFIRM_SELECT_OK;
      Exit(0);
    end;
    else
      Exit(Int(AMQP_STATUS_UNKNOWN_METHOD));
  end;
end;

function amqp_encode_properties(class_id : uint16;decoded: Pointer; encoded : Tamqp_bytes):integer;
var
  offset          : size_t;
  flags,
  remaining_flags,
  remainder       : amqp_flags_t;
  partial_flags   : uint16;
  p               : Pamqp_basic_properties;
  res             : integer;
begin
  offset := 0;
  { Cheat, and get the flags out generically, relying on the
     similarity of structure between classes }
  //flags := *(amqp_flags(decoded;
  flags := Pamqp_flags_t(decoded)^;
  begin
    { We take a copy of flags to avoid destroying it, as it is used
       in the autogenerated code below. }
    remaining_flags := flags;
    while (remaining_flags <> 0) do
    begin
      remainder := remaining_flags  shr  16;
      partial_flags := remaining_flags and $FFFE;
      if remainder <> 0 then
        partial_flags  := partial_flags  or 1;

      if  0= amqp_encode_n(16,encoded, @offset, partial_flags) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      remaining_flags := remainder;
    end;

  end;
  case class_id of
    10,
    20,
    30,
    40,
    50:
    begin
      Exit(int(offset));
    end;
    60:
    begin
      p := Pamqp_basic_properties(decoded);
      if (flags and AMQP_BASIC_CONTENT_TYPE_FLAG) > 0 then
      begin
        if (UINT8_MAX < p.content_type.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.content_type.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.content_type)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_CONTENT_ENCODING_FLAG)>0 then
      begin
        if (UINT8_MAX < p.content_encoding.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.content_encoding.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.content_encoding))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_HEADERS_FLAG)>0 then
      begin
        begin
          res := amqp_encode_table(encoded, @(p.headers), @offset);
          if res < 0 then Exit(res);
        end;
      end;
      if (flags and AMQP_BASIC_DELIVERY_MODE_FLAG)>0 then
      begin
        if  (0 = amqp_encode_n(8,encoded, @offset, p.delivery_mode)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_PRIORITY_FLAG)>0 then
      begin
        if  (0 = amqp_encode_n(8,encoded, @offset, p.priority)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_CORRELATION_ID_FLAG)>0 then
      begin
        if (UINT8_MAX < p.correlation_id.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.correlation_id.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.correlation_id)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_REPLY_TO_FLAG)>0 then
      begin
        if (UINT8_MAX < p.reply_to.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.reply_to.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.reply_to))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_EXPIRATION_FLAG)>0 then
      begin
        if (UINT8_MAX < p.expiration.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.expiration.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.expiration))  then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_MESSAGE_ID_FLAG)>0 then
      begin
        if (UINT8_MAX < p.message_id.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.message_id.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.message_id))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_TIMESTAMP_FLAG)>0 then
      begin
        if  (0 = amqp_encode_n(64,encoded, @offset, p.timestamp)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_TYPE_FLAG)>0 then
      begin
        if (UINT8_MAX < p.&type.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.&type.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.&type))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_USER_ID_FLAG)>0 then
      begin
        if (UINT8_MAX < p.user_id.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.user_id.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.user_id))then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_APP_ID_FLAG)>0 then
      begin
        if (UINT8_MAX < p.app_id.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.app_id.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.app_id)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      if (flags and AMQP_BASIC_CLUSTER_ID_FLAG)>0 then
      begin
        if (UINT8_MAX < p.cluster_id.len)  or
             (0 = amqp_encode_n(8,encoded, @offset, uint8_t(p.cluster_id.len)))  or
             (0 = amqp_encode_bytes(encoded, @offset, p.cluster_id)) then
          Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      end;
      Exit(int(offset));
    end;
    90:
    begin
      Exit(int(offset));
    end;
    85:
    begin
      Exit(int(offset));
    end;
    else
      Exit(Integer(AMQP_STATUS_UNKNOWN_CLASS));
  end;
end;

function amqp_encode_method(methodNumber : amqp_method_number_t;decoded: Pointer; encoded : Tamqp_bytes):integer;
var
    offset     : size_t;
    bit_buffer : byte;
    res        : Integer;
    START : Pamqp_connection_start;
    START_OK : Pamqp_connection_start_ok;
    SECURE_OK : Pamqp_connection_secure_ok;
    SECURE : Pamqp_connection_secure;
    TUNE : Pamqp_connection_tune;
    TUNE_OK : Pamqp_connection_tune_ok;
    open : Pamqp_connection_open;
    OPEN_OK : Pamqp_connection_open_ok;
    CONNECTION_CLOSE : Pamqp_connection_close;
    UPDATE_SECRET : Pamqp_connection_update_secret;
    BLOCKED : Pamqp_connection_blocked;
    CHANNEL_OPEN : Pamqp_channel_open;
    CHANNEL_OPEN_OK : Pamqp_channel_open_ok;
    CHANNEL_FLOW : Pamqp_channel_flow;
    CHANNEL_FLOW_OK : Pamqp_channel_flow_ok;
    CHANNEL_CLOSE : Pamqp_channel_close;
    ACCESS_REQUEST : Pamqp_access_request;
    ACCESS_REQUEST_OK : Pamqp_access_request_ok;
    EXCHANGE_DECLARE : Pamqp_exchange_declare;
    EXCHANGE_DELETE : Pamqp_exchange_delete;
    EXCHANGE_BIND : Pamqp_exchange_bind;
    EXCHANGE_UNBIND : Pamqp_exchange_unbind;
    QUEUE_DECLARE : Pamqp_queue_declare;
    QUEUE_DECLARE_OK : Pamqp_queue_declare_ok;
    QUEUE_BIND : Pamqp_queue_bind;
    QUEUE_PURGE : Pamqp_queue_purge;
    QUEUE_PURGE_OK : Pamqp_queue_purge_ok;
    QUEUE_DELETE : Pamqp_queue_delete;
    QUEUE_DELETE_OK : Pamqp_queue_delete_ok;
    QUEUE_UNBIND : Pamqp_queue_unbind;
    BASIC_QOS : Pamqp_basic_qos;
    BASIC_CONSUME : Pamqp_basic_consume;
    BASIC_CONSUME_OK : Pamqp_basic_consume_ok;
    BASIC_CANCEL : Pamqp_basic_cancel;
    BASIC_CANCEL_OK : Pamqp_basic_cancel_ok;
    pub : Pamqp_basic_publish;
    BASIC_RETURN : Pamqp_basic_return;
    BASIC_DELIVER : Pamqp_basic_deliver;
    BASIC_GET_OK : Pamqp_basic_get_ok;
    BASIC_GET_EMPTY : Pamqp_basic_get_empty;
    BASIC_ACK : Pamqp_basic_ack;
    BASIC_REJECT : Pamqp_basic_reject;
    BASIC_RECOVER_ASYNC : Pamqp_basic_recover_async;
    BASIC_GET : Pamqp_basic_get;
    BASIC_RECOVER : Pamqp_basic_recover;
    BASIC_NACK : Pamqp_basic_nack;
    CONFIRM_SELECT : Pamqp_confirm_select;
begin
  offset := 0;
  case methodNumber of
    AMQP_CONNECTION_START_METHOD:
    begin
      START := Pamqp_connection_start(decoded);
      if  0 = amqp_encode_n(8, encoded, @offset, START.version_major ) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  0 = amqp_encode_n(8, encoded, @offset, START.version_minor)  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        res := amqp_encode_table(encoded, @(START.server_properties), @offset);
        if res < 0 then Exit(res);
      end;
      if (UINT32_MAX < START.mechanisms.len)  or
         (0= amqp_encode_n(32, encoded, @offset, uint32_t(START.mechanisms.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, START.mechanisms)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT32_MAX < START.locales.len)  or
         (0= amqp_encode_n(32, encoded, @offset, uint32_t(START.locales.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, START.locales))   then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CONNECTION_START_OK_METHOD:
    begin
      START_OK := Pamqp_connection_start_ok(decoded);
      begin
        res := amqp_encode_table(encoded, @START_OK.client_properties, @offset);
        if res < 0 then Exit(res);
      end;
      if (UINT8_MAX < START_OK.mechanism.len)  or
         (0= amqp_encode_n(8, encoded, @offset, uint8_t(START_OK.mechanism.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, START_OK.mechanism))  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));

      if (UINT32_MAX < START_OK.response.len)  or
         (0= amqp_encode_n(32, encoded, @offset, uint32_t(  START_OK.response.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, START_OK.response)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));

      if (UINT8_MAX < START_OK.locale.len)  or
         (0= amqp_encode_n(8, encoded, @offset, uint8_t(START_OK.locale.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, START_OK.locale)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));

      Exit(int(offset));
    end;

    AMQP_CONNECTION_SECURE_METHOD:
    begin
      SECURE := Pamqp_connection_secure (decoded);
      if (UINT32_MAX < SECURE.challenge.len)  or
         (0= amqp_encode_n(32, encoded, @offset, uint32_t(SECURE.challenge.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, SECURE.challenge)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));

      Exit(int(offset));
    end;

    AMQP_CONNECTION_SECURE_OK_METHOD:
    begin
      SECURE_OK := Pamqp_connection_secure_ok(decoded);
      if (UINT32_MAX < SECURE_OK.response.len)  or
         (0= amqp_encode_n(32, encoded, @offset, uint32_t(SECURE_OK.response.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, SECURE_OK.response)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));

      Exit(int(offset));
    end;

    AMQP_CONNECTION_TUNE_METHOD:
    begin
      TUNE := Pamqp_connection_tune(decoded);
      if  0= amqp_encode_n(16, encoded, @offset, tune.channel_max  )then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_encode_n(32, encoded, @offset, tune.frame_max  ) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_encode_n(16, encoded, @offset, tune.heartbeat )  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CONNECTION_TUNE_OK_METHOD:
    begin
      tune_ok := Pamqp_connection_tune_ok(decoded);
      if  0= amqp_encode_n(16, encoded, @offset, tune_ok.channel_max  )then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_encode_n(32, encoded, @offset, tune_ok.frame_max) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_encode_n(16, encoded, @offset, tune_ok.heartbeat)  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CONNECTION_OPEN_METHOD:
    begin
      open := Pamqp_connection_open(decoded);
      if (UINT8_MAX < open.virtual_host.len)  or
         (0= amqp_encode_n(8, encoded, @offset, uint8_t(open.virtual_host.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, open.virtual_host)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < open.capabilities.len)  or
         (0 = amqp_encode_n(8, encoded, @offset, uint8_t(open.capabilities.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, open.capabilities))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if open.insist > 0 then
        bit_buffer  := bit_buffer  or ((1  shl  0));
      if  0= amqp_encode_n(8, encoded, @offset, bit_buffer )  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CONNECTION_OPEN_OK_METHOD:
    begin
      OPEN_OK := Pamqp_connection_open_ok(decoded);
      if (UINT8_MAX < OPEN_OK.known_hosts.len)  or
         (0= amqp_encode_n(8, encoded, @offset, uint8_t(OPEN_OK.known_hosts.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, OPEN_OK.known_hosts))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CONNECTION_CLOSE_METHOD:
    begin
      CONNECTION_CLOSE := Pamqp_connection_close(decoded);
      if  0= amqp_encode_n(16, encoded, @offset, CONNECTION_CLOSE.reply_code )  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < CONNECTION_CLOSE.reply_text.len)  or
         (0= amqp_encode_n(8, encoded, @offset, uint8_t(CONNECTION_CLOSE.reply_text.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, CONNECTION_CLOSE.reply_text)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_encode_n(16, encoded, @offset, CONNECTION_CLOSE.class_id  ) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  0= amqp_encode_n(16, encoded, @offset, CONNECTION_CLOSE.method_id)  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CONNECTION_CLOSE_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_CONNECTION_BLOCKED_METHOD:
    begin
      BLOCKED := Pamqp_connection_blocked(decoded);
      if (UINT8_MAX < BLOCKED.reason.len)  or
         (0= amqp_encode_n(8, encoded, @offset, uint8_t( BLOCKED.reason.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, BLOCKED.reason))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CONNECTION_UNBLOCKED_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_CONNECTION_UPDATE_SECRET_METHOD:
    begin
      UPDATE_SECRET := Pamqp_connection_update_secret(decoded);
      if (UINT32_MAX < UPDATE_SECRET.new_secret.len)  or
         (0= amqp_encode_n(32, encoded, @offset, uint32_t(UPDATE_SECRET.new_secret.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, UPDATE_SECRET.new_secret))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < UPDATE_SECRET.reason.len)  or
         (0= amqp_encode_n(8, encoded, @offset, uint8_t(UPDATE_SECRET.reason.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, UPDATE_SECRET.reason))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CONNECTION_UPDATE_SECRET_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_CHANNEL_OPEN_METHOD:
    begin
      CHANNEL_OPEN := Pamqp_channel_open(decoded);
      if (UINT8_MAX < CHANNEL_OPEN.out_of_band.len)  or
         (0= amqp_encode_n(8, encoded, @offset, uint8_t(CHANNEL_OPEN.out_of_band.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, CHANNEL_OPEN.out_of_band)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CHANNEL_OPEN_OK_METHOD:
    begin
      CHANNEL_OPEN_OK := Pamqp_channel_open_ok(decoded);
      if (UINT32_MAX < CHANNEL_OPEN_OK.channel_id.len)  or
         (0= amqp_encode_n(32, encoded, @offset, uint32_t (CHANNEL_OPEN_OK.channel_id.len)))  or
         (0= amqp_encode_bytes(encoded, @offset, CHANNEL_OPEN_OK.channel_id))  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CHANNEL_FLOW_METHOD:
    begin
      CHANNEL_FLOW := Pamqp_channel_flow(decoded);
      bit_buffer := 0;
      if CHANNEL_FLOW.active > 0 then
        bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if 0= amqp_encode_n(8, encoded, @offset, bit_buffer)  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CHANNEL_FLOW_OK_METHOD:
    begin
      CHANNEL_FLOW_OK := Pamqp_channel_flow_ok(decoded);
      bit_buffer := 0;
      if CHANNEL_FLOW_OK.active > 0 then
        bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  0= amqp_encode_n(8, encoded, @offset, bit_buffer) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CHANNEL_CLOSE_METHOD:
    begin
      CHANNEL_CLOSE := Pamqp_channel_close(decoded);
      if  (0 = amqp_encode_n(16, encoded, @offset, CHANNEL_CLOSE.reply_code)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < CHANNEL_CLOSE.reply_text.len)  or
           (0 = amqp_encode_n(8, encoded, @offset, uint8_t(CHANNEL_CLOSE.reply_text.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, CHANNEL_CLOSE.reply_text)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0 = amqp_encode_n(16, encoded, @offset, CHANNEL_CLOSE.class_id ))  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0 = amqp_encode_n(16, encoded, @offset, CHANNEL_CLOSE.method_id)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_CHANNEL_CLOSE_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_ACCESS_REQUEST_METHOD:
    begin
      ACCESS_REQUEST := Pamqp_access_request(decoded);
      if (UINT8_MAX < ACCESS_REQUEST.realm.len)  or
           (0 = amqp_encode_n(8, encoded, @offset, uint8_t( ACCESS_REQUEST.realm.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, ACCESS_REQUEST.realm))  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if ACCESS_REQUEST.exclusive > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if ACCESS_REQUEST.passive > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  1));
      if ACCESS_REQUEST.active > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  2));
      if ACCESS_REQUEST.write > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  3));
      if ACCESS_REQUEST.read > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  4));
      if  (0 = amqp_encode_n(8, encoded, @offset, bit_buffer)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_ACCESS_REQUEST_OK_METHOD:
    begin
      ACCESS_REQUEST_OK := Pamqp_access_request_ok(decoded);
      if  (0 = amqp_encode_n(16, encoded, @offset, ACCESS_REQUEST_OK.ticket  )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_EXCHANGE_DECLARE_METHOD:
    begin
      EXCHANGE_DECLARE := Pamqp_exchange_declare(decoded);
      if  (0 = amqp_encode_n(16, encoded, @offset, EXCHANGE_DECLARE.ticket)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < EXCHANGE_DECLARE.exchange.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(EXCHANGE_DECLARE.exchange.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, EXCHANGE_DECLARE.exchange)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < EXCHANGE_DECLARE.&type.len)  or
           (0 = amqp_encode_n(8, encoded, @offset, uint8_t(EXCHANGE_DECLARE.&type.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, EXCHANGE_DECLARE.&type))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if EXCHANGE_DECLARE.passive >0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if EXCHANGE_DECLARE.durable > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  1));
      if EXCHANGE_DECLARE.auto_delete > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  2));
      if EXCHANGE_DECLARE.internal > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  3));
      if EXCHANGE_DECLARE.nowait > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  4));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer  ))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        res := amqp_encode_table(encoded, @(EXCHANGE_DECLARE.arguments), @offset);
        if res < 0 then
           Exit(res);
      end;
      Exit(int(offset));
    end;

    AMQP_EXCHANGE_DECLARE_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_EXCHANGE_DELETE_METHOD:
    begin
      EXCHANGE_DELETE := Pamqp_exchange_delete(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, EXCHANGE_DELETE.ticket  )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < EXCHANGE_DELETE.exchange.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(EXCHANGE_DELETE.exchange.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, EXCHANGE_DELETE.exchange))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if EXCHANGE_DELETE.if_unused > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if EXCHANGE_DELETE.nowait > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  1));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_EXCHANGE_DELETE_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_EXCHANGE_BIND_METHOD:
    begin
      EXCHANGE_BIND := Pamqp_exchange_bind(decoded);
      if  (0 = amqp_encode_n(16, encoded, @offset, EXCHANGE_BIND.ticket )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < EXCHANGE_BIND.destination.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t( EXCHANGE_BIND.destination.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, EXCHANGE_BIND.destination))  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < EXCHANGE_BIND.source.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(EXCHANGE_BIND.source.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, EXCHANGE_BIND.source)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < EXCHANGE_BIND.routing_key.len)  or
           (0 = amqp_encode_n(8, encoded, @offset, uint8_t(EXCHANGE_BIND.routing_key.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, EXCHANGE_BIND.routing_key)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if EXCHANGE_BIND.nowait > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        res := amqp_encode_table(encoded, @(EXCHANGE_BIND.arguments), @offset);
        if res < 0 then Exit(res);
      end;
      Exit(int(offset));
    end;

    AMQP_EXCHANGE_BIND_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_EXCHANGE_UNBIND_METHOD:
    begin
      EXCHANGE_UNBIND := Pamqp_exchange_unbind(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, EXCHANGE_UNBIND.ticket  ))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < EXCHANGE_UNBIND.destination.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t( EXCHANGE_UNBIND.destination.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, EXCHANGE_UNBIND.destination)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < EXCHANGE_UNBIND.source.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(EXCHANGE_UNBIND.source.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, EXCHANGE_UNBIND.source)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < EXCHANGE_UNBIND.routing_key.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t( EXCHANGE_UNBIND.routing_key.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, EXCHANGE_UNBIND.routing_key)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if EXCHANGE_UNBIND.nowait > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        res := amqp_encode_table(encoded, @(EXCHANGE_UNBIND.arguments), @offset);
        if res < 0 then Exit(res);
      end;
      Exit(int(offset));
    end;

    AMQP_EXCHANGE_UNBIND_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_QUEUE_DECLARE_METHOD:
    begin
      QUEUE_DECLARE := Pamqp_queue_declare(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, QUEUE_DECLARE.ticket))  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < QUEUE_DECLARE.queue.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t (QUEUE_DECLARE.queue.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_DECLARE.queue))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if QUEUE_DECLARE.passive > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if QUEUE_DECLARE.durable > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  1));
      if QUEUE_DECLARE.exclusive > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  2));
      if QUEUE_DECLARE.auto_delete > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  3));
      if QUEUE_DECLARE.nowait > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  4));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer))  then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        res := amqp_encode_table(encoded, @(QUEUE_DECLARE.arguments), @offset);
        if res < 0 then Exit(res);
      end;
      Exit(int(offset));
    end;

    AMQP_QUEUE_DECLARE_OK_METHOD:
    begin
      QUEUE_DECLARE_OK := Pamqp_queue_declare_ok(decoded);
      if (UINT8_MAX < QUEUE_DECLARE_OK.queue.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t( QUEUE_DECLARE_OK.queue.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_DECLARE_OK.queue)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0 = amqp_encode_n(32,encoded, @offset, QUEUE_DECLARE_OK.message_count)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0 = amqp_encode_n(32,encoded, @offset, QUEUE_DECLARE_OK.consumer_count)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_QUEUE_BIND_METHOD:
    begin
      QUEUE_BIND := Pamqp_queue_bind(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, QUEUE_BIND.ticket)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < QUEUE_BIND.queue.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( QUEUE_BIND.queue.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_BIND.queue)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < QUEUE_BIND.exchange.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( QUEUE_BIND.exchange.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_BIND.exchange))then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < QUEUE_BIND.routing_key.len ) or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(  QUEUE_BIND.routing_key.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_BIND.routing_key)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if QUEUE_BIND.nowait > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        res := amqp_encode_table(encoded, @(QUEUE_BIND.arguments), @offset);
        if res < 0 then Exit(res);
      end;
      Exit(int(offset));
    end;

    AMQP_QUEUE_BIND_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_QUEUE_PURGE_METHOD:
    begin
      QUEUE_PURGE := Pamqp_queue_purge(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, QUEUE_PURGE.ticket )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < QUEUE_PURGE.queue.len ) or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( QUEUE_PURGE.queue.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_PURGE.queue)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if QUEUE_PURGE.nowait > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_QUEUE_PURGE_OK_METHOD:
    begin
      QUEUE_PURGE_OK := Pamqp_queue_purge_ok(decoded);
      if  (0 = amqp_encode_n(32,encoded, @offset, QUEUE_PURGE_OK.message_count )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_QUEUE_DELETE_METHOD:
    begin
      QUEUE_DELETE := Pamqp_queue_delete(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, QUEUE_DELETE.ticket )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < QUEUE_DELETE.queue.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t( QUEUE_DELETE.queue.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_DELETE.queue)) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if QUEUE_DELETE.if_unused > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if QUEUE_DELETE.if_empty > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  1));
      if QUEUE_DELETE.nowait > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  2));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(Integer(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_QUEUE_DELETE_OK_METHOD:
    begin
      QUEUE_DELETE_OK := Pamqp_queue_delete_ok(decoded);
      if  (0 = amqp_encode_n(32,encoded, @offset, QUEUE_DELETE_OK.message_count )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_QUEUE_UNBIND_METHOD:
    begin
      QUEUE_UNBIND := Pamqp_queue_unbind(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, QUEUE_UNBIND.ticket )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < QUEUE_UNBIND.queue.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(QUEUE_UNBIND.queue.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_UNBIND.queue))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < QUEUE_UNBIND.exchange.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(QUEUE_UNBIND.exchange.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_UNBIND.exchange))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < QUEUE_UNBIND.routing_key.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(QUEUE_UNBIND.routing_key.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, QUEUE_UNBIND.routing_key)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        res := amqp_encode_table(encoded, @(QUEUE_UNBIND.arguments), @offset);
        if res < 0 then Exit(res);
      end;
      Exit(int(offset));
    end;

    AMQP_QUEUE_UNBIND_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_BASIC_QOS_METHOD:
    begin
      BASIC_QOS := Pamqp_basic_qos(decoded);
      if  (0 = amqp_encode_n(32,encoded, @offset, BASIC_QOS.prefetch_size )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0 = amqp_encode_n(16,encoded, @offset, BASIC_QOS.prefetch_count )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if BASIC_QOS.global > 0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer ) )then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_QOS_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_BASIC_CONSUME_METHOD:
    begin
      BASIC_CONSUME := Pamqp_basic_consume(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, BASIC_CONSUME.ticket ) )then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_CONSUME.queue.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(BASIC_CONSUME.queue.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_CONSUME.queue))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_CONSUME.consumer_tag.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t(BASIC_CONSUME.consumer_tag.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_CONSUME.consumer_tag)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if BASIC_CONSUME.no_local >0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if BASIC_CONSUME.no_ack>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  1));
      if BASIC_CONSUME.exclusive>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  2));
      if BASIC_CONSUME.nowait>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  3));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      begin
        res := amqp_encode_table(encoded, @(BASIC_CONSUME.arguments), @offset);
        if res < 0 then Exit(res);
      end;
      Exit(int(offset));
    end;

    AMQP_BASIC_CONSUME_OK_METHOD:
    begin
      BASIC_CONSUME_OK := Pamqp_basic_consume_ok(decoded);
      if (UINT8_MAX < BASIC_CONSUME_OK.consumer_tag.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t (BASIC_CONSUME_OK.consumer_tag.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_CONSUME_OK.consumer_tag))  then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_CANCEL_METHOD:
    begin
      BASIC_CANCEL := Pamqp_basic_cancel(decoded);
      if (UINT8_MAX < BASIC_CANCEL.consumer_tag.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_CANCEL.consumer_tag.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_CANCEL.consumer_tag))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if BASIC_CANCEL.nowait>0 then
         bit_buffer  := bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_CANCEL_OK_METHOD:
    begin
      BASIC_CANCEL_OK := Pamqp_basic_cancel_ok(decoded);
      if (UINT8_MAX < BASIC_CANCEL_OK.consumer_tag.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_CANCEL_OK.consumer_tag.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_CANCEL_OK.consumer_tag)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_PUBLISH_METHOD:
    begin
      pub := Pamqp_basic_publish(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, pub.ticket ) )then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < pub.exchange.len)  or
         (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( pub.exchange.len)))  or
         (0 = amqp_encode_bytes(encoded, @offset, pub.exchange)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < pub.routing_key.len)  or
         (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( pub.routing_key.len)))  or
         (0 = amqp_encode_bytes(encoded, @offset, pub.routing_key))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if pub.mandatory>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if pub.immediate>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  1));
      if 0 = amqp_encode_n(8,encoded, @offset, bit_buffer ) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_RETURN_METHOD:
    begin
      BASIC_RETURN := Pamqp_basic_return(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, BASIC_RETURN.reply_code ) )then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_RETURN.reply_text.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_RETURN.reply_text.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_RETURN.reply_text)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_RETURN.exchange.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_RETURN.exchange.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_RETURN.exchange))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_RETURN.routing_key.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_RETURN.routing_key.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_RETURN.routing_key))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_DELIVER_METHOD:
    begin
      BASIC_DELIVER := Pamqp_basic_deliver(decoded);
      if (UINT8_MAX < BASIC_DELIVER.consumer_tag.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_DELIVER.consumer_tag.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_DELIVER.consumer_tag))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0 = amqp_encode_n(64,encoded, @offset, BASIC_DELIVER.delivery_tag )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if BASIC_DELIVER.redelivered>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_DELIVER.exchange.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_DELIVER.exchange.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_DELIVER.exchange)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_DELIVER.routing_key.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_DELIVER.routing_key.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_DELIVER.routing_key))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_GET_METHOD:
    begin
      BASIC_GET := Pamqp_basic_get(decoded);
      if  (0 = amqp_encode_n(16,encoded, @offset, BASIC_GET.ticket )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_GET.queue.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_GET.queue.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_GET.queue)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if BASIC_GET.no_ack>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_GET_OK_METHOD:
    begin
      BASIC_GET_OK := Pamqp_basic_get_ok(decoded);
      if  (0 = amqp_encode_n(64,encoded, @offset, BASIC_GET_OK.delivery_tag )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if BASIC_GET_OK.redelivered>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_GET_OK.exchange.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_GET_OK.exchange.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_GET_OK.exchange))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if (UINT8_MAX < BASIC_GET_OK.routing_key.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_GET_OK.routing_key.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_GET_OK.routing_key))then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      if  (0 = amqp_encode_n(32,encoded, @offset, BASIC_GET_OK.message_count)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_GET_EMPTY_METHOD:
    begin
      BASIC_GET_EMPTY := Pamqp_basic_get_empty(decoded);
      if (UINT8_MAX < BASIC_GET_EMPTY.cluster_id.len)  or
           (0 = amqp_encode_n(8,encoded, @offset, uint8_t ( BASIC_GET_EMPTY.cluster_id.len)))  or
           (0 = amqp_encode_bytes(encoded, @offset, BASIC_GET_EMPTY.cluster_id)) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_ACK_METHOD:
    begin
      BASIC_ACK := Pamqp_basic_ack(decoded);
      if  (0 = amqp_encode_n(64,encoded, @offset, BASIC_ACK.delivery_tag )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if BASIC_ACK.multiple>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_REJECT_METHOD:
    begin
      BASIC_REJECT := Pamqp_basic_reject(decoded);
      if  (0 = amqp_encode_n(64,encoded, @offset, BASIC_REJECT.delivery_tag )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if BASIC_REJECT.requeue>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_RECOVER_ASYNC_METHOD:
    begin
      BASIC_RECOVER_ASYNC := Pamqp_basic_recover_async(decoded);
      bit_buffer := 0;
      if BASIC_RECOVER_ASYNC.requeue >0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_RECOVER_METHOD:
    begin
      BASIC_RECOVER := Pamqp_basic_recover(decoded);
      bit_buffer := 0;
      if BASIC_RECOVER.requeue>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;

    AMQP_BASIC_RECOVER_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_BASIC_NACK_METHOD:
    begin
      BASIC_NACK := Pamqp_basic_nack(decoded);
      if  (0 = amqp_encode_n(64,encoded, @offset, BASIC_NACK.delivery_tag )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      bit_buffer := 0;
      if BASIC_NACK.multiple>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if BASIC_NACK.requeue>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  1));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;
    AMQP_TX_SELECT_METHOD,
    AMQP_TX_SELECT_OK_METHOD,
    AMQP_TX_COMMIT_METHOD,
    AMQP_TX_COMMIT_OK_METHOD,
    AMQP_TX_ROLLBACK_METHOD,
    AMQP_CONFIRM_SELECT_OK_METHOD,
    AMQP_TX_ROLLBACK_OK_METHOD:
    begin
      Exit(int(offset));
    end;

    AMQP_CONFIRM_SELECT_METHOD:
    begin
      CONFIRM_SELECT := Pamqp_confirm_select(decoded);
      bit_buffer := 0;
      if CONFIRM_SELECT.nowait>0 then
         bit_buffer  :=  bit_buffer  or ((1  shl  0));
      if  (0 = amqp_encode_n(8,encoded, @offset, bit_buffer )) then
        Exit(int(AMQP_STATUS_BAD_AMQP_DATA));
      Exit(int(offset));
    end;
    else
      Exit(Integer(AMQP_STATUS_UNKNOWN_METHOD));
  end;
end;
initialization

end.
