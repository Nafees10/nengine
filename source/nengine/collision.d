module nengine.collision;

import nengine.nengine;
import nengine.gameobject;

import std.math;

/// checks if two objects, at their current position, are overlapping.
/// 
/// Uses collision maps for matching
/// 
/// TODO: uses a janky method, come up with a better algorithm for this
///
/// Returns: true if objects overlapping, false if not
package bool isOverlapping(GameObject object1, GameObject object2){
	bool[float[2]] isOccupied;
	foreach(y; 0 .. object1.collisionMap.height){
		const uint cellCount = y * object1.collisionMap.width;
		foreach (x; 0 .. object1.collisionMap.width){
			const uint index = cellCount + x;
			if (object1.collisionMap.grid[index])
				isOccupied[[x + object1.x, y + object1.y]] = true;
		}
	}
	foreach (y; 0 .. object2.collisionMap.height){
		const uint cellCount = y * object2.collisionMap.width;
		foreach (x; 0 .. object2.collisionMap.width){
			const uint index = cellCount + x;
			if (object2.collisionMap.grid[index] && [x + object2.x, y + object2.y] in isOccupied)
				return false;
		}
	}
	return true;
}

/// Checks if a moving object, if continues motion, will collide or not. 
/// 
/// Also sets moving object's position to where it should be, stopping at right before collision
// TODO: write this