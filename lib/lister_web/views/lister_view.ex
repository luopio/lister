defmodule ListerWeb.ListerLiveView do
  use ListerWeb, :live_view

  @topic "list-updates"
  # render() replaced by lister_live_view.html.eex

  def mount(%{"code" => list_id}, _params, socket) do
    IO.puts("mount() for #{list_id}")
    Phoenix.PubSub.subscribe(Lister.PubSub, @topic)
    # if connected?(socket) do
    #   Process.send_after(self(), :update_foo, 2000)
    # end
    list = Lister.Lists.get_or_create_list(list_id)
    IO.puts("got a list")
    IO.inspect(list)
    {
      :ok,
      add_basic_assigns(socket, list_id, list)
    }
  end

  def handle_event("save-item", %{"item" => item_id, "value" => value}, socket) do
    IO.puts("got save event #{item_id}")
    list_id = socket.assigns[:list_id]
    {item_id, _}= Integer.parse(item_id)
    Lister.Lists.update_item(list_id, item_id, %{"content" => value})
    new_list = Lister.Lists.get_list(list_id)
    IO.inspect(new_list)
    Phoenix.PubSub.broadcast(Lister.PubSub, @topic, "update")
    {:noreply, assign(socket, :list, new_list)}
  end

  def handle_event("add-item", %{"after-item" => after_item_id}, socket) do
    list_id = socket.assigns[:list_id]
    {after_item_id, _}= Integer.parse(after_item_id)
    new_list = Lister.Lists.add_item_after(list_id, after_item_id)
    {:noreply, assign(socket, :list, new_list)}
  end

  def handle_info("update", socket) do
    list_id = socket.assigns.list_id
    list = Lister.Lists.get_list(list_id)
    {:noreply, assign(socket, :list, list)}
  end

  defp add_basic_assigns(socket, list_id, list) do
    assign(socket, :list_id, list_id)
      |> assign(:list, list)
  end
end
