# godot-kotlin-editor-plugin

This plugin for the Godot editor assists in setting up a new Godot/Kotlin project inside of an existing Godot project.

## How to setup
1. Add this plugin to your project from the **Godot Asset Library**, or by downloading it from here. Only the `addons/` directory is required.

2. Ensure it is enabled inside of Godot: `Project -> Project Settings` then go to the `Plugins` tab, and make sure the status of `Godot Kotlin` is set to `Active`.

3. Then go to `Tools -> Kotlin Tools`. Once the window launches, click `Add Kotlin Support`. This may take some time as it will download all of the required project files and build tools, and it will run an initial build.

Once it's complete, further builds can be triggered from the `Build Kotlin` button at the top right.


## Build configuration
Further configuration of the build can be done in the tools dialog: `Tools -> Kotlin Tools`

It's recomended to select the platform you are developing on as this will reduce build times.

## Build Output
The Kotlin source files are located in: `<root>/kotlin/src/main/kotlin/...`

And the produced `.gdns` for each class are in `<root>/scripts/`. These are the files you will select as your script for Nodes in the Godot Editor.

The GDNative library file is located here: `<root>/kotlin.gdnlib`