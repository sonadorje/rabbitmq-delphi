unit amqp.tcp_socket;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$INCLUDE  config.inc}

//DEFINE EAGAIN Operation would have caused the process to be suspended.
interface
uses AMQP.Types, amqp.socket,
     {$IFNDEF FPC}

         {$IFDEF _WIN32}
            Net.Winsock2, Net.Wship6,
         {$ELSE}
            Net.SocketAPI,
         {$ENDIF}
         System.SysUtils;
     {$ELSE}
        winsock2, SysUtils;
     {$ENDIF}

function amqp_tcp_socket_new( state : Pamqp_connection_state):Pamqp_socket;
function amqp_tcp_socket_recv(base: Pointer; buf: Pointer; len : size_t; flags : integer):ssize_t;
function amqp_tcp_socket_open( base: Pointer; const host : PAnsiChar; port : integer;const timeout: Ptimeval):integer;
function amqp_tcp_socket_get_sockfd(base: Pointer):int;
function amqp_tcp_socket_close(base: Pointer; force: Tamqp_socket_close_enum):integer;
function amqp_tcp_socket_send(base: Pointer;const buf: Pointer; len : size_t; flags : integer):ssize_t;
procedure amqp_tcp_socket_set_sockfd(base : Pamqp_socket; sockfd : integer);
procedure amqp_tcp_socket_delete(base: Pointer);


const
  //Record Constants  Record constants cannot contain file-type values at any level.
  amqp_tcp_socket_class: Tamqp_socket_class = (
                     send       : amqp_tcp_socket_send;
                     recv       : amqp_tcp_socket_recv;
                     open       : amqp_tcp_socket_open;
                     close      : amqp_tcp_socket_close;
                     get_sockfd : amqp_tcp_socket_get_sockfd;
                     delete     : amqp_tcp_socket_delete);

implementation

(*TCP_CORK is Linux only; TCP_NOPUSH is BSD only; Windows does its own thing:
https://baus.net/on-tcp_cork/
https://docs.microsoft.com/en-us/windows/win32/winsock/ipproto-tcp-socket-options
*)
procedure amqp_tcp_socket_set_sockfd(base : Pamqp_socket; sockfd : integer);
var
  self : Pamqp_tcp_socket;
  s: string;
begin
  if base.klass <> @amqp_tcp_socket_class then
  begin
    s := Format('<%p> is not of type Tamqp_tcp_socket', [base]);
    raise Exception.Create(s);
  end;
  self := Pamqp_tcp_socket(base);
  self.sockfd := sockfd;
end;

procedure amqp_tcp_socket_delete(base: Pointer);
var
  self : Pamqp_tcp_socket;
begin
  self := Pamqp_tcp_socket(base);
  if Assigned(self) then
  begin
    amqp_tcp_socket_close(self, AMQP_SC_NONE);
    freeMem(self);
  end;
end;

function amqp_tcp_socket_get_sockfd(base: Pointer):int;
var
  self : Pamqp_tcp_socket;
begin
  self := Pamqp_tcp_socket(base);
  Result := self.sockfd;
end;

function amqp_tcp_socket_close(base: Pointer; force: Tamqp_socket_close_enum):integer;
var
  self : Pamqp_tcp_socket;
begin
  self := Pamqp_tcp_socket(base);
  if -1 = self.sockfd then
    Exit(Int(AMQP_STATUS_SOCKET_CLOSED));

  if amqp_os_socket_close(self.sockfd) > 0 then
    Exit(Int(AMQP_STATUS_SOCKET_ERROR));

  self.sockfd := -1;
  Result := Int(AMQP_STATUS_OK);
end;


function amqp_tcp_socket_open( base: Pointer; const host : PAnsiChar; port : integer;const timeout: Ptimeval):integer;
var
  Lself : Pamqp_tcp_socket;
  err : integer;
begin
  Lself := Pamqp_tcp_socket(base);
  if -1 <> Lself.sockfd then
    Exit(Int(AMQP_STATUS_SOCKET_INUSE));

  Lself.sockfd := amqp_open_socket_noblock(host, port, timeout);
  if 0 > Lself.sockfd then
  begin
    err := Lself.sockfd;
    Lself.sockfd := -1;
    Exit(err);
  end;
  Result := Int(AMQP_STATUS_OK);
end;

function amqp_tcp_socket_recv(base: Pointer; buf: Pointer; len : size_t; flags : integer):ssize_t;
var
  self : Pamqp_tcp_socket;
  ret : ssize_t;
  Level: int;
  s: string;

  label start;
begin
  Inc(gLevel);
  Level := gLevel;
  {$IFDEF _DEBUG_}
        DebugOut(Level, 'step into amqp.tcp_socket::amqp_tcp_socket_recv!');
  {$ENDIF}
  self := Pamqp_tcp_socket(base);
  if -1 = self.sockfd then
     Exit(Int(AMQP_STATUS_SOCKET_CLOSED));

start:
{$IFDEF _WIN32}

  ret := recv(self.sockfd, Pbyte(buf)^, Int(len), flags);
{$ELSE}
  ret = recv(self.sockfd, buf, len, flags);
{$ENDIF}
  if 0 > ret then
  begin
    self.internal_error := amqp_os_socket_error();
    {$IFDEF _DEBUG_}
      s := Format('step over amqp.tcp_socket::recv, ret=%d os_socket_error=%d', [ret, self.internal_error] );
      DebugOut(Level,  s);
   {$ENDIF}
    case self.internal_error of
      WSAEINTR: goto start;
{$IFDEF _WIN32}
      WSAEWOULDBLOCK,
{$ELSE}
      EWOULDBLOCK:
{$ENDIF}
{$IF EAGAIN <> 10035}//EWOULDBLOCK}
      EAGAIN:
{$IFEND}
      ret := Int(AMQP_PRIVATE_STATUS_SOCKET_NEEDREAD);
      else
        ret := Int(AMQP_STATUS_SOCKET_ERROR);
    end;
  end
  else
  if (0 = ret) then
    ret := Int(AMQP_STATUS_CONNECTION_CLOSED);

  Result := ret;

end;

function amqp_tcp_socket_send(base: Pointer;const buf: Pointer; len : size_t; flags : integer):ssize_t;
var
  Lself : Pamqp_tcp_socket;
  res : ssize_t;
  flagz, one, zero : integer;
  LBuffer : Puint8_t;
  LArray: array of AnsiChar;
  label start;
begin
  {$POINTERMATH ON}
  Lself := Pamqp_tcp_socket(base);
  flagz := 0;
  //sockfd=-1    表示socket 已经closed
  if -1 = Lself.sockfd then
    Exit(Int(AMQP_STATUS_SOCKET_CLOSED));

{$IFDEF MSG_NOSIGNAL}
  flagz  := flagz  or MSG_NOSIGNAL;
{$ENDIF}
{$IF defined(MSG_MORE)}
  if flags and AMQP_SF_MORE then begin
    flagz  := flagz  or MSG_MORE;
  end;
{ Cygwin defines TCP_NOPUSH, but trying to use it will return not
 * implemented. Disable it here. }
{$ELSEIF defined(TCP_NOPUSH)  and   not defined(__CYGWIN__)}
  if ( (flags and Int(AMQP_SF_MORE))>0 )  and
     (0> (self.state and Int(AMQP_SF_MORE) )) then
  begin
    one := 1;
    res := setsockopt(self.sockfd, IPPROTO_TCP, TCP_NOPUSH, &one, sizeof(one));
    if 0 <> res then
    begin
      self.internal_error := res;
      Exit(AMQP_STATUS_SOCKET_ERROR);
    end;
    self.state  := self.state  or AMQP_SF_MORE;
  end
  else
  if ( 0= (flags and AMQP_SF_MORE) ) and  ((self.state and AMQP_SF_MORE)>0) then
  begin
    zero := 0;
    res := setsockopt(self.sockfd, IPPROTO_TCP, TCP_NOPUSH, &zero, sizeof(&zero));
    if 0 <> res then
    begin
      self.internal_error := res;
      res := AMQP_STATUS_SOCKET_ERROR;
    end
    else
    begin
      self.state &= ~AMQP_SF_MORE;
    end;
  end;
{$IFEND}

start:
{$IFDEF _WIN32}
  //LBuffer := Puint8_t(buf);
  {SetLength(LArray, len);
  for var I := 0 to Len - 1 do
     Larray[I] := AnsiChar(LBuffer[I]); }
 {$IFNDEF FPC}
  res := send(Lself.sockfd, buf^, Int(len), flagz);
  {$ELSE}
  res := send(Lself.sockfd, buf^, len, flagz);
 {$ENDIF}
{$ELSE}
  res := send(Lself.sockfd, buf, len, flagz);
{$ENDIF}
  if res < 0 then
  begin
    Lself.internal_error := amqp_os_socket_error();
    case Lself.internal_error of
      WSAEINTR: goto start;
{$IFDEF _WIN32}
      WSAEWOULDBLOCK,
{$ELSE }
      EWOULDBLOCK:
{$ENDIF}
{$if  EAGAIN <> 10035}//EWOULDBLOCK}
      EAGAIN:
{$IFEND}
      res := int(AMQP_PRIVATE_STATUS_SOCKET_NEEDWRITE);

      else
        res := Int(AMQP_STATUS_SOCKET_ERROR);
    end;
  end
  else
    Lself.internal_error := 0;

  Result := res;
  {$POINTERMATH ON}
end;


function amqp_tcp_socket_new( state : Pamqp_connection_state):Pamqp_socket;
var
  Lself : Pamqp_tcp_socket;
begin
  Lself := calloc(1, sizeof(Tamqp_tcp_socket));
  if  not Assigned(Lself) then
    Exit(nil);

  Lself.klass := @amqp_tcp_socket_class;
  Lself.sockfd := -1;
  //amqp_set_socket(state, Pamqp_socket(Lself));
  state.socket := Pamqp_socket(Lself);
  Result := Pamqp_socket(Lself);
end;

initialization

end.
