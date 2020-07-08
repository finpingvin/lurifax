defmodule LurifaxWeb.CommunityLive do
  alias Poker.Dealer
  alias LurifaxWeb.CardComponent
  use LurifaxWeb, :live_view
  require Logger

  @impl true
  def mount(_params, session, socket) do
    Dealer.register_community()
    {:ok, assign(socket, community_cards: [], query: "", results: %{})}
  end

  @impl true
  def handle_info({:poker_dealer_community_cards, cards}, socket) do
    IO.inspect cards, label: "Getting community cards"
    {:noreply, assign(socket, community_cards: cards)}
  end

  @impl true
  def handle_event("deal", _, socket) do
    Dealer.next()
    {:noreply, socket}
  end
end
