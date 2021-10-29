program TestRpcServer;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  {$IFNDEF FPC}
  System.SysUtils,
  Net.Winsock2,
  {$else}
    winsock2, SysUtils,
  {$ENDIF}


  amqp.connection,
  amqp.framing,
  AMQP.Types,
  amqp.time,
  amqp.socket,
  amqp.privt,
  amqp.table,
  amqp.mem,
  amqp.tcp_socket,
  amqp.api,
  amqp.consumer;

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
  host: Ansistring;
  hostname, exchange, queue, routingkey, messagebody: PAnsiChar;
  tval: Ttimeval ;
  tv: Ptimeval ;
  vl: Tva_list;
  frame: Tamqp_frame;
  recv_queue: Tamqp_bytes;
  envelope: Tamqp_envelope;
  s: string;
  res: int;
  reply_props :Tamqp_basic_properties;
  replyQ : Pansichar;
begin
  socket := nil;

  {
  if ( ParamCount > 0 ) then
    host := ParamStr(1)
  else
    Exit; }

  hostname    := 'localhost';
  port        := 5672;
  exchange    := 'Test.EX';
  queue       := 'Test.Q';
  routingkey     := 'test-key';
  messagebody := 'Hello RpcClient， I''v received your message!';


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

  res := socket.open( hostname, port);
  if res < 0 then
     Exit;

  vl.username := 'sa';
  vl.password := 'admin';
  vl.identity := '';
  die_on_amqp_error(amqp_login(conn, '/', 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, vl),
                     'Logging in');



   amqp_channel_open(conn, 1);
   die_on_amqp_error(amqp_get_rpc_reply(conn), 'Opening channel');

    recv_queue := Tamqp_bytes.Create(queue);
    amqp_basic_consume(conn, 1, recv_queue, amqp_empty_bytes, 0, 1, 0,
                       amqp_empty_table);

    die_on_amqp_error(amqp_get_rpc_reply(conn), 'Consuming');
    {
      Get MSG
      3. 获取消息的具体内容
    }
    begin
      while True do
      begin
        amqp_maybe_release_buffers(conn);
        ret := amqp_consume_message(conn, envelope, nil, 0);
        if AMQP_RESPONSE_NORMAL <> ret.reply_type then begin
          break;
        end;

        s := Format('Delivery %u, exchange %.*s routingkey %.*s\n',
                      [envelope.delivery_tag, envelope.exchange.len,
                      Pansichar(envelope.exchange.bytes), envelope.routing_key.len,
                      PAnsiChar(envelope.routing_key.bytes)]);
        Writeln(s);
        Writeln('**************************************************************');
        amqp_dump(envelope.message.body.bytes, envelope.message.body.len);
        {
          4. 此处为作者个人修改部分
          因为在发送的时候初始化props为0， 则如果不是一个RPC的消息类型，则此处的reply_to的长度应该是0，否则，不为0
        }
        if 0 <> envelope.message.properties.reply_to.len then
        begin
          Writeln('there is a RPC reply');


          reply_props._flags := AMQP_BASIC_CONTENT_TYPE_FLAG or AMQP_BASIC_DELIVERY_MODE_FLAG;
          reply_props.content_type := amqp_cstring_bytes('text/plain');
          reply_props.delivery_mode := 2; { persistent delivery mode }
          reply_props.correlation_id := envelope.message.properties.correlation_id;
          {
            5. 重点需要照顾的部分
            此处EXCHANGE_NAME也就是交换机的名称为空，如果填写了上面接收使用的名称，rpc client端将不会收到，或者使用其他的名称也不行
            在原本需要写入ROUTE_KEY的部分则需要填入接收到的reply_to信息，只有当这两部分都填写正确rpc client才会收到回复的消息
          }
          replyQ := PAnsiChar(envelope.message.properties.reply_to.bytes);
          die_on_error(amqp_basic_publish(conn, 1, amqp_cstring_bytes(''),
            amqp_cstring_bytes(replyQ), 0, 0,
            @reply_props, amqp_cstring_bytes(messagebody)),
            'Publishing');
        end;
        envelope.destroy;
      end;
    end;

    die_on_amqp_error(amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS),
                      'Closing channel');
    die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS),
                      'Closing connection');
    die_on_error(amqp_destroy_connection(conn), 'Ending connection');

end;

begin
  try
    Main;
  except
    on e:Exception do
      WriteLn(e.Message);
  end;
end.


