defmodule GildedRose do
  use Agent
  alias GildedRose.Item

  @doc """
  Starts a new GildedRose agent, returning the default list of items:

  - +5 Dexterity Vest
  - Aged Brie
  - Elixir of the Mongoose
  - Sulfuras, Hand of Ragnaros
  - Backstage passes to a TAFKAL80ETC concert
  - Conjured Mana Cake
  """
  def new() do
    new([
      Item.new("+5 Dexterity Vest", 10, 20),
      Item.new("Aged Brie", 2, 0),
      Item.new("Elixir of the Mongoose", 5, 7),
      Item.new("Sulfuras, Hand of Ragnaros", 0, 80),
      Item.new("Backstage passes to a TAFKAL80ETC concert", 15, 20),
      Item.new("Conjured Mana Cake", 3, 6)
    ])
  end

  @doc """
  Starts a new GildedRose agent, with the given list of items.
  """
  def new(items) do
    {:ok, agent} = Agent.start_link(fn -> items end)
    agent
  end

  @doc """
  Retrieves the current state of the agent, returning a list of items.
  """
  def items(agent), do: Agent.get(agent, & &1)

  @legendary_items [
    "Sulfuras, Hand of Ragnaros"
  ]

  @doc """
  Ages the item by one day, updating the quality depending on the item's rules.

  Outside of Legendary items, quality can neither be greater than 50 or lower
  than 0.

  - "Standard" items have their quality decrease by 1 each day.
  - "Legendary" items retain their quality permanently, and their sell_in never
  changes, as they are timeless.
  - "Backstage passes" increase in quality as their sell_in decreases, by 1 if
  it's more than 10 days away, by 2 if it's between 10 and 5, and by 3 if it's
  under 5 days left. After the concert, the quality drops to 0.
  - "Conjured" items decrease in quality twice as fast as standard items.
  - "Aged Brie" increases in quality as it ages, instead of decreasing, doubling
  the increase after its sell_in date. It still cannot exceed 50.
  """
  def update_item(item)

  def update_item(%Item{name: name} = item) when name in @legendary_items do
    item
  end

  def update_item(%Item{name: "Backstage passes to a " <> _concert_name} = item) do
    case item do
      %{sell_in: sell_in, quality: quality} when sell_in > 10 ->
        %{item | sell_in: sell_in - 1, quality: quality + 1}

      %{sell_in: sell_in, quality: quality} when sell_in > 5 ->
        %{item | sell_in: sell_in - 1, quality: quality + 2}

      %{sell_in: sell_in, quality: quality} when sell_in > 0 ->
        %{item | sell_in: sell_in - 1, quality: quality + 3}

      item ->
        %{item | sell_in: item.sell_in - 1, quality: 0}
    end
  end

  def update_item(%Item{name: "Conjured " <> _item_name} = item) do
    case item do
      %{sell_in: sell_in, quality: quality} when sell_in >= 0 ->
        %{item | sell_in: sell_in - 1, quality: max(quality - 2, 0)}

      %{sell_in: sell_in, quality: quality} when sell_in < 0 ->
        %{item | sell_in: sell_in - 1, quality: max(quality - 4, 0)}
    end
  end

  def update_item(%Item{name: "Aged Brie"} = item) do
    case item do
      %{sell_in: sell_in, quality: quality} when sell_in > 0 ->
        %{item | sell_in: sell_in - 1, quality: min(quality + 1, 50)}

      %{sell_in: sell_in, quality: quality} when sell_in <= 0 ->
        %{item | sell_in: sell_in - 1, quality: min(quality + 2, 50)}
    end
  end

  def update_item(item) do
    sell_in = item.sell_in - 1
    quality = if sell_in >= 0, do: item.quality - 1, else: item.quality - 2

    %{item | sell_in: sell_in, quality: max(quality, 0)}
  end

  @doc """
  Given an agent containing a list of items, ages each item by one day.
  """
  def update_quality(agent) do
    updated_items =
      agent
      |> items()
      |> Enum.map(&update_item/1)

    Agent.update(agent, fn _ -> updated_items end)
  end
end
