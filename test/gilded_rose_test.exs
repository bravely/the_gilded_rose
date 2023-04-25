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

    test "Aged Brie increases in quality as its sell_in decreases, but never exceeds maximum" do
      gilded_rose = GildedRose.new()

      # Baseline Aged Brie sell_in and quality.
      items = GildedRose.items(gilded_rose)

      assert %Item{name: "Aged Brie", sell_in: 2, quality: 0} =
               Enum.find(items, &(&1.name == "Aged Brie"))

      # Work up to the sell_in date for the Aged Brie. Quality should increase by 1 each time.
      for _ <- 1..2 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      items = GildedRose.items(gilded_rose)

      assert %Item{name: "Aged Brie", sell_in: 0, quality: 2} =
               Enum.find(items, &(&1.name == "Aged Brie"))

      # Past sell_in, quality should increase by 2 each time...
      for _ <- 1..24 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      items = GildedRose.items(gilded_rose)

      assert %Item{name: "Aged Brie", sell_in: -24, quality: 50} =
               Enum.find(items, &(&1.name == "Aged Brie"))

      # ...but can't exceed 50.
      for _ <- 1..2 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      items = GildedRose.items(gilded_rose)

      assert %Item{name: "Aged Brie", sell_in: -26, quality: 50} =
               Enum.find(items, &(&1.name == "Aged Brie"))
    end

    test "Sulfuras never decreases in quality as its sell_in increases" do
      gilded_rose = GildedRose.new()

      # Baseline for Sulfuras.
      items = GildedRose.items(gilded_rose)

      assert %Item{name: "Sulfuras, Hand of Ragnaros", sell_in: 0, quality: 80} =
               Enum.find(items, &(&1.name == "Sulfuras, Hand of Ragnaros"))

      # Work up to the sell_in date for the Sulfuras. Quality should never change.
      for _ <- 1..10 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      items = GildedRose.items(gilded_rose)

      assert %Item{name: "Sulfuras, Hand of Ragnaros", sell_in: 0, quality: 80} =
               Enum.find(items, &(&1.name == "Sulfuras, Hand of Ragnaros"))
    end
  end
end
