defmodule Crucible.UI.Components do
  @moduledoc """
  Reusable UI components for Crucible experiment dashboards.

  These components are host-agnostic and can be used in any Phoenix LiveView
  application that imports this module. All components follow Phoenix.Component
  conventions and work seamlessly with LiveView.

  ## Component Categories

  ### Layout & Navigation
  - `header/1` - Page headers with optional subtitle and actions
  - `back/1` - Back navigation link

  ### Data Display
  - `stat_card/1` - Metric display cards
  - `status_badge/1` - Status indicators
  - `list/1` - Definition lists
  - `table/1` - Data tables with streaming

  ### Interaction
  - `button/1` - Action buttons
  - `modal/1` - Modal dialogs

  ### Utilities
  - `icon/1` - Heroicons

  ## Usage

      defmodule MyAppWeb.MyLive do
        use Phoenix.LiveView
        import Crucible.UI.Components

        def render(assigns) do
          ~H\"""
          <.header>
            My Dashboard
            <:subtitle>Real-time experiment tracking</:subtitle>
            <:actions>
              <.button phx-click="refresh">Refresh</.button>
            </:actions>
          </.header>

          <div class="grid grid-cols-3 gap-4">
            <.stat_card
              icon="hero-beaker"
              label="Total Experiments"
              value={@experiment_count}
            />
            <.stat_card
              icon="hero-play"
              label="Running"
              value={@running_count}
              icon_class="text-green-400"
            />
          </div>

          <.table id="experiments" rows={@streams.experiments}>
            <:col :let={{_id, exp}} label="Name"><%= exp.name %></:col>
            <:col :let={{_id, exp}} label="Status">
              <.status_badge status={exp.status} />
            </:col>
          </.table>
          \"""
        end
      end

  ## Styling

  All components use Tailwind CSS classes and follow a consistent design system:
  - Gray for neutral elements
  - Blue for running/active states
  - Green for completed/success states
  - Red for failed/error states
  - Yellow for warning/cancelled states

  Components accept additional CSS classes via the `class` attribute for
  customization while maintaining the base styles.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a statistic card with icon, label, and value.

  ## Examples

      <.stat_card
        icon="hero-beaker"
        label="Total Experiments"
        value={42}
        icon_class="text-blue-400"
      />
  """
  attr :icon, :string, required: true, doc: "Heroicon name (e.g., 'hero-beaker')"
  attr :label, :string, required: true, doc: "Card label text"
  attr :value, :any, required: true, doc: "Value to display"
  attr :icon_class, :string, default: "text-gray-400", doc: "Tailwind classes for icon color"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def stat_card(assigns) do
    ~H"""
    <div class={["bg-white overflow-hidden shadow rounded-lg", @class]}>
      <div class="p-5">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <.icon name={@icon} class={"h-6 w-6 #{@icon_class}"} />
          </div>
          <div class="ml-5 w-0 flex-1">
            <dl>
              <dt class="text-sm font-medium text-gray-500 truncate"><%= @label %></dt>
              <dd class="text-lg font-semibold text-gray-900"><%= @value %></dd>
            </dl>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a status badge with appropriate coloring.

  ## Examples

      <.status_badge status="running" />
      <.status_badge status="completed" class="ml-2" />
  """
  attr :status, :string, required: true, doc: "Status value"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
      status_color(@status),
      @class
    ]}>
      <%= @status %>
    </span>
    """
  end

  @doc """
  Renders a header with optional subtitle and actions.

  ## Examples

      <.header>
        Experiments
        <:subtitle>Manage your ML experiments</:subtitle>
        <:actions>
          <.button>New Experiment</.button>
        </:actions>
      </.header>
  """
  attr :class, :string, default: ""
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={@class}>
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            <%= render_slot(@inner_block) %>
          </h1>
          <p :if={@subtitle != []} class="mt-2 text-sm text-gray-700">
            <%= render_slot(@subtitle) %>
          </p>
        </div>
        <div :if={@actions != []} class="flex gap-2">
          <%= render_slot(@actions) %>
        </div>
      </div>
    </header>
    """
  end

  @doc """
  Renders a simple list with items.

  ## Examples

      <.list>
        <:item title="Name"><%= @experiment.name %></:item>
        <:item title="Status"><.status_badge status={@experiment.status} /></:item>
      </.list>
  """
  attr :class, :string, default: ""

  slot :item, doc: "List items" do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <dl class={["divide-y divide-gray-200", @class]}>
      <%= for item <- @item do %>
        <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4">
          <dt class="text-sm font-medium text-gray-500"><%= item.title %></dt>
          <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
            <%= render_slot(item) %>
          </dd>
        </div>
      <% end %>
    </dl>
    """
  end

  @doc """
  Renders a back link/button.

  ## Examples

      <.back navigate={~p"/experiments"}>Back to experiments</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-8">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left" class="h-3 w-3 inline-block" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Save</.button>
      <.button phx-click="delete" data-confirm="Are you sure?">Delete</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a table with sortable columns and clickable rows.

  ## Examples

      <.table id="experiments" rows={@streams.experiments}>
        <:col :let={{_id, exp}} label="Name"><%= exp.name %></:col>
        <:col :let={{_id, exp}} label="Status"><.status_badge status={exp.status} /></:col>
        <:action :let={{_id, exp}}>
          <.link navigate={~p"/experiments/\#{exp.id}"}>Show</.link>
        </:action>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_click, :any, default: nil
  attr :row_id, :any, default: nil

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "Action buttons" do
    attr :label, :string
  end

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 sm:rounded-lg">
      <table class="min-w-full divide-y divide-gray-300">
        <thead class="bg-gray-50">
          <tr>
            <th :for={col <- @col} class="py-3.5 px-3 text-left text-sm font-semibold text-gray-900">
              <%= col[:label] %>
            </th>
            <th :if={@action != []} class="relative py-3.5 px-3">
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={(match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream") || "replace"}
          class="divide-y divide-gray-200 bg-white"
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class={@row_click && "hover:bg-gray-50 cursor-pointer"}
          >
            <td
              :for={{col, _i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class="whitespace-nowrap py-4 px-3 text-sm text-gray-900"
            >
              <%= render_slot(col, row) %>
            </td>
            <td :if={@action != []} class="relative whitespace-nowrap py-4 px-3 text-right text-sm">
              <span
                :for={action <- @action}
                class="ml-4 text-zinc-900 hover:text-zinc-700 font-medium"
              >
                <%= render_slot(action, row) %>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a modal dialog.

  ## Examples

      <.modal id="confirm-modal" show on_cancel={JS.patch(~p"/experiments")}>
        <p>Are you sure?</p>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-zinc-50/90 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <div
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label="close"
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a heroicon.

  ## Examples

      <.icon name="hero-beaker" />
      <.icon name="hero-beaker" class="h-6 w-6 text-blue-500" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: ""

  def icon(assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  # Helper functions

  defp status_color("pending"), do: "bg-gray-100 text-gray-800"
  defp status_color("running"), do: "bg-blue-100 text-blue-800"
  defp status_color("completed"), do: "bg-green-100 text-green-800"
  defp status_color("failed"), do: "bg-red-100 text-red-800"
  defp status_color("cancelled"), do: "bg-yellow-100 text-yellow-800"
  defp status_color(_), do: "bg-gray-100 text-gray-800"

  defp show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  defp hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  defp show(js, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  defp hide(js, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end
