unit amqp.time;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
{$INCLUDE config.inc}
uses {$IFNDEF FPC}
         {$IFDEF _WIN32}
            Net.Winsock2,
         {$ELSE}
            Net.SocketAPI,
         {$ENDIF}

         Winapi.Windows,
     {$ELSE}
         Windows, winsock2, //WS2tcpip,
     {$ENDIF} AMQP.Types;


  function amqp_time_from_now(var Atime : Tamqp_time;const Atimeout: Ptimeval):integer;
  function amqp_time_s_from_now(var Atime : Tamqp_time; Aseconds : integer):integer;

  function amqp_time_ms_until( Atime : Tamqp_time):integer;
  function amqp_time_tv_until( Atime : Tamqp_time; Ain: Ptimeval; Aout: PPtimeval):integer;
  function amqp_time_has_past( Atime : Tamqp_time):integer;
  function amqp_time_first( l, r : Tamqp_time):Tamqp_time;


const
 //要指定 uint64_t,否则会引发计算错误
 AMQP_MS_PER_S: uint32_t  =1000;
 AMQP_US_PER_MS: uint32_t =1000;
 AMQP_NS_PER_S: uint64_t  =1000*1000*1000; //每秒=多少纳秒
 AMQP_NS_PER_MS: uint64_t =1000*1000; //每毫秒=多少纳秒
 AMQP_NS_PER_US: uint32_t =1000; //每微秒=多少纳秒

var
  NS_PER_COUNT: double ;

implementation

function amqp_get_monotonic_timestamp:uint64;
var
  perf_count,
  perf_frequency : Int64;//LARGE_INTEGER;
begin
  //static double NS_PER_COUNT = 0;
  if 0 = NS_PER_COUNT then
  begin
    if  not QueryPerformanceFrequency(perf_frequency) then
      Exit(0);

    //NS_PER_COUNT := double(AMQP_NS_PER_S / perf_frequency);
    NS_PER_COUNT := (AMQP_NS_PER_S / perf_frequency);
  end;
  if  not QueryPerformanceCounter(perf_count) then
     Exit(0);

  Result := uint64_t(Round(perf_count * NS_PER_COUNT));
end;

function amqp_time_from_now(var Atime : Tamqp_time;const Atimeout: Ptimeval):integer;
var
  now_ns,
  delta_ns : Uint64;
  LValue: int;
  Lns: Int64;
begin
  //assert(nil <> Atime);
  if nil = Atimeout then
  begin
    Atime := Tamqp_time.infinite;
    LValue := Integer(AMQP_STATUS_OK);
    Exit(LValue);
  end;
  if (Atimeout.tv_sec < 0)  or
     (Atimeout.tv_usec < 0) then
  begin
    LValue := Integer(AMQP_STATUS_INVALID_PARAMETER);
    Exit(LValue);
  end;

  Lns := Atimeout.tv_sec * AMQP_NS_PER_S;
  delta_ns := Lns +
              Atimeout.tv_usec * AMQP_NS_PER_US;
  now_ns := amqp_get_monotonic_timestamp();

  if 0 = now_ns then
  begin
    Exit(Integer(AMQP_STATUS_TIMER_FAILURE));
  end;

  Atime.time_point_ns := now_ns + delta_ns;

  if (now_ns > Atime.time_point_ns)  or
     (delta_ns > Atime.time_point_ns) then
  begin
    Exit(Integer(AMQP_STATUS_INVALID_PARAMETER));
  end;
  Result := Integer(AMQP_STATUS_OK);
end;


function amqp_time_s_from_now(var Atime : Tamqp_time; Aseconds : integer):integer;
var
  now_ns,
  delta_ns : uint64;
begin
  //assert(nil <> Atime);
  if 0 >= Aseconds then
  begin
    Atime := Tamqp_time.infinite;
    Exit(Integer(AMQP_STATUS_OK));
  end;
  now_ns := amqp_get_monotonic_timestamp();
  if 0 = now_ns then
  begin
    Exit(Integer(AMQP_STATUS_TIMER_FAILURE));
  end;
  delta_ns := uint64_t(Aseconds * AMQP_NS_PER_S);
  Atime.time_point_ns := now_ns + delta_ns;
  if (now_ns > Atime.time_point_ns)  or
     (delta_ns > Atime.time_point_ns) then
  begin
    Exit(Integer(AMQP_STATUS_INVALID_PARAMETER));
  end;
  Result := Integer(AMQP_STATUS_OK);
end;





function amqp_time_ms_until( Atime : Tamqp_time):integer;
var
  now_ns,
  delta_ns : uint64;
  left_ms  : integer;
begin
  if UINT64_MAX = Atime.time_point_ns then
  begin
    Exit(-1);
  end;
  if 0 = Atime.time_point_ns then
  begin
    Exit(0);
  end;
  now_ns := amqp_get_monotonic_timestamp();
  if 0 = now_ns then
  begin
    Exit(Integer(AMQP_STATUS_TIMER_FAILURE));
  end;
  if now_ns >= Atime.time_point_ns then
  begin
    Exit(0);
  end;
  delta_ns := Atime.time_point_ns - now_ns;
  left_ms := delta_ns div AMQP_NS_PER_MS;
  Result := left_ms;
end;


function amqp_time_tv_until( Atime : Tamqp_time; Ain: Ptimeval; Aout: PPtimeval):integer;
var
  now_ns,
  delta_ns : uint64;
begin
  assert(Ain <> nil);
  if UINT64_MAX = Atime.time_point_ns then
  begin
    Aout^ := nil;
    Exit(Integer(AMQP_STATUS_OK));
  end;
  if 0 = Atime.time_point_ns then
  begin
    Ain.tv_sec := 0;
    Ain.tv_usec := 0;
    Aout^ := Ain;
    Exit(Integer(AMQP_STATUS_OK));
  end;
  now_ns := amqp_get_monotonic_timestamp();
  if 0 = now_ns then
  begin
    Exit(Integer(AMQP_STATUS_TIMER_FAILURE));
  end;
  if now_ns >= Atime.time_point_ns then
  begin
    Ain.tv_sec := 0;
    Ain.tv_usec := 0;
    Aout^ := Ain;
    Exit(Integer(AMQP_STATUS_OK));
  end;
  delta_ns := Atime.time_point_ns - now_ns;
  Ain.tv_sec := delta_ns div AMQP_NS_PER_S;
  Ain.tv_usec :=(delta_ns mod AMQP_NS_PER_S) div AMQP_NS_PER_US;
  Aout^ := Ain;
  Result := Integer(AMQP_STATUS_OK);
end;


function amqp_time_has_past( Atime : Tamqp_time):integer;
var
  now_ns : uint64;
begin
  if UINT64_MAX = Atime.time_point_ns then
  begin
    Exit(Integer(AMQP_STATUS_OK));
  end;
  now_ns := amqp_get_monotonic_timestamp();
  if 0 = now_ns then
  begin
    Exit(Integer(AMQP_STATUS_TIMER_FAILURE));
  end;
  if now_ns > Atime.time_point_ns then
  begin
    Exit(Integer(AMQP_STATUS_TIMEOUT));
  end;
  Result := Integer(AMQP_STATUS_OK);
end;


function amqp_time_first( l, r : Tamqp_time):Tamqp_time;
begin
  if l.time_point_ns < r.time_point_ns then
    Exit(l);

  Result := r;
end;




initialization
  NS_PER_COUNT := 0;

end.
