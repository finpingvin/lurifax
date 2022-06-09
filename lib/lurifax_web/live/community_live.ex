defmodule LurifaxWeb.CommunityLive do
  alias Poker.Dealer
  alias LurifaxWeb.CardComponent
  alias LurifaxWeb.PreviousCardComponent
  use LurifaxWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    Dealer.register_community()
    community_cards = Dealer.get_community_cards()
    {:ok, assign(socket, community_cards: community_cards, previous_cards: [], query: "", results: %{})}
  end

  @impl true
  def handle_info({:poker_dealer_community_cards, cards}, socket) do
    IO.inspect cards, label: "Getting community cards"
    previous_cards = if length(cards) == 0, do: socket.assigns.community_cards, else: []
    {:noreply, assign(socket, community_cards: cards, previous_cards: previous_cards)}
  end

  @impl true
  def handle_event("deal", _, socket) do
    Dealer.next()
    {:noreply, socket}
  end
end
