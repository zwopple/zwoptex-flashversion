package com.zwopple.zwoptex {

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.*;

	public class ZTImage extends Sprite {
		
		private var _id:String;
		
		private var _imageBytes:ByteArray;
		
		private var _trimmed:Boolean = true;
		private var _selected:Boolean = false;
		
		private var _loader:Loader;
		private var _bitmap:Bitmap;
		private var _bitmapData:BitmapData;
		
		private var _originalRect:Rectangle;
		private var _trimmedRect:Rectangle;
		
		private var _overlay:Sprite;
	
		public function ZTImage() {
			name = "image";
		}
		
		public function get id():String {
			return _id;
		}
		public function get trimmed():Boolean {
			return _trimmed;
		}
		public function set trimmed(pValue:Boolean):void {
			_trimmed = pValue;
			if(_trimmed) {
				_bitmap.x = 0.0;
				_bitmap.y = 0.0;
			} else {
				_bitmap.x = _trimmedRect.x;
				_bitmap.y = _trimmedRect.y;
			}
			_overlay.width = width;
			_overlay.height = height;
		}
		public function get selected():Boolean {
			return _selected;
		}
		public function set selected(pValue:Boolean):void {
			_selected = pValue;
			_overlay.alpha = (_selected) ? 0.75 : 0.25;
			if(_selected) {
				if(parent != null) {
					parent.setChildIndex(this,parent.numChildren-1);
				}
			}
		}
		override public function set x(pValue:Number):void {
			super.x = Math.round(pValue);
		}
		override public function set y(pValue:Number):void {
			super.y = Math.round(pValue);
		}
		override public function get width():Number {
			if(trimmed) {
				return _trimmedRect.width;
			} else {
				return _originalRect.width;
			}
		}
		override public function get height():Number {
			if(trimmed) {
				return _trimmedRect.height;
			} else {
				return _originalRect.height;
			}
		}
		public function get squarePixels():Number {
			return width * height;
		}
		public function get offsetX():Number {
			if(!trimmed) {
				return 0.0;
			}
			var ocx:Number = _originalRect.width / 2.0;
			var tcx:Number = _trimmedRect.x + _trimmedRect.width / 2.0;
			return tcx - ocx;
		}
		public function get offsetY():Number {
			if(!trimmed) {
				return 0.0;
			}
			var ocy:Number = _originalRect.height / 2.0;
			var tcy:Number = _trimmedRect.y + _trimmedRect.height / 2.0;
			return tcy - ocy;
		}
		public function get bitmapData():BitmapData {
			return _bitmapData;
		}
		public function get trimmedRect():Rectangle {
			return _trimmedRect;
		}
		public function get originalRect():Rectangle {
			return _originalRect;
		}
		public function get originalWidth():int {
			return _originalRect.width;
		}
		public function get originalHeight():int {
			return _originalRect.height;
		}
		
		public function loadFromFileReference(pFileRef:FileReference):void {
			_id = pFileRef.name;
			loadImageFromBytes(pFileRef.data);
		}
		public function loadFromByteArray(pBytes:ByteArray):void {
			var obj:Object = pBytes.readObject();
			_id = obj.id;
			x = obj.x;
			y = obj.y;
			_trimmed = obj.trimmed;
			_selected = false;
			loadImageFromBytes(obj.imageBytes);
		}
		public function saveToByteArray(pBytes:ByteArray):void {
			_imageBytes.position = 0;
			var obj:Object = {
				id:_id,
				x:x,
				y:y,
				trimmed:_trimmed,
				imageBytes:_imageBytes
			};
			pBytes.writeObject(obj);
		}
		public function destroy():void {
			if(_loader != null) {
				_loader.unloadAndStop();
				_loader = null;
			} else {
				removeChild(_bitmap);
				removeChild(_overlay);
				_bitmapData.dispose();
				_bitmapData = null;
				_bitmap = null;
				_overlay = null;
			}
			_imageBytes = null;
		}
		
		private function loadImageFromBytes(pBytes:ByteArray):void {
			_imageBytes = pBytes;
			_imageBytes.position = 0;
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderLoadBytesCompleteEvent, false, 0, true);
			_loader.loadBytes(_imageBytes);
		}
		private function loaderLoadBytesCompleteEvent(pEvent:Event):void {
			
			// draw from loader
			var tempBitmapData:BitmapData = new BitmapData(_loader.width,_loader.height,true,0x00000000);
			tempBitmapData.draw(_loader);
			
			// dump loader
			_loader.unloadAndStop();
			_loader = null;
			
			// get rects
			_originalRect = new Rectangle(0.0,0.0,tempBitmapData.width,tempBitmapData.height);
			_trimmedRect = tempBitmapData.getColorBoundsRect(0xFF000000,0x00FFFFFF,false);
			
			// trim
			_bitmapData = new BitmapData(_trimmedRect.width,_trimmedRect.height,true,0x00000000);
			_bitmapData.copyPixels(tempBitmapData,_trimmedRect,new Point(0.0,0.0),null,null,true);
			_bitmap = new Bitmap(_bitmapData,"auto",true);
			
			// overlay
			_overlay = new Sprite();
			_overlay.graphics.beginFill(0xFF0000,1.0);
			_overlay.graphics.drawRect(0.0,0.0,100.0,100.0);
			_overlay.graphics.endFill();
			_overlay.cacheAsBitmap = true;
			
			// add children
			addChild(_overlay);
			addChild(_bitmap);
			
			// set vars
			trimmed = _trimmed;
			selected = _selected;
			
			// mouse
			mouseEnabled = true;
			mouseChildren = false;
			hitArea = _overlay;
		}
	}
}