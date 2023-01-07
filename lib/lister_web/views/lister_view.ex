defmodule ListerWeb.ListerLiveView do
  use ListerWeb, :live_view

  @topic "list-updates"
  # render() replaced by lister_live_view.html.eex

  def mount(%{"code" => list_id}, _params, socket) do
    IO.puts("mount() for #{list_id}")
    Phoenix.PubSub.subscribe(Lister.PubSub, @topic)
    list = Lister.Lists.get_or_create_list(list_id)

    {
      :ok,
      add_basic_assigns(socket, list_id, list)
    }
  end

  # Events come from the UI (phx)
  def handle_event("update-item-content", %{"item" => item_id, "value" => value}, socket) do
    IO.puts("got save event #{item_id}")
    list_id = socket.assigns[:list_id]
    {item_id, _} = Integer.parse(item_id)
    Lister.Lists.update_item(list_id, item_id, %{"content" => value})

    Phoenix.PubSub.broadcast(Lister.PubSub, @topic, %{
      update: {list_id, item_id, %{"content" => value}}
    })

    {:noreply, socket}
  end

  def handle_event("update-item-completed", %{"item" => item_id, "value" => "on"}, socket) do
    IO.puts("got completed event #{item_id}")
    list_id = socket.assigns[:list_id]
    {item_id, _} = Integer.parse(item_id)
    Lister.Lists.update_item(list_id, item_id, %{"completed" => true})

    Phoenix.PubSub.broadcast(Lister.PubSub, @topic, %{
      update: {list_id, item_id, %{"completed" => true}}
    })

    {:noreply, socket}
  end

  def handle_event("update-item-completed", %{"item" => item_id}, socket) do
    IO.puts("got completed event #{item_id}")
    list_id = socket.assigns[:list_id]
    {item_id, _} = Integer.parse(item_id)
    Lister.Lists.update_item(list_id, item_id, %{"completed" => false})

    Phoenix.PubSub.broadcast(Lister.PubSub, @topic, %{
      update: {list_id, item_id, %{"completed" => false}}
    })

    {:noreply, socket}
  end

  def handle_event("add-item", %{"after-item" => after_item_id}, socket) do
    IO.puts("got add event after #{after_item_id}")
    list_id = socket.assigns[:list_id]
    {after_item_id, _} = Integer.parse(after_item_id)
    new_item_id = Lister.Lists.add_item_after(list_id, after_item_id)
    Phoenix.PubSub.broadcast(Lister.PubSub, @topic, %{add: {list_id, after_item_id, new_item_id}})
    {:noreply, socket}
  end

  # Handle info natches the pubsub notifications
  def handle_info(%{update: {_list_id, item_id, value}}, socket) do
    IO.inspect(value, label: "update call with #{item_id}")

    new_items =
      Lister.Lists.local_update_item_content(socket.assigns.list["items"], item_id, value)

    list = Map.put(socket.assigns[:list], "items", new_items)
    {:noreply, assign(socket, :list, list)}
  end

  def handle_info(%{add: {_list_id, after_item_id, new_item_id}}, socket) do
    IO.puts("add call with #{after_item_id}")

    new_items =
      Lister.Lists.local_add_item_after(socket.assigns.list["items"], new_item_id, after_item_id)

    list = Map.put(socket.assigns[:list], "items", new_items)
    {:noreply, assign(socket, :list, list)}
  end

  defp add_basic_assigns(socket, list_id, list) do
    assign(socket, :list_id, list_id)
    |> assign(:list, list)
  end
end
