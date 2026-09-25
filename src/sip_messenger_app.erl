%%%-------------------------------------------------------------------
%% @doc sip_messenger public API
%% @end
%%%-------------------------------------------------------------------

-module(sip_messenger_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    sip_messenger_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
