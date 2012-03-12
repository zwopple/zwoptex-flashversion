package com.zwopple.zwoptex {

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.*;

	public class ZTCanvas extends MovieClip {
		
		private var _width:Number = 1024.0;
		private var _height:Number = 1024.0;
		private var _gridSize:Number = 32.0;
		private var _background:Sprite;
		private var _container:Sprite;
		
		public function ZTCanvas() {
			name = "canvas";
			_background = new Sprite();
			_background.cacheAsBitmap = true;
			_background.addChild(new Sprite());
			_background.addChild(new Sprite());
			_background.name = "canvas";
			_background.mouseChildren = false;
			addChild(_background);
			_container = new Sprite();
			_container.name = "canvas";
			addChild(_container);
			width = 1024.0;
			height = 1024.0;
		}
		
		override public function get width():Number {
			return _width;
		}
		override public function set width(pValue:Number):void {
			_width = pValue;
			drawBackground();
			
		}
		override public function get height():Number {
			return _height;
		}
		override public function set height(pValue:Number):void {
			_height = pValue;
			drawBackground();
		}
		public function get container():Sprite {
			return _container;
		}
		
		private function drawBackground():void {
			var gfx:Graphics;
			
			gfx = Sprite(_background.getChildAt(0)).graphics;
			gfx.clear();
			
			var rows:int = _height / _gridSize;
			var cols:int = _width / _gridSize;
			var c:Boolean = true;
			for(var i:int = 0; i < rows; i++) {
				for(var j:int = 0; j < cols; j++) {
					var px:Number = j * _gridSize;
					var py:Number = i * _gridSize;
					var color:uint = (c) ? 0x131313 : 0x333333;
					c = !c;
					gfx.beginFill(color,1.0);
					gfx.drawRect(px,py,_gridSize,_gridSize);
					gfx.endFill();
					
				}
				c = !c;
			}
			
			gfx = Sprite(_background.getChildAt(1)).graphics;
			gfx.clear();
			
			gfx.beginFill(0xFFFFFF,0.7);
			gfx.drawRect(0.0,0.0,_width,_height);
			gfx.endFill();
		}
	}
}