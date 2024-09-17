extends Viewport

# Renders a page of text to a viewport for use as a texture.


func set_text(text: String, page: int):
	$PageRendererUI.set_text(text, page)
