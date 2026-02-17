defmodule UndercityCli.View.ConstitutionTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View.Constitution

  describe "awareness_tier/1" do
    test "40+ is rested" do
      assert :rested = Constitution.awareness_tier(50)
      assert :rested = Constitution.awareness_tier(40)
    end

    test "16-39 is weary" do
      assert :weary = Constitution.awareness_tier(39)
      assert :weary = Constitution.awareness_tier(16)
    end

    test "1-15 is exhausted" do
      assert :exhausted = Constitution.awareness_tier(15)
      assert :exhausted = Constitution.awareness_tier(1)
    end

    test "0 is spent" do
      assert :spent = Constitution.awareness_tier(0)
    end
  end

  describe "status_message/1" do
    test "rested is a success message" do
      assert {"You feel rested.", :success} = Constitution.status_message(50)
    end

    test "weary is a warning message" do
      assert {"You feel weary.", :warning} = Constitution.status_message(30)
    end

    test "exhausted is a warning message" do
      assert {"You can barely keep your eyes open.", :warning} = Constitution.status_message(10)
    end

    test "spent is a warning message" do
      assert {"You are completely exhausted.", :warning} = Constitution.status_message(0)
    end
  end

  describe "threshold_message/2" do
    test "returns message when crossing into weary" do
      assert {"You feel weary.", :warning} = Constitution.threshold_message(40, 39)
    end

    test "returns message when crossing into exhausted" do
      assert {"You can barely keep your eyes open.", :warning} = Constitution.threshold_message(16, 15)
    end

    test "returns message when crossing into spent" do
      assert {"You are completely exhausted.", :warning} = Constitution.threshold_message(1, 0)
    end

    test "returns message when recovering to rested" do
      assert {"You feel rested.", :success} = Constitution.threshold_message(39, 40)
    end

    test "returns nil when staying in same tier" do
      assert nil == Constitution.threshold_message(50, 49)
      assert nil == Constitution.threshold_message(30, 20)
    end
  end

  describe "health_tier/1" do
    test "45+ is healthy" do
      assert :healthy = Constitution.health_tier(50)
      assert :healthy = Constitution.health_tier(45)
    end

    test "35-44 is sore" do
      assert :sore = Constitution.health_tier(44)
      assert :sore = Constitution.health_tier(35)
    end

    test "15-34 is wounded" do
      assert :wounded = Constitution.health_tier(34)
      assert :wounded = Constitution.health_tier(15)
    end

    test "5-14 is battered" do
      assert :battered = Constitution.health_tier(14)
      assert :battered = Constitution.health_tier(5)
    end

    test "1-4 is critical" do
      assert :critical = Constitution.health_tier(4)
      assert :critical = Constitution.health_tier(1)
    end

    test "0 is collapsed" do
      assert :collapsed = Constitution.health_tier(0)
    end
  end

  describe "health_status_message/1" do
    test "healthy is a success message" do
      assert {"You feel healthy.", :success} = Constitution.health_status_message(50)
    end

    test "sore is a warning message" do
      assert {"You feel some aches and pains.", :warning} = Constitution.health_status_message(40)
    end

    test "wounded is a warning message" do
      assert {"You are wounded.", :warning} = Constitution.health_status_message(20)
    end

    test "battered is a warning message" do
      assert {"You are severely wounded.", :warning} = Constitution.health_status_message(10)
    end

    test "critical is a warning message" do
      assert {"You have many wounds and are close to passing out.", :warning} = Constitution.health_status_message(2)
    end

    test "collapsed is a warning message" do
      assert {"Your body has given out.", :warning} = Constitution.health_status_message(0)
    end
  end

  describe "health_threshold_message/2" do
    test "returns message when crossing into sore" do
      assert {"You feel some aches and pains.", :warning} = Constitution.health_threshold_message(45, 44)
    end

    test "returns message when crossing into battered" do
      assert {"You are severely wounded.", :warning} = Constitution.health_threshold_message(15, 14)
    end

    test "returns message when crossing into collapsed" do
      assert {"Your body has given out.", :warning} = Constitution.health_threshold_message(1, 0)
    end

    test "returns message when recovering to healthy" do
      assert {"You feel healthy.", :success} = Constitution.health_threshold_message(44, 45)
    end

    test "returns nil when staying in same tier" do
      assert nil == Constitution.health_threshold_message(50, 49)
      assert nil == Constitution.health_threshold_message(20, 16)
    end
  end

  describe "status_messages/2" do
    test "returns AP and HP messages when alive" do
      messages = Constitution.status_messages(50, 50)
      assert [{"You feel rested.", :success}, {"You feel healthy.", :success}] = messages
    end

    test "returns only HP message when collapsed" do
      messages = Constitution.status_messages(10, 0)
      assert [{"Your body has given out.", :warning}] = messages
    end
  end

  describe "threshold_messages/4" do
    test "returns AP threshold when crossing tier" do
      assert [{"You feel weary.", :warning}] = Constitution.threshold_messages(40, 39)
    end

    test "returns empty list when no threshold crossed" do
      assert [] = Constitution.threshold_messages(50, 49)
    end

    test "returns both AP and HP thresholds" do
      assert [{"You feel weary.", :warning}, {"You feel some aches and pains.", :warning}] =
               Constitution.threshold_messages(40, 39, 45, 44)
    end

    test "defaults old_hp/new_hp to nil" do
      assert [{"You feel weary.", :warning}] = Constitution.threshold_messages(40, 39)
    end
  end
end
