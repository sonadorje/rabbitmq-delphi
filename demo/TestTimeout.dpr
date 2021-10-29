program TestTimeout;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Net.Winsock2,
  amqp.api in '..\amqp.api.pas',
  amqp.connection in '..\amqp.connection.pas',
  amqp.consumer in '..\amqp.consumer.pas',
  amqp.framing in '..\amqp.framing.pas',
  amqp.mem in '..\amqp.mem.pas',
  amqp.privt in '..\amqp.privt.pas',
  amqp.socket in '..\amqp.socket.pas',
  amqp.table in '..\amqp.table.pas',
  amqp.tcp_socket in '..\amqp.tcp_socket.pas',
  amqp.time in '..\amqp.time.pas',
  AMQP.Types in '..\AMQP.Types.pas',
  amqp_tcp_socket in '..\amqp_tcp_socket.pas';

{var MyEnum : TMyEnum;
begin

  MyEnum := Two;
  writeln(Ord(MyEnum));  // writes 1, because first element in enumeration is numbered zero

  MyEnum := TMyEnum(2);  // Use TMyEnum as if it were a function
  Writeln (GetEnumName(TypeInfo(TMyEnum), Ord(MyEnum)));  //  Use RTTI to return the enum value's name
  readln;

end. }

function main:integer;
var
  port, status : integer;
  ret : Tamqp_rpc_reply;
  socket : Pamqp_socket;
  conn : Pamqp_connection_state;
  props : Tamqp_basic_properties;
  hostname, exchange, queue, bindkey: PAnsiChar;
  tval: Ttimeval ;
  tv: Ptimeval ;
  vl: Tva_list;
begin
  socket := nil;

  hostname := 'localhost';
  port := 5672;
  exchange := 'Test.EX';
  queue := 'Queue.Test';
  bindkey := 'test-key';

  tv := @tval;
  //timeout 5'
  tv.tv_sec := 5;

  if initializeWinsockIfNecessary() < 1 then
  begin
    Writeln('Failed to initialize "winsock": ');
    Exit;
  end;

  conn := amqp_new_connection();
  socket := amqp_tcp_socket_new(conn);
  if  socket = nil then begin
    Writeln('creating TCP socket failed!');
    Exit;
  end;

  var res := try_socket_open_noblock(socket, hostname, port, tv);
  if res < 0 then
     Exit;

  vl.username := 'sa';
  vl.password := 'admin';
  vl.identity := '';
  ret := amqp_login(conn, '/', 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, vl);

  if ret.library_error < 0 then
    Exit;



  amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
  amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
  amqp_destroy_connection(conn);

end;


begin
  try
    Main;
  except
    on e:Exception do
      WriteLn(e.Message);
  end;
end.

