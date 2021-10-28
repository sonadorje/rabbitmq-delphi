unit amqp.connection;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$INCLUDE  config.inc}
interface
  uses {$IFDEF FPC}SysUtils,{$Else} System.SysUtils, {$ENDIF}amqp.socket, AMQP.Types,
       amqp.framing, amqp.time, amqp.table,
       amqp.privt, amqp.mem, amqp.tcp_socket;

  function amqp_new_connection:Pamqp_connection_state;
  procedure amqp_set_sockfd( state : Pamqp_connection_state; sockfd : integer);

  function amqp_tune_connection( state : Pamqp_connection_state; channel_max, frame_max, heartbeat : integer):integer;
  function amqp_destroy_connection( state : Pamqp_connection_state):integer;
  procedure return_to_idle( state : Pamqp_connection_state);
  function consume_data(state : Pamqp_connection_state; out received_data : Tamqp_bytes):size_t;

  function amqp_release_buffers_ok( state : Pamqp_connection_state):amqp_boolean_t;
  procedure amqp_release_buffers( state : Pamqp_connection_state);
  procedure amqp_maybe_release_buffers( state : Pamqp_connection_state);
  procedure amqp_maybe_release_buffers_on_channel( state : Pamqp_connection_state; channel : amqp_channel_t);
  function amqp_frame_to_bytes(const Aframe : Tamqp_frame; Abuffer : Tamqp_bytes; out Aencoded : Tamqp_bytes):integer;

  function amqp_send_frame(Astate : Pamqp_connection_state;const Aframe : Pamqp_frame):integer;
  function amqp_send_frame_inner(Astate : Pamqp_connection_state;const Aframe : Tamqp_frame; Aflags : integer; Adeadline : Tamqp_time):integer;
 
  function amqp_handle_input(Astate : Pamqp_connection_state;
                             var Areceived_data : Tamqp_bytes;
                             out Adecoded_frame : Tamqp_frame):integer;
  //function amqp_heartbeat_send(state: Pamqp_connection_state): int;
  function amqp_heartbeat_recv(state: Pamqp_connection_state): int;

  const
     AMQP_INITIAL_FRAME_POOL_PAGE_SIZE = 65536;
     AMQP_INITIAL_INBOUND_SOCK_BUFFER_SIZE = 131072;
     AMQP_DEFAULT_LOGIN_TIMEOUT_SEC = 12;

implementation

function amqp_send_frame_inner(Astate : Pamqp_connection_state;const Aframe : Tamqp_frame;
                               Aflags : integer; Adeadline : Tamqp_time):integer;
var
    Lres, count, Level   : integer;
    Lsent         : ssize_t;
    Lencoded      : Tamqp_bytes;
    Lnext_timeout : Tamqp_time;
    label start_send   ;
begin
  { TODO: if the AMQP_SF_MORE socket optimization can be shown to work
   * correctly, then this could be un-done so that body-frames are sent as 3
   * send calls, getting rid of the copy of the body content, some testing
   * would need to be done to see if this would actually a win for performance.
   * }
   Inc(gLevel);
   Level := gLevel;
   count := 0;
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step into amqp.connection:: amqp_frame_to_bytes==>');
  {$ENDIF}

  Lres := amqp_frame_to_bytes(Aframe, Astate.outbound_buffer, Lencoded);
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step over amqp.connection::amqp_frame_to_bytes, res=' + IntToStr(Lres));
  {$ENDIF}
  if Int(AMQP_STATUS_OK) <> Lres then
     Exit(Lres);

start_send:
  Inc(count);
  Lnext_timeout := amqp_time_first(Adeadline, Astate.next_recv_heartbeat);
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step into amqp.socket:: amqp_try_send==>, start_send:' + IntToStr(count));
  {$ENDIF}
  Lsent := amqp_try_send(Astate, Lencoded.bytes, Lencoded.len, Lnext_timeout, Aflags);
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step over amqp.socket:: amqp_try_send, res=' + IntToStr(Lsent));
  {$ENDIF}
  if 0 > Lsent then
    Exit(int(Lsent));

  { A partial send has occurred, because of a heartbeat timeout (so try recv
   * something) or common timeout (so return AMQP_STATUS_TIMEOUT) }
  if ssize_t(Lencoded.len) <> Lsent then
  begin
    if Lnext_timeout = Adeadline then
        { timeout of method was received, so return from method}
      Exit(Integer(AMQP_STATUS_TIMEOUT));

    Lres := amqp_try_recv(Astate);
    if Int(AMQP_STATUS_TIMEOUT) = Lres then
        Exit(Integer(AMQP_STATUS_HEARTBEAT_TIMEOUT))
    else
    if (Int(AMQP_STATUS_OK) <> Lres) then
        Exit(Lres);

    Inc(Lencoded.bytes ,Lsent);
    Lencoded.len  := Lencoded.len - Lsent;
    goto start_send;
  end;
  Lres := amqp_time_s_from_now(Astate.next_send_heartbeat,
                               Astate.heartbeat);
  Result := Lres;
end;


function amqp_heartbeat_recv( state: Pamqp_connection_state): int;
begin
  Result := 2 * state.heartbeat;
end;


function amqp_handle_input(Astate : Pamqp_connection_state;
                           var Areceived_data : Tamqp_bytes;
                           out Adecoded_frame : Tamqp_frame):integer;
var
    bytes_consumed : size_t;
    raw_frame      : PAMQPChar;
    channel        : amqp_channel_t;
    channel_pool   : Pamqp_pool;
    frame_size     : uint32;
    encoded        : Tamqp_bytes;
    res,Level            : integer;

begin
  { Returning frame_type of zero indicates either insufficient input,
     or a complete, ignored frame was read. }
  Inc(gLevel);
  Level := gLevel;
  Adecoded_frame.frame_type := 0;
  if Areceived_data.len = 0 then
     Exit(Int(AMQP_STATUS_OK));

  if Astate.state = CONNECTION_STATE_IDLE then
     Astate.state := CONNECTION_STATE_HEADER;
  {$IFDEF _DEBUG_}
      DebugOut(Level, 'step into amqp.connection:: consume_data==>');
  {$ENDIF}
  bytes_consumed := consume_data(Astate, Areceived_data);
  {$IFDEF _DEBUG_}
      DebugOut(Level, 'step over amqp.connection:: consume_data, bytes_consumed=' + IntToStr(bytes_consumed));
  {$ENDIF}
  { do we have target_size data yet? if not, return with the
     expectation that more will arrive }
  if Astate.inbound_offset < Astate.target_size then
    Exit(int(bytes_consumed));

  raw_frame := (Astate.inbound_buffer.bytes);
  //var p := PAnsiChar( state.inbound_buffer.bytes);
  case Astate.state of
    CONNECTION_STATE_INITIAL,
    CONNECTION_STATE_HEADER,
    CONNECTION_STATE_BODY:
    begin
      { check for a protocol header from the server }
      if CompareMem(raw_frame, PAnsiChar('AMQP'), 4) then
      //if PAnsiChar(raw_frame) = 'AMQP' then
      begin
        Adecoded_frame.frame_type := Ord(AMQP_PSEUDOFRAME_PROTOCOL_HEADER);
        Adecoded_frame.channel := 0;
        Adecoded_frame.payload.protocol_header.transport_high := amqp_d8(amqp_offset(raw_frame, 4));
        Adecoded_frame.payload.protocol_header.transport_low := amqp_d8(amqp_offset(raw_frame, 5));
        Adecoded_frame.payload.protocol_header.protocol_version_major := amqp_d8(amqp_offset(raw_frame, 6));
        Adecoded_frame.payload.protocol_header.protocol_version_minor := amqp_d8(amqp_offset(raw_frame, 7));
        return_to_idle(Astate);
        Exit(int(bytes_consumed));
      end;

    //CONNECTION_STATE_HEADER:

      channel := amqp_d16(amqp_offset(raw_frame, 1));
      { frame length is 3 bytes in }
      frame_size := amqp_d32(amqp_offset(raw_frame, 3));
      { To prevent the target_size calculation below from overflowing, check
       * that the stated frame_size is smaller than a signed 32-bit. Given
       * the library only allows configuring frame_max as an int32_t, and
       * frame_size is uint32_t, the math below is safe from overflow. }
      if frame_size >= INT32_MAX then
         Exit(Int(AMQP_STATUS_BAD_AMQP_DATA));

      Astate.target_size := frame_size + HEADER_SIZE + FOOTER_SIZE;
      if size_t(Astate.frame_max) < Astate.target_size then
         Exit(Int(AMQP_STATUS_BAD_AMQP_DATA));

      {$IFDEF _DEBUG_}
          DebugOut(Level, 'step into amqp.mem:: amqp_get_or_create_channel_pool==>');
      {$ENDIF}
      channel_pool := Astate.get_or_create_channel_pool(channel);
      {$IFDEF _DEBUG_}
          DebugOut(Level, 'step over amqp.mem:: amqp_get_or_create_channel_pool.');
      {$ENDIF}
      if nil = channel_pool then
         Exit(Int(AMQP_STATUS_NO_MEMORY));

      channel_pool.alloc_bytes( Astate.target_size, Astate.inbound_buffer);
      if nil = Astate.inbound_buffer.bytes then
          Exit(Int(AMQP_STATUS_NO_MEMORY));

      memcpy(Astate.inbound_buffer.bytes, @Astate.header_buffer, HEADER_SIZE);
      raw_frame := Astate.inbound_buffer.bytes;
      Astate.state := CONNECTION_STATE_BODY;
      bytes_consumed  := bytes_consumed + consume_data(Astate, Areceived_data);
      { do we have target_size data yet? if not, return with the
         expectation that more will arrive }
      if Astate.inbound_offset < Astate.target_size then
        Exit(int(bytes_consumed));


      { fall through to process body }
    //CONNECTION_STATE_BODY:

      { Check frame end marker (footer) }
      if amqp_d8(amqp_offset(raw_frame, Astate.target_size - 1 )) <> AMQP_FRAME_END then
          Exit(Int(AMQP_STATUS_BAD_AMQP_DATA));

      Adecoded_frame.frame_type := amqp_d8(amqp_offset(raw_frame, 0));
      Adecoded_frame.channel    := amqp_d16(amqp_offset(raw_frame, 1));
      {$IFDEF _DEBUG_}
          DebugOut(Level, 'step into amqp.mem:: amqp_get_or_create_channel_pool==>');
      {$ENDIF}
      channel_pool := Astate.get_or_create_channel_pool(Adecoded_frame.channel);
      {$IFDEF _DEBUG_}
          DebugOut(Level, 'step over amqp.mem:: amqp_get_or_create_channel_pool.');
      {$ENDIF}
      if nil = channel_pool then
        Exit(Int(AMQP_STATUS_NO_MEMORY));

      case Adecoded_frame.frame_type of
        AMQP_FRAME_METHOD:
        begin
          Adecoded_frame.payload.method.id := amqp_d32(amqp_offset(raw_frame, HEADER_SIZE));
          encoded.bytes := amqp_offset(raw_frame, HEADER_SIZE + 4);
          encoded.len := Astate.target_size - HEADER_SIZE - 4 - FOOTER_SIZE;
          {$IFDEF _DEBUG_}
              DebugOut(Level, 'AMQP_FRAME_METHOD step into amqp.framming:: amqp_decode_method==>');
          {$ENDIF}
          res := amqp_decode_method(Adecoded_frame.payload.method.id,
                                   channel_pool, encoded,
                                   Adecoded_frame.payload.method.decoded);
          {$IFDEF _DEBUG_}
              DebugOut(Level, 'AMQP_FRAME_METHOD step over amqp.framming:: amqp_decode_method, res=' + IntToStr(res));
          {$ENDIF}
          if res < 0 then
            Exit(res);
        end;

        AMQP_FRAME_HEADER:
        begin
          Adecoded_frame.payload.properties.class_id := amqp_d16(amqp_offset(raw_frame, HEADER_SIZE));
          { unused 2-byte weight field goes here }
          Adecoded_frame.payload.properties.body_size := amqp_d64(amqp_offset(raw_frame, HEADER_SIZE + 4));
          encoded.bytes := amqp_offset(raw_frame, HEADER_SIZE + 12);
          encoded.len := Astate.target_size - HEADER_SIZE - 12 - FOOTER_SIZE;
          Adecoded_frame.payload.properties.raw := encoded;
          {$IFDEF _DEBUG_}
              DebugOut(Level, 'AMQP_FRAME_HEADER step into amqp.framming:: amqp_decode_properties==>');
          {$ENDIF}
          res := amqp_decode_properties(Adecoded_frame.payload.properties.class_id,
                                        channel_pool, encoded,
                                        @Adecoded_frame.payload.properties.decoded);
          {$IFDEF _DEBUG_}
              DebugOut(Level, 'AMQP_FRAME_HEADER step over amqp.framming:: amqp_decode_properties, res=' + IntToStr(res));
          {$ENDIF}
          if res < 0 then
            Exit(res);
        end;

        AMQP_FRAME_BODY:
        begin
          Adecoded_frame.payload.body_fragment.len := Astate.target_size - HEADER_SIZE - FOOTER_SIZE;
          Adecoded_frame.payload.body_fragment.bytes := amqp_offset(raw_frame, HEADER_SIZE);
        end;
        AMQP_FRAME_HEARTBEAT:
        begin
          //
        end;
        else
        begin
          { Ignore the frame }
          Adecoded_frame.frame_type := 0;
        end;
      end;
      return_to_idle(Astate);
      Exit(int(bytes_consumed)) ;
    end;
    else
      raise Exception.Create('Internal error: invalid amqp_connection_state_t.state '
        + IntToStr(Int(Astate.state)));
  end;
end;

function amqp_new_connection:Pamqp_connection_state;
var
  res       : integer;
  state     : Pamqp_connection_state;
  label out_nomem;

begin
  state := Pamqp_connection_state(AllocMem(1* sizeof(Tamqp_connection_state)));
  if state = nil then
    Exit(nil);

  res := amqp_tune_connection(state, 0, AMQP_INITIAL_FRAME_POOL_PAGE_SIZE, 0);
  if 0 <> res then
     goto out_nomem;

  state.inbound_buffer.bytes := @state.header_buffer;
  state.inbound_buffer.len := sizeof(state.header_buffer);
  state.state := CONNECTION_STATE_INITIAL;
  { the server protocol version response is 8 bytes, which conveniently
     is also the minimum frame size }
  state.target_size := 8;
  state.sock_inbound_buffer.len := AMQP_INITIAL_INBOUND_SOCK_BUFFER_SIZE;
  state.sock_inbound_buffer.bytes := malloc(AMQP_INITIAL_INBOUND_SOCK_BUFFER_SIZE);
  if state.sock_inbound_buffer.bytes = nil then
     goto out_nomem;

  //init_amqp_pool(@state.properties_pool, 512);
  state.properties_pool.Create(512);
  { Use address of the internal_handshake_timeout object by default. }
  state.internal_handshake_timeout.tv_sec := AMQP_DEFAULT_LOGIN_TIMEOUT_SEC;
  state.internal_handshake_timeout.tv_usec := 0;
  state.handshake_timeout := @state.internal_handshake_timeout;
  Exit(state);
out_nomem:
  free(state.sock_inbound_buffer.bytes);
  free(state);
  Result := nil;
end;


procedure amqp_set_sockfd( state : Pamqp_connection_state; sockfd : integer);
var
  socket : Pamqp_socket;
begin
  socket := amqp_tcp_socket_new(state);
  if  not Assigned(socket) then
    //amqp_abort('%s', strerror(errno));
    raise Exception.Create('CRAETE new socket error!!!');

  amqp_tcp_socket_set_sockfd(socket, sockfd);
end;


procedure ENFORCE_STATE( statevec : Pamqp_connection_state; statenum : Tamqp_connection_state_enum);
var
    _check_state  : Pamqp_connection_state;
    _wanted_state : Tamqp_connection_state_enum;
    s: string;
begin
    _check_state := (statevec);
    _wanted_state := (statenum);
    if _check_state.state <> _wanted_state then
    begin
      s := Format('Programming error: invalid AMQP connection state: expected %d, '+
          'got %d',
          [Int(_wanted_state), Int(_check_state.state)]);
      raise Exception.Create(s);
    end;
end;


function amqp_tune_connection( state : Pamqp_connection_state; channel_max, frame_max, heartbeat : integer):integer;
var
  newbuf : Pointer;
  res : integer;
begin
  ENFORCE_STATE(state, CONNECTION_STATE_IDLE);
  state.channel_max := channel_max;
  state.frame_max := frame_max;
  state.heart_beat := heartbeat;
  if 0 > state.heart_beat then
    state.heart_beat := 0;

  res := amqp_time_s_from_now(state.next_send_heartbeat, state.heartbeat);
  if Int(AMQP_STATUS_OK) <> res then
     Exit(res);

  res := amqp_time_s_from_now(state.next_recv_heartbeat,
                             amqp_heartbeat_recv(state));
  if Int(AMQP_STATUS_OK) <> res then
    Exit(res);

  state.outbound_buffer.len := frame_max;
  //newbuf := realloc(state.outbound_buffer.bytes, frame_max);
  reallocMem(state.outbound_buffer.bytes, frame_max);
  newbuf := state.outbound_buffer.bytes;
  if newbuf = nil then
    Exit(Int(AMQP_STATUS_NO_MEMORY));

  //state.outbound_buffer.bytes := newbuf;
  Result := Int(AMQP_STATUS_OK);
end;

function amqp_destroy_connection( state : Pamqp_connection_state):integer;
var
  status,
  i        : integer;
  entry,
  todelete : Pamqp_pool_table_entry;
begin
  status := Int(AMQP_STATUS_OK);
  if Assigned(state) then
  begin  //++i
    for i := 0 to POOL_TABLE_SIZE -1 do
    begin
      //Inc(i);
      entry := state.pool_table[i];
      while nil <> entry do
      begin
        todelete := entry;
        entry.pool.empty;
        entry := entry.next;
        free(todelete);
      end;
    end;
    free(state.outbound_buffer.bytes);

    free(state.sock_inbound_buffer.bytes);
    state.Fsocket.delete;
    state.properties_pool.empty;
    free(state);
  end;
  Result := status;
end;


procedure return_to_idle( state : Pamqp_connection_state);
begin
  state.inbound_buffer.len := sizeof(state.header_buffer);
  state.inbound_buffer.bytes := @state.header_buffer;
  state.inbound_offset := 0;
  state.target_size := HEADER_SIZE;
  state.state := CONNECTION_STATE_IDLE;
end;


function consume_data(state : Pamqp_connection_state; out received_data : Tamqp_bytes):size_t;
var
  bytes_consumed : size_t;
begin
  { how much data is available and will fit? }
  bytes_consumed := state.target_size - state.inbound_offset;
  if received_data.len < bytes_consumed then
     bytes_consumed := received_data.len;

  //此句执行后导致state.Fsock不可访问
  memcpy(amqp_offset(state.inbound_buffer.bytes, state.inbound_offset), received_data.bytes, bytes_consumed);
  state.inbound_offset  := state.inbound_offset + bytes_consumed;
  //received_data.bytes :=
  Inc(received_data.bytes, bytes_consumed);
  received_data.len  := received_data.len - bytes_consumed;
  Result := bytes_consumed;
end;


function amqp_release_buffers_ok( state : Pamqp_connection_state):amqp_boolean_t;
begin
  if (state.state = CONNECTION_STATE_IDLE) then
    Result := 1
  else
    Result := 0;
end;


procedure amqp_release_buffers( state : Pamqp_connection_state);
var
  i : integer;
  Lentry : Pamqp_pool_table_entry;
begin
  ENFORCE_STATE(state, CONNECTION_STATE_IDLE);
  for i := 0 to POOL_TABLE_SIZE-1 do
  begin
    Lentry := state.pool_table[i];
    While nil <> Lentry do
    begin
      amqp_maybe_release_buffers_on_channel(state, Lentry.channel);
      Lentry := Lentry.next;
    end;
  end;
end;

procedure amqp_maybe_release_buffers( state : Pamqp_connection_state);
begin
  if amqp_release_buffers_ok(state) > 0 then
     amqp_release_buffers(state);

end;


procedure amqp_maybe_release_buffers_on_channel( state : Pamqp_connection_state; channel : amqp_channel_t);
var
    queued_link : Pamqp_link;
    pool        : Pamqp_pool;
    frame       : Pamqp_frame;
begin
  if CONNECTION_STATE_IDLE <> state.state then
     exit;

  queued_link := state.first_queued_frame;
  while nil <> queued_link do
  begin
    frame := queued_link.data;
    if channel = frame.channel then
       Exit;

    queued_link := queued_link.next;
  end;

  pool := state.get_channel_pool(channel);
  if pool <> nil then
     pool.recycle;

end;


function amqp_frame_to_bytes(const Aframe : Tamqp_frame; Abuffer : Tamqp_bytes;
                             out Aencoded : Tamqp_bytes):integer;
var
    Lout_frame          : PAMQPChar;
    Lout_frame_len      : size_t;
    Lres ,Level               : integer;
    Lproperties_encoded,
    Lmethod_encoded     : Tamqp_bytes;
    Lbody               : Tamqp_bytes;

begin
  Inc(gLevel);
  Level := gLevel;
  Lout_frame := Abuffer.bytes;
  amqp_e8(Aframe.frame_type, amqp_offset(Lout_frame, 0));
  amqp_e16(Aframe.channel, amqp_offset(Lout_frame, 1));
  case Aframe.frame_type of
    AMQP_FRAME_BODY:
    begin
      {$IFDEF _DEBUG_}
           DebugOut(Level,  ' frame_type = AMQP_FRAME_BODY');
      {$ENDIF}

      Lbody := Aframe.payload.body_fragment;
      memcpy(amqp_offset(Lout_frame, HEADER_SIZE), Lbody.bytes, Lbody.len);
      Lout_frame_len := Lbody.len;

    end;

    AMQP_FRAME_METHOD:
    begin
      {$IFDEF _DEBUG_}
           DebugOut(Level,  ' frame_type = AMQP_FRAME_METHOD');
      {$ENDIF}
      amqp_e32(Aframe.payload.method.id, amqp_offset(Lout_frame, HEADER_SIZE));
      Lmethod_encoded.bytes := amqp_offset(Lout_frame, HEADER_SIZE + 4);
      Lmethod_encoded.len := Abuffer.len - HEADER_SIZE - 4 - FOOTER_SIZE;
      Lres := amqp_encode_method(Aframe.payload.method.id,
                                 Aframe.payload.method.decoded, Lmethod_encoded);
      if Lres < 0 then
        Exit(Lres);

      Lout_frame_len := Lres + 4;

    end;

    AMQP_FRAME_HEADER:
    begin
      {$IFDEF _DEBUG_}
           DebugOut(Level,  ' frame_type = AMQP_FRAME_HEADER');
      {$ENDIF}
      amqp_e16(Aframe.payload.properties.class_id,
               amqp_offset(Lout_frame, HEADER_SIZE));
      amqp_e16(0, amqp_offset(Lout_frame, HEADER_SIZE + 2)); { 'weight' }
      amqp_e64(Aframe.payload.properties.body_size,
               amqp_offset(Lout_frame, HEADER_SIZE + 4));
      Lproperties_encoded.bytes := amqp_offset(Lout_frame, HEADER_SIZE + 12);
      Lproperties_encoded.len := Abuffer.len - HEADER_SIZE - 12 - FOOTER_SIZE;
      Lres := amqp_encode_properties(Aframe.payload.properties.class_id,
                                   Aframe.payload.properties.decoded,
                                   Lproperties_encoded);
      if Lres < 0 then
        Exit(Lres);

      Lout_frame_len := Lres + 12;

    end;
    AMQP_FRAME_HEARTBEAT:
    begin
      {$IFDEF _DEBUG_}
           DebugOut(Level,  ' frame_type = AMQP_FRAME_HEARTBEAT');
      {$ENDIF}
      Lout_frame_len := 0;
    end;

    else
      Exit(Int(AMQP_STATUS_INVALID_PARAMETER));
  end;

  amqp_e32(uint32_t(Lout_frame_len), amqp_offset(Lout_frame, 3));
  amqp_e8(AMQP_FRAME_END, amqp_offset(Lout_frame, HEADER_SIZE + Lout_frame_len));
  Aencoded.bytes := Lout_frame;
  Aencoded.len := Lout_frame_len + HEADER_SIZE + FOOTER_SIZE;
  Result := Int(AMQP_STATUS_OK);
end;


function amqp_send_frame(Astate : Pamqp_connection_state;const Aframe : Pamqp_frame):integer;
begin
  Result := amqp_send_frame_inner(Astate, Aframe^, Int(AMQP_SF_NONE), Tamqp_time.infinite);
end;

initialization


end.
