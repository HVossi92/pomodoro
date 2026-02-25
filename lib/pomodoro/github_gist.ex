defmodule Pomodoro.GithubGist do
  @moduledoc """
  Server-side GitHub Gist API client. Uses Bearer token authentication.
  """
  @gist_api "https://api.github.com/gists"
  @gist_file "pomodoro.json"
  @accept "application/vnd.github.v3+json"

  @doc """
  Creates a new private Gist with the given data. Returns {:ok, gist_id} or {:error, reason}.
  """
  def create(token, data) when is_binary(token) and is_map(data) do
    body = %{
      description: "Pomodoro session stats",
      public: false,
      files: %{@gist_file => %{content: Jason.encode!(data)}}
    }

    request(:post, @gist_api, token, body, fn resp ->
      case resp["id"] do
        nil -> {:error, resp["message"] || "missing gist id"}
        id -> {:ok, id}
      end
    end)
  end

  @doc """
  Fetches Gist content. Returns {:ok, decoded_data} or {:ok, nil} if empty, or {:error, reason}.
  """
  def fetch(token, gist_id) when is_binary(token) and is_binary(gist_id) do
    request(:get, "#{@gist_api}/#{gist_id}", token, nil, fn resp ->
      files = resp["files"] || {}
      file = files[@gist_file]
      content = file && file["content"]
      if content in [nil, ""], do: {:ok, nil}, else: {:ok, Jason.decode!(content)}
    end)
  end

  @doc """
  Updates an existing Gist with the given data. Returns :ok or {:error, reason}.
  """
  def update(token, gist_id, data) when is_binary(token) and is_binary(gist_id) and is_map(data) do
    body = %{
      files: %{@gist_file => %{content: Jason.encode!(data)}}
    }

    request(:patch, "#{@gist_api}/#{gist_id}", token, body, fn _resp -> {:ok, :done} end)
  end

  defp request(method, url, token, body, parse) do
    headers = [
      {"authorization", "Bearer #{token}"},
      {"accept", @accept},
      {"content-type", "application/json"}
    ]

    req =
      if body do
        Finch.build(method, url, headers, Jason.encode!(body))
      else
        Finch.build(method, url, headers)
      end

    case Finch.request(req, Pomodoro.Finch) do
      {:ok, %{status: status, body: raw}} when status in 200..299 ->
        decoded = if raw == "" or raw == nil, do: %{}, else: Jason.decode!(raw)
        result = parse.(decoded)
        if result == {:ok, :done}, do: :ok, else: result

      {:ok, %{status: status, body: raw}} ->
        msg = case Jason.decode(raw) do
          {:ok, %{"message" => m}} -> m
          _ -> "HTTP #{status}"
        end
        {:error, msg}

      {:error, e} ->
        {:error, inspect(e)}
    end
  end
end
