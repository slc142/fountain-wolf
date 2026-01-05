# Known bugs

- FlowController delay is not handled properly, causing water flow split branches to not flow simultaneously for straight pieces, and some branches have water begin to flow before the water has finished falling into them.
- Pieces visually float in the air if the player drags them outside the grid borders and attempts to place them (but they don't get placed in the grid at the spot where they are visually placed).
- Drop indicator casts shadows, which is not intended.
