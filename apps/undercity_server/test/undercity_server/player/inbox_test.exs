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

  describe "send_message/2 and fetch/1" do
    test "returns the sent message as a {text} tuple" do
      id = Helpers.player_id()

      Inbox.send_message(id, "hello")
      :timer.sleep(10)

      assert [{"hello"}] = Inbox.fetch(id)
    end

    test "multiple messages are returned newest-first" do
      id = Helpers.player_id()

      Inbox.send_message(id, "first")
      Inbox.send_message(id, "second")
      Inbox.send_message(id, "third")
      :timer.sleep(10)

      assert [{"third"}, {"second"}, {"first"}] = Inbox.fetch(id)
    end

    test "fetch/1 clears the inbox — a second call returns []" do
      id = Helpers.player_id()

      Inbox.send_message(id, "hello")
      :timer.sleep(10)

      assert [{"hello"}] = Inbox.fetch(id)
      assert [] = Inbox.fetch(id)
    end

    test "fetch/2 with n: 1 returns only the newest message" do
      id = Helpers.player_id()

      Inbox.send_message(id, "older")
      Inbox.send_message(id, "newer")
      :timer.sleep(10)

      assert [{"newer"}] = Inbox.fetch(id, 1)
    end

    test "messages for different player IDs are independent" do
      id_a = Helpers.player_id()
      id_b = Helpers.player_id()

      Inbox.send_message(id_a, "for A")
      :timer.sleep(10)

      assert [{"for A"}] = Inbox.fetch(id_a)
      assert [] = Inbox.fetch(id_b)
    end
  end
end
