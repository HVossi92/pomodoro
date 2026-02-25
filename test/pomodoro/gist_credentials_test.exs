defmodule Pomodoro.GistCredentialsTest do
  use Pomodoro.DataCase, async: true

  alias Pomodoro.GistCredentials

  describe "connect/3 and get_credentials/1" do
    test "connect stores credentials and get_credentials returns token and gist_id" do
      user_id = "test_user_#{System.unique_integer([:positive])}"
      token = "ghp_test_token_123"

      assert {:ok, _cred} = GistCredentials.connect(user_id, token, nil)
      creds = GistCredentials.get_credentials(user_id)
      assert creds != nil
      assert creds.token == token
      assert creds.gist_id == nil
    end

    test "connect with gist_id stores it" do
      user_id = "test_user_#{System.unique_integer([:positive])}"
      token = "ghp_abc"
      gist_id = "gist_id_123"

      assert {:ok, _} = GistCredentials.connect(user_id, token, gist_id)
      creds = GistCredentials.get_credentials(user_id)
      assert creds.gist_id == gist_id
    end

    test "set_gist_id updates gist_id" do
      user_id = "test_user_#{System.unique_integer([:positive])}"
      assert {:ok, _} = GistCredentials.connect(user_id, "token", nil)
      assert {:ok, _} = GistCredentials.set_gist_id(user_id, "new_gist_id")
      creds = GistCredentials.get_credentials(user_id)
      assert creds.gist_id == "new_gist_id"
    end
  end

  describe "disconnect/1" do
    test "disconnect removes credentials (user-initiated only)" do
      user_id = "test_user_#{System.unique_integer([:positive])}"
      assert {:ok, _} = GistCredentials.connect(user_id, "token", "gid")
      assert GistCredentials.connected?(user_id)
      assert :ok = GistCredentials.disconnect(user_id)
      refute GistCredentials.connected?(user_id)
      assert GistCredentials.get_credentials(user_id) == nil
    end
  end

  describe "connected?/1" do
    test "returns false when no credentials" do
      refute GistCredentials.connected?("nonexistent_user")
    end

    test "returns true after connect" do
      user_id = "test_user_#{System.unique_integer([:positive])}"
      assert {:ok, _} = GistCredentials.connect(user_id, "t", nil)
      assert GistCredentials.connected?(user_id)
    end
  end
end
