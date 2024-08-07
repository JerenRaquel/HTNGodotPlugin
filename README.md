# HTN Godot Plugin - Work in Progress

This is a plugin designed to work in the Godot Engine. It facilitates an easy to use visual node based graph editor to setup complex AI interactions for your game development needs.

The plugin can be seen as two parts:

- The plugin that is accessible once enabled at the top of the editor alongside the standard 2D, 3D, Script, and AssetLib buttons.
- The [Hierarchical Task Network](https://en.wikipedia.org/wiki/Hierarchical_task_network) (HTN) Planner node that can be seen under `res://addons/HTNDomainManager/HTNGameLibrary/htn_planner.tscn`

For more information on how to get started with using this plugin, please refer to the wiki pages setup with this repository. <br>
(Docs are only in engine currently)

- [Installation](https://github.com/JerenRaquel/HTNGodotPlugin/wiki/Installation)
- [Getting Started](https://github.com/JerenRaquel/HTNGodotPlugin/wiki/Getting-Started)

Thank you for taking some time to look at or use this plugin!

## Notice -- Project Work in Progress Status

The branch on Master is considered "Stable".

- There is a known bug with Domain Link Node producing a recursion warning when loading a domain.
  - Doesn't affect compiling the graph; just a visual bug.
