# FountainWolf

This is a game and level editor inspired by the game *Flow Water Fountain 3D Puzzle*, created in Godot 4.5.1.

The goal of the game is to create a path of flowing water from the start point to the finish point by arranging pieces. The puzzle area is a 3D grid where each space can hold only one piece at a time (but pieces may be stacked on top of each other). The player moves pieces by dragging them. Pieces can be moved but not rotated.

## TODO

- [ ] Game logic
    - [x] Basic flow logic
    - [ ] Flow logic with covered pieces
    - [ ] Level win condition
    - [x] Non-movable pieces
    - [x] Piece stacking
    - [ ] Multiple color flows
    - [ ] Partial flow recalculation (immediately after pick up piece and after placement)
- [ ] Piece types:
    - [ ] Water source
    - [ ] Goal
    - [x] Block
    - [x] One-exit piece
    - [x] T-piece
    - [x] Cross-piece
    - [ ] Covered pieces
- [ ] Graphics
    - [ ] Camera rotation
    - [ ] Smooth piece dragging
    - [ ] Target grid space indicator while dragging
    - [ ] Better water
    - [ ] Non-movable pieces are dulled in color
    - [ ] Better lighting
    - [ ] Piece materials
- [ ] Sound
    - [ ] Water flow sound
    - [ ] Win sound
    - [ ] Music
- [ ] Game UI
    - [ ] Level selection
    - [ ] Win screen
    - [ ] Main menu
- [ ] Level editor
    - [ ] Piece type selector
    - [ ] Add piece
    - [ ] Remove piece
    - [ ] Move piece
    - [ ] Rotate piece
    - [ ] Box select, copy/paste/delete/move selection
    - [ ] Edit level size (must be square)
    - [ ] Test level
    - [ ] Save level
    - [ ] Load level
    - [ ] Share/upload level