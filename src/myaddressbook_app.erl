%%%-------------------------------------------------------------------
%% @doc myaddressbook public API
%% @end
%%%-------------------------------------------------------------------

-module(myaddressbook_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    myaddressbook_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
