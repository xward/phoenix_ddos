defmodule PhoenixDDoS.TemplateHelper do
  @moduledoc false

  # this is where the fun begins !
  # runtime code compilation to prepare high-performance tools

  require Logger

  @templates [__DIR__, "/*.eex"]
             |> Path.join()
             |> Path.wildcard()
             |> Map.new(fn file_name ->
               {Path.basename(file_name, ".eex"), File.read!(file_name)}
             end)

  def compile(context, template_name) do
    Code.put_compiler_option(:ignore_module_conflict, true)

    @templates[template_name]
    |> EEx.eval_string(Keyword.new(context))
    # |> inspect_code()
    |> Code.compile_string()

    Code.put_compiler_option(:ignore_module_conflict, false)
  end

  def render_list(list) do
    "[#{Enum.map_join(list, ", ", fn e -> inspect(e) end)}]"
  end

  # --------------------------------------------------------------
  # debug generated code
  # --------------------------------------------------------------

  def inspect_code(content) do
    IO.puts("-----------------------------------------------------------------")

    try do
      content |> Code.format_string!()
    rescue
      _ ->
        content
        |> String.split("\n")
        |> Stream.with_index(1)
        |> Enum.map_join("\n", fn {l, i} -> "#{i}: #{l}" end)
    end
    |> print()

    content
  end

  defp print(content), do: Logger.info(["\n", content])
end
