module nengine.gameobject;

import utils.misc;
import nengine.io;

/// A grid, can be used to store collision maps and sprites
public struct Grid(T){
	uint width; /// width
	uint height; /// height
	T[] grid; /// the grid. Read as grid[y*width + x]
	/// Returns: ref to cell at x, y
	/// 
	/// Throws: Exception if x or y is outside bounds
	T cell(uint x, uint y){
		immutable uint index = (y * width) + x;
		if (index >= grid.length)
			throw new Exception("x y coordinates out of bound in nengine.gameobject.Grid.cell");
		return grid[index];
	}
	/// postblit
	this(this){
		this.grid = this.grid.dup;
	}
}

/// Sprite
public alias Sprite = Grid!(RGBA);
/// Collision map
public alias CollisionMap = Grid!bool;

/// object
public abstract class GameObject{
private:

protected:
	int _x, _y; /// x and y coordinates
	Sprite _sprite; /// it's sprite
	CollisionMap _collisionMap; /// collision map
public:
	/// generates collision map from sprite. Generated based on transparent pixels in sprite
	void generateCollisionMap(){
		_collisionMap.grid.length = _sprite.grid.length;
		_collisionMap.width = _sprite.width;
		_collisionMap.height = _sprite.height;
		foreach(index, spriteCell; _sprite.grid){
			_collisionMap.grid[index] = spriteCell.a > 0;
		}
	}
	/// Returns: sprite of this object
	@property Sprite sprite(){
		return _sprite;
	}
	/// ditto
	@property Sprite sprite(Sprite newSprite){
		return _sprite = newSprite;
	}
	/// Returns: collision map for this object
	@property CollisionMap collisionMap(){
		return _collisionMap;
	}
	/// ditto
	@property CollisionMap collisionMap(CollisionMap newCollisionMap){
		return _collisionMap = newCollisionMap;
	}
	/// Returns: x coordinates of this object
	@property int x(){
		return _x;
	}
	/// ditto
	@property int x(int newX){
		return _x = newX;
	}
	/// Returns: y coordinates of this object
	@property int y(){
		return _y;
	}
	/// ditto
	@property int y(int newY){
		return _y = newY;
	}
}