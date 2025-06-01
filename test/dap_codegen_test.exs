defmodule DAPCodegenTest do
  use ExUnit.Case
  doctest DAPCodegen

  @output_dir "../dap_codegen_lib/lib/dap"

  test "generates DAP code and verifies it can be compiled" do
    # Ensure project directory exists
    project_dir = (@output_dir <> "/../..") |> Path.expand()
    File.mkdir_p!(project_dir)

    # Initialize mix project if needed
    unless File.exists?(Path.join(project_dir, "mix.exs")) do
      {result, 0} =
        System.cmd("mix", ["new", "dap_codegen_lib", "--module", "DapCodegenLib"],
          cd: Path.dirname(project_dir)
        )

      IO.puts("Mix project creation output: \n#{result}")
    end

    # Update mix.exs with required dependencies
    mix_file = Path.join(project_dir, "mix.exs")
    mix_content = File.read!(mix_file)

    updated_content =
      String.replace(mix_content, "defp deps do\n    [\n    ]", """
      defp deps do
        [
          {:schematic, "~> 0.2"},
          {:typed_struct, "~> 0.3"},
          {:jason, "~> 1.4"}
        ]
      """)

    File.write!(mix_file, updated_content)

    # Ensure output directory exists
    File.rm_rf!(@output_dir)
    File.mkdir_p!(@output_dir)

    # Generate the code
    assert :ok = DAPCodegen.generate(["--path", @output_dir])

    # List generated files for debugging
    IO.puts("\nGenerated files in #{@output_dir}:")

    case File.ls(@output_dir) do
      {:ok, files} -> Enum.each(files, &IO.puts/1)
      {:error, reason} -> IO.puts("Error listing files: #{inspect(reason)}")
    end

    # Get dependencies
    IO.puts("\nFetching dependencies...")
    {deps_result, deps_status} = System.cmd("mix", ["deps.get"], cd: project_dir)
    IO.puts("Dependencies output:\n#{deps_result}")
    assert deps_status == 0

    # Attempt to compile the generated code
    IO.puts("\nAttempting to compile...")
    {result, status} = System.cmd("mix", ["compile"], cd: project_dir)
    IO.puts("Compilation output:\n#{result}")
    IO.puts("Exit status: #{status}")

    assert status == 0
    assert String.contains?(result, "Generated") or String.contains?(result, "Compiled")
  end
end
