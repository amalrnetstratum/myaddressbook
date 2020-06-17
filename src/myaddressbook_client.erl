-module(myaddressbook_client).
%hello
-behaviour(tivan_server).

-export([start_link/0,
 		insert_address_api/4,
		view_address_api/4,
		viewtag_address_api/4,
		tag_address_api/4]).

-export([init/1]).

-define(ALLOWED_TAGS, [<<"FAVORITES">>, <<"BLOCKED">>]).

init([]) ->
  TableDef =
    #{my_addresses => #{columns	=>
                         #{name => #{type => binary,
    								unique => true
    								,limit => {3,30}}
    					  ,number => #{type => integer}}
                          ,tags => address_status
    				   }
    },
  {ok, TableDef}.

start_link() ->
  tivan_server:start_link({local, ?MODULE}, ?MODULE, [], []).

insert_address_api(_Headers, ReqParams, _PathInfo, _State) ->
  lager:info("Request : insert_address_api. Body :~p",[ReqParams]),
  case insert_address(ReqParams) of
    {error, Reason} ->
      {ok, [#{success => false, error => Reason}]};
    Result  ->
      {ok, [Result#{success => true}]}
  end.

insert_address(Address) when is_map(Address) ->
  Number = maps:get(number, Address),
  case re:run(Number, "^[1-9][0-9]{9}$") of
    nomatch ->
      lager:error("Invalid Number : ~p", [Number]),
      {error, <<"Invalid Number">>};
    _ ->
      tivan_server:put(?MODULE, my_addresses, Address#{number => binary_to_integer(Number)})
  end.

view_address_api(_Headers, ReqParams, _PathInfo, _State) ->
  io:format("~p",[ReqParams]),
  lager:info("Request : view_address_api. Body :~p",[ReqParams]),
  case view_address(ReqParams) of
    {error, Reason} -> 
	  lager:error("Error in view_address. Reason : ~p", [Reason]),
	  {ok, #{success => false, error => Reason}};
    [Result]  ->
	  {ok, [Result#{success => true}]};
    [] ->
	  {ok, [#{success => false, error => nodata}]}
  end.

view_address(Address) when is_map(Address) ->
  tivan_server:get(?MODULE, my_addresses, Address).

viewtag_address_api(_Headers, ReqParams, _PathInfo, _State) ->
  io:format("~p",[ReqParams]),
  lager:info("Request : viewtag_address_api. Body :~p",[ReqParams]),
  case view_tag(ReqParams) of
    {error, Reason} ->
      {ok, #{success => false, error => Reason}};
    [] -> 
	  {ok, [#{success => false, error => nodata}]};
    Results ->
      {ok, [begin
              Name = maps:get(name, X),
              #{success => true, name => Name}
            end || X <- Results]}
  end.

view_tag(Tags) when is_map(Tags) ->
  Tag = maps:get(tags, Tags, <<>>),
  case tivan_server:get(?MODULE, my_addresses, #{match => #{tags => [Tag]}}) of
    {error, Reason} -> {error, Reason};
	Results -> filter_tag_objects(Results, string:uppercase(Tag), [])
  end.

filter_tag_objects([], _InputTag, Acc) ->
  Acc;
filter_tag_objects([Object | RestObject], InputTag, Acc) ->
  Tag = maps:get(tags, Object, []),
  case lists:member(InputTag, Tag) of
    true -> filter_tag_objects(RestObject, InputTag, [Object | Acc]);
    false -> filter_tag_objects(RestObject, InputTag, Acc)
  end.
  
tag_address_api(_Headers, ReqParams, _PathInfo, _State) ->
  io:format("~p",[ReqParams]),
  lager:info("Request : tag_address_api. Body :~p",[ReqParams]),
  Tag = maps:get(tag, ReqParams, []),
  TagU = string:uppercase(Tag),
  case view_address(maps:remove(tag, ReqParams)) of
    {error, Reason} ->
	  lager:error("Error in view_address. Reason : ~p", [Reason]),
	  {ok, #{success => false, error => Reason}};
    [Result]  ->
	  case lists:member(TagU, ?ALLOWED_TAGS) of
	    true ->
		  tivan_server:remove(?MODULE, my_addresses, Result),
		  tivan_server:put(?MODULE, my_addresses, Result#{tags => [TagU]}),
	      {ok, [Result#{success => true, tags => [TagU]}]};
		false ->
	      {ok, [#{success => false, error => wrong_tag}]}
	  end;
    [] ->
	      {ok, [#{success => false, error => nodata}]}
  end.
