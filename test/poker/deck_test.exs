defmodule Poker.DeckTest do
  alias Poker.Deck
  use ExUnit.Case, async: true

  setup_all do
    {:ok, deck: Deck.deck()}
  end

  test "deck has 52 cards", state do
    assert length(state[:deck]) == 52
  end

  test "draw 5 cards", state do
    {drawn, deck} = Deck.draw_cards(5, state[:deck])
    assert length(drawn) == 5
    assert length(deck) == 47
  end
end
