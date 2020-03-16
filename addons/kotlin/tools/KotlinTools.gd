######################################
# KotlinTools.gd
# The main tools window, accessible from:
# Project -> Tools
# Provides new project setup and common gradle actions
######################################

tool
extends WindowDialog

const KOTLIN_ZIP := "kotlin_template.zip"
const LOCAL_KOTLIN_ZIP := "res://%s" % KOTLIN_ZIP
const GITHUB_USER := "utopia-rise"
const API_URL := "https://api.github.com/repos/%s/godot-kotlin-project-template/releases/latest" % [GITHUB_USER]
# List of files in the Project Template repo that we don't actually want in everyone's for-real projects
const FILE_BLACK_LIST := ["README.md", "LICENSE"]

onready var buildDialogScene := preload("res://addons/kotlin/build_dialog/BuildDialog.tscn")
onready var setupDialogScene := preload("res://addons/kotlin/tools/SetupDialog.tscn")
onready var setupDialog: SetupDialog = setupDialogScene.instance()

onready var GradleProperties := load("res://addons/kotlin/tools/GradleProperties.gd")

export(NodePath) var buildTypeSelectorPath: NodePath
onready var buildTypeSelector: OptionButton = get_node(buildTypeSelectorPath)

export(NodePath) var platformSelectorPath: NodePath
onready var platformSelector: OptionButton = get_node(platformSelectorPath)

export(NodePath) var armArchSelectorPath: NodePath
onready var armArchSelector: OptionButton = get_node(armArchSelectorPath)

export(NodePath) var iosIdentityLineEditPath: NodePath
onready var iosIdentityLineEdit: LineEdit = get_node(iosIdentityLineEditPath)


var unzipThread = null


func _on_AddSupportButton_pressed():
	step_1_create_structure()


func step_1_create_structure():
	setupDialog.set_step_text("Step 1/4:\nCreating structure")
	add_child(setupDialog)
	setupDialog.show()
	
	print("Step 3: Create project structure")
	var zipFile := File.new()
	if zipFile.file_exists(LOCAL_KOTLIN_ZIP):
		print("Template already downloaded")
		unzip(LOCAL_KOTLIN_ZIP)
	else:
		print("Downloading template")
		find_download_url()


func find_download_url():
	setupDialog.set_step_text("Step 1/4:\nFinding template")
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	print("Start API request")
	http_request.connect("request_completed", self, "api_request_complete")
	var error = http_request.request(API_URL)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		setup_failed()


func api_request_complete(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print("API request complete")
	var parsed = JSON.parse(body.get_string_from_utf8())
	var json = parsed.result
	
	if json.has("zipball_url"):
		var zipballUrl = json["zipball_url"]
		
		if response_code == 200:
			download_template(zipballUrl)
		else:
			push_error("Failed to get download URL")
			setup_failed()
	else:
		push_error("Failed to get download URL")
		setup_failed()


func download_template(url):
	setupDialog.set_step_text("Step 1/4:\nDownloading template")
	
	print("Starting Download...")
	print(url)
	# Create an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_completed")
	
	# Perform the HTTP request. The URL below returns some JSON as of writing.
	var error = http_request.request(url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func _http_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	if response_code == 200:
		print("Download complete.")
		
		var zipFile := File.new()
		zipFile.open(LOCAL_KOTLIN_ZIP, File.WRITE)
		zipFile.store_buffer(body)
		zipFile.close()
		
		unzip(LOCAL_KOTLIN_ZIP)
	else:
		print("Failed to download zip")
		setup_failed()


func unzip(filePath: String):
	setupDialog.set_step_text("Step 1/4:\nUnzipping template")
	
	unzipThread = Thread.new()
	unzipThread.start(self, "background_unzip", filePath)


func background_unzip(filePath: String):
	var dir := Directory.new()
	dir.open("res://")
	
	var rootKotlinDir := 'kotlin/'
	dir.make_dir(rootKotlinDir)
	
	var gdunzip = load('res://addons/kotlin/gdunzip/gdunzip.gd').new()
	var loaded = gdunzip.load(filePath)
	if loaded:
		for f in gdunzip.files.values():
			var file = File.new()
			var fileName = get_file_name(f.file_name)
			
			# Skip empty file names, and files on the black list
			if fileName.length() > 0 and  is_not_black_listed(fileName):
			
				# Skip directories, and files included in the black list
				if f.file_name.find("/") > -1:
					var pathParts = f.file_name.split("/", false)
					pathParts.remove(pathParts.size()-1) # Remove the file
					var justDirectories := rootKotlinDir
					# Github source downloads contain a parent dir with a changing name
					# we want to skip that as we'll just use a constant dir name to
					# contain everything
					var firstSkipped := false
					# Ensure all of the directories in the structure exist
					for part in pathParts:
						if firstSkipped:
							justDirectories += "%s/" % part
							print("Making directory: %s" % justDirectories)
							dir.make_dir_recursive(justDirectories)
						else:
							firstSkipped = true
				
				# Github source downloads have a root directory that we don't care about
				# So just remove it here
				var path := remove_root_dir(f.file_name)
				file.open("%s%s" % [rootKotlinDir, path], File.WRITE)
				
				# Finally actually decompress and write the file
				print("Extracting file: %s" % fileName)
				var uncompressed = gdunzip.uncompress(f.file_name)
				file.store_buffer(uncompressed)
				file.close()
	
	call_deferred("step_2_cleanup")


func is_not_black_listed(fileName: String) -> bool:
	var isOnBlackList := true
	for name in FILE_BLACK_LIST:
		if name == fileName:
			isOnBlackList = false
			break
	
	return isOnBlackList


func get_file_name(path: String) -> String:
	var lastSegment := path.find_last("/")
	if lastSegment == -1:
		return path.strip_edges()
	else:
		var x = path.substr(lastSegment+1).strip_edges()
		return x


# Removes the first directory from the path
func remove_root_dir(path: String) -> String:
	var firstPathBreak := path.find("/")
	if firstPathBreak == -1:
		return path
	else:
		return path.substr(firstPathBreak+1, path.length())


func step_2_cleanup():
	setupDialog.set_step_text("Step 2/4:\nCleaning up")
	print("Step 2: Clean up")
	
	# Dispose of the thread
	unzipThread.wait_to_finish()
	unzipThread = null
	
	# Clean up the zip file
	var dir = Directory.new()
	dir.remove(LOCAL_KOTLIN_ZIP)
	
	step_3_configure()


func step_3_configure():
	setupDialog.set_step_text("Step 3/4:\nConfiguring")
	print("Step 3: Configure project")
	
	if not GradleUtilities.is_windows():
		print("Setting permissions...")
		var output := []
		OS.execute("/bin/chmod", ["+x", "kotlin/gradlew"], true, output)
		print(output)
		output.clear()
		OS.execute("/bin/chmod", ["+x", "kotlin/runBuild"], true, output)
		print(output)
	
	configure_gradle(true)


func step_4_create_library():
	setupDialog.set_step_text("Step 4/4:\nCreating library")
	print("Step 4: Create GDNative library")
	
	# Create the GDNlib file
	var gdnslib := GDNativeLibrary.new()
	
	gdnslib.config_file.set_value("general", "singleton", false)
	gdnslib.config_file.set_value("general", "load_once", true)
	gdnslib.config_file.set_value("general", "symbol_prefix", "godot_")
	gdnslib.config_file.set_value("general", "reloadable", true)
	
	gdnslib.config_file.set_value("entry", "OSX.64", "res://kotlin/build/bin/osx/debugShared/libkotlin.dylib")
	gdnslib.config_file.set_value("entry", "Windows.64", "res://kotlin/build/bin/windows/debugShared/kotlin.dll")
	gdnslib.config_file.set_value("entry", "X11.64", "res://kotlin/build/bin/linux/debugShared/libkotlin.so")
	
	gdnslib.config_file.set_value("dependencies", "OSX.64", [])
	gdnslib.config_file.set_value("dependencies", "Windows.64", [])
	gdnslib.config_file.set_value("dependencies", "X11.64", [])
	
	gdnslib.config_file.save("res://kotlin.gdnlib")
	
	# All done! Close it out
	setupDialog.hide()
	setup_complete()


func configure_gradle(inSetup: bool = false):
	var buildDialog := buildDialogScene.instance() as BuildDialog
	# During setup, continue on to the next step, other wise just finish
	if inSetup:
		buildDialog.connect("build_complete", self, "step_4_create_library")
	add_child(buildDialog)
	buildDialog.rect_position.y += setupDialog.rect_size.y
	buildDialog.show()
	buildDialog.start_build("config")


func setup_complete():
	setupDialog.set_step_text("All done!")
	update_contents()
	
	var completeDialog := AcceptDialog.new()
	completeDialog.window_title = "Kotlin setup"
	completeDialog.dialog_text = "Setup complete!"
	get_parent().add_child(completeDialog)
	completeDialog.popup_centered()


func setup_failed():
	setupDialog.hide()
	
	var completeDialog := AcceptDialog.new()
	completeDialog.window_title = "Kotlin setup"
	completeDialog.dialog_text = "Setup failed"
	get_parent().add_child(completeDialog)
	completeDialog.popup_centered()


func _on_ConfigGradleButton_pressed():
	configure_gradle()


func _on_BuildButton_pressed():
	var buildDialog := buildDialogScene.instance()
	add_child(buildDialog)
	buildDialog.show()
	buildDialog.start_build("build")


# Configure the tool window
func _on_KotlinToolMenuItem_about_to_show():
	update_contents()


func update_contents():
	var dir := Directory.new()
	# Kotlin is already setup, show actions
	if dir.dir_exists("res://kotlin"):
		update_ui_from_properties()
		
		$ActionsContainer.show()
		$SetupContainer.hide()
	# Not setup yet, show intro
	else:
		$ActionsContainer.hide()
		$SetupContainer.show()


func _on_BuildTypeButton_item_selected(id):
	match id:
		0:
			print("Updating Kotlin Build Type to: DEBUG")
			GradleProperties.write_property(GradleProperties.KEY_BUILD_TYPE, "debug")
		1:
			print("Updating Kotlin Build Type to: RELEASE")
			GradleProperties.write_property(GradleProperties.KEY_BUILD_TYPE, "release")


func update_ui_from_properties():
	var properties := GradleProperties.read_properties() as Dictionary
	update_build_type(properties)
	update_platform(properties)
	update_arm_arch(properties)
	update_ios_identity(properties)


# Update the build type selector
func update_build_type(properties: Dictionary):
	var buildType = null
	if properties.has(GradleProperties.KEY_BUILD_TYPE):
		buildType = properties[GradleProperties.KEY_BUILD_TYPE]
	
	if buildType == "debug":
		buildTypeSelector.selected = 0
	elif buildType == "release":
		buildTypeSelector.selected = 1
	else:
		buildTypeSelector.selected = 0


func update_platform(properties: Dictionary):
	var platform = null
	if properties.has(GradleProperties.KEY_PLATFORM):
		platform = properties[GradleProperties.KEY_PLATFORM]
	
	if platform == "windows":
		platformSelector.selected = 1
	elif platform == "linux":
		platformSelector.selected = 2
	elif platform == "macos":
		platformSelector.selected = 3
	elif platform == "ios":
		platformSelector.selected = 4
	elif platform == "android":
		platformSelector.selected = 5
	# Default to all
	else:
		platformSelector.selected = 0


func _on_PlatformButton_item_selected(id):
	var newPlatform = null
	match id:
		# all
		0:
			newPlatform = null
		1:
			newPlatform = "windows"
		2:
			newPlatform = "linux"
		3:
			newPlatform = "macos"
		4:
			newPlatform = "ios"
		5:
			newPlatform = "android"
		_:
			newPlatform = null
	
	GradleProperties.write_property(GradleProperties.KEY_PLATFORM, newPlatform)


func update_arm_arch(properties: Dictionary):
	var armArch = null
	if properties.has(GradleProperties.KEY_ARM_ARCH):
		armArch = properties[GradleProperties.KEY_ARM_ARCH]
	
	if armArch == "arm64":
		armArchSelector.selected = 0
	elif armArch == "x64":
		armArchSelector.selected = 1
	else:
		armArchSelector.selected = 0


func _on_ArmArchOptionButton_item_selected(id):
	var newArmArch: String
	match id:
		# all
		0:
			newArmArch = "arm64"
		1:
			newArmArch = "x64"
	
	GradleProperties.write_property(GradleProperties.KEY_ARM_ARCH, newArmArch)


func update_ios_identity(properties: Dictionary):
	var iosSigningIdentity = null
	if properties.has(GradleProperties.KEY_IOS_IDENTITY):
		iosSigningIdentity = properties[GradleProperties.KEY_IOS_IDENTITY]
	
	if iosSigningIdentity != null:
		iosIdentityLineEdit.text = iosSigningIdentity
	else:
		iosIdentityLineEdit.text = ""


func _on_iOSIdentityLineEdit_text_changed(new_text):
	var newIdentity = iosIdentityLineEdit.text.strip_edges()
	if newIdentity.length() == 0:
		newIdentity = null
	
	GradleProperties.write_property(GradleProperties.KEY_IOS_IDENTITY, newIdentity)
