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
 * Handles divider drag-to-resize between division children.
 * Spatial events only — no content awareness (INV-1.1c).
 */
const ChassisResize = {
    mounted() {
        const el = this.el;
        const slotId = el.dataset.slotId;
        // The divider names both of its sides, so the committed event carries the pair and the
        // server never has to infer which children it sat between from DOM position.
        const nextSlotId = el.dataset.nextSlotId;
        const direction = el.dataset.direction;
        let startPos = null;
        let startSizes = null;
        let prevEl = null;
        let nextEl = null;

        el.addEventListener("mousedown", (e) => {
            e.preventDefault();
            prevEl = el.previousElementSibling;
            nextEl = el.nextElementSibling;
            if (!prevEl || !nextEl) return;

            const isHorizontal = direction === "horizontal";
            startPos = isHorizontal ? e.clientX : e.clientY;
            const prevRect = prevEl.getBoundingClientRect();
            const nextRect = nextEl.getBoundingClientRect();
            startSizes = {
                prev: isHorizontal ? prevRect.width : prevRect.height,
                next: isHorizontal ? nextRect.width : nextRect.height,
            };

            document.body.style.cursor = isHorizontal ? "col-resize" : "row-resize";
            document.body.style.userSelect = "none";

            const onMouseMove = (e) => {
                if (!startSizes) return;
                const currentPos = isHorizontal ? e.clientX : e.clientY;
                const delta = currentPos - startPos;
                const total = startSizes.prev + startSizes.next;
                const newPrev = Math.max(50, startSizes.prev + delta);
                const newNext = Math.max(50, total - newPrev);
                const ratio = newPrev / (newPrev + newNext);

                prevEl.style.flex = `${ratio}`;
                nextEl.style.flex = `${1 - ratio}`;
            };

            const onMouseUp = (e) => {
                document.removeEventListener("mousemove", onMouseMove);
                document.removeEventListener("mouseup", onMouseUp);
                document.body.style.cursor = "";
                document.body.style.userSelect = "";

                if (startSizes) {
                    const currentPos = isHorizontal ? e.clientX : e.clientY;
                    const delta = currentPos - startPos;
                    const total = startSizes.prev + startSizes.next;
                    const newPrev = Math.max(50, startSizes.prev + delta);
                    const newNext = Math.max(50, total - newPrev);
                    const ratio = newPrev / (newPrev + newNext);

                    this.pushEvent("chassis:resize_division", {
                        slot_id: slotId,
                        next_slot_id: nextSlotId,
                        ratio: ratio,
                    });
                }

                startPos = null;
                startSizes = null;
            };

            document.addEventListener("mousemove", onMouseMove);
            document.addEventListener("mouseup", onMouseUp);
        });
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
