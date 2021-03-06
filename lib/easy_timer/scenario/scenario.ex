defmodule EasyTimer.Scenario do
  alias EasyTimer.Phase

  @moduledoc """
  Defines a Scenario struct which is an ordered series of Phases.
  Sports example:
    - Stretch, 5min
    - Cardio, 5min
    - Weight lifting, 20min
    - Bike, 30min
  """
  defstruct id: nil,
            admin_pin: nil,
            auto_advance: false,
            auto_reset: true,
            current_round: 1,
            current_phase: %Phase{},
            next_phases: [],
            previous_phases: [],
            status: :created,
            total_rounds: 1
end
