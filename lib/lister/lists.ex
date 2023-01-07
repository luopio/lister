defmodule Lister.Lists do
  def init do
    # :mnesia.stop
    loc = node()
    IO.puts("Lists.init at #{loc}")
    :mnesia.create_schema([loc])
    :mnesia.start()
    ensure_table_exists(List, attributes: [:id, :name])

    ensure_table_exists(ListItem, attributes: [:id, :list_id, :next_item_id, :content, :completed])

    :mnesia.wait_for_tables(List, ListItem)
  end

  def create_list(list_id, name) do
    :mnesia.transaction(fn ->
      _create_list(list_id, name)
    end)
  end

  def get_all_lists() do
    {:atomic, lists} =
      :mnesia.transaction(fn ->
        :mnesia.match_object({List, :_, :_})
      end)

    Enum.map(lists, fn list ->
      %{
        "id" => elem(list, 1),
        "name" => elem(list, 2)
      }
    end)
  end

  def get_or_create_list(list_id) do
    IO.puts("get_or_create_list with #{list_id}")
    list = get_list(list_id)

    if list == nil do
      IO.puts("creating a new list")
      create_list(list_id, list_id)
      add_last_item(list_id)
      get_list(list_id)
    else
      list
    end
  end

  def get_list(list_id) do
    {:atomic, list} =
      :mnesia.transaction(fn ->
        case :mnesia.match_object({List, list_id, :_}) do
          [list | _] ->
            results = :mnesia.match_object({ListItem, :_, list_id, :_, :_, :_})

            sorted_items =
              results
              |> listitems_to_map
              |> IO.inspect()
              |> sort_list_2

            %{
              "id" => elem(list, 1),
              "name" => elem(list, 2),
              "items" => sorted_items
            }

          [] ->
            nil
        end
      end)

    list |> IO.inspect(label: "get_list(#{list_id}) returns")
  end

  def listitems_to_map(items) do
    Enum.map(items, fn item ->
      %{
        "id" => elem(item, 1),
        "next" => elem(item, 3),
        "content" => elem(item, 4),
        "completed" => elem(item, 5)
      }
    end)
  end

  # These local things should live somewhere else..
  def local_update_item_content(list_items, item_id, values) do
    Enum.map(list_items, fn item ->
      if item_id == item["id"] do
        # Map.put(item, "content", content)
        Map.merge(item, values)
      else
        item
      end
    end)
  end

  def local_add_item_after(
        list_items,
        new_item_id,
        after_item_id,
        content \\ "",
        completed \\ false
      ) do
    after_index = Enum.find_index(list_items, fn item -> item["id"] == after_item_id end)

    List.insert_at(list_items, after_index + 1, %{
      "id" => new_item_id,
      "next" => after_item_id,
      "content" => content,
      "completed" => completed
    })
  end

  def add_last_item(list_id) do
    :mnesia.transaction(fn ->
      results = :mnesia.match_object({ListItem, :_, list_id, nil, :_, :_})
      new_id = _new_entry_id()

      if length(results) > 0 do
        [last_item | _] = results
        IO.puts("last item needs update")

        :mnesia.write(
          {ListItem, elem(last_item, 1), list_id, new_id, elem(last_item, 4), elem(last_item, 5)}
        )
      end

      :mnesia.write({ListItem, new_id, list_id, nil, "", false})
    end)
  end

  def add_item_after(list_id, after_item_id) when is_integer(after_item_id) do
    new_id = _new_entry_id()

    {:atomic, :ok} =
      :mnesia.transaction(fn ->
        IO.puts("insert after #{after_item_id} for #{list_id}")
        ret = :mnesia.read({ListItem, after_item_id})
        [{ListItem, _id, _list_id, next_item_id, content, completed} | _] = ret
        :mnesia.write({ListItem, new_id, list_id, next_item_id, "", false})
        :mnesia.write({ListItem, after_item_id, list_id, new_id, content, completed})
      end)

    new_id
  end

  def update_item(list_id, entry_id, params)
      when is_integer(entry_id) and is_map(params) do
    {:atomic, :ok} =
      :mnesia.transaction(fn ->
        [{ListItem, _, _, prev_id, content, completed}] = :mnesia.read({ListItem, entry_id})

        :mnesia.write(
          {ListItem, entry_id, list_id, prev_id, Map.get(params, "content", content),
           Map.get(params, "completed", completed)}
        )

        IO.puts("Updated #{entry_id}")
      end)
  end

  defp _create_list(list_id, name) do
    :mnesia.write({List, list_id, name})
  end

  defp _new_entry_id() do
    System.system_time(:millisecond)
  end

  defp ensure_table_exists(tbl, schema) do
    case :mnesia.create_table(tbl, schema) do
      {:atomic, :ok} ->
        IO.puts("table created")
        # {:atomic, :ok} = :mnesia.add_table_index(tbl, :id)
        if :list_id in schema[:attributes] do
          {:atomic, :ok} = :mnesia.add_table_index(tbl, :list_id)
        end

      {:aborted, {:already_exists, ^tbl}} ->
        IO.puts("table already exists")
    end
  end

  def sort_list_2(list) do
    _s(list, [], [])
  end

  def _s([], [], sorted_list) do
    IO.puts("end end")
    sorted_list
  end

  def _s([], list_head, sorted_list) do
    IO.puts("swap")
    _s(list_head, [], sorted_list)
  end

  def _s([%{"next" => nil} = cur | rest], list_head, []) do
    IO.puts("found end")
    _s(rest, list_head, [cur])
  end

  def _s([%{"next" => nid} = cur | rest], list_head, []) when nid != nil do
    IO.puts("looking for end")
    _s(rest, [cur | list_head], [])
  end

  def _s(
        [%{"next" => n_id} = cur | rest],
        list_head,
        [%{"id" => sorted_id} | _] = sorted_list
      ) do
    if sorted_id == n_id do
      IO.puts("found")
      _s(rest, list_head, [cur | sorted_list])
    else
      IO.puts("next")
      _s(rest, [cur | list_head], sorted_list)
    end
  end

  def next_item_for([], _) do
    nil
  end

  def next_item_for(list, %{"next" => next_id} = elem) do
    IO.inspect(list, label: "looking for next #{next_id}")
    [%{"id" => hd_id} = hd_elem | tail] = list

    if hd_id == next_id do
      hd_elem
    else
      next_item_for(tail, elem)
    end
  end

  def previous_item_for([], _) do
    nil
  end

  def previous_item_for(list, %{"id" => id} = elem) do
    IO.inspect(list, label: "looking for #{id}")
    [%{"next" => hd_next_id} = hd_elem | tl] = list

    if hd_next_id == id do
      hd_elem
    else
      previous_item_for(tl, elem)
    end
  end

  def test_list() do
    [
      %{"id" => 1, "next" => 3},
      %{"id" => 2, "next" => nil},
      %{"id" => 5, "next" => 4},
      %{"id" => 4, "next" => 2},
      %{"id" => 3, "next" => 5}
    ]
  end
end
