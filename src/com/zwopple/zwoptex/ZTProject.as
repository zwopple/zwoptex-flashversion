package com.zwopple.zwoptex {

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.*;
	
	import mx.graphics.codec.PNGEncoder;

	public class ZTProject {
		
		public static const PROJECT_BINARY_FORMAT_VERSION:Number = 1.0;
		public static const PROJECT_FORMAT_CURRENT:uint = 0;
		public static const PROJECT_FORMAT_LEGACY:uint = 1;
		public static const PROJECT_FORMAT_OLD:uint = 2;
		
		public var name:String = "project.ztp";
		public var savedTextureName:String = "texture.png";
		public var savedCoordinatesName:String = "coordinates.plist";
		public var arrangeMinSpacing:int = 1;
		
		private var _images:Array;
		private var _selector:ZTSelector;
		private var _canvas:ZTCanvas;
		
		public function ZTProject() {
			_images = [];
			_selector = new ZTSelector(this);
			_canvas = new ZTCanvas();
		}
		public function get images():Array {
			return _images.slice();
		}
		public function get selector():ZTSelector {
			return _selector;
		}
		public function get canvas():ZTCanvas {
			return _canvas;
		}
		public function get data():ByteArray {
			var byteArray:ByteArray = new ByteArray();
			var obj:Object = {
				version:PROJECT_BINARY_FORMAT_VERSION,
				savedTextureName:savedTextureName,
				savedCoordinatesName:savedCoordinatesName,
				canvasWidth:_canvas.width,
					canvasHeight:_canvas.height,
					arrangeMinSpacing:arrangeMinSpacing
			};
			byteArray.writeObject(obj);
			for(var i:int = 0; i < _images.length; i++) {
				ZTImage(_images[i]).saveToByteArray(byteArray);
			}
			byteArray.compress();
			return byteArray;
		}
		public function set data(pData:ByteArray):void {
			var byteArray:ByteArray = pData;
			byteArray.position = 0.0;
			try {
				byteArray.uncompress();
			} catch(e:*) {
				// wasn't compressed don't do anything
			}
			var projectFormat:uint = projectFormat(byteArray);
			switch(projectFormat) {
				case PROJECT_FORMAT_LEGACY :
					byteArray = convertLegacyToVersioned(byteArray);
					break;
				case PROJECT_FORMAT_OLD :
					byteArray = convertOldVersionedToNewVersioned(byteArray);
					break;
				case PROJECT_FORMAT_CURRENT :
					break;
			}
			byteArray.position = 0;
			removeAllImages();
			var obj:Object = byteArray.readObject();
			savedTextureName = obj.savedTextureName;
			savedCoordinatesName = obj.savedCoordinatesName;
			_canvas.width = obj.canvasWidth;
			_canvas.height = obj.canvasHeight;
			while(byteArray.position < byteArray.length) {
				var image:ZTImage = new ZTImage();
				image.loadFromByteArray(byteArray);
				addImage(image,false);
			}
			updateCanvas();
		}
		public function serializeCanvasToPNG():ByteArray {
			var bmd:BitmapData = new BitmapData(_canvas.width,_canvas.height,true,0x00000000);
			bmd.lock();
			for(var i:int = 0; i < _images.length; i++) {
				var image:ZTImage = _images[i];
				var drawPoint:Point = new Point(image.x,image.y);
				if(!image.trimmed) {
					drawPoint.x += image.trimmedRect.x;
					drawPoint.y += image.trimmedRect.y;
				}
				bmd.copyPixels(image.bitmapData,new Rectangle(0.0,0.0,image.width,image.height),drawPoint,null,null,true);
			}
			bmd.unlock();
			return new PNGEncoder().encode(bmd);
		}
		public function serializeToPropertyListString():String {
			var o:String = "";
			
			// add plist headers
			o += '<?xml version="1.0" encoding="UTF-8"?>\n';
			o += '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n';
			o += '<plist version="1.0">\n';
			
			// start dict
			o += '<dict>\n';
			
			// texture data
			o += '\t<key>texture</key>\n';
			o += '\t<dict>\n';
			o += '\t\t<key>width</key>\n';
			o += '\t\t<integer>' + _canvas.width + '</integer>\n';
			o += '\t\t<key>height</key>\n';
			o += '\t\t<integer>' + _canvas.height + '</integer>\n';
			o += '\t</dict>\n';
			
			// frames
			o += '\t<key>frames</key>\n';
			o += '\t<dict>\n';
			for(var i:int = 0; i < _images.length; i++) {
				var image:ZTImage = _images[i];
				o += '\t\t<key>' + image.id + '</key>\n';
				o += '\t\t<dict>\n';
				o += '\t\t\t<key>x</key>\n';
				o += '\t\t\t<integer>' + image.x + '</integer>\n';
				o += '\t\t\t<key>y</key>\n';
				o += '\t\t\t<integer>' + image.y + '</integer>\n';
				o += '\t\t\t<key>width</key>\n';
				o += '\t\t\t<integer>' + image.width + '</integer>\n';
				o += '\t\t\t<key>height</key>\n';
				o += '\t\t\t<integer>' + image.height + '</integer>\n';
				o += '\t\t\t<key>offsetX</key>\n';
				o += '\t\t\t<real>' + image.offsetX + '</real>\n';
				o += '\t\t\t<key>offsetY</key>\n';
				o += '\t\t\t<real>' + -image.offsetY + '</real>\n';
				o += '\t\t\t<key>originalWidth</key>\n';
				o += '\t\t\t<integer>' + image.originalWidth + '</integer>\n';
				o += '\t\t\t<key>originalHeight</key>\n';
				o += '\t\t\t<integer>' + image.originalHeight + '</integer>\n';
				o += '\t\t</dict>\n';
			}
			o += '\t</dict>\n';
			
			// end dict
			o += '</dict>\n';
			
			// end plist
			o += '</plist>';
			
			return o;
		}
		
		public function removeAllImages():void {
			_images = [];
			updateCanvas();
		}
		
		public function addImage(pImage:ZTImage, pUpdateCanvas:Boolean = true):void {
			_images.push(pImage);
			if(pUpdateCanvas) {
				updateCanvas();
			}
		}
		public function deleteImage(pImage:ZTImage, pUpdateCanvas:Boolean = true):void {
			var index:int = _images.indexOf(pImage);
			if(index >= 0) {
				_images.splice(index,1);
				updateCanvas();
			}
		}
		public function repositionImagesInsideCanvas():void {
			var image:ZTImage;
			for(var i:int = 0; i< _images.length; i++) {
				image = _images[i];
				image.x = Math.max(0.0,Math.min(canvas.width - image.width,image.x));
				image.y = Math.max(0.0,Math.min(canvas.height - image.height,image.y));
			}
		}
		public function selectAllImages():void {
			for(var i:int = 0; i < _images.length; i++) {
				_images[i].selected = true;
			}
		}
		public function trimImages(pImages:Array):void {
			while(pImages.length > 0) {
				pImages.shift().trimmed = true;
			}
			repositionImagesInsideCanvas();
		}
		public function untrimImages(pImages:Array):void {
			while(pImages.length > 0) {
				pImages.shift().trimmed = false;
			}
			repositionImagesInsideCanvas();
		}
		public function arrangeImagesByNameAndWidth(pAscending:Boolean = true):void {
			var imagesArray:Array = _images.slice().sortOn("id");
			if(!pAscending) {
				imagesArray = imagesArray.reverse();
			}
			layoutImagesByWidth(imagesArray);
		}
		public function arrangeImagesByNameAndHeight(pAscending:Boolean = true):void {
			var imagesArray:Array = _images.slice().sortOn("id");
			if(!pAscending) {
				imagesArray = imagesArray.reverse();
			}
			layoutImagesByHeight(imagesArray);
		}
		public function arrangeImagesByWidth(pAscending:Boolean = true):void {
			var imagesArray:Array = _images.slice().sortOn("width", Array.NUMERIC);
			if(!pAscending) {
				imagesArray = imagesArray.reverse();
			}
			layoutImagesByWidth(imagesArray);
		}
		public function arrangeImagesByHeight(pAscending:Boolean = true):void {
			var imagesArray:Array = _images.slice().sortOn("height", Array.NUMERIC);
			if(!pAscending) {
				imagesArray = imagesArray.reverse();
			}
			layoutImagesByHeight(imagesArray);
		}
		public function arrangeImagesByComplexWidth(pAscending:Boolean = true):void {
			var imagesArray:Array = _images.slice().sortOn("width", Array.NUMERIC);
			if(!pAscending) {
				imagesArray = imagesArray.reverse();
			}
			new ZTSorter(imagesArray, canvas.width, canvas.height, arrangeMinSpacing);
		}
		public function arrangeImagesByComplexHeight(pAscending:Boolean = true):void {
			var imagesArray:Array = _images.slice().sortOn("height", Array.NUMERIC);
			if(!pAscending) {
				imagesArray = imagesArray.reverse();
			}
			new ZTSorter(imagesArray, canvas.width, canvas.height, arrangeMinSpacing);
		}
		
		private function layoutImagesByHeight(pImageArray:Array):void {
			var nextX:int = arrangeMinSpacing;
			var nextY:int = arrangeMinSpacing;
			var biggestY:int = 0;
			for(var i:int = 0; i < pImageArray.length; i++) {
				var image:ZTImage = pImageArray[i];
				
				if(nextX + image.width + arrangeMinSpacing > _canvas.width) {
					nextX = arrangeMinSpacing;
					nextY = biggestY + arrangeMinSpacing;
				}
				image.x = nextX;
				image.y = nextY;
				biggestY = Math.max(biggestY, nextY + image.height);
				
				nextX += image.width + arrangeMinSpacing;
				
				if(nextY + image.height + arrangeMinSpacing > _canvas.height) {
					image.x = 0.0;
					image.y = 0.0;
				}
			}
		}
		private function layoutImagesByWidth(pImageArray:Array):void {
			var nextX:int = arrangeMinSpacing;
			var nextY:int = arrangeMinSpacing;
			var biggestX:int = 0;
			for(var i:int = 0; i < pImageArray.length; i++) {
				var image:ZTImage = pImageArray[i];
				
				if(nextY + image.height + arrangeMinSpacing > _canvas.height) {
					nextY = arrangeMinSpacing;
					nextX = biggestX + arrangeMinSpacing;
				}
				image.x = nextX;
				image.y = nextY;
				biggestX = Math.max(biggestX,nextX + image.width);
				
				nextY += image.height + arrangeMinSpacing;
				
				if(nextX + image.width + arrangeMinSpacing > _canvas.width) {
					image.x = 0.0;
					image.y = 0.0;
				}
			}
		}
		
		private function updateCanvas():void {
			var s:Sprite = _canvas.container;
			while(s.numChildren > 0) {
				s.removeChildAt(0);
			}
			var imagesCopy:Array = _images.slice();
			while(imagesCopy.length > 0) {
				s.addChild(imagesCopy.shift())
			}
		}
		private function projectFormat(pByteArray:ByteArray):uint {
			pByteArray.position = 0;
			var obj:Object = pByteArray.readObject();
			if(obj.version == null) {
				return PROJECT_FORMAT_LEGACY;
			} else if(isNaN(obj.version)) {
				return PROJECT_FORMAT_LEGACY;
			} else if(obj.version != PROJECT_BINARY_FORMAT_VERSION) {
				return PROJECT_FORMAT_OLD;
			}
			return PROJECT_FORMAT_CURRENT;
		}
		private function convertLegacyToVersioned(pByteArray:ByteArray):ByteArray {
			var newByteArray:ByteArray = new ByteArray();
			var obj:Object = {
				version:PROJECT_BINARY_FORMAT_VERSION,
				savedTextureName:"texture.png",
				savedCoordinatesName:"coordinates.plist",
				canvasWidth:1024.0,
				canvasHeight:1024.0,
				arrangeMinSpacing:1.0
			};
			newByteArray.writeObject(obj);
			pByteArray.position = 0;
			while(pByteArray.position < pByteArray.length) {
				var legacyObject:Object = pByteArray.readObject();
				var newObject:Object = {
					id:legacyObject.id,
					x:legacyObject.x,
					y:legacyObject.y,
					trimmed:true,
					imageBytes:legacyObject.png
				};
				newObject.imageBytes.position = 0;
				newByteArray.writeObject(newObject);
			}
			return newByteArray;
		}
		private function convertOldVersionedToNewVersioned(pByteArray:ByteArray):ByteArray {
			return pByteArray;
		}
	}
}