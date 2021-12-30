defmodule ListerWeb.ListerController do
  use ListerWeb, :controller

  def list(conn, %{ "code" => code}) do
    render(conn, "list.html", code: code)
  end
end
