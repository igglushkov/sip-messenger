-module(sip_messenger_server).

-export([sip_authorize/3, sip_register/2, sip_message/2, sip_get_user_pass/4]).

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


sip_register(Req, _Call) ->
    {ok, [{from_scheme, FromScheme}, {from_user, FromUser}, {from_domain, FromDomain}]} =
        nksip_request:get_metas([from_scheme, from_user, from_domain], Req),

    {ok, [{to_scheme, ToScheme}, {to_user, ToUser}, {to_domain, ToDomain}]} =
        nksip_request:get_metas([to_scheme, to_user, to_domain], Req),

    io:format("sip_server: sip_register(From ~p)~n", [FromUser]),
    case {FromScheme, FromUser, FromDomain} of
        {ToScheme, ToUser, ToDomain} ->
            io:format("REGISTER OK: ~p~n", [{ToUser, ToDomain}]),
            {reply, nksip_registrar:request(Req)};
        _ ->
            {reply, forbidden}
    end.


sip_message(Req, Call) ->
    {ok, [{from_scheme, FromScheme},
          {from_user, FromUser},
          {from_domain, FromDomain}]} =
        nksip_request:get_metas([from_scheme, from_user, from_domain], Req),

    {ok, [{to_user, ToUser},
          {to_domain, ToDomain},
          {body, Body}]} = nksip_request:get_metas([to_user, to_domain, body], Req),
          
    case FromUser == ToUser of
        true ->
            {reply, 403};
        false ->
            io:format("SIP MESSAGE From: ~p, To: ~p, ToDomain: ~p Body: ~p ~n",
                      [FromUser, ToUser, ToDomain, Body]),
            FromUri = uri_tools:build_user_uri(FromScheme, FromUser, FromDomain),
            io:format("FromUri: ~p~n", [FromUri]),
            Contacts = nksip_registrar:find(sip_messenger_server, {sip, ToUser, ToDomain}),
            case Contacts of
                [] ->
                    io:format("User ~p not found~n", [ToUser]),
                    {reply, 404};
                [Contact] ->
                    {ok, ContentType} = nksip_request:get_meta(content_type, Req),
                    io:format("ContentType: ~p~n", [ContentType]),
                    case ContentType of
                        {<<"text/plain">>, _} ->
                            UserUri = uri_tools:get_user_uri(Contact),
                            Opts = [{body, Body},
                                    {content_type, ContentType},
                                    {from, FromUri},
                                    {to, UserUri}],
                            case nksip_uac:message(sip_messenger_server, UserUri, Opts) of
                                {ok, 200, _} ->
                                    io:format("MESSAGE was delivered to ~p~n", [UserUri]),
                                    {reply, 200};
                                {ok, Code, _} ->
                                    io:format("MESSAGE failed with code ~w", [Code]),
                                    {reply, Code};
                                {error, Error} ->
                                    io:format("MESSAGE error: ~w", [Error]),
                                    {reply, 480}
                            end;
                        %% This ContentType used in Twinkle for indicating user typing
                        {<<"application/im-iscomposing+xml">>, _} ->
                            {reply, 200}
                    end
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
