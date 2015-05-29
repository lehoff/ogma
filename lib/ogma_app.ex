defmodule Ogma.App do
  use Application

  def start(_type, _args) do
    Ogma.Sup.start_link()
  end

end
