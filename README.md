# Watts

MBTA text-to-speech service

## Prerequisites

* [asdf](https://asdf-vm.com/)
* [direnv](https://direnv.net/)

## Development

* Run `asdf install` from the repository root.
* `mix deps.get` to fetch dependencies.
* Copy `.envrc.template` to `.envrc`, then edit `.envrc` and make sure all required environment variables are set. When finished, run `direnv allow` to activate them.
* To start the server, run `iex -S mix`.
