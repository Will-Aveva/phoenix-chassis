/**
 * Chassis Hooks — registration index
 *
 * Import and register all Chassis hooks for use with Phoenix LiveView.
 *
 * Usage in consuming application:
 *   import { ChassisHooks } from "./hooks/chassis_hooks_index";
 *   let liveSocket = new LiveSocket("/live", Socket, {
 *     hooks: { ...ChassisHooks, ...YourAppHooks }
 *   });
 */
import { ChassisTab, ChassisDragDrop, ChassisSidebarItem, ChassisResize, ChassisKeyboard } from "./chassis_hooks";

const ChassisHooks = {
    ChassisTab,
    ChassisDragDrop,
    ChassisSidebarItem,
    ChassisResize,
    ChassisKeyboard,
};

export { ChassisHooks, ChassisTab, ChassisDragDrop, ChassisSidebarItem, ChassisResize, ChassisKeyboard };
export default ChassisHooks;
