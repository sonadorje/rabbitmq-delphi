program TestRPCClient;

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
  host: Ansistring;
  hostname, exchange, queue, bindkey, messagebody, reply_Q: PAnsiChar;
  tval: Ttimeval ;
  tv: Ptimeval ;
  vl: Tva_list;
  frame: Tamqp_frame;
  reply_to_queue: Tamqp_bytes;
begin
  socket := nil;

  {
  if ( ParamCount > 0 ) then
    host := ParamStr(1)
  else
    Exit;  }

  hostname    := 'localhost';
  port        := 5672;
  exchange    := 'Test.EX';
  queue       := 'Test.Q';
  bindkey     := 'test-key';
  messagebody := 'hello';
  reply_Q := 'reply.Q';
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

  var res := amqp_socket_open(socket, hostname, port);
  if res < 0 then
     Exit;

  vl.username := 'sa';
  vl.password := 'admin';
  vl.identity := '';
  die_on_amqp_error(amqp_login(conn, '/', 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, vl),
                     'Logging in');



  amqp_channel_open(conn, 1);
  die_on_amqp_error(amqp_get_rpc_reply(conn), 'Opening channel');

  //create private reply_to queue
  //var r := amqp_queue_declare(conn, 1, amqp_empty_bytes, 0, 0, 0, 1, amqp_empty_table);
  //die_on_amqp_error(amqp_get_rpc_reply(conn), 'Declaring queue');

   reply_to_queue:= Tamqp_bytes.Create(reply_Q);

    if reply_to_queue.bytes = nil then
    begin
      Writeln('Out of memory while copying queue name');
      Exit(1);
    end;

  {
     send the message
  }
  begin

    //set properties

    props._flags := AMQP_BASIC_CONTENT_TYPE_FLAG or AMQP_BASIC_DELIVERY_MODE_FLAG or
                    AMQP_BASIC_REPLY_TO_FLAG or AMQP_BASIC_CORRELATION_ID_FLAG;
    props.content_type := amqp_cstring_bytes('text/plain');
    props.delivery_mode := 2; { persistent delivery mode }
    {$if CompilerVersion < 34}
    props.reply_to := @reply_to_queue;
    {$ELSE}
     props.reply_to := reply_to_queue;
    {$ENDIF}
    if props.reply_to.bytes = nil then begin
      Write('Out of memory while copying queue name');
      Exit(1);
    end;

    props.correlation_id := amqp_cstring_bytes('1');
    die_on_error(amqp_basic_publish(conn, 1, amqp_cstring_bytes(exchange),
                                    amqp_cstring_bytes(bindkey), 0, 0,
                                    @props, amqp_cstring_bytes(messagebody)
                                   ), 'Publishing');

    props.reply_to.Destroy;
  end;
  {
    wait an answer
  }
  begin

    amqp_basic_consume(conn, 1, reply_to_queue, amqp_empty_bytes, 0, 1, 0,
                       amqp_empty_table);
    die_on_amqp_error(amqp_get_rpc_reply(conn), 'Consuming');
    reply_to_queue.Destroy;

    begin
      while True do
      begin
        amqp_maybe_release_buffers(conn);
        result := amqp_simple_wait_frame(conn, frame);
        writeln(format('Result: %d',[result]));
        if result < 0 then begin
          break;
        end;
        writeln(format('Frame type: %u channel: %u',[frame.frame_type, frame.channel]));
        if frame.frame_type <> AMQP_FRAME_METHOD then begin
          continue;
        end;
        writeln(format('Method: %s',[amqp_method_name(frame.payload.method.id)]));
        if frame.payload.method.id <> AMQP_BASIC_DELIVER_METHOD then begin
          continue;
        end;
        var d := Pamqp_basic_deliver(frame.payload.method.decoded);
        Writeln('Delivery: %u exchange: %d %s routingkey: %d %s\n',
                d.delivery_tag, d.exchange.len,
               PAnsiChar(d.exchange.bytes), d.routing_key.len,
               PAnsiChar(d.routing_key.bytes));
        result := amqp_simple_wait_frame(conn, frame);
        if result < 0 then begin
          break;
        end;
        if frame.frame_type <> AMQP_FRAME_HEADER then begin
          Write('Expected header!');
          abort();
        end;
        var p := Pamqp_basic_properties(frame.payload.properties.decoded);
        if (p._flags and AMQP_BASIC_CONTENT_TYPE_FLAG) > 0 then begin
          Writeln('Content-type: %d %s\n', p.content_type.len,
                 PAnsiChar(p.content_type.bytes));
        end;
        Writeln('----');
        var body_target := size_t(frame.payload.properties.body_size);
        var body_received := 0;
        while body_received < body_target do
        begin
          result := amqp_simple_wait_frame(conn, frame);
          if result < 0 then
            break;

          if frame.frame_type <> AMQP_FRAME_BODY then
          begin
            Write('Expected body!');
            abort();
          end;
          body_received  := body_received + frame.payload.body_fragment.len;
          assert(body_received <= body_target);
          amqp_dump(frame.payload.body_fragment.bytes,
                    frame.payload.body_fragment.len);
        end;
        if body_received <> body_target then
          { Can only happen when amqp_simple_wait_frame returns <= 0 }
          { We break here to close the connection }
          break;

        { everything was fine, we can quit now because we received the reply }
        break;
      end;
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

