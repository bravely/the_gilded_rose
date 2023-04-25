defmodule GildedRoseTest do
  use ExUnit.Case
  doctest GildedRose

  alias GildedRose.Item

  test "interface specification" do
    gilded_rose = GildedRose.new()
    [%GildedRose.Item{} | _] = GildedRose.items(gilded_rose)
    assert :ok == GildedRose.update_quality(gilded_rose)
  end

  describe "update_quality/1" do
    test "standard items before their sell date decrease their quality and sell_in by 1" do
      gilded_rose = GildedRose.new()

      items = GildedRose.items(gilded_rose)
      vest_index = Enum.find_index(items, &(&1.name == "+5 Dexterity Vest"))
      %Item{name: "+5 Dexterity Vest", sell_in: 10, quality: 20} = Enum.at(items, vest_index)
      elixir_index = Enum.find_index(items, &(&1.name == "Elixir of the Mongoose"))
      %Item{name: "Elixir of the Mongoose", sell_in: 5, quality: 7} = Enum.at(items, elixir_index)

      assert :ok == GildedRose.update_quality(gilded_rose)
      items = GildedRose.items(gilded_rose)

      %GildedRose.Item{name: "+5 Dexterity Vest", sell_in: 9, quality: 19} =
        Enum.at(items, vest_index)

      %GildedRose.Item{name: "Elixir of the Mongoose", sell_in: 4, quality: 6} =
        Enum.at(items, elixir_index)
    end

    test "standard items after their sell date decrease their quality by 2, sell_in by 1" do
      gilded_rose = GildedRose.new()

      # Baseline, and re-establishing sell_in and quality amounts while they decrease normally.
      items = GildedRose.items(gilded_rose)

      assert %Item{name: "+5 Dexterity Vest", sell_in: 10, quality: 20} =
               Enum.find(items, &(&1.name == "+5 Dexterity Vest"))

      assert %Item{name: "Elixir of the Mongoose", sell_in: 5, quality: 7} =
               Enum.find(items, &(&1.name == "Elixir of the Mongoose"))

      # Work up to the sell_in date for the Elixir of the Mongoose.
      for _ <- 1..5 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      items = GildedRose.items(gilded_rose)

      assert %Item{name: "+5 Dexterity Vest", sell_in: 5, quality: 15} =
               Enum.find(items, &(&1.name == "+5 Dexterity Vest"))

      assert %Item{name: "Elixir of the Mongoose", sell_in: 0, quality: 2} =
               Enum.find(items, &(&1.name == "Elixir of the Mongoose"))

      # Work past the sell_in date for the Elixir of the Mongoose, where quality
      # decreases twice as fast, but the Vest decreases normally.

      assert :ok == GildedRose.update_quality(gilded_rose)
      items = GildedRose.items(gilded_rose)

      assert %Item{name: "+5 Dexterity Vest", sell_in: 4, quality: 14} =
               Enum.find(items, &(&1.name == "+5 Dexterity Vest"))

      assert %Item{name: "Elixir of the Mongoose", sell_in: -1, quality: 0} =
               Enum.find(items, &(&1.name == "Elixir of the Mongoose"))

      # Work up to the sell_in date for the Vest. Elixir's quality shouldn't
      # decrease past 0.
      for _ <- 1..4 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      items = GildedRose.items(gilded_rose)

      assert %Item{name: "+5 Dexterity Vest", sell_in: 0, quality: 10} =
               Enum.find(items, &(&1.name == "+5 Dexterity Vest"))

      assert %Item{name: "Elixir of the Mongoose", sell_in: -5, quality: 0} =
               Enum.find(items, &(&1.name == "Elixir of the Mongoose"))

      # Work past Vest sell_in, ensuring quality decreases twice as fast.

      assert :ok == GildedRose.update_quality(gilded_rose)
      items = GildedRose.items(gilded_rose)

      assert %Item{name: "+5 Dexterity Vest", sell_in: -1, quality: 8} =
               Enum.find(items, &(&1.name == "+5 Dexterity Vest"))

      assert %Item{name: "Elixir of the Mongoose", sell_in: -6, quality: 0} =
               Enum.find(items, &(&1.name == "Elixir of the Mongoose"))
    end
  end
end
