defmodule ChassisWeb.Components.ShellTest do
  use ExUnit.Case, async: true
  use Phoenix.Component

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias ChassisWeb.Components.Shell

  # ---------------------------------------------------------------------------
  # Test providers
  # ---------------------------------------------------------------------------

  defmodule TestProvider do
    use Phoenix.Component
    use Chassis.SlotProvider

    @impl Chassis.SlotProvider
    def render_content(slot_id, _assigns) do
      assigns = %{slot_id: slot_id}

      ~H"""
      <div class="test-content">{@slot_id}</div>
      """
    end

    @impl Chassis.SlotProvider
    def tab_label(slot_id, _assigns), do: "Label:#{slot_id}"

    # closable?/1 defaults to true via __using__
    # tab_icon/1 defaults to nil via __using__
  end

  defmodule NonClosableProvider do
    use Phoenix.Component
    use Chassis.SlotProvider

    @impl Chassis.SlotProvider
    def render_content(slot_id, _assigns) do
      assigns = %{slot_id: slot_id}

      ~H"""
      <div class="test-content">{@slot_id}</div>
      """
    end

    @impl Chassis.SlotProvider
    def tab_label(slot_id, _assigns), do: "Label:#{slot_id}"

    @impl Chassis.SlotProvider
    def closable?(_slot_id), do: false
  end

  defmodule IconProvider do
    use Phoenix.Component
    use Chassis.SlotProvider

    @impl Chassis.SlotProvider
    def render_content(slot_id, _assigns) do
      assigns = %{slot_id: slot_id}

      ~H"""
      <div class="test-content">{@slot_id}</div>
      """
    end

    @impl Chassis.SlotProvider
    def tab_label(slot_id, _assigns), do: "Label:#{slot_id}"

    @impl Chassis.SlotProvider
    def tab_icon(_slot_id), do: "📄"
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp render_shell(tree, provider \\ TestProvider) do
    assigns = %{tree: tree, provider: provider}

    rendered_to_string(~H"""
    <Shell.layout tree={@tree} provider={@provider} />
    """)
  end

  # Helpers live at module level: a `defp` inside `describe` is legal but reads as scoped when it
  # is not.
  defp divider_ids(html) do
    ~r/class="chassis-divider"\s+id="([^"]+)"/
    |> Regex.scan(html)
    |> Enum.map(fn [_, id] -> id end)
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  describe "nil tree (INV-3.2)" do
    test "renders empty state" do
      html = render_shell(nil)
      assert html =~ "chassis-empty"
      assert html =~ "No layout"
    end
  end

  describe "bare slot → stack promotion (INV-3.2)" do
    test "slot promotes to stack with tab bar" do
      html = render_shell({:slot, :editor})
      assert html =~ "chassis-tab-bar"
      assert html =~ "chassis-stack"
    end
  end

  describe "stack rendering (INV-3.2)" do
    test "renders tab bar with correct tab count" do
      tree = {:stack, :a, [:a, :b, :c]}
      html = render_shell(tree)

      # 3 tabs
      assert length(Regex.scan(~r/chassis-tab /, html)) == 3
      # Active tab
      assert html =~ "chassis-tab active"
      # Inactive tabs
      assert length(Regex.scan(~r/chassis-tab inactive/, html)) == 2
    end

    test "renders slot content area" do
      tree = {:stack, :editor, [:editor]}
      html = render_shell(tree)
      assert html =~ "chassis-slot-content"
    end
  end

  describe "division rendering (INV-3.2)" do
    test "renders flex container with children" do
      tree = {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
      html = render_shell(tree)

      assert html =~ "chassis-division"
      assert html =~ "flex-direction: row"
      # 2 child stacks (bare slots promote)
      assert length(Regex.scan(~r/chassis-stack/, html)) == 2
    end

    test "vertical division uses column direction" do
      tree = {:division, :vertical, [{:slot, :a}, {:slot, :b}]}
      html = render_shell(tree)
      assert html =~ "flex-direction: column"
    end
  end

  describe "provider content (INV-1.1d, INV-9.2)" do
    test "render_content output appears in slot content area" do
      tree = {:stack, :editor, [:editor]}
      html = render_shell(tree)
      assert html =~ "test-content"
      assert html =~ "editor"
    end

    test "render_content receives slot_id in assigns" do
      # TestProvider renders slot_id into DOM — verify it matches active tab
      tree = {:stack, :my_slot, [:my_slot]}
      html = render_shell(tree)
      assert html =~ ">my_slot</div>"
    end
  end

  describe "tab labels from provider (INV-9.1)" do
    test "tab_label/1 output rendered in tab label span" do
      tree = {:stack, :editor, [:editor, :terminal]}
      html = render_shell(tree)
      assert html =~ "Label:editor"
      assert html =~ "Label:terminal"
    end
  end

  describe "closable gate (INV-9.1, INV-9.8)" do
    test "closable provider renders close button" do
      tree = {:stack, :a, [:a]}
      html = render_shell(tree, TestProvider)
      assert html =~ "chassis-tab-close"
    end

    test "non-closable provider omits close button" do
      tree = {:stack, :a, [:a]}
      html = render_shell(tree, NonClosableProvider)
      refute html =~ "chassis-tab-close"
    end
  end

  describe "tab icon rendering (INV-9.1, G-5)" do
    test "provider with icon renders chassis-tab-icon span" do
      tree = {:stack, :a, [:a]}
      html = render_shell(tree, IconProvider)
      assert html =~ "chassis-tab-icon"
      assert html =~ "📄"
    end

    test "default nil icon omits chassis-tab-icon span" do
      tree = {:stack, :a, [:a]}
      html = render_shell(tree, TestProvider)
      refute html =~ "chassis-tab-icon"
    end
  end

  describe "divider identity (INV-3.3)" do
    test "a divider is named by both of the subtrees it separates" do
      tree = {:division, :horizontal, [{:slot, :a}, {:slot, :b}]}
      assert divider_ids(render_shell(tree)) == ["chassis-divider-a-b"]
    end

    test "no divider follows the last child" do
      tree = {:division, :horizontal, [{:slot, :a}, {:slot, :b}, {:slot, :c}]}
      assert divider_ids(render_shell(tree)) == ["chassis-divider-a-b", "chassis-divider-b-c"]
    end

    test "a nested division does not collide with its parent's divider" do
      # The id used to be built from the child's leftmost slot alone, and `first_slot_id/1` walks
      # into the subtree — so this tree rendered `chassis-divider-a` twice, at two levels. LiveView
      # patches by id, so the second divider was undraggable: the resize hook mounted on the first.
      #
      # Reachable by dragging a pane onto the top or bottom edge of a pane that is already split,
      # which is why `ChassisWeb.TabbedStackTest` hit it before any test named it.
      tree =
        {:division, :vertical,
         [
           {:division, :vertical, [{:slot, :a}, {:slot, :b}]},
           {:slot, :c}
         ]}

      ids = divider_ids(render_shell(tree))
      assert ids == Enum.uniq(ids)
      assert ids == ["chassis-divider-a-b", "chassis-divider-a-c"]
    end

    test "a stack's active tab does not move its divider's identity" do
      # Clicking a tab must not rename the divider beside it, or the hook is torn down and
      # remounted mid-arrangement. The id follows the stack's FIRST tab, like the weight does.
      tree = {:division, :horizontal, [{:stack, :a, [:a, :b]}, {:slot, :c}]}
      focused = {:division, :horizontal, [{:stack, :b, [:a, :b]}, {:slot, :c}]}

      assert divider_ids(render_shell(tree)) == divider_ids(render_shell(focused))
    end
  end

  describe "deterministic rendering (INV-3.1)" do
    test "same tree produces identical HTML" do
      tree =
        {:division, :horizontal,
         [
           {:stack, :a, [:a, :b]},
           {:slot, :c}
         ]}

      html1 = render_shell(tree)
      html2 = render_shell(tree)
      assert html1 == html2
    end
  end
end
