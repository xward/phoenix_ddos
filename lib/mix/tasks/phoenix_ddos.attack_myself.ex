defmodule Mix.Tasks.PhoenixDdos.AttackMyself do
  use Mix.Task

  @shortdoc "local ddos myself"

  @moduledoc """
  Using siege binary, attack localhost
  """

  @target "http://127.0.0.1:4000"
  @confirmation_message "This will spam request to #{IO.ANSI.cyan()}#{@target}#{IO.ANSI.reset()} during 20 seconds. Procceed ?"

  @impl true
  def run(args) when is_list(args) do
    ensure_siege_installed!()

    Mix.Shell.IO.yes?(@confirmation_message)

    System.cmd("siege", ["-t20S", @target])
  end

  defp ensure_siege_installed! do
    if System.find_executable("siege") == nil do
      raise """
      Missing siege binary #{IO.ANSI.cyan()}https://linux.die.net/man/1/siege#{IO.ANSI.reset()}

      you must install siege on your system. run:

        #{IO.ANSI.light_blue()}apt install siege#{IO.ANSI.reset()}

      or the command for your system.
      """
    end
  end
end
