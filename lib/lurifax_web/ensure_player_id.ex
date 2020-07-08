defmodule LurifaxWeb.EnsureUserId do
  import Plug.Conn

  def init(opts \\ []) do
    opts
  end

  def call(conn, _opts) do
    user_id = get_session(conn, :player_id)
    if user_id do
      conn
    else
      put_session(conn, :player_id, UUID.uuid4())
    end
  end
end
