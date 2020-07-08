defmodule LurifaxWeb.CardComponent do
  use LurifaxWeb, :live_component

  def get_card_image_name(card) do
    IO.inspect card, label: "Translating card name"
    value = case card[:value] do
      11 -> "jack"
      12 -> "queen"
      13 -> "king"
      14 -> "ace"
      _ -> card[:value]
    end
    suit = Atom.to_string(card[:suit])
    "#{value}_of_#{suit}.svg"
  end
end
