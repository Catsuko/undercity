defmodule UndercityServer.Player.InboxTest do
  use ExUnit.Case, async: true

  alias UndercityServer.Player.Inbox
  alias UndercityServer.Test.Helpers

  describe "fetch/1" do
    test "returns [] for a player with no messages" do
      id = Helpers.player_id()

      assert [] = Inbox.fetch(id)
    end
  end

  describe "typed senders and fetch/1" do
    test "returns the sent message as a {type, text} tuple" do
      id = Helpers.player_id()

      Inbox.info(id, "hello")
      :timer.sleep(10)

      assert [{:info, "hello"}] = Inbox.fetch(id)
    end

    test "multiple messages are returned oldest-first" do
      id = Helpers.player_id()

      Inbox.info(id, "first")
      Inbox.warning(id, "second")
      Inbox.success(id, "third")
      :timer.sleep(10)

      assert [{:info, "first"}, {:warning, "second"}, {:success, "third"}] = Inbox.fetch(id)
    end

    test "fetch/1 clears the inbox — a second call returns []" do
      id = Helpers.player_id()

      Inbox.info(id, "hello")
      :timer.sleep(10)

      assert [{:info, "hello"}] = Inbox.fetch(id)
      assert [] = Inbox.fetch(id)
    end

    test "fetch/2 with n: 1 returns only the newest message" do
      id = Helpers.player_id()

      Inbox.info(id, "older")
      Inbox.warning(id, "newer")
      :timer.sleep(10)

      assert [{:warning, "newer"}] = Inbox.fetch(id, 1)
    end

    test "fetch/2 with n: 2 returns messages in order received" do
      id = Helpers.player_id()

      Inbox.info(id, "first")
      Inbox.info(id, "second")
      Inbox.info(id, "third")
      :timer.sleep(10)

      assert [{:info, "second"}, {:info, "third"}] = Inbox.fetch(id, 2)
    end

    test "messages for different player IDs are independent" do
      id_a = Helpers.player_id()
      id_b = Helpers.player_id()

      Inbox.info(id_a, "for A")
      :timer.sleep(10)

      assert [{:info, "for A"}] = Inbox.fetch(id_a)
      assert [] = Inbox.fetch(id_b)
    end

    test "all message types are accepted" do
      id = Helpers.player_id()

      Inbox.success(id, "ok")
      Inbox.info(id, "note")
      Inbox.warning(id, "watch out")
      Inbox.failure(id, "error")
      :timer.sleep(10)

      assert [
               {:success, "ok"},
               {:info, "note"},
               {:warning, "watch out"},
               {:failure, "error"}
             ] = Inbox.fetch(id)
    end
  end
end
