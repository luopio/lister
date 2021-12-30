defmodule Lister.Lists do
  def init do
    # :mnesia.stop
    loc = node()
    IO.puts("Lists.init at #{loc}")
    :mnesia.create_schema([loc])
    :mnesia.start()
    ensure_table_exists(List, attributes: [:id, :name])
    ensure_table_exists(ListItem, attributes: [:id, :list_id, :content])
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

  def get_list(list_id) do
    {:atomic, list} =
      :mnesia.transaction(fn ->
        case :mnesia.match_object({List, list_id, :_}) do
          [list | _] ->
            results = :mnesia.match_object({ListItem, :_, list_id, :_})

            %{
              "id" => elem(list, 1),
              "name" => elem(list, 2),
              "items" =>
                Enum.map(
                  results,
                  fn item ->
                    %{"id" => elem(item, 1), "content" => elem(item, 3)}
                  end
                )
            }

          [] ->
            nil
        end
      end)

    list
  end

  def add_entry(list_id, entry) when is_integer(list_id) and is_map(entry) do
    :mnesia.transaction(fn ->
      _add_entry(list_id, entry)
    end)
  end

  def update_entry(list_id, entry_id, params)
      when is_integer(entry_id) and is_map(params) do
    :mnesia.transaction(fn ->
      :mnesia.write({ListItem, entry_id, list_id, params["content"]})
    end)
  end

  defp _create_list(list_id, name) do
    :mnesia.write({List, list_id, name})
  end

  defp _add_entry(list_id, entry) do
    entry_id = System.system_time(:millisecond)
    :mnesia.write({ListItem, entry_id, list_id, entry["content"]})
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
end
