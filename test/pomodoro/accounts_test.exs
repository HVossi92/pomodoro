defmodule Pomodoro.AccountsTest do
  use Pomodoro.DataCase, async: true

  alias Pomodoro.Accounts

  describe "link_identity/4" do
    test "creates identity for new user" do
      user_id = "user_#{System.unique_integer([:positive])}"

      assert {:ok, identity} =
               Accounts.link_identity(user_id, "google", "google_123", email: "a@b.com", name: "Alice")

      assert identity.user_id == user_id
      assert identity.provider == "google"
      assert identity.provider_uid == "google_123"
      assert identity.email == "a@b.com"
      assert identity.name == "Alice"
    end

    test "updates existing identity on re-link" do
      user_id = "user_#{System.unique_integer([:positive])}"

      Accounts.link_identity(user_id, "github", "gh_1", email: "old@x.com")
      {:ok, updated} = Accounts.link_identity(user_id, "github", "gh_1", email: "new@x.com")

      assert updated.email == "new@x.com"
    end
  end

  describe "list_identities/1" do
    test "returns linked identities" do
      user_id = "user_#{System.unique_integer([:positive])}"
      Accounts.link_identity(user_id, "google", "g1", email: "g@x.com")
      Accounts.link_identity(user_id, "github", "gh1", name: "Dev")

      identities = Accounts.list_identities(user_id)
      assert length(identities) == 2
    end

    test "returns empty for unknown user" do
      assert Accounts.list_identities("nonexistent") == []
    end
  end

  describe "unlink_identity/2" do
    test "removes identity" do
      user_id = "user_#{System.unique_integer([:positive])}"
      Accounts.link_identity(user_id, "google", "g1")
      assert Accounts.list_identities(user_id) != []

      assert :ok = Accounts.unlink_identity(user_id, "google")
      assert Accounts.list_identities(user_id) == []
    end
  end

  describe "delete_all_identities_for_user/1" do
    test "deletes all identities for the given user" do
      user_id = "user_#{System.unique_integer([:positive])}"
      other_id = "user_#{System.unique_integer([:positive])}"

      Accounts.link_identity(user_id, "google", "g1", email: "g@x.com")
      Accounts.link_identity(user_id, "github", "gh1", name: "Dev")
      Accounts.link_identity(other_id, "google", "other", email: "o@x.com")

      assert :ok = Accounts.delete_all_identities_for_user(user_id)
      assert Accounts.list_identities(user_id) == []
      assert length(Accounts.list_identities(other_id)) == 1
    end

    test "returns :ok for user with no identities" do
      user_id = "user_#{System.unique_integer([:positive])}"
      assert :ok = Accounts.delete_all_identities_for_user(user_id)
    end
  end
end
