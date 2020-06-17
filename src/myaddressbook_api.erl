-module(myaddressbook_api).

-behaviour(bifrost_api).

-export([start_link/0
        ,initialize/0]).

-export([
		init/1,
		handle_options/4]).

start_link() ->
  bifrost_api:start_link({local,  ?MODULE}, ?MODULE, [], []).

initialize() ->
  bifrost_api:initialize(?MODULE).

init([]) ->
  Routes = 
    [#{path => "/insert/[:name]/[:number]",
      auth => false,
	  functions => #{get => {myaddressbook_client, insert_address_api},
					put => {myaddressbook_client, insert_address_api},
					options => {myaddressbook_api, handle_options}}}
	,#{path => "/view/name/[:name]",
      auth => false,
	  functions => #{get => {myaddressbook_client, view_address_api},
	  			    put => {myaddressbook_client, view_address_api},
	  			    options => {myaddressbook_api, handle_options}}}
	,#{path => "/view/uuid/[:uuid]",
      auth => false,
	  functions => #{get => {myaddressbook_client, view_address_api},
	  			    put => {myaddressbook_client, view_address_api},
	  			    options => {myaddressbook_api, handle_options}}}
    ,#{path => "/view/tag/[:tags]",
      auth => false,
	  functions => #{get => {myaddressbook_client, viewtag_address_api},
					put => {myaddressbook_client, viewtag_address_api},
					options => {myaddressbook_api, handle_options}}}
    ,#{path => "/tag/uuid/[:uuid]/[:tag]",
      auth => false,
	  functions => #{get => {myaddressbook_client, tag_address_api},
					put => {myaddressbook_client, tag_address_api},
					options => {myaddressbook_api, handle_options}}}
	,#{path => "/tag/name/[:name]/[:tag]",
      auth => false,
      functions => #{get => {myaddressbook_client, tag_address_api},
					put => {myaddressbook_client, tag_address_api},
					options => {myaddressbook_api, handle_options}}}
    ],
  {ok, Routes}.

handle_options(Headers, ReqParams, _PathInfo, _State) ->
  lager:info("Got the headers for options:~p",[Headers]),
  lager:info("Got the request for the options:~p",[ReqParams]),
  ACRequestHeaders = maps:get(<<"access-control-request-headers">>, Headers, <<"*">>),
  RequestMethod = maps:get(<<"access-control-request-method">>, Headers),
  lager:info("ACRequestHeaders:~p~n",[ACRequestHeaders]),
  ResponseHeaders =  
  	#{<<"content-type">>				=> <<"application/json;charset=utf-8">>,
  	<<"Access-Control-Allow-Headers">>	=> ACRequestHeaders,
  	<<"Access-Control-Allow-Methods">>	=> <<RequestMethod/binary, ",OPTIONS">>,
  	<<"Access-Control-Max-Age">>		=> <<"1728000">>},
  lager:info("ResponseHeaders for options:~p:",[ResponseHeaders]),
  {204, [], ResponseHeaders}.

