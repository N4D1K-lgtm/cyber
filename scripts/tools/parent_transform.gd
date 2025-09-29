@tool
extends EditorScript

func _run():
    var editor_selection = get_editor_interface().get_selection()
    var selected_nodes = editor_selection.get_selected_nodes()
    
    if selected_nodes.is_empty():
        print("No node selected")
        return
    
    var selected = selected_nodes[0]
    
    # Check if we have a MeshInstance3D selected
    if not selected is MeshInstance3D:
        print("Select a MeshInstance3D first (you selected: " + selected.get_class() + ")")
        return
    
    var mesh_node = selected
    var original_parent = mesh_node.get_parent()
    
    # Store the mesh's current global transform
    var global_trans = mesh_node.global_transform
    
    # Create new parent Node3D with the same name + "_Group"
    var new_parent = Node3D.new()
    new_parent.name = mesh_node.name + "_Group"
    
    # Add the new parent to the original parent at the mesh's position
    original_parent.add_child(new_parent)
    new_parent.owner = mesh_node.owner  # Important for saving
    new_parent.global_transform = global_trans
    
    # Reparent the mesh under the new parent
    mesh_node.get_parent().remove_child(mesh_node)
    new_parent.add_child(mesh_node)
    mesh_node.owner = new_parent.owner
    
    # Reset the mesh's local transform since parent is at the same position
    mesh_node.transform = Transform3D.IDENTITY
    
    print("Created parent: " + new_parent.name)
    print("You can now drag other meshes under this parent")
