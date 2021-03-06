defmodule EasyTimer do
  @moduledoc """
  Public API to create a series of live timers, grouped into a Scenario.
  A Scenario is made up of one or more phases.
  """
  alias EasyTimer.{Scenario, ScenarioSupervisor, Phase, CSV}

  @doc """
  Create a new scenario server with client options.
  Client receives either:
    - Scenario ID (for Registry PID lookup), scenario admin pin code
    - Error(s) map

    Note: https://hexdocs.pm/elixir/GenServer.html#module-name-registration
  """
  def create(:quick, data) when is_map(data) do
    case Phase.create(:quick, Map.put(data, :id, 1)) do
      %Phase{} = phase ->
        scenario = setup_timer([phase])
        %{scenario_id: scenario.id, admin_pin: scenario.admin_pin}

      {:error, %{} = response} ->
        {:error, %{type: "phase_init_errors", errors: response.errors}}
    end
  end

  def create(:custom, %{file: file}) do
    with {:ok, data} <- CSV.load(file),
         {:ok, phases} <- process_custom_timer_data(data) do
      scenario = setup_timer(phases)
      %{scenario_id: scenario.id, admin_pin: scenario.admin_pin}
    else
      {:error, %{} = response} -> {:error, response}
    end
  end

  def create(_, _), do: {:error, %{type: "invalid_scenario_type", errors: nil}}

  defp process_custom_timer_data(data) do
    processed_phases =
      Enum.map(data, fn item ->
        case Phase.create(:custom, item) do
          %Phase{} = phase -> phase
          error -> error
        end
      end)

    if Enum.all?(
         processed_phases,
         &(is_struct(&1) and Map.get(&1, :__struct__) == :"Elixir.EasyTimer.Phase")
       ) do
      {:ok, processed_phases}
    else
      errors = Enum.filter(processed_phases, &(is_tuple(&1) and elem(&1, 0) == :error))
      {:error, %{type: "phase_init_errors", errors: errors}}
    end
  end

  defp setup_timer([first | rest] = phases) do
    scenario = %Scenario{
      current_phase: first,
      next_phases: rest,
      total_rounds: length(phases),
      id: "#{gen_scenario_id()}",
      admin_pin: "#{gen_admin_pin()}"
    }

    {:ok, _pid} = ScenarioSupervisor.start_scenario(scenario)

    scenario
  end

  def authorize_admin(scenario, pin) do
    IO.puts("API: attempting to authorize scenario admin")
    EasyTimer.ScenarioServer.authorize_admin(scenario, pin)
  end

  def get_scenario(scenario_id) do
    IO.puts("API: attempting to get scenario server PID for ID:#{scenario_id}")

    case Registry.lookup(EasyTimer.ScenarioServer, scenario_id) do
      [{pid, _} | _] -> pid
      [] -> {:error, "Scenario not found or no longer alive"}
    end
  end

  def get_scenario_data(scenario) do
    IO.puts("API: attempting to get scenario data for server PID:")
    # IO.inspect(scenario)
    EasyTimer.ScenarioServer.get(scenario)
  end

  def next(scenario) do
    IO.puts("API: attempting to go to next phase on scenario server PID:")
    # IO.inspect(scenario)
    EasyTimer.ScenarioServer.next(scenario)
  end

  def pause(scenario) do
    IO.puts("API: attempting to pause scenario server PID:")
    # IO.inspect(scenario)
    EasyTimer.ScenarioServer.pause(scenario)
  end

  def previous(scenario) do
    IO.puts("API: attempting to go to previous phase on scenario server PID:")
    # IO.inspect(scenario)
    EasyTimer.ScenarioServer.previous(scenario)
  end

  def start(scenario) do
    IO.puts("API: attempting to start scenario server PID:")
    # IO.inspect(scenario)
    EasyTimer.ScenarioServer.start(scenario)
  end

  def stop(scenario) do
    IO.puts("API: attempting to stop scenario server PID:")
    # IO.inspect(scenario)
    EasyTimer.ScenarioServer.stop(scenario)
  end

  #
  # HELPERS
  #
  defp gen_scenario_id do
    n = :rand.uniform(999_999)
    if n < 1000, do: gen_admin_pin(), else: n
  end

  defp gen_admin_pin do
    n = :rand.uniform(9999)
    if n < 1000, do: gen_admin_pin(), else: n
  end
end
