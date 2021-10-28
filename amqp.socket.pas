unit amqp.socket;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$INCLUDE  config.inc}
interface
uses  AMQP.Types, amqp.time, amqp.framing,  amqp.mem,  amqp.table,
      amqp.privt,
      {$IFNDEF FPC}
          {$IFDEF _WIN32}
            Net.Winsock2, Net.Wship6,
         {$ELSE}
            Net.SocketAPI,
         {$ENDIF} Vcl.Dialogs, System.SysUtils;
      {$ELSE}
         winsock2, JwaWS2tcpip, SysUtils;
      {$ENDIF}


  function amqp_try_recv( state : Pamqp_connection_state):integer;
  function amqp_try_send(Astate : Pamqp_connection_state;const Abuf: Pointer; Alen : size_t; Adeadline : Tamqp_time; Aflags : integer):ssize_t;
  //function amqp_send_method(state : Pamqp_connection_state; channel : amqp_channel_t; id : amqp_method_number_t;decoded: Pointer):integer;
  function amqp_send_method_inner(Astate : Pamqp_connection_state;
                                  Achannel : amqp_channel_t;
                                  Aid : amqp_method_number_t;Adecoded: Pointer;
                                  Aflags : integer; Adeadline : Tamqp_time):integer;

  function amqp_id_in_reply_list(expected : amqp_method_number_t;list : Tamqp_methods): Integer;
  function amqp_get_rpc_reply( state : Pamqp_connection_state): Tamqp_rpc_reply;

  function amqp_open_socket_noblock(const Ahostname: PAnsiChar; Aportnumber : integer;const Atimeout : PTimeval):integer;
  function amqp_open_socket_inner(const Ahostname: PAnsiChar; Aportnumber : integer; Adeadline : Tamqp_time):integer;

  function amqp_poll( Afd, Aevent : integer; Adeadline : Tamqp_time):integer;
  function do_poll( Astate : Pamqp_connection_state; var Ares : ssize_t; Adeadline : Tamqp_time):ssize_t;
  function send_header_inner( state : Pamqp_connection_state; deadline : Tamqp_time):integer;

  function amqp_queue_frame(state : Pamqp_connection_state;frame : Pamqp_frame):integer;
  function amqp_put_back_frame(state : Pamqp_connection_state;frame : Pamqp_frame):integer;


  function sasl_mechanism_in_list( mechanisms : Tamqp_bytes; method : Tamqp_sasl_method_enum):integer;
  function sasl_method_name( method : Tamqp_sasl_method_enum):Tamqp_bytes;

  function amqp_merge_capabilities(const base, add: Pamqp_table; out Aresult : Tamqp_table; pool : Pamqp_pool):integer;

  function amqp_create_link_for_frame(Astate : Pamqp_connection_state;Aframe : Pamqp_frame):Pamqp_link;
  function amqp_os_socket_close(sockfd: int): int;

  function amqp_os_socket_error:integer;

  function wait_frame_inner(Astate : Pamqp_connection_state;out Adecoded_frame : Tamqp_frame; Atimeout_deadline : Tamqp_time):integer;
  function recv_with_timeout( Astate : Pamqp_connection_state; Atimeout : Tamqp_time):integer;

  function amqp_simple_wait_frame_on_channel(Astate : Pamqp_connection_state;
                    Achannel : amqp_channel_t;out Adecoded_frame : Tamqp_frame):integer;

  function amqp_simple_rpc_decoded(Astate : Pamqp_connection_state;
                                   const Achannel : amqp_channel_t;
                                   const Arequest_id, Areply_id : amqp_method_number_t;
                                   Adecoded_request_method: Pointer): Pointer;
  function simple_rpc_inner(state : Pamqp_connection_state;
                            const channel : amqp_channel_t;
                            const request_id : amqp_method_number_t;
                            const expected_reply_ids : Tamqp_methods;
                            decoded_request_method: Pointer;
                            const deadline: Tamqp_time):Tamqp_rpc_reply;

  function amqp_simple_rpc(state : Pamqp_connection_state;
                           channel : amqp_channel_t;
                           request_id : amqp_method_number_t;
                           expected_reply_ids : Tamqp_methods;
                           decoded_request_method: Pointer):Tamqp_rpc_reply;

  function amqp_login_inner(state : Pamqp_connection_state; const vhost: PAnsiChar;
                            channel_max, frame_max, heartbeat : integer;
                            const client_properties : Pamqp_table;
                            const timeout: Ptimeval;
                            sasl_method : Tamqp_sasl_method_enum;
                            vl : Tva_list):Tamqp_rpc_reply;

  function simple_wait_method_inner(Astate : Pamqp_connection_state;
                                  Aexpected_channel : amqp_channel_t;
                                  Aexpected_method : amqp_method_number_t;
                                  Adeadline : Tamqp_time;
                                  out Aoutput : Tamqp_method):integer;
  function amqp_simple_wait_method_list(state : Pamqp_connection_state;
                                      expected_channel : amqp_channel_t;
                                      expected_methods : Tamqp_methods;//Pamqp_method_number_t;
                                      deadline : Tamqp_time;
                                      out output : Tamqp_method):integer;
  function amqp_simple_wait_frame_noblock(Astate : Pamqp_connection_state;
                         out Adecoded_frame : Tamqp_frame;
                         const Atimeout: Ptimeval):integer;
  function sasl_response(Apool : Pamqp_pool;
                       Amethod : Tamqp_sasl_method_enum;
                       Aargs : Tva_list): Tamqp_bytes;

  function amqp_login( state : Pamqp_connection_state;
                       const vhost: PAnsiChar;
                       channel_max, frame_max, heartbeat : integer;
                       sasl_method : Tamqp_sasl_method_enum;
                       vl : Tva_list): Tamqp_rpc_reply;

  function initializeWinsockIfNecessary: integer;

  var
  called_wsastartup: int;
  _haveInitializedWinsock, ErrNo: integer;
   hWinSockDll : THandle = 0; // WS2_32.DLL handle

 const
    WS_VERSION_CHOICE1 = $202; {*MAKEWORD(2,2)*}
    WS_VERSION_CHOICE2 = $101; {*MAKEWORD(1,1)*}
    AMQP_HEADER: array[0..7] of uint8_t = ( Ord('A'),
                                            Ord('M'),
                                            Ord('Q'),
                                            Ord('P'),
                                            0,
                                            AMQP_PROTOCOL_VERSION_MAJOR,
                                            AMQP_PROTOCOL_VERSION_MINOR,
                                            AMQP_PROTOCOL_VERSION_REVISION);
implementation

uses amqp.connection;
{$IFDEF FPC}
procedure InitializeWinSock;
var
  LData: TWSAData;
  LError: DWORD;
begin
  if hWinSockDll = 0 then begin
    hWinSockDll := SafeLoadLibrary('WS2_32.DLL');
    if hWinSockDll <> 0 then begin
      LError := WSAStartup($202, LData);
      if LError = 0 then begin
        Exit;
      end;
      FreeLibrary(hWinSockDll);
      hWinSockDll := 0;
    end else begin
      LError := winsock2.WSAGetLastError;
    end;
    raise Exception.Create(Format('Winsock Error %d', [LError]));
  end;
end;
{$ENDIF}

function initializeWinsockIfNecessary():integer;
var
  _wsadata : TWSAData;
begin
  { We need to call an initialization routine before
   * we can do anything with winsock.  (How fucking lame!):
   }
   InitializeWinSock();
   //if not InitSocketInterface('') then
     // Exit;
  if   _haveInitializedWinsock < 1 then
  begin
    if (WSAStartup(WS_VERSION_CHOICE1, _wsadata) <> 0) and
       (WSAStartup(WS_VERSION_CHOICE2, _wsadata) <> 0) then
    begin
      Result := 0; { error in initialization }
    end;
    if (_wsadata.wVersion <> WS_VERSION_CHOICE1)  and
       (_wsadata.wVersion <> WS_VERSION_CHOICE2) then
    begin
        WSACleanup();
        Result := 0; { desired Winsock version was not available }
    end;
    _haveInitializedWinsock := 1;
  end;
  Result := 1;
end;

function amqp_queue_frame(state : Pamqp_connection_state;frame : Pamqp_frame):integer;
var
  link : Pamqp_link;
begin
  link := amqp_create_link_for_frame(state, frame);
  if nil = link then
    Exit(Int(AMQP_STATUS_NO_MEMORY));

  if nil = state.first_queued_frame then
    state.first_queued_frame := link
  else
    state.last_queued_frame.next := link;

  link.next := nil;
  state.last_queued_frame := link;
  Result := Int(AMQP_STATUS_OK);
end;

function amqp_send_method_inner(Astate : Pamqp_connection_state;
                                Achannel : amqp_channel_t; Aid : amqp_method_number_t;
                                Adecoded: Pointer; Aflags : integer;
                                Adeadline : Tamqp_time):integer;
var
  Lframe : Tamqp_frame;
  Level: int;
begin
  Lframe.frame_type := AMQP_FRAME_METHOD;
  Lframe.channel := Achannel;
  Lframe.payload.method.id := Aid;
  Lframe.payload.method.decoded := Adecoded;
  Inc(gLevel);
  Level := gLevel;
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step into amqp.connection:: amqp_send_frame_inner==>');
  {$ENDIF}

  Result := amqp_send_frame_inner(Astate, Lframe, Aflags, Adeadline);
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step over amqp.connection:: amqp_send_frame_inner, res=' + IntToStr(Result));
  {$ENDIF}
end;

function amqp_login( state : Pamqp_connection_state;
                     const vhost: PAnsiChar;
                     channel_max, frame_max, heartbeat : integer;
                     sasl_method : Tamqp_sasl_method_enum;
                     vl : Tva_list): Tamqp_rpc_reply;

begin
  {$IFDEF _DEBUG_}
     Writeln('step into amqp.socket:: amqp_login_inner=>');
  {$ENDIF}
  Result := amqp_login_inner(state, vhost, channel_max, frame_max, heartbeat,
                         @amqp_empty_table, state.handshake_timeout,
                         sasl_method, vl);
  gLevel := 1;
  {$IFDEF _DEBUG_}
     Writeln('step over amqp.socket::amqp_login_inner!');
  {$ENDIF}
end;

procedure StringToArray(const Source: AnsiString; Dest: PAnsiChar);
var
  i: Integer;
begin

  for I := 1 to Length(Source) do
      Dest[i-1] := Source[i];

end;

function sasl_response(Apool : Pamqp_pool;
                       Amethod : Tamqp_sasl_method_enum;
                       Aargs : Tva_list): Tamqp_bytes;
var
    response     : Tamqp_bytes;
    username     : PAnsiChar;
    username_len : size_t;
    password     : PAnsiChar;
    password_len : size_t;
    response_buf : PAMQPChar;
    identity     : PAnsiChar;
    identity_len,
    len          : size_t;
    s: string;
    responseStr: AnsiString;
    I :Integer;
begin
  {$POINTERMATH ON}
  case Amethod of
    AMQP_SASL_METHOD_PLAIN:
    begin
      username := Aargs.username;
      username_len := Length(username);
      password := Aargs.password;
      password_len := Length(password);
      len := username_len + password_len + 2;
      Apool.alloc_bytes( len, response);
      if not Assigned(response.bytes) then { We never request a zero-length block, because of the +2
         above, so a nil here really is ENOMEM. }
         Exit(response);


      response.bytes[0] := 0;
      //Inc(response.bytes , 1);
      //memcpy(response.bytes, username, username_len);
      move(username[0], response.bytes[1], username_len);
      response.bytes[username_len + 1] := 0;
      //Inc(response.bytes , username_len + 2);
      //memcpy(response.bytes, password, password_len);
      move(password[0], response.bytes[username_len + 2], password_len);

      //SetString(UnicodeStr, PWideChar(@ByteArray[0]), Length(ByteArray) div 2);
      SetString(s, PAnsiChar(@response.bytes[0]), Len);

      //strpcopy(PAnsiChar(response.bytes), responseStr);


    end;

    AMQP_SASL_METHOD_EXTERNAL:
    begin
      identity := Aargs.identity;
      identity_len := Length(identity);
      Apool.alloc_bytes( identity_len, response);
      if response.bytes = nil then
        Exit(response);

      memcpy(response.bytes, identity, identity_len);

    end;
    else
    begin
      s := Format('Invalid SASL method: %d', [int(Amethod)]);
      raise Exception.Create(s);
    end;
  end;
  Result := response;
  {$POINTERMATH OFF}
end;

function amqp_simple_wait_frame_noblock(Astate : Pamqp_connection_state;
                         out Adecoded_frame : Tamqp_frame;
                         const Atimeout: Ptimeval):integer;
var
    Ldeadline : Tamqp_time;
    Lres      : integer;
    Lf        : Pamqp_frame;
begin

  Lres := amqp_time_from_now(Ldeadline, Atimeout);
  if Int(AMQP_STATUS_OK) <> Lres then
     Exit(Lres);

  if Astate.first_queued_frame <> nil then
  begin
    Lf := Pamqp_frame(Astate.first_queued_frame.data);
    Astate.first_queued_frame := Astate.first_queued_frame.next;
    if Astate.first_queued_frame = nil then
      Astate.last_queued_frame := nil;

    Adecoded_frame := Lf^;
    Exit(Int(AMQP_STATUS_OK));
  end
  else
  begin
  {$IFDEF _DEBUG_}
      DebugOut(5,  'step into amqp.socket:: wait_frame_inner==>');
  {$ENDIF}
      gLevel := 5;
      Result := wait_frame_inner(Astate, Adecoded_frame, Ldeadline);
  {$IFDEF _DEBUG_}
      DebugOut(5,  'step over amqp.socket::wait_frame_inner, res=' + IntToStr(Result));
  {$ENDIF}
  end;

end;

function amqp_simple_wait_method_list(state : Pamqp_connection_state;
                                      expected_channel : amqp_channel_t;
                                      expected_methods : Tamqp_methods;//Pamqp_method_number_t;
                                      deadline : Tamqp_time;
                                      out output : Tamqp_method):integer;
var
  Lframe : Tamqp_frame;
  Ltv : Ttimeval;
  Ltvp : Ptimeval;
  Lres, ret : integer;
begin
  Lres := amqp_time_tv_until(deadline, @Ltv, @Ltvp);
  if Lres <> Int(AMQP_STATUS_OK) then
     Exit(Lres);


  {$IFDEF _DEBUG_}
      DebugOut(4,  'step into amqp.socket:: amqp_simple_wait_frame_noblock==>');
  {$ENDIF}
  Lres := amqp_simple_wait_frame_noblock(state, Lframe, Ltvp);
  {$IFDEF _DEBUG_}
      DebugOut(4,  'step over amqp.socket::amqp_simple_wait_frame_noblock, res=' + IntToStr(Lres));
  {$ENDIF}
  if Int(AMQP_STATUS_OK) <> Lres then
     Exit(Lres);

  ret := amqp_id_in_reply_list(Lframe.payload.method.id, expected_methods );
  if (AMQP_FRAME_METHOD <> Lframe.frame_type)  or
     (expected_channel <> Lframe.channel)  or
     (0 = ret) then
    Exit(Int(AMQP_STATUS_WRONG_METHOD));

  output := Lframe.payload.method;
  Result := Int(AMQP_STATUS_OK);
end;


function simple_wait_method_inner(Astate : Pamqp_connection_state;
                                  Aexpected_channel : amqp_channel_t;
                                  Aexpected_method : amqp_method_number_t;
                                  Adeadline : Tamqp_time;
                                  out Aoutput : Tamqp_method):integer;
var
  Lexpected_methods : Tamqp_methods;//array[0..1] of amqp_method_number_t;
begin

  SetLength(Lexpected_methods, 2);
  Lexpected_methods[0] := Aexpected_method;
  Lexpected_methods[1] := 0;


  {$IFDEF _DEBUG_}
      DebugOut(3,  'expected_method:' + IntToStr(Aexpected_method));
      DebugOut(3,  'step into amqp.socket:: amqp_simple_wait_method_list==>');
  {$ENDIF}
  Result := amqp_simple_wait_method_list(Astate, Aexpected_channel, Lexpected_methods,
                                      Adeadline, Aoutput);
   SetLength(Lexpected_methods, 0);
  {$IFDEF _DEBUG_}
      DebugOut(3,  'step over amqp.socket:: amqp_simple_wait_method_list, result=' + IntToStr(Result));
  {$ENDIF}
end;

function send_header_inner( state : Pamqp_connection_state; deadline : Tamqp_time):integer;
var
  res : ssize_t;
begin
  res := amqp_try_send(state, @AMQP_HEADER, sizeof(AMQP_HEADER), deadline, Int(AMQP_SF_NONE));
  if sizeof(AMQP_HEADER)  = res then
     Exit(Int(AMQP_STATUS_OK));

  Result := int(res);
end;

function amqp_login_inner(state : Pamqp_connection_state; const vhost: PAnsiChar;
                channel_max, frame_max, heartbeat : integer;
                const client_properties : Pamqp_table;const timeout: Ptimeval;
                sasl_method : Tamqp_sasl_method_enum; vl : Tva_list):Tamqp_rpc_reply;
var
    res                       : integer;
    Lmethod                   : Tamqp_method;
    client_channel_max        : uint16;
    client_frame_max          : uint32;
    client_heartbeat,
    server_channel_max        : uint16;
    server_frame_max          : uint32;
    server_heartbeat          : uint16;

    Ldeadline                  : Tamqp_time;
    default_properties        : array[0..5] of Tamqp_table_entry;
    default_table             : Tamqp_table;
    client_capabilities       : array[0..1] of Tamqp_table_entry;
    client_capabilities_table : Tamqp_table;
    channel_pool              : Pamqp_pool;
    response_bytes            : Tamqp_bytes;
    expected                  : Tamqp_methods;
    replies                   : Tamqp_methods ;
    start: Pamqp_connection_start;
    ret: int;
    start_ok: Tamqp_connection_start_ok;
    tune : Pamqp_connection_tune;
    tune_ok: Tamqp_connection_tune_ok;
    open: Tamqp_connection_open;

    label error_res;
    label _out;
begin
   {$POINTERMATH ON}
   gLevel := 2;
  if (channel_max < 0)  or  (channel_max > UINT16_MAX) then
    Exit(amqp_rpc_reply_error(AMQP_STATUS_INVALID_PARAMETER));

  client_channel_max := uint16_t(channel_max);
  if frame_max < 0 then
    Exit(amqp_rpc_reply_error(AMQP_STATUS_INVALID_PARAMETER));

  client_frame_max := uint32_t(frame_max);
  if (heartbeat < 0)  or  (heartbeat > UINT16_MAX) then
    Exit(amqp_rpc_reply_error(AMQP_STATUS_INVALID_PARAMETER));

  client_heartbeat := uint16_t(heartbeat);
  res := amqp_time_from_now(Ldeadline, timeout);
  if Int(AMQP_STATUS_OK) <> res then
      goto error_res;

  {$IFDEF _DEBUG_}
      DebugOut(2,  'step into amqp.socket:: send_header_inner==>');
  {$ENDIF}
  res := send_header_inner(state, Ldeadline);
  {$IFDEF _DEBUG_}
      DebugOut(2,  'step over amqp.socket::send_header_inner: res=' + IntToStr(res));
  {$ENDIF}
  if Int(AMQP_STATUS_OK) <> res then
     goto error_res;

  {$IFDEF _DEBUG_}
      DebugOut(2,  'step over amqp.socket::simple_wait_method_inner==>');
  {$ENDIF}
  res := simple_wait_method_inner(state, 0, AMQP_CONNECTION_START_METHOD,
                                 Ldeadline, Lmethod);
  {$IFDEF _DEBUG_}
      DebugOut(2,  'step over amqp.socket::simple_wait_method_inner: res=' + IntToStr(res));
  {$ENDIF}
  if Int(AMQP_STATUS_OK) <> res then
     goto error_res;

  begin
    start := Pamqp_connection_start(Lmethod.decoded);
    if (start.version_major <> AMQP_PROTOCOL_VERSION_MAJOR)   or
        (start.version_minor <> AMQP_PROTOCOL_VERSION_MINOR) then
      res := Int(AMQP_STATUS_INCOMPATIBLE_AMQP_VERSION);

    {$IFDEF _DEBUG_}
       Writeln;
       DebugOut(2,  'begin amqp_connection_start......');
       DebugOut(2,  'step into amqp.socket:: amqp_table_clone==>');
    {$ENDIF}
    res := start.server_properties.clone( state.server_properties,
                            @state.properties_pool);
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::amqp_table_clone: res=' + IntToStr(res));
    {$ENDIF}
    if Int(AMQP_STATUS_OK) <> res then
       goto error_res;


    { TODO: check that our chosen SASL mechanism is in the list of
       acceptable mechanisms. Or even let the application choose from
       the list! }
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step into amqp.socket:: sasl_mechanism_in_list==>');
    {$ENDIF}
     ret := sasl_mechanism_in_list(start.mechanisms, sasl_method);
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::sasl_mechanism_in_list: ret=' + IntToStr(ret));
    {$ENDIF}
    if  0>=ret  then
      res := Int(AMQP_STATUS_BROKER_UNSUPPORTED_SASL_METHOD);

  end;

  begin

    {$IFDEF _DEBUG_}
       Writeln;
       DebugOut(2,  'begin amqp_connection_start_ok......');
       DebugOut(2,  'step into amqp.socket:: amqp_get_or_create_channel_pool==>');
    {$ENDIF}

    channel_pool := state.get_or_create_channel_pool(0);
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::amqp_get_or_create_channel_pool');
    {$ENDIF}
    if nil = channel_pool then
      res := Int(AMQP_STATUS_NO_MEMORY);

    {$IFDEF _DEBUG_}
       DebugOut(2,  'step into amqp.socket:: sasl_response==>');
    {$ENDIF}
    response_bytes := sasl_response(channel_pool, sasl_method, vl);
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::sasl_response, len=' + IntToStr(response_bytes.len));
    {$ENDIF}
    if response_bytes.bytes = nil then
      res := Int(AMQP_STATUS_NO_MEMORY);

    client_capabilities[0] := Tamqp_table_entry.Create('authentication_failure_close', 1);
    client_capabilities[1] := Tamqp_table_entry.Create('exchange_exchange_bindings', 1);
    client_capabilities_table.entries := @client_capabilities;
    client_capabilities_table.num_entries := Round(sizeof(client_capabilities) / sizeof(Tamqp_table_entry));

    default_properties[0] := Tamqp_table_entry.Create('product', 'rabbitmq-c');
    default_properties[1] := Tamqp_table_entry.Create('version', AMQP_VERSION_STRING);
    default_properties[2] := Tamqp_table_entry.Create('platform', AMQ_PLATFORM);
    default_properties[3] := Tamqp_table_entry.Create('copyright', AMQ_COPYRIGHT);
    default_properties[4] := Tamqp_table_entry.Create('information', 'See https://github.com/alanxz/rabbitmq-c');
    default_properties[5] := Tamqp_table_entry.Create('capabilities', client_capabilities_table);
    default_table.entries := @default_properties;
    //var e := default_table.entries[5];
    default_table.num_entries := Round(sizeof(default_properties) / sizeof(Tamqp_table_entry));
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step into amqp.socket:: amqp_merge_capabilities==>');
    {$ENDIF}
    res := amqp_merge_capabilities(@default_table, client_properties,
                                  state.client_properties, channel_pool);
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::amqp_merge_capabilities: res=' + IntToStr(res));
    {$ENDIF}
    if Int(AMQP_STATUS_OK) <> res then
       goto error_res;


    start_ok.client_properties := state.client_properties;
    start_ok.mechanism := sasl_method_name(sasl_method);
    start_ok.response := response_bytes;
    start_ok.locale := amqp_cstring_bytes('en_US');
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step into amqp.socket:: amqp_send_method_inner==>');
    {$ENDIF}
    gLevel := 2;
    res := amqp_send_method_inner(state, 0, AMQP_CONNECTION_START_OK_METHOD, @start_ok,
                                 Int(AMQP_SF_NONE), Ldeadline);
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::amqp_send_method_inner: res=' + IntToStr(res));
    {$ENDIF}
    if res < 0 then
       goto error_res;

  end;

  amqp_release_buffers(state);
  begin
    setLength(expected, 3);
    expected[0] := AMQP_CONNECTION_TUNE_METHOD;
    expected[1] := AMQP_CONNECTION_CLOSE_METHOD;
    expected[2] := 0;
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step into amqp.socket:: amqp_simple_wait_method_list==>');
    {$ENDIF}
    res := amqp_simple_wait_method_list(state, 0, expected, Ldeadline, Lmethod);
    setLength(expected, 0);
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::amqp_simple_wait_method_list, res=' + IntToStr(res));
    {$ENDIF}
    if Int(AMQP_STATUS_OK) <> res then
        goto error_res;

  end;

  if AMQP_CONNECTION_CLOSE_METHOD = Lmethod.id then
  begin
    result.reply_type := AMQP_RESPONSE_SERVER_EXCEPTION;
    result.reply := Lmethod;
    result.library_error := 0;
  end;

  begin
    tune := Pamqp_connection_tune(Lmethod.decoded);
    server_channel_max := tune.channel_max;
    server_frame_max := tune.frame_max;
    server_heartbeat := tune.heartbeat;
  end;

  if (server_channel_max <> 0)  and
     ( (server_channel_max < client_channel_max)  or  (client_channel_max = 0))  then  begin
    client_channel_max := server_channel_max;
  end
  else
  if (server_channel_max = 0 ) and ( client_channel_max = 0) then
    client_channel_max := UINT16_MAX;

  if (server_frame_max <> 0)  and  (server_frame_max < client_frame_max) then
    client_frame_max := server_frame_max;

  if (server_heartbeat <> 0)  and  (server_heartbeat < client_heartbeat) then
    client_heartbeat := server_heartbeat;

  {$IFDEF _DEBUG_}
       Writeln;
       DebugOut(2,  'begin amqp_connection_tune......');
       DebugOut(2,  'step into amqp.socket:: amqp_tune_connection==>');
  {$ENDIF}
  res := amqp_tune_connection(state, client_channel_max, client_frame_max,
                             client_heartbeat);
  {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::amqp_tune_connection, res=' + IntToStr(res));
  {$ENDIF}
  if res < 0 then
     goto error_res;

  begin

    tune_ok.frame_max := client_frame_max;
    tune_ok.channel_max := client_channel_max;
    tune_ok.heartbeat := client_heartbeat;
    gLevel := 2;
    {$IFDEF _DEBUG_}
       Writeln;
       DebugOut(2,  'begin amqp_connection_tune_ok......');
       DebugOut(2,  'step into amqp.socket:: amqp_send_method_inner==>');
    {$ENDIF}
    gLevel := 2;
    res := amqp_send_method_inner(state, 0, AMQP_CONNECTION_TUNE_OK_METHOD, @tune_ok,
                                 Int(AMQP_SF_NONE), Ldeadline);
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::amqp_send_method_inner: res=' + IntToStr(res));
    {$ENDIF}
    if res < 0 then
       goto error_res;

  end;

  amqp_release_buffers(state);

  begin
    SetLength(replies, 2);
    replies[0] := AMQP_CONNECTION_OPEN_OK_METHOD;
    replies[1] := 0;
    open.virtual_host := amqp_cstring_bytes(vhost);
    open.capabilities := amqp_empty_bytes;
    open.insist := 1;
    gLevel := 2;
    {$IFDEF _DEBUG_}
       Writeln;
       DebugOut(2,  'begin AMQP_CONNECTION_OPEN_OK_METHOD......');
       DebugOut(2,  'step into amqp.socket:: simple_rpc_inner==>');
    {$ENDIF}
    result := simple_rpc_inner(state, 0, AMQP_CONNECTION_OPEN_METHOD, replies,
                               @open, Ldeadline);
    SetLength(replies, 0);
    {$IFDEF _DEBUG_}
       DebugOut(2,  'step over amqp.socket::simple_rpc_inner');
    {$ENDIF}
    if result.reply_type <> AMQP_RESPONSE_NORMAL then
      goto _out;

  end;

  result.reply_type := AMQP_RESPONSE_NORMAL;
  result.reply.id := 0;
  result.reply.decoded := nil;
  result.library_error := 0;
  amqp_maybe_release_buffers(state);

_out:
   Exit(result);

error_res:
  state.Fsocket.close(AMQP_SC_FORCE);
  result := amqp_rpc_reply_error(Tamqp_status_enum(res));

  {$IFDEF _DEBUG_}
       Writeln('step OVER function amqp_socket_close');
       Writeln('step OVER function amqp_rpc_reply_error');
       Writeln('function amqp_login_inner return fail!');
  {$ENDIF}
  goto _out;
  {$POINTERMATH OFF}
end;

function amqp_simple_rpc(state : Pamqp_connection_state; channel : amqp_channel_t;
                         request_id : amqp_method_number_t;
                         expected_reply_ids : Tamqp_methods;
                         decoded_request_method: Pointer):Tamqp_rpc_reply;
var
    Ldeadline : Tamqp_time;
    res      : integer;
begin
  res := amqp_time_from_now(Ldeadline, state.rpc_timeout);
  if res <> Int(AMQP_STATUS_OK) then
    Exit(amqp_rpc_reply_error(Tamqp_status_enum(res)));

  Result := simple_rpc_inner(state, channel, request_id, expected_reply_ids,
                             decoded_request_method, Ldeadline);
end;


function amqp_get_rpc_reply( state : Pamqp_connection_state): Tamqp_rpc_reply;
begin
  Result := state.most_recent_api_result;
end;

function amqp_id_in_reply_list(expected : amqp_method_number_t;list : Tamqp_methods):Integer;
var
  I: Integer;
begin

  I := 0;
  while list[I] <> 0 do
  begin
    if list[I] = expected then
      Exit(1);

    Inc(I);
  end;
  Result := 0;

end;

{
function amqp_send_method(state : Pamqp_connection_state; channel : amqp_channel_t;
                          id : amqp_method_number_t;decoded: Pointer):integer;
begin
  Result := amqp_send_method_inner(state, channel, id, decoded, Int(AMQP_SF_NONE),
                                Tamqp_time.infinite());
end;
}
function simple_rpc_inner(state : Pamqp_connection_state;
                          const channel : amqp_channel_t;
                          const request_id : amqp_method_number_t;
                          const expected_reply_ids : Tamqp_methods;
                          decoded_request_method: Pointer;
                          const deadline: Tamqp_time):Tamqp_rpc_reply;
var
    Lstatus       : integer;

    Lframe        : Tamqp_frame;
    Lchannel_pool : Pamqp_pool;
    Lframe_copy   : Pamqp_frame;
    Llink         : Pamqp_link;
    count, ret, Level: int;
    label retry ;
begin
  count := 0;
  Inc(gLevel);
  Level := gLevel;
  //memset(Lresult, 0, sizeof(Lresult));
  {$IFDEF _DEBUG_}
        DebugOut(Level, 'step into amqp.socket::amqp_send_method.');
  {$ENDIF}
  Lstatus := amqp_send_method_inner(state, channel, request_id, decoded_request_method, Int(AMQP_SF_NONE),
                                     Tamqp_time.infinite());
  {$IFDEF _DEBUG_}
        DebugOut(Level, 'step over amqp.socket::amqp_send_method, status=' + IntToStr(Lstatus));
  {$ENDIF}
  if Lstatus < 0 then
     Exit(amqp_rpc_reply_error(Tamqp_status_enum(Lstatus)));

  begin
retry:
    count := count+1;
    {$IFDEF _DEBUG_}
        DebugOut(Level, 'step into amqp.socket:: wait_frame_inner, retry:' + IntToStr(count));
    {$ENDIF}
    Lstatus := wait_frame_inner(state, Lframe, deadline);
    {$IFDEF _DEBUG_}
        DebugOut(Level, 'step over amqp.socket:: wait_frame_inner, status=' + IntToStr(Lstatus));
    {$ENDIF}
    if Lstatus <> Int(AMQP_STATUS_OK) then
    begin
      if Lstatus = Int(AMQP_STATUS_TIMEOUT) then
         state.Fsocket.close( AMQP_SC_FORCE);

      Exit(amqp_rpc_reply_error(Tamqp_status_enum(Lstatus)));
    end;
    {
     * We store the frame for later processing unless it's something
     * that directly affects us here, namely a method frame that is
     * either
     *  - on the channel we want, and of the expected type, or
     *  - on the channel we want, and a channel.close frame, or
     *  - on channel zero, and a connection.close frame.
     }
     ret := amqp_id_in_reply_list(Lframe.payload.method.id, expected_reply_ids);
    if  not ( (Lframe.frame_type = AMQP_FRAME_METHOD)   and(*1*)
              ( ( (Lframe.channel = channel)  and
                  (ret > 0)  or
                  (Lframe.payload.method.id = AMQP_CHANNEL_CLOSE_METHOD)
                )
              )                                         or(*1*)
              ( (Lframe.channel = 0)  and
                (Lframe.payload.method.id = AMQP_CONNECTION_CLOSE_METHOD)
              )
            ) then
    begin
      Lchannel_pool := state.get_or_create_channel_pool(Lframe.channel);
      if nil = Lchannel_pool then
         Exit(amqp_rpc_reply_error(AMQP_STATUS_NO_MEMORY));

      Lframe_copy := Lchannel_pool.alloc( sizeof(Tamqp_frame));
      Llink       := Lchannel_pool.alloc( sizeof(Tamqp_link));
      if (Lframe_copy = nil)  or  (Llink = nil) then
         Exit(amqp_rpc_reply_error(AMQP_STATUS_NO_MEMORY));

      Lframe_copy^ := Lframe;
      Llink.next := nil;
      Llink.data := Lframe_copy;
      if state.last_queued_frame = nil then
         state.first_queued_frame := Llink
      else
        state.last_queued_frame.next := Llink;

      state.last_queued_frame := Llink;
      goto retry;
    end;

    ret := amqp_id_in_reply_list(Lframe.payload.method.id, expected_reply_ids);
    if ret > 0 then
       result.reply_type := AMQP_RESPONSE_NORMAL
    else
       result.reply_type := AMQP_RESPONSE_SERVER_EXCEPTION;

    result.reply := Lframe.payload.method;

  end;
end;

function amqp_simple_rpc_decoded(Astate : Pamqp_connection_state;
                                 const Achannel : amqp_channel_t;
                                 const Arequest_id, Areply_id : amqp_method_number_t;
                                 Adecoded_request_method: Pointer): Pointer;
var
    Ldeadline : Tamqp_time;
    Lres      : integer;
    Lreplies  : Tamqp_methods;
begin
  Lres := amqp_time_from_now(Ldeadline, Astate.rpc_timeout);
  if Lres <> Int(AMQP_STATUS_OK) then
  begin
    Astate.most_recent_api_result := amqp_rpc_reply_error(Tamqp_status_enum(Lres));
    Exit(nil);
  end;

  //AMQP_BASIC_CONSUME_OK_METHOD etc.
  SetLength(Lreplies, 2);
  Lreplies[0] := Areply_id;
  Lreplies[1] := 0;
  Astate.most_recent_api_result := simple_rpc_inner(Astate, Achannel, Arequest_id,
                                                    Lreplies, Adecoded_request_method,
                                                    Ldeadline);
  SetLength(Lreplies, 2);
  if Astate.most_recent_api_result.reply_type = AMQP_RESPONSE_NORMAL then
    Exit(Astate.most_recent_api_result.reply.decoded)
  else
    Exit(nil);

end;



function amqp_os_socket_close( sockfd : integer):integer;
begin
{$IFDEF _WIN32}
  Exit(closesocket(sockfd));
{$ELSE}
  Exit(close(sockfd));
{$ENDIF}
end;

function amqp_create_link_for_frame(Astate : Pamqp_connection_state;Aframe : Pamqp_frame):Pamqp_link;
var
    Llink         : Pamqp_link;
    Lframe_copy   : Pamqp_frame;
    Lchannel_pool : Pamqp_pool;
begin
  Lchannel_pool := Astate.get_or_create_channel_pool( Aframe.channel);
  if nil = Lchannel_pool then
    Exit(nil);

  Llink       := Lchannel_pool.alloc( sizeof(Tamqp_link));
  Lframe_copy := Lchannel_pool.alloc( sizeof(Tamqp_frame));
  if (nil = Llink)  or  (nil = Lframe_copy) then
    Exit(nil);

  //取值相等
  Lframe_copy^ := Aframe^;
  Llink.data := Lframe_copy;
  Result := Llink;
end;


function recv_with_timeout( Astate : Pamqp_connection_state; Atimeout : Tamqp_time):integer;
var
    Lres  : ssize_t;
    Lfd, count, Level   : integer;
    s: string;
    label start_recv ;
begin
   Inc(gLevel);
   Level := gLevel;
   count := 0;

start_recv:
   count := count+1;
  {$IFDEF _DEBUG_}
     DebugOut(Level,  'step into amqp.socket:: amqp_socket_recv==>, start_recv:' + IntToStr(count));
  {$ENDIF}
  Lres := Astate.Fsocket.recv(Astate.sock_inbound_buffer.bytes,
                           Astate.sock_inbound_buffer.len, 0);
  {$IFDEF _DEBUG_}
     //SetString(S, PAnsiChar(@Astate.sock_inbound_buffer.bytes[0]), Astate.sock_inbound_buffer.len);
     DebugOut(Level,  'step over amqp.socket::amqp_socket_recv, res=' + IntToStr(Lres));
     //WriteLn(Trim(S));
  {$ENDIF}
  if Lres < 0 then
  begin
    {$IFDEF _DEBUG_}
        DebugOut(Level,  'step into amqp.connection:: amqp_get_sockfd==>');
    {$ENDIF}
    Lfd := Astate.sockfd;
    {$IFDEF _DEBUG_}
        DebugOut(Level,  'step over amqp.connection::amqp_get_sockfd, fd=' + IntToStr(Lfd));
    {$ENDIF}
    if -1 = Lfd then
      Exit(Int(AMQP_STATUS_CONNECTION_CLOSED));

    case Lres of
      Int(AMQP_PRIVATE_STATUS_SOCKET_NEEDREAD):
      begin
        Lres := amqp_poll(Lfd, Int(AMQP_SF_POLLIN), Atimeout);
        {$IFDEF _DEBUG_}
          DebugOut(Level,  'AMQP_PRIVATE_STATUS_SOCKET_NEEDREAD(-4865) step over amqp.socket::amqp_poll, res=' + IntToStr(Lres));
        {$ENDIF}
      end;

      Int(AMQP_PRIVATE_STATUS_SOCKET_NEEDWRITE):
      begin
        Lres := amqp_poll(Lfd, Int(AMQP_SF_POLLOUT), Atimeout);
        {$IFDEF _DEBUG_}
          DebugOut(Level,  'AMQP_PRIVATE_STATUS_SOCKET_NEEDWRITE(-4866) step over amqp.socket::amqp_poll, res=' + IntToStr(Lres));
        {$ENDIF}
      end;
      else
        Exit(Lres);
    end;

    if Int(AMQP_STATUS_OK) = Lres then
        goto start_recv;


    Exit(Lres);
  end;  //if Lres < 0

  Astate.sock_inbound_limit := Lres;
  Astate.sock_inbound_offset := 0;

  Lres := amqp_time_s_from_now(Astate.next_recv_heartbeat, amqp_heartbeat_recv(Astate));

  if Int(AMQP_STATUS_OK) <> Lres then
    Exit(Lres);

  Result := Int(AMQP_STATUS_OK);
end;

function amqp_os_socket_error:integer;
begin
{$IFDEF _WIN32}
  Exit(WSAGetLastError());
{$ELSE}
  Exit(errno);
{$ENDIF}
end;

{
function amqp_socket_get_sockfd(Aself : Pamqp_socket):integer;
begin
  assert(Assigned(Aself));
  assert(Assigned(Aself.klass.get_sockfd));
  Result := Aself.klass.get_sockfd(Aself);
end;

function amqp_get_sockfd( Astate : Pamqp_connection_state):integer;
begin
  if Assigned(Astate.socket) then
     Result := amqp_socket_get_sockfd(Astate.socket)
  else
     Result := -1;
end;
}

function do_poll( Astate : Pamqp_connection_state; var Ares : ssize_t; Adeadline : Tamqp_time):ssize_t;
var
  Lfd : integer;
begin
  Lfd := Astate.sockfd;
  if -1 = Lfd then
    Exit(Int(AMQP_STATUS_SOCKET_CLOSED));

  case Ares of
    Int(AMQP_PRIVATE_STATUS_SOCKET_NEEDREAD):
       Ares := amqp_poll(Lfd, Int(AMQP_SF_POLLIN), Adeadline);

    Integer(AMQP_PRIVATE_STATUS_SOCKET_NEEDWRITE):
       Ares := amqp_poll(Lfd, Int(AMQP_SF_POLLOUT), Adeadline);

  end;
  Result := Ares;
end;



function amqp_try_send(Astate : Pamqp_connection_state;const Abuf: Pointer; Alen : size_t; Adeadline : Tamqp_time; Aflags : integer):ssize_t;
var
    res,count,Level   : ssize_t;
    buf_left   : Pointer;
    len_left   : ssize_t;
    label start_send;
begin
  buf_left := Abuf;
  { Assume that len is not going to be larger than ssize_t can hold. }
  len_left := size_t(Alen);
  Inc(gLevel);
  Level := gLevel;
  count := 0;

start_send:
  Inc(count);
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step into amqp.socket:: amqp_socket_send==>, start_send:' + IntToStr(Count));
  {$ENDIF}
  res := Astate.Fsocket.send(buf_left, len_left, Aflags);
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step over amqp.socket::amqp_socket_send, res=' + IntToStr(res) );
  {$ENDIF}
  if res > 0 then
  begin
    len_left  := len_left - res;
    Inc(PByte(buf_left) , res);
    if 0 = len_left then
       Exit(ssize_t(Alen));

    goto start_send;
  end;
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step into amqp.socket:: do_poll==>');
  {$ENDIF}
  res := do_poll(Astate, res, Adeadline);
  {$IFDEF _DEBUG_}
       DebugOut(Level,  'step over amqp.socket::do_poll, res=' + IntToStr(res) );
  {$ENDIF}
  if Integer(AMQP_STATUS_OK) = res then
     goto start_send;

  if Integer(AMQP_STATUS_TIMEOUT) = res then
     Exit(ssize_t(Alen) - len_left);

  Result := res;

end;


function amqp_open_socket_noblock(const Ahostname: PAnsiChar; Aportnumber : integer;const Atimeout : Ptimeval):integer;
var
    Ldeadline : Tamqp_time;
    res      : integer;
begin
  res := amqp_time_from_now(Ldeadline, Atimeout);
  if Integer(AMQP_STATUS_OK) <> res then
     Exit(res);

  Result := amqp_open_socket_inner(Ahostname, Aportnumber, Ldeadline);
end;

function connect_socket(  Aaddr: Paddrinfo; Adeadline : Tamqp_time):integer;
var
    one, ret        : integer;
    sockfd     : TSOCKET;
    last_error : integer;
    Lresult,
    result_len ,
    event      : integer;

    label err;

begin
  one := 1; //30'
  {
   * This cast is to squash warnings on Win64, see:
   * http://stackoverflow.com/questions/1953639/is-it-safe-to-cast-socket-to-int-under-win64
   }
  sockfd := socket(Aaddr.ai_family, Aaddr.ai_socktype, Aaddr.ai_protocol);
  if INVALID_SOCKET = sockfd then
    Exit(Int(AMQP_STATUS_SOCKET_ERROR));

  { Set the socket to be non-blocking }
  if SOCKET_ERROR = ioctlsocket(sockfd, FIONBIO, Cardinal(one)) then
    last_error := Int(AMQP_STATUS_SOCKET_ERROR);

  { Disable nagle }
  if SOCKET_ERROR = setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, PAnsiChar(@one), sizeof(one)) then
    last_error := Integer(AMQP_STATUS_SOCKET_ERROR);


  { Enable TCP keepalives }
  if SOCKET_ERROR = setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE, PAnsiChar(@one), sizeof(one)) then
     last_error := Integer(AMQP_STATUS_SOCKET_ERROR);
  {$IFDEF FPC}
  //sockAddr.sa_family := Aaddr.ai_addr^.sa_family;
  //sockAddr.sa_data   := Aaddr.ai_addr.sa_data;
  ret := connect(sockfd, TSockAddr(Aaddr.ai_addr^), int(Aaddr.ai_addrlen));
  {$ELSE}
  ret := connect(sockfd, Aaddr.ai_addr, int(Aaddr.ai_addrlen));
  {$ENDIF}
  if SOCKET_ERROR <> ret then
     Exit(int(sockfd));


  if WSAEWOULDBLOCK <> WSAGetLastError( ) then
  begin
    last_error := Integer(AMQP_STATUS_SOCKET_ERROR);
    goto err;
  end;

  event := Int(AMQP_SF_POLLOUT) or Int(AMQP_SF_POLLERR);
  last_error := amqp_poll(int(sockfd), event, Adeadline);
  if Integer(AMQP_STATUS_OK) <> last_error then
    goto err;

  begin
    result_len := sizeof(Lresult);
    if (SOCKET_ERROR = getsockopt(sockfd, SOL_SOCKET, SO_ERROR, PAnsiChar(@Lresult), result_len))  or
       (Lresult <> 0)  then
    begin
      last_error := Integer(AMQP_STATUS_SOCKET_ERROR);
      goto err;
    end;
  end;
  Exit(int(sockfd));
err:
  closesocket(sockfd);
  Result := last_error;
end;

function amqp_os_socket_init:integer;
var
  data : WSADATA;
  res : integer;
begin

  if called_wsastartup < 0 then
  begin
    res := WSAStartup($0202, data);
    if res > 0 then
    begin
      Exit(Integer(AMQP_STATUS_TCP_SOCKETLIB_INIT_ERROR));
    end;
    called_wsastartup := 1;
  end;
  Exit(Integer(AMQP_STATUS_OK));

end;

function amqp_open_socket_inner(const Ahostname: PAnsiChar; Aportnumber : integer; Adeadline : Tamqp_time):integer;
var
  hint              : Taddrinfo;

  address_list,
  addr1             : Paddrinfo;
  sockfd,
  last_error        : integer;
  portStr, hostStr: string;
begin
  sockfd := -1;
  last_error := amqp_os_socket_init();
  if Integer(AMQP_STATUS_OK) <> last_error then
  begin
    Exit(last_error);
  end;
  memset(hint, 0, sizeof(hint));

  hint.ai_family := PF_INET;//PF_UNSPEC; { PF_INET or PF_INET6 }
  hint.ai_socktype := SOCK_STREAM;
  hint.ai_protocol := IPPROTO_TCP;

  portStr := IntToStr(Aportnumber);
  hostStr := Ahostname;
  {$IFNDEF FPC}
  last_error := getaddrinfo(@hostStr[1], @portStr[1], @hint, @address_list);
  {$ELSE}
   last_error := getaddrinfo(@hostStr[1], @portStr[1], @hint, address_list);
  {$ENDIF}
  if 0 <> last_error then
  begin
    Exit(Integer(AMQP_STATUS_HOSTNAME_RESOLUTION_FAILED));
  end;

  addr1 := address_list;
  while addr1 <> nil do
  begin
    sockfd := connect_socket(addr1, Adeadline);
    if sockfd >= 0 then
    begin
      last_error := Integer(AMQP_STATUS_OK);
      break;
    end
    else
    if (sockfd = Integer(AMQP_STATUS_TIMEOUT)) then
    begin
      last_error := sockfd;
      break;
    end;
    addr1 := addr1.ai_next;
  end;

  {$IFDEF FPC}
  freeaddrinfo(address_list);
  {$ELSE}
  freeaddrinfo(PaddrinfoW(address_list));
  {$ENDIF}

  if (last_error <> Integer(AMQP_STATUS_OK))  or  (sockfd = -1) then
  begin
    Exit(last_error);
  end;
  Result := sockfd;
end;

//HAVE_POLL SELECT只能二选一
function amqp_poll( Afd, Aevent : integer; Adeadline : Tamqp_time):integer;
var
  {$IFDEF HAVE_POLL}
   pfd          : TWSAPOLLFD;
  {$ENDIF}
  res, err,
  timeout_ms   : integer;
  fds,
  exceptfds    : TFDSet;
  exceptfdsp   : Pfdset;
  tv           : Ttimeval;
  tvp          : Ptimeval;
  label start_select ;
  label start_poll;
begin
{$IFDEF HAVE_POLL}
  { Function should only ever be called with one of these two }
  assert((event = Int(AMQP_SF_POLLIN) ) or  (event = Int(AMQP_SF_POLLOUT)));
start_poll:
  pfd.fd := fd;
  case event of
    Int(AMQP_SF_POLLIN):
      pfd.events := POLLIN;

    Int(AMQP_SF_POLLOUT):
      pfd.events := POLLOUT;

  end;
  timeout_ms := amqp_time_ms_until(deadline);
  if -1 > timeout_ms then
    Exit(timeout_ms);

  res := WSAPoll(@pfd, 1, timeout_ms);
  if 0 < res then
    { TODO: optimize this a bit by returning the AMQP_STATUS_SOCKET_ERROR or
     * equivalent when pdf.revent is POLLHUP or POLLERR, so an extra syscall
     * doesn't need to be made. }
    Exit(Int(AMQP_STATUS_OK))
  else
  if (0 = res) then
    Exit(Int(AMQP_STATUS_TIMEOUT))
  else
  begin
    case amqp_os_socket_error() of
      EINTR:
        goto start_poll;
      else
        Exit(Int(AMQP_STATUS_SOCKET_ERROR));
    end;
  end;
  Exit(Int(AMQP_STATUS_OK));
{$ENDIF}
{$if defined(HAVE_SELECT)}
  assert((0 <> (Aevent and Int(AMQP_SF_POLLIN)))  or
         (0 <> (Aevent and Int(AMQP_SF_POLLOUT))));
{$IFNDEF _WIN32}
  { On Win32 connect() failure is indicated through the exceptfds, it does not
   * make any sense to allow POLLERR on any other platform or condition }
  assert(0 = (Aevent and AMQP_SF_POLLERR));
{$ENDIF}

start_select:
  FD_ZERO(fds);
  {$IFDEF FPC}
  FD_SET(Afd, fds);
  {$ELSE}
  FD_SET(Afd, fds);
  {$ENDIF}

  if (Aevent and Int(AMQP_SF_POLLERR))>0 then
  begin
    FD_ZERO(exceptfds);
    {$IFDEF FPC}
    FD_SET(Afd, exceptfds);
    {$ELSE}
    FD_SET(Afd, exceptfds);
    {$ENDIF}
    exceptfdsp := @exceptfds;
  end
  else
    exceptfdsp := nil;

  res := amqp_time_tv_until(Adeadline, @tv, @tvp);
  if res <> Int(AMQP_STATUS_OK) then
    Exit(res);


  if (Aevent and Int(AMQP_SF_POLLIN)) > 0 then
    res := select(Afd + 1, @fds, nil, exceptfdsp, tvp)
  else
  if (Aevent and Int(AMQP_SF_POLLOUT)) > 0 then
    res := select(Afd + 1, nil, @fds, exceptfdsp, tvp);

  if 0 < res then
    Exit(Int(AMQP_STATUS_OK))
  else
  if (0 = res) then
    Exit(Int(AMQP_STATUS_TIMEOUT))
  else
  begin
    err := amqp_os_socket_error();
    {$IFDEF _DEBUG_}
        DebugOut(0, 'amqp_os_socket_error=' + IntToStr(err));
    {$ENDIF}
    case (err) of
      WSAEINTR: goto start_select;
      else
        Exit(Int(AMQP_STATUS_SOCKET_ERROR));
    end;
  end;
{$ELSE}
   Showmessage('poll() or select() is needed to compile rabbitmq-c');
{$IFEND}

end;


function amqp_data_in_buffer( state : Pamqp_connection_state):boolean;
begin
  Result := (state.sock_inbound_offset < state.sock_inbound_limit);
end;

function consume_one_frame(state : Pamqp_connection_state;out decoded_frame : Tamqp_frame):integer;
var
  res, Level : integer;
  buffer : Tamqp_bytes;
  s: String;
begin
  Inc(gLevel);
  Level := gLevel;

  buffer.len := state.sock_inbound_limit - state.sock_inbound_offset;

  buffer.bytes := state.sock_inbound_buffer.bytes + state.sock_inbound_offset;
  SetString(s, PAnsiChar(@buffer.bytes[0]), buffer.len);
  {$IFDEF _DEBUG_}
      DebugOut(Level, 'step into amqp.connection:: amqp_handle_input==>, buffer.bytes=' + s);
  {$ENDIF}
  res := amqp_handle_input(state, buffer, decoded_frame);
  {$IFDEF _DEBUG_}
      DebugOut(Level, 'step over amqp.connection:: amqp_handle_input, res=' + IntToStr(res));
  {$ENDIF}
  if res < 0 then
    Exit(res);

  state.sock_inbound_offset  := state.sock_inbound_offset + res;
  Result := Int(AMQP_STATUS_OK);
end;

function amqp_try_recv( state : Pamqp_connection_state):integer;
var
    Ltimeout      : Tamqp_time;
    Lres          : integer;
    Lframe        : Tamqp_frame;
    Lchannel_pool : Pamqp_pool;
    Lframe_copy   : Pamqp_frame;
    Llink         : Pamqp_link;
begin
  while amqp_data_in_buffer(state) do
  begin
    Lres := consume_one_frame(state, Lframe);
    if Int(AMQP_STATUS_OK) <> Lres then
       Exit(Lres);

    if Lframe.frame_type <> 0 then
    begin
      Lchannel_pool := state.get_or_create_channel_pool(Lframe.channel);
      if nil = Lchannel_pool then
         Exit(Int(AMQP_STATUS_NO_MEMORY));

      Lframe_copy := Lchannel_pool.alloc( sizeof(Tamqp_frame));
      Llink       := Lchannel_pool.alloc( sizeof(Tamqp_link));
      if (Lframe_copy = nil)  or  (Llink = nil) then
          Exit(Int(AMQP_STATUS_NO_MEMORY));

      Lframe_copy^ := Lframe;
      Llink.next := nil;
      Llink.data := Lframe_copy;
      if state.last_queued_frame = nil then
        state.first_queued_frame := Llink
      else
         state.last_queued_frame.next := Llink;

      state.last_queued_frame := Llink;
    end;
  end;
  Lres := amqp_time_s_from_now(Ltimeout, 0);
  if Int(AMQP_STATUS_OK) <> Lres then
     Exit(Lres);

  Result := recv_with_timeout(state, Ltimeout);
end;


function amqp_put_back_frame(state : Pamqp_connection_state;frame : Pamqp_frame):integer;
var
  link : Pamqp_link;
begin
  link := amqp_create_link_for_frame(state, frame);
  if nil = link then
    Exit(Int(AMQP_STATUS_NO_MEMORY));

  if nil = state.first_queued_frame then
  begin
    state.first_queued_frame := link;
    state.last_queued_frame := link;
    link.next := nil;
  end
  else
  begin
    link.next := state.first_queued_frame;
    state.first_queued_frame := link;
  end;
  Result := Int(AMQP_STATUS_OK);
end;

function wait_frame_inner(Astate : Pamqp_connection_state;out Adecoded_frame : Tamqp_frame;
                          Atimeout_deadline : Tamqp_time):integer;
var
    Ldeadline  : Tamqp_time;
    res,count,Level  : integer;
    Lheartbeat : Tamqp_frame;
    label beginrecv ;
begin
  count := 0;
  Inc(gLevel);
  Level := gLevel;
  while True do
  begin
    while amqp_data_in_buffer(Astate) do
    begin
      {$IFDEF _DEBUG_}
          DebugOut(Level,  'step into amqp.socket:: consume_one_frame==>');
      {$ENDIF}
      res := consume_one_frame(Astate, Adecoded_frame);
      {$IFDEF _DEBUG_}
          DebugOut(Level,  'step over amqp.socket:: consume_one_frame: res=' + IntToStr(res));
      {$ENDIF}
      if Int(AMQP_STATUS_OK) <> res then
        Exit(res);

      if AMQP_FRAME_HEARTBEAT = Adecoded_frame.frame_type then
      begin
        {$IFDEF _DEBUG_}
          DebugOut(Level,  'step into amqp.socket::amqp_maybe_release_buffers_on_channel==>');
        {$ENDIF}
        amqp_maybe_release_buffers_on_channel(Astate, 0);
        {$IFDEF _DEBUG_}
          DebugOut(Level,  'step over amqp.socket::amqp_maybe_release_buffers_on_channel.');
        {$ENDIF}
        continue;
      end;
      if Adecoded_frame.frame_type <> 0 then
        { Complete frame was read. Return it. }
        Exit(Int(AMQP_STATUS_OK));

    end; //while amqp_data_in_buffer(state)

beginrecv:
    count  := count + 1;
    res := amqp_time_has_past(Astate.next_send_heartbeat);
    if Int(AMQP_STATUS_TIMER_FAILURE) = res then
       Exit(res)
    else
    if (Int(AMQP_STATUS_TIMEOUT) = res) then
    begin
      Lheartbeat.channel := 0;
      Lheartbeat.frame_type := AMQP_FRAME_HEARTBEAT;
      {$IFDEF _DEBUG_}
          DebugOut(Level,  'AMQP_STATUS_TIMEOUT step into amqp.socket:: amqp_send_frame==>');
      {$ENDIF}
      res := amqp_send_frame(Astate, @Lheartbeat);
      {$IFDEF _DEBUG_}
          DebugOut(Level,  'AMQP_STATUS_TIMEOUT step into amqp.socket::amqp.socket:: amqp_send_frame, res=' + IntToStr(res));
      {$ENDIF}
      if Int(AMQP_STATUS_OK) <> res then
        Exit(res);

    end;


    Ldeadline := amqp_time_first(Atimeout_deadline, amqp_time_first(Astate.next_recv_heartbeat, Astate.next_send_heartbeat) );
    { TODO this needs to wait for a _frame_ and not anything written from the
     * socket }
    {$IFDEF _DEBUG_}
        DebugOut(Level,  'step into amqp.socket:: recv_with_timeout==>, beginrecv:' + IntToStr(count));
    {$ENDIF}
    res := recv_with_timeout(Astate, Ldeadline);
    {$IFDEF _DEBUG_}
        DebugOut(Level,  'step over amqp.socket::amqp.socket:: recv_with_timeout: res=' + IntToStr(res));
    {$ENDIF}

    if Int(AMQP_STATUS_TIMEOUT) = res then
    begin
      if Ldeadline= Astate.next_recv_heartbeat then
      begin
        Astate.Fsocket.close(AMQP_SC_FORCE);
        Exit(Int(AMQP_STATUS_HEARTBEAT_TIMEOUT));
      end
      else
      if (Ldeadline= Atimeout_deadline) then
         Exit(Int(AMQP_STATUS_TIMEOUT))
      else
      if (Ldeadline= Astate.next_send_heartbeat) then
          goto beginrecv{ send heartbeat happens before we do recv_with_timeout }
      else
          raise Exception.Create('Internal error: unable to determine timeout reason');

    end
    else
    if (Int(AMQP_STATUS_OK) <> res) then
       exit(res);

  end; //end while True
end;

function amqp_simple_wait_frame_on_channel(Astate : Pamqp_connection_state;
           Achannel : amqp_channel_t;out Adecoded_frame : Tamqp_frame):integer;
var
    frame_ptr : Pamqp_frame;
    cur       : Pamqp_link;
    res       : integer;
begin
  cur := Astate.first_queued_frame;
  while ( nil <> cur) do
  begin
    frame_ptr := Pamqp_frame(cur.data);
    if Achannel = frame_ptr.channel then
    begin
      Astate.first_queued_frame := cur.next;
      if nil = Astate.first_queued_frame then
         Astate.last_queued_frame := nil;

      Adecoded_frame := frame_ptr^;
      Exit(Int(AMQP_STATUS_OK));
    end;
    cur := cur.next
  end;

  while True do
  begin
    res := wait_frame_inner(Astate, Adecoded_frame, Tamqp_time.infinite());
    if Int(AMQP_STATUS_OK) <> res then
      Exit(res);

    if Achannel = Adecoded_frame.channel then
      Exit(Int(AMQP_STATUS_OK))

    else
    begin
      res := amqp_queue_frame(Astate, @Adecoded_frame);
      if res <> Int(AMQP_STATUS_OK) then
        Exit(res);

    end;
  end;
end;

function sasl_method_name( method : Tamqp_sasl_method_enum):Tamqp_bytes;
var
  res : Tamqp_bytes;
  s: string;
begin
  case method of
    AMQP_SASL_METHOD_PLAIN:
      res := amqp_cstring_bytes('PLAIN');

    AMQP_SASL_METHOD_EXTERNAL:
      res := amqp_cstring_bytes('EXTERNAL');

    else
    begin
      s := Format('Invalid SASL method: %d', [int(method)]);
      raise Exception.Create(s);
    end;
  end;
  Result := res;
end;

{$IFNDEF FPC}
function memchr(const buf: Pointer; c: AnsiChar; len: size_t): Pointer;
var
  l: AnsiChar;
begin
  Result := buf;
  l := c;
  while len <> 0 do
  begin
    if PAnsiChar(Result)[0] = l then
      Exit;
    Inc(Integer(Result));
    Dec(len);
  end;
  Result := Nil;
end;
{$ELSE}
 function memchr(const buf: Pointer; c: AnsiChar; len: size_t): Pointer;
var
  l: AnsiChar;
begin
  Result := buf;
  l := c;
  while len <> 0 do
  begin
    if PAnsiChar(Result)[0] = l then
      Exit;
    Inc(PByte(Result));
    Dec(len);
  end;
  Result := Nil;
end;
{$ENDIF}

function sasl_mechanism_in_list( mechanisms : Tamqp_bytes; method : Tamqp_sasl_method_enum):integer;
var
  Lmechanism,
  Lsupported_mechanism : Tamqp_bytes;
  Lstart,
  Lend,
  Lcurrent             : PAMQPChar;
begin
  {$POINTERMATH ON}
  assert(nil <> mechanisms.bytes);
  Lmechanism := sasl_method_name(method);
  Lstart := (mechanisms.bytes);
  Lcurrent := Lstart;
  Lend := Lstart + mechanisms.len;
  while Lcurrent <> Lend do
  begin
    { HACK: SASL states that we should be parsing this string as a UTF-8
     * string, which we're plainly not doing here. At this point its not worth
     * dragging an entire UTF-8 parser for this one case, and this should work
     * most of the time }
    Lcurrent := memchr(Lstart, ' ', Lend - Lstart);
    if nil = Lcurrent then
      Lcurrent := Lend;

    Lsupported_mechanism.bytes := Lstart;
    Lsupported_mechanism.len := Lcurrent - Lstart;
    if Lmechanism = Lsupported_mechanism then
      Exit(1);

    Lstart := Lcurrent + 1;
  end;
  Result := 0;
  {$POINTERMATH OFF}
end;

function amqp_merge_capabilities(const base, add: Pamqp_table; out Aresult : Tamqp_table; pool : Pamqp_pool):integer;
var
  i, num ,
  res         : integer;
  temp_pool   : Tamqp_pool;
  temp_result : Tamqp_table;
  e,
  be          : Pamqp_table_entry;
  label  error_out ;
begin
  {$POINTERMATH ON}
  assert(base <> nil);

  assert(pool <> nil);
  if nil = add then
    Exit(base^.clone( Aresult, pool));

  //init_amqp_pool(@temp_pool, 4096);
  temp_pool.Create( 4096);
  temp_result.num_entries := 0;
  num := (base.num_entries + add.num_entries);
  temp_result.entries := temp_pool.alloc( sizeof(Tamqp_table_entry) *num );
  if nil = temp_result.entries then
  begin
    res := Int(AMQP_STATUS_NO_MEMORY);
    goto error_out;
  end;

  //PreInc(i)
  for i := 0  to  base.num_entries-1 do
  begin
    temp_result.entries[temp_result.num_entries] := base.entries[i];
    Inc(temp_result.num_entries);
  end;

  for i := 0 to add.num_entries-1 do
  begin
    e := temp_result.get_entry_by_key( add.entries[i].key);
    if nil <> e then
    begin
      if (Int(AMQP_FIELD_KIND_TABLE) = add.entries[i].value.kind)  and
         (Int(AMQP_FIELD_KIND_TABLE) = e.value.kind) then
      begin
        be := base.get_entry_by_key( add.entries[i].key);
        res := amqp_merge_capabilities(@be.value.value.table,
                                      @add.entries[i].value.value.table,
                                      e.value.value.table, @temp_pool);
        if Int(AMQP_STATUS_OK) <> res then
           goto error_out;

      end
      else
         e.value := add.entries[i].value;

    end
    else
    begin
      temp_result.entries[temp_result.num_entries] := add.entries[i];
      Inc(temp_result.num_entries);
    end;
  end;
  res := temp_result.clone(Aresult, pool);

error_out:
  temp_pool.empty;
  Result := res;
  {$POINTERMATH OFF}
end;


initialization
  called_wsastartup := 0;
  _haveInitializedWinsock :=0;
end.

