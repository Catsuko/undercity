defmodule UndercityCore.Item.CatalogueTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Combat.Weapon
  alias UndercityCore.Item.Catalogue
  alias UndercityCore.Item.Catalogue.Entry
  alias UndercityCore.Item.Food
  alias UndercityCore.LootTable

  describe "fetch/1" do
    test "returns {:ok, entry} for a known atom id" do
      assert {:ok, %Entry{id: :iron_pipe, name: "Iron Pipe"}} = Catalogue.fetch(:iron_pipe)
    end

    test "returns :not_found for an unknown atom" do
      assert :not_found = Catalogue.fetch(:banana)
    end

    test "chalk entry has default_uses set" do
      assert {:ok, %Entry{default_uses: 5}} = Catalogue.fetch(:chalk)
    end

    test "iron_pipe entry has weapon flag set" do
      assert {:ok, %Entry{weapon: true}} = Catalogue.fetch(:iron_pipe)
    end

    test "mushroom entry has edible flag set" do
      assert {:ok, %Entry{edible: true}} = Catalogue.fetch(:mushroom)
    end

    test "junk entry has no special flags" do
      assert {:ok, %Entry{weapon: false, edible: false, default_uses: nil}} =
               Catalogue.fetch(:junk)
    end
  end

  describe "fetch_by_name/1" do
    test "returns {:ok, entry} for a known display name" do
      assert {:ok, %Entry{id: :iron_pipe}} = Catalogue.fetch_by_name("Iron Pipe")
    end

    test "returns :not_found for an unknown name string" do
      assert :not_found = Catalogue.fetch_by_name("Banana")
    end

    test "returns :not_found for an empty string" do
      assert :not_found = Catalogue.fetch_by_name("")
    end
  end

  describe "name!/1" do
    test "returns the display name string for a known id" do
      assert "Iron Pipe" = Catalogue.name!(:iron_pipe)
      assert "Chalk" = Catalogue.name!(:chalk)
      assert "Mushroom" = Catalogue.name!(:mushroom)
      assert "Junk" = Catalogue.name!(:junk)
    end

    test "raises for an unknown id" do
      assert_raise KeyError, fn -> Catalogue.name!(:banana) end
    end
  end

  describe "all/0" do
    test "returns a list of entries" do
      entries = Catalogue.all()
      assert is_list(entries)
      assert Enum.all?(entries, &match?(%Entry{}, &1))
    end

    test "includes all expected items" do
      ids = Enum.map(Catalogue.all(), & &1.id)
      assert :iron_pipe in ids
      assert :chalk in ids
      assert :mushroom in ids
      assert :junk in ids
    end

    test "every entry has a non-empty name" do
      assert Enum.all?(Catalogue.all(), fn e -> byte_size(e.name) > 0 end)
    end

    test "atom ids are unique" do
      ids = Enum.map(Catalogue.all(), & &1.id)
      assert ids == Enum.uniq(ids)
    end

    test "name strings are unique" do
      names = Enum.map(Catalogue.all(), & &1.name)
      assert names == Enum.uniq(names)
    end
  end

  describe "cross-module consistency" do
    test "every item in any LootTable is catalogued" do
      named_ids =
        LootTable.all_block_types()
        |> Enum.flat_map(&LootTable.for_block_type/1)
        |> Enum.map(fn {_prob, id} -> id end)

      # :fountain is a real block type not in @tables — covers the default path
      default_ids =
        :fountain
        |> LootTable.for_block_type()
        |> Enum.map(fn {_prob, id} -> id end)

      for id <- Enum.uniq(named_ids ++ default_ids) do
        assert {:ok, _entry} = Catalogue.fetch(id),
               "Expected #{inspect(id)} (from LootTable) to be in Catalogue"
      end
    end

    test "every weapon in the Weapon registry is catalogued" do
      for id <- Weapon.all_ids() do
        assert {:ok, _entry} = Catalogue.fetch(id),
               "Expected #{inspect(id)} (from Weapon registry) to be in Catalogue"
      end
    end

    test "every food item in the Food table is catalogued" do
      for id <- Food.all_ids() do
        assert {:ok, _entry} = Catalogue.fetch(id),
               "Expected #{inspect(id)} (from Food table) to be in Catalogue"
      end
    end
  end
end
