/**
 * Chassis Tab Hook
 *
 * Handles tab interactions: dragging tabs between stacks,
 * clicking to focus, and close button.
 * Spatial events only — no content awareness (INV-1.1c).
 */
const ChassisTab = {
    mounted() {
        const el = this.el;
        const slotId = el.dataset.slotId;

        // Click to focus
        el.addEventListener("click", (e) => {
            if (e.target.closest(".chassis-tab-close")) return;
            this.pushEvent("chassis:focus_slot", { slot_id: slotId });
        });

        el.addEventListener("dragstart", (e) => {
            e.dataTransfer.effectAllowed = "move";
            e.dataTransfer.setData("text/plain", slotId);
            el.classList.add("dragging");
            document.body.classList.add("chassis-dragging");
        });

        el.addEventListener("dragend", () => {
            el.classList.remove("dragging");
            document.body.classList.remove("chassis-dragging");
        });

        // Drop target (tab reordering)
        el.addEventListener("dragenter", (e) => {
            e.preventDefault();
            el.classList.add("drag-over");
        });

        el.addEventListener("dragover", (e) => {
            e.preventDefault();
            e.dataTransfer.dropEffect = "move";
            el.classList.add("drag-over");
        });

        el.addEventListener("dragleave", () => {
            el.classList.remove("drag-over");
        });

        el.addEventListener("drop", (e) => {
            e.preventDefault();
            el.classList.remove("drag-over");
            const draggedId = e.dataTransfer.getData("text/plain");
            if (draggedId && draggedId !== slotId) {
                this.pushEvent("chassis:reorder_slot", {
                    target_id: slotId,
                    dragged_id: draggedId,
                });
            }
        });
    },
};

/**
 * Chassis DragDrop Hook
 *
 * Handles dock zone interactions: drag-over highlights and
 * drop events for splitting/attaching slots.
 * Spatial events only — no content awareness (INV-1.1c).
 */
const ChassisDragDrop = {
    mounted() {
        const el = this.el;
        const dropType = el.dataset.dropType;
        const direction = el.dataset.direction;
        const slotId = el.dataset.slotId;

        el.addEventListener("dragenter", (e) => {
            e.preventDefault();
            el.classList.add("active");
        });

        el.addEventListener("dragover", (e) => {
            e.preventDefault();
            e.dataTransfer.dropEffect = "move";
            el.classList.add("active");
        });

        el.addEventListener("dragleave", () => {
            el.classList.remove("active");
        });

        el.addEventListener("drop", (e) => {
            e.preventDefault();
            el.classList.remove("active");
            const draggedId = e.dataTransfer.getData("text/plain");
            if (!draggedId) return;
            if (draggedId === slotId && dropType === "dock-zone") return;

            if (dropType === "dock-zone") {
                // Center drop — add to stack
                this.pushEvent("chassis:dock_slot", {
                    target_id: slotId,
                    dragged_id: draggedId,
                });
            } else if (dropType === "split-zone") {
                // Edge drop — split
                this.pushEvent("chassis:split_slot", {
                    target_id: slotId,
                    dragged_id: draggedId,
                    direction: direction,
                });
            }
        });
    },
};

/**
 * Chassis Sidebar Item Hook
 *
 * Makes sidebar items draggable as slot sources.
 * Spatial events only — no content awareness (INV-1.1c).
 */
const ChassisSidebarItem = {
    mounted() {
        const el = this.el;
        el.draggable = true;

        el.addEventListener("dragstart", (e) => {
            const slotId = el.dataset.slotId;
            e.dataTransfer.effectAllowed = "move";
            e.dataTransfer.setData("text/plain", slotId);
            el.classList.add("dragging");
            document.body.classList.add("chassis-dragging");
        });

        el.addEventListener("dragend", () => {
            el.classList.remove("dragging");
            document.body.classList.remove("chassis-dragging");
        });
    },
};

/**
 * Chassis Resize Hook
 *
 * Drag a divider to redistribute space between the two children it sits between.
 * Spatial events only — no content awareness (INV-1.1c).
 *
 * Pointer events with `setPointerCapture`, not mouse events: a mouse-only binding ignores pen and
 * touch entirely, and loses the drag the moment the pointer leaves the window. Because the pointer
 * is captured, every move and release is retargeted to the divider even over an iframe or outside
 * the viewport, so the listeners live on the element rather than on the document.
 *
 * `pointercancel` is not optional — without it, a gesture the browser takes over (a scroll, a
 * back-swipe) leaves the listeners attached and the body's cursor overridden.
 *
 * The drag is optimistic: the children follow the pointer with no round trip, and the event is
 * pushed once on release. The server re-renders the committed weights into the same wrappers, which
 * is why they are server-rendered at all — a patch synchronises attributes, and an inline style the
 * server never declared is removed.
 *
 * MIN_CHILD_PX is the floor here; the server clamps the ratio independently, because a client is not
 * the authority on that bound.
 */
const MIN_CHILD_PX = 60;

const ChassisResize = {
    mounted() {
        this.el.addEventListener("pointerdown", this.onPointerDown.bind(this));
    },

    onPointerDown(e) {
        // Left button only: a right-click on a divider is a context menu, not a drag.
        if (e.button !== 0) return;

        const el = this.el;
        const prevEl = el.previousElementSibling;
        const nextEl = el.nextElementSibling;
        if (!prevEl || !nextEl) return;

        // The divider names both of its sides, so the committed event carries the pair and the
        // server never has to infer which children it sat between from DOM position.
        const slotId = el.dataset.slotId;
        const nextSlotId = el.dataset.nextSlotId;
        if (!slotId || !nextSlotId) return;

        e.preventDefault();
        el.setPointerCapture?.(e.pointerId);

        const horizontal = el.dataset.direction === "horizontal";
        const startPos = horizontal ? e.clientX : e.clientY;

        const prevRect = prevEl.getBoundingClientRect();
        const nextRect = nextEl.getBoundingClientRect();
        const prevSize = horizontal ? prevRect.width : prevRect.height;
        const total = prevSize + (horizontal ? nextRect.width : nextRect.height);

        // Degenerate container (both children collapsed, or measured before layout): a ratio from
        // this would be meaningless, and dividing by it would be worse.
        if (total < MIN_CHILD_PX * 2) return;

        // The pair's combined weight is preserved, so the drag redistributes within the pair and
        // leaves every other child of the division alone. Read from the rendered style, defaulting
        // to the even share the Shell renders when no weight is stored.
        const combined = (parseFloat(prevEl.style.flex) || 1) + (parseFloat(nextEl.style.flex) || 1);

        document.body.style.cursor = horizontal ? "col-resize" : "row-resize";
        document.body.style.userSelect = "none";
        el.classList.add("dragging");

        const ratioAt = (pos) => {
            const delta = pos - startPos;
            const newPrev = Math.min(Math.max(MIN_CHILD_PX, prevSize + delta), total - MIN_CHILD_PX);
            return newPrev / total;
        };

        const onMove = (ev) => {
            const ratio = ratioAt(horizontal ? ev.clientX : ev.clientY);
            prevEl.style.flex = `${combined * ratio}`;
            nextEl.style.flex = `${combined * (1 - ratio)}`;
        };

        const onUp = (ev) => {
            el.removeEventListener("pointermove", onMove);
            el.removeEventListener("pointerup", onUp);
            el.removeEventListener("pointercancel", onUp);
            document.body.style.cursor = "";
            document.body.style.userSelect = "";
            el.classList.remove("dragging");

            this.pushEvent("chassis:resize_division", {
                slot_id: slotId,
                next_slot_id: nextSlotId,
                ratio: ratioAt(horizontal ? ev.clientX : ev.clientY),
            });
        };

        el.addEventListener("pointermove", onMove);
        el.addEventListener("pointerup", onUp);
        el.addEventListener("pointercancel", onUp);
    },

    destroyed() {
        // A divider can be patched away mid-drag (the arrangement changed under it), and the body
        // must not be left with a resize cursor and text selection disabled.
        document.body.style.cursor = "";
        document.body.style.userSelect = "";
    },
};

/**
 * Chassis Keyboard Hook
 *
 * Handles keyboard navigation for the layout shell.
 * Spatial events only — no content awareness (INV-1.1c).
 * Server resolves adjacency — hook has zero tree knowledge.
 */
const ChassisKeyboard = {
    mounted() {
        // Track visual focus via clicks
        this.el.addEventListener("mousedown", (e) => {
            const stack = e.target.closest(".chassis-stack");
            if (stack) {
                const clickedSlotId = stack.dataset.activeId;
                const currentActiveSlot = this.el.dataset.activeSlot;
                
                // If they clicked a pane that isn't active, focus it
                if (clickedSlotId && clickedSlotId !== currentActiveSlot) {
                    this.pushEvent("chassis:focus_slot", { slot_id: clickedSlotId });
                }
            }
        });

        this.handleKeyDown = (e) => {
            const activeSlot = this.el.dataset.activeSlot;
            if (!activeSlot) return;

            if (e.ctrlKey && e.key === "w") {
                e.preventDefault();
                this.pushEvent("chassis:close_slot", { "slot-id": activeSlot });
            } else if (e.ctrlKey && e.shiftKey && e.key === "Tab") {
                e.preventDefault();
                this.pushEvent("chassis:focus_prev", { slot_id: activeSlot });
            } else if (e.ctrlKey && e.key === "Tab") {
                e.preventDefault();
                this.pushEvent("chassis:focus_next", { slot_id: activeSlot });
            } else if (e.altKey && ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(e.key)) {
                e.preventDefault();
                const dirMap = {
                    ArrowLeft: "left",
                    ArrowRight: "right",
                    ArrowUp: "up",
                    ArrowDown: "down",
                };
                this.pushEvent("chassis:focus_direction", {
                    slot_id: activeSlot,
                    direction: dirMap[e.key],
                });
            }
        };

        document.addEventListener("keydown", this.handleKeyDown);
    },

    destroyed() {
        document.removeEventListener("keydown", this.handleKeyDown);
    },
};

export { ChassisTab, ChassisDragDrop, ChassisSidebarItem, ChassisResize, ChassisKeyboard };
