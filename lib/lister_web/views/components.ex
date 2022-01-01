defmodule ListerWeb.Components do
  use Phoenix.Component

  def list_item(assigns) do
    ~H"""
    <li class="list-item">
      <input
        type="text"
        value={ @item["content"] }
        phx-keyup="save-item"
        phx-value-item={ @item["id" ]}
        phx-debounce="500"
      />
      <button
        phx-click="add-item"
        phx-value-after-item={ @item["id"] }>
        +
      </button>
    </li>
    """
  end
end
