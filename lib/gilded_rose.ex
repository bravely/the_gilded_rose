defmodule GildedRose do
  use Agent
  alias GildedRose.Item

  def new() do
    {:ok, agent} =
      Agent.start_link(fn ->
        [
          Item.new("+5 Dexterity Vest", 10, 20),
          Item.new("Aged Brie", 2, 0),
          Item.new("Elixir of the Mongoose", 5, 7),
          Item.new("Sulfuras, Hand of Ragnaros", 0, 80),
          Item.new("Backstage passes to a TAFKAL80ETC concert", 15, 20),
          Item.new("Conjured Mana Cake", 3, 6)
        ]
      end)

    agent
  end

  def items(agent), do: Agent.get(agent, & &1)

  @legendary_items [
    "Sulfuras, Hand of Ragnaros"
  ]

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

  def update_item(item) do
    item =
      cond do
        item.name != "Aged Brie" ->
          if item.quality > 0 do
            %{item | quality: item.quality - 1}
          else
            item
          end

        true ->
          if item.quality < 50 do
            %{item | quality: item.quality + 1}
          else
            item
          end
      end

    item = %{item | sell_in: item.sell_in - 1}

    item =
      cond do
        item.sell_in < 0 ->
          cond do
            item.name != "Aged Brie" ->
              cond do
                item.quality > 0 ->
                  %{item | quality: item.quality - 1}

                true ->
                  item
              end

            true ->
              cond do
                item.quality < 50 ->
                  %{item | quality: item.quality + 1}

                true ->
                  item
              end
          end

        true ->
          item
      end

    item
  end

  def update_quality(agent) do
    updated_items =
      agent
      |> items()
      |> Enum.map(&update_item/1)

    Agent.update(agent, fn _ -> updated_items end)
  end
end
