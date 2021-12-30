defmodule ListerWeb.Components do
  use Phoenix.Component

  def list_item(assigns) do
    ~H"""
    <li class="list-item">
      <input
        type="text"
        value={ @item["content"] }
        phx-keyup="save-item"
        phx-value-item={@item["id"]}
        phx-debounce="500"
        x-ref="input"}
        x-on:blur="edited = false"
      />
      <button
        @click="edited = false">
        +
      </button>
    </li>
    """
  end

end
