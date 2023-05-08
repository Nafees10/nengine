module nengine.io;

import std.datetime;

import utils.lists;
import utils.misc : uinteger, integer;

/// a RGBA color
public struct RGBA{
	ubyte r = 0; /// red
	ubyte g = 0; /// green
	ubyte b = 0; /// blue
	ubyte a = 255; /// alpha
	/// operator overload
	RGBA opBinary(string op : "+")(RGBA rhs){
		immutable float aAlpha = cast(float)rhs.a / 255;
		immutable float bAlpha = cast(float)this.a / 255;
		immutable float alpha = aAlpha + (bAlpha * (1 - aAlpha));
		immutable float bMultiplier = bAlpha * (1 - aAlpha);
		return RGBA(
			cast(ubyte)(((rhs.r * aAlpha) + (this.r * bMultiplier)) / alpha),
			cast(ubyte)(((rhs.g * aAlpha) + (this.g * bMultiplier)) / alpha),
			cast(ubyte)(((rhs.b * aAlpha) + (this.b * bMultiplier)) / alpha),
			cast(ubyte)(alpha * 255)
		);
	}
}

/// Mouse buttons
enum MouseButton{
	Hover, /// cursor moved. This type of event won't be returned by NEngineIO
	Left, /// left click
	Right, /// right click
	Middle, /// middle click
	ScrollUp, /// scroll up
	ScrollDown  /// scroll down
}

/// Keyboard non character keys
/// 
/// safe to add more
public enum Key : char{
	ArrowUp,
	ArrowDown,
	ArrowLeft,
	ArrowRight,

	Enter,
	Backspace,
	Tab,
	Escape,
}

/// Mouse input event
public struct MouseEvent{
	/// type of this event
	MouseButton type;
	/// x and y coordinates of where cursor was
	int x, y;
	/// constructor
	this (MouseButton type, int x, int y){
		this.type = type;
		this.x = x;
		this.y = y;
	}
}

/// Keyboard input event
public struct KeyboardEvent{
	/// possible types
	enum Type{
		Pressed,
		Released,
	}
	/// type of this event
	Type type;
	/// the key pressed/released
	char key;

	/// if key pressed/released was character
	bool isChar;
	/// constructor, for character keys
	this(Type type, char key){
		// catch some special keys that are characters too
		const Key[char] KEY_CHAR_MAP = [
			'\n' : Key.Enter,
			'\b' : Key.Backspace,
			'\t' : Key.Tab
		];
		this.type = type;
		if (key in KEY_CHAR_MAP){
			this.key = cast(Key)key;
			this.isChar = false;
		}else{
			this.key = key;
			this.isChar = true;
		}
	}
	/// constructor, for non character eys
	this(Type type, Key key){
		this.type = type;
		this.key = key;
		this.isChar = false;
	}
}

/// an output for the nengine to render onto. This is also responsible for input events
public abstract class NEngineIO{
private:
	/// resolution
	uint _width, _height;
	/// stores status of character keys. true is pressed, false is not pressed
	bool[char] _charKeyIsPressed;
	/// stores status of character keys. true is pressed, false is not pressed
	bool[Key] _keyIsPressed;
	/// event queue for keyboard events
	FIFOStack!KeyboardEvent _keyboardEvents;
	/// event queue for mouse events
	FIFOStack!MouseEvent _mouseEvents;
	/// stores what pixels have to be redrawn. Read as _pixelNeedsUpdate[y*width + x]
	bool[] _pixelNeedsUpdate;
	/// stores all pixels of screen. Read as _screenMatrix[y*width + x]
	RGBA[] _screenMatrix;
	/// background color
	RGBA _backColor;
protected:
	/// x, y position of mouse cursor
	int _mouseX, _mouseY;
	/// reads a keyboard event that occurred, if any, to a ref KeyboardEvent
	/// 
	/// Returns: true if event occured
	abstract bool readKeyboardEvent(ref KeyboardEvent);
	/// reads a mouse event that occurred, if any, to a ref MouseEvent
	/// 
	/// Returns: true if event occured
	abstract bool readMouseEvent(ref MouseEvent);
	/// draws a color at a pixel at x,y coordinates
	abstract void drawPixel(int x, int y, RGBA color);

	/// call this in constructor
	void start(){
		_keyboardEvents = new FIFOStack!KeyboardEvent;
		_mouseEvents = new FIFOStack!MouseEvent;
	}
	/// call this in destructor
	void end(){
		.destroy(_keyboardEvents);
		.destroy(_mouseEvents);
	}
public:
	/// Sets resolution
	void forceResolution(uint width, uint height){
		_width = width;
		_height = height;
		_pixelNeedsUpdate.length = _width * _height;
		_screenMatrix.length = _width * _height;
	}

	/// Runs a short benchmark to determine max average FPS that it can output.
	/// 
	/// `delay` is artificially added as a delay, to compensate for no work actually being done aside from rendering, after each frame
	abstract uint detectMaxFPS(Duration delay);

	/// Sets the background color
	void backColor(RGBA color){
		_backColor = color;
	}

	/// prepare to draw a frame
	abstract void frameStart();
	/// flush frame
	void frameEnd(){
		foreach(y; 0 .. _height){
			immutable yTimesWidth = y * _width;
			foreach(x; 0 .. _width){
				immutable index = yTimesWidth + x;
				if (_pixelNeedsUpdate[index])
					drawPixel(x, y, _screenMatrix[index]);
			}
		}
		/// clear matrix for next frame
		_screenMatrix[] = _backColor;
	}
	/// draws a pixel
	/// 
	/// Returns: false if the x, y coordinates are outside screen
	bool draw(int x, int y, RGBA color){
		immutable uinteger index = (y * _width) + x;
		if (index >= _screenMatrix.length)
			return false;
		_screenMatrix[index] = _screenMatrix[index] + color;
		_pixelNeedsUpdate[index] = true;
		return true;
	}

	/// prepares events to be read
	void readEvents(){
		MouseEvent mEvent;
		KeyboardEvent kEvent;
		while (readKeyboardEvent(kEvent)){
			_keyboardEvents.push(kEvent);
			if (kEvent.isChar){
				_charKeyIsPressed[kEvent.key] = kEvent.type == KeyboardEvent.Type.Pressed;
				continue;
			}
			_keyIsPressed[cast(Key)(kEvent.key)] = kEvent.type == KeyboardEvent.Type.Pressed;
		}
		while (readMouseEvent(mEvent)){
			_mouseEvents.push(mEvent);
			_mouseX = mEvent.x;
			_mouseY = mEvent.y;
		}
	}
	/// Returns: true if mouse event occurred, and writes event to ref
	bool getMouseEvent(ref MouseEvent mEvent){
		if (_mouseEvents.count > 0){
			mEvent = _mouseEvents.pop;
			return true;
		}
		return false;
	}
	/// Returns: true if keyboard event occurred, and writes event to ref
	bool getKeyboardEvent(ref KeyboardEvent kEvent){
		if (_keyboardEvents.count > 0){
			kEvent = _keyboardEvents.pop;
			return true;
		}
		return false;
	}
	/// Returns: true if a key is pressed down
	bool keyIsDown(char key){
		return key in _charKeyIsPressed && _charKeyIsPressed[key];
	}
	/// ditto
	bool keyIsDown(Key key){
		return key in _keyIsPressed && _keyIsPressed[key];
	}
	/// Sets mouse x, y coordinates to where cursor is
	void getMouseXY(ref int x, ref int y){
		x = _mouseX;
		y = _mouseY;
	}
}
/// 
unittest{
	class SampleIO : NEngineIO{

	}
}
