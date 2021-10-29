program TestBinding;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
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
  hostname, bindkey, exchange, queue: PAnsiChar;
  vl: Tva_list;
begin
  socket := nil;

  hostname := 'localhost';
  port := 5672;
  exchange := 'Test.EX';
  bindkey := 'test-key';
  queue := 'Queue.Test';

  if initializeWinsockIfNecessary() < 1 then
 begin
    Writeln('Failed to initialize "winsock": ');
    Exit;
 end;

  conn := amqp_new_connection();
  socket := amqp_tcp_socket_new(conn);
  if  not Assigned(socket) then begin
    Writeln('creating TCP socket failed!');
    Exit;
  end;
  status := amqp_socket_open(socket, hostname, port);
  if status > 0 then begin
    Writeln('opening TCP socket failed!');
    Exit;
  end;
  vl.username := 'sa';
  vl.password := 'admin';
  vl.identity := '';
  ret := amqp_login(conn, '/', 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, vl);

  if ret.library_error < 0 then
    Exit;

  var P := amqp_channel_open(conn, 1);
  IF P = nil then
     Exit;
  var reply := amqp_get_rpc_reply(conn);
  if reply.library_error < 0 then
     Exit;

  amqp_queue_bind(conn, 1, amqp_cstring_bytes(queue),
                  amqp_cstring_bytes(exchange), amqp_cstring_bytes(bindkey),
                  amqp_empty_table);
  if reply.library_error < 0 then
     Exit;
  amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
  amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
  amqp_destroy_connection(conn);
  Result := 0;
end;


begin
  try
    Main;
  except
    on e:Exception do
      WriteLn(e.Message);
  end;
end.

