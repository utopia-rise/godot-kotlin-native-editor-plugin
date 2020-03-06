# godot-kotlin-editor-plugin

This plugin for the Godot editor assists in setting up a new Godot/Kotlin project inside of an existing Godot project.

Add this plugin to your project from the Asset Library, or by downloading it from here. Only the `addons/` directory is required.

Ensure it is enabled inside of Godot: `Project -> Project Settings` then go to the `Plugins` tab, and make sure the status of `Godot Kotlin` is set to `Active`.

Then go to `Tools -> Kotlin Tools`. Once the window launches, click `Add Kotlin Support`. This make take some time as it will download all of the required project files and build tools, and it will run an initial build.

Once it's complete, further builds can be triggered from the `Build Kotlin` button at the top right.

Further configuration of the build can be done in the tools dialog: `Tools -> Kotlin Tools`

It's recomended to select the platform you are developing on as this will reduce build times.

The Kotlin source files are in: `kotlin/src/main/kotlin/...`

And the produced `.gdns` for each class are in `scripts/`

The GDNative library file is `<root>/kotlin.gdnlib`