-module(sip_messenger_server).

-export([sip_authorize/3, sip_get_user_pass/4]).

-include_lib("nkserver/include/nkserver_module.hrl").


sip_get_user_pass(User, <<"nksip">>, _Req, _Call) ->
    io:format("sip_get_user_pass for ~p~n", [User]),
    find_pass_userauth(User).


sip_authorize(AuthList, Req, _Call) ->
    Method = nksip_sipmsg:get_meta(method, Req),
    FromUser = nksip_sipmsg:get_meta(from_user, Req),
    io:format("sip_authorize: Method=~p, FromUser=~p~n", [Method, FromUser]),
    io:format("sip_authorize: AuthList=~p~n", [AuthList]),
    case lists:member(dialog, AuthList) orelse lists:member(register, AuthList) of
        true ->
            io:format("Authorized (dialog or register)~n", []),
            ok;
        false ->
            case proplists:get_value({digest, <<"nksip">>}, AuthList) of
                true ->
                    io:format("Authorized (digest ok)~n", []),
                    ok;
                false ->
                    io:format("Forbidden (digest failed)~n", []),
                    forbidden;
                undefined ->
                    io:format("Challenge (no digest yet)~n", []),
                    {proxy_authenticate, <<"nksip">>}
            end
    end.

%% Private functions
get_users_from_json() ->
    {ok, Binary} = file:read_file("priv/users.json"),
    Output = jsx:decode(Binary),
    #{<<"users">> := Users} = Output,
    Users.


find_pass_userauth(User) ->
    Users = get_users_from_json(),
    Filter = fun(UserMap) ->
                     UserName = maps:get(<<"userName">>, UserMap),
                     User == UserName
             end,
    UserList = lists:filter(Filter, Users),
    case UserList of
        [] -> <<>>;
        _ ->
            [UserMap] = UserList,
            #{<<"userPass">> := UserPass} = UserMap,
            UserPass
    end.
