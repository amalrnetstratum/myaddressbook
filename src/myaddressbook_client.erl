-module(myaddressbook_client).

-behaviour(tivan_server).

-export([start_link/0,

		insert_address_api/4,
		insert_address/1,
		
		view_address_api/4,
		view_address/1]).

-export([init/1]).

init([])	->
	TableDef =
		#{my_addresses	=>
				#{columns	=>
						#{name		=>
								#{type	=>	binary
                  ,unique=> true
								,limit	=>	{3,30}}
						,number	=>
								#{type	=>	integer}}
        }
     },
  {ok, TableDef}.

start_link()	->
	tivan_server:start_link({local, ?MODULE}, ?MODULE, [], []).

insert_address_api(_Headers, ReqParams, _PathInfo, _State) ->
	lager:info("Request : insert_address_api. Body :~p",[ReqParams]),
	case catch insert_address(ReqParams) of
    {X, Reason} when X == 'EXIT'; X == error  ->
      lager:error("Request : insert_address_api. Reason : ~p", [Reason]),
      {ok, [#{success => false}]};
    Result  ->
	    {ok, [Result#{success => true}]}
  end.

insert_address(Address) when is_map(Address) ->
	Number = maps:get(number, Address),
  case catch re:run(Number, "^[1-9][0-9]{9}$") of
    {'EXIT',_} ->
      lager:error("Invalid Number : ~p", [Number]),
      {error, <<"Invalid Number">>};
    nomatch ->
      lager:error("Invalid Number : ~p", [Number]),
      {error, <<"Invalid Number">>};
    _ ->
      tivan_server:put(?MODULE, my_addresses, Address#{number => binary_to_integer(Number)})
  end.

view_address_api(_Headers, ReqParams, _PathInfo, _State) ->
  io:format("~p",[ReqParams]),
	lager:info("Request : view_address_api. Body :~p",[ReqParams]),
	case catch view_address(ReqParams) of
    {X, Reason} when X == 'EXIT'; X == error  ->
      lager:error("Error in view_address_api. Reason : ~p", [Reason]),
      {ok, #{success => false}};
    [Result]  ->
    	{ok, [Result#{success => true}]};
    []        ->
      {ok, [#{success => false, error => nodata}]}
  end.

view_address(Address) when is_map(Address) ->
	tivan_server:get(?MODULE, my_addresses, Address).

% {error, Reason} ->
      % lager:error("Room exists failed ~p", [Reason]),
      % Response = #{<<"status">> => <<"failure">>
                   % ,<<"reason">> => Reason
                  % },
      % {ok, Response};
% {ok, #{<<"status">> => <<"success">>,
                  % <<"room_exists">> => Value}}
