defmodule ChassisWeb.DemoLiveTest do
  use ChassisWeb.ConnCase
  import Phoenix.LiveViewTest

  # ---------------------------------------------------------------------------
  # LiveView lifecycle
  # ---------------------------------------------------------------------------

  describe "LiveView lifecycle" do
    test "mount succeeds at /", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "chassis-shell"
    end

    test "initial tree renders 3 slots", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "editor"
      assert html =~ "preview"
      assert html =~ "terminal"
    end

    test "shell structure present", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "chassis-division"
      assert html =~ "chassis-stack"
    end

    test "provider tab labels render", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Editor"
      assert html =~ "Preview"
      assert html =~ "Terminal"
    end

    test "provider content areas render", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "chassis-slot-content"
    end
  end

  # ---------------------------------------------------------------------------
  # Handle event integration
  # ---------------------------------------------------------------------------

  describe "handle_event integration" do
    test "chassis:close_slot removes slot from DOM", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Close the editor slot via the close button
      html =
        view
        |> element("#chassis-tab-editor .chassis-tab-close")
        |> render_click()

      refute html =~ "chassis-tab-editor"
    end

    test "chassis:focus_slot switches active tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html = render_hook(view, "chassis:focus_slot", %{"slot_id" => "editor"})
      assert html =~ "chassis-tab active"
    end

    test "chassis:focus_slot syncs data-active-slot attribute", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html = render_hook(view, "chassis:focus_slot", %{"slot_id" => "preview"})
      assert html =~ "data-active-slot=\"preview\""
    end

    test "close all slots renders empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Close all 3 slots
      render_hook(view, "chassis:close_slot", %{"slot-id" => "editor"})
      render_hook(view, "chassis:close_slot", %{"slot-id" => "preview"})
      html = render_hook(view, "chassis:close_slot", %{"slot-id" => "terminal"})

      assert html =~ "chassis-empty"
    end

    test "chassis:dock_slot merges slots into stack", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        render_hook(view, "chassis:dock_slot", %{
          "target_id" => "editor",
          "dragged_id" => "preview"
        })

      # After docking, editor and preview share a stack — both should appear as tabs
      assert html =~ "chassis-tab-editor"
      assert html =~ "chassis-tab-preview"
    end

    test "chassis:split_slot creates new division", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        render_hook(view, "chassis:split_slot", %{
          "target_id" => "editor",
          "dragged_id" => "preview",
          "direction" => "right"
        })

      # Both slots should still be present after split
      assert html =~ "editor"
      assert html =~ "preview"
      assert html =~ "chassis-division"
    end

    test "chassis:reorder_slot reorders within stack", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # First dock preview onto editor to create a multi-tab stack
      render_hook(view, "chassis:dock_slot", %{
        "target_id" => "editor",
        "dragged_id" => "preview"
      })

      # Now reorder within the stack
      html =
        render_hook(view, "chassis:reorder_slot", %{
          "target_id" => "editor",
          "dragged_id" => "preview"
        })

      # Both tabs should still exist
      assert html =~ "chassis-tab-editor"
      assert html =~ "chassis-tab-preview"
    end
  end

  # ---------------------------------------------------------------------------
  # Integration contract verification
  # ---------------------------------------------------------------------------

  describe "integration contract verification" do
    test "re-render determinism: same view produces same DOM (INV-3.1)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      html1 = render(view)
      html2 = render(view)
      assert html1 == html2
    end
  end

  # ---------------------------------------------------------------------------
  # Resize integration
  # ---------------------------------------------------------------------------

  describe "resize integration" do
    test "chassis:resize_division updates flex weights", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        render_hook(view, "chassis:resize_division", %{
          "slot_id" => "editor",
          "ratio" => 0.7
        })

      # The editor's container should now have flex: 0.7
      assert html =~ "flex: 0.7"
    end
  end

  # ---------------------------------------------------------------------------
  # Keyboard navigation integration
  # ---------------------------------------------------------------------------

  describe "keyboard navigation integration" do
    test "focus_next cycles tabs in a multi-tab stack", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Dock preview onto editor to create a 2-tab stack
      render_hook(view, "chassis:dock_slot", %{
        "target_id" => "editor",
        "dragged_id" => "preview"
      })

      # Focus next from editor → should go to preview
      html =
        render_hook(view, "chassis:focus_next", %{
          "slot_id" => "editor"
        })

      # After focus_next, the active slot should change
      assert html =~ "data-active-slot=\"preview\""
    end

    test "focus_prev cycles tabs backward", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Dock preview onto editor
      render_hook(view, "chassis:dock_slot", %{
        "target_id" => "editor",
        "dragged_id" => "preview"
      })

      # Focus prev from editor → should wrap to preview
      html =
        render_hook(view, "chassis:focus_prev", %{
          "slot_id" => "editor"
        })

      assert html =~ "data-active-slot=\"preview\""
    end

    test "focus_direction navigates between divisions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # The default layout has editor | (preview / terminal)
      # Moving right from editor should reach preview
      html =
        render_hook(view, "chassis:focus_direction", %{
          "slot_id" => "editor",
          "direction" => "right"
        })

      assert html =~ "data-active-slot=\"preview\""
    end

    test "close via keyboard event removes slot", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        render_hook(view, "chassis:close_slot", %{
          "slot-id" => "editor"
        })

      refute html =~ "chassis-tab-editor"
    end
  end
end
