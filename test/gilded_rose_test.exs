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

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "+5 Dexterity Vest",
        sell_in: 10,
        quality: 20
      })
      |> assert_item_matches(%Item{
        name: "Elixir of the Mongoose",
        sell_in: 5,
        quality: 7
      })

      assert :ok == GildedRose.update_quality(gilded_rose)

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "+5 Dexterity Vest",
        sell_in: 9,
        quality: 19
      })
      |> assert_item_matches(%Item{
        name: "Elixir of the Mongoose",
        sell_in: 4,
        quality: 6
      })
    end

    test "standard items after their sell date decrease their quality by 2, sell_in by 1" do
      gilded_rose = GildedRose.new()

      gilded_rose
      |> GildedRose.items()
      # Baseline, and re-establishing sell_in and quality amounts while they decrease normally.
      |> assert_item_matches(%Item{
        name: "+5 Dexterity Vest",
        sell_in: 10,
        quality: 20
      })
      |> assert_item_matches(%Item{
        name: "Elixir of the Mongoose",
        sell_in: 5,
        quality: 7
      })

      # Work up to the sell_in date for the Elixir of the Mongoose.
      for _ <- 1..5 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      # Baseline, and re-establishing sell_in and quality amounts while they decrease normally.
      |> assert_item_matches(%Item{
        name: "+5 Dexterity Vest",
        sell_in: 5,
        quality: 15
      })
      |> assert_item_matches(%Item{
        name: "Elixir of the Mongoose",
        sell_in: 0,
        quality: 2
      })

      # Work past the sell_in date for the Elixir of the Mongoose, where quality
      # decreases twice as fast, but the Vest decreases normally.

      assert :ok == GildedRose.update_quality(gilded_rose)

      gilded_rose
      |> GildedRose.items()
      # Baseline, and re-establishing sell_in and quality amounts while they decrease normally.
      |> assert_item_matches(%Item{
        name: "+5 Dexterity Vest",
        sell_in: 4,
        quality: 14
      })
      |> assert_item_matches(%Item{
        name: "Elixir of the Mongoose",
        sell_in: -1,
        quality: 0
      })

      # Work up to the sell_in date for the Vest. Elixir's quality shouldn't
      # decrease past 0.
      for _ <- 1..4 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      # Baseline, and re-establishing sell_in and quality amounts while they decrease normally.
      |> assert_item_matches(%Item{
        name: "+5 Dexterity Vest",
        sell_in: 0,
        quality: 10
      })
      |> assert_item_matches(%Item{
        name: "Elixir of the Mongoose",
        sell_in: -5,
        quality: 0
      })

      # Work past Vest sell_in, ensuring quality decreases twice as fast.

      assert :ok == GildedRose.update_quality(gilded_rose)

      gilded_rose
      |> GildedRose.items()
      # Baseline, and re-establishing sell_in and quality amounts while they decrease normally.
      |> assert_item_matches(%Item{
        name: "+5 Dexterity Vest",
        sell_in: -1,
        quality: 8
      })
      |> assert_item_matches(%Item{
        name: "Elixir of the Mongoose",
        sell_in: -6,
        quality: 0
      })
    end

    test "Aged Brie increases in quality as its sell_in decreases, but never exceeds maximum" do
      gilded_rose = GildedRose.new()

      gilded_rose
      |> GildedRose.items()
      # Baseline Aged Brie sell_in and quality.
      |> assert_item_matches(%Item{
        name: "Aged Brie",
        sell_in: 2,
        quality: 0
      })

      # Work up to the sell_in date for the Aged Brie. Quality should increase by 1 each time.
      for _ <- 1..2 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      # Baseline Aged Brie sell_in and quality.
      |> assert_item_matches(%Item{
        name: "Aged Brie",
        sell_in: 0,
        quality: 2
      })

      # Past sell_in, quality should increase by 2 each time...
      for _ <- 1..24 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Aged Brie",
        sell_in: -24,
        quality: 50
      })

      # ...but can't exceed 50.
      for _ <- 1..2 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Aged Brie",
        sell_in: -26,
        quality: 50
      })
    end

    test "Sulfuras never decreases in quality as its sell_in increases" do
      gilded_rose = GildedRose.new()

      gilded_rose
      |> GildedRose.items()
      # Baseline for Sulfuras.
      |> assert_item_matches(%Item{
        name: "Sulfuras, Hand of Ragnaros",
        sell_in: 0,
        quality: 80
      })

      # Work up to the sell_in date for the Sulfuras. Quality should never change.
      for _ <- 1..10 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      # Still baseline.
      |> assert_item_matches(%Item{
        name: "Sulfuras, Hand of Ragnaros",
        sell_in: 0,
        quality: 80
      })
    end

    test "Backstage passes increases in quality according to its own rules" do
      gilded_rose = GildedRose.new()

      gilded_rose
      |> GildedRose.items()
      # Baseline for Backstage passes.
      |> assert_item_matches(%Item{
        name: "Backstage passes to a TAFKAL80ETC concert",
        sell_in: 15,
        quality: 20
      })

      # Work up to 10 days before, when quality increases by 1 each time.
      for _ <- 1..5 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Backstage passes to a TAFKAL80ETC concert",
        sell_in: 10,
        quality: 25
      })

      # Under 10 days, but more than 5, quality increases by 2 each time.
      assert :ok == GildedRose.update_quality(gilded_rose)

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Backstage passes to a TAFKAL80ETC concert",
        sell_in: 9,
        quality: 27
      })

      for _ <- 1..4 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Backstage passes to a TAFKAL80ETC concert",
        sell_in: 5,
        quality: 35
      })

      # Now, under 5 days, quality increases by 3 each time.
      assert :ok == GildedRose.update_quality(gilded_rose)

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Backstage passes to a TAFKAL80ETC concert",
        sell_in: 4,
        quality: 38
      })

      for _ <- 1..4 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Backstage passes to a TAFKAL80ETC concert",
        sell_in: 0,
        quality: 50
      })

      # And after the concert, quality drops to 0, and stays there.
      assert :ok == GildedRose.update_quality(gilded_rose)

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Backstage passes to a TAFKAL80ETC concert",
        sell_in: -1,
        quality: 0
      })

      for _ <- 1..10 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Backstage passes to a TAFKAL80ETC concert",
        sell_in: -11,
        quality: 0
      })
    end

    test "Conjured items degrade in quality twice as fast, but otherwise match standard item behavior" do
      gilded_rose = GildedRose.new()

      gilded_rose
      |> GildedRose.items()
      # Baseline!
      |> assert_item_matches(%Item{
        name: "Conjured Mana Cake",
        sell_in: 3,
        quality: 6
      })

      # Quality degrades by two before the sell_in date.
      for _ <- 1..3 do
        assert :ok == GildedRose.update_quality(gilded_rose)
      end

      gilded_rose
      |> GildedRose.items()
      |> assert_item_matches(%Item{
        name: "Conjured Mana Cake",
        sell_in: 0,
        quality: 0
      })

      # Currently there's no Conjured items whose sell_in affects quality, but
      # if any are added, add them here!
    end
  end

  defp assert_item_matches(item_list, %Item{
         name: name,
         sell_in: sell_in,
         quality: quality
       }) do
    # Ensuring we're not mistakenly matching a different item, by asserting there
    # should only be one of any kind of item in the list.
    assert [item] = Enum.filter(item_list, &(&1.name == name))
    assert %Item{sell_in: ^sell_in, quality: ^quality} = item

    # Return the list so we can pipe chain if we like!
    item_list
  end
end
