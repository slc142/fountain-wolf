import bpy
from mathutils import Vector

# Adjustable parameters
OPENING_SIZE = 0.4 # Size of the openings (0.0 to 1.0, where 1.0 would remove the entire face)
PIECE_SIZE = 1.0    # Base size of each piece
PIECE_HEIGHT = 0.5  # Half the height as specified

def clear_scene():
    """Clear all objects in the current scene"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def create_base_cube():
    """Create the base cube with half height"""
    bpy.ops.mesh.primitive_cube_add(size=PIECE_SIZE)
    cube = bpy.context.active_object
    cube.scale.z = PIECE_HEIGHT / PIECE_SIZE
    return cube

def create_opening(obj, face_normal, opening_size=OPENING_SIZE, extra_depth=0):
    """Create a rectangular opening on the specified face using boolean modifier"""
    # Calculate opening dimensions - centered opening with walls on both sides
    opening_width = PIECE_SIZE * opening_size
    floor_thickness = 0.1
    
    # Create a cut cube that extends from bottom to top of the piece
    # Add extra_depth parameter for aesthetic purposes
    cut_depth = PIECE_SIZE + extra_depth
    
    # Determine cut position based on face normal
    if abs(face_normal.x) > 0.5:  # Left or right face
        # Center the opening vertically and horizontally
        cut_location = obj.location + face_normal * (PIECE_SIZE / 2)
        cut_location.z = obj.location.z + floor_thickness
        # Scale: depth (into piece), width (opening width), height (full piece height)
        cut_scale_x = cut_depth
        cut_scale_y = opening_width
        cut_scale_z = PIECE_HEIGHT - floor_thickness
    elif abs(face_normal.y) > 0.5:  # Front or back face
        cut_location = obj.location + face_normal * (PIECE_SIZE / 2)
        cut_location.z = obj.location.z + floor_thickness
        cut_scale_x = opening_width
        cut_scale_y = cut_depth
        cut_scale_z = PIECE_HEIGHT - floor_thickness
    else:  # Top or bottom face (not used for this game)
        cut_location = obj.location + face_normal * (PIECE_HEIGHT / 2)
        cut_scale_x = opening_width
        cut_scale_y = opening_width
        cut_scale_z = cut_depth
    
    # Create a small cube for the cut
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    cut_cube = bpy.context.active_object
    cut_cube.name = "Cut_Cube_Temp"
    
    # Scale and position the cut cube
    cut_cube.scale.x = cut_scale_x
    cut_cube.scale.y = cut_scale_y
    cut_cube.scale.z = cut_scale_z
    cut_cube.location = cut_location
    
    # Select both objects
    obj.select_set(True)
    cut_cube.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Apply boolean modifier to cut the opening
    bpy.ops.object.modifier_add(type='BOOLEAN')
    obj.modifiers[-1].operation = 'DIFFERENCE'
    obj.modifiers[-1].object = cut_cube
    bpy.ops.object.modifier_apply(modifier="Boolean")
    
    # Delete the temporary cut cube
    cut_cube.select_set(True)
    obj.select_set(False)
    bpy.context.view_layer.objects.active = cut_cube
    bpy.ops.object.delete()
    
    # Re-select the main object
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

def create_straight_piece():
    """Create a straight piece with openings on opposite sides"""
    piece = create_base_cube()
    piece.name = "Straight_Piece"
    
    # Create openings on front and back faces
    create_opening(piece, Vector((0, 1, 0)))  # Front
    create_opening(piece, Vector((0, -1, 0)))  # Back
    
    return piece

def create_turn_piece():
    """Create a turn piece with openings on adjacent sides (90-degree turn)"""
    piece = create_base_cube()
    piece.name = "Turn_Piece"
    
    # Create openings on front and right faces (L-shaped turn)
    create_opening(piece, Vector((0, 1, 0)), extra_depth=OPENING_SIZE)   # Front
    create_opening(piece, Vector((1, 0, 0)), extra_depth=OPENING_SIZE)   # Right
    
    return piece

def create_t_piece():
    """Create a T-piece with openings on three sides"""
    piece = create_base_cube()
    piece.name = "T_Piece"
    
    # Create openings on front, back, and right faces
    create_opening(piece, Vector((0, 1, 0)))   # Front
    create_opening(piece, Vector((0, -1, 0)))  # Back
    create_opening(piece, Vector((1, 0, 0)))   # Right
    
    return piece

def create_cross_piece():
    """Create a cross-piece with openings on all four sides"""
    piece = create_base_cube()
    piece.name = "Cross_Piece"
    
    # Create openings on all four vertical faces
    create_opening(piece, Vector((0, 1, 0)))   # Front
    create_opening(piece, Vector((0, -1, 0)))  # Back
    create_opening(piece, Vector((1, 0, 0)))   # Right
    create_opening(piece, Vector((-1, 0, 0)))  # Left
    
    return piece

def create_one_exit_piece():
    """Create a one-exit piece with single opening"""
    piece = create_base_cube()
    piece.name = "One_Exit_Piece"
    
    # Create opening on front face with extra depth for aesthetics
    create_opening(piece, Vector((0, 1, 0)), extra_depth=0.2)   # Front
    
    return piece

def create_block():
    """Create a solid block with no openings"""
    piece = create_base_cube()
    piece.name = "Block"
    # No openings - solid piece
    
    return piece

def arrange_pieces_in_grid():
    """Arrange all pieces in a grid for easy viewing"""
    pieces = bpy.context.scene.objects
    grid_size = 3
    spacing = PIECE_SIZE * 1.5
    
    for i, piece in enumerate(pieces):
        row = i // grid_size
        col = i % grid_size
        piece.location.x = col * spacing - (grid_size - 1) * spacing / 2
        piece.location.y = row * spacing - (len(pieces) // grid_size - 1) * spacing / 2

def create_all_pieces():
    """Create all game pieces"""
    
    # Create all piece types
    pieces = [
        create_straight_piece(),
        create_turn_piece(),
        create_t_piece(),
        create_cross_piece(),
        create_one_exit_piece(),
        create_block()
    ]
    
    # Arrange pieces in a grid
    arrange_pieces_in_grid()
    
    # Deselect all objects
    bpy.ops.object.select_all(action='DESELECT')
    
    print(f"Created {len(pieces)} game pieces with opening size: {OPENING_SIZE}")
    print("Pieces created:")
    for piece in pieces:
        print(f"  - {piece.name}")

# Main execution
if __name__ == "__main__":
    create_all_pieces()
