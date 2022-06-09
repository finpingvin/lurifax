defmodule Poker.Dealer do
  use GenServer
  require Logger
  alias Poker.Deck

  ###
  # Public API
  ###

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end


  def join(player_id) do
    Registry.register(Poker.Dealer.Registry, {:player_listeners, player_id}, [])
    GenServer.call(__MODULE__, {:join, player_id})
  end

  def get_player_cards(player_id) do
    GenServer.call(__MODULE__, {:player_cards, player_id})
  end

  def get_community_cards() do
    GenServer.call(__MODULE__, :community_cards)
  end

  def register_community() do
    Registry.register(Poker.Dealer.Registry, :community_listeners, [])
  end

  def next() do
    GenServer.cast(Poker.Dealer, :next)
  end

  ###
  # Private API
  ###

  def find_player(players, player_id) do
    Enum.find(players, fn(player) ->
      player.player_id == player_id
    end)
  end

  @impl true
  def init(:ok) do
    {:ok, %{
      :players => [],
      :deck => Deck.deck(),
      :community => [],
      :turn => :preflop,
    }}
  end

  # Stolen from: https://elixirforum.com/t/best-way-to-either-add-a-new-item-to-a-list-or-updating-an-existing-one/7361/2
  def ensure_player([], new_player) do
    [new_player]
  end
  def ensure_player([h = %{player_id: id} | t], %{player_id: id} = _new_player) do
    [h | t]
  end
  def ensure_player([h | t], new_player) do
    [h | ensure_player(t, new_player)]
  end

  @impl true
  def handle_call({:join, player_id}, _sender, state) do
    IO.inspect player_id, label: "Joining player with id"

    new_player = %{
      :player_id => player_id,
      :cards => [],
    }
    players = ensure_player(state.players, new_player)
    state = Map.put(state, :players, players)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:player_cards, player_id}, _sender, state) do
    IO.inspect player_id, label: "Sending player her cards"

    player = find_player(state.players, player_id)
    {:reply, player.cards, state}
  end

  @impl true
  def handle_call(:community_cards, _sender, state) do
    Logger.info "Sending community cards"
    {:reply, state.community, state}
  end

  @impl true
  def handle_cast(:next, state) do
    state = case state.turn do
      :preflop ->
        state
          |> cleanup_round()
          |> send_community()
          |> deal_players()
          |> Map.put(:turn, :flop)
      :flop ->
        state
          |> deal_community(3)
          |> Map.put(:turn, :turn)
      :turn ->
        state
          |> deal_community(1)
          |> Map.put(:turn, :river)
      :river ->
        state
          |> deal_community(1)
          |> Map.put(:turn, :preflop)
    end

    {:noreply, state}
  end

  def cleanup_round(state) do
    # TODO: Send new state to players and community registers
    state
      |> Map.put(:players, empty_player_cards(state.players))
      |> Map.put(:community, [])
      |> Map.put(:deck, Deck.deck())
  end

  def collect_player_cards([h | t]) do
    h.cards ++ collect_player_cards(t)
  end
  def collect_player_cards([]) do
    []
  end

  # TODO: Could be made in one iteration together with collect_player_cards
  def empty_player_cards([h | t]) do
    [Map.put(h, :cards, []) | empty_player_cards(t)]
  end
  def empty_player_cards([]) do
    []
  end

  def deal_players(state) do
    {players, deck} = deal_players(state.players, state.deck)

    state
      |> Map.put(:deck, deck)
      |> Map.put(:players, players)
  end

  def deal_players([player | players], deck) do
    {drawn, deck} = Deck.draw_cards(2, deck)
    player = Map.put(player, :cards, drawn)
    # TODO: Break this out so we can call it from cleanup round as well
    IO.inspect drawn, label: "Dealing cards to player #{player.player_id}"
    dispatch_player_cards(drawn, player.player_id)

    {players, deck} = deal_players(players, deck)
    {[player | players], deck}
  end

  def deal_players([], deck) do
    {[], deck}
  end

  def deal_community(state, how_many) do
    {drawn, deck} = Deck.draw_cards(how_many, state.deck)

    state = state
      |> Map.put(:community, state.community ++ drawn)
      |> Map.put(:deck, deck)
    dispatch_community_cards(state.community)
    state
  end

  def send_community(state) do
    dispatch_community_cards(state.community)
    state
  end

  defp dispatch_cards(cards, registry_term, send_term) do
    Registry.dispatch(Poker.Dealer.Registry, registry_term, fn entries ->
      for {pid, _} <- entries do
        send(pid, {send_term, cards})
      end
    end)
  end

  defp dispatch_community_cards(cards) do
    dispatch_cards(cards, :community_listeners, :poker_dealer_community_cards)
  end

  defp dispatch_player_cards(cards, player_id) do
    dispatch_cards(cards, {:player_listeners, player_id}, :poker_dealer_cards)
  end
end
