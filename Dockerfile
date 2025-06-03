ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27.3.4
ARG ALPINE_VERSION=3.21.3

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} as build

WORKDIR /root
COPY . .
RUN apk add --no-cache git && \
    mix do local.hex --force, local.rebar --force && \
    mix deps.get --only prod && \
    MIX_ENV=prod mix release

# The one the elixir image was built with
FROM alpine:${ALPINE_VERSION}

WORKDIR /root
COPY --from=build /root/_build/prod/rel/watts /watts
RUN apk add --no-cache libssl1.1 dumb-init libstdc++ libgcc ncurses-libs

ENV TERM=xterm LANG=C.UTF-8 ERL_CRASH_DUMP_SECONDS=0

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
HEALTHCHECK CMD ["/watts/bin/watts", "rpc", "1 + 1"]
CMD ["/watts/bin/watts", "start"]
