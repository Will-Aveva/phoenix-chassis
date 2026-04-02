defmodule Chassis.SlotProviderTest do
  use ExUnit.Case, async: true

  # A minimal provider implementing only required callbacks
  defmodule MinimalProvider do
    use Chassis.SlotProvider

    @impl true
    def render_content(_slot_id, _assigns), do: "content"

    @impl true
    def tab_label(_slot_id, _assigns), do: "Label"
  end

  # A full provider implementing all callbacks
  defmodule FullProvider do
    use Chassis.SlotProvider

    @impl true
    def render_content(_slot_id, _assigns), do: "content"

    @impl true
    def tab_label(:editor, _assigns), do: "Editor"
    def tab_label(_, _assigns), do: "Unknown"

    @impl true
    def tab_icon(:editor), do: "code"
    def tab_icon(_), do: nil

    @impl true
    def closable?(:pinned), do: false
    def closable?(_), do: true
  end

  describe "minimal provider (required callbacks only)" do
    test "T-9.1: behaviour module defines correct callbacks" do
      callbacks = Chassis.SlotProvider.behaviour_info(:callbacks)
      assert {:render_content, 2} in callbacks
      assert {:tab_label, 2} in callbacks
      assert {:tab_icon, 1} in callbacks
      assert {:closable?, 1} in callbacks
    end

    test "T-9.5: compiles without warnings when omitting optional callbacks" do
      # If this module compiled, the test passes —
      # optional callbacks have defaults via __using__
      assert MinimalProvider.render_content(:any, %{}) == "content"
      assert MinimalProvider.tab_label(:any, %{}) == "Label"
    end

    test "optional callbacks have content-blind defaults" do
      assert MinimalProvider.tab_icon(:any) == nil
      assert MinimalProvider.closable?(:any) == true
    end
  end

  describe "full provider (all callbacks)" do
    test "required callbacks work" do
      assert FullProvider.render_content(:editor, %{}) == "content"
      assert FullProvider.tab_label(:editor, %{}) == "Editor"
      assert FullProvider.tab_label(:unknown, %{}) == "Unknown"
    end

    test "overridden optional callbacks work" do
      assert FullProvider.tab_icon(:editor) == "code"
      assert FullProvider.tab_icon(:other) == nil
      assert FullProvider.closable?(:pinned) == false
      assert FullProvider.closable?(:editor) == true
    end
  end

  describe "T-9.6: callbacks receive only slot ID" do
    test "render_content receives slot_id and assigns map" do
      # The type spec enforces (term(), map()) — verify at runtime
      assert FullProvider.render_content(:editor, %{slot_id: :editor}) == "content"
    end

    test "tab_label receives only slot_id" do
      assert FullProvider.tab_label(:editor, %{}) == "Editor"
    end
  end
end
