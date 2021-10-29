unit amqp_tcp_socket;
{$INCLUDE  config.inc}

//DEFINE EAGAIN Operation would have caused the process to be suspended.
interface
uses AMQP.Types,
     {$IFDEF CrossSocket}
        Net.Winsock2, Net.Wship6,
     {$ELSE}
        Winsock2, IdWship6,
     {$ENDIF}
amqp.socket, System.SysUtils;

function amqp_tcp_socket_new( state : Pamqp_connection_state):Pamqp_socket;
function amqp_tcp_socket_recv(base, buf: Pointer; len : size_t; flags : integer):ssize_t;
function amqp_tcp_socket_open( base: Pointer; host : PAMQPChar; port : integer;const timeout: Ptimeval):integer;
function amqp_tcp_socket_get_sockfd(base: Pointer):int;
function amqp_tcp_socket_close(base: Pointer; force: Tamqp_socket_close_enum):integer;
procedure amqp_tcp_socket_set_sockfd(base : Pamqp_socket; sockfd : integer);
procedure amqp_tcp_socket_delete(base: Pointer);


var
  amqp_tcp_socket_class: Tamqp_socket_class;

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
  if Assigned(self) then begin
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
  if -1 = self.sockfd then begin
    Exit(Int(AMQP_STATUS_SOCKET_CLOSED));
  end;
  if amqp_os_socket_close(self.sockfd) > 0 then  begin
    Exit(Int(AMQP_STATUS_SOCKET_ERROR));
  end;
  self.sockfd := -1;
  Result := Int(AMQP_STATUS_OK);
end;


function amqp_tcp_socket_open( base: Pointer; host : PAMQPChar; port : integer;const timeout: Ptimeval):integer;
var
  self : Pamqp_tcp_socket;
  err : integer;
begin
  self := Pamqp_tcp_socket(base);
  if -1 <> self.sockfd then begin
    Exit(Int(AMQP_STATUS_SOCKET_INUSE));
  end;
  self.sockfd := amqp_open_socket_noblock(host, port, timeout);
  if 0 > self.sockfd then begin
    err := self.sockfd;
    self.sockfd := -1;
    Exit(err);
  end;
  Result := Int(AMQP_STATUS_OK);
end;

function amqp_tcp_socket_recv(base, buf: Pointer; len : size_t; flags : integer):ssize_t;
var
  self : Pamqp_tcp_socket;
  ret : ssize_t;
  label start;
begin
  self := Pamqp_tcp_socket(base);
  if -1 = self.sockfd then
     Exit(Int(AMQP_STATUS_SOCKET_CLOSED));

start:
{$IFDEF _WIN32}
  ret := recv(self.sockfd, buf^, len, flags);
{$ELSE}
  ret = recv(self.sockfd, buf, len, flags);
{$ENDIF}
  if 0 > ret then
  begin
    self.internal_error := amqp_os_socket_error();
    case self.internal_error of
      EINTR: goto start;
{$IFDEF _WIN32}
      WSAEWOULDBLOCK,
{$ELSE}
      EWOULDBLOCK:
{$ENDIF}
{$IF EAGAIN <> EWOULDBLOCK}
      EAGAIN:
{$ENDIF}
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
  self : Pamqp_tcp_socket;
  res : ssize_t;
  flagz, one, zero : integer;
  LBuffer : Puint8_t;
  LArray: array of AnsiChar;
  label start;
begin
  {$POINTERMATH ON}
  self := Pamqp_tcp_socket(base);
  flagz := 0;
  //sockfd=-1    表示socket 已经closed
  if -1 = self.sockfd then
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
{$ENDIF}
start:
{$IFDEF _WIN32}
  //LBuffer := Puint8_t(buf);
  {SetLength(LArray, len);
  for var I := 0 to Len - 1 do
     Larray[I] := AnsiChar(LBuffer[I]); }
  res := send(self.sockfd, buf^, len, flagz);
{$ELSE}
  res := send(self.sockfd, buf, len, flagz);
{$ENDIF}
  if res < 0 then
  begin
    self.internal_error := amqp_os_socket_error();
    case self.internal_error of
      EINTR,
{$IFDEF _WIN32}
      WSAEWOULDBLOCK,
{$ELSE }
      EWOULDBLOCK:
{$ENDIF}
{$if  EAGAIN <> EWOULDBLOCK}
      EAGAIN:
{$ENDIF}
      res := int(AMQP_PRIVATE_STATUS_SOCKET_NEEDWRITE);

      else
        res := Int(AMQP_STATUS_SOCKET_ERROR);
    end;
  end
  else
  begin
    self.internal_error := 0;
  end;
  Result := res;
  {$POINTERMATH ON}
end;


function amqp_tcp_socket_new( state : Pamqp_connection_state):Pamqp_socket;
var
  Lself : Pamqp_tcp_socket;
begin
  Lself := calloc(1, sizeof(Lself^));
  if  not Assigned(Lself) then begin
    Exit(nil);
  end;
  Lself.klass := @amqp_tcp_socket_class;
  Lself.sockfd := -1;
  amqp_set_socket(state, Pamqp_socket(Lself));
  Result := Pamqp_socket(Lself);
end;

initialization
   amqp_tcp_socket_class.send       := @amqp_tcp_socket_send;
   amqp_tcp_socket_class.recv       := @amqp_tcp_socket_recv;
   amqp_tcp_socket_class.open       := @amqp_tcp_socket_open;
   amqp_tcp_socket_class.close      := @amqp_tcp_socket_close;
   amqp_tcp_socket_class.get_sockfd := @amqp_tcp_socket_get_sockfd;
   amqp_tcp_socket_class.delete     := @amqp_tcp_socket_delete;

end.
