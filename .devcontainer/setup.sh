#!/bin/bash

set -e

# Update Debian mirrors for old Erlang 21.3 image
sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list
sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list


# Install dependencies
apt-get update
apt-get install -y build-essential git curl ca-certificates net-tools lsof nano


# Download and install rebar3
curl -fsSL https://github.com/erlang/rebar3/releases/download/3.14.0/rebar3 -o /usr/local/bin/rebar3
chmod +x /usr/local/bin/rebar3
rebar3 --version


# Compile the project
cd /workspaces/sip_messenger
rebar3 compile

erl -noshell \
-name sip@127.0.0.1 \
-eval '
case mnesia:create_schema([node()]) of
    ok ->
        io:format("Schema created~n");
    {error,{_,{already_exists,_}}} ->
        io:format("Schema already exists~n");
    Error ->
        io:format("Schema error: ~p~n",[Error])
end,
halt().
'