# Watts

MBTA text-to-speech service

## Prerequisites

* [asdf](https://asdf-vm.com/)
* [direnv](https://direnv.net/)

## Development

* Run `asdf install` from the repository root.
* `mix deps.get` to fetch dependencies.
* Copy `.envrc.template` to `.envrc`, then edit `.envrc` and make sure all
  required environment variables are set. When finished, run `direnv allow` to
  activate them.
* To start the server, run `iex -S mix`.

**Note:** There is no automatic code reloading in development. To pick up code
changes while the server is running, use the `recompile` command in IEx.

## API

The main API endpoint is `/tts`, which accepts JSON POST requests with the
following parameters:
* `text` - The text to generate, in SSML format. Required.
* `voice_id` - The id of the Polly voice to use. Required.
* `output_format` - The format to return. Defaults to `mp3`

An `x-api-key` HTTP header must also be set to the value specified in the
`WATTS_API_KEY` environment variable.

Example request, using `curl` and a local development instance of the app:

    curl localhost:4005/tts \
      --output voice.mp3 \
      --header "x-api-key: your_api_key_here" \
      --json '{"voice_id": "Matthew", "text": "<speak>Your text here.</speak>"}'

Note to synthesize new (uncached) voice lines, the `WATTS_ENABLE_POLLY`
environment variable must be `true`. **This incurs a cost per character of
text**, so avoid large amounts of text or a large number of unique lines.
