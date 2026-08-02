defmodule ChassisWeb.TabbedStackTest do
  @moduledoc """
  Multi-tab interactions driven end to end, through the events the hooks actually push.

  `demo_live_test.exs` asserts that each event is handled. This file asserts what the user is
  looking at afterwards: which pane holds which tabs, in what order, and which one is showing.
  Every assertion reads the whole tab bar rather than a substring, because `html =~ "notes"`
  passes for a tab that landed in the wrong pane, in the wrong order, or twice.

  The payloads are copied from `assets/js/hooks/chassis_hooks.js` — `slot_id` for focus,
  `slot-id` for close, `target_id`/`dragged_id` for drops — so a rename on either side breaks a
  test rather than the shell.
  """
  use ChassisWeb.ConnCase
  import Phoenix.LiveViewTest

  # The demo's :default composition is `editor | (preview / terminal)`.
  @default_arrangement [
    %{active: "editor", tabs: [{"editor", "active"}]},
    %{active: "preview", tabs: [{"preview", "active"}]},
    %{active: "terminal", tabs: [{"terminal", "active"}]}
  ]

  # ---------------------------------------------------------------------------
  # Reading the rendered shell
  # ---------------------------------------------------------------------------

  # One entry per rendered pane, in document order: the tab bar's contents and which tab is
  # showing. A pane's chunk runs to the start of the next pane, and stacks are siblings rather
  # than nested, so the slice is exactly one pane's chrome.
  defp stacks(html) do
    html
    |> String.split(~s(class="chassis-stack"))
    |> tl()
    |> Enum.map(fn chunk ->
      %{active: active_id(chunk), tabs: tabs(chunk)}
    end)
  end

  defp active_id(chunk) do
    case Regex.run(~r/^\s*data-active-id="([^"]*)"/, chunk) do
      [_, id] -> id
      nil -> nil
    end
  end

  defp tabs(chunk) do
    ~r/class="chassis-tab (active|inactive)"[^>]*?id="chassis-tab-([^"]+)"/
    |> Regex.scan(chunk)
    |> Enum.map(fn [_, state, id] -> {id, state} end)
  end

  defp tab_ids(html) do
    ~r/id="chassis-tab-([^"]+)"/
    |> Regex.scan(html)
    |> Enum.map(fn [_, id] -> id end)
  end

  defp shell_focus(html) do
    case Regex.run(~r/data-active-slot="([^"]*)"/, html) do
      [_, id] -> id
      nil -> nil
    end
  end

  # ---------------------------------------------------------------------------
  # Driving the hooks
  # ---------------------------------------------------------------------------

  defp click_tab(view, slot_id),
    do: render_hook(view, "chassis:focus_slot", %{"slot_id" => slot_id})

  defp drop_on_centre(view, target, dragged) do
    render_hook(view, "chassis:dock_slot", %{"target_id" => target, "dragged_id" => dragged})
  end

  defp drop_on_edge(view, target, dragged, direction) do
    render_hook(view, "chassis:split_slot", %{
      "target_id" => target,
      "dragged_id" => dragged,
      "direction" => direction
    })
  end

  defp drop_on_tab(view, target, dragged) do
    render_hook(view, "chassis:reorder_slot", %{"target_id" => target, "dragged_id" => dragged})
  end

  defp ctrl_tab(view, from), do: render_hook(view, "chassis:focus_next", %{"slot_id" => from})

  defp ctrl_shift_tab(view, from),
    do: render_hook(view, "chassis:focus_prev", %{"slot_id" => from})

  defp ctrl_w(view, slot_id), do: render_hook(view, "chassis:close_slot", %{"slot-id" => slot_id})

  defp alt_arrow(view, from, direction) do
    render_hook(view, "chassis:focus_direction", %{"slot_id" => from, "direction" => direction})
  end

  # ---------------------------------------------------------------------------
  # Docking
  # ---------------------------------------------------------------------------

  describe "dropping a panel on a pane's centre" do
    test "the pane gains a tab, the dropped panel is showing, and its old pane is gone", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, "/")
      assert stacks(html) == @default_arrangement

      html = drop_on_centre(view, "editor", "terminal")

      assert stacks(html) == [
               %{active: "terminal", tabs: [{"editor", "inactive"}, {"terminal", "active"}]},
               %{active: "preview", tabs: [{"preview", "active"}]}
             ]
    end

    test "a panel dragged in from the sidebar arrives as a tab, exactly once", %{conn: conn} do
      # The sidebar's slot ids are not in the tree yet, so this is the branch that creates a slot
      # rather than moving one. It still has to leave one tab, not two: the handler attaches,
      # closes and re-adds, and only the last of those three is what the user sees.
      {:ok, view, _html} = live(conn, "/")

      html = drop_on_centre(view, "editor", "notes")

      assert stacks(html) == [
               %{active: "notes", tabs: [{"editor", "inactive"}, {"notes", "active"}]},
               %{active: "preview", tabs: [{"preview", "active"}]},
               %{active: "terminal", tabs: [{"terminal", "active"}]}
             ]

      assert tab_ids(html) == Enum.uniq(tab_ids(html))
    end

    test "a second panel from the sidebar appends rather than replacing the first", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      drop_on_centre(view, "editor", "notes")
      html = drop_on_centre(view, "editor", "debugger")

      assert hd(stacks(html)) == %{
               active: "debugger",
               tabs: [{"editor", "inactive"}, {"notes", "inactive"}, {"debugger", "active"}]
             }
    end
  end

  # ---------------------------------------------------------------------------
  # Clicking
  # ---------------------------------------------------------------------------

  describe "clicking a tab" do
    test "shows that tab without reordering the tab bar", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")

      html = click_tab(view, "editor")

      assert hd(stacks(html)) == %{
               active: "editor",
               tabs: [{"editor", "active"}, {"notes", "inactive"}]
             }

      assert shell_focus(html) == "editor"
    end

    test "clicking into another pane moves the shell's focus and leaves both tab bars alone", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/")

      html = click_tab(view, "terminal")

      assert stacks(html) == @default_arrangement
      assert shell_focus(html) == "terminal"
    end
  end

  # ---------------------------------------------------------------------------
  # Keyboard
  # ---------------------------------------------------------------------------

  describe "cycling tabs from the keyboard" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")
      drop_on_centre(view, "editor", "debugger")
      %{view: view}
    end

    test "ctrl+tab walks forward and wraps at the end", %{view: view} do
      assert shell_focus(ctrl_tab(view, "editor")) == "notes"
      assert shell_focus(ctrl_tab(view, "notes")) == "debugger"
      assert shell_focus(ctrl_tab(view, "debugger")) == "editor"
    end

    test "ctrl+shift+tab walks back and wraps at the start", %{view: view} do
      assert shell_focus(ctrl_shift_tab(view, "editor")) == "debugger"
      assert shell_focus(ctrl_shift_tab(view, "debugger")) == "notes"
    end

    test "the tab bar follows the keyboard, so what is showing matches what is focused", %{
      view: view
    } do
      html = ctrl_tab(view, "editor")

      assert hd(stacks(html)) == %{
               active: "notes",
               tabs: [{"editor", "inactive"}, {"notes", "active"}, {"debugger", "inactive"}]
             }
    end

    test "ctrl+tab in a one-tab pane does nothing at all", %{view: view} do
      # Compared through `render/1` on both sides: a hook's return value is the rendered content
      # without the LiveView container, so it is not comparable to `render/1`'s output.
      before = render(view)
      ctrl_tab(view, "preview")
      assert render(view) == before
      ctrl_shift_tab(view, "preview")
      assert render(view) == before
    end
  end

  describe "spatial navigation between panes" do
    test "alt+arrow lands on the neighbouring pane's visible tab", %{conn: conn} do
      # Not its first tab: moving focus must not also change what that pane is showing.
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "preview", "notes")

      assert shell_focus(alt_arrow(view, "editor", "right")) == "notes"
      assert shell_focus(alt_arrow(view, "notes", "left")) == "editor"
      assert shell_focus(alt_arrow(view, "notes", "down")) == "terminal"
    end

    test "alt+arrow at an edge is a no-op", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      click_tab(view, "editor")
      before = render(view)

      alt_arrow(view, "editor", "left")
      assert render(view) == before
      alt_arrow(view, "editor", "up")
      assert render(view) == before
    end
  end

  # ---------------------------------------------------------------------------
  # Closing
  # ---------------------------------------------------------------------------

  describe "closing a tab" do
    test "closing an inactive tab leaves what is showing alone", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")
      drop_on_centre(view, "editor", "debugger")

      html = ctrl_w(view, "notes")

      assert stacks(html) == [
               %{active: "debugger", tabs: [{"editor", "inactive"}, {"debugger", "active"}]},
               %{active: "preview", tabs: [{"preview", "active"}]},
               %{active: "terminal", tabs: [{"terminal", "active"}]}
             ]
    end

    test "closing the tab that is showing promotes the first remaining one", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")
      drop_on_centre(view, "editor", "debugger")

      html = ctrl_w(view, "debugger")

      assert stacks(html) == [
               %{active: "editor", tabs: [{"editor", "active"}, {"notes", "inactive"}]},
               %{active: "preview", tabs: [{"preview", "active"}]},
               %{active: "terminal", tabs: [{"terminal", "active"}]}
             ]
    end

    test "closing a pane's last tab removes the pane and collapses its division", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      ctrl_w(view, "terminal")
      html = ctrl_w(view, "preview")

      assert stacks(html) == [%{active: "editor", tabs: [{"editor", "active"}]}]
      refute html =~ "chassis-division", "one pane left, so there is nothing to divide"
    end

    test "a pane left with one tab still renders a tab bar", %{conn: conn} do
      # The lone slot is re-promoted to a one-tab stack at render time, so a single panel is not a
      # special case with its own chrome.
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")

      html = ctrl_w(view, "notes")

      assert hd(stacks(html)) == %{active: "editor", tabs: [{"editor", "active"}]}
      assert html =~ "chassis-tab-bar"
    end
  end

  # ---------------------------------------------------------------------------
  # Tearing out
  # ---------------------------------------------------------------------------

  describe "dragging a tab onto a pane's edge" do
    test "a right drop puts the torn-out tab after the pane it split", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")

      html = drop_on_edge(view, "editor", "notes", "right")

      assert stacks(html) == [
               %{active: "editor", tabs: [{"editor", "active"}]},
               %{active: "notes", tabs: [{"notes", "active"}]},
               %{active: "preview", tabs: [{"preview", "active"}]},
               %{active: "terminal", tabs: [{"terminal", "active"}]}
             ]
    end

    test "a left drop puts it before — the compass direction is translated once, at the handler",
         %{
           conn: conn
         } do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")

      html = drop_on_edge(view, "editor", "notes", "left")

      assert Enum.take(stacks(html), 2) == [
               %{active: "notes", tabs: [{"notes", "active"}]},
               %{active: "editor", tabs: [{"editor", "active"}]}
             ]
    end

    test "an up drop splits vertically, before", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")

      html = drop_on_edge(view, "editor", "notes", "up")

      assert Enum.take(stacks(html), 2) == [
               %{active: "notes", tabs: [{"notes", "active"}]},
               %{active: "editor", tabs: [{"editor", "active"}]}
             ]

      assert html =~ "flex-direction: column"
    end

    test "tearing a tab out leaves no duplicate of it behind", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")

      html = drop_on_edge(view, "preview", "notes", "down")

      assert tab_ids(html) == ["editor", "preview", "notes", "terminal"]
    end
  end

  # ---------------------------------------------------------------------------
  # Reordering
  # ---------------------------------------------------------------------------

  describe "dropping a tab on another tab" do
    test "the dragged tab lands before the target and becomes the one showing", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")
      drop_on_centre(view, "editor", "debugger")

      html = drop_on_tab(view, "editor", "debugger")

      assert hd(stacks(html)) == %{
               active: "debugger",
               tabs: [{"debugger", "active"}, {"editor", "inactive"}, {"notes", "inactive"}]
             }
    end

    test "a tab dropped on a tab in another pane changes panes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      drop_on_centre(view, "editor", "notes")

      html = drop_on_tab(view, "terminal", "notes")

      # Dropped on a pane that had a single tab, so it lands second — see
      # `Chassis.LayoutStackTest`, "a tab dragged onto a lone slot lands AFTER it". The left pane is
      # a lone slot again, which is the part that matters: it emptied and collapsed.
      assert stacks(html) == [
               %{active: "editor", tabs: [{"editor", "active"}]},
               %{active: "preview", tabs: [{"preview", "active"}]},
               %{active: "notes", tabs: [{"terminal", "inactive"}, {"notes", "active"}]}
             ]
    end
  end

  # ---------------------------------------------------------------------------
  # Compositions
  # ---------------------------------------------------------------------------

  describe "compositions hold separate arrangements" do
    test "switching away and back keeps the arrangement that was built", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      arranged = drop_on_centre(view, "editor", "notes") |> stacks()

      minimal =
        view
        |> element(~s(button[phx-value-composition="minimal"]))
        |> render_click()

      assert stacks(minimal) == [%{active: "editor", tabs: [{"editor", "active"}]}],
             ":minimal is its own tree — the :default arrangement must not leak into it"

      back =
        view
        |> element(~s(button[phx-value-composition="default"]))
        |> render_click()

      assert stacks(back) == arranged
    end

    test "switching composition drops the shell's focused slot", %{conn: conn} do
      # Pinned because it is observable, not because it is desirable: the keyboard hook reads
      # `data-active-slot`, so until the user clicks a pane, ctrl+tab and alt+arrow do nothing in
      # the composition they just switched to.
      {:ok, view, _html} = live(conn, "/")
      assert shell_focus(render(view)) == "editor"

      html = view |> element(~s(button[phx-value-composition="minimal"])) |> render_click()

      assert shell_focus(html) == nil
    end
  end

  # ---------------------------------------------------------------------------
  # The property under all of it
  # ---------------------------------------------------------------------------

  describe "one slot, one place" do
    test "a long sequence of drags never renders a tab id twice", %{conn: conn} do
      # LiveView patches by DOM id, so a duplicated tab id does not look like a duplicate — it
      # looks like a tab that stops responding. Every interaction that adds a slot has to vacate
      # where it was, and this asserts the whole sequence, since a single operation cannot show it.
      {:ok, view, _html} = live(conn, "/")

      drop_on_centre(view, "editor", "notes")
      drop_on_centre(view, "editor", "debugger")
      drop_on_tab(view, "notes", "debugger")
      drop_on_edge(view, "preview", "notes", "right")
      drop_on_centre(view, "terminal", "settings")
      drop_on_tab(view, "editor", "settings")
      html = drop_on_edge(view, "terminal", "editor", "up")

      ids = tab_ids(html)
      assert ids == Enum.uniq(ids)
      assert Enum.sort(ids) == ["debugger", "editor", "notes", "preview", "settings", "terminal"]
      assert Process.alive?(view.pid)
    end
  end
end
