-module(uri_tools).

-include_lib("nklib/include/nklib.hrl").

-export([get_user_uri/1, build_user_uri/3]).


%% @doc Returns uri in format <scheme:username@domain:port>.
-spec get_user_uri(SipUri :: tuple()) -> nksip:user_uri().

get_user_uri(SipUri) ->
    {Scheme, User, Domain, Port} =
        {atom_to_binary(SipUri#uri.scheme, latin1),
         SipUri#uri.user,
         SipUri#uri.domain,
         integer_to_binary(SipUri#uri.port)},
    <<Scheme/binary, ":", User/binary, "@", Domain/binary, ":", Port/binary>>.


%% @doc Returns uri in format <scheme:username@domain>.
-spec build_user_uri(Scheme :: atom(), User :: binary(), Domain :: binary()) -> nksip:user_uri().

build_user_uri(Scheme, User, Domain) ->
    SchemeBinary = atom_to_binary(Scheme, latin1),

    <<SchemeBinary/binary, ":", User/binary, "@", Domain/binary>>.

