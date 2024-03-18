defmodule PollyStub do
  @moduledoc """
  Used in staging to reduce costs by stubbing out Polly calls
  """

  def synthesize_speech(_, _, _) do
    {:ok, %{"Body" => " ", "ContentType" => "audio/mpeg"}, nil}
  end
end
