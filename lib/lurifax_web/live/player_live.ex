defmodule LurifaxWeb.PlayerLive do
  alias Poker.Dealer
  alias LurifaxWeb.CardComponent
  use LurifaxWeb, :live_view
  require Logger

  @impl true
  def mount(_params, session, socket) do
    Dealer.join(session["player_id"])
    player_cards = Dealer.get_player_cards(session["player_id"])
    {:ok, assign(socket, player_cards: player_cards, query: "", results: %{})}
  end

  @impl true
  def handle_info({:poker_dealer_cards, cards}, socket) do
    IO.inspect cards, label: "Getting player cards"
    {:noreply, assign(socket, player_cards: cards)}
  end
end
