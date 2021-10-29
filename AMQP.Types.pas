unit AMQP.Types;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$INCLUDE config.inc}
interface
uses {$IFDEF FPC}SysUtils, Windows,{$Else} System.SysUtils, Winapi.Windows,{$ENDIF}
     {$IFNDEF FPC}
        {$IFDEF _WIN32}
           Net.Winsock2

        {$ELSE}
           Net.SocketAPI
        {$ENDIF}
     {$ELSE}
         winsock2
     {$ENDIF};
const
   UINT32_MAX  = $ffffffff;
   UINT8_MAX   = $ff;
   UINT64_MAX  = $ffffffffffffffff;
   UINT16_MAX  = $ffff;
   INT32_MAX   = $7fffffff;
  //EINTR = 3407;
  EAGAIN =	3406;

type
  uint16_t = uint16;
  int16_t = Int16;
  int8_t = Int8;
  uint8_t = UInt8;
  Puint8_t = ^uint8_t;
  uint64_t = Uint64;
  int64_t = Int64;
  bool     = Boolean ;
  uint32_t = UInt32;
  int32_t  = int32;
  int = Integer;
  float = Single;
  PAMQPChar = PByte;
  AMQPChar = AnsiChar;
  {$IFDEF OS64}
  size_t = Uint64;
  ssize_t = int64;

  {$ELSE}
  size_t = uint32;
  Psize_t = ^size_t;
  ssize_t = int32;

  {$ENDIF}
  (* 7 bytes up front, then payload, then 1 byte footer *)
const
  HEADER_SIZE = 7;
  FOOTER_SIZE = 1;
  POOL_TABLE_SIZE = 16;
  AMQP_PSEUDOFRAME_PROTOCOL_HEADER = 'A';
  {$IFDEF OS64}
     SIZE_MAX = $ffffffffffffffff;
  {$ELSE}
     SIZE_MAX = $ffffffff;
  {$ENDIF}
type
  PPTimeVal = ^PTimeVal;
  Tamqp_time = record
    time_point_ns: uint64_t;
    class operator equal( l, r : Tamqp_time):Boolean;
    class function infinite:Tamqp_time; static;
  end;

  Pamqp_time            = ^Tamqp_time;
  amqp_boolean_t        = int;
  amqp_method_number_t  = uint32_t;
  Pamqp_method_number_t = ^amqp_method_number_t;
  amqp_flags_t          = uint32_t ;
  amqp_channel_t        = uint16_t ;
  Pamqp_flags_t         = ^amqp_flags_t;
  Tamqp_methods = array of amqp_method_number_t;

  Tamqp_field_value_kind = (
      AMQP_FIELD_KIND_BOOLEAN = Ord('t'), (**< boolean type. 0 = false, 1 = true @see amqp_boolean_t *)
      AMQP_FIELD_KIND_I8 = Ord('b'),  (**< 8-bit signed integer, datatype: int8_t *)
      AMQP_FIELD_KIND_U8 = Ord('B'),  (**< 8-bit unsigned integer, datatype: uint8_t *)
      AMQP_FIELD_KIND_I16 = Ord('s'), (**< 16-bit signed integer, datatype: int16_t *)
      AMQP_FIELD_KIND_U16 = Ord('u'), (**< 16-bit unsigned integer, datatype: uint16_t *)
      AMQP_FIELD_KIND_I32 = Ord('I'), (**< 32-bit signed integer, datatype: int32_t *)
      AMQP_FIELD_KIND_U32 = Ord('i'), (**< 32-bit unsigned integer, datatype: uint32_t *)
      AMQP_FIELD_KIND_I64 = Ord('l'), (**< 64-bit signed integer, datatype: int64_t *)
      AMQP_FIELD_KIND_U64 = Ord('L'), (**< 64-bit unsigned integer, datatype: uint64_t *)
      AMQP_FIELD_KIND_F32 = Ord('f'), (**< single-precision floating point value, datatype: float *)
      AMQP_FIELD_KIND_F64 = Ord('d'), (**< double-precision floating point value, datatype: double *)
      AMQP_FIELD_KIND_DECIMAL = Ord('D'), (**< amqp-decimal value, datatype: amqp_decimal_t *)
      AMQP_FIELD_KIND_UTF8 = Ord('S'),      (**< UTF-8 null-terminated character string,
                                          datatype: amqp_bytes_t *)
      AMQP_FIELD_KIND_ARRAY = Ord('A'),     (**< field array (repeated values of another
                                          datatype. datatype: amqp_array_t *)
      AMQP_FIELD_KIND_TIMESTAMP = Ord('T'), (**< 64-bit timestamp. datatype uint64_t *)
      AMQP_FIELD_KIND_TABLE = Ord('F'), (**< field table. encapsulates a table inside a
                                      table entry. datatype: amqp_table_t *)
      AMQP_FIELD_KIND_VOID = Ord('V'),  (**< empty entry *)
      AMQP_FIELD_KIND_BYTES = Ord('x') (**< unformatted byte string, datatype: amqp_bytes_t *)
   );

  Tamqp_response_type_enum = (
    AMQP_RESPONSE_NONE = 0, (**< the library got an EOF from the socket *)
    AMQP_RESPONSE_NORMAL, (**< response normal, the RPC completed successfully *)
    AMQP_RESPONSE_LIBRARY_EXCEPTION, (**< library error, an error occurred in the
                                        library, examine the library_error *)
    AMQP_RESPONSE_SERVER_EXCEPTION   (**< server exception, the broker returned an
                                        error, check replay *)
  );

  Pamqp_bytes = ^Tamqp_bytes;
  Tamqp_bytes = record
     len: size_t;  (**< length of the buffer in bytes *)
     bytes: PAMQPChar;//Pointer; (**< pointer to the beginning of the buffer *)
     class operator Equal(r, l: Tamqp_bytes) : Boolean;
     //{$if CompilerVersion >= 34}
     //class operator Assign(var Dest: Tamqp_bytes; const [ref] Src: Tamqp_bytes);

     class operator Implicit(src: Pamqp_bytes): Tamqp_bytes;

     constructor Create(amount : size_t);   overload;
     constructor Create( Aname : PAnsiChar); overload;
     procedure Destroy;
     function malloc_dup_failed:integer;

  end;


 Tamqp_decimal_t_ = record
   decimals: uint8_t; (**< the location of the decimal point *)
   value: uint32_t;   (**< the value before the decimal point is applied *)
 end;
 Tamqp_decimal = Tamqp_decimal_t_;

  Tamqp_pool_blocklist = record
    num_blocks: int ;   (**< Number of blocks in the block list *)
    blocklist: PPointer; (**< Array of memory blocks *)
  end;
  Pamqp_pool_blocklist = ^Tamqp_pool_blocklist;

  (**
 * A memory pool
 *
 * \since v0.1
 *)
 Tamqp_pool = record
  pagesize: size_t ; (**< the size of the page in bytes. Allocations less than or
                    * equal to this size are allocated in the pages block list.
                    * Allocations greater than this are allocated in their own
                    * own block in the large_blocks block list *)

  pages: Tamqp_pool_blocklist ; (**< blocks that are the size of pagesize *)
  large_blocks: Tamqp_pool_blocklist ; (**< allocations larger than the pagesize
                                       *)

  next_page: int ;     (**< an index to the next unused page block *)
  alloc_block: PAMQPChar; (**< pointer to the current allocation block *)
  alloc_used: size_t ; (**< number of bytes in the current allocation block that
                        has been used *)
  constructor Create(pagesize : size_t);
  function alloc(amount : size_t): Pointer;
  procedure empty();
  procedure recycle();
  procedure alloc_bytes(amount : size_t;out output : Tamqp_bytes);

 end;
  Pamqp_pool = ^Tamqp_pool;


  Pamqp_table_entry = ^Tamqp_table_entry;
  Tamqp_table = record
    num_entries: int ;                     (**< length of entries array *)
    entries: Pamqp_table_entry; (**< an array of table entries *)
    function clone(out Aclone : Tamqp_table; pool : Pamqp_pool):integer;
    function get_entry_by_key(const key : Tamqp_bytes): Pamqp_table_entry;
  end;

  Pamqp_table = ^Tamqp_table;

  Pamqp_field_value = ^Tamqp_field_value;
  Tamqp_array = record
    num_entries: int ;                     (**< Number of entries in the table *)
    entries: Pamqp_field_value; (**< linked list of field values *)
  end;

  Pamqp_array = ^Tamqp_array;



  Tamqp_field_value = record
    kind: uint8_t; (**< the type of the entry /sa amqp_field_value_kind_t *)
    value: record
      &boolean: amqp_boolean_t; (**< boolean type  *)
      i8: int8_t ;              (**< int8_t type  *)
      u8: uint8_t;             (**< uint8_t  *)
      i16: int16_t;            (**< int16_t type  *)
      u16:uint16_t;           (**< uint16_t type  *)
      i32: int32_t;            (**< int32_t type  *)
      u32: uint32_t;           (**< uint32_t type  *)
      i64: int64_t;            (**< int64_t type  *)
      u64: uint64_t;           (**< uint64_t type ,
                               AMQP_FIELD_KIND_TIMESTAMP *)
      f32: float;              (**< float type  *)
      f64: double;             (**< double type  *)
      decimal: Tamqp_decimal; (**< amqp_decimal_t  *)
      bytes: Tamqp_bytes;     (**< amqp_bytes_t type AMQP_FIELD_KIND_UTF8,
                               AMQP_FIELD_KIND_BYTES *)
      table: Tamqp_table;     (**< amqp_table_t type  *)
      &array: Tamqp_array;     (**< amqp_array_t type  *)

   end;  (**< a union of the value *)
     function clone(out Aclone : Tamqp_field_value; pool : Pamqp_pool):integer;
 end;

 Tamqp_method =  record
  id: amqp_method_number_t ; (**< the method id number *)
  decoded: Pointer;           (**< pointer to the decoded method,
                            *    cast to the appropriate type to use *)
 end;
 Pamqp_method = ^Tamqp_method;

 

  Tamqp_rpc_reply =  record
   reply_type: Tamqp_response_type_enum; (**< the reply type:
                                       * - AMQP_RESPONSE_NORMAL - the RPC
                                       * completed successfully
                                       * - AMQP_RESPONSE_SERVER_EXCEPTION - the
                                       * broker returned
                                       *     an exception, check the reply field
                                       * - AMQP_RESPONSE_LIBRARY_EXCEPTION - the
                                       * library
                                       *    encountered an error, check the
                                       * library_error field
                                       *)
   reply: Tamqp_method ; (**< in case of AMQP_RESPONSE_SERVER_EXCEPTION this
                        * field will be set to the method returned from the
                        * broker *)
  library_error: int ;   (**< in case of AMQP_RESPONSE_LIBRARY_EXCEPTION this
                        *    field will be set to an error code. An error
                        *     string can be retrieved using amqp_error_string *)
  end;
  Pamqp_rpc_reply = ^Tamqp_rpc_reply;

  Tamqp_connection_state_enum = (
  CONNECTION_STATE_IDLE = 0,
  CONNECTION_STATE_INITIAL,
  CONNECTION_STATE_HEADER,
  CONNECTION_STATE_BODY
);

Tamqp_status_private_enum = (
  (* 0x00xx -> AMQP_STATUS_*)
  (* 0x01xx -> AMQP_STATUS_TCP_* *)
  (* 0x02xx -> AMQP_STATUS_SSL_* *)
  AMQP_PRIVATE_STATUS_SOCKET_NEEDREAD = -$1301,
  AMQP_PRIVATE_STATUS_SOCKET_NEEDWRITE = -$1302
);



  Pamqp_link = ^Tamqp_link;
  Tamqp_link = record
      next: Pamqp_link ;
      data: Pointer;
  end;



 Pamqp_pool_table_entry = ^Tamqp_pool_table_entry;
 Tamqp_pool_table_entry = record
  next: Pamqp_pool_table_entry;
  pool: Tamqp_pool ;
  channel: amqp_channel_t ;
 end;


  Tamqp_socket_flag_enum = (
  AMQP_SF_NONE = 0,
  AMQP_SF_MORE = 1,
  AMQP_SF_POLLIN = 2,
  AMQP_SF_POLLOUT = 4,
  AMQP_SF_POLLERR = 8
 ) ;

Tamqp_socket_close_enum = ( AMQP_SC_NONE = 0, AMQP_SC_FORCE = 1 ) ;



(* Socket callbacks. *)
 Tamqp_socket_send_fn = function(Aself: Pointer; const Abuf: Pointer; Alen : size_t; Aflags : integer): ssize_t;
 Tamqp_socket_recv_fn = function(Aself: Pointer; Abuf: Pointer; Alen : size_t; Aflags : integer): ssize_t;
 Tamqp_socket_open_fn = function(Aself: Pointer; const Ahost: PAnsiChar; Aport: int; const Atimeout: Ptimeval): int;
 Tamqp_socket_close_fn = function(Aself: Pointer; Aforce: Tamqp_socket_close_enum): int;
 Tamqp_socket_get_sockfd_fn = function(Aself: Pointer): int;
 Tamqp_socket_delete_fn = procedure(Aself: Pointer);

(** V-table for Tamqp_socket *)
 Tamqp_socket_class = record
   send: Tamqp_socket_send_fn;
   recv: Tamqp_socket_recv_fn;
   open: Tamqp_socket_open_fn;
   close: Tamqp_socket_close_fn;
   get_sockfd: Tamqp_socket_get_sockfd_fn;
   delete: Tamqp_socket_delete_fn;
end;
Pamqp_socket_class = ^Tamqp_socket_class;
(** Abstract base class for Tamqp_socket *)

  Tamqp_socket = record
    klass: Pamqp_socket_class;
    function send(const Abuf: Pointer; Alen : size_t; Aflags : integer):ssize_t;
    function recv(Abuf: Pointer; Alen : size_t; Aflags : integer):ssize_t;
    function close(Aforce : Tamqp_socket_close_enum):integer;
    function open( host : PAnsiChar; port : integer):integer;
    function open_noblock(Ahost : PAnsiChar; Aport : integer;const Atimeout: Ptimeval):integer;
    procedure delete;
  end;
  Pamqp_socket = ^Tamqp_socket;

  Tamqp_tcp_socket = record
     klass: Pamqp_socket_class;
     sockfd,
     internal_error,
     state          : int;
  end;
  Pamqp_tcp_socket = ^Tamqp_tcp_socket;

  Tamqp_connection_state = record
    pool_table: array[0..POOL_TABLE_SIZE -1] of Pamqp_pool_table_entry;
    state: Tamqp_connection_state_enum;
    channel_max: int ;
    frame_max: int ;

    (* Heartbeat interval in seconds. If this is <= 0, then heartbeats are not
     * enabled, and next_recv_heartbeat and next_send_heartbeat are set to
     * infinite *)
    heart_beat: int ;
    next_recv_heartbeat: Tamqp_time ;
    next_send_heartbeat: Tamqp_time ;

    (* buffer for holding frame headers.  Allows us to delay allocating
     * the raw frame buffer until the type, channel, and size are all known
     *)
     //char header_buffer[HEADER_SIZE + 1];
    header_buffer: array[0..HEADER_SIZE] of Byte;
    inbound_buffer: Tamqp_bytes ;
    inbound_offset: size_t ;
    target_size: size_t ;
    outbound_buffer: Tamqp_bytes ;
    Fsocket: Pamqp_socket ;
    sock_inbound_buffer: Tamqp_bytes ;
    sock_inbound_offset: size_t ;
    sock_inbound_limit: size_t ;
    first_queued_frame: Pamqp_link;
    last_queued_frame: Pamqp_link;
    most_recent_api_result: Tamqp_rpc_reply ;
    server_properties: Tamqp_table ;
    client_properties: Tamqp_table ;
    properties_pool: Tamqp_pool ;
    handshake_timeout: Ptimeval;
    internal_handshake_timeout: TtimeVal;
    rpc_timeout: Ptimeval;
    internal_rpc_timeout: Ttimeval;

    function get_sockfd:integer;
    procedure set_socket(Asocket : Pamqp_socket);
    function get_channel_pool(channel : amqp_channel_t):Pamqp_pool;
    function get_or_create_channel_pool(channel : amqp_channel_t):Pamqp_pool;

    property channelmax: Int read channel_max;
    property framemax: Int read frame_max;
    property heartbeat: Int read heart_beat;
    property sockfd: Int read get_sockfd;
    property socket: Pamqp_socket write set_socket;
    property ServerProperties: Tamqp_table read server_properties;
    property ClientProperties: Tamqp_table read client_properties;
 end;

 Pamqp_connection_state = ^Tamqp_connection_state;

  Tamqp_status_enum = (
  AMQP_STATUS_OK = $0,                             (**< Operation successful *)
  AMQP_STATUS_NO_MEMORY = -$0001,                  (**< Memory allocation
                                                         failed *)
  AMQP_STATUS_BAD_AMQP_DATA = -$0002,              (**< Incorrect or corrupt
                                                         data was received from
                                                         the broker. This is a
                                                         protocol error. *)
  AMQP_STATUS_UNKNOWN_CLASS = -$0003,              (**< An unknown AMQP class
                                                         was received. This is
                                                         a protocol error. *)
  AMQP_STATUS_UNKNOWN_METHOD = -$0004,             (**< An unknown AMQP method
                                                         was received. This is
                                                         a protocol error. *)
  AMQP_STATUS_HOSTNAME_RESOLUTION_FAILED = -$0005, (**< Unable to resolve the
                                                     * hostname *)
  AMQP_STATUS_INCOMPATIBLE_AMQP_VERSION = -$0006,  (**< The broker advertised
                                                         an incompaible AMQP
                                                         version *)
  AMQP_STATUS_CONNECTION_CLOSED = -$0007,          (**< The connection to the
                                                         broker has been closed
                                                         *)
  AMQP_STATUS_BAD_URL = -$0008,                    (**< malformed AMQP URL *)
  AMQP_STATUS_SOCKET_ERROR = -$0009,               (**< A socket error
                                                         occurred *)
  AMQP_STATUS_INVALID_PARAMETER = -$000A,          (**< An invalid parameter
                                                         was passed into the
                                                         function *)
  AMQP_STATUS_TABLE_TOO_BIG = -$000B,              (**< The amqp_table_t object
                                                         cannot be serialized
                                                         because the output
                                                         buffer is too small *)
  AMQP_STATUS_WRONG_METHOD = -$000C,               (**< The wrong method was
                                                         received *)
  AMQP_STATUS_TIMEOUT = -$000D,                    (**< Operation timed out *)
  AMQP_STATUS_TIMER_FAILURE = -$000E,              (**< The underlying system
                                                         timer facility failed *)
  AMQP_STATUS_HEARTBEAT_TIMEOUT = -$000F,          (**< Timed out waiting for
                                                         heartbeat *)
  AMQP_STATUS_UNEXPECTED_STATE = -$0010,           (**< Unexpected protocol
                                                         state *)
  AMQP_STATUS_SOCKET_CLOSED = -$0011,              (**< Underlying socket is
                                                         closed *)
  AMQP_STATUS_SOCKET_INUSE = -$0012,               (**< Underlying socket is
                                                         already open *)
  AMQP_STATUS_BROKER_UNSUPPORTED_SASL_METHOD = -$0013, (**< Broker does not
                                                          support the requested
                                                          SASL mechanism *)
  AMQP_STATUS_UNSUPPORTED = -$0014, (**< Parameter is unsupported
                                       in this version *)
  AMQP_STATUS_NEXT_VALUE = -$0015, (**< Internal value *)

  AMQP_STATUS_TCP_ERROR = -$0100,                (**< A generic TCP error
                                                       occurred *)
  AMQP_STATUS_TCP_SOCKETLIB_INIT_ERROR = -$0101, (**< An error occurred trying
                                                       to initialize the
                                                       socket library*)
  AMQP_STATUS_TCP_NEXT_VALUE = -$0102,          (**< Internal value *)

  AMQP_STATUS_SSL_ERROR = -$0200,                  (**< A generic SSL error
                                                         occurred. *)
  AMQP_STATUS_SSL_HOSTNAME_VERIFY_FAILED = -$0201, (**< SSL validation of
                                                         hostname against
                                                         peer certificate
                                                         failed *)
  AMQP_STATUS_SSL_PEER_VERIFY_FAILED = -$0202,     (**< SSL validation of peer
                                                         certificate failed. *)
  AMQP_STATUS_SSL_CONNECTION_FAILED = -$0203, (**< SSL handshake failed. *)
  AMQP_STATUS_SSL_SET_ENGINE_FAILED = -$0204, (**< SSL setting engine failed *)
  AMQP_STATUS_SSL_NEXT_VALUE = -$0205        (**< Internal value *)
);



 Tamqp_sasl_method_enum = (
  AMQP_SASL_METHOD_UNDEFINED = -1, (**< Invalid SASL method *)
  AMQP_SASL_METHOD_PLAIN =
      0, (**< the PLAIN SASL method for authentication to the broker *)
  AMQP_SASL_METHOD_EXTERNAL =
      1 (**< the EXTERNAL SASL method for authentication to the broker *)
 );

 Tva_list = record
    username: PAnsiChar;
    password: PAnsiChar;
    identity: PAnsiChar;
 end;


  Tamqp_frame = record
    frame_type: uint8_t ;     (**< frame type. The types:
                           * - AMQP_FRAME_METHOD - use the method union member
                           * - AMQP_FRAME_HEADER - use the properties union member
                           * - AMQP_FRAME_BODY - use the body_fragment union member
                           *)
    channel: amqp_channel_t ; (**< the channel the frame was received on *)
    payload: record
      method: Tamqp_method;
      properties: record
       class_id: uint16_t;        (**< the class for the properties *)
       body_size: uint64_t;       (**< size of the body in bytes *)
       decoded: Pointer;            (**< the decoded properties *)
       raw: Tamqp_bytes;         (**< amqp-encoded properties structure *)
      end ;               (**< message header, a.k.a., properties,
                                      use if frame_type == AMQP_FRAME_HEADER *)
      body_fragment: Tamqp_bytes; (**< a body fragment, use if frame_type ==
                                   AMQP_FRAME_BODY *)
      protocol_header: record
          transport_high: uint8_t ;         (**< @internal first byte of handshake *)
          transport_low: uint8_t ;          (**< @internal second byte of handshake *)
          protocol_version_major: uint8_t ; (**< @internal third byte of handshake *)
          protocol_version_minor: uint8_t ; (**< @internal fourth byte of handshake *)
      end ; (**< Used only when doing the initial handshake with the
                          broker, don't use otherwise *)
    end;          (**< the payload of the frame *)
 end;
 Pamqp_frame = ^Tamqp_frame;

 (** connection.start method fields *)
Tamqp_connection_start = record
   version_major: uint8_t;          (**< version-major *)
   version_minor: uint8_t;          (**< version-minor *)
   server_properties: Tamqp_table; (**< server-properties *)
   mechanisms: Tamqp_bytes;        (**< mechanisms *)
   locales: Tamqp_bytes;           (**< locales *)
end;
Pamqp_connection_start = ^Tamqp_connection_start;

(** connection.start-ok method fields *)
Tamqp_connection_start_ok = record

   client_properties: Tamqp_table; (**< client-properties *)
   mechanism: Tamqp_bytes;         (**< mechanism *)
   response: Tamqp_bytes;          (**< response *)
   locale: Tamqp_bytes;            (**< locale *)
end;
Pamqp_connection_start_ok = ^Tamqp_connection_start_ok;

(** connection.secure method fields *)
Tamqp_connection_secure = record
   challenge: Tamqp_bytes; (**< challenge *)
end;
Pamqp_connection_secure = ^Tamqp_connection_secure;

(** connection.secure-ok method fields *)
Tamqp_connection_secure_ok = record
   response: Tamqp_bytes; (**< response *)
end;
 Pamqp_connection_secure_ok = ^Tamqp_connection_secure_ok;

 (** connection.blocked method fields *)
Tamqp_connection_blocked = record
  reason: Tamqp_bytes ; (**< reason *)
end;
 Pamqp_connection_blocked = ^Tamqp_connection_blocked;

 (** connection.tune method fields *)
Tamqp_connection_tune = record
   channel_max: uint16_t; (**< channel-max *)
   frame_max: uint32_t;   (**< frame-max *)
   heartbeat: uint16_t;   (**< heartbeat *)
end;
 Pamqp_connection_tune = ^Tamqp_connection_tune;

 (** connection.tune-ok method fields *)
Tamqp_connection_tune_ok = record
  channel_max: uint16_t ; (**< channel-max *)
  frame_max: uint32_t ;   (**< frame-max *)
  heartbeat: uint16_t ;   (**< heartbeat *)
end;
 Pamqp_connection_tune_ok = ^Tamqp_connection_tune_ok;

 Tamqp_connection_open= record
   virtual_host: Tamqp_bytes; (**< virtual-host *)
   capabilities: Tamqp_bytes; (**< capabilities *)
   insist: amqp_boolean_t;     (**< insist *)
 end;
  Pamqp_connection_open = ^Tamqp_connection_open;

 Tamqp_connection_open_ok = record
   known_hosts: Tamqp_bytes; (**< known-hosts *)
 end;
  Pamqp_connection_open_ok = ^Tamqp_connection_open_ok;

  Tamqp_connection_close = record
    reply_code: uint16_t ;     (**< reply-code *)
    reply_text: Tamqp_bytes; (**< reply-text *)
    class_id: uint16_t;       (**< class-id *)
    method_id: uint16_t;      (**< method-id *)
  end;
   Pamqp_connection_close = ^Tamqp_connection_close;

  Tamqp_connection_close_ok = record
     dummy: AMQPchar ; (**< Dummy field to avoid empty struct *)
  end;
   Pamqp_connection_close_ok = ^Tamqp_connection_close_ok;

  Tamqp_connection_unblocked = record
     dummy: AMQPchar; (**< Dummy field to avoid empty struct *)
  end;
  Pamqp_connection_unblocked = ^Tamqp_connection_unblocked;

  Tamqp_connection_update_secret = record
    new_secret: Tamqp_bytes; (**< new-secret *)
    reason: Tamqp_bytes;     (**< reason *)
  end;
   Pamqp_connection_update_secret = ^Tamqp_connection_update_secret;

  Tamqp_connection_update_secret_ok = record
    dummy: AMQPchar; (**< Dummy field to avoid empty struct *)
  end;
  Pamqp_connection_update_secret_ok = ^Tamqp_connection_update_secret_ok;

  Tamqp_channel_open = record
    out_of_band: Tamqp_bytes; (**< out-of-band *)
  end;
   Pamqp_channel_open = ^Tamqp_channel_open;

  Tamqp_channel_open_ok = record
    channel_id: Tamqp_bytes; (**< channel-id *)
  end;
   Pamqp_channel_open_ok = ^Tamqp_channel_open_ok;

  Tamqp_channel_flow = record
   active: amqp_boolean_t; (**< active *)
  end;
  Pamqp_channel_flow = ^Tamqp_channel_flow;

  Tamqp_channel_flow_ok = record
    active: amqp_boolean_t; (**< active *)
  end;
  Pamqp_channel_flow_ok = ^Tamqp_channel_flow_ok;

  Tamqp_channel_close = record
   reply_code: uint16_t;     (**< reply-code *)
   reply_text: Tamqp_bytes; (**< reply-text *)
   class_id: uint16_t;       (**< class-id *)
   method_id: uint16_t;      (**< method-id *)
  end;
  Pamqp_channel_close = ^Tamqp_channel_close;

  Tamqp_channel_close_ok = record
    dummy: AMQPchar; (**< Dummy field to avoid empty struct *)
  end;
  Pamqp_channel_close_ok = ^Tamqp_channel_close_ok;

  Tamqp_access_request = record
    realm     : Tamqp_bytes;
    exclusive,
    passive,
    active,
    write,
    read      : amqp_boolean_t;
  end;
  Pamqp_access_request = ^Tamqp_access_request;

  Tamqp_access_request_ok = record
   ticket: uint16_t; (**< ticket *)
  end;
  Pamqp_access_request_ok = ^Tamqp_access_request_ok;

  Tamqp_exchange_declare = record
    ticket      : uint16;
    exchange,
    &type       : Tamqp_bytes;
    passive,
    durable,
    auto_delete,
    internal,
    nowait      : amqp_boolean_t;
    arguments   : Tamqp_table;
  end;
  Pamqp_exchange_declare = ^Tamqp_exchange_declare;

  Tamqp_exchange_declare_ok = record
     dummy: AMQPchar; (**< Dummy field to avoid empty struct *)
  end;
  Pamqp_exchange_declare_ok = ^Tamqp_exchange_declare_ok;

  Tamqp_exchange_delete = record
    ticket    : uint16;
    exchange  : Tamqp_bytes;
    if_unused,
    nowait    : amqp_boolean_t;
  end;
  Pamqp_exchange_delete = ^Tamqp_exchange_delete;

  Tamqp_exchange_delete_ok = record
    dummy: AMQPchar; (**< Dummy field to avoid empty struct *)
  end;
  Pamqp_exchange_delete_ok = ^Tamqp_exchange_delete_ok;

  Tamqp_exchange_bind = record
    ticket      : uint16;
    destination,
    source,
    routing_key : Tamqp_bytes;
    nowait      : amqp_boolean_t;
    arguments   : Tamqp_table;
  end;
  Pamqp_exchange_bind = ^Tamqp_exchange_bind;

  Tamqp_exchange_bind_ok = record
    dummy: AMQPchar; (**< Dummy field to avoid empty struct *)
  end;
  Pamqp_exchange_bind_ok = ^Tamqp_exchange_bind_ok;

  Tamqp_exchange_unbind = record
    ticket      : uint16;
    destination,
    source,
    routing_key : Tamqp_bytes;
    nowait      : amqp_boolean_t;
    arguments   : Tamqp_table;
  end;
  Pamqp_exchange_unbind = ^Tamqp_exchange_unbind;

  Tamqp_exchange_unbind_ok = record
   dummy: AMQPchar ;
  end;
  Pamqp_exchange_unbind_ok = ^Tamqp_exchange_unbind_ok;

  Tamqp_queue_declare = record
    ticket      : uint16;
    queue       : Tamqp_bytes;
    passive,
    durable,
    exclusive,
    auto_delete,
    nowait      : amqp_boolean_t;
    arguments   : Tamqp_table;
  end;
  Pamqp_queue_declare = ^Tamqp_queue_declare;

  Tamqp_queue_declare_ok = record
      queue          : Tamqp_bytes;
      message_count,
      consumer_count : uint32;
  end;
  Pamqp_queue_declare_ok = ^Tamqp_queue_declare_ok;

  Tamqp_queue_bind = record
    ticket      : uint16;
    queue,
    exchange,
    routing_key : Tamqp_bytes;
    nowait      : amqp_boolean_t;
    arguments   : Tamqp_table;
  end;
  Pamqp_queue_bind = ^Tamqp_queue_bind;

  Tamqp_queue_bind_ok = record
     dummy: AMQPchar ; (**< Dummy field to avoid empty struct *)
  end;
  Pamqp_queue_bind_ok = ^Tamqp_queue_bind_ok;

  Tamqp_queue_purge = record
    ticket : uint16;
    queue : Tamqp_bytes;
    nowait : amqp_boolean_t;
  end;
  Pamqp_queue_purge = ^Tamqp_queue_purge;

  Tamqp_queue_purge_ok = record
   message_count: uint32_t;
  end;
  Pamqp_queue_purge_ok = ^Tamqp_queue_purge_ok;

  Tamqp_queue_delete = record
    ticket    : uint16;
    queue     : Tamqp_bytes;
    if_unused,
    if_empty,
    nowait    : amqp_boolean_t;
  end;
  Pamqp_queue_delete = ^Tamqp_queue_delete;

  Tamqp_queue_delete_ok = record
   message_count: uint32_t;
  end;
  Pamqp_queue_delete_ok = ^Tamqp_queue_delete_ok;

  Tamqp_queue_unbind = record
    ticket      : uint16;
    queue,
    exchange,
    routing_key : Tamqp_bytes;
    arguments   : Tamqp_table;
  end;
  Pamqp_queue_unbind = ^Tamqp_queue_unbind;

  Tamqp_queue_unbind_ok = record
    dummy: AMQPchar ; (**< Dummy field to avoid empty struct *)
  end;
  Pamqp_queue_unbind_ok = ^Tamqp_queue_unbind;

  Tamqp_basic_qos = record
    prefetch_size  : uint32;
    prefetch_count : uint16;
    global         : amqp_boolean_t;
  end;
  Pamqp_basic_qos = ^Tamqp_basic_qos;

  Tamqp_basic_qos_ok = record
   dummy: AMQPchar; (**< Dummy field to avoid empty struct *)
  end;
  Pamqp_basic_qos_ok = ^Tamqp_basic_qos_ok;

  Tamqp_basic_consume = record
    ticket       : uint16;
    queue,
    consumer_tag : Tamqp_bytes;
    no_local,
    no_ack,
    exclusive,
    nowait       : amqp_boolean_t;
    arguments    : Tamqp_table;
  end;
  Pamqp_basic_consume = ^Tamqp_basic_consume;

  Tamqp_basic_consume_ok = record
     consumer_tag: Tamqp_bytes; (**< consumer-tag *)
  end;
  Pamqp_basic_consume_ok = ^Tamqp_basic_consume_ok;

  Tamqp_basic_cancel = record
    consumer_tag : Tamqp_bytes;
    nowait       : amqp_boolean_t;
  end;
  Pamqp_basic_cancel = ^Tamqp_basic_cancel;

  Tamqp_basic_cancel_ok = record
   consumer_tag: Tamqp_bytes; (**< consumer-tag *)
  end;
  Pamqp_basic_cancel_ok = ^Tamqp_basic_cancel_ok;

  Tamqp_basic_publish = record
     ticket      : uint16;
    exchange,
    routing_key : Tamqp_bytes;
    mandatory,
    immediate   : amqp_boolean_t;
  end;
  Pamqp_basic_publish = ^Tamqp_basic_publish;

  Tamqp_basic_return = record
    reply_code  : uint16;
    reply_text,
    exchange,
    routing_key : Tamqp_bytes;
  end;
  Pamqp_basic_return = ^Tamqp_basic_return;

  Tamqp_basic_deliver = record
    consumer_tag : Tamqp_bytes;
    delivery_tag : uint64;
    redelivered  : amqp_boolean_t;
    exchange,
    routing_key  : Tamqp_bytes;
  end;
  Pamqp_basic_deliver = ^Tamqp_basic_deliver;

  Tamqp_basic_get = record
     ticket : uint16;
    queue : Tamqp_bytes;
    no_ack : amqp_boolean_t;
  end;
  Pamqp_basic_get = ^Tamqp_basic_get;

  Tamqp_basic_get_ok = record
     delivery_tag  : uint64;
    redelivered   : amqp_boolean_t;
    exchange,
    routing_key   : Tamqp_bytes;
    message_count : uint32;
  end;
  Pamqp_basic_get_ok = ^Tamqp_basic_get_ok;

  Tamqp_basic_get_empty = record
      cluster_id: Tamqp_bytes; (**< cluster-id *)
  end;
  Pamqp_basic_get_empty = ^Tamqp_basic_get_empty;

  Tamqp_basic_ack = record
    delivery_tag : uint64;
    multiple     : amqp_boolean_t;
  end;
  Pamqp_basic_ack = ^Tamqp_basic_ack;

  Tamqp_basic_reject = record
    delivery_tag : uint64;
    requeue      : amqp_boolean_t;
  end;
  Pamqp_basic_reject = ^Tamqp_basic_reject;

  Tamqp_basic_recover_async = record
   requeue: amqp_boolean_t;
  end;
  Pamqp_basic_recover_async = ^Tamqp_basic_recover_async;

  Tamqp_basic_recover = record
   requeue: amqp_boolean_t;
  end;
  Pamqp_basic_recover = ^Tamqp_basic_recover;

  Tamqp_basic_recover_ok = record
   dummy: AMQPchar;
  end;
  Pamqp_basic_recover_ok = ^Tamqp_basic_recover_ok;

  Tamqp_basic_nack = record
     delivery_tag : uint64;
     multiple,
     requeue      : amqp_boolean_t;
  end;
  Pamqp_basic_nack = ^Tamqp_basic_nack;

  Tamqp_tx_select = record
   dummy: AMQPchar;
  end;
  Pamqp_tx_select = ^Tamqp_tx_select;

  Tamqp_tx_select_ok = record
    dummy: AMQPchar;
  end;
  Pamqp_tx_select_ok = ^Tamqp_tx_select_ok;

  Tamqp_tx_commit= record
    dummy: AMQPchar;
  end;
  Pamqp_tx_commit = ^Tamqp_tx_commit;

  Tamqp_tx_commit_ok = record
    dummy: AMQPchar;
  end;
  Pamqp_tx_commit_ok = ^Tamqp_tx_commit_ok;

  Tamqp_tx_rollback = record
    dummy: AMQPchar;
  end;
  Pamqp_tx_rollback = ^Tamqp_tx_rollback;

  Tamqp_tx_rollback_ok= record
    dummy: AMQPchar;
  end;
  Pamqp_tx_rollback_ok = ^Tamqp_tx_rollback_ok;

  Tamqp_confirm_select = record
   nowait: amqp_boolean_t;
  end;
  Pamqp_confirm_select = ^Tamqp_confirm_select;

  Tamqp_confirm_select_ok= record
    dummy: AMQPchar;
  end;
  Pamqp_confirm_select_ok = ^Tamqp_confirm_select_ok;

  Tamqp_basic_properties = record
      _flags           : amqp_flags_t;
      content_type,
      content_encoding : Tamqp_bytes;
      headers          : Tamqp_table;
      delivery_mode,
      priority         : byte;
      correlation_id,
      reply_to,
      expiration,
      message_id       : Tamqp_bytes;
      timestamp        : uint64;
      &type,
      user_id,
      app_id,
      cluster_id       : Tamqp_bytes;
      function Clone(out AClone : Tamqp_basic_properties;
                                     pool : Pamqp_pool):integer;
  end;
  Pamqp_basic_properties = ^Tamqp_basic_properties;

  Tamqp_connection_properties = record
   _flags: amqp_flags_t;
    dummy: AMQPchar ;
  end;
  Pamqp_connection_properties = ^Tamqp_connection_properties;

  Tamqp_channel_properties = record
   _flags: amqp_flags_t;
    dummy: AMQPchar ;
  end;
  Pamqp_channel_properties = ^Tamqp_channel_properties;

  Tamqp_access_properties= record
   _flags: amqp_flags_t;
    dummy: AMQPchar ;
  end;
  Pamqp_access_properties = ^Tamqp_access_properties;

  Tamqp_exchange_properties= record
   _flags: amqp_flags_t;
    dummy: AMQPchar ;
  end;
  Pamqp_exchange_properties = ^Tamqp_exchange_properties;

  Tamqp_queue_properties= record
   _flags: amqp_flags_t;
    dummy: AMQPchar ;
  end;
  Pamqp_queue_properties = ^Tamqp_queue_properties;

  Tamqp_tx_properties= record
   _flags: amqp_flags_t;
    dummy: AMQPchar ;
  end;
  Pamqp_tx_properties = ^Tamqp_tx_properties;

  Tamqp_confirm_properties= record
   _flags: amqp_flags_t;
    dummy: AMQPchar ;
  end;
  Pamqp_confirm_properties = ^Tamqp_confirm_properties;

  Tamqp_message = record
     properties: Tamqp_basic_properties; (**< message properties *)
     body: Tamqp_bytes;                  (**< message body *)
     pool: Tamqp_pool;                   (**< pool used to allocate properties *)
     procedure Destroy;
  end;
  Pamqp_message = ^Tamqp_message;

  Tamqp_envelope = record
    channel      : amqp_channel_t;
    consumer_tag : Tamqp_bytes;
    delivery_tag : uint64;
    redelivered  : amqp_boolean_t;
    exchange,
    routing_key  : Tamqp_bytes;
    &message     : Tamqp_message;
    procedure destroy;
  end;
  Pamqp_envelope = ^Tamqp_envelope;

  Terror_category_enum = ( EC_base = 0, EC_tcp = 1, EC_ssl = 2 );

  Tamqp_table_entry = record
    key: Tamqp_bytes; (**< the table entry key. Its a null-terminated UTF-8
                       * string, with a maximum size of 128 bytes *)
    value: Tamqp_field_value; (**< the table entry values *)

    constructor Create(const Akey : PAnsiChar;  const Avalue : integer); overload;
    constructor Create(const Akey : PAnsiChar;  const Avalue : PAnsiChar); overload;
    constructor Create(const Akey : PAnsiChar;  const Avalue : Tamqp_table); overload;
    function clone(out Aclone : Tamqp_table_entry; pool : Pamqp_pool):integer;
  end;

 var
   amqp_empty_bytes: Tamqp_bytes;
   amqp_empty_array: Tamqp_array;
   amqp_empty_table: Tamqp_table;
   gLevel: Integer;

 const
    AMQP_VERSION_STRING = '0.9.1';
    AMQ_PLATFORM = 'win32/64';
    AMQ_COPYRIGHT = 'softwind';

     AMQP_PROTOCOL_VERSION_MAJOR = 0;    (**< AMQP protocol version major *)
     AMQP_PROTOCOL_VERSION_MINOR = 9;    (**< AMQP protocol version minor *)
     AMQP_PROTOCOL_VERSION_REVISION = 1; (**< AMQP protocol version revision \
                                          *)
     AMQP_PROTOCOL_PORT =5672;          (**< Default AMQP Port *)
     AMQP_FRAME_METHOD =1;              (**< Constant: FRAME-METHOD *)
     AMQP_FRAME_HEADER =2;              (**< Constant: FRAME-HEADER *)
     AMQP_FRAME_BODY =3;                (**< Constant: FRAME-BODY *)
     AMQP_FRAME_HEARTBEAT =8;           (**< Constant: FRAME-HEARTBEAT *)
     AMQP_FRAME_MIN_SIZE =4096;         (**< Constant: FRAME-MIN-SIZE *)
     AMQP_FRAME_END =206;               (**< Constant: FRAME-END *)
     AMQP_REPLY_SUCCESS =200;           (**< Constant: REPLY-SUCCESS *)
     AMQP_CONTENT_TOO_LARGE =311;       (**< Constant: CONTENT-TOO-LARGE *)
     AMQP_NO_ROUTE =312;                (**< Constant: NO-ROUTE *)
     AMQP_NO_CONSUMERS =313;            (**< Constant: NO-CONSUMERS *)
     AMQP_ACCESS_REFUSED =403;          (**< Constant: ACCESS-REFUSED *)
     AMQP_NOT_FOUND =404;               (**< Constant: NOT-FOUND *)
     AMQP_RESOURCE_LOCKED =405;         (**< Constant: RESOURCE-LOCKED *)
     AMQP_PRECONDITION_FAILED =406;     (**< Constant: PRECONDITION-FAILED *)
     AMQP_CONNECTION_FORCED =320;       (**< Constant: CONNECTION-FORCED *)
     AMQP_INVALID_PATH =402;            (**< Constant: INVALID-PATH *)
     AMQP_FRAME_ERROR =501;             (**< Constant: FRAME-ERROR *)
     AMQP_SYNTAX_ERROR =502;            (**< Constant: SYNTAX-ERROR *)
     AMQP_COMMAND_INVALID =503;         (**< Constant: COMMAND-INVALID *)
     AMQP_CHANNEL_ERROR =504;           (**< Constant: CHANNEL-ERROR *)
     AMQP_UNEXPECTED_FRAME =505;        (**< Constant: UNEXPECTED-FRAME *)
     AMQP_RESOURCE_ERROR =506;          (**< Constant: RESOURCE-ERROR *)
     AMQP_NOT_ALLOWED =530;             (**< Constant: NOT-ALLOWED *)
     AMQP_NOT_IMPLEMENTED =540;         (**< Constant: NOT-IMPLEMENTED *)
     AMQP_INTERNAL_ERROR =541;          (**< Constant: INTERNAL-ERROR *)

     AMQP_CONNECTION_START_METHOD = amqp_method_number_t($000A000A); (**< connection.start method id @internal \
                                        10, 10; 655370 *)
     AMQP_CONNECTION_START_OK_METHOD = amqp_method_number_t($000A000B); (**< connection.start-ok method id \
                                        @internal 10, 11; 655371 *)

     AMQP_CONNECTION_SECURE_METHOD = amqp_method_number_t($000A0014); (**< connection.secure method id \
                                        @internal 10, 20; 655380 *)
     AMQP_CONNECTION_SECURE_OK_METHOD = amqp_method_number_t($000A0015); (**< connection.secure-ok method id \
                                        @internal 10, 21; 655381 *)


     AMQP_CONNECTION_BLOCKED_METHOD = amqp_method_number_t($000A003C); (**< connection.blocked method id \
                                        @internal 10, 60; 655420 *)

     AMQP_CONNECTION_TUNE_METHOD  = amqp_method_number_t($000A001E); (**< connection.tune method id @internal \
                                       10, 30; 655390 *)

     AMQP_CONNECTION_TUNE_OK_METHOD = amqp_method_number_t($000A001F); (**< connection.tune-ok method id \
                                        @internal 10, 31; 655391 *)
     AMQP_CONNECTION_OPEN_METHOD = amqp_method_number_t($000A0028); (**< connection.open method id @internal \
                                        10, 40; 655400 *)
     AMQP_CONNECTION_OPEN_OK_METHOD = amqp_method_number_t($000A0029); (**< connection.open-ok method id \
                                        @internal 10, 41; 655401 *)
     AMQP_CONNECTION_CLOSE_METHOD = amqp_method_number_t($000A0032); (**< connection.close method id @internal \
                                        10, 50; 655410 *)
     AMQP_CONNECTION_CLOSE_OK_METHOD  = amqp_method_number_t($000A0033); (**< connection.close-ok method id \
                                        @internal 10, 51; 655411 *)
     AMQP_CONNECTION_UNBLOCKED_METHOD = amqp_method_number_t($000A003D); (**< connection.unblocked method id \
                                        @internal 10, 61; 655421 *)
     AMQP_CONNECTION_UPDATE_SECRET_METHOD = amqp_method_number_t($000A0046); (**< connection.update-secret method id \
                                        @internal 10, 70; 655430 *)
     AMQP_CONNECTION_UPDATE_SECRET_OK_METHOD  = amqp_method_number_t($000A0047); (**< connection.update-secret-ok method \
                                        id @internal 10, 71; 655431 *)
     AMQP_CHANNEL_OPEN_METHOD = amqp_method_number_t($0014000A); (**< channel.open method id @internal 20, \
                                        10; 1310730 *)
     AMQP_CHANNEL_OPEN_OK_METHOD = amqp_method_number_t($0014000B); (**< channel.open-ok method id @internal \
                                        20, 11; 1310731 *)
     AMQP_CHANNEL_FLOW_METHOD = amqp_method_number_t($00140014); (**< channel.flow method id @internal 20, \
                                        20; 1310740 *)
     AMQP_CHANNEL_FLOW_OK_METHOD = amqp_method_number_t($00140015); (**< channel.flow-ok method id @internal \
                                        20, 21; 1310741 *)
     AMQP_CHANNEL_CLOSE_METHOD = amqp_method_number_t($00140028); (**< channel.close method id @internal \
                                        20, 40; 1310760 *)
     AMQP_CHANNEL_CLOSE_OK_METHOD = amqp_method_number_t($00140029); (**< channel.close-ok method id @internal \
                                        20, 41; 1310761 *)

     AMQP_ACCESS_REQUEST_METHOD = amqp_method_number_t($001E000A); (**< access.request method id @internal \
                                        30, 10; 1966090 *)
     AMQP_ACCESS_REQUEST_OK_METHOD = amqp_method_number_t($001E000B); (**< access.request-ok method id \
                                        @internal 30, 11; 1966091 *)

     AMQP_EXCHANGE_DECLARE_METHOD = amqp_method_number_t($0028000A); (**< exchange.declare method id @internal \
                                        40, 10; 2621450 *)

     AMQP_EXCHANGE_DECLARE_OK_METHOD = amqp_method_number_t($0028000B); (**< exchange.declare-ok method id \
                                        @internal 40, 11; 2621451 *)

     AMQP_EXCHANGE_DELETE_METHOD  = amqp_method_number_t($00280014); (**< exchange.delete method id @internal \
                                        40, 20; 2621460 *)
     AMQP_EXCHANGE_DELETE_OK_METHOD = amqp_method_number_t($00280015); (**< exchange.delete-ok method id \
                                        @internal 40, 21; 2621461 *)
     AMQP_EXCHANGE_BIND_METHOD  = amqp_method_number_t($0028001E); (**< exchange.bind method id @internal \
                                        40, 30; 2621470 *)
     AMQP_EXCHANGE_BIND_OK_METHOD = amqp_method_number_t($0028001F); (**< exchange.bind-ok method id @internal \
                                        40, 31; 2621471 *)


     AMQP_EXCHANGE_UNBIND_METHOD = amqp_method_number_t($00280028); (**< exchange.unbind method id @internal \
                                        40, 40; 2621480 *)
     AMQP_EXCHANGE_UNBIND_OK_METHOD = amqp_method_number_t($00280033); (**< exchange.unbind-ok method id \
                                        @internal 40, 51; 2621491 *)
     AMQP_QUEUE_DECLARE_METHOD  = amqp_method_number_t($0032000A); (**< queue.declare method id @internal \
                                        50, 10; 3276810 *)
     AMQP_QUEUE_DECLARE_OK_METHOD = amqp_method_number_t($0032000B); (**< queue.declare-ok method id @internal \
                                        50, 11; 3276811 *)
     AMQP_QUEUE_BIND_METHOD = amqp_method_number_t($00320014); (**< queue.bind method id @internal 50, \
                                        20; 3276820 *)
     AMQP_QUEUE_BIND_OK_METHOD = amqp_method_number_t($00320015); (**< queue.bind-ok method id @internal \
                                        50, 21; 3276821 *)
     AMQP_QUEUE_PURGE_METHOD = amqp_method_number_t($0032001E); (**< queue.purge method id @internal 50, \
                                        30; 3276830 *)
     AMQP_QUEUE_PURGE_OK_METHOD = amqp_method_number_t($0032001F); (**< queue.purge-ok method id @internal \
                                        50, 31; 3276831 *)
     AMQP_QUEUE_DELETE_METHOD = amqp_method_number_t($00320028); (**< queue.delete method id @internal 50, \
                                        40; 3276840 *)
     AMQP_QUEUE_DELETE_OK_METHOD = amqp_method_number_t($00320029); (**< queue.delete-ok method id @internal \
                                        50, 41; 3276841 *)
     AMQP_QUEUE_UNBIND_METHOD = amqp_method_number_t($00320032); (**< queue.unbind method id @internal 50, \
                                        50; 3276850 *)
     AMQP_QUEUE_UNBIND_OK_METHOD = amqp_method_number_t($00320033); (**< queue.unbind-ok method id @internal \
                                        50, 51; 3276851 *)
     AMQP_BASIC_QOS_METHOD = amqp_method_number_t($003C000A); (**< basic.qos method id @internal 60, \
                                        10; 3932170 *)
     AMQP_BASIC_QOS_OK_METHOD = amqp_method_number_t($003C000B); (**< basic.qos-ok method id @internal 60, \
                                        11; 3932171 *)
     AMQP_BASIC_CONSUME_METHOD = amqp_method_number_t($003C0014); (**< basic.consume method id @internal \
                                        60, 20; 3932180 *)
     AMQP_BASIC_CONSUME_OK_METHOD = amqp_method_number_t($003C0015); (**< basic.consume-ok method id @internal \
                                        60, 21; 3932181 *)
     AMQP_BASIC_CANCEL_METHOD = amqp_method_number_t($003C001E); (**< basic.cancel method id @internal 60, \
                                        30; 3932190 *)
     AMQP_BASIC_CANCEL_OK_METHOD  = amqp_method_number_t($003C001F); (**< basic.cancel-ok method id @internal \
                                        60, 31; 3932191 *)
     AMQP_BASIC_PUBLISH_METHOD = amqp_method_number_t($003C0028); (**< basic.publish method id @internal \
                                        60, 40; 3932200 *)
     AMQP_BASIC_RETURN_METHOD  = amqp_method_number_t($003C0032); (**< basic.return method id @internal 60, \
                                        50; 3932210 *)
     AMQP_BASIC_DELIVER_METHOD = amqp_method_number_t($003C003C); (**< basic.deliver method id @internal \
                                        60, 60; 3932220 *)
     AMQP_BASIC_GET_METHOD   = amqp_method_number_t($003C0046); (**< basic.get method id @internal 60, \
                                        70; 3932230 *)
     AMQP_BASIC_GET_OK_METHOD = amqp_method_number_t($003C0047); (**< basic.get-ok method id @internal 60, \
                                        71; 3932231 *)
     AMQP_BASIC_GET_EMPTY_METHOD = amqp_method_number_t($003C0048); (**< basic.get-empty method id @internal \
                                        60, 72; 3932232 *)
     AMQP_BASIC_ACK_METHOD  = amqp_method_number_t($003C0050); (**< basic.ack method id @internal 60, \
                                        80; 3932240 *)
     AMQP_BASIC_REJECT_METHOD = amqp_method_number_t($003C005A); (**< basic.reject method id @internal 60, \
                                        90; 3932250 *)
     AMQP_BASIC_RECOVER_ASYNC_METHOD  = amqp_method_number_t($003C0064); (**< basic.recover-async method id \
                                        @internal 60, 100; 3932260 *)
     AMQP_BASIC_RECOVER_METHOD  = amqp_method_number_t($003C006E); (**< basic.recover method id @internal \
                                        60, 110; 3932270 *)
     AMQP_BASIC_RECOVER_OK_METHOD = amqp_method_number_t($003C006F); (**< basic.recover-ok method id @internal \
                                        60, 111; 3932271 *)
     AMQP_BASIC_NACK_METHOD = amqp_method_number_t($003C0078); (**< basic.nack method id @internal 60, \
                                        120; 3932280 *)
     AMQP_TX_SELECT_METHOD  = amqp_method_number_t($005A000A); (**< tx.select method id @internal 90, \
                                        10; 5898250 *)
     AMQP_TX_SELECT_OK_METHOD  = amqp_method_number_t($005A000B); (**< tx.select-ok method id @internal 90, \
                                        11; 5898251 *)
     AMQP_TX_COMMIT_METHOD  = amqp_method_number_t($005A0014); (**< tx.commit method id @internal 90, \
                                        20; 5898260 *)
     AMQP_TX_COMMIT_OK_METHOD  = amqp_method_number_t($005A0015); (**< tx.commit-ok method id @internal 90, \
                                        21; 5898261 *)
     AMQP_TX_ROLLBACK_METHOD  = amqp_method_number_t($005A001E); (**< tx.rollback method id @internal 90, \
                                        30; 5898270 *)

     AMQP_TX_ROLLBACK_OK_METHOD = amqp_method_number_t($005A001F); (**< tx.rollback-ok method id @internal \
                                        90, 31; 5898271 *)
     AMQP_CONFIRM_SELECT_METHOD = amqp_method_number_t($0055000A); (**< confirm.select method id @internal \
                                        85, 10; 5570570 *)
     AMQP_CONFIRM_SELECT_OK_METHOD = amqp_method_number_t($0055000B); (**< confirm.select-ok method id \
                                        @internal 85, 11; 5570571 *)


     AMQP_BASIC_CLASS = ($003C) ;(**< basic class id @internal 60 *)
     AMQP_BASIC_CONTENT_TYPE_FLAG =   (1 shl 15) ;(**< basic.content-type property flag *)
     AMQP_BASIC_CONTENT_ENCODING_FLAG =   (1 shl 14) ;(**< basic.content-encoding property flag *)
     AMQP_BASIC_HEADERS_FLAG = (1 shl 13) ;(**< basic.headers property flag *)
     AMQP_BASIC_DELIVERY_MODE_FLAG =  (1 shl 12) ;(**< basic.delivery-mode property flag *)
     AMQP_BASIC_PRIORITY_FLAG = (1 shl 11) ;(**< basic.priority property flag =
                                                *)
     AMQP_BASIC_CORRELATION_ID_FLAG =  (1 shl 10) ;(**< basic.correlation-id property flag *)
     AMQP_BASIC_REPLY_TO_FLAG = (1 shl 9) ;(**< basic.reply-to property flag *)
     AMQP_BASIC_EXPIRATION_FLAG =   (1 shl 8) ;(**< basic.expiration property flag *)
     AMQP_BASIC_MESSAGE_ID_FLAG =   (1 shl 7) ;(**< basic.message-id property flag *)
     AMQP_BASIC_TIMESTAMP_FLAG = (1 shl 6) ;(**< basic.timestamp property flag =
                                                *)
     AMQP_BASIC_TYPE_FLAG = (1 shl 5)      ;(**< basic.type property flag *)
     AMQP_BASIC_USER_ID_FLAG = (1 shl 4)   ;(**< basic.user-id property flag *)
     AMQP_BASIC_APP_ID_FLAG = (1 shl 3)    ;(**< basic.app-id property flag *)
     AMQP_BASIC_CLUSTER_ID_FLAG =   (1 shl 2) ;(**< basic.cluster-id property flag *)

     ERROR_CATEGORY_MASK = ($FF00);
     ERROR_MASK = $00FF;

     unknown_error_string: PAnsiChar = '(unknown error)';
     {$IFNDEF FPC}
       {$if CompilerVersion <= 23}
          base_error_strings: array[0..20] of PAnsiChar = (
       {$else}
          base_error_strings: array of PAnsiChar = [
       {$ifend}
     {$ELSE}
     base_error_strings: array[0..20] of PAnsiChar = (
     {$ENDIF}
    (* AMQP_STATUS_OK 0x0 *)
    'operation completed successfully',
    (* AMQP_STATUS_NO_MEMORY                  -0x0001 *)
    'could not allocate memory',
    (* AMQP_STATUS_BAD_AQMP_DATA              -0x0002 *)
    'invalid AMQP data',
    (* AMQP_STATUS_UNKNOWN_CLASS              -0x0003 *)
    'unknown AMQP class id',
    (* AMQP_STATUS_UNKNOWN_METHOD             -0x0004 *)
    'unknown AMQP method id',
    (* AMQP_STATUS_HOSTNAME_RESOLUTION_FAILED -0x0005 *)
    'hostname lookup failed',
    (* AMQP_STATUS_INCOMPATIBLE_AMQP_VERSION  -0x0006 *)
    'incompatible AMQP version',
    (* AMQP_STATUS_CONNECTION_CLOSED          -0x0007 *)
    'connection closed unexpectedly',
    (* AMQP_STATUS_BAD_AMQP_URL               -0x0008 *)
    'could not parse AMQP URL',
    (* AMQP_STATUS_SOCKET_ERROR               -0x0009 *)
    'a socket error occurred',
    (* AMQP_STATUS_INVALID_PARAMETER          -0x000A *)
    'invalid parameter',
    (* AMQP_STATUS_TABLE_TOO_BIG              -0x000B *)
    'table too large for buffer',
    (* AMQP_STATUS_WRONG_METHOD               -0x000C *)
    'unexpected method received',
    (* AMQP_STATUS_TIMEOUT                    -0x000D *)
    'request timed out',
    (* AMQP_STATUS_TIMER_FAILED               -0x000E *)
    'system timer has failed',
    (* AMQP_STATUS_HEARTBEAT_TIMEOUT          -0x000F *)
    'heartbeat timeout, connection closed',
    (* AMQP_STATUS_UNEXPECTED STATE           -0x0010 *)
    'unexpected protocol state',
    (* AMQP_STATUS_SOCKET_CLOSED              -0x0011 *)
    'socket is closed',
    (* AMQP_STATUS_SOCKET_INUSE               -0x0012 *)
    'socket already open',
    (* AMQP_STATUS_BROKER_UNSUPPORTED_SASL_METHOD -0x00013 *)
    'unsupported sasl method requested',
    (* AMQP_STATUS_UNSUPPORTED                -0x0014 *)
    'parameter value is unsupported'
    {$IFNDEF FPC}
      {$if CompilerVersion <= 23} );{$else} ]; {$ifend}
    {$ELSE} ); {$ENDIF}





    {$IFNDEF FPC}
        {$if CompilerVersion <= 23}
         tcp_error_strings: array[0..1] of PAnsiChar = (
         {$else}
        tcp_error_strings: array of PAnsiChar = [
        {$ifend}
    {$ELSE}
        tcp_error_strings: array[0..1] of PAnsiChar = (
    {$ENDIF}
    (* AMQP_STATUS_TCP_ERROR                  -0x0100 *)
    'a socket error occurred',
    (* AMQP_STATUS_TCP_SOCKETLIB_INIT_ERROR   -0x0101 *)
    'socket library initialization failed'
    {$IFNDEF FPC}
      {$if CompilerVersion <= 23} );{$else} ]; {$ifend}
    {$ELSE} ); {$ENDIF}

    {$IFNDEF FPC}
        {$if CompilerVersion <= 23}
        ssl_error_strings: array[0..4] of PAnsiChar =(
        {$else}
        ssl_error_strings: array of PAnsiChar =[
        {$ifend}
    {$ELSE}
        ssl_error_strings: array[0..4] of PAnsiChar =(
    {$ENDIF}
    (* AMQP_STATUS_SSL_ERROR                  -0x0200 *)
    'a SSL error occurred',
    (* AMQP_STATUS_SSL_HOSTNAME_VERIFY_FAILED -0x0201 *)
    'SSL hostname verification failed',
    (* AMQP_STATUS_SSL_PEER_VERIFY_FAILED     -0x0202 *)
    'SSL peer cert verification failed',
    (* AMQP_STATUS_SSL_CONNECTION_FAILED      -0x0203 *)
    'SSL handshake failed',
    (* AMQP_STATUS_SSL_SET_ENGINE_FAILED      -0x0204 *)
    'SSL setting engine failed'
    {$IFNDEF FPC}
      {$if CompilerVersion <= 23} );{$else} ]; {$ifend}
    {$ELSE} ); {$ENDIF}

function htobe16(x: Word): uint16;
function htobe32(x: Cardinal): Uint32;
function htobe64(x: Uint64): Uint64;
function calloc(Anum, ASize: Integer): Pointer;
function malloc(Size: NativeInt): Pointer;
procedure Free(P: Pointer);
procedure memset(var X; Value: Integer; Count: NativeInt );
procedure DebugOut(const ALevel: Integer; const AOutStr: String);
procedure memcpy(dest: Pointer; const source: Pointer; count: Integer);
procedure die_on_amqp_error( x : Tamqp_rpc_reply; const context: PAnsiChar);
function amqp_error_string2( code : integer):PAnsiChar;
procedure die_on_error( x : integer; const context: PAnsiChar);
function now_microseconds:uint64;

implementation

function Tamqp_connection_state.get_or_create_channel_pool(channel : amqp_channel_t):Pamqp_pool;
var
  Lentry : Pamqp_pool_table_entry;
  Lindex : size_t;
  Level: int;
begin
  Inc(gLevel);
  Level := gLevel;
  Lindex := channel mod POOL_TABLE_SIZE;
  Lentry := Self.pool_table[Lindex];
  while nil <> Lentry do
  begin
    if channel = Lentry.channel then
      Exit(@Lentry.pool);

    Lentry := Lentry.next;
  end;
  Lentry := malloc(sizeof(Tamqp_pool_table_entry));
  if nil = Lentry then
    Exit(nil);

  Lentry.channel := channel;
  Lentry.next := Self.pool_table[Lindex];
  Self.pool_table[Lindex] := Lentry;
  {$IFDEF _DEBUG_}
       DebugOut(Level, 'step into amqp.mem::init_amqp_pool==>');
  {$ENDIF}
  //init_amqp_pool(@Lentry.pool, Self.frame_max);
  Lentry.pool.Create(Self.frame_max);
  {$IFDEF _DEBUG_}
       DebugOut(Level, 'step over amqp.mem::init_amqp_pool.');
  {$ENDIF}
  Result := @Lentry.pool;
end;


function Tamqp_connection_state.get_channel_pool(channel : amqp_channel_t):Pamqp_pool;
var
  entry : Pamqp_pool_table_entry;
  index : size_t;
begin
  index := channel mod POOL_TABLE_SIZE;
  entry := Self.pool_table[index];
  while nil <> entry do
  begin
    if channel = entry.channel then
      Exit(@entry.pool);

    entry := entry.next
  end;
  Result := nil;
end;

function Tamqp_socket.open( host : PAnsiChar; port : integer):integer;
begin
  assert(@self<>nil);
  assert(Assigned(self.klass.open));
  Result := self.klass.open(@self, host, port, nil);
end;

function Tamqp_socket.open_noblock(Ahost : PAnsiChar;
                            Aport : integer;const Atimeout: Ptimeval):integer;
begin
  assert(@self <> nil);
  assert(Assigned(self.klass.open));
  Result := self.klass.open(@self, Ahost, Aport, Atimeout);
end;

function now_microseconds:uint64;
var
  ft : TFILETIME;
begin
  GetSystemTimeAsFileTime(ft);
  Result := ( (uint64_t(ft.dwHighDateTime)  shl  32) or uint64_t(ft.dwLowDateTime)) div
         10;
end;

function Tamqp_basic_properties.Clone(out AClone : Tamqp_basic_properties;
                                     pool : Pamqp_pool):integer;
var
  res : integer;
  function Clone_BYTES_POOL(const ASelf: Tamqp_bytes; out AClone: Tamqp_bytes; pool: Pamqp_pool): int;
  begin
      if 0 = ASelf.len then
        AClone := amqp_empty_bytes

      else
      begin
        pool.alloc_bytes( ASelf.len, AClone);
        if nil = AClone.bytes then
          Exit(Int(AMQP_STATUS_NO_MEMORY));

        memcpy(AClone.bytes, ASelf.bytes, AClone.len);
      end;
  end;

begin
  memset(AClone, 0, sizeof(AClone));
  AClone._flags := Self._flags;

  if (AClone._flags and AMQP_BASIC_CONTENT_TYPE_FLAG)>0 then begin
    Clone_BYTES_POOL(Self.content_type, AClone.content_type, pool)
  end;
  if (AClone._flags and AMQP_BASIC_CONTENT_ENCODING_FLAG)>0 then
    Clone_BYTES_POOL(Self.content_encoding, AClone.content_encoding, pool);

  if (AClone._flags and AMQP_BASIC_HEADERS_FLAG)>0 then
  begin
    res := Self.headers.Clone( AClone.headers, pool);
    if Int(AMQP_STATUS_OK) <> res then
      Exit(res);

  end;
  if (AClone._flags and AMQP_BASIC_DELIVERY_MODE_FLAG)>0 then
    AClone.delivery_mode := Self.delivery_mode;

  if (AClone._flags and AMQP_BASIC_PRIORITY_FLAG)>0 then
    AClone.priority := Self.priority;

  if (AClone._flags and AMQP_BASIC_CORRELATION_ID_FLAG)>0 then
    Clone_BYTES_POOL(Self.correlation_id, AClone.correlation_id, pool);

  if (AClone._flags and AMQP_BASIC_REPLY_TO_FLAG)>0 then
    Clone_BYTES_POOL(Self.reply_to, AClone.reply_to, pool);

  if (AClone._flags and AMQP_BASIC_EXPIRATION_FLAG)>0 then
    Clone_BYTES_POOL(Self.expiration, AClone.expiration, pool);

  if (AClone._flags and AMQP_BASIC_MESSAGE_ID_FLAG)>0 then
    Clone_BYTES_POOL(Self.message_id, AClone.message_id, pool);

  if (AClone._flags and AMQP_BASIC_TIMESTAMP_FLAG)>0 then
    AClone.timestamp := Self.timestamp;

  if (AClone._flags and AMQP_BASIC_TYPE_FLAG)>0 then ;
    Clone_BYTES_POOL(Self.&type, AClone.&type, pool);

  if (AClone._flags and AMQP_BASIC_USER_ID_FLAG)>0 then
    Clone_BYTES_POOL(Self.user_id, AClone.user_id, pool);

  if (AClone._flags and AMQP_BASIC_APP_ID_FLAG)>0 then
    Clone_BYTES_POOL(Self.app_id, AClone.app_id, pool) ;

  if (AClone._flags and AMQP_BASIC_CLUSTER_ID_FLAG)>0 then
    Clone_BYTES_POOL(Self.cluster_id, AClone.cluster_id, pool);

  Exit(Int(AMQP_STATUS_OK));

end;

function amqp_cstring_bytes( const cstr: PAnsiChar):Tamqp_bytes;
begin
  result.len := Length(cstr);
  result.bytes := PAMQPChar(cstr);
end;

function Tamqp_table.get_entry_by_key(const key : Tamqp_bytes): Pamqp_table_entry;
var
  i : integer;
begin
  {$POINTERMATH ON}

  for i := 0 to num_entries-1 do
  begin
    if entries[i].key = key  then
    begin
      Exit(@entries[i]);
    end;
  end;
  Result := nil;
  {$POINTERMATH OFF}
end;

function Tamqp_field_value.clone(out Aclone : Tamqp_field_value; pool : Pamqp_pool):integer;
var
  i, res : integer;
begin
  {$POINTERMATH ON}
  Aclone.kind := Self.kind;
  case Aclone.kind of
    Byte(AMQP_FIELD_KIND_BOOLEAN):
      Aclone.value.boolean := Self.value.boolean;

    Byte(AMQP_FIELD_KIND_I8):
      Aclone.value.i8 := Self.value.i8;

    Byte(AMQP_FIELD_KIND_U8):
      Aclone.value.u8 := Self.value.u8;

    Byte(AMQP_FIELD_KIND_I16):
      Aclone.value.i16 := Self.value.i16;

    Byte(AMQP_FIELD_KIND_U16):
      Aclone.value.u16 := Self.value.u16;

    Byte(AMQP_FIELD_KIND_I32):
      Aclone.value.i32 := Self.value.i32;

    Byte(AMQP_FIELD_KIND_U32):
      Aclone.value.u32 := Self.value.u32;

    Byte(AMQP_FIELD_KIND_I64):
      Aclone.value.i64 := Self.value.i64;

    Byte(AMQP_FIELD_KIND_U64),
    Byte(AMQP_FIELD_KIND_TIMESTAMP):
      Aclone.value.u64 := Self.value.u64;

    Byte(AMQP_FIELD_KIND_F32):
      Aclone.value.f32 := Self.value.f32;

    Byte(AMQP_FIELD_KIND_F64):
      Aclone.value.f64 := Self.value.f64;

    Byte(AMQP_FIELD_KIND_DECIMAL):
      Aclone.value.decimal := Self.value.decimal;

    Byte(AMQP_FIELD_KIND_UTF8),
    Byte(AMQP_FIELD_KIND_BYTES):
    begin
      if 0 = Self.value.bytes.len then
        Aclone.value.bytes := amqp_empty_bytes
      else
      begin
        pool.alloc_bytes(Self.value.bytes.len,
                              Aclone.value.bytes);
        if nil = Aclone.value.bytes.bytes then
          Exit(Int(AMQP_STATUS_NO_MEMORY));

        memcpy(Aclone.value.bytes.bytes, Self.value.bytes.bytes,
               Aclone.value.bytes.len);
      end;
    end;
    Byte(AMQP_FIELD_KIND_ARRAY):
    begin
      if nil = Self.value.&array.entries then
        Aclone.value.&array := amqp_empty_array

      else
      begin
        Aclone.value.&array.num_entries := Self.value.&array.num_entries;
        Aclone.value.&array.entries := pool.alloc( Aclone.value.&array.num_entries * sizeof(Tamqp_field_value));
        if nil = Aclone.value.&array.entries then
          Exit(Int(AMQP_STATUS_NO_MEMORY));

        for i := 0 to Aclone.value.&array.num_entries-1 do
        begin
          res := Self.value.&array.entries[i].clone(Aclone.value.&array.entries[i], pool);
          if Int(AMQP_STATUS_OK) <> res then
            Exit(res);

        end;
      end;
    end;
    Byte(AMQP_FIELD_KIND_TABLE):
      Exit(Self.value.table.clone(Aclone.value.table, pool));
    Byte(AMQP_FIELD_KIND_VOID):
    begin
      //
    end;
    else
      Exit(Int(AMQP_STATUS_INVALID_PARAMETER));
  end;
  Result := Int(AMQP_STATUS_OK);
  {$POINTERMATH OFF}
end;


(*********************************Tamqp_table_entry****************************)
//construct_utf8_entry
constructor Tamqp_table_entry.Create(const Akey , Avalue : PAnsiChar);
begin
  key := amqp_cstring_bytes(Akey);
  value.kind := Int(AMQP_FIELD_KIND_UTF8);
  value.value.bytes := amqp_cstring_bytes(Avalue);

end;

//construct_bool_entry
constructor Tamqp_table_entry.Create(const Akey : PAnsiChar;  const Avalue : integer);
begin
  key := amqp_cstring_bytes(Akey);
  value.kind := Int(AMQP_FIELD_KIND_BOOLEAN);
  value.value.boolean := Avalue;

end;

//construct_table_entry
constructor Tamqp_table_entry.Create(const Akey : PAnsiChar; const Avalue : Tamqp_table);
begin
  key := amqp_cstring_bytes(Akey);
  value.kind := Int(AMQP_FIELD_KIND_TABLE);
  value.value.table := Avalue;

end;

function Tamqp_table_entry.clone(out Aclone : Tamqp_table_entry; pool : Pamqp_pool):integer;
begin
  if 0 = Self.key.len then
    Exit(Int(AMQP_STATUS_INVALID_PARAMETER));

  pool.alloc_bytes(Self.key.len, Aclone.key);
  if nil = Aclone.key.bytes then
    Exit(Int(AMQP_STATUS_NO_MEMORY));

  memcpy(Aclone.key.bytes, Self.key.bytes, Aclone.key.len);
  Result := Self.value.clone(Aclone.value, pool);
end;

function Tamqp_table.clone(out Aclone : Tamqp_table; pool : Pamqp_pool):integer;
var
  i,
  res   : integer;
  label  error_out1 ;
begin
  {$POINTERMATH ON}
  Aclone.num_entries := Self.num_entries;
  if 0 = Aclone.num_entries then
  begin
    Aclone := amqp_empty_table;
    Exit(Int(AMQP_STATUS_OK));
  end;
  Aclone.entries := pool.alloc( Aclone.num_entries * sizeof(Tamqp_table_entry));
  if nil = Aclone.entries then
    Exit(Int(AMQP_STATUS_NO_MEMORY));

  for i := 0 to Aclone.num_entries-1 do
  begin
    res := Self.entries[i].clone(Aclone.entries[i], pool);
    if Int(AMQP_STATUS_OK) <> res then
       goto error_out1;
  end;
  Exit(Int(AMQP_STATUS_OK));
error_out1:
  Result := res;
  {$POINTERMATH ON}
end;

(**********************************Tamqp_socket********************************)
procedure Tamqp_socket.delete;
begin
    assert(Assigned(self.klass.delete));
    self.klass.delete(@self);

end;

function Tamqp_socket.close(Aforce : Tamqp_socket_close_enum):integer;
begin
  assert(@self <> nil);
  assert(assigned(self.klass.close));
  Result := self.klass.close(@self, Aforce);
end;

function Tamqp_socket.recv(Abuf: Pointer; Alen : size_t; Aflags : integer):ssize_t;
var Level: int;
begin
   Inc(gLevel);
   Level := gLevel;
   assert(@self <> nil);
   assert(Assigned(self.klass.recv));
   {$IFDEF _DEBUG_}
       DebugOut(Level,  'step into amqp.socket:: Aself.klass.recv==>');
   {$ENDIF}
   result := self.klass.recv(@self, Abuf, Alen, Aflags);
   {$IFDEF _DEBUG_}
       DebugOut(Level,  'step over amqp.socket::Aself.klass.recv, res=' + IntToStr(Result));
   {$ENDIF}
end;

function Tamqp_socket.send(const Abuf: Pointer; Alen : size_t; Aflags : integer):ssize_t;
begin
   assert(@self <> nil);
   assert(Assigned(self.klass.send));
   Result := self.klass.send(@self, Abuf, Alen, Aflags);
end;

class function Tamqp_time.infinite:Tamqp_time;
begin
  Result.time_point_ns := UINT64_MAX;
end;

class operator Tamqp_time.equal( l, r : Tamqp_time):Boolean;
begin
  if l.time_point_ns = r.time_point_ns then
     Result := TRUE
  else
     Result := FALSE;
end;

procedure Tamqp_envelope.destroy;
begin
  &message.Destroy;
  routing_key.Destroy;
  exchange.Destroy;
  consumer_tag.Destroy;
end;

procedure Tamqp_message.destroy;
begin
  pool.empty;
  body.Destroy;
end;

procedure empty_blocklist(x : Pamqp_pool_blocklist);
var
  i : integer;
begin
{$POINTERMATH ON}
  if x.blocklist <> nil then
  begin
    for i := 0 to x.num_blocks-1 do
       free(x.blocklist[i]);

    Dispose(x.blocklist);
  end;
  x.num_blocks := 0;
  x.blocklist := nil;
  {$POINTERMATH OFF}
end;

procedure Tamqp_pool.recycle();
begin
  empty_blocklist(@large_blocks);
  next_page := 0;
  alloc_block := nil;
  alloc_used := 0;
end;

procedure Tamqp_pool.empty();
begin
  recycle();
  empty_blocklist(@pages);
end;

function record_pool_block(x : Pamqp_pool_blocklist; block: Pointer):integer;
var
    blocklistlength : size_t;
    newbl: Pointer;
begin
{$POINTERMATH ON}
  blocklistlength := sizeof(Pointer) * (x.num_blocks + 1);
  if x.blocklist = nil then
  begin
    x.blocklist := allocMem(blocklistlength);
    if x.blocklist = nil then
       Exit(0);

  end
  else
  begin
    //newbl := realloc(x.blocklist, blocklistlength);
    reallocMem(x.blocklist, blocklistlength);
    newbl := x.blocklist;
    if newbl = nil then
      Exit(0);

    //x.blocklist := newbl;
  end;
  x.blocklist[x.num_blocks] := block;
  Inc(x.num_blocks);
  Result := 1;
  {$POINTERMATH OFF}
end;

procedure Tamqp_pool.alloc_bytes(amount : size_t;out output : Tamqp_bytes);
begin
  output.len := amount;
  output.bytes := alloc(amount);
end;

function Tamqp_pool.alloc(amount : size_t): Pointer;
var
  temp: size_t;
begin
{$POINTERMATH ON}
  if amount = 0 then
    Exit(nil);

  amount := (amount + 7) and (not 7); { round up to nearest 8-byte boundary }
  if amount > pagesize then
  begin
    //result1 := calloc(1, amount);
    result := allocmem(1*amount);
    if result = nil then
      Exit(nil);

    if  0= record_pool_block(@large_blocks, result  )then
    begin
      freeMemory(result);
      Exit(nil);
    end;
    Exit(result);
  end;

  if alloc_block <> nil then
  begin
    assert(alloc_used <= pagesize);
    if alloc_used + amount <= pagesize then
    begin
      inc(alloc_block , alloc_used);
      result := alloc_block;
      alloc_used  := alloc_used + amount;
      Exit(result);
    end;
  end;

  if next_page >= pages.num_blocks then
  begin
    alloc_block := AllocMem(1*pagesize);
    if alloc_block = nil then
       Exit(nil);

    if  0= record_pool_block(@pages, alloc_block) then
       Exit(nil);

    next_page := pages.num_blocks;
  end
  else
  begin
    alloc_block := pages.blocklist[next_page];
    Inc(next_page);
  end;
  alloc_used := amount;
  Result := alloc_block;
  {$POINTERMATH OFF}
end;

constructor Tamqp_pool.Create(pagesize : size_t);
begin
   if pagesize > 0 then
     self.pagesize := pagesize
  else
     self.pagesize := 4096;
  self.pages.num_blocks := 0;
  self.pages.blocklist := nil;
  self.large_blocks.num_blocks := 0;
  self.large_blocks.blocklist := nil;
  self.next_page := 0;
  self.alloc_block := nil;
  self.alloc_used := 0;
end;

(*
//Delphi 10.4 Sydney	34	VER340
{$if CompilerVersion >= 34}
class operator Tamqp_bytes.Assign(var Dest: Tamqp_bytes; const [ref] Src: Tamqp_bytes);
begin
   Dest.len := src.len;
   Dest.bytes := malloc(src.len);
   if Dest.bytes <> nil then
      memcpy(Dest.bytes, src.bytes, src.len);
end;
{$ELSE} *)
class operator Tamqp_bytes.Implicit(src: Pamqp_bytes): Tamqp_bytes;
begin
   Result.len := src.len;
   Result.bytes := malloc(src.len);
   if Result.bytes <> nil then
      memcpy(Result.bytes, src.bytes, src.len);

end;


function Tamqp_bytes.malloc_dup_failed:integer;
begin
  if (len <> 0)  and  (bytes = nil) then begin
    Exit(1);
  end;
  Result := 0;
end;

procedure Tamqp_bytes.Destroy;
begin
   free(bytes);
end;

constructor Tamqp_bytes.Create( Aname : PAnsiChar);
var
  len: Integer;
begin
  len := Length(Aname);
  Self.len := len;
  //Each byte in the allocated buffer is set to zero
  bytes := AllocMem(len);
  memcpy(bytes, Aname, len);
end;

constructor Tamqp_bytes.Create( amount : size_t);
begin
  len := amount;
  bytes := AllocMem(amount); { will return nil if it fails }
end;

class operator Tamqp_bytes.Equal(r, l: Tamqp_bytes) : Boolean;
begin
  if l.len = r.len then
  begin
    if (l.bytes<>nil)  and  (r.bytes<>nil) then
    begin
      if CompareMem(l.bytes, r.bytes, l.len) then
        Exit(true);

    end;
  end;
  Result := False;
end;

procedure die_on_error( x : integer; const context: PAnsiChar);
begin
  if x < 0 then begin
    WriteLn(Format('%s: %s',[context, amqp_error_string2(x)]));
    Halt(1);
  end;
end;

function amqp_error_string2( code : integer):PAnsiChar;
var
  category,
  error    : size_t;
  error_string: PAnsiChar;
begin
  category := (((-code) and ERROR_CATEGORY_MASK)  shr  8);
  error := (-code) and ERROR_MASK;
  case category of
    0://EC_base:
    begin
      if error < (sizeof(base_error_strings) div sizeof(PAMQPChar))  then
        error_string := base_error_strings[error]
      else
        error_string := unknown_error_string;
    end;

    1://EC_tcp:
    begin
      if error < (sizeof(tcp_error_strings)  div sizeof(PAMQPChar)) then
        error_string := tcp_error_strings[error]
      else
        error_string := unknown_error_string;
    end;

    2://EC_ssl:
    begin
      if error < (sizeof(ssl_error_strings) div sizeof(PAMQPChar)) then
        error_string := ssl_error_strings[error]

      else
        error_string := unknown_error_string;
    end;

    else
      error_string := unknown_error_string;

  end;
  Result := error_string;
end;

procedure die_on_amqp_error( x : Tamqp_rpc_reply; const context: PAnsiChar);
var
  stderr: string;
  CONNECTION_CLOSE: Pamqp_connection_close;
  CHANNEL_CLOSE: Pamqp_channel_close;
begin
  case x.reply_type of
    AMQP_RESPONSE_NORMAL:
      exit;
    AMQP_RESPONSE_NONE:
      WriteLn(Format('%s: missing RPC reply type!',[context]));

    AMQP_RESPONSE_LIBRARY_EXCEPTION:
      WriteLn(Format('%s: %s',[context, amqp_error_string2(x.library_error)]));

    AMQP_RESPONSE_SERVER_EXCEPTION:
      case x.reply.id of
        AMQP_CONNECTION_CLOSE_METHOD:
        begin
          CONNECTION_CLOSE := Pamqp_connection_close(x.reply.decoded);
          stderr := Format( '%s: server connection error %uh, message: %.*s\n',
                  [context, CONNECTION_CLOSE.reply_code, CONNECTION_CLOSE.reply_text.len,
                  PAMQPChar(CONNECTION_CLOSE.reply_text.bytes)]);
          WriteLn(stderr);
        end;
        AMQP_CHANNEL_CLOSE_METHOD:
        begin
          CHANNEL_CLOSE := Pamqp_channel_close(x.reply.decoded);
          stderr := Format( '%s: server channel error %uh, message: %.*s\n',
                  [context, CHANNEL_CLOSE.reply_code, CHANNEL_CLOSE.reply_text.len,
                  PAMQPChar(CHANNEL_CLOSE.reply_text.bytes)]);
          WriteLn(stderr);
        end;
        else
          WriteLn(Format('%s: unknown server error, method id 0x%08X',[context, x.reply.id]));

      end;

  end;
  Halt(1);
end;

function Tamqp_connection_state.get_sockfd:integer;
begin
  if Assigned(Fsocket) and Assigned(Fsocket.klass.get_sockfd) then
     Result := Fsocket.klass.get_sockfd(Fsocket)
  else
     Result := -1;
end;

procedure Tamqp_connection_state.set_socket(Asocket : Pamqp_socket);
begin

   if Assigned(Fsocket) then
   begin
      assert(Assigned(Fsocket.klass.delete));
      Fsocket.klass.delete(Fsocket);
   end;

   Fsocket := Asocket;
end;

function BinToString(const s: RawByteString): String;
begin
  assert(length(s) mod SizeOf(result[1])=0);
  setlength(result, length(s) div SizeOf(result[1]));
  move(s[1], result[1], length(result)*SizeOf(result[1]));
end;

function StringToBin(const s: String): RawByteString;
begin
  setlength(result, length(s)*SizeOf(s[1]));
  move(s[1], result[1], length(result));
end;

procedure memcpy(Dest: Pointer; const source: Pointer; count: Integer);
begin
   move(Source^,Dest^, Count);
end;

procedure DebugOut(const ALevel: Integer; const AOutStr: String);
var
   I: int;
   s1, s2, res: string;
begin

   for  I:= 1 to ALevel do
   begin
      s1 := s1 + ' ';
      s2 := s2 + '#';
   end;
   Res := s2 + s1;
   Writeln(res + AOutStr);
end;

procedure memset(var X; Value: Integer; Count: NativeInt );
begin
   FillChar(X, Count, VALUE);
end;

procedure Free(P: Pointer);
begin
   FreeMemory(P);
end;

function malloc(Size: NativeInt): Pointer;
begin
   Result := AllocMem(Size);
end;

function calloc(Anum, ASize: Integer): Pointer;
begin
  Result := AllocMem(Anum*ASize);
end;

function htobe16(x: Word): uint16;
begin
  Result := htons(x);
end;

function htobe32(x: Cardinal): Uint32;
begin
  Result := htonl(x);
end;

function htobe64(x: Uint64): Uint64;
begin
   if 1=htonl(1) then
      Result := (x)
   else
      Result := uint64_t(htonl(x and $FFFFFFFF) shl 32) or htonl(x shr 32);
end;

{var
 intim,intim2:PInteger;
 x:Integer;
begin
  x := 0;
  intim := AllocMem(SizeOf(Integer)*imsize);
  intim2 := intim;
//  dereference pointer intim2, store something, then increment pointer
  intim2^ := x;
  Inc(intim2);

  FreeMem(intim);}

initialization
   amqp_empty_bytes.len:=0; amqp_empty_bytes.bytes:= nil;
   amqp_empty_array.num_entries:= 0; amqp_empty_array.entries:= nil;
   amqp_empty_table.num_entries:= 0; amqp_empty_table.entries:= nil;
end.
